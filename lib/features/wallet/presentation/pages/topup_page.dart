import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/neo_brutalism_theme.dart';
import '../cubit/topup_cubit.dart';
import '../cubit/topup_state.dart';

/// Neo-brutalism Màn hình nạp BVC.
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
  int _selectedAmountVnd = 100000;

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
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (amountToSend % 1000 != 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Số tiền phải chia hết cho 1.000'),
          backgroundColor: AppColors.error,
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

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;
    final bgColor = isDark ? AppColors.backgroundDark : AppColors.background;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: const Text(
          'NẠP BVC',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<TopUpCubit, TopUpState>(
        listenWhen: (previous, current) => previous.runtimeType != current.runtimeType,
        listener: (context, state) {
          if (state is TopUpSuccess) {
            _showSuccessDialog(context, state);
          } else if (state is TopUpFailed) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.reason),
                backgroundColor: AppColors.error,
              ),
            );
          } else if (state is TopUpExpired) {
            _showExpiredDialog(context);
          }
        },
        buildWhen: (previous, current) {
          if (previous.runtimeType != current.runtimeType) return true;
          return false;
        },
        builder: (context, state) {
          return SingleChildScrollView(
            key: const PageStorageKey<String>('topup_scroll'),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildPackageSection(context, state, textTheme, borderColor),
                const SizedBox(height: AppSpacing.lg),
                _buildCustomAmountSection(context, state, textTheme, borderColor),
                const SizedBox(height: AppSpacing.xl),
                _buildAmountSummary(context, state, textTheme, borderColor),
                const SizedBox(height: AppSpacing.xl),
                _buildActionButton(context, state, borderColor),
                if (state is TopUpAwaitingPayment) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _buildPaymentInstructions(context, state, textTheme),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPackageSection(BuildContext context, TopUpState state, TextTheme textTheme, Color borderColor) {
    final packages = TopUpPackages.suggestedPackages;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CHỌN GÓI NẠP',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1.1,
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

            return _PackageTile(
              pkg: pkg,
              isSelected: isSelected,
              isDisabled: isDisabled,
              onTap: () => _selectAmount(pkg.amountVnd),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCustomAmountSection(BuildContext context, TopUpState state, TextTheme textTheme, Color borderColor) {
    final isDisabled = state is TopUpAwaitingPayment ||
        state is TopUpCreating ||
        state is TopUpCheckingStatus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'HOẶC NHẬP SỐ TIỀN KHÁC',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _customAmountController,
          enabled: !isDisabled,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            _ThousandsSeparatorFormatter(),
          ],
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: 'Nhập số tiền (VND)',
            suffixText: 'VND',
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: borderColor,
                width: NeoBrutalismTheme.borderWidth,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: borderColor,
                width: NeoBrutalismTheme.borderWidth,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: NeoBrutalismTheme.borderWidthBold,
              ),
            ),
          ),
          onChanged: (_) {
            setState(() {});
          },
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Tối thiểu 10.000 VND, bội số của 1.000',
          style: textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildAmountSummary(BuildContext context, TopUpState state, TextTheme textTheme, Color borderColor) {
    int amountVnd;
    if (_customAmountController.text.isNotEmpty) {
      amountVnd =
          int.tryParse(_customAmountController.text.replaceAll(',', '')) ?? 0;
    } else {
      amountVnd = _selectedAmountVnd;
    }

    final amountBvc = amountVnd ~/ 1000;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary,
          width: NeoBrutalismTheme.borderWidthBold,
        ),
        boxShadow: NeoBrutalismTheme.lightShadow(
          shadowColor: AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'SỐ TIỀN THANH TOÁN',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                _formatVnd(amountVnd),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(height: 2, color: AppColors.primary.withValues(alpha: 0.3)),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'BẠN NHẬN ĐƯỢC',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 0.8,
                ),
              ),
              Row(
                children: [
                  Text(
                    '$amountBvc',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  const Text(
                    'BVC',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tỷ lệ quy đổi',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '1 BVC = 1.000 VND',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, TopUpState state, Color borderColor) {
    if (state is TopUpAwaitingPayment) {
      return _buildCountdownSection(context, state, borderColor);
    }

    if (state is TopUpCreating || state is TopUpCheckingStatus) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: NeoBrutalismTheme.borderWidthBold),
        boxShadow: NeoBrutalismTheme.lightShadow(
          shadowColor: AppColors.primary.withValues(alpha: 0.5),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _startTopUp(context),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Text(
              'TIẾP TỤC THANH TOÁN',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCountdownSection(BuildContext context, TopUpAwaitingPayment state, Color borderColor) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        _buildQrSection(context, state, textTheme, borderColor),
        const SizedBox(height: AppSpacing.lg),
        _buildPaymentInstructions(context, state, textTheme),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: _NeoOutlineButton(
                label: 'HỦY ĐƠN',
                icon: Icons.close,
                color: AppColors.error,
                borderColor: borderColor,
                onTap: () => _showCancelConfirmation(context),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _NeoOutlineButton(
                label: 'ĐỔI SỐ TIỀN',
                icon: Icons.edit,
                color: AppColors.textPrimary,
                borderColor: borderColor,
                onTap: () => _showUpdateAmountDialog(context),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _NeoFilledButton(
                label: 'MỞ SEPAY',
                icon: Icons.open_in_new,
                color: AppColors.primary,
                borderColor: borderColor,
                onTap: () {
                  context.read<TopUpCubit>().openPaymentUrl();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showUpdateAmountDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.radiusLg),
        ),
        title: const Text('Đổi số tiền đơn top-up'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            hintText: 'Số tiền mới (VND)',
            suffixText: 'VND',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () {
              final newAmount =
                  int.tryParse(controller.text.replaceAll(',', '')) ?? 0;
              Navigator.pop(ctx);
              context.read<TopUpCubit>().updateCurrentTopUp(
                newAmountVnd: newAmount,
                onSuccess: () {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã đổi số tiền đơn.')),
                    );
                  }
                },
              );
            },
            child: const Text('Cập nhật'),
          ),
        ],
      ),
    );
  }

  Widget _buildQrSection(
      BuildContext context, TopUpAwaitingPayment state, TextTheme textTheme, Color borderColor) {
    final qrUrl = state.quote.qrUrl;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: NeoBrutalismTheme.borderWidthBold),
        boxShadow: NeoBrutalismTheme.lightShadow(
          shadowColor: AppColors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        children: [
          const Text(
            'QUÉT QR ĐỂ THANH TOÁN',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Số tiền: ${_formatVnd(state.quote.amountVnd)}',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            'Mã đơn: ${state.quote.orderId}',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.black, width: 2),
            ),
            child: qrUrl.isEmpty
                ? const SizedBox(
                    height: 220,
                    width: 220,
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  )
                : Image.network(
                    qrUrl,
                    height: 220,
                    width: 220,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return SizedBox(
                        height: 220,
                        width: 220,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return _buildFallbackQr(context, state.quote);
                    },
                  ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Mở app ngân hàng và quét QR này',
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackQr(BuildContext context, dynamic quote) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          QrImageView(
            data: quote.paymentUrl,
            version: QrVersions.auto,
            size: 220,
            backgroundColor: AppColors.white,
            errorCorrectionLevel: QrErrorCorrectLevel.M,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Không thể tải ảnh QR. Dùng mã QR này.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.radiusLg),
        ),
        title: const Text('Hủy thanh toán?'),
        content: const Text(
          'Đơn nạp BVC sẽ bị hủy. Nếu bạn đã chuyển khoản, vui lòng liên hệ admin để được hoàn tiền.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Không'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<TopUpCubit>().cancelCurrentTopUp(
                onCancel: () {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã hủy đơn nạp BVC'),
                      ),
                    );
                  }
                },
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Hủy thanh toán'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInstructions(
      BuildContext context, TopUpAwaitingPayment state, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.info, width: NeoBrutalismTheme.borderWidth),
        boxShadow: NeoBrutalismTheme.lightShadow(
          shadowColor: AppColors.info.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.info,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.info_outline, color: AppColors.white, size: 16),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Text(
                'HƯỚNG DẪN THANH TOÁN',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppColors.info,
                  letterSpacing: 0.8,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _buildInstructionStep('1', 'Quét mã QR bằng app SePay'),
          _buildInstructionStep('2', 'Hoặc mở link thanh toán'),
          _buildInstructionStep('3', 'Thanh toán đúng số tiền hiển thị'),
          _buildInstructionStep('4', 'Đợi xác nhận và BVC sẽ được cộng vào ví'),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.info,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.black, width: 2),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, TopUpSuccess state) {
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
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.success, width: 3),
                boxShadow: NeoBrutalismTheme.lightShadow(
                  shadowColor: AppColors.success.withValues(alpha: 0.4),
                ),
              ),
              child: const Icon(Icons.check_circle, color: AppColors.success, size: 48),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'NẠP BVC THÀNH CÔNG!',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${state.amountBvc} BVC đã được cộng vào ví',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Số dư mới: ${state.newBalance} BVC',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.radiusLg),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.error, width: 3),
              ),
              child: const Icon(Icons.access_time, color: AppColors.error, size: 48),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'MÃ THANH TOÁN ĐÃ HẾT HẠN',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Vui lòng tạo mã mới để tiếp tục',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
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

