import '../../domain/entities/lobby_entity.dart';

/// Mapping cho model layer → entity layer.
/// Enum này tách biệt với `LobbyStatus` của entity để có thể map khi backend
/// trả về string khác (e.g. "Open", "open", "OPEN"). Khi deserialize JSON,
/// gọi `LobbyStatusModelX.fromWire(...)` để chuẩn hoá.
enum LobbyStatusModel {
  open,
  full,
  inProgress,
  closed,
  timeoutFailed,
  hostCancelled;

  static LobbyStatusModel fromWire(String? value) {
    if (value == null) return LobbyStatusModel.open;
    final normalized = value.toLowerCase().trim();
    for (final s in LobbyStatusModel.values) {
      if (s.name == normalized) return s;
    }
    // Backward-compat cho mock cũ.
    switch (normalized) {
      case 'waiting':
      case 'filling':
        return LobbyStatusModel.open;
      case 'ready':
        return LobbyStatusModel.full;
      case 'cancelled':
        return LobbyStatusModel.hostCancelled;
      case 'expired':
        return LobbyStatusModel.timeoutFailed;
    }
    return LobbyStatusModel.open;
  }
}

class LobbyPlayerModel {
  final String id;
  final String name;
  final String avatarUrl;
  final bool isHost;
  final bool isReady;
  final String joinedAt;
  final double karma;

  const LobbyPlayerModel({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.isHost,
    required this.isReady,
    required this.joinedAt,
    this.karma = 70,
  });

