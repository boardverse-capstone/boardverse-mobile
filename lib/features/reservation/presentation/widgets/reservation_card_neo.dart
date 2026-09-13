import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../lobby_management/domain/entities/lobby_entity.dart';
import '../../domain/entities/entities.dart';

/// Neo-brutalism card hiển thị reservation — modern layout.
///
/// **Design:**
/// ```
/// ┌──────────────────────────────────────────┐
/// │ ▌ 🟦 STATUS   [Đã xác nhận]   countdown │  ← Colored sidebar + status
/// │ ▌                                          │
/// │ ▌ Catan                          ┐       │  ← Game name (large bold)
/// │ ▌ 📍 BoardGame Cafe              │       │  ← Cafe name (with icon)
/// │ ▌                                   │       │
/// │ ▌ ┌──────┬───────┬──────┬──────┐   │       │  ← Meta row (icon + label)
/// │ ▌ │ 20h  │ 3/6   │ 100k │ K7H3 │   │       │
/// │ ▌ └──────┴───────┴──────┴──────┘   ┘       │
/// └──────────────────────────────────────────┘
/// ```
///
/// **Status palette (semantic, dễ phân biệt):**
/// - `recruiting` / `viable` → **info (xanh dương)** — đang tuyển
/// - `full` / `confirmed` / `checkedIn` → **success (xanh lá)** — đã confirm
/// - `pendingCafeApproval` / `waitingCheckIn` → **warning (cam vàng)** — chờ duyệt
/// - `inProgress` → **primary (cam)** — đang chơi
/// - `ratingOpen` → **accent (vàng gold)** — đang đánh giá
/// - `closed` → **neutral (xám)** — đã đóng
/// - `rejectedByCafe` / `hostCancelled` / `expiredByCafe` / `expired` /
///   `timeoutFailed` → **error (đỏ)** — hủy/lỗi
class ReservationCardNeo extends StatelessWidget {
  final ReservationEntity reservation;

  /// `true` nếu đây là reservation của user hiện tại (host).
  final bool isOwnedByMe;

  final VoidCallback? onTap;

  const ReservationCardNeo({
    super.key,
    required this.reservation,
    this.isOwnedByMe = false,
    this.onTap,
  });

  /// Map reservation status → variant card.
  ///
  /// Logic giống `lobby_card_base.dart` nhưng gọn hơn cho reservation — vì
  /// chỉ cần resolve variant theo reservation (không cần fallback lobby).
  static _CardVariant _resolveVariant(ReservationEntity r) {
    final status = r.status;
    final lobbyStatus = r.lobbyStatus;

    // Terminal reservation → dùng reservation status trực tiếp.
    if (status.isTerminal) {
      switch (status) {
        case ReservationStatus.rejectedByCafe:
        case ReservationStatus.cancelledByCafe:
          return _CardVariant.rejectedByCafe;
        case ReservationStatus.cancelledByPlayer:
        case ReservationStatus.cancelledByHost:
          return _CardVariant.hostCancelled;
        case ReservationStatus.expired:
          return _CardVariant.expired;
        case ReservationStatus.noShow:
        case ReservationStatus.completed:
        case ReservationStatus.earlyCheckout:
          return _CardVariant.closed;
        default:
          break;
      }
    }

    // Active reservation.
    switch (status) {
      case ReservationStatus.draft:
      case ReservationStatus.awaitingDeposit:
        return _CardVariant.pendingCafeApproval;
      case ReservationStatus.holding:
        if (lobbyStatus == LobbyStatus.pendingCafeApproval) {
          return _CardVariant.pendingCafeApproval;
        }
        return _CardVariant.confirmed;
      case ReservationStatus.confirmed:
        if (lobbyStatus == LobbyStatus.waitingCheckIn) {
          return _CardVariant.waitingCheckIn;
        }
        return _CardVariant.confirmed;
      case ReservationStatus.checkedIn:
        return _CardVariant.checkedIn;
      default:
        break;
    }

    return _CardVariant.unknown;
  }

