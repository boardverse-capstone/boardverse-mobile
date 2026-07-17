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
import '../widgets/widgets.dart';
import 'verify_email_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true, _obscureConfirm = true, _acceptTerms = false;

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
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onRegister() {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptTerms) {
      _showToast('Vui lòng đồng ý với điều khoản sử dụng', isError: true);
      return;
    }
    context.read<AuthCubit>().register(username: _usernameController.text.trim(), email: _emailController.text.trim(), phoneNumber: _phoneController.text.trim(), password: _passwordController.text);
  }

  void _showToast(String message, {bool isError = false}) {
    DelightToastBar(autoDismiss: true, snackbarDuration: const Duration(seconds: 3), position: DelightSnackbarPosition.top, builder: (context) => ToastCard(leading: Icon(isError ? Icons.error_outline : Icons.check_circle_outlined, color: isError ? AppColors.error : AppColors.success, size: 28), title: Text(message, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)))).show(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthRegistered) {
            _showToast(state.message);
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => VerifyEmailPage(email: _emailController.text.trim())));
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
      child: Row(
        children: [
          AuthBackButton(onPressed: () => Navigator.pop(context)),
          const Spacer(),
          const AuthLogoMini(),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, AuthState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AuthTitle(title: 'Tạo tài khoản mới', subtitle: 'Tham gia cộng đồng yêu board game'),
        const SizedBox(height: AppSpacing.xl),
        AuthFormCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthTextField(controller: _usernameController, label: 'Tên đăng nhập', hint: 'Nhập tên đăng nhập', icon: Icons.person_outline, textInputAction: TextInputAction.next, validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tên đăng nhập' : v.trim().length < 3 ? 'Tối thiểu 3 ký tự' : null),
              const SizedBox(height: AppSpacing.md),
              AuthTextField(controller: _emailController, label: 'Email', hint: 'Nhập địa chỉ email', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next, validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập email' : !RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v.trim()) ? 'Email không hợp lệ' : null),
              const SizedBox(height: AppSpacing.md),
              AuthTextField(controller: _phoneController, label: 'Số điện thoại', hint: 'Nhập số điện thoại', icon: Icons.phone_outlined, keyboardType: TextInputType.phone, textInputAction: TextInputAction.next, validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập số điện thoại' : v.trim().length < 10 ? 'Số điện thoại không hợp lệ' : null),
              const SizedBox(height: AppSpacing.md),
              _buildPasswordField(),
              const SizedBox(height: AppSpacing.xs),
              PasswordStrengthIndicator(password: _passwordController.text),
              const SizedBox(height: AppSpacing.md),
              _buildConfirmPasswordField(),
              const SizedBox(height: AppSpacing.lg),
              TermsCheckbox(value: _acceptTerms, onChanged: (v) => setState(() => _acceptTerms = v ?? false)),
              const SizedBox(height: AppSpacing.lg),
              AuthSecondaryButton(label: 'Tạo tài khoản', icon: Icons.person_add_outlined, isLoading: state is AuthLoading, onPressed: _onRegister),
              const SizedBox(height: AppSpacing.lg),
              AuthLinkText(text: 'Đã có tài khoản? ', linkText: 'Đăng nhập', onTap: () => Navigator.pop(context)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return AuthTextField(
      controller: _passwordController,
      label: 'Mật khẩu',
      hint: 'Nhập mật khẩu',
      icon: Icons.lock_outline,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.next,
      suffixIcon: IconButton(
        icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: AppIcons.sm, color: AppColors.textSecondary),
        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
      ),
      validator: (v) => (v == null || v.isEmpty) ? 'Vui lòng nhập mật khẩu' : v.length < 8 ? 'Tối thiểu 8 ký tự' : null,
    );
  }

  Widget _buildConfirmPasswordField() {
    return AuthTextField(
      controller: _confirmPasswordController,
      label: 'Xác nhận mật khẩu',
      hint: 'Nhập lại mật khẩu',
      icon: Icons.lock_outline,
      obscureText: _obscureConfirm,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _onRegister(),
      suffixIcon: IconButton(
        icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: AppIcons.sm, color: AppColors.textSecondary),
        onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
      ),
      validator: (v) => v != _passwordController.text ? 'Mật khẩu xác nhận không khớp' : null,
    );
  }
}
