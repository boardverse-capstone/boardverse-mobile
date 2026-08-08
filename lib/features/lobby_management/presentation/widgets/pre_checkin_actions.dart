import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:boardverse_mobile/core/theme/app_colors.dart';
import 'package:boardverse_mobile/core/theme/app_spacing.dart';

/// Quick action row cho giai đoạn "Sau lobby FULL → trước khi đến quán".
/// Hiển thị các nút người chơi cần — neo-brutalism style với bold border + hard shadow.
class PreCheckinActions extends StatelessWidget {
  /// Callback khi member nhấn "Tôi đang trên đường". Host sẽ thấy badge
  /// trong lobby_members_checklist. Optional — nếu null, button ẩn.
  final VoidCallback? onEnRoute;

  /// Callback khi member nhấn "Tôi đã đến". Optional.
  final VoidCallback? onArrived;

  /// Callback khi nhấn "Chỉ đường". Optional — nếu null, sử dụng default.
  final VoidCallback? onDirections;

  /// Callback khi nhấn "Gọi quán". Optional.
  final VoidCallback? onCallCafe;

  /// Callback khi nhấn "Sao chép mã". Optional.
  final ValueChanged<String>? onCopyCode;

  /// Mã booking/reservation sẽ copy khi nhấn "Sao chép mã".
  final String? shareCode;

  /// Số điện thoại cafe — `tel:` URI khi nhấn "Gọi quán".
  final String? cafePhone;

  /// Lat/Lng cafe — dùng cho Google Maps URI khi nhấn "Chỉ đường".
  final double? cafeLatitude;
  final double? cafeLongitude;

  /// Ẩn một số nút nhất định theo context (vd: host có thể không cần
  /// "Tôi đang trên đường").
  final bool showEnRoute;
  final bool showArrived;
  final bool showDirections;
  final bool showCallCafe;
  final bool showCopyCode;
  final bool showAlarm;

  const PreCheckinActions({
    super.key,
    this.onEnRoute,
    this.onArrived,
    this.onDirections,
    this.onCallCafe,
    this.onCopyCode,
    this.shareCode,
    this.cafePhone,
    this.cafeLatitude,
    this.cafeLongitude,
    this.showEnRoute = true,
    this.showArrived = true,
    this.showDirections = true,
    this.showCallCafe = true,
    this.showCopyCode = true,
    this.showAlarm = true,
  });

  Future<void> _openDirections(BuildContext context) async {
    if (onDirections != null) {
      onDirections!();
      return;
    }
    if (cafeLatitude == null || cafeLongitude == null) return;
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$cafeLatitude,$cafeLongitude&travelmode=driving',
    );
    try {
      await _launchUri(context, uri);
    } on Object catch (e) {
      if (context.mounted) _showError(context, 'Không mở được Maps: $e');
    }
  }

  Future<void> _callCafe(BuildContext context) async {
    if (onCallCafe != null) {
      onCallCafe!();
      return;
    }
    if (cafePhone == null || cafePhone!.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: cafePhone);
    try {
      await _launchUri(context, uri);
    } on Object catch (e) {
      if (context.mounted) _showError(context, 'Không gọi được: $e');
    }
  }

  Future<void> _copyCode(BuildContext context) async {
    final code = shareCode;
    if (code == null || code.isEmpty) return;
    if (onCopyCode != null) {
      onCopyCode!(code);
      return;
    }
    await Clipboard.setData(ClipboardData(text: code));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã sao chép mã: $code'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _setAlarm(BuildContext context) async {
    try {
      await _launchUri(
        context,
        Uri.parse('https://www.google.com/search?q=set+alarm'),
      );
    } on Object catch (_) {/* silent */}
  }

  Future<void> _launchUri(BuildContext context, Uri uri) async {
    await Clipboard.setData(ClipboardData(text: uri.toString()));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã sao chép link: ${uri.toString()}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final buttons = <_ActionButtonData>[];

    if (showDirections) {
      buttons.add(_ActionButtonData(
        icon: Icons.directions_rounded,
        label: 'Chỉ đường',
        color: AppColors.primary,
        onPressed: () => _openDirections(context),
      ));
    }
    if (showCallCafe) {
      buttons.add(_ActionButtonData(
        icon: Icons.phone_rounded,
        label: 'Gọi quán',
        color: AppColors.secondary,
        onPressed: () => _callCafe(context),
      ));
    }
    if (showCopyCode && shareCode != null && shareCode!.isNotEmpty) {
      buttons.add(_ActionButtonData(
        icon: Icons.content_copy_rounded,
        label: 'Sao chép mã',
        color: AppColors.info,
        onPressed: () => _copyCode(context),
      ));
    }
    if (showEnRoute) {
      buttons.add(_ActionButtonData(
        icon: Icons.directions_car_rounded,
        label: 'Đang trên đường',
        color: AppColors.success,
        onPressed: onEnRoute,
        filled: true,
      ));
    }
    if (showArrived) {
      buttons.add(_ActionButtonData(
        icon: Icons.location_on_rounded,
        label: 'Tôi đã đến',
        color: AppColors.accent,
        onPressed: onArrived,
        filled: true,
      ));
    }
    if (showAlarm) {
      buttons.add(_ActionButtonData(
        icon: Icons.alarm_rounded,
        label: 'Đặt báo thức',
        color: AppColors.warning,
        onPressed: () => _setAlarm(context),
      ));
    }

    if (buttons.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: buttons
          .map(
            (b) => SizedBox(
              width: 160,
              child: _ActionButton(data: b),
            ),
          )
          .toList(),
    );
  }
}

class _ActionButtonData {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onPressed;
  final bool filled;
  const _ActionButtonData({
    required this.icon,
    required this.label,
    required this.color,
    this.onPressed,
    this.filled = false,
  });
}

class _ActionButton extends StatelessWidget {
  final _ActionButtonData data;
  const _ActionButton({required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final enabled = data.onPressed != null;
    final fg = data.filled ? AppColors.white : data.color;
    final bg = data.filled
        ? data.color
        : (isDark ? AppColors.surfaceDark : AppColors.surface);

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: data.onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: enabled
                  ? data.color
                  : (isDark ? AppColors.borderDark : AppColors.border),
              width: 2.5,
            ),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: AppColors.black.withValues(alpha: 0.4),
                      blurRadius: 0,
                      offset: const Offset(2, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                data.icon,
                color: enabled
                    ? fg
                    : (isDark
                        ? AppColors.textTertiary
                        : AppColors.textTertiary),
                size: 18,
              ),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  data.label,
                  style: TextStyle(
                    color: enabled
                        ? fg
                        : (isDark
                            ? AppColors.textTertiary
                            : AppColors.textTertiary),
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}