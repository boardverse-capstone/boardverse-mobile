import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:boardverse/core/di/injection.dart';
import 'package:boardverse/core/theme/app_colors.dart';
import 'package:boardverse/core/theme/app_icons.dart';
import 'package:boardverse/core/theme/app_spacing.dart';
import '../../../match_summary_rating/domain/entities/rating_entity.dart';
import '../../../match_summary_rating/presentation/cubit/rating_cubit.dart';
import '../../../match_summary_rating/presentation/cubit/rating_state.dart';
import '../../../match_summary_rating/presentation/widgets/player_rating_card.dart';

/// Màn hình đánh giá Karma sau phiên chơi — bind với API thật
/// `GET /api/v1/users/ratings/karma/lobbies/{lobbyId}` +
/// `POST /api/v1/users/ratings/karma` (xem
/// `.agents/docs/apis_docs/user-ratings.md`).
///
/// Được mở từ 2 entry point:
/// 1. `LobbyEndedView` khi lobby status = `closed`.
/// 2. `ReservationDetailPage` khi reservation terminal + lobby rating open.
///
/// Sau khi submit thành công (hoặc đã rate hết) → pop về root với
/// `true` để caller refresh lobby state.
class LobbyRatingPage extends StatefulWidget {
  final String lobbyId;
  final String? reservationId;

  const LobbyRatingPage({
    super.key,
    required this.lobbyId,
    this.reservationId,
  });

  @override
  State<LobbyRatingPage> createState() => _LobbyRatingPageState();
}

class _LobbyRatingPageState extends State<LobbyRatingPage> {
  late final RatingCubit _ratingCubit;

  @override
  void initState() {
    super.initState();
    _ratingCubit = getIt<RatingCubit>();
    _ratingCubit.loadKarmaContext(widget.lobbyId);
  }

  @override
  void dispose() {
    // Reset cubit state để lần mở sau không giữ cache cũ.
    _ratingCubit.reset();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return BlocProvider.value(
      value: _ratingCubit,
      child: BlocConsumer<RatingCubit, RatingState>(
        listener: (context, state) {
          if (state is KarmaRatingSubmitted && !state.partial) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đánh giá Karma đã được gửi thành công!'),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
            Navigator.of(context).pop(true);
          } else if (state is KarmaRatingSubmitted && state.partial) {
            // 1 vài target đã được rate trước đó (409) — vẫn pop.
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message ?? 'Đã cập nhật đánh giá.'),
                backgroundColor: AppColors.warning,
                behavior: SnackBarBehavior.floating,
              ),
            );
            Navigator.of(context).pop(true);
          } else if (state is RatingFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: colors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Đánh giá Karma'),
              leading: IconButton(
                tooltip: 'Đóng',
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              actions: [
                IconButton(
                  tooltip: 'Tải lại',
                  icon: const Icon(AppIcons.refresh),
                  onPressed: () => _ratingCubit.refresh(),
                ),
              ],
            ),
            body: _buildBody(context, state),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, RatingState state) {
    if (state is RatingLoading) {
      return const _LoadingView();
    }

    if (state is RatingFailure) {
      return _FailureView(
        message: state.message,
        onRetry: () => _ratingCubit.loadKarmaContext(widget.lobbyId),
      );
    }

    if (state is KarmaRating) {
      return _KarmaRatingView(
        state: state,
        onToggleTag: (playerId, tagId) =>
            _ratingCubit.toggleKarmaTag(playerId, tagId),
        onSubmit: () => _ratingCubit.submitKarmaRatings(),
      );
    }

    if (state is KarmaRatingSubmitted) {
      return _KarmaRatingSubmittedView(
        result: state.result,
        partial: state.partial,
        message: state.message,
      );
    }

    return const _LoadingView();
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 4,
            ),
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            'Đang tải ngữ cảnh đánh giá...',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _KarmaRatingView extends StatelessWidget {
  final KarmaRating state;
  final void Function(String playerId, String tagId) onToggleTag;
  final VoidCallback onSubmit;

  const _KarmaRatingView({
    required this.state,
    required this.onToggleTag,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final canSubmit = state.canSubmitRatings &&
        state.playersToRate.any(
          (p) => !p.alreadyRated && p.selectedTagIds.isNotEmpty,
        );

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      children: [
        _HeaderBanner(
          lobbyStatus: state.lobbyStatus,
          canSubmitRatings: state.canSubmitRatings,
          pendingMemberCount: state.pendingMemberCount,
          allRated: state.allRated,
        ),
        const SizedBox(height: AppSpacing.md),

        // Nếu đã rate hết member, hiển thị empty state + nút đóng.
        if (state.playersToRate.isEmpty)
          _EmptyPlayersView(lobbyStatus: state.lobbyStatus)
        else if (state.allRated)
          _AllRatedView()
        else
          ...state.playersToRate.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: PlayerRatingCard(
                player: p,
                availableTags: state.availableTags,
                onTagToggle: (playerId, tagId) =>
                    onToggleTag(playerId, tagId),
              ),
            ),
          ),

        if (!state.allRated) ...[
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: canSubmit ? onSubmit : null,
            icon: const Icon(Icons.send_rounded),
            label: Text(
              state.canSubmitRatings
                  ? 'Gửi đánh giá'
                  : 'Phòng chưa mở cửa sổ đánh giá',
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            state.allRated ? 'Đóng' : 'Để sau',
          ),
        ),

        const SizedBox(height: AppSpacing.lg),
        const _PrivacyNote(),
      ],
    );
  }
}

