import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

import '../../../../core/error/failures.dart';
import '../../../booking_payment/presentation/cubit/booking_result_cubit.dart';
import '../../../matchmaking_discovery/domain/entities/board_game_entity.dart';
import '../../../matchmaking_discovery/presentation/cubit/matchmaking_cubit.dart';
import '../../../matchmaking_discovery/presentation/cubit/matchmaking_state.dart';
import '../../../matchmaking_discovery/presentation/pages/lobby_cafe_selection_page.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';
import '../../data/realtime/lobby_realtime_service.dart';
import '../../domain/entities/lobby_entity.dart';
import '../../domain/entities/lobby_summary.dart';
import '../cubit/lobby_cubit.dart';
import '../cubit/lobby_search_cubit.dart';
import '../cubit/my_lobbies_cubit.dart';
import '../widgets/lobby_game_filter_bar.dart';
import '../widgets/lobby_explore_tab.dart';
import '../widgets/lobby_history_tab.dart';
import '../widgets/lobby_game_picker_sheet.dart';
import 'lobby_page.dart';
import 'lobby_preview_page.dart';

/// Trang Lobby chính với 2 tabs:
/// - Tab "Khám phá": Xem các phòng chờ công khai đang hoạt động
/// - Tab "Lịch sử": Xem phòng chờ của tôi (hosted + joined)
///
/// APIs được gọi:
/// - `/api/v1/lobbies/discoverable?limit=50` - Lobby công khai
/// - `/api/v1/lobbies/hosted` - Lobby đã tạo
/// - `/api/v1/lobbies/joined` - Lobby đã tham gia
/// - `/api/v1/board-games?pageNumber=1&pageSize=20` - Danh sách game (cho filter)
class LobbyHubPage extends StatefulWidget {
  const LobbyHubPage({super.key});

  @override
  State<LobbyHubPage> createState() => _LobbyHubPageState();
}

