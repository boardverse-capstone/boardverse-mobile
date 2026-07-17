import 'package:flutter/material.dart';

import 'package:boardverse_mobile/core/theme/app_colors.dart';
import 'package:boardverse_mobile/core/theme/app_colors_dark.dart';
import 'package:boardverse_mobile/core/theme/app_radius.dart';
import 'package:boardverse_mobile/core/theme/app_spacing.dart';
import 'package:boardverse_mobile/features/profile/domain/entities/profile_entity.dart';

/// Header gradient hiển thị avatar, tên người dùng, hạng tier và bio.
///
/// Sử dụng gradient [AppColors.cardGradientOrange] → [AppColors.cardGradientTeal]
/// theo design system (tạo cảm giác năng động + ấm cúng).
class AvatarHeader extends StatelessWidget {
  const AvatarHeader({
    super.key,
    required this.profile,
    required this.onAvatarTap,
  });

  final ProfileEntity profile;

  /// Callback khi người dùng tap vào avatar (đổi ảnh đại diện).
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
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 16,
            offset: Offset(0, 6),
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
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),

          // Handle
          Text(
            '@${profile.username}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.white.withValues(alpha: 0.85),
            ),
          ),

          // Tier badge (chỉ hiện khi đã có hạng)
          if (profile.gamerTier != null && profile.gamerTier!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _TierBadge(label: 'Hạng: ${profile.gamerTier}'),
          ],

          // Bio
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
            Container(
              padding: const EdgeInsets.all(AppSpacing.xxs),
              decoration: const BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
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
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
              ),
            ),
            // Edit indicator
            Container(
              padding: const EdgeInsets.all(AppSpacing.xxs),
              decoration: const BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
              ),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.xxs),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt_outlined,
                  size: 14,
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
        color: AppColors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(AppRadius.radiusFull),
        border: Border.all(
          color: AppColors.white.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.white,
          letterSpacing: 0.4,
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
          color: AppColors.white.withValues(alpha: hasBio ? 0.95 : 0.7),
        ),
      ),
    );
  }
}
