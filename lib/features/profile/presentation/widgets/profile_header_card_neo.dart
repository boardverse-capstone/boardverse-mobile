import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:boardverse_mobile/core/theme/app_icons.dart';
import 'package:boardverse_mobile/core/theme/app_spacing.dart';
import 'package:boardverse_mobile/core/theme/app_colors.dart';
import 'package:boardverse_mobile/core/theme/neo_brutalism_theme.dart';
import 'package:boardverse_mobile/features/profile/domain/entities/profile_entity.dart';

/// Neo-brutalism Profile Header Card - VERTICAL LAYOUT
/// 
/// Features:
/// - Layout dọc: Avatar trên, info dưới
/// - Bio và description hiển thị đầy đủ, không cắt ngắn
/// - Card cao hơn để chứa nhiều info
/// - Phù hợp cho màn hình mobile
class ProfileHeaderCardNeo extends StatelessWidget {
  const ProfileHeaderCardNeo({
    super.key,
    required this.profile,
    required this.onAvatarTap,
    required this.onEditPressed,
  });

  final ProfileEntity profile;
  final VoidCallback onAvatarTap;
  final VoidCallback onEditPressed;

  String get _initials {
    final name = profile.displayName;
    if (name.isEmpty) return '?';
    return name.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasTier = profile.gamerTier != null && profile.gamerTier!.isNotEmpty;
    final topPadding = MediaQuery.of(context).padding.top + AppSpacing.sm;
    final hasBio = profile.bio != null && profile.bio!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: NeoBrutalismTheme.autoBox(
        context,
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        shadowColor: AppColors.primary.withValues(alpha: 0.2),
        bold: true,
        borderRadius: 20,
      ),
      child: Column(
        children: [
          // ===== TOP SECTION: Avatar + Edit Button =====
          Container(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              topPadding,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Row(
              children: [
                _AvatarNeo(
                  avatarUrl: profile.avatarUrl,
                  initials: _initials,
                  onTap: onAvatarTap,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Username
                      Text(
                        profile.username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Handle + Tier
                      Row(
                        children: [
                          Text(
                            '@${profile.username}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (hasTier) ...[
                            const SizedBox(width: AppSpacing.xs),
                            _TierBadge(tier: profile.gamerTier!),
                          ],
                        ],
                      ),
                      // Full name
                      if (profile.firstName != null ||
                          profile.lastName != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          profile.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _EditButtonNeo(onPressed: onEditPressed),
              ],
            ),
          ),
          
          // ===== BOTTOM SECTION: Bio (Full display) =====
          if (hasBio) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  profile.bio!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ] else
            const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

class _AvatarNeo extends StatefulWidget {
  const _AvatarNeo({
    required this.avatarUrl,
    required this.initials,
    required this.onTap,
  });

  final String? avatarUrl;
  final String initials;
  final VoidCallback onTap;

  @override
  State<_AvatarNeo> createState() => _AvatarNeoState();
}

class _AvatarNeoState extends State<_AvatarNeo>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasImage = widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty;
    const size = 72.0;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.border,
              width: NeoBrutalismTheme.borderWidth,
            ),
            boxShadow: NeoBrutalismTheme.lightShadow(
              shadowColor: AppColors.primary.withValues(alpha: 0.3),
            ),
          ),
          child: CircleAvatar(
            radius: (size - 6) / 2,
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            backgroundImage: hasImage ? NetworkImage(widget.avatarUrl!) : null,
            child: hasImage
                ? null
                : Text(
                    widget.initials,
                    style: TextStyle(
                      fontSize: size * 0.38,
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

class _TierBadge extends StatelessWidget {
  const _TierBadge({required this.tier});

  final String tier;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppColors.accentDark,
          width: 1.5,
        ),
        boxShadow: NeoBrutalismTheme.lightShadow(
          shadowColor: AppColors.accent.withValues(alpha: 0.4),
        ),
      ),
      child: Text(
        tier.toUpperCase(),
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: Colors.black87,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _EditButtonNeo extends StatefulWidget {
  const _EditButtonNeo({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_EditButtonNeo> createState() => _EditButtonNeoState();
}

class _EditButtonNeoState extends State<_EditButtonNeo>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      duration: const Duration(milliseconds: 80),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onPressed();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.border,
              width: NeoBrutalismTheme.borderWidth,
            ),
            boxShadow: NeoBrutalismTheme.lightShadow(
              shadowColor: AppColors.primary.withValues(alpha: 0.4),
            ),
          ),
          child: Icon(
            AppIcons.edit,
            size: AppIcons.md,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
