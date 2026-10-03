import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../features/discovery/presentation/cubit/saved_games_cubit.dart';
import '../../../features/discovery/presentation/cubit/saved_games_state.dart';
import '../../../features/discovery/presentation/pages/saved_games_page.dart';
import '../../../features/discovery/presentation/pages/survey_page.dart';
import '../../../features/discovery/presentation/widgets/survey_hero_cta.dart';
import '../../../features/profile/presentation/cubit/profile_cubit.dart';
import '../../../features/reservation/presentation/pages/reservation_search_page.dart';
import 'leaderboard_page.dart';
import 'tournament_shell.dart';
import '../nav_tab.dart';
import '../tournament_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_spacing.dart';
import '../../theme/neo_brutalism_theme.dart';

/// Activity page - "Trung tâm điều hướng" của BoardVerse.
///
/// Triết lý thiết kế (2026-10-03): trang này KHÔNG hiển thị danh sách
/// chi tiết (giải đấu đang mở, game đã lưu, lịch hẹn sắp tới...) mà đóng
/// vai trò là **bảng điều khiển truy cập nhanh** — mỗi tile là một lối tắt
/// trực tiếp đến một màn hình chức năng cụ thể (tạo lobby, tìm bạn, nạp
/// BVC, xem xếp hạng...). User bấm vào → app tự chuyển đến đúng tab hoặc
/// push trang tương ứng.
///
/// Bám sát Design System §7 Neo-Brutalism:
/// - Bold border 2-3px, hard offset shadow 3-5px, NO blur
/// - Vibrant brand color, theme-aware (light/dark)
/// - Press animation scale 0.95, duration 100ms
/// - 8pt grid spacing
class ActivityPage extends StatefulWidget {
  final ValueChanged<int>? onSwitchTab;

  /// Called by [MainScaffold] mỗi lần user tap vào tab Activity.
  final VoidCallback? onReselect;

