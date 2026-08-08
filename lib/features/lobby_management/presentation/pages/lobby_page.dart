import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:boardverse_mobile/core/di/injection.dart';
import 'package:boardverse_mobile/core/theme/theme.dart';
import 'package:boardverse_mobile/core/utils/current_user_resolver.dart';
import 'package:boardverse_mobile/core/widgets/top_snack_bar.dart';
import 'package:boardverse_mobile/features/booking_payment/domain/entities/booking_rating_submission_entity.dart';
import 'package:boardverse_mobile/features/booking_payment/domain/entities/session_status_entity.dart';
import 'package:boardverse_mobile/features/booking_payment/domain/repositories/booking_repository.dart';
import 'package:boardverse_mobile/features/booking_payment/presentation/cubit/booking_realtime_cubit.dart';
import 'package:boardverse_mobile/features/booking_payment/presentation/widgets/rating_form_sheet.dart';
import 'package:boardverse_mobile/features/friend_management/domain/entities/friend_entity.dart';
import 'package:boardverse_mobile/features/lobby_management/data/datasources/base/lobby_remote_datasource.dart';
import 'package:boardverse_mobile/features/lobby_management/domain/entities/lobby_invite_entity.dart';
import 'package:boardverse_mobile/features/reservation/domain/entities/entities.dart' as res;
import '../../domain/entities/lobby_entity.dart';
import '../../domain/entities/lobby_chat_message.dart';
import '../../domain/entities/lobby_share_info.dart';
import '../cubit/lobby_cubit.dart';
import '../cubit/lobby_reservation_cubit.dart';
import '../cubit/lobby_state.dart';
import '../pages/lobby_pending_cafe_approval_page.dart';
import '../pages/lobby_rating_page.dart';
import '../widgets/lobby_check_in_section.dart';
import '../widgets/lobby_player_card.dart';
import '../widgets/lobby_scaffolds.dart';
import '../widgets/lobby_hero_header.dart';
import '../widgets/lobby_chat_section.dart';
import '../widgets/lobby_bottom_bar.dart';
import '../widgets/lobby_ended_view.dart';
import '../widgets/lobby_sheets.dart';
import '../widgets/lobby_friends_sheet.dart';
import '../widgets/lobby_share_section.dart';
import '../widgets/lobby_status_badge.dart';
import '../widgets/lobby_invitable_friends_sheet.dart';
import '../widgets/members_arrival_checklist.dart';
import '../widgets/scheduled_time_countdown.dart';

/// Entry page cho một lobby — hiển thị hero, players grid, chat, và bottom bar.
class LobbyPage extends StatefulWidget {
  final String lobbyId;
  final LobbyCubit lobbyCubit;

  const LobbyPage({super.key, required this.lobbyId, required this.lobbyCubit});

  @override
  State<LobbyPage> createState() => _LobbyPageState();
}

class _LobbyPageState extends State<LobbyPage> {
  final _chatController = TextEditingController();
  final List<LobbyChatMessage> _chatMessages = [];
  String? _currentUserId;
  bool _chatLoaded = false;

  /// Set các friendId đã gửi lời mời thành công trong session hiện tại
  /// — dùng để disable nút "Mời" trong FriendsSheet (đổi thành "Đã mời")
  /// và giữ user ở nguyên trong sheet để mời tiếp.
  final Set<String> _invitedFriendIds = <String>{};

  /// Set các friendId đã có lời mời Pending trên server cho lobby này
  /// (lấy qua `GET /lobbies/invites/me?status=Pending` rồi filter theo
  /// `lobbyId == currentLobbyId`). Đây là source of truth — đảm bảo khi
  /// user mở sheet sau khi reload / mở app lần sau vẫn thấy đúng tile
  /// "Đã mời" thay vì "Mời" (local cache không biết).
  final Set<String> _serverInvitedFriendIds = <String>{};

  // ─── Share code + sent invites ─────────────────────────────────────
  /// Mã share code của lobby (lấy từ `GET /share-info`). Null = chưa load.
  String? _shareCode;

  /// Lobby có phải private không (lấy từ share-info).
  bool _isPrivate = false;

  /// Danh sách lời mời đã gửi đang còn pending (cache local để re-render
  /// LobbyShareSection khi cancel thành công).
  List<LobbyInviteEntity> _sentPendingInvites = const [];

  LobbyState? _lastGoodLobbyState;

  /// Map userId → arrival status cho MembersArrivalChecklist. Track realtime
  /// qua SignalR BookingCheckedIn event + self-report cubit.
  final Map<String, MemberArrivalStatus> _arrivalByUserId = {};

  /// Booking id (nếu có) — dùng để bind BookingRealtimeCubit cho realtime
  /// checked-in/checked-out events.
  String? _currentBookingId;

  /// Trigger show session-status card khi user đã check-in.
  SessionStatusEntity? _sessionStatus;

