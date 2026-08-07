import 'package:equatable/equatable.dart';

/// Vòng đời của phòng chờ trực tuyến — đồng bộ với BR §17.5 và `state.md`.
///
/// - [pendingActivation]    : atomic transaction đang xử lý (chưa publish).
/// - [pendingCafeApproval]  : lobby public > 2 ngày, chờ cafe duyệt (BR-NEW-11).
/// - [open]                 : đang tuyển người, recruitmentDeadline chưa tới.
/// - [viable]               : đã đạt minPlayers, vẫn có thể nhận thêm đến max.
/// - [full]                 : đạt maxPlayers, ngừng nhận.
/// - [inProgress]           : cả nhóm đã check-in tại quán (Task 4).
/// - [ratingOpen]           : sau thanh toán POS, đang đánh giá Karma (Task 5).
/// - [closed]               : phiên kết thúc, rating cross được phép (Task 5).
/// - [timeoutFailed]        : BR-08 — Lead-time trôi qua mà chưa đạt [minPlayers].
/// - [hostCancelled]        : Host主动 hủy khi còn [open].
/// - [rejectedByCafe]       : cafe từ chối duyệt (BR-NEW-11).
/// - [expiredByCafe]        : cafe không duyệt trong 24h (BR-NEW-11).
enum LobbyStatus {
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
  expiredByCafe,
}

extension LobbyStatusX on LobbyStatus {
  /// Lobby đã kết thúc (không thể tương tác thêm — chỉ xem/action dissolve).
  bool get isTerminal {
    switch (this) {
      case LobbyStatus.closed:
      case LobbyStatus.timeoutFailed:
      case LobbyStatus.hostCancelled:
      case LobbyStatus.rejectedByCafe:
      case LobbyStatus.expiredByCafe:
        return true;
      case LobbyStatus.pendingActivation:
      case LobbyStatus.pendingCafeApproval:
      case LobbyStatus.open:
      case LobbyStatus.viable:
      case LobbyStatus.full:
      case LobbyStatus.inProgress:
      case LobbyStatus.ratingOpen:
        return false;
    }
  }

  /// Host có thể bấm "Giải tán" (DELETE /api/v1/lobbies/{id}) để hard
  /// delete lobby khỏi DB.
  ///
  /// Backend swagger spec: không áp dụng khi lobby đã check-in tại quán
  /// hoặc đã đóng/rating. Tương ứng ta chặn `InProgress` / `RatingOpen`
  /// / `Closed`:
  /// - InProgress/RatingOpen: phiên chơi đang diễn ra.
  /// - Closed: lobby đã đóng rồi, không cần gọi lại.
  /// - PendingActivation/PendingCafeApproval: chưa publish, backend không
  ///   cho phép dissolve.
  bool get canDissolve {
    switch (this) {
      case LobbyStatus.open:
      case LobbyStatus.viable:
      case LobbyStatus.full:
      case LobbyStatus.timeoutFailed:
      case LobbyStatus.hostCancelled:
        return true;
      case LobbyStatus.closed:
      case LobbyStatus.inProgress:
      case LobbyStatus.ratingOpen:
      case LobbyStatus.pendingActivation:
      case LobbyStatus.pendingCafeApproval:
      case LobbyStatus.rejectedByCafe:
      case LobbyStatus.expiredByCafe:
        return false;
    }
  }

  /// Lobby đã hết hạn do không đủ người — host có thể tạo lại.
  bool get isExpired => this == LobbyStatus.timeoutFailed;

  /// Lobby host đã chủ động huỷ.
  bool get isHostCancelled => this == LobbyStatus.hostCancelled;

  /// Lobby đã đủ điều kiện để host đến quán check-in. Áp dụng khi:
  /// - Viable  (đủ minPlayers, còn slot) → có thể đến quán
  /// - Full    (đủ maxPlayers, đóng tuyển) → sẵn sàng đến quán
  /// - InProgress (đã check-in, đang chơi)
  bool get canCheckIn =>
      this == LobbyStatus.viable ||
      this == LobbyStatus.full ||
      this == LobbyStatus.inProgress;

  /// Lobby đang chờ cafe duyệt (BR-NEW-11) — host phải đợi.
  bool get isPendingCafeApproval => this == LobbyStatus.pendingCafeApproval;

  /// Lobby đang chờ tuyển người (open) hoặc đã đạt minPlayers mà vẫn
  /// có thể nhận thêm (viable) — vẫn show countdown tới recruitmentDeadline.
  bool get isRecruiting =>
      this == LobbyStatus.open || this == LobbyStatus.viable;
}

class LobbyEntity extends Equatable {
  final String id;
  final String gameId;
  final String gameName;

  /// URL ảnh game — optional. Chỉ có ở một số endpoint (vd: `/discoverable`).
  final String? gameImageUrl;

  final String cafeId;
  final String cafeName;

  /// Bàn đã được backend gán sẵn cho lobby, nếu có.
  final String? cafeTableId;

  final String hostId;
  final String hostName;
  final DateTime scheduledTime;

  /// Giờ hẹn chơi thực tế. Khác với `timeoutAt` (= scheduledTime - leadTime).
  final int currentPlayers;
  final int maxPlayers;
  final int minPlayers;
  final bool isPublic;

  /// Optional — chỉ có khi lobby riêng tư & host đã generate share code.
  final String? inviteCode;

