import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/theme.dart';
import '../../domain/entities/entities.dart';
import '../cubit/reservation_cubit.dart';
import '../cubit/reservation_state.dart';

/// Bottom sheet cho phép user nhập lý do hủy + xem preview refund/forfeit
/// theo policy backend. Sau khi cancel xong sẽ hiển thị kết quả policy.
class ReservationCancelSheet extends StatelessWidget {
  final String reservationId;

  const ReservationCancelSheet({
    super.key,
    required this.reservationId,
  });

  static Future<void> show(BuildContext context, String reservationId) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: context.read<ReservationCubit>(),
        child: ReservationCancelSheet(reservationId: reservationId),
      ),
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
        child: BlocConsumer<ReservationCubit, ReservationState>(
          listener: (context, state) {},
          builder: (context, state) {
            if (state is ReservationCancelling) {
              return const _CenteredLoading();
            }
            if (state is ReservationCancelled) {
              return _CancelledView(result: state.result);
            }
            if (state is ReservationCancelError) {
              return _CancelErrorView(message: state.message);
            }
            return _ReasonForm(reservationId: reservationId);
          },
        ),
      ),
    );
  }
}

class _ReasonForm extends StatefulWidget {
  final String reservationId;
  const _ReasonForm({required this.reservationId});

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

  void _submit(BuildContext context) {
    final reason =
        _selectedReason == 'other' ? _controller.text.trim() : _selectedReason;
    context
        .read<ReservationCubit>()
        .cancelReservation(widget.reservationId, reason: reason.isEmpty ? null : reason);
  }

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
                  'Theo policy: huỷ trong 15 phút đầu hoàn 100% BVC; huỷ trước 6 giờ hoàn 50%; dưới 6 giờ forfeit 100%.',
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
            onPressed: () => _submit(context),
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
  const _CancelledView({required this.result});

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
        _kv('Policy', result.refundPolicyApplied),
        const SizedBox(height: AppSpacing.md),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
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
  const _CancelErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
        const SizedBox(height: AppSpacing.sm),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.md),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Đóng'),
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