class _HeaderBanner extends StatelessWidget {
  final String lobbyStatus;
  final bool canSubmitRatings;
  final int pendingMemberCount;
  final bool allRated;

  const _HeaderBanner({
    required this.lobbyStatus,
    required this.canSubmitRatings,
    required this.pendingMemberCount,
    required this.allRated,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    String title;
    String subtitle;
    IconData icon;

    if (allRated) {
      bgColor = AppColors.success;
      title = 'Hoàn tất đánh giá';
      subtitle = 'Bạn đã đánh giá toàn bộ thành viên trong phòng này.';
      icon = AppIcons.check;
    } else if (canSubmitRatings) {
      bgColor = AppColors.primary;
      title = 'Đánh giá trải nghiệm';
      subtitle = pendingMemberCount > 0
          ? 'Còn $pendingMemberCount thành viên cần được đánh giá.'
          : 'Chọn tag mô tả từng thành viên trong phòng.';
      icon = Icons.star_rate;
    } else {
      // Lobby chưa ở RatingOpen/Closed — show cảnh báo nhẹ.
      bgColor = AppColors.warning;
      title = 'Phòng chưa mở cửa sổ đánh giá';
      subtitle = 'Vui lòng đợi host mở cửa sổ Karma sau khi POS thanh toán xong.';
      icon = Icons.lock_clock_outlined;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [bgColor, bgColor.withValues(alpha: 0.85)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.35),
            blurRadius: 0,
            offset: const Offset(4, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.white, width: 2),
            ),
            child: Icon(icon, size: 28, color: AppColors.white),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.white.withValues(alpha: 0.92),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                if (lobbyStatus.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xxs),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.black.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Lobby: $lobbyStatus',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPlayersView extends StatelessWidget {
  final String lobbyStatus;
  const _EmptyPlayersView({required this.lobbyStatus});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.3),
            blurRadius: 0,
            offset: const Offset(4, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.group_off_outlined, size: 56, color: AppColors.textSecondary),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Không có thành viên để đánh giá',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 15,
              color: AppColors.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Có thể phòng chỉ có 1 người hoặc bạn đã đánh giá toàn bộ thành viên.',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _AllRatedView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success, width: 2.5),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border, width: 2.5),
            ),
            child: Icon(AppIcons.check, size: 36, color: AppColors.white),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Bạn đã hoàn tất đánh giá!',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: AppColors.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Đánh giá Karma của bạn đã được ghi nhận.',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, size: 16, color: colors.onSurfaceVariant),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Đánh giá Karma giúp cộng đồng BoardVerse an toàn hơn. '
              'Đánh giá của bạn được server tổng hợp ẩn danh.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KarmaRatingSubmittedView extends StatelessWidget {
  final SubmitKarmaRatingsResultEntity result;
  final bool partial;
  final String? message;

  const _KarmaRatingSubmittedView({
    required this.result,
    required this.partial,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = partial ? AppColors.warning : AppColors.success;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: accent,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.4),
                  blurRadius: 0,
                  offset: const Offset(4, 4),
                ),
              ],
            ),
            child: Icon(
              partial ? Icons.warning_amber_rounded : AppIcons.check,
              size: 56,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            partial ? 'Đã cập nhật một phần' : 'Đã gửi đánh giá!',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 22,
              color: AppColors.black,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              message!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          if (result.appliedRatings.isNotEmpty)
            _AppliedRatingsCard(result: result),
        ],
      ),
    );
  }
}

class _AppliedRatingsCard extends StatelessWidget {
  final SubmitKarmaRatingsResultEntity result;
  const _AppliedRatingsCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final totalDelta = result.totalKarmaDelta;
    final isPositive = totalDelta >= 0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.35),
            blurRadius: 0,
            offset: const Offset(4, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Kết quả áp dụng',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  color: AppColors.black,
                  letterSpacing: 0.3,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: isPositive ? AppColors.success : AppColors.error,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: Text(
                  '${isPositive ? '+' : ''}${totalDelta.toStringAsFixed(1)} Karma',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...result.appliedRatings.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                children: [
                  Icon(
                    r.karmaDeltaApplied >= 0
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    size: 16,
                    color: r.karmaDeltaApplied >= 0
                        ? AppColors.success
                        : AppColors.error,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'Tag: ${r.tags.join(", ")}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    '${r.karmaDeltaApplied >= 0 ? '+' : ''}${r.karmaDeltaApplied.toStringAsFixed(1)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      color: r.karmaDeltaApplied >= 0
                          ? AppColors.success
                          : AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FailureView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _FailureView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: colors.error),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Đã có lỗi xảy ra',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(AppIcons.refresh),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }
}
