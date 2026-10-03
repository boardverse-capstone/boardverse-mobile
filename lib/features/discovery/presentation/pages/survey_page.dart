import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/neo_page_header.dart';
import '../../domain/entities/discovery_request_entity.dart';
import '../../domain/entities/game_category_discovery_entity.dart';
import '../cubit/saved_games_cubit.dart';
import '../cubit/survey_cubit.dart';
import '../cubit/survey_state.dart';
import '../widgets/discovery_shimmer.dart';
import '../widgets/survey_filter_form.dart';
import 'discovery_results_page.dart';

/// Trang **chỉ chứa bộ lọc** cho chức năng Survey / Discovery.
///
/// Khi player nhấn "ÁP DỤNG":
/// 1. Form gọi [SurveyCubit.searchWithRequest] → cubit chuyển sang
///    [SurveySearching].
/// 2. Ngay lập tức push [DiscoveryResultsPage] lên stack — trang này
///    dùng chung cubit (qua [BlocProvider.value]) nên không tốn thêm
///    request và tự động chuyển từ loader → results khi cubit emit
///    state mới.
///
/// Kết quả gợi ý KHÔNG hiển thị ở đây — player nhấn back từ results
/// để quay lại filter, giữ nguyên state filter đã chọn.
class SurveyPage extends StatelessWidget {
  const SurveyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => getIt<SurveyCubit>()..loadCategories(),
        ),
        // `SavedGamesCubit` là LazySingleton được cung cấp bởi
        // `MainScaffold` qua `BlocProvider.value(...)`. Dùng
        // `BlocProvider.value` (không phải `create:`) để TIẾP TỤC dùng
        // chung instance đó mà KHÔNG gọi `close()` khi SurveyPage bị
        // dispose. Nếu dùng `create:`, cubit bị close → lần mở
        // `SavedGamesPage` sau sẽ treo loading vĩnh viễn (vì emit
        // throw trước khi gọi API).
        BlocProvider<SavedGamesCubit>.value(
          value: getIt<SavedGamesCubit>(),
        ),
      ],
      child: const _SurveyPageContent(),
    );
  }
}

class _SurveyPageContent extends StatelessWidget {
  const _SurveyPageContent();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      // ── HEADER: Neo-Brutalism style ─────────────────────────────
      // Custom header đồng bộ với DiscoveryResultsPage và design system
      // chung. Gradient cam + hard offset shadow + border 3px.
      // Height 88 = 32 safe-area top + 56 content (title 20 + 2 spacing +
      // subtitle 12 + 12*2 padding + 4 shadow offset). Nếu thấp hơn sẽ
      // gây overflow khi có subtitle.
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(88),
        child: NeoPageHeader(
          title: 'KHẢO SÁT GỢI Ý',
          subtitle: 'Tìm board game hoàn hảo cho bạn',
          decorationIcon: Icons.travel_explore_rounded,
          leading: NeoPageHeader.backButton(context),
        ),
      ),
      // Trang này chỉ chứa filter. Mọi state không phải loading
      // đều hiển thị form để user chỉnh sửa (kể cả sau khi đã có
      // results — back từ results là phải thấy lại filter).
      body: const _FilterOnlyBody(),
    );
  }
}

// ─── Filter-only body ─────────────────────────────────────────────────────

class _FilterOnlyBody extends StatefulWidget {
  const _FilterOnlyBody();

  @override
  State<_FilterOnlyBody> createState() => _FilterOnlyBodyState();
}

