import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/neo_page_header.dart';
import '../../../matchmaking_discovery/presentation/cubit/matchmaking_cubit.dart';
import '../../../matchmaking_discovery/presentation/pages/board_game_detail_page.dart';
import '../cubit/saved_games_cubit.dart';
import '../cubit/survey_cubit.dart';
import '../cubit/survey_state.dart';
import '../widgets/beautiful_discovery_loader.dart';
import '../widgets/personalization_hint_card.dart';
import '../widgets/recommended_game_card.dart';
import 'survey_page.dart';

/// Màn hình kết quả gợi ý — hiển thị tách biệt với màn hình filter.
///
/// Flow:
/// - Player ở [SurveyPage] nhấn "ÁP DỤNG" → cubit chạy search →
///   push trang này.
/// - BlocProvider.value cung cấp CÙNG cubit instance với [SurveyPage]
///   nên không tốn thêm request. Khi back về, SurveyPage giữ được
///   state filter trước đó.
/// - Trong trang này:
///   - [SurveySearching] → [BeautifulDiscoveryLoader] (loading đẹp)
///   - [SurveySoloResults] / [SurveyPersonalizedResults] → list kết quả
///   - [SurveyEmpty] → empty state với nút "Chỉnh lại filter"
///   - [SurveyError] → error state với nút retry
class DiscoveryResultsPage extends StatefulWidget {
  /// SurveyCubit dùng chung với màn hình filter — truyền vào để giữ state
  /// và tránh tạo instance mới (mất kết quả vừa load).
  final SurveyCubit surveyCubit;

  /// SavedGamesCubit cũng phải truyền vào vì
  /// `RecommendedGameCard._CardSaveButton` dùng `BlocBuilder<SavedGamesCubit>`
  /// để đọc trạng thái saved/unsaved. Nếu thiếu → ProviderNotFoundException
  /// → Flutter render red error widget che mất thumbnail.
  final SavedGamesCubit savedGamesCubit;

  const DiscoveryResultsPage({
    super.key,
    required this.surveyCubit,
    required this.savedGamesCubit,
  });

  /// Helper để push trang kết quả từ bất kỳ đâu có context.
  ///
  /// Caller đảm bảo context có CẢ [SurveyCubit] VÀ [SavedGamesCubit]
  /// trong scope (thường là ngay sau khi `context.read<SurveyCubit>()`).
  static Future<void> push(
    BuildContext context, {
    required SurveyCubit surveyCubit,
    required SavedGamesCubit savedGamesCubit,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: surveyCubit),
            BlocProvider.value(value: savedGamesCubit),
          ],
          child: DiscoveryResultsPage(
            surveyCubit: surveyCubit,
            savedGamesCubit: savedGamesCubit,
          ),
        ),
      ),
    );
  }

  @override
  State<DiscoveryResultsPage> createState() => _DiscoveryResultsPageState();
}

