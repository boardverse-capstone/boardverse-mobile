import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';

/// Bottom FilledButton nằm dưới các tab của LobbyConfigPage.
///
/// Có debounce 500ms để chống double-tap — đảm bảo idempotency key
/// mới được tạo cho mỗi lần bấm thực sự (tránh trùng key khi user bấm
/// 2 lần nhanh trước khi state loading được set).
class LobbyConfigBottomButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const LobbyConfigBottomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  State<LobbyConfigBottomButton> createState() =>
      _LobbyConfigBottomButtonState();
}

class _LobbyConfigBottomButtonState extends State<LobbyConfigBottomButton> {
  bool _isDebouncing = false;

  void _handlePress() {
    if (widget.onPressed == null || widget.isLoading || _isDebouncing) return;

    _isDebouncing = true;
    widget.onPressed?.call();

    // Reset debounce sau 500ms
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _isDebouncing = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: widget.isLoading || _isDebouncing ? null : _handlePress,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              disabledBackgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
            child: widget.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(widget.label),
          ),
        ),
      ),
    );
  }
}