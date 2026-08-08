import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:boardverse_mobile/core/theme/app_colors.dart';
import 'package:boardverse_mobile/core/theme/app_icons.dart';
import 'package:boardverse_mobile/core/theme/app_spacing.dart';
import '../../../matchmaking_discovery/presentation/cubit/matchmaking_cubit.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';
import '../../../profile/domain/entities/profile_entity.dart';
import '../widgets/home_news_placeholder.dart';
import '../widgets/home_quick_action_card.dart';
import '../widgets/home_section_header.dart';

/// Neo-brutalism home overview page.
///
/// Layout:
/// - Hero greeting card (gradient + avatar + ELO badge + greeting text)
/// - 3 stats cards (ELO / Karma / Streak)
/// - Quick action grid (4 actions)
/// - News & Events section
/// - Suggestions section
class HomeOverviewPage extends StatelessWidget {
  final MatchmakingCubit matchmakingCubit;
  final ValueChanged<int>? onSwitchTab;

  const HomeOverviewPage({
    super.key,
    required this.matchmakingCubit,
    this.onSwitchTab,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.md),
              _buildHeader(context),
              const SizedBox(height: AppSpacing.md),
              _buildStatsRow(context),
              const SizedBox(height: AppSpacing.md),
              _buildQuickActions(context),
              const HomeSectionHeader(
                title: 'Tin tức & Sự kiện',
                icon: Icons.campaign_outlined,
              ),
              HomeNewsPlaceholder(
                title: 'Wingspan Season Opening sắp khởi tranh',
                description:
                    'Đăng ký ngay để nhận ưu đãi phí tham gia cho thành viên BoardVerse.',
                icon: AppIcons.tournament,
                color: AppColors.accent,
              ),
              const SizedBox(height: AppSpacing.sm),
              HomeNewsPlaceholder(
                title: 'Tính năng đề xuất đối thủ đang phát triển',
                description:
                    'Bản cập nhật tiếp theo sẽ gợi ý đối thủ theo ELO và khoảng cách.',
                icon: Icons.bolt,
                color: AppColors.primary,
              ),
              const SizedBox(height: AppSpacing.sm),
              const HomeSectionHeader(
                title: 'Gợi ý cho bạn',
                icon: Icons.tips_and_updates_outlined,
              ),
              _buildSuggestion(context),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primaryLight],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.border,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.4),
              blurRadius: 0,
              offset: const Offset(5, 5),
            ),
          ],
        ),
        child: BlocBuilder<ProfileCubit, ProfileState>(
          builder: (context, state) {
            final username = state is ProfileLoaded
                ? state.profile.username
                : 'Player';
            final elo = state is ProfileLoaded
                ? state.profile.globalElo
                : 0;
            return Row(
              children: [
                // Avatar với neo-brutalism border trắng
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.white,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.black.withValues(alpha: 0.3),
                        blurRadius: 0,
                        offset: const Offset(2, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      username.isNotEmpty
                          ? username.substring(0, 1).toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Xin chào, $username!',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _greetingMessage(),
                        style: TextStyle(
                          color: AppColors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // ELO pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xxs,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.black,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              AppIcons.rating,
                              size: 12,
                              color: AppColors.warning,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'ELO $elo',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                                color: AppColors.black,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _greetingMessage() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Chúc bạn buổi sáng vui vẻ';
    if (hour < 14) return 'Buổi trưa nay có trận nào hấp dẫn không?';
    if (hour < 18) return 'Buổi chiều rảnh — ghép phòng chơi ngay';
    return 'Buổi tối tuyệt vời để chơi cùng bạn bè!';
  }

  Widget _buildStatsRow(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final elo = state is ProfileLoaded ? state.profile.globalElo : 0;
        final karma =
            state is ProfileLoaded ? (state.profile.karmaPoints ?? 0) : 0;
        final level = state is ProfileLoaded ? state.profile.level : 1;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: AppIcons.rating,
                  label: 'ELO',
                  value: '$elo',
                  color: AppColors.warning,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatCard(
                  icon: AppIcons.karma,
                  label: 'Karma',
                  value: '$karma',
                  color: AppColors.primary,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatCard(
                  icon: AppIcons.level,
                  label: 'Level',
                  value: '$level',
                  color: AppColors.accent,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: HomeQuickActionCard(
              icon: AppIcons.booking,
              label: 'Đặt chỗ',
              color: AppColors.primary,
              onTap: () => onSwitchTab?.call(1),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: HomeQuickActionCard(
              icon: AppIcons.users,
              label: 'Tìm phòng',
              color: AppColors.primaryDark,
              onTap: () => onSwitchTab?.call(2),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: HomeQuickActionCard(
              icon: AppIcons.bookingHistory,
              label: 'Lịch sử',
              color: AppColors.secondary,
              onTap: () => onSwitchTab?.call(1),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: HomeQuickActionCard(
              icon: AppIcons.tournament,
              label: 'Giải đấu',
              color: AppColors.accentDark,
              onTap: () => onSwitchTab?.call(3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestion(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          if (state is! ProfileLoaded) {
            return Container(
              height: 96,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceDark
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? AppColors.borderDark
                      : AppColors.border,
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.4),
                    blurRadius: 0,
                    offset: const Offset(3, 3),
                  ),
                ],
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 3,
                ),
              ),
            );
          }

          return _SuggestionList(
            profile: state.profile,
            isDark: isDark,
          );
        },
      ),
    );
  }
}

/// Neo-brutalism stat card với border + shadow + colored icon badge.
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.4),
            blurRadius: 0,
            offset: const Offset(3, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.border,
                width: 2,
              ),
            ),
            child: Icon(icon, size: 16, color: AppColors.white),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Neo-brutalism suggestion list với border + colored icon badge cho mỗi tip.
class _SuggestionList extends StatelessWidget {
  final ProfileEntity profile;
  final bool isDark;

  const _SuggestionList({
    required this.profile,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final elo = profile.globalElo;
    final category =
        elo >= 1500 ? 'cao thủ' : elo >= 1100 ? 'trung cấp' : 'mới chơi';
    final tips = <(IconData, String, String, Color)>[
      (
        AppIcons.search,
        'Khám phá các board game mới',
        'Mở tab "Khám phá" để tìm board game và quán gần bạn.',
        AppColors.info,
      ),
      (
        Icons.trending_up,
        'Nâng cao ELO ($category)',
        'Bạn đang ở khoảng $elo ELO. Tham gia lobby để tích lũy kinh nghiệm.',
        AppColors.warning,
      ),
      (
        AppIcons.tournament,
        'Giải đấu tháng này',
        'Wingspan và Catan Championship đang mở đăng ký.',
        AppColors.primary,
      ),
    ];

    return Column(
      children: tips
          .map(
            (tip) => Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.border,
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.4),
                    blurRadius: 0,
                    offset: const Offset(3, 3),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: tip.$4,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.borderDark
                                  : AppColors.border,
                              width: 2,
                            ),
                          ),
                          child: Icon(tip.$1,
                              color: AppColors.white, size: 20),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tip.$2,
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                tip.$3,
                                style: TextStyle(
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}