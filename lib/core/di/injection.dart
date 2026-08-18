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
import '../../features/profile/data/services/profile_cache_service.dart';
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
import '../../features/lobby_management/data/realtime/mock_lobby_realtime_service.dart';
import '../../features/lobby_management/domain/repositories/lobby_repository.dart';
import '../../features/lobby_management/presentation/cubit/lobby_cubit.dart';
import '../../features/lobby_management/presentation/cubit/lobby_reservation_cubit.dart';
import '../../features/friend_management/data/datasources/base/friend_remote_datasource.dart';
import '../../features/friend_management/data/datasources/remote/real_friend_remote_datasource.dart';
import '../../features/friend_management/data/friend_repository_impl.dart';
import '../../features/friend_management/domain/repositories/friend_repository.dart';
import '../../features/friend_management/presentation/cubit/friend_list_cubit.dart';
import '../../features/friend_management/presentation/cubit/friend_profile_cubit.dart';
import '../../features/lobby_management/presentation/cubit/lobby_search_cubit.dart';
import '../../features/lobby_management/presentation/cubit/lobby_invite_cubit.dart';
import '../../features/lobby_management/presentation/cubit/my_lobbies_cubit.dart';
import '../../features/notification/data/datasources/base/notification_remote_datasource.dart';
import '../../features/notification/data/datasources/remote/notification_remote_datasource.dart';
import '../../features/notification/data/notification_repository_impl.dart';
import '../../features/notification/data/realtime/fcm_service.dart';
import '../../features/notification/domain/repositories/notification_repository.dart';
import '../../features/in_game_experience/data/in_game_repository_impl.dart';
import '../../features/in_game_experience/domain/repositories/in_game_repository.dart';
import '../../features/in_game_experience/presentation/cubit/in_game_cubit.dart';
import '../../features/match_summary_rating/data/rating_repository_impl.dart';
import '../../features/match_summary_rating/domain/repositories/rating_repository.dart';
import '../../features/match_summary_rating/presentation/cubit/rating_cubit.dart';
import '../../features/leaderboard/data/datasources/leaderboard_remote_datasource.dart';
import '../../features/leaderboard/data/leaderboard_repository_impl.dart';
import '../../features/leaderboard/domain/repositories/leaderboard_repository.dart';
import '../../features/leaderboard/presentation/cubit/leaderboard_cubit.dart';
import '../../features/tournament/data/datasources/base/tournament_remote_datasource.dart';
import '../../features/tournament/data/datasources/tournament_remote_datasource_impl.dart';
import '../../features/tournament/data/tournament_repository_impl.dart';
import '../../features/tournament/domain/repositories/tournament_repository.dart';
import '../../features/tournament/presentation/cubit/tournament_list_cubit.dart';
import '../../features/tournament/presentation/cubit/tournament_detail_cubit.dart';
import '../../features/tournament/presentation/cubit/my_registrations_cubit.dart';
import '../../features/tournament/presentation/cubit/elo_history_cubit.dart';
import '../../features/tournament/presentation/cubit/tournament_engagement_cubit.dart';
import '../../features/settings/presentation/cubit/theme_cubit.dart';
import '../../features/wallet/data/datasources/wallet_remote_datasource.dart';
import '../../features/wallet/data/wallet_repository_impl.dart';
import '../../features/wallet/domain/repositories/wallet_repository.dart';
import '../../features/wallet/presentation/cubit/wallet_cubit.dart';
import '../../features/wallet/presentation/cubit/topup_cubit.dart';
import '../../features/player_check_in/data/datasources/player_check_in_remote_datasource.dart';
import '../../features/player_check_in/data/player_check_in_repository_impl.dart';
import '../../features/player_check_in/domain/repositories/player_check_in_repository.dart';
import '../../features/player_check_in/presentation/cubit/player_check_in_cubit.dart';
import '../../features/reservation/data/datasources/reservation_remote_datasource.dart';
import '../../features/reservation/data/reservation_repository_impl.dart';
import '../../features/reservation/domain/repositories/reservation_repository.dart';
import '../../features/reservation/presentation/cubit/reservation_cubit.dart';
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

  sl.registerLazySingleton<ProfileCacheService>(
    () => ProfileCacheService(),
  );

  sl.registerLazySingleton<ProfileRepository>(
    () =>
        ProfileRepositoryImpl(remoteDatasource: sl<ProfileRemoteDatasource>()),
  );

  // Factory: new Cubit instance every time it is requested.
  sl.registerFactory<ProfileCubit>(
    () => ProfileCubit(
      repository: sl<ProfileRepository>(),
      cache: sl<ProfileCacheService>(),
    ),
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
    () => MockLobbyRealtimeService(),
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
  // Đồng thời fetch cafe details từ /cafes/{id}.
  sl.registerFactory<MyLobbiesCubit>(
    () => MyLobbiesCubit(
      repository: sl<LobbyRepository>(),
      matchmakingRepository: sl<MatchmakingRepository>(),
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

  // Tournament Engagement (T-03 Waitlist + T-04 Spectator) — lifetime
  // gắn liền với [TournamentDetailPage], tạo mới mỗi lần mở detail.
  sl.registerFactory<TournamentEngagementCubit>(
    () => TournamentEngagementCubit(repository: sl<TournamentRepository>()),
  );

  // ─── Feature: Leaderboard (Global — BR §K-06) ──────────────────────────
  // Dùng chung cho Tournament tab + Profile/Home "Xếp hạng".
  sl.registerLazySingleton<LeaderboardRemoteDatasource>(
    () => LeaderboardRemoteDatasourceImpl(dio: sl<Dio>()),
  );

  sl.registerLazySingleton<LeaderboardRepository>(
    () => LeaderboardRepositoryImpl(remote: sl<LeaderboardRemoteDatasource>()),
  );

  // Factory — mỗi page mount tạo cubit mới để tránh cache entries qua các
  // màn khác nhau. Tournament page cũng dùng lại cubit này.
  sl.registerFactory<LeaderboardCubit>(
    () => LeaderboardCubit(repository: sl<LeaderboardRepository>()),
  );

  // ─── Theme preferences ────────────────────────────────────────────────
  sl.registerLazySingleton<ThemePreferencesService>(
    () => ThemePreferencesService(storage: sl<FlutterSecureStorage>()),
  );

  sl.registerLazySingleton<ThemeCubit>(
    () => ThemeCubit(preferences: sl<ThemePreferencesService>()),
  );

  // ─── Feature: Wallet (BVC) ────────────────────────────────────────────
  // Backend API: /api/v1/wallet/* (BR §2, §3)
  sl.registerLazySingleton<WalletRemoteDatasource>(
    () => WalletRemoteDatasourceImpl(dio: sl<Dio>()),
  );

  sl.registerLazySingleton<WalletRepository>(
    () => WalletRepositoryImpl(remoteDatasource: sl<WalletRemoteDatasource>()),
  );

  // Factory cubit: new instance every time it is requested.
  //
  // Registered as Factory (not LazySingleton) so that logout → fresh
  // login always yields a clean wallet cubit with no cached state
  // from the previous user. Any caller (e.g. WalletPage) can still
  // resolve it via GetIt.I<WalletCubit>() and the BlocProvider will
  // create the instance.
  sl.registerFactory<WalletCubit>(
    () => WalletCubit(repository: sl<WalletRepository>()),
  );

  // Factory cubit for top-up flow (creates new instance each time)
  sl.registerFactory<TopUpCubit>(
    () => TopUpCubit(repository: sl<WalletRepository>()),
  );

  // ─── Feature: Reservation (BVC atomic transaction) ──────────────────────
  // Backend API: /api/v1/reservations/* (BR §6)
  sl.registerLazySingleton<ReservationRemoteDatasource>(
    () => ReservationRemoteDatasourceImpl(dio: sl<Dio>()),
  );

  sl.registerLazySingleton<ReservationRepository>(
    () => ReservationRepositoryImpl(remoteDatasource: sl<ReservationRemoteDatasource>()),
  );

  // Factory cubit for reservation flow (creates new instance each time).
  // Cubit cần cả `WalletRepository` để `refreshBalanceAndConfirm` có thể
  // gọi `getWallet(includeHeld:true)` trước khi re-quote.
  sl.registerFactory<ReservationCubit>(
    () => ReservationCubit(
      repository: sl<ReservationRepository>(),
      walletRepository: sl<WalletRepository>(),
    ),
  );

  /// Factory cubit load + poll reservation detail cho LobbyPage.
  /// Mỗi LobbyPage mount sẽ tạo 1 instance mới; tự dispose khi page pop.
  sl.registerFactory<LobbyReservationCubit>(
    () => LobbyReservationCubit(repository: sl<ReservationRepository>()),
  );

  // ─── Feature: Player Check-In (BR §21A.7) ──────────────────────────────
  // Player self check-in via POS QR token (chiều 2 của check-in 2 chiều).
  // Backend: /api/check-in/scan-qr — chỉ register khi backend live;
  // các device that chưa cấu hình endpoint vẫn boot được app bình thường.
  sl.registerLazySingleton<PlayerCheckInRemoteDatasource>(
    () => PlayerCheckInRemoteDatasourceImpl(dio: sl<Dio>()),
  );
  sl.registerLazySingleton<PlayerCheckInRepository>(
    () => PlayerCheckInRepositoryImpl(remote: sl<PlayerCheckInRemoteDatasource>()),
  );
  // Factory — mỗi page mount (PlayerCheckInPage) sẽ có cubit riêng.
  sl.registerFactory<PlayerCheckInCubit>(
    () => PlayerCheckInCubit(repository: sl<PlayerCheckInRepository>()),
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
