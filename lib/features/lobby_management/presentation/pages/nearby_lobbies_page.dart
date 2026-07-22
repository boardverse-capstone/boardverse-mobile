import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/navigation/lobby_suggestion_signal.dart';
import '../../../../core/theme/theme.dart';
import '../../../booking_payment/presentation/cubit/booking_result_cubit.dart';
import '../../../booking_payment/presentation/cubit/booking_result_state.dart';
import '../../../booking_payment/presentation/pages/booking_detail_page.dart';
import '../../../booking_payment/presentation/widgets/booking_summary_cards.dart';
import '../../../booking_payment/presentation/widgets/section_header.dart';
import '../../../booking_payment/domain/entities/booking_entity.dart';
import '../../../booking_payment/domain/entities/booking_history_entity.dart';
import '../../../matchmaking_discovery/domain/entities/board_game_entity.dart';
import '../../../matchmaking_discovery/presentation/cubit/matchmaking_cubit.dart';
import '../../../matchmaking_discovery/presentation/cubit/matchmaking_state.dart';
import '../../../matchmaking_discovery/presentation/pages/lobby_config_page.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';
import '../../../profile/presentation/cubit/profile_state.dart';
import '../../data/realtime/lobby_realtime_service.dart';
import '../../domain/entities/lobby_entity.dart';
import '../../domain/entities/lobby_summary.dart';
import '../cubit/lobby_cubit.dart';
import '../cubit/lobby_search_cubit.dart';
import '../cubit/lobby_state.dart';
import '../cubit/my_lobbies_cubit.dart';
import '../cubit/my_lobbies_state.dart';
import 'lobby_page.dart';
import 'lobby_preview_page.dart';

/// Trang Browse lobbies cho Player (Discovery → tab "Phòng chờ").
///
/// **Flow chính:** gọi `/api/v1/lobbies/discoverable?limit=N` — server trả về
/// lobby đang hoạt động đã filter theo vị trí + visibility. User **không cần
/// chọn game trước** (xem `.agents/docs/lobby_docs/lobby.md`). Mỗi card →
/// `LobbyPreviewPage` (full page detail) → "Tham gia" → confirm →
/// `LobbyPage`.
///
/// **Advanced filter** (icon 🎚️ ở header): mở drawer cho phép chọn game cụ
/// thể + bán kính + Karma → đổi sang gọi `/api/v1/lobbies/search`. Phù hợp
/// cho user muốn filter chặt hơn (vd: chỉ tìm lobby Catan trong 5km với
/// Karma ≥ 60).
class NearbyLobbiesPage extends StatefulWidget {
  const NearbyLobbiesPage({super.key});

  @override
  State<NearbyLobbiesPage> createState() => _NearbyLobbiesPageState();
}

class _NearbyLobbiesPageState extends State<NearbyLobbiesPage> {
  static final DateFormat _timeFormatter = DateFormat('HH:mm');

  /// Bật/tắt chế độ advanced filter (gọi `/search` thay vì `/discoverable`).
  bool _advancedFilter = false;

  /// Filter của advanced mode — chỉ áp dụng khi [_advancedFilter] = true.
  double _radiusKm = 10.0;
  double _minKarma = 0.0;
  BoardGameEntity? _selectedGame;

  late final LobbySearchCubit _searchCubit;
  late final LobbyCubit _lobbyCubit;
  late final MatchmakingCubit _matchmakingCubit;
  late final LobbyRealtimeService _realtime;

  /// Cubit section "Phòng chờ của tôi" — lobby hosted + active.
  late final MyLobbiesCubit _myLobbiesCubit;

  /// Cubit section "Đặt chỗ của tôi" + "Lịch sử đặt chỗ".
  late final BookingResultCubit _bookingCubit;

  /// Bán kính default cho realtime subscribe — phải trùng với bán kính
  /// user đang browse để nhận đúng broadcast từ server. Hiện tại user
  /// chưa custom được trong `/discoverable` mode nên fix cứng 50km.
  static const double _realtimeRadiusKm = 50.0;

  /// Đọc karma của current user từ ProfileCubit state. Trả 0 khi profile
  /// chưa load (mặc định an toàn — server BR-10 sẽ tự filter).
  double get _currentUserKarma {
    final profileState = context.read<ProfileCubit>().state;
    if (profileState is ProfileLoaded) {
      return (profileState.profile.karmaPoints ?? 0).toDouble();
    }
    return 0;
  }

