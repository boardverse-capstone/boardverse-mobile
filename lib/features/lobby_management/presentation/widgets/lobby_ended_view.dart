import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:boardverse/core/theme/app_colors.dart';
import 'package:boardverse/core/theme/app_icons.dart';
import 'package:boardverse/core/theme/app_spacing.dart';
import 'package:boardverse/features/lobby_management/domain/entities/lobby_entity.dart';

/// View hiển thị khi lobby đã kết thúc (status = closed / timeoutFailed /
/// hostCancelled / rejectedByCafe / expiredByCafe).
///
/// Phase D: xử lý 5 terminal states với unique UI:
/// - `closed`           → phòng đã đóng (phiên chơi hoàn tất, có thể rate)
/// - `timeoutFailed`    → không đủ người trong lead-time
/// - `hostCancelled`    → host chủ động huỷ
/// - `rejectedByCafe`   → cafe từ chối duyệt (BR-NEW-11)
/// - `expiredByCafe`    → cafe không duyệt trong 24h (BR-NEW-11)
class LobbyEndedView extends StatelessWidget {
  final LobbyEntity lobby;
  final String currentUserId;
  final VoidCallback onDissolve;
  final VoidCallback onRecreate;
  final VoidCallback onExtend;
  final VoidCallback onShowDetails;

  /// Callback mở Karma Rating (Phase E). Optional — chỉ hiển thị khi
  /// status là `closed` (rating cross được phép theo Task 5).
  final VoidCallback? onRate;

  const LobbyEndedView({
    super.key,
    required this.lobby,
    required this.currentUserId,
    required this.onDissolve,
    required this.onRecreate,
    required this.onExtend,
    required this.onShowDetails,
    this.onRate,
  });

  bool get _isHost => lobby.hostId == currentUserId;

