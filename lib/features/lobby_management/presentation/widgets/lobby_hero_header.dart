import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:boardverse/core/theme/app_colors.dart';
import 'package:boardverse/core/theme/app_icons.dart';
import 'package:boardverse/core/theme/app_spacing.dart';
import 'package:boardverse/features/lobby_management/domain/entities/lobby_entity.dart';
import 'package:boardverse/features/reservation/domain/entities/entities.dart' as res;

/// Hero header cho LobbyPage — layout mới (2026-08):
///
/// - Cafe info (avatar + tên + địa điểm) ở hàng trên cùng
/// - Tiêu đề game nổi bật + **QR mini code của lobby** ở góc phải (khi
///   lobby ready + có reservation) — thay cho nút "Xem chi tiết" cũ để
///   UX liền mạch: player thấy QR ngay trên hero, không cần scroll xuống.
///   Khi lobby chưa ready (open), vẫn hiển thị icon info như cũ.
/// - 3 stat card (Thành viên / Chế độ / Mã mời) ở dưới
///
/// Style neo-brutalism với border đậm + hard shadow nhưng **ít chen chúc**
/// hơn bản cũ (bỏ countdown `LobbyCountdownTimer` ở header → chuyển vào
/// status strip nếu cần sau).
class LobbyHeroHeader extends StatelessWidget {
  final LobbyEntity lobby;
  final ThemeData theme;

  /// Reservation hiện tại của player trong lobby (optional). Khi lobby đã
  /// ready (viable/full) mà reservation đã `Confirmed`/`CheckedIn`, header
  /// sẽ hiển thị QR mini của `reservation.id` thay cho icon "Xem chi tiết"
  /// — POS staff có thể quét QR này trực tiếp trên hero header.
  final res.ReservationEntity? reservation;

  /// Callback khi user bấm icon "Xem chi tiết" (chỉ dùng khi lobby chưa
  /// ready, hoặc reservation null).
  final VoidCallback onShowDetails;

  /// Callback khi user bấm copy share code.
  final VoidCallback onShareInviteCode;

  /// Callback khi user bấm vào QR mini (mở full screen QR để staff dễ
  /// quét hơn — vẫn dùng `reservation.id`).
  final VoidCallback? onShowFullScreenQr;

  const LobbyHeroHeader({
    super.key,
    required this.lobby,
    required this.theme,
    required this.onShowDetails,
    required this.onShareInviteCode,
    this.reservation,
    this.onShowFullScreenQr,
  });

  /// Lobby đã ready để hiển thị QR mini ở hero header.
  ///
  /// Điều kiện (theo yêu cầu):
  /// 1. **Lobby ready** — `lobby.status.canCheckIn` (viable/full/inProgress)
  ///    HOẶC tất cả player đã nhấn "Sẵn sàng" (`players.every(isReady)`).
  /// 2. **Có dữ liệu encode QR** — xem [_qrPayload] (ưu tiên
  ///    `reservation.id` đã Confirmed/CheckedIn, fallback
  ///    `lobby.reservationId`, cuối cùng `lobby.id`).
  ///
  /// Khi lobby chưa ready (open/pending cafe approval/vv.) → vẫn hiển
  /// thị icon info cũ, không phá UX.
  ///
  /// Vì sao KHÔNG bắt buộc `reservation != null`:
  ///   Khi user vừa vào LobbyPage, `LobbyReservationCubit` đang ở
  ///   `Loading`/`Initial` → `reservation` trong BlocBuilder là null. UI
  ///   sẽ flash "Xem chi tiết" → đợi 200-500ms → flash QR. Bằng cách
  ///   fallback về `lobby.reservationId` (đã có trong entity), QR hiện
  ///   ngay frame đầu, UX liền mạch. POS scanner flow `lookup by
  ///   reservationId` đã chấp nhận dạng UUID này.
  bool get _showQrInsteadOfInfo {
    final players = lobby.players;
    final allPlayersReady =
        players.isNotEmpty && players.every((p) => p.isReady);
    final lobbyReady = lobby.status.canCheckIn || allPlayersReady;
    if (!lobbyReady) return false;
    return _qrPayload != null;
  }