  @override
  Widget build(BuildContext context) {
    final variant = _resolveVariant(reservation);
    final style = _CardStyle.forVariant(variant);

    return _ReservationCardPressable(
      onTap: onTap,
      sidebarColor: style.sidebarColor,
      sidebarShadow: style.sidebarShadow,
      isOwnedByMe: isOwnedByMe,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Top row: status badge + countdown + isOwned ────────
            _TopRow(
              reservation: reservation,
              style: style,
              isOwnedByMe: isOwnedByMe,
            ),
            const SizedBox(height: AppSpacing.sm),

            // ── Game name ─────────────────────────────────────────
            Text(
              reservation.gameName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                height: 1.2,
                letterSpacing: -0.3,
              ),
            ),

            // ── Cafe row ──────────────────────────────────────────
            const SizedBox(height: AppSpacing.xxs),
            _CafeRow(cafeName: reservation.cafeName),
            const SizedBox(height: AppSpacing.sm),

            // ── Meta row ──────────────────────────────────────────
            _MetaRow(
              reservation: reservation,
              style: style,
            ),
          ],
        ),
      ),
    );
  }
}

enum _CardVariant {
  recruiting,
  viable,
  full,
  pendingCafeApproval,
  waitingCheckIn,
  confirmed,
  checkedIn,
  inProgress,
  ratingOpen,
  closed,
  hostCancelled,
  rejectedByCafe,
  expired,
  unknown,
}

class _CardStyle {
  final Color sidebarColor;
  final Color sidebarShadow;
  final String statusLabel;
  final IconData statusIcon;
  final Color statusBg;
  final Color statusFg;
  final Color accent;

  const _CardStyle({
    required this.sidebarColor,
    required this.sidebarShadow,
    required this.statusLabel,
    required this.statusIcon,
    required this.statusBg,
    required this.statusFg,
    required this.accent,
  });

  static _CardStyle forVariant(_CardVariant v) {
    switch (v) {
      case _CardVariant.recruiting:
        return const _CardStyle(
          sidebarColor: AppColors.info,
          sidebarShadow: AppColors.info,
          statusLabel: 'Cần thêm người',
          statusIcon: Icons.group_add_outlined,
          statusBg: AppColors.info,
          statusFg: Colors.white,
          accent: AppColors.info,
        );
      case _CardVariant.viable:
        return const _CardStyle(
          sidebarColor: AppColors.accent,
          sidebarShadow: AppColors.accent,
          statusLabel: 'Sẵn sàng khởi động',
          statusIcon: Icons.check_circle_outline,
          statusBg: AppColors.accent,
          statusFg: AppColors.black,
          accent: AppColors.accent,
        );
      case _CardVariant.full:
      case _CardVariant.confirmed:
        return const _CardStyle(
          sidebarColor: AppColors.success,
          sidebarShadow: AppColors.success,
          statusLabel: 'Đã xác nhận',
          statusIcon: Icons.check_circle,
          statusBg: AppColors.success,
          statusFg: Colors.white,
          accent: AppColors.success,
        );
      case _CardVariant.checkedIn:
        return const _CardStyle(
          sidebarColor: AppColors.success,
          sidebarShadow: AppColors.success,
          statusLabel: 'Đã check-in',
          statusIcon: Icons.location_on,
          statusBg: AppColors.success,
          statusFg: Colors.white,
          accent: AppColors.success,
        );
      case _CardVariant.pendingCafeApproval:
        return const _CardStyle(
          sidebarColor: AppColors.warning,
          sidebarShadow: AppColors.warning,
          statusLabel: 'Chờ quán duyệt',
          statusIcon: Icons.hourglass_top_rounded,
          statusBg: AppColors.warning,
          statusFg: AppColors.black,
          accent: AppColors.warning,
        );
      case _CardVariant.waitingCheckIn:
        return const _CardStyle(
          sidebarColor: AppColors.warning,
          sidebarShadow: AppColors.warning,
          statusLabel: 'Chờ check-in',
          statusIcon: Icons.pin_drop_outlined,
          statusBg: AppColors.warning,
          statusFg: AppColors.black,
          accent: AppColors.warning,
        );
      case _CardVariant.inProgress:
        return const _CardStyle(
          sidebarColor: AppColors.primary,
          sidebarShadow: AppColors.primary,
          statusLabel: 'Đang chơi',
          statusIcon: Icons.sports_esports_rounded,
          statusBg: AppColors.primary,
          statusFg: Colors.white,
          accent: AppColors.primary,
        );
      case _CardVariant.ratingOpen:
        return const _CardStyle(
          sidebarColor: AppColors.accent,
          sidebarShadow: AppColors.accent,
          statusLabel: 'Đang đánh giá',
          statusIcon: Icons.star_rounded,
          statusBg: AppColors.accent,
          statusFg: AppColors.black,
          accent: AppColors.accent,
        );
      case _CardVariant.closed:
        return _CardStyle(
          sidebarColor: AppColors.textTertiary,
          sidebarShadow: AppColors.textTertiary,
          statusLabel: 'Đã đóng',
          statusIcon: Icons.lock_outline,
          statusBg: AppColors.textTertiary,
          statusFg: Colors.white,
          accent: AppColors.textTertiary,
        );
      case _CardVariant.hostCancelled:
      case _CardVariant.rejectedByCafe:
      case _CardVariant.expired:
        return const _CardStyle(
          sidebarColor: AppColors.error,
          sidebarShadow: AppColors.error,
          statusLabel: 'Đã hủy',
          statusIcon: Icons.cancel_outlined,
          statusBg: AppColors.error,
          statusFg: Colors.white,
          accent: AppColors.error,
        );
      case _CardVariant.unknown:
        return const _CardStyle(
          sidebarColor: AppColors.textTertiary,
          sidebarShadow: AppColors.textTertiary,
          statusLabel: 'Đang cập nhật',
          statusIcon: Icons.help_outline,
          statusBg: AppColors.textTertiary,
          statusFg: Colors.white,
          accent: AppColors.textTertiary,
        );
    }
  }
}