/// Neo-brutalism outlined button.
class _NeoOutlineButton extends StatelessWidget {
  const _NeoOutlineButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.borderColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: NeoBrutalismTheme.borderWidth),
        boxShadow: NeoBrutalismTheme.lightShadow(
          shadowColor: AppColors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Neo-brutalism filled button.
class _NeoFilledButton extends StatelessWidget {
  const _NeoFilledButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.borderColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: NeoBrutalismTheme.borderWidth),
        boxShadow: NeoBrutalismTheme.lightShadow(
          shadowColor: color.withValues(alpha: 0.5),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: AppColors.white, size: 16),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Neo-brutalism package tile.
class _PackageTile extends StatelessWidget {
  const _PackageTile({
    required this.pkg,
    required this.isSelected,
    required this.isDisabled,
    required this.onTap,
  });

  final dynamic pkg;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected ? AppColors.primary : AppColors.border;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: isDisabled ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: isSelected ? 3 : 2),
            boxShadow: isSelected
                ? NeoBrutalismTheme.lightShadow(
                    shadowColor: AppColors.primary.withValues(alpha: 0.4),
                  )
                : NeoBrutalismTheme.lightShadow(
                    shadowColor: AppColors.black.withValues(alpha: 0.04),
                  ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${pkg.amountBvc}',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  color: isSelected ? AppColors.white : AppColors.textPrimary,
                ),
              ),
              Text(
                'BVC',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                  color: isSelected
                      ? AppColors.white.withValues(alpha: 0.85)
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.white.withValues(alpha: 0.25)
                      : AppColors.accent.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  pkg.label,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    color: isSelected
                        ? AppColors.white
                        : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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