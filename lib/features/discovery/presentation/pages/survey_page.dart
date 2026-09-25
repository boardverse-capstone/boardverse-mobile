import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/neo_brutalism_theme.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../domain/entities/discovery_request_entity.dart';
import '../../domain/repositories/discovery_repository.dart';
import '../cubit/saved_games_cubit.dart';
import '../cubit/survey_cubit.dart';
import '../cubit/survey_state.dart';
import '../widgets/discovery_shimmer.dart';
import '../widgets/group_score_breakdown_card.dart';
import '../widgets/personalization_hint_card.dart';
import '../widgets/recommended_game_card.dart';
import '../widgets/solo_mode_inner_toggle.dart';
import '../widgets/survey_filter_sheet.dart';
import '../widgets/survey_mode_tabs.dart';

/// Trang chính cho chức năng Survey / Discovery.
///
/// Layout:
/// - AppBar có filter button
/// - Hero header gradient với tiêu đề + sub-title
/// - Mode tabs (Solo / Nhóm)
/// - Tab content với toggle inner cho Solo
class SurveyPage extends StatelessWidget {
  const SurveyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => getIt<SurveyCubit>()..loadCategories(),
        ),
        BlocProvider(
          create: (_) => getIt<SavedGamesCubit>(),
        ),
      ],
      child: const _SurveyPageContent(),
    );
  }
}

class _SurveyPageContent extends StatefulWidget {
  const _SurveyPageContent();

  @override
  State<_SurveyPageContent> createState() => _SurveyPageContentState();
}

