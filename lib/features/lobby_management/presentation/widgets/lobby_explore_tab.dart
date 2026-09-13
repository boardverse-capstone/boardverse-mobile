import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/theme/theme.dart';
import '../../domain/entities/lobby_entity.dart';
import '../cubit/lobby_search_cubit.dart';
import '../cubit/lobby_state.dart';
import 'lobby_card_base.dart';

/// Modern lobby explore tab — đồng bộ style với [ReservationListPage].
class LobbyExploreTab extends StatelessWidget {
  final LobbySearchCubit searchCubit;
  final void Function(LobbyEntity) onPreview;
  final void Function(LobbyEntity) onOpenOwned;
  final void Function(String, String?) onJoin;
  final VoidCallback onCreateLobby;
  final String? currentUserId;

  const LobbyExploreTab({
    super.key,
    required this.searchCubit,
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
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        120,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 265,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => const _GridCardSkeleton(),
    );
  }
}

/// Shimmer skeleton cho grid card — đồng bộ với [LobbyCardBase] vertical layout.
class _GridCardSkeleton extends StatelessWidget {
  const _GridCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgBase = isDark ? AppColors.surfaceElevatedDark : AppColors.surface;

    return AppShimmer.shimmer(
      context: context,
      child: Container(
        decoration: BoxDecoration(
          color: bgBase,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? AppColors.borderDark.withValues(alpha: 0.4)
                : AppColors.border.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Artwork cover placeholder
            Container(
              height: 88,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
            ),
            // Content — match vertical card padding/sizes
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title line
                    Container(
                      width: double.infinity,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Cafe line
                    Container(
                      width: 80,
                      height: 11,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Time chip placeholder (2-row stacked: date + time)
                    Container(
                      width: 140,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const Spacer(),
                    // Share code pill placeholder — full width
                    Container(
                      width: double.infinity,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 7),
                    // Hint line placeholder
                    Container(
                      width: 120,
                      height: 9,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

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
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(AppIcons.error, size: 48, color: AppColors.error),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Đã xảy ra lỗi',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _RetryButton(onTap: onRetry),
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
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
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
            Text(
              'Chưa có phòng chờ nào',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 20,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Hãy là người đầu tiên tạo phòng\nđể mọi người cùng tham gia!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _CreateButton(
              label: 'TẠO PHÒNG',
              icon: AppIcons.addSimple,
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
  final String? currentUserId;
  final void Function(LobbyEntity) onPreview;
  final void Function(LobbyEntity) onOpenOwned;
  final void Function(String, String?) onJoin;
  final Future<void> Function() onRefresh;

  const _LobbyList({
    required this.lobbies,
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
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          120,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisExtent: 265,
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
        ),
        itemCount: lobbies.length,
        itemBuilder: (context, index) {
          final lobby = lobbies[index];
          final isMine = currentUserId != null &&
              currentUserId!.isNotEmpty &&
              lobby.hostId == currentUserId;

          return _GridLobbyCard(
            lobby: lobby,
            isMine: isMine,
            onTap: () => isMine ? onOpenOwned(lobby) : onPreview(lobby),
          );
        },
      ),
    );
  }
}

/// Grid card — dùng `LobbyCardBase` với vertical layout.
class _GridLobbyCard extends StatelessWidget {
  final LobbyEntity lobby;
  final bool isMine;
  final VoidCallback onTap;

  const _GridLobbyCard({
    required this.lobby,
    required this.isMine,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LobbyCardBase(
      item: lobbyItemFromEntity(lobby, isOwnedByMe: isMine),
      onTap: onTap,
      layout: LobbyCardLayout.vertical,
    );
  }
}

/// Soft-shadow retry button — Game Store style.
class _RetryButton extends StatelessWidget {
  final VoidCallback onTap;

  const _RetryButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primary.withAlpha(204)],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
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

/// Soft-shadow filled button — Game Store style.
class _CreateButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;

  const _CreateButton({
    required this.label,
    required this.icon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryLight],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
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
