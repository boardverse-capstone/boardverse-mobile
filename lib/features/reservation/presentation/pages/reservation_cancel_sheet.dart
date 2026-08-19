import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/theme.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/reservation_repository.dart';

/// Bottom sheet cho phép user nhập lý do hủy + xem preview refund/forfeit
/// theo policy backend.
class ReservationCancelSheet extends StatefulWidget {
  final String reservationId;
  final VoidCallback? onCancelled;

  const ReservationCancelSheet({
    super.key,
    required this.reservationId,
    this.onCancelled,
  });

  static Future<void> show(
    BuildContext context,
    String reservationId, {
    VoidCallback? onCancelled,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ReservationCancelSheet(
        reservationId: reservationId,
        onCancelled: onCancelled,
      ),
    );
  }

  @override
  State<ReservationCancelSheet> createState() => _CancelSheetState();
}

class _CancelSheetState extends State<ReservationCancelSheet> {
  final _repository = sl<ReservationRepository>();
  
  CancelState _state = CancelState.idle;
  String? _errorMessage;
  ReservationCancelResult? _cancelResult;

  Future<void> _submit(String? reason) async {
    setState(() => _state = CancelState.cancelling);

    final idempotencyKey = DateTime.now().millisecondsSinceEpoch.toString();
    final result = await _repository.cancelReservation(
      reservationId: widget.reservationId,
      reason: reason,
      idempotencyKey: idempotencyKey,
    );

    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() {
          _state = CancelState.error;
          _errorMessage = failure.message;
        });
      },
      (cancelResult) {
        setState(() {
          _state = CancelState.success;
          _cancelResult = cancelResult;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
          top: AppSpacing.md,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
        ),
        child: switch (_state) {
          CancelState.idle => _ReasonForm(
              reservationId: widget.reservationId,
              onSubmit: _submit,
            ),
          CancelState.cancelling => const _CenteredLoading(),
          CancelState.success => _CancelledView(
              result: _cancelResult!,
              onDismiss: () {
                widget.onCancelled?.call();
                Navigator.of(context).pop();
              },
            ),
          CancelState.error => _CancelErrorView(
              message: _errorMessage ?? 'Đã xảy ra lỗi',
              onRetry: () => setState(() => _state = CancelState.idle),
            ),
        },
      ),
    );
  }
}

enum CancelState { idle, cancelling, success, error }

class _ReasonForm extends StatefulWidget {
  final String reservationId;
  final void Function(String?) onSubmit;

  const _ReasonForm({
    required this.reservationId,
    required this.onSubmit,
  });

  @override
  State<_ReasonForm> createState() => _ReasonFormState();
}

class _ReasonFormState extends State<_ReasonForm> {
  final _controller = TextEditingController();
  String _selectedReason = 'schedule_conflict';

  static const _reasons = <String, String>{
    'schedule_conflict': 'Trùng lịch',
    'illness': 'Ốm / sức khoẻ',
    'no_partner': 'Không tìm được người chơi cùng',
    'changed_mind': 'Đổi ý',
    'other': 'Lý do khác',
  };

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Hiển thị policy huỷ theo BR-REFUND-02 (BVC v2).
  ///
  /// Backend đã đơn giản hoá policy còn 2 mốc duy nhất:
  /// - Grace 15 phút (countdown ngay sau khi confirm) HOẶC ≥24h trước
  ///   giờ chơi → hoàn 100% BVC.
  /// - <24h trước giờ chơi (ngoài grace) → hoàn 0% BVC, có thể bị trừ
  ///   Karma tuỳ BR-USER-LIMIT-* (FE không hiển thị chi tiết — server
  ///   mới là nguồn chính).
  ///
  /// Lưu ý: tier 50% (6-24h trước) đã bị BVC v2 bỏ — UI không còn đề
  /// cập "6-24h hoàn 50%" nữa.
  static const _refundPolicyDescription =
      'Policy BR-REFUND-02: trong 15 phút đầu HOẶC trước 24 giờ → '
      'hoàn 100%. Dưới 24 giờ (ngoài grace) → hoàn 0%, có thể bị phạt '
      'Karma.';

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Huỷ đặt chỗ', style: textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<String>(
          initialValue: _selectedReason,
          items: _reasons.entries
              .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
              .toList(),
          onChanged: (v) {
            if (v != null) setState(() => _selectedReason = v);
          },
          decoration: const InputDecoration(labelText: 'Lý do'),
        ),
        if (_selectedReason == 'other') ...[
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _controller,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Mô tả chi tiết',
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.radiusMd),
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.warning),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  _refundPolicyDescription,
                  style: textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () {
              final reason = _selectedReason == 'other'
                  ? _controller.text.trim()
                  : _selectedReason;
              widget.onSubmit(reason.isEmpty ? null : reason);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            child: const Text('Xác nhận huỷ'),
          ),
        ),
      ],
    );
  }
}

class _CancelledView extends StatelessWidget {
  final ReservationCancelResult result;
  final VoidCallback onDismiss;

  const _CancelledView({
    required this.result,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle, color: Colors.green, size: 56),
        const SizedBox(height: AppSpacing.sm),
        Text('Đã huỷ đặt chỗ', style: textTheme.titleLarge),
        const SizedBox(height: AppSpacing.md),
        _kv('Hoàn BVC', '${result.refundBvc}'),
        _kv('BVC bị giữ', '${result.forfeitBvc}'),
        _kv('Policy', result.refundPolicyApplied.refundPolicyLabel),
        const SizedBox(height: AppSpacing.md),
        FilledButton(
          onPressed: onDismiss,
          child: const Text('Đóng'),
        ),
      ],
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(k), Text(v, style: const TextStyle(fontWeight: FontWeight.w600))],
        ),
      );
}

class _CancelErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _CancelErrorView({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
        const SizedBox(height: AppSpacing.sm),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Đóng'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: FilledButton(
                onPressed: onRetry,
                child: const Text('Thử lại'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CenteredLoading extends StatelessWidget {
  const _CenteredLoading();

  @override
  Widget build(BuildContext context) =>
      const SizedBox(height: 160, child: Center(child: CircularProgressIndicator()));
}