  /// Payload encode vào QR mini — ưu tiên reservation ID, fallback về
  /// `lobby.reservationId`, cuối cùng là `lobby.id`.
  ///
  /// ReservationEntity status Confirmed/CheckedIn được ưu tiên hơn
  /// `lobby.reservationId` vì ReservationEntity là source of truth cho
  /// POS check-in (lobby.reservationId chỉ là reference).
  String? get _qrPayload {
    if (reservation != null &&
        (reservation!.status == res.ReservationStatus.confirmed ||
            reservation!.status == res.ReservationStatus.checkedIn)) {
      return reservation!.id;
    }
    if (lobby.reservationId != null && lobby.reservationId!.isNotEmpty) {
      return lobby.reservationId;
    }
    if (lobby.id.isNotEmpty) return lobby.id;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final capacityProgress = lobby.maxPlayers == 0
        ? 0.0
        : (lobby.currentPlayers / lobby.maxPlayers).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        0,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Row 1: Cafe info ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              0,
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.white.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    AppIcons.cafe,
                    color: AppColors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lobby.cafeName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: AppColors.white,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Giờ hẹn: ${lobby.scheduledTime.hour.toString().padLeft(2, '0')}:${lobby.scheduledTime.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          color: AppColors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // QR mini code khi lobby ready — thay cho "Xem chi tiết".
                // Lý do: khi lobby đã viable/full, điều player quan tâm nhất
                // là show QR cho staff quét, không phải xem chi tiết. Đặt
                // QR ngay tại hero header giúp liền mạch với flow check-in
                // (vẫn có QR đầy đủ ở LobbyCheckInSection bên dưới).
                //
                // Payload lấy từ [_qrPayload] — reservation.id nếu đã
                // Confirmed/CheckedIn, fallback lobby.reservationId / lobby.id.
                if (_showQrInsteadOfInfo)
                  _HeroQrBadge(
                    reservationId: _qrPayload!,
                    onTap: onShowFullScreenQr,
                  )
                else
                  _HeroIconButton(
                    icon: AppIcons.info,
                    onTap: onShowDetails,
                  ),
              ],
            ),
          ),

          // ── Row 2: Game title (nổi bật) ───────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              0,
            ),
            child: Text(
              lobby.gameName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w900,
                fontSize: 22,
                letterSpacing: -0.5,
                height: 1.15,
              ),
            ),
          ),

          // ── Row 3: 3 stat cards (Thành viên / Chế độ / Mã mời) ───
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: Row(
              children: [
                Expanded(
                  child: HeroStat(
                    label: 'Thành viên',
                    value: '${lobby.currentPlayers}/${lobby.maxPlayers}',
                    icon: AppIcons.users,
                    progress: capacityProgress,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: HeroStat(
                    label: 'Chế độ',
                    value: lobby.isPublic ? 'Công khai' : 'Riêng tư',
                    icon: lobby.isPublic ? AppIcons.globe : AppIcons.lock,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: lobby.inviteCode != null
                      ? InviteCodeStat(
                          code: lobby.inviteCode!,
                          onTap: onShareInviteCode,
                        )
                      : HeroStat(
                          label: 'Slot trống',
                          value: lobby.slotsRemaining.toString(),
                          icon: AppIcons.userAdd,
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

/// Nút icon tròn trong hero header (neo-brutalism mini).
///
/// Lưu ý: KHÔNG wrap trong [Tooltip] — Tooltip trên Chrome/Web trigger
/// `mouse_tracker.dart:199:12` assertion khi widget rebuild trong
/// `CustomScrollView` (mỗi frame Flutter đều re-evaluate Tooltip's
/// mouse region, gây "An annotation already exists for device X").
/// Nếu cần tooltip, dùng semanticLabel + showDialog thay thế.
class _HeroIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeroIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Xem chi tiết',
      child: Material(
        color: AppColors.white.withValues(alpha: 0.2),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            child: Icon(icon, size: 20, color: AppColors.white),
          ),
        ),
      ),
    );
  }
}

/// QR mini badge hiển thị ở góc phải hero header khi lobby ready.
///
/// Kích thước 56×56 px (compact) — đủ để staff scanner bắt được trên
/// thiết bị POS di động, đồng thời không chiếm quá nhiều diện tích
/// hero header. Bấm vào sẽ mở full-screen QR để staff dễ scan.
///
/// Encode `reservation.id` (UUID 36-char) — POS scanner sẽ đọc được UUID
/// này và gọi `/api/v1/reservations/{reservationId}/check-in` để staff
/// check-in player (BR §21A.7).
class _HeroQrBadge extends StatelessWidget {
  final String reservationId;
  final VoidCallback? onTap;

  const _HeroQrBadge({
    required this.reservationId,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Mã QR check-in cho staff quét',
      child: Material(
        color: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 56,
            height: 56,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.white,
                width: 1.5,
              ),
            ),
            child: QrImageView(
              data: reservationId,
              version: QrVersions.auto,
              size: 48,
              backgroundColor: AppColors.white,
              errorCorrectionLevel: QrErrorCorrectLevel.M,
              padding: EdgeInsets.zero,
            ),
          ),
        ),
      ),
    );
  }
}

/// Stat item trong hero header, có thể có progress bar.
class HeroStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final double? progress;

  const HeroStat({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.white.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 14,
                color: AppColors.white.withValues(alpha: 0.85),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.white.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: AppColors.white,
              fontSize: 14,
            ),
          ),
          if (progress != null) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: AppColors.white.withValues(alpha: 0.25),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Stat card hiển thị mã mời — có thể bấm copy.
class InviteCodeStat extends StatelessWidget {
  final String code;
  final VoidCallback onTap;

  const InviteCodeStat({
    super.key,
    required this.code,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.white.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    AppIcons.copy,
                    size: 14,
                    color: AppColors.white.withValues(alpha: 0.85),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Mã mời',
                    style: TextStyle(
                      color: AppColors.white.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                code,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}