  @override
  void initState() {
    super.initState();
    _resolveCurrentUserAndJoin();
  }

  Future<void> _resolveCurrentUserAndJoin() async {
    final resolver = getIt<CurrentUserResolver>();
    final userId = await resolver.resolveUserId();
    if (!mounted) return;
    if (userId != null) setState(() => _currentUserId = userId);
    await widget.lobbyCubit.initLobbyState(widget.lobbyId, userId ?? '');
    if (!mounted) return;
    // Load share-info + sent invites song song (best-effort, không block UI).
    _loadShareSection();
  }

  /// Fetch share-info + pending outgoing invites cho LobbyShareSection.
  /// Chạy best-effort: nếu fail thì fallback về lobby.inviteCode (nếu có)
  /// + list rỗng cho pending invites.
  Future<void> _loadShareSection() async {
    final remote = sl<LobbyRemoteDatasource>();
    final results = await Future.wait([
      remote.getShareInfo(widget.lobbyId),
      remote.getAllInvites(LobbyInviteStatus.pending),
    ]);
    if (!mounted) return;

    final shareResult = results[0];
    final invitesResult = results[1];

    String? code;
    bool isPrivate = _isPrivate;
    final shareVal = shareResult.fold<dynamic>(
      (_) => null,
      (info) => info,
    );
    if (shareVal is LobbyShareInfo) {
      code = shareVal.shareCode;
      isPrivate = shareVal.isPrivate;
    } else {
      // fallback: dùng inviteCode từ LobbyEntity nếu có
      final cached = _lastGoodLobbyState;
      final lobby = cached is LobbyCreated
          ? cached.lobby
          : cached is LobbyUpdatedRealtime
              ? cached.lobby
              : null;
      code = lobby?.inviteCode;
    }

    final pending = <LobbyInviteEntity>[];
    final invitesVal = invitesResult.fold<dynamic>(
      (_) => null,
      (list) => list,
    );
    if (invitesVal is List<LobbyInviteEntity>) {
      final userId = _currentUserId ?? '';
      pending.addAll(
        invitesVal.where((inv) =>
            inv.lobbyId == widget.lobbyId &&
            inv.status == LobbyInviteStatus.pending &&
            (userId.isEmpty || inv.inviterId == userId)),
      );
    }

    if (!mounted) return;
    setState(() {
      _shareCode = code;
      _isPrivate = isPrivate;
      _sentPendingInvites = pending;
    });
  }

  /// Cancel 1 invite đã gửi. Trả về true nếu thành công.
  Future<bool> _cancelSentInvite(String inviteId) async {
    final remote = sl<LobbyRemoteDatasource>();
    final result = await remote.cancelInvite(inviteId);
    return result.fold(
      (_) => false,
      (_) {
        if (!mounted) return true;
        setState(() {
          _sentPendingInvites =
              _sentPendingInvites.where((i) => i.inviteId != inviteId).toList();
        });
        return true;
      },
    );
  }

  void _loadChatMessages() {
    if (!_chatLoaded) {
      _chatLoaded = true;
      widget.lobbyCubit.loadChatMessages(widget.lobbyId);
    }
  }

