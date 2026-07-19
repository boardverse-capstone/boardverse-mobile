import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/components/toast_card.dart';
import 'package:delightful_toast/toast/utils/enums.dart';

import 'package:image_picker/image_picker.dart';

import 'package:boardverse_mobile/core/di/injection.dart';
import 'package:boardverse_mobile/core/navigation/pages/leaderboard_page.dart';
import 'package:boardverse_mobile/core/services/cloudinary/cloudinary_service.dart';
import 'package:boardverse_mobile/core/theme/app_colors.dart';
import 'package:boardverse_mobile/core/theme/app_icons.dart';
import 'package:boardverse_mobile/core/theme/app_radius.dart';
import 'package:boardverse_mobile/core/theme/app_spacing.dart';
import 'package:boardverse_mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:boardverse_mobile/features/auth/presentation/pages/login_page.dart';
import 'package:boardverse_mobile/features/profile/domain/entities/profile_entity.dart';
import 'package:boardverse_mobile/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:boardverse_mobile/features/profile/presentation/cubit/profile_state.dart';
import 'package:boardverse_mobile/features/profile/presentation/widgets/avatar_header.dart';
import 'package:boardverse_mobile/features/profile/presentation/widgets/edit_profile_sheet.dart';
import 'package:boardverse_mobile/features/profile/presentation/widgets/error_state.dart';
import 'package:boardverse_mobile/features/profile/presentation/widgets/loading_skeleton.dart';
import 'package:boardverse_mobile/features/profile/presentation/widgets/location_card.dart';
import 'package:boardverse_mobile/features/profile/presentation/widgets/personal_info_card.dart';
import 'package:boardverse_mobile/features/profile/presentation/widgets/setup_profile_form.dart';
import 'package:boardverse_mobile/features/profile/presentation/widgets/stat_card.dart';
import 'package:boardverse_mobile/features/settings/presentation/widgets/theme_switcher_sheet.dart';

