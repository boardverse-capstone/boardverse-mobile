import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/top_snack_bar.dart';
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
enum LobbyCardVariant {
  recruiting,
  viable,
  full,
  waitingCheckIn,
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
LobbyCardVariant resolveLobbyCardVariant({
  required lobby.LobbyStatus? lobbyStatus,
  required res.ReservationStatus? reservationStatus,
}) {
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

  if (reservationStatus != null) {
    switch (reservationStatus) {
      case res.ReservationStatus.holding:
        if (lobbyStatus == lobby.LobbyStatus.pendingCafeApproval) {
          return LobbyCardVariant.pendingCafeApproval;
        }
        return LobbyCardVariant.confirmed;
      case res.ReservationStatus.confirmed:
        if (lobbyStatus == lobby.LobbyStatus.waitingCheckIn) {
          return LobbyCardVariant.waitingCheckIn;
        }
        return LobbyCardVariant.confirmed;
      case res.ReservationStatus.checkedIn:
        return LobbyCardVariant.checkedIn;
      case res.ReservationStatus.draft:
      case res.ReservationStatus.awaitingDeposit:
        break;
      default:
        break;
    }
  }

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
    case lobby.LobbyStatus.waitingCheckIn:
      return LobbyCardVariant.waitingCheckIn;
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
    case lobby.LobbyStatus.dissolved:
      return LobbyCardVariant.closed;
    case null:
      return LobbyCardVariant.unknown;
  }
}

/// Dữ liệu thô để render 1 dòng card — bỏ qua các entity khác nhau
/// (`LobbyEntity`, `ReservationEntity`) và chỉ giữ field card cần.
class LobbyCardItem {
  final String gameName;
  final String cafeName;
  final LobbyCardVariant variant;

  /// true nếu lobby đang active (đang tuyển / đang chơi / đang rating).
  final bool isActive;

  /// true nếu đây là lobby của user hiện tại (host). UI sẽ viền primary.
  final bool isOwnedByMe;

  /// Thời điểm chơi dự kiến — bắt buộc.
  final DateTime scheduledTime;

  /// Giờ kết thúc dự kiến (optional).
  final DateTime? endTime;

  /// Số người hiện tại / tối đa — bắt buộc.
  final int currentPlayers;
  final int maxPlayers;

  /// Số BVC đã cọc — optional. > 0 mới hiện.
  final int depositBvc;

  /// Mã reservation/lobby code 8 ký tự cho POS check-in.
  final String? code;

  /// Players info — optional (null nếu không có data).
  /// Mỗi player có: name, avatarUrl, isHost, isReady
  final List<LobbyPlayerInfo>? players;

  const LobbyCardItem({
    required this.gameName,
    required this.cafeName,
    required this.variant,
    required this.isActive,
    required this.isOwnedByMe,
    required this.scheduledTime,
    this.endTime,
    required this.currentPlayers,
    required this.maxPlayers,
    this.depositBvc = 0,
    this.code,
    this.players,
  });
}

/// Simplified player info for card display.
class LobbyPlayerInfo {
  final String name;
  final String? avatarUrl;
  final bool isHost;
  final bool isReady;

  const LobbyPlayerInfo({
    required this.name,
    this.avatarUrl,
    this.isHost = false,
    this.isReady = false,
  });
}

/// Layout hiển thị card.
enum LobbyCardLayout {
  horizontal,
  vertical,
}

/// Modern Game Store Card — đồng bộ với [ReservationCardModern].
///
/// **Design (soft shadow + gradient avatar):**
///
/// [LobbyCardLayout.horizontal] — layout ngang (dòng đơn):
/// - Avatar gradient bên trái (icon theo variant, kích thước 56-64dp).
/// - Content bên phải: game name (16/w800) + cafe + status badge + stats row.
///
/// [LobbyCardLayout.vertical] — layout dọc grid (2 card/hàng):
/// - Vibrant gradient artwork cover chiếm ~55% card height.
/// - Status badge đặt trên cover (góc trên-trái).
/// - Decorative pattern icon ở góc cover.
/// - Content bên dưới: game name + cafe + stats row 3 cột.
/// - Border mỏng 1.5px (active), 2.5px cam primary cho owned-by-me.
/// - Soft colored shadow theo accent (alpha 0.18-0.25).
class LobbyCardBase extends StatelessWidget {
  final LobbyCardItem item;
  final VoidCallback? onTap;
  final LobbyCardLayout layout;

