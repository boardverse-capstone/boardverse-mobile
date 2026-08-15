import 'package:flutter/material.dart';

import 'package:boardverse/core/theme/app_colors.dart';
import 'package:boardverse/core/theme/app_icons.dart';
import 'package:boardverse/core/theme/app_spacing.dart';

import '../../../reservation/domain/entities/entities.dart' as res;
import '../../domain/entities/lobby_entity.dart';

/// Variant hiển thị — map từ (LobbyStatus, ReservationStatus) → chip badge.
enum LobbyStatusBadgeVariant {
  recruiting,
  viable,
  full,
  pendingCafeApproval,
  rejectedByCafe,
  expiredByCafe,
  confirmed,
  checkedIn,
  inProgress,
  ratingOpen,
  closed,
  timeoutFailed,
  hostCancelled,
  expired,
  unknown,
}

/// Helper chuyển cặp (lobbyStatus, reservationStatus) → variant.
///
/// Nguyên tắc:
/// - **ReservationStatus ưu tiên hơn LobbyStatus** cho flow chính (đặt cọc /
///   check-in / POS). Ví dụ lobby.status = `Open` nhưng reservation.status =
///   `Holding` (đã trừ tiền cọc, chờ duyệt) → badge vẫn là `pendingCafeApproval`.
/// - `CheckedIn` / `Completed` của reservation → `checkedIn` badge.
/// - Lobby ở terminal state → dùng lobby status trực tiếp.
LobbyStatusBadgeVariant resolveBadgeVariant({
  required LobbyStatus? lobbyStatus,
  required res.ReservationStatus? reservationStatus,
}) {
  // Terminal reservation → dùng reservation status trực tiếp.
  if (reservationStatus != null && reservationStatus.isTerminal) {
    switch (reservationStatus) {
      case res.ReservationStatus.rejectedByCafe:
        return LobbyStatusBadgeVariant.rejectedByCafe;
      case res.ReservationStatus.cancelledByCafe:
        return LobbyStatusBadgeVariant.rejectedByCafe;
      case res.ReservationStatus.cancelledByPlayer:
      case res.ReservationStatus.cancelledByHost:
        return LobbyStatusBadgeVariant.hostCancelled;
      case res.ReservationStatus.expired:
        return LobbyStatusBadgeVariant.expiredByCafe;
      case res.ReservationStatus.noShow:
        return LobbyStatusBadgeVariant.closed;
      case res.ReservationStatus.completed:
        return LobbyStatusBadgeVariant.closed;
      default:
        break;
    }
  }

  // Active reservation → ưu tiên reservation.
  if (reservationStatus != null) {
    switch (reservationStatus) {
      case res.ReservationStatus.holding:
        // Có thể là awaiting cafe approval hoặc đang giữ chỗ thông thường.
        // Phân biệt qua lobbyStatus: nếu lobby là pendingCafeApproval thì
        // badge = pendingCafeApproval, ngược lại = confirmed.
        if (lobbyStatus == LobbyStatus.pendingCafeApproval) {
          return LobbyStatusBadgeVariant.pendingCafeApproval;
        }
        return LobbyStatusBadgeVariant.confirmed;
      case res.ReservationStatus.confirmed:
        return LobbyStatusBadgeVariant.confirmed;
      case res.ReservationStatus.checkedIn:
        return LobbyStatusBadgeVariant.checkedIn;
      case res.ReservationStatus.draft:
      case res.ReservationStatus.awaitingDeposit:
        // Chưa hoàn tất flow đặt cọc — fallback theo lobby status.
        break;
      default:
        break;
    }
  }

  // Fallback theo lobby status.
  switch (lobbyStatus) {
    case LobbyStatus.pendingActivation:
      return LobbyStatusBadgeVariant.pendingCafeApproval;
    case LobbyStatus.pendingCafeApproval:
      return LobbyStatusBadgeVariant.pendingCafeApproval;
    case LobbyStatus.open:
      return LobbyStatusBadgeVariant.recruiting;
    case LobbyStatus.viable:
      return LobbyStatusBadgeVariant.viable;
    case LobbyStatus.full:
      return LobbyStatusBadgeVariant.full;
    case LobbyStatus.inProgress:
      return LobbyStatusBadgeVariant.inProgress;
    case LobbyStatus.ratingOpen:
      return LobbyStatusBadgeVariant.ratingOpen;
    case LobbyStatus.closed:
      return LobbyStatusBadgeVariant.closed;
    case LobbyStatus.timeoutFailed:
      return LobbyStatusBadgeVariant.timeoutFailed;
    case LobbyStatus.hostCancelled:
      return LobbyStatusBadgeVariant.hostCancelled;
    case LobbyStatus.rejectedByCafe:
      return LobbyStatusBadgeVariant.rejectedByCafe;
    case LobbyStatus.expiredByCafe:
      return LobbyStatusBadgeVariant.expiredByCafe;
    case null:
      return LobbyStatusBadgeVariant.unknown;
  }
}

class _BadgeStyle {
  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  const _BadgeStyle({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
  });
}

