import '../../domain/entities/lobby_share_info.dart';

/// Model cho API response của share info.
///
/// Backend: GET /api/v1/lobbies/{lobbyId}/share-info
/// Response: { data: { lobbyId, shareCode, isPrivate, lobbyStatus } }
class LobbyShareInfoModel {
  final String lobbyId;
  final String shareCode;
  final bool isPrivate;
  final String lobbyStatus;

  const LobbyShareInfoModel({
    required this.lobbyId,
    required this.shareCode,
    required this.isPrivate,
    required this.lobbyStatus,
  });

  factory LobbyShareInfoModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return LobbyShareInfoModel(
      lobbyId: (data['lobbyId'] ?? data['id'] ?? '').toString(),
      shareCode: (data['shareCode'] ?? '').toString(),
      isPrivate: data['isPrivate'] as bool? ?? false,
      lobbyStatus: (data['lobbyStatus'] ?? data['status'] ?? 'open').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'lobbyId': lobbyId,
    'shareCode': shareCode,
    'isPrivate': isPrivate,
    'lobbyStatus': lobbyStatus,
  };

  LobbyShareInfo toEntity() => LobbyShareInfo(
    lobbyId: lobbyId,
    shareCode: shareCode,
    isPrivate: isPrivate,
    lobbyStatus: lobbyStatus,
  );
}