  /// Cho phép override initial avatar size (mặc định 60).
  final double avatarSize;

  const LobbyCardBase({
    super.key,
    required this.item,
    this.onTap,
    this.layout = LobbyCardLayout.horizontal,
    this.avatarSize = 60,
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
      case LobbyCardVariant.waitingCheckIn:
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

  @override
  Widget build(BuildContext context) {
    switch (layout) {
      case LobbyCardLayout.vertical:
        return _buildVertical(context);
      case LobbyCardLayout.horizontal:
        return _buildHorizontal(context);
    }
  }

  Widget _buildVertical(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final style = _CardStyleModern.forVariant(item.variant);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: item.isOwnedByMe
                ? AppColors.primary
                : (isDark ? AppColors.borderDark : AppColors.border),
            width: item.isOwnedByMe ? 2.5 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: style.gradientColors.first.withValues(alpha: 0.18),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ═══════════════════════════════════════════════
            // ARTWORK COVER — gradient với game name overlay
            // ═══════════════════════════════════════════════
            _RichArtworkCover(
              item: item,
              style: style,
              isDark: isDark,
            ),

            // ═══════════════════════════════════════════════
            // CONTENT — spacious, breathing room between sections
            // ═══════════════════════════════════════════════
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Game name ───────────────────────────
                  // 1 dòng max để card không phụ thuộc vào tên dài; tên
                  // dài hiện ellipsis, user bấm vào chi tiết để xem full.
                  Text(
                    item.gameName.isNotEmpty ? item.gameName : item.cafeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // ── Cafe info ──────────────────────────
                  if (item.cafeName.isNotEmpty)
                    _CafeInfoRow(
                      cafeName: item.cafeName,
                      isDark: isDark,
                    ),

                  const SizedBox(height: 8),

                  // ── Time range row (with date) ──────────────
                  _TimeRangeRowCompact(
                    startTime: item.scheduledTime,
                    endTime: item.endTime,
                    accent: style.accent,
                  ),

                  const SizedBox(height: 10),

                  // ── Share code pill (full-width) ───────────
                  // Thay thế `_PlayersInfo` (trùng lặp với overlay đầu card)
                  // bằng share code dạng pill full-width — player bấm vào
                  // pill để copy mã, không cần nút copy riêng. Chiếm trọn
                  // chiều ngang để mã code không bị truncate ("J2T2GE...").
                  if (item.code != null && item.code!.isNotEmpty)
                    _ShareCodeRow(code: item.code!, isDark: isDark)
                  else
                    // Fallback khi API không trả `shareCode` (vd: lobby cũ,
                    // schema thay đổi) — vẫn show thông tin người chơi để
                    // card không bị trống nội dung.
                    _PlayersInfo(
                      players: item.players,
                      current: item.currentPlayers,
                      max: item.maxPlayers,
                      style: style,
                      isDark: isDark,
                    ),

                  // ── Hint icon — báo cho player biết pill là tương tác ─
                  // Dùng icon copy đơn giản thay vì text dài "Ấn vào mã để
                  // sao chép" — text dài gây RenderFlex overflow khi card
                  // hẹp. Icon tự giải thích ngữ nghĩa và không tốn width.
                  if (item.code != null && item.code!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Row(
                        children: [
                          Icon(
                            Icons.content_copy_rounded,
                            size: 11,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Bấm để sao chép',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                              height: 1.0,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontal(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = _accentColor(context);
    final isActive = _isActive;
    final hasGame = item.gameName.trim().isNotEmpty;
    final displayTitle = hasGame ? item.gameName : item.cafeName;

    return Material(
      color: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: accent.withValues(alpha: 0.08),
        highlightColor: accent.withValues(alpha: 0.04),
        child: Ink(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: item.isOwnedByMe
                  ? AppColors.primary
                  : (isActive
                      ? accent.withValues(alpha: 0.3)
                      : (isDark ? AppColors.borderDark : AppColors.border)),
              width: item.isOwnedByMe ? 2.5 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (item.isOwnedByMe ? AppColors.primary : accent)
                    .withValues(alpha: 0.18),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Avatar Icon (gradient theo accent) ─────────────
                _AvatarIcon(
                  accent: accent,
                  isActive: isActive,
                  icon: _avatarIcon(),
                  size: avatarSize,
                ),
                const SizedBox(width: AppSpacing.md),

                // ── Content ────────────────────────────────────
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Game name + status badge (inline)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              displayTitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                height: 1.2,
                                letterSpacing: -0.2,
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (item.isOwnedByMe) ...[
                            const SizedBox(width: AppSpacing.xs),
                            const _OwnedDotIndicator(),
                          ],
                        ],
                      ),
                      if (item.cafeName.isNotEmpty && hasGame) ...[
                        const SizedBox(height: 4),
                        _CafeRow(cafeName: item.cafeName, isDark: isDark),
                      ],
                      const SizedBox(height: AppSpacing.sm),

                      // Status badge
                      Align(
                        alignment: Alignment.centerLeft,
                        child: LobbyStatusBadge(
                          variant: _toBadgeVariant(item.variant),
                          dense: true,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // Footer: Time + Players + (optional) Deposit + Code
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _TimeChip(
                            scheduledTime: item.scheduledTime,
                            accent: accent,
                          ),
                          _PlayersBadge(
                            current: item.currentPlayers,
                            max: item.maxPlayers,
                            accent: accent,
                          ),
                          if (item.depositBvc > 0)
                            _DepositPill(deposit: item.depositBvc),
                          if (item.code != null && item.code!.isNotEmpty)
                            _CodePill(code: item.code!),
                        ],
                      ),
                    ],
                  ),
                ),

                // Chevron
                Padding(
                  padding: const EdgeInsets.only(top: 18),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _accentColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
      case LobbyCardVariant.waitingCheckIn:
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
    return _isActive ? Icons.casino_rounded : Icons.meeting_room_outlined;
  }
}

// ═══════════════════════════════════════════════════════════════════════
// VARIANT & STYLE (cho vertical grid layout)
// ═══════════════════════════════════════════════════════════════════════

class _CardStyleModern {
  final List<Color> gradientColors;
  final Color accent;
  final String statusLabel;
  final IconData statusIcon;
  final IconData decorIcon;

  const _CardStyleModern({
    required this.gradientColors,
    required this.accent,
    required this.statusLabel,
    required this.statusIcon,
    required this.decorIcon,
  });

  static _CardStyleModern forVariant(LobbyCardVariant v) {
    switch (v) {
      case LobbyCardVariant.recruiting:
        return const _CardStyleModern(
          gradientColors: [Color(0xFF667eea), Color(0xFF764ba2)],
          accent: Color(0xFF667eea),
          statusLabel: 'Tuyển người',
          statusIcon: Icons.person_add_rounded,
          decorIcon: Icons.casino_rounded,
        );
      case LobbyCardVariant.viable:
        return const _CardStyleModern(
          gradientColors: [Color(0xFF11998e), Color(0xFF38ef7d)],
          accent: Color(0xFF38ef7d),
          statusLabel: 'Đủ người',
          statusIcon: Icons.check_circle_rounded,
          decorIcon: Icons.verified_rounded,
        );
      case LobbyCardVariant.full:
        return const _CardStyleModern(
          gradientColors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
          accent: Color(0xFF4CAF50),
          statusLabel: 'Phòng đầy',
          statusIcon: Icons.groups_rounded,
          decorIcon: Icons.celebration_rounded,
        );
      case LobbyCardVariant.confirmed:
        return const _CardStyleModern(
          gradientColors: [Color(0xFF00BCD4), Color(0xFF009688)],
          accent: Color(0xFF00BCD4),
          statusLabel: 'Đã xác nhận',
          statusIcon: Icons.check_rounded,
          decorIcon: Icons.verified_rounded,
        );
      case LobbyCardVariant.waitingCheckIn:
        return const _CardStyleModern(
          gradientColors: [Color(0xFFFF9800), Color(0xFFE65100)],
          accent: Color(0xFFFF9800),
          statusLabel: 'Chờ check-in',
          statusIcon: Icons.pin_drop_rounded,
          decorIcon: Icons.location_on_rounded,
        );
      case LobbyCardVariant.pendingCafeApproval:
        return const _CardStyleModern(
          gradientColors: [Color(0xFFFFB300), Color(0xFFFF8F00)],
          accent: Color(0xFFFFB300),
          statusLabel: 'Chờ quán duyệt',
          statusIcon: Icons.hourglass_top_rounded,
          decorIcon: Icons.store_rounded,
        );
      case LobbyCardVariant.checkedIn:
        return const _CardStyleModern(
          gradientColors: [Color(0xFF26A69A), Color(0xFF00897B)],
          accent: Color(0xFF26A69A),
          statusLabel: 'Đã check-in',
          statusIcon: Icons.check_circle_outline_rounded,
          decorIcon: Icons.done_all_rounded,
        );
      case LobbyCardVariant.inProgress:
        return const _CardStyleModern(
          gradientColors: [Color(0xFFE91E63), Color(0xFFC2185B)],
          accent: Color(0xFFE91E63),
          statusLabel: 'Đang chơi',
          statusIcon: Icons.sports_esports_rounded,
          decorIcon: Icons.sports_esports_rounded,
        );
      case LobbyCardVariant.ratingOpen:
        return const _CardStyleModern(
          gradientColors: [Color(0xFFFFC107), Color(0xFFFFB300)],
          accent: Color(0xFFFFC107),
          statusLabel: 'Đánh giá',
          statusIcon: Icons.star_rounded,
          decorIcon: Icons.star_rounded,
        );
      case LobbyCardVariant.closed:
        return const _CardStyleModern(
          gradientColors: [Color(0xFF78909C), Color(0xFF546E7A)],
          accent: Color(0xFF78909C),
          statusLabel: 'Đã đóng',
          statusIcon: Icons.lock_rounded,
          decorIcon: Icons.history_rounded,
        );
      case LobbyCardVariant.timeoutFailed:
        return const _CardStyleModern(
          gradientColors: [Color(0xFF90A4AE), Color(0xFF78909C)],
          accent: Color(0xFF90A4AE),
          statusLabel: 'Hết hạn',
          statusIcon: Icons.timer_off_rounded,
          decorIcon: Icons.timer_off_rounded,
        );
      case LobbyCardVariant.hostCancelled:
        return const _CardStyleModern(
          gradientColors: [Color(0xFFEF5350), Color(0xFFD32F2F)],
          accent: Color(0xFFEF5350),
          statusLabel: 'Đã hủy',
          statusIcon: Icons.cancel_rounded,
          decorIcon: Icons.close_rounded,
        );
      case LobbyCardVariant.rejectedByCafe:
        return const _CardStyleModern(
          gradientColors: [Color(0xFFEF5350), Color(0xFFC62828)],
          accent: Color(0xFFEF5350),
          statusLabel: 'Quán từ chối',
          statusIcon: Icons.block_rounded,
          decorIcon: Icons.do_not_disturb_rounded,
        );
      case LobbyCardVariant.expiredByCafe:
        return const _CardStyleModern(
          gradientColors: [Color(0xFFBDBDBD), Color(0xFF9E9E9E)],
          accent: Color(0xFFBDBDBD),
          statusLabel: 'Hết hạn duyệt',
          statusIcon: Icons.schedule_rounded,
          decorIcon: Icons.schedule_rounded,
        );
      case LobbyCardVariant.expired:
        return const _CardStyleModern(
          gradientColors: [Color(0xFF90A4AE), Color(0xFF546E7A)],
          accent: Color(0xFF90A4AE),
          statusLabel: 'Hết hạn',
          statusIcon: Icons.timer_off_rounded,
          decorIcon: Icons.timer_off_rounded,
        );
      case LobbyCardVariant.unknown:
        return const _CardStyleModern(
          gradientColors: [Color(0xFF607D8B), Color(0xFF263238)],
          accent: Color(0xFF607D8B),
          statusLabel: 'Đang cập nhật',
          statusIcon: Icons.help_outline_rounded,
          decorIcon: Icons.help_outline_rounded,
        );
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════
// RICH ARTWORK COVER — gradient với players avatars overlay
// ═══════════════════════════════════════════════════════════════════════

class _RichArtworkCover extends StatelessWidget {
  final LobbyCardItem item;
  final _CardStyleModern style;
  final bool isDark;

  const _RichArtworkCover({
    required this.item,
    required this.style,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: style.gradientColors,
        ),
      ),
      child: Stack(
        children: [
          // ── Background decor icon (bottom-right) ───────────
          Positioned(
            right: -10,
            bottom: -10,
            child: Icon(
              style.decorIcon,
              size: 78,
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),

          // ── Dots pattern (top-right) ───────────────────────
          Positioned(
            right: 8,
            top: 8,
            child: Opacity(
              opacity: 0.15,
              child: CustomPaint(
                size: const Size(30, 30),
                painter: _DotsPatternPainter(),
              ),
            ),
          ),

          // ── Game icon (center) ─────────────────────────────
          Center(
            child: Icon(
              style.decorIcon,
              size: 44,
              color: Colors.white.withValues(alpha: 0.2),
            ),
          ),

          // ── Bottom-left: Players avatars overlay ─────────────
          if (item.players != null && item.players!.isNotEmpty)
            Positioned(
              left: 8,
              bottom: 8,
              child: _MiniPlayerAvatars(
                players: item.players!,
                maxPlayers: item.maxPlayers,
                isDark: isDark,
              ),
            ),

          // ── Top-left: Status pill ─────────────────────────
          Positioned(
            top: 8,
            left: 8,
            child: _GridStatusPill(
              label: style.statusLabel,
              icon: style.statusIcon,
            ),
          ),

          // ── Top-right: Owned chip ──────────────────────────
          if (item.isOwnedByMe)
            Positioned(
              top: 8,
              right: 8,
              child: _OwnedChip(),
            ),
        ],
      ),
    );
  }
}

class _MiniPlayerAvatars extends StatelessWidget {
  final List<LobbyPlayerInfo> players;
  final int maxPlayers;
  final bool isDark;

  const _MiniPlayerAvatars({
    required this.players,
    required this.maxPlayers,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    const avatarSize = 32.0;
    const overlap = 12.0;
    final visiblePlayers = players.take(3).toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Stacked avatars
          SizedBox(
            width: avatarSize + (visiblePlayers.length - 1) * overlap,
            height: avatarSize,
            child: Stack(
              children: [
                for (int i = 0; i < visiblePlayers.length; i++)
                  Positioned(
                    left: i * overlap,
                    child: _PlayerAvatarChip(player: visiblePlayers[i]),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Count + Max text
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${players.length}/$maxPlayers',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'người',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Single player avatar chip - shows real avatar image if available,
/// fallback to username initials. Host is distinguished by ring border color.
class _PlayerAvatarChip extends StatelessWidget {
  final LobbyPlayerInfo player;
  static const double _size = 32.0;

  const _PlayerAvatarChip({required this.player});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: _getRingColor(player),
          width: 2.5,
        ),
        color: _getAvatarBg(player),
      ),
      child: ClipOval(
        child: _getAvatarContent(player),
      ),
    );
  }

  /// Show real avatar if URL is valid, else fallback to initials.
  Widget _getAvatarContent(LobbyPlayerInfo player) {
    final url = player.avatarUrl;
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        width: _size,
        height: _size,
        errorBuilder: (context, error, stackTrace) => _buildInitials(player),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildInitials(player);
        },
      );
    }
    return _buildInitials(player);
  }

  /// Hiển thị initials từ username (lowercase) -> uppercase.
  /// VD: "player7" -> "P7", "jonny" -> "JO", "nguyenvana" -> "NG"
  Widget _buildInitials(LobbyPlayerInfo player) {
    return Container(
      width: _size,
      height: _size,
      alignment: Alignment.center,
      color: _getAvatarBg(player),
      child: Text(
        _getInitials(player.name),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  /// Lấy 2 chữ cái đầu của username, in hoa.
  /// VD: "player7" -> "P7", "jonny" -> "JO", "ab" -> "AB"
  static String _getInitials(String name) {
    final cleaned = name.trim();
    if (cleaned.isEmpty) return '?';
    // Uppercase 2 ký tự đầu của username
    final upper = cleaned.toUpperCase();
    if (upper.length == 1) return upper;
    return upper.substring(0, 2);
  }

  /// Màu nền avatar - giống nhau cho tất cả player.
  static Color _getAvatarBg(LobbyPlayerInfo player) {
    return const Color(0xFF455A64); // slate dark - đồng nhất
  }

  /// Màu viền vòng tròn - phân biệt host.
  /// Host = vàng cam, member = trắng.
  static Color _getRingColor(LobbyPlayerInfo player) {
    if (player.isHost) {
      return const Color(0xFFFFB74D); // cam vàng nổi bật cho host
    }
    return Colors.white.withValues(alpha: 0.95);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// CAFE INFO ROW
// ═══════════════════════════════════════════════════════════════════════

class _CafeInfoRow extends StatelessWidget {
  final String cafeName;
  final bool isDark;

  const _CafeInfoRow({
    required this.cafeName,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.storefront_rounded,
          size: 14,
          color: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondary,
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            cafeName,
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
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PLAYERS INFO
// ═══════════════════════════════════════════════════════════════════════

class _PlayersInfo extends StatelessWidget {
  final List<LobbyPlayerInfo>? players;
  final int current;
  final int max;
  final _CardStyleModern style;
  final bool isDark;

  const _PlayersInfo({
    this.players,
    required this.current,
    required this.max,
    required this.style,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isFull = current >= max;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isFull
            ? style.accent.withValues(alpha: 0.15)
            : (isDark ? AppColors.surfaceElevatedDark : Colors.grey.shade100),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isFull ? Icons.check_circle_rounded : Icons.group_rounded,
            size: 16,
            color: isFull
                ? style.accent
                : (isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary),
          ),
          const SizedBox(width: 6),
          Text(
            '$current / $max người',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isFull
                  ? style.accent
                  : (isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// TIME RANGE ROW COMPACT — compact 2-row chip: ngày + khung giờ
// ═══════════════════════════════════════════════════════════════════════

/// Time chip nhỏ gọn hiển thị **ngày** và **khung giờ** theo 2 hàng:
/// - Hàng 1: icon calendar + "dd/MM/yyyy" (vd: "24/08/2026").
/// - Hàng 2: icon clock + "HH:mm - HH:mm" hoặc chỉ "HH:mm" nếu không có
///   endTime.
///
/// Layout 2 hàng để fit vừa card width h�p (~165px) mà không bị overflow.
/// Mỗi hàng dùng `Flexible` + `ellipsis` làm safety net — text sẽ tự co
/// lại thay vì tràn ra ngoài. Màu chip theo `accent` của variant game.
class _TimeRangeRowCompact extends StatelessWidget {
  final DateTime startTime;
  final DateTime? endTime;
  final Color accent;

  const _TimeRangeRowCompact({
    required this.startTime,
    required this.endTime,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final localStart = startTime.toLocal();
    final localEnd = endTime?.toLocal();
    final dateStr = DateFormatter.dateOnly(localStart);
    final startStr = DateFormatter.timeOnly(localStart);
    final endStr =
        localEnd != null ? DateFormatter.timeOnly(localEnd) : null;
    final timeText =
        endStr != null ? '$startStr - $endStr' : startStr;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Date row ─────────────────────────
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 11,
                color: accent,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  dateStr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    height: 1.0,
                    color: accent,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // ── Time row ──────────────────────────
          Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                size: 12,
                color: accent,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  timeText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    height: 1.0,
                    color: accent,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// SHARE CODE ROW — pill full-width, tap để copy
// ═══════════════════════════════════════════════════════════════════════

/// Share code pill full-width chiếm trọn chiều ngang card. Player bấm trực
/// tiếp vào pill để copy mã 8 ký tự — không cần nút copy riêng.
///
/// UI gọn để vừa vertical card grid (mainAxisExtent hữu hạn):
/// - Pill gradient full-width với mã code bold căn giữa.
/// - Bỏ icon trang trí 2 bên (đã từng làm mã code bị truncate thành
///   "J2T2GE..." khi card hẹp). Toàn bộ chiều ngang pill dành cho mã.
/// - Font mã 13px w900 letter-spacing 1.4 — đủ rõ để player chụp ảnh /
///   đọc nhanh, vẫn gọn trong 1 dòng.
/// - Tap pill → `Clipboard.setData(code)` + snackbar "Đã sao chép mã phòng".
/// - Ripple effect (InkWell) để feedback cho user biết pill tương tác được.
class _ShareCodeRow extends StatelessWidget {
  final String code;
  final bool isDark;

  const _ShareCodeRow({required this.code, required this.isDark});

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!context.mounted) return;
    context.showTopSnackBar('Đã sao chép mã phòng');
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _copy(context),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, Color(0xFFFF8A50)],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.25),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              code,
              maxLines: 1,
              softWrap: false,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1.4,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════

/// Pattern dots nhỏ — trang trí subtle.
class _DotsPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    const spacing = 6.0;
    const radius = 1.5;
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
// STATUS PILL (cho vertical layout)
// ═══════════════════════════════════════════════════════════════════════

class _GridStatusPill extends StatelessWidget {
  final String label;
  final IconData icon;

  const _GridStatusPill({
    required this.label,
    required this.icon,
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
          Icon(icon, size: 13, color: Colors.black87),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
              letterSpacing: 0.2,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _OwnedChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFFFF8A50)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.4),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 10, color: Colors.white),
          SizedBox(width: 2),
          Text(
            'CỦA TÔI',
            style: TextStyle(
              color: Colors.white,
              fontSize: 8.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.3,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}


// ═══════════════════════════════════════════════════════════════════════
// PLAYERS AVATARS ROW (cho vertical grid layout mới)
// ═══════════════════════════════════════════════════════════════════════



// ═══════════════════════════════════════════════════════════════════════
// PLAYERS FALLBACK (khi không có player data)
// ═══════════════════════════════════════════════════════════════════════


// ═══════════════════════════════════════════════════════════════════════
// TIME CHIP COMPACT (cho vertical layout mới)
// ═══════════════════════════════════════════════════════════════════════


// ═══════════════════════════════════════════════════════════════════════
// SLOTS BADGE
// ═══════════════════════════════════════════════════════════════════════


// ═══════════════════════════════════════════════════════════════════════
// CODE BADGE
// ═══════════════════════════════════════════════════════════════════════


// ═══════════════════════════════════════════════════════════════════════
// DEPOSIT BADGE
// ═══════════════════════════════════════════════════════════════════════


// ── Avatar icon (gradient theo accent + soft shadow) ──────────────────────

class _AvatarIcon extends StatelessWidget {
  final Color accent;
  final bool isActive;
  final IconData icon;
  final double size;

  const _AvatarIcon({
    required this.accent,
    required this.isActive,
    required this.icon,
    this.size = 60,
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
            bgColor.withValues(alpha: 0.65),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: bgColor.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Subtle decorative pattern góc
          Positioned(
            right: -8,
            bottom: -8,
            child: Icon(
              icon,
              size: size * 0.55,
              color: Colors.white.withValues(alpha: 0.15),
            ),
          ),
          Center(
            child: Icon(icon, color: Colors.white, size: size * 0.5),
          ),
        ],
      ),
    );
  }
}

/// Tiny dot indicator thay cho "CỦA TÔI" pill — gọn, hiện đại, pill bo tròn.
class _OwnedDotIndicator extends StatelessWidget {
  const _OwnedDotIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFFFF8A50)],
        ),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Text(
        'CỦA TÔI',
        style: TextStyle(
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.3,
          height: 1.1,
        ),
      ),
    );
  }
}

// ── Pills / chips (Modern Game Store style) ──────────────────────────────

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
          Icons.storefront_rounded,
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
              fontSize: 13,
              fontWeight: FontWeight.w500,
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
  final Color accent;

  const _TimeChip({
    required this.scheduledTime,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final time = DateFormatter.dateTime(scheduledTime);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule_rounded, size: 13, color: accent),
          const SizedBox(width: 4),
          Text(
            time,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: accent,
              letterSpacing: -0.1,
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
    final isFull = current >= max;
    final color = isFull ? AppColors.error : accent;
    final bgColor = isFull
        ? AppColors.error.withValues(alpha: 0.1)
        : accent.withValues(alpha: 0.1);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.group_rounded,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            '$current/$max',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
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
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.accent, Color(0xFFFF8A50)],
        ),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.account_balance_wallet_rounded,
            size: 13,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            '$deposit BVC',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Code pill hiển thị mã reservation (8-char) cho POS check-in.
/// Tap vào pill để copy mã vào clipboard — player copy nhanh từ card
/// (horizontal layout) không cần mở detail. Snackbar xác nhận "Đã sao
/// chép mã phòng" tương tự [_ShareCodeRow] (vertical layout).
class _CodePill extends StatelessWidget {
  final String code;

  const _CodePill({required this.code});

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!context.mounted) return;
    context.showTopSnackBar('Đã sao chép mã phòng');
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _copy(context),
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 9,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.qr_code_rounded,
                size: 13,
                color: AppColors.primary,
              ),
              const SizedBox(width: 4),
              Text(
                code,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                  letterSpacing: 1.2,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
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
    // `inviteCode` map sang `shareCode` từ backend (LobbyEntity.inviteCode
    // được populate từ JSON key `shareCode` ở LobbyModel.fromJson). Đây là
    // mã 8 ký tự player dùng để share nhanh — UI phải hiện và cho copy từ
    // card, không bắt buộc vào chi tiết phòng.
    code: lobbyEntity.inviteCode,
    depositBvc: 0,
    players: lobbyEntity.players
        .map((p) => LobbyPlayerInfo(
              name: p.name,
              avatarUrl: p.avatarUrl.isNotEmpty ? p.avatarUrl : null,
              isHost: p.isHost,
              isReady: p.isReady,
            ))
        .toList(),
  );
}

/// Build `LobbyCardItem` từ ReservationEntity (cho ReservationList).
LobbyCardItem lobbyItemFromReservation(res.ReservationEntity r) {
  // r.lobbyStatus giờ đã dùng chung lobby.LobbyStatus — không cần convert.
  final lobbyStatus = r.lobbyStatus;

  final variant = resolveLobbyCardVariant(
    lobbyStatus: lobbyStatus,
    reservationStatus: r.status,
  );

  final code = r.lobbyShareCode;

  // Calculate end time from preferredEndTime
  DateTime? endTime;
  if (r.preferredEndTime != null && r.preferredEndTime!.isNotEmpty) {
    final parts = r.preferredEndTime!.split(':');
    if (parts.length >= 2) {
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;
      endTime = DateTime(
        r.scheduledTime.year,
        r.scheduledTime.month,
        r.scheduledTime.day,
        hour,
        minute,
      );
    }
  }

  return LobbyCardItem(
    gameName: r.gameName,
    cafeName: r.cafeName,
    variant: variant,
    isActive: r.status.isActive || (lobbyStatus?.isActive ?? false),
    isOwnedByMe: true,
    scheduledTime: r.scheduledTime,
    endTime: endTime,
    currentPlayers: r.currentPlayers,
    maxPlayers: r.maxPlayers,
    depositBvc: r.finalDeposit,
    code: code,
  );
}
