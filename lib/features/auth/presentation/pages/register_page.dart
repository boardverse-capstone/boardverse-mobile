import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/navigation/pages/main_scaffold.dart';
import '../../../../core/widgets/app_toast.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../widgets/widgets.dart';
import 'verify_email_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _acceptTerms = false;

  // Theo cùng pattern với `LoginPage` để đảm bảo hành vi đồng nhất:
// web dùng GOOGLE_WEB_CLIENT_ID làm clientId, mobile dùng
// GOOGLE_SERVER_CLIENT_ID làm serverClientId.
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

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
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
      AppToast.showError(
        context,
        null,
        defaultMessage: 'Vui lòng đồng ý với điều khoản sử dụng',
      );
      return;
    }
    context.read<AuthCubit>().register(
          username: _usernameController.text.trim(),
          email: _emailController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          password: _passwordController.text,
        );
  }

  /// Google Sign-In cho đăng ký.
  ///
  /// Tận dụng cùng endpoint backend `/api/auth/google-login`: nếu email
  /// chưa tồn tại → backend tự tạo tài khoản Player mới, nếu đã tồn tại
  /// → đăng nhập luôn. Frontend không phân biệt flow nào — để backend
  /// quyết định.
  Future<void> _onGoogleRegister() async {
    await _googleAuthHelper.signIn(
      context: context,
      onLoadingChanged: (_) {
        // Loading state do AuthCubit quản lý qua `state is AuthLoading`
        // nên không cần local flag ở đây.
      },
      onError: (msg) {
        if (mounted) AppToast.showError(context, msg);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          switch (state) {
            case AuthRegistered():
              // Luồng đăng ký thường: backend trả về token ngay nhưng tài
              // khoản chưa verify email → chuyển sang trang nhập OTP.
              AppToast.showSuccess(context, state.message);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => VerifyEmailPage(
                    email: _emailController.text.trim(),
                  ),
                ),
              );
            case AuthSuccess():
              // Luồng Google: backend tự tạo user (nếu mới) hoặc login
              // (nếu cũ) và trả về token hợp lệ → vào thẳng app.
              AppToast.showSuccess(context, 'Đăng ký với Google thành công!');
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const MainScaffold(),
                ),
              );
            case AuthFailure():
              AppToast.showError(context, state.message);
            default:
              break;
          }
        },
        builder: (context, state) {
          return AuthGradientBackground(
            colors: AuthGradientBackground.registerGradient(context),
            stops: AuthGradientBackground.standardStops,
            child: SafeArea(
              child: Column(
                children: [
                  _buildAppBar(context),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Form(
                            key: _formKey,
                            child: _buildContent(context, state),
                          ),
                        ),
                      ),
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
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
        const AuthTitle(
          title: 'Tạo tài khoản mới',
          subtitle: 'Tham gia cộng đồng yêu board game',
        ),
        const SizedBox(height: AppSpacing.xl),
        AuthFormCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthTextField(
                controller: _usernameController,
                labelText: 'Tên đăng nhập',
                hintText: 'Nhập tên đăng nhập',
                prefixIcon: Icons.person_outline,
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Vui lòng nhập tên đăng nhập';
                  }
                  if (v.trim().length < 3) {
                    return 'Tối thiểu 3 ký tự';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              AuthTextField(
                controller: _emailController,
                labelText: 'Email',
                hintText: 'Nhập địa chỉ email',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Vui lòng nhập email';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$')
                      .hasMatch(v.trim())) {
                    return 'Email không hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              AuthTextField(
                controller: _phoneController,
                labelText: 'Số điện thoại',
                hintText: 'Nhập số điện thoại',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Vui lòng nhập số điện thoại';
                  }
                  if (v.trim().length < 10) {
                    return 'Số điện thoại không hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              AuthPasswordField(
                controller: _passwordController,
                labelText: 'Mật khẩu',
                hintText: 'Nhập mật khẩu',
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Vui lòng nhập mật khẩu';
                  }
                  if (v.length < 8) {
                    return 'Tối thiểu 8 ký tự';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.xs),
              PasswordStrengthIndicator(password: _passwordController.text),
              const SizedBox(height: AppSpacing.md),
              AuthPasswordField(
                controller: _confirmPasswordController,
                labelText: 'Xác nhận mật khẩu',
                hintText: 'Nhập lại mật khẩu',
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _onRegister(),
                validator: (v) {
                  if (v != _passwordController.text) {
                    return 'Mật khẩu xác nhận không khớp';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              TermsCheckbox(
                value: _acceptTerms,
                onChanged: (v) =>
                    setState(() => _acceptTerms = v ?? false),
              ),
              const SizedBox(height: AppSpacing.lg),
              AuthSecondaryButton(
                label: 'Tạo tài khoản',
                icon: Icons.person_add_outlined,
                isLoading: state is AuthLoading,
                onPressed: _onRegister,
              ),
              const SizedBox(height: AppSpacing.lg),
              _SocialDivider(),
              const SizedBox(height: AppSpacing.lg),
              AuthSocialButton(
                icon: Icons.g_mobiledata,
                label: 'Đăng ký với Google',
                onPressed:
                    state is AuthLoading ? () {} : _onGoogleRegister,
              ),
              const SizedBox(height: AppSpacing.lg),
              AuthLinkText(
                text: 'Đã có tài khoản? ',
                linkText: 'Đăng nhập',
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Divider "hoặc" giữa form đăng ký và nút Google.
///
/// Đặt ở cuối file để cô lập — chỉ `RegisterPage` dùng. `LoginPage` có bản
/// riêng để tránh phụ thuộc ngược.
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
