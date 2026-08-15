import 'package:flutter/material.dart';
import 'package:boardverse/core/theme/theme.dart';
import 'package:boardverse/features/friend_management/domain/entities/friend_entity.dart';
import 'package:boardverse/features/lobby_management/presentation/cubit/lobby_state.dart';
import 'package:boardverse/features/lobby_management/presentation/widgets/lobby_friends_shimmer.dart';
import 'package:boardverse/features/lobby_management/presentation/widgets/online_friends_list.dart';

/// Bottom sheet mời bạn bè vào lobby.
class FriendsSheet extends StatelessWidget {
  final LobbyState state;
  final void Function(FriendEntity) onInvite;
  final void Function(FriendEntity) onAdd;
  final VoidCallback onClose;
  final bool showDevBadge;
  final BuildContext sheetContext;

  /// Set các friendId đã mời thành công trong session — tile tương ứng
  /// sẽ disable nút "Mời" (đổi thành "Đã mời" + icon check) để user
  /// biết đã invite rồi mà không phải đóng sheet ra reload.
  final Set<String> invitedFriendIds;

  const FriendsSheet({
    super.key,
    required this.state,
    required this.onInvite,
    required this.onAdd,
    required this.onClose,
    required this.showDevBadge,
    required this.sheetContext,
    this.invitedFriendIds = const <String>{},
  });

  List<FriendEntity> get _friends => state is LobbyFriendsLoaded
      ? (state as LobbyFriendsLoaded).friends
      : state is LobbySimulateFriendsLoaded
          ? (state as LobbySimulateFriendsLoaded).friends
          : const <FriendEntity>[];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.55,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.radiusXl),
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Row(
                children: [
                  if (showDevBadge) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: AppSpacing.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.12),
                        borderRadius: AppRadius.radiusXxsAll,
                      ),
                      child: Text(
                        'DEV',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.infoDark,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                  Expanded(
                    child: Text(
                      showDevBadge
                          ? 'Thêm bạn bè (Giả lập)'
                          : 'Mời bạn bè vào phòng',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Đóng',
                    icon: const Icon(AppIcons.close),
                    onPressed: onClose,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: OnlineFriendsList(
                friends: _friends,
                controller: controller,
                invitedFriendIds: invitedFriendIds,
                onInvite: onInvite,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Loading state cho sheet — Phase 3 2026-08-10: thay spinner bằng shimmer
/// skeleton list giống layout thật của OnlineFriendsList.
class SheetLoading extends StatelessWidget {
  final String label;

  const SheetLoading({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Giữ label để user biết đang load gì (khi label = "Đang tải...").
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          // Shimmer list thay cho spinner.
          const Flexible(child: LobbyFriendsShimmer(itemCount: 4)),
        ],
      ),
    );
  }
}
