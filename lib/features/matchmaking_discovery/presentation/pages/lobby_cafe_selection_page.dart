import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../lobby_management/presentation/widgets/lobby_game_picker_sheet.dart';
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

/// Chế độ lọc cafe trên màn hình `LobbyCafeSelectionPage`.
///
/// - [gps] (mặc định): dùng vị trí GPS đã lưu của player — sort theo
///   `distanceMeters` tăng dần, lọc trong bán kính 15km.
/// - [city]: lấy toàn bộ quán ACTIVE trên toàn quốc rồi filter
///   client-side theo `PlayerLocationEntity.city` — giải quyết case player
///   muốn đặt chỗ ở nơi không có quán trong bán kính GPS (vd: đi công
///   tác tỉnh khác, hoặc ở vùng ven chưa có quán).
enum _CafeFilterMode { gps, city }

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

  /// Chế độ filter hiện tại. Mặc định GPS để không phá vỡ UX hiện tại —
  /// player vẫn thấy quán gần trước, có thể switch sang "Trong thành phố"
  /// khi cần.
  _CafeFilterMode _filterMode = _CafeFilterMode.gps;

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
    if (_filterMode == _CafeFilterMode.city) {
      final location = _readPlayerLocation();
      final city = location?.city;
      if (city == null || city.trim().isEmpty) {
        // Fallback về GPS mode + thông báo.
        await _switchToGpsMode(notify: true);
        return;
      }
      await widget.matchmakingCubit.loadCafesByCity(
        city: city,
        cityDisplayName: city.trim(),
      );
      return;
    }
    if (_manualLatitude != null && _manualLongitude != null) {
      await _loadWithManualLocation();
    } else {
      widget.matchmakingCubit.loadNearbyCafesForCurrentUser(
        gameId: widget.game.id,
      );
    }
  }

  /// Đọc `PlayerLocationEntity` hiện tại từ `ProfileCubit` (nếu đã load).
  /// Trả về `null` khi chưa có state location — caller phải xử lý.
  PlayerLocationEntity? _readPlayerLocation() {
    if (!mounted) return null;
    final profileState = context.read<ProfileCubit>().state;
    if (profileState is ProfileLocationLoaded) {
      return profileState.location;
    }
    return null;
  }

  /// Switch sang chế độ "Trong thành phố". Lấy `city` từ
  /// `ProfileLocationEntity.city` (đã được backend resolve sau
  /// reverse-geocode).
  ///
  /// Edge case:
  /// - `city == null` (chưa GPS / reverse-geocode fail) → giữ chế độ
  ///   GPS, hiển thị snackbar hướng dẫn player bật GPS / cập nhật vị trí.
  /// - State Profile chưa load xong → cố gắng trigger load rồi retry 1 lần.
  Future<void> _switchToCityMode() async {
    if (!mounted) return;

    var location = _readPlayerLocation();
    if (location == null) {
      // ProfileCubit có thể chưa từng được gọi getLocation ở flow này —
      // thử load nhanh (best-effort, không block UI).
      final profileCubit = context.read<ProfileCubit>();
      try {
        await profileCubit.getLocation();
      } catch (_) {
        // ignore: bỏ qua lỗi, fallback snackbar
      }
      if (!mounted) return;
      location = _readPlayerLocation();
    }

    final city = location?.city;
    if (city == null || city.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Chưa tìm được thành phố của bạn. Bật GPS hoặc cập nhật vị trí '
            'rồi thử lại nhé!',
          ),
        ),
      );
      return;
    }

    setState(() => _filterMode = _CafeFilterMode.city);
    await widget.matchmakingCubit.loadCafesByCity(
      city: city,
      cityDisplayName: city.trim(),
    );
  }

  /// Switch về chế độ "Gần bạn" (GPS). Khi [notify] = true thì hiển thị
  /// snackbar (dùng khi auto-fallback từ city mode do thiếu city info).
  Future<void> _switchToGpsMode({bool notify = false}) async {
    if (!mounted) return;
    setState(() => _filterMode = _CafeFilterMode.gps);
    if (_manualLatitude != null && _manualLongitude != null) {
      await _loadWithManualLocation();
    } else {
      await widget.matchmakingCubit.loadNearbyCafesForCurrentUser(
        gameId: widget.game.id,
      );
    }
    if (notify && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã chuyển về "Gần bạn".'),
        ),
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

  /// Mở bottom sheet [LobbyGamePickerSheet] để player đổi sang tựa
  /// game khác — giống flow tạo lobby ở [LobbyHubPage._openCreateLobby].
  ///
  /// Flow: Player ấn "Đổi" →
  ///   1. Đảm bảo cubit đã có danh sách games (nếu chưa cache → fetch).
  ///   2. Mở bottom sheet picker — player search/chọn game mới.
  ///   3. Nếu chọn game khác game hiện tại → replace page hiện tại bằng
  ///      [LobbyCafeSelectionPage] mới với [BoardGameEntity] mới.
  ///      Player bắt đầu lại từ bước chọn cafe (đúng nghiệp vụ vì
  ///      game mới có thể chỉ chơi ở cafe khác / khác khoảng cách).
  ///
  /// Lưu ý: flow này giữ nguyên pattern cũ (trước khi refactor) — chỉ
  /// khác ở chỗ player chọn game MỚI ngay trong flow lobby thay vì phải
  /// back ra tận SearchPage. UX khớp với "Đổi quán" ở LobbyConfigPage
  /// (chỉ swap field, không reset cả flow).
  Future<void> _onChangeGamePressed() async {
    if (!mounted) return;
    final matchmakingCubit = widget.matchmakingCubit;

    // Đảm bảo cubit có search results để picker hiển thị. Có thể cubit
    // chưa fetch nếu player mở flow qua BoardGameDetail trực tiếp
    // (chưa vào Search tab Explore).
    if (matchmakingCubit.state is! MatchmakingSearchResults) {
      await matchmakingCubit.searchGames();
      if (!mounted) return;
    }

    // Mở bottom sheet picker — contract giống LobbyHubPage:
    // nhận List<BoardGameEntity> đã được cache trong cubit state, trả
    // về BoardGameEntity qua Navigator.pop (null nếu player đóng).
    final picked = await showModalBottomSheet<BoardGameEntity>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        final s = matchmakingCubit.state;
        final games = s is MatchmakingSearchResults
            ? s.games
            : <BoardGameEntity>[];
        return LobbyGamePickerSheet(games: games);
      },
    );
    if (picked == null || !mounted) return;

    // Bỏ qua nếu player chọn lại chính game hiện tại.
    if (picked.id == widget.game.id) return;

    // Reset nearby cafes state để cubit fetch lại theo gameId mới
    // (cache theo gameId cũ không còn hợp lệ).
    matchmakingCubit.resetNearbyCafesForGameSwitch();

    // Restart flow với game mới: replace page hiện tại bằng
    // LobbyCafeSelectionPage mới. Player chọn cafe từ đầu → đây là
    // behavior tự nhiên vì game mới có thể khác về cafes available.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => LobbyCafeSelectionPage(
          game: picked,
          matchmakingCubit: matchmakingCubit,
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
                  // Nút "Đổi game" — cho phép player đổi sang tựa game
                  // khác nếu lỡ chọn nhầm. Tap sẽ pop về
                  // BoardGameDetailPage để player back ra ngoài hoặc
                  // chọn game khác từ SimilarGamesCarousel.
                  _ChangeGameButton(onTap: _onChangeGamePressed),
                ],
              ),
            ),
          ),
        ),
        body: BlocConsumer<MatchmakingCubit, MatchmakingState>(
          listenWhen: (prev, curr) =>
              curr is MatchmakingNearbyCafesLoaded ||
              curr is MatchmakingCafesByCityLoaded ||
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
              curr is MatchmakingCafesByCityLoaded ||
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
                    _CafeFilterChipsRow(
                      currentMode: _filterMode,
                      onGpsSelected: () {
                        if (_filterMode == _CafeFilterMode.gps) return;
                        _switchToGpsMode();
                      },
                      onCitySelected: _switchToCityMode,
                    ),
                    if (!_hasUpdatedLocation &&
                        _filterMode == _CafeFilterMode.gps)
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

            if (state is MatchmakingCafesByCityLoaded) {
              final cafes = state.cafes;
              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  children: [
                    _CafeFilterChipsRow(
                      currentMode: _filterMode,
                      onGpsSelected: () {
                        if (_filterMode == _CafeFilterMode.gps) return;
                        _switchToGpsMode();
                      },
                      onCitySelected: _switchToCityMode,
                    ),
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
                          cafes.isEmpty
                              ? 'Chưa tìm thấy quán ở ${state.cityDisplayName}'
                              : '${cafes.length} quán ở ${state.cityDisplayName}',
                          style: const TextStyle(
                            color: AppColors.black,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    if (cafes.isEmpty)
                      CafeSelectionEmptyState(
                        title: 'Chưa có quán nào ở ${state.cityDisplayName}',
                        message:
                            'BoardVerse chưa có quán nào đang mở cửa ở '
                            '${state.cityDisplayName} phục vụ game "${widget.game.name}". '
                            'Bạn thử chuyển về "Gần bạn" hoặc đổi sang game khác nhé!',
                      )
                    else
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
                ),
              );
            }

            if (state is MatchmakingFailure) {
              return CafeSelectionErrorRetryView(
                message: state.message,
                requiresLocationUpdate: state.requiresLocationUpdate,
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

/// Pill-style segmented control cho 2 chế độ lọc: "Gần bạn" / "Trong
/// thành phố". Neo-brutalism style — pill đơn, 2 chip với viền đậm, chip
/// đang chọn có nền primary.
class _CafeFilterChipsRow extends StatelessWidget {
  final _CafeFilterMode currentMode;
  final VoidCallback onGpsSelected;
  final VoidCallback onCitySelected;

  const _CafeFilterChipsRow({
    required this.currentMode,
    required this.onGpsSelected,
    required this.onCitySelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        0,
      ),
      child: Row(
        children: [
          Expanded(
            child: _FilterChip(
              label: 'Gần bạn',
              icon: Icons.my_location,
              selected: currentMode == _CafeFilterMode.gps,
              onTap: onGpsSelected,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: _FilterChip(
              label: 'Trong thành phố',
              icon: Icons.location_city,
              selected: currentMode == _CafeFilterMode.city,
              onTap: onCitySelected,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary
                : (isDark ? AppColors.surfaceDark : AppColors.surface),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : (isDark ? AppColors.borderDark : AppColors.border),
              width: 2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: selected
                    ? AppColors.white
                    : (isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary)
                        .withValues(alpha: 0.75),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                    color: selected
                        ? AppColors.white
                        : (isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary),
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

/// Pill button "Đổi" ở header — neo-brutalism style.
///
/// Hiển thị nhãn "ĐỔI" + icon edit để player biết có thể đổi sang game
/// khác khi lỡ chọn nhầm. Tap sẽ pop [LobbyCafeSelectionPage] về
/// [BoardGameDetailPage] đã có sẵn trong stack.
class _ChangeGameButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ChangeGameButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.primary,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.edit_rounded,
                size: 14,
                color: AppColors.primary,
              ),
              const SizedBox(width: 4),
              Text(
                'ĐỔI',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
