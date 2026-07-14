import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/components/toast_card.dart';
import 'package:delightful_toast/toast/utils/enums.dart';

import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../../core/navigation/pages/leaderboard_page.dart';
import '../cubit/profile_cubit.dart';
import '../cubit/profile_state.dart';
import '../../domain/entities/profile_entity.dart';

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

  void _showToast(String message, {bool isError = false}) {
    DelightToastBar(
      autoDismiss: true,
      snackbarDuration: const Duration(seconds: 3),
      position: DelightSnackbarPosition.top,
      builder: (context) => ToastCard(
        leading: Icon(
          isError ? Icons.error_outline : Icons.check_circle_outline,
          color: isError ? Colors.red : Colors.green,
          size: 28,
        ),
        title: Text(
          message,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    ).show(context);
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

  void _onLogout() {
    context.read<AuthCubit>().logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dobController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'BoardVerse',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'Đăng xuất',
            onPressed: _onLogout,
          ),
        ],
      ),
      body: BlocConsumer<ProfileCubit, ProfileState>(
        listener: (context, state) {
          if (state is ProfileLoaded) {
            _showToast('Đã tải thông tin cá nhân!');
          } else if (state is ProfileFailure) {
            _showToast(state.message, isError: true);
          }
        },
        builder: (context, state) {
          if (state is ProfileLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Đang xử lý thông tin...',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          if (state is ProfileLoaded) {
            final profile = state.profile;
            if (!profile.hasProfile) {
              return _buildSetupProfileForm(theme);
            }
            return _buildProfileDashboard(profile, theme);
          }

          if (state is ProfileFailure) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: Colors.redAccent,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Tải dữ liệu thất bại',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => context.read<ProfileCubit>().getProfile(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSetupProfileForm(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.account_circle_outlined,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hoàn tất hồ sơ',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Để tiếp tục trải nghiệm hệ thống, vui lòng điền thông tin cá nhân của bạn.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Bio field
            TextFormField(
              controller: _bioController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Mô tả cá nhân (Bio) *',
                prefixIcon: Icon(Icons.description_outlined),
                border: OutlineInputBorder(),
                helperText: 'Giới thiệu về bản thân bạn',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập mô tả cá nhân';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // First Name field
            TextFormField(
              controller: _firstNameController,
              decoration: const InputDecoration(
                labelText: 'Tên (First Name) *',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập tên';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Last Name field
            TextFormField(
              controller: _lastNameController,
              decoration: const InputDecoration(
                labelText: 'Họ (Last Name) *',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập họ';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Date of Birth field
            TextFormField(
              controller: _dobController,
              readOnly: true,
              onTap: () => _selectDate(context),
              decoration: InputDecoration(
                labelText: 'Ngày sinh (Date of Birth) *',
                prefixIcon: const Icon(Icons.calendar_today_outlined),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_month),
                  onPressed: () => _selectDate(context),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng chọn ngày sinh';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Phone Number field
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Số điện thoại (Phone Number) *',
                prefixIcon: Icon(Icons.phone_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập số điện thoại';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: _onCreateProfile,
                icon: const Icon(Icons.check),
                label: const Text(
                  'Tạo hồ sơ cá nhân',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileDashboard(ProfileEntity profile, ThemeData theme) {
    final username = profile.username;
    final initials = username.isNotEmpty ? username.substring(0, 1).toUpperCase() : '?';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // ── Premium Header ──────────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(32),
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: theme.colorScheme.surface,
                  child: Text(
                    initials,
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  username,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '@$username',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                if (profile.gamerTier != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Hạng: ${profile.gamerTier}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                if (profile.bio != null && profile.bio!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      profile.bio!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  )
                else
                  Text(
                    'Chưa có mô tả cá nhân',
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Stats Section (ELO and Level) ───────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'ELO RATING',
                    value: '${profile.globalElo}',
                    icon: Icons.emoji_events_rounded,
                    iconColor: Colors.amber,
                    theme: theme,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    title: 'LEVEL / CẤP ĐỘ',
                    value: '${profile.level}',
                    icon: Icons.star_rounded,
                    iconColor: Colors.blueAccent,
                    theme: theme,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Personal Info Details Card ──────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.contact_page_outlined,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Thông tin tài khoản',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _buildDetailRow(
                      icon: Icons.favorite_border_rounded,
                      label: 'Karma Points / Điểm uy tín',
                      value: profile.karmaPoints != null ? '${profile.karmaPoints} PTS' : 'Chưa có',
                      theme: theme,
                    ),
                    if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        icon: Icons.description_outlined,
                        label: 'Mô tả cá nhân',
                        value: profile.bio!,
                        theme: theme,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 40),

          // ── Tiện ích (Xếp hạng, Lịch sử, Cài đặt) ────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
                ),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.leaderboard_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    title: const Text('Xếp hạng'),
                    subtitle: const Text(
                        'Xem bảng xếp hạng ELO & Karma của cộng đồng'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const LeaderboardPage(),
                      ),
                    ),
                  ),
                  Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.emoji_events_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    title: const Text('Lịch sử đấu'),
                    subtitle: const Text('Theo dõi các trận đã chơi gần đây'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showComingSoonToast(context, 'Lịch sử đấu'),
                  ),
                  Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.settings_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    title: const Text('Cài đặt'),
                    subtitle: const Text('Tùy chỉnh tài khoản và thông báo'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showComingSoonToast(context, 'Cài đặt'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _showComingSoonToast(BuildContext context, String feature) {
    _showToast('$feature sắp ra mắt');
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required ThemeData theme,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Icon(icon, color: iconColor, size: 24),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
