import 'package:flutter/material.dart';

/// Thay thế cho `ToastCard` của package `delightful_toast` — đã có bug
/// assertion trong Flutter Material 3 vì `Container` (với color +
/// `BorderRadius.circular(15)` + boxShadow) wrap `ListTile` mà không có
/// `Material` ancestor riêng cho ListTile. Stack trace:
///
///   ListTile background color or ink splashes may be invisible.
///   The ListTile is wrapped in a DecoratedBox that has a background color.
///
/// Cấu trúc của widget này:
///
/// ```
/// Container (chỉ giữ margin + boxShadow, không có color)
///   └── Material (color + borderRadius)
///         └── ListTile
/// ```
///
/// `Material` được đặt ngay trước `ListTile` để `ListTile` có Material
/// ancestor phù hợp cho ink splash + tileColor; `Container` ngoài cùng
/// chỉ giữ shadow để giữ nguyên visual của `ToastCard` gốc.
class AppToastCard extends StatelessWidget {
  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final Color? color;
  final Color? shadowColor;
  final VoidCallback? onTap;

  const AppToastCard({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.color,
    this.shadowColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        color ?? Theme.of(context).dialogTheme.backgroundColor ?? Colors.white;
    final effectiveShadowColor =
        shadowColor ?? Colors.black.withValues(alpha: 0.05);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            spreadRadius: 3,
            offset: Offset.zero,
            color: effectiveShadowColor,
          ),
        ],
      ),
      child: Material(
        color: effectiveColor,
        borderRadius: BorderRadius.circular(15),
        child: ListTile(
          contentPadding: const EdgeInsets.all(7),
          leading: Padding(
            padding: const EdgeInsets.all(10.0),
            child: leading,
          ),
          trailing: trailing,
          subtitle: subtitle,
          title: title,
          onTap: onTap,
        ),
      ),
    );
  }
}