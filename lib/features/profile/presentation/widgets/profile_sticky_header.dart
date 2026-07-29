import 'package:flutter/material.dart';

import 'package:boardverse_mobile/core/theme/app_radius.dart';
import 'package:boardverse_mobile/core/theme/app_spacing.dart';
import 'package:boardverse_mobile/features/profile/domain/entities/profile_entity.dart';

/// Compact sticky header cho trang Profile.
///
/// Designed để dùng làm `flexibleSpace` của [SliverAppBar]:
/// - Khi expanded: hiện avatar + username + handle + tier badge.
/// - Khi collapsed: chỉ còn avatar nhỏ + username (SliverAppBar tự xử lý).
///
/// Không dùng gradient rực rỡ — chỉ solid `surface` theo theme + subtle elevation
/// để giữ phong cách minimal mobile.
class ProfileStickyHeader extends StatelessWidget {
  const ProfileStickyHeader({
    required this.profile,
    required this.onAvatarTap,
    required this.maxExtent,
    super.key,
  });

  final ProfileEntity profile;
  final VoidCallback onAvatarTap;

  /// Chiều cao tối đa khi expanded (típ: ~ 220 cho mobile).
  final double maxExtent;

  String get _initials {
    if (profile.username.isEmpty) return '?';
    return profile.username.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasTier =
        profile.gamerTier != null && profile.gamerTier!.isNotEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        // 0..1 tỉ lệ collapse (1 = expanded, 0 = collapsed).
        final t = ((constraints.maxHeight - kToolbarHeight) /
                (maxExtent - kToolbarHeight))
            .clamp(0.0, 1.0);

        // Avatar size: 72 (expanded) → 36 (collapsed).
        // Giảm delta để tránh overflow khi collapsed gần hết.
        final avatarSize = 36 + (36 * t);
        // Padding top tính đến status bar.
        final topPadding = MediaQuery.of(context).padding.top + AppSpacing.sm;

        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.outlineVariant
                    .withValues(alpha: 0.5 * t),
              ),
            ),
          ),
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            topPadding,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _Avatar(
                avatarUrl: profile.avatarUrl,
                initials: _initials,
                size: avatarSize,
                onTap: onAvatarTap,
              ),
              SizedBox(width: AppSpacing.md + (AppSpacing.xs * t)),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.username,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    if (t > 0.4) ...[
                      SizedBox(height: AppSpacing.xxs * t),
                      _HeaderMeta(
                        handle: profile.username,
                        tier: hasTier ? profile.gamerTier : null,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.avatarUrl,
    required this.initials,
    required this.size,
    required this.onTap,
  });

  final String? avatarUrl;
  final String initials;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = avatarUrl != null && avatarUrl!.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.radiusFullAll,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: theme.colorScheme.outlineVariant,
              width: 1.5,
            ),
          ),
          child: CircleAvatar(
            radius: (size - 6) / 2,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            backgroundImage:
                hasImage ? NetworkImage(avatarUrl!) : null,
            child: hasImage
                ? null
                : Text(
                    initials,
                    style: TextStyle(
                      fontSize: size * 0.4,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _HeaderMeta extends StatelessWidget {
  const _HeaderMeta({required this.handle, this.tier});

  final String handle;
  final String? tier;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Flexible(
          child: Text(
            '@$handle',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        if (tier != null) ...[
          const SizedBox(width: AppSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: AppRadius.radiusSmAll,
            ),
            child: Text(
              tier!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
