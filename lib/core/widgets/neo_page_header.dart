import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Page header theo Neo-Brutalism style — dùng thay cho `AppBar` mặc định.
///
/// **Tại sao không dùng `AppBar` mặc định:**
/// `AppBar` Material mặc định chỉ là nền phẳng đơn sắc, không thể hiện
/// được DNA Neo-Brutalism (border đậm, hard offset shadow, vibrant).
/// Header custom này có:
/// - Background gradient cam rực (primary → primaryDark)
/// - Border đen 3px (3 cạnh dưới/trái/phải)
/// - Hard offset shadow 4px xuống (no blur) — neo-brutalism signature
/// - Title `FontWeight.w900` + shadow chữ nhẹ tăng độ tương phản
/// - Subtitle nhỏ phía dưới (optional) giải thích ngữ cảnh
/// - Icon trang trí ở góc phải tạo personality (bị clip, không ảnh hưởng layout)
///
/// **Layout (kích thước cố định, dùng trong `PreferredSize`):**
/// ```
/// ┌─────────────────────────────────────────┐
/// │  ◀  KẾT QUẢ GỢI Ý              🔄     │  ← content (≈56px)
/// │      Tìm board game phù hợp            │
/// └─────────────────────────────────────────┘
///   ▓▓▓▓▓▓▓▓ hard offset shadow ▓▓▓▓▓▓▓▓
/// ```
///
/// **Cách dùng với Scaffold:**
/// ```dart
/// Scaffold(
///   appBar: PreferredSize(
///     preferredSize: const Size.fromHeight(88), // content 56 + safearea ~32
///     child: NeoPageHeader(title: 'KẾT QUẢ', subtitle: 'Tìm game phù hợp'),
///   ),
///   body: ...,
/// )
/// ```
class NeoPageHeader extends StatelessWidget {
  /// Tiêu đề chính (FontWeight.w900).
  final String title;

  /// Mô tả phụ hiển thị dưới title (optional).
  final String? subtitle;

  /// Widget leading (thường là back button).
  final Widget? leading;

  /// Actions hiển thị bên phải (IconButton...).
  final List<Widget> actions;

  /// Icon trang trí ở góc phải (background mờ, nằm sau content).
  /// Bị clip bởi ClipRect nên không ảnh hưởng layout của header.
  final IconData? decorationIcon;

  /// Gradient background. Mặc định primary → primaryDark.
  final List<Color>? gradientColors;

  /// Màu border.
  final Color? borderColor;

  /// Kích thước title (mặc định 20 — đã giảm từ 22 để vừa với height 88).
  final double titleFontSize;

  /// Padding ngang của nội dung.
  final double horizontalPadding;

  const NeoPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions = const [],
    this.decorationIcon,
    this.gradientColors,
    this.borderColor,
    this.titleFontSize = 20,
    this.horizontalPadding = AppSpacing.md,
  });

  @override
  Widget build(BuildContext context) {
    final colors = gradientColors ??
        const [AppColors.primary, AppColors.primaryDark];
    final borderClr = borderColor ?? AppColors.border;

    return Material(
      // Material để InkWell bên trong action buttons render đúng ripple.
      type: MaterialType.transparency,
      child: Container(
        // Hard offset shadow + border + gradient — tất cả trong 1 BoxDecoration.
        // boxShadow được clip bởi borderRadius nên không bị tràn.
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          border: Border(
            bottom: BorderSide(color: borderClr, width: 3),
            left: BorderSide(color: borderClr, width: 3),
            right: BorderSide(color: borderClr, width: 3),
            top: BorderSide.none,
          ),
          boxShadow: [
            // Hard offset shadow — neo-brutalism signature (no blur).
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.85),
              offset: const Offset(0, 4),
              blurRadius: 0,
              spreadRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          // ClipRRect để:
          // 1) Decoration icon không tràn ra ngoài border radius
          // 2) Shadow hiển thị đúng ở cạnh dưới (không bị border-radius cắt mất)
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          child: Stack(
            // Stack dùng fit: StackFit.loose để chiều cao Stack = chiều cao
            // content (không bị kéo giãn bởi icon lớn). Icon lớn sẽ bị clip
            // thay vì đẩy content xuống → không gây overflow.
            fit: StackFit.loose,
            children: [
              // Decoration icon — nằm dưới content, IgnorePointer để không
              // cản tap. Position với right/top âm để "tràn" ra ngoài.
              if (decorationIcon != null)
                Positioned(
                  right: -16,
                  top: -8,
                  child: IgnorePointer(
                    child: Icon(
                      decorationIcon,
                      size: 96,
                      color: Colors.white.withValues(alpha: 0.10),
                    ),
                  ),
                ),

              // Content chính — fit StackFit.loose sẽ tự co lại theo content.
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Leading (back button).
                      if (leading != null) ...[
                        leading!,
                        const SizedBox(width: AppSpacing.sm),
                      ],

                      // Title + subtitle column.
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: titleFontSize,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.3,
                                height: 1.05,
                                shadows: const [
                                  Shadow(
                                    color: Color(0x40000000),
                                    offset: Offset(0, 2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (subtitle != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                subtitle!,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white.withValues(alpha: 0.92),
                                  letterSpacing: 0.1,
                                  height: 1.1,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Actions.
                      if (actions.isNotEmpty) ...[
                        const SizedBox(width: AppSpacing.xs),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: actions,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Convenience: tạo back button với style đồng bộ với header.
  static Widget backButton(BuildContext context, {VoidCallback? onPressed}) {
    return _HeaderIconButton(
      icon: Icons.arrow_back_rounded,
      onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
      semanticLabel: 'Quay lại',
    );
  }
}

/// IconButton tròn neo-brutalist — dùng trong header actions.
class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String semanticLabel;

  const _HeaderIconButton({
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Material(
        color: Colors.white.withValues(alpha: 0.18),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Tooltip(
            message: semanticLabel,
            child: Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: 20,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Public wrapper để dùng cho actions trong header.
class NeoHeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;

  const NeoHeaderIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return _HeaderIconButton(
      icon: icon,
      onPressed: onPressed,
      semanticLabel: tooltip,
    );
  }
}
