import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

/// Màn chọn quán cafe cho flow "Tạo lobby theo quán đã biết".
///
/// Player từng chơi ở quán cafe → muốn rủ bạn cùng chơi tại quán đó:
///   1. Vào màn này, chọn game + quán đã chơi
///   2. Đi tiếp [LobbyConfigPage] để chọn ngày/giờ + tạo phòng
///
/// API dùng:
/// - Ưu tiên `GET /api/cafes/nearby/me?gameTemplateId=...` (lấy vị trí user
///   đã lưu). Trước khi gọi cần `PUT /api/userprofile/me/location` (nếu user
///   chưa có vị trí server sẽ trả 400 — banner "Cập nhật" cho phép chọn
///   thành phố để ghi lat/lng lên profile).
/// - Fallback `GET /api/cafes/nearby?latitude=&longitude=&gameTemplateId=...`
///   dùng khi user chọn vị trí thủ công ngay tại page này.
class LobbyCafeSelectionPage extends StatefulWidget {
  /// Game đã được chọn trước đó (từ [BoardGameDetailPage] hoặc
  /// [LobbyHubPage]). Page sẽ dùng `game.id` để gọi `/api/cafes/nearby`.
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
  /// Cờ đánh dấu đã trigger lần đầu. Tránh gọi API trùng khi state
  /// `MatchmakingNearbyCafesLoaded` tới sau khi page build.
  bool _hasInitialLoad = false;

  /// Vị trí thủ công (được người dùng cập nhật qua LocationCard).
  /// Nếu có, ưu tiên dùng vị trí thủ công để gọi `/api/cafes/nearby`.
  double? _manualLatitude;
  double? _manualLongitude;

  /// Cờ đang gọi `PUT /api/userprofile/me/location`. Dùng để disable
  /// nút "Cập nhật" trên banner và đảm bảo không gọi trùng.
  bool _isUpdatingLocation = false;

  /// Cờ đánh dấu user đã cập nhật vị trí thành công **trong session này**.
  /// Khi `true`, banner "Cập nhật vị trí" sẽ ẩn đi — user đã xử lý xong
  /// nhu cầu thay đổi location. Empty state lúc này chỉ thông báo đơn
  /// giản là khu vực hiện tại chưa có quán cafe.
  bool _hasUpdatedLocation = false;

  @override
  void initState() {
    super.initState();
    // Nếu cubit đã ở state loaded cho đúng game, render ngay không cần gọi
    // lại. Nếu chưa, kick một lần ở đây (sẽ được skip khi listener attach).
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

  /// Mở dialog cho phép user chọn thành phố / quận để cập nhật vị trí lên
  /// server. Sau khi PUT thành công sẽ reload `/api/cafes/nearby/me`.
  ///
  /// Lý do cần dialog: backend `/api/cafes/nearby/me` yêu cầu server đã có
  /// `LastKnownLatitude/Longitude` (PUT /api/userprofile/me/location) — nếu
  /// chưa có sẽ trả 400. Nút "Cập nhật" trên banner hiện tại chỉ refresh
  /// lại request cũ nên user "ấn mà không có gì xảy ra".
  Future<void> _promptUpdateLocation() async {
    if (_isUpdatingLocation) return;

    final picked = await showDialog<LocationPick>(
      context: context,
      builder: (_) => const LocationPickerDialog(),
    );
    if (picked == null || !mounted) return;

    setState(() => _isUpdatingLocation = true);

    // Reset vị trí thủ công để lần refresh sau dùng `/nearby/me` (server).
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

    // Chờ cubit emit kết quả rồi xử lý UI.
    await _waitForProfileResult(
      profileCubit,
      stateBefore: stateBefore,
      onSuccess: () {
        if (!mounted) return;
        // Ẩn banner cập nhật location — user đã hoàn tất nhu cầu
        // thay đổi vị trí trong session này.
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
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      },
    );

    if (mounted) setState(() => _isUpdatingLocation = false);
  }

  /// Spin cho tới khi [cubit] chuyển sang `ProfileLocationLoaded` /
  /// `ProfileFailure` (so với [stateBefore]). Có timeout 8s để không kẹt
  /// vĩnh viễn nếu cubit phát sinh lỗi lạ.
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

    // Timeout — giả định success vì ProfileCubit.updateLocation không emit
    // loading state trước khi gọi. Vẫn refresh để user thấy kết quả mới.
    onSuccess();
  }

  /// Nút "Cập nhật" trên banner: luôn mở dialog chọn vị trí thay vì chỉ
  /// refresh (vì refresh không giải quyết được tình trạng server chưa có
  /// lat/lng).
  Future<void> _onBannerUpdatePressed() async {
    await _promptUpdateLocation();
  }

  void _openConfigWithCafe(CafeEntity cafe) {
    // Sau khi chọn cafe → route sang `LobbyConfigPage` (step cấu hình
    // duy nhất trong luồng tạo lobby). Từ đây user bấm "Xác nhận" →
    // `ReservationCubit.createQuote()` → `LobbyQuotePage` (đặt cọc)
    // → lobby được tạo nguyên tử qua `confirmReservation()`.
    //
    // Trước đây có 2 nhánh (walk-in solo vs lobby creation) — giờ chỉ
    // giữ 1 nhánh duy nhất để tránh duplicate UI như `LobbyCreateSetupPage`.
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

    return BlocProvider.value(
      value: widget.matchmakingCubit,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Chọn quán cafe'),
          centerTitle: false,
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
                  Icon(
                    Icons.extension,
                    size: AppSpacing.md + 2,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.xs - 2),
                  Expanded(
                    child: Text(
                      widget.game.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
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
                  backgroundColor: theme.colorScheme.error,
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
                        child: Text(
                          '${cafes.length} quán phù hợp',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
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
                          'Gợi ý game khác cùng thể loại',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
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