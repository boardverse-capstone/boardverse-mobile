import 'package:flutter/material.dart';

import 'package:boardverse/core/theme/app_colors.dart';
import 'package:boardverse/core/theme/app_icons.dart';
import 'package:boardverse/core/theme/app_spacing.dart';

/// Bottom bar của LobbyPage — Modern Game Store style.
///
/// **Design:**
/// - Container với soft shadow thay vì hard offset.
/// - Buttons với gradient nhẹ và soft colored shadow theo màu accent.
/// - Border mỏng 1.5px, không còn border cứng 2.5px của neo-brutalism.
///
/// Từ 2026-08, bottom bar chỉ còn 1 action "Rời phòng" (an toàn, chỉ
/// pop UI). Action "Giải tán phòng" (host-only, hard-delete) đã được
/// chuyển xuống dưới chat section dưới dạng subtle text-only link để
/// tránh user ấn nhầm.
///
/// **Update 2026-08-22**: Thêm navigation tới Reservation Detail và
/// In-Game Session khi có reservation đã check-in.
class LobbyBottomBar extends StatelessWidget {
  /// Callback "Rời phòng" — chỉ pop UI, không gọi API.
  final VoidCallback onLeave;

  /// Callback "Xem đặt chỗ" — điều hướng tới ReservationDetailPage
  final VoidCallback? onViewReservation;

  /// Callback "Phiên chơi" — điều hướng tới InGameSessionPage
  final VoidCallback? onViewInGameSession;

  /// Có reservation đã check-in hay chưa
  final bool hasActiveSession;

  /// Host-only: callback mở bottom sheet đổi giờ lobby (BR-NEW-15).
  /// Chỉ hiển thị khi current user là host + lobby còn recruiting.
  final VoidCallback? onChangeTime;

  /// BR §3.2: callback mở màn đánh giá Karma (real API). Hiển thị
  /// khi lobby ở `ratingOpen` (host đã mở cửa sổ sau POS thanh toán)
  /// hoặc khi `closed` (terminal). Ẩn nếu `null`.
  final VoidCallback? onRate;

  const LobbyBottomBar({
    super.key,
    required this.onLeave,
    this.onViewReservation,
    this.onViewInGameSession,
    this.hasActiveSession = false,
    this.onChangeTime,
    this.onRate,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.surfaceDark : AppColors.surface;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.border,
            width: 1.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Action buttons row
            Row(
              children: [
                // View Reservation button
                if (onViewReservation != null)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.xs),
                      child: _ActionButton(
                        label: 'Đặt chỗ',
                        icon: Icons.calendar_today,
                        color: AppColors.primary,
                        onPressed: onViewReservation,
                      ),
                    ),
                  ),
                // Host-only: Đổi giờ lobby (BR-NEW-15).
                if (onChangeTime != null)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: AppSpacing.xs,
                        right: AppSpacing.xs,
                      ),
                      child: _ActionButton(
                        label: 'Đổi giờ',
                        icon: Icons.schedule,
                        color: AppColors.warning,
                        onPressed: onChangeTime,
                      ),
                    ),
                  ),
                // In-Game Session button (only when active)
                if (hasActiveSession && onViewInGameSession != null)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: onViewReservation != null ? 0 : 0,
                        right: onViewReservation != null ? 0 : AppSpacing.xs,
                      ),
                      child: _ActionButton(
                        label: 'Phiên chơi',
                        icon: Icons.sports_esports,
                        color: AppColors.success,
                        onPressed: onViewInGameSession,
                      ),
                    ),
                  ),
                // BR §3.2: Đánh giá Karma khi lobby ở ratingOpen/closed.
                if (onRate != null)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.xs),
                      child: _ActionButton(
                        label: 'Đánh giá Karma',
                        icon: Icons.star_rate,
                        color: AppColors.warning,
                        onPressed: onRate,
                      ),
                    ),
                  ),
              ],
            ),
            if (onViewReservation != null ||
                hasActiveSession ||
                onChangeTime != null ||
                onRate != null)
              const SizedBox(height: AppSpacing.sm),
            // Leave button
            _OutlineButton(
              label: 'Rời phòng',
              icon: AppIcons.logout,
              onPressed: onLeave,
            ),
          ],
        ),
      ),
    );
  }
}

/// Modern filled action button — soft colored shadow + gradient.
class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  const _ActionButton({
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
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color, color.withAlpha(204)],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: AppColors.white),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Modern outline button — soft shadow, rounded, modern style.
class _OutlineButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  const _OutlineButton({
    required this.label,
    required this.icon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.border,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: TextStyle(
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
