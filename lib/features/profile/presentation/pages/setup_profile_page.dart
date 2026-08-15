import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/utils/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:boardverse/core/theme/app_colors.dart';
import 'package:boardverse/core/theme/app_shimmer.dart';
import 'package:boardverse/core/theme/app_spacing.dart';
import 'package:boardverse/core/widgets/app_toast_card.dart';
import 'package:boardverse/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:boardverse/features/profile/presentation/cubit/profile_cubit.dart';

/// Full-screen page yêu cầu player điền thông tin cá nhân cơ bản
/// trước khi sử dụng được các chức năng khác của app.
///
/// Được dùng như một "gate" ở cấp MainScaffold — khi
/// [ProfileEntity.hasProfile] = false, page này sẽ che toàn bộ UI
/// chính cho tới khi player nhấn "Hoàn tất hồ sơ" và backend trả về
/// profile với `hasProfile: true`.
///
/// Thiết kế:
///
/// - Nền gradient cyan→dark thay vì cam đậm như auth pages, để tách
///   biệt rõ "đây không phải flow đăng nhập" mà là "sau khi đã login,
///   cần bổ sung thông tin".
/// - Form card trắng/đen-tối, border mảnh, shadow nhẹ — Material 3
///   clean thay vì neo-brutalism để dễ đọc hơn trên mobile.
/// - Indicator 3 dot cho các required fields, mỗi dot sáng dần khi
///   field được điền — visualise progress vào từng field.
/// - Logout ở góc phải AppBar (hiếm khi cần nhưng quan trọng khi
///   account bị nhầm).
class SetupProfilePage extends StatefulWidget {
  const SetupProfilePage({super.key});

  @override
  State<SetupProfilePage> createState() => _SetupProfilePageState();
}

