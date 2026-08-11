import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/top_snack_bar.dart';
import '../../domain/entities/lobby_invitable_friend.dart';
import '../../domain/repositories/lobby_repository.dart';
import '../cubit/lobby_invitable_friends_cubit.dart';
import 'lobby_friends_shimmer.dart';

/// Bottom sheet dùng API mới `GET /api/v1/lobbies/{id}/invitable-friends`.
///
/// UI:
///
/// - Search bar (case-insensitive contains)
/// - Filter chips: Online only, Min karma
/// - List tile với 5 trạng thái:
///   • Invitable → button "Mời"
///   • InvitePending → button "Đã gửi" + nút huỷ
///   • InviteNotPending + terminal status → button "Gửi lại"
///   • AlreadyMember / InviteAccepted → badge "Đã trong phòng"
///   • BlockedByThem / BlockedByMe → disabled + icon block
///   • LobbyClosed → disabled
class LobbyInvitableFriendsSheet extends StatelessWidget {
  final String lobbyId;

  const LobbyInvitableFriendsSheet({super.key, required this.lobbyId});

  /// Helper open sheet từ một context bất kỳ.
  ///
  /// Caller phải đảm bảo [BuildContext] đã có `LobbyRepository` trong
  /// widget tree (qua `BlocProvider`/`RepositoryProvider`).
  static Future<void> show(BuildContext context, String lobbyId) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        // Tạo cubit ngay tại đây — sheetCtx có thể access provider trên
        // root tree vì showModalBottomSheet không tạo scope mới.
        final cubit = LobbyInvitableFriendsCubit(
          repository: sheetCtx.read<LobbyRepository>(),
        )..loadFriends(lobbyId);
        return BlocProvider<LobbyInvitableFriendsCubit>.value(
          value: cubit,
          child: const _SheetHost(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Không dùng — entry point qua `LobbyInvitableFriendsSheet.show`.
    return const SizedBox.shrink();
  }
}

class _SheetHost extends StatelessWidget {
  const _SheetHost();

