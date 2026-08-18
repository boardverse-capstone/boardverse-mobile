import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:boardverse/core/navigation/tournament_routes.dart';
import 'package:boardverse/core/theme/app_colors.dart';
import 'package:boardverse/core/theme/app_icons.dart';
import 'package:boardverse/core/theme/app_spacing.dart';
import 'package:boardverse/features/tournament/domain/entities/tournament_entity.dart';
import 'package:boardverse/features/tournament/presentation/cubit/tournament_list_cubit.dart';
import 'package:boardverse/features/tournament/presentation/cubit/tournament_list_state.dart';
import 'package:boardverse/features/tournament/presentation/widgets/tournament_hero.dart';
import 'package:boardverse/features/tournament/presentation/widgets/tournament_filter_section.dart';
import 'package:boardverse/features/tournament/presentation/widgets/tournament_error_state.dart';
import 'package:boardverse/features/tournament/presentation/widgets/tournament_list_card.dart';
import 'package:boardverse/features/tournament/presentation/widgets/tournament_skeleton.dart';
import 'package:boardverse/features/tournament/presentation/utils/tournament_utils.dart';

/// Tournament tab page.
///
/// Tạo `TournamentListCubit` **trong `initState` thay vì trong `build()`**
/// để tránh vòng lặp vô tận — tương tự bug `HomeOverviewPage` đã fix
/// trước đó. Nếu tạo cubit trong `build()` qua `BlocProvider(create: ...)`,
/// mỗi lần parent rebuild (do `NavigationCubit` state change, hoặc do
/// cubit emit state mới) sẽ tạo instance MỚI → gọi `loadTournaments()` →
/// emit `TournamentListLoading` → rebuild → loop.
class TournamentPage extends StatefulWidget {
  const TournamentPage({super.key});

  @override
  State<TournamentPage> createState() => _TournamentPageState();
}

class _TournamentPageState extends State<TournamentPage> {
  @override
  void initState() {
    super.initState();
    // `PostFrameCallback` đảm bảo `BlocProvider` cha (app root) đã sẵn sàng
    // trước khi `read<TournamentListCubit>()` chạy.
    //
    // KHÔNG dùng guard `state is TournamentListInitial` vì:
    // ActivityPage gọi `loadOpenTournamentsOnly()` khi mount → state thành
    // `TournamentListLoaded`. Khi user bấm "Giải đấu" vào TournamentPage,
    // guard check → condition FAIL → loadTournaments() không bao giờ chạy.
    // Giải pháp: LUÔN gọi loadTournaments() khi TournamentPage mount.
    // Cubit có thể fetch trùng (nếu đã load trước) nhưng đây là trade-off
    // an toàn — đảm bảo user luôn thấy data mới nhất khi vào trang.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<TournamentListCubit>().loadTournaments();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const _TournamentPageContent();
  }
}

class _TournamentPageContent extends StatefulWidget {
  const _TournamentPageContent();

  @override
  State<_TournamentPageContent> createState() => _TournamentPageContentState();
}

