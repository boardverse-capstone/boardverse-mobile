import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/navigation/pages/main_scaffold.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/game_loading_screen.dart';
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
  bool _isLoggingIn = false;

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? dotenv.env['GOOGLE_WEB_CLIENT_ID'] : null,
    serverClientId: _serverClientId,
  );

  /// Trả về serverClientId dùng cho cả Android & iOS.
  /// - Web: null (không cần)
  /// - Android/iOS: GOOGLE_SERVER_CLIENT_ID (Web OAuth Client ID)
  ///
  /// Lý do dùng Web Client ID cho mobile:
  /// `google_sign_in` Flutter plugin yêu cầu Web OAuth Client ID làm
  /// serverClientId để Firebase Auth xác thực idToken phía backend.
  static String? get _serverClientId {
    if (kIsWeb) return null;
    return dotenv.env['GOOGLE_SERVER_CLIENT_ID'];
  }

  late final GoogleAuthHelper _googleAuthHelper = GoogleAuthHelper(
    googleSignIn: _googleSignIn,
  );

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
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
    setState(() => _isLoggingIn = true);
    context.read<AuthCubit>().login(
          usernameOrEmail: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  Future<void> _onGoogleLogin() async {
    await _googleAuthHelper.signIn(
      context: context,
      onLoadingChanged: (loading) {
        if (mounted) setState(() => _isLoggingIn = loading);
      },
      onError: (msg) {
        if (mounted) AppToast.showError(context, msg);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        switch (state) {
          case AuthSuccess():
            AppToast.showSuccess(context, 'Đăng nhập thành công!');
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const MainScaffold()),
            );
          case AuthFailure():
            // Bắt message từ backend (vd: "Tên đăng nhập/email hoặc mật
            // khẩu không đúng..."). Nếu message rỗng → AppToast tự fallback.
            AppToast.showError(context, state.message);
            setState(() => _isLoggingIn = false);
          case AuthInitial():
            setState(() => _isLoggingIn = false);
          default:
            break;
        }
      },
      builder: (context, state) {
        if (_isLoggingIn) {
          return const GameLoadingScreen(message: 'Đang đăng nhập...');
        }

        return Scaffold(
          body: AuthGradientBackground(
            colors: AuthGradientBackground.loginGradient(context),
            stops: AuthGradientBackground.standardStops,
            child: SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xl,
                ),
                // Drag-to-dismiss the keyboard so the user can scroll
                // the form without first tapping outside a field.
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Form(
                      key: _formKey,
                      child: _buildContent(context),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: AppSpacing.xxxl),
        const AuthLogo(),
        const SizedBox(height: AppSpacing.xl),
        AuthFormCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthTitle(
                title: 'Chào mừng trở lại!',
                subtitle: 'Đăng nhập để tiếp tục khám phá',
                color: Theme.of(context).colorScheme.onSurface,
              ),
              const SizedBox(height: AppSpacing.xl),
              AuthTextField(
                controller: _emailController,
                labelText: 'Email hoặc tên đăng nhập',
                hintText: 'Nhập email hoặc tên đăng nhập',
                prefixIcon: Icons.email_outlined,
                textInputAction: TextInputAction.next,
                validator: (value) =>
                    (value == null || value.trim().isEmpty)
                        ? 'Vui lòng nhập email hoặc tên đăng nhập'
                        : null,
              ),
              const SizedBox(height: AppSpacing.md),
              AuthPasswordField(
                controller: _passwordController,
                labelText: 'Mật khẩu',
                hintText: 'Nhập mật khẩu của bạn',
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _onLogin(),
                validator: (value) =>
                    (value == null || value.isEmpty)
                        ? 'Vui lòng nhập mật khẩu'
                        : null,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ForgotPasswordPage(),
                    ),
                  ),
                  child: Text(
                    'Quên mật khẩu?',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              AuthPrimaryButton(
                label: 'Đăng nhập',
                icon: Icons.login,
                onPressed: _onLogin,
              ),
              const SizedBox(height: AppSpacing.lg),
              const _SocialDivider(),
              const SizedBox(height: AppSpacing.lg),
              AuthSocialButton(
                icon: Icons.g_mobiledata,
                label: 'Đăng nhập với Google',
                onPressed: _onGoogleLogin,
              ),
              const SizedBox(height: AppSpacing.xl),
              AuthLinkText(
                text: 'Chưa có tài khoản? ',
                linkText: 'Đăng ký ngay',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterPage()),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SocialDivider extends StatelessWidget {
  const _SocialDivider();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Divider(color: theme.colorScheme.outlineVariant),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            'hoặc',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Divider(color: theme.colorScheme.outlineVariant),
        ),
      ],
    );
  }
}
