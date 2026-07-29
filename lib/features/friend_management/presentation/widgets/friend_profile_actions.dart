import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/entities.dart';
import '../cubit/friend_profile_cubit.dart';
import '../cubit/friend_profile_state.dart';

/// Action panel phía dưới FriendProfilePage — thay đổi theo
/// `friendshipStatus` và permission flags từ `FriendProfileEntity`.
///
/// Các action chính:
/// - `accepted`     → "Mời vào phòng" + overflow "Hủy kết bạn" + "Báo cáo"
/// - `none`         → "Kết bạn"
/// - `pendingSent`  → disabled "Đã gửi lời mời"
/// - `pendingReceived` → "Chấp nhận" + "Từ chối" (đã có flow riêng trong
///                      inbox; trên profile chỉ hiển thị read-only)
/// - `blocked`      → "Bỏ chặn"
/// - `blockedByOther` hoặc `self-blocked` → "Người dùng không khả dụng"
class FriendProfileActions extends StatelessWidget {
  const FriendProfileActions({
    super.key,
    required this.profile,
    required this.isMutating,
    required this.onSendRequest,
    required this.onUnfriend,
    required this.onInviteToLobby,
    required this.onBlock,
    required this.onUnblock,
    required this.onReport,
  });

  final FriendProfileEntity profile;
  final bool isMutating;

  final VoidCallback onSendRequest;
  final VoidCallback onUnfriend;
  final VoidCallback onInviteToLobby;
  final VoidCallback onBlock;
  final VoidCallback onUnblock;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Player chặn mình → chỉ hiện thông báo.
    if (profile.hasBlockedMe) {
      return _Notice(
        icon: Icons.lock_outline,
        color: theme.colorScheme.outline,
        text: 'Người chơi này hiện không nhận tương tác từ bạn.',
      );
    }

    // Mình đã chặn player → hiện nút bỏ chặn.
    if (profile.isBlockedByMe) {
      return Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: isMutating ? null : onUnblock,
              icon: const Icon(AppIcons.unlock),
              label: const Text('Bỏ chặn'),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.tertiary,
              ),
            ),
          ),
        ],
      );
    }

    switch (profile.friendshipStatus) {
      case FriendshipStatus.accepted:
        return Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: isMutating ? null : onInviteToLobby,
                icon: const Icon(AppIcons.add),
                label: const Text('Mời vào phòng'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _OverflowMenu(
              onUnfriend: onUnfriend,
              onReport: profile.canReport ? onReport : null,
            ),
          ],
        );
      case FriendshipStatus.pendingSent:
        return _Notice(
          icon: AppIcons.pending,
          color: theme.colorScheme.outline,
          text: 'Bạn đã gửi lời mời. Đang chờ phản hồi.',
        );
      case FriendshipStatus.pendingReceived:
        return _Notice(
          icon: AppIcons.inbox,
          color: theme.colorScheme.primary,
          text: 'Người chơi này đã gửi lời mời cho bạn. Mở tab "Lời mời" để phản hồi.',
        );
      case FriendshipStatus.blocked:
        return _Notice(
          icon: AppIcons.lock,
          color: theme.colorScheme.error,
          text: 'Bạn đã chặn người chơi này.',
        );
      case FriendshipStatus.none:
        if (!profile.canSendFriendRequest) {
          return _Notice(
            icon: Icons.do_not_disturb_on_outlined,
            color: theme.colorScheme.outline,
            text: 'Người chơi này hiện không nhận lời mời kết bạn.',
          );
        }
        return Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: isMutating ? null : onSendRequest,
                icon: const Icon(AppIcons.userAdd),
                label: const Text('Kết bạn'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _OverflowMenu(
              onBlock: onBlock,
            ),
          ],
        );
    }
  }
}

class _OverflowMenu extends StatelessWidget {
  const _OverflowMenu({
    this.onUnfriend,
    this.onReport,
    this.onBlock,
  });

  final VoidCallback? onUnfriend;
  final VoidCallback? onReport;
  final VoidCallback? onBlock;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = <PopupMenuEntry<String>>[];
    if (onUnfriend != null) {
      items.add(
        const PopupMenuItem<String>(
          value: 'unfriend',
          child: Row(
            children: [
              Icon(AppIcons.userRemove, size: AppIcons.sm, color: Colors.red),
              SizedBox(width: AppSpacing.sm),
              Text('Hủy kết bạn', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      );
    }
    if (onBlock != null) {
      items.add(
        const PopupMenuItem<String>(
          value: 'block',
          child: Row(
            children: [
              Icon(AppIcons.lock, size: AppIcons.sm, color: Colors.red),
              SizedBox(width: AppSpacing.sm),
              Text('Chặn người chơi', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      );
    }
    if (onReport != null) {
      items.add(
        const PopupMenuItem<String>(
          value: 'report',
          child: Row(
            children: [
              Icon(AppIcons.flag, size: AppIcons.sm, color: Colors.red),
              SizedBox(width: AppSpacing.sm),
              Text('Báo cáo vi phạm', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      );
    }
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: PopupMenuButton<String>(
        icon: Icon(
          Icons.more_vert,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        onSelected: (value) {
          switch (value) {
            case 'unfriend':
              onUnfriend?.call();
              break;
            case 'block':
              onBlock?.call();
              break;
            case 'report':
              onReport?.call();
              break;
          }
        },
        itemBuilder: (context) => items,
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: AppIcons.md),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialog báo cáo người chơi — chỉ category + reason.
/// Trả `null` nếu user cancel.
class ReportDialogResult {
  ReportDialogResult({required this.category, required this.reason});
  final String category;
  final String reason;
}

Future<ReportDialogResult?> showFriendReportDialog(BuildContext context) async {
  final theme = Theme.of(context);
  final categories = const ['Spam', 'Harassment', 'FakeAccount', 'InappropriateContent', 'Other'];
  var selectedCategory = categories.first;
  final reasonController = TextEditingController();

  return showDialog<ReportDialogResult>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Báo cáo người chơi'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Loại vi phạm',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: categories.map((cat) {
                      final isSelected = selectedCategory == cat;
                      return ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        onSelected: (value) {
                          if (value) setState(() => selectedCategory = cat);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: reasonController,
                    minLines: 3,
                    maxLines: 5,
                    maxLength: 1000,
                    decoration: const InputDecoration(
                      labelText: 'Lý do chi tiết (5–1000 ký tự)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Hủy'),
              ),
              FilledButton(
                onPressed: () {
                  final reason = reasonController.text.trim();
                  if (reason.length < 5) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                        content: Text('Lý do phải có ít nhất 5 ký tự.'),
                      ),
                    );
                    return;
                  }
                  Navigator.of(dialogContext).pop(
                    ReportDialogResult(
                      category: selectedCategory,
                      reason: reason,
                    ),
                  );
                },
                child: const Text('Gửi báo cáo'),
              ),
            ],
          );
        },
      );
    },
  );
}

/// Confirm dialog cho "Hủy kết bạn" / "Chặn người chơi".
Future<bool> showFriendConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = true,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: destructive
                ? Theme.of(dialogContext).colorScheme.error
                : null,
          ),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Helper dùng cho cả FriendProfilePage — lắng nghe transient action
/// message + error message trên cubit và hiển thị snackbar.
void listenProfileActionMessage(BuildContext context, FriendProfileState state) {
  if (state is FriendProfileLoaded && state.actionMessage != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(state.actionMessage!),
        duration: const Duration(seconds: 3),
      ),
    );
    context.read<FriendProfileCubit>().clearActionMessage();
  }
}
