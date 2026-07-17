import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/components/toast_card.dart';
import 'package:delightful_toast/toast/utils/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../widgets/widgets.dart';
import 'reset_password_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

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
    _emailController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onRequestReset() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthCubit>().requestPasswordReset(email: _emailController.text.trim());
  }

  void _showToast(String message, {bool isError = false}) {
    DelightToastBar(autoDismiss: true, snackbarDuration: const Duration(seconds: 3), position: DelightSnackbarPosition.top, builder: (context) => ToastCard(leading: Icon(isError ? Icons.error_outline : Icons.check_circle_outlined, color: isError ? AppColors.error : AppColors.success, size: 28), title: Text(message, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)))).show(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthPasswordResetRequested) {
            _showToast(state.message);
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ResetPasswordPage(email: _emailController.text.trim())));
          } else if (state is AuthFailure) {
            _showToast(state.message, isError: true);
          }
        },
        builder: (context, state) {
          return AuthGradientBackground(
            colors: AuthGradientBackground.registerGradient,
            stops: AuthGradientBackground.standardStops,
            child: SafeArea(
              child: Column(
                children: [
                  _buildAppBar(context),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                      child: FadeTransition(opacity: _fadeAnimation, child: SlideTransition(position: _slideAnimation, child: Form(key: _formKey, child: _buildContent(context, state)))),
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
      child: Row(children: [AuthBackButton(onPressed: () => Navigator.pop(context)), const Spacer(), const AuthLogoMini(), const Spacer(), const SizedBox(width: 48)]),
    );
  }

  Widget _buildContent(BuildContext context, AuthState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.xl),
        const AuthTitle(title: 'Quên mật khẩu?', subtitle: 'Nhập email để nhận mã đặt lại mật khẩu'),
        const SizedBox(height: AppSpacing.xl),
        AuthFormCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthTextField(
                controller: _emailController,
                label: 'Email',
                hint: 'Nhập email đã đăng ký',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _onRequestReset(),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Vui lòng nhập email';
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value.trim())) return 'Email không hợp lệ';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.xl),
              AuthPrimaryButton(
                label: 'Gửi yêu cầu',
                icon: Icons.send,
                isLoading: state is AuthLoading,
                onPressed: _onRequestReset,
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildBackToLogin(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBackToLogin(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Nhớ mật khẩu? ', style: TextStyle(color: AppColors.textSecondary)),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Đăng nhập', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}