  void _sendChatMessage() {
    final content = _chatController.text.trim();
    if (content.isEmpty) return;
    widget.lobbyCubit.sendChatMessage(widget.lobbyId, content);
    _chatController.clear();
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  void _showInviteFriendsSheet(BuildContext context, LobbyEntity lobby) {
    widget.lobbyCubit.loadOnlineFriends();
    // Fetch outgoing pending invites từ server để build
    // `_serverInvitedFriendIds` — đảm bảo nút "Đã mời" hiển thị đúng
    // ngay cả khi user mở app mới hoặc mở sheet sau khi reload.
    // Đây là fire-and-forget — không block việc show sheet; UI sẽ
    // re-render khi set mới được build xong.
    _loadServerPendingInvites();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) => BlocProvider.value(
        value: widget.lobbyCubit,
        child: BlocListener<LobbyCubit, LobbyState>(
          listenWhen: (prev, current) =>
              current is LobbyUpdatedRealtime && prev is! LobbyUpdatedRealtime,
          listener: (sheetCtx, _) {
            if (Navigator.of(sheetCtx).canPop()) Navigator.of(sheetCtx).pop();
          },
          child: BlocBuilder<LobbyCubit, LobbyState>(
            builder: (sheetCtx, state) {
              if (state is LobbyFriendsLoaded) {
                // Union giữa local state (vừa mời thành công trong
                // session này) + server state (đã pending từ trước) →
                // disable cả những tile mà user đã mời trước khi reload.
                final allInvited = <String>{
                  ..._invitedFriendIds,
                  ..._serverInvitedFriendIds,
                };
                return FriendsSheet(
                  state: state,
                  invitedFriendIds: allInvited,
                  onInvite: (friend) => _completeFriendAction(friend, lobby),
                  onAdd: (friend) => _completeAddFriendAction(friend, lobby),
                  onClose: () => Navigator.pop(sheetCtx),
                  showDevBadge: false,
                  sheetContext: sheetCtx,
                );
              }
              return SheetLoading(label: 'Đang tải danh sách bạn bè...');
            },
          ),
        ),
      ),
    );
  }

  /// Gọi `GET /api/v1/lobbies/invites/me?status=Pending` rồi filter ra
  /// các invite mà:
  /// - `lobbyId == widget.lobbyId` (chỉ quan tâm lobby hiện tại)
  /// - `status == pending` (chưa bị accept/decline/cancel/expire)
  /// - `inviterId == currentUserId` (outgoing — do user hiện tại gửi)
  ///
  /// Kết quả là `Set<inviteeId>` dùng để đánh dấu tile "Đã mời" trong
  /// FriendsSheet — phản ánh đúng trạng thái server-side.
  Future<void> _loadServerPendingInvites() async {
    final remote = sl<LobbyRemoteDatasource>();
    final result = await remote.getAllInvites(LobbyInviteStatus.pending);
    if (!mounted) return;
    result.fold(
      (_) {
        // Lỗi → giữ set rỗng, UI sẽ chỉ dựa vào local state. Không show
        // snackbar lỗi vì đây là best-effort refresh.
      },
      (invites) {
        if (!mounted) return;
        final currentUserId = _currentUserId;
        final lobbyId = widget.lobbyId;
        final newSet = <String>{
          for (final inv in invites)
            if (inv.lobbyId == lobbyId &&
                (currentUserId == null || inv.inviterId == currentUserId))
              inv.inviteeId,
        };
        setState(() {
          _serverInvitedFriendIds
            ..clear()
            ..addAll(newSet);
        });
      },
    );
  }

  Future<void> _completeFriendAction(
    FriendEntity friend,
    LobbyEntity lobby,
  ) async {
    final result = await widget.lobbyCubit.inviteFriend(
      widget.lobbyId,
      friend.odId,
    );

    if (!mounted) return;

    // Capture `context` reference trước khi dùng trong callback — vì
    // đã `await` ở trên, cần guard lại `mounted` (lint rule).
    final overlayContext = context;

    result.fold(
      (failure) {
        final msg = failure.message.isEmpty
            ? 'Không gửi được lời mời. Vui lòng thử lại.'
            : 'Không gửi được lời mời: ${failure.message}';
        if (!mounted) return;
        overlayContext.showTopSnackBar(msg, isError: true);
      },
      (_) {
        if (!mounted) return;
        // Đánh dấu friend này đã mời → tile sẽ disable nút "Mời"
        // (đổi thành "Đã mời" + icon check) mà user vẫn còn trong sheet.
        setState(() => _invitedFriendIds.add(friend.odId));
        overlayContext.showTopSnackBar(
          'Đã gửi lời mời đến ${friend.username}',
        );
        // Refresh sent pending invites để LobbyShareSection hiển thị
        // invite vừa gửi.
        _loadShareSection();
      },
    );
  }

  void _completeAddFriendAction(FriendEntity friend, LobbyEntity lobby) {
    widget.lobbyCubit.simulateAddFriend(widget.lobbyId, friend.odId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã thêm ${friend.username} vào phòng')),
    );
  }

  void _shareInviteCode(BuildContext context, String? code) {
    if (code == null) return;
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Mã phòng $code đã được sao chép!'),
        action: SnackBarAction(label: 'OK', onPressed: () {}),
      ),
    );
  }

  void _showDismissDialog(BuildContext context, LobbyDismissed state) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLgAll),
        icon: Icon(
          AppIcons.warning,
          size: AppIcons.massive,
          color: AppColors.warning,
        ),
        title: Text(state.title),
        content: Text(state.message),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(dialogContext).popUntil((route) => route.isFirst);
            },
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }

  void _showDissolvedSnackBar(BuildContext context, LobbyDissolved state) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Phòng chờ đã được giải tán và xoá khỏi hệ thống.'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        duration: const Duration(seconds: 3),
      ),
    );
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: widget.lobbyCubit),
        BlocProvider<LobbyReservationCubit>(
          create: (_) {
            final cubit = getIt<LobbyReservationCubit>();
            // Start watching với reservationId từ lastGood state (nếu có)
            // — sẽ được update khi lobby state load xong.
            final cached = _lastGoodLobbyState;
            final cachedLobby = cached is LobbyCreated
                ? cached.lobby
                : cached is LobbyUpdatedRealtime
                    ? cached.lobby
                    : null;
            cubit.startWatching(reservationId: cachedLobby?.reservationId);
            return cubit;
          },
        ),
        BlocProvider<BookingRealtimeCubit>(
          create: (_) => getIt<BookingRealtimeCubit>(),
        ),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<LobbyCubit, LobbyState>(
            listener: (context, state) {
              if (state is LobbyDismissed) _showDismissDialog(context, state);
              if (state is LobbyDissolved) _showDissolvedSnackBar(context, state);
              if (state is LobbyChatLoaded) {
                setState(() {
                  _chatMessages.clear();
                  _chatMessages.addAll(state.messages);
                });
              }
              if (state is LobbyChatError) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(state.message)));
              }
              if (state is LobbyFailure) {
                debugPrint(
                  '[LobbyPage] LobbyFailure received: ${state.message} '
                  '(ignored in build; UI already handled in action handler)',
                );
              }
              // Khi lobby load/realtime update → sync reservation watcher
              // để fetch reservation detail + start poll.
              if (state is LobbyCreated || state is LobbyUpdatedRealtime) {
                final lobby = state is LobbyCreated
                    ? state.lobby
                    : (state as LobbyUpdatedRealtime).lobby;
                // Restart watch với reservationId mới (nếu đổi so với trước).
                final reservationCubit = context.read<LobbyReservationCubit>();
                reservationCubit.startWatching(
                  reservationId: lobby.reservationId,
                );

                // Bind BookingRealtime để đón check-in/check-out events.
                _bindBookingRealtime(lobby.reservationId);
              }
            },
          ),
          BlocListener<BookingRealtimeCubit, BookingRealtimeState>(
            listener: (context, state) async {
              if (state is BookingCheckedInEvent) {
                final userId = _currentUserId;
                if (userId != null && userId.isNotEmpty) {
                  setState(() {
                    _arrivalByUserId[userId] = MemberArrivalStatus.checkedIn;
                  });
                }
                if (!mounted) return;
                context.showTopSnackBar(
                  'Bạn đã check-in! Phiên chơi bắt đầu.',
                );
              } else if (state is BookingCheckedOutEvent) {
                final lobby = _currentLobby();
                if (lobby != null &&
                    lobby.hostId != (_currentUserId ?? '') &&
                    _currentBookingId != null) {
                  await _showRatingFormAfterCheckout(_currentBookingId!);
                }
              } else if (state is LobbyAutoCancelledState) {
                if (!mounted) return;
                context.showTopSnackBar(
                  'Phòng chờ đã bị huỷ: ${state.reason}',
                  isError: true,
                );
              }
            },
          ),
          BlocListener<LobbyReservationCubit, LobbyReservationState>(
            listener: (context, state) {
              if (state is LobbyReservationLoaded) {
                final reservation = state.reservation;
                if (reservation.status == res.ReservationStatus.checkedIn &&
                    _sessionStatus == null) {
                  _bindBookingRealtime(reservation.id);
                }
              }
            },
          ),
        ],
        child: BlocConsumer<LobbyCubit, LobbyState>(
        listener: (context, state) {
          // LobbyCubit listener xử lý trong MultiBlocListener ở trên.
        },
        buildWhen: (previous, current) =>
            current is! LobbyFriendsLoaded &&
            current is! LobbySimulateFriendsLoaded &&
            current is! LobbyChatLoaded &&
            current is! LobbyChatError,
        builder: (context, state) {
          if (state is LobbyLoading) return const LobbyLoadingScaffold();

          if (state is LobbyCreated) {
            _lastGoodLobbyState = state;
          } else if (state is LobbyUpdatedRealtime) {
            _lastGoodLobbyState = state;
          } else if (state is LobbyEnded) {
            _lastGoodLobbyState = state;
          }

          if (state is LobbyFailure && _lastGoodLobbyState != null) {
            final cached = _lastGoodLobbyState!;
            if (cached is LobbyCreated) {
              return _buildLobbyView(context, cached.lobby);
            }
            if (cached is LobbyUpdatedRealtime) {
              return _buildLobbyView(context, cached.lobby);
            }
            if (cached is LobbyEnded) {
              return LobbyEndedView(
                lobby: cached.lobby,
                currentUserId: _currentUserId ?? '',
                onDissolve: () => _onDissolveEndedLobby(cached.lobby),
                onRecreate: () => _onRecreateEndedLobby(cached.lobby),
                onExtend: () => _onExtendEndedLobby(cached.lobby),
                onShowDetails: () => _showLobbyDetails(context, cached.lobby),
                onRate: cached.lobby.status == LobbyStatus.closed
                    ? () => _onRateLobby(cached.lobby)
                    : null,
              );
            }
          }

          if (state is LobbyFailure) {
            return LobbyFailureScaffold(
              message: state.message,
              onRetry: () => widget.lobbyCubit.joinLobby(widget.lobbyId, null),
            );
          }
          if (state is LobbyEnded) {
            return LobbyEndedView(
              lobby: state.lobby,
              currentUserId: _currentUserId ?? '',
              onDissolve: () => _onDissolveEndedLobby(state.lobby),
              onRecreate: () => _onRecreateEndedLobby(state.lobby),
              onExtend: () => _onExtendEndedLobby(state.lobby),
              onShowDetails: () => _showLobbyDetails(context, state.lobby),
              onRate: state.lobby.status == LobbyStatus.closed
                  ? () => _onRateLobby(state.lobby)
                  : null,
            );
          }

          final lobby = state is LobbyCreated
              ? state.lobby
              : state is LobbyUpdatedRealtime
                  ? state.lobby
                  : null;

          if (lobby == null) return const LobbyLoadingScaffold();
          _loadChatMessages();
          return _buildLobbyView(context, lobby);
        },
      ),
      ),
    );
  }

  Future<void> _onDissolveEndedLobby(LobbyEntity lobby) async {
    await widget.lobbyCubit.dissolveLobby(lobby.id);
  }

  Future<void> _onRecreateEndedLobby(LobbyEntity lobby) async {
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Vào "Phòng chờ" → bấm "Tạo phòng" để tạo lobby mới.'),
        duration: Duration(seconds: 4),
      ),
    );
  }

  Future<void> _onExtendEndedLobby(LobbyEntity lobby) =>
      _onRecreateEndedLobby(lobby);

  Future<void> _onRateLobby(LobbyEntity lobby) async {
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (_) => LobbyRatingPage(
          lobbyId: lobby.id,
          reservationId: lobby.reservationId,
        ),
      ),
    );
  }

  Future<bool> _confirmDissolveActive(BuildContext context) async {
    final colors = Theme.of(context).colorScheme;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLgAll),
        icon: Icon(
          AppIcons.delete,
          size: AppIcons.massive,
          color: colors.error,
        ),
        title: const Text('Giải tán phòng chờ?'),
        content: const Text(
          'Phòng chờ sẽ bị xoá vĩnh viễn khỏi hệ thống. '
          'Tất cả tin nhắn, lời mời và báo cáo cũng sẽ bị xoá. '
          'Bạn không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colors.error,
              foregroundColor: colors.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Giải tán'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Xác nhận trước khi user bấm "Rời phòng".
  ///
  /// Hành vi: chỉ **pop UI** (đưa user ra MainScaffold) — KHÔNG gọi
  /// bất kỳ API nào. User vẫn là member của lobby và có thể vào lại
  /// bất cứ lúc nào qua tab "Đang tham gia".
  Future<bool> _confirmLeaveLobby(BuildContext context) async {
    final colors = Theme.of(context).colorScheme;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLgAll),
        icon: Icon(
          AppIcons.logout,
          size: AppIcons.massive,
          color: colors.primary,
        ),
        title: const Text('Rời phòng chờ?'),
        content: const Text(
          'Bạn sẽ thoát khỏi màn hình phòng chờ và có thể dùng các '
          'tính năng khác của app. Bạn vẫn là thành viên và có thể quay '
          'lại bất cứ lúc nào qua tab "Đang tham gia".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Ở lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Rời phòng'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Xác nhận trước khi host bấm "Huỷ phòng".
  ///
  /// Hành vi: gọi `POST /api/v1/lobbies/{id}/close` — status = Closed,
  /// không thể join lại. Đây là action thật sự đóng lobby (khác với
  /// "Rời phòng" chỉ pop UI). Icon + màu đỏ để phân biệt rõ với nút
  /// "Rời phòng" (icon logout, màu primary).
  Future<bool> _confirmCancelLobby(BuildContext context) async {
    final colors = Theme.of(context).colorScheme;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLgAll),
        icon: Icon(
          AppIcons.cancelBooking,
          size: AppIcons.massive,
          color: colors.error,
        ),
        title: const Text('Huỷ phòng chờ?'),
        content: const Text(
          'Phòng chờ sẽ được đóng và chuyển sang trạng thái "Đã đóng". '
          'Các thành viên khác sẽ không thể tham gia lại. '
          'Bạn có chắc chắn muốn huỷ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Không'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colors.error,
              foregroundColor: colors.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Huỷ phòng'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _onDissolveActiveLobby(LobbyEntity lobby) async {
    final confirmed = await _confirmDissolveActive(context);
    if (!confirmed || !mounted) return;
    await widget.lobbyCubit.dissolveLobby(lobby.id);
  }

  Widget _buildLobbyView(BuildContext context, LobbyEntity lobby) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isHost = lobby.hostId == (_currentUserId ?? '');
    final showDissolve = isHost && lobby.status.canDissolve;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── AppBar ─────────────────────────────────────────────────────
          SliverAppBar(
            floating: true,
            pinned: true,
            expandedHeight: 0,
            title: Text(
              lobby.gameName,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            actions: [
              if (showDissolve)
                IconButton(
                  tooltip: 'Giải tán phòng',
                  icon: Icon(AppIcons.delete, color: colors.error),
                  onPressed: () => _onDissolveActiveLobby(lobby),
                ),
              IconButton(
                tooltip: 'Chi tiết phòng',
                icon: Icon(AppIcons.info, color: colors.onSurfaceVariant),
                onPressed: () => _showLobbyDetails(context, lobby),
              ),
            ],
          ),

          // ── Hero Header ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: LobbyHeroHeader(
              lobby: lobby,
              theme: theme,
              onShareInviteCode: () =>
                  _shareInviteCode(context, lobby.inviteCode),
            ),
          ),

          // ── Phase A: Status strip (badge + countdown + check-in section) ─
          SliverToBoxAdapter(
            child: BlocBuilder<LobbyReservationCubit, LobbyReservationState>(
              builder: (context, reservationState) {
                return _LobbyStatusStrip(
                  lobby: lobby,
                  reservationState: reservationState,
                  currentUserId: _currentUserId ?? '',
                  arrivalByUserId: _arrivalByUserId,
                );
              },
            ),
          ),

          // ── Players Section ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: PlayersSection(
              lobby: lobby,
              currentUserId: _currentUserId ?? '',
              onInvite: () => _showInviteFriendsSheet(context, lobby),
              onToggleReady: (isReady) async {
                // Gọi cubit.setReady — UI sẽ tự rebuild khi state đổi
                // (cubit đã emit LobbyReadyStatusChanged).
                await widget.lobbyCubit.setReady(
                  lobby.id,
                  isReady: isReady,
                );
              },
              onFullGuidanceSecondary: () =>
                  _showLobbyDetails(context, lobby),
            ),
          ),

          // ── Share & Invites Section ─────────────────────────────────────
          SliverToBoxAdapter(
            child: LobbyShareSection(
              lobbyId: widget.lobbyId,
              currentUserId: _currentUserId ?? '',
              shareCode: _shareCode ?? lobby.inviteCode,
              isPrivate: _isPrivate,
              pendingInvites: _sentPendingInvites,
              onCancelInvite: _cancelSentInvite,
              onRefresh: _loadShareSection,
              onInviteFriends: () =>
                  LobbyInvitableFriendsSheet.show(context, widget.lobbyId),
            ),
          ),

          // ── Chat Section ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: LobbyChatSection(
              controller: _chatController,
              messages: _chatMessages,
              currentUserId: _currentUserId ?? '',
              onSend: _sendChatMessage,
            ),
          ),

          // ── Bottom padding for safe area ────────────────────────────────
          const SliverToBoxAdapter(child: SizedBox(height: 160)),
        ],
      ),

      // ── Bottom Action Bar ───────────────────────────────────────────
      bottomNavigationBar: LobbyBottomBar(
        onLeave: () async {
          // "Rời phòng" chỉ pop UI — KHÔNG gọi API. User vẫn là member
          // của lobby, có thể vào lại bất cứ lúc nào qua tab "Đang tham gia".
          // Trước đây code này gọi `lobbyCubit.leaveLobby(...)` (POST /leave)
          // → với host, server tự chuyển status thành `HostCancelled`,
          // khiến mọi join về sau đều trả 409.
          final confirmed = await _confirmLeaveLobby(context);
          if (!confirmed || !mounted) return;
          if (!context.mounted) return;
          // Về thẳng MainScaffold — pop toàn bộ stack trung gian (vd: nếu
          // user vào lobby từ flow đặt cọc / browse, các page trước đó
          // đã stale). Tránh rơi lại vào tab "Đặt cọc" của LobbyConfigPage
          // cũ với data lobby cũ.
          Navigator.of(context, rootNavigator: true).popUntil(
            (route) => route.isFirst,
          );
        },
        onCancel: isHost
            ? () async {
                // "Huỷ phòng" — chỉ host, gọi API /close để đóng lobby.
                // Tách riêng khỏi "Rời phòng" để tránh nhầm lẫn nghiệp vụ.
                final confirmed = await _confirmCancelLobby(context);
                if (!confirmed || !mounted) return;
                await widget.lobbyCubit.closeLobby(widget.lobbyId);
              }
            : null,
      ),
    );
  }

  void _showLobbyDetails(BuildContext context, LobbyEntity lobby) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => LobbyDetailsSheet(lobby: lobby),
    );
  }

  /// Bind BookingRealtimeCubit cho 1 reservationId. Idempotent — chỉ
  /// connect nếu id thay đổi hoặc chưa bind.
  void _bindBookingRealtime(String? reservationId) {
    if (reservationId == null || reservationId.isEmpty) return;
    if (_currentBookingId == reservationId) return;
    _currentBookingId = reservationId;
    final cubit = context.read<BookingRealtimeCubit>();
    cubit.watchBooking(reservationId);
  }

  /// Lấy lobby hiện tại từ `_lastGoodLobbyState`.
  LobbyEntity? _currentLobby() {
    final s = _lastGoodLobbyState;
    if (s is LobbyCreated) return s.lobby;
    if (s is LobbyUpdatedRealtime) return s.lobby;
    if (s is LobbyEnded) return s.lobby;
    return null;
  }

  /// Auto-trigger RatingFormSheet khi nhận BookingCheckedOut event. Kiểm
  /// tra rating status trước để tránh mở sheet 2 lần.
  Future<void> _showRatingFormAfterCheckout(String bookingId) async {
    final repo = getIt<BookingRepository>();
    final statusResult = await repo.getRatingStatus(bookingId);
    if (!mounted) return;
    statusResult.fold((_) => null, (status) async {
      if (!mounted) return;
      if (!status.canRate || status.alreadyRated) return;
      if (!mounted) return;
      final detailResult = await repo.getBookingById(bookingId);
      if (!mounted) return;
      detailResult.fold(
        (_) => null,
        (booking) async {
          if (!mounted) return;
          await showModalBottomSheet<RatingSubmissionResultEntity>(
            context: context,
            isScrollControlled: true,
            builder: (_) => RatingFormSheet(
              booking: booking,
              ratingStatus: status,
              repository: repo,
            ),
          );
        },
      );
    });
  }
}