class _LobbyHubPageState extends State<LobbyHubPage>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  static final DateFormat _timeFormatter = DateFormat('HH:mm');

  late final TabController _tabController;

  // Cubits
  late final LobbySearchCubit _searchCubit;
  late final LobbyCubit _lobbyCubit;
  late final MatchmakingCubit _matchmakingCubit;
  late final MyLobbiesCubit _myLobbiesCubit;
  late final BookingResultCubit _bookingCubit;
  late final LobbyRealtimeService _realtime;

  // Lazy loading state
  bool _hasLoadedInitialData = false;

  // Filter state
  bool _showGameFilter = false;
  BoardGameEntity? _selectedGame;
  double _radiusKm = 15.0;
  double _minKarma = 0.0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);

    // Initialize cubits from DI
    _searchCubit = context.read<LobbySearchCubit>();
    _lobbyCubit = context.read<LobbyCubit>();
    _matchmakingCubit = context.read<MatchmakingCubit>();
    _myLobbiesCubit = context.read<MyLobbiesCubit>();
    _bookingCubit = context.read<BookingResultCubit>();
    _realtime = GetIt.instance<LobbyRealtimeService>();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      _ensureDataLoaded();
    }
  }

  void _ensureDataLoaded() {
    if (_hasLoadedInitialData) return;
    _hasLoadedInitialData = true;
    _loadData();
  }

  void _loadData() {
    _searchCubit.loadDiscoverable(limit: 50);
    _loadMyLobbies();
    _subscribeRealtime();
  }

  void _loadMyLobbies() {
    final profileState = context.read<ProfileCubit>().state;
    final profile = profileState is ProfileLoaded ? profileState.profile : null;
    _myLobbiesCubit.load(profile);
  }

  Future<void> _subscribeRealtime() async {
    try {
      await _realtime.connect();
      await _realtime.subscribeNearbyLobbies(
        latitude: 10.7769,
        longitude: 106.7009,
        radiusKm: 50.0,
      );
    } catch (_) {
      // Realtime optional - continue without it
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Phòng chờ'),
        centerTitle: false,
        actions: [
          if (_tabController.index == 0)
            IconButton(
              tooltip: _showGameFilter ? 'Ẩn bộ lọc' : 'Bộ lọc game',
              icon: Icon(_showGameFilter ? Icons.tune : Icons.filter_list),
              onPressed: () {
                setState(() => _showGameFilter = !_showGameFilter);
              },
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.outline,
          indicatorColor: theme.colorScheme.primary,
          indicatorSize: TabBarIndicatorSize.label,
          indicatorWeight: 3,
          labelStyle: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          tabs: const [
            Tab(icon: Icon(Icons.explore), text: 'Khám phá'),
            Tab(icon: Icon(Icons.history), text: 'Lịch sử'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Game filter bar (only on Khám phá tab)
          if (_tabController.index == 0 && _showGameFilter)
            LobbyGameFilterBar(
              selectedGame: _selectedGame,
              radiusKm: _radiusKm,
              minKarma: _minKarma,
              onGameSelected: _onGameSelected,
              onRadiusChanged: _onRadiusChanged,
              onKarmaChanged: _onKarmaChanged,
              onClear: _clearFilter,
            ),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                LobbyExploreTab(
                  searchCubit: _searchCubit,
                  timeFormatter: _timeFormatter,
                  onPreview: _openPreview,
                  onJoin: _joinAndOpen,
                  onCreateLobby: _openCreateLobby,
                ),
                LobbyHistoryTab(
                  myLobbiesCubit: _myLobbiesCubit,
                  bookingCubit: _bookingCubit,
                  timeFormatter: _timeFormatter,
                  onTapLobby: _openMyLobby,
                  onRefresh: _loadMyLobbies,
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'lobby_hub_fab',
        onPressed: _openCreateLobby,
        icon: const Icon(Icons.add),
        label: const Text('Tạo phòng'),
      ),
    );
  }

  void _onGameSelected(BoardGameEntity? game) {
    setState(() => _selectedGame = game);
    if (game != null) {
      _searchCubit.searchNearbyLobbies(
        filter: LobbySearchFilter(
          gameId: game.id,
          radiusKm: _radiusKm,
          minKarma: _minKarma,
        ),
        currentUserKarma: _getCurrentKarma(),
      );
    } else {
      _searchCubit.loadDiscoverable(limit: 50);
    }
  }

  void _onRadiusChanged(double value) {
    setState(() => _radiusKm = value);
    if (_selectedGame != null) _onGameSelected(_selectedGame);
  }

  void _onKarmaChanged(double value) {
    setState(() => _minKarma = value);
    if (_selectedGame != null) _onGameSelected(_selectedGame);
  }

  void _clearFilter() {
    setState(() {
      _selectedGame = null;
      _radiusKm = 15.0;
      _minKarma = 0.0;
    });
    _searchCubit.loadDiscoverable(limit: 50);
  }

  double _getCurrentKarma() {
    final profileState = context.read<ProfileCubit>().state;
    if (profileState is ProfileLoaded) {
      return (profileState.profile.karmaPoints ?? 0).toDouble();
    }
    return 0;
  }

  Future<void> _openPreview(LobbyEntity lobby) async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LobbyPreviewPage(lobby: lobby, lobbyCubit: _lobbyCubit),
      ),
    );
  }

  /// Mở lobby từ danh sách "My Lobbies" (đã hosted/joined).
  /// 
  /// QUAN TRỌNG: User đã là member/host của lobby này rồi,
  /// KHÔNG gọi joinLobby() vì sẽ bị 409.
  /// Để LobbyPage.initState() tự kiểm tra membership và sync state.
  Future<void> _openMyLobby(LobbyEntity lobby) async {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LobbyPage(lobbyId: lobby.id, lobbyCubit: _lobbyCubit),
      ),
    );
  }

  /// Join lobby mới (chưa là member) rồi mở LobbyPage.
  /// Chỉ dùng cho lobby công khai hoặc lobby được invite.
  Future<void> _joinAndOpen(String lobbyId, String? inviteCode) async {
    // TODO: Kiểm tra membership trước khi join
    // Hiện tại vẫn gọi joinLobby nhưng sẽ bị 409 nếu đã là member
    // Cần cải thiện: sử dụng initLobbyState thay vì joinLobby
    final joinResult = await _lobbyCubit.joinLobby(lobbyId, inviteCode);
    if (!mounted) return;

    final failureOrLobby = joinResult.fold<Failure?>(
      (failure) => failure,
      (_) => null,
    );

    if (failureOrLobby != null) {
      // Nếu lỗi 409 (đã là member), vẫn cho phép vào lobby
      if (failureOrLobby.message.contains('đã là thành viên') ||
          failureOrLobby.message.contains('already')) {
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => LobbyPage(lobbyId: lobbyId, lobbyCubit: _lobbyCubit),
          ),
        );
        return;
      }
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

  void _openCreateLobby() {
    if (_selectedGame != null) {
      _openConfigForCreate(_selectedGame!);
    } else {
      _showGamePicker();
    }
  }

  Future<void> _showGamePicker() async {
    final state = _matchmakingCubit.state;
    final games = state is MatchmakingSearchResults
        ? state.games
        : <BoardGameEntity>[];

    if (games.isEmpty) {
      _matchmakingCubit.searchGames();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đang tải danh sách game...')),
      );
      return;
    }

    final picked = await showModalBottomSheet<BoardGameEntity>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => LobbyGamePickerSheet(games: games),
    );

    if (picked != null && mounted) {
      _openConfigForCreate(picked);
    }
  }

  void _openConfigForCreate(BoardGameEntity game) {
    // Luồng mới: tạo lobby cần chọn cafe trước (player đã biết quán → chọn
    // quán đã từng chơi → cấu hình lobby → tạo). Mở [LobbyCafeSelectionPage]
    // thay vì nhảy thẳng vào [LobbyConfigPage] để có cafeId gửi lên backend.
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LobbyCafeSelectionPage(
          game: game,
          matchmakingCubit: _matchmakingCubit,
        ),
      ),
    );
  }
}
