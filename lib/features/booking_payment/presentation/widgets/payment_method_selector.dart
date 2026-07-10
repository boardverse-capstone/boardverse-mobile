import 'package:flutter/material.dart';

import '../../domain/enums/payment_method.dart';

/// Radio list cho phương thức thanh toán.
///
/// Hiện tại chỉ có [PaymentMethod.sandboxMock]; cấu trúc đặt sẵn để
/// khi tích hợp VNPay/MoMo chỉ cần enable thêm.
class PaymentMethodSelector extends StatelessWidget {
  final PaymentMethod selected;
  final ValueChanged<PaymentMethod> onChanged;

  const PaymentMethodSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final methods = PaymentMethod.values;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            'Phương thức thanh toán',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        ...methods.map(
          (m) => RadioListTile<PaymentMethod>(
            value: m,
            // ignore: deprecated_member_use
            groupValue: selected,
            // ignore: deprecated_member_use
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
            title: Text(m.displayName),
            subtitle: m == PaymentMethod.sandboxMock
                ? const Text('Dùng cho môi trường dev — không qua cổng thật')
                : null,
            controlAffinity: ListTileControlAffinity.trailing,
          ),
        ),
      ],
    );
  }
}
