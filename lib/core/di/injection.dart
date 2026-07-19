import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import '../config/app_config.dart';
import '../network/auth_interceptor.dart';
import '../network/dio_client.dart';
import '../services/cloudinary/cloudinary_config.dart';
import '../services/cloudinary/cloudinary_service.dart';
import '../../features/auth/data/auth_repository_impl.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/profile/data/datasources/profile_remote_datasource.dart';
import '../../features/profile/data/profile_repository_impl.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/presentation/cubit/profile_cubit.dart';
import '../../features/matchmaking_discovery/data/matchmaking_repository_impl.dart';
import '../../features/matchmaking_discovery/data/datasources/base/matchmaking_datasource.dart';
import '../../features/matchmaking_discovery/data/datasources/remote/matchmaking_remote_datasource_impl.dart';
import '../../features/matchmaking_discovery/domain/repositories/matchmaking_repository.dart';
import '../../features/matchmaking_discovery/presentation/cubit/matchmaking_cubit.dart';
import '../../features/lobby_management/data/lobby_repository_impl.dart';
import '../../features/lobby_management/data/lobby_persistence_service.dart';
import '../../features/lobby_management/domain/repositories/lobby_repository.dart';
import '../../features/lobby_management/presentation/cubit/lobby_cubit.dart';
import '../../features/lobby_management/presentation/cubit/lobby_search_cubit.dart';
import '../../features/booking_payment/data/booking_persistence_service.dart';
import '../../features/booking_payment/data/booking_repository_impl.dart';
import '../../features/booking_payment/data/datasources/base/booking_remote_datasource.dart';
import '../../features/booking_payment/data/datasources/base/payment_gateway.dart';
import '../../features/booking_payment/data/datasources/mock/mock_booking_remote_datasource.dart';
import '../../features/booking_payment/data/datasources/mock/mock_payment_gateway.dart';
import '../../features/booking_payment/data/datasources/remote/booking_remote_datasource_impl.dart';
import '../../features/booking_payment/domain/repositories/booking_repository.dart';
import '../../features/booking_payment/presentation/cubit/booking_result_cubit.dart';
import '../../features/booking_payment/presentation/cubit/booking_summary_cubit.dart';
import '../../features/booking_payment/presentation/cubit/payment_cubit.dart';
import '../../features/in_game_experience/data/in_game_repository_impl.dart';
import '../../features/in_game_experience/domain/repositories/in_game_repository.dart';
import '../../features/in_game_experience/presentation/cubit/in_game_cubit.dart';
import '../../features/match_summary_rating/data/rating_repository_impl.dart';
import '../../features/match_summary_rating/domain/repositories/rating_repository.dart';
import '../../features/match_summary_rating/presentation/cubit/rating_cubit.dart';
import '../../features/settings/presentation/cubit/theme_cubit.dart';
import '../services/storage/theme_preferences_service.dart';

/// Global service locator instance.
final sl = GetIt.instance;

/// Alias for sl to allow pages to use getIt directly.
final getIt = sl;