/// Badge hiển thị trạng thái lobby/reservation ở header của LobbyPage.
///
/// Hiển thị text + icon + màu nền khác nhau cho từng variant. Màu sắc theo
/// semantic: xanh dương cho recruiting, xanh lá cho confirmed/full, vàng
/// cho pending approval, đỏ cho rejected/expired.
class LobbyStatusBadge extends StatelessWidget {
  final LobbyStatusBadgeVariant variant;
  final bool dense;
  final bool showActiveIndicator;

  const LobbyStatusBadge({
    super.key,
    required this.variant,
    this.dense = false,
    this.showActiveIndicator = false,
  });

  _BadgeStyle _styleFor(BuildContext context) {
    switch (variant) {
      case LobbyStatusBadgeVariant.recruiting:
        return const _BadgeStyle(
          label: 'Cần thêm người',
          icon: AppIcons.users,
          background: AppColors.info,
          foreground: AppColors.white,
        );
      case LobbyStatusBadgeVariant.viable:
        return const _BadgeStyle(
          label: 'Đủ người tối thiểu',
          icon: AppIcons.check,
          background: AppColors.accent,
          foreground: AppColors.black,
        );
      case LobbyStatusBadgeVariant.full:
        return const _BadgeStyle(
          label: 'Phòng đầy',
          icon: AppIcons.check,
          background: AppColors.success,
          foreground: AppColors.white,
        );
      case LobbyStatusBadgeVariant.pendingCafeApproval:
        return const _BadgeStyle(
          label: 'Chờ quán duyệt',
          icon: AppIcons.warning,
          background: AppColors.warning,
          foreground: AppColors.black,
        );
      case LobbyStatusBadgeVariant.rejectedByCafe:
        return const _BadgeStyle(
          label: 'Quán từ chối',
          icon: AppIcons.cancelBooking,
          background: AppColors.error,
          foreground: AppColors.white,
        );
      case LobbyStatusBadgeVariant.expiredByCafe:
        return const _BadgeStyle(
          label: 'Hết hạn duyệt',
          icon: Icons.timer_off_outlined,
          background: AppColors.error,
          foreground: AppColors.white,
        );
      case LobbyStatusBadgeVariant.confirmed:
        return const _BadgeStyle(
          label: 'Đã xác nhận đặt chỗ',
          icon: AppIcons.check,
          background: AppColors.success,
          foreground: AppColors.white,
        );
      case LobbyStatusBadgeVariant.checkedIn:
        return const _BadgeStyle(
          label: 'Đã check-in tại quán',
          icon: AppIcons.location,
          background: AppColors.success,
          foreground: AppColors.white,
        );
      case LobbyStatusBadgeVariant.inProgress:
        return const _BadgeStyle(
          label: 'Đang chơi',
          icon: Icons.sports_esports_outlined,
          background: AppColors.primary,
          foreground: AppColors.white,
        );
      case LobbyStatusBadgeVariant.ratingOpen:
        return const _BadgeStyle(
          label: 'Đang đánh giá',
          icon: Icons.star_outline,
          background: AppColors.accent,
          foreground: AppColors.black,
        );
      case LobbyStatusBadgeVariant.closed:
        return const _BadgeStyle(
          label: 'Đã đóng',
          icon: AppIcons.lock,
          background: AppColors.textTertiary,
          foreground: AppColors.white,
        );
      case LobbyStatusBadgeVariant.timeoutFailed:
        return const _BadgeStyle(
          label: 'Hết hạn tuyển',
          icon: Icons.timer_off_outlined,
          background: AppColors.error,
          foreground: AppColors.white,
        );
      case LobbyStatusBadgeVariant.hostCancelled:
        return const _BadgeStyle(
          label: 'Đã huỷ',
          icon: AppIcons.cancelBooking,
          background: AppColors.error,
          foreground: AppColors.white,
        );
      case LobbyStatusBadgeVariant.expired:
        return const _BadgeStyle(
          label: 'Hết hạn',
          icon: Icons.timer_off_outlined,
          background: AppColors.error,
          foreground: AppColors.white,
        );
      case LobbyStatusBadgeVariant.unknown:
        return const _BadgeStyle(
          label: 'Đang cập nhật…',
          icon: Icons.hourglass_empty,
          background: AppColors.textTertiary,
          foreground: AppColors.white,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;
    final shadowColor = isDark ? AppColors.black : AppColors.black;

    return Semantics(
      label: 'Trạng thái phòng: ${style.label}${showActiveIndicator ? ' (Hoạt động)' : ''}',
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: dense ? AppSpacing.sm : AppSpacing.md,
          vertical: dense ? AppSpacing.xs : AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: style.background,
          borderRadius: BorderRadius.circular(dense ? 8 : 10),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 0,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(style.icon, size: dense ? 14 : 16, color: style.foreground),
            SizedBox(width: dense ? 4 : AppSpacing.xs),
            Text(
              style.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: style.foreground,
                fontSize: dense ? 11 : 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.3,
              ),
            ),
            if (showActiveIndicator) ...[
              const SizedBox(width: 4),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: style.foreground,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}