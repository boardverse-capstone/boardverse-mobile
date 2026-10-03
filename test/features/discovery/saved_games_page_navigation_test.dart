// Widget test cho [SavedGamesPage] navigation tới [BoardGameDetailPage].
//
// Verify:
// - Tap card → push route BoardGameDetailPage với đúng gameId
// - Tap không crash khi không có MatchmakingCubit (defensive fallback)
// - Trang empty vẫn render đúng

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:boardverse/core/di/injection.dart';
import 'package:boardverse/core/error/failures.dart';
import 'package:boardverse/core/storage/saved_games_cache.dart';
import 'package:boardverse/features/discovery/domain/entities/board_game_save_result_entity.dart';
import 'package:boardverse/features/discovery/domain/entities/discovery_request_entity.dart';
import 'package:boardverse/features/discovery/domain/entities/game_category_discovery_entity.dart';
import 'package:boardverse/features/discovery/domain/entities/group_board_game_entity.dart';
import 'package:boardverse/features/discovery/domain/entities/recommended_board_game_entity.dart';
import 'package:boardverse/features/discovery/domain/entities/saved_board_game_entity.dart';
import 'package:boardverse/features/discovery/domain/entities/solo_personalized_response_entity.dart';
import 'package:boardverse/features/discovery/domain/repositories/discovery_repository.dart';
import 'package:boardverse/features/discovery/presentation/cubit/saved_games_cubit.dart';
import 'package:boardverse/features/discovery/presentation/cubit/saved_games_state.dart';
import 'package:boardverse/features/discovery/presentation/pages/saved_games_page.dart';
import 'package:boardverse/features/matchmaking_discovery/domain/repositories/matchmaking_repository.dart';
import 'package:boardverse/features/matchmaking_discovery/presentation/cubit/matchmaking_cubit.dart';
import 'package:boardverse/features/matchmaking_discovery/presentation/cubit/matchmaking_state.dart';
import 'package:boardverse/features/matchmaking_discovery/presentation/pages/board_game_detail_page.dart';

class _MockMatchmakingRepository extends Mock implements MatchmakingRepository {}

/// Test-only subclass của `MatchmakingCubit` chỉ override
/// `loadGameDetail` để không gọi repository thật (mà chỉ ghi nhận
/// gameId được request). Các method khác dùng default từ base class
/// (không cần call vì test này chỉ verify navigation route, không
/// verify logic bên trong BoardGameDetailPage).
class _SpyMatchmakingCubit extends MatchmakingCubit {
  _SpyMatchmakingCubit({required super.repository});

  /// gameId cuối cùng mà [loadGameDetail] được gọi với.
  String? lastGameIdRequested;

  /// Tổng số lần `loadGameDetail` được gọi.
  int loadGameDetailCalls = 0;

  @override
  Future<void> loadGameDetail({
    required String gameId,
    double latitude = 10.7769,
    double longitude = 106.7009,
    bool isGpsEnabled = true,
  }) async {
    lastGameIdRequested = gameId;
    loadGameDetailCalls++;
    // Emit Loading để BoardGameDetailPage render shimmer loading
    // — không gọi API thật.
    // ignore: invalid_use_of_visible_for_testing_member, no_leading_underscores_local_reference
    emit(const MatchmakingLoading());
  }
}

List<SavedBoardGameEntity> _defaultGames() => [
      SavedBoardGameEntity(
        id: 's-1',
        gameTemplateId: 'g-catan',
        gameName: 'Catan',
        categories: const ['Strategy'],
        weight: 2.4,
        playTime: 90,
        thumbnailUrl: null,
        savedAt: DateTime(2024, 1, 1),
      ),
      SavedBoardGameEntity(
        id: 's-2',
        gameTemplateId: 'g-pandem',
        gameName: 'Pandemic',
        categories: const ['Cooperative'],
        weight: 2.4,
        playTime: 60,
        thumbnailUrl: null,
        savedAt: DateTime(2024, 1, 2),
      ),
    ];

/// Repository stub cung cấp data đã được cache (để cubit khỏi phải gọi API).
class _StubRepository implements DiscoveryRepository {
  _StubRepository({this.games = const []});