  @override
  void initState() {
    super.initState();
    _searchCubit = context.read<LobbySearchCubit>();
    _lobbyCubit = context.read<LobbyCubit>();
    _matchmakingCubit = context.read<MatchmakingCubit>();
    _realtime = context.read<LobbyRealtimeService>();
    _myLobbiesCubit = context.read<MyLobbiesCubit>();
    _bookingCubit = context.read<BookingResultCubit>();
    // Preload games cho advanced picker (nếu user bật filter sau).
    _matchmakingCubit.searchGames();
    // Load `/discoverable` mặc định ngay khi vào trang.
    _searchCubit.loadDiscoverable(limit: 50);
    // Load 3 section "Phòng chờ của tôi" + "Đặt chỗ của tôi" + "Lịch sử".
    // Profile có thể chưa load ngay khi page mount → dùng listener bên
    // dưới để re-load khi profile tới.
    _loadMySections();
    // Subscribe broadcast location-based để nhận `NearbyLobbyCreated` /
    // `NearbyLobbyRemoved` / `NearbyLobbyUpdated`. Cubit sẽ tự reload list
    // khi nhận event. Dùng default lat/lng TP.HCM cho MVP — sau này đổi
    // sang lấy từ GPS khi tích hợp `geolocator`.
    _subscribeNearbyBroadcast();
    // Listen yêu cầu preselect game từ BoardGameDetailPage (khi user bấm
    // "Chơi cùng nhóm"). Áp dụng advanced filter với game preselect và
    // chạy search ngay. Đây là phần "đề xuất tìm phòng" của flow
    // Discovery → Lobby.
    LobbySuggestionSignal.instance.addListener(_onLobbySuggestion);
    // Drain pending request ngay trong initState — trường hợp signal đã
    // được broadcast trước khi page mount (khi user switch tab Discovery
    // lần đầu). Lúc này `LobbySuggestionSignal` đã có `pendingGame` mà
    // chưa ai consume → cần apply ngay.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (LobbySuggestionSignal.instance.pendingGame != null) {
        _onLobbySuggestion();
      }
    });
  }

  /// Load các section cá nhân: "Phòng chờ của tôi" + "Đặt chỗ của tôi" +
  /// "Lịch sử đặt chỗ". Profile có thể chưa load lần đầu (ProfileCubit
  /// async). Trong trường hợp đó, MyLobbiesCubit.load() sẽ chỉ trả
  /// active lobby từ persistence. Khi profile load xong, `BlocListener`
  /// bên dưới sẽ trigger lại để filter hosted lobbies.
  void _loadMySections() {
    final profileState = context.read<ProfileCubit>().state;
    final profile = profileState is ProfileLoaded
        ? profileState.profile
        : null;
    _myLobbiesCubit.load(profile);
    _bookingCubit.loadUpcomingAndHistory();
  }

  /// Reload các section cá nhân — dùng cho Pull-to-refresh.
  void _refreshMySections() {
    final profileState = context.read<ProfileCubit>().state;
    final profile = profileState is ProfileLoaded
        ? profileState.profile
        : null;
    _myLobbiesCubit.refresh(profile);
    _bookingCubit.loadUpcomingAndHistory();
  }

  /// Áp dụng preselect game từ `LobbySuggestionSignal`:
  /// 1. Bật advanced filter mode.
  /// 2. Set selected game.
  /// 3. Chạy advanced search ngay (gọi `/api/v1/lobbies/search`).
  ///
  /// Luôn consume signal khi nhận được để tránh apply lại khi user
  /// switch tab Discovery qua lại nhiều lần. Nếu không có pending game
  /// thì chỉ cần clear pending (defensive).
  void _onLobbySuggestion() {
    final game = LobbySuggestionSignal.instance.pendingGame;
    LobbySuggestionSignal.instance.consume();
    if (game == null) return;

    setState(() {
      _advancedFilter = true;
      _selectedGame = game;
    });
    _runAdvancedSearch();
  }

  /// Subscribe broadcast location-based. Best-effort — không block UI nếu
  /// hub chưa connect hoặc user chưa login (lúc đó realtime service tự
  /// swallow error). Cubit vẫn dùng được `/discoverable` bình thường.
  Future<void> _subscribeNearbyBroadcast() async {
    try {
      await _realtime.connect();
      await _realtime.subscribeNearbyLobbies(
        latitude: 10.7769,
        longitude: 106.7009,
        radiusKm: _realtimeRadiusKm,
      );
    } on Exception {
      // Realtime chưa sẵn sàng — bỏ qua, list vẫn hoạt động qua HTTP poll.
    }
  }

  @override
  void dispose() {
    // Hub connection là app-scoped (GetIt singleton) — không disconnect ở
    // page level. Nếu cần unsubscribe khỏi group location-based, sẽ dùng
    // method riêng từ realtime service trong tương lai. Hiện tại khi user
    // rời trang, cubit vẫn giữ subscription nhưng không emit state nếu
    // page đã dispose (`BlocBuilder` chỉ listen state khi mounted).
    LobbySuggestionSignal.instance.removeListener(_onLobbySuggestion);
    super.dispose();
  }

  /// Đổi mode và trigger reload list.
  void _toggleAdvancedFilter() {
    setState(() => _advancedFilter = !_advancedFilter);
    if (_advancedFilter) {
      _runAdvancedSearch();
    } else {
      _searchCubit.loadDiscoverable(limit: 50);
    }
  }

  void _runAdvancedSearch() {
    final game = _selectedGame;
    if (game == null) {
      _searchCubit.clear();
      return;
    }
    _searchCubit.searchNearbyLobbies(
      filter: LobbySearchFilter(
        gameId: game.id,
        radiusKm: _radiusKm,
        minKarma: _minKarma,
        excludeOwnLobbies: true,
      ),
      currentUserKarma: _currentUserKarma,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tìm phòng chờ'),
        actions: [
          IconButton(
            tooltip: _advancedFilter ? 'Tắt bộ lọc nâng cao' : 'Bộ lọc nâng cao',
            icon: Icon(
              _advancedFilter ? Icons.tune : AppIcons.filter,
            ),
            onPressed: _toggleAdvancedFilter,
          ),
          IconButton(
            tooltip: 'Tạo phòng mới',
            icon: const Icon(AppIcons.add),
            onPressed: _onCreateLobbyPressed,
          ),
        ],
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<ProfileCubit, ProfileState>(
            // Khi profile load xong → re-search để áp dụng karma filter BR-10
            // + re-load các section "Phòng chờ của tôi" (cần userId để
            // filter hosted lobbies).
            listenWhen: (prev, curr) =>
                curr is ProfileLoaded && prev is! ProfileLoaded,
            listener: (context, state) {
              if (_advancedFilter) _runAdvancedSearch();
              _myLobbiesCubit.load((state as ProfileLoaded).profile);
            },
          ),
          BlocListener<MatchmakingCubit, MatchmakingState>(
            listenWhen: (prev, curr) =>
                prev is MatchmakingLoading &&
                curr is MatchmakingSearchResults,
            listener: (context, state) {
              if (mounted) setState(() {});
            },
          ),
        ],
        child: Column(
          children: [
            if (_advancedFilter)
              _GamePickerBar(
                selected: _selectedGame,
                theme: theme,
                onPick: _openGamePicker,
                onClear: _onClearGame,
              ),
            if (_advancedFilter) const Divider(height: 1),
            if (_advancedFilter && _selectedGame != null)
              _FilterBar(
                radiusKm: _radiusKm,
                minKarma: _minKarma,
                theme: theme,
                onRadiusChanged: (value) {
                  setState(() => _radiusKm = value);
                  _runAdvancedSearch();
                },
                onKarmaChanged: (value) {
                  setState(() => _minKarma = value);
                  _runAdvancedSearch();
                },
              ),
            if (_advancedFilter && _selectedGame != null)
              const Divider(height: 1),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  _refreshMySections();
                  if (_advancedFilter) {
                    _runAdvancedSearch();
                  } else {
                    await _searchCubit.loadDiscoverable(limit: 50);
                  }
                },
                child: _buildHubBody(theme),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Body chính của trang — scroll chứa 4 section theo thứ tự:
  /// 1. Phòng chờ của tôi (lobby hosted + active).
  /// 2. Đặt chỗ của tôi (upcoming booking).
  /// 3. Lịch sử đặt chỗ (history).
  /// 4. Phòng chờ khả dụng quanh bạn (list lobby discoverable).
  Widget _buildHubBody(ThemeData theme) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // ─── Section 1: Phòng chờ của tôi ───────────────────────────────
        SliverToBoxAdapter(
          child: _MyLobbiesSection(
            cubit: _myLobbiesCubit,
            theme: theme,
            onTapLobby: _openActiveLobby,
          ),
        ),
        // ─── Section 2: Đặt chỗ của tôi ─────────────────────────────────
        SliverToBoxAdapter(
          child: _UpcomingBookingsSection(
            cubit: _bookingCubit,
            theme: theme,
            onRefresh: () async => _bookingCubit.loadUpcomingAndHistory(),
            onChanged: () async => _bookingCubit.loadUpcomingAndHistory(),
          ),
        ),
        // ─── Section 3: Lịch sử đặt chỗ ─────────────────────────────────
        SliverToBoxAdapter(
          child: _HistoryBookingsSection(
            cubit: _bookingCubit,
            theme: theme,
            onRefresh: () async => _bookingCubit.loadUpcomingAndHistory(),
          ),
        ),
        // ─── Section 4: Phòng chờ khả dụng quanh bạn ─────────────────────
        SliverToBoxAdapter(
          child: _BrowseNearbyHeader(theme: theme),
        ),
        // List lobby discoverable (giữ logic `_buildList` cũ).
        if (_advancedFilter && _selectedGame == null)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _GameRequiredView(
              theme: theme,
              onPick: _openGamePicker,
            ),
          )
        else
          ..._buildBrowseSlivers(theme),
        const SliverPadding(padding: EdgeInsets.only(bottom: AppSpacing.xl)),
      ],
    );
  }

  /// Trả về các sliver chứa list lobby discoverable (từ LobbySearchCubit).
  /// Tách ra để dễ đọc hơn.
  List<Widget> _buildBrowseSlivers(ThemeData theme) {
    return [
      SliverToBoxAdapter(
        child: BlocBuilder<LobbySearchCubit, LobbyState>(
          bloc: _searchCubit,
          builder: (context, state) {
            if (state is LobbyListLoading) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: _LoadingPanel(),
              );
            }
            if (state is LobbyListEmpty) {
              return _EmptyView(message: state.message);
            }
            if (state is LobbyFailure) {
              return _EmptyView(
                message: state.message,
                isError: true,
                onRetry: () {
                  if (_advancedFilter) {
                    _runAdvancedSearch();
                  } else {
                    _searchCubit.loadDiscoverable(limit: 50);
                  }
                },
              );
            }
            if (state is LobbyListLoaded) {
              final entities = state.entities;
              final summaries = state.lobbies;
              final total = entities.length + summaries.length;
              if (total == 0) {
                return _EmptyView(message: 'Không tìm thấy phòng nào.');
              }
              return Column(
                children: [
                  for (int index = 0; index < total; index++)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      child: index < entities.length
                          ? _LobbyCard(
                              lobby: LobbyCardData.fromEntity(
                                entities[index],
                              ),
                              theme: theme,
                              onPreview: _openPreview,
                              onJoin: _joinAndOpen,
                              timeFormatter: _timeFormatter,
                            )
                          : _LobbyCard(
                              lobby: LobbyCardData.fromSummary(
                                summaries[index - entities.length],
                              ),
                              theme: theme,
                              onPreview: _openPreview,
                              onJoin: _joinAndOpen,
                              timeFormatter: _timeFormatter,
                            ),
                    ),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    ];
  }

  /// Mở lobby active (user đã join) → LobbyPage.
  Future<void> _openActiveLobby(LobbyEntity lobby) async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LobbyPage(lobbyId: lobby.id, lobbyCubit: _lobbyCubit),
      ),
    );
  }

  /// Mở LobbyPreviewPage cho lobby. Nếu là [LobbySummary] (advanced mode),
  /// trước tiên gọi `getLobbyById` để lấy full entity.
  Future<void> _openPreview(LobbyCardData data) async {
    if (data.entity != null) {
      _pushPreview(data.entity!);
      return;
    }
    if (data.summary == null) return;
    // Fetch full lobby rồi push preview.
    final res = await _lobbyCubit.getLobbyById(data.summary!.id);
    if (!mounted) return;
    res.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        );
      },
      (lobby) {
        if (lobby == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không tìm thấy phòng này.')),
          );
          return;
        }
        _pushPreview(lobby);
      },
    );
  }

  void _pushPreview(LobbyEntity lobby) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LobbyPreviewPage(
          lobby: lobby,
          lobbyCubit: _lobbyCubit,
        ),
      ),
    );
  }

  /// Mở bottom-sheet chọn game từ kết quả `MatchmakingCubit.searchGames`.
  /// Game được chọn sẽ lưu vào [_selectedGame] và trigger search ngay.
  Future<void> _openGamePicker() async {
    final state = _matchmakingCubit.state;
    final games = state is MatchmakingSearchResults
        ? state.games
        : const <BoardGameEntity>[];
    if (games.isEmpty) {
      _matchmakingCubit.searchGames();
    }
    final picked = await showModalBottomSheet<BoardGameEntity>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _GamePickerSheet(
        games: games,
        selectedId: _selectedGame?.id,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _selectedGame = picked);
      _runAdvancedSearch();
    }
  }

  void _onClearGame() {
    setState(() => _selectedGame = null);
    _searchCubit.clear();
  }

  /// Mở flow tạo lobby cho game đã chọn. Nếu chưa có → mở picker.
  void _onCreateLobbyPressed() {
    final game = _selectedGame;
    if (game == null) {
      _openGamePicker().then((_) {
        final afterPick = _selectedGame;
        if (afterPick == null || !mounted) return;
        _openConfigForCreate(afterPick);
      });
      return;
    }
    _openConfigForCreate(game);
  }

  /// Mở form cấu hình lobby (`LobbyConfigPage`) — user chọn ngày/giờ +
  /// chế độ + bán kính + karma → bấm "Tạo phòng" → cubit tạo lobby →
  /// navigate sang `LobbyPage`.
  ///
  /// Theo phân chia nghiệp vụ mới: Discovery chỉ tìm boardgame + cafe,
  /// mọi flow tạo lobby phải đi qua screen lobby (`NearbyLobbiesPage`).
  /// Trước đây `_openDetailForCreate` nhảy sang `BoardGameDetailPage` rồi
  /// bấm "Chơi cùng nhóm" → tạo vòng lặp vô hạn giữa Discovery và Lobby.
  /// Sửa lại: nhảy thẳng tới `LobbyConfigPage` (form tạo lobby) vì đây
  /// là nghiệp vụ thuộc lobby_management.
  void _openConfigForCreate(BoardGameEntity game) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LobbyConfigPage(
          gameId: game.id,
          gameName: game.name,
          cafeId: '',
          cafeName: '',
          matchmakingCubit: _matchmakingCubit,
        ),
      ),
    );
  }

  Future<void> _joinAndOpen(LobbyCardData data) async {
    final lobbyId = data.lobbyId;
    final inviteCode = data.inviteCode;
    final joinResult = await _lobbyCubit.joinLobby(lobbyId, inviteCode);
    if (!mounted) return;
    final failureOrLobby = joinResult.fold<Failure?>(
      (failure) => failure,
      (_) => null,
    );
    if (failureOrLobby != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failureOrLobby.message)));
      return;
    }
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LobbyPage(lobbyId: lobbyId, lobbyCubit: _lobbyCubit),
      ),
    );
  }
}

