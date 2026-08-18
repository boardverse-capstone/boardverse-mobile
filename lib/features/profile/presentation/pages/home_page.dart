import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/utils/enums.dart';

import 'package:boardverse/core/navigation/pages/leaderboard_page.dart';
import 'package:boardverse/core/services/location/location_service.dart';
import 'package:boardverse/core/theme/app_icons.dart';
import 'package:boardverse/core/theme/app_spacing.dart';
import 'package:boardverse/core/theme/app_colors.dart';
import 'package:boardverse/core/theme/neo_brutalism_theme.dart';
import 'package:boardverse/core/widgets/app_toast_card.dart';
import 'package:boardverse/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:boardverse/features/auth/presentation/pages/login_page.dart';
import 'package:boardverse/features/friend_management/presentation/pages/friends_page.dart';
import 'package:boardverse/features/profile/domain/entities/karma_history_entity.dart';
import 'package:boardverse/features/profile/domain/entities/player_location_entity.dart';
import 'package:boardverse/features/profile/domain/entities/profile_entity.dart';
import 'package:boardverse/features/profile/presentation/controllers/avatar_upload_controller.dart';
import 'package:boardverse/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:boardverse/features/profile/presentation/widgets/avatar_viewer_sheet.dart';
import 'package:boardverse/features/profile/presentation/widgets/edit_profile_sheet.dart';
import 'package:boardverse/features/profile/presentation/widgets/error_state.dart';
import 'package:boardverse/features/profile/presentation/widgets/loading_skeleton.dart';
import 'package:boardverse/features/profile/presentation/widgets/location_card_neo.dart';
import 'package:boardverse/features/profile/presentation/widgets/profile_header_card_neo.dart';
import 'package:boardverse/features/profile/presentation/widgets/profile_stats_row_neo.dart';
import 'package:boardverse/features/profile/presentation/widgets/quick_actions_card_neo.dart';
import 'package:boardverse/features/profile/presentation/widgets/setup_profile_form.dart';
import 'package:boardverse/features/settings/presentation/pages/system_settings_page.dart';
import 'package:boardverse/features/wallet/presentation/pages/wallet_page.dart';

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

  /// `true` trong khi PUT location đang bay — dùng để disable nút
  /// "Cập nhật vị trí hiện tại", tránh player spam tap nhiều lần khi
  /// thấy app chưa phản hồi ngay.
  bool _isUpdatingLocation = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      final cubit = context.read<ProfileCubit>();
      // Hydrate UI instantly from cache so the screen renders with
      // the player's info even before the network response lands (or
      // if it never lands).
      cubit.hydrateFromCache();
      cubit.getProfile();
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
        // Nếu state mang theo `message` từ backend thì hiển thị luôn —
        // chỉ PUT mới có message, GET không có nên sẽ tự skip.
        if (state.message != null) {
          _showToast(state.message!);
          setState(() => _isUpdatingLocation = false);
        }

      case ProfileLocationDeleted():
        _lastLocation = null;

      case ProfileKarmaLoaded():
        _lastKarma = state.karma;

      case ProfileFailure():
        // Khi update location fail, bật lại nút để user retry.
        if (_isUpdatingLocation) {
          setState(() => _isUpdatingLocation = false);
        }
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

      // Chỉ hiện full-screen error khi CHƯA từng load được profile
      // chính (main failure). Nếu đã có `_lastProfile` cached thì
      // supplementary failure (location/karma) sẽ được show qua toast
      // ở `_onStateChanged` — dashboard vẫn render bình thường.
      ProfileFailure() when _lastProfile == null => Scaffold(
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
      // `ProfileFailure` supplementary (location/karma fail): fall back
      // về dashboard thay vì full-screen error — message đã được show
      // qua toast ở `_onStateChanged`.
      ProfileFailure() ||
      ProfileInitial() when _lastProfile != null => _buildDashboardShell(
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
        isUpdatingLocation: _isUpdatingLocation,
        onAvatarTap: _changeAvatar,
        onEditPressed: () => _showEditProfileSheet(profile),
        onUpdateGpsPressed: _updateLocationGps,
        onOpenLeaderboard: _openLeaderboard,
        onOpenFriends: _openFriendsPage,
        onOpenWallet: _openWalletPage,
        onOpenSettings: _openSystemSettings,
        onLogout: _logout,
        onRefresh: () => context.read<ProfileCubit>().getProfile(),
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

    final profile = _lastProfile;
    if (profile == null) return;

    await AvatarViewerSheet.show(
      context,
      avatarUrl: profile.avatarUrl,
      username: profile.username,
      onChangeAvatar: () async {
        Navigator.of(context).pop(); // Dismiss viewer
        await _performAvatarUpload();
      },
    );
  }

  Future<void> _performAvatarUpload() async {
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

  /// Read device GPS rồi PUT lên backend. Trước đây hardcode
  /// `(10.7769, 106.7008)` → backend reverse-geocode trả về "Quận 1"
  /// dù player thực sự ở chỗ khác. Đã đổi sang `LocationService`.
  ///
  /// Set `_isUpdatingLocation = true` để disable nút trong UI — player
  /// không thể spam tap trong khi request đang bay. Toast thành công sẽ
  /// được show từ `_onStateChanged` khi nhận `ProfileLocationLoaded`
  /// mang theo `message` từ backend.
  Future<void> _updateLocationGps() async {
    if (_isUpdatingLocation) return; // chặn double-tap trước khi vào async

    setState(() => _isUpdatingLocation = true);
    try {
      final loc = await const LocationService().getCurrentLocation();
      if (!mounted) return;
      context.read<ProfileCubit>().updateLocation(
            latitude: loc.latitude,
            longitude: loc.longitude,
            source: 0,
          );
    } on LocationFailure catch (e) {
      if (!mounted) return;
      setState(() => _isUpdatingLocation = false);
      _showToast(e.userMessage, isError: true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUpdatingLocation = false);
      _showToast('Không thể cập nhật vị trí: $e', isError: true);
    }
  }

  // ─── Navigation ─────────────────────────────────────────────────────────

  void _openLeaderboard() => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const LeaderboardPage()));

  void _openFriendsPage() => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const FriendsPage()));

  void _openWalletPage() => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const WalletPage()));

  void _openSystemSettings() => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const SystemSettingsPage()));

  // ─── Toast helper ───────────────────────────────────────────────────────

  void _showToast(String message, {bool isError = false}) {
    DelightToastBar(
      autoDismiss: true,
      snackbarDuration: const Duration(seconds: 3),
      position: DelightSnackbarPosition.top,
      builder: (context) => AppToastCard(
        leading: Icon(
          isError ? Icons.error_outline : Icons.check,
          color: isError ? Theme.of(context).colorScheme.error : Colors.green,
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
    required this.isUpdatingLocation,
    required this.onAvatarTap,
    required this.onEditPressed,
    required this.onUpdateGpsPressed,
    required this.onOpenLeaderboard,
    required this.onOpenFriends,
    required this.onOpenWallet,
    required this.onOpenSettings,
    required this.onLogout,
    required this.onRefresh,
  });

  final ProfileEntity profile;
  final PlayerLocationEntity? location;
  final KarmaHistoryEntity? karma;
  final double horizontalPadding;
  final bool isUpdatingLocation;
  final VoidCallback onAvatarTap;
  final VoidCallback onEditPressed;
  final VoidCallback onUpdateGpsPressed;
  final VoidCallback onOpenLeaderboard;
  final VoidCallback onOpenFriends;
  final VoidCallback onOpenWallet;
  final VoidCallback onOpenSettings;
  final VoidCallback onLogout;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? NeoBrutalismTheme.bgDark
          : NeoBrutalismTheme.bgLight,
      appBar: AppBar(
        backgroundColor: isDark
            ? NeoBrutalismTheme.bgDark
            : NeoBrutalismTheme.bgLight,
        title: const Text(
          'BOARDVERSE',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2),
        ),
        centerTitle: true,
        forceMaterialTransparency: true,
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: () async {
            onRefresh();
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ProfileHeaderCardNeo(
                  profile: profile,
                  onAvatarTap: onAvatarTap,
                  onEditPressed: onEditPressed,
                ),
                const SizedBox(height: AppSpacing.md),
                ProfileStatsRowNeoCompact(profile: profile),
                const SizedBox(height: AppSpacing.md),
                LocationCardNeo(
                  location: location,
                  isUpdating: isUpdatingLocation,
                  onUpdateGpsPressed: onUpdateGpsPressed,
                ),
                const SizedBox(height: AppSpacing.md),
                QuickActionsGridNeo(
                  actions: [
                    QuickActionItemNeo(
                      icon: AppIcons.users,
                      title: 'Bạn bè',
                      onTap: onOpenFriends,
                      accentColor: AppColors.secondary, // Xanh dương/Teal
                    ),
                    QuickActionItemNeo(
                      icon: AppIcons.tournament,
                      title: 'Xếp hạng',
                      onTap: onOpenLeaderboard,
                      accentColor: AppColors.accent, // Vàng
                    ),
                    QuickActionItemNeo(
                      icon: AppIcons.money,
                      title: 'Ví BVC',
                      onTap: onOpenWallet,
                      accentColor: AppColors.success, // Xanh lá
                    ),
                    QuickActionItemNeo(
                      icon: AppIcons.settings,
                      title: 'Cài đặt',
                      onTap: onOpenSettings,
                      accentColor: AppColors.primary, // Cam
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                _NeoBrutalismLogoutButton(
                  onPressed: () => _confirmLogout(context),
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
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

/// Neo-brutalism styled logout button
/// - Light mode: white background, red border & text
/// - Dark mode: dark background, white/red border & text
class _NeoBrutalismLogoutButton extends StatefulWidget {
  const _NeoBrutalismLogoutButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_NeoBrutalismLogoutButton> createState() =>
      _NeoBrutalismLogoutButtonState();
}

class _NeoBrutalismLogoutButtonState extends State<_NeoBrutalismLogoutButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      duration: const Duration(milliseconds: 80),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) => _pressCtrl.forward();
  void _onTapUp(TapUpDetails details) => _pressCtrl.reverse();
  void _onTapCancel() => _pressCtrl.reverse();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.translate(
              offset: _pressCtrl.isAnimating ? const Offset(2, 2) : Offset.zero,
              child: child,
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: NeoBrutalismTheme.autoBox(
            context,
            backgroundColor: isDark
                ? NeoBrutalismTheme.surfaceDark
                : Colors.white,
            borderColor: AppColors.error,
            borderRadius: 14,
            shadowColor: AppColors.error.withValues(alpha: 0.2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(AppIcons.logout, color: AppColors.error, size: AppIcons.md),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'ĐĂNG XUẤT',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
