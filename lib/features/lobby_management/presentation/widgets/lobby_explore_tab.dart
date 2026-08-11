import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_icons.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../domain/entities/lobby_entity.dart';
import '../cubit/lobby_search_cubit.dart';
import '../cubit/lobby_state.dart';
import 'lobby_card_base.dart';
import 'lobby_list_shimmer.dart';

/// Modern lobby explore tab với neo-brutalism cards.
class LobbyExploreTab extends StatelessWidget {
  final LobbySearchCubit searchCubit;
  final DateFormat timeFormatter;
  final void Function(LobbyEntity) onPreview;
  final void Function(LobbyEntity) onOpenOwned;
  final void Function(String, String?) onJoin;
  final VoidCallback onCreateLobby;
  final String? currentUserId;

  const LobbyExploreTab({
    super.key,
    required this.searchCubit,
    required this.timeFormatter,
    required this.onPreview,
    required this.onOpenOwned,
    required this.onJoin,
    required this.onCreateLobby,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LobbySearchCubit, LobbyState>(
      bloc: searchCubit,
      builder: (context, state) {
        if (state is LobbyListLoading) return const _LoadingView();
        if (state is LobbyFailure) {
          return _ErrorView(
            message: state.message,
            onRetry: () => searchCubit.loadDiscoverable(limit: 50),
          );
        }
        if (state is LobbyListEmpty ||
            (state is LobbyListLoaded && state.entities.isEmpty)) {
          return _EmptyExploreView(onCreateLobby: onCreateLobby);
        }
        if (state is LobbyListLoaded) {
          return _LobbyList(
            lobbies: state.entities,
            timeFormatter: timeFormatter,
            currentUserId: currentUserId,
            onPreview: onPreview,
            onOpenOwned: onOpenOwned,
            onJoin: onJoin,
            onRefresh: () => searchCubit.loadDiscoverable(limit: 50),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const LobbyInvitesShimmer(itemCount: 5);
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.error, width: 3),
              ),
              child: const Icon(AppIcons.error, size: 48, color: AppColors.error),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Đã xảy ra lỗi',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _NeoRetryButton(onTap: onRetry),
          ],
        ),
      ),
    );
  }
}

class _EmptyExploreView extends StatelessWidget {
  final VoidCallback onCreateLobby;

  const _EmptyExploreView({required this.onCreateLobby});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.border,
                  width: 3,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.black,
                    blurRadius: 0,
                    offset: Offset(5, 5),
                  ),
                ],
              ),
              child: const Icon(
                AppIcons.boardGame,
                size: 48,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Chưa có phòng chờ nào',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 20,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Hãy là người đầu tiên tạo phòng\nđể mọi người cùng tham gia!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _NeoFilledButton(
              label: 'TẠO PHÒNG',
              icon: AppIcons.addSimple,
              color: AppColors.primary,
              onPressed: onCreateLobby,
            ),
          ],
        ),
      ),
    );
  }
}

class _LobbyList extends StatelessWidget {
  final List<LobbyEntity> lobbies;
  final DateFormat timeFormatter;
  final String? currentUserId;
  final void Function(LobbyEntity) onPreview;
  final void Function(LobbyEntity) onOpenOwned;
  final void Function(String, String?) onJoin;
  final Future<void> Function() onRefresh;

  const _LobbyList({
    required this.lobbies,
    required this.timeFormatter,
    this.currentUserId,
    required this.onPreview,
    required this.onOpenOwned,
    required this.onJoin,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          120,
        ),
        itemCount: lobbies.length,
        itemBuilder: (context, index) {
          final lobby = lobbies[index];
          final isMine = currentUserId != null &&
              currentUserId!.isNotEmpty &&
              lobby.hostId == currentUserId;

          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _NeoLobbyCard(
              lobby: lobby,
              timeFormatter: timeFormatter,
              isMine: isMine,
              onTap: () => isMine ? onOpenOwned(lobby) : onPreview(lobby),
              onJoin: () => onJoin(lobby.id, lobby.inviteCode),
            ),
          );
        },
      ),
    );
  }
}

/// Wrapper nhỏ - dùng `LobbyCardBase` chung để đồng bộ UI với
/// `ReservationCard`. Field `onJoin` được dùng để wire các action
/// riêng (open lobby của mình / join lobby của người khác) trong tương lai.
class _NeoLobbyCard extends StatelessWidget {
  final LobbyEntity lobby;
  final DateFormat timeFormatter;
  final bool isMine;
  final VoidCallback onTap;
  final VoidCallback onJoin;

  const _NeoLobbyCard({
    required this.lobby,
    required this.timeFormatter,
    required this.isMine,
    required this.onTap,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    return LobbyCardBase(
      item: lobbyItemFromEntity(lobby, isOwnedByMe: isMine),
      onTap: onTap,
    );
  }
}

class _NeoRetryButton extends StatelessWidget {
  final VoidCallback onTap;

  const _NeoRetryButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: 2.5),
            boxShadow: const [
              BoxShadow(
                color: AppColors.black,
                blurRadius: 0,
                offset: Offset(3, 3),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(AppIcons.refresh, size: 18, color: AppColors.white),
              SizedBox(width: AppSpacing.xs),
              Text(
                'THỬ LẠI',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: AppColors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NeoFilledButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final VoidCallback? onPressed;

  const _NeoFilledButton({
    required this.label,
    required this.icon,
    required this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: 2.5),
            boxShadow: const [
              BoxShadow(
                color: AppColors.black,
                blurRadius: 0,
                offset: Offset(3, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: AppColors.white),
                const SizedBox(width: AppSpacing.xs),
              ],
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: AppColors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
