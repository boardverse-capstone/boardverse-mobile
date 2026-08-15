import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:boardverse/core/theme/app_colors.dart';
import 'package:boardverse/core/theme/app_shimmer.dart';
import 'package:boardverse/core/theme/app_spacing.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';

/// Simplified home overview page - just greeting + avatar.
class HomeOverviewPage extends StatelessWidget {
  final ValueChanged<int>? onSwitchTab;

  const HomeOverviewPage({
    super.key,
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
          padding: const EdgeInsets.all(AppSpacing.md),
          child: _buildHeader(context),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        // Khi profile chưa load (Initial / Loading / Error) hiển thị
        // skeleton shimmer trên cùng card gradient - tránh hiển thị
        // fake "Player" gây hiểu nhầm là đã load xong.
        if (state is! ProfileLoaded) {
          return _HeaderSkeleton(isDark: isDark);
        }

        final username = state.profile.username;
        final avatarUrl = state.profile.avatarUrl;

        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryLight],
            ),
            borderRadius: BorderRadius.circular(20),
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
          child: Row(
            children: [
              _AvatarWithBorder(avatarUrl: avatarUrl, username: username),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Xin chào,',
                      style: TextStyle(
                        color: AppColors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      username,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _greetingMessage(),
                      style: TextStyle(
                        color: AppColors.white.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _greetingMessage() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Chúc bạn buổi sáng vui vẻ';
    if (hour < 14) return 'Buổi trưa nay có trận nào không?';
    if (hour < 18) return 'Buổi chiều rảnh rỗi';
    return 'Chào buổi tối!';
  }
}

class _AvatarWithBorder extends StatelessWidget {
  const _AvatarWithBorder({required this.avatarUrl, required this.username});

  final String? avatarUrl;
  final String username;

  @override
  Widget build(BuildContext context) {
    final hasImage = avatarUrl != null && avatarUrl!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(3),
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
      child: CircleAvatar(
        radius: 32,
        backgroundColor: AppColors.primary.withValues(alpha: 0.2),
        backgroundImage: hasImage ? NetworkImage(avatarUrl!) : null,
        child: hasImage
            ? null
            : Text(
                username.isNotEmpty
                    ? username.substring(0, 1).toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
      ),
    );
  }
}

/// Skeleton cho header trong khi profile đang load.
///
/// Giữ nguyên cấu trúc gradient + border + shadow để khi load xong
/// không bị "jump" layout. Phần text/avatar thay bằng shimmer box
/// để user biết app đang tải, không phải lỗi.
class _HeaderSkeleton extends StatelessWidget {
  const _HeaderSkeleton({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
        borderRadius: BorderRadius.circular(20),
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
      child: Row(
        children: [
          AppShimmer.circle(context: context, size: 64),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AppShimmer.box(
                  context: context,
                  width: 70,
                  height: 14,
                  borderRadius: 4,
                ),
                const SizedBox(height: 8),
                AppShimmer.box(
                  context: context,
                  width: 160,
                  height: 22,
                  borderRadius: 6,
                ),
                const SizedBox(height: 8),
                AppShimmer.box(
                  context: context,
                  width: 200,
                  height: 12,
                  borderRadius: 4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}