import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/components/toast_card.dart';
import 'package:delightful_toast/toast/utils/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/navigation/pages/main_scaffold.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../widgets/widgets.dart';
import 'forgot_password_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  // Google Sign-In instance
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: 'YOUR_SERVER_CLIENT_ID.apps.googleusercontent.com', // Replace with actual Server Client ID
  );

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
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onLogin() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthCubit>().login(usernameOrEmail: _emailController.text.trim(), password: _passwordController.text);
  }

  Future<void> _onGoogleLogin() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return; // User cancelled

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken != null && mounted) {
        context.read<AuthCubit>().googleLogin(idToken: idToken);
      }
    } catch (e) {
      if (mounted) {
        _showToast('Đăng nhập Google thất bại: ${e.toString()}', isError: true);
      }
    }
  }

  void _showToast(String message, {bool isError = false}) {
    DelightToastBar(autoDismiss: true, snackbarDuration: const Duration(seconds: 3), position: DelightSnackbarPosition.top, builder: (context) => ToastCard(leading: Icon(isError ? Icons.error_outline : Icons.check_circle_outlined, color: isError ? AppColors.error : AppColors.success, size: 28), title: Text(message, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)))).show(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            _showToast('Đăng nhập thành công!');
            Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MainScaffold()));
          } else if (state is AuthFailure) {
            _showToast(state.message, isError: true);
          }
        },
        builder: (context, state) {
          return AuthGradientBackground(
            colors: AuthGradientBackground.loginGradient,
            stops: AuthGradientBackground.standardStops,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(position: _slideAnimation, child: Form(key: _formKey, child: _buildContent(context, state))),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, AuthState state) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 40),
        const AuthLogo(),
        const SizedBox(height: AppSpacing.xxxl),
        AuthFormCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AuthTitle(title: 'Chào mừng trở lại!', subtitle: 'Đăng nhập để tiếp tục khám phá'),
              const SizedBox(height: AppSpacing.xl),
              _buildEmailField(),
              const SizedBox(height: AppSpacing.md),
              _buildPasswordField(),
              _buildForgotPassword(context),
              const SizedBox(height: AppSpacing.md),
              AuthPrimaryButton(label: 'Đăng nhập', icon: Icons.login, isLoading: state is AuthLoading, onPressed: _onLogin),
              const SizedBox(height: AppSpacing.lg),
              const _SocialDivider(),
              const SizedBox(height: AppSpacing.lg),
              _buildGoogleButton(state is AuthLoading),
              const SizedBox(height: AppSpacing.xl),
              AuthLinkText(text: 'Chưa có tài khoản? ', linkText: 'Đăng ký ngay', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage()))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return AuthTextField(
      controller: _emailController,
      label: 'Email hoặc tên đăng nhập',
      hint: 'Nhập email hoặc tên đăng nhập',
      icon: Icons.email_outlined,
      textInputAction: TextInputAction.next,
      validator: (value) => (value == null || value.trim().isEmpty) ? 'Vui lòng nhập email hoặc tên đăng nhập' : null,
    );
  }

  Widget _buildPasswordField() {
    return AuthTextField(
      controller: _passwordController,
      label: 'Mật khẩu',
      hint: 'Nhập mật khẩu của bạn',
      icon: Icons.lock_outline,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _onLogin(),
      suffixIcon: IconButton(
        icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: AppIcons.sm, color: AppColors.textSecondary),
        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
      ),
      validator: (value) => (value == null || value.isEmpty) ? 'Vui lòng nhập mật khẩu' : null,
    );
  }

  Widget _buildForgotPassword(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordPage())),
        child: const Text('Quên mật khẩu?', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildGoogleButton(bool isLoading) {
    return AuthSocialButton(
      icon: Icons.g_mobiledata,
      label: 'Đăng nhập với Google',
      onPressed: isLoading ? () {} : _onGoogleLogin,
    );
  }
}

class _SocialDivider extends StatelessWidget {
  const _SocialDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.border)),
        Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md), child: Text('hoặc', style: TextStyle(color: AppColors.textTertiary))),
        const Expanded(child: Divider(color: AppColors.border)),
      ],
    );
  }
}
