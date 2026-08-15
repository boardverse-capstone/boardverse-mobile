import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:boardverse/core/di/injection.dart';
import 'package:boardverse/core/theme/theme.dart';

import '../../../features/lobby_management/domain/entities/lobby_entity.dart';
import '../../../features/lobby_management/presentation/cubit/lobby_cubit.dart';
import '../../../features/lobby_management/presentation/cubit/my_lobbies_cubit.dart';
import '../../../features/lobby_management/presentation/cubit/my_lobbies_state.dart';
import '../../../features/lobby_management/presentation/pages/lobby_page.dart';
import '../../../features/lobby_management/presentation/widgets/lobby_card_base.dart';
import '../../../features/lobby_management/presentation/widgets/lobby_friends_shimmer.dart';
import '../../../features/reservation/presentation/pages/reservation_list_page.dart';

/// Tab "Lịch đặt" — hiển thị reservation + lobby của user.
///
/// Redesign 2026-08-08: thay vì scroll qua 2 section ("ĐẶT CHỖ CỦA TÔI"
/// và "PHÒNG CHỜ CỦA TÔI") dồn vào một list, page giờ dùng
/// `TabBar` + `TabBarView` pill-style cho 2 tab:
///   - **Phòng chờ của tôi** (tab 0, default): lobby user host + joined.
///     Tap → mở `LobbyPage` (chi tiết lobby).
///   - **Lịch đặt** (tab 1): danh sách reservation qua API.
///     Tap → mở `ReservationDetailPage` (tự route sang lobby nếu có).
///
/// Phần reservation được tách sang feature `reservation` qua
/// `ReservationListPage`; tab này chỉ chịu trách nhiệm render lobby list
/// (vì lobby list UI thuộc `lobby_management`).
class BookingsPage extends StatefulWidget {
  const BookingsPage({super.key});

  /// Backward-compat — các caller cũ (MainScaffold) gọi `requestRefresh`
  /// khi user double-tap tab. Hiện tại không cần vì cả reservation list lẫn
  /// lobby list đều auto-load khi build.
  static void requestRefresh(BuildContext context) {}

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final MyLobbiesCubit _myLobbiesCubit;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _myLobbiesCubit = context.read<MyLobbiesCubit>();
    _myLobbiesCubit.load(null);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return SafeArea(
      child: Column(
        children: [
          // Tiêu đề page + pill-style tab bar
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LỊCH ĐẶT',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Phòng chờ và đơn đặt chỗ của bạn',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: _ModernPillTabBar(
              controller: _tabController,
              theme: theme,
              colors: colors,
            ),
          ),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                const ReservationListPage(scrollable: false),
                _MyLobbiesTab(
                  myLobbiesCubit: _myLobbiesCubit,
                  onOpenLobby: _openLobby,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openLobby(LobbyEntity lobby) {
    final lobbyCubit = getIt<LobbyCubit>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LobbyPage(
          lobbyId: lobby.id,
          lobbyCubit: lobbyCubit,
        ),
      ),
    );
  }
}

// ─── My Lobbies tab ───────────────────────────────────────────────────────

class _MyLobbiesTab extends StatelessWidget {
  final MyLobbiesCubit myLobbiesCubit;
  final void Function(LobbyEntity) onOpenLobby;

