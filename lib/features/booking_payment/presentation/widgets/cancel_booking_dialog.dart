import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';

/// Dialog 2 bước để Host huỷ đơn đặt chỗ.
///
/// Trả về `String?` — lý do user nhập nếu xác nhận, `null` nếu huỷ.
class CancelBookingDialog extends StatefulWidget {
  final String bookingId;

  const CancelBookingDialog({super.key, required this.bookingId});

  static Future<String?> show(BuildContext context,
      {required String bookingId}) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CancelBookingDialog(bookingId: bookingId),
    );
  }

  @override
  State<CancelBookingDialog> createState() => _CancelBookingDialogState();
}

class _CancelBookingDialogState extends State<CancelBookingDialog> {
  int _step = 0;
  final _reasonController = TextEditingController();
  bool _canConfirm = false;

  static const _maxLength = 200;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _onReasonChanged(String v) {
    final trimmed = v.trim();
    setState(() => _canConfirm = trimmed.isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    return _step == 0 ? _buildWarning() : _buildReasonForm();
  }

  Widget _buildWarning() {
    final theme = Theme.of(context);
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.dialogRadius),
      icon: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.warning_amber_rounded,
          color: AppColors.warning,
          size: AppIcons.xl,
        ),
      ),
      title: const Text('Xác nhận huỷ đơn'),
      content: Text(
        'Bạn có chắc muốn huỷ đơn đặt chỗ ${widget.bookingId} không?\n'
        'Vui lòng cho quán biết lý do để họ hỗ trợ bạn tốt hơn.',
        style: theme.textTheme.bodyMedium,
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Không, giữ lại'),
        ),
        FilledButton.icon(
          onPressed: () => setState(() => _step = 1),
          icon: const Icon(Icons.cancel_outlined),
          label: const Text('Huỷ đơn'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.error,
          ),
        ),
      ],
    );
  }

  Widget _buildReasonForm() {
    final theme = Theme.of(context);
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.dialogRadius),
      title: Row(
        children: [
          Icon(Icons.edit_note_rounded,
              size: AppIcons.lg, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.xs),
          const Text('Lý do huỷ'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _reasonController,
            autofocus: true,
            maxLines: 3,
            maxLength: _maxLength,
            decoration: InputDecoration(
              hintText: 'Ví dụ: Bận đột xuất, không thể đến...',
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.4),
              border: OutlineInputBorder(
                borderRadius: AppRadius.radiusMdAll,
                borderSide: BorderSide(
                  color: theme.colorScheme.outlineVariant,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.radiusMdAll,
                borderSide: BorderSide(
                  color: theme.colorScheme.outlineVariant,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadius.radiusMdAll,
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 2,
                ),
              ),
            ),
            onChanged: _onReasonChanged,
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Quay lại'),
        ),
        FilledButton.icon(
          onPressed: _canConfirm
              ? () =>
                  Navigator.pop(context, _reasonController.text.trim())
              : null,
          icon: const Icon(Icons.check_rounded),
          label: const Text('Xác nhận huỷ'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.error,
            disabledBackgroundColor: AppColors.error.withValues(alpha: 0.3),
          ),
        ),
      ],
    );
  }
}
