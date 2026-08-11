import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/theme.dart';
import '../../../reservation/domain/entities/entities.dart' as res;
import '../../domain/entities/lobby_entity.dart' as lobby;
import 'lobby_status_badge.dart';

// ── Public re-exports ────────────────────────────────────────────────────
//
// Card UI cần xác định variant giống hệt badge UI (cùng semantic, cùng
// màu). Để tránh drift enum giữa 2 file, card reuse enum + helper từ
// `lobby_status_badge.dart` rồi re-map sang nhãn tiếng Việt tương ứng.

LobbyStatusBadgeVariant _toBadgeVariant(LobbyCardVariant v) {
  return LobbyStatusBadgeVariant.values[v.index];
}

/// Variant hiển thị card - đồng bộ với `LobbyStatusBadge` ở mức enum.
///
/// Khi thay đổi state machine lobby/reservation, sửa `LobbyStatusBadgeVariant`
/// trong `lobby_status_badge.dart`; enum này tự động kế thừa mapping.
enum LobbyCardVariant {
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
/// - `CheckedIn` / `Completed` của reservation → `checkedIn` variant.
/// - Lobby ở terminal state → dùng lobby status trực tiếp.
LobbyCardVariant resolveLobbyCardVariant({
  required lobby.LobbyStatus? lobbyStatus,
  required res.ReservationStatus? reservationStatus,
}) {
  // Terminal reservation → dùng reservation status trực tiếp.
  if (reservationStatus != null && reservationStatus.isTerminal) {
    switch (reservationStatus) {
      case res.ReservationStatus.rejectedByCafe:
        return LobbyCardVariant.rejectedByCafe;
      case res.ReservationStatus.cancelledByCafe:
        return LobbyCardVariant.rejectedByCafe;
      case res.ReservationStatus.cancelledByPlayer:
      case res.ReservationStatus.cancelledByHost:
        return LobbyCardVariant.hostCancelled;
      case res.ReservationStatus.expired:
        return LobbyCardVariant.expiredByCafe;
      case res.ReservationStatus.noShow:
        return LobbyCardVariant.closed;
      case res.ReservationStatus.completed:
        return LobbyCardVariant.closed;
      default:
        break;
    }
  }

  // Active reservation → ưu tiên reservation.
  if (reservationStatus != null) {
    switch (reservationStatus) {
      case res.ReservationStatus.holding:
        if (lobbyStatus == lobby.LobbyStatus.pendingCafeApproval) {
          return LobbyCardVariant.pendingCafeApproval;
        }
        return LobbyCardVariant.confirmed;
      case res.ReservationStatus.confirmed:
        return LobbyCardVariant.confirmed;
      case res.ReservationStatus.checkedIn:
        return LobbyCardVariant.checkedIn;
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
    case lobby.LobbyStatus.pendingActivation:
      return LobbyCardVariant.pendingCafeApproval;
    case lobby.LobbyStatus.pendingCafeApproval:
      return LobbyCardVariant.pendingCafeApproval;
    case lobby.LobbyStatus.open:
      return LobbyCardVariant.recruiting;
    case lobby.LobbyStatus.viable:
      return LobbyCardVariant.viable;
    case lobby.LobbyStatus.full:
      return LobbyCardVariant.full;
    case lobby.LobbyStatus.inProgress:
      return LobbyCardVariant.inProgress;
    case lobby.LobbyStatus.ratingOpen:
      return LobbyCardVariant.ratingOpen;
    case lobby.LobbyStatus.closed:
      return LobbyCardVariant.closed;
    case lobby.LobbyStatus.timeoutFailed:
      return LobbyCardVariant.timeoutFailed;
    case lobby.LobbyStatus.hostCancelled:
      return LobbyCardVariant.hostCancelled;
    case lobby.LobbyStatus.rejectedByCafe:
      return LobbyCardVariant.rejectedByCafe;
    case lobby.LobbyStatus.expiredByCafe:
      return LobbyCardVariant.expiredByCafe;
    case null:
      return LobbyCardVariant.unknown;
  }
}

/// Dữ liệu thô để render 1 dòng card — bỏ qua các entity khác nhau
/// (`LobbyEntity`, `ReservationEntity`) và chỉ giữ field card cần.
///
/// Lý do: Card UI **phải đồng bộ giữa lobby + reservation** mà không cần
/// dùng chung entity (vì entity của reservation có `timeSlot` + `deposit`,
/// entity của lobby thì không). Field `nullable` cho phép bỏ qua tuỳ
/// context (vd: lobby không có deposit).
class LobbyCardItem {
  final String gameName;
  final String cafeName;
  final LobbyCardVariant variant;

  /// true nếu lobby đang active (đang tuyển / đang chơi / đang rating).
  /// false nếu đã đóng / timeout / cancelled.
  final bool isActive;

  /// true nếu đây là lobby của user hiện tại (host). UI sẽ viền primary.
  final bool isOwnedByMe;

  /// Thời điểm chơi dự kiến — bắt buộc.
  final DateTime scheduledTime;

  /// Số người hiện tại / tối đa — bắt buộc.
  final int currentPlayers;
  final int maxPlayers;

  /// Phiên chơi (sáng/chiều/tối/khuya) — optional, chỉ bên reservation.
  final String? timeSlotLabel;

  /// Số BVC đã cọc — optional, chỉ bên reservation. > 0 mới hiện pill.
  final int depositBvc;

  const LobbyCardItem({
    required this.gameName,
    required this.cafeName,
    required this.variant,
    required this.isActive,
    required this.isOwnedByMe,
    required this.scheduledTime,
    required this.currentPlayers,
    required this.maxPlayers,
    this.timeSlotLabel,
    this.depositBvc = 0,
  });
}

/// Layout hiển thị card.
///
/// - [horizontal] — list ngang, full-width. Avatar icon trái + content phải.
///   Phù hợp với `ListView` trong ReservationList / Explore / Của tôi.
/// - [vertical] — grid card, image cover trên + content dưới.
///   Phù hợp với `GridView` 2-cột.
enum LobbyCardLayout {
  /// Full-width row: avatar + game name + cafe + status pill + time + players.
  /// Layout duy nhất — dùng chung cho cả Explore, Của tôi, Reservation.
  horizontal,
}

/// Neo-brutalism card hiển thị chung cho lobby + reservation — tuân theo
/// design system (`docs/design_system.md` §7.1, §14.1).
///
/// **Card structure:**
/// - Avatar icon trái (gradient theo accent) + content phải.
/// - Header: game name (16/w900) + "CỦA BẠN" ribbon nếu là lobby của mình.
/// - Cafe name (12) + time chip (icon + label).
/// - Footer: status pill (icon + label, theo §14.1) + players badge +
///   optional deposit pill. Tất cả pill có border 2px + hard shadow (2,2).
/// - Outer: border 3px + hard offset shadow (4,4) cho active, (3,3) cho terminal.
///
/// **Một layout duy nhất** cho cả 4 chỗ hiển thị lobby/reservation
/// (Bookings → tab "Phòng chờ" + tab "Lịch đặt", LobbyHub → "Khám phá" +
/// "Của tôi") để không drift UI giữa 2 tab giống nhau.
///
/// Status pill ở **footer** thay vì overlay trên cover để:
/// 1. Không bị trùng màu với cover image (low contrast).
/// 2. Tăng tỷ lệ đọc được khi list nhiều card.
class LobbyCardBase extends StatelessWidget {
  final LobbyCardItem item;
  final VoidCallback? onTap;

  /// Cho phép override initial avatar size (mặc định 56 theo design system §14.3).
  final double avatarSize;

  const LobbyCardBase({
    super.key,
    required this.item,
    this.onTap,
    this.avatarSize = 56,
  });

  bool get _isActive => item.isActive || _isActiveVariant(item.variant);

  bool _isActiveVariant(LobbyCardVariant v) {
    switch (v) {
      case LobbyCardVariant.recruiting:
      case LobbyCardVariant.viable:
      case LobbyCardVariant.confirmed:
      case LobbyCardVariant.pendingCafeApproval:
      case LobbyCardVariant.checkedIn:
      case LobbyCardVariant.full:
        return true;
      case LobbyCardVariant.inProgress:
      case LobbyCardVariant.ratingOpen:
      case LobbyCardVariant.closed:
      case LobbyCardVariant.timeoutFailed:
      case LobbyCardVariant.hostCancelled:
      case LobbyCardVariant.rejectedByCafe:
      case LobbyCardVariant.expiredByCafe:
      case LobbyCardVariant.expired:
      case LobbyCardVariant.unknown:
        return false;
    }
  }

  // ── Build ────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) => _buildHorizontal(context);

  Widget _buildHorizontal(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = _accentColor(context);
    final isActive = _isActive;
    final hasGame = item.gameName.trim().isNotEmpty;
    final displayTitle = hasGame ? item.gameName : item.cafeName;

    return _NeoPressableCard(
      isActive: isActive,
      accent: accent,
      isOwnedByMe: item.isOwnedByMe,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Avatar Icon (gradient theo accent) ─────────────────
            _AvatarIcon(
              accent: accent,
              isActive: isActive,
              icon: _avatarIcon(),
              size: avatarSize,
            ),
            const SizedBox(width: AppSpacing.md),

            // ── Content ──────────────────────────────────────────
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Game name + isOwned ribbon
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          displayTitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            height: 1.2,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (item.isOwnedByMe) ...[
                        const SizedBox(width: AppSpacing.xs),
                        _OwnedByMePill(),
                      ],
                    ],
                  ),
                  if (item.cafeName.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    _CafeRow(cafeName: item.cafeName, isDark: isDark),
                  ],
                  const SizedBox(height: AppSpacing.sm),

                  // Time chip + Slot
                  _TimeChip(
                    scheduledTime: item.scheduledTime,
                    timeSlotLabel: item.timeSlotLabel,
                    accent: accent,
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Footer: Status pill + Players badge + (optional) Deposit
                  Row(
                    children: [
                      LobbyStatusBadge(
                        variant: _toBadgeVariant(item.variant),
                        dense: true,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      _PlayersBadge(
                        current: item.currentPlayers,
                        max: item.maxPlayers,
                        accent: accent,
                      ),
                      if (item.depositBvc > 0) ...[
                        const SizedBox(width: AppSpacing.xs),
                        _DepositPill(deposit: item.depositBvc),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Chevron
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                Icons.chevron_right,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _accentColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Bảng màu theo design system §14.1: success / warning / accent / error / info.
    switch (item.variant) {
      case LobbyCardVariant.recruiting:
        return isDark ? AppColors.infoDark : AppColors.info;
      case LobbyCardVariant.viable:
        return isDark ? AppColors.accentDark : AppColors.accent;
      case LobbyCardVariant.full:
      case LobbyCardVariant.confirmed:
      case LobbyCardVariant.checkedIn:
        return isDark ? AppColors.successDark : AppColors.success;
      case LobbyCardVariant.pendingCafeApproval:
        return isDark ? AppColors.warningDark : AppColors.warning;
      case LobbyCardVariant.inProgress:
        return isDark ? AppColors.primaryDark : AppColors.primary;
      case LobbyCardVariant.ratingOpen:
        return isDark ? AppColors.accentDark : AppColors.accent;
      case LobbyCardVariant.closed:
        return AppColors.textTertiary;
      case LobbyCardVariant.rejectedByCafe:
      case LobbyCardVariant.hostCancelled:
      case LobbyCardVariant.expiredByCafe:
      case LobbyCardVariant.expired:
      case LobbyCardVariant.timeoutFailed:
        return isDark ? AppColors.errorDark : AppColors.error;
      case LobbyCardVariant.unknown:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

  IconData _avatarIcon() {
    return _isActive ? AppIcons.boardGame : Icons.meeting_room_outlined;
  }
}

// ── Avatar icon (gradient theo accent + hard shadow) ────────────────────
//
// Theo design system §14.3 (Player card) — colored icon background giúp
// phân biệt variant ngay từ avatar.

class _AvatarIcon extends StatelessWidget {
  final Color accent;
  final bool isActive;
  final IconData icon;
  final double size;

  const _AvatarIcon({
    required this.accent,
    required this.isActive,
    required this.icon,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isActive
        ? accent
        : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondary);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            bgColor,
            bgColor.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: bgColor.withValues(alpha: 0.4),
            blurRadius: 0,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.5),
    );
  }
}

// ── Neo-pressable card wrapper (border + hard shadow + press scale) ─────

class _NeoPressableCard extends StatefulWidget {
  final Widget child;
  final bool isActive;
  final Color accent;
  final bool isOwnedByMe;
  final VoidCallback? onTap;

  const _NeoPressableCard({
    required this.child,
    required this.isActive,
    required this.accent,
    required this.isOwnedByMe,
    this.onTap,
  });

  @override
  State<_NeoPressableCard> createState() => _NeoPressableCardState();
}

class _NeoPressableCardState extends State<_NeoPressableCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surface;
    final border = widget.isOwnedByMe
        ? AppColors.primary
        : (widget.isActive
            ? widget.accent
            : (isDark ? AppColors.borderDark : AppColors.border));
    final shadow = widget.isActive
        ? widget.accent.withValues(alpha: 0.4)
        : AppColors.black.withValues(alpha: 0.5);
    final shadowOffset = widget.isActive
        ? const Offset(4, 4)
        : const Offset(3, 3);

    return GestureDetector(
      onTapDown: widget.onTap != null
          ? (_) => setState(() => _isPressed = true)
          : null,
      onTapUp: widget.onTap != null
          ? (_) => setState(() => _isPressed = false)
          : null,
      onTapCancel: widget.onTap != null
          ? () => setState(() => _isPressed = false)
          : null,
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border, width: 3),
            boxShadow: [
              BoxShadow(
                color: shadow,
                blurRadius: 0,
                offset: shadowOffset,
              ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

// ── Pills / chips (theo design system §7.5, §14.1) ──────────────────────

class _OwnedByMePill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppColors.border,
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.black,
            blurRadius: 0,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: const Text(
        'CỦA BẠN',
        style: TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _CafeRow extends StatelessWidget {
  final String cafeName;
  final bool isDark;

  const _CafeRow({
    required this.cafeName,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.storefront,
          size: 13,
          color: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondary,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            cafeName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _TimeChip extends StatelessWidget {
  final DateTime scheduledTime;
  final String? timeSlotLabel;
  final Color accent;

  const _TimeChip({
    required this.scheduledTime,
    required this.timeSlotLabel,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('HH:mm • dd/MM').format(scheduledTime.toLocal());
    final label = timeSlotLabel != null ? '$time • $timeSlotLabel' : time;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule, size: 13, color: accent),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayersBadge extends StatelessWidget {
  final int current;
  final int max;
  final Color accent;

  const _PlayersBadge({
    required this.current,
    required this.max,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isFull = current >= max;
    final borderColor = isFull
        ? (isDark ? AppColors.errorDark : AppColors.error)
        : (isDark ? AppColors.borderDark : AppColors.border);
    final color = isFull
        ? (isDark ? AppColors.errorDark : AppColors.error)
        : accent;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: AppColors.black,
            blurRadius: 0,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.group,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            '$current/$max',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _DepositPill extends StatelessWidget {
  final int deposit;

  const _DepositPill({required this.deposit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: AppColors.black,
            blurRadius: 0,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.confirmation_number,
            size: 13,
            color: AppColors.black,
          ),
          const SizedBox(width: 4),
          Text(
            '$deposit BVC',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: AppColors.black,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Adapter factories ────────────────────────────────────────────────────

/// Build `LobbyCardItem` từ LobbyEntity (cho tab Explore + tab Của tôi).
LobbyCardItem lobbyItemFromEntity(
  lobby.LobbyEntity lobbyEntity, {
  bool isOwnedByMe = false,
}) {
  final variant = resolveLobbyCardVariant(
    lobbyStatus: lobbyEntity.status,
    reservationStatus: lobbyEntity.reservationStatus,
  );

  return LobbyCardItem(
    gameName: lobbyEntity.gameName,
    cafeName: lobbyEntity.cafeName,
    variant: variant,
    isActive:
        lobbyEntity.status.isActive || (lobbyEntity.reservationStatus?.isActive ?? false),
    isOwnedByMe: isOwnedByMe,
    scheduledTime: lobbyEntity.scheduledTime,
    currentPlayers: lobbyEntity.currentPlayers,
    maxPlayers: lobbyEntity.maxPlayers,
    // Lobby chưa có TimeSlot concept → bỏ.
    timeSlotLabel: null,
    depositBvc: 0,
  );
}

/// Build `LobbyCardItem` từ ReservationEntity (cho ReservationList).
LobbyCardItem lobbyItemFromReservation(res.ReservationEntity r) {
  // Reservation entity có enum `LobbyStatus` riêng (legacy) — convert
  // sang lobby_management's `LobbyStatus` enum để truyền vào
  // `resolveLobbyCardVariant` chung. Mapping 1-1 vì 2 enum giống nhau
  // chỉ khác tên label.
  final lobbyStatus = _mapLobbyStatus(r.lobbyStatus);

  final variant = resolveLobbyCardVariant(
    lobbyStatus: lobbyStatus,
    reservationStatus: r.status,
  );

  return LobbyCardItem(
    gameName: r.gameName,
    cafeName: r.cafeName,
    variant: variant,
    isActive: r.status.isActive || (lobbyStatus?.isActive ?? false),
    isOwnedByMe: true, // Reservation list chỉ của user.
    scheduledTime: r.scheduledTime,
    currentPlayers: r.currentPlayers,
    maxPlayers: r.maxPlayers,
    timeSlotLabel: r.timeSlot.displayName,
    depositBvc: r.finalDeposit,
  );
}

/// Convert reservation's `LobbyStatus` (legacy enum) → lobby_management's
/// `LobbyStatus`. 2 enum có cùng giá trị, chỉ khác label; mapping trực tiếp.
lobby.LobbyStatus? _mapLobbyStatus(res.LobbyStatus? s) {
  if (s == null) return null;
  switch (s) {
    case res.LobbyStatus.pendingActivation:
      return lobby.LobbyStatus.pendingActivation;
    case res.LobbyStatus.pendingCafeApproval:
      return lobby.LobbyStatus.pendingCafeApproval;
    case res.LobbyStatus.open:
      return lobby.LobbyStatus.open;
    case res.LobbyStatus.viable:
      return lobby.LobbyStatus.viable;
    case res.LobbyStatus.full:
      return lobby.LobbyStatus.full;
    case res.LobbyStatus.inProgress:
      return lobby.LobbyStatus.inProgress;
    case res.LobbyStatus.closed:
      return lobby.LobbyStatus.closed;
    case res.LobbyStatus.timeoutFailed:
      return lobby.LobbyStatus.timeoutFailed;
    case res.LobbyStatus.hostCancelled:
      return lobby.LobbyStatus.hostCancelled;
    case res.LobbyStatus.rejectedByCafe:
      return lobby.LobbyStatus.rejectedByCafe;
    case res.LobbyStatus.expiredByCafe:
      return lobby.LobbyStatus.expiredByCafe;
  }
}
