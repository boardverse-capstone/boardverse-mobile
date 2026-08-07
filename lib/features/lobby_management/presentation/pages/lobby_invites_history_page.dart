import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/top_snack_bar.dart';
import '../../domain/entities/lobby_invite_entity.dart';
import '../cubit/lobby_invites_history_cubit.dart';
import '../widgets/lobby_invite_card.dart';
import '../widgets/lobby_invites_shimmer.dart';

/// Trang lịch sử invite của 1 lobby — host/inviter xem "Lời mời tôi đã gửi".
///
/// Hỗ trợ tabs filter theo status (Tất cả/Đã gửi/Đã chấp nhận/Đã từ chối/Đã huỷ/Hết hạn)
/// + action Resend cho invite ở terminal state.
class LobbyInvitesHistoryPage extends StatelessWidget {
  /// Lobby ID để load history.
  final String lobbyId;

  /// Tên lobby (optional, hiển thị ở title).
  final String? lobbyName;

  const LobbyInvitesHistoryPage({
    super.key,
    required this.lobbyId,
    this.lobbyName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LobbyInvitesHistoryCubit>(
      create: (ctx) =>
          LobbyInvitesHistoryCubit(repository: ctx.read())
            ..loadHistory(lobbyId),
      child: _LobbyInvitesHistoryView(lobbyName: lobbyName),
    );
  }
}

class _LobbyInvitesHistoryView extends StatefulWidget {
  final String? lobbyName;
  const _LobbyInvitesHistoryView({this.lobbyName});

  @override
  State<_LobbyInvitesHistoryView> createState() =>
      _LobbyInvitesHistoryViewState();
}

class _LobbyInvitesHistoryViewState extends State<_LobbyInvitesHistoryView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  static const _filters = <_StatusFilter>[
    _StatusFilter(null, 'Tất cả'),
    _StatusFilter(LobbyInviteStatus.pending, 'Đã mời'),
    _StatusFilter(LobbyInviteStatus.accepted, 'Đã chấp nhận'),
    _StatusFilter(LobbyInviteStatus.declined, 'Đã từ chối'),
    _StatusFilter(LobbyInviteStatus.cancelled, 'Đã huỷ'),
    _StatusFilter(LobbyInviteStatus.expired, 'Hết hạn'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _filters.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final filter = _filters[_tabController.index].status;
        final cubit = context.read<LobbyInvitesHistoryCubit>();
        if (filter != cubit.state.statusFilter) {
          cubit.changeFilter(filter);
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Lời mời đã gửi',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            if (widget.lobbyName != null && widget.lobbyName!.isNotEmpty)
              Text(
                widget.lobbyName!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        actions: [
          BlocBuilder<LobbyInvitesHistoryCubit, LobbyInvitesHistoryState>(
            buildWhen: (a, b) =>
                a.invites.length != b.invites.length ||
                a.isRefreshing != b.isRefreshing,
            builder: (context, state) => IconButton(
              tooltip: 'Làm mới',
              icon: state.isRefreshing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(AppIcons.refresh),
              onPressed: state.isRefreshing
                  ? null
                  : () => context
                      .read<LobbyInvitesHistoryCubit>()
                      .refresh(),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: BlocBuilder<LobbyInvitesHistoryCubit, LobbyInvitesHistoryState>(
            buildWhen: (a, b) =>
                a.invites != b.invites || a.isRefreshing != b.isRefreshing,
            builder: (context, state) => Container(
              color: AppColors.surface,
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: Theme.of(context).colorScheme.primary,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                tabs: [
                  for (final f in _filters)
                    Tab(text: _buildTabLabel(f, state)),
                ],
              ),
            ),
          ),
        ),
      ),
      body: BlocConsumer<LobbyInvitesHistoryCubit, LobbyInvitesHistoryState>(
        listenWhen: (a, b) =>
            a.errorMessage != b.errorMessage && b.errorMessage != null,
        listener: (context, state) {
          context.showTopSnackBar(
            state.errorMessage ?? 'Có lỗi xảy ra',
            isError: true,
          );
          context.read<LobbyInvitesHistoryCubit>().clearError();
        },
        builder: (context, state) {
          if (state.isInitialLoading) {
            return const LobbyInvitesShimmer();
          }
          if (state.invites.isEmpty) {
            return _EmptyView(filter: state.statusFilter);
          }
          return RefreshIndicator(
            onRefresh: () =>
                context.read<LobbyInvitesHistoryCubit>().refresh(),
            color: Theme.of(context).colorScheme.primary,
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: state.invites.length,
              separatorBuilder: (_, _) => const SizedBox(
                height: AppSpacing.md,
              ),
              itemBuilder: (context, index) {
                final invite = state.invites[index];
                return LobbyInviteCard(
                  invite: invite,
                  isInvitee: false,
                  isLoading: state.actionInviteId == invite.inviteId,
                  onCancel: invite.status == LobbyInviteStatus.pending
                      ? () => _onCancel(context, invite)
                      : null,
                  onResend: invite.canResend
                      ? () => _onResend(context, invite)
                      : null,
                );
              },
            ),
          );
        },
      ),
    );
  }

  String _buildTabLabel(_StatusFilter f, LobbyInvitesHistoryState state) {
    final count = f.status == null
        ? state.invites.length
        : state.invites.where((i) => i.status == f.status).length;
    return '${f.label} ($count)';
  }

  Future<void> _onCancel(
    BuildContext context,
    LobbyInviteEntity invite,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Huỷ lời mời?'),
        content: Text(
          'Bạn có chắc muốn huỷ lời mời tới '
          '${invite.inviteeUsername ?? invite.inviteeId}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Không'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Huỷ lời mời'),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      final cubit = context.read<LobbyInvitesHistoryCubit>();
      final ok = await cubit.cancelInvite(invite.inviteId);
      if (!context.mounted) return;
      if (ok) {
        context.showTopSnackBar('Đã huỷ lời mời');
      }
    }
  }

  Future<void> _onResend(
    BuildContext context,
    LobbyInviteEntity invite,
  ) async {
    final cubit = context.read<LobbyInvitesHistoryCubit>();
    final ok = await cubit.resendInvite(invite.inviteId);
    if (!context.mounted) return;
    if (ok) {
      context.showTopSnackBar('Đã gửi lại lời mời');
    }
  }
}

class _StatusFilter {
  final LobbyInviteStatus? status;
  final String label;
  const _StatusFilter(this.status, this.label);
}

class _EmptyView extends StatelessWidget {
  final LobbyInviteStatus? filter;
  const _EmptyView({this.filter});

  @override
  Widget build(BuildContext context) {
    final message = filter == null
        ? 'Chưa có lời mời nào được gửi.'
        : 'Không có lời mời ở trạng thái "${_statusLabel(filter!)}".';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              AppIcons.inbox,
              size: 56,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(LobbyInviteStatus s) {
    switch (s) {
      case LobbyInviteStatus.pending:
        return 'đã gửi';
      case LobbyInviteStatus.accepted:
        return 'đã chấp nhận';
      case LobbyInviteStatus.declined:
        return 'đã từ chối';
      case LobbyInviteStatus.cancelled:
        return 'đã huỷ';
      case LobbyInviteStatus.expired:
        return 'hết hạn';
    }
  }
}