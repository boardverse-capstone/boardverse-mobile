import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:boardverse/core/theme/theme.dart';
import 'package:boardverse/core/widgets/top_snack_bar.dart';
import '../../../lobby_management/domain/entities/lobby_invite_entity.dart';
import '../../lobby_routes.dart';

/// Section chia sẻ mã phòng + danh sách lời mời đã gửi.
///
/// Hiển thị dưới [PlayersSection] trong [LobbyPage]. Hỗ trợ host:
/// - Copy share code (clipboard) + share qua system share sheet
/// - Xem & cancel các lời mời Pending đã gửi
///
/// State là local — widget không tự fetch. Caller (LobbyPage) fetch qua
/// `LobbyRemoteDatasource.getShareInfo()` và
/// `LobbyRemoteDatasource.getAllInvites(status: pending)`, filter theo
/// `lobbyId == currentLobbyId`, rồi truyền xuống.
class LobbyShareSection extends StatefulWidget {
  final String lobbyId;
  final String currentUserId;
  final String? shareCode;
  final bool isPrivate;

  /// true khi người xem là host của lobby — bật nút "Tạo mã mới"
  /// (gọi `POST /share-code/regenerate`). Mặc định `false` cho member.
  final bool isHost;

  final List<LobbyInviteEntity> pendingInvites;

  /// Được gọi khi user bấm cancel 1 invite.
  final Future<bool> Function(String inviteId) onCancelInvite;

  /// Được gọi khi user pull-to-refresh.
  final Future<void> Function() onRefresh;

  /// Được gọi khi user bấm "Mời bạn bè" (mở sheet invite mới).
  final VoidCallback? onInviteFriends;

  /// Được gọi khi host bấm "Tạo mã mới" trong share code card. Chỉ hiển
  /// thị khi [isHost] = true. Trả về share code mới để caller update state
  /// (`LobbyPage._shareCode`) — UI sẽ tự re-render qua BlocListener.
  final Future<String?> Function() onRegenerateShareCode;

  const LobbyShareSection({
    super.key,
    required this.lobbyId,
    required this.currentUserId,
    required this.shareCode,
    required this.isPrivate,
    required this.pendingInvites,
    required this.onCancelInvite,
    required this.onRefresh,
    required this.onRegenerateShareCode,
    this.onInviteFriends,
    this.isHost = false,
  });

  @override
  State<LobbyShareSection> createState() => _LobbyShareSectionState();
}

class _LobbyShareSectionState extends State<LobbyShareSection> {
  bool _cancelling = false;

  /// Loading flag cho nút "Tạo mã mới" trong share code card — tránh
  /// user spam click trong khi request regenerate đang bay tới server.
  /// Type là `Future<String?>` (không phải bool) để khớp với callback
  /// `onRegenerateShareCode: Future<String?> Function()` — share code
  /// mới sẽ được return từ cubit để client copy vào clipboard.
  Future<String?> _regenerating = Future<String?>.value(null);

  /// Host bấm "Tạo mã mới" → confirm dialog → gọi callback.
  ///
  /// Flow:
  /// 1. Show dialog giải thích effect (mã cũ hết hiệu lực, mã mới được
  ///    copy tự động vào clipboard cho tiện share tiếp).
  /// 2. Disable nút trong khi gọi API (`_regenerating = Future(...)`).
  /// 3. Callback (`onRegenerateShareCode`) → LobbyPage gọi cubit →
  ///    cubit emit `LobbyShareCodeRegenerated(info)` → parent update
  ///    `_shareCode` qua BlocListener.
  /// 4. Show snackbar thành công/thất bại.
  Future<void> _handleRegenerateShareCode(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLgAll),
        title: const Text('Tạo lại mã phòng?'),
        content: const Text(
          'Mã chia sẻ hiện tại sẽ hết hiệu lực ngay lập tức. Người chưa vào '
          'phòng bằng mã cũ sẽ không thể dùng mã đó nữa. Bạn chắc chắn?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Tạo mã mới'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || !context.mounted) return;

    setState(() {
      _regenerating = widget.onRegenerateShareCode();
    });

    final newCode = await _regenerating;
    if (!mounted) return;

    // Reset future (luôn thành `null` để nút có thể bấm lại).
    setState(() {
      _regenerating = Future<String?>.value(null);
    });

