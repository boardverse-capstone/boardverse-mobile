import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Snackbar hiển thị ở **đầu màn hình** (top) thay vì bottom mặc định.
///
/// Lý do tồn tại: trong các sheet / page có nội dung cuộn từ dưới lên
/// (vd: sheet danh sách bạn bè, sheet filter), snackbar mặc định của
/// Flutter hiển thị ở bottom → che mất phần tiêu đề và nội dung quan
/// trọng. Hiển thị top giúp thông báo không giao với nội dung UI.
///
/// API mô phỏng `ScaffoldMessenger.showSnackBar`:
///   context.showTopSnackBar('Đã gửi lời mời đến A');
///   context.showTopSnackBar('Có lỗi xảy ra', isError: true);
class TopSnackBar {
  TopSnackBar._();

  /// Entry hiện đang hiển thị (chỉ giữ 1 entry tại 1 thời điểm để
  /// tránh chồng chập khi user bấm liên tục).
  static OverlayEntry? _currentEntry;

  /// Timer để tự đóng entry hiện tại.
  static Timer? _dismissTimer;

  /// Hiển thị snackbar ở top.
  ///
  /// [isError] đổi sang tone đỏ (error container).
  /// [duration] mặc định 2s (ngắn hơn SnackBar mặc định 4s vì snackbar
  /// ở top thường dùng cho action confirm đơn giản).
  static void show(
    BuildContext context, {
    required String message,
    bool isError = false,
    Duration duration = const Duration(seconds: 2),
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    // Đóng entry hiện tại (nếu có) trước khi show entry mới.
    _dismissTimer?.cancel();
    _currentEntry?.remove();
    _currentEntry = null;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (entryCtx) => _TopSnackBarWidget(
        message: message,
        isError: isError,
        onDismiss: () => _dismiss(entry),
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);

    _dismissTimer = Timer(duration, () => _dismiss(entry));
  }

  static void _dismiss(OverlayEntry entry) {
    if (_currentEntry != entry) return;
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _currentEntry = null;
    entry.remove();
  }
}

extension TopSnackBarContext on BuildContext {
  /// Tiện ích gọi nhanh: `context.showTopSnackBar('Xong!')`.
  void showTopSnackBar(
    String message, {
    bool isError = false,
    Duration duration = const Duration(seconds: 2),
  }) {
    TopSnackBar.show(
      this,
      message: message,
      isError: isError,
      duration: duration,
    );
  }
}

/// Widget top snackbar — slide in từ trên + fade.
class _TopSnackBarWidget extends StatefulWidget {
  final String message;
  final bool isError;
  final VoidCallback onDismiss;

  const _TopSnackBarWidget({
    required this.message,
    required this.isError,
    required this.onDismiss,
  });

  @override
  State<_TopSnackBarWidget> createState() => _TopSnackBarWidgetState();
}

class _TopSnackBarWidgetState extends State<_TopSnackBarWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final bg = widget.isError ? colors.errorContainer : colors.surface;
    final fg = widget.isError ? colors.onErrorContainer : colors.onSurface;
    final borderColor = widget.isError
        ? colors.error
        : colors.outlineVariant.withValues(alpha: 0.6);

    final mediaQuery = MediaQuery.of(context);
    // Đặt snackbar ngay dưới status bar + một khoảng đệm nhỏ.
    final topOffset = mediaQuery.padding.top + AppSpacing.sm;

    return Positioned(
      top: topOffset,
      left: AppSpacing.md,
      right: AppSpacing.md,
      child: IgnorePointer(
        ignoring: false,
        child: SlideTransition(
          position: _slide,
          child: FadeTransition(
            opacity: _fade,
            child: Material(
              color: Colors.transparent,
              child: GestureDetector(
                onTap: widget.onDismiss,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: AppRadius.radiusMdAll,
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        widget.isError ? AppIcons.close : AppIcons.check,
                        size: AppIcons.sm,
                        color: fg,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          widget.message,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: fg,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}