  final List<SavedBoardGameEntity> games;

  @override
  Future<Either<Failure, List<SavedBoardGameEntity>>> getSavedGames() async =>
      Right(games);

  @override
  Future<Either<Failure, BoardGameSaveResultEntity>> toggleSave(
    String gameTemplateId,
  ) async =>
      Right(BoardGameSaveResultEntity(
        gameTemplateId: gameTemplateId,
        gameName: 'Stub',
        isSaved: true,
      ));

  @override
  Future<Either<Failure, bool>> unsaveGame(String gameTemplateId) async =>
      const Right(true);

  @override
  Future<int> getSavedGamesCount() async => games.length;

  @override
  Future<Either<Failure, List<GameCategoryDiscoveryEntity>>> getCategories() async =>
      const Right([]);

  @override
  Future<Either<Failure, List<RecommendedBoardGameEntity>>> runSurvey(
    DiscoveryRequestEntity request,
  ) async =>
      const Right([]);

  @override
  Future<Either<Failure, SoloPersonalizedResponseEntity>> getSoloPersonalized({
    required DiscoveryRequestEntity request,
    double? latitude,
    double? longitude,
    int pageSize = 20,
    bool excludeSavedGames = false,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, List<GroupBoardGameEntity>>> discoverForGroup({
    required List<MemberPreferenceRequest> members,
    double? latitude,
    double? longitude,
  }) async {
    throw UnimplementedError();
  }
}

SavedGamesCubit _newSavedCubit(List<SavedBoardGameEntity> games) {
  // Pre-emit Loaded state — không chờ API. Test không quan tâm
  // cubit lifecycle, chỉ verify UI render state.
  return SavedGamesCubit(
    repository: _StubRepository(games: games),
    cache: SavedGamesCache(_FakePrefs.instance),
  )..emit(SavedGamesLoaded(
      games: games,
      totalCount: games.length,
      savedIds: games.map((g) => g.gameTemplateId).toSet(),
    ));
}

SavedGamesCubit _newEmptySavedCubit() {
  return SavedGamesCubit(
    repository: _StubRepository(games: const []),
    cache: SavedGamesCache(_FakePrefs.instance),
  )..emit(const SavedGamesLoaded(
      games: [],
      totalCount: 0,
      savedIds: {},
    ));
}

/// Singleton wrapper around SharedPreferences instance để fake trong test.
class _FakePrefs {
  static SharedPreferences? _instance;
  static SharedPreferences get instance {
    final i = _instance;
    if (i == null) {
      throw StateError('_FakePrefs chưa được init — gọi _FakePrefs.init()');
    }
    return i;
  }

  static Future<void> init() async {
    SharedPreferences.setMockInitialValues({});
    _instance = await SharedPreferences.getInstance();
  }
}

void main() {
  setUp(() async {
    await _FakePrefs.init();
    // Reset getIt — `SavedGamesPage` gọi `getIt<SavedGamesCubit>()` trong
    // `build()` để share singleton với MainScaffold. Test env không
    // chạy `setupDependencies()` của production → phải register thủ công.
    await sl.reset();
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets(
    'tap vào saved game card → push BoardGameDetailPage với đúng gameId',
    (tester) async {
      // Setup: SavedGamesCubit (Loaded) + MatchmakingCubit đều có
      // sẵn trong tree như app production.
      final savedCubit = _newSavedCubit(_defaultGames());
      final matchmakingCubit = _SpyMatchmakingCubit(
        repository: _MockMatchmakingRepository(),
      );
      // `SavedGamesPage` lookup SavedGamesCubit qua getIt singleton.
      sl.registerSingleton<SavedGamesCubit>(savedCubit);

      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<SavedGamesCubit>.value(value: savedCubit),
              BlocProvider<MatchmakingCubit>.value(value: matchmakingCubit),
            ],
            child: const SavedGamesPage(),
          ),
        ),
      );
      await tester.pump();

      // Sanity: trang render đúng danh sách game.
      expect(find.text('Catan'), findsOneWidget);
      expect(find.text('Pandemic'), findsOneWidget);

      // Tap card game đầu tiên (Catan).
      await tester.tap(find.text('Catan'));
      // Pump nhiều frame cho MaterialPageRoute transition (300ms) +
      // 1 frame cho page build.
      // Không dùng pumpAndSettle — BoardGameDetailPage render
      // shimmer loading có animation lặp vô hạn (period 1500ms),
      // pumpAndSettle sẽ timeout.
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      // Verify route mới là BoardGameDetailPage.
      expect(find.byType(BoardGameDetailPage), findsOneWidget);

      // Verify MatchmakingCubit.loadGameDetail được gọi với đúng gameId
      // (khớp với gameTemplateId của game đầu tiên).
      expect(matchmakingCubit.loadGameDetailCalls, 1);
      expect(matchmakingCubit.lastGameIdRequested, 'g-catan');

      await matchmakingCubit.close();
    },
  );

