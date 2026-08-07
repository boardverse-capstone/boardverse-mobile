import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/navigation/lobby_flow_navigator.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/utils/current_user_resolver.dart';
import '../../../matchmaking_discovery/domain/entities/board_game_entity.dart';
import '../../../matchmaking_discovery/presentation/cubit/matchmaking_cubit.dart';
import '../../../matchmaking_discovery/presentation/cubit/matchmaking_state.dart';
import '../../../matchmaking_discovery/presentation/pages/lobby_cafe_selection_page.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';
import '../widgets/lobby_game_picker_sheet.dart';
import '../../data/realtime/lobby_realtime_service.dart';
import '../../domain/entities/lobby_entity.dart';
import '../../domain/entities/lobby_summary.dart';
import '../cubit/lobby_cubit.dart';
import '../cubit/lobby_search_cubit.dart';
import '../cubit/my_lobbies_cubit.dart';
import '../widgets/lobby_game_filter_bar.dart';
import '../widgets/lobby_explore_tab.dart';
import '../widgets/lobby_history_tab.dart';
import '../widgets/lobby_hub_actions.dart';
import 'lobby_page.dart';
import 'lobby_preview_page.dart';

/// Modern Lobby Hub page với gradient FAB, pill tab indicator.
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
  late final LobbyRealtimeService _realtime;

  bool _hasLoadedInitialData = false;
  bool _showGameFilter = false;
  BoardGameEntity? _selectedGame;
  double _radiusKm = 15.0;
  double _minKarma = 0.0;

  /// ID user hiện tại — resolve từ JWT trong secure storage qua
  /// `CurrentUserResolver`. Dùng để so sánh với `lobby.hostId` trong
  /// `_LobbyList` → phân biệt lobby do mình tạo (UI khác + tap → mở
  /// thẳng LobbyPage) với lobby của người khác (UI cũ + preview/join).
  ///
  /// `null` = chưa resolve xong (khi đó coi như không có lobby nào là
  /// của mình, UI render bình thường). Async resolve trong initState,
  /// setState khi có kết quả.
  String? _currentUserId;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);

    _searchCubit = context.read<LobbySearchCubit>();
    _lobbyCubit = context.read<LobbyCubit>();
    _matchmakingCubit = context.read<MatchmakingCubit>();
    _myLobbiesCubit = context.read<MyLobbiesCubit>();
    _realtime = GetIt.instance<LobbyRealtimeService>();

    // Resolve currentUserId từ JWT — không block UI; nếu resolve
    // xong sau khi list đã render thì setState sẽ rebuild với
    // `currentUserId` đúng → list card tự phân biệt lobby của mình.
    _resolveCurrentUserId();
  }

  Future<void> _resolveCurrentUserId() async {
    final id = await sl<CurrentUserResolver>().resolveUserId();
    if (!mounted) return;
    setState(() => _currentUserId = id);
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) _ensureDataLoaded();
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
      // Realtime optional
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
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Phòng chờ',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        actions: [
          const LobbyHubActions(),
          if (_tabController.index == 0)
            IconButton(
              tooltip: _showGameFilter ? 'Ẩn bộ lọc' : 'Bộ lọc game',
              icon: Icon(_showGameFilter ? Icons.tune : Icons.filter_list),
              onPressed: () => setState(() => _showGameFilter = !_showGameFilter),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _ModernTabBar(
            controller: _tabController,
            theme: theme,
            colors: colors,
          ),
        ),
      ),
      body: Column(
        children: [
          // Game filter bar
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: LobbyGameFilterBar(
              selectedGame: _selectedGame,
              radiusKm: _radiusKm,
              minKarma: _minKarma,
              onGameSelected: _onGameSelected,
              onRadiusChanged: _onRadiusChanged,
              onKarmaChanged: _onKarmaChanged,
              onClear: _clearFilter,
            ),
            crossFadeState: _showGameFilter ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
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
                  onOpenOwned: _openOwnedLobby,
                  onJoin: _joinAndOpen,
                  onCreateLobby: _openCreateLobby,
                  currentUserId: _currentUserId,
                ),
                LobbyHistoryTab(
                  myLobbiesCubit: _myLobbiesCubit,
                  timeFormatter: _timeFormatter,
                  onTapLobby: _openMyLobby,
                  onRefresh: _loadMyLobbies,
                ),
              ],
            ),
          ),
        ],
      ),

      // Gradient FAB
      floatingActionButton: _ModernFab(onPressed: _openCreateLobby),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
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

  Future<void> _openMyLobby(LobbyEntity lobby) async {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LobbyPage(lobbyId: lobby.id, lobbyCubit: _lobbyCubit),
      ),
    );
  }

  /// Mở LobbyPage cho lobby do chính user hiện tại host (được tap từ
  /// tab Explore). Tương đương `_openMyLobby` (đã dùng cho tab Lịch sử)
  /// nhưng tách riêng để rõ semantic: tap từ Explore → không qua preview
  /// popup, mở LobbyPage thẳng.
  Future<void> _openOwnedLobby(LobbyEntity lobby) async {
    await _openMyLobby(lobby);
  }

  Future<void> _joinAndOpen(String lobbyId, String? inviteCode) async {
    final joinResult = await _lobbyCubit.joinLobby(lobbyId, inviteCode);
    if (!mounted) return;

    final failureOrLobby = joinResult.fold<Failure?>(
      (failure) => failure,
      (_) => null,
    );

    if (failureOrLobby != null) {
      final msg = failureOrLobby.message;
      final is409 = msg.contains('409') ||
          msg.contains('trạng thái mở') ||
          msg.contains('đã đóng') ||
          msg.contains('đang chờ cafe duyệt') ||
          msg.contains('đang chơi');

      if (msg.contains('đã là thành viên') || msg.contains('already')) {
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => LobbyPage(lobbyId: lobbyId, lobbyCubit: _lobbyCubit),
          ),
        );
        return;
      }

      if (is409) {
        _showLobbyStatusDialog(msg);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
      return;
    }

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LobbyPage(lobbyId: lobbyId, lobbyCubit: _lobbyCubit),
      ),
    );
  }

  void _showLobbyStatusDialog(String message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Theme.of(ctx).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.tertiaryContainer.withValues(alpha: 0.3),
                borderRadius: AppRadius.radiusMdAll,
              ),
              child: Row(
                children: [
                  Icon(
                    AppIcons.info,
                    color: Theme.of(ctx).colorScheme.tertiary,
                    size: 28,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Phòng không khả dụng',
                          style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          message,
                          style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Đã hiểu'),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  /// Mở flow tạo lobby.
  ///
  /// Luồng đơn giản hoá sau khi bỏ `LobbyCreateSetupPage`:
  ///   1. Cần có game đã chọn (từ filter bar hoặc game picker).
  ///   2. Mở `LobbyCafeSelectionPage` để chọn quán cafe.
  ///   3. `LobbyConfigPage` → `LobbyQuotePage` (đặt cọc) → lobby.
  ///
  /// Nếu chưa có game, hiển thị bottom sheet picker để user chọn game
  /// trước khi tiếp tục.
  Future<void> _openCreateLobby() async {
    var game = _selectedGame;
    if (game == null) {
      // Khởi tạo search games một lần (cached) và hiển thị picker.
      final state = _matchmakingCubit.state;
      if (state is! MatchmakingSearchResults) {
        await _matchmakingCubit.searchGames();
      }
      if (!mounted) return;
      final picked = await showModalBottomSheet<BoardGameEntity>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (sheetCtx) {
          final s = _matchmakingCubit.state;
          final games = s is MatchmakingSearchResults ? s.games : <BoardGameEntity>[];
          return LobbyGamePickerSheet(games: games);
        },
      );
      if (picked == null) return;
      game = picked;
      setState(() => _selectedGame = picked);
    }

    if (!mounted) return;
    LobbyFlowNavigator.push(
      context,
      LobbyCafeSelectionPage(
        game: game,
        matchmakingCubit: _matchmakingCubit,
      ),
    );
  }
}

/// Modern pill-style tab bar với gradient indicator.
class _ModernTabBar extends StatelessWidget implements PreferredSizeWidget {
  final TabController controller;
  final ThemeData theme;
  final ColorScheme colors;

  const _ModernTabBar({
    required this.controller,
    required this.theme,
    required this.colors,
  });

  @override
  Size get preferredSize => const Size.fromHeight(48);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: AppRadius.radiusFullAll,
        ),
        child: TabBar(
          controller: controller,
          isScrollable: false,
          dividerColor: Colors.transparent,
          indicator: BoxDecoration(
            gradient: LinearGradient(
              colors: [colors.primary, colors.primary.withAlpha(204)],
            ),
            borderRadius: AppRadius.radiusFullAll,
            boxShadow: [
              BoxShadow(
                color: colors.primary.withAlpha(64),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorPadding: const EdgeInsets.all(4),
          labelColor: Colors.white,
          unselectedLabelColor: colors.onSurfaceVariant,
          labelStyle: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          labelPadding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
          tabs: const [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.explore, size: 18),
                  SizedBox(width: 6),
                  Text('Khám phá'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history, size: 18),
                  SizedBox(width: 6),
                  Text('Của tôi'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Modern gradient FAB.
class _ModernFab extends StatelessWidget {
  final VoidCallback onPressed;

  const _ModernFab({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.primary, colors.primary.withAlpha(204)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withAlpha(102),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(28),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add, color: Colors.white, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Tạo phòng',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
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