class _DiscoveryResultsPageState extends State<DiscoveryResultsPage> {
  /// Navigator captured tại didChangeDependencies — dùng cho các
  /// callback pop/back thay vì `Navigator.of(context)` trực tiếp.
  /// Tránh "deactivated widget's ancestor" khi state thay đổi giữa
  /// lúc callback đang chạy.
  NavigatorState? _cachedNavigator;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _cachedNavigator = Navigator.of(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cubit = widget.surveyCubit;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      // ── HEADER: Neo-Brutalism style ───────────────────────────
      // Custom header (gradient primary + hard offset shadow + border 3px)
      // thay cho AppBar mặc định để đồng bộ với design system chung.
      // Height 88 = 32 safe-area top + 56 content (title 20 + 2 spacing +
      // subtitle 12 + 12*2 padding + 4 shadow offset). Nếu thấp hơn sẽ
      // gây overflow khi có subtitle.
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(88),
        child: NeoPageHeader(
          title: 'KẾT QUẢ GỢI Ý',
          subtitle: 'Tìm board game phù hợp với bạn',
          decorationIcon: Icons.casino_rounded,
          leading: NeoPageHeader.backButton(context),
          actions: [
            NeoHeaderIconButton(
              icon: Icons.refresh_rounded,
              tooltip: 'Làm mới',
              onPressed: () => cubit.refresh(),
            ),
          ],
        ),
      ),
      body: BlocBuilder<SurveyCubit, SurveyState>(
        bloc: cubit,
        builder: (context, state) {
          // ─── Đang tìm kiếm → loader đẹp ─────────────────────
          // Không wrap RefreshIndicator vì loading screen đã có animation
          // riêng; nếu user pull-down sẽ làm gián đoạn animation.
          if (state is SurveySearching) {
            return const BeautifulDiscoveryLoader();
          }

          // ─── Kết quả Solo Survey (filter-based) ────────────
          if (state is SurveySoloResults) {
            return _RefreshableScroll(
              onRefresh: () => cubit.refresh(),
              child: _SoloResultsList(
                games: state.games,
                soloMode: state.soloMode,
              ),
            );
          }

          // ─── Kết quả Personalized ──────────────────────────
          if (state is SurveyPersonalizedResults) {
            return _RefreshableScroll(
              onRefresh: () => cubit.refresh(),
              child: _PersonalizedResultsList(response: state.response),
            );
          }

          // ─── Không có kết quả ──────────────────────────────
          if (state is SurveyEmpty) {
            return _RefreshableScroll(
              onRefresh: () => cubit.refresh(),
              child: EmptyStateWidget(
                icon: Icons.search_off,
                title: 'Không tìm thấy game',
                message: state.message,
                actionLabel: 'Chỉnh lại filter',
                onAction: _popToFilter,
              ),
            );
          }

          // ─── Lỗi ──────────────────────────────────────────
          if (state is SurveyError) {
            return _RefreshableScroll(
              onRefresh: () => cubit.refresh(),
              child: ErrorStateWidget(
                message: state.message,
                onRetry: () => cubit.refresh(),
                retryLabel: 'Thử lại',
              ),
            );
          }

          // ─── States khác (Initial / Loading / CategoriesLoaded)
          // — quay về filter page là an toàn nhất. Vẫn cho
          // pull-to-refresh để user có thể retry từ trang này.
          return _RefreshableScroll(
            onRefresh: () => cubit.refresh(),
            child: EmptyStateWidget(
              icon: Icons.filter_alt_rounded,
              title: 'Chưa có kết quả',
              message: 'Hãy điều chỉnh filter và nhấn ÁP DỤNG để tìm game.',
              actionLabel: 'Mở filter',
              onAction: _popToFilter,
            ),
          );
        },
      ),
    );
  }

  /// Pop về filter page — dùng navigator cached để tránh truy cập
  /// BuildContext sau khi state thay đổi (deactivated ancestor).
  void _popToFilter() {
    final navigator = _cachedNavigator;
    if (navigator == null) return;
    if (navigator.canPop()) {
      navigator.pop();
    }
  }
}

// ─── Helpers (chuyển từ SurveyPage sang để dùng riêng cho results) ──────

class _SoloResultsList extends StatefulWidget {
  final List games;
  final SoloMode soloMode;

  const _SoloResultsList({
    required this.games,
    required this.soloMode,
  });

  @override
  State<_SoloResultsList> createState() => _SoloResultsListState();
}

class _SoloResultsListState extends State<_SoloResultsList> {
  NavigatorState? _cachedNavigator;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _cachedNavigator = Navigator.of(context);
  }

  @override
  Widget build(BuildContext context) {
    final games = widget.games;
    final isPersonalized = widget.soloMode == SoloMode.personalized;
    final navigator = _cachedNavigator;

    // Dùng Column thay cho ListView.separated vì parent
    // (_RefreshableScroll) đã cung cấp SingleChildScrollView.
    // Nếu dùng ListView ở đây → nested scrollable → crash "Vertical viewport
    // was given unbounded height".
    return Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ResultSummaryHeader(
              count: games.length,
              isPersonalized: isPersonalized,
            ),
            for (var i = 0; i < games.length; i++) ...[
              const SizedBox(height: AppSpacing.md),
              RecommendedGameCard(
                game: games[i],
                onTap: navigator == null
                    ? null
                    : () => openBoardGameDetailFromNavigator(
                          navigator,
                          context,
                          games[i].id,
                        ),
              ),
            ],
          ],
        ),
      );
  }
}

/// Push board-game detail page dùng navigator cached — tránh dùng
/// `Navigator.of(context)` trong tap callback có thể bị "deactivated"
/// sau khi state đổi.
void openBoardGameDetailFromNavigator(
  NavigatorState navigator,
  BuildContext context,
  String gameId,
) {
  final matchmakingCubit = context.read<MatchmakingCubit>();
  navigator.push(
    MaterialPageRoute(
      builder: (_) => BoardGameDetailPage(
        gameId: gameId,
        matchmakingCubit: matchmakingCubit,
      ),
    ),
  );
}