/// Registers all dependencies.
///
/// Call this once at app startup **after** loading the `.env` file.
void setupDependencies() {
  // ─── External ──────────────────────────────────────────────────────
  sl.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );

  // ─── Core / Network ───────────────────────────────────────────────
  sl.registerLazySingleton<AuthInterceptor>(
    () => AuthInterceptor(storage: sl<FlutterSecureStorage>()),
  );

  sl.registerLazySingleton<DioClient>(
    () => DioClient(authInterceptor: sl<AuthInterceptor>()),
  );

  // Expose the raw Dio instance for convenience.
  sl.registerLazySingleton<Dio>(() => sl<DioClient>().dio);

  // ─── Feature: Auth ─────────────────────────────────────────────────
  sl.registerLazySingleton<AuthRemoteDatasource>(
    () => AuthRemoteDatasourceImpl(dio: sl<Dio>()),
  );

  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDatasource: sl<AuthRemoteDatasource>()),
  );

  // Factory: new Cubit instance every time it is requested.
  sl.registerFactory<AuthCubit>(
    () => AuthCubit(
      repository: sl<AuthRepository>(),
      storage: sl<FlutterSecureStorage>(),
    ),
  );

  // ─── Feature: Profile ──────────────────────────────────────────────
  sl.registerLazySingleton<ProfileRemoteDatasource>(
    () => ProfileRemoteDatasourceImpl(dio: sl<Dio>()),
  );

  sl.registerLazySingleton<ProfileRepository>(
    () =>
        ProfileRepositoryImpl(remoteDatasource: sl<ProfileRemoteDatasource>()),
  );

  // Factory: new Cubit instance every time it is requested.
  sl.registerFactory<ProfileCubit>(
    () => ProfileCubit(repository: sl<ProfileRepository>()),
  );

  // ─── Feature: Matchmaking Discovery ──────────────────────────────────
  // Always use real API — backend endpoints /api/v1/board-games, /api/cafes
  // are fully implemented and stable.
  sl.registerLazySingleton<MatchmakingDatasource>(
    () => MatchmakingRemoteDatasourceImpl(dio: sl<Dio>()),
  );

  sl.registerLazySingleton<MatchmakingRepository>(
    () => MatchmakingRepositoryImpl(datasource: sl<MatchmakingDatasource>()),
  );

  sl.registerFactory<MatchmakingCubit>(
    () => MatchmakingCubit(
      repository: sl<MatchmakingRepository>(),
      lobbyRepository: sl<LobbyRepository>(),
    ),
  );

  // ─── Feature: Lobby Management ────────────────────────────────────────
  sl.registerLazySingleton<LobbyRepository>(() => LobbyRepositoryImpl());

  sl.registerLazySingleton<LobbyPersistenceService>(
    () => LobbyPersistenceService(storage: sl<FlutterSecureStorage>()),
  );

  sl.registerFactory<LobbyCubit>(
    () => LobbyCubit(
      repository: sl<LobbyRepository>(),
      persistenceService: sl<LobbyPersistenceService>(),
    ),
  );

  sl.registerFactory<LobbySearchCubit>(
    () => LobbySearchCubit(repository: sl<LobbyRepository>()),
  );

  // ─── Feature: Booking & Payment ─────────────────────────────────────
  // Datasource: switch mock vs remote theo AppConfig.useMockData
  sl.registerLazySingleton<BookingRemoteDatasource>(
    () => AppConfig.useMockData
        ? MockBookingRemoteDatasource()
        : BookingRemoteDatasourceImpl(dio: sl<Dio>()),
  );

  // Mock-only: expose concrete singleton để `BookingDetailPage`
  // gọi `simulateQrScan` (chỉ tồn tại trên mock). Khi AppConfig chuyển sang
  // remote, registration sẽ throw — page phải kiểm tra trước khi gọi.
  sl.registerLazySingleton<MockBookingRemoteDatasource>(
    () {
      if (!AppConfig.useMockData) {
        throw StateError(
          'MockBookingRemoteDatasource chỉ khả dụng khi AppConfig.useMockData = true. '
          'Hiện tại: useMockData=false. Không thể resolve MockBookingRemoteDatasource.',
        );
      }
      // Tái sử dụng cùng instance đã được register cho interface.
      return sl<BookingRemoteDatasource>() as MockBookingRemoteDatasource;
    },
  );

  // Payment gateway: hiện tại chỉ có mock; placeholder cho VNPay/MoMo.
  sl.registerLazySingleton<PaymentGateway>(() => MockPaymentGateway());

  sl.registerLazySingleton<BookingPersistenceService>(
    () => BookingPersistenceService(storage: sl<FlutterSecureStorage>()),
  );

  sl.registerLazySingleton<BookingRepository>(
    () => BookingRepositoryImpl(
      datasource: sl<BookingRemoteDatasource>(),
      persistence: sl<BookingPersistenceService>(),
    ),
  );

  // Factory Cubits — dùng cho BookingSummaryPage / PaymentPage / Success.
  sl.registerFactory<BookingSummaryCubit>(
    () => BookingSummaryCubit(repository: sl<BookingRepository>()),
  );
  sl.registerFactory<PaymentCubit>(
    () => PaymentCubit(
      repository: sl<BookingRepository>(),
      gateway: sl<PaymentGateway>(),
    ),
  );
  sl.registerFactory<BookingResultCubit>(
    () => BookingResultCubit(repository: sl<BookingRepository>()),
  );

  // ─── Feature: In Game Experience ──────────────────────────────────────
  sl.registerLazySingleton<InGameRepository>(() => InGameRepositoryImpl());

  sl.registerFactory<InGameCubit>(
    () => InGameCubit(repository: sl<InGameRepository>()),
  );

  // ─── Feature: Match Summary Rating ────────────────────────────────────
  sl.registerLazySingleton<RatingRepository>(() => RatingRepositoryImpl());

  sl.registerFactory<RatingCubit>(
    () => RatingCubit(repository: sl<RatingRepository>()),
  );

  // ─── Theme preferences ────────────────────────────────────────────────
  sl.registerLazySingleton<ThemePreferencesService>(
    () => ThemePreferencesService(storage: sl<FlutterSecureStorage>()),
  );

  sl.registerLazySingleton<ThemeCubit>(
    () => ThemeCubit(preferences: sl<ThemePreferencesService>()),
  );

  // ─── Cloudinary (image upload + transformation) ────────────────────────
  // Only register when env is configured so the app still boots if the
  // operator hasn't filled in Cloudinary credentials yet. Features that
  // need upload should `if (sl.isRegistered<CloudinaryService>())` guard.
  if (CloudinaryConfig.isValid) {
    sl.registerLazySingleton<CloudinaryService>(
      () => CloudinaryService.fromEnv(),
    );
  }
}
