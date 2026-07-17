import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/components/toast_card.dart';
import 'package:delightful_toast/toast/utils/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/navigation/pages/main_scaffold.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../widgets/widgets.dart';
import 'login_page.dart';

class VerifyEmailPage extends StatefulWidget {
  final String email;

  const VerifyEmailPage({super.key, required this.email});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> with SingleTickerProviderStateMixin {
  final _otpController = TextEditingController();
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
    _animationController.dispose();
    super.dispose();
  }

  void _onVerify() {
    if (_otpController.text.trim().length != _otpLength) {
      _showToast('Vui lòng nhập đủ $_otpLength chữ số.', isError: true);
      return;
    }
    context.read<AuthCubit>().verifyEmail(otpCode: _otpController.text.trim());
  }

  void _onResendCode() => context.read<AuthCubit>().sendEmailVerification(email: widget.email);

  void _showToast(String message, {bool isError = false}) {
    DelightToastBar(autoDismiss: true, snackbarDuration: const Duration(seconds: 3), position: DelightSnackbarPosition.top, builder: (context) => ToastCard(leading: Icon(isError ? Icons.error_outline : Icons.check_circle_outlined, color: isError ? AppColors.error : AppColors.success, size: 28), title: Text(message, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)))).show(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            // Auto-login after OTP verification — straight into the app.
            _showToast('Xác thực thành công!');
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const MainScaffold()),
              (route) => false,
            );
          } else if (state is AuthEmailVerified) {
            // Fallback for the flow where tokens weren't returned by register.
            _showToast(state.message);
            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginPage()), (route) => false);
          } else if (state is AuthEmailVerificationSent) {
            _showToast(state.message);
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
                      child: FadeTransition(opacity: _fadeAnimation, child: ScaleTransition(scale: _scaleAnimation, child: _buildContent(context, state))),
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
      child: Row(
        children: [
          AuthBackButton(onPressed: () => Navigator.pop(context)),
          const Spacer(),
          const Text('Xác thực email', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w600)),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, AuthState state) {
    final isLoading = state is AuthLoading;
    return Column(
      children: [
        const SizedBox(height: AppSpacing.xl),
        const _EmailIconBadge(),
        const SizedBox(height: AppSpacing.xl),
        const AuthTitle(title: 'Nhập mã xác thực'),
        const SizedBox(height: AppSpacing.md),
        EmailInfoBadge(email: widget.email),
        const SizedBox(height: AppSpacing.md),
        Text('Chúng tôi đã gửi mã OTP $_otpLength chữ số đến email của bạn.\nVui lòng kiểm tra hộp thư và nhập mã bên dưới.', style: TextStyle(color: AppColors.white.withValues(alpha: 0.8), height: 1.5), textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.xxl),
        AuthFormCard(
          child: Column(
            children: [
              _buildOtpSection(),
              const SizedBox(height: AppSpacing.lg),
              AuthPrimaryButton(label: 'Xác nhận', icon: Icons.check_circle_outline, isLoading: isLoading, onPressed: _onVerify),
              const SizedBox(height: AppSpacing.lg),
              _buildResendSection(isLoading),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Text('Không nhận được mã? Kiểm tra thư rác hoặc nhấn "Gửi lại"', style: TextStyle(color: AppColors.white.withValues(alpha: 0.7)), textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildOtpSection() {
    return Column(
      children: [
        const Text('Nhập mã OTP', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: AppSpacing.md),
        OtpInputField(controller: _otpController, length: _otpLength, onChanged: (v) {
          if (v.length == _otpLength) _onVerify();
          setState(() {});
        }),
        if (_otpController.text.isEmpty) ...[const SizedBox(height: AppSpacing.sm), Text('Mã có $_otpLength chữ số', style: TextStyle(color: AppColors.textTertiary))],
      ],
    );
  }

  Widget _buildResendSection(bool isLoading) {
    return Column(
      children: [
        const Divider(color: AppColors.border),
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Chưa nhận được mã? ', style: TextStyle(color: AppColors.textSecondary)),
            TextButton.icon(
              onPressed: isLoading ? null : _onResendCode,
              icon: const Icon(Icons.refresh, size: AppIcons.sm, color: AppColors.primary),
              label: const Text('Gửi lại mã', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ],
    );
  }
}

class _EmailIconBadge extends StatelessWidget {
  const _EmailIconBadge();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(width: 120, height: 120, decoration: BoxDecoration(color: AppColors.white.withValues(alpha: 0.15), shape: BoxShape.circle, border: Border.all(color: AppColors.white.withValues(alpha: 0.3), width: 3))),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: AppColors.cardGradientOrange),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 20, spreadRadius: 2)],
            ),
            child: const Icon(Icons.email_outlined, size: 36, color: AppColors.white),
          ),
          Positioned(
            right: 10,
            top: 10,
            child: Container(width: 32, height: 32, decoration: BoxDecoration(color: AppColors.accent, shape: BoxShape.circle, border: Border.all(color: AppColors.white, width: 2)), child: const Icon(Icons.check, size: 16, color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}