/// Players section — header + player grid + invite button.
class PlayersSection extends StatelessWidget {
  final LobbyEntity lobby;
  final String currentUserId;
  final VoidCallback onInvite;

  /// Optional callback khi player bấm CTA chính trong banner "Phòng đầy".
  /// Hiện tại không sử dụng (banner dùng `onToggleReady` thay thế), giữ để
  /// tương thích ngược.
  final VoidCallback? onFullGuidancePrimary;

  /// Optional callback khi player bấm "Chi tiết" trong banner.
  final VoidCallback? onFullGuidanceSecondary;

  /// Callback toggle Ready/Unready — được gọi khi user bấm nút "Sẵn sàng".
  /// Implement ở `LobbyPage` (nơi có `widget.lobbyCubit.setReady`).
  final Future<void> Function(bool isReady)? onToggleReady;

  const PlayersSection({
    super.key,
    required this.lobby,
    required this.currentUserId,
    required this.onInvite,
    this.onFullGuidancePrimary,
    this.onFullGuidanceSecondary,
    this.onToggleReady,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xxs),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: AppRadius.radiusXxsAll,
                ),
                child: Icon(
                  AppIcons.users,
                  size: AppIcons.sm,
                  color: colors.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Thành viên (${lobby.currentPlayers}/${lobby.maxPlayers})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              InviteButton(onTap: onInvite),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Player grid
          LobbyPlayerGrid(
            players: lobby.players,
            maxSlots: lobby.maxPlayers,
            currentUserId: currentUserId,
          ),

          // Banner hướng dẫn khi lobby đầy — chỉ hiện nếu currentPlayers ==
          // maxPlayers và lobby chưa kết thúc. Banner đã có sẵn nút
          // "Sẵn sàng" cho cả host và member.
          LobbyFullGuidanceBanner(
            lobby: lobby,
            currentUserId: currentUserId,
            onToggleReady: onToggleReady,
            onSecondaryAction: onFullGuidanceSecondary,
          ),
        ],
      ),
    );
  }
}

