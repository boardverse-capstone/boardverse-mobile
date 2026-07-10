import 'package:equatable/equatable.dart';

/// Vòng đời của phòng chờ trực tuyến — đồng bộ với `state.md`.
///
/// - [open]          : đang tuyển người (BR-08 timer đang chạy).
/// - [full]          : đủ người, chờ auto-create booking (Luồng A).
/// - [inProgress]    : cả nhóm đã check-in tại quán (Task 4).
/// - [closed]        : phiên kết thúc, rating cross được phép (Task 5).
/// - [timeoutFailed] : BR-08 — Lead-time trôi qua mà chưa đạt [minPlayers].
/// - [hostCancelled] : Host主动 hủy khi còn [open].
enum LobbyStatus {
  open,
  full,
  inProgress,
  closed,
  timeoutFailed,
  hostCancelled,
}

class LobbyEntity extends Equatable {
  final String id;
  final String gameId;
  final String gameName;
  final String cafeId;
  final String cafeName;
  final String hostId;
  final String hostName;
  final DateTime scheduledTime;

  /// Giờ hẹn chơi thực tế. Khác với `timeoutAt` (= scheduledTime - leadTime).
  final int currentPlayers;
  final int maxPlayers;
  final int minPlayers;
  final bool isPublic;
  final String? inviteCode;
  final LobbyStatus status;
  final List<LobbyPlayer> players;
  final DateTime createdAt;

  /// Hạn chót phải đủ người (BR-08):
  /// `timeoutAt = scheduledTime - leadTimeMinutes` (lấy từ deposit-config của quán).
  final DateTime timeoutAt;

  /// BR-07: liên kết tới Booking của host khi lobby phát sinh từ Luồng B.
  final String? bookingId;

  /// BR-10: chỉ chấp nhận thành viên có Karma ≥ minimumKarma.
  final double minimumKarma;

  /// BR-08: bán kính tìm kiếm lobby khả dụng (km).
  final double searchRadiusKm;

  const LobbyEntity({
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
  });

  int get slotsRemaining => maxPlayers - currentPlayers;

  /// Khoảng thời gian còn lại trước khi BR-08 timeout.
  Duration get remainingTime => timeoutAt.difference(DateTime.now());

  /// true nếu đã trôi qua BR-08 lead-time mà chưa đạt minPlayers.
  bool get isExpired => DateTime.now().isAfter(timeoutAt);

  LobbyEntity copyWith({
    String? id,
    String? gameId,
    String? gameName,
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
    LobbyStatus? status,
    List<LobbyPlayer>? players,
    DateTime? createdAt,
    DateTime? timeoutAt,
    Object? bookingId = _sentinel,
    double? minimumKarma,
    double? searchRadiusKm,
  }) {
    return LobbyEntity(
      id: id ?? this.id,
      gameId: gameId ?? this.gameId,
      gameName: gameName ?? this.gameName,
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
      bookingId: identical(bookingId, _sentinel) ? this.bookingId : bookingId as String?,
      minimumKarma: minimumKarma ?? this.minimumKarma,
      searchRadiusKm: searchRadiusKm ?? this.searchRadiusKm,
    );
  }

  @override
  List<Object?> get props => [
        id,
        gameId,
        gameName,
        cafeId,
        cafeName,
        hostId,
        hostName,
        scheduledTime,
        currentPlayers,
        maxPlayers,
        minPlayers,
        isPublic,
        inviteCode,
        status,
        players,
        createdAt,
        timeoutAt,
        bookingId,
        minimumKarma,
        searchRadiusKm,
      ];
}

/// Sentinel cho phép `copyWith` phân biệt được "không truyền" với "truyền null".
const Object _sentinel = Object();

class LobbyPlayer extends Equatable {
  final String id;
  final String name;
  final String avatarUrl;
  final bool isHost;
  final bool isReady;
  final DateTime joinedAt;

  /// BR-10: điểm uy tín hiện tại của player (chỉ dùng cho filter & hiển thị).
  final double karma;

  const LobbyPlayer({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.isHost,
    required this.isReady,
    required this.joinedAt,
    this.karma = 70,
  });

  @override
  List<Object?> get props => [id, name, avatarUrl, isHost, isReady, joinedAt, karma];
}
