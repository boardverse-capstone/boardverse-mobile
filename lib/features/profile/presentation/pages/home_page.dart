import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/components/toast_card.dart';
import 'package:delightful_toast/toast/utils/enums.dart';

import 'package:boardverse_mobile/core/navigation/pages/leaderboard_page.dart';
import 'package:boardverse_mobile/core/theme/app_icons.dart';
import 'package:boardverse_mobile/core/theme/app_spacing.dart';
import 'package:boardverse_mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:boardverse_mobile/features/auth/presentation/pages/login_page.dart';
import 'package:boardverse_mobile/features/friend_management/presentation/pages/friends_page.dart';
import 'package:boardverse_mobile/features/profile/domain/entities/karma_history_entity.dart';
import 'package:boardverse_mobile/features/profile/domain/entities/player_location_entity.dart';
import 'package:boardverse_mobile/features/profile/domain/entities/profile_entity.dart';
import 'package:boardverse_mobile/features/profile/presentation/controllers/avatar_upload_controller.dart';
import 'package:boardverse_mobile/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:boardverse_mobile/features/profile/presentation/widgets/edit_profile_sheet.dart';
import 'package:boardverse_mobile/features/profile/presentation/widgets/error_state.dart';
import 'package:boardverse_mobile/features/profile/presentation/widgets/loading_skeleton.dart';
import 'package:boardverse_mobile/features/profile/presentation/widgets/location_card.dart';
import 'package:boardverse_mobile/features/profile/presentation/widgets/profile_header_card.dart';
import 'package:boardverse_mobile/features/profile/presentation/widgets/profile_stats_row.dart';
import 'package:boardverse_mobile/features/profile/presentation/widgets/quick_actions_card.dart';
import 'package:boardverse_mobile/features/profile/presentation/widgets/setup_profile_form.dart';
import 'package:boardverse_mobile/features/settings/presentation/pages/system_settings_page.dart';

