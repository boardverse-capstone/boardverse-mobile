import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/navigation/lobby_suggestion_signal.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/neo_brutalism_theme.dart';
import '../../domain/entities/alternative_game_suggestion_entity.dart';
import '../../domain/entities/board_game_entity.dart';
import '../../domain/entities/game_play_configuration_entity.dart';
import '../cubit/matchmaking_cubit.dart';
import '../cubit/matchmaking_state.dart';
import '../pages/cafe_detail_page.dart';
import '../pages/lobby_cafe_selection_page.dart';
import '../widgets/board_game_detail/board_game_detail_error_retry_view.dart';
import '../widgets/board_game_detail/board_game_detail_shimmer.dart';
import '../widgets/cafe_card.dart';
import '../widgets/game_detail_header.dart';
import '../widgets/game_info_section.dart';
import '../widgets/gps_warning_banner.dart';
import '../widgets/similar_games_carousel.dart';

class BoardGameDetailPage extends StatefulWidget {
  final String gameId;
  final MatchmakingCubit matchmakingCubit;

  const BoardGameDetailPage({
    super.key,
    required this.gameId,
    required this.matchmakingCubit,
  });

  @override
  State<BoardGameDetailPage> createState() => _BoardGameDetailPageState();
}

class _BoardGameDetailPageState extends State<BoardGameDetailPage> {
  MatchmakingState? _lastDetailState;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    widget.matchmakingCubit.loadGameDetail(gameId: widget.gameId);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.matchmakingCubit,
      child: Scaffold(
        body: MultiBlocListener(
          listeners: [
            BlocListener<MatchmakingCubit, MatchmakingState>(
              listenWhen: (prev, curr) =>
                  curr is MatchmakingPlayNavigationResolved ||
                  curr is MatchmakingFailure,
              listener: (context, state) {
                if (state is MatchmakingPlayNavigationResolved) {
                  _handlePlayNavigation(context, state);
                }
              },
            ),
          ],
          child: BlocBuilder<MatchmakingCubit, MatchmakingState>(
            builder: (context, state) {
              if (state is MatchmakingLoading) {
                return const BoardGameDetailShimmer();
              }
              if (state is MatchmakingFailure) {
                return BoardGameDetailErrorRetryView(
                  message: state.message,
                  onRetry: () => widget.matchmakingCubit.loadGameDetail(
                    gameId: widget.gameId,
                  ),
                );
              }
              if (state is MatchmakingGpsDisabled) {
                return _buildGpsDisabledView(context, state);
              }

              // Thống nhất UI cho cả case "không có quán nào" và "có quán
              // nhưng quá xa": cả 2 đều dùng `MatchmakingGameDetail` với
              // `isOutOfRadius: true`. Xem cubit comment để biết lý do.
              if (state is MatchmakingGameDetail) {
                _lastDetailState = state;
                return _buildGameDetailView(context, state);
              }

              if (state is MatchmakingPlayNavigationResolving &&
                  _lastDetailState != null) {
                final lastDetail =
                    _lastDetailState as MatchmakingGameDetail;
                return Stack(
                  children: [
                    _buildGameDetailView(context, lastDetail),
                    Positioned.fill(
                      child: ColoredBox(
                        color: AppColors.black.withValues(alpha: 0.4),
                        child: const Center(
                          child: SizedBox(
                            width: 48,
                            height: 48,
                            child: CircularProgressIndicator(strokeWidth: 3),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }

              if (state is MatchmakingPlayNavigationResolving) {
                return const BoardGameDetailShimmer();
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  void _handlePlayNavigation(
    BuildContext context,
    MatchmakingPlayNavigationResolved state,
  ) {
    final nav = state.navigation;
    final gameId = nav.gameTemplateId;
    final gameName = nav.gameName ?? '';

    final current = widget.matchmakingCubit.state;
    BoardGameEntity? gameEntity;
    if (current is MatchmakingGameDetail) {
      gameEntity = current.game.toBoardGameEntity();
    }
    gameEntity ??= BoardGameEntity(
      id: gameId,
      name: gameName.isEmpty ? 'Game' : gameName,
      description: '',
      imageUrl: '',
      minPlayers: nav.roomConfiguration.minPlayers,
      maxPlayers: nav.roomConfiguration.maxPlayers,
      estimatedMinutes: 0,
      category: '',
      components: const [],
      mechanics: const [],
      rating: 0,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LobbyCafeSelectionPage(
          game: gameEntity!,
          matchmakingCubit: widget.matchmakingCubit,
        ),
      ),
    );

    if (nav.isLobbyCreation) {
      LobbySuggestionSignal.instance.request(gameEntity);
    }
  }

  Widget _buildGpsDisabledView(
    BuildContext context,
    MatchmakingGpsDisabled state,
  ) {
    return CustomScrollView(
      slivers: [
        if (state.selectedGame != null)
          GameDetailHeader(game: state.selectedGame!),
        SliverToBoxAdapter(
          child: GpsWarningBanner(
            onEnableGps: () {
              widget.matchmakingCubit.enableGpsAndReload(
                gameId: widget.gameId,
              );
            },
            onEnterManually: () => _showManualLocationDialog(context),
          ),
        ),
        if (state.selectedGame != null)
          SliverToBoxAdapter(
            child: GameInfoSection.fromEntity(state.selectedGame!),
          ),
      ],
    );
  }

  Widget _buildGameDetailView(
    BuildContext context,
    MatchmakingGameDetail state,
  ) {
    final gameAsEntity = state.game.toBoardGameEntity();

    final isResolving = widget.matchmakingCubit.state
        is MatchmakingPlayNavigationResolving;
    final supportsSolo = state.game.minPlayers == 1;
    final hasAlternatives = state.alternativeSuggestions.isNotEmpty;

    return Stack(
      children: [
        CustomScrollView(
          controller: _scrollController,
          slivers: [
            GameDetailHeader(game: gameAsEntity),
            SliverToBoxAdapter(
              child: GameInfoSection.fromDetail(state.game),
            ),
            // Section "QUÁN CAFE GẦN BẠN" — đổi tiêu đề theo trường hợp:
            // - Có quán trong bán kính → "QUÁN CAFE GẦN BẠN" (mặc định).
            // - Có quán nhưng xa (out-of-radius) → "QUÁN CAFE TRONG KHU VỰC"
            //   để user biết quán này xa hơn bán kính ưu tiên.
            // - Không có quán nào → ẩn section này (UI empty state đã
            //   thông báo rồi).
            if (state.nearbyCafes.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: Padding(
                    padding: AppSpacing.paddingHorizontalMd,
                    child: Text(
                      state.isOutOfRadius
                          ? 'QUÁN CAFE TRONG KHU VỰC'
                          : 'QUÁN CAFE GẦN BẠN',
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                    ),
                  ),
                ),
              ),
            if (state.nearbyCafes.isEmpty)
              SliverToBoxAdapter(
                child: _buildNearbyEmptyState(
                  context,
                  emptyMessage: state.emptyResultMessage,
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final cafe = state.nearbyCafes[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      child: CafeCard(
                        cafe: cafe,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CafeDetailPage(
                              cafeId: cafe.id,
                              selectedGame: gameAsEntity,
                              matchmakingCubit: widget.matchmakingCubit,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: state.nearbyCafes.length,
                ),
              ),
            // Khi out-of-radius (kể cả có hoặc không có quán) mà backend
            // có gợi ý game tương tự → hiển thị carousel ngay dưới.
            // Nếu backend trả `alternativeSuggestions = []` (không gợi ý)
            // → hiển thị notice "Hiện chưa có gợi ý game tương tự" để user
            // biết là backend không phải frontend bug, thay vì để carousel
            // rỗng (gây hiểu nhầm UI không hoạt động).
            if (state.isOutOfRadius)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: _buildAlternativesSection(
                    context,
                    alternatives: state.alternativeSuggestions,
                    hasAlternatives: hasAlternatives,
                  ),
                ),
              ),
                        // Bottom padding đủ lớn để user có thể scroll xuống xem hết
            // alternatives content mà không bị sticky CTA che khuất.
            // huge(48) + massive(64) = 112px buffer dưới alternatives.
            const SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.huge + AppSpacing.massive),
            ),
          ],
        ),
        _buildStickyBottomCta(
          context: context,
          state: state,
          isResolving: isResolving,
          supportsSolo: supportsSolo,
        ),
      ],
    );
  }

  /// Section game tương tự — thống nhất cho 2 case:
  /// - `hasAlternatives = true` (backend có gợi ý) → `SimilarGamesCarousel`.
  /// - `hasAlternatives = false` (backend trả rỗng) → notice giải thích.
  Widget _buildAlternativesSection(
    BuildContext context, {
    required List<AlternativeGameSuggestionEntity> alternatives,
    required bool hasAlternatives,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor =
        isDark ? AppColors.borderDark : AppColors.border;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
          ).copyWith(top: AppSpacing.xs),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.recommend_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'GỢI Ý GAME TƯƠNG TỰ',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (hasAlternatives)
          SimilarGamesCarousel(
            games: alternatives
                .map<BoardGameEntity>((s) => s.toBoardGameEntity())
                .toList(),
            onGameTap: (game) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BoardGameDetailPage(
                    gameId: game.id,
                    matchmakingCubit: widget.matchmakingCubit,
                  ),
                ),
              );
            },
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
            ),
            child: Container(
              padding: AppSpacing.paddingAllMd,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: borderColor,
                  width: NeoBrutalismTheme.borderWidth,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.info,
                      size: AppSpacing.xl,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Hiện chưa có gợi ý game tương tự. Bạn có thể thử '
                      'tìm game khác ở tab Khám phá.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStickyBottomCta({
    required BuildContext context,
    required MatchmakingGameDetail state,
    required bool isResolving,
    required bool supportsSolo,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surface,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.border,
              width: NeoBrutalismTheme.borderWidth,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.1),
              blurRadius: 0,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              if (supportsSolo) ...[
                Expanded(
                  child: _NeoCtaButton(
                    label: 'MỘT MÌNH',
                    icon: Icons.person_rounded,
                    backgroundColor: isDark
                        ? AppColors.surfaceElevatedDark
                        : AppColors.surfaceVariant,
                    textColor: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                    borderColor: isDark
                        ? AppColors.borderDark
                        : AppColors.border,
                    onPressed: isResolving
                        ? null
                        : () => widget.matchmakingCubit.resolvePlayNavigation(
                              gameId: state.game.id,
                              mode: PlayMode.solo,
                            ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                flex: 2,
                child: _NeoCtaButton(
                  label: supportsSolo ? 'TẠO LOBBY' : 'ĐẶT BÀN',
                  icon: supportsSolo
                      ? Icons.groups_rounded
                      : Icons.calendar_today_rounded,
                  backgroundColor: AppColors.primary,
                  textColor: AppColors.white,
                  borderColor: AppColors.primary,
                  shadowColor: AppColors.primary,
                  isLoading: isResolving,
                  onPressed: isResolving
                      ? null
                      : () => widget.matchmakingCubit.resolvePlayNavigation(
                            gameId: state.game.id,
                            mode: PlayMode.group,
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNearbyEmptyState(
    BuildContext context, {
    required String? emptyMessage,
  }) {
    final theme = Theme.of(context);
    final message = emptyMessage ??
        'Không có quán nào có game này gần bạn. Hãy thử chọn game khác.';
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Container(
        padding: AppSpacing.paddingAllMd,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: theme.brightness == Brightness.dark
                ? AppColors.borderDark
                : AppColors.border,
            width: NeoBrutalismTheme.borderWidth,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.location_off,
                color: AppColors.error,
                size: AppSpacing.xl,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showManualLocationDialog(BuildContext context) {
    final districtController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nhập vị trí thủ công'),
        content: TextField(
          controller: districtController,
          decoration: const InputDecoration(
            labelText: 'Quận/Huyện',
            hintText: 'Ví dụ: Quận 1',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              widget.matchmakingCubit.loadCafesWithManualLocation(
                gameId: widget.gameId,
                district: districtController.text,
              );
            },
            child: const Text('Tìm kiếm'),
          ),
        ],
      ),
    );
  }
}

/// Neo-brutalism CTA Button - dùng cho sticky bottom bar.
class _NeoCtaButton extends StatefulWidget {
  const _NeoCtaButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.textColor,
    required this.borderColor,
    this.shadowColor,
    this.isLoading = false,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color textColor;
  final Color borderColor;
  final Color? shadowColor;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  State<_NeoCtaButton> createState() => _NeoCtaButtonState();
}

class _NeoCtaButtonState extends State<_NeoCtaButton>
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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPressed = _pressCtrl.isAnimating && _pressCtrl.value > 0.5;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.translate(
            offset: isPressed ? const Offset(2, 2) : Offset.zero,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTapDown: widget.onPressed == null
            ? null
            : (_) {
                _pressCtrl.forward();
                HapticFeedback.mediumImpact();
              },
        onTapUp: widget.onPressed == null
            ? null
            : (_) => _pressCtrl.reverse(),
        onTapCancel: widget.onPressed == null
            ? null
            : () => _pressCtrl.reverse(),
        onTap: widget.onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.borderColor,
              width: NeoBrutalismTheme.borderWidthBold,
            ),
            boxShadow: widget.onPressed == null
                ? null
                : NeoBrutalismTheme.lightShadow(
                    shadowColor: (widget.shadowColor ?? widget.backgroundColor)
                        .withValues(alpha: 0.5),
                  ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.isLoading) ...[
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation(widget.textColor),
                  ),
                ),
              ] else ...[
                Icon(widget.icon, size: 20, color: widget.textColor),
              ],
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.fade,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: widget.textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