  factory LobbyPlayerModel.fromJson(Map<String, dynamic> json) {
    return LobbyPlayerModel(
      id: json['id'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatarUrl'] as String,
      isHost: json['isHost'] as bool,
      isReady: json['isReady'] as bool,
      joinedAt: json['joinedAt'] as String,
      karma: (json['karma'] as num?)?.toDouble() ?? 70,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'avatarUrl': avatarUrl,
    'isHost': isHost,
    'isReady': isReady,
    'joinedAt': joinedAt,
    'karma': karma,
  };

  LobbyPlayer toEntity() => LobbyPlayer(
    id: id,
    name: name,
    avatarUrl: avatarUrl,
    isHost: isHost,
    isReady: isReady,
    joinedAt: DateTime.parse(joinedAt),
    karma: karma,
  );
}

class LobbyModel {
  final String id;
  final String gameId;
  final String gameName;
  final String? gameImageUrl;
  final String cafeId;
  final String cafeName;
  final String hostId;
  final String hostName;
  final DateTime scheduledTime;
  final int currentPlayers;
  final int maxPlayers;
  final int minPlayers;
  final bool isPublic;
  final String? inviteCode;
  final LobbyStatusModel status;
  final List<LobbyPlayerModel> players;
  final DateTime createdAt;
  final DateTime timeoutAt;
  final String? bookingId;
  final double minimumKarma;
  final double searchRadiusKm;
  final double? distanceKm;
  final double? cafeLat;
  final double? cafeLng;

  LobbyModel({
    required this.id,
    required this.gameId,
    required this.gameName,
    required this.cafeId,
    required this.cafeName,
    required this.hostId,
    required this.hostName,
    required this.scheduledTime,
    required this.currentPlayers,
    required this.maxPlayers,
    required this.minPlayers,
    required this.isPublic,
    this.inviteCode,
    required this.status,
    required this.players,
    required this.createdAt,
    required this.timeoutAt,
    this.bookingId,
    this.minimumKarma = 0,
    this.searchRadiusKm = 5,
    this.gameImageUrl,
    this.distanceKm,
    this.cafeLat,
    this.cafeLng,
  });

  factory LobbyModel.fromJson(Map<String, dynamic> json) {
    return LobbyModel(
      id: json['id'] as String,
      gameId: json['gameId'] as String,
      gameName: json['gameName'] as String,
      gameImageUrl: json['gameImageUrl'] as String?,
      cafeId: json['cafeId'] as String,
      cafeName: json['cafeName'] as String,
      hostId: json['hostId'] as String,
      hostName: json['hostName'] as String,
      scheduledTime: DateTime.parse(json['scheduledTime'] as String),
      currentPlayers: json['currentPlayers'] as int,
      maxPlayers: json['maxPlayers'] as int,
      minPlayers: json['minPlayers'] as int,
      isPublic: json['isPublic'] as bool,
      inviteCode: json['inviteCode'] as String?,
      status: LobbyStatusModel.fromWire(json['status'] as String?),
      players: (json['players'] as List)
          .map((e) => LobbyPlayerModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      timeoutAt: DateTime.parse(json['timeoutAt'] as String),
      bookingId: json['bookingId'] as String?,
      minimumKarma: (json['minimumKarma'] as num?)?.toDouble() ?? 0,
      searchRadiusKm: (json['searchRadiusKm'] as num?)?.toDouble() ?? 5,
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      cafeLat: (json['cafeLat'] as num?)?.toDouble(),
      cafeLng: (json['cafeLng'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'gameId': gameId,
    'gameName': gameName,
    'gameImageUrl': gameImageUrl,
    'cafeId': cafeId,
    'cafeName': cafeName,
    'hostId': hostId,
    'hostName': hostName,
    'scheduledTime': scheduledTime.toIso8601String(),
    'currentPlayers': currentPlayers,
    'maxPlayers': maxPlayers,
    'minPlayers': minPlayers,
    'isPublic': isPublic,
    'inviteCode': inviteCode,
    'status': status.name,
    'players': players.map((e) => e.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'timeoutAt': timeoutAt.toIso8601String(),
    'bookingId': bookingId,
    'minimumKarma': minimumKarma,
    'searchRadiusKm': searchRadiusKm,
    'distanceKm': distanceKm,
    'cafeLat': cafeLat,
    'cafeLng': cafeLng,
  };

  int get slotsRemaining => maxPlayers - currentPlayers;
  bool get isFull => currentPlayers >= maxPlayers;

  LobbyModel copyWith({
    String? id,
    String? gameId,
    String? gameName,
    String? gameImageUrl,
    String? cafeId,
    String? cafeName,
    String? hostId,
    String? hostName,
    DateTime? scheduledTime,
    int? currentPlayers,
    int? maxPlayers,
    int? minPlayers,
    bool? isPublic,
    String? inviteCode,
    LobbyStatusModel? status,
    List<LobbyPlayerModel>? players,
    DateTime? createdAt,
    DateTime? timeoutAt,
    Object? bookingId = _sentinel,
    double? minimumKarma,
    double? searchRadiusKm,
    Object? distanceKm = _sentinel,
    Object? cafeLat = _sentinel,
    Object? cafeLng = _sentinel,
  }) {
    return LobbyModel(
      id: id ?? this.id,
      gameId: gameId ?? this.gameId,
      gameName: gameName ?? this.gameName,
      gameImageUrl: gameImageUrl ?? this.gameImageUrl,
      cafeId: cafeId ?? this.cafeId,
      cafeName: cafeName ?? this.cafeName,
      hostId: hostId ?? this.hostId,
      hostName: hostName ?? this.hostName,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      currentPlayers: currentPlayers ?? this.currentPlayers,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      minPlayers: minPlayers ?? this.minPlayers,
      isPublic: isPublic ?? this.isPublic,
      inviteCode: inviteCode ?? this.inviteCode,
      status: status ?? this.status,
      players: players ?? this.players,
      createdAt: createdAt ?? this.createdAt,
      timeoutAt: timeoutAt ?? this.timeoutAt,
      bookingId: identical(bookingId, _sentinel)
          ? this.bookingId
          : bookingId as String?,
      minimumKarma: minimumKarma ?? this.minimumKarma,
      searchRadiusKm: searchRadiusKm ?? this.searchRadiusKm,
      distanceKm: identical(distanceKm, _sentinel)
          ? this.distanceKm
          : distanceKm as double?,
      cafeLat: identical(cafeLat, _sentinel)
          ? this.cafeLat
          : cafeLat as double?,
      cafeLng: identical(cafeLng, _sentinel)
          ? this.cafeLng
          : cafeLng as double?,
    );
  }

  LobbyEntity toEntity() => LobbyEntity(
    id: id,
    gameId: gameId,
    gameName: gameName,
    cafeId: cafeId,
    cafeName: cafeName,
    hostId: hostId,
    hostName: hostName,
    scheduledTime: scheduledTime,
    currentPlayers: currentPlayers,
    maxPlayers: maxPlayers,
    minPlayers: minPlayers,
    isPublic: isPublic,
    inviteCode: inviteCode,
    status: _statusToEntity(status),
    players: players.map((p) => p.toEntity()).toList(),
    createdAt: createdAt,
    timeoutAt: timeoutAt,
    bookingId: bookingId,
    minimumKarma: minimumKarma,
    searchRadiusKm: searchRadiusKm,
  );

  static LobbyStatus _statusToEntity(LobbyStatusModel status) {
    switch (status) {
      case LobbyStatusModel.open:
        return LobbyStatus.open;
      case LobbyStatusModel.full:
        return LobbyStatus.full;
      case LobbyStatusModel.inProgress:
        return LobbyStatus.inProgress;
      case LobbyStatusModel.closed:
        return LobbyStatus.closed;
      case LobbyStatusModel.timeoutFailed:
        return LobbyStatus.timeoutFailed;
      case LobbyStatusModel.hostCancelled:
        return LobbyStatus.hostCancelled;
    }
  }
}

const Object _sentinel = Object();
