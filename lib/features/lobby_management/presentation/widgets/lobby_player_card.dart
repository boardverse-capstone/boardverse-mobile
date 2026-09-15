import 'package:flutter/material.dart';

import 'package:boardverse/core/theme/app_colors.dart';
import 'package:boardverse/core/theme/app_icons.dart';
import 'package:boardverse/core/theme/app_spacing.dart';
import '../../domain/entities/lobby_entity.dart';

/// Card hiển thị 1 player trong lobby player grid.
///
/// Status label dựa trên **lobby.status + player.isHost/player.readyAt**:
/// - Host luôn hiển thị "Chủ phòng" (override tất cả trạng thái khác).
/// - Lobby terminal (closed/cancelled/timeout/rejected/expired) → "Đã đóng".
/// - Lobby `full` → hiển thị ready state để thành viên xác nhận.
/// - Lobby `waitingCheckIn` → tất cả đã sẵn sàng, chờ staff check-in.
/// - Lobby `inProgress`/`ratingOpen` → phiên tại quán đã bắt đầu hoặc đang đánh giá.
/// - Lobby `pendingActivation`/`pendingCafeApproval` → "Thành viên".
/// - Lobby `open`/`viable` → "Cần thêm người".
///
/// Mapping này đảm bảo UI phản ánh đúng nghiệp vụ từ backend
/// (`docs/apis/lobby.md` §State machine + BR-08 + BR-NEW-11).
///
/// **Host actions:** Khi `isHostViewer == true` VÀ `player.isHost == false`,
/// card hiển thị icon menu (⋮) ở **góc trên-trái của card** (xem
/// [_KickMemberMenuButton]). Trước đây nút này nằm overlay trên avatar
/// (top-right của avatar stack) — bị avatar/host badge che, tap target
/// nhỏ (~24px), khó bấm. Tap menu → mở action sheet với "Xóa khỏi
/// phòng" (POST /api/v1/lobbies/{lobbyId}/kick).
///
/// ── HELPER: darken status color cho chip text ─────────────────────
/// Trả về phiên bản tối hơn (~45% darker lightness) của [color]. Cần
/// thiết vì:
///   - Chip background dùng `status.color.withValues(alpha: 0.12)` →
///     rất nhạt, gần như tint nhẹ.
///   - Nếu text color cũng dùng `status.color` (full opacity) thì
///     contrast giữa text và bg quá thấp → text "chìm" vào bg, khó
///     đọc (đặc biệt warning/info màu vàng-cam vốn đã sáng).
///
/// Dùng HSLColor.withLightness() để darken ổn định cho MỌI màu (kể
/// cả `textTertiary` không có `*Dark` variant hardcode).
Color darkenForChipText(Color color) {
  final hsl = HSLColor.fromColor(color);
  final darkened = hsl
      .withLightness((hsl.lightness * 0.55).clamp(0.05, 0.95))
      .toColor();
  return darkened;
}

class LobbyPlayerCard extends StatelessWidget {
  final LobbyPlayer player;

  /// Lobby hiện tại — dùng để derive status label theo lobby state.
  final LobbyStatus lobbyStatus;

  final bool isCurrentUser;

  /// true khi người xem là host của lobby — bật icon menu (⋮)
  /// để host kick member không phải host.
  final bool isHostViewer;

  /// Callback khi host bấm "Xóa khỏi phòng" từ action sheet.
  /// Chỉ gọi khi `isHostViewer == true` VÀ `player.isHost == false`.
  final VoidCallback? onKickMember;

  final VoidCallback? onTap;

  const LobbyPlayerCard({
    super.key,
    required this.player,
    required this.lobbyStatus,
    this.isCurrentUser = false,
    this.isHostViewer = false,
    this.onKickMember,
    this.onTap,
  });

