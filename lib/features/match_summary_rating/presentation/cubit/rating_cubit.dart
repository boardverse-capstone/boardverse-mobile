import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/rating_entity.dart';
import '../../domain/entities/voting_session.dart';
import '../../domain/repositories/rating_repository.dart';
import 'rating_state.dart';
import 'voting_state.dart';

/// Cubit phụ trách 2 chức năng liên quan đến Karma rating:
///
/// 1. **Karma cross-rating** (mới — backend `/api/v1/users/ratings/karma/*`):
///    - `loadKarmaContext(lobbyId)` → fetch context (membersToRate, tags,
///      `alreadyRated` flags, `canSubmitRatings`).
///    - `toggleKarmaTag(playerId, tagId)` → chọn/bỏ tag cho 1 player.
///    - `submitKarmaRatings()` → POST lên server, áp dụng delta + tier mới.
///
/// 2. **No-show voting** (legacy — giữ API để không phá code cũ, nhưng
///    backend mới KHÔNG còn endpoint voting cho no-show riêng → các
///    method voting trả về state rỗng):
///    - `checkPendingVotes()`, `startVoting()`, `submitVote()`,
///      `completeVoting()`.
class RatingCubit extends Cubit<RatingState> {
  final RatingRepository _repository;
  String _currentLobbyId = '';

  // Voting state — legacy, giữ cho code cũ không crash.
  VotingState _votingState = const VotingInitial();

  RatingCubit({required this._repository}) : super(const RatingInitial());

  // ─── Public getters ────────────────────────────────────────────────

  VotingState get votingState => _votingState;

  // ═══════════════════════════════════════════════════════════════════
  // KARMA RATING FLOW — bind tới /api/v1/users/ratings/karma/*
  // ═══════════════════════════════════════════════════════════════════

  /// Load context đánh giá Karma cho 1 lobby. Gọi khi user mở màn hình
  /// đánh giá từ `LobbyRatingPage` hoặc `ReservationDetailPage`.
  ///
  /// Response `200` → emit [KarmaRating] với `availableTags`,
  /// `membersToRate`. Nếu response `canSubmitRatings=false` thì
  /// `membersToRate` vẫn render nhưng button Submit bị disable.
  Future<void> loadKarmaContext(String lobbyId) async {
    emit(const RatingLoading());
    _currentLobbyId = lobbyId;

    final result = await _repository.getKarmaRatingContext(lobbyId);
    result.fold(
      (failure) => emit(RatingFailure(message: failure.message)),
      (context) {
        // Build RatingPlayer list cho UI hiển thị [PlayerRatingCard].
        final players = context.membersToRate
            .map(
              (m) => RatingPlayer(
                id: m.userId,
                name: m.username,
                avatarUrl: m.avatarUrl ?? '',
                alreadyRated: m.alreadyRated,
              ),
            )
            .toList();
        emit(
          KarmaRating(
            playersToRate: players,
            availableTags: context.availableTags,
            canSubmitRatings: context.canSubmitRatings,
            lobbyStatus: context.lobbyStatus,
            pendingMemberCount: context.pendingMemberCount,
            allRated: context.allRated,
          ),
        );
      },
    );
  }

  /// Toggle tag được chọn cho 1 player.
  ///
  /// - Bỏ qua nếu player đã `alreadyRated` (UI cũng disable chips).
  /// - Bỏ qua nếu tag lạ (không match enum `KarmaRatingTag`).
  void toggleKarmaTag(String playerId, String tagId) {
    final currentState = state;
    if (currentState is! KarmaRating) return;

    // Validate tag id là enum hợp lệ (server không nhận tag khác).
    final tagEnum = KarmaRatingTag.fromApiValue(tagId);
    if (tagEnum == null) return;

    final updatedPlayers = currentState.playersToRate.map((player) {
      if (player.id == playerId) {
        if (player.alreadyRated) return player; // immutable
        final selectedTags = List<String>.from(player.selectedTagIds);
        if (selectedTags.contains(tagId)) {
          selectedTags.remove(tagId);
        } else {
          selectedTags.add(tagId);
        }
        return player.copyWith(selectedTagIds: selectedTags);
      }
      return player;
    }).toList();

    emit(
      KarmaRating(
        playersToRate: updatedPlayers,
        availableTags: currentState.availableTags,
        canSubmitRatings: currentState.canSubmitRatings,
        lobbyStatus: currentState.lobbyStatus,
        pendingMemberCount: currentState.pendingMemberCount,
        allRated: currentState.allRated,
      ),
    );
  }