/// Nút "Mời bạn" trong players section.
class InviteButton extends StatelessWidget {
  final VoidCallback onTap;

  const InviteButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.primaryContainer,
      borderRadius: AppRadius.radiusSmAll,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.radiusSmAll,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                AppIcons.userAdd,
                size: 16,
                color: colors.onPrimaryContainer,
              ),
              const SizedBox(width: 4),
              Text(
                'Mời bạn',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colors.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Strip trạng thái lobby + countdown + check-in section — Phase A.
///
/// Hiển thị tuần tự:
/// 1. [LobbyStatusBadge] — variant resolve từ (lobby.status, reservation.status).
/// 2. [ScheduledTimeCountdown] — đếm ngược tới `lobby.scheduledTime` (giờ chơi).
/// 3. [LobbyCheckInSection] — chỉ khi `reservation.status == confirmed` và
///    lobby đang trong phase check-in (Viable/Full/InProgress).
///
/// Dùng `BlocBuilder` trong parent, không fetch gì thêm.
class _LobbyStatusStrip extends StatelessWidget {
  final LobbyEntity lobby;
  final LobbyReservationState reservationState;
  final String currentUserId;
  final Map<String, MemberArrivalStatus> arrivalByUserId;

  const _LobbyStatusStrip({
    required this.lobby,
    required this.reservationState,
    required this.currentUserId,
    required this.arrivalByUserId,
  });

  res.ReservationEntity? get _reservation {
    final s = reservationState;
    if (s is LobbyReservationLoaded) return s.reservation;
    return null;
  }

  void _openPendingApproval(BuildContext context) {
    final reservation = _reservation;
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => LobbyPendingCafeApprovalPage(
          reservationId: reservation?.id ?? lobby.reservationId ?? '',
          cafeId: lobby.cafeId,
          cafeName: lobby.cafeName,
          cafeApprovalDeadline: reservation?.cafeApprovalDeadline,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reservation = _reservation;
    final isHost = lobby.hostId == currentUserId;

    // ── Badge ────────────────────────────────────────────────────────────
    final variant = resolveBadgeVariant(
      lobbyStatus: lobby.status,
      reservationStatus: reservation?.status,
    );

    // Chỉ show countdown tới scheduledTime khi lobby chưa ở terminal.
    final showCountdown = !lobby.status.isTerminal;

    // ── Check-in section: confirmed + lobby canCheckIn ───────────────────
    final showCheckIn = reservation != null &&
        reservation.status == res.ReservationStatus.confirmed &&
        lobby.status.canCheckIn;

    // ── Pending cafe approval banner — Phase B ──────────────────────────
    final showPendingCafeBanner = lobby.status.isPendingCafeApproval &&
        reservation != null &&
        reservation.status == res.ReservationStatus.holding;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Badge
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            0,
          ),
          child: Row(
            children: [
              LobbyStatusBadge(variant: variant),
              if (reservationState is LobbyReservationLoading) ...[
                const SizedBox(width: AppSpacing.sm),
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ],
          ),
        ),

        // Countdown tới scheduledTime
        if (showCountdown)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              0,
            ),
            child: ScheduledTimeCountdown(
              scheduledTime: lobby.scheduledTime,
              title: isHost ? 'Giờ bắt đầu (cả nhóm)' : 'Giờ chơi',
              subtitle: lobby.cafeName,
              accentColor: AppColors.primary,
            ),
          ),

        // Pending cafe approval banner — Phase B
        if (showPendingCafeBanner)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              0,
            ),
            child: _PendingCafeApprovalCard(
              reservation: reservation,
              onOpen: () => _openPendingApproval(context),
            ),
          ),

        // Check-in section — chỉ host/member thấy khi đã confirmed.
        if (showCheckIn)
          LobbyCheckInSection(
            reservation: reservation,
            isHost: isHost,
            lobbyStatus: _mapLobbyStatus(lobby.status),
            playStartedAt: lobby.playStartedAt,
            currentUserId: currentUserId,
            arrivalByUserId: arrivalByUserId,
            lobbyPlayers: lobby.players,
          ),
      ],
    );
  }
}

