import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:boardverse/core/theme/app_colors.dart';
import 'package:boardverse/core/theme/app_spacing.dart';
import 'package:boardverse/core/theme/neo_brutalism_theme.dart';

/// Full-screen modal sheet to preview the current avatar.
///
/// Tap "Đổi ảnh" → calls [onChangeAvatar].
/// Tap outside / swipe down → dismisses without action.
class AvatarViewerSheet extends StatelessWidget {
  const AvatarViewerSheet({
    super.key,
    required this.avatarUrl,
    required this.username,
    required this.onChangeAvatar,
  });

  final String? avatarUrl;
  final String username;
  final VoidCallback onChangeAvatar;

  static Future<void> show(
    BuildContext context, {
    required String? avatarUrl,
    required String username,
    required VoidCallback onChangeAvatar,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AvatarViewerSheet(
        avatarUrl: avatarUrl,
        username: username,
        onChangeAvatar: onChangeAvatar,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasImage = avatarUrl != null && avatarUrl!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(top: 80),
      decoration: BoxDecoration(
        color: isDark ? NeoBrutalismTheme.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(28),
        ),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: NeoBrutalismTheme.borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.textSecondaryDark : AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Avatar preview
          _AvatarPreview(avatarUrl: avatarUrl, hasImage: hasImage),

          const SizedBox(height: AppSpacing.md),

          // Username label
          Text(
            '@$username',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Change button
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.lg + MediaQuery.of(context).padding.bottom,
            ),
            child: _ChangeAvatarButton(onPressed: onChangeAvatar),
          ),
        ],
      ),
    );
  }
}

class _AvatarPreview extends StatelessWidget {
  const _AvatarPreview({required this.avatarUrl, required this.hasImage});

  final String? avatarUrl;
  final bool hasImage;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: NeoBrutalismTheme.borderWidthBold,
        ),
        boxShadow: NeoBrutalismTheme.lightShadow(
          shadowColor: AppColors.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.white,
            width: 3,
          ),
        ),
        child: ClipOval(
          child: SizedBox(
            width: 200,
            height: 200,
            child: hasImage
                ? Image.network(
                    avatarUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _PlaceholderAvatar(),
                  )
                : _PlaceholderAvatar(),
          ),
        ),
      ),
    );
  }
}

class _PlaceholderAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.15),
      child: const Center(
        child: Icon(
          Icons.person_outline,
          size: 80,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _ChangeAvatarButton extends StatefulWidget {
  const _ChangeAvatarButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_ChangeAvatarButton> createState() => _ChangeAvatarButtonState();
}

class _ChangeAvatarButtonState extends State<_ChangeAvatarButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 80),
      vsync: this,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _ctrl.forward();
  void _onTapUp(TapUpDetails _) => _ctrl.reverse();
  void _onTapCancel() => _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onPressed();
      },
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) {
          return Transform.scale(
            scale: _scale.value,
            child: child,
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.border,
              width: NeoBrutalismTheme.borderWidth,
            ),
            boxShadow: NeoBrutalismTheme.lightShadow(
              shadowColor: AppColors.primary.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.camera_alt_outlined, color: AppColors.white),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'ĐỔI ẢNH AVATAR',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.white,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
