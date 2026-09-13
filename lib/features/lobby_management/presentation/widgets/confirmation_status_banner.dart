import 'package:flutter/material.dart';

import 'package:boardverse/core/theme/app_colors.dart';
import 'package:boardverse/core/theme/app_spacing.dart';
import '../../../reservation/domain/entities/entities.dart';
import '../../domain/entities/lobby_entity.dart';

/// Banner hiển thị trạng thái booking xuyên suốt giai đoạn "Sau lobby FULL
/// → trước khi đến quán". Phân biệt 3 case dựa trên
/// `ReservationStatus` + `LobbyStatus`:
/// - Confirmed + Full (lobby đầy) → banner xanh lá "✅ Booking đã xác nhận"
/// - Confirmed + Viable (đủ min, vẫn nhận thêm) → banner vàng "⏳ Lobby đạt tối thiểu"
/// - Holding (chưa confirmed) → banner info "🕒 Cần thêm người"
/// - Cancelled/Rejected → banner đỏ "❌ Đã hủy"
/// - NoShow → banner cam "⚠️ Bạn đã không đến"
class ConfirmationStatusBanner extends StatelessWidget {
  final ReservationStatus reservationStatus;
  final LobbyStatus? lobbyStatus;
  final DateTime scheduledTime;
  final int currentPlayers;
  final int minPlayers;
  final int maxPlayers;

  /// Số người còn cần tuyển (chỉ áp dụng cho banner Holding).
  final int playersNeededToConfirm;

  const ConfirmationStatusBanner({
    super.key,
    required this.reservationStatus,
    required this.lobbyStatus,
    required this.scheduledTime,
    required this.currentPlayers,
    required this.minPlayers,
    required this.maxPlayers,
    this.playersNeededToConfirm = 0,
  });

  _BannerVariant _resolveVariant() {
    if (reservationStatus == ReservationStatus.cancelledByPlayer ||
        reservationStatus == ReservationStatus.cancelledByCafe ||
        reservationStatus == ReservationStatus.cancelledByHost ||
        reservationStatus == ReservationStatus.rejectedByCafe) {
      return _BannerVariant.cancelled;
    }
    if (reservationStatus == ReservationStatus.noShow) {
      return _BannerVariant.noShow;
    }
    if (reservationStatus == ReservationStatus.expired) {
      return _BannerVariant.expired;
    }

    if (reservationStatus == ReservationStatus.confirmed ||
        reservationStatus == ReservationStatus.checkedIn) {
      final ls = lobbyStatus;
      if (ls == LobbyStatus.full || currentPlayers >= maxPlayers) {
        return _BannerVariant.confirmedFull;
      }
      if (ls == LobbyStatus.viable || currentPlayers >= minPlayers) {
        return _BannerVariant.confirmedViable;
      }
      return _BannerVariant.confirmedFull;
    }

    if (reservationStatus == ReservationStatus.holding) {
      return _BannerVariant.holding;
    }

    if (reservationStatus == ReservationStatus.awaitingDeposit) {
      return _BannerVariant.awaitingDeposit;
    }

    return _BannerVariant.idle;
  }

  String _formatTime() {
    final local = scheduledTime.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final variant = _resolveVariant();
    if (variant == _BannerVariant.idle) return const SizedBox.shrink();

    final cfg = _BannerConfig.fromVariant(variant);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cfg.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.4),
            blurRadius: 0,
            offset: const Offset(4, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.border,
                width: 2,
              ),
            ),
            child: Icon(cfg.icon, color: cfg.foregroundColor, size: 24),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cfg.title,
                  style: TextStyle(
                    color: cfg.foregroundColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  cfg.subtitle(
                    scheduledTimeText: _formatTime(),
                    playersNeeded: playersNeededToConfirm,
                  ),
                  style: TextStyle(
                    color: cfg.foregroundColor.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _BannerVariant {
  idle,
  awaitingDeposit,
  holding,
  confirmedFull,
  confirmedViable,
  cancelled,
  noShow,
  expired,
}

class _BannerConfig {
  final Color color;
  final Color foregroundColor;
  final IconData icon;
  final String title;
  final String Function({
    required String scheduledTimeText,
    required int playersNeeded,
  }) subtitle;

  const _BannerConfig({
    required this.color,
    required this.foregroundColor,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  factory _BannerConfig.fromVariant(_BannerVariant v) {
    switch (v) {
      case _BannerVariant.awaitingDeposit:
        return _BannerConfig(
          color: AppColors.warning,
          foregroundColor: AppColors.black,
          icon: Icons.hourglass_top_rounded,
          title: 'Chờ thanh toán cọc',
          subtitle: ({required scheduledTimeText, required playersNeeded}) =>
              'Hoàn tất thanh toán cọc để xác nhận booking. Sau khi xong, '
              'lobby sẽ được đăng tuyển.',
        );
      case _BannerVariant.holding:
        return _BannerConfig(
          color: AppColors.info,
          foregroundColor: AppColors.white,
          icon: Icons.people_alt_rounded,
          title: 'Cần thêm người',
          subtitle: ({required scheduledTimeText, required playersNeeded}) =>
              'Còn ${playersNeeded > 0 ? playersNeeded : 1} người nữa để đạt '
              'minPlayers. Lobby sẽ tự xác nhận khi đủ người.',
        );
      case _BannerVariant.confirmedFull:
        return _BannerConfig(
          color: AppColors.success,
          foregroundColor: AppColors.white,
          icon: Icons.check_circle_rounded,
          title: 'Booking đã xác nhận',
          subtitle: ({required scheduledTimeText, required playersNeeded}) =>
              'Đến quán trước $scheduledTimeText. Đưa QR cho staff để check-in.',
        );
      case _BannerVariant.confirmedViable:
        return _BannerConfig(
          color: AppColors.accent,
          foregroundColor: AppColors.black,
          icon: Icons.access_time_filled_rounded,
          title: 'Lobby đạt tối thiểu',
          subtitle: ({required scheduledTimeText, required playersNeeded}) =>
              'Đã đủ minPlayers. Bạn có thể chờ thêm người hoặc đến quán '
              'trước $scheduledTimeText.',
        );
      case _BannerVariant.cancelled:
        return _BannerConfig(
          color: AppColors.error,
          foregroundColor: AppColors.white,
          icon: Icons.cancel_rounded,
          title: 'Đã hủy',
          subtitle: ({required scheduledTimeText, required playersNeeded}) =>
              'Booking này đã bị huỷ. Kiểm tra lịch sử để xem chi tiết hoàn cọc.',
        );
      case _BannerVariant.noShow:
        return _BannerConfig(
          color: AppColors.warning,
          foregroundColor: AppColors.black,
          icon: Icons.person_off_rounded,
          title: 'Bạn đã không đến',
          subtitle: ({required scheduledTimeText, required playersNeeded}) =>
              'Cọc có thể đã bị tịch thu theo chính sách quán. Mở lịch sử '
              'để xem chi tiết.',
        );
      case _BannerVariant.expired:
        return _BannerConfig(
          color: AppColors.error,
          foregroundColor: AppColors.white,
          icon: Icons.timer_off_rounded,
          title: 'Đã hết hạn',
          subtitle: ({required scheduledTimeText, required playersNeeded}) =>
              'Lobby không đạt minPlayers trước deadline. Cọc đã được hoàn.',
        );
      case _BannerVariant.idle:
        return _BannerConfig(
          color: AppColors.textSecondary,
          foregroundColor: AppColors.white,
          icon: Icons.info_outline_rounded,
          title: '',
          subtitle: ({required scheduledTimeText, required playersNeeded}) =>
              '',
        );
    }
  }
}