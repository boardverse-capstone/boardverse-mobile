import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:boardverse/core/theme/app_icons.dart';
import 'package:boardverse/core/theme/app_spacing.dart';
import 'package:boardverse/core/theme/app_colors.dart';
import 'package:boardverse/core/theme/neo_brutalism_theme.dart';
import 'package:boardverse/features/profile/domain/entities/player_location_entity.dart';

/// Neo-brutalism Location Card - COMPACT
///
/// Trạng thái:
/// - Chưa có vị trí: text "Chưa cập nhật vị trí" + button "Cập nhật vị trí hiện tại"
/// - Đã có vị trí: hiển thị tên khu vực + nút refresh (icon)
///
/// `isUpdating` disable nút cập nhật trong khi PUT location đang bay,
/// tránh player spam tap vì tưởng app bị lag.
///
/// Callback thuần UI — side-effect xử lý ở parent (HomePage gọi
/// `ProfileCubit.updateLocation(...)`).
class LocationCardNeo extends StatelessWidget {
  const LocationCardNeo({
    super.key,
    required this.location,
    required this.isUpdating,
    required this.onUpdateGpsPressed,
  });

  final PlayerLocationEntity? location;
  final bool isUpdating;
  final VoidCallback onUpdateGpsPressed;

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
              isUpdating: isUpdating,
              onUpdatePressed: onUpdateGpsPressed,
            )
          else
            _EmptyLocationNeo(
              onUpdatePressed: onUpdateGpsPressed,
              isUpdating: isUpdating,
            ),
        ],
      ),
    );
  }
}

class _LoadedLocationNeo extends StatelessWidget {
  const _LoadedLocationNeo({
    required this.location,
    required this.isUpdating,
    required this.onUpdatePressed,
  });

  final PlayerLocationEntity location;
  final bool isUpdating;
  final VoidCallback onUpdatePressed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    final hasCoords =
        location.latitude != null && location.longitude != null;
    final hasResolved = location.hasResolvedName &&
        (location.displayName?.trim().isNotEmpty ?? false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Top row: tên hiển thị + actions ─────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasResolved)
                    Text(
                      location.displayName!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style:
                          Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                                height: 1.3,
                              ),
                    ),
                  if (hasResolved) const SizedBox(height: 4),
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
            const SizedBox(width: AppSpacing.xs),
            _CompactIconButton(
              icon: isUpdating ? Icons.hourglass_top : Icons.refresh,
              color: AppColors.secondary,
              tooltip: isUpdating
                  ? 'Đang cập nhật...'
                  : 'Cập nhật vị trí hiện tại',
              onPressed: isUpdating ? null : onUpdatePressed,
            ),
          ],
        ),

        // ── Block chi tiết địa chỉ (chỉ khi reverse-geocode xong) ──
        if (hasResolved) ...[
          const SizedBox(height: AppSpacing.sm),
          _AddressBlockNeo(location: location, textSecondary: textSecondary),
        ],

        // ── Toạ độ + cập nhật lúc ──────────────────────────────────
        if (hasCoords) ...[
          const SizedBox(height: AppSpacing.sm),
          _CoordinatesRowNeo(
            latitude: location.latitude!,
            longitude: location.longitude!,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
        ],
      ],
    );
  }
}

/// Block nhỏ hiển thị district / city / country khi backend đã trả về.
class _AddressBlockNeo extends StatelessWidget {
  const _AddressBlockNeo({
    required this.location,
    required this.textSecondary,
  });

  final PlayerLocationEntity location;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (location.district != null && location.district!.trim().isNotEmpty)
            _AddressLineNeo(
              icon: Icons.location_city,
              label: 'Quận/Huyện',
              value: location.district!,
              textColor: textSecondary,
              theme: theme,
            ),
          if (location.city != null && location.city!.trim().isNotEmpty)
            _AddressLineNeo(
              icon: Icons.apartment,
              label: 'Thành phố',
              value: location.city!,
              textColor: textSecondary,
              theme: theme,
            ),
          if (location.country != null && location.country!.trim().isNotEmpty)
            _AddressLineNeo(
              icon: Icons.public,
              label: 'Quốc gia',
              value: location.country!,
              textColor: textSecondary,
              theme: theme,
            ),
        ],
      ),
    );
  }
}