/// Pressable card wrapper — sidebar trái + bordered card.
class _ReservationCardPressable extends StatefulWidget {
  final Widget child;
  final Color sidebarColor;
  final Color sidebarShadow;
  final bool isOwnedByMe;
  final VoidCallback? onTap;

  const _ReservationCardPressable({
    required this.child,
    required this.sidebarColor,
    required this.sidebarShadow,
    required this.isOwnedByMe,
    this.onTap,
  });

  @override
  State<_ReservationCardPressable> createState() =>
      _ReservationCardPressableState();
}

class _ReservationCardPressableState extends State<_ReservationCardPressable> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surface;
    final border = widget.isOwnedByMe
        ? AppColors.primary
        : (isDark ? AppColors.borderDark : AppColors.border);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: AppRadius.radiusLgAll,
            border: Border.all(
              color: border,
              width: widget.isOwnedByMe
                  ? NeoBrutalismTheme.borderWidthBold
                  : NeoBrutalismTheme.borderWidth,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.sidebarShadow.withValues(alpha: 0.25),
                blurRadius: 0,
                offset: const Offset(4, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: AppRadius.radiusLgAll,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Colored sidebar (gradient theo variant) ──
                  Container(
                    width: 6,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          widget.sidebarColor,
                          widget.sidebarShadow.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                  // ── Content ──
                  Expanded(child: widget.child),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Top row: status badge + countdown + isOwnedByMe ribbon.
class _TopRow extends StatelessWidget {
  final ReservationEntity reservation;
  final _CardStyle style;
  final bool isOwnedByMe;

  const _TopRow({
    required this.reservation,
    required this.style,
    required this.isOwnedByMe,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;

    // Top row chỉ còn status badge + countdown. Tag CHỦ PHÒNG / THÀNH VIÊN
    // đã được loại bỏ vì phân biệt Host vs Member đã có tab "TÔI TẠO" /
    // "TÔI THAM GIA" — tag chỉ làm che UI.
    return Row(
      children: [
        // ── Status badge ──
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: style.statusBg,
            borderRadius: AppRadius.radiusXsAll,
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: style.statusBg.withValues(alpha: 0.3),
                blurRadius: 0,
                offset: const Offset(1.5, 1.5),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(style.statusIcon, size: 13, color: style.statusFg),
              const SizedBox(width: 4),
              Text(
                style.statusLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: style.statusFg,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),

        // ── Countdown (nếu có deadline) ──
        if (_showCountdown(reservation)) ...[
          const SizedBox(width: AppSpacing.xs),
          _CountdownChip(deadline: reservation.recruitmentDeadline!),
        ],
      ],
    );
  }

  bool _showCountdown(ReservationEntity r) {
    if (r.recruitmentDeadline == null) return false;
    final d = r.recruitmentDeadline!;
    final diff = d.difference(DateTime.now());
    return !diff.isNegative && diff.inHours < 24;
  }
}

/// Countdown chip — hiển thị thời gian còn lại đến deadline.
class _CountdownChip extends StatelessWidget {
  final DateTime deadline;

  const _CountdownChip({required this.deadline});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final diff = deadline.difference(now);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;

    // Màu sắc theo thời gian còn lại
    Color bg;
    Color fg;
    String label;
    IconData icon;
    if (diff.inHours < 2) {
      bg = AppColors.error;
      fg = Colors.white;
      icon = Icons.timer_outlined;
    } else if (diff.inHours < 6) {
      bg = AppColors.warning;
      fg = AppColors.black;
      icon = Icons.timer_outlined;
    } else {
      bg = isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceVariant;
      fg = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
      icon = Icons.schedule;
    }

    label = _formatRemaining(diff);
    if (label.isEmpty) label = 'Sắp hết hạn';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.radiusXsAll,
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: fg,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  String _formatRemaining(Duration d) {
    if (d.inMinutes <= 0) return 'Hết hạn';
    if (d.inHours < 1) return '${d.inMinutes}p';
    if (d.inHours < 24) return '${d.inHours}h';
    return '${d.inDays}d';
  }
}

/// Cafe name row với icon pin.
class _CafeRow extends StatelessWidget {
  final String cafeName;

  const _CafeRow({required this.cafeName});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;

    return Row(
      children: [
        Icon(Icons.storefront_outlined, size: 14, color: color),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            cafeName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

/// Meta row dưới cùng: time + players + deposit + code.
class _MetaRow extends StatelessWidget {
  final ReservationEntity reservation;
  final _CardStyle style;

  const _MetaRow({required this.reservation, required this.style});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceBg = isDark
        ? AppColors.surfaceElevatedDark
        : AppColors.surfaceVariant;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: surfaceBg,
        borderRadius: AppRadius.radiusSmAll,
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        children: [
          // Time
          _MetaItem(
            icon: Icons.schedule,
            label: DateFormatter.timeOnly(reservation.scheduledTime),
            tooltip: DateFormatter.dateOnly(reservation.scheduledTime),
          ),
          _MetaDivider(),
          // Players
          _MetaItem(
            icon: Icons.group_outlined,
            label:
                '${reservation.currentPlayers}/${reservation.maxPlayers}',
            isAccent: reservation.isLobbyFull,
          ),
          _MetaDivider(),
          // Deposit
          if (reservation.finalDeposit > 0) ...[
            _MetaItem(
              icon: Icons.account_balance_wallet_outlined,
              label: _formatBvc(reservation.finalDeposit),
              isAccent: true,
            ),
            _MetaDivider(),
          ],
          // Share code (nếu có)
          if (reservation.lobbyShareCode != null &&
              reservation.lobbyShareCode!.isNotEmpty)
            Expanded(
              child: _MetaItem(
                icon: Icons.confirmation_number_outlined,
                label: reservation.lobbyShareCode!,
                isMono: true,
              ),
            )
          else
            const Spacer(),
        ],
      ),
    );
  }

  String _formatBvc(int amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M BVC';
    }
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}k BVC';
    }
    return '$amount BVC';
  }
}

class _MetaDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 1,
      height: 14,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      color: isDark ? AppColors.borderDark : AppColors.border,
    );
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? tooltip;
  final bool isAccent;
  final bool isMono;

  const _MetaItem({
    required this.icon,
    required this.label,
    this.tooltip,
    this.isAccent = false,
    this.isMono = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isAccent
        ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary)
        : (isDark
            ? AppColors.textSecondaryDark
            : AppColors.textSecondary);

    final widget = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: fg),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: fg,
              fontFeatures: isMono
                  ? const [FontFeature.tabularFigures()]
                  : null,
              letterSpacing: isMono ? 0.5 : 0,
            ),
          ),
        ),
      ],
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: widget);
    }
    return widget;
  }
}