  /// 5 terminal states — mỗi state có icon/title/subtitle/color riêng.
  /// Action buttons cũng được lọc theo state:
  /// - `closed`: rate + recreate (host) hoặc rate + create new (member)
  /// - `timeoutFailed` / `hostCancelled`: recreate + extend (host only)
  /// - `rejectedByCafe` / `expiredByCafe`: create new (member) hoặc recreate (host)
  ({
    String title,
    IconData icon,
    Color color,
    String subtitle,
    List<_EndedAction> hostActions,
    List<_EndedAction> memberActions,
  }) _stateInfo(ColorScheme colors) {
    final serverReason = lobby.closedReason?.trim();
    switch (lobby.status) {
      case LobbyStatus.closed:
        return (
          title: 'Phòng đã đóng',
          icon: Icons.lock_outline,
          color: colors.outline,
          subtitle: (serverReason != null && serverReason.isNotEmpty)
              ? serverReason
              : 'Phiên chơi đã hoàn tất. Cảm ơn bạn đã tham gia!',
          hostActions: [
            if (onRate != null)
              _EndedAction(
                key: _EndedActionKey.rate,
                icon: Icons.star_rate,
                iconColor: AppColors.warning,
                title: 'Đánh giá Karma',
                subtitle: 'Đánh giá trải nghiệm cho quán và thành viên.',
              ),
            _EndedAction(
              key: _EndedActionKey.dissolve,
              icon: AppIcons.delete,
              iconColor: colors.error,
              title: 'Giải tán phòng',
              subtitle: 'Xoá vĩnh viễn khỏi hệ thống.',
              enabled: lobby.status.canDissolve,
            ),
            _EndedAction(
              key: _EndedActionKey.recreate,
              icon: AppIcons.refresh,
              iconColor: colors.primary,
              title: 'Tạo lại phòng',
              subtitle: 'Tạo lobby mới với cùng game và quán.',
            ),
            _EndedAction(
              key: _EndedActionKey.extend,
              icon: Icons.update,
              iconColor: colors.secondary,
              title: 'Gia hạn phòng',
              subtitle: 'Tạo lobby mới với thời gian mới.',
            ),
          ],
          memberActions: [
            if (onRate != null)
              _EndedAction(
                key: _EndedActionKey.rate,
                icon: Icons.star_rate,
                iconColor: AppColors.warning,
                title: 'Đánh giá Karma',
                subtitle: 'Đánh giá trải nghiệm cho quán và thành viên.',
              ),
            _EndedAction(
              key: _EndedActionKey.recreate,
              icon: AppIcons.refresh,
              iconColor: colors.primary,
              title: 'Tạo phòng mới',
              subtitle: 'Tạo lobby mới của bạn với game yêu thích.',
            ),
          ],
        );

      case LobbyStatus.timeoutFailed:
        return (
          title: 'Phòng đã hết hạn',
          icon: Icons.timer_off_outlined,
          color: colors.error,
          subtitle: (serverReason != null && serverReason.isNotEmpty)
              ? serverReason
              : 'Không đủ người tham gia trong thời gian chờ. BVC sẽ được hoàn.',
          hostActions: [
            _EndedAction(
              key: _EndedActionKey.dissolve,
              icon: AppIcons.delete,
              iconColor: colors.error,
              title: 'Giải tán phòng',
              subtitle: 'Xoá vĩnh viễn khỏi hệ thống.',
              enabled: lobby.status.canDissolve,
            ),
            _EndedAction(
              key: _EndedActionKey.recreate,
              icon: AppIcons.refresh,
              iconColor: colors.primary,
              title: 'Tạo lại phòng',
              subtitle: 'Tạo lobby mới với cùng game và quán.',
            ),
            _EndedAction(
              key: _EndedActionKey.extend,
              icon: Icons.update,
              iconColor: colors.secondary,
              title: 'Gia hạn phòng',
              subtitle: 'Đẩy lùi giờ chơi để tuyển thêm người.',
            ),
          ],
          memberActions: [
            _EndedAction(
              key: _EndedActionKey.recreate,
              icon: AppIcons.refresh,
              iconColor: colors.primary,
              title: 'Tạo phòng mới',
              subtitle: 'Tạo lobby mới của bạn với game yêu thích.',
            ),
          ],
        );

      case LobbyStatus.hostCancelled:
        return (
          title: 'Phòng đã bị hủy',
          icon: Icons.cancel_outlined,
          color: colors.error,
          subtitle: (serverReason != null && serverReason.isNotEmpty)
              ? serverReason
              : 'Host đã huỷ phòng chờ này. BVC sẽ được hoàn 100% về ví.',
          hostActions: [
            _EndedAction(
              key: _EndedActionKey.dissolve,
              icon: AppIcons.delete,
              iconColor: colors.error,
              title: 'Giải tán phòng',
              subtitle: 'Xoá vĩnh viễn khỏi hệ thống.',
              enabled: lobby.status.canDissolve,
            ),
            _EndedAction(
              key: _EndedActionKey.recreate,
              icon: AppIcons.refresh,
              iconColor: colors.primary,
              title: 'Tạo lại phòng',
              subtitle: 'Tạo lobby mới với cùng game và quán.',
            ),
          ],
          memberActions: [
            _EndedAction(
              key: _EndedActionKey.recreate,
              icon: AppIcons.refresh,
              iconColor: colors.primary,
              title: 'Tạo phòng mới',
              subtitle: 'Tạo lobby mới của bạn với game yêu thích.',
            ),
          ],
        );

      case LobbyStatus.rejectedByCafe:
        return (
          title: 'Quán đã từ chối',
          icon: Icons.do_not_disturb_on_outlined,
          color: colors.error,
          subtitle: (serverReason != null && serverReason.isNotEmpty)
              ? serverReason
              : 'Quán từ chối duyệt phòng này. BVC đã được hoàn 100% về ví.',
          hostActions: [
            _EndedAction(
              key: _EndedActionKey.recreate,
              icon: AppIcons.refresh,
              iconColor: colors.primary,
              title: 'Chọn quán khác',
              subtitle: 'Tạo lobby mới ở quán khác.',
            ),
          ],
          memberActions: [
            _EndedAction(
              key: _EndedActionKey.recreate,
              icon: AppIcons.refresh,
              iconColor: colors.primary,
              title: 'Tạo phòng mới',
              subtitle: 'Tạo lobby mới của bạn với game yêu thích.',
            ),
          ],
        );

      case LobbyStatus.expiredByCafe:
        return (
          title: 'Hết hạn duyệt',
          icon: Icons.hourglass_disabled_outlined,
          color: AppColors.warning,
          subtitle: (serverReason != null && serverReason.isNotEmpty)
              ? serverReason
              : 'Quán không duyệt trong 24h. BVC đã được hoàn 100% về ví.',
          hostActions: [
            _EndedAction(
              key: _EndedActionKey.recreate,
              icon: AppIcons.refresh,
              iconColor: colors.primary,
              title: 'Chọn quán khác',
              subtitle: 'Tạo lobby mới ở quán khác.',
            ),
          ],
          memberActions: [
            _EndedAction(
              key: _EndedActionKey.recreate,
              icon: AppIcons.refresh,
              iconColor: colors.primary,
              title: 'Tạo phòng mới',
              subtitle: 'Tạo lobby mới của bạn với game yêu thích.',
            ),
          ],
        );

      default:
        return (
          title: 'Phòng đã kết thúc',
          icon: Icons.history,
          color: colors.outline,
          subtitle: (serverReason != null && serverReason.isNotEmpty)
              ? serverReason
              : 'Không còn nhận thành viên mới.',
          hostActions: [
            _EndedAction(
              key: _EndedActionKey.dissolve,
              icon: AppIcons.delete,
              iconColor: colors.error,
              title: 'Giải tán phòng',
              subtitle: 'Xoá vĩnh viễn khỏi hệ thống.',
              enabled: lobby.status.canDissolve,
            ),
            _EndedAction(
              key: _EndedActionKey.recreate,
              icon: AppIcons.refresh,
              iconColor: colors.primary,
              title: 'Tạo lại phòng',
              subtitle: 'Tạo lobby mới với cùng game và quán.',
            ),
          ],
          memberActions: [
            _EndedAction(
              key: _EndedActionKey.recreate,
              icon: AppIcons.refresh,
              iconColor: colors.primary,
              title: 'Tạo phòng mới',
              subtitle: 'Tạo lobby mới của bạn với game yêu thích.',
            ),
          ],
        );
    }
  }