class _TournamentPageContentState extends State<_TournamentPageContent> {
  static const _heroHeight = 140.0;
  int _selectedFilter = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: BlocBuilder<TournamentListCubit, TournamentListState>(
        builder: (context, state) {
          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                automaticallyImplyLeading: false,
                pinned: true,
                expandedHeight: _heroHeight,
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                elevation: 0,
                scrolledUnderElevation: 0,
                actions: [
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.black, width: 2),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.black,
                          blurRadius: 0,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                    child: PopupMenuButton<_TournamentMenuAction>(
                      tooltip: 'Tùy chọn',
                      icon: const Icon(Icons.more_vert_rounded, color: AppColors.black),
                      onSelected: (action) => _onMenuAction(context, action),
                      itemBuilder: (popupContext) => const [
                        PopupMenuItem(
                          value: _TournamentMenuAction.myRegistrations,
                          child: ListTile(
                            leading: Icon(Icons.assignment_outlined),
                            title: Text('Giải của tôi'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        PopupMenuItem(
                          value: _TournamentMenuAction.eloHistory,
                          child: ListTile(
                            leading: Icon(Icons.trending_up),
                            title: Text('Lịch sử Elo'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        PopupMenuItem(
                          value: _TournamentMenuAction.leaderboard,
                          child: ListTile(
                            leading: Icon(Icons.leaderboard_outlined),
                            title: Text('Bảng xếp hạng'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(
                    left: AppSpacing.md,
                    bottom: AppSpacing.md,
                  ),
                  title: const Text(
                    'GIẢI ĐẤU',
                    style: TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      shadows: [
                        Shadow(
                          color: AppColors.black,
                          offset: Offset(0, 2),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                  background: TournamentHero(state: state),
                ),
              ),
              SliverToBoxAdapter(
                child: TournamentFilterSection(
                  selectedFilter: _selectedFilter,
                  onFilterChanged: (index) => setState(() => _selectedFilter = index),
                ),
              ),
            ],
            body: _buildBody(context, state),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, TournamentListState state) {
    // Pull-to-refresh phải hoạt động ở MỌI trạng thái của list, không chỉ
    // khi đã load xong và có data. Wrap toàn bộ body trong một
    // [RefreshIndicator] duy nhất với child luôn là scrollable widget
    // (physics: AlwaysScrollableScrollPhysics) để gesture kéo xuống từ
    // mọi vị trí đều kích hoạt được — kể cả khi list rỗng, đang loading
    // hay đang error.
    final cubit = context.read<TournamentListCubit>();

    Widget child;
    if (state is TournamentListLoading || state is TournamentListInitial) {
      child = TournamentSkeleton.list();
    } else if (state is TournamentListError) {
      child = TournamentErrorState(
        message: state.message,
        onRetry: () => cubit.loadTournaments(),
      );
    } else if (state is TournamentListLoaded) {
      final filtered = TournamentUtils.filterTournaments(state, _selectedFilter);

      if (filtered.isEmpty) {
        child = const _TournamentEmptyPlaceholder();
      } else {
        child = ListView.builder(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.massive,
          ),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final tournament = filtered[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: TournamentListCard(
                tournament: tournament,
                onTap: () => _showTournamentDetail(context, tournament),
              ),
            );
          },
        );
      }
    } else {
      child = const SizedBox.shrink();
    }

    return RefreshIndicator(
      onRefresh: () => cubit.refresh(),
      child: _AlwaysScrollable(child: child),
    );
  }

  void _showTournamentDetail(BuildContext context, TournamentEntity tournament) {
    TournamentRoutes.openTournamentDetail(
      context: context,
      tournamentId: tournament.id,
    );
  }

  void _onMenuAction(BuildContext context, _TournamentMenuAction action) {
    switch (action) {
      case _TournamentMenuAction.myRegistrations:
        TournamentRoutes.openMyRegistrations(context);
        break;
      case _TournamentMenuAction.eloHistory:
        TournamentRoutes.openEloHistory(context);
        break;
      case _TournamentMenuAction.leaderboard:
        TournamentRoutes.openLeaderboard(context);
        break;
    }
  }
}

/// Menu actions exposed from the tournament page popup menu.
enum _TournamentMenuAction {
  myRegistrations,
  eloHistory,
  leaderboard,
}

class _TournamentEmptyPlaceholder extends StatelessWidget {
  const _TournamentEmptyPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              AppIcons.tournament,
              size: AppIcons.xxl * 2,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Không có giải đấu nào',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Hãy quay lại sau để cập nhật thông tin mới nhất.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Wrapper để đảm bảo [RefreshIndicator] cha luôn nhận được pull gesture —
/// kể cả khi child không phải scrollable widget (ví dụ `Center` placeholder
/// rỗng hay `TournamentErrorState` không cuộn được).
///
/// Cách hoạt động:
/// - Với child đã là scrollable widget (vd: `ListView`, `GridView`),
///   truyền thẳng qua — tránh nested scroll gây giật và tránh double
///   physics conflict.
/// - Với child KHÔNG scrollable (Center, Column), wrap trong
///   `SingleChildScrollView` với `AlwaysScrollableScrollPhysics` để gesture
///   kéo xuống vẫn bắt được, kể cả khi nội dung ngắn.
class _AlwaysScrollable extends StatelessWidget {
  const _AlwaysScrollable({required this.child});

  final Widget child;

  bool _isAlreadyScrollable(Widget widget) {
    // Heuristic: các widget thường gặp đã cuộn được. Không thể introspect
    // runtime type generic nên ta check qua type chain.
    return widget is ListView ||
        widget is GridView ||
        widget is SingleChildScrollView ||
        widget is NestedScrollView ||
        widget is CustomScrollView;
  }

  @override
  Widget build(BuildContext context) {
    if (_isAlreadyScrollable(child)) {
      return child;
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        // Đảm bảo child chiếm đủ chiều cao để RefreshIndicator nhận gesture
        // kéo xuống từ bất kỳ vị trí nào, kể cả khi nội dung ngắn hơn
        // viewport.
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight.isFinite
                  ? constraints.maxHeight
                  : 0,
            ),
            child: child,
          ),
        );
      },
    );
  }
}
