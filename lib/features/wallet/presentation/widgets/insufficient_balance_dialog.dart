import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../cubit/topup_cubit.dart';
import '../pages/topup_page.dart';

/// Dialog hiển thị khi số dư BVC không đủ cho reservation
///
/// User có thể chọn:
/// - Nạp thêm BVC ngay
/// - Hủy bỏ
class InsufficientBalanceDialog extends StatelessWidget {
  final WalletEntity wallet;
  final int requiredAmount;
  final VoidCallback? onCancel;
  final VoidCallback? onTopUpComplete;

  const InsufficientBalanceDialog({
    super.key,
    required this.wallet,
    required this.requiredAmount,
    this.onCancel,
    this.onTopUpComplete,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final missingAmount = requiredAmount - wallet.availableBalance;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.radiusLg),
      ),
      title: Row(
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            color: AppColors.warning,
          ),
          SizedBox(width: AppSpacing.sm),
          Text(
            'Số dư không đủ',
            style: textTheme.titleLarge,
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bạn cần thêm ${_formatBvc(missingAmount)} BVC để thực hiện đặt cọc.',
            style: textTheme.bodyMedium,
          ),
          SizedBox(height: AppSpacing.lg),
          _buildInfoRow(
            textTheme,
            'Số dư hiện tại',
            '${wallet.availableBalance} BVC',
            AppColors.textSecondary,
          ),
          SizedBox(height: AppSpacing.sm),
          _buildInfoRow(
            textTheme,
            'Số tiền cần',
            '$requiredAmount BVC',
            AppColors.textPrimary,
          ),
          SizedBox(height: AppSpacing.sm),
          _buildInfoRow(
            textTheme,
            'Thiếu',
            '$missingAmount BVC',
            AppColors.error,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onCancel?.call();
          },
          child: Text(
            'Hủy bỏ',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
            _navigateToTopUp(context, missingAmount);
          },
          icon: const Icon(Icons.add),
          label: const Text('Nạp thêm'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    TextTheme textTheme,
    String label,
    String value,
    Color valueColor,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: textTheme.bodyMedium,
        ),
        Text(
          value,
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  void _navigateToTopUp(BuildContext context, int amountBvc) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (_) => TopUpCubit(repository: GetIt.I<WalletRepository>()),
          child: TopUpPage(
            initialAmountVnd: amountBvc * 1000,
            onSuccess: () {
              onTopUpComplete?.call();
            },
          ),
        ),
      ),
    );
  }

  String _formatBvc(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}