  testWidgets(
    'tap card thứ 2 → navigate với gameId của card đó (không lẫn với card 1)',
    (tester) async {
      final savedCubit = _newSavedCubit(_defaultGames());
      final matchmakingCubit = _SpyMatchmakingCubit(
        repository: _MockMatchmakingRepository(),
      );
      sl.registerSingleton<SavedGamesCubit>(savedCubit);

      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<SavedGamesCubit>.value(value: savedCubit),
              BlocProvider<MatchmakingCubit>.value(value: matchmakingCubit),
            ],
            child: const SavedGamesPage(),
          ),
        ),
      );
      await tester.pump();

      // Tap card thứ 2 (Pandemic).
      await tester.tap(find.text('Pandemic'));
      // Pump cho transition + build hoàn tất (xem comment test trên).
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.byType(BoardGameDetailPage), findsOneWidget);
      expect(matchmakingCubit.lastGameIdRequested, 'g-pandem',
          reason: 'GameId phải khớp với card Pandemic, không phải Catan');

      await matchmakingCubit.close();
    },
  );

  testWidgets(
    'tap card KHÔNG crash khi MatchmakingCubit vắng mặt (defensive fallback)',
    (tester) async {
      // Trường hợp hiếm: test wrapper hoặc deep-link route nào đó
      // navigate tới mà thiếu MatchmakingCubit trong scope. Helper
      // _openBoardGameDetail phải catch và show snackbar — không crash.
      final savedCubit = _newSavedCubit(_defaultGames());
      sl.registerSingleton<SavedGamesCubit>(savedCubit);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<SavedGamesCubit>.value(
            value: savedCubit,
            child: const SavedGamesPage(),
          ),
        ),
      );
      await tester.pump();

      // Tap — KHÔNG throw.
      await tester.tap(find.text('Catan'));
      await tester.pump();

      // Snackbar hiện thông báo fallback.
      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.text('Không thể mở chi tiết game. Vui lòng thử lại.'),
        findsOneWidget,
      );

      // Vẫn KHÔNG push route detail (vì thiếu cubit).
      expect(find.byType(BoardGameDetailPage), findsNothing);
    },
  );

  testWidgets(
    'SavedGamesPage trống (EmptyState) render đúng, không có card để tap',
    (tester) async {
      final savedCubit = _newEmptySavedCubit();
      final matchmakingCubit = _SpyMatchmakingCubit(
        repository: _MockMatchmakingRepository(),
      );
      sl.registerSingleton<SavedGamesCubit>(savedCubit);

      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<SavedGamesCubit>.value(value: savedCubit),
              BlocProvider<MatchmakingCubit>.value(value: matchmakingCubit),
            ],
            child: const SavedGamesPage(),
          ),
        ),
      );
      await tester.pump();

      // EmptyState render — title được convert sang UPPERCASE
      // (EmptyStateWidget.title.toUpperCase()).
      expect(find.text('CHƯA CÓ GAME NÀO'), findsOneWidget);

      // Không có BoardGameDetailPage được push.
      expect(find.byType(BoardGameDetailPage), findsNothing);
      expect(matchmakingCubit.loadGameDetailCalls, 0);

      await matchmakingCubit.close();
    },
  );
}