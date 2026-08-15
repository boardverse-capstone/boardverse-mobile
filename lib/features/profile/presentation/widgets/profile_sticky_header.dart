import 'package:flutter/material.dart';

import 'package:boardverse/core/theme/app_colors.dart';
import 'package:boardverse/core/theme/app_radius.dart';
import 'package:boardverse/core/theme/app_spacing.dart';
import 'package:boardverse/core/theme/neo_brutalism_theme.dart';
import 'package:boardverse/features/profile/domain/entities/profile_entity.dart';

/// Neo-brutalism Compact sticky header cho trang Profile.
class ProfileStickyHeader extends StatelessWidget {
  const ProfileStickyHeader({
    required this.profile,
    required this.onAvatarTap,
    required this.maxExtent,
    super.key,
  });

  final ProfileEntity profile;
  final VoidCallback onAvatarTap;
  final double maxExtent;

  String get _initials {
    if (profile.username.isEmpty) return '?';
    return profile.username.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasTier =
        profile.gamerTier != null && profile.gamerTier!.isNotEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        final t = ((constraints.maxHeight - kToolbarHeight) /
                (maxExtent - kToolbarHeight))
            .clamp(0.0, 1.0);

        final avatarSize = 36 + (36 * t);
        final topPadding = MediaQuery.of(context).padding.top + AppSpacing.sm;

        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surface,
            border: Border(
              bottom: BorderSide(
                color: (isDark ? AppColors.borderDark : AppColors.border)
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
                        fontWeight: FontWeight.w900,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
              color: isDark ? AppColors.borderDark : AppColors.border,
              width: NeoBrutalismTheme.borderWidth,
            ),
          ),
          child: CircleAvatar(
            radius: (size - 6) / 2,
            backgroundColor: AppColors.surfaceVariant,
            backgroundImage:
                hasImage ? NetworkImage(avatarUrl!) : null,
            child: hasImage
                ? null
                : Text(
                    initials,
                    style: TextStyle(
                      fontSize: size * 0.4,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
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
              fontWeight: FontWeight.w600,
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
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: AppColors.black,
                width: 1.5,
              ),
            ),
            child: Text(
              tier!,
              style: const TextStyle(
                color: AppColors.black,
                fontWeight: FontWeight.w900,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