class _SurveyPageContentState extends State<_SurveyPageContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    // Tab changed — UI rebuilds via BlocBuilder
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ─── SliverAppBar với gradient hero ─────────────────────────────
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            stretch: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            flexibleSpace: const _DiscoveryHeroHeader(),
            actions: [
              BlocBuilder<SurveyCubit, SurveyState>(
                builder: (context, state) {
                  final canFilter = state is SurveyCategoriesLoaded ||
                      state is SurveySoloResults ||
                      state is SurveyPersonalizedResults ||
                      state is SurveyEmpty ||
                      (state is SurveyError &&
                          state.categories != null &&
                          state.categories!.isNotEmpty);

                  if (!canFilter) return const SizedBox.shrink();

                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: _FilterIconButton(
                      onPressed: () => _showFilterSheet(context),
                    ),
                  );
                },
              ),
            ],
          ),

          // ─── Mode tabs (sticky-ish) ────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.xs,
              ),
              child: SurveyModeTabs(
                selectedIndex: _tabController.index,
                onChanged: (i) => _tabController.animateTo(i),
              ),
            ),
          ),

          // ─── Tab content ───────────────────────────────────────────────
          SliverFillRemaining(
            hasScrollBody: true,
            child: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _SoloTabContent(onFilterTap: () => _showFilterSheet(context)),
                _GroupTabContent(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    final state = context.read<SurveyCubit>().state;
    List<dynamic> categories = [];
    dynamic currentRequest;

    if (state is SurveyCategoriesLoaded) {
      categories = state.categories;
      currentRequest = state.currentRequest;
    } else if (state is SurveySoloResults) {
      categories = state.categories;
      currentRequest = state.currentRequest;
    } else if (state is SurveyPersonalizedResults) {
      categories = state.categories;
      currentRequest = state.currentRequest;
    } else if (state is SurveyEmpty) {
      categories = state.categories;
      currentRequest = state.currentRequest;
    } else if (state is SurveyError && state.categories != null) {
      categories = state.categories!;
      currentRequest = state.currentRequest;
    }

    if (categories.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SurveyFilterSheet(
        currentRequest: currentRequest ?? const DiscoveryRequestEntity(),
        categories: categories.cast(),
        onApply: (request) {
          context.read<SurveyCubit>().searchWithRequest(request);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero header
// ─────────────────────────────────────────────────────────────────────────────

class _DiscoveryHeroHeader extends StatelessWidget {
  const _DiscoveryHeroHeader();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SurveyCubit, SurveyState>(
      builder: (context, state) {
        final hasPersonalization = _hasPersonalization(state);
        final isDark = Theme.of(context).brightness == Brightness.dark;

        final gradient = hasPersonalization
            ? const [Color(0xFF7B2FF7), Color(0xFF3D1E78)]
            : AppColors.cardGradientDiscovery;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient,
            ),
            border: Border(
              bottom: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.border,
                width: 3,
              ),
            ),
          ),
          child: Stack(
            children: [
              // Decorative shapes
              Positioned(
                top: -20,
                right: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                bottom: -30,
                right: 60,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              // Decorative dots
              Positioned(
                top: 36,
                right: 70,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                bottom: 30,
                right: 130,
                child: Container(
                  width: 4,
                  height: 4,
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.45),
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              hasPersonalization
                                  ? Icons.auto_awesome_rounded
                                  : Icons.explore_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    hasPersonalization
                                        ? 'AI GỢI Ý'
                                        : 'KHẢO SÁT',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 9,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  hasPersonalization
                                      ? 'Gợi ý cá nhân hóa'
                                      : 'Khảo sát gợi ý Board Game',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 19,
                                    letterSpacing: -0.5,
                                    height: 1.1,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Padding(
                        padding: const EdgeInsets.only(left: 52),
                        child: Text(
                          hasPersonalization
                              ? 'Dựa trên sở thích & lịch sử chơi của bạn'
                              : 'Không biết chơi gì? Để BoardVerse gợi ý!',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  bool _hasPersonalization(SurveyState state) {
    if (state is SurveyCategoriesLoaded) {
      return state.hasPersonalizationEligible;
    }
    if (state is SurveySoloResults) {
      return state.hasPersonalizationEligible;
    }
    if (state is SurveyPersonalizedResults) {
      return state.hasPersonalizationEligible;
    }
    if (state is SurveyEmpty) {
      return state.hasPersonalizationEligible;
    }
    if (state is SurveyError) {
      return state.hasPersonalizationEligible ?? false;
    }
    return false;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter icon button
// ─────────────────────────────────────────────────────────────────────────────

class _FilterIconButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _FilterIconButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 40,
          height: 40,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.45),
              width: 2,
            ),
          ),
          child: const Icon(
            Icons.tune_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }
}

// ─── Solo Tab ────────────────────────────────────────────────────────────────

class _SoloTabContent extends StatelessWidget {
  final VoidCallback onFilterTap;

  const _SoloTabContent({required this.onFilterTap});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SurveyCubit, SurveyState>(
      builder: (context, state) {
        // Solo inner toggle (chỉ khi categories đã load)
        Widget? header;
        if (state is SurveyCategoriesLoaded ||
            state is SurveySoloResults ||
            state is SurveyPersonalizedResults ||
            state is SurveyEmpty) {
          final mode = state is SurveyCategoriesLoaded
              ? state.soloMode
              : state is SurveySoloResults
                  ? state.soloMode
                  : state is SurveyEmpty
                      ? state.soloMode
                      : SoloMode.personalized;
          final hasEligible = state is SurveyCategoriesLoaded
              ? state.hasPersonalizationEligible
              : state is SurveySoloResults
                  ? state.hasPersonalizationEligible
                  : state is SurveyEmpty
                      ? state.hasPersonalizationEligible
                      : false;

          header = Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            child: SoloModeInnerToggle(
              currentMode: mode,
              isEligible: hasEligible,
              onChanged: (m) => context.read<SurveyCubit>().switchSoloMode(m),
            ),
          );
        }

        return Column(
          children: [
            if (header != null) header,
            Expanded(child: _buildBody(context, state)),
          ],
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, SurveyState state) {
    if (state is SurveyLoading) {
      return const DiscoveryShimmer();
    }

    if (state is SurveyCategoriesLoaded) {
      return _EmptySurveyView(onFilterTap: onFilterTap);
    }

    if (state is SurveySearching) {
      return const DiscoveryShimmer();
    }

    if (state is SurveySoloResults) {
      return _SoloResultsList(games: state.games, state: state);
    }

    if (state is SurveyPersonalizedResults) {
      return _PersonalizedResultsList(
        response: state.response,
        state: state,
      );
    }

    if (state is SurveyEmpty) {
      return EmptyStateWidget(
        icon: Icons.search_off,
        title: 'Không tìm thấy game',
        message: state.message,
        actionLabel: 'Điều chỉnh bộ lọc',
        onAction: onFilterTap,
      );
    }

    if (state is SurveyError) {
      return ErrorStateWidget(
        message: state.message,
        onRetry: () => context.read<SurveyCubit>().loadCategories(),
      );
    }

    return const SizedBox.shrink();
  }
}

class _EmptySurveyView extends StatelessWidget {
  final VoidCallback onFilterTap;

  const _EmptySurveyView({required this.onFilterTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          // Hero illustration card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xl,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        AppColors.primaryDark,
                        AppColors.accentDark,
                      ]
                    : AppColors.cardGradientDiscovery,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.border,
                width: 3,
              ),
              boxShadow: NeoBrutalismTheme.lightShadow(
                shadowColor: AppColors.primary.withValues(alpha: 0.5),
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -20,
                  right: -20,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  bottom: -30,
                  left: -20,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.45),
                          width: 2.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.rocket_launch_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'BẮT ĐẦU KHẢO SÁT',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Tìm game phù hợp\nvới nhóm bạn',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        letterSpacing: -0.5,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Cho mình biết số người chơi, thể loại và thời gian bạn muốn — BoardVerse sẽ gợi ý những game hoàn hảo nhất!',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onFilterTap,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md + 2,
                            vertical: AppSpacing.sm + 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.borderDark
                                  : AppColors.border,
                              width: 2.5,
                            ),
                            boxShadow: NeoBrutalismTheme.lightShadow(
                              shadowColor: Colors.black.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.tune_rounded,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Mở bộ lọc',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 14,
                                color: AppColors.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Quick feature cards
          Row(
            children: [
              Expanded(
                child: _FeatureMiniCard(
                  icon: Icons.bolt_rounded,
                  title: 'Nhanh chóng',
                  subtitle: '< 30 giây',
                  color: AppColors.accent,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _FeatureMiniCard(
                  icon: Icons.psychology_rounded,
                  title: 'Thông minh',
                  subtitle: 'AI phân tích',
                  color: AppColors.secondary,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureMiniCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool isDark;

  const _FeatureMiniCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm + 2),
      decoration: NeoBrutalismTheme.autoBox(
        context,
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderColor: color.withValues(alpha: 0.5),
        borderRadius: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.4), width: 2),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _SoloResultsList extends StatelessWidget {
  final dynamic games;
  final SurveyState state;

  const _SoloResultsList({required this.games, required this.state});

  @override
  Widget build(BuildContext context) {
    // Pre-extract type-narrowed state values trước khi vào closure
    // vì Dart không thể narrow type trong itemBuilder.
    final soloResults =
        state is SurveySoloResults ? state as SurveySoloResults : null;
    final isPersonalized =
        soloResults != null && soloResults.soloMode == SoloMode.personalized;

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      itemCount: games.length + 1, // +1 cho header summary
      separatorBuilder: (_, index) {
        if (index == 0) return const SizedBox.shrink();
        return const SizedBox(height: AppSpacing.md);
      },
      itemBuilder: (context, i) {
        if (i == 0) {
          return _ResultSummaryHeader(
            count: games.length,
            isPersonalized: isPersonalized,
          );
        }
        final game = games[i - 1];
        return RecommendedGameCard(
          game: game,
          onTap: () {
            // TODO: Navigate to game detail
          },
        );
      },
    );
  }
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

class _PersonalizedResultsList extends StatelessWidget {
  final dynamic response;
  final SurveyState state;

  const _PersonalizedResultsList({
    required this.response,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final games = response.games as List;
    final profile = response.userProfile;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      children: [
        // Personalization hint
        if (profile != null) PersonalizationHintCard(profile: profile),
        const SizedBox(height: AppSpacing.md),

        // Games list
        ...games.map((game) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: RecommendedGameCard(
              game: game,
              onTap: () {},
            ),
          );
        }),
      ],
    );
  }
}

// ─── Group Tab ──────────────────────────────────────────────────────────────

class _GroupTabContent extends StatefulWidget {
  @override
  State<_GroupTabContent> createState() => _GroupTabContentState();
}

class _GroupTabContentState extends State<_GroupTabContent> {
  final List<_MemberEntry> _members = [
    _MemberEntry(playerCount: 2),
  ];

  void _addMember() {
    if (_members.length >= 10) return;
    setState(() => _members.add(_MemberEntry(playerCount: 2)));
  }

  void _removeMember(int index) {
    if (_members.length <= 1) return;
    setState(() => _members.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<SurveyCubit, SurveyState>(
      builder: (context, state) {
        // Nếu đang có results → hiển thị results screen
        if (state is SurveyGroupResults) {
          return _GroupResultsList(state: state);
        }

        if (state is SurveySearching) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: DiscoveryShimmer(itemCount: 3),
          );
        }

        // Setup screen
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            // Header explainer
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: AppColors.cardGradientGroup,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.border,
                  width: 2.5,
                ),
                boxShadow: NeoBrutalismTheme.lightShadow(
                  shadowColor: AppColors.secondary.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.45),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.groups_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'GỢI Ý CHO NHÓM',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w900,
                            fontSize: 9,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Thêm thành viên & số người',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // Members list
            ..._members.asMap().entries.map((entry) {
              final i = entry.key;
              final member = entry.value;
              return _MemberCard(
                key: ValueKey(member),
                index: i,
                entry: member,
                onPlayerCountChanged: (v) {
                  setState(() {
                    _members[i] = member.copyWith(playerCount: v);
                  });
                },
                onRemove: _members.length > 1 ? () => _removeMember(i) : null,
              );
            }),
            const SizedBox(height: AppSpacing.md),
            if (_members.length < 10)
              _AddMemberButton(onPressed: _addMember),
            const SizedBox(height: AppSpacing.lg),
            _FindGameButton(
              onPressed: () {
                final members = _members.map((e) {
                  return MemberPreferenceRequest(playerCount: e.playerCount);
                }).toList();
                context.read<SurveyCubit>().discoverForGroup(members);
              },
              memberCount: _members.length,
            ),
          ],
        );
      },
    );
  }
}

class _GroupResultsList extends StatelessWidget {
  final SurveyGroupResults state;

  const _GroupResultsList({required this.state});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: state.games.length + 1,
      separatorBuilder: (_, index) {
        if (index == 0) return const SizedBox.shrink();
        return const SizedBox(height: AppSpacing.md);
      },
      itemBuilder: (context, i) {
        if (i == 0) {
          return _GroupResultHeader(count: state.games.length);
        }
        return GroupScoreBreakdownCard(game: state.games[i - 1]);
      },
    );
  }
}

class _GroupResultHeader extends StatelessWidget {
  final int count;

  const _GroupResultHeader({required this.count});

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
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.groups_rounded,
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
                  const TextSpan(text: 'Tìm thấy '),
                  TextSpan(
                    text: '$count',
                    style: const TextStyle(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const TextSpan(text: ' game cho nhóm'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddMemberButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _AddMemberButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm + 2),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.secondary,
              width: 2.5,
            ),
            boxShadow: NeoBrutalismTheme.lightShadow(
              shadowColor: AppColors.secondary.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor, width: 1.5),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Thêm thành viên',
                style: TextStyle(
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FindGameButton extends StatefulWidget {
  final VoidCallback onPressed;
  final int memberCount;

  const _FindGameButton({
    required this.onPressed,
    required this.memberCount,
  });

  @override
  State<_FindGameButton> createState() => _FindGameButtonState();
}

class _FindGameButtonState extends State<_FindGameButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md + 2),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [AppColors.secondary, AppColors.secondaryDark],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 3),
            boxShadow: NeoBrutalismTheme.lightShadow(
              shadowColor: AppColors.secondary.withValues(alpha: 0.55),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.search_rounded,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'TÌM GAME CHO ${widget.memberCount} THÀNH VIÊN',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 0.8,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      offset: const Offset(1, 1),
                      blurRadius: 0,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MemberEntry {
  final int playerCount;
  _MemberEntry({required this.playerCount});
  _MemberEntry copyWith({int? playerCount}) =>
      _MemberEntry(playerCount: playerCount ?? this.playerCount);
}

class _MemberCard extends StatelessWidget {
  final int index;
  final _MemberEntry entry;
  final ValueChanged<int> onPlayerCountChanged;
  final VoidCallback? onRemove;

  const _MemberCard({
    super.key,
    required this.index,
    required this.entry,
    required this.onPlayerCountChanged,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;

    final accentColor = AppColors.secondary;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 2.5),
        boxShadow: NeoBrutalismTheme.lightShadow(
          shadowColor: accentColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          // Avatar circle with index
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        AppColors.surfaceElevatedDark,
                        AppColors.surfaceContainerDark,
                      ]
                    : AppColors.cardGradientTeal,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 2),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Thành viên ${index + 1}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${entry.playerCount} người',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: accentColor,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: accentColor,
                    inactiveTrackColor:
                        accentColor.withValues(alpha: 0.2),
                    thumbColor: accentColor,
                    overlayColor: accentColor.withValues(alpha: 0.15),
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 8,
                    ),
                  ),
                  child: Slider(
                    value: entry.playerCount.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    onChanged: (v) => onPlayerCountChanged(v.round()),
                  ),
                ),
              ],
            ),
          ),
          if (onRemove != null)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onRemove,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: AppColors.error,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