/// Trang chính của feature profile.
///
/// Orchestration layer — chỉ quản lý state và truyền callbacks xuống
/// sub-shells. UI dashboard đã tách hoàn toàn ra widgets.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const double _horizontalPadding = AppSpacing.lg;

  // ─── Form controllers ────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _bioController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _phoneController = TextEditingController();

  final AvatarUploadController _avatarUpload = AvatarUploadController();

  // ─── Cached supplementary data ─────────────────────────────────────────
  /// Chỉ load location 1 lần sau khi profile đã loaded.
  bool _locationLoaded = false;

  /// Cache gần nhất để supplementary states không rơi về loading skeleton.
  ProfileEntity? _lastProfile;
  PlayerLocationEntity? _lastLocation;
  KarmaHistoryEntity? _lastKarma;

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

  // ─── State handlers ────────────────────────────────────────────────────

  void _onStateChanged(BuildContext context, ProfileState state) {
    switch (state) {
      case ProfileLoaded():
        _lastProfile = state.profile;
        if (state.location != null) _lastLocation = state.location;
        if (state.karma != null) _lastKarma = state.karma;
        if (!_locationLoaded && state.profile.hasProfile) {
          _locationLoaded = true;
          final cubit = context.read<ProfileCubit>();
          Future.microtask(() {
            if (!mounted) return;
            cubit.getLocation();
          });
        }
        if (state.supplementaryError != null) {
          _showToast(state.supplementaryError!, isError: true);
        }

      case ProfileLocationLoaded():
        _lastLocation = state.location;

      case ProfileLocationDeleted():
        _lastLocation = null;

      case ProfileKarmaLoaded():
        _lastKarma = state.karma;

      case ProfileFailure():
        _showToast(state.message, isError: true);

      case ProfileDeleted():
        _showToast('Hồ sơ đã được vô hiệu hóa.');
        _logout();

      default:
        break;
    }
  }

  // ─── State → UI builder ────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileCubit, ProfileState>(
      listener: _onStateChanged,
      builder: _build,
    );
  }

  Widget _build(BuildContext context, ProfileState state) {
    return switch (state) {
      ProfileLoading() => const _LoadingShell(),
      ProfileFailure() => Scaffold(
          appBar: AppBar(title: const Text('BoardVerse')),
          body: ProfileErrorState(
            message: state.message,
            onRetry: () => context.read<ProfileCubit>().getProfile(),
          ),
        ),
      ProfileLoaded() when !state.profile.hasProfile => _buildSetupShell(),
      ProfileLoaded() => _buildDashboardShell(
          profile: state.profile,
          location: state.location ?? _lastLocation,
          karma: state.karma ?? _lastKarma,
        ),
      ProfileNotFound() => _buildSetupShell(),
      // Supplementary-only states: re-render dashboard với cache.
      ProfileLocationLoaded() ||
      ProfileLocationDeleted() ||
      ProfileKarmaLoaded() ||
      ProfileInitial()
          when _lastProfile != null =>
        _buildDashboardShell(
          profile: _lastProfile!,
          location: _lastLocation,
          karma: _lastKarma,
        ),
      _ => const _LoadingShell(),
    };
  }

  // ─── Shell factories (DRY — tránh trùng lặp constructor params) ────────

  Widget _buildSetupShell() => _SetupShell(
        formKey: _formKey,
        bioController: _bioController,
        firstNameController: _firstNameController,
        lastNameController: _lastNameController,
        dobController: _dobController,
        phoneController: _phoneController,
        onPickDate: _selectDate,
        onSubmit: _onCreateProfile,
      );

  Widget _buildDashboardShell({
    required ProfileEntity profile,
    PlayerLocationEntity? location,
    KarmaHistoryEntity? karma,
  }) =>
      _DashboardShell(
        profile: profile,
        location: location,
        karma: karma,
        horizontalPadding: _horizontalPadding,
        onAvatarTap: _changeAvatar,
        onEditPressed: () => _showEditProfileSheet(profile),
        onUpdateGpsPressed: _updateLocationGps,
        onDeleteLocation: () => context.read<ProfileCubit>().deleteLocation(),
        onOpenLeaderboard: _openLeaderboard,
        onOpenFriends: _openFriendsPage,
        onOpenHistory: () => _showToast('Lịch sử đấu sắp ra mắt'),
        onOpenSettings: _openSystemSettings,
        onLogout: _logout,
      );

  // ─── Shell components ────────────────────────────────────────────────────

  // ─── User actions ───────────────────────────────────────────────────────

  void _logout() {
    context.read<AuthCubit>().logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Future<void> _changeAvatar() async {
    if (!_avatarUpload.isCloudinaryConfigured) {
      _showToast('Cloudinary chưa được cấu hình.', isError: true);
      return;
    }

    try {
      final result = await _avatarUpload.runWithFeedback(context);
      if (!mounted || result == null) return;
      context.read<ProfileCubit>().updateAvatar(result.url);
    } on AvatarUploadException catch (e) {
      if (!mounted) return;
      _showToast(e.message, isError: true);
    }
  }

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

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
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

  void _showEditProfileSheet(ProfileEntity profile) {
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
        onPickDate: () => _selectDate(),
        onClose: () => Navigator.of(bottomSheetContext).pop(),
        onSubmit: () {
          Navigator.of(bottomSheetContext).pop();
          _onUpdateProfile();
        },
      ),
    );
  }

  void _updateLocationGps() {
    context.read<ProfileCubit>().updateLocation(
          latitude: 10.7769,
          longitude: 106.7008,
          source: 0,
        );
    _showToast('Đang cập nhật vị trí...');
  }

  // ─── Navigation ─────────────────────────────────────────────────────────

  void _openLeaderboard() => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LeaderboardPage()),
      );

  void _openFriendsPage() => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const FriendsPage()),
      );

  void _openSystemSettings() => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SystemSettingsPage()),
      );

  // ─── Toast helper ───────────────────────────────────────────────────────

  void _showToast(String message, {bool isError = false}) {
    DelightToastBar(
      autoDismiss: true,
      snackbarDuration: const Duration(seconds: 3),
      position: DelightSnackbarPosition.top,
      builder: (context) => ToastCard(
        leading: Icon(
          isError ? Icons.error_outline : Icons.check,
          color: isError
              ? Theme.of(context).colorScheme.error
              : Colors.green,
          size: 24,
        ),
        title: Text(
          message,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    ).show(context);
  }
}

// ─── Sub-shells ──────────────────────────────────────────────────────────

/// Loading state: AppBar + shimmer skeleton.
class _LoadingShell extends StatelessWidget {
  const _LoadingShell();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BoardVerse'),
        centerTitle: true,
        forceMaterialTransparency: true,
      ),
      body: const ProfileLoadingSkeleton(),
    );
  }
}

