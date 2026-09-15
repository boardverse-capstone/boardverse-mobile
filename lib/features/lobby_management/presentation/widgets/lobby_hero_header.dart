import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:boardverse/core/theme/app_colors.dart';
import 'package:boardverse/core/theme/app_icons.dart';
import 'package:boardverse/core/theme/app_spacing.dart';
import 'package:boardverse/core/theme/neo_brutalism_theme.dart';
import 'package:boardverse/features/lobby_management/domain/entities/lobby_entity.dart';
import 'package:boardverse/features/reservation/domain/entities/entities.dart' as res;

/// Hero header cho LobbyPage:
///
/// - Header solid AppColors.primary với neo-brutalism border
/// - Cafe info (avatar + tên + thời gian)
/// - Tiêu đề game nổi bật với decorative underline
/// - 2 stat card dọc: Chế độ và Mã mời
/// - QR mini code khi lobby ready
///
/// Style: Neo-brutalism với solid brand color.
class LobbyHeroHeader extends StatelessWidget {
  final LobbyEntity lobby;
  final ThemeData theme;

  /// Reservation hiện tại của player trong lobby (optional).
  final res.ReservationEntity? reservation;

  /// Callback khi user bấm icon "Xem chi tiết".
  final VoidCallback onShowDetails;

  /// Callback khi user bấm copy share code.
  final VoidCallback onShareInviteCode;

  /// Callback khi user bấm vào QR mini.
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

  /// Lobby đã ready để hiển thị QR mini.
  bool get _showQrInsteadOfInfo {
    final players = lobby.players;
    final allPlayersReady =
        players.isNotEmpty && players.every((p) => p.isReady);
    final lobbyReady = lobby.status.canCheckIn || allPlayersReady;
    if (!lobbyReady) return false;
    return _qrPayload != null;
  }

  /// Payload encode vào QR mini.
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

          // ── Row 1: Cafe info + QR/Info button ────────────────────
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
                // QR or Info button
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

/// QR mini badge hiển thị khi lobby ready.
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
      label: 'Mã QR check-in',
      child: Material(
        color: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 56,
            height: 56,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.white,
                width: 2,
              ),
            ),
            child: QrImageView(
              data: reservationId,
              version: QrVersions.auto,
              size: 46,
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