  const ActivityPage({super.key, this.onSwitchTab, this.onReselect});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      _ensureProfileLoaded();
      // Trigger load saved games cubit để có thể hiển thị count badge
      // trên shortcut "Game đã lưu". Không block UI; nếu fail thì
      // shortcut vẫn navigate được.
      final savedCubit = context.read<SavedGamesCubit>();
      if (savedCubit.state is SavedGamesInitial) {
        savedCubit.loadSavedGames();
      }
    });
  }

  @override
  void didUpdateWidget(covariant ActivityPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.onReselect != null &&
        widget.onReselect != oldWidget.onReselect) {
      _refreshProfile();
    }
  }

  void _refreshProfile() {
    if (!mounted) return;
    final cubit = context.read<ProfileCubit>();
    if (cubit.state is ProfileLoading) return;
    cubit.getProfile();
  }

  void _ensureProfileLoaded() {
    final cubit = context.read<ProfileCubit>();
    if (cubit.state is ProfileLoading) return;
    if (cubit.state is ProfileInitial || cubit.state is ProfileFailure) {
      cubit.getProfile();
    }
  }

  // ─── Navigation helpers ────────────────────────────────────────────────

  /// Chuyển tab qua MainScaffold. Nếu MainScaffold không cung cấp callback
  /// (test / standalone) thì fallback push MainScaffold — nhưng trong app
  /// thật, [onSwitchTab] luôn được set bởi MainScaffold.
  void _switchTab(NavTab tab) {
    final callback = widget.onSwitchTab;
    if (callback != null) {
      callback(tab.tabIndex);
    }
  }

  void _openSurvey() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SurveyPage()),
    );
  }

  void _openSavedGames() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SavedGamesPage()),
    );
  }

  void _openBookings() {
    _switchTab(NavTab.bookings);
  }

  void _openExplore() {
    _switchTab(NavTab.explore);
  }

  void _openLeaderboard() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LeaderboardPage()),
    );
  }

  /// Mở "Tournament" — vì Tournament là 1 sub-flow bên ngoài MainScaffold,
  /// dùng TournamentShell để có bottom mini-nav. Khi user pop shell, kết
  /// quả trả về (tab index) sẽ được MainScaffold dùng để chuyển tab chính.
  Future<void> _openTournaments() async {
    final result = await Navigator.of(context).push<int>(
      MaterialPageRoute(builder: (_) => const TournamentShell()),
    );
    if (result != null && result != 0) {
      widget.onSwitchTab?.call(result);
    }
  }

  void _openMyRegistrations() {
    TournamentRoutes.openMyRegistrations(context);
  }

  void _openEloHistory() {
    TournamentRoutes.openEloHistory(context);
  }

  void _openReservationSearch() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ReservationSearchPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Hoạt động',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        elevation: 0,
        centerTitle: false,
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGreetingCard(context),
              const SizedBox(height: AppSpacing.lg),
              _buildSurveyHeroCta(context),
              const SizedBox(height: AppSpacing.lg),
              _buildDiscoverSection(context),
              const SizedBox(height: AppSpacing.lg),
              _buildPlaySection(context),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Greeting card (gradient + skeleton) ────────────────────────────────

  Widget _buildGreetingCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 380;

    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        final hasProfile = state is ProfileLoaded;

        if (!hasProfile) {
          return _GreetingCardSkeleton(
            isDark: isDark,
            isSmallScreen: isSmallScreen,
          );
        }

        final username = state.profile.username;
        final avatarUrl = state.profile.avatarUrl;
        final avatarSize = isSmallScreen ? 48.0 : 64.0;
        final horizontalPadding =
            isSmallScreen ? AppSpacing.md : AppSpacing.lg;
        final titleFontSize = isSmallScreen ? 18.0 : 22.0;

        return Container(
          padding: EdgeInsets.all(horizontalPadding),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryLight],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.border,
              width: 3,
            ),
            boxShadow: NeoBrutalismTheme.lightShadow(
              shadowColor: AppColors.primary.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            children: [
              _AvatarWithBorder(
                avatarUrl: avatarUrl,
                username: username,
                size: avatarSize,
              ),
              SizedBox(
                width: isSmallScreen ? AppSpacing.sm : AppSpacing.md,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Xin chào,',
                      style: TextStyle(
                        color: AppColors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w700,
                        fontSize: isSmallScreen ? 12 : 14,
                      ),
                    ),
                    Text(
                      username,
                      style: TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: titleFontSize,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _greetingMessage(),
                      style: TextStyle(
                        color: AppColors.white.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w600,
                        fontSize: isSmallScreen ? 10 : 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Survey Hero CTA ───────────────────────────────────────────────────

  Widget _buildSurveyHeroCta(BuildContext context) {
    return BlocBuilder<SavedGamesCubit, SavedGamesState>(
      builder: (context, savedState) {
        final hasEligible = _resolveSavedCount(savedState) >= 3;
        return SurveyHeroCta(
          hasPersonalizationEligible: hasEligible,
          onTap: _openSurvey,
        );
      },
    );
  }

  int _resolveSavedCount(SavedGamesState state) {
    if (state is SavedGamesLoaded) return state.savedIds.length;
    if (state is SavedGamesLoadingFromCache) return state.cachedIds.length;
    if (state is SavedGamesRefreshing) return state.totalCount;
    if (state is SavedGamesError) return state.savedIds?.length ?? 0;
    return 0;
  }

  // ─── Khám phá & Lịch hẹn ──────────────────────────────────────────────

  Widget _buildDiscoverSection(BuildContext context) {
    return _CategorySection(
      header: _SectionHeader(
        icon: AppIcons.explore,
        title: 'Khám phá & Đặt lịch',
        accentColor: AppColors.info,
      ),
      actions: [
        _ListActionCard(
          icon: AppIcons.search,
          title: 'Tìm quán & board game',
          subtitle: 'Khám phá quán cafe gần bạn',
          accentColor: AppColors.info,
          onTap: _openExplore,
        ),
        _ListActionCard(
          icon: AppIcons.bookmark,
          title: 'Game đã lưu',
          subtitle: 'Bộ sưu tập game yêu thích',
          accentColor: AppColors.accent,
          onTap: _openSavedGames,
        ),
        _ListActionCard(
          icon: AppIcons.book,
          title: 'Tìm lịch hẹn',
          subtitle: 'Tra cứu lịch hẹn trong lịch sử',
          accentColor: AppColors.secondary,
          onTap: _openReservationSearch,
        ),
        _ListActionCard(
          icon: AppIcons.schedule,
          title: 'Lịch đặt của tôi',
          subtitle: 'Các đơn reservation đã tạo',
          accentColor: AppColors.warning,
          onTap: _openBookings,
        ),
      ],
    );
  }

  // ─── Thi đấu ──────────────────────────────────────────────────────────

  Widget _buildPlaySection(BuildContext context) {
    return _CategorySection(
      header: _SectionHeader(
        icon: AppIcons.tournament,
        title: 'Thi đấu',
        accentColor: AppColors.success,
      ),
      actions: [
        _ListActionCard(
          icon: AppIcons.tournament,
          title: 'Khám phá giải đấu',
          subtitle: 'Danh sách các giải đang mở đăng ký',
          accentColor: AppColors.success,
          onTap: _openTournaments,
        ),
        _ListActionCard(
          icon: AppIcons.tournament,
          title: 'Giải đấu của tôi',
          subtitle: 'Theo dõi các giải đã đăng ký',
          accentColor: AppColors.success,
          onTap: _openMyRegistrations,
        ),
        _ListActionCard(
          icon: AppIcons.elo,
          title: 'Bảng xếp hạng',
          subtitle: 'Xếp hạng ELO, Level, Karma',
          accentColor: AppColors.accent,
          onTap: _openLeaderboard,
        ),
        _ListActionCard(
          icon: Icons.history_rounded,
          title: 'Lịch sử ELO',
          subtitle: 'Theo dõi biến động điểm ELO',
          accentColor: AppColors.primary,
          onTap: _openEloHistory,
        ),
      ],
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────────

  String _greetingMessage() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Chúc bạn buổi sáng vui vẻ';
    if (hour < 14) return 'Buổi trưa nay có trận nào không?';
    if (hour < 18) return 'Buổi chiều rảnh rỗi';
    return 'Chào buổi tối!';
  }
}

// =============================================================================
// Reusable widgets
// =============================================================================

/// Section header với icon badge + title (uppercase) theo Design System §7.
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color accentColor;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: accentColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.4),
                blurRadius: 0,
                offset: const Offset(2, 2),
              ),
            ],
          ),
          child: Icon(icon, color: AppColors.white, size: 18),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ],
    );
  }
}

