import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

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
import '../../features/lobby_management/data/datasources/base/lobby_remote_datasource.dart';
import '../../features/lobby_management/data/datasources/remote/real_lobby_remote_datasource.dart';
import '../../features/lobby_management/data/lobby_persistence_service.dart';
import '../../features/lobby_management/data/lobby_repository_impl.dart';
import '../../features/lobby_management/data/realtime/lobby_realtime_service.dart';
import '../../features/lobby_management/data/realtime/real_lobby_realtime_service.dart';
import '../../features/lobby_management/domain/repositories/lobby_repository.dart';
import '../../features/lobby_management/presentation/cubit/lobby_cubit.dart';
import '../../features/friend_management/data/datasources/base/friend_remote_datasource.dart';
import '../../features/friend_management/data/datasources/remote/real_friend_remote_datasource.dart';
import '../../features/friend_management/data/friend_repository_impl.dart';
import '../../features/friend_management/domain/repositories/friend_repository.dart';
import '../../features/friend_management/presentation/cubit/friend_list_cubit.dart';
import '../../features/friend_management/presentation/cubit/friend_profile_cubit.dart';
import '../../features/match/data/datasources/base/match_result_remote_datasource.dart';
import '../../features/match/data/datasources/remote/real_match_result_remote_datasource.dart';
import '../../features/match/data/match_result_repository_impl.dart';
import '../../features/match/domain/repositories/match_result_repository.dart';
import '../../features/match/presentation/cubit/match_result_cubit.dart';
import '../../features/lobby_management/presentation/cubit/lobby_search_cubit.dart';
import '../../features/lobby_management/presentation/cubit/lobby_invite_cubit.dart';
import '../../features/lobby_management/presentation/cubit/my_lobbies_cubit.dart';
import '../../features/booking_payment/data/booking_persistence_service.dart';
import '../../features/booking_payment/data/booking_repository_impl.dart';
import '../../features/booking_payment/data/datasources/base/booking_rating_remote_datasource.dart';
import '../../features/booking_payment/data/datasources/base/booking_remote_datasource.dart';
import '../../features/booking_payment/data/datasources/base/bookings_by_cafe_remote_datasource.dart';
import '../../features/booking_payment/data/datasources/base/cafe_availability_remote_datasource.dart';
import '../../features/booking_payment/data/datasources/base/cafe_table_remote_datasource.dart';
import '../../features/booking_payment/data/datasources/base/payment_gateway.dart';
import '../../features/booking_payment/data/datasources/base/session_status_remote_datasource.dart';
import '../../features/booking_payment/data/datasources/gateway/sepay_payment_gateway.dart';
import '../../features/booking_payment/data/datasources/remote/booking_rating_remote_datasource.dart';
import '../../features/booking_payment/data/datasources/remote/booking_remote_datasource_impl.dart';
import '../../features/booking_payment/data/datasources/remote/bookings_by_cafe_remote_datasource.dart';
import '../../features/booking_payment/data/datasources/remote/cafe_availability_remote_datasource.dart';
import '../../features/booking_payment/data/datasources/remote/cafe_table_remote_datasource.dart';
import '../../features/booking_payment/data/datasources/remote/payment_remote_datasource.dart';
import '../../features/booking_payment/data/datasources/remote/session_status_remote_datasource.dart';
import '../../features/booking_payment/data/realtime/booking_realtime_service.dart';
import '../../features/booking_payment/domain/repositories/booking_repository.dart';
import '../../features/booking_payment/presentation/cubit/booking_detail_actions_cubit.dart';
import '../../features/booking_payment/presentation/cubit/booking_history_cubit.dart';
import '../../features/booking_payment/presentation/cubit/booking_realtime_cubit.dart';
import '../../features/booking_payment/presentation/cubit/booking_result_cubit.dart';
import '../../features/booking_payment/presentation/cubit/booking_summary_cubit.dart';
import '../../features/booking_payment/presentation/cubit/payment_cubit.dart';
import '../../features/notification/data/datasources/base/notification_remote_datasource.dart';
import '../../features/notification/data/datasources/remote/notification_remote_datasource.dart';
import '../../features/notification/data/notification_repository_impl.dart';
import '../../features/notification/data/realtime/fcm_service.dart';
import '../../features/notification/domain/repositories/notification_repository.dart';
import '../../core/navigation/widgets/booking_pending_resume_helper.dart';
import '../../features/in_game_experience/data/in_game_repository_impl.dart';
import '../../features/in_game_experience/domain/repositories/in_game_repository.dart';
import '../../features/in_game_experience/presentation/cubit/in_game_cubit.dart';
import '../../features/match_summary_rating/data/rating_repository_impl.dart';
import '../../features/match_summary_rating/domain/repositories/rating_repository.dart';
import '../../features/match_summary_rating/presentation/cubit/rating_cubit.dart';
import '../../features/tournament/data/datasources/base/tournament_remote_datasource.dart';
import '../../features/tournament/data/datasources/tournament_remote_datasource_impl.dart';
import '../../features/tournament/data/tournament_repository_impl.dart';
import '../../features/tournament/domain/repositories/tournament_repository.dart';
import '../../features/tournament/presentation/cubit/tournament_list_cubit.dart';
import '../../features/tournament/presentation/cubit/tournament_detail_cubit.dart';
import '../../features/tournament/presentation/cubit/my_registrations_cubit.dart';
import '../../features/tournament/presentation/cubit/elo_history_cubit.dart';
import '../../features/settings/presentation/cubit/theme_cubit.dart';
import '../services/storage/theme_preferences_service.dart';
import '../utils/current_user_resolver.dart';

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
  sl.registerLazySingleton<LobbyRemoteDatasource>(
    () => RealLobbyRemoteDatasource(dio: sl<Dio>()),
  );

  sl.registerLazySingleton<LobbyRealtimeService>(
    () => RealLobbyRealtimeService(storage: sl<FlutterSecureStorage>()),
  );

  sl.registerLazySingleton<LobbyRepository>(
    () => LobbyRepositoryImpl(
      remoteDatasource: sl<LobbyRemoteDatasource>(),
      realtimeService: sl<LobbyRealtimeService>(),
    ),
  );

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
    () => LobbySearchCubit(
      repository: sl<LobbyRepository>(),
      realtime: sl<LobbyRealtimeService>(),
    ),
  );

  // MyLobbiesCubit — section "Phòng chờ của tôi" trong Discovery → tab
  // "Phòng chờ". Sử dụng real API endpoints /hosted và /joined.
  sl.registerFactory<MyLobbiesCubit>(
    () => MyLobbiesCubit(
      repository: sl<LobbyRepository>(),
    ),
  );

  sl.registerFactory<LobbyInviteCubit>(
    () => LobbyInviteCubit(remoteDatasource: sl<LobbyRemoteDatasource>()),
  );

  // ─── Feature: Friend Management ─────────────────────────────────────
  sl.registerLazySingleton<FriendRemoteDatasource>(
    () => RealFriendRemoteDatasource(dio: sl<Dio>()),
  );

  sl.registerLazySingleton<FriendRepository>(
    () => FriendRepositoryImpl(datasource: sl<FriendRemoteDatasource>()),
  );

  sl.registerFactory<FriendListCubit>(
    () => FriendListCubit(repository: sl<FriendRepository>()),
  );

  sl.registerFactory<FriendProfileCubit>(
    () => FriendProfileCubit(repository: sl<FriendRepository>()),
  );

  // ─── Feature: Match (Elo consensus) ─────────────────────────────────
  sl.registerLazySingleton<MatchResultRemoteDatasource>(
    () => RealMatchResultRemoteDatasource(dio: sl<Dio>()),
  );

  sl.registerLazySingleton<MatchResultRepository>(
    () => MatchResultRepositoryImpl(remote: sl<MatchResultRemoteDatasource>()),
  );

  sl.registerFactory<MatchResultCubit>(
    () => MatchResultCubit(repository: sl<MatchResultRepository>()),
  );

  // ─── Feature: Booking & Payment ─────────────────────────────────────
  // Backend API thật — không còn mock. Xem `.agents/docs/apis_docs/booking.md`
  // + `payment.md`. SePay gateway mở URL qua `url_launcher` + polling.
  sl.registerLazySingleton<BookingRemoteDatasource>(
    () => BookingRemoteDatasourceImpl(dio: sl<Dio>()),
  );

  sl.registerLazySingleton<CafeTableRemoteDatasource>(
    () => CafeTableRemoteDatasourceImpl(dio: sl<Dio>()),
  );

  // Gap #2 — Cafe availability (capacity + alternative slots).
  sl.registerLazySingleton<CafeAvailabilityRemoteDatasource>(
    () => CafeAvailabilityRemoteDatasourceImpl(dio: sl<Dio>()),
  );

  // Gap #4 + #5 — Booking rating (NoShow vote + cross-rating).
  sl.registerLazySingleton<BookingRatingRemoteDatasource>(
    () => BookingRatingRemoteDatasourceImpl(dio: sl<Dio>()),
  );

  // Gap #8 — Session status realtime.
  sl.registerLazySingleton<SessionStatusRemoteDatasource>(
    () => SessionStatusRemoteDatasourceImpl(dio: sl<Dio>()),
  );

  // Gap #14 — Cafe view cho Player.
  sl.registerLazySingleton<BookingsByCafeRemoteDatasource>(
    () => BookingsByCafeRemoteDatasourceImpl(dio: sl<Dio>()),
  );

  sl.registerLazySingleton<PaymentRemoteDatasource>(
    () => PaymentRemoteDatasource(dio: sl<Dio>()),
  );

  sl.registerLazySingleton<PaymentGateway>(
    () => SepayPaymentGateway(paymentRemote: sl<PaymentRemoteDatasource>()),
  );

  sl.registerLazySingleton<BookingPersistenceService>(
    () => BookingPersistenceService(storage: sl<FlutterSecureStorage>()),
  );

  sl.registerLazySingleton<BookingRepository>(
    () => BookingRepositoryImpl(
      datasource: sl<BookingRemoteDatasource>(),
      cafeTableDatasource: sl<CafeTableRemoteDatasource>(),
      cafeAvailabilityDatasource: sl<CafeAvailabilityRemoteDatasource>(),
      bookingRatingDatasource: sl<BookingRatingRemoteDatasource>(),
      sessionStatusDatasource: sl<SessionStatusRemoteDatasource>(),
      bookingsByCafeDatasource: sl<BookingsByCafeRemoteDatasource>(),
      persistence: sl<BookingPersistenceService>(),
    ),
  );

  // ─── Feature: Notification (FCM device tokens) ────────────────────
  // Gap #11 + lobby auto-cancel push (background events).
  sl.registerLazySingleton<NotificationRemoteDatasource>(
    () => NotificationRemoteDatasourceImpl(dio: sl<Dio>()),
  );
  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(datasource: sl<NotificationRemoteDatasource>()),
  );

  // FCM service — stub NullFcmService cho đến khi firebase deps được add.
  // Production impl cần register `FirebaseMessagingService` thay thế sau khi
  // thêm `firebase_core` + `firebase_messaging` vào pubspec.yaml.
  sl.registerLazySingleton<FcmService>(
    () => NullFcmService(),
  );

  // Booking realtime service — SignalR.
  sl.registerLazySingleton<BookingRealtimeService>(
    () => BookingRealtimeService(accessToken: ''),
  );

  // Helper gọn cho banner resume trên tab Bookings — gói gọn
  // getPendingBookingId + clearPending + fetchBooking.
  sl.registerLazySingleton<BookingPersistenceResumeHelper>(
    () => BookingPersistenceResumeHelper(sl<BookingRepository>()),
  );

  // Factory Cubits — dùng cho BookingSummaryPage / PaymentPage / Success.
  sl.registerFactory<BookingSummaryCubit>(
    () => BookingSummaryCubit(repository: sl<BookingRepository>()),
  );
  sl.registerFactory<PaymentCubit>(
    () => PaymentCubit(
      repository: sl<BookingRepository>(),
      gateway: sl<PaymentGateway>(),
      persistence: sl<BookingPersistenceService>(),
    ),
  );
  sl.registerFactory<BookingResultCubit>(
    () => BookingResultCubit(repository: sl<BookingRepository>()),
  );
  sl.registerFactory<BookingDetailActionsCubit>(
    () => BookingDetailActionsCubit(repository: sl<BookingRepository>()),
  );
  sl.registerFactory<BookingRealtimeCubit>(
    () => BookingRealtimeCubit(
      signalR: sl<BookingRealtimeService>(),
      fcm: sl<FcmService>(),
      repository: sl<BookingRepository>(),
    ),
  );
  sl.registerLazySingleton<BookingHistoryCubit>(
    () => BookingHistoryCubit(repository: sl<BookingRepository>()),
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

  // ─── Feature: Tournament ────────────────────────────────────────────────
  // Tournament uses real API - backend endpoints are implemented
  sl.registerLazySingleton<TournamentRemoteDatasource>(
    () => TournamentRemoteDatasourceImpl(dio: sl<Dio>()),
  );

  sl.registerLazySingleton<TournamentRepository>(
    () => TournamentRepositoryImpl(remoteDatasource: sl<TournamentRemoteDatasource>()),
  );

  // Lazy singletons — dùng cho các cubit có vòng đời dài (vd Tournament
  // tab nằm trong PageView nên phải giữ state qua các lần rebuild).
  // Nếu để `registerFactory`, mỗi lần parent rebuild sẽ tạo instance
  // mới → loop vô tận với các API async.
  sl.registerLazySingleton<TournamentListCubit>(
    () => TournamentListCubit(repository: sl<TournamentRepository>()),
  );

  // Factory — các cubit có vòng đời ngắn, mở là tạo mới.
  sl.registerFactory<TournamentDetailCubit>(
    () => TournamentDetailCubit(repository: sl<TournamentRepository>()),
  );

  sl.registerFactory<MyRegistrationsCubit>(
    () => MyRegistrationsCubit(repository: sl<TournamentRepository>()),
  );

  sl.registerFactory<EloHistoryCubit>(
    () => EloHistoryCubit(repository: sl<TournamentRepository>()),
  );

  // ─── Theme preferences ────────────────────────────────────────────────
  sl.registerLazySingleton<ThemePreferencesService>(
    () => ThemePreferencesService(storage: sl<FlutterSecureStorage>()),
  );

  sl.registerLazySingleton<ThemeCubit>(
    () => ThemeCubit(preferences: sl<ThemePreferencesService>()),
  );

  // ─── Current user (JWT-based, used to identify "me" in lists) ────────
  sl.registerLazySingleton<CurrentUserResolver>(
    () => CurrentUserResolver(sl<FlutterSecureStorage>()),
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
