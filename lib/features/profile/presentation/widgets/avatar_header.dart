import 'package:flutter/material.dart';

import 'package:boardverse/core/theme/app_colors.dart';
import 'package:boardverse/core/theme/app_colors_dark.dart';
import 'package:boardverse/core/theme/app_radius.dart';
import 'package:boardverse/core/theme/app_spacing.dart';
import 'package:boardverse/core/theme/neo_brutalism_theme.dart';
import 'package:boardverse/features/profile/domain/entities/profile_entity.dart';

/// Neo-brutalism Header gradient hiển thị avatar, tên người dùng, hạng tier và bio.
class AvatarHeader extends StatelessWidget {
  const AvatarHeader({
    super.key,
    required this.profile,
    required this.onAvatarTap,
  });

  final ProfileEntity profile;
  final VoidCallback onAvatarTap;

  String get _initials {
    if (profile.username.isEmpty) return '?';
    return profile.username.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final gradientColors = isDark
        ? AppColorsDark.cardGradientOrange + AppColorsDark.cardGradientTeal
        : [
            AppColors.cardGradientOrange.first,
            AppColors.cardGradientOrange.last,
            AppColors.cardGradientTeal.first,
          ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors.take(3).toList(),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.radiusHuge),
        ),
        // Neo-brutalism: hard shadow offset below the gradient
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.3),
            blurRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      child: Column(
        children: [
          _Avatar(
            avatarUrl: profile.avatarUrl,
            initials: _initials,
            onTap: onAvatarTap,
          ),
          const SizedBox(height: AppSpacing.md),

          // Tên hiển thị
          Text(
            profile.username,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w900,
              shadows: const [
                Shadow(
                  color: AppColors.black,
                  offset: Offset(0, 2),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),

          // Handle
          Text(
            '@${profile.username}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
            ),
          ),

          // Tier badge
          if (profile.gamerTier != null && profile.gamerTier!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _TierBadge(label: 'HẠNG: ${profile.gamerTier!.toUpperCase()}'),
          ],

          const SizedBox(height: AppSpacing.sm),
          _BioText(bio: profile.bio),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.avatarUrl,
    required this.initials,
    required this.onTap,
  });

  final String? avatarUrl;
  final String initials;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasImage = avatarUrl != null && avatarUrl!.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.radiusFullAll,
        onTap: onTap,
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            // Outer ring với neo-brutalism border
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.black,
                  width: NeoBrutalismTheme.borderWidthBold,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.black,
                    blurRadius: 0,
                    offset: Offset(4, 4),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 48,
                backgroundColor: AppColors.surface,
                backgroundImage:
                    hasImage ? NetworkImage(avatarUrl!) : null,
                onBackgroundImageError: hasImage
                    ? (exception, stackTrace) {}
                    : null,
                child: hasImage
                    ? null
                    : Text(
                        initials,
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
              ),
            ),
            // Edit indicator - neo-brutalism style
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.black,
                  width: 2,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.black,
                    blurRadius: 0,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt_outlined,
                  size: 12,
                  color: AppColors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TierBadge extends StatelessWidget {
  const _TierBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xxs + 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(AppRadius.radiusFull),
        border: Border.all(
          color: AppColors.black,
          width: NeoBrutalismTheme.borderWidth,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.black,
            blurRadius: 0,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: AppColors.black,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _BioText extends StatelessWidget {
  const _BioText({this.bio});
  final String? bio;

  @override
  Widget build(BuildContext context) {
    final hasBio = bio != null && bio!.isNotEmpty;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 280),
      child: Text(
        hasBio ? bio! : 'Chưa có mô tả cá nhân',
        textAlign: TextAlign.center,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 13,
          height: 1.4,
          fontStyle: hasBio ? FontStyle.normal : FontStyle.italic,
          color: AppColors.white.withValues(alpha: hasBio ? 0.95 : 0.75),
          fontWeight: hasBio ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }
}
