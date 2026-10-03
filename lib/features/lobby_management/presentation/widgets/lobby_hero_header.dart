import 'package:flutter/material.dart';

import 'package:boardverse/core/theme/app_colors.dart';
import 'package:boardverse/core/theme/app_icons.dart';
import 'package:boardverse/core/theme/app_spacing.dart';
import 'package:boardverse/core/theme/neo_brutalism_theme.dart';
import 'package:boardverse/features/lobby_management/domain/entities/lobby_entity.dart';

/// Hero header cho LobbyPage:
///
/// - Header solid AppColors.primary với neo-brutalism border
/// - Cafe info (avatar + tên + thời gian)
/// - Tiêu đề game nổi bật với decorative underline
/// - 2 stat card dọc: Chế độ và Mã mời
/// - **2 quick-access icon cố định ở góc trên-phải** (Phase 4
///   2026-10-02 — bidirectional linking):
///   1. Icon "Xem lịch hẹn chi tiết" (booking/calendar) — mở
///      `ReservationDetailPage`. Cặp với nút "Vào phòng chờ" trong
///      `ReservationDetailPage._PrimaryActionStrip` (đường về).
///   2. Icon "Xem chi tiết phòng" (info) — mở `LobbyDetailsSheet`
///      (overview mô tả, địa chỉ, thành viên, ...).
///   Trước đây khi lobby ready (viable/full/waitingCheckIn) header tự
///   đổi icon info thành QR mini code cho liền mạch flow check-in.
///   User feedback 2026-10-02: icon "Xem chi tiết" là nút duy nhất
///   để player mở bảng tổng quan (mô tả, địa chỉ quán, thành viên,
///   ...) — bị đổi thành QR khiến player không truy cập được. Giữ
///   nguyên icon info mọi lúc; QR full-screen vẫn truy cập được qua
///   entry point khác (`_LobbyCheckInSection` ở dưới).
///
/// Style: Neo-brutalism với solid brand color.
class LobbyHeroHeader extends StatelessWidget {
  final LobbyEntity lobby;
  final ThemeData theme;

  /// Callback khi user bấm icon "Xem chi tiết" (góc trên-phải hero).
  final VoidCallback onShowDetails;

  /// Callback khi user bấm copy share code.
  final VoidCallback onShareInviteCode;

  /// (Không còn dùng ở hero — giữ để tương thích caller.) Có thể được
  /// dùng cho entry point khác ở tương lai.
  final VoidCallback? onShowFullScreenQr;

  /// Callback khi user bấm icon "Xem lịch hẹn" (góc trên-phải hero,
  /// nằm cạnh icon "Xem chi tiết"). Đây là **đường liên kết ngược** từ
  /// lobby → reservation detail page — đảm bảo bidirectional linking
  /// với nút "Vào phòng chờ" trong `ReservationDetailPage` (xem
  /// `_PrimaryActionStrip` ở `reservation_detail_page.dart`).
  ///
  /// Optional: chỉ hiển thị icon khi callback được truyền (parent chỉ
  /// truyền khi `lobby.bookingId != null` — BR-XXI-B.1: backend
  /// `LobbyResponseDto.bookingId` = reservation ID; field
  /// `lobby.reservationId` là vestigial, luôn null). Lý do ẩn khi
  /// không có reservationId: lobby draft (chưa reserve) hoặc lobby
  /// đã terminal chưa map vào reservation → bấm vào sẽ noop, UX
  /// kỳ vọng bị phá.
  final VoidCallback? onShowReservation;

  const LobbyHeroHeader({
    super.key,
    required this.lobby,
    required this.theme,
    required this.onShowDetails,
    required this.onShareInviteCode,
    this.onShowFullScreenQr,
    this.onShowReservation,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        0,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: 3,
        ),
        boxShadow: NeoBrutalismTheme.lightShadow(
          shadowColor: AppColors.primary.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Top decorative bar ────────────────────────────────────
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.15),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(17),
                topRight: Radius.circular(17),
              ),
            ),
          ),

          // ── Row 1: Cafe info + Info button (luôn là icon chi tiết) ─
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              0,
            ),
            child: Row(
              children: [
                // Cafe avatar với border gradient
                _CafeAvatar(),
                const SizedBox(width: AppSpacing.md),
                // Cafe name + time
                Expanded(
                  child: _CafeInfo(lobby: lobby),
                ),
                // Icon "Xem lịch hẹn chi tiết" — nằm cạnh icon
                // "Xem chi tiết", tạo cặp quick-access ở góc trên-phải
                // hero header. Đây là **đường liên kết từ lobby → reservation
                // detail page** (bidirectional linking với nút "Vào phòng chờ"
                // trong ReservationDetailPage). Chỉ hiển thị khi parent
                // truyền `onShowReservation` (= lobby có reservationId).
                if (onShowReservation != null) ...[
                  const SizedBox(width: AppSpacing.xs),
                  _HeroIconButton(
                    icon: AppIcons.booking,
                    semanticLabel: 'Xem lịch hẹn chi tiết',
                    onTap: onShowReservation!,
                  ),
                ],
                // Icon "Xem chi tiết" — luôn hiển thị (xem comment class).
                _HeroIconButton(
                  icon: AppIcons.info,
                  semanticLabel: 'Xem chi tiết phòng',
                  onTap: onShowDetails,
                ),
              ],
            ),
          ),

          // ── Row 2: Game title với decorative line ────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.extension_rounded,
                        color: AppColors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        lobby.gameName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          letterSpacing: -0.3,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                // Decorative gradient line
                Container(
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.white.withValues(alpha: 0.6),
                        AppColors.white.withValues(alpha: 0.0),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),

          // ── Row 3: Stat cards (vertical) ─────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: Column(
              children: [
                // Chế độ
                _StatCard(
                  icon: lobby.isPublic ? AppIcons.globe : AppIcons.lock,
                  label: 'Chế độ',
                  value: lobby.isPublic ? 'Công khai' : 'Riêng tư',
                ),
                const SizedBox(height: AppSpacing.sm),
                // Mã mời
                if (lobby.inviteCode != null)
                  _InviteCodeCard(
                    code: lobby.inviteCode!,
                    onTap: onShareInviteCode,
                  )
                else
                  _StatCard(
                    icon: AppIcons.userAdd,
                    label: 'Slot trống',
                    value: lobby.slotsRemaining.toString(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Cafe avatar với gradient border.
class _CafeAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.white.withValues(alpha: 0.4),
            AppColors.white.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.white.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: const Icon(
        AppIcons.cafe,
        color: AppColors.white,
        size: 26,
      ),
    );
  }
}