class _LoadingPanel extends StatelessWidget {
  const _LoadingPanel();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: theme.colorScheme.primary),
          const SizedBox(height: AppSpacing.md),
          Text('Đang tìm phòng gần bạn...', style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

/// Header bar hiển thị game đang được chọn để search lobby.
/// Backend `/api/v1/lobbies/search` yêu cầu `gameTemplateId` là bắt buộc
/// (xem `lobby.md:188-220`), nên cần picker này ở trên cùng.
class _GamePickerBar extends StatelessWidget {
  final BoardGameEntity? selected;
  final ThemeData theme;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const _GamePickerBar({
    required this.selected,
    required this.theme,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final colors = theme.colorScheme;
    final hasSelection = selected != null;
    return InkWell(
      onTap: onPick,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: hasSelection
              ? colors.primaryContainer.withValues(alpha: 0.35)
              : colors.surfaceContainerHigh,
          border: Border(
            bottom: BorderSide(color: colors.outlineVariant),
          ),
        ),
        child: Row(
          children: [
            Icon(
              hasSelection ? Icons.extension : Icons.search,
              color: colors.primary,
              size: AppIcons.md,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasSelection
                        ? 'Đang tìm phòng cho:'
                        : 'Chọn game để tìm phòng',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasSelection ? selected!.name : 'Bắt buộc — bấm để chọn',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: hasSelection
                          ? colors.onPrimaryContainer
                          : colors.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (hasSelection)
              IconButton(
                tooltip: 'Đổi game',
                icon: const Icon(Icons.close, size: 20),
                onPressed: onClear,
              )
            else
              Icon(Icons.chevron_right, color: colors.outline),
          ],
        ),
      ),
    );
  }
}

/// Empty-state CTA yêu cầu user chọn game trước khi search lobby.
class _GameRequiredView extends StatelessWidget {
  final ThemeData theme;
  final VoidCallback onPick;

  const _GameRequiredView({required this.theme, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final colors = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videogame_asset_outlined,
              size: 72,
              color: colors.primary.withValues(alpha: 0.7),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Chọn game trước khi tìm phòng',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Server yêu cầu mã game để lọc danh sách phòng chờ đang mở '
              'gần bạn.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: onPick,
              icon: const Icon(Icons.search),
              label: const Text('Chọn game'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom-sheet picker danh sách game từ `MatchmakingCubit.searchGames`.
class _GamePickerSheet extends StatelessWidget {
  final List<BoardGameEntity> games;
  final String? selectedId;

  const _GamePickerSheet({required this.games, required this.selectedId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Chọn game',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (games.isEmpty)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Center(
                  child: Text(
                    'Đang tải danh sách game...',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: games.length,
                  itemBuilder: (context, index) {
                    final game = games[index];
                    final isSelected = game.id == selectedId;
                    return ListTile(
                      leading: game.imageUrl.isEmpty
                          ? const Icon(Icons.extension)
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                game.imageUrl,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) =>
                                    const Icon(Icons.extension),
                              ),
                            ),
                      title: Text(
                        game.name,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : null,
                        ),
                      ),
                      subtitle: Text(
                        '${game.category} · ${game.minPlayers}-${game.maxPlayers} người',
                        style: theme.textTheme.bodySmall,
                      ),
                      trailing: isSelected
                          ? Icon(
                              Icons.check_circle,
                              color: theme.colorScheme.primary,
                            )
                          : null,
                      onTap: () => Navigator.pop(context, game),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final double radiusKm;
  final double minKarma;
  final ValueChanged<double> onRadiusChanged;
  final ValueChanged<double> onKarmaChanged;
  final ThemeData theme;

  const _FilterBar({
    required this.radiusKm,
    required this.minKarma,
    required this.theme,
    required this.onRadiusChanged,
    required this.onKarmaChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        boxShadow: AppElevation.shadowXxs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FilterRow(
            icon: AppIcons.location,
            label: 'Bán kính',
            value: radiusKm < 1
                ? '${(radiusKm * 1000).toInt()} m'
                : '${radiusKm.toStringAsFixed(1)} km',
            valueColor: colors.primary,
            theme: theme,
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: colors.primary,
              thumbColor: colors.primary,
              trackHeight: 4,
            ),
            child: Slider(
              value: radiusKm,
              min: 1,
              max: 30,
              divisions: 29,
              label: '${radiusKm.toStringAsFixed(1)} km',
              onChanged: onRadiusChanged,
            ),
          ),
          _FilterRow(
            icon: AppIcons.karma,
            label: 'Karma tối thiểu',
            value: '${minKarma.toInt()}',
            valueColor: colors.tertiary,
            theme: theme,
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: colors.tertiary,
              thumbColor: colors.tertiary,
              trackHeight: 4,
            ),
            child: Slider(
              value: minKarma,
              min: 0,
              max: 100,
              divisions: 20,
              label: '${minKarma.toInt()} Karma',
              onChanged: onKarmaChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;
  final ThemeData theme;

  const _FilterRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.valueColor,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final colors = theme.colorScheme;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.xs),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: AppRadius.radiusXxsAll,
          ),
          child: Icon(icon, size: AppIcons.sm, color: colors.primary),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            color: valueColor,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

/// Wrapper cho 1 lobby trong list — chứa 1 trong 2 loại:
/// - [entity] từ `/discoverable` (full data, mở được preview ngay)
/// - [summary] từ `/search` (chỉ field cơ bản, cần fetch thêm trước khi preview)
class LobbyCardData {
  final LobbyEntity? entity;
  final LobbySummary? summary;

  const LobbyCardData._({this.entity, this.summary});

  factory LobbyCardData.fromEntity(LobbyEntity e) =>
      LobbyCardData._(entity: e);
  factory LobbyCardData.fromSummary(LobbySummary s) =>
      LobbyCardData._(summary: s);

  String get lobbyId => entity?.id ?? summary!.id;
  String? get inviteCode => entity?.inviteCode ?? summary!.inviteCode;
  String get gameName => entity?.gameName ?? summary!.gameName;
  String? get gameImageUrl =>
      entity?.gameImageUrl ?? summary!.gameImageUrl;
  String get cafeName => entity?.cafeName ?? summary!.cafeName;
  String get hostName => entity?.hostName ?? summary!.hostName;
  DateTime get scheduledTime =>
      entity?.scheduledTime ?? summary!.scheduledTime;
  int get currentPlayers =>
      entity?.currentPlayers ?? summary!.currentPlayers;
  int get maxPlayers => entity?.maxPlayers ?? summary!.maxPlayers;
  int get slotsRemaining => maxPlayers - currentPlayers;
  bool get isPublic => entity?.isPublic ?? summary!.isPublic;
  double get distanceKm {
    // `LobbyEntity.distanceKm` nullable, `LobbySummary.distanceKm` non-null.
    if (entity != null) return entity!.distanceKm ?? 0;
    return summary!.distanceKm;
  }
  double get minimumKarma {
    // `LobbyEntity.minimumKarma` non-null, `LobbySummary.minimumKarma` non-null.
    // Ưu tiên entity (full data), fallback summary.
    if (entity != null) return entity!.minimumKarma;
    return summary!.minimumKarma;
  }
}

class _LobbyCard extends StatelessWidget {
  final LobbyCardData lobby;
  final void Function(LobbyCardData) onJoin;
  final void Function(LobbyCardData) onPreview;
  final ThemeData theme;
  final DateFormat timeFormatter;

  const _LobbyCard({
    required this.lobby,
    required this.onJoin,
    required this.onPreview,
    required this.theme,
    required this.timeFormatter,
  });

  @override
  Widget build(BuildContext context) {
    final colors = theme.colorScheme;
    final distance = lobby.distanceKm < 1
        ? '${(lobby.distanceKm * 1000).toInt()} m'
        : '${lobby.distanceKm.toStringAsFixed(1)} km';
    final capacityProgress = lobby.maxPlayers == 0
        ? 0.0
        : (lobby.currentPlayers / lobby.maxPlayers).clamp(0.0, 1.0);
    final isFull = lobby.currentPlayers >= lobby.maxPlayers;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: colors.outlineVariant),
        boxShadow: AppElevation.shadowXs,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onPreview(lobby),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CardImage(lobby: lobby, theme: theme),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              lobby.gameName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          _SlotsBadge(
                            lobby: lobby,
                            isFull: isFull,
                            progress: capacityProgress,
                            theme: theme,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Row(
                        children: [
                          Icon(
                            AppIcons.cafe,
                            size: AppIcons.sm,
                            color: colors.onSurfaceVariant,
                          ),
                          const SizedBox(width: AppSpacing.xxs),
                          Expanded(
                            child: Text(
                              lobby.cafeName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [
                          _MetaChip(icon: AppIcons.location, label: distance),
                          _MetaChip(
                            icon: AppIcons.karma,
                            label: '≥ ${lobby.minimumKarma.toInt()}',
                            accent: colors.tertiary,
                          ),
                          _MetaChip(
                            icon: AppIcons.clock,
                            label: timeFormatter.format(lobby.scheduledTime),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isFull
                                ? 'Phòng đã đầy'
                                : 'Còn ${lobby.slotsRemaining} chỗ',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: isFull
                                  ? colors.error
                                  : colors.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Row(
                            children: [
                              Icon(
                                lobby.isPublic ? AppIcons.globe : AppIcons.lock,
                                size: AppIcons.sm,
                                color: colors.onSurfaceVariant,
                              ),
                              const SizedBox(width: AppSpacing.xxs),
                              Text(
                                lobby.isPublic ? 'Công khai' : 'Riêng tư',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: colors.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CardImage extends StatelessWidget {
  final LobbyCardData lobby;
  final ThemeData theme;

  const _CardImage({required this.lobby, required this.theme});

  @override
  Widget build(BuildContext context) {
    final hasImage =
        (lobby.gameImageUrl ?? '').trim().isNotEmpty;
    final placeholder = Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: AppRadius.radiusMdAll,
        gradient: LinearGradient(
          colors: theme.brightness == Brightness.dark
              ? AppColorsDark.cardGradientTeal
              : AppColors.cardGradientTeal,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            AppIcons.boardGame,
            size: AppIcons.xl,
            color: Colors.white.withValues(alpha: 0.9),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Board Game',
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );

    return ClipRRect(
      borderRadius: AppRadius.radiusMdAll,
      child: hasImage
          ? Image.network(
              lobby.gameImageUrl!,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => placeholder,
            )
          : placeholder,
    );
  }
}

class _SlotsBadge extends StatelessWidget {
  final LobbyCardData lobby;
  final bool isFull;
  final double progress;
  final ThemeData theme;

  const _SlotsBadge({
    required this.lobby,
    required this.isFull,
    required this.progress,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final colors = theme.colorScheme;
    final bg = isFull ? colors.errorContainer : colors.primaryContainer;
    final fg = isFull ? colors.onErrorContainer : colors.onPrimaryContainer;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.radiusSmAll),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${lobby.currentPlayers}/${lobby.maxPlayers}',
            style: theme.textTheme.titleMedium?.copyWith(
              color: fg,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(
            width: 44,
            child: ClipRRect(
              borderRadius: AppRadius.radiusFullAll,
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: fg.withValues(alpha: 0.18),
                valueColor: AlwaysStoppedAnimation<Color>(fg),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? accent;

  const _MetaChip({required this.icon, required this.label, this.accent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final highlight = accent ?? colors.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: AppRadius.radiusFullAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppIcons.sm, color: highlight),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: highlight,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final String message;
  final bool isError;
  final VoidCallback? onRetry;

  const _EmptyView({required this.message, this.isError = false, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return RefreshIndicator(
      onRefresh: onRetry == null ? () async {} : () async => onRetry!(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xxxl,
        ),
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: isError
                    ? colors.errorContainer
                    : colors.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isError ? AppIcons.error : AppIcons.search,
                size: AppIcons.massive,
                color: isError
                    ? colors.onErrorContainer
                    : colors.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            isError
                ? 'Đã có lỗi xảy ra, bạn có thể thử lại để cập nhật danh sách.'
                : 'Hãy tinh chỉnh bộ lọc hoặc tạo phòng mới để bắt đầu.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(AppIcons.refresh),
                label: const Text('Thử lại'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Hub sections — "Phòng chờ của tôi" + "Đặt chỗ của tôi" + "Lịch sử".
// Tách riêng khỏi [NearbyLobbiesPage] để file không quá dài.
// ════════════════════════════════════════════════════════════════════════════

/// Padding ngang chuẩn cho mỗi section trong hub. Dùng chung để đảm bảo
/// alignment với list lobby discoverable phía dưới.
const EdgeInsets _hubSectionPadding = EdgeInsets.fromLTRB(
  AppSpacing.md,
  AppSpacing.md,
  AppSpacing.md,
  0,
);

/// Header cho section "Phòng chờ khả dụng quanh bạn" — section cuối
/// của hub. Giúp tách bạch với các section cá nhân ở trên.
class _BrowseNearbyHeader extends StatelessWidget {
  final ThemeData theme;
  const _BrowseNearbyHeader({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: _hubSectionPadding,
      child: SectionHeader(
        icon: Icons.travel_explore,
        title: 'Phòng chờ khả dụng quanh bạn',
        subtitle: 'Bấm vào phòng để xem chi tiết hoặc tham gia.',
        accent: theme.colorScheme.primary,
      ),
    );
  }
}

/// Section "Phòng chờ của tôi" — lobby hosted + lobby đang active.
///
/// Tap vào card → mở `LobbyPage` (màn hình lobby detail).
class _MyLobbiesSection extends StatelessWidget {
  final MyLobbiesCubit cubit;
  final ThemeData theme;
  final Future<void> Function(LobbyEntity) onTapLobby;

  const _MyLobbiesSection({
    required this.cubit,
    required this.theme,
    required this.onTapLobby,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MyLobbiesCubit, MyLobbiesState>(
      bloc: cubit,
      builder: (context, state) {
        return Padding(
          padding: _hubSectionPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                icon: Icons.meeting_room_outlined,
                title: 'Phòng chờ của tôi',
                subtitle: 'Phòng bạn đã tạo hoặc đang tham gia.',
                accent: theme.colorScheme.primary,
              ),
              const SizedBox(height: AppSpacing.sm),
              if (state is MyLobbiesLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else if (state is MyLobbiesFailure)
                _SectionEmptyTile(
                  icon: AppIcons.error,
                  message: state.message,
                  isError: true,
                )
              else if (state is MyLobbiesLoaded && state.isEmpty)
                _SectionEmptyTile(
                  icon: Icons.meeting_room_outlined,
                  message:
                      'Bạn chưa tạo hoặc tham gia phòng chờ nào. '
                      'Bấm "Tạo phòng" để bắt đầu.',
                )
              else if (state is MyLobbiesLoaded) ...[
                if (state.active != null)
                  _MyLobbyTile(
                    lobby: state.active!,
                    isActive: true,
                    theme: theme,
                    onTap: onTapLobby,
                  ),
                for (final lobby in state.hosted)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: _MyLobbyTile(
                      lobby: lobby,
                      isActive: false,
                      theme: theme,
                      onTap: onTapLobby,
                    ),
                  ),
              ] else
                const SizedBox.shrink(),
            ],
          ),
        );
      },
    );
  }
}

/// Section "Đặt chỗ của tôi" — upcoming booking (BookingResultCubit).
class _UpcomingBookingsSection extends StatelessWidget {
  final BookingResultCubit cubit;
  final ThemeData theme;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onChanged;

  const _UpcomingBookingsSection({
    required this.cubit,
    required this.theme,
    required this.onRefresh,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingResultCubit, BookingResultState>(
      bloc: cubit,
      builder: (context, state) {
        final upcoming = _extractUpcoming(state);
        return Padding(
          padding: _hubSectionPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.md),
              SectionHeader(
                icon: Icons.event_available_outlined,
                title: 'Đặt chỗ của tôi',
                subtitle: 'Các lịch hẹn sắp tới và đang diễn ra.',
                accent: theme.colorScheme.tertiary,
              ),
              const SizedBox(height: AppSpacing.sm),
              if (upcoming.isEmpty)
                _SectionEmptyTile(
                  icon: Icons.event_busy_rounded,
                  message:
                      'Bạn chưa có lịch hẹn nào. Sau khi đặt chỗ, '
                      'lịch sẽ hiển thị tại đây.',
                )
              else
                for (final b in upcoming)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: UpcomingBookingSummaryCard(
                      booking: b,
                      onChanged: onChanged,
                      detailPageBuilder: (ctx, booking) =>
                          BookingDetailPage(booking: booking),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }
}

/// Section "Lịch sử đặt chỗ" — booking history.
class _HistoryBookingsSection extends StatelessWidget {
  final BookingResultCubit cubit;
  final ThemeData theme;
  final Future<void> Function() onRefresh;

  const _HistoryBookingsSection({
    required this.cubit,
    required this.theme,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingResultCubit, BookingResultState>(
      bloc: cubit,
      builder: (context, state) {
        final history = _extractHistory(state);
        return Padding(
          padding: _hubSectionPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.md),
              SectionHeader(
                icon: Icons.history_rounded,
                title: 'Lịch sử đặt chỗ',
                subtitle: 'Các phiên chơi đã hoàn tất hoặc đã huỷ.',
                accent: theme.colorScheme.secondary,
              ),
              const SizedBox(height: AppSpacing.sm),
              if (history.isEmpty)
                _SectionEmptyTile(
                  icon: Icons.history_rounded,
                  message: 'Chưa có lịch sử đặt chỗ.',
                )
              else
                for (final h in history)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: HistoryBookingSummaryCard(item: h),
                  ),
            ],
          ),
        );
      },
    );
  }
}

/// Empty tile cho mỗi section — gọn, không chiếm nhiều chiều cao.
class _SectionEmptyTile extends StatelessWidget {
  final IconData icon;
  final String message;
  final bool isError;

  const _SectionEmptyTile({
    required this.icon,
    required this.message,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final fg = isError ? colors.error : colors.onSurfaceVariant;
    final bg = isError ? colors.errorContainer : colors.surfaceContainerHighest;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.radiusMdAll,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: fg, size: AppIcons.md),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: fg,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Card nhỏ cho 1 lobby trong section "Phòng chờ của tôi".
class _MyLobbyTile extends StatelessWidget {
  final LobbyEntity lobby;
  final bool isActive;
  final ThemeData theme;
  final Future<void> Function(LobbyEntity) onTap;

  const _MyLobbyTile({
    required this.lobby,
    required this.isActive,
    required this.theme,
    required this.onTap,
  });

  String _statusLabel() {
    switch (lobby.status) {
      case LobbyStatus.open:
        return 'Đang tuyển người';
      case LobbyStatus.full:
        return 'Đã đầy';
      case LobbyStatus.inProgress:
        return 'Đang chơi';
      case LobbyStatus.ratingOpen:
        return 'Đang đánh giá';
      case LobbyStatus.closed:
        return 'Đã đóng';
      case LobbyStatus.timeoutFailed:
        return 'Hết hạn';
      case LobbyStatus.hostCancelled:
        return 'Đã huỷ';
    }
  }

  Color _statusColor() {
    switch (lobby.status) {
      case LobbyStatus.open:
        return theme.colorScheme.primary;
      case LobbyStatus.full:
      case LobbyStatus.inProgress:
        return theme.colorScheme.tertiary;
      case LobbyStatus.ratingOpen:
        return AppColors.info;
      case LobbyStatus.closed:
      case LobbyStatus.hostCancelled:
      case LobbyStatus.timeoutFailed:
        return theme.colorScheme.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = theme.colorScheme;
    final scheduledLabel =
        '${lobby.scheduledTime.hour.toString().padLeft(2, '0')}:${lobby.scheduledTime.minute.toString().padLeft(2, '0')} • '
        '${lobby.scheduledTime.day.toString().padLeft(2, '0')}/${lobby.scheduledTime.month.toString().padLeft(2, '0')}';
    final accent = _statusColor();

    return Material(
      color: colors.surface,
      borderRadius: AppRadius.cardRadius,
      child: InkWell(
        borderRadius: AppRadius.cardRadius,
        onTap: () => onTap(lobby),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: AppRadius.cardRadius,
            border: Border.all(
              color: isActive
                  ? accent.withValues(alpha: 0.5)
                  : colors.outlineVariant.withValues(alpha: 0.5),
              width: isActive ? 1.5 : 1,
            ),
            boxShadow: AppElevation.shadowXxs,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: AppRadius.radiusMdAll,
                  ),
                  child: Icon(
                    isActive
                        ? Icons.sports_esports_rounded
                        : Icons.meeting_room_rounded,
                    color: accent,
                    size: AppIcons.md,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              lobby.gameName,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: accent,
                                borderRadius: AppRadius.radiusXsAll,
                              ),
                              child: Text(
                                'ĐANG Ở',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colors.onPrimary,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            AppIcons.location,
                            size: AppIcons.sm,
                            color: colors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              lobby.cafeName,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Icon(
                            AppIcons.clock,
                            size: AppIcons.sm,
                            color: accent,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            scheduledLabel,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.15),
                              borderRadius: AppRadius.radiusXsAll,
                            ),
                            child: Text(
                              _statusLabel(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: accent,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colors.outline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Helpers: extract upcoming + history từ BookingResultState ────────────

List<BookingEntity> _extractUpcoming(BookingResultState state) {
  if (state is ResultUpcomingBookings) {
    return state.bookings;
  }
  if (state is ResultUpcomingAndHistory) {
    return state.upcoming;
  }
  return const <BookingEntity>[];
}

List<BookingHistoryEntity> _extractHistory(BookingResultState state) {
  if (state is ResultHistory) {
    return state.items;
  }
  if (state is ResultUpcomingAndHistory) {
    return state.history;
  }
  return const <BookingHistoryEntity>[];
}