  final LobbyStatus status;
  final List<LobbyPlayer> players;
  final DateTime createdAt;

  /// Hạn chót phải đủ người (BR-08):
  /// `timeoutAt = scheduledTime - leadTimeMinutes` (lấy từ deposit-config của quán).
  final DateTime timeoutAt;

  /// BR-07: liên kết tới Booking của host khi lobby phát sinh từ Luồng B.
  final String? bookingId;

  /// Reservation ID tạo ra lobby (theo plan migrate sang Reservation/BVC).
  /// Poll `getHostedLobbies` dựa trên field này để nhận cafe-approval update.
  final String? reservationId;

  /// BR-10: chỉ chấp nhận thành viên có Karma ≥ minimumKarma.
  final double minimumKarma;

  /// BR-08: bán kính tìm kiếm lobby khả dụng (km).
  final double searchRadiusKm;

  /// Khoảng cách từ user hiện tại tới lobby (km). Optional — chỉ có khi
  /// gọi `/discoverable` hoặc `/search` có tính toán distance.
  final double? distanceKm;

  /// Server-side timestamp khi lobby chuyển sang terminal state (closed,
  /// cancelled, timeout). Optional — chỉ có khi status terminal.
  final DateTime? closedAt;

  /// Lý do đóng phòng do server cung cấp (vd: "Host đã rời phòng và không
  /// còn thành viên nào."). Optional — chỉ có khi status terminal.
  final String? closedReason;

  /// Thời gian tối thiểu (phút) trước `scheduledTime` mà lobby phải đủ
  /// người (BR-08). Optional — backend trả về cho `/lobbies/{id}`.
  final int? cancellationLeadTimeMinutes;

  /// Timestamp khi lobby chính thức chuyển sang `inProgress` (POS xác nhận
  /// đã check-in toàn bộ thành viên). UI dùng để hiển thị banner "Đang
  /// chơi" + đếm ngược thời gian đã chơi.
  final DateTime? playStartedAt;

  const LobbyEntity({
    required this.id,
    required this.gameId,
    required this.gameName,
    this.gameImageUrl,
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
    this.distanceKm,
    this.closedAt,
    this.closedReason,
    this.cancellationLeadTimeMinutes,
    this.playStartedAt,
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
    Object? cafeTableId = _sentinel,
    String? hostId,
    String? hostName,
    DateTime? scheduledTime,
    int? currentPlayers,
    int? maxPlayers,
    int? minPlayers,
    bool? isPublic,
    Object? inviteCode = _sentinel,
    LobbyStatus? status,
    List<LobbyPlayer>? players,
    DateTime? createdAt,
    DateTime? timeoutAt,
    Object? bookingId = _sentinel,
    Object? reservationId = _sentinel,
    double? minimumKarma,
    double? searchRadiusKm,
    Object? gameImageUrl = _sentinel,
    Object? distanceKm = _sentinel,
    Object? closedAt = _sentinel,
    Object? closedReason = _sentinel,
    Object? cancellationLeadTimeMinutes = _sentinel,
    Object? playStartedAt = _sentinel,
  }) {
    return LobbyEntity(
      id: id ?? this.id,
      gameId: gameId ?? this.gameId,
      gameName: gameName ?? this.gameName,
      gameImageUrl: identical(gameImageUrl, _sentinel)
          ? this.gameImageUrl
          : gameImageUrl as String?,
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
      inviteCode: identical(inviteCode, _sentinel)
          ? this.inviteCode
          : inviteCode as String?,
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
      closedAt: identical(closedAt, _sentinel)
          ? this.closedAt
          : closedAt as DateTime?,
      closedReason: identical(closedReason, _sentinel)
          ? this.closedReason
          : closedReason as String?,
      cancellationLeadTimeMinutes:
          identical(cancellationLeadTimeMinutes, _sentinel)
              ? this.cancellationLeadTimeMinutes
              : cancellationLeadTimeMinutes as int?,
      playStartedAt: identical(playStartedAt, _sentinel)
          ? this.playStartedAt
          : playStartedAt as DateTime?,
    );
  }

  @override
  List<Object?> get props => [
    id,
    gameId,
    gameName,
    gameImageUrl,
    cafeId,
    cafeName,
    cafeTableId,
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
    reservationId,
    minimumKarma,
    searchRadiusKm,
    distanceKm,
    closedAt,
    closedReason,
    cancellationLeadTimeMinutes,
    playStartedAt,
  ];
}

/// Sentinel cho phép `copyWith` phân biệt được "không truyền" với "truyền null".
const Object _sentinel = Object();

class LobbyPlayer extends Equatable {
  /// ID của membership record
  final String id;
  
  /// ID của user (để kiểm tra membership)
  final String userId;
  
  final String name;
  final String avatarUrl;
  final bool isHost;
  final bool isReady;
  final DateTime joinedAt;

  /// BR-10: điểm uy tín hiện tại của player (chỉ dùng cho filter & hiển thị).
  final double karma;

  const LobbyPlayer({
    required this.id,
    required this.userId,
    required this.name,
    required this.avatarUrl,
    required this.isHost,
    required this.isReady,
    required this.joinedAt,
    this.karma = 70,
  });

  @override
  List<Object?> get props => [
    id,
    userId,
    name,
    avatarUrl,
    isHost,
    isReady,
    joinedAt,
    karma,
  ];
}
