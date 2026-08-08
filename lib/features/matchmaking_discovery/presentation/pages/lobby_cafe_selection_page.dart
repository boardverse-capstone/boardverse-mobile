import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../profile/domain/entities/player_location_entity.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';
import '../../domain/entities/board_game_entity.dart';
import '../../domain/entities/cafe_entity.dart';
import '../cubit/matchmaking_cubit.dart';
import '../cubit/matchmaking_state.dart';
import '../widgets/cafe_selection/cafe_selection_empty_state.dart';
import '../widgets/cafe_selection/cafe_selection_error_retry_view.dart';
import '../widgets/cafe_selection/cafe_selection_location_banner.dart';
import '../widgets/cafe_selection/location_pick.dart';
import '../widgets/cafe_selection/location_picker_dialog.dart';
import '../widgets/cafe_selection/selectable_cafe_card.dart';
import '../widgets/lobby_cafe_selection/lobby_cafe_selection_shimmer.dart';
import 'lobby_config_page.dart';

/// Neo-brutalism Lobby Cafe Selection Page.
class LobbyCafeSelectionPage extends StatefulWidget {
  final BoardGameEntity game;
  final MatchmakingCubit matchmakingCubit;

  const LobbyCafeSelectionPage({
    super.key,
    required this.game,
    required this.matchmakingCubit,
  });

  @override
  State<LobbyCafeSelectionPage> createState() => _LobbyCafeSelectionPageState();
}

