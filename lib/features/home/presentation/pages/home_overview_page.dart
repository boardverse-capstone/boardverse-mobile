import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_elevation.dart';
import '../../../matchmaking_discovery/presentation/cubit/matchmaking_cubit.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';
import '../../../profile/domain/entities/profile_entity.dart';
import '../widgets/home_news_placeholder.dart';
import '../widgets/home_quick_action_card.dart';
import '../widgets/home_section_header.dart';

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
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: AppSpacing.sm),
              _buildQuickActions(context),
              const HomeSectionHeader(
                title: 'Tin tức & Sự kiện',
                icon: Icons.campaign_outlined,
              ),
              HomeNewsPlaceholder(
                title: 'Wingspan Season Opening sắp khởi tranh',
                description:
                    'Đăng ký ngay để nhận ưu đãi phí tham gia cho thành viên BoardVerse.',
                icon: Icons.emoji_events_outlined,
                color: AppColors.accent,
              ),
              const SizedBox(height: AppSpacing.sm),
              HomeNewsPlaceholder(
                title: 'Tính năng đề xuất đối thủ đang phát triển',
                description:
                    'Bản cập nhật tiếp theo sẽ gợi ý đối thủ theo ELO và khoảng cách.',
                icon: Icons.bolt_outlined,
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
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.radiusLgAll,
        boxShadow: AppElevation.shadowSm,
      ),
      child: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          final username = state is ProfileLoaded
              ? state.profile.username
              : 'Player';
          return Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white,
                child: Text(
                  username.isNotEmpty
                      ? username.substring(0, 1).toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Xin chào, $username!',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      _greetingMessage(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
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

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: HomeQuickActionCard(
              icon: Icons.calendar_today,
              label: 'Đặt chỗ',
              color: AppColors.primary,
              onTap: () => onSwitchTab?.call(1),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: HomeQuickActionCard(
              icon: Icons.groups,
              label: 'Tìm phòng',
              color: AppColors.primaryDark,
              onTap: () => onSwitchTab?.call(2),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: HomeQuickActionCard(
              icon: Icons.history,
              label: 'Lịch sử',
              color: AppColors.secondary,
              onTap: () => _openBookingHistory(context),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: HomeQuickActionCard(
              icon: Icons.emoji_events,
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
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          if (state is! ProfileLoaded) {
            return Container(
              height: 96,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: AppRadius.radiusMdAll,
              ),
              child: const Center(child: CircularProgressIndicator()),
            );
          }

          return _SuggestionList(profile: state.profile, theme: theme);
        },
      ),
    );
  }

  void _openBookingHistory(BuildContext context) {
    // Chuyển sang tab Bookings (index 1) — danh sách reservation + lobby
    // của user.
    onSwitchTab?.call(1);
  }
}

class _SuggestionList extends StatelessWidget {
  final ProfileEntity profile;
  final ThemeData theme;

  const _SuggestionList({required this.profile, required this.theme});

  @override
  Widget build(BuildContext context) {
    final elo = profile.globalElo;
    final category = elo >= 1500
        ? 'cao thủ'
        : elo >= 1100
        ? 'trung cấp'
        : 'mới chơi';
    final tips = <(IconData, String, String)>[
      (
        Icons.search,
        'Khám phá các board game mới',
        'Mở tab "Khám phá" để tìm board game và quán gần bạn.',
      ),
      (
        Icons.trending_up,
        'Nâng cao ELO ($category)',
        'Bạn đang ở khoảng $elo ELO. Tham gia lobby để tích lũy kinh nghiệm.',
      ),
      (
        Icons.emoji_events,
        'Giải đấu tháng này',
        'Wingspan và Catan Championship đang mở đăng ký.',
      ),
    ];

    return Column(
      children: tips
          .map(
            (tip) => Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              decoration: BoxDecoration(
                borderRadius: AppRadius.radiusSmAll,
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.4,
                  ),
                ),
              ),
              child: Material(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: AppRadius.radiusSmAll,
                child: ListTile(
                  leading: Icon(tip.$1, color: theme.colorScheme.primary),
                  title: Text(
                    tip.$2,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(tip.$3),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.outline,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
