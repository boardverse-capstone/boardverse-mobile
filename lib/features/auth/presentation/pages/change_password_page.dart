import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/components/toast_card.dart';
import 'package:delightful_toast/toast/utils/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureCurrent = true, _obscureNew = true, _obscureConfirm = true;

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
    _animationController.forward();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onChangePassword() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthCubit>().changePassword(currentPassword: _currentPasswordController.text, newPassword: _newPasswordController.text);
  }

  void _showToast(String message, {bool isError = false}) {
    DelightToastBar(autoDismiss: true, snackbarDuration: const Duration(seconds: 3), position: DelightSnackbarPosition.top, builder: (context) => ToastCard(leading: Icon(isError ? Icons.error_outline : Icons.check_circle_outlined, color: isError ? AppColors.error : AppColors.success, size: 28), title: Text(message, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)))).show(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đổi mật khẩu'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthPasswordChanged) {
            _showToast(state.message);
            Navigator.pop(context);
          } else if (state is AuthFailure) {
            _showToast(state.message, isError: true);
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildCurrentPasswordField(),
                      const SizedBox(height: AppSpacing.md),
                      _buildNewPasswordField(),
                      const SizedBox(height: AppSpacing.xs),
                      _buildPasswordStrengthIndicator(),
                      const SizedBox(height: AppSpacing.md),
                      _buildConfirmPasswordField(),
                      const SizedBox(height: AppSpacing.xl),
                      _buildChangeButton(state is AuthLoading),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mật khẩu hiện tại', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(
          controller: _currentPasswordController,
          obscureText: _obscureCurrent,
          textInputAction: TextInputAction.next,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Nhập mật khẩu hiện tại',
            hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textTertiary),
            prefixIcon: const Icon(Icons.lock_outline, size: AppIcons.md, color: AppColors.textSecondary),
            suffixIcon: IconButton(icon: Icon(_obscureCurrent ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: AppIcons.sm, color: AppColors.textSecondary), onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent)),
            filled: true,
            fillColor: AppColors.surfaceVariant,
            contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.sm), borderSide: BorderSide.none),
          ),
          validator: (v) => (v == null || v.isEmpty) ? 'Vui lòng nhập mật khẩu hiện tại' : null,
        ),
      ],
    );
  }

  Widget _buildNewPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mật khẩu mới', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(
          controller: _newPasswordController,
          obscureText: _obscureNew,
          textInputAction: TextInputAction.next,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Nhập mật khẩu mới',
            hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textTertiary),
            prefixIcon: const Icon(Icons.lock_outline, size: AppIcons.md, color: AppColors.textSecondary),
            suffixIcon: IconButton(icon: Icon(_obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: AppIcons.sm, color: AppColors.textSecondary), onPressed: () => setState(() => _obscureNew = !_obscureNew)),
            filled: true,
            fillColor: AppColors.surfaceVariant,
            contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.sm), borderSide: BorderSide.none),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu mới';
            if (v.length < 8) return 'Tối thiểu 8 ký tự';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    final password = _newPasswordController.text;
    if (password.isEmpty) return const SizedBox.shrink();

    int strength = 0;
    Color strengthColor = AppColors.error;
    String strengthText = 'Yếu';

    if (password.length >= 8) strength++;
    if (password.length >= 12) strength++;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength++;
    if (RegExp(r'[0-9]').hasMatch(password)) strength++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strength++;

    switch (strength) {
      case 0:
      case 1:
        strengthColor = AppColors.error;
        strengthText = 'Yếu';
        break;
      case 2:
        strengthColor = AppColors.warning;
        strengthText = 'Trung bình';
        break;
      case 3:
        strengthColor = AppColors.success;
        strengthText = 'Khá';
        break;
      case 4:
      case 5:
        strengthColor = AppColors.primary;
        strengthText = 'Mạnh';
        break;
    }

    return Row(
      children: [
        Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: strength / 5, backgroundColor: AppColors.border, valueColor: AlwaysStoppedAnimation<Color>(strengthColor), minHeight: 4))),
        const SizedBox(width: AppSpacing.sm),
        Text(strengthText, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: strengthColor, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildConfirmPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Xác nhận mật khẩu mới', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirm,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _onChangePassword(),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Nhập lại mật khẩu mới',
            hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textTertiary),
            prefixIcon: const Icon(Icons.lock_outline, size: AppIcons.md, color: AppColors.textSecondary),
            suffixIcon: IconButton(icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: AppIcons.sm, color: AppColors.textSecondary), onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm)),
            filled: true,
            fillColor: AppColors.surfaceVariant,
            contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.sm), borderSide: BorderSide.none),
          ),
          validator: (v) {
            if (v != _newPasswordController.text) return 'Mật khẩu xác nhận không khớp';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildChangeButton(bool isLoading) {
    return SizedBox(
      height: 52,
      child: FilledButton(
        onPressed: isLoading ? null : _onChangePassword,
        style: FilledButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.sm))),
        child: isLoading
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.white))
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.save, size: AppIcons.sm),
                const SizedBox(width: AppSpacing.xs),
                Text('Đổi mật khẩu', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.white, fontWeight: FontWeight.w600)),
              ]),
      ),
    );
  }
}
