import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../lobby_management/domain/entities/lobby_entity.dart';
import '../../domain/entities/entities.dart';

/// Modern Boardgame Reservation Card — Game Store style.
///
/// **Design:**
/// - Vibrant gradient "artwork" cover chiếm ~55% card height — đây là điểm
///   visual focal, khiến card trông như poster game trên App Store.
/// - Content bên dưới: game name TO + cafe + stats grid 3 cột (icon/value stack).
/// - Status badge đặt absolute trên cover (góc trên-trái), countdown góc phải.
/// - Không có "CỦA BẠN" ribbon lệch — thay bằng border 2.5px cam nổi bật.
/// - Decor pattern chỉ là subtle circles/dots ở góc phải cover, không icon to.
/// - Soft shadow colored theo variant.
class ReservationCardModern extends StatelessWidget {
  final ReservationEntity reservation;
  final bool isOwnedByMe;
  final VoidCallback? onTap;

  const ReservationCardModern({
    super.key,
    required this.reservation,
    this.isOwnedByMe = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final variant = _resolveVariant(reservation);
    final style = _CardStyleModern.forVariant(variant);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Resolve vai trò của user với reservation này:
    // - Host: border + shadow tone cam (primary) + bold border.
    // - Member: border + shadow tone xanh dương (info) + bold border.
    //
    // Mục tiêu UX: player phân biệt được "Tôi tạo" vs "Tôi tham gia" chỉ
    // qua việc nhìn UI/UX (không cần đọc text). Màu sắc + độ dày border
    // là tín hiệu thị giác rõ ràng nhất.
    final participation = reservation.effectiveParticipationType;
    final borderColor = isDark
        ? AppColors.borderDark
        : AppColors.border;
    final roleBorderColor = participation == ReservationParticipationType.host
        ? AppColors.primary
        : AppColors.info;
    final roleShadowColor = participation == ReservationParticipationType.host
        ? AppColors.primary
        : AppColors.info;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surface,
          borderRadius: AppRadius.radiusXlAll,
          border: Border.all(
            color: isOwnedByMe ? roleBorderColor : borderColor,
            width: isOwnedByMe ? 2.5 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              // Shadow tone theo participation type — Host cam, Member xanh.
              // Khi reservation là của user (host) → shadow tone cam đậm.
              // Khi member → shadow tone xanh nhẹ (vẫn nổi bật nhưng tách biệt).
              color: isOwnedByMe
                  ? roleShadowColor.withValues(alpha: 0.28)
                  : style.gradientColors.first.withValues(alpha: 0.18),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ═══════════════════════════════════════════════
            // ARTWORK COVER — vibrant gradient + soft patterns
            // ═══════════════════════════════════════════════
            _ArtworkCover(
              reservation: reservation,
              style: style,
            ),

            // ═══════════════════════════════════════════════
            // CONTENT — compact spacing
            // ═══════════════════════════════════════════════
            Padding(
              padding: const EdgeInsets.fromLTRB(
                12,
                10,
                12,
                12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Game name ───────────────────────────
                  // 1 dòng max để card có height ổn định; tên dài ellipsis,
                  // user bấm vào chi tiết để xem full.
                  Text(
                    reservation.gameName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),

                  const SizedBox(height: 3),

                  // ── Cafe name ───────────────────────────
                  Row(
                    children: [
                      Icon(
                        Icons.storefront_outlined,
                        size: 12,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          reservation.cafeName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.xs),

                  // ── Stats row — compact inline ───────────
                  _StatsRowCompact(
                    reservation: reservation,
                    style: style,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static _CardVariant _resolveVariant(ReservationEntity r) {
    final status = r.status;
    final lobbyStatus = r.lobbyStatus;

    if (status.isTerminal) {
      switch (status) {
        case ReservationStatus.rejectedByCafe:
        case ReservationStatus.cancelledByCafe:
          return _CardVariant.rejected;
        case ReservationStatus.cancelledByPlayer:
        case ReservationStatus.cancelledByHost:
          return _CardVariant.cancelled;
        case ReservationStatus.expired:
          return _CardVariant.expired;
        case ReservationStatus.noShow:
        case ReservationStatus.completed:
        case ReservationStatus.earlyCheckout:
          return _CardVariant.completed;
        default:
          break;
      }
    }

    switch (status) {
      case ReservationStatus.draft:
      case ReservationStatus.awaitingDeposit:
        return _CardVariant.pending;
      case ReservationStatus.holding:
        if (lobbyStatus == LobbyStatus.pendingCafeApproval) {
          return _CardVariant.pending;
        }
        return _CardVariant.confirmed;
      case ReservationStatus.confirmed:
        if (lobbyStatus == LobbyStatus.waitingCheckIn) {
          return _CardVariant.waitingCheckin;
        }
        return _CardVariant.confirmed;
      case ReservationStatus.checkedIn:
        return _CardVariant.checkedIn;
      default:
        break;
    }

    return _CardVariant.unknown;
  }
}

// ═══════════════════════════════════════════════════════════════════════
// VARIANT
// ═══════════════════════════════════════════════════════════════════════

enum _CardVariant {
  recruiting,
  viable,
  full,
  pending,
  waitingCheckin,
  confirmed,
  checkedIn,
  playing,
  rating,
  completed,
  cancelled,
  rejected,
  expired,
  unknown,
}

// ═══════════════════════════════════════════════════════════════════════
// STYLE
// ═══════════════════════════════════════════════════════════════════════

class _CardStyleModern {
  /// Gradient colors cho artwork cover (2 màu).
  final List<Color> gradientColors;

  /// Accent color cho stats highlight.
  final Color accent;

  /// Label status.
  final String statusLabel;

  /// Icon status.
  final IconData statusIcon;

  /// Màu background status pill (trên cover).
  final Color statusBadgeBg;

  /// Màu text status pill.
  final Color statusBadgeFg;

  /// Icon trang trí ở góc (cho soft pattern).
  final IconData decorIcon;

  const _CardStyleModern({
    required this.gradientColors,
    required this.accent,
    required this.statusLabel,
    required this.statusIcon,
    required this.statusBadgeBg,
    required this.statusBadgeFg,
    required this.decorIcon,
  });

  static _CardStyleModern forVariant(_CardVariant v) {
    switch (v) {
      case _CardVariant.recruiting:
        return const _CardStyleModern(
          gradientColors: [Color(0xFF667eea), Color(0xFF764ba2)],
          accent: Color(0xFF667eea),
          statusLabel: 'Tuyển người',
          statusIcon: Icons.group_add_rounded,
          statusBadgeBg: Color(0xFFFFFFFF),
          statusBadgeFg: Color(0xFF4F62E8),
          decorIcon: Icons.casino_rounded,
        );

      case _CardVariant.viable:
        return const _CardStyleModern(
          gradientColors: [Color(0xFF11998e), Color(0xFF38ef7d)],
          accent: Color(0xFF11998e),
          statusLabel: 'Sẵn sàng',
          statusIcon: Icons.check_circle_rounded,
          statusBadgeBg: Color(0xFFFFFFFF),
          statusBadgeFg: Color(0xFF0E8A68),
          decorIcon: Icons.extension_rounded,
        );

      case _CardVariant.full:
        return const _CardStyleModern(
          gradientColors: [Color(0xFF43cea2), Color(0xFF185a9d)],
          accent: Color(0xFF43cea2),
          statusLabel: 'Phòng đầy',
          statusIcon: Icons.groups_rounded,
          statusBadgeBg: Color(0xFFFFFFFF),
          statusBadgeFg: Color(0xFF1E7FD4),
          decorIcon: Icons.celebration_rounded,
        );

      case _CardVariant.confirmed:
        return const _CardStyleModern(
          gradientColors: [Color(0xFF00b09b), Color(0xFF96c93d)],
          accent: Color(0xFF00b09b),
          statusLabel: 'Đã xác nhận',
          statusIcon: Icons.check_rounded,
          statusBadgeBg: Color(0xFFFFFFFF),
          statusBadgeFg: Color(0xFF0D8A5A),
          decorIcon: Icons.verified_rounded,
        );

      case _CardVariant.waitingCheckin:
        return const _CardStyleModern(
          gradientColors: [Color(0xFFf093fb), Color(0xFFf5576c)],
          accent: Color(0xFFf5576c),
          statusLabel: 'Chờ check-in',
          statusIcon: Icons.pin_drop_rounded,
          statusBadgeBg: Color(0xFFFFFFFF),
          statusBadgeFg: Color(0xFFD42044),
          decorIcon: Icons.location_on_rounded,
        );

      case _CardVariant.checkedIn:
        return const _CardStyleModern(
          gradientColors: [Color(0xFF30cfd0), Color(0xFF330867)],
          accent: Color(0xFF30cfd0),
          statusLabel: 'Đã check-in',
          statusIcon: Icons.touch_app_rounded,
          statusBadgeBg: Color(0xFFFFFFFF),
          statusBadgeFg: Color(0xFF0E8A8A),
          decorIcon: Icons.wifi_tethering_rounded,
        );

      case _CardVariant.pending:
        return const _CardStyleModern(
          gradientColors: [Color(0xFFf7971e), Color(0xFFFFD200)],
          accent: Color(0xFFf7971e),
          statusLabel: 'Chờ duyệt',
          statusIcon: Icons.hourglass_top_rounded,
          statusBadgeBg: Color(0xFFFFFFFF),
          statusBadgeFg: Color(0xFFD07000),
          decorIcon: Icons.schedule_rounded,
        );

      case _CardVariant.playing:
        return const _CardStyleModern(
          gradientColors: [Color(0xFFFF6A00), Color(0xFFEE0979)],
          accent: Color(0xFFFF6A00),
          statusLabel: 'Đang chơi',
          statusIcon: Icons.sports_esports_rounded,
          statusBadgeBg: Color(0xFFFFFFFF),
          statusBadgeFg: Color(0xFFCC4400),
          decorIcon: Icons.sports_esports_rounded,
        );

      case _CardVariant.rating:
        return const _CardStyleModern(
          gradientColors: [Color(0xFFFFC107), Color(0xFFFF8A50)],
          accent: Color(0xFFFF8A50),
          statusLabel: 'Đánh giá',
          statusIcon: Icons.star_rounded,
          statusBadgeBg: Color(0xFFFFFFFF),
          statusBadgeFg: Color(0xFFCC6633),
          decorIcon: Icons.star_rounded,
        );

      case _CardVariant.completed:
        return const _CardStyleModern(
          gradientColors: [Color(0xFF5C6BC0), Color(0xFF3949AB)],
          accent: Color(0xFF5C6BC0),
          statusLabel: 'Hoàn thành',
          statusIcon: Icons.task_alt_rounded,
          statusBadgeBg: Color(0xFFFFFFFF),
          statusBadgeFg: Color(0xFF3949AB),
          decorIcon: Icons.emoji_events_rounded,
        );

      case _CardVariant.cancelled:
        return const _CardStyleModern(
          gradientColors: [Color(0xFF78909C), Color(0xFF455A64)],
          accent: Color(0xFF78909C),
          statusLabel: 'Đã hủy',
          statusIcon: Icons.cancel_rounded,
          statusBadgeBg: Color(0xFFFFFFFF),
          statusBadgeFg: Color(0xFF455A64),
          decorIcon: Icons.cancel_rounded,
        );

      case _CardVariant.rejected:
        return const _CardStyleModern(
          gradientColors: [Color(0xFFEB3349), Color(0xFFF45C43)],
          accent: Color(0xFFEB3349),
          statusLabel: 'Bị từ chối',
          statusIcon: Icons.block_rounded,
          statusBadgeBg: Color(0xFFFFFFFF),
          statusBadgeFg: Color(0xFFCC2020),
          decorIcon: Icons.block_rounded,
        );

      case _CardVariant.expired:
        return const _CardStyleModern(
          gradientColors: [Color(0xFF90A4AE), Color(0xFF546E7A)],
          accent: Color(0xFF90A4AE),
          statusLabel: 'Hết hạn',
          statusIcon: Icons.timer_off_rounded,
          statusBadgeBg: Color(0xFFFFFFFF),
          statusBadgeFg: Color(0xFF546E7A),
          decorIcon: Icons.timer_off_rounded,
        );

      case _CardVariant.unknown:
        return const _CardStyleModern(
          gradientColors: [Color(0xFF607D8B), Color(0xFF263238)],
          accent: Color(0xFF607D8B),
          statusLabel: 'Đang cập nhật',
          statusIcon: Icons.help_outline_rounded,
          statusBadgeBg: Color(0xFFFFFFFF),
          statusBadgeFg: Color(0xFF263238),
          decorIcon: Icons.help_outline_rounded,
        );
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════
// ARTWORK COVER — Vibrant gradient + subtle patterns + badges
// ═══════════════════════════════════════════════════════════════════════

class _ArtworkCover extends StatelessWidget {
  final ReservationEntity reservation;
  final _CardStyleModern style;

  const _ArtworkCover({
    required this.reservation,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: style.gradientColors,
        ),
      ),
      child: Stack(
        children: [
          // ── Subtle pattern: decor icon ở góc phải-dưới ───────
          Positioned(
            right: -12,
            bottom: -12,
            child: Icon(
              style.decorIcon,
              size: 70,
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          // ── Subtle pattern 2: casino ở góc trái-trên ──────────
          Positioned(
            left: -6,
            top: -6,
            child: Icon(
              Icons.casino_rounded,
              size: 40,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          // ── Subtle pattern 3: dots decoration (top-right) ──────
          Positioned(
            right: 8,
            top: 8,
            child: Opacity(
              opacity: 0.18,
              child: CustomPaint(
                size: const Size(24, 24),
                painter: _DotsPatternPainter(),
              ),
            ),
          ),

          // ── Status pill (top-left) ─────────────────────────────
          Positioned(
            top: AppSpacing.xs,
            left: AppSpacing.xs,
            child: _StatusPill(
              label: style.statusLabel,
              icon: style.statusIcon,
              fg: style.statusBadgeFg,
            ),
          ),

          // ── Countdown (top-right) — chỉ khi còn <24h ──────────
          if (_showCountdown(reservation))
            Positioned(
              top: AppSpacing.xs,
              right: AppSpacing.xs,
              child: _CountdownChip(
                deadline: reservation.recruitmentDeadline!,
              ),
            ),

          // ── Lobby share code (bottom-right) ────────────────────
          if (reservation.lobbyShareCode != null &&
              reservation.lobbyShareCode!.isNotEmpty)
            Positioned(
              bottom: AppSpacing.xs,
              right: AppSpacing.xs,
              child: _CodeChip(code: reservation.lobbyShareCode!),
            ),
        ],
      ),
    );
  }

  bool _showCountdown(ReservationEntity r) {
    if (r.recruitmentDeadline == null) return false;
    final diff = r.recruitmentDeadline!.difference(DateTime.now());
    return !diff.isNegative && diff.inHours < 24;
  }
}

/// Pattern dots nhỏ — trang trí subtle.
class _DotsPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    const spacing = 6.0;
    final radius = 1.5;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════════════
// STATUS PILL — White glassy pill on top of gradient
// ═══════════════════════════════════════════════════════════════════════

class _StatusPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color fg;

  const _StatusPill({
    required this.label,
    required this.icon,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: fg,
              letterSpacing: 0.2,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// COUNTDOWN CHIP
// ═══════════════════════════════════════════════════════════════════════

class _CountdownChip extends StatelessWidget {
  final DateTime deadline;

  const _CountdownChip({required this.deadline});

  @override
  Widget build(BuildContext context) {
    final diff = deadline.difference(DateTime.now());
    Color bg;
    Color fg;
    IconData icon;
    if (diff.inHours < 2) {
      bg = const Color(0xFFFFEBEE);
      fg = const Color(0xFFD32F2F);
      icon = Icons.timer_outlined;
    } else if (diff.inHours < 6) {
      bg = const Color(0xFFFFF8E1);
      fg = const Color(0xFFF57C00);
      icon = Icons.timer_outlined;
    } else {
      bg = const Color(0xFFFFFFFF);
      fg = const Color(0xFF424242);
      icon = Icons.timer_outlined;
    }

    final label = diff.inMinutes <= 0
        ? 'Hết hạn'
        : (diff.inHours < 1
            ? '${diff.inMinutes}p'
            : '${diff.inHours}h');

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: fg,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// CODE CHIP
// ═══════════════════════════════════════════════════════════════════════

class _CodeChip extends StatelessWidget {
  final String code;

  const _CodeChip({required this.code});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.tag_rounded, size: 11, color: Color(0xFF424242)),
          const SizedBox(width: 4),
          Text(
            code,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
              color: Color(0xFF424242),
              letterSpacing: 0.6,
              fontFeatures: [FontFeature.tabularFigures()],
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// STATS ROW COMPACT — inline icon + value (không có label)
// ═══════════════════════════════════════════════════════════════════════

class _StatsRowCompact extends StatelessWidget {
  final ReservationEntity reservation;
  final _CardStyleModern style;
  final bool isDark;

  const _StatsRowCompact({
    required this.reservation,
    required this.style,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final hasDeposit = reservation.finalDeposit > 0;
    final timeColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimary;
    final timeIconColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;
    final playersColor = reservation.isLobbyFull
        ? style.accent
        : timeColor;
    final playersIconColor = reservation.isLobbyFull
        ? style.accent
        : timeIconColor;

    final timeItem = _StatItemCompact(
      icon: Icons.schedule_rounded,
      value: DateFormatter.timeOnly(reservation.scheduledTime),
      valueColor: timeColor,
      iconColor: timeIconColor,
    );
    final playersItem = _StatItemCompact(
      icon: Icons.group_rounded,
      value: '${reservation.currentPlayers}/${reservation.maxPlayers}',
      valueColor: playersColor,
      iconColor: playersIconColor,
    );
    final depositItem = hasDeposit
        ? _StatItemCompact(
            icon: Icons.account_balance_wallet_rounded,
            value: '${_formatBvc(reservation.finalDeposit)} BVC',
            valueColor: style.accent,
            iconColor: style.accent,
          )
        : null;

    // ── Multi-row layout để tránh overflow ngang ─────────────
    // Trước đây dùng Row chia 3 cột đều → mỗi cột chỉ ~50px, text
    // dài như "12:30", "12/20", "100k BVC" bị ellipsis. Đổi sang:
    //   - 3 items: 2 dòng (time+players dòng 1, deposit dòng 2 full)
    //   - 2 items: 2 dòng (time dòng 1, players dòng 2)
    // Mỗi dòng item full-width nên text không bao giờ bị cắt.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: timeItem),
            const SizedBox(width: AppSpacing.xs),
            Expanded(child: playersItem),
          ],
        ),
        if (depositItem != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: depositItem),
            ],
          ),
        ],
      ],
    );
  }

  String _formatBvc(int amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    }
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}k';
    }
    return '$amount';
  }
}

class _StatItemCompact extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color valueColor;
  final Color iconColor;

  const _StatItemCompact({
    required this.icon,
    required this.value,
    required this.valueColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    // Mỗi stat item giờ là full-width (Expanded) trong Column — left-align
    // sạch sẽ hơn center khi text dài ngắn khác nhau. Padding pill ngầm
    // tạo visual grouping.
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: iconColor),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: valueColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}