  /// Resolve label + màu cho status chip của player dựa trên
  /// (lobbyStatus, player.isHost, player.readyAt).
  ///
  /// BR-LOBBY-READY-01: check `readyAt != null` (DateTime) thay vì
  /// `bool isReady`. Backend có thể trả `readyAt: null` nhưng flag lỗi
  /// thời — check DateTime mới chính xác.
  ({String label, Color color}) _resolveStatus() {
    // 1. Host luôn là "Chủ phòng" — bất kể lobby state.
    if (player.isHost) {
      return (label: 'Chủ phòng', color: AppColors.accent);
    }

    // 2. Lobby đã terminal → tất cả player đều "Đã đóng".
    if (lobbyStatus.isTerminal) {
      return (label: 'Đã đóng', color: AppColors.textTertiary);
    }

    // 3. Lobby `waitingCheckIn` → tất cả đã Ready, chờ staff check-in.
    if (lobbyStatus == LobbyStatus.waitingCheckIn) {
      return (label: 'Chờ check-in', color: AppColors.warning);
    }

    // 4. Đã bấm Ready (BR-LOBBY-READY-01: `readyAt != null`) → ưu tiên
    //    hiển thị "Sẵn sàng" ở mọi phase pre-game/check-in (`open` /
    //    `viable` / `full` / `pendingCafeApproval` / `inProgress` /
    //    `ratingOpen`). Trước đây chỉ phase `full`/`inProgress`/`ratingOpen`
    //    mới flip → user thấy "Cần thêm người" dù đã bấm Ready ở lobby
    //    open/viable.
    if (player.readyAt != null &&
        (lobbyStatus == LobbyStatus.open ||
            lobbyStatus == LobbyStatus.viable ||
            lobbyStatus == LobbyStatus.full ||
            lobbyStatus == LobbyStatus.inProgress ||
            lobbyStatus == LobbyStatus.ratingOpen ||
            lobbyStatus == LobbyStatus.pendingCafeApproval)) {
      return (label: 'Sẵn sàng', color: AppColors.success);
    }

    // 5. Phase chưa Ready: full/inProgress/ratingOpen → "Chưa sẵn sàng".
    if (lobbyStatus == LobbyStatus.full ||
        lobbyStatus == LobbyStatus.inProgress ||
        lobbyStatus == LobbyStatus.ratingOpen) {
      return (label: 'Chưa sẵn sàng', color: AppColors.textTertiary);
    }

    // 6. Lobby open/viable, player chưa Ready → "Cần thêm người".
    if (lobbyStatus == LobbyStatus.open ||
        lobbyStatus == LobbyStatus.viable) {
      return (label: 'Cần thêm người', color: AppColors.info);
    }

    // 7. Lobby pending (chờ kích hoạt / chờ quán duyệt) → "Thành viên".
    if (lobbyStatus == LobbyStatus.pendingActivation ||
        lobbyStatus == LobbyStatus.pendingCafeApproval) {
      return (label: 'Thành viên', color: AppColors.warning);
    }

    return (label: 'Thành viên', color: AppColors.textTertiary);
  }

