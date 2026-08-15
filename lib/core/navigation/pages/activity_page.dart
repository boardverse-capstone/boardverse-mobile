import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../features/profile/presentation/cubit/profile_cubit.dart';
import '../../../features/tournament/domain/entities/tournament_entity.dart';
import '../../../features/tournament/presentation/cubit/tournament_list_cubit.dart';
import '../../../features/tournament/presentation/cubit/tournament_list_state.dart';
import '../../../features/tournament/presentation/widgets/tournament_status_pill.dart';
import '../../navigation/tournament_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shimmer.dart';
import '../../theme/app_spacing.dart';
import '../../theme/neo_brutalism_theme.dart';
import '../../utils/refresh_helper.dart';
import 'tournament_shell.dart';

/// Activity page - hiển thị thông báo, invite requests, pending bookings
class ActivityPage extends StatefulWidget {
  final ValueChanged<int>? onSwitchTab;

  /// Called by [MainScaffold] every time the Activity tab becomes the
  /// active tab (i.e. the user taps the Activity tab in the bottom
  /// nav). Lets the page re-fetch its data without relying on a
  /// [BlocListener] on a transient navigation cubit.
  final VoidCallback? onReselect;

  const ActivityPage({
    super.key,
    this.onSwitchTab,
    this.onReselect,
  });

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage>
    with WidgetsBindingObserver {
  final RefreshHelper _refreshHelper = RefreshHelper();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() {
      if (!mounted) return;
      _ensureProfileLoaded();
      _ensureTournamentsLoaded();
    });
  }

  @override
  void didUpdateWidget(covariant ActivityPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The parent reuses the same `ActivityPage` widget instance and
    // only swaps in a fresh `onReselect` closure when the user taps
    // the Activity tab. Treat any callback invocation as a
    // reselection signal: it would never fire on the very first
    // mount because the parent only assigns it on user tap.
    if (widget.onReselect != null && widget.onReselect != oldWidget.onReselect) {
      _refreshAll();
    }
  }

  /// Re-fetch profile + tournaments. Called from [initState] (first
  /// mount) and [didUpdateWidget] (every subsequent tap of the
  /// Activity tab via [MainScaffold]).
  void _refreshAll() {
    if (!mounted) return;
    _refreshProfile();
    _refreshTournaments();
    _refreshHelper.markRefreshed();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _onAppResumed();
    }
  }

  void _onAppResumed() {
    if (_refreshHelper.shouldRefreshActivity()) {
      _refreshProfile();
      _refreshTournaments();
      _refreshHelper.markRefreshed();
    }
  }

  void _refreshProfile() {
    final cubit = context.read<ProfileCubit>();
    // Always re-fetch on tab reselection unless a request is currently in
    // flight. The previous guard skipped `ProfileFailure`, which is what
    // kept the greeting skeleton stuck forever when the initial fetch
    // (triggered from `MainScaffold.initState`) failed before the user
    // even reached this tab.
    if (cubit.state is ProfileLoading) return;
    cubit.getProfile();
  }

  void _refreshTournaments() {
    final cubit = context.read<TournamentListCubit>();
    if (cubit.state is TournamentListLoading) return;
    cubit.loadOpenTournamentsOnly();
  }

  void _ensureProfileLoaded() {
    final cubit = context.read<ProfileCubit>();
    // Initial mount must recover from `ProfileFailure` too — otherwise a
    // previous failed fetch keeps the greeting card skeletonised forever
    // (no follow-up request is ever issued).
    if (cubit.state is ProfileLoading) return;
    if (cubit.state is ProfileInitial || cubit.state is ProfileFailure) {
      cubit.getProfile();
    }
  }

  void _ensureTournamentsLoaded() {
    final cubit = context.read<TournamentListCubit>();
    if (cubit.state is TournamentListLoading) return;
    if (cubit.state is TournamentListInitial ||
        cubit.state is TournamentListError) {
      cubit.loadOpenTournamentsOnly();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
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
        actions: [
          IconButton(
            icon: Icon(
              Icons.notifications_none_rounded,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimary,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await context
                .read<TournamentListCubit>()
                .loadOpenTournamentsOnly();
            _refreshHelper.markRefreshed();
          },
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGreetingCard(context),
                const SizedBox(height: AppSpacing.lg),
                _buildQuickActionsSection(context),
                  const SizedBox(height: AppSpacing.lg),
                  _buildTournamentSection(context),
                  const SizedBox(height: AppSpacing.lg),
                  _buildRecentActivitySection(context),
                ],
              ),
            ),
          ),
        ),
      );
  }

  Widget _buildGreetingCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        final hasProfile = state is ProfileLoaded;

        // Khi profile chưa load (Initial / Loading / Error) hiển thị
        // skeleton shimmer trên cùng card gradient - tránh hiển thị
        // fake "Player" gây hiểu nhầm là đã load xong.
        // Khác với home_overview_page.dart dùng fallback, Activity page
        // (entry tab sau login) cần rõ ràng "đang tải" cho user đợi.
        if (!hasProfile) {
          return _GreetingCardSkeleton(isDark: isDark);
        }

        final username = state.profile.username;
        final avatarUrl = state.profile.avatarUrl;

        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
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
              _AvatarWithBorder(avatarUrl: avatarUrl, username: username),
              const SizedBox(width: AppSpacing.md),
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
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      username,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
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
                        fontSize: 12,
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

  Widget _buildQuickActionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'THAO TÁC NHANH',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.3,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          children: [
            _QuickActionCard(
              icon: Icons.groups_rounded,
              label: 'Tạo phòng',
              color: AppColors.primary,
              onTap: () => widget.onSwitchTab?.call(3), // Go to Lobbies tab
            ),
            _QuickActionCard(
              icon: Icons.search_rounded,
              label: 'Tìm phòng',
              color: AppColors.secondary,
              onTap: () => widget.onSwitchTab?.call(2), // Go to Explore tab
            ),
            _QuickActionCard(
              icon: Icons.calendar_month_rounded,
              label: 'Đặt bàn',
              color: AppColors.accent,
              onTap: () => widget.onSwitchTab?.call(1), // Go to Bookings tab
            ),
            _QuickActionCard(
              icon: Icons.emoji_events_rounded,
              label: 'Giải đấu',
              color: AppColors.success,
              onTap: () => _openTournaments(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTournamentSection(BuildContext context) {
    return BlocBuilder<TournamentListCubit, TournamentListState>(
      builder: (context, state) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'GIẢI ĐẤU NỔI BẬT',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: AppColors.success,
                  ),
                ),
                TextButton(
                  onPressed: () => _openTournaments(),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Xem tất cả',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: AppColors.success,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (state is TournamentListLoading ||
                state is TournamentListInitial)
              _TournamentLoadingCard()
            else if (state is TournamentListError)
              _TournamentErrorCard(
                message: state.message,
                onRetry: () => context
                    .read<TournamentListCubit>()
                    .loadOpenTournamentsOnly(),
              )
            else if (state is TournamentListLoaded)
              _TournamentListContent(
                state: state,
                isDark: isDark,
                onTapTournament: _openTournamentDetail,
              )
            else
              const SizedBox.shrink(),
          ],
        );
      },
    );
  }

  Widget _buildRecentActivitySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'HOẠT ĐỘNG GẦN ĐÂY',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        const _EmptyActivityCard(
          icon: Icons.inbox_rounded,
          title: 'Chưa có hoạt động',
          subtitle: 'Các thông báo và invite sẽ hiển thị ở đây',
        ),
      ],
    );
  }

  String _greetingMessage() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Chúc bạn buổi sáng vui vẻ';
    if (hour < 14) return 'Buổi trưa nay có trận nào không?';
    if (hour < 18) return 'Buổi chiều rảnh rỗi';
    return 'Chào buổi tối!';
  }

  void _openTournaments() async {
    final result = await Navigator.of(
      context,
    ).push<int>(MaterialPageRoute(builder: (_) => const TournamentShell()));
    // Handle tab switch if user selected a tab from mini nav bar
    if (result != null && result != 0) {
      widget.onSwitchTab?.call(result);
    }
  }

  void _openTournamentDetail(TournamentEntity tournament) {
    TournamentRoutes.openTournamentDetail(
      context: context,
      tournamentId: tournament.id,
    );
  }
}

