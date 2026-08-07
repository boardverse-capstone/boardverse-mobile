import '../../domain/entities/lobby_entity.dart';

/// Mapping cho model layer → entity layer.
/// Enum này tách biệt với `LobbyStatus` của entity để có thể map khi backend
/// trả về string khác (e.g. "Open", "open", "OPEN"). Khi deserialize JSON,
/// gọi `LobbyStatusModelX.fromWire(...)` để chuẩn hoá.
enum LobbyStatusModel {
  pendingActivation,
  pendingCafeApproval,
  open,
  viable,
  full,
  inProgress,
  ratingOpen,
  closed,
  timeoutFailed,
  hostCancelled,
  rejectedByCafe,
  expiredByCafe;

  static LobbyStatusModel fromWire(String? value) {
    if (value == null) return LobbyStatusModel.open;
    final normalized = value.toLowerCase().trim();
    for (final s in LobbyStatusModel.values) {
      if (s.name == normalized) return s;
    }
    // Backward-compat cho mock cũ + alias từ backend docs.
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
      case 'ratingopen':
      case 'rating_open':
        return LobbyStatusModel.ratingOpen;
      case 'pendingactivation':
      case 'pending_activation':
        return LobbyStatusModel.pendingActivation;
      case 'pendingcafeapproval':
      case 'pending_cafe_approval':
        return LobbyStatusModel.pendingCafeApproval;
      case 'rejectedbycafe':
      case 'rejected_by_cafe':
        return LobbyStatusModel.rejectedByCafe;
      case 'expiredbycafe':
      case 'expired_by_cafe':
        return LobbyStatusModel.expiredByCafe;
    }
    return LobbyStatusModel.open;
  }
}

class LobbyPlayerModel {
  final String id;
  final String userId;
  final String name;
  final String avatarUrl;
  final bool isHost;
  final bool isReady;
  final String joinedAt;
  final double karma;