/// Banner ngắn gọn cho lobby `pendingCafeApproval`. CTA mở
/// `LobbyPendingCafeApprovalPage` (full countdown + cancel button).
class _PendingCafeApprovalCard extends StatelessWidget {
  final res.ReservationEntity reservation;
  final VoidCallback onOpen;

  const _PendingCafeApprovalCard({
    required this.reservation,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final deadline = reservation.cafeApprovalDeadline;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.10),
        borderRadius: AppRadius.radiusLgAll,
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.20),
              borderRadius: AppRadius.radiusMdAll,
            ),
            child: Icon(
              Icons.hourglass_top,
              color: AppColors.warning,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Đang chờ quán duyệt',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  reservation.cafeName.isEmpty
                      ? 'Phòng chờ sẽ mở khi quán duyệt.'
                      : '${reservation.cafeName} sẽ duyệt trong 24h.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                if (deadline != null) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    'Hạn: ${deadline.toLocal()}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            tooltip: 'Xem chi tiết',
            onPressed: onOpen,
            icon: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }
}

/// Map [LobbyStatus] (lobby_management entity) sang [res.LobbyStatus]
/// (reservation entity) — 2 enum có overlap nhưng tách rời để tránh coupling.
/// Helper này giúp `LobbyCheckInSection` (đang dùng `as res`) nhận đúng enum.
res.LobbyStatus _mapLobbyStatus(LobbyStatus s) {
  switch (s) {
    case LobbyStatus.pendingActivation:
      return res.LobbyStatus.pendingActivation;
    case LobbyStatus.pendingCafeApproval:
      return res.LobbyStatus.pendingCafeApproval;
    case LobbyStatus.open:
      return res.LobbyStatus.open;
    case LobbyStatus.viable:
      return res.LobbyStatus.viable;
    case LobbyStatus.full:
      return res.LobbyStatus.full;
    case LobbyStatus.inProgress:
      return res.LobbyStatus.inProgress;
    case LobbyStatus.ratingOpen:
      return res.LobbyStatus.closed; // ratingOpen → closed (terminal) ở enum res
    case LobbyStatus.closed:
      return res.LobbyStatus.closed;
    case LobbyStatus.timeoutFailed:
      return res.LobbyStatus.timeoutFailed;
    case LobbyStatus.hostCancelled:
      return res.LobbyStatus.hostCancelled;
    case LobbyStatus.rejectedByCafe:
      return res.LobbyStatus.rejectedByCafe;
    case LobbyStatus.expiredByCafe:
      return res.LobbyStatus.expiredByCafe;
  }
}