class _AddressLineNeo extends StatelessWidget {
  const _AddressLineNeo({
    required this.icon,
    required this.label,
    required this.value,
    required this.textColor,
    required this.theme,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color textColor;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: RichText(
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: theme.textTheme.bodySmall?.copyWith(color: textColor),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dòng toạ độ dạng nh� ở cuối card.
class _CoordinatesRowNeo extends StatelessWidget {
  const _CoordinatesRowNeo({
    required this.latitude,
    required this.longitude,
    required this.textPrimary,
    required this.textSecondary,
  });

  final double latitude;
  final double longitude;
  final Color textPrimary;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.place_outlined, size: 14, color: textSecondary),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            'Toạ độ: ${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
          ),
        ),
      ],
    );
  }
}

class _EmptyLocationNeo extends StatelessWidget {
  const _EmptyLocationNeo({
    required this.onUpdatePressed,
    required this.isUpdating,
  });

  final VoidCallback onUpdatePressed;
  final bool isUpdating;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: _UpdateLocationButton(
            onPressed: onUpdatePressed,
            isUpdating: isUpdating,
            label: 'Cập nhật vị trí hiện tại',
          ),
        ),
      ],
    );
  }
}

class _UpdateLocationButton extends StatefulWidget {
  const _UpdateLocationButton({
    required this.onPressed,
    required this.label,
    required this.isUpdating,
  });

  final VoidCallback onPressed;
  final String label;
  final bool isUpdating;

  @override
  State<_UpdateLocationButton> createState() => _UpdateLocationButtonState();
}

class _UpdateLocationButtonState extends State<_UpdateLocationButton>
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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.isUpdating) return;
    _pressCtrl.forward();
    HapticFeedback.lightImpact();
  }

  void _onTapUp(TapUpDetails details) => _pressCtrl.reverse();
  void _onTapCancel() => _pressCtrl.reverse();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final disabled = widget.isUpdating;
    // Làm mờ cả nền + chữ + icon khi đang gọi API để player không tap.
    final bgColor =
        disabled ? AppColors.secondary.withValues(alpha: 0.5) : AppColors.secondary;
    final fgColor = isDark ? AppColors.textPrimaryDark : Colors.white;
    final label = disabled ? 'Đang cập nhật...' : widget.label;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: disabled ? null : widget.onPressed,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: NeoBrutalismTheme.autoBox(
            context,
            backgroundColor: bgColor,
            borderRadius: 12,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                disabled ? Icons.hourglass_top : Icons.my_location,
                color: fgColor,
                size: 18,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: fgColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactIconButton extends StatefulWidget {
  const _CompactIconButton({
    required this.icon,
    required this.color,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final Color color;

  /// `null` = disabled (button sẽ grey-out và không phản hồi tap).
  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  State<_CompactIconButton> createState() => _CompactIconButtonState();
}

class _CompactIconButtonState extends State<_CompactIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _scaleAnimation;

  bool get _isEnabled => widget.onPressed != null;

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
    if (!_isEnabled) return;
    _pressCtrl.forward();
    HapticFeedback.lightImpact();
  }

  void _onTapUp(TapUpDetails details) => _pressCtrl.reverse();
  void _onTapCancel() => _pressCtrl.reverse();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveColor =
        _isEnabled ? widget.color : widget.color.withValues(alpha: 0.35);

    final button = GestureDetector(
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
            color: effectiveColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.border,
              width: NeoBrutalismTheme.borderWidth,
            ),
          ),
          child: Icon(
            widget.icon,
            color: effectiveColor,
            size: 20,
          ),
        ),
      ),
    );

    if (widget.tooltip == null) return button;
    return Tooltip(
      message: widget.tooltip!,
      child: button,
    );
  }
}