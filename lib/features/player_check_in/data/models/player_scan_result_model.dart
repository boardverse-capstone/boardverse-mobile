import '../../../reservation/domain/entities/entities.dart' as res;

/// Pure data class — kết quả `POST /api/check-in/scan-qr` (BR §21A.7).
class PlayerScanResultModel {
  final String activeSessionId;
  final String reservationId;
  final String cafeId;
  final DateTime checkedInAt;
  final res.ReservationStatus? reservationStatus;

  const PlayerScanResultModel({
    required this.activeSessionId,
    required this.reservationId,
    required this.cafeId,
    required this.checkedInAt,
    this.reservationStatus,
  });

  factory PlayerScanResultModel.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['reservationStatus'];
    return PlayerScanResultModel(
      activeSessionId: (json['activeSessionId'] ?? json['sessionId'] ?? '')
          .toString(),
      reservationId: (json['reservationId'] ?? '').toString(),
      cafeId: (json['cafeId'] ?? '').toString(),
      checkedInAt: DateTime.tryParse(
            (json['checkedInAt'] ?? json['startedAt'] ?? '').toString(),
          ) ??
          DateTime.now(),
      reservationStatus: rawStatus is String && rawStatus.isNotEmpty
          ? res.ReservationStatus.fromString(rawStatus)
          : null,
    );
  }
}

/// Request body cho `POST /api/check-in/scan-qr`.
class PlayerScanTokenRequestModel {
  final String token;

  const PlayerScanTokenRequestModel({required this.token});

  Map<String, dynamic> toJson() => {'token': token};
}
