import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:boardverse/core/theme/theme.dart';
import 'package:boardverse/core/widgets/top_snack_bar.dart';
import '../cubit/lobby_invite_cubit.dart';
import '../cubit/lobby_invite_state.dart';
import '../widgets/lobby_invite_card.dart';
import '../widgets/lobby_list_shimmer.dart';

class LobbyInvitesPage extends StatefulWidget {
  final LobbyInviteCubit lobbyInviteCubit;
  final void Function(String lobbyId)? onJoinLobby;

  const LobbyInvitesPage({
    super.key,
    required this.lobbyInviteCubit,
    this.onJoinLobby,
  });

  @override
  State<LobbyInvitesPage> createState() => _LobbyInvitesPageState();
}

class _LobbyInvitesPageState extends State<LobbyInvitesPage> {
  /// Mỗi lần widget mount:
  /// - Nếu cubit state đang là `LobbyInviteInitial` (chưa load lần nào) →
  ///   trigger `loadPendingInvites()` để hiển thị danh sách ngay khi mở
  ///   trang.
  /// - Nếu state khác Initial (đã load từ trước — vd khi user back vào từ
  ///   lobby detail rồi mở lại inbox) → giữ nguyên data, không refetch để
  ///   tránh flash loading không cần thiết.
  ///
  /// Vì `BlocProvider.create: ... ..loadPendingInvites()` ở router chỉ
  /// cascade gọi 1 lần duy nhất khi widget được mount, nhưng cubit singleton
  /// có thể đã emit `Initial` do state bị reset khi 1 widget scope khác
  /// (`LobbyHubActions` chẳng hạn) cũng trigger rebuild BlocProvider cùng
  /// key → bloc vẫn provide cùng cubit instance với state Initial → user
  /// phải bấm nút reload. Fix bằng cách check state ngay tại `initState`
  /// của page để bảo đảm luôn fetch khi mở lần đầu.
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Chỉ trigger khi cubit chưa có dữ liệu (state khác Loaded/ActionLoading
      // thực sự có data). Tránh gọi lại khi state là Loaded thực sự (user đã
      // load từ trước qua hub) → tránh flash shimmer không cần thiết.
      final current = widget.lobbyInviteCubit.state;
      if (current is LobbyInviteInitial || current is LobbyInviteEmpty) {
        widget.lobbyInviteCubit.loadPendingInvites();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.lobbyInviteCubit,
      child: BlocConsumer<LobbyInviteCubit, LobbyInviteState>(
        listener: _onStateChanged,
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Lời mời tham gia'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => widget.lobbyInviteCubit.refresh(),
                ),
              ],
            ),
            body: _buildBody(context, state),
          );
        },
      ),
    );
  }

  void _onStateChanged(BuildContext context, LobbyInviteState state) {
    // Tất cả thông báo accept/decline/cancel/error dùng top snackbar
    // (slide-in từ đầu màn hình) để đồng bộ với design system + các
    // flow khác trong app (vd: BookingRealtime, LobbyReservation,
    // lobby share invite). Bottom SnackBar mặc định hay che nội
    // dung quan trọng trong các sheet có scroll dọc.
    if (state is LobbyInviteAccepted) {
      context.showTopSnackBar('Đã tham gia phòng!');
      widget.onJoinLobby?.call(state.lobbyId);
    } else if (state is LobbyInviteDeclined) {
      context.showTopSnackBar('Đã từ chối lời mời');
      widget.lobbyInviteCubit.loadPendingInvites();
    } else if (state is LobbyInviteCancelled) {
      context.showTopSnackBar('Đã hủy lời mời');
      widget.lobbyInviteCubit.loadAllInvites();
    } else if (state is LobbyInviteError) {
      context.showTopSnackBar(state.message, isError: true);
    }
  }

  Widget _buildBody(BuildContext context, LobbyInviteState state) {
    if (state is LobbyInviteLoading) {
      return const LobbyInvitesShimmer();
    }

    if (state is LobbyInviteEmpty) {
      return _EmptyState();
    }

    if (state is LobbyInviteError && state.pendingInvites.isEmpty) {
      return _ErrorState(
        message: state.message,
        onRetry: () => widget.lobbyInviteCubit.loadPendingInvites(),
      );
    }

    // Xử lý `LobbyInviteInitial`: nếu cubit chưa load lần nào → hiển thị
    // shimmer (chứ không phải EmptyState) để báo cho user biết đang load.
    // Tránh trường hợp "lần đầu mở thấy trống trơn" gây hiểu nhầm.
    if (state is LobbyInviteInitial) {
      return const LobbyInvitesShimmer();
    }

    // Get invites from state
    final invites = _getInvites(state);

    if (invites.isEmpty) {
      return _EmptyState();
    }

    return RefreshIndicator(
      onRefresh: () => widget.lobbyInviteCubit.refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: invites.length,
        itemBuilder: (context, index) {
          final invite = invites[index];
          final isLoading =
              state is LobbyInviteActionLoading &&
                  state.inviteId == invite.inviteId;

          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: LobbyInviteCard(
              invite: invite,
              isInvitee: true,
              isLoading: isLoading,
              onAccept: () =>
                  widget.lobbyInviteCubit.acceptInvite(invite.inviteId),
              onDecline: () =>
                  widget.lobbyInviteCubit.declineInvite(invite.inviteId),
            ),
          );
        },
      ),
    );
  }

  List<dynamic> _getInvites(LobbyInviteState state) {
    if (state is LobbyInviteLoaded) {
      return state.pendingInvites;
    } else if (state is LobbyInviteActionLoading) {
      return state.pendingInvites;
    } else if (state is LobbyInviteError) {
      return state.pendingInvites;
    }
    return [];
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.mail_outline, size: 80, color: colors.outline),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Không có lời mời nào',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Lời mời tham gia lobby sẽ xuất hiện ở đây',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: colors.error),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Đã xảy ra lỗi',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
