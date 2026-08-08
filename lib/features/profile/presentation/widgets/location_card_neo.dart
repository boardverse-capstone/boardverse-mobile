import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:boardverse_mobile/core/theme/app_icons.dart';
import 'package:boardverse_mobile/core/theme/app_spacing.dart';
import 'package:boardverse_mobile/core/theme/app_colors.dart';
import 'package:boardverse_mobile/core/theme/neo_brutalism_theme.dart';
import 'package:boardverse_mobile/features/profile/domain/entities/player_location_entity.dart';

/// Neo-brutalism Location Card - COMPACT
class LocationCardNeo extends StatelessWidget {
  const LocationCardNeo({
    super.key,
    required this.location,
    required this.onUpdateGpsPressed,
    required this.onDeletePressed,
  });

  final PlayerLocationEntity? location;
  final VoidCallback onUpdateGpsPressed;
  final VoidCallback onDeletePressed;

  bool get _hasLocation =>
      location != null &&
      location!.hasLocation &&
      location!.latitude != null;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: NeoBrutalismTheme.autoBox(
        context,
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        shadowColor: AppColors.secondary.withValues(alpha: 0.15),
        borderRadius: 16,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  AppIcons.location,
                  color: AppColors.secondary,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Vị trí của bạn',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          
          // Content
          if (_hasLocation)
            _LoadedLocationNeo(
              location: location!,
              onDeletePressed: onDeletePressed,
            )
          else
            _EmptyLocationNeo(onUpdatePressed: onUpdateGpsPressed),
        ],
      ),
    );
  }
}

class _LoadedLocationNeo extends StatelessWidget {
  const _LoadedLocationNeo({
    required this.location,
    required this.onDeletePressed,
  });

  final PlayerLocationEntity location;
  final VoidCallback onDeletePressed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${location.latitude!.toStringAsFixed(4)}, ${location.longitude!.toStringAsFixed(4)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                location.source == LocationSource.gps
                    ? '📍 GPS thiết bị'
                    : '🗺️ Chọn trên bản đồ',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        _CompactIconButton(
          icon: AppIcons.delete,
          color: AppColors.error,
          onPressed: onDeletePressed,
        ),
      ],
    );
  }
}

class _EmptyLocationNeo extends StatelessWidget {
  const _EmptyLocationNeo({required this.onUpdatePressed});

  final VoidCallback onUpdatePressed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Icon(
          Icons.location_off_outlined,
          size: 20,
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            'Chưa cập nhật vị trí',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
            ),
          ),
        ),
        _CompactIconButton(
          icon: AppIcons.directions,
          color: AppColors.secondary,
          onPressed: onUpdatePressed,
        ),
      ],
    );
  }
}

class _CompactIconButton extends StatefulWidget {
  const _CompactIconButton({
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  State<_CompactIconButton> createState() => _CompactIconButtonState();
}

class _CompactIconButtonState extends State<_CompactIconButton>
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

  void _onTapDown(TapDownDetails details) {
    _pressCtrl.forward();
    HapticFeedback.lightImpact();
  }

  void _onTapUp(TapUpDetails details) => _pressCtrl.reverse();
  void _onTapCancel() => _pressCtrl.reverse();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onPressed,
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
            color: widget.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.border,
              width: NeoBrutalismTheme.borderWidth,
            ),
          ),
          child: Icon(
            widget.icon,
            color: widget.color,
            size: 20,
          ),
        ),
      ),
    );
  }
}