  /// Quyết định có show badge "ready" (icon check) trên avatar hay không.
  /// BR-LOBBY-READY-01: hiển thị ở mọi phase pre-game/check-in (open/viable/
  /// full/waitingCheckIn/pendingCafeApproval/inProgress/ratingOpen) khi
  /// player đã bấm Ready (`readyAt != null`). Host luôn ưu tiên host badge.
  bool _showReadyBadge() {
    if (player.isHost) return false; // ưu tiên host badge
    if (player.readyAt == null) return false; // chưa Ready → không hiện
    switch (lobbyStatus) {
      case LobbyStatus.open:
      case LobbyStatus.viable:
      case LobbyStatus.full:
      case LobbyStatus.waitingCheckIn:
      case LobbyStatus.pendingCafeApproval:
      case LobbyStatus.inProgress:
      case LobbyStatus.ratingOpen:
        return true;
      // pendingActivation / terminal → không hiện (lobby chưa publish hoặc
      // đã kết thúc).
      case LobbyStatus.pendingActivation:
      case LobbyStatus.closed:
      case LobbyStatus.timeoutFailed:
      case LobbyStatus.hostCancelled:
      case LobbyStatus.rejectedByCafe:
      case LobbyStatus.expiredByCafe:
      case LobbyStatus.dissolved:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = _resolveStatus();
    final statusLabel = status.label;

    final cardColor = isCurrentUser
        ? (isDark ? AppColors.primaryDark : AppColors.primaryLight)
        : (isDark ? AppColors.surfaceDark : AppColors.surface);
    final borderColor = isCurrentUser
        ? AppColors.primary
        : (isDark ? AppColors.borderDark : AppColors.border);
    final textColor = isDark ? AppColors.white : AppColors.black;

    // Phase 4 2026-09-15: wrap Semantics trong [SizedBox.expand] để
    // **đảm bảo tuyệt đối** LobbyPlayerCard fill 100% parent size
    // (parent là SizedBox cardSize × cardSize bên ngoài). Mặc dù
    // Material widget nhận tight constraints từ parent nhưng trong một
    // số nested Stack/Container lồng nhau, intrinsic sizing có thể
    // khiến content không fill hết. `SizedBox.expand()` loại bỏ mọi
    // ambiguity — nó ép child (Semantics → Material → Stack → …)
    // nhận tight BoxConstraints(fill parent) rồi mới tính intrinsic.
    return SizedBox.expand(
      child: Semantics(
        button: onTap != null,
        label: '${player.name}, $statusLabel',
        child: Material(
          color: Colors.transparent,
          clipBehavior: Clip.antiAlias,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            splashColor: AppColors.primary.withValues(alpha: 0.06),
            child: Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: borderColor,
                  width: isCurrentUser ? 2 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isCurrentUser
                        ? AppColors.primary.withValues(alpha: 0.25)
                        : Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(
                // Phase 4 2026-09-15: padding xs (8) ngang + xs (8) dọc.
                // Card 2-per-row (~174×174 cho 360dp viewport) nên
                // padding vừa phải — quá to sẽ bóp content, quá nhỏ
                // sẽ thiếu breathing room. xs là balance tốt.
                horizontal: AppSpacing.xs,
                vertical: AppSpacing.xs,
              ),
              // ── VERTICAL LAYOUT (Phase 4 2026-09-15 lần 2) ───────
              // Revert từ Row (horizontal profile) về Column (vertical
              // profile) sau khi user feedback "tôi muốn 2 card cùng
              // 1 hàng". Lý do:
              //   1. Với 2-per-row cards ~174dp wide, horizontal
              //      layout sẽ quá chật — info column chỉ còn ~50dp
              //      sau khi trừ avatar + kick menu, không đủ cho
              //      name + chip.
              //   2. Vertical layout cho card vuông (174×174) tận
              //      dụng không gian tốt hơn — avatar centered ở
              //      trên, name + chip centered dưới.
              //   3. UI quen thuộc hơn với user (Phase 3 design đã
              //      chạy ổn định).
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── Avatar + badges stack (top center) ──────────
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _PlayerAvatar(
                        player: player,
                        isCurrentUser: isCurrentUser,
                      ),
                      // Ready badge — góc dưới-phải avatar
                      if (_showReadyBadge())
                        Positioned(
                          right: -4,
                          bottom: -4,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.success,
                                  Color(0xFF0E8A68),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.success
                                      .withValues(alpha: 0.4),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(AppIcons.check,
                                size: 14, color: AppColors.white),
                          ),
                        ),
                      // Host badge — góc trên-trái avatar
                      if (player.isHost)
                        Positioned(
                          left: -4,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.xxs),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.accent, Color(0xFFFFC107)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accent
                                      .withValues(alpha: 0.4),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(AppIcons.starFilled,
                                size: 13, color: AppColors.black),
                          ),
                        ),
                      // Kick menu (⋮) — góc trên-phải avatar, đè
                      // lên border card (top: -10, right: -10)
                      if (isHostViewer && !player.isHost)
                        Positioned(
                          top: -10,
                          right: -10,
                          child: _KickMemberMenuButton(onTap: onKickMember),
                        ),
                    ],
                  ),
                  // Gap giữa avatar và name
                  const SizedBox(height: AppSpacing.xs),
                  // Name — centered, font 16 (lớn hơn Phase 3 là 14)
                  Text(
                    player.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: textColor,
                      fontSize: 16,
                      letterSpacing: -0.3,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  // Status chip — font 12, padding thoáng
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xxs + 2,
                    ),
                    decoration: BoxDecoration(
                      color: status.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      statusLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        // Phase 4 2026-09-15: dùng `darkenForChipText`
                        // thay vì `status.color` thuần để tăng
                        // contrast text/background. Trước đây text
                        // "Chờ check-in" (warning orange) và "Sẵn
                        // sàng" (success green) dễ bị "chìm" vào
                        // chip background (alpha 12% của cùng màu) →
                        // user feedback "text status chìm với bg".
                        // Darken lightness ~45% để text nổi rõ trên
                        // tinted bg.
                        color: darkenForChipText(status.color),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        letterSpacing: 0.1,
                        height: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Nút "⋮" (kick member menu) — góc trên-phải avatar trong [LobbyPlayerCard].
///
/// Nằm TRONG avatar Stack (không phải card-level Stack), với vị trí
/// `top: -10, right: -10` để đè lên góc trên-phải avatar (xấp xỉ góc
/// trên-phải card vì avatar ở giữa card).
///
/// `borderRadius: 18` của card bo tròn toàn bộ Material widget, nên
/// phần button nằm trong vùng bo góc sẽ bị clip bởi Material.clipBehavior.
/// Giải pháp: kích thước 26×26 với vị trí `top:-10, right:-10` đặt
/// tâm button cách đỉnh card 13px, trong khi bán kính bo góc ở vị trí
/// đó chỉ ~2px → button gần như không bị clip.
///
/// GestureDetector với `opaque` chặn hit test không lan xuống InkWell
/// card body → host bấm ⋮ không trigger onTap card.
class _KickMemberMenuButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _KickMemberMenuButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Mở menu thành viên',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Material(
          color: AppColors.white,
          shape: const CircleBorder(
            side: BorderSide(
              color: AppColors.error,
              width: 1.5,
            ),
          ),
          elevation: 2,
          shadowColor: Colors.black.withValues(alpha: 0.2),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: 30,
            height: 30,
            child: Center(
              child: Icon(
                AppIcons.moreVertical,
                size: 18,
                color: AppColors.error,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayerAvatar extends StatelessWidget {
  final LobbyPlayer player;
  final bool isCurrentUser;

  const _PlayerAvatar({required this.player, required this.isCurrentUser});

  @override
  Widget build(BuildContext context) {
    final hasAvatar = player.avatarUrl.trim().isNotEmpty;
    final initial = player.name.trim().isEmpty
        ? '?'
        : player.name.trim().characters.first.toUpperCase();
    final avatarColor = isCurrentUser
        ? AppColors.primary
        : AppColors.secondary;

    return Container(
      // Phase 4 2026-09-15: avatar 80 (to hơn 72 — Phase 3) vì giờ card
      // là full-width 1-per-row, có nhiều horizontal space hơn nên
      // avatar có thể to hơn mà vẫn cân đối. User feedback "width item
      // card quá ngắn" → to avatar lên 80 để trở thành điểm nhấn
      // chính trên card wide.
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            avatarColor,
            avatarColor.withValues(alpha: 0.65),
          ],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: avatarColor.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: hasAvatar
          ? ClipOval(
              child: Image.network(
                player.avatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Center(
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: AppColors.white,
                      fontSize: 26,
                    ),
                  ),
                ),
              ),
            )
          : Center(
              child: Text(
                initial,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppColors.white,
                  fontSize: 26,
                ),
              ),
            ),
    );
  }
}