  @override
  Widget build(BuildContext context) {
    return const LobbyInvitableFriendsBody();
  }
}

class LobbyInvitableFriendsBody extends StatelessWidget {
  const LobbyInvitableFriendsBody({super.key});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.55,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.radiusXl),
          ),
        ),
        child: Column(
          children: [
            _Header(controller: controller),
            const Divider(height: 1),
            _SearchAndFilters(),
            Expanded(
              child: BlocConsumer<
                LobbyInvitableFriendsCubit,
                LobbyInvitableFriendsState
              >(
                listenWhen: (a, b) =>
                    (a.errorMessage != b.errorMessage &&
                        b.errorMessage != null) ||
                    (a.successMessage != b.successMessage &&
                        b.successMessage != null),
                listener: (context, state) {
                  if (state.errorMessage != null) {
                    context.showTopSnackBar(state.errorMessage!, isError: true);
                    context
                        .read<LobbyInvitableFriendsCubit>()
                        .clearError();
                  }
                  if (state.successMessage != null) {
                    context.showTopSnackBar(state.successMessage!);
                    context
                        .read<LobbyInvitableFriendsCubit>()
                        .clearSuccess();
                  }
                },
                builder: (context, state) {
                  if (state.isInitialLoading) {
                    return const _SheetLoadingState();
                  }
                  if (state.friends.isEmpty) {
                    return const _SheetEmptyState();
                  }
                  return RefreshIndicator(
                    onRefresh: () => context
                        .read<LobbyInvitableFriendsCubit>()
                        .refresh(),
                    child: ListView.separated(
                      controller: controller,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                      itemCount: state.friends.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final friend = state.friends[index];
                        return _FriendRow(
                          friend: friend,
                          cubit: context.read<LobbyInvitableFriendsCubit>(),
                          state: state,
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final ScrollController controller;
  const _Header({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Mời bạn bè vào phòng',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Đóng',
            icon: const Icon(AppIcons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _SearchAndFilters extends StatefulWidget {
  @override
  State<_SearchAndFilters> createState() => _SearchAndFiltersState();
}

class _SearchAndFiltersState extends State<_SearchAndFilters> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LobbyInvitableFriendsCubit, LobbyInvitableFriendsState>(
      buildWhen: (a, b) =>
          a.onlineOnly != b.onlineOnly || a.minKarma != b.minKarma,
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                focusNode: _searchFocus,
                onSubmitted: (value) => context
                    .read<LobbyInvitableFriendsCubit>()
                    .search(value),
                decoration: InputDecoration(
                  hintText: 'Tìm bạn theo username',
                  prefixIcon: const Icon(AppIcons.search, size: 20),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(AppIcons.close, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            context
                                .read<LobbyInvitableFriendsCubit>()
                                .search('');
                          },
                        ),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.radiusMdAll,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  FilterChip(
                    label: const Text('Đang online'),
                    selected: state.onlineOnly,
                    onSelected: (_) => context
                        .read<LobbyInvitableFriendsCubit>()
                        .toggleOnlineOnly(),
                    avatar: Icon(
                      state.onlineOnly
                          ? AppIcons.check
                          : AppIcons.userAdd,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  _KarmaFilterChip(
                    current: state.minKarma,
                    onSelected: (v) => context
                        .read<LobbyInvitableFriendsCubit>()
                        .setMinKarma(v),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _KarmaFilterChip extends StatelessWidget {
  final int? current;
  final void Function(int?) onSelected;

  const _KarmaFilterChip({required this.current, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final label = current == null ? 'Karma' : '≥ $current';
    return PopupMenuButton<int?>(
      itemBuilder: (ctx) => [
        const PopupMenuItem<int?>(value: null, child: Text('Tất cả')),
        const PopupMenuItem<int?>(value: 0, child: Text('≥ 0')),
        const PopupMenuItem<int?>(value: 50, child: Text('≥ 50')),
        const PopupMenuItem<int?>(value: 100, child: Text('≥ 100')),
        const PopupMenuItem<int?>(value: 200, child: Text('≥ 200')),
      ],
      onSelected: onSelected,
      child: Chip(
        avatar: const Icon(AppIcons.karma, size: 16),
        label: Text(label),
        backgroundColor: current != null
            ? Theme.of(context).colorScheme.primaryContainer
            : null,
      ),
    );
  }
}

class _FriendRow extends StatelessWidget {
  final LobbyInvitableFriend friend;
  final LobbyInvitableFriendsCubit cubit;
  final LobbyInvitableFriendsState state;

  const _FriendRow({
    required this.friend,
    required this.cubit,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final isSending = state.sendingInviteId == friend.userId;
    final isCancelling = state.cancellingInviteId == friend.userId;
    final isResending = state.resendingInviteId == friend.userId;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: AppRadius.radiusMdAll,
          border: Border.all(color: colors.outlineVariant.withAlpha(80)),
        ),
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundImage: friend.avatarUrl != null &&
                      friend.avatarUrl!.isNotEmpty
                  ? NetworkImage(friend.avatarUrl!)
                  : null,
              child: friend.avatarUrl == null || friend.avatarUrl!.isEmpty
                  ? Text(
                      friend.username.isNotEmpty
                          ? friend.username[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          friend.username,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (friend.isOnline)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withAlpha(30),
                            borderRadius: AppRadius.radiusXxsAll,
                          ),
                          child: const Text(
                            'Online',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        AppIcons.karma,
                        size: 12,
                        color: colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${friend.karmaPoints}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      if (friend.gamerTier != null &&
                          friend.gamerTier!.isNotEmpty) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          friend.gamerTier!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (friend.isBlocked ||
                      friend.inviteStatus ==
                          LobbyInviteFriendStatus.blockedByMe ||
                      friend.inviteStatus ==
                          LobbyInviteFriendStatus.blockedByThem) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Bị chặn — không thể mời',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _ActionButton(
              friend: friend,
              isSending: isSending,
              isCancelling: isCancelling,
              isResending: isResending,
              onInvite: () => cubit.sendInvite(friend.userId),
              onCancel: () => cubit.cancelInvite(friend.userId),
              onResend: () => cubit.resendInvite(friend.userId),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final LobbyInvitableFriend friend;
  final bool isSending;
  final bool isCancelling;
  final bool isResending;
  final VoidCallback onInvite;
  final VoidCallback onCancel;
  final VoidCallback onResend;

  const _ActionButton({
    required this.friend,
    required this.isSending,
    required this.isCancelling,
    required this.isResending,
    required this.onInvite,
    required this.onCancel,
    required this.onResend,
  });

  @override
  Widget build(BuildContext context) {
    final isBusy = isSending || isCancelling || isResending;
    final color = Theme.of(context).colorScheme.primary;

    // Already member → disabled chip
    if (friend.canShowAsMember) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: AppColors.success.withAlpha(30),
          borderRadius: AppRadius.radiusXxsAll,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.check, size: 14, color: AppColors.success),
            const SizedBox(width: 4),
            const Text(
              'Đã tham gia',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.success,
              ),
            ),
          ],
        ),
      );
    }

    // Lobby closed → disabled
    if (friend.inviteStatus == LobbyInviteFriendStatus.lobbyClosed) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: AppColors.textSecondary.withAlpha(30),
          borderRadius: AppRadius.radiusXxsAll,
        ),
        child: const Text(
          'Phòng đã đóng',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    // Blocked → disabled
    if (friend.isBlocked ||
        friend.inviteStatus == LobbyInviteFriendStatus.blockedByMe ||
        friend.inviteStatus == LobbyInviteFriendStatus.blockedByThem) {
      return IconButton(
        onPressed: null,
        icon: const Icon(AppIcons.userRemove, size: 20),
        color: AppColors.error,
      );
    }

    if (friend.canInvite) {
      return SizedBox(
        height: 36,
        child: ElevatedButton.icon(
          onPressed: isBusy ? null : onInvite,
          icon: isSending
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(AppIcons.userAdd, size: 16),
          label: const Text('Mời'),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.radiusMdAll,
            ),
            textStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    if (friend.canCancel) {
      return SizedBox(
        height: 36,
        child: OutlinedButton.icon(
          onPressed: isBusy ? null : onCancel,
          icon: isCancelling
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(AppIcons.close, size: 16),
          label: const Text('Đã gửi'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            side: const BorderSide(color: AppColors.textSecondary),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.radiusMdAll,
            ),
            textStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    if (friend.canResend) {
      return SizedBox(
        height: 36,
        child: OutlinedButton.icon(
          onPressed: isBusy ? null : onResend,
          icon: isResending
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(AppIcons.refresh, size: 16),
          label: const Text('Gửi lại'),
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(color: color),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.radiusMdAll,
            ),
            textStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    // Default fallback
    return const SizedBox.shrink();
  }
}

class _SheetLoadingState extends StatelessWidget {
  const _SheetLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      // Phase 3 2026-08-10: thay spinner + text bằng shimmer skeleton
      // list giống layout friend tile thật.
      child: LobbyFriendsShimmer(itemCount: 4),
    );
  }
}

const _kThemeBody = TextStyle(fontSize: 14);

class _SheetEmptyState extends StatelessWidget {
  const _SheetEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              AppIcons.users,
              size: 56,
              color: AppColors.textSecondary.withAlpha(100),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Không có bạn bè nào phù hợp.',
              style: _kThemeBody,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}