import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/deeplink/deep_link_handler.dart';
import 'core/di/injection.dart';
import 'core/navigation/pages/main_scaffold.dart';
import 'core/theme/theme.dart';
import 'core/widgets/game_loading_screen.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/auth/presentation/cubit/auth_state.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/lobby_management/lobby_routes.dart';
import 'features/lobby_management/presentation/cubit/lobby_cubit.dart';
import 'features/lobby_management/presentation/cubit/lobby_search_cubit.dart';
import 'features/lobby_management/presentation/cubit/my_lobbies_cubit.dart';
import 'features/discovery/presentation/cubit/saved_games_cubit.dart';
import 'features/in_game_experience/presentation/pages/in_game_session_page.dart';
import 'features/matchmaking_discovery/presentation/cubit/matchmaking_cubit.dart';
import 'features/profile/presentation/cubit/profile_cubit.dart';
import 'features/settings/presentation/cubit/theme_cubit.dart';
import 'features/tournament/presentation/cubit/tournament_list_cubit.dart';

/// Global navigator key — dùng cho deep-link handler navigate từ
/// ngoài widget tree.
final GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  // Khởi tạo SharedPreferences trước khi setupDependencies() — SavedGamesCache
  // cần instance này để register. Phải gọi trước setupDependencies vì
  // injection.dart dùng `sl<SharedPreferences>()`.
  final prefs = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(prefs);

  setupDependencies();

  // Khởi tạo locale data cho `intl.DateFormat` — tránh LocaleDataException
  // khi widget dùng `DateFormat(..., 'vi')` (vd: `ScheduledTimeCountdown`).
  // Cần gọi trước khi `runApp`.
  await initializeDateFormatting('vi');
  await initializeDateFormatting('en_US');

  await DeepLinkHandler.instance.initialize(
    navigatorKey: rootNavigatorKey,
    onBookingsRefresh: _noop,
  );

  runApp(const BoardVerseApp());
}

void _noop() {}

class BoardVerseApp extends StatelessWidget {
  const BoardVerseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(
          create: (_) => sl<AuthCubit>()..checkAuthStatus(),
        ),
        BlocProvider<ProfileCubit>(create: (_) => sl<ProfileCubit>()),
        BlocProvider<MatchmakingCubit>(create: (_) => sl<MatchmakingCubit>()),
        BlocProvider<LobbyCubit>(create: (_) => sl<LobbyCubit>()),
        BlocProvider<LobbySearchCubit>(create: (_) => sl<LobbySearchCubit>()),
        BlocProvider<MyLobbiesCubit>(create: (_) => sl<MyLobbiesCubit>()),
        BlocProvider<TournamentListCubit>(
          create: (_) => sl<TournamentListCubit>(),
        ),
        BlocProvider<ThemeCubit>(create: (_) => sl<ThemeCubit>()..load()),
        // SavedGamesCubit phải ở root (không phải trong MainScaffold) để
        // các route push qua Navigator (vd: BoardGameDetailPage, CafeDetailPage)
        // có thể `context.read<SavedGamesCubit>()` thành công — Navigator
        // root nằm ngoài widget tree của MainScaffold nên các cubit
        // chỉ được provide trong MainScaffold sẽ không visible cho route
        // pushed. Khi đó `toggleSave` throw ProviderNotFoundException → UI
        // catch hiển thị "Không thể lưu game. Vui lòng thử lại sau." dù
        // chưa có API call nào.
        //
        // LazySingleton trong `getIt` → chỉ tạo 1 instance duy nhất,
        // không tốn thêm chi phí. `loadSavedGames()` được trigger từ
        // MainScaffold.initState() (sau khi user đã auth) để tránh
        // gọi API với user chưa đăng nhập.
        BlocProvider<SavedGamesCubit>.value(value: sl<SavedGamesCubit>()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, themeState) {
          return MaterialApp(
            title: 'BoardVerse',
            debugShowCheckedModeBanner: false,
            navigatorKey: rootNavigatorKey,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeState.mode,
            home: const AuthWrapper(),
            initialRoute: '/',
            onGenerateRoute: (settings) {
              // Try lobby routes first
              final lobbyRoute = lobbyRouteGenerator(settings);
              if (lobbyRoute != null) return lobbyRoute;

              // Fall back to named routes
              switch (settings.name) {
                case '/login':
                  return MaterialPageRoute(builder: (_) => const LoginPage());
                case '/home':
                  return MaterialPageRoute(
                    builder: (_) => const MainScaffold(),
                  );
                case LobbyRoutes.inGameSession:
                  final args = settings.arguments as InGameSessionPageArgs;
                  return MaterialPageRoute(
                    builder: (_) => InGameSessionPage(
                      bookingId: args.bookingId,
                      cafeName: args.cafeName,
                      gameName: args.gameName,
                      tableNumber: args.tableNumber,
                      skipCheckIn: args.skipCheckIn,
                    ),
                  );
                default:
                  return MaterialPageRoute(
                    builder: (_) => const MainScaffold(),
                  );
              }
            },
            onUnknownRoute: (settings) {
              return MaterialPageRoute(builder: (_) => const MainScaffold());
            },
          );
        },
      ),
    );
  }
}

/// Wrapper widget that handles initial auth state check and displays
/// the appropriate screen (Login or MainScaffold) based on auth status.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state is AuthLoading) {
          return const GameLoadingScreen();
        }

        if (state is AuthSuccess) {
          return const MainScaffold();
        }

        return const LoginPage();
      },
    );
  }
}