/// Modern grid hiển thị players + empty slots.
class LobbyPlayerGrid extends StatelessWidget {
  final List<LobbyPlayer> players;
  final int maxSlots;
  final String? currentUserId;

  /// Lobby hiện tại — truyền xuống từng [LobbyPlayerCard] để derive
  /// status label theo lobby state.
  final LobbyStatus lobbyStatus;

  /// true khi viewer là host của lobby — hiển thị nút kick member
  /// trên mỗi player card (player không phải host).
  final bool isCurrentUserHost;

  /// Callback khi host bấm action menu kick member.
  /// Chỉ gọi khi `isCurrentUserHost == true` VÀ player ≠ host.
  final Future<void> Function(LobbyPlayer player)? onKickMember;

  final Function(LobbyPlayer)? onPlayerTap;

  const LobbyPlayerGrid({
    super.key,
    required this.players,
    required this.maxSlots,
    required this.lobbyStatus,
    this.currentUserId,
    this.isCurrentUserHost = false,
    this.onKickMember,
    this.onPlayerTap,
  });

  @override
  Widget build(BuildContext context) {
    final emptySlots = (maxSlots - players.length).clamp(0, maxSlots);
    final totalSlots = players.length + emptySlots;
    if (totalSlots == 0) return const SizedBox.shrink();

    // Phase 4 2026-09-15 (cập nhật lần 2 — sau khi user feedback): revert
    // về "2 cards-per-row grid" (user feedback "tôi muốn 2 card cùng 1
    // hàng"), giữ các cải thiện UI:
    //   - Section padding 4 (xxs) horizontal — giảm từ xs (8) để cards
    //     rộng hơn (user feedback "card width quá ngắn").
    //   - Gap giữa cards 4 (xxs) — giảm từ xs (8) để cards rộng hơn.
    //   - LayoutBuilder + SizedBox tuyệt đối (width + height) — Phase 3.
    //   - KHÔNG dùng 1-per-row full-width nữa (đã thử nhưng user không
    //     thích layout này).
    //
    // Cách tính:
    // - `SizedBox(width: double.infinity)` ép tight width constraint.
    // - `LayoutBuilder` lấy maxWidth, tính `cardSize = (avail - gap) / 2`.
    // - Từng card là `SizedBox(width: cardSize, height: cardSize)` — fill
    //   100% row width (2 * cardSize + gap = avail), không thừa
    //   "khoảng trống thừa" như user feedback trước.
    return SizedBox(
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Phase 4 2026-09-15: gap xs (8) → xxs (4) để cards rộng
          // hơn nữa. Trước: page 360 - padding 8 - gap 8 = 344, card
          // 344/2 = 172. Sau: page 360 - padding 8 - gap 4 = 348,
          // card 348/2 = 174. Kết hợp với padding xxs (4) ở
          // PlayersSection → card 174dp (vs 168dp Phase 3, +6dp).
          const gap = AppSpacing.xxs; // 4 — khoảng cách giữa 2 card
          final avail =
              constraints.hasBoundedWidth ? constraints.maxWidth : 360.0;
          final cardSize = (avail - gap) / 2;

          final rows = <Widget>[];
          for (int i = 0; i < totalSlots; i += 2) {
            // Padding giữa các rows (chỉ insert từ row thứ 2 trở đi).
            if (i > 0) rows.add(const SizedBox(height: gap));

            final firstCard = _buildSlot(i, players);
            final hasSecond = i + 1 < totalSlots;
            final secondCard =
                hasSecond ? _buildSlot(i + 1, players) : null;

            // Một row với 2 SizedBox tuyệt đối (width + height =
            // cardSize). Không có `Expanded` nên không có risk bị
            // shrink.
            // Tổng: 2 * cardSize + gap = avail → fill chuẩn 100% row.
            rows.add(
              Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  SizedBox(width: cardSize, height: cardSize, child: firstCard),
                  SizedBox(width: gap),
                  SizedBox(
                    width: cardSize,
                    height: cardSize,
                    child: secondCard ?? const _EmptySlotCard(),
                  ),
                ],
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: rows,
          );
        },
      ),
    );
  }

  /// Build một slot card (player hoặc empty slot) — full width, height
  /// được set bên ngoài qua `SizedBox(height: cardHeight)`.
  Widget _buildSlot(int index, List<LobbyPlayer> playersList) {
    if (index < playersList.length) {
      final player = playersList[index];
      // So sánh cả `id` (mock cũ) và `userId` (response mới) để
      // highlight đúng người đang đăng nhập.
      final isCurrentUser =
          currentUserId != null &&
              (player.userId == currentUserId || player.id == currentUserId);
      return LobbyPlayerCard(
        player: player,
        lobbyStatus: lobbyStatus,
        isCurrentUser: isCurrentUser,
        isHostViewer: isCurrentUserHost,
        onKickMember: onKickMember == null
            ? null
            : () => onKickMember?.call(player),
        onTap: onPlayerTap == null
            ? null
            : () => onPlayerTap?.call(player),
      );
    }
    return const _EmptySlotCard();
  }
}