/// Cafe info: name + scheduled time range + address.
///
/// Layout:
///
///   [Cafe Name]
///   [Address line]                       ← BR-NEW-15 / 2026-09-14:
///                                         backend bổ sung `cafeAddress`
///                                         trong `/lobbies/{id}` response.
///   [time badge: HH:mm – HH:mm]          ← BR-NEW-15 / 2026-09-14:
///                                         backend bổ sung `scheduledEndTime`.
///                                         Fallback chỉ start nếu end null.
class _CafeInfo extends StatelessWidget {
  final LobbyEntity lobby;

  const _CafeInfo({required this.lobby});

  @override
  Widget build(BuildContext context) {
    final startLabel = '${lobby.scheduledTime.hour.toString().padLeft(2, '0')}'
        ':${lobby.scheduledTime.minute.toString().padLeft(2, '0')}';
    final endTime = lobby.scheduledEndTime;
    final endLabel = endTime != null
        ? '${endTime.hour.toString().padLeft(2, '0')}'
              ':${endTime.minute.toString().padLeft(2, '0')}'
        : null;
    final rangeLabel = endLabel != null ? '$startLabel – $endLabel' : startLabel;

    final children = <Widget>[
      Text(
        lobby.cafeName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          color: AppColors.white,
          fontSize: 15,
        ),
      ),
    ];

    // Địa chỉ quán — chỉ render khi backend trả về `cafeAddress` non-empty.
    // Trước đây địa chỉ chỉ hiện trong LobbyCafeInfoCard (đã bỏ); nay
    // đưa vào hero header để player thấy ngay mà không cần mở chi tiết.
    final address = lobby.cafeAddress;
    if (address != null && address.isNotEmpty) {
      children.add(const SizedBox(height: 3));
      children.add(
        Row(
          children: [
            Icon(
              Icons.location_on_rounded,
              size: 11,
              color: AppColors.white.withValues(alpha: 0.75),
            ),
            const SizedBox(width: 3),
            Expanded(
              child: Text(
                address,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.white.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ],
        ),
      );
    }

    children.add(const SizedBox(height: 4));
    children.add(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.schedule_rounded,
              size: 12,
              color: AppColors.white.withValues(alpha: 0.9),
            ),
            const SizedBox(width: 4),
            Text(
              rangeLabel,
              style: TextStyle(
                color: AppColors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}

/// Stat card với icon, label, value.
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.white.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: AppColors.white.withValues(alpha: 0.85),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: TextStyle(
              color: AppColors.white.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: AppColors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

/// Invite code card với animation hover effect.
class _InviteCodeCard extends StatelessWidget {
  final String code;
  final VoidCallback onTap;

  const _InviteCodeCard({
    required this.code,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.white.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Label row
              Row(
                children: [
                  Icon(
                    AppIcons.copy,
                    size: 13,
                    color: AppColors.white.withValues(alpha: 0.85),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Mã mời',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.white.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.touch_app_rounded,
                    size: 12,
                    color: AppColors.white.withValues(alpha: 0.6),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Code value
              Text(
                code,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Nút icon tròn trong hero header.
class _HeroIconButton extends StatelessWidget {
  final IconData icon;

  /// Nhãn accessibility cho TalkBack/VoiceOver. Mặc định "Xem chi tiết"
  /// cho tương thích với caller cũ — widget chỉ render 1 icon info ở
  /// hero header. Khi thêm icon mới (vd: "Xem lịch hẹn chi tiết"), truyền
  /// `semanticLabel` riêng để user screen reader phân biệt được action.
  final String semanticLabel;

  final VoidCallback onTap;

  const _HeroIconButton({
    required this.icon,
    required this.onTap,
    this.semanticLabel = 'Xem chi tiết',
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: AppColors.white.withValues(alpha: 0.2),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.4),
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
