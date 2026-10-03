import 'package:boardverse/core/storage/saved_games_cache.dart';
import 'package:boardverse/features/discovery/domain/entities/board_game_save_result_entity.dart';
import 'package:boardverse/features/discovery/domain/entities/recommended_board_game_entity.dart';
import 'package:boardverse/features/discovery/domain/entities/saved_board_game_entity.dart';
import 'package:boardverse/features/discovery/domain/repositories/discovery_repository.dart';
import 'package:boardverse/features/discovery/presentation/cubit/saved_games_cubit.dart';
import 'package:boardverse/features/discovery/presentation/cubit/saved_games_state.dart';
import 'package:boardverse/features/discovery/presentation/widgets/recommended_game_card.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Widget test cho [RecommendedGameCard] defensive behavior.
///
/// Trước đây, `_CardSaveButton` (nằm trong `RecommendedGameCard`) dùng
/// `BlocBuilder<SavedGamesCubit>` mà không check xem cubit có sẵn
/// trong widget tree hay không. Khi thiếu → `ProviderNotFoundException`
/// → Flutter render red error widget che mất thumbnail boardgame.
///
/// Fix: nếu `SavedGamesCubit` không có trong tree, render disabled
/// heart icon (không crash).
class _MockDiscoveryRepository extends Mock implements DiscoveryRepository {}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  RecommendedBoardGameEntity _makeGame({
    String id = 'g1',
    String name = 'Pandemic',
    String? imageUrl,
    double score = 80,
    double? weight = 2.4,
    bool isSaved = false,
  }) {
    return RecommendedBoardGameEntity(
      id: id,
      name: name,
      imageUrl: imageUrl,
      score: score,
      weight: weight,
      minPlayers: 2,
      maxPlayers: 4,
      playTimeMinutes: 45,
      categories: const ['Cooperative'],
      matchReasons: const ['Cooperative'],
      isSaved: isSaved,
    );
  }

  group('RecommendedGameCard defensive save button', () {
    testWidgets(
      'renders without crashing when SavedGamesCubit is NOT provided',
      (tester) async {
        // Push RecommendedGameCard WITHOUT any BlocProvider in tree.
        // Pre-fix: this throws ProviderNotFoundException → red error widget.
        // Post-fix: this renders gracefully with disabled heart icon.
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 500,
                child: RecommendedGameCard(game: _makeGame()),
              ),
            ),
          ),
        );

        // Card builds without throwing
        expect(tester.takeException(), isNull);

        // Bookmark outline (not filled) because no cubit -> no saved state.
        // Using bookmark icon (not heart) per UI design choice.
        expect(find.byIcon(Icons.bookmark_border_rounded), findsOneWidget);
        expect(find.byIcon(Icons.bookmark_rounded), findsNothing);

        // Game name is rendered (proves thumbnail Stack didn't crash)
        expect(find.text('Pandemic'), findsOneWidget);
      },
    );

    testWidgets(
      'still allows tap (graceful no-op) when cubit missing',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 500,
                child: RecommendedGameCard(game: _makeGame()),
              ),
            ),
          ),
        );

        // Tap the bookmark icon -- should NOT crash even without cubit
        await tester.tap(find.byIcon(Icons.bookmark_border_rounded));
        await tester.pump();

        // Still no exception
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('RecommendedGameCard API isSaved fallback', () {
    // Stub cubit khong can call API — chi emit state thu cong cho test.
    Future<SavedGamesCubit> _newCubit() async {
      final prefs = await SharedPreferences.getInstance();
      final cache = SavedGamesCache(prefs);
      return SavedGamesCubit(
        repository: _MockDiscoveryRepository(),
        cache: cache,
      );
    }

    testWidgets(
      'shows filled bookmark when game.isSaved=true and cubit in Initial state '
      '(API is source of truth before cubit loads)',
      (tester) async {
        // Cubit dang o SavedGamesInitial — savedIds chua co data.
        // Truoc fix: icon hien "chua luu" du API da noi isSaved=true.
        // Sau fix: icon hien "da luu" (filled) tu API fallback.
        final cubit = await _newCubit();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BlocProvider<SavedGamesCubit>.value(
                value: cubit,
                child: SizedBox(
                  width: 400,
                  height: 500,
                  child: RecommendedGameCard(
                    game: _makeGame(id: 'g-saved', isSaved: true),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        // Filled bookmark (saved state) tu API fallback.
        expect(find.byIcon(Icons.bookmark_rounded), findsOneWidget);
        expect(find.byIcon(Icons.bookmark_border_rounded), findsNothing);

        await cubit.close();
      },
    );

    testWidgets(
      'falls back to game.isSaved=true when cubit state is Error without savedIds',
      (tester) async {
        // SavedGamesError khong co savedIds (post-refresh failure).
        // Truoc fix: icon co the sai. Sau fix: fallback `initialIsSaved`.
        final cubit = await _newCubit();
        cubit.emit(const SavedGamesError(message: 'API failed'));

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BlocProvider<SavedGamesCubit>.value(
                value: cubit,
                child: SizedBox(
                  width: 400,
                  height: 500,
                  child: RecommendedGameCard(
                    game: _makeGame(id: 'g-error-saved', isSaved: true),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.byIcon(Icons.bookmark_rounded), findsOneWidget);

        await cubit.close();
      },
    );

    testWidgets(
      'shows outline when game.isSaved=false and cubit in Initial state',
      (tester) async {
        final cubit = await _newCubit();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BlocProvider<SavedGamesCubit>.value(
                value: cubit,
                child: SizedBox(
                  width: 400,
                  height: 500,
                  child: RecommendedGameCard(
                    game: _makeGame(id: 'g-unsaved', isSaved: false),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        // Outline (unsaved) khi API va cubit dong y "chua luu".
        expect(find.byIcon(Icons.bookmark_border_rounded), findsOneWidget);
        expect(find.byIcon(Icons.bookmark_rounded), findsNothing);

        await cubit.close();
      },
    );

    testWidgets(
      'cubit state wins over API when cubit has reliable data',
      (tester) async {
        // game.isSaved=true (API), nhung cubit Loaded ma savedIds
        // KHONG co game nay (sau toggle unsave) → icon phai la outline.
        final cubit = await _newCubit();
        cubit.emit(const SavedGamesLoaded(
          games: [],
          totalCount: 0,
          savedIds: <String>{}, // empty → gameId 'g-divergent' khong co
        ));

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BlocProvider<SavedGamesCubit>.value(
                value: cubit,
                child: SizedBox(
                  width: 400,
                  height: 500,
                  child: RecommendedGameCard(
                    game: _makeGame(id: 'g-divergent', isSaved: true),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        // Cubit noi "chua luu" → outline thang, bo qua API fallback.
        expect(find.byIcon(Icons.bookmark_border_rounded), findsOneWidget);
        expect(find.byIcon(Icons.bookmark_rounded), findsNothing);

        await cubit.close();
      },
    );
  });

  group('RecommendedGameCard tap transitions UI', () {
    // Khi player an luu / bo luu, UI icon phai thay doi ngay (filled ->
    // outline hoac outline -> filled), ke ca khi SavedGamesCubit dang o
    // state Initial (do discovery_results_page khong goi loadSavedGames).
    //
    // Bug truoc day: _optimisticUpdate trong SavedGamesCubit khong co
    // branch cho Initial/Refreshing/Error -> emit im lang -> button
    // BlocBuilder khong rebuild -> user khong thay UI thay doi.
    Future<SavedGamesCubit> _newCubitWithStubbedToggle({
      bool serverReturnsIsSaved = true,
    }) async {
      final prefs = await SharedPreferences.getInstance();
      final cache = SavedGamesCache(prefs);
      final repo = _MockDiscoveryRepository();
      // Stub toggleSave tra ve gia tri co dinh theo tham so
      // `serverReturnsIsSaved` (de test setup xac dinh).
      when(() => repo.toggleSave(any())).thenAnswer((invocation) async {
        final id = invocation.positionalArguments.first as String;
        return Right(BoardGameSaveResultEntity(
          gameTemplateId: id,
          gameName: '',
          isSaved: serverReturnsIsSaved,
          savedAt: null,
          message: serverReturnsIsSaved
              ? 'Đã lưu board game.'
              : 'Đã bỏ lưu board game.',
        ));
      });
      // Stub getSavedGames tra ve empty list (de loadSavedGames
      // neu goi se khong throw).
      when(() => repo.getSavedGames()).thenAnswer((_) async => const Right([]));
      return SavedGamesCubit(repository: repo, cache: cache);
    }

    testWidgets(
      'tap from Initial state flips outline -> filled immediately',
      (tester) async {
        // Day la scenario nguoi dung gap: mo survey, cubit Initial,
        // API noi isSaved=false -> hien outline, an luu -> ky vong
        // UI chuyen thanh filled ngay (truoc khi API response).
        final cubit = await _newCubitWithStubbedToggle(
          serverReturnsIsSaved: true, // toggle save thanh cong
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BlocProvider<SavedGamesCubit>.value(
                value: cubit,
                child: SizedBox(
                  width: 400,
                  height: 500,
                  child: RecommendedGameCard(
                    game: _makeGame(id: 'g-tap', isSaved: false),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        // Ban dau: outline (chua luu).
        expect(find.byIcon(Icons.bookmark_border_rounded), findsOneWidget);
        expect(find.byIcon(Icons.bookmark_rounded), findsNothing);

        // Tap save. Cubit state tu Initial -> LoadingFromCache
        // (do _optimisticUpdate fallback). BlocBuilder phai rebuild.
        await tester.tap(find.byIcon(Icons.bookmark_border_rounded));
        // Pump rieng cho tung phase:
        // 1. pump() xu ly tap event va state emit (sync).
        // 2. pump 300ms cho AnimatedSwitcher (240ms) hoan thanh icon swap.
        // 3. pump 400ms cho API stub tra ve va state sync voi server.
        //
        // Dung `pump(...)` thay cho `pumpAndSettle(...)` vi toast
        // (`AppToast.showSuccess` qua `delightful_toast`) co animation
        // tu `flutter_animate` chay rat lau, gay pending timer
        // khi `pumpAndSettle`. Test nay chi verify icon thay doi,
        // khong care toast nen pump rieng se dam bao on dinh.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 400));

        // Sau tap + API response (stub isSaved=true) → filled.
        expect(find.byIcon(Icons.bookmark_rounded), findsOneWidget);
        expect(find.byIcon(Icons.bookmark_border_rounded), findsNothing);

        await cubit.close();
      },
    );

    testWidgets(
      'tap from Initial state with isSaved=true flips filled -> outline after API',
      (tester) async {
        // API noi isSaved=true (DB da luu), cache rong, user an icon
        // de BO LUU → UI ky vong chuyen filled → outline sau khi
        // API confirm (server toggle tu true thanh false).
        //
        // Edge case: cache out-of-sync voi server. Luc dau cubit se
        // toggle SAI chieu (cache empty → toggle save), nhung ngay
        // sau khi API tra ve isSaved=false, cubit se sync lai state
        // → UI chuyen thanh outline.
        final cubit = await _newCubitWithStubbedToggle(
          serverReturnsIsSaved: false, // server toggle: true -> false
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BlocProvider<SavedGamesCubit>.value(
                value: cubit,
                child: SizedBox(
                  width: 400,
                  height: 500,
                  child: RecommendedGameCard(
                    game: _makeGame(id: 'g-tap-2', isSaved: true),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        // Ban dau: filled (do API fallback).
        expect(find.byIcon(Icons.bookmark_rounded), findsOneWidget);
        expect(find.byIcon(Icons.bookmark_border_rounded), findsNothing);

        // Tap. Sau khi API confirm, UI phai chuyen sang outline.
        await tester.tap(find.byIcon(Icons.bookmark_rounded));
        // Pump rieng (khong pumpAndSettle) de tranh pending timer tu
        // toast animation (delightful_toast + flutter_animate).
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 400));

        expect(find.byIcon(Icons.bookmark_border_rounded), findsOneWidget);

        await cubit.close();
      },
    );

    testWidgets(
      'unsave from Loaded state flips filled -> outline',
      (tester) async {
        // Cubit Loaded, gameId co trong savedIds → hien filled.
        // User an bo luu → UI ky vong chuyen filled → outline.
        //
        // QUAN TRONG: cache phai dong bo voi state.savedIds (de
        // cubit toggle dung chieu). Production code: `loadSavedGames`
        // se sync cache qua `_cache.replaceAll(...)`. Trong test nay
        // ta emit Loaded truc tiep, nen can sync cache bang tay.
        final cubit = await _newCubitWithStubbedToggle(
          serverReturnsIsSaved: false, // toggle unsave thanh cong
        );
        final prefs = await SharedPreferences.getInstance();
        final cache = SavedGamesCache(prefs);
        await cache.add('g-loaded'); // Sync cache voi state
        cubit.emit(SavedGamesLoaded(
          games: [
            SavedBoardGameEntity(
              id: 'g-loaded',
              gameTemplateId: 'g-loaded',
              gameName: 'Pandemic',
              categories: const [],
              savedAt: DateTime(2026, 1, 1),
            ),
          ],
          totalCount: 1,
          savedIds: const {'g-loaded'},
        ));

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BlocProvider<SavedGamesCubit>.value(
                value: cubit,
                child: SizedBox(
                  width: 400,
                  height: 500,
                  child: RecommendedGameCard(
                    game: _makeGame(id: 'g-loaded', isSaved: true),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        // Ban dau: filled.
        expect(find.byIcon(Icons.bookmark_rounded), findsOneWidget);

        // Tap unsave. Cubit toggle: cache.has(id)=true → newSavedState=false
        // → _optimisticUpdate emit Loaded(savedIds={}) → button flip.
        await tester.tap(find.byIcon(Icons.bookmark_rounded));
        // Pump rieng (khong pumpAndSettle) de tranh pending timer tu
        // toast animation (delightful_toast + flutter_animate).
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 400));

        // Sau tap: outline.
        expect(find.byIcon(Icons.bookmark_border_rounded), findsOneWidget);
        expect(find.byIcon(Icons.bookmark_rounded), findsNothing);

        await cubit.close();
      },
    );
  });
}