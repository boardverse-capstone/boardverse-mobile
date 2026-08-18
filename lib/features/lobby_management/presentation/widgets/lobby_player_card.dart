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
/// - Lobby `full`/`inProgress`/`ratingOpen` → hiển thị ready state của player
///   theo **BR-LOBBY-READY-01** (`readyAt != null` = "Sẵn sàng", ngược lại
///   "Chưa sẵn sàng"). Trước đây dùng `bool isReady` dễ bị drift với backend.
/// - Lobby `pendingActivation`/`pendingCafeApproval` → "Thành viên".
/// - Lobby `open`/`viable` → "Cần thêm người".
///
/// Mapping này đảm bảo UI phản ánh đúng nghiệp vụ từ backend
/// (`docs/apis/lobby.md` §State machine + BR-08 + BR-NEW-11).
class LobbyPlayerCard extends StatelessWidget {
  final LobbyPlayer player;

  /// Lobby hiện tại — dùng để derive status label theo lobby state.
  final LobbyStatus lobbyStatus;

  final bool isCurrentUser;
  final VoidCallback? onTap;

  const LobbyPlayerCard({
    super.key,
    required this.player,
    required this.lobbyStatus,
    this.isCurrentUser = false,
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

    // 3. Lobby đang ở phase có thể ready (full/inProgress/ratingOpen).
    if (lobbyStatus == LobbyStatus.full ||
        lobbyStatus == LobbyStatus.inProgress ||
        lobbyStatus == LobbyStatus.ratingOpen) {
      // BR-LOBBY-READY-01: `readyAt != null` = đã sẵn sàng.
      final isReady = player.readyAt != null;
      return isReady
          ? (label: 'Sẵn sàng', color: AppColors.success)
          : (label: 'Chưa sẵn sàng', color: AppColors.textTertiary);
    }

    // 4. Lobby open/viable → cần thêm người, player chưa cam kết.
    if (lobbyStatus == LobbyStatus.open ||
        lobbyStatus == LobbyStatus.viable) {
      return (label: 'Cần thêm người', color: AppColors.info);
    }

    // 5. Lobby pending (chờ kích hoạt / chờ quán duyệt) → "Thành viên".
    if (lobbyStatus == LobbyStatus.pendingActivation ||
        lobbyStatus == LobbyStatus.pendingCafeApproval) {
      return (label: 'Thành viên', color: AppColors.warning);
    }

    return (label: 'Thành viên', color: AppColors.textTertiary);
  }

  /// Quyết định có show badge "ready" (icon check) trên avatar hay không.
  /// Chỉ relevant khi lobby đang ở phase có ready (full/inProgress/ratingOpen).
  /// Host luôn có host badge (ưu tiên hơn ready badge).
  bool _showReadyBadge() {
    if (player.isHost) return false; // ưu tiên host badge
    return lobbyStatus == LobbyStatus.full ||
        lobbyStatus == LobbyStatus.inProgress ||
        lobbyStatus == LobbyStatus.ratingOpen;
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

    return Semantics(
      button: onTap != null,
      label: '${player.name}, $statusLabel',
      child: Material(
        color: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: borderColor,
                width: isCurrentUser ? 3 : 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.4),
                  blurRadius: 0,
                  offset: const Offset(3, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.sm,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Avatar + badges stack
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _PlayerAvatar(player: player, isCurrentUser: isCurrentUser),
                    // Ready badge — chỉ hiển thị khi lobby đang ở phase
                    // có ready (full/inProgress/ratingOpen). BR-LOBBY-READY-01:
                    // check `readyAt != null` (DateTime) thay vì bool flag.
                    if (_showReadyBadge()) ...[
                      Positioned(
                        right: -4,
                        bottom: -4,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: player.readyAt != null
                                ? AppColors.success
                                : AppColors.textTertiary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark
                                  ? AppColors.borderDark
                                  : AppColors.border,
                              width: 2,
                            ),
                          ),
                          child: player.readyAt != null
                              ? const Icon(AppIcons.check,
                                  size: 12, color: AppColors.white)
                              : null,
                        ),
                      ),
                    ],
                    // Host badge
                    if (player.isHost)
                      Positioned(
                        left: -4,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.xxs),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark
                                  ? AppColors.borderDark
                                  : AppColors.border,
                              width: 2,
                            ),
                          ),
                          child: const Icon(AppIcons.starFilled,
                              size: 12, color: AppColors.black),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                // Name
                Text(
                  player.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: textColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                // Status chip
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: status.color,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.border,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    statusLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: player.isHost
                          ? AppColors.black
                          : AppColors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasAvatar = player.avatarUrl.trim().isNotEmpty;
    final initial = player.name.trim().isEmpty
        ? '?'
        : player.name.trim().characters.first.toUpperCase();
    final avatarColor = isCurrentUser
        ? AppColors.primary
        : AppColors.secondary;

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: avatarColor,
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.4),
            blurRadius: 0,
            offset: const Offset(2, 2),
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
                      fontSize: 22,
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
                  fontSize: 22,
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

  final Function(LobbyPlayer)? onPlayerTap;

  const LobbyPlayerGrid({
    super.key,
    required this.players,
    required this.maxSlots,
    required this.lobbyStatus,
    this.currentUserId,
    this.onPlayerTap,
  });

  @override
  Widget build(BuildContext context) {
    final emptySlots = (maxSlots - players.length).clamp(0, maxSlots);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Phase 3 2026-08-10: chuyển sang **2 card / hàng** (cố định)
        // thay vì `maxCrossAxisExtent` (sinh ra 3 card khi viewport
        // ~360dp gây chật, info cắt cụt). Aspect ratio dùng cellWidth
        // để cell auto-resize cho cả mobile + tablet.
        const crossAxisCount = 2;
        const spacing = AppSpacing.md;
        final availableWidth = constraints.maxWidth -
            (spacing * (crossAxisCount - 1));
        final cellWidth = availableWidth / crossAxisCount;
        // Cell rộng : cao = 1 : 1.05 → đủ chỗ cho avatar + tên + chip.
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            childAspectRatio: cellWidth / (cellWidth * 1.05),
          ),
          itemCount: players.length + emptySlots,
          itemBuilder: (context, index) {
            if (index < players.length) {
              final player = players[index];
              // So sánh cả `id` (mock cũ) và `userId` (response mới) để
              // highlight đúng người đang đăng nhập.
              final isCurrentUser =
                  currentUserId != null &&
                      (player.userId == currentUserId ||
                          player.id == currentUserId);
              return LobbyPlayerCard(
                player: player,
                lobbyStatus: lobbyStatus,
                isCurrentUser: isCurrentUser,
                onTap: onPlayerTap == null
                    ? null
                    : () => onPlayerTap?.call(player),
              );
            }
            return const _EmptySlotCard();
          },
        );
      },
    );
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
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.border,
            width: 2,
            style: BorderStyle.solid,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.3),
              blurRadius: 0,
              offset: const Offset(3, 3),
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
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
                child: const Icon(
                  AppIcons.userAdd,
                  size: 22,
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
        widget.lobby.status == LobbyStatus.inProgress ||
        widget.lobby.status == LobbyStatus.pendingCafeApproval;

    return Semantics(
      container: true,
      label: 'Phòng ${isFull ? "đã đầy" : "đang tuyển"}. ${showReadySection ? "Sẵn sàng: $readyCount/$totalMembers" : ""}',
      child: Container(
        margin: const EdgeInsets.only(top: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceElevatedDark : AppColors.accentLight,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.border,
                      width: 2,
                    ),
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
                            color: isCurrentUserReady
                                ? AppColors.accent
                                : AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.borderDark
                                  : AppColors.border,
                              width: 2.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.black.withValues(alpha: 0.4),
                                blurRadius: 0,
                                offset: const Offset(3, 3),
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
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.surfaceDark
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.borderDark
                                  : AppColors.border,
                              width: 2.5,
                            ),
                          ),
                          child: const Text(
                            'Chi tiết',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
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
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surfaceDark
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.border,
                        width: 2.5,
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
            vertical: AppSpacing.xxs,
          ),
          decoration: BoxDecoration(
            color: allReady ? AppColors.success : AppColors.accent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.border,
              width: 2,
            ),
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