/// Empty slot với neo-brutalism style.
class _EmptySlotCard extends StatelessWidget {
  const _EmptySlotCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      label: 'Vị trí đang trống',
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.border,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  AppIcons.userAdd,
                  size: 24,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Đang trống',
                style: TextStyle(
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Mời bạn bè',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Banner hỗ trợ chỉ dẫn hiển thị khi lobby đã đầy (currentPlayers == maxPlayers).
///
/// Theo nghiệp vụ BoardVerse (BR §17.5, lobby.md):
/// - Sau khi lobby chuyển sang `Full` → member & host **đều phải bấm "Sẵn
///   sàng" (POST /lobbies/{id}/ready)**.
/// - Khi tất cả member ready → lobby chuyển sang `InProgress` (POS check-in).
///
/// UX: khi slot cuối cùng vừa được lấp, player chưa biết phải làm gì tiếp.
/// Banner này:
/// - Hiển thị progress ready: "X/Y đã sẵn sàng".
/// - Cho phép current user toggle Ready/Unready.
/// - Cập nhật real-time khi member khác bấm (qua SignalR + cubit).
class LobbyFullGuidanceBanner extends StatefulWidget {
  /// Lobby hiện tại.
  final LobbyEntity lobby;

  /// ID của current user — dùng tìm `isReady` của chính họ trong `lobby.players`.
  final String currentUserId;

  /// Bấm để toggle ready (host + member đều dùng).
  final Future<void> Function(bool isReady)? onToggleReady;

  /// Optional callback mở bottom sheet chi tiết lobby.
  final VoidCallback? onSecondaryAction;

  const LobbyFullGuidanceBanner({
    super.key,
    required this.lobby,
    required this.currentUserId,
    this.onToggleReady,
    this.onSecondaryAction,
  });

  @override
  State<LobbyFullGuidanceBanner> createState() =>
      _LobbyFullGuidanceBannerState();
}

class _LobbyFullGuidanceBannerState extends State<LobbyFullGuidanceBanner> {
  bool _isToggling = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Tính `isFull` nhưng KHÔNG dùng làm guard ẩn banner.
    // User có thể bấm "Sẵn sàng" kể cả khi phòng chưa đầy (BR-LOBBY-READY-01:
    // player có thể ready từ sớm, không cần đợi đủ maxPlayers).
    final isFull = widget.lobby.currentPlayers >= widget.lobby.maxPlayers;

    // Không show nếu lobby đã kết thúc → tránh gây nhiễu.
    final endedStatuses = {
      LobbyStatus.closed,
      LobbyStatus.timeoutFailed,
      LobbyStatus.hostCancelled,
      LobbyStatus.rejectedByCafe,
      LobbyStatus.expiredByCafe,
    };
    if (endedStatuses.contains(widget.lobby.status)) {
      return const SizedBox.shrink();
    }

    // Tính số người đã Ready (BR-LOBBY-READY-01: `readyAt != null`).
    final readyCount =
        widget.lobby.players.where((p) => p.readyAt != null).length;
    final totalMembers = widget.lobby.players.length;

    // Current user có phải member + ready chưa?
    LobbyPlayer? currentPlayer;
    for (final p in widget.lobby.players) {
      if (p.userId == widget.currentUserId || p.id == widget.currentUserId) {
        currentPlayer = p;
        break;
      }
    }
    final isCurrentUserMember = currentPlayer != null;
    final isCurrentUserReady = currentPlayer?.isReady ?? false;
    final isCurrentUserHost = currentPlayer?.isHost ?? false;

    // Trạng thái lobby đặc biệt: inProgress / pendingCafeApproval → copy khác.
    // Mở rộng ready section cho TẤT CẢ lobby active: open, viable, full, inProgress
    // — player có thể bấm "Sẵn sàng" ngay khi tham gia, không cần đợi đủ người.
    final showReadySection =
        widget.lobby.status == LobbyStatus.open ||
        widget.lobby.status == LobbyStatus.viable ||
        widget.lobby.status == LobbyStatus.full ||
        widget.lobby.status == LobbyStatus.pendingCafeApproval;

    return Semantics(
      container: true,
      label: 'Phòng ${isFull ? "đã đầy" : "đang tuyển"}. ${showReadySection ? "Sẵn sàng: $readyCount/$totalMembers" : ""}',
      child: Container(
        margin: const EdgeInsets.only(top: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    AppColors.surfaceElevatedDark,
                    AppColors.surfaceDark,
                  ]
                : [
                    AppColors.accentLight,
                    AppColors.surface,
                  ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────────
            Row(
              children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFFFF8A50)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  AppIcons.users,
                  size: 16,
                  color: AppColors.white,
                ),
              ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    isFull
                        ? 'Phòng đã đầy • ${widget.lobby.currentPlayers}/${widget.lobby.maxPlayers}'
                        : 'Phòng đang tuyển • ${widget.lobby.currentPlayers}/${widget.lobby.maxPlayers}',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // ── Body copy theo trạng thái ───────────────────────────
            if (widget.lobby.status == LobbyStatus.inProgress)
              _bodyInProgress(isDark)
            else if (widget.lobby.status == LobbyStatus.waitingCheckIn)
              _bodyWaitingCheckIn(isDark)
            else if (widget.lobby.status == LobbyStatus.pendingCafeApproval)
              _bodyPendingCafeApproval(isDark)
            else if (showReadySection)
              _bodyReadySection(
                isDark: isDark,
                readyCount: readyCount,
                totalMembers: totalMembers,
                isCurrentUserReady: isCurrentUserReady,
                isCurrentUserHost: isCurrentUserHost,
              )
            else
              _bodyFallback(isDark),

            // ── Action buttons ──────────────────────────────────────
            const SizedBox(height: AppSpacing.md),
            if (showReadySection && isCurrentUserMember) ...[
              Row(
                children: [
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isToggling
                            ? null
                            : () => _handleToggleReady(isCurrentUserReady),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            gradient: isCurrentUserReady
                                ? const LinearGradient(
                                    colors: [AppColors.accent, Color(0xFFFFC107)],
                                  )
                                : const LinearGradient(
                                    colors: [AppColors.primary, Color(0xFFFF8A50)],
                                  ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: (isCurrentUserReady
                                        ? AppColors.accent
                                        : AppColors.primary)
                                    .withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isToggling)
                                const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.white,
                                  ),
                                )
                              else
                                Icon(
                                  isCurrentUserReady
                                      ? AppIcons.check
                                      : AppIcons.clock,
                                  size: 16,
                                  color: isCurrentUserReady
                                      ? AppColors.black
                                      : AppColors.white,
                                ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                isCurrentUserReady
                                    ? 'Đã sẵn sàng ✓'
                                    : 'Bấm Sẵn sàng',
                                style: TextStyle(
                                  color: isCurrentUserReady
                                      ? AppColors.black
                                      : AppColors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (widget.onSecondaryAction != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: widget.onSecondaryAction,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.surfaceDark
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.borderDark
                                  : AppColors.border,
                              width: 1.5,
                            ),
                          ),
                          child: const Text(
                            'Chi tiết',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ] else if (widget.onSecondaryAction != null) ...[
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onSecondaryAction,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surfaceDark
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.border,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(AppIcons.info,
                            size: 16, color: AppColors.info),
                        const SizedBox(width: AppSpacing.xs),
                        const Text(
                          'Xem chi tiết',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _handleToggleReady(bool wasReady) async {
    if (widget.onToggleReady == null) return;
    setState(() => _isToggling = true);
    try {
      await widget.onToggleReady!(!wasReady);
    } finally {
      if (mounted) setState(() => _isToggling = false);
    }
  }

  Widget _bodyReadySection({
    required bool isDark,
    required int readyCount,
    required int totalMembers,
    required bool isCurrentUserReady,
    required bool isCurrentUserHost,
  }) {
    final allReady = readyCount >= totalMembers && totalMembers > 0;
    final nextStep = allReady
        ? 'Tất cả đã sẵn sàng! Đợi đến ngày chơi — bấm "Đã tới quán" để check-in.'
        : isCurrentUserReady
            ? 'Đang đợi các thành viên khác bấm Sẵn sàng. Khi cả nhóm ready, '
                'lobby sẽ chuyển sang "Đang chơi" (InProgress).'
            : 'Mỗi thành viên${isCurrentUserHost ? " (bao gồm host)" : ""} '
                'bấm "Sẵn sàng" để xác nhận đã chuẩn bị xong. Khi tất cả ready, '
                'lobby sẽ chuyển sang "Đang chơi".';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress chip
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            gradient: allReady
                ? const LinearGradient(
                    colors: [AppColors.success, Color(0xFF0E8A68)],
                  )
                : const LinearGradient(
                    colors: [AppColors.accent, Color(0xFFFFC107)],
                  ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: (allReady ? AppColors.success : AppColors.accent)
                    .withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                allReady ? AppIcons.check : AppIcons.clock,
                size: 14,
                color: allReady ? AppColors.white : AppColors.black,
              ),
              const SizedBox(width: AppSpacing.xxs),
              Text(
                'Sẵn sàng: $readyCount/$totalMembers',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: allReady ? AppColors.white : AppColors.black,
                  fontSize: 12,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          nextStep,
          style: TextStyle(
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimary,
            fontSize: 13,
            height: 1.4,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _bodyWaitingCheckIn(bool isDark) {
    return Text(
      'Cả nhóm đã sẵn sàng. Hãy đến quán và chờ staff check-in để bắt đầu phiên chơi.',
      style: TextStyle(
        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _bodyInProgress(bool isDark) {
    return Text(
      'Lobby đã chuyển sang "Đang chơi". Đến quán đúng giờ và bấm "Đã tới '
      'quán" để nhận mã QR check-in. Đừng quên đánh giá Karma sau khi chơi '
      'xong!',
      style: TextStyle(
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
        fontSize: 13,
        height: 1.4,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _bodyPendingCafeApproval(bool isDark) {
    return Text(
      'Chủ phòng đang chờ quán duyệt. Bạn có thể bấm "Sẵn sàng" từ '
      'giờ để báo đã sẵn sàng chơi — quán sẽ được duyệt sớm thôi!',
      style: TextStyle(
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
        fontSize: 13,
        height: 1.4,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _bodyFallback(bool isDark) {
    return Text(
      'Phòng đã đầy. Theo dõi để cập nhật tiếp theo từ chủ phòng.',
      style: TextStyle(
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
        fontSize: 13,
        height: 1.4,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}