class _FilterOnlyBodyState extends State<_FilterOnlyBody> {
  /// Navigator reference captured từ `didChangeDependencies` — dùng cho
  /// `_onApply` thay vì `Navigator.of(context)` trực tiếp. Tránh trường
  /// hợp context bị "deactivated" giữa frame (ví dụ: emit state trong
  /// cùng microtask với push → framework đánh dấu widget ancestors
  /// là unsafe).
  NavigatorState? _cachedNavigator;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Capture navigator an toàn tại đây — context chắc chắn mounted.
    _cachedNavigator = Navigator.of(context);
  }

  /// Trích categories + currentRequest từ cubit state.
  ///
  /// Trả về null khi:
  /// - [SurveyLoading] / [SurveyInitial] → chưa có categories
  /// - [SurveySearching] → không có categories (rare) hoặc state bất thường
  ///
  /// Mọi state còn lại đều có data (categories + currentRequest) → vẫn
  /// hiển thị filter form bình thường.
  _FilterFormData? _resolveFormData(SurveyState state) {
    if (state is SurveyCategoriesLoaded) {
      return _FilterFormData(state.categories, state.currentRequest);
    }
    if (state is SurveySoloResults) {
      return _FilterFormData(state.categories, state.currentRequest);
    }
    if (state is SurveyPersonalizedResults) {
      return _FilterFormData(state.categories, state.currentRequest);
    }
    if (state is SurveySearching) {
      return _FilterFormData(state.categories, state.currentRequest);
    }
    if (state is SurveyEmpty) {
      return _FilterFormData(state.categories, state.currentRequest);
    }
    if (state is SurveyError && state.categories != null) {
      return _FilterFormData(
        state.categories!,
        state.currentRequest ?? const DiscoveryRequestEntity(),
      );
    }
    return null;
  }

  /// Player nhấn "ÁP DỤNG" trong filter form.
  ///
  /// Flow:
  /// 1. Forward request cho cubit (sẽ emit [SurveySearching] trong
  ///    microtask tiếp theo).
  /// 2. **Defer** push [DiscoveryResultsPage] sang frame kế tiếp bằng
  ///    `addPostFrameCallback`. Nếu push ngay trong cùng frame với
  ///    state emit, Navigator có thể thấy ancestor "deactivated" →
  ///    ném "Looking up a deactivated widget's ancestor is unsafe".
  ///
  /// Mounted check đảm bảo không push khi State đã dispose (user back
  /// ra khỏi filter page trong lúc microtask chạy).
  void _onApply(DiscoveryRequestEntity request) {
    final surveyCubit = context.read<SurveyCubit>();
    final savedGamesCubit = context.read<SavedGamesCubit>();
    final navigator = _cachedNavigator;
    if (navigator == null) return;

    surveyCubit.searchWithRequest(request);

    // Defer push sang post-frame để tránh deactivated-ancestor warning.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      navigator.push(
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
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SurveyCubit, SurveyState>(
      // Sử dụng `buildWhen` để chỉ rebuild khi categories/currentRequest
      // thay đổi — tránh rebuild filter form khi chỉ chuyển giữa
      // Searching/Results/Empty (DiscoveryResultsPage đang handle).
      buildWhen: (prev, curr) {
        final prevData = _resolveFormData(prev);
        final currData = _resolveFormData(curr);
        return prevData?.currentRequest != currData?.currentRequest ||
            prevData?.categories != currData?.categories;
      },
      builder: (context, state) {
        // Initial loading → shimmer (chưa có categories)
        if (state is SurveyLoading) return const DiscoveryShimmer();

        final data = _resolveFormData(state);

        // Lỗi và chưa load được categories → error state
        if (data == null && state is SurveyError) {
          return ErrorStateWidget(
            message: state.message,
            onRetry: () => context.read<SurveyCubit>().loadCategories(),
          );
        }

        // Mọi trường hợp còn lại (kể cả đang Searching) đều hiển thị filter
        // form — player back từ results sẽ thấy ngay filter để chỉnh sửa.
        if (data == null) return const SizedBox.shrink();

        return _buildFilterLayout(data);
      },
    );
  }

  Widget _buildFilterLayout(_FilterFormData data) {
    return RefreshIndicator(
      // Pull-down refresh lại categories (giữ filter values hiện tại).
      // Cubit đã có method `refresh()` cho `SurveyCategoriesLoaded` →
      // gọi `loadCategories()` (không reset currentRequest).
      displacement: 80,
      color: AppColors.primary,
      backgroundColor: Colors.white,
      strokeWidth: 3,
      onRefresh: () async {
        try {
          await context.read<SurveyCubit>().refresh();
        } catch (_) {
          // Swallow exception đã được ErrorStateWidget handle.
        }
      },
      // SingleChildScrollView đã có sẵn — chỉ cần đảm bảo
      // `physics: AlwaysScrollableScrollPhysics` để RefreshIndicator
      // hoạt động ngay cả khi form ngắn (không đủ overflow).
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.xs,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: SurveyFilterForm(
          // Form tu quan ly local state cho filter values,
          // chi dung cua state phong lam initial values.
          currentRequest: data.currentRequest,
          categories: data.categories,
          onApply: _onApply,
        ),
      ),
    );
  }
}

/// Helper data holder gom categories + currentRequest tu cubit state.
class _FilterFormData {
  final List<GameCategoryDiscoveryEntity> categories;
  final DiscoveryRequestEntity currentRequest;
  const _FilterFormData(this.categories, this.currentRequest);
}