class _SetupProfilePageState extends State<SetupProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _bioController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _bioController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dobController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'CHỌN NGÀY SINH',
      cancelText: 'Hủy',
      confirmText: 'Xác nhận',
    );
    if (picked != null && mounted) {
      // BR-AUTH-11: dob >= 13 tuổi.
      final age = _calculateAge(picked);
      if (age < 13) {
        _showToast('Bạn phải đủ 13 tuổi để sử dụng BoardVerse');
        return;
      }
      _dobController.text =
          '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      // Re-validate để clear lỗi "Chọn ngày sinh" nếu trước đó
      // form đang hiển thị.
      _formKey.currentState?.validate();
    }
  }

  int _calculateAge(DateTime dob) {
    final now = DateTime.now();
    var age = now.year - dob.year;
    final birthdayThisYear = DateTime(now.year, dob.month, dob.day);
    if (now.isBefore(birthdayThisYear)) age--;
    return age;
  }

  void _onSubmit() {
    if (!_formKey.currentState!.validate()) return;
    // Đọc cubit qua closure để check state hiện tại - chống
    // double-tap khi user nhấn nút 2 lần trong cùng frame (giữa
    // các lần rebuild của BlocBuilder).
    final cubit = context.read<ProfileCubit>();
    if (cubit.state is ProfileLoading) return;
    cubit.createProfile(
      bio: _bioController.text.trim(),
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      dateOfBirth: _dobController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
    );
  }

  void _showToast(String message, {bool isError = false}) {
    DelightToastBar(
      autoDismiss: true,
      snackbarDuration: const Duration(seconds: 3),
      position: DelightSnackbarPosition.top,
      builder: (context) => AppToastCard(
        leading: Icon(
          isError ? Icons.error_outline : Icons.check_circle_outlined,
          color: isError
              ? Theme.of(context).colorScheme.error
              : AppColors.success,
          size: 28,
        ),
        title: Text(
          message,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    ).show(context);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProfileCubit, dynamic>(
      listenWhen: (prev, curr) =>
          curr is ProfileFailure ||
          curr is ProfileDeleted ||
          (curr is ProfileLoaded && curr.profile.hasProfile),
      listener: (context, state) {
        if (state is ProfileFailure) {
          _showToast(state.message, isError: true);
        } else if (state is ProfileDeleted) {
          _showToast('Hồ sơ đã được vô hiệu hóa.');
        }
        // Success: gate tự đóng vì BlocBuilder bên ngoài sẽ thấy
        // `hasProfile = true` → render MainScaffold bình thường.
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF00BCD4),
                Color(0xFF0097A7),
                Color(0xFF121212),
              ],
              stops: [0.0, 0.45, 1.0],
            ),
          ),
          child: SafeArea(
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: _SetupAppBar(
                      onLogout: () async {
                        final authCubit = context.read<AuthCubit>();
                        final nav = Navigator.of(context);
                        await nav.maybePop();
                        if (!mounted) return;
                        await authCubit.logout();
                      },
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: BlocBuilder<ProfileCubit, dynamic>(
                        builder: (context, state) {
                          final isLoading = state is ProfileLoading;
                          return _SetupHeader(isLoading: isLoading);
                        },
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: ListenableBuilder(
                        listenable: Listenable.merge([
                          _firstNameController,
                          _lastNameController,
                          _dobController,
                        ]),
                        builder: (context, _) {
                          return _RequiredFieldsIndicator(
                            firstName: _firstNameController.text,
                            lastName: _lastNameController.text,
                            dob: _dobController.text,
                          );
                        },
                      ),
                    ),
                  ),
                  const SliverPadding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: _SetupCardTitle(),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.lg,
                      AppSpacing.xxl,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: BlocBuilder<ProfileCubit, dynamic>(
                        builder: (context, state) {
                          final isLoading = state is ProfileLoading;
                          return Stack(
                            children: [
                              _SetupFormCard(
                                formKey: _formKey,
                                bioController: _bioController,
                                firstNameController: _firstNameController,
                                lastNameController: _lastNameController,
                                dobController: _dobController,
                                phoneController: _phoneController,
                                onPickDate: _selectDate,
                              ),
                              if (isLoading)
                                const Positioned.fill(
                                  child: IgnorePointer(
                                    child: _ShimmerFormOverlay(),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.xl,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: _SetupSubmitButton(onPressed: _onSubmit),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AppBar
// ─────────────────────────────────────────────────────────────────────────────

class _SetupAppBar extends StatelessWidget {
  const _SetupAppBar({required this.onLogout});

  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.casino_rounded,
                  color: AppColors.white,
                  size: 18,
                ),
                SizedBox(width: 6),
                Text(
                  'BOARDVERSE',
                  style: TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: onLogout,
            icon: const Icon(
              Icons.logout_rounded,
              size: 18,
              color: AppColors.white,
            ),
            label: const Text(
              'Đăng xuất',
              style: TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _SetupHeader extends StatelessWidget {
  const _SetupHeader({required this.isLoading});

  /// `true` khi form đang submit - đổi subtitle từ hướng dẫn
  /// sang thông báo "đang xử lý" để user yên tâm.
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chào mừng bạn!',
            style: TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w900,
              fontSize: 30,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: isLoading
                ? Row(
                    key: const ValueKey('loading'),
                    children: [
                      const SizedBox(
                        height: 14,
                        width: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation(AppColors.white),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Đang lưu hồ sơ của bạn... Vui lòng không đóng ứng dụng.',
                          style: TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  )
                : const Text(
                    'Hãy hoàn tất hồ sơ để bắt đầu khám phá cộng đồng board game.',
                    key: ValueKey('idle'),
                    style: TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Required fields indicator (3 dots)
// ─────────────────────────────────────────────────────────────────────────────

class _RequiredFieldsIndicator extends StatelessWidget {
  const _RequiredFieldsIndicator({
    required this.firstName,
    required this.lastName,
    required this.dob,
  });

  final String firstName;
  final String lastName;
  final String dob;

  @override
  Widget build(BuildContext context) {
    final completedCount = [
      firstName,
      lastName,
      dob,
    ].where((s) => s.trim().isNotEmpty).length;

    return Row(
      children: [
        const Icon(
          Icons.checklist_rounded,
          size: 14,
          color: AppColors.white,
        ),
        const SizedBox(width: 6),
        Text(
          'Thông tin bắt buộc',
          style: TextStyle(
            color: AppColors.white.withValues(alpha: 0.85),
            fontWeight: FontWeight.w700,
            fontSize: 12,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(width: 10),
        for (var i = 0; i < 3; i++)
          Padding(
            padding: EdgeInsets.only(right: i < 2 ? 6 : 0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              width: i < completedCount ? 22 : 10,
              height: 10,
              decoration: BoxDecoration(
                color: i < completedCount
                    ? AppColors.accent
                    : AppColors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
        const Spacer(),
        Text(
          '$completedCount/3',
          style: TextStyle(
            color: AppColors.white.withValues(alpha: 0.85),
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card title
// ─────────────────────────────────────────────────────────────────────────────

class _SetupCardTitle extends StatelessWidget {
  const _SetupCardTitle();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: AppSpacing.lg),
      child: Text(
        'Thông tin cá nhân',
        style: TextStyle(
          color: AppColors.white,
          fontWeight: FontWeight.w800,
          fontSize: 18,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Form card
// ─────────────────────────────────────────────────────────────────────────────

class _SetupFormCard extends StatelessWidget {
  const _SetupFormCard({
    required this.formKey,
    required this.bioController,
    required this.firstNameController,
    required this.lastNameController,
    required this.dobController,
    required this.phoneController,
    required this.onPickDate,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController bioController;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController dobController;
  final TextEditingController phoneController;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceContainerDark : AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionLabel(
              label: 'Họ và tên',
              required: true,
              isDark: isDark,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _SetupField(
                    controller: firstNameController,
                    label: 'Tên',
                    hint: 'An',
                    icon: Icons.person_outline,
                    textInputAction: TextInputAction.next,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Nhập tên'
                        : null,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _SetupField(
                    controller: lastNameController,
                    label: 'Họ',
                    hint: 'Nguyễn',
                    icon: Icons.person_outline,
                    textInputAction: TextInputAction.next,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Nhập họ'
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _SectionLabel(
              label: 'Ngày sinh',
              required: true,
              isDark: isDark,
            ),
            const SizedBox(height: AppSpacing.sm),
            _SetupField(
              controller: dobController,
              label: 'Ngày sinh',
              hint: 'Chọn ngày sinh',
              icon: Icons.cake_outlined,
              readOnly: true,
              onTap: onPickDate,
              suffixIcon: Icons.calendar_today_rounded,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Chọn ngày sinh'
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            _SectionLabel(
              label: 'Số điện thoại',
              required: false,
              helperText: 'Dùng để xác thực & liên hệ nhanh',
              isDark: isDark,
            ),
            const SizedBox(height: AppSpacing.sm),
            _SetupField(
              controller: phoneController,
              label: 'Số điện thoại',
              hint: 'VD: 0912345678',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSpacing.md),
            _SectionLabel(
              label: 'Giới thiệu',
              required: false,
              helperText: 'Tối đa 1000 ký tự',
              isDark: isDark,
            ),
            const SizedBox(height: AppSpacing.sm),
            _SetupField(
              controller: bioController,
              label: 'Mô tả về bạn',
              hint: 'Sở thích board game, phong cách chơi...',
              icon: Icons.edit_note_rounded,
              maxLines: 3,
              maxLength: 1000,
              textInputAction: TextInputAction.newline,
              validator: (v) {
                if (v != null && v.length > 1000) {
                  return 'Mô tả không quá 1000 ký tự';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Thông tin chỉ hiển thị cho người chơi khác khi bạn cho phép.',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section label
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.label,
    required this.required,
    required this.isDark,
    this.helperText,
  });

  final String label;
  final bool required;
  final bool isDark;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    final color = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 13,
            letterSpacing: 0.2,
          ),
        ),
        if (required) ...[
          const SizedBox(width: 4),
          const Text(
            '*',
            style: TextStyle(
              color: AppColors.error,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
        if (helperText != null) ...[
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              helperText!,
              style: TextStyle(
                color: isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiary,
                fontWeight: FontWeight.w500,
                fontSize: 11,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Setup field
// ─────────────────────────────────────────────────────────────────────────────

class _SetupField extends StatelessWidget {
  const _SetupField({
    required this.controller,
    required this.label,
    this.hint,
    this.icon,
    this.suffixIcon,
    this.readOnly = false,
    this.onTap,
    this.maxLines = 1,
    this.maxLength,
    this.keyboardType,
    this.textInputAction,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? icon;
  final IconData? suffixIcon;
  final bool readOnly;
  final VoidCallback? onTap;
  final int maxLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    final fillColor = isDark
        ? AppColors.surfaceElevatedDark
        : AppColors.surfaceVariant;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      style: TextStyle(
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        prefixIcon: icon != null
            ? Icon(
                icon,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              )
            : null,
        suffixIcon: suffixIcon != null
            ? Icon(
                suffixIcon,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              )
            : null,
        filled: true,
        fillColor: fillColor,
        counterText: '',
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 2,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Submit button
// ─────────────────────────────────────────────────────────────────────────────

class _SetupSubmitButton extends StatelessWidget {
  const _SetupSubmitButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, dynamic>(
      builder: (context, state) {
        final isLoading = state is ProfileLoading;
        return SizedBox(
          width: double.infinity,
          height: 56,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  AppColors.accent,
                  AppColors.warning,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isLoading ? null : onPressed,
                borderRadius: BorderRadius.circular(16),
                child: Center(
                  child: isLoading
                      ? const _ShimmerLoadingLabel()
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Hoàn tất hồ sơ',
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: AppColors.white,
                              size: 20,
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Loading label (pulse + shimmer)
// ─────────────────────────────────────────────────────────────────────────────

class _ShimmerLoadingLabel extends StatefulWidget {
  const _ShimmerLoadingLabel();

  @override
  State<_ShimmerLoadingLabel> createState() => _ShimmerLoadingLabelState();
}

class _ShimmerLoadingLabelState extends State<_ShimmerLoadingLabel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final t = _pulseController.value;
        return Opacity(
          opacity: 0.7 + (0.3 * t),
          child: Transform.scale(
            scale: 0.97 + (0.03 * t),
            child: child,
          ),
        );
      },
      child: AppShimmer.shimmer(
        context: context,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Đang tạo hồ sơ',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              '...',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shimmer form overlay
// ─────────────────────────────────────────────────────────────────────────────

class _ShimmerFormOverlay extends StatelessWidget {
  const _ShimmerFormOverlay();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: ColoredBox(
        color: AppColors.black.withValues(alpha: 0.04),
        child: AppShimmer.shimmer(
          context: context,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppShimmer.box(
                  context: context,
                  height: 56,
                  borderRadius: 12,
                ),
                const SizedBox(height: AppSpacing.md),
                AppShimmer.box(
                  context: context,
                  height: 56,
                  borderRadius: 12,
                ),
                const SizedBox(height: AppSpacing.md),
                AppShimmer.box(
                  context: context,
                  height: 56,
                  borderRadius: 12,
                ),
                const SizedBox(height: AppSpacing.md),
                AppShimmer.box(
                  context: context,
                  height: 56,
                  borderRadius: 12,
                ),
                const SizedBox(height: AppSpacing.md),
                AppShimmer.box(
                  context: context,
                  height: 96,
                  borderRadius: 12,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}