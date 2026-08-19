import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:boardverse/core/di/injection.dart';
import 'package:boardverse/core/navigation/lobby_join_signal.dart';
import 'package:boardverse/features/in_game_experience/presentation/cubit/in_game_cubit.dart';
import 'package:boardverse/features/in_game_experience/presentation/pages/in_game_session_page.dart';
import 'package:boardverse/features/player_check_in/presentation/pages/player_qr_check_in_page.dart';
import 'presentation/cubit/lobby_cubit.dart';
import 'presentation/cubit/lobby_invite_cubit.dart';
import 'presentation/cubit/match_result_cubit.dart';
import 'presentation/pages/join_by_code_page.dart';
import 'presentation/pages/lobby_invites_page.dart';
import 'presentation/pages/lobby_invites_sent_page.dart';
import 'presentation/pages/lobby_invites_history_page.dart';
import 'presentation/pages/lobby_page.dart';
import 'presentation/pages/match_result_page.dart';
import 'data/datasources/base/lobby_remote_datasource.dart';

/// Route names for lobby-related pages.
class LobbyRoutes {
  // Lobby invite / discovery helpers.
  static const String lobbyInvites = '/lobby/invites';
  static const String lobbyInvitesSent = '/lobby/invites-sent';
  static const String lobbyInvitesHistory = '/lobby/invites-history';
  static const String joinByCode = '/lobby/join-by-code';
  static const String matchResult = '/lobby/match-result';

  // Reservation / BVC lobby-creation flow.
  static const String lobbyCreateSetup = '/lobby/create-setup';
  static const String lobbyQuote = '/lobby/quote';
  static const String lobbyPendingCafeApproval =
      '/lobby/pending-cafe-approval';
  static const String lobbyPage = '/lobby/page';
  static const String inGameSession = '/lobby/in-game-session';

  /// Player tự check-in bằng cách nhập token QR do POS cung cấp
  /// (BR §21A.7 — chiều 2 của check-in 2 chiều).
  static const String playerQrCheckIn = '/lobby/player-qr-check-in';

  static const String shareCodeDeepLink = 'boardverse://lobby/join';
  static const String lobbyDeepLink = 'boardverse://lobby';
  static const String friendsDeepLink = 'boardverse://friends';
  static const String friendsRequestsDeepLink = 'boardverse://friends/requests';
}

/// Page arguments for lobby pages.
class MatchResultPageArgs {
  final String lobbyId;
  final String gameName;

  const MatchResultPageArgs({
    required this.lobbyId,
    required this.gameName,
  });
}

/// Page arguments for [LobbyPendingCafeApprovalPage].
class LobbyPendingCafeApprovalArgs {
  final String reservationId;
  final String? cafeId;
  final String? cafeName;
  final DateTime? cafeApprovalDeadline;

  const LobbyPendingCafeApprovalArgs({
    required this.reservationId,
    this.cafeId,
    this.cafeName,
    this.cafeApprovalDeadline,
  });
}

/// Page arguments for [LobbyPage] (post-creation / preview / joined lobby).
class LobbyPageArgs {
  final String lobbyId;
  const LobbyPageArgs({required this.lobbyId});
}

/// Page arguments cho [LobbyInvitesHistoryPage].
class LobbyInvitesHistoryPageArgs {
  final String lobbyId;
  final String? lobbyName;
  const LobbyInvitesHistoryPageArgs({
    required this.lobbyId,
    this.lobbyName,
  });
}

/// Page arguments cho [InGameSessionPage].
class InGameSessionPageArgs {
  final String bookingId;
  final String cafeName;
  final String gameName;
  final int tableNumber;

  /// Nếu true, InGameSessionPage bỏ qua checkIn trong initState.
  /// Dùng khi navigate từ LobbyCheckInSection (user đã được staff
  /// check-in rồi).
  final bool skipCheckIn;

  const InGameSessionPageArgs({
    required this.bookingId,
    required this.cafeName,
    required this.gameName,
    required this.tableNumber,
    this.skipCheckIn = true,
  });
}

/// Page arguments cho [PlayerQrCheckInPage] — chiều 2 check-in (BR §21A.7).
///
/// - [reservationId]: id của reservation player đang muốn check-in. Dùng để
///   navigate sang `InGameSessionPage` khi thành công (vì backend trả về
///   cùng reservationId trong response).
/// - [cafeName], [gameName], [tableNumber]: cần thiết để truyền vào
///   `InGameSessionPageArgs` sau khi check-in thành công.
class PlayerQrCheckInPageArgs {
  final String reservationId;
  final String cafeName;
  final String gameName;
  final int tableNumber;

  const PlayerQrCheckInPageArgs({
    required this.reservationId,
    required this.cafeName,
    required this.gameName,
    this.tableNumber = 1,
  });
}

