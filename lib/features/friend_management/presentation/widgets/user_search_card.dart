import 'package:flutter/material.dart';

import 'package:boardverse/core/theme/app_colors.dart';
import 'package:boardverse/core/theme/app_spacing.dart';
import '../../domain/entities/entities.dart';
import 'common/common.dart';
import 'shared/meta_row.dart';
import 'shared/status_chip.dart';

/// Neo-brutalism Card displaying user search results.
class UserSearchCard extends StatelessWidget {
  const UserSearchCard({
    super.key,
    required this.user,
    this.onSendRequest,
    this.onTap,
  });

  final UserSearchEntity user;
  final VoidCallback? onSendRequest;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedCard(
      onTap: onTap,
      radius: 12,
      shadowColor: AppColors.black.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            UserAvatar(
              username: user.username,
              avatarUrl: user.avatarUrl,
              radius: 22,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    user.username,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  MetaRow(
                    karmaPoints: user.karmaPoints,
                    mutualFriendsCount: user.mutualFriendsCount,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _buildAction(),
          ],
        ),
      ),
    );
  }

  Widget _buildAction() {
    switch (user.friendshipStatus) {
      case FriendshipStatus.none:
      case null:
        return SizedBox(
          height: 36,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.black, width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.black,
                  blurRadius: 0,
                  offset: Offset(2, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: onSendRequest,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.person_add_alt_1_outlined,
                        size: 14,
                        color: AppColors.white,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'KẾT BẠN',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      case FriendshipStatus.pendingSent:
        return const StatusChip(
          icon: Icons.schedule,
          label: 'ĐÃ GỬI',
          color: AppColors.textSecondary,
        );
      case FriendshipStatus.pendingReceived:
        return const StatusChip(
          icon: Icons.inbox_outlined,
          label: 'CHỜ PHẢN HỒI',
          color: AppColors.primary,
        );
      case FriendshipStatus.accepted:
        return const StatusChip(
          icon: Icons.check_circle_outline,
          label: 'BẠN BÈ',
          color: AppColors.success,
        );
      case FriendshipStatus.blocked:
        return const StatusChip(
          icon: Icons.block,
          label: 'ĐÃ CHẶN',
          color: AppColors.error,
        );
    }
  }
}