/// Setup state: AppBar + form nhập profile lần đầu.
class _SetupShell extends StatelessWidget {
  const _SetupShell({
    required this.formKey,
    required this.bioController,
    required this.firstNameController,
    required this.lastNameController,
    required this.dobController,
    required this.phoneController,
    required this.onPickDate,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController bioController;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController dobController;
  final TextEditingController phoneController;
  final VoidCallback onPickDate;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hoàn tất hồ sơ'),
        centerTitle: true,
        forceMaterialTransparency: true,
      ),
      body: SetupProfileForm(
        formKey: formKey,
        bioController: bioController,
        firstNameController: firstNameController,
        lastNameController: lastNameController,
        dobController: dobController,
        phoneController: phoneController,
        onPickDate: onPickDate,
        onSubmit: onSubmit,
      ),
    );
  }
}

/// Dashboard state: header + stats + info + location + quick actions + logout.
class _DashboardShell extends StatelessWidget {
  const _DashboardShell({
    required this.profile,
    required this.location,
    required this.karma,
    required this.horizontalPadding,
    required this.onAvatarTap,
    required this.onEditPressed,
    required this.onUpdateGpsPressed,
    required this.onDeleteLocation,
    required this.onOpenLeaderboard,
    required this.onOpenFriends,
    required this.onOpenHistory,
    required this.onOpenSettings,
    required this.onLogout,
  });

  final ProfileEntity profile;
  final PlayerLocationEntity? location;
  final KarmaHistoryEntity? karma;
  final double horizontalPadding;
  final VoidCallback onAvatarTap;
  final VoidCallback onEditPressed;
  final VoidCallback onUpdateGpsPressed;
  final VoidCallback onDeleteLocation;
  final VoidCallback onOpenLeaderboard;
  final VoidCallback onOpenFriends;
  final VoidCallback onOpenHistory;
  final VoidCallback onOpenSettings;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('BoardVerse'),
        centerTitle: true,
        forceMaterialTransparency: true,
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ProfileHeaderCard(
                profile: profile,
                onAvatarTap: onAvatarTap,
                onEditPressed: onEditPressed,
              ),
              const SizedBox(height: AppSpacing.md),
              ProfileStatsRow(profile: profile),
              const SizedBox(height: AppSpacing.md),
              LocationCard(
                location: location,
                onUpdateGpsPressed: onUpdateGpsPressed,
                onDeletePressed: onDeleteLocation,
              ),
              const SizedBox(height: AppSpacing.md),
              QuickActionsCard(
                actions: [
                  QuickActionItem(
                    icon: AppIcons.users,
                    title: 'Bạn bè',
                    onTap: onOpenFriends,
                  ),
                  QuickActionItem(
                    icon: AppIcons.tournament,
                    title: 'Xếp hạng',
                    onTap: onOpenLeaderboard,
                  ),
                  QuickActionItem(
                    icon: AppIcons.bookingHistory,
                    title: 'Lịch sử đấu',
                    onTap: onOpenHistory,
                  ),
                  QuickActionItem(
                    icon: AppIcons.settings,
                    title: 'Cài đặt',
                    onTap: onOpenSettings,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              OutlinedButton.icon(
                onPressed: () => _confirmLogout(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  side: BorderSide(color: theme.colorScheme.error),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
                icon: const Icon(AppIcons.logout),
                label: const Text('Đăng xuất'),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              onLogout();
            },
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }
}
