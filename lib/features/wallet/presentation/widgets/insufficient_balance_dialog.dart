import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/neo_brutalism_theme.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../cubit/topup_cubit.dart';
import '../pages/topup_page.dart';

/// Neo-brutalism Dialog hiển thị khi số dư BVC không đủ cho reservation.
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;
    final missingAmount = requiredAmount - wallet.availableBalance;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Stack(
        children: [
          // Hard shadow offset
          Positioned(
            left: 3,
            right: -3,
            top: 3,
            bottom: -3,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.black,
                borderRadius: BorderRadius.circular(AppRadius.radiusLg + 2),
              ),
            ),
          ),
          // Main dialog
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.radiusLg),
              border: Border.all(
                color: borderColor,
                width: NeoBrutalismTheme.borderWidthBold,
              ),
            ),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.warning,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.black,
                          width: 2,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.black,
                            blurRadius: 0,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_outlined,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'SỐ DƯ KHÔNG ĐỦ',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Bạn cần thêm ${_formatBvc(missingAmount)} BVC để thực hiện đặt cọc.',
                  style: textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _buildInfoRow(textTheme, 'Số dư hiện tại',
                    '${wallet.availableBalance} BVC', AppColors.textSecondary),
                const SizedBox(height: AppSpacing.sm),
                _buildInfoRow(textTheme, 'Số tiền cần',
                    '$requiredAmount BVC', AppColors.textPrimary),
                const SizedBox(height: AppSpacing.sm),
                _buildInfoRow(textTheme, 'Thiếu',
                    '$missingAmount BVC', AppColors.error),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark : AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: borderColor,
                            width: NeoBrutalismTheme.borderWidth,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              Navigator.of(context).pop();
                              onCancel?.call();
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: AppSpacing.sm,
                              ),
                              child: Text(
                                'HỦY BỎ',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: borderColor,
                            width: NeoBrutalismTheme.borderWidth,
                          ),
                          boxShadow: NeoBrutalismTheme.lightShadow(
                            shadowColor:
                                AppColors.primary.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              Navigator.of(context).pop();
                              _navigateToTopUp(context, missingAmount);
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: AppSpacing.sm,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add,
                                    color: AppColors.white,
                                    size: 16,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'NẠP THÊM',
                                    style: TextStyle(
                                      color: AppColors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    TextTheme textTheme,
    String label,
    String value,
    Color valueColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: valueColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: valueColor.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            value,
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: valueColor,
            ),
          ),
        ],
      ),
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