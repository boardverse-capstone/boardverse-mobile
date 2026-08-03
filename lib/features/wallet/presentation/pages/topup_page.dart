import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../cubit/topup_cubit.dart';
import '../cubit/topup_state.dart';

/// Màn hình nạp BVC
///
/// Cho phép user:
/// - Chọn gói nạp có sẵn
/// - Nhập số tiền tùy chỉnh (≥ 10.000 VND, bội số 1.000)
/// - Xem QR code và mở SePay
/// - Theo dõi trạng thái thanh toán
class TopUpPage extends StatefulWidget {
  final int? initialAmountVnd;
  final VoidCallback? onSuccess;

  const TopUpPage({
    super.key,
    this.initialAmountVnd,
    this.onSuccess,
  });

  @override
  State<TopUpPage> createState() => _TopUpPageState();
}

class _TopUpPageState extends State<TopUpPage> {
  final TextEditingController _customAmountController = TextEditingController();
  int _selectedAmountVnd = 100000; // Default 100K VND
  Timer? _countdownTimer;
  Duration _remainingTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    if (widget.initialAmountVnd != null) {
      _selectedAmountVnd = widget.initialAmountVnd!;
    }
  }

  @override
  void dispose() {
    _customAmountController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _selectAmount(int amountVnd) {
    setState(() {
      _selectedAmountVnd = amountVnd;
      _customAmountController.clear();
    });
  }

  void _startTopUp(BuildContext context) {
    int amountToSend;
    if (_customAmountController.text.isNotEmpty) {
      amountToSend = int.tryParse(_customAmountController.text.replaceAll(',', '')) ?? 0;
    } else {
      amountToSend = _selectedAmountVnd;
    }

    if (amountToSend < 10000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Số tiền tối thiểu là 10.000 VND'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (amountToSend % 1000 != 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Số tiền phải chia hết cho 1.000'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    context.read<TopUpCubit>().createTopUp(
      amountVnd: amountToSend,
      onSuccess: () {
        widget.onSuccess?.call();
      },
    );
  }

  void _startCountdown(DateTime deadline) {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = deadline.difference(DateTime.now());
      if (remaining.isNegative) {
        timer.cancel();
        setState(() {
          _remainingTime = Duration.zero;
        });
      } else {
        setState(() {
          _remainingTime = remaining;
        });
      }
    });
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nạp BVC'),
        centerTitle: true,
      ),
      body: BlocConsumer<TopUpCubit, TopUpState>(
        listener: (context, state) {
          if (state is TopUpAwaitingPayment) {
            _startCountdown(state.deadline);
          } else if (state is TopUpSuccess) {
            _countdownTimer?.cancel();
            _showSuccessDialog(context, state);
          } else if (state is TopUpFailed) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.reason),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is TopUpExpired) {
            _showExpiredDialog(context);
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildPackageSection(context, state, textTheme),
                SizedBox(height: AppSpacing.lg),
                _buildCustomAmountSection(context, state, textTheme),
                SizedBox(height: AppSpacing.xl),
                _buildAmountSummary(context, state, textTheme),
                SizedBox(height: AppSpacing.xl),
                _buildActionButton(context, state),
                if (state is TopUpAwaitingPayment) ...[
                  SizedBox(height: AppSpacing.lg),
                  _buildPaymentInstructions(context, state, textTheme),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPackageSection(BuildContext context, TopUpState state, TextTheme textTheme) {
    final packages = TopUpPackages.suggestedPackages;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chọn gói nạp',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: AppSpacing.md),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1.2,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
          ),
          itemCount: packages.length,
          itemBuilder: (context, index) {
            final pkg = packages[index];
            final isSelected = _customAmountController.text.isEmpty &&
                _selectedAmountVnd == pkg.amountVnd;
            final isDisabled = state is TopUpAwaitingPayment ||
                state is TopUpCreating ||
                state is TopUpCheckingStatus;

            return InkWell(
              onTap: isDisabled ? null : () => _selectAmount(pkg.amountVnd),
              borderRadius: BorderRadius.circular(AppRadius.radiusMd),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.radiusMd),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${pkg.amountBvc}',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'BVC',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      pkg.label,
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCustomAmountSection(BuildContext context, TopUpState state, TextTheme textTheme) {
    final isDisabled = state is TopUpAwaitingPayment ||
        state is TopUpCreating ||
        state is TopUpCheckingStatus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hoặc nhập số tiền khác',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: AppSpacing.md),
        TextField(
          controller: _customAmountController,
          enabled: !isDisabled,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            _ThousandsSeparatorFormatter(),
          ],
          decoration: InputDecoration(
            hintText: 'Nhập số tiền (VND)',
            prefixText: '',
            suffixText: 'VND',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.radiusMd),
            ),
            filled: true,
            fillColor: isDisabled ? AppColors.surface : Colors.white,
          ),
          onChanged: (_) {
            setState(() {});
          },
        ),
        SizedBox(height: AppSpacing.xs),
        Text(
          'Tối thiểu 10.000 VND, bội số của 1.000',
          style: textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildAmountSummary(BuildContext context, TopUpState state, TextTheme textTheme) {
    int amountVnd;
    if (_customAmountController.text.isNotEmpty) {
      amountVnd =
          int.tryParse(_customAmountController.text.replaceAll(',', '')) ?? 0;
    } else {
      amountVnd = _selectedAmountVnd;
    }

    final amountBvc = amountVnd ~/ 1000;

    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.radiusLg),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Số tiền thanh toán',
                style: textTheme.bodyMedium,
              ),
              Text(
                _formatVnd(amountVnd),
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bạn nhận được',
                style: textTheme.bodyMedium,
              ),
              Row(
                children: [
                  Text(
                    '$amountBvc',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(width: AppSpacing.xs),
                  Text(
                    'BVC',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tỷ lệ quy đổi',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '1 BVC = 1.000 VND',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, TopUpState state) {
    if (state is TopUpAwaitingPayment) {
      return _buildCountdownSection(context, state);
    }

    if (state is TopUpCreating || state is TopUpCheckingStatus) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return ElevatedButton(
      onPressed: () => _startTopUp(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.radiusMd),
        ),
      ),
      child: const Text(
        'Tiếp tục thanh toán',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildCountdownSection(BuildContext context, TopUpAwaitingPayment state) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: _remainingTime.inMinutes < 2
                ? Colors.red.withValues(alpha: 0.1)
                : Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.radiusLg),
          ),
          child: Column(
            children: [
              Icon(
                Icons.access_time,
                size: 48,
                color: _remainingTime.inMinutes < 2
                    ? Colors.red
                    : Colors.orange,
              ),
              SizedBox(height: AppSpacing.sm),
              Text(
                'Mã thanh toán hết hạn sau',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              SizedBox(height: AppSpacing.xs),
              Text(
                _formatDuration(_remainingTime),
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _remainingTime.inMinutes < 2
                      ? Colors.red
                      : Colors.orange,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  context.read<TopUpCubit>().retryTopUp(
                    onSuccess: () {
                      widget.onSuccess?.call();
                    },
                  );
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Tạo mã mới'),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
              ),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  context.read<TopUpCubit>().openPaymentUrl();
                },
                icon: const Icon(Icons.open_in_new),
                label: const Text('Mở SePay'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.md),
        ElevatedButton(
          onPressed: () {
            context.read<TopUpCubit>().checkStatus(
              onSuccess: () {
                widget.onSuccess?.call();
              },
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
          ),
          child: const Text('Tôi đã thanh toán'),
        ),
      ],
    );
  }

  Widget _buildPaymentInstructions(
      BuildContext context, TopUpAwaitingPayment state, TextTheme textTheme) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.radiusLg),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.info, size: 20),
              SizedBox(width: AppSpacing.sm),
              Text(
                'Hướng dẫn thanh toán',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.info,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          _buildInstructionStep('1', 'Quét mã QR bằng app SePay', textTheme),
          _buildInstructionStep('2', 'Hoặc mở link thanh toán', textTheme),
          _buildInstructionStep('3', 'Thanh toán đúng số tiền hiển thị', textTheme),
          _buildInstructionStep('4', 'Đợi xác nhận và BVC sẽ được cộng vào ví', textTheme),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(String number, String text, TextTheme textTheme) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: textTheme.labelSmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, TopUpSuccess state) {
    final textTheme = Theme.of(context).textTheme;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.radiusLg),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 64,
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              'Nạp BVC thành công!',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              '${state.amountBvc} BVC đã được cộng vào ví',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              'Số dư mới: ${state.newBalance} BVC',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showExpiredDialog(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.radiusLg),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.access_time,
              color: Colors.red,
              size: 64,
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              'Mã thanh toán đã hết hạn',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              'Vui lòng tạo mã mới để tiếp tục',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Đóng'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<TopUpCubit>().retryTopUp(
                onSuccess: () {
                  widget.onSuccess?.call();
                },
              );
            },
            child: const Text('Tạo mã mới'),
          ),
        ],
      ),
    );
  }

  String _formatVnd(int amount) {
    final str = amount.toString();
    final result = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        result.write(',');
      }
      result.write(str[i]);
    }
    return '$result VNĐ';
  }
}

/// Input formatter for thousands separator
class _ThousandsSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final number = int.tryParse(newValue.text.replaceAll(',', ''));
    if (number == null) {
      return oldValue;
    }

    final formatted = _formatNumber(number);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _formatNumber(int number) {
    final str = number.toString();
    final result = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        result.write(',');
      }
      result.write(str[i]);
    }
    return result.toString();
  }
}