  /// Submit tất cả đánh giá Karma cho server.
  ///
  /// Flow:
  /// 1. Filter ra các player có ≥1 tag được chọn VÀ chưa `alreadyRated`.
  /// 2. Build [KarmaRatingEntry] (targetUserId + tags[]) cho mỗi player.
  /// 3. POST `/api/v1/users/ratings/karma`.
  /// 4. Emit [KarmaRatingSubmitted] với kết quả áp dụng (delta + tier mới).
  Future<void> submitKarmaRatings() async {
    final currentState = state;
    if (currentState is! KarmaRating) return;
    if (!currentState.canSubmitRatings) {
      emit(
        const RatingFailure(
          message: 'Phòng chưa mở cửa sổ đánh giá. Vui lòng đợi staff.',
        ),
      );
      return;
    }

    final entries = currentState.playersToRate
        .where((p) => !p.alreadyRated && p.selectedTagIds.isNotEmpty)
        .map(
          (p) => KarmaRatingEntry(
            targetUserId: p.id,
            tags: p.selectedTagIds
                .map((id) => KarmaRatingTag.fromApiValue(id))
                .whereType<KarmaRatingTag>()
                .toList(),
            lobbyId: _currentLobbyId,
          ),
        )
        .where((e) => e.tags.isNotEmpty)
        .toList();

    if (entries.isEmpty) {
      emit(
        const RatingFailure(
          message: 'Bạn cần chọn ít nhất 1 tag cho 1 thành viên.',
        ),
      );
      return;
    }

    emit(const RatingLoading());

    final result = await _repository.submitKarmaRatings(
      lobbyId: _currentLobbyId,
      entries: entries,
    );
    result.fold(
      (failure) {
        // 409 → "Đã đánh giá người này trước đó" — fallback nhẹ nhàng
        // bằng cách reload context để UI đồng bộ với server.
        final isConflict = failure is ServerFailure &&
            failure.statusCode == 409;
        if (isConflict) {
          emit(
            KarmaRatingSubmitted(
              result: const SubmitKarmaRatingsResultEntity(
                lobbyId: '',
                appliedRatings: [],
              ),
              partial: true,
              message: failure.message,
            ),
          );
          return;
        }
        emit(RatingFailure(message: failure.message));
      },
      (submitResult) {
        emit(
          KarmaRatingSubmitted(
            result: submitResult,
            partial: false,
            message: null,
          ),
        );
      },
    );
  }

  /// Reload context (dùng sau khi submit xong hoặc khi user back vào page).
  Future<void> refresh() async {
    if (_currentLobbyId.isEmpty) return;
    await loadKarmaContext(_currentLobbyId);
  }

  /// Reset state — dùng khi user đóng page.
  void reset() {
    _currentLobbyId = '';
    _votingState = const VotingInitial();
    emit(const RatingInitial());
  }

  // ═══════════════════════════════════════════════════════════════════
  // LEGACY: No-show voting — backend mới không có endpoint riêng,
  // giữ API để code cũ không crash.
  // ═══════════════════════════════════════════════════════════════════

  /// Không còn no-show voting riêng (BR-NEW KarmaRatingTag enum NoShow
  /// đã gộp vào tag list). Method giữ lại cho backward compat — emit
  /// `VotingComplete` ngay để caller không loop.
  void checkPendingVotes() {
    _votingState = const VotingComplete();
  }

  /// Legacy no-op.
  void startVoting(dynamic target) {
    _votingState = const VotingComplete();
  }

  /// Legacy no-op.
  void submitVote(VoteType vote) {
    _votingState = const VotingComplete();
  }

  /// Legacy no-op.
  void completeVoting() {
    _votingState = const VotingComplete();
  }

  /// Mark rating complete — dùng cho UI cũ muốn đóng page.
  void completeRating() {
    emit(const RatingComplete());
  }

  /// Bỏ qua match result — cho UI cũ (không dùng trong flow mới).
  void skipMatchResult() {
    emit(const RatingComplete());
  }
}
