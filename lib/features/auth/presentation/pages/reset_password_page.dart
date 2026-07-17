import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/components/toast_card.dart';
import 'package:delightful_toast/toast/utils/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../widgets/widgets.dart';
import 'login_page.dart';

class ResetPasswordPage extends StatefulWidget {
  final String email;

  const ResetPasswordPage({super.key, required this.email});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true, _obscureConfirm = true;
  final int _otpLength = 6;

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack));
    _animationController.forward();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onResetPassword() {
    if (!_formKey.currentState!.validate()) return;
    if (_otpController.text.trim().length != _otpLength) {
      _showToast('Vui lòng nhập đủ $_otpLength chữ số', isError: true);
      return;
    }
    context.read<AuthCubit>().resetPassword(otpCode: _otpController.text.trim(), newPassword: _passwordController.text);
  }

  void _showToast(String message, {bool isError = false}) {
    DelightToastBar(autoDismiss: true, snackbarDuration: const Duration(seconds: 3), position: DelightSnackbarPosition.top, builder: (context) => ToastCard(leading: Icon(isError ? Icons.error_outline : Icons.check_circle_outlined, color: isError ? AppColors.error : AppColors.success, size: 28), title: Text(message, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)))).show(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthPasswordResetSuccess) {
            _showToast(state.message);
            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginPage()), (route) => false);
          } else if (state is AuthFailure) {
            _showToast(state.message, isError: true);
          }
        },
        builder: (context, state) {
          return AuthGradientBackground(
            colors: AuthGradientBackground.verifyGradient,
            stops: AuthGradientBackground.standardStops,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            child: SafeArea(
              child: Column(
                children: [
                  _buildAppBar(context),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
                      child: FadeTransition(opacity: _fadeAnimation, child: ScaleTransition(scale: _scaleAnimation, child: Form(key: _formKey, child: _buildContent(context, state)))),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      child: Row(children: [AuthBackButton(onPressed: () => Navigator.pop(context)), const Spacer(), Text('Đặt lại mật khẩu', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w600)), const Spacer(), const SizedBox(width: 48)]),
    );
  }

  Widget _buildContent(BuildContext context, AuthState state) {
    final isLoading = state is AuthLoading;
    return Column(children: [
      const SizedBox(height: AppSpacing.lg),
      const _ResetIconBadge(),
      const SizedBox(height: AppSpacing.xl),
      const AuthTitle(title: 'Đặt lại mật khẩu'),
      const SizedBox(height: AppSpacing.md),
      EmailInfoBadge(email: widget.email),
      const SizedBox(height: AppSpacing.md),
      Text('Nhập mã OTP đã gửi qua email và mật khẩu mới của bạn.', style: TextStyle(color: AppColors.white.withValues(alpha: 0.8), height: 1.5), textAlign: TextAlign.center),
      const SizedBox(height: AppSpacing.xxl),
      AuthFormCard(
        child: Column(children: [
          _buildOtpField(context),
          const SizedBox(height: AppSpacing.md),
          _buildPasswordField(),
          const SizedBox(height: AppSpacing.xs),
          PasswordStrengthIndicator(password: _passwordController.text),
          const SizedBox(height: AppSpacing.md),
          _buildConfirmPasswordField(),
          const SizedBox(height: AppSpacing.xl),
          AuthPrimaryButton(label: 'Đặt lại mật khẩu', icon: Icons.lock_reset, isLoading: isLoading, onPressed: _onResetPassword),
        ]),
      ),
    ]);
  }

  Widget _buildOtpField(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Mã OTP', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
      const SizedBox(height: AppSpacing.xs),
      SizedBox(
        height: 56,
        child: TextFormField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: _otpLength,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(_otpLength)],
          style: Theme.of(context).textTheme.titleLarge?.copyWith(letterSpacing: 8, fontWeight: FontWeight.w700, color: AppColors.primary),
          decoration: InputDecoration(hintText: List.filled(_otpLength, '•').join(' '), hintStyle: Theme.of(context).textTheme.titleLarge?.copyWith(letterSpacing: 8, color: AppColors.textTertiary), counterText: '', filled: true, fillColor: AppColors.surfaceVariant, contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md), border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.sm), borderSide: BorderSide.none), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.sm), borderSide: BorderSide.none), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.sm), borderSide: const BorderSide(color: AppColors.primary, width: 2))),
        ),
      ),
    ]);
  }

  Widget _buildPasswordField() {
    return AuthTextField(
      controller: _passwordController,
      label: 'Mật khẩu mới',
      hint: 'Nhập mật khẩu mới',
      icon: Icons.lock_outline,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.next,
      suffixIcon: IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: AppIcons.sm, color: AppColors.textSecondary), onPressed: () => setState(() => _obscurePassword = !_obscurePassword)),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu';
        if (v.length < 8) return 'Tối thiểu 8 ký tự';
        return null;
      },
    );
  }

  Widget _buildConfirmPasswordField() {
    return AuthTextField(
      controller: _confirmPasswordController,
      label: 'Xác nhận mật khẩu',
      hint: 'Nhập lại mật khẩu mới',
      icon: Icons.lock_outline,
      obscureText: _obscureConfirm,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _onResetPassword(),
      suffixIcon: IconButton(icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: AppIcons.sm, color: AppColors.textSecondary), onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm)),
      validator: (v) {
        if (v != _passwordController.text) return 'Mật khẩu xác nhận không khớp';
        return null;
      },
    );
  }
}

class _ResetIconBadge extends StatelessWidget {
  const _ResetIconBadge();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(alignment: Alignment.center, children: [
        Container(width: 100, height: 100, decoration: BoxDecoration(color: AppColors.white.withValues(alpha: 0.15), shape: BoxShape.circle, border: Border.all(color: AppColors.white.withValues(alpha: 0.3), width: 3))),
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: AppColors.cardGradientOrange), shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 20, spreadRadius: 2)]),
          child: const Icon(Icons.lock_reset, size: 32, color: AppColors.white),
        ),
      ]),
    );
  }
}
