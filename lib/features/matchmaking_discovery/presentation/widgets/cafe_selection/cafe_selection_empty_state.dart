import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/neo_brutalism_theme.dart';

/// Neo-brutalism Empty state khi không có cafe nào trong khu vực.
///
/// Widget này hiển thị icon + title + message. Mặc định title là "Chưa
/// có quán cafe nào" — caller có thể override bằng [title] để phù hợp
/// với ngữ cảnh (vd: "Chưa có quán nào tại Hồ Chí Minh" khi filter
/// "Trong thành phố" trống).
class CafeSelectionEmptyState extends StatelessWidget {
  final String message;

  /// Tiêu đề empty state. Mặc định là câu chung chung để giữ backward
  /// compat — code mới nên truyền title cụ thể hơn (vd: theo thành phố).
  final String? title;
  const CafeSelectionEmptyState({super.key, required this.message, this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.xl,
        AppSpacing.xxl,
        AppSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primary,
                width: NeoBrutalismTheme.borderWidth,
              ),
            ),
            child: Icon(
              Icons.store_mall_directory_outlined,
              size: AppSpacing.huge,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title ?? 'Chưa có quán cafe nào',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              // Dùng `textPrimary` thay vì `outline` để đảm bảo contrast
              // đủ lớn cho body text — `outline` trong Material 3 quá nhạt,
              // khó đọc trên thiết bị di động, đặc biệt dưới ánh sáng mạnh.
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimary,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