  void _handleAction(BuildContext context, _EndedAction action) {
    switch (action.key) {
      case _EndedActionKey.rate:
        onRate?.call();
        break;
      case _EndedActionKey.dissolve:
        _confirmAndDissolve(context);
        break;
      case _EndedActionKey.recreate:
        onRecreate();
        break;
      case _EndedActionKey.extend:
        onExtend();
        break;
    }
  }

  Future<void> _confirmAndDissolve(BuildContext context) async {
    final confirmed = await _confirmDissolve(context);
    if (confirmed) onDissolve();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final info = _stateInfo(colors);
    final actions = _isHost ? info.hostActions : info.memberActions;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          lobby.gameName,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          if (_isHost && lobby.status.canDissolve)
            IconButton(
              tooltip: 'Giải tán phòng',
              icon: Icon(AppIcons.delete, color: colors.error),
              onPressed: () => _confirmAndDissolve(context),
            ),
          IconButton(
            tooltip: 'Chi tiết phòng',
            icon: const Icon(AppIcons.info),
            onPressed: onShowDetails,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // Status banner
          _StatusBanner(info: (
            title: info.title,
            icon: info.icon,
            color: info.color,
            subtitle: info.subtitle,
          )),
          const SizedBox(height: AppSpacing.lg),

          // Lobby info card
          EndedInfoCard(lobby: lobby),
          const SizedBox(height: AppSpacing.lg),

          // Refund banner — chỉ hiện cho rejectedByCafe / expiredByCafe /
          // hostCancelled (các trạng thái refund BVC).
          if (lobby.status == LobbyStatus.rejectedByCafe ||
              lobby.status == LobbyStatus.expiredByCafe ||
              lobby.status == LobbyStatus.hostCancelled ||
              lobby.status == LobbyStatus.timeoutFailed)
            _RefundBanner(lobby: lobby),

          const SizedBox(height: AppSpacing.md),

          // Action buttons (filtered theo role + state)
          ...actions.map(
            (a) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: ActionCard(
                icon: a.icon,
                title: a.title,
                subtitle: a.subtitle,
                iconColor: a.iconColor,
                isEnabled: a.enabled,
                onTap: a.enabled ? () => _handleAction(context, a) : () {},
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDissolve(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: EdgeInsets.zero,
        content: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.border,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.4),
                blurRadius: 0,
                offset: const Offset(6, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.border,
                    width: 3,
                  ),
                ),
                child: const Icon(
                  AppIcons.delete,
                  size: 36,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Giải tán phòng chờ?',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: AppColors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Phòng chờ sẽ bị xoá vĩnh viễn. Bạn không thể hoàn tác.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: _NeoOutlineButton(
                      label: 'Huỷ',
                      onPressed: () => Navigator.of(ctx).pop(false),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _NeoFilledButton(
                      label: 'Giải tán',
                      color: AppColors.error,
                      onPressed: () => Navigator.of(ctx).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return result ?? false;
  }
}

/// Status banner với gradient trong LobbyEndedView.
class _StatusBanner extends StatelessWidget {
  final ({String title, IconData icon, Color color, String subtitle}) info;

  const _StatusBanner({required this.info});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: info.color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.4),
            blurRadius: 0,
            offset: const Offset(5, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.25),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            child: Icon(info.icon, color: AppColors.white, size: 32),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info.title,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  info.subtitle,
                  style: TextStyle(
                    color: AppColors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Card hiển thị thông tin lobby trong ended view.
class EndedInfoCard extends StatelessWidget {
  final LobbyEntity lobby;

  const EndedInfoCard({super.key, required this.lobby});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeFmt = DateFormat('HH:mm • dd/MM/yyyy');

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: 2.5,
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
        children: [
          InfoRow(
            icon: AppIcons.boardGame,
            label: 'Trò chơi',
            value: lobby.gameName,
            isLast: false,
          ),
          InfoRow(
            icon: AppIcons.cafe,
            label: 'Quán',
            value: lobby.cafeName,
            isLast: false,
          ),
          InfoRow(
            icon: AppIcons.schedule,
            label: 'Giờ hẹn',
            value: timeFmt.format(lobby.scheduledTime.toLocal()),
            isLast: false,
          ),
          InfoRow(
            icon: AppIcons.users,
            label: 'Thành viên',
            value: '${lobby.currentPlayers}/${lobby.maxPlayers}',
            isLast: false,
          ),
          InfoRow(
            icon: AppIcons.user,
            label: 'Chủ phòng',
            value: lobby.hostName.isEmpty ? 'Chủ phòng' : lobby.hostName,
            isLast: false,
          ),
          if (lobby.closedAt != null)
            InfoRow(
              icon: Icons.event_busy,
              label: 'Đã đóng lúc',
              value: timeFmt.format(lobby.closedAt!.toLocal()),
              isLast: true,
            ),
        ],
      ),
    );
  }
}

/// Một dòng thông tin (icon + label + value).
class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  const InfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      decoration: isLast
          ? null
          : BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.border,
                  width: 1,
                ),
              ),
            ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.border,
                width: 1.5,
              ),
            ),
            child: Icon(icon, size: 14, color: AppColors.white),
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Card cho một action button trong ended view.
class ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final bool isEnabled;
  final VoidCallback onTap;

  const ActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    this.isEnabled = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? AppColors.surfaceDark : AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isEnabled
                  ? iconColor
                  : (isDark ? AppColors.borderDark : AppColors.border),
              width: 2.5,
            ),
            boxShadow: isEnabled
                ? [
                    BoxShadow(
                      color: AppColors.black.withValues(alpha: 0.4),
                      blurRadius: 0,
                      offset: const Offset(4, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: isEnabled ? iconColor : AppColors.textTertiary,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.border,
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  icon,
                  color: AppColors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: isEnabled
                            ? (isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimary)
                            : (isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isEnabled
                    ? (isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary)
                    : AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Internal — một action hiển thị trong LobbyEndedView.
class _EndedAction {
  final _EndedActionKey key;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool enabled;

  const _EndedAction({
    required this.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.enabled = true,
  });
}

enum _EndedActionKey { rate, dissolve, recreate, extend }

/// Banner "BVC sẽ được hoàn" — chỉ hiện cho 4 states refund BVC.
class _RefundBanner extends StatelessWidget {
  final LobbyEntity lobby;
  const _RefundBanner({required this.lobby});

  String _refundMessage() {
    switch (lobby.status) {
      case LobbyStatus.rejectedByCafe:
      case LobbyStatus.expiredByCafe:
      case LobbyStatus.hostCancelled:
        return 'BVC đã được hoàn 100% về ví của bạn.';
      case LobbyStatus.timeoutFailed:
        return 'BVC đã được hoàn về ví theo chính sách hoàn tiền (BR-08).';
      case LobbyStatus.dissolved:
        // Soft-delete theo BR §XXI-A.6 — refund thường là 100% (chưa check-in)
        // hoặc theo BR-08 nếu đã qua recruitmentDeadline.
        return 'Phòng đã được giải tán. BVC đã được hoàn về ví của bạn.';
      default:
        return 'BVC đã được hoàn.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.success,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.border,
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.4),
            blurRadius: 0,
            offset: const Offset(4, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              color: AppColors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Hoàn BVC',
                  style: TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  _refundMessage(),
                  style: TextStyle(
                    color: AppColors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Neo-brutalism outline button (used in dialogs).
class _NeoOutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const _NeoOutlineButton({required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.border,
              width: 2.5,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Neo-brutalism filled button (used in dialogs).
class _NeoFilledButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onPressed;

  const _NeoFilledButton({
    required this.label,
    required this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.border,
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
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
