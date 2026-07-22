import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:boardverse_mobile/core/di/injection.dart';
import 'presentation/cubit/lobby_invite_cubit.dart';
import 'presentation/cubit/match_result_cubit.dart';
import 'presentation/pages/join_by_code_page.dart';
import 'presentation/pages/lobby_invites_page.dart';
import 'presentation/pages/match_result_page.dart';
import 'data/datasources/base/lobby_remote_datasource.dart';

/// Route names for lobby-related pages.
class LobbyRoutes {
  static const String lobbyInvites = '/lobby/invites';
  static const String joinByCode = '/lobby/join-by-code';
  static const String matchResult = '/lobby/match-result';

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
              // Navigate to lobby - caller should handle navigation
            },
          ),
        ),
      );

    case LobbyRoutes.joinByCode:
      // final args = settings.arguments as Map<String, dynamic>?;
      // final shareCode = args?['shareCode'] as String?; // To be used for pre-filling code
      return MaterialPageRoute(
        builder: (_) => JoinByCodePage(
          remoteDatasource: getIt<LobbyRemoteDatasource>(),
          onJoined: (lobby) {
            // Navigate to lobby - caller should handle navigation
          },
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
