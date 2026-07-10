import 'package:flutter/material.dart';

/// Dialog 2 bước để Host huỷ đơn đặt chỗ.
///
/// Trả về `String?` — lý do user nhập nếu xác nhận, `null` nếu huỷ.
class CancelBookingDialog extends StatefulWidget {
  final String bookingId;

  const CancelBookingDialog({super.key, required this.bookingId});

  static Future<String?> show(BuildContext context, {required String bookingId}) {
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
      icon: Icon(
        Icons.warning_amber_rounded,
        color: Colors.orange.shade700,
        size: 48,
      ),
      title: const Text('Xác nhận huỷ đơn'),
      content: Text(
        'Bạn có chắc muốn huỷ đơn đặt chỗ ${widget.bookingId} không?\n'
        'Vui lòng cho quán biết lý do để họ hỗ trợ bạn tốt hơn.',
        style: theme.textTheme.bodyMedium,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Không, giữ lại'),
        ),
        FilledButton.tonal(
          onPressed: () => setState(() => _step = 1),
          child: const Text('Huỷ đơn'),
        ),
      ],
    );
  }

  Widget _buildReasonForm() {
    return AlertDialog(
      title: const Text('Lý do huỷ'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _reasonController,
            autofocus: true,
            maxLines: 3,
            maxLength: _maxLength,
            decoration: const InputDecoration(
              hintText: 'Ví dụ: Bận đột xuất, không thể đến...',
              border: OutlineInputBorder(),
            ),
            onChanged: _onReasonChanged,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Quay lại'),
        ),
        FilledButton(
          onPressed: _canConfirm
              ? () => Navigator.pop(context, _reasonController.text.trim())
              : null,
          child: const Text('Xác nhận huỷ'),
        ),
      ],
    );
  }
}