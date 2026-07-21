import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../domain/enums/payment_method.dart';
import 'booking_ui_helpers.dart';

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
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.xs,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: AppRadius.radiusSmAll,
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  size: AppIcons.md,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Phương thức thanh toán',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        ...methods.map(
          (m) => Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xxs,
            ),
            child: _PaymentMethodTile(
              method: m,
              selected: m == selected,
              onTap: () => onChanged(m),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  final PaymentMethod method;
  final bool selected;
  final VoidCallback onTap;

  const _PaymentMethodTile({
    required this.method,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = BookingUiHelpers.paymentMethodColor(method, context);
    final icon = BookingUiHelpers.paymentMethodIcon(method);

    return Material(
      color: selected
          ? accent.withValues(alpha: 0.10)
          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      borderRadius: AppRadius.radiusMdAll,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.radiusMdAll,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: AppRadius.radiusMdAll,
            border: Border.all(
              color: selected
                  ? accent
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: AppRadius.radiusXxsAll,
                ),
                child: Icon(icon, size: AppIcons.md, color: accent),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method.displayName,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (method == PaymentMethod.sandboxMock) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Dùng cho môi trường dev — không qua cổng thật',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Radio<PaymentMethod>(
                value: method,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