// ============ Tournament Section Widgets ============

class _TournamentListContent extends StatelessWidget {
  const _TournamentListContent({
    required this.state,
    required this.isDark,
    required this.onTapTournament,
  });

  final TournamentListLoaded state;
  final bool isDark;
  final void Function(TournamentEntity) onTapTournament;

  @override
  Widget build(BuildContext context) {
    // Get tournaments to show: open + upcoming (max 3)
    final tournaments = [
      ...state.openTournaments,
      ...state.upcomingTournaments,
    ].take(3).toList();

    if (tournaments.isEmpty) {
      return _TournamentEmptyCard();
    }

    return Column(
      children: tournaments.map((tournament) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: _TournamentMiniCard(
            tournament: tournament,
            isDark: isDark,
            onTap: () => onTapTournament(tournament),
          ),
        );
      }).toList(),
    );
  }
}

class _TournamentMiniCard extends StatelessWidget {
  const _TournamentMiniCard({
    required this.tournament,
    required this.isDark,
    required this.onTap,
  });

  final TournamentEntity tournament;
  final bool isDark;
  final VoidCallback onTap;

  static final DateFormat _dateFormat = DateFormat('dd/MM • HH:mm');

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: NeoBrutalismTheme.autoBox(
          context,
          backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
          borderRadius: 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    tournament.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                TournamentStatusPill(status: tournament.status),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Icon(
                  Icons.videogame_asset_rounded,
                  size: 14,
                  color: AppColors.success,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    tournament.gameTemplateName,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 14,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  _dateFormat.format(tournament.startTime),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.people_rounded,
                  size: 14,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${tournament.currentParticipants}/${tournament.maxParticipants}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
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

class _TournamentLoadingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Shimmer skeleton mô phỏng cấu trúc _TournamentMiniCard:
    // - Title row: pill status bên phải
    // - Subtitle row: tên game
    // - Bottom row: date + participants
    // Dùng AppShimmer.box để đồng bộ style với các shimmer khác trong app.
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: NeoBrutalismTheme.autoBox(
        context,
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              Expanded(
                child: AppShimmer.box(
                  context: context,
                  width: 180,
                  height: 16,
                  borderRadius: 4,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              AppShimmer.box(
                context: context,
                width: 56,
                height: 18,
                borderRadius: 9,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Subtitle row (game name)
          Row(
            children: [
              AppShimmer.box(
                context: context,
                width: 14,
                height: 14,
                borderRadius: 3,
              ),
              const SizedBox(width: 4),
              AppShimmer.box(
                context: context,
                width: 120,
                height: 12,
                borderRadius: 3,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Bottom row (date + participants)
          Row(
            children: [
              AppShimmer.box(
                context: context,
                width: 14,
                height: 14,
                borderRadius: 3,
              ),
              const SizedBox(width: 4),
              AppShimmer.box(
                context: context,
                width: 90,
                height: 12,
                borderRadius: 3,
              ),
              const Spacer(),
              AppShimmer.box(
                context: context,
                width: 14,
                height: 14,
                borderRadius: 3,
              ),
              const SizedBox(width: 4),
              AppShimmer.box(
                context: context,
                width: 36,
                height: 12,
                borderRadius: 3,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Skeleton cho greeting card trong khi profile đang load.
///
/// Giữ nguyên cấu trúc gradient + border + shadow để khi load xong
/// không bị "jump" layout. Phần text/avatar thay bằng shimmer box
/// để user biết app đang tải.
class _GreetingCardSkeleton extends StatelessWidget {
  const _GreetingCardSkeleton({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
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
          // Avatar skeleton - circle với shimmer
          AppShimmer.circle(context: context, size: 64),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // "Xin chào," line
                AppShimmer.box(
                  context: context,
                  width: 70,
                  height: 14,
                  borderRadius: 4,
                ),
                const SizedBox(height: 8),
                // Username (to hơn)
                AppShimmer.box(
                  context: context,
                  width: 160,
                  height: 22,
                  borderRadius: 6,
                ),
                const SizedBox(height: 8),
                // Greeting message
                AppShimmer.box(
                  context: context,
                  width: 200,
                  height: 12,
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

class _TournamentErrorCard extends StatelessWidget {
  const _TournamentErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: NeoBrutalismTheme.autoBox(
        context,
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: 16,
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline_rounded, color: AppColors.error, size: 32),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Không thể tải giải đấu',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          TextButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    );
  }
}

class _TournamentEmptyCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: NeoBrutalismTheme.autoBox(
        context,
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: 16,
      ),
      child: Column(
        children: [
          Icon(
            Icons.emoji_events_rounded,
            size: 40,
            color: AppColors.success.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Chưa có giải đấu nào',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Hãy quay lại sau để cập nhật thông tin mới nhất',
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ============ Existing Widgets ============

class _AvatarWithBorder extends StatelessWidget {
  const _AvatarWithBorder({required this.avatarUrl, required this.username});

  final String? avatarUrl;
  final String username;

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
        radius: 32,
        backgroundColor: AppColors.primary.withValues(alpha: 0.2),
        backgroundImage: hasImage ? NetworkImage(avatarUrl!) : null,
        child: hasImage
            ? null
            : Text(
                username.isNotEmpty
                    ? username.substring(0, 1).toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
      ),
    );
  }
}

class _QuickActionCard extends StatefulWidget {
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  State<_QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<_QuickActionCard> {
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
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        child: Container(
          decoration: NeoBrutalismTheme.autoBox(
            context,
            backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
            shadowColor: widget.color.withValues(alpha: 0.2),
            borderRadius: 16,
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm + 2),
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.border,
                    width: 2,
                  ),
                ),
                child: Icon(widget.icon, color: widget.color, size: 28),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyActivityCard extends StatelessWidget {
  const _EmptyActivityCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: NeoBrutalismTheme.autoBox(
        context,
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: 16,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              size: 48,
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
