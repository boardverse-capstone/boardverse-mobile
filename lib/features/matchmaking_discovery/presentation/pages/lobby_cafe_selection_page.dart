import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../booking_payment/presentation/pages/booking_summary_page.dart';
import '../../../profile/domain/entities/player_location_entity.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';
import '../../domain/entities/board_game_entity.dart';
import '../../domain/entities/cafe_entity.dart';
import '../cubit/matchmaking_cubit.dart';
import '../cubit/matchmaking_state.dart';
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

  /// Walk-in flag — khi `true`, sau khi chọn cafe sẽ nhảy thẳng
  /// `BookingSummaryPage(lobbyId: null)` thay vì `LobbyConfigPage` (gap #3).
  final bool isWalkInSolo;

  const LobbyCafeSelectionPage({
    super.key,
    required this.game,
    required this.matchmakingCubit,
    this.isWalkInSolo = false,
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

    final picked = await showDialog<_LocationPick>(
      context: context,
      builder: (_) => const _LocationPickerDialog(),
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
    if (widget.isWalkInSolo) {
      // Walk-in: skip lobby creation, jump straight to BookingSummaryPage.
      // BookingSummaryPage sẽ tự load availability + bàn trống (gaps #1, #2).
      final now = DateTime.now();
      final startTime = DateTime(now.year, now.month, now.day, now.hour + 1);
      final endTime = startTime.add(const Duration(hours: 2));
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => BookingSummaryPage(
            // lobbyId == null → walk-in (gap #3).
            lobbyId: null,
            cafeId: cafe.id,
            cafeName: cafe.name,
            // cafeTableId rỗng → cubit sẽ resolve từ availableTables API.
            cafeTableId: '',
            gameId: widget.game.id,
            gameName: widget.game.name,
            scheduledStartTime: startTime,
            scheduleEndTime: endTime,
            // Mặc định 1 người cho walk-in; user có thể chỉnh trong page.
            seatCount: 1,
            playerQuantity: 1,
          ),
        ),
      );
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => LobbyConfigPage(
          gameId: widget.game.id,
          gameName: widget.game.name,
          cafeId: cafe.id,
          cafeName: cafe.name,
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
              return const Center(child: CircularProgressIndicator());
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
                      _LocationBanner(
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
                      _EmptyState(
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
                          child: _SelectableCafeCard(
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
              return _ErrorRetryView(
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

class _SelectableCafeCard extends StatelessWidget {
  final CafeEntity cafe;
  final VoidCallback onTap;

  const _SelectableCafeCard({required this.cafe, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final distanceLabel = cafe.distanceMeters < 1000
        ? '${cafe.distanceMeters.toStringAsFixed(0)} m'
        : '${(cafe.distanceMeters / 1000).toStringAsFixed(1)} km';

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusSmAll),
      child: InkWell(
        borderRadius: AppRadius.radiusSmAll,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm + 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.local_cafe,
                color: theme.colorScheme.primary,
                size: AppSpacing.xl + AppSpacing.xs,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cafe.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (cafe.address.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        cafe.address,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xxs,
                      children: [
                        _Chip(
                          icon: Icons.location_on,
                          label: distanceLabel,
                        ),
                        if (cafe.isWaitingForGame &&
                            cafe.estimatedWaitMinutes != null)
                          _Chip(
                            icon: Icons.hourglass_bottom,
                            label:
                                'Chờ game ~${cafe.estimatedWaitMinutes} phút',
                            color: AppColors.warning.withValues(alpha: 0.12),
                            textColor: AppColors.warningDark,
                          ),
                        if (cafe.totalTableCount > 0)
                          _Chip(
                            icon: Icons.table_restaurant,
                            label:
                                '${cafe.availableTableCount}/${cafe.totalTableCount} bàn',
                          ),
                        if (cafe.rating > 0)
                          _Chip(
                            icon: Icons.star,
                            label: cafe.rating.toStringAsFixed(1),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final Color? textColor;

  const _Chip({
    required this.icon,
    required this.label,
    this.color,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = color ?? theme.colorScheme.surfaceContainerHighest;
    final fg = textColor ?? theme.colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.radiusXsAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppSpacing.sm, color: fg),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationBanner extends StatelessWidget {
  final bool hasManualLocation;
  final bool isUpdating;
  final VoidCallback onRefreshLocation;
  final VoidCallback onClearManualLocation;

  const _LocationBanner({
    required this.hasManualLocation,
    required this.isUpdating,
    required this.onRefreshLocation,
    required this.onClearManualLocation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        0,
      ),
      padding: AppSpacing.paddingAllSm,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.sm - 2),
      ),
      child: Row(
        children: [
          Icon(
            hasManualLocation ? Icons.edit_location_alt : Icons.my_location,
            color: theme.colorScheme.primary,
            size: AppSpacing.lg,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              hasManualLocation
                  ? 'Đang dùng vị trí đã chọn thủ công.'
                  : 'Đang tìm quán quanh vị trí đã lưu của bạn.',
              style: theme.textTheme.bodySmall,
            ),
          ),
          if (hasManualLocation)
            TextButton(
              onPressed: isUpdating ? null : onClearManualLocation,
              child: const Text('Dùng vị trí đã lưu'),
            ),
          const SizedBox(width: AppSpacing.xxs),
          FilledButton.tonal(
            onPressed: isUpdating ? null : onRefreshLocation,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs - 2,
              ),
              visualDensity: VisualDensity.compact,
              textStyle: theme.textTheme.labelMedium,
            ),
            child: isUpdating
                ? const SizedBox(
                    width: AppSpacing.sm + 2,
                    height: AppSpacing.sm + 2,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Cập nhật'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.xl,
        AppSpacing.xxl,
        AppSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.store_mall_directory_outlined,
            size: AppSpacing.huge + AppSpacing.xs,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorRetryView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final Future<void> Function() onUpdateLocation;
  const _ErrorRetryView({
    required this.message,
    required this.onRetry,
    required this.onUpdateLocation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: AppSpacing.paddingAllXl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off,
              size: AppSpacing.huge + AppSpacing.xs,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
            const SizedBox(height: AppSpacing.xs),
            TextButton.icon(
              onPressed: () => onUpdateLocation(),
              icon: const Icon(Icons.my_location),
              label: const Text('Cập nhật vị trí'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kết quả trả về từ [_LocationPickerDialog].
class _LocationPick {
  final String label;
  final double latitude;
  final double longitude;

  const _LocationPick({
    required this.label,
    required this.latitude,
    required this.longitude,
  });
}

/// Dialog cho phép user chọn vị trí đại diện (theo thành phố) để ghi lên
/// profile. Dùng khi thiết bị không có GPS hoặc app chưa tích hợp
/// `geolocator` — user chọn thành phố → lưu lat/lng tương ứng lên server.
///
/// Các tọa độ dưới đây là trung tâm thành phố lớn tại Việt Nam, đủ để
/// backend `/api/cafes/nearby/me` trả về quán trong bán kính 15 km mặc định.
class _LocationPickerDialog extends StatefulWidget {
  const _LocationPickerDialog();

  @override
  State<_LocationPickerDialog> createState() => _LocationPickerDialogState();
}

class _LocationPickerDialogState extends State<_LocationPickerDialog> {
  /// Danh sách thành phố preset. Cập nhật/thêm nếu mở rộng khu vực.
  static const _presets = <_LocationPick>[
    _LocationPick(label: 'TP. Hồ Chí Minh', latitude: 10.7769, longitude: 106.7009),
    _LocationPick(label: 'Hà Nội', latitude: 21.0285, longitude: 105.8542),
    _LocationPick(label: 'Đà Nẵng', latitude: 16.0544, longitude: 108.2022),
    _LocationPick(label: 'Hải Phòng', latitude: 20.8449, longitude: 106.6881),
    _LocationPick(label: 'Cần Thơ', latitude: 10.0452, longitude: 105.7469),
    _LocationPick(label: 'Nha Trang', latitude: 12.2388, longitude: 109.1967),
    _LocationPick(label: 'Vũng Tàu', latitude: 10.3460, longitude: 107.0843),
  ];

  _LocationPick? _selected = _presets.first;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Cập nhật vị trí của bạn'),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chọn khu vực để hệ thống tìm quán cafe xung quanh bạn.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<_LocationPick>(
              initialValue: _selected,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Khu vực',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final p in _presets)
                  DropdownMenuItem<_LocationPick>(
                    value: p,
                    child: Text(p.label),
                  ),
              ],
              onChanged: (v) => setState(() => _selected = v),
            ),
            const SizedBox(height: 8),
            if (_selected != null)
              Text(
                'Lat ${_selected!.latitude.toStringAsFixed(4)}, '
                'Lng ${_selected!.longitude.toStringAsFixed(4)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Huỷ'),
        ),
        FilledButton(
          onPressed: _selected == null
              ? null
              : () => Navigator.of(context).pop(_selected),
          child: const Text('Lưu'),
        ),
      ],
    );
  }
}