/// Trang chính của feature profile.
///
/// Logic bloc (controllers, initState, dispose, callbacks) giữ nguyên 100% so với
/// phiên bản trước. Phần UI đã được tách ra các widget riêng trong `./widgets/`
/// để dễ đọc, dễ test, và đồng bộ với design system.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _formKey = GlobalKey<FormState>();
  final _bioController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<ProfileCubit>().getProfile();
    });
  }

  @override
  void dispose() {
    _bioController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dobController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // ─── Toast / Logout ───────────────────────────────────────────────────

  void _showToast(String message, {bool isError = false}) {
    DelightToastBar(
      autoDismiss: true,
      snackbarDuration: const Duration(seconds: 3),
      position: DelightSnackbarPosition.top,
      builder: (context) => ToastCard(
        leading: Icon(
          isError ? Icons.error_outline : Icons.check,
          color: isError ? AppColors.error : AppColors.success,
          size: 24,
        ),
        title: Text(
          message,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    ).show(context);
  }

  void _onLogout() {
    context.read<AuthCubit>().logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  // ─── Form actions ──────────────────────────────────────────────────────

  void _onCreateProfile() {
    if (!_formKey.currentState!.validate()) return;

    context.read<ProfileCubit>().createProfile(
      bio: _bioController.text.trim(),
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      dateOfBirth: _dobController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
    );
  }

  void _onUpdateProfile() {
    if (!_formKey.currentState!.validate()) return;

    context.read<ProfileCubit>().updateProfile(
      bio: _bioController.text.trim(),
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      dateOfBirth: _dobController.text.trim(),
    );
  }

  void _prefillForm(ProfileEntity profile) {
    _bioController.text = profile.bio ?? '';
    _firstNameController.text = profile.firstName ?? '';
    _lastNameController.text = profile.lastName ?? '';
    _dobController.text = profile.dateOfBirth ?? '';
    _phoneController.text = profile.phoneNumber ?? '';
  }

  // ─── Date picker ───────────────────────────────────────────────────────

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dobController.text =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  // ─── Bottom sheets / navigation helpers ────────────────────────────────

  void _showEditProfileSheet(BuildContext context, ProfileEntity profile) {
    _prefillForm(profile);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => EditProfileSheet(
        formKey: _formKey,
        bioController: _bioController,
        firstNameController: _firstNameController,
        lastNameController: _lastNameController,
        dobController: _dobController,
        onPickDate: () => _selectDate(bottomSheetContext),
        onClose: () => Navigator.of(bottomSheetContext).pop(),
        onSubmit: () {
          Navigator.of(bottomSheetContext).pop();
          _onUpdateProfile();
        },
      ),
    );
  }

  void _updateLocationGps(BuildContext context) {
    context.read<ProfileCubit>().updateLocation(
      latitude: 10.7769,
      longitude: 106.7008,
      source: 0, // Gps
    );
    _showToast('Đang cập nhật vị trí...');
  }

  void _openLeaderboard() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LeaderboardPage()));
  }

  void _showComingSoonToast(String feature) {
    _showToast('$feature sắp ra mắt');
  }

  void _openThemeSwitcher() {
    ThemeSwitcherSheet.show(context);
  }

  // ─── Avatar upload ────────────────────────────────────────────────────

  /// Pick an image from the gallery → upload to Cloudinary → save URL on
  /// the backend via [ProfileCubit.updateAvatar].
  ///
  /// Disabled (with a hint toast) when Cloudinary is not configured.
  Future<void> _changeAvatar() async {
    if (!sl.isRegistered<CloudinaryService>()) {
      _showToast('Cloudinary chưa được cấu hình.', isError: true);
      return;
    }

    final picker = ImagePicker();
    final XFile? picked;
    try {
      picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1024,
      );
    } catch (e) {
      _showToast('Không thể mở thư viện ảnh: $e', isError: true);
      return;
    }

    if (picked == null) return;
    if (!mounted) return;

    _showToast('Đang tải ảnh lên...');

    try {
      final url = await sl<CloudinaryService>().uploadImage(
        file: File(picked.path),
        folder: 'boardverse/avatars',
      );
      if (!mounted) return;
      context.read<ProfileCubit>().updateAvatar(url);
    } on Object catch (e) {
      if (!mounted) return;
      _showToast('Upload thất bại: $e', isError: true);
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BoardVerse'),
        actions: [
          IconButton(
            icon: const Icon(AppIcons.logout),
            tooltip: 'Đăng xuất',
            onPressed: _onLogout,
          ),
        ],
      ),
      body: BlocConsumer<ProfileCubit, ProfileState>(
        listener: _onStateChanged,
        builder: _onStateBuilt,
      ),
    );
  }

  void _onStateChanged(BuildContext context, ProfileState state) {
    if (state is ProfileLoaded) {
      _showToast('Đã tải thông tin cá nhân!');
      // Load location sau khi profile loaded thành công
      if (state.profile.hasProfile) {
        final cubit = context.read<ProfileCubit>();
        Future.microtask(() {
          if (!mounted) return;
          cubit.getLocation();
        });
      }
    } else if (state is ProfileFailure) {
      _showToast(state.message, isError: true);
    } else if (state is ProfileDeleted) {
      _showToast('Hồ sơ đã được vô hiệu hóa.');
      _onLogout();
    }
  }

  Widget _onStateBuilt(BuildContext context, ProfileState state) {
    if (state is ProfileLoading) {
      return const ProfileLoadingSkeleton();
    }

    if (state is ProfileLoaded) {
      final profile = state.profile;
      if (!profile.hasProfile) {
        return SetupProfileForm(
          formKey: _formKey,
          bioController: _bioController,
          firstNameController: _firstNameController,
          lastNameController: _lastNameController,
          dobController: _dobController,
          phoneController: _phoneController,
          onPickDate: () => _selectDate(context),
          onSubmit: _onCreateProfile,
        );
      }
      return _buildDashboard(context, profile);
    }

    if (state is ProfileFailure) {
      return ProfileErrorState(
        message: state.message,
        onRetry: () => context.read<ProfileCubit>().getProfile(),
      );
    }

    return const ProfileLoadingSkeleton();
  }

  // ─── Dashboard composition ─────────────────────────────────────────────

  Widget _buildDashboard(BuildContext context, ProfileEntity profile) {
    _prefillForm(profile);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          AvatarHeader(
            profile: profile,
            onAvatarTap: _changeAvatar,
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── ELO & Level stats ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: ProfileStatCard(
                    label: 'ELO RATING',
                    value: '${profile.globalElo}',
                    icon: Icons.emoji_events_outlined,
                    iconColor: AppColors.accent,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: ProfileStatCard(
                    label: 'LEVEL / CẤP ĐỘ',
                    value: '${profile.level}',
                    icon: AppIcons.level,
                    iconColor: AppColors.info,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Personal info ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: PersonalInfoCard(
              profile: profile,
              onEditPressed: () => _showEditProfileSheet(context, profile),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Location ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: BlocBuilder<ProfileCubit, ProfileState>(
              buildWhen: (previous, current) =>
                  current is ProfileLocationLoaded ||
                  current is ProfileLocationDeleted ||
                  (previous is ProfileLocationLoaded && current is ProfileLoaded),
              builder: (context, state) {
                final location = state is ProfileLocationLoaded
                    ? state.location
                    : state is ProfileLoaded
                        ? null
                        : null;
                return LocationCard(
                  location: location,
                  onUpdateGpsPressed: () => _updateLocationGps(context),
                  onDeletePressed: () =>
                      context.read<ProfileCubit>().deleteLocation(),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Quick actions ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: _buildQuickActionsCard(context),
          ),

          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard(BuildContext context) {
    final theme = Theme.of(context);
    final dividerColor = theme.colorScheme.outlineVariant.withValues(
      alpha: 0.6,
    );

    return _ActionsCard(
      dividerColor: dividerColor,
      children: [
        _ActionTile(
          icon: Icons.leaderboard_outlined,
          title: 'Xếp hạng',
          subtitle: 'Xem bảng xếp hạng ELO & Karma của cộng đồng',
          onTap: _openLeaderboard,
        ),
        _ActionDivider(color: dividerColor),
        _ActionTile(
          icon: Icons.history,
          title: 'Lịch sử đấu',
          subtitle: 'Theo dõi các trận đã chơi gần đây',
          onTap: () => _showComingSoonToast('Lịch sử đấu'),
        ),
        _ActionDivider(color: dividerColor),
        _ActionTile(
          icon: AppIcons.settings,
          title: 'Cài đặt giao diện',
          subtitle: 'Chuyển đổi chế độ Sáng / Tối / Theo hệ thống',
          onTap: _openThemeSwitcher,
        ),
      ],
    );
  }
}

// ─── Helpers ────────────────────────────────────────────────────────────

class _ActionsCard extends StatelessWidget {
  const _ActionsCard({required this.children, required this.dividerColor});
  final List<Widget> children;
  final Color dividerColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.radiusMd),
        border: Border.all(color: dividerColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _ActionDivider extends StatelessWidget {
  const _ActionDivider({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: AppSpacing.md,
      endIndent: AppSpacing.md,
      color: color,
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      onTap: onTap,
      tileColor: Colors.transparent,
      selectedTileColor: theme.colorScheme.primary.withValues(alpha: 0.08),
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(title, style: theme.textTheme.bodyLarge),
      subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
      trailing: const Icon(AppIcons.forward, size: AppIcons.sm),
    );
  }
}
