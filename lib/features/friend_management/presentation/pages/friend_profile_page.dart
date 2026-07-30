import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/theme.dart';
import '../../domain/entities/entities.dart';
import '../cubit/cubit.dart';
import '../widgets/common/common.dart';
import '../widgets/dialogs/dialogs.dart';
import '../widgets/friend_profile_actions.dart';
import '../widgets/shared/activity_status_helpers.dart';

/// Friend profile page showing detailed player information.
class FriendProfilePage extends StatelessWidget {
  const FriendProfilePage({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<FriendProfileCubit>(
      create: (_) {
        final cubit = sl<FriendProfileCubit>();
        cubit.loadProfile(userId);
        return cubit;
      },
      child: const _FriendProfileView(),
    );
  }
}

class _FriendProfileView extends StatelessWidget {
  const _FriendProfileView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FriendProfileCubit, FriendProfileState>(
      listenWhen: (prev, curr) =>
          (curr is FriendProfileLoaded &&
              (prev is! FriendProfileLoaded ||
                  prev.actionMessage != curr.actionMessage ||
                  prev.profile != curr.profile)) ||
          curr is FriendProfileError,
      listener: (context, state) {
        if (state is FriendProfileLoaded && state.actionMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text(state.actionMessage!),
              duration: const Duration(seconds: 3),
            ),
          );
          context.read<FriendProfileCubit>().clearActionMessage();
        } else if (state is FriendProfileError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text(state.message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is FriendProfileInitial || state is FriendProfileLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (state is FriendProfileError && state.profile == null) {
          return Scaffold(
            appBar: AppBar(),
            body: ErrorRetryView(
              message: state.message,
              onRetry: () {
                final id = state.userId.isNotEmpty
                    ? state.userId
                    : (context.read<FriendProfileCubit>().currentUserId ?? '');
                if (id.isEmpty) return;
                context.read<FriendProfileCubit>().loadProfile(id);
              },
            ),
          );
        }

        FriendProfileEntity? profile;
        bool isMutating = false;
        if (state is FriendProfileLoaded) {
          profile = state.profile;
          isMutating = state.isMutating;
        } else if (state is FriendProfileError) {
          profile = state.profile;
        }

        if (profile == null) {
          return const Scaffold(
            body: Center(child: Text('Không tìm thấy thông tin người chơi.')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(profile.username),
          ),
          body: RefreshIndicator(
            onRefresh: () => context.read<FriendProfileCubit>().refresh(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ProfileHeader(profile: profile),
                  const SizedBox(height: AppSpacing.md),
                  _StatsRow(profile: profile),
                  if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    _BioCard(bio: profile.bio!),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  _MutualFriendsSection(
                    profile: profile,
                    state: state,
                    onLoadMore: () =>
                        context.read<FriendProfileCubit>().loadMutualFriends(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FriendProfileActions(
                    profile: profile,
                    isMutating: isMutating,
                    onSendRequest: () {
                      context.read<FriendProfileCubit>().sendFriendRequest();
                    },
                    onUnfriend: () async {
                      final confirm = await showConfirmDialog(
                        context,
                        title: 'Hủy kết bạn',
                        message:
                            'Bạn có chắc muốn hủy kết bạn với ${profile!.username}? '
                            'Mọi lời mời lobby đang chờ giữa 2 bên sẽ bị hủy.',
                        confirmLabel: 'Hủy kết bạn',
                      );
                      if (confirm && context.mounted) {
                        context.read<FriendProfileCubit>().unfriend();
                      }
                    },
                    onInviteToLobby: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          content: Text(
                            'Tính năng mời lobby đang được phát triển. '
                            'Player: ${profile!.username}',
                          ),
                        ),
                      );
                    },
                    onBlock: () async {
                      final confirm = await showConfirmDialog(
                        context,
                        title: 'Chặn người chơi',
                        message:
                            '${profile!.username} sẽ không thể gửi lời mời kết bạn hoặc lời mời lobby cho bạn.',
                        confirmLabel: 'Chặn',
                      );
                      if (confirm && context.mounted) {
                        context.read<FriendProfileCubit>().blockUser();
                      }
                    },
                    onUnblock: () {
                      context.read<FriendProfileCubit>().unblockUser();
                    },
                    onReport: () async {
                      final result = await showReportDialog(context);
                      if (result != null && context.mounted) {
                        context.read<FriendProfileCubit>().report(
                              category: result.category,
                              reason: result.reason,
                            );
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile});

  final FriendProfileEntity profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tierColor = profile.gamerTier?.color ?? theme.colorScheme.outline;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tierColor.withValues(alpha: 0.12),
            theme.colorScheme.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.radiusMd),
        border: Border.all(
          color: tierColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          UserAvatar(
            username: profile.username,
            avatarUrl: profile.avatarUrl,
            radius: 42,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            profile.username,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (profile.gamerTier != null) ...[
            const SizedBox(height: AppSpacing.xxs),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: tierColor.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _gamerTierLabel(profile.gamerTier!),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: tierColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          if (profile.friendsSince != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Bạn bè từ ${_formatDate(profile.friendsSince!)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _gamerTierLabel(GamerTier tier) {
    switch (tier) {
      case GamerTier.bronze:
        return 'Đồng';
      case GamerTier.silver:
        return 'Bạc';
      case GamerTier.gold:
        return 'Vàng';
      case GamerTier.platinum:
        return 'Bạch kim';
      case GamerTier.diamond:
        return 'Kim cương';
    }
  }

  static String _formatDate(DateTime date) {
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    return '${date.year}-$mm-$dd';
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.profile});

  final FriendProfileEntity profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return OutlinedCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Expanded(
              child: _StatCell(
                icon: AppIcons.karma,
                color: Colors.orange,
                label: 'Karma',
                value: '${profile.karmaPoints}',
              ),
            ),
            _Divider(theme: theme),
            Expanded(
              child: _StatCell(
                icon: AppIcons.elo,
                color: theme.colorScheme.primary,
                label: 'ELO',
                value: '${profile.globalElo}',
              ),
            ),
            _Divider(theme: theme),
            Expanded(
              child: _StatCell(
                icon: AppIcons.level,
                color: Colors.purple,
                label: 'Cấp',
                value: '${profile.level}',
              ),
            ),
            _Divider(theme: theme),
            Expanded(
              child: _StatCell(
                icon: AppIcons.users,
                color: theme.colorScheme.tertiary,
                label: 'Bạn chung',
                value: '${profile.mutualFriendsCount}',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider({required this.theme});
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      color: theme.colorScheme.outlineVariant,
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: AppIcons.md),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }
}

class _BioCard extends StatelessWidget {
  const _BioCard({required this.bio});
  final String bio;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return OutlinedCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Giới thiệu',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(bio, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _MutualFriendsSection extends StatelessWidget {
  const _MutualFriendsSection({
    required this.profile,
    required this.state,
    required this.onLoadMore,
  });

  final FriendProfileEntity profile;
  final FriendProfileState state;
  final VoidCallback onLoadMore;

  List<MutualFriendSummary> get _mutualFriends {
    if (state is FriendProfileLoaded) {
      return (state as FriendProfileLoaded).effectiveMutualFriends;
    }
    return profile.mutualFriends;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutual = _mutualFriends;
    if (profile.mutualFriendsCount == 0) return const SizedBox.shrink();

    final preview = mutual.take(5).toList();
    return OutlinedCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(AppIcons.users,
                    color: theme.colorScheme.tertiary, size: AppIcons.md),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Bạn chung (${profile.mutualFriendsCount})',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 56,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemBuilder: (_, index) {
                  final m = preview[index];
                  return _MutualAvatar(summary: m);
                },
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppSpacing.xs),
                itemCount: preview.length,
              ),
            ),
            if (profile.mutualFriendsCount > preview.length) ...[
              const SizedBox(height: AppSpacing.xs),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onLoadMore,
                  icon: const Icon(Icons.expand_more, size: AppIcons.sm),
                  label: const Text('Xem tất cả'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MutualAvatar extends StatelessWidget {
  const _MutualAvatar({required this.summary});
  final MutualFriendSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        UserAvatar(
          username: summary.username,
          avatarUrl: summary.avatarUrl,
          radius: 22,
        ),
        const SizedBox(height: 2),
        SizedBox(
          width: 56,
          child: Text(
            summary.username,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ),
      ],
    );
  }
}