    if (!context.mounted) return;
    if (newCode != null && newCode.isNotEmpty) {
      // Sau khi backend tạo mã mới, auto-copy vào clipboard cho host
      // tiện share ngay — tiết kiệm 1 thao tác copy thủ công.
      await Clipboard.setData(ClipboardData(text: newCode));
      if (!context.mounted) return;
      context.showTopSnackBar('Đã tạo mã mới và sao chép vào bộ nhớ tạm');
    } else {
      // null = cubit không emit LobbyShareCodeRegenerated (vd: 403/409).
      // LobbyPage đã show snackbar lỗi riêng qua BlocListener, nên ở
      // đây không cần làm gì thêm.
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // Filter: chỉ hiển thị các pending outgoing invites của lobby này
    // và do current user gửi (đã làm ở caller, nhưng double-check).
    final outgoingInvites = widget.pendingInvites
        .where((inv) =>
            inv.lobbyId == widget.lobbyId &&
            inv.status == LobbyInviteStatus.pending &&
            (widget.currentUserId.isEmpty ||
                inv.inviterId == widget.currentUserId))
        .toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xxs),
                decoration: BoxDecoration(
                  color: colors.tertiaryContainer,
                  borderRadius: AppRadius.radiusXxsAll,
                ),
                child: Icon(
                  Icons.share_rounded,
                  size: AppIcons.sm,
                  color: colors.onTertiaryContainer,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
Expanded(
            child: Text(
              'Mời & Chia sẻ',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (widget.onInviteFriends != null)
            TextButton.icon(
              onPressed: widget.onInviteFriends,
              icon: const Icon(AppIcons.userAdd, size: 16),
              label: const Text('Mời bạn bè'),
            ),
        ],
      ),
      const SizedBox(height: AppSpacing.md),

          // ── Share Code Card ────────────────────────────────────────────
          _ShareCodeCard(
            code: widget.shareCode,
            isPrivate: widget.isPrivate,
            isHost: widget.isHost,
            onRegenerate: widget.isHost
                ? () => _handleRegenerateShareCode(context)
                : null,
            regenerating: _regenerating,
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Pending Invites ────────────────────────────────────────────
          Row(
            children: [
              Text(
                'Lời mời đang chờ (${outgoingInvites.length})',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (outgoingInvites.isNotEmpty)
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushNamed(
                      LobbyRoutes.lobbyInvitesHistory,
                      arguments: LobbyInvitesHistoryPageArgs(
                        lobbyId: widget.lobbyId,
                      ),
                    );
                  },
                  icon: const Icon(AppIcons.bookingHistory, size: 16),
                  label: const Text('Xem tất cả'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...outgoingInvites.map((inv) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _PendingInviteRow(
                  invite: inv,
                  cancelling: _cancelling,
                  onCancel: () => _handleCancel(inv.inviteId),
                ),
              )),
        ],
      ),
    );
  }

  Future<void> _handleCancel(String inviteId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLgAll),
        title: const Text('Huỷ lời mời?'),
        content: const Text(
          'Người được mời sẽ không nhận được thông báo nữa và không thể tham gia phòng qua lời mời này.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Không'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Huỷ lời mời'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    setState(() => _cancelling = true);
    final ok = await widget.onCancelInvite(inviteId);
    if (!mounted) return;
    setState(() => _cancelling = false);

    if (!ok) {
      if (!context.mounted) return;
      context.showTopSnackBar(
        'Không huỷ được lời mời. Vui lòng thử lại.',
        isError: true,
      );
    } else {
      if (!context.mounted) return;
      context.showTopSnackBar('Đã huỷ lời mời');
    }
  }
}

class _ShareCodeCard extends StatelessWidget {
  final String? code;
  final bool isPrivate;

  /// true khi viewer là host — hiển thị nút "Tạo mã mới" (POST
  /// `/share-code/regenerate`). `null` callback = không hiển thị nút.
  final bool isHost;
  final VoidCallback? onRegenerate;

  /// `Future<String?>` từ parent để disable nút trong khi gọi API.
/// Mặc định `Future<String?>.value(null)` = sẵn sàng.
  final Future<String?>? regenerating;

  const _ShareCodeCard({
    required this.code,
    required this.isPrivate,
    this.isHost = false,
    this.onRegenerate,
    this.regenerating,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (code == null || code!.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: AppRadius.radiusMdAll,
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(Icons.lock_outline, color: colors.outline, size: 18),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Đang tải mã chia sẻ...',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primaryContainer,
            colors.primaryContainer.withValues(alpha: 0.6),
          ],
        ),
        borderRadius: AppRadius.radiusMdAll,
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.qr_code_2_rounded,
                  size: 18, color: colors.onPrimaryContainer),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Mã phòng',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colors.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (isPrivate)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.2),
                    borderRadius: AppRadius.radiusXxsAll,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.visibility_off_rounded,
                        size: 12,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Riêng tư',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: SelectableText(
                  code!,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4,
                    color: colors.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              FilledButton.tonalIcon(
                onPressed: () => _copy(context),
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text('Sao chép'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Chia sẻ mã này qua Zalo, Messenger, SMS để mời người chơi tham gia. '
            'Người được mời dùng nút "Nhập mã" ở màn hình Phòng chờ.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onPrimaryContainer.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: code!));
    if (!context.mounted) return;
    context.showTopSnackBar('Đã sao chép mã phòng');
  }
}

class _PendingInviteRow extends StatelessWidget {
  final LobbyInviteEntity invite;
  final bool cancelling;
  final VoidCallback onCancel;

  const _PendingInviteRow({
    required this.invite,
    required this.cancelling,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.radiusSmAll,
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: colors.primaryContainer,
            child: Text(
              (invite.inviterName.isNotEmpty
                      ? invite.inviterName[0]
                      : '?')
                  .toUpperCase(),
              style: TextStyle(
                color: colors.onPrimaryContainer,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Đã mời ${_shortId(invite.inviteeId)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Hết hạn sau ${_formatDuration(invite.remainingTime)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (cancelling)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            IconButton(
              tooltip: 'Huỷ lời mời',
              icon: Icon(Icons.close_rounded, color: AppColors.error),
              onPressed: onCancel,
            ),
        ],
      ),
    );
  }

  String _shortId(String id) {
    if (id.length <= 8) return id;
    return '${id.substring(0, 4)}…${id.substring(id.length - 4)}';
  }

  String _formatDuration(Duration d) {
    if (d.isNegative) return 'đã hết hạn';
    if (d.inHours > 0) return '${d.inHours} giờ';
    if (d.inMinutes > 0) return '${d.inMinutes} phút';
    return '${d.inSeconds} giây';
  }
}