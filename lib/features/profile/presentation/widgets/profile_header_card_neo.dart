import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:boardverse/core/theme/app_icons.dart';
import 'package:boardverse/core/theme/app_spacing.dart';
import 'package:boardverse/core/theme/app_colors.dart';
import 'package:boardverse/core/theme/neo_brutalism_theme.dart';
import 'package:boardverse/features/profile/domain/entities/profile_entity.dart';

/// Neo-brutalism Profile Header Card - VERTICAL LAYOUT
/// 
/// Features:
/// - Layout dọc: Avatar trên, info dưới
/// - Bio và description hiển thị đầy đủ, không cắt ngắn
/// - Card cao hơn để chứa nhiều info
/// - Phù hợp cho màn hình mobile
/// - Responsive cho màn hình nhỏ (360x740)
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 380;
    final topPadding = MediaQuery.of(context).padding.top + AppSpacing.sm;
    final hasBio = profile.bio != null && profile.bio!.isNotEmpty;

    // Responsive sizing
    final avatarSize = isSmallScreen ? 56.0 : 72.0;
    final horizontalPadding = isSmallScreen ? AppSpacing.md : AppSpacing.lg;
    final titleFontSize = isSmallScreen ? 14.0 : 16.0;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
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
              horizontalPadding,
              topPadding,
              horizontalPadding,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                _AvatarNeo(
                  avatarUrl: profile.avatarUrl,
                  initials: _initials,
                  onTap: onAvatarTap,
                  size: avatarSize,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Username
                      Text(
                        profile.username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: titleFontSize,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Handle + Tier
                      Wrap(
                        spacing: AppSpacing.xxs,
                        runSpacing: 2,
                        children: [
                          Text(
                            '@${profile.username}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                              fontSize: isSmallScreen ? 10 : 12,
                            ),
                          ),
                          if (hasTier)
                            _TierBadge(tier: profile.gamerTier!),
                        ],
                      ),
                      // Full name
                      if (profile.firstName != null ||
                          profile.lastName != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          profile.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w500,
                            fontSize: isSmallScreen ? 11 : 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                _EditButtonNeo(onPressed: onEditPressed, size: isSmallScreen ? 36 : 40),
              ],
            ),
          ),
          
          // ===== BOTTOM SECTION: Bio (Full display) =====
          if (hasBio) ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                0,
                horizontalPadding,
                horizontalPadding,
              ),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(isSmallScreen ? AppSpacing.sm : AppSpacing.md),
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
                  maxLines: isSmallScreen ? 2 : 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                    height: 1.4,
                    fontSize: isSmallScreen ? 11 : 13,
                  ),
                ),
              ),
            ),
          ] else
            const SizedBox(height: AppSpacing.sm),
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
    this.size = 72.0,
  });

  final String? avatarUrl;
  final String initials;
  final VoidCallback onTap;
  final double size;

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
            radius: (widget.size - 6) / 2,
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            backgroundImage: hasImage ? NetworkImage(widget.avatarUrl!) : null,
            child: hasImage
                ? null
                : Text(
                    widget.initials,
                    style: TextStyle(
                      fontSize: widget.size * 0.38,
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
  const _EditButtonNeo({required this.onPressed, this.size = 40});

  final VoidCallback onPressed;
  final double size;

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
          padding: EdgeInsets.all(widget.size * 0.2),
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
            size: widget.size * 0.5,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