/// Helper to build routes for lobby-related pages.
/// Call `setupLobbyRoutes()` in MaterialApp.onGenerateRoute.
Route<dynamic>? lobbyRouteGenerator(RouteSettings settings) {
  switch (settings.name) {
    case LobbyRoutes.lobbyInvites:
      return MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => getIt<LobbyInviteCubit>()..loadPendingInvites(),
          child: LobbyInvitesPage(
            lobbyInviteCubit: getIt<LobbyInviteCubit>(),
            onJoinLobby: (lobbyId) {
              // Phát signal để MainScaffold navigate đến LobbyPage.
              LobbyJoinSignal.instance.request(lobbyId);
            },
          ),
        ),
      );

    case LobbyRoutes.lobbyInvitesSent:
      return MaterialPageRoute(
        builder: (_) => const LobbyInvitesSentPage(),
      );

    case LobbyRoutes.lobbyInvitesHistory:
      final args =
          settings.arguments as LobbyInvitesHistoryPageArgs? ??
              const LobbyInvitesHistoryPageArgs(lobbyId: '');
      return MaterialPageRoute(
        builder: (_) => LobbyInvitesHistoryPage(
          lobbyId: args.lobbyId,
          lobbyName: args.lobbyName,
        ),
      );

    case LobbyRoutes.joinByCode:
      return MaterialPageRoute(
        builder: (_) => JoinByCodePage(
          remoteDatasource: getIt<LobbyRemoteDatasource>(),
          onJoined: (lobby) {
            // Phát signal để MainScaffold navigate tới LobbyPage — đảm
            // bảo pop hết stack trung gian và chỉ giữ MainScaffold + LobbyPage
            // (nhánh "Join bằng mã" → user đã là member của lobby).
            LobbyJoinSignal.instance.request(lobby.id);
          },
        ),
      );

    case LobbyRoutes.lobbyPage:
      // Route target của `LobbyJoinSignal.request(lobbyId)` được fire từ
      // `MainScaffold._handleLobbyJoin`. Arguments là `{'lobbyId': String}`
      // (set bởi signal consumer).
      //
      // Trước đây case này bị THIẾU → named-route lookup rơi xuống default
      // của `main.dart` → build một `MainScaffold()` mới → user thấy "bị
      // văng" về Lobby Hub. Fix: build `LobbyPage` thật, dùng `LobbyCubit`
      // từ DI và wrap trong `BlocProvider.value` (vì context push từ root
      // navigator không có provider cha).
      final args = settings.arguments;
      final lobbyId = args is Map
          ? (args['lobbyId'] as String?) ?? ''
          : '';
      if (lobbyId.isEmpty) {
        return MaterialPageRoute(
          builder: (_) => const _MissingLobbyIdScaffold(),
        );
      }
      final lobbyCubit = getIt<LobbyCubit>();
      return MaterialPageRoute(
        builder: (_) => BlocProvider<LobbyCubit>.value(
          value: lobbyCubit,
          child: LobbyPage(lobbyId: lobbyId, lobbyCubit: lobbyCubit),
        ),
      );

    case LobbyRoutes.matchResult:
      final args = settings.arguments as MatchResultPageArgs;
      final cubit = getIt<MatchResultCubit>();
      return MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: MatchResultPage(
            matchResultCubit: cubit,
            lobbyId: args.lobbyId,
            gameName: args.gameName,
          ),
        ),
      );

    case LobbyRoutes.inGameSession:
      final args = settings.arguments as InGameSessionPageArgs;
      // Wrap BlocProvider ở route level — đảm bảo cubit được tạo một
      // lần qua factory + auto-dispose khi route pop. Trước đây page tự
      // gọi `getIt<InGameCubit>()` trong initState → tạo cubit riêng,
      // KHÔNG match với BlocProvider cha (nếu có) → state không đồng bộ
      // → page trắng + `mouse_tracker.dart:199` assertion khi popup.
      return MaterialPageRoute(
        builder: (_) => BlocProvider<InGameCubit>(
          create: (_) => getIt<InGameCubit>(),
          child: InGameSessionPage(
            bookingId: args.bookingId,
            cafeName: args.cafeName,
            gameName: args.gameName,
            tableNumber: args.tableNumber,
            skipCheckIn: args.skipCheckIn,
          ),
        ),
      );

    case LobbyRoutes.playerQrCheckIn:
      final args = settings.arguments as PlayerQrCheckInPageArgs;
      return MaterialPageRoute(
        builder: (_) => PlayerQrCheckInPage(
          reservationId: args.reservationId,
          cafeName: args.cafeName,
          gameName: args.gameName,
          tableNumber: args.tableNumber,
        ),
      );

    default:
      return null;
  }
}

/// Parse share code from deep link URI.
/// Supports: `boardverse://lobby/join?code=K7H3NP9X`
String? parseShareCodeFromUri(Uri uri) {
  if (uri.scheme == 'boardverse' &&
      uri.host == 'lobby' &&
      uri.pathSegments.isNotEmpty &&
      uri.pathSegments.first == 'join') {
    return uri.queryParameters['code'];
  }
  return null;
}

/// Check if URI is a lobby deep link.
bool isLobbyDeepLink(Uri uri) {
  if (uri.scheme != 'boardverse') return false;
  return uri.host == 'lobby' || uri.host == 'friends';
}

/// Get deep link type from URI.
DeepLinkType getDeepLinkType(Uri uri) {
  if (uri.scheme != 'boardverse') return DeepLinkType.unknown;

  switch (uri.host) {
    case 'lobby':
      if (uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'join') {
        return DeepLinkType.joinByCode;
      }
      if (uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'invites') {
        return DeepLinkType.lobbyInvites;
      }
      return DeepLinkType.lobbyDetail;

    case 'friends':
      if (uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'requests') {
        return DeepLinkType.friendRequests;
      }
      return DeepLinkType.friends;

    default:
      return DeepLinkType.unknown;
  }
}

enum DeepLinkType {
  unknown,
  lobbyDetail,
  joinByCode,
  lobbyInvites,
  friends,
  friendRequests,
}

/// Scaffold fallback khi [LobbyRoutes.lobbyPage] được push mà thiếu
/// `lobbyId` trong arguments — lỗi hiếm nhưng an toàn để user không bị
/// crash vào màn hình đen. Nút "Quay lại" pop về MainScaffold.
class _MissingLobbyIdScaffold extends StatelessWidget {
  const _MissingLobbyIdScaffold();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lỗi'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Không tìm thấy mã lobby. Vui lòng thử lại.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