  const LobbyPlayerModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.avatarUrl,
    required this.isHost,
    required this.isReady,
    required this.joinedAt,
    this.karma = 70,
  });

  factory LobbyPlayerModel.fromJson(Map<String, dynamic> json) {
    return LobbyPlayerModel(
      id: (json['id'] ?? '') as String,
      userId: (json['userId'] ?? '') as String,
      name: (json['name'] ?? json['userName'] ?? '') as String,
      avatarUrl: (json['avatarUrl'] ?? '') as String,
      isHost: (json['isHost'] ?? false) as bool,
      // Backend `readyAt` (DateTime? — null nếu chưa ready). Một số mock
      // schema cũ dùng `isReady: bool` — fallback cả 2.
      isReady: (json['readyAt'] != null) ||
          ((json['isReady'] ?? false) as bool),
      joinedAt: (json['joinedAt'] ?? DateTime.now().toIso8601String())
          as String,
      karma: (json['karma'] as num?)?.toDouble() ??
          (json['karmaPoints'] as num?)?.toDouble() ??
          70,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'name': name,
    'avatarUrl': avatarUrl,
    'isHost': isHost,
    'isReady': isReady,
    'joinedAt': joinedAt,
    'karma': karma,
  };

  LobbyPlayer toEntity() => LobbyPlayer(
    id: id,
    userId: userId,
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
  final String? cafeTableId;
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
  final String? reservationId;
  final double minimumKarma;
  final double searchRadiusKm;
  final double? distanceKm;
  final double? cafeLat;
  final double? cafeLng;
  final DateTime? closedAt;
  final String? closedReason;
  final int? cancellationLeadTimeMinutes;
  final DateTime? playStartedAt;

  LobbyModel({
    required this.id,
    required this.gameId,
    required this.gameName,
    required this.cafeId,
    required this.cafeName,
    this.cafeTableId,
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
    this.reservationId,
    this.minimumKarma = 0,
    this.searchRadiusKm = 5,
    this.gameImageUrl,
    this.distanceKm,
    this.cafeLat,
    this.cafeLng,
    this.closedAt,
    this.closedReason,
    this.cancellationLeadTimeMinutes,
    this.playStartedAt,
  });

  factory LobbyModel.fromJson(Map<String, dynamic> json) {
    // Schema `/discoverable` mới trả field camelCase khác với `/search`
    // và `/lobbies/{id}` cũ:
    //   `gameTemplateId`      ↔ `gameId`
    //   `currentMembers`      ↔ `currentPlayers`
    //   `maxMembers`          ↔ `maxPlayers`
    //   `visibility`          ↔ `isPublic`  ("public" / "private")
    //   `scheduledStartTime`  ↔ `scheduledTime`
    //   `memberAvatars[]`     ↔ `players[]`  (chỉ list URL, không full DTO)
    // `/discoverable` response **không có** `hostName`, `cafeName`, `minPlayers`,
    // `timeoutAt`, `bookingId`, `inviteCode`, `minimumKarma`, `distanceKm` —
    // ta fallback giá trị mặc định an toàn cho các field optional này.
    final hostId = (json['hostId'] ?? json['hostUserId'] ?? '') as String;
    final gameId = (json['gameId'] ?? json['gameTemplateId'] ?? '') as String;
    final maxPlayers = (json['maxPlayers'] ?? json['maxMembers'] ?? 0) as int;
    final isPublic = _parseVisibility(
      json['isPublic'] ?? json['visibility'],
      json['isPrivate'],
    );

    // scheduledTime: bắt buộc trong cả 2 schema, nhưng đặt tên khác nhau.
    final scheduledTimeRaw = (json['scheduledTime'] ??
            json['scheduledStartTime'] ??
            DateTime.now().toIso8601String())
        as String;

    // createdAt: bắt buộc cũ, optional mới — fallback now().
    final createdAtRaw = (json['createdAt'] ??
            json['scheduledStartTime'] ??
            DateTime.now().toIso8601String())
        as String;

    // timeoutAt: optional ở `/discoverable`. Fallback `+6h` để UI không crash.
    final timeoutAtRaw = (json['timeoutAt'] ?? json['expiresAt'] ??
            DateTime.now()
                .add(const Duration(hours: 6))
                .toIso8601String())
        as String;

    // Members: response `/lobbies/{id}` mới dùng `members[]` (PascalCase)
    // với full DTO. Cũng fallback `players[]` để tương thích schema cũ.
    final playersJson =
        (json['members'] ?? json['players'] ?? json['memberAvatars']) as List?;
    final players = playersJson == null
        ? <LobbyPlayerModel>[]
        : (playersJson.first is Map
            ? (playersJson)
                .map((e) => LobbyPlayerModel.fromJson(e as Map<String, dynamic>))
                .toList()
            : (playersJson)
                .map((url) => LobbyPlayerModel(
                      id: '',
                      userId: '', // Mock data - actual data has userId
                      name: '',
                      avatarUrl: url as String,
                      isHost: false,
                      isReady: false,
                      joinedAt: DateTime.now().toIso8601String(),
                    ))
                .toList());

    // currentPlayers: response mới không trả `currentPlayers` — derive từ
    // `members.length` (host + members đều được tính là 1 slot). Khi có
    // `currentPlayers` thì ưu tiên dùng nó để tương thích mock cũ.
    final currentPlayersRaw = json['currentPlayers'] ?? json['currentMembers'];
    final derivedCurrentPlayers = currentPlayersRaw != null
        ? (currentPlayersRaw as num).toInt()
        : players.length;

    return LobbyModel(
      id: json['id'] as String,
      gameId: gameId,
      gameName: (json['gameName'] ?? '') as String,
      gameImageUrl: json['gameImageUrl'] as String?,
      cafeId: (json['cafeId'] ?? '') as String,
      // `cafeName` optional ở schema mới (vd: `/lobbies/{id}`) — fallback
      // rỗng; cubit merge với cached lobby trước khi emit state để UI
      // vẫn hiển thị tên quán cũ.
      cafeName: (json['cafeName'] ?? '') as String,
      cafeTableId: json['cafeTableId']?.toString(),
      hostId: hostId,
      // `hostName` optional ở schema mới — fallback 'Chủ phòng' để UI không
      // hiển thị ô trống. cubit có thể merge với cached lobby để lấy tên thật.
      hostName: (json['hostName'] ?? '') as String,
      scheduledTime: DateTime.parse(scheduledTimeRaw),
      currentPlayers: derivedCurrentPlayers,
      maxPlayers: maxPlayers,
      // `/discoverable` không trả `minPlayers` — fallback = 2 (BR-07 min).
      minPlayers: (json['minPlayers'] as int?) ?? 2,
      isPublic: isPublic,
      // `shareCode` (PascalCase) ≈ `inviteCode` (camelCase) — fallback cả 2
      // để tương thích schema cũ và mới.
      inviteCode: (json['inviteCode'] ?? json['shareCode']) as String?,
      status: LobbyStatusModel.fromWire(json['status'] as String?),
      players: players,
      createdAt: DateTime.parse(createdAtRaw),
      timeoutAt: DateTime.parse(timeoutAtRaw),
      bookingId: json['bookingId'] as String?,
      reservationId: json['reservationId'] as String?,
      // `minKarmaScore` (PascalCase) ≈ `minKarma` (camelCase) — fallback cả 2.
      minimumKarma: (json['minimumKarma'] as num?)?.toDouble() ??
          (json['minKarmaScore'] as num?)?.toDouble() ??
          0,
      searchRadiusKm: (json['searchRadiusKm'] as num?)?.toDouble() ?? 5,
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      cafeLat: (json['cafeLat'] as num?)?.toDouble(),
      cafeLng: (json['cafeLng'] as num?)?.toDouble(),
      closedAt: json['closedAt'] != null
          ? DateTime.tryParse(json['closedAt'] as String)
          : null,
      closedReason: json['closedReason'] as String?,
      cancellationLeadTimeMinutes: (json['cancellationLeadTimeMinutes'] as num?)?.toInt(),
      playStartedAt: json['playStartedAt'] != null
          ? DateTime.tryParse(json['playStartedAt'] as String)
          : null,
    );
  }

  /// Parse `visibility` từ cả schema cũ (`isPublic: bool`) và mới
  /// (`visibility: "public" | "private" | "invite_only"`).
  ///
  /// Hỗ trợ field `isPrivate` từ backend (true = private, false = public).
  static bool _parseVisibility(dynamic isPublic, [dynamic isPrivate]) {
    // Nếu có `isPrivate` field → đảo ngược giá trị (isPrivate: true = private lobby)
    if (isPrivate != null && isPrivate is bool) {
      return !isPrivate;
    }
    if (isPublic is bool) return isPublic;
    if (isPublic is String) {
      final normalized = isPublic.toLowerCase().trim();
      return normalized == 'public' || normalized.isEmpty;
    }
    return true; // mặc định an toàn — public.
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'gameId': gameId,
    'gameName': gameName,
    'gameImageUrl': gameImageUrl,
    'cafeId': cafeId,
    'cafeName': cafeName,
    'cafeTableId': cafeTableId,
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
    'reservationId': reservationId,
    'minimumKarma': minimumKarma,
    'searchRadiusKm': searchRadiusKm,
    'distanceKm': distanceKm,
    'cafeLat': cafeLat,
    'cafeLng': cafeLng,
    'closedAt': closedAt?.toIso8601String(),
    'closedReason': closedReason,
    'cancellationLeadTimeMinutes': cancellationLeadTimeMinutes,
    'playStartedAt': playStartedAt?.toIso8601String(),
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
    Object? cafeTableId = _sentinel,
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
    Object? reservationId = _sentinel,
    double? minimumKarma,
    double? searchRadiusKm,
    Object? distanceKm = _sentinel,
    Object? cafeLat = _sentinel,
    Object? cafeLng = _sentinel,
    Object? closedAt = _sentinel,
    Object? closedReason = _sentinel,
    Object? cancellationLeadTimeMinutes = _sentinel,
    Object? playStartedAt = _sentinel,
  }) {
    return LobbyModel(
      id: id ?? this.id,
      gameId: gameId ?? this.gameId,
      gameName: gameName ?? this.gameName,
      gameImageUrl: gameImageUrl ?? this.gameImageUrl,
      cafeId: cafeId ?? this.cafeId,
      cafeName: cafeName ?? this.cafeName,
      cafeTableId: identical(cafeTableId, _sentinel)
          ? this.cafeTableId
          : cafeTableId as String?,
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
      reservationId: identical(reservationId, _sentinel)
          ? this.reservationId
          : reservationId as String?,
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
      closedAt: identical(closedAt, _sentinel)
          ? this.closedAt
          : closedAt as DateTime?,
      closedReason: identical(closedReason, _sentinel)
          ? this.closedReason
          : closedReason as String?,
      cancellationLeadTimeMinutes: identical(
        cancellationLeadTimeMinutes,
        _sentinel,
      )
          ? this.cancellationLeadTimeMinutes
          : cancellationLeadTimeMinutes as int?,
      playStartedAt: identical(playStartedAt, _sentinel)
          ? this.playStartedAt
          : playStartedAt as DateTime?,
    );
  }

  LobbyEntity toEntity() => LobbyEntity(
    id: id,
    gameId: gameId,
    gameName: gameName,
    cafeId: cafeId,
    cafeName: cafeName,
    cafeTableId: cafeTableId,
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
    reservationId: reservationId,
    minimumKarma: minimumKarma,
    searchRadiusKm: searchRadiusKm,
    closedAt: closedAt,
    closedReason: closedReason,
    cancellationLeadTimeMinutes: cancellationLeadTimeMinutes,
    playStartedAt: playStartedAt,
  );

  static LobbyStatus _statusToEntity(LobbyStatusModel status) {
    switch (status) {
      case LobbyStatusModel.pendingActivation:
        return LobbyStatus.pendingActivation;
      case LobbyStatusModel.pendingCafeApproval:
        return LobbyStatus.pendingCafeApproval;
      case LobbyStatusModel.open:
        return LobbyStatus.open;
      case LobbyStatusModel.viable:
        return LobbyStatus.viable;
      case LobbyStatusModel.full:
        return LobbyStatus.full;
      case LobbyStatusModel.inProgress:
        return LobbyStatus.inProgress;
      case LobbyStatusModel.ratingOpen:
        return LobbyStatus.ratingOpen;
      case LobbyStatusModel.closed:
        return LobbyStatus.closed;
      case LobbyStatusModel.timeoutFailed:
        return LobbyStatus.timeoutFailed;
      case LobbyStatusModel.hostCancelled:
        return LobbyStatus.hostCancelled;
      case LobbyStatusModel.rejectedByCafe:
        return LobbyStatus.rejectedByCafe;
      case LobbyStatusModel.expiredByCafe:
        return LobbyStatus.expiredByCafe;
    }
  }
}

const Object _sentinel = Object();