class _ResultSummaryHeader extends StatelessWidget {
  final int count;
  final bool isPersonalized;

  const _ResultSummaryHeader({
    required this.count,
    required this.isPersonalized,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceContainerDark
            : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isPersonalized
                  ? const Color(0xFF7B2FF7)
                  : AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.sports_esports_rounded,
              size: 14,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
                ),
                children: [
                  TextSpan(text: 'Tìm thấy '),
                  TextSpan(
                    text: '$count',
                    style: TextStyle(
                      color: isPersonalized
                          ? const Color(0xFF7B2FF7)
                          : AppColors.primary,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const TextSpan(text: ' game phù hợp'),
                ],
              ),
            ),
          ),
          if (isPersonalized)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF7B2FF7).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'AI',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF7B2FF7),
                  letterSpacing: 1.0,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PersonalizedResultsList extends StatefulWidget {
  final dynamic response;

  const _PersonalizedResultsList({required this.response});

  @override
  State<_PersonalizedResultsList> createState() =>
      _PersonalizedResultsListState();
}

class _PersonalizedResultsListState extends State<_PersonalizedResultsList> {
  NavigatorState? _cachedNavigator;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _cachedNavigator = Navigator.of(context);
  }

  @override
  Widget build(BuildContext context) {
    final games = widget.response.games as List;
    final profile = widget.response.userProfile;
    final navigator = _cachedNavigator;

    // Dùng Column thay cho ListView vì parent (_RefreshableScroll) đã cung
    // cấp SingleChildScrollView. ListView ở đây sẽ tạo nested scrollable
    // → crash "Vertical viewport was given unbounded height".
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Personalization hint
          if (profile != null) PersonalizationHintCard(profile: profile),
          if (profile != null) const SizedBox(height: AppSpacing.md),

          // Games list
          ...games.map((game) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: RecommendedGameCard(
                game: game,
                onTap: navigator == null
                    ? null
                    : () => openBoardGameDetailFromNavigator(
                          navigator,
                          context,
                          game.id,
                        ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ============================================================================
// _RefreshableScroll — Wrap child trong RefreshIndicator để pull-to-refresh.
// ============================================================================
//
// RefreshIndicator của Flutter BẮT BUỘC phải có một scrollable widget
// (ListView, SingleChildScrollView, ...) làm con trực tiếp để phát hiện
// pull gesture. Khi child là EmptyStateWidget / ErrorStateWidget không
// scroll được, wrap trong SingleChildScrollView với AlwaysScrollable
// physics để indicator vẫn hoạt động trên empty/error states.
//
// **Mounted check**: cubit có thể bị close giữa lúc await (user back ra
// khỏi page trong khi refresh). Wrap trong try/catch + check `mounted`
// của widget hiện tại để tránh lỗi "Cannot emit new states after close".
class _RefreshableScroll extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onRefresh;

  const _RefreshableScroll({
    required this.child,
    required this.onRefresh,
  });

  @override
  State<_RefreshableScroll> createState() => _RefreshableScrollState();
}

class _RefreshableScrollState extends State<_RefreshableScroll> {
  /// Key cho SingleChildScrollView bên ngoài để child có thể reset
  /// scroll position khi state đổi (empty → results, etc.).
  final GlobalKey _scrollKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      // Pull-down distance mặc định của Flutter là 140px — đủ rõ cho
      // user thấy gesture nhưng không quá dài.
      displacement: 80,
      color: AppColors.primary,
      backgroundColor: Colors.white,
      strokeWidth: 3,
      onRefresh: () async {
        try {
          await widget.onRefresh();
        } catch (_) {
          // Swallow exception từ cubit (đã có ErrorStateWidget handle
          // phần user-facing). Tránh để exception làm crash app.
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Đảm bảo SingleChildScrollView có chiều cao tối thiểu =
          // viewport hiện tại. Nếu không, khi child là EmptyState /
          // ErrorState (chiếm ít không gian), RefreshIndicator sẽ
          // không pull-down được vì không có đủ content để overflow.
          final viewportHeight = constraints.hasBoundedHeight
              ? constraints.maxHeight
              : MediaQuery.of(context).size.height;
          return SingleChildScrollView(
            key: _scrollKey,
            physics: const AlwaysScrollableScrollPhysics(
              // Parent BouncingScrollPhysics cho cảm giác iOS-style bounce.
              parent: BouncingScrollPhysics(),
            ),
            // EdgeInsets.zero vì child tự quản lý padding của nó.
            padding: EdgeInsets.zero,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: viewportHeight),
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}