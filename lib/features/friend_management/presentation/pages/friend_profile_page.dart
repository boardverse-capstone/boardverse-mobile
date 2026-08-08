import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/neo_brutalism_theme.dart';
import '../../domain/entities/entities.dart';
import '../cubit/cubit.dart';
import '../widgets/common/common.dart';
import '../widgets/dialogs/dialogs.dart';
import '../widgets/friend_profile_actions.dart';
import '../widgets/shared/activity_status_helpers.dart';

/// Neo-brutalism Friend profile page showing detailed player information.
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.backgroundDark : AppColors.background;

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
              backgroundColor: AppColors.success,
            ),
          );
          context.read<FriendProfileCubit>().clearActionMessage();
        } else if (state is FriendProfileError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is FriendProfileInitial || state is FriendProfileLoading) {
          return Scaffold(
            backgroundColor: bgColor,
            body: const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }
        if (state is FriendProfileError && state.profile == null) {
          return Scaffold(
            backgroundColor: bgColor,
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
          return Scaffold(
            backgroundColor: bgColor,
            body: const Center(
              child: Text('Không tìm thấy thông tin người chơi.'),
            ),
          );
        }

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: bgColor,
            elevation: 0,
            title: Text(
              profile.username.toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ),
          body: RefreshIndicator(
            color: AppColors.primary,
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
    final tierColor = profile.gamerTier?.color ?? AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tierColor.withValues(alpha: 0.2),
            tierColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tierColor, width: NeoBrutalismTheme.borderWidthBold),
        boxShadow: NeoBrutalismTheme.lightShadow(
          shadowColor: tierColor.withValues(alpha: 0.3),
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
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 22,
            ),
          ),
          if (profile.gamerTier != null) ...[
            const SizedBox(height: AppSpacing.xxs),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: tierColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.black, width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.black,
                    blurRadius: 0,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
              child: Text(
                _gamerTierLabel(profile.gamerTier!),
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
          if (profile.friendsSince != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'BẠN BÈ TỪ ${_formatDate(profile.friendsSince!)}',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 11,
                letterSpacing: 0.8,
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
        return 'ĐỒNG';
      case GamerTier.silver:
        return 'BẠC';
      case GamerTier.gold:
        return 'VÀNG';
      case GamerTier.platinum:
        return 'BẠCH KIM';
      case GamerTier.diamond:
        return 'KIM CƯƠNG';
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
    return OutlinedCard(
      shadowColor: AppColors.black.withValues(alpha: 0.05),
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
                color: AppColors.warning,
                label: 'KARMA',
                value: '${profile.karmaPoints}',
              ),
            ),
            Container(
              width: 1.5,
              height: 32,
              color: AppColors.border,
            ),
            Expanded(
              child: _StatCell(
                icon: AppIcons.elo,
                color: AppColors.primary,
                label: 'ELO',
                value: '${profile.globalElo}',
              ),
            ),
            Container(
              width: 1.5,
              height: 32,
              color: AppColors.border,
            ),
            Expanded(
              child: _StatCell(
                icon: AppIcons.level,
                color: AppColors.accent,
                label: 'CẤP',
                value: '${profile.level}',
              ),
            ),
            Container(
              width: 1.5,
              height: 32,
              color: AppColors.border,
            ),
            Expanded(
              child: _StatCell(
                icon: AppIcons.users,
                color: AppColors.secondary,
                label: 'BẠN CHUNG',
                value: '${profile.mutualFriendsCount}',
              ),
            ),
          ],
        ),
      ),
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.black, width: 1.5),
        ),
          child: Icon(icon, color: AppColors.white, size: AppIcons.md),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: color,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
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
    return OutlinedCard(
      shadowColor: AppColors.black.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.black, width: 1.5),
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    color: AppColors.white,
                    size: 14,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                const Text(
                  'GIỚI THIỆU',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              bio,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
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
    final mutual = _mutualFriends;
    if (profile.mutualFriendsCount == 0) return const SizedBox.shrink();

    final preview = mutual.take(5).toList();
    return OutlinedCard(
      shadowColor: AppColors.black.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.black, width: 1.5),
                  ),
                  child: const Icon(
                    AppIcons.users,
                    color: AppColors.white,
                    size: 14,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'BẠN CHUNG (${profile.mutualFriendsCount})',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 64,
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
    return SizedBox(
      width: 56,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          UserAvatar(
            username: summary.username,
            avatarUrl: summary.avatarUrl,
            radius: 20,
          ),
          const SizedBox(height: 2),
          Text(
            summary.username,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}