/// Wrapper cho 1 section — header + list các action cards.
class _CategorySection extends StatelessWidget {
  final _SectionHeader header;
  final List<Widget> actions;

  const _CategorySection({required this.header, required this.actions});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,
        const SizedBox(height: AppSpacing.sm),
        ...actions.expand(
          (action) => [
            action,
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ],
    );
  }
}

/// List-style action card (dùng cho các section dài).
///
/// Layout ngang: [icon badge] [title + subtitle] [chevron].
class _ListActionCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final VoidCallback onTap;

  const _ListActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_ListActionCard> createState() => _ListActionCardState();
}

class _ListActionCardState extends State<_ListActionCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: NeoBrutalismTheme.autoBox(
            context,
            backgroundColor:
                isDark ? AppColors.surfaceDark : AppColors.surface,
            shadowColor: widget.accentColor.withValues(alpha: 0.15),
            borderRadius: 14,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: widget.accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: widget.accentColor.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  widget.icon,
                  color: widget.accentColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Greeting card skeleton & avatar
// =============================================================================

class _GreetingCardSkeleton extends StatelessWidget {
  const _GreetingCardSkeleton({
    required this.isDark,
    this.isSmallScreen = false,
  });

  final bool isDark;
  final bool isSmallScreen;

  @override
  Widget build(BuildContext context) {
    final avatarSize = isSmallScreen ? 48.0 : 64.0;
    final horizontalPadding =
        isSmallScreen ? AppSpacing.md : AppSpacing.lg;
    // AppShimmer chưa có sẵn — fallback dùng surfaceVariant.
    return Container(
      padding: EdgeInsets.all(horizontalPadding),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: 3,
        ),
        boxShadow: NeoBrutalismTheme.lightShadow(
          shadowColor: AppColors.primary.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          _ShimmerBox(
            width: avatarSize,
            height: avatarSize,
            borderRadius: avatarSize / 2,
          ),
          SizedBox(width: isSmallScreen ? AppSpacing.sm : AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _ShimmerBox(
                  width: isSmallScreen ? 50 : 70,
                  height: isSmallScreen ? 12 : 14,
                  borderRadius: 4,
                ),
                SizedBox(height: isSmallScreen ? 6 : 8),
                _ShimmerBox(
                  width: isSmallScreen ? 120 : 160,
                  height: isSmallScreen ? 18 : 22,
                  borderRadius: 6,
                ),
                SizedBox(height: isSmallScreen ? 6 : 8),
                _ShimmerBox(
                  width: isSmallScreen ? 150 : 200,
                  height: isSmallScreen ? 10 : 12,
                  borderRadius: 4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const _ShimmerBox({
    required this.width,
    required this.height,
    required this.borderRadius,
  });

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1 + _ctrl.value * 2, 0),
              end: Alignment(1 + _ctrl.value * 2, 0),
              colors: [
                AppColors.white.withValues(alpha: 0.25),
                AppColors.white.withValues(alpha: 0.5),
                AppColors.white.withValues(alpha: 0.25),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AvatarWithBorder extends StatelessWidget {
  const _AvatarWithBorder({
    required this.avatarUrl,
    required this.username,
    this.size = 64,
  });

  final String? avatarUrl;
  final String username;
  final double size;

  @override
  Widget build(BuildContext context) {
    final hasImage = avatarUrl != null && avatarUrl!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.white,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.3),
            blurRadius: 0,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: (size - 6) / 2,
        backgroundColor: AppColors.primary.withValues(alpha: 0.2),
        backgroundImage: hasImage ? NetworkImage(avatarUrl!) : null,
        child: hasImage
            ? null
            : Text(
                username.isNotEmpty
                    ? username.substring(0, 1).toUpperCase()
                    : '?',
                style: TextStyle(
                  fontSize: size * 0.44,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
      ),
    );
  }
}