class _LobbyCafeSelectionPageState extends State<LobbyCafeSelectionPage> {
  bool _hasInitialLoad = false;
  double? _manualLatitude;
  double? _manualLongitude;
  bool _isUpdatingLocation = false;
  bool _hasUpdatedLocation = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _hasInitialLoad) return;
      _initialLoad();
    });
  }

  void _initialLoad() {
    _hasInitialLoad = true;
    final state = widget.matchmakingCubit.state;
    if (state is MatchmakingNearbyCafesLoaded && state.gameId == widget.game.id) {
      return;
    }
    widget.matchmakingCubit.loadNearbyCafesForCurrentUser(
      gameId: widget.game.id,
    );
  }

  Future<void> _loadWithManualLocation() async {
    if (_manualLatitude == null || _manualLongitude == null) return;
    widget.matchmakingCubit.loadNearbyCafesWithCoordinates(
      gameId: widget.game.id,
      latitude: _manualLatitude!,
      longitude: _manualLongitude!,
    );
  }

  Future<void> _refresh() async {
    if (_manualLatitude != null && _manualLongitude != null) {
      await _loadWithManualLocation();
    } else {
      widget.matchmakingCubit.loadNearbyCafesForCurrentUser(
        gameId: widget.game.id,
      );
    }
  }

  Future<void> _promptUpdateLocation() async {
    if (_isUpdatingLocation) return;

    final picked = await showDialog<LocationPick>(
      context: context,
      builder: (_) => const LocationPickerDialog(),
    );
    if (picked == null || !mounted) return;

    setState(() => _isUpdatingLocation = true);

    setState(() {
      _manualLatitude = null;
      _manualLongitude = null;
    });

    final messenger = ScaffoldMessenger.of(context);
    final profileCubit = context.read<ProfileCubit>();
    final stateBefore = profileCubit.state;

    profileCubit.updateLocation(
      latitude: picked.latitude,
      longitude: picked.longitude,
      source: LocationSource.manual.index,
    );

    await _waitForProfileResult(
      profileCubit,
      stateBefore: stateBefore,
      onSuccess: () {
        if (!mounted) return;
        setState(() => _hasUpdatedLocation = true);
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Đã cập nhật vị trí. Đang tìm quán quanh bạn...'),
          ),
        );
        widget.matchmakingCubit.loadNearbyCafesForCurrentUser(
          gameId: widget.game.id,
        );
      },
      onFailure: (msg) {
        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(
            content: Text('Không thể cập nhật vị trí: $msg'),
            backgroundColor: AppColors.error,
          ),
        );
      },
    );

    if (mounted) setState(() => _isUpdatingLocation = false);
  }

  Future<void> _waitForProfileResult(
    ProfileCubit cubit, {
    required ProfileState stateBefore,
    required VoidCallback onSuccess,
    required void Function(String message) onFailure,
  }) async {
    const timeout = Duration(seconds: 8);
    final end = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(end)) {
      if (!mounted) return;
      final s = cubit.state;
      if (!identical(s, stateBefore)) {
        if (s is ProfileLocationLoaded) {
          onSuccess();
          return;
        }
        if (s is ProfileFailure) {
          onFailure(s.message);
          return;
        }
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }

    onSuccess();
  }

  Future<void> _onBannerUpdatePressed() async {
    await _promptUpdateLocation();
  }

  void _openConfigWithCafe(CafeEntity cafe) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => LobbyConfigPage(
          gameId: widget.game.id,
          gameName: widget.game.name,
          cafeId: cafe.id,
          cafeName: cafe.name,
          cafeEntity: cafe,
          matchmakingCubit: widget.matchmakingCubit,
          gameEntity: widget.game,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocProvider.value(
      value: widget.matchmakingCubit,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Chọn quán cafe',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          centerTitle: false,
          backgroundColor:
              isDark ? AppColors.surfaceDark : AppColors.surface,
          foregroundColor:
              isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          leading: IconButton(
            tooltip: 'Đóng',
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(AppSpacing.xxxl + AppSpacing.xs),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.extension,
                      size: AppSpacing.md,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      widget.game.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: BlocConsumer<MatchmakingCubit, MatchmakingState>(
          listenWhen: (prev, curr) =>
              curr is MatchmakingNearbyCafesLoaded ||
              curr is MatchmakingFailure,
          listener: (context, state) {
            if (state is MatchmakingFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          },
          buildWhen: (prev, curr) =>
              curr is MatchmakingNearbyCafesLoaded ||
              curr is MatchmakingInitial ||
              curr is MatchmakingLoading ||
              curr is MatchmakingFailure,
          builder: (context, state) {
            if (state is MatchmakingLoading || state is MatchmakingInitial) {
              return const LobbyCafeSelectionShimmer();
            }

            if (state is MatchmakingNearbyCafesLoaded) {
              final cafes = state.cafes;
              final hasSuggestions = state.alternativeSuggestions.isNotEmpty;
              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  children: [
                    if (!_hasUpdatedLocation)
                      CafeSelectionLocationBanner(
                        hasManualLocation:
                            _manualLatitude != null && _manualLongitude != null,
                        isUpdating: _isUpdatingLocation,
                        onRefreshLocation: _onBannerUpdatePressed,
                        onClearManualLocation: () {
                          if (_manualLatitude == null) return;
                          setState(() {
                            _manualLatitude = null;
                            _manualLongitude = null;
                          });
                          widget.matchmakingCubit.loadNearbyCafesForCurrentUser(
                            gameId: widget.game.id,
                          );
                        },
                      ),
                    if (cafes.isEmpty)
                      CafeSelectionEmptyState(
                        message: state.emptyResultMessage ??
                            'Chưa có quán nào có game này trong bán kính tìm kiếm.',
                      )
                    else ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.sm,
                          AppSpacing.md,
                          AppSpacing.xs,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xxs,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.borderDark
                                  : AppColors.border,
                              width: 2,
                            ),
                          ),
                          child: Text(
                            '${cafes.length} quán phù hợp',
                            style: const TextStyle(
                              color: AppColors.black,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      for (final cafe in cafes)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.sm,
                            0,
                            AppSpacing.sm,
                            AppSpacing.xs,
                          ),
                          child: SelectableCafeCard(
                            cafe: cafe,
                            onTap: () => _openConfigWithCafe(cafe),
                          ),
                        ),
                    ],
                    if (hasSuggestions)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.xl,
                          AppSpacing.md,
                          AppSpacing.xs,
                        ),
                        child: Text(
                          'GỢI Ý GAME KHÁC',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }

            if (state is MatchmakingFailure) {
              return CafeSelectionErrorRetryView(
                message: state.message,
                onRetry: _refresh,
                onUpdateLocation: _promptUpdateLocation,
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
