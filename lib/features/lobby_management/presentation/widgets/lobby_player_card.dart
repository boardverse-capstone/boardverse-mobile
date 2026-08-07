import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../domain/entities/lobby_entity.dart';

/// Modern lobby player card với gradient accent, badge indicators, và
/// press animation. Sử dụng board game style với glass-morphism hint.
class LobbyPlayerCard extends StatelessWidget {
  final LobbyPlayer player;
  final bool isCurrentUser;
  final VoidCallback? onTap;

  const LobbyPlayerCard({
    super.key,
    required this.player,
    this.isCurrentUser = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final successColor = theme.brightness == Brightness.dark
        ? AppColorsDark.success
        : AppColors.success;
    final statusColor = player.isReady ? successColor : colors.outline;
    final statusLabel = player.isHost
        ? 'Chủ phòng'
        : player.isReady
            ? 'Sẵn sàng'
            : 'Đang chờ';

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
              gradient: isCurrentUser
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colors.primary.withValues(alpha: 0.15),
                        colors.primary.withValues(alpha: 0.05),
                      ],
                    )
                  : null,
              color: isCurrentUser
                  ? null
                  : colors.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: AppRadius.radiusLgAll,
              border: Border.all(
                color: isCurrentUser
                    ? colors.primary.withValues(alpha: 0.6)
                    : colors.outlineVariant.withValues(alpha: 0.5),
                width: isCurrentUser ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isCurrentUser ? colors.primary : colors.primary)
                      .withValues(alpha: isCurrentUser ? 0.08 : 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
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
                    // Ready badge
                    Positioned(
                      right: -AppSpacing.xxs,
                      bottom: -AppSpacing.xxs,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: colors.surface, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: statusColor.withValues(alpha: 0.4),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: player.isReady
                            ? const Icon(AppIcons.check, size: 12, color: Colors.white)
                            : null,
                      ),
                    ),
                    // Host badge
                    if (player.isHost)
                      Positioned(
                        left: -AppSpacing.xxs,
                        top: -AppSpacing.xxs,
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.xxs),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [colors.tertiary, colors.tertiary.withAlpha(204)],
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(color: colors.surface, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: colors.tertiary.withValues(alpha: 0.4),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: const Icon(AppIcons.starFilled, size: 12, color: Colors.white),
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
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isCurrentUser ? colors.primary : colors.onSurface,
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
                    gradient: LinearGradient(
                      colors: [
                        (player.isHost ? colors.tertiary : statusColor).withValues(alpha: 0.15),
                        (player.isHost ? colors.tertiary : statusColor).withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: AppRadius.radiusFullAll,
                    border: Border.all(
                      color: (player.isHost ? colors.tertiary : statusColor)
                          .withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    statusLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: player.isHost
                          ? colors.tertiary
                          : statusColor,
                      fontWeight: FontWeight.w800,
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
    final colors = Theme.of(context).colorScheme;
    final hasAvatar = player.avatarUrl.trim().isNotEmpty;
    final initial = player.name.trim().isEmpty
        ? '?'
        : player.name.trim().characters.first.toUpperCase();
    final avatarColor = isCurrentUser
        ? colors.primaryContainer
        : colors.secondaryContainer;

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            avatarColor,
            avatarColor.withAlpha(200),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: avatarColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: colors.onSecondaryContainer,
                        ),
                  ),
                ),
              ),
            )
          : Center(
              child: Text(
                initial,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: colors.onSecondaryContainer,
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
  final Function(LobbyPlayer)? onPlayerTap;

  const LobbyPlayerGrid({
    super.key,
    required this.players,
    required this.maxSlots,
    this.currentUserId,
    this.onPlayerTap,
  });

  @override
  Widget build(BuildContext context) {
    final emptySlots = (maxSlots - players.length).clamp(0, maxSlots);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxExtent = constraints.maxWidth >= 720 ? 172.0 : 152.0;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: maxExtent,
            childAspectRatio: 0.72,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
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

/// Empty slot với gradient accent để thu hút attention.
class _EmptySlotCard extends StatelessWidget {
  const _EmptySlotCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Semantics(
      label: 'Vị trí đang trống',
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.surfaceContainerHighest.withValues(alpha: 0.3),
              colors.surfaceContainerHighest.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: AppRadius.radiusLgAll,
          border: Border.all(
            color: colors.outlineVariant.withValues(alpha: 0.4),
            style: BorderStyle.solid,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colors.primary.withValues(alpha: 0.1),
                      colors.primary.withValues(alpha: 0.05),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Icon(
                  AppIcons.userAdd,
                  size: AppIcons.lg,
                  color: colors.primary.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Đang trống',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colors.onSurfaceVariant.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Mời bạn bè',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.primary.withValues(alpha: 0.6),
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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final isFull = widget.lobby.currentPlayers >= widget.lobby.maxPlayers;
    if (!isFull) return const SizedBox.shrink();

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

    // Tính số người đã Ready.
    final readyCount =
        widget.lobby.players.where((p) => p.isReady).length;
    final totalMembers = widget.lobby.players.length;

    // Current user có phải member + ready chưa?
    // Lấy player trùng userId; nếu không tìm thấy (chưa load xong) coi như
    // chưa ready.
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
    final showReadySection = widget.lobby.status == LobbyStatus.full ||
        widget.lobby.status == LobbyStatus.inProgress;

    return Semantics(
      container: true,
      label: 'Phòng đã đầy. ${showReadySection ? "Sẵn sàng: $readyCount/$totalMembers" : "Đang chờ quán duyệt."}',
      child: Container(
        margin: const EdgeInsets.only(top: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.primaryContainer.withValues(alpha: 0.55),
              colors.tertiaryContainer.withValues(alpha: 0.35),
            ],
          ),
          borderRadius: AppRadius.radiusLgAll,
          border: Border.all(
            color: colors.primary.withValues(alpha: 0.25),
            width: 1,
          ),
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
                    color: colors.primary,
                    borderRadius: AppRadius.radiusSmAll,
                  ),
                  child: Icon(
                    AppIcons.users,
                    size: AppIcons.sm,
                    color: colors.onPrimary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Phòng đã đầy • ${widget.lobby.currentPlayers}/${widget.lobby.maxPlayers}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // ── Body copy theo trạng thái ───────────────────────────
            if (widget.lobby.status == LobbyStatus.inProgress)
              _bodyInProgress(theme, colors)
            else if (showReadySection)
              _bodyReadySection(
                theme: theme,
                colors: colors,
                readyCount: readyCount,
                totalMembers: totalMembers,
                isCurrentUserReady: isCurrentUserReady,
                isCurrentUserHost: isCurrentUserHost,
              )
            else
              _bodyFallback(theme, colors),

            // ── Action buttons ──────────────────────────────────────
            const SizedBox(height: AppSpacing.md),
            if (showReadySection && isCurrentUserMember) ...[
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _isToggling
                          ? null
                          : () => _handleToggleReady(isCurrentUserReady),
                      icon: _isToggling
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              isCurrentUserReady
                                  ? AppIcons.check
                                  : AppIcons.clock,
                              size: 16,
                            ),
                      label: Text(
                        isCurrentUserReady
                            ? 'Đã sẵn sàng ✓ (bấm để hủy)'
                            : 'Bấm Sẵn sàng',
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: isCurrentUserReady
                            ? colors.tertiary
                            : colors.primary,
                        foregroundColor: isCurrentUserReady
                            ? colors.onTertiary
                            : colors.onPrimary,
                      ),
                    ),
                  ),
                  if (widget.onSecondaryAction != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    OutlinedButton(
                      onPressed: widget.onSecondaryAction,
                      child: const Text('Chi tiết'),
                    ),
                  ],
                ],
              ),
            ] else if (widget.onSecondaryAction != null) ...[
              OutlinedButton.icon(
                onPressed: widget.onSecondaryAction,
                icon: const Icon(AppIcons.info, size: 16),
                label: const Text('Xem chi tiết'),
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
    required ThemeData theme,
    required ColorScheme colors,
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
            color: allReady
                ? colors.tertiaryContainer
                : colors.surfaceContainerHighest.withValues(alpha: 0.6),
            borderRadius: AppRadius.radiusSmAll,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                allReady ? AppIcons.check : AppIcons.clock,
                size: 14,
                color: allReady
                    ? colors.onTertiaryContainer
                    : colors.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.xxs),
              Text(
                'Sẵn sàng: $readyCount/$totalMembers',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: allReady
                      ? colors.onTertiaryContainer
                      : colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          nextStep,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _bodyInProgress(ThemeData theme, ColorScheme colors) {
    return Text(
      'Lobby đã chuyển sang "Đang chơi". Đến quán đúng giờ và bấm "Đã tới '
      'quán" để nhận mã QR check-in. Đừng quên đánh giá Karma sau khi chơi '
      'xong!',
      style: theme.textTheme.bodySmall?.copyWith(
        color: colors.onSurfaceVariant,
        height: 1.4,
      ),
    );
  }

  Widget _bodyFallback(ThemeData theme, ColorScheme colors) {
    return Text(
      'Phòng đã đầy. Theo dõi để cập nhật tiếp theo từ chủ phòng.',
      style: theme.textTheme.bodySmall?.copyWith(
        color: colors.onSurfaceVariant,
        height: 1.4,
      ),
    );
  }
}