  const _MyLobbiesTab({
    required this.myLobbiesCubit,
    required this.onOpenLobby,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => myLobbiesCubit.load(null),
      child: BlocBuilder<MyLobbiesCubit, MyLobbiesState>(
        bloc: myLobbiesCubit,
        builder: (context, state) {
          if (state is MyLobbiesLoading) {
            return const _LobbiesLoadingView();
          }
          if (state is MyLobbiesFailure) {
            return _ErrorView(
              message: state.message,
              onRetry: () => myLobbiesCubit.load(null),
            );
          }
          if (state is MyLobbiesLoaded) {
            final lobbies = <LobbyEntity>[...state.joined, ...state.hosted];
            if (lobbies.isEmpty) {
              return _EmptyView(
                onRefresh: () => myLobbiesCubit.load(null),
              );
            }
            // Sắp xếp: hoạt động trước, sau đó theo thời gian giảm dần.
            lobbies.sort((a, b) {
              final aActive = a.status == LobbyStatus.open ||
                  a.status == LobbyStatus.viable ||
                  a.status == LobbyStatus.full ||
                  a.status == LobbyStatus.inProgress ||
                  a.status == LobbyStatus.pendingCafeApproval;
              final bActive = b.status == LobbyStatus.open ||
                  b.status == LobbyStatus.viable ||
                  b.status == LobbyStatus.full ||
                  b.status == LobbyStatus.inProgress ||
                  b.status == LobbyStatus.pendingCafeApproval;
              if (aActive != bActive) {
                return aActive ? -1 : 1;
              }
              return b.scheduledTime.compareTo(a.scheduledTime);
            });

            // UI hoàn toàn giống tab "Phòng chờ của tôi" trong lobby_hub:
            // cùng widget `LobbyCardBase` (horizontal row, full-width). Một UI
            // duy nhất cho 4 nơi hiển thị lobby/reservation để không drift.
            final hostedIds = state.hosted.map((h) => h.id).toSet();
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xs,
                AppSpacing.md,
                AppSpacing.xl,
              ),
              itemCount: lobbies.length,
              itemBuilder: (_, i) {
                final lobby = lobbies[i];
                final isMine = hostedIds.contains(lobby.id);
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: LobbyCardBase(
                    item: lobbyItemFromEntity(
                      lobby,
                      isOwnedByMe: isMine,
                    ),
                    onTap: () => onOpenLobby(lobby),
                  ),
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _LobbiesLoadingView extends StatelessWidget {
  const _LobbiesLoadingView();

  @override
  Widget build(BuildContext context) {
    // Tái sử dụng shimmer đã viết cho friends sheet (mỗi tile là
    // 48x48 circle + text lines).
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.xl,
      ),
      itemCount: 4,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, _) => LobbyFriendsShimmer(
        itemCount: 1,
        shrinkWrap: true,
      ),
    );
  }
}

// ─── Modern pill-style tab bar ────────────────────────────────────────────

class _ModernPillTabBar extends StatelessWidget {
  final TabController controller;
  final ThemeData theme;
  final ColorScheme colors;

  const _ModernPillTabBar({
    required this.controller,
    required this.theme,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: AppRadius.radiusFullAll,
      ),
      child: TabBar(
        controller: controller,
        isScrollable: false,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          gradient: LinearGradient(
            colors: [colors.primary, colors.primary.withAlpha(204)],
          ),
          borderRadius: AppRadius.radiusFullAll,
          boxShadow: [
            BoxShadow(
              color: colors.primary.withAlpha(64),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(2),
        labelColor: Colors.white,
        unselectedLabelColor: colors.onSurfaceVariant,
        labelStyle: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        labelPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        tabs: const [
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.event_note, size: 18),
                SizedBox(width: 6),
                Text('Lịch đặt'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.meeting_room, size: 18),
                SizedBox(width: 6),
                Text('Phòng chờ'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty / Error views ─────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  final VoidCallback onRefresh;
  const _EmptyView({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: AppRadius.radiusMdAll,
                border: Border.all(
                  color: colors.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.meeting_room_outlined,
                    size: 48,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Bạn chưa tạo hoặc tham gia phòng chờ nào.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return RefreshIndicator(
      onRefresh: () async => onRetry(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.errorContainer,
                borderRadius: AppRadius.radiusMdAll,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: colors.onErrorContainer,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          message,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Thử lại'),
                      style: TextButton.styleFrom(
                        foregroundColor: colors.onErrorContainer,
                      ),
                      onPressed: onRetry,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}