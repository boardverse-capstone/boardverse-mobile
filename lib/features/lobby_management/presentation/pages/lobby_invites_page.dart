import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/theme.dart';
import '../cubit/lobby_invite_cubit.dart';
import '../cubit/lobby_invite_state.dart';
import '../widgets/lobby_invite_card.dart';

class LobbyInvitesPage extends StatelessWidget {
  final LobbyInviteCubit lobbyInviteCubit;
  final void Function(String lobbyId)? onJoinLobby;

  const LobbyInvitesPage({
    super.key,
    required this.lobbyInviteCubit,
    this.onJoinLobby,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: lobbyInviteCubit,
      child: BlocConsumer<LobbyInviteCubit, LobbyInviteState>(
        listener: (context, state) {
          if (state is LobbyInviteAccepted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Đã tham gia phòng!'),
                backgroundColor: AppColors.success,
              ),
            );
            onJoinLobby?.call(state.lobbyId);
          } else if (state is LobbyInviteDeclined) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Đã từ chối lời mời')));
            lobbyInviteCubit.loadPendingInvites();
          } else if (state is LobbyInviteCancelled) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Đã hủy lời mời')));
            lobbyInviteCubit.loadAllInvites();
          } else if (state is LobbyInviteError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Lời mời tham gia'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => lobbyInviteCubit.refresh(),
                ),
              ],
            ),
            body: _buildBody(context, state),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, LobbyInviteState state) {
    if (state is LobbyInviteLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is LobbyInviteEmpty) {
      return _EmptyState();
    }

    if (state is LobbyInviteError && state.pendingInvites.isEmpty) {
      return _ErrorState(
        message: state.message,
        onRetry: () => lobbyInviteCubit.loadPendingInvites(),
      );
    }

    // Get invites from state
    final invites = _getInvites(state);

    if (invites.isEmpty) {
      return _EmptyState();
    }

    return RefreshIndicator(
      onRefresh: () => lobbyInviteCubit.refresh(),
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
              onAccept: () => lobbyInviteCubit.acceptInvite(invite.inviteId),
              onDecline: () => lobbyInviteCubit.declineInvite(invite.inviteId),
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
