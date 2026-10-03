import 'package:equatable/equatable.dart';

/// Kết quả giải tán lobby — trả về từ `DELETE /api/v1/lobbies/{id}`.
///
/// **Cập nhật 2026-08-27 (BR §XXI-A.6):**
/// Backend đã chuyển từ **hard delete** sang **soft delete** (`Lobby.Status =
/// Dissolved`). Endpoint vẫn giữ `DELETE` HTTP verb nhưng row vẫn còn trong
/// DB để phục vụ audit trail + risk score signals (BR-RISK-01
/// SIG-01/SIG-02, BR-NEW-10 cooling-off).
///
/// Backend có thể áp dụng **Karma penalty** cho Host khi dissolve lobby sau
/// grace period (đã có member join HOẶC > 15 phút từ tạo) — xem BR-KARMA-03.
///
/// DTO reference: `BoardVerse.Core/DTOs/Lobby/DissolveLobbyResponseDto.cs`.
class DissolveLobbyResult extends Equatable {
  final String lobbyId;

  /// Reservation bị release về trạng thái Holding (nếu đang Confirmed) để
  /// host tạo lobby mới cùng `playDate + timeSlot`. `null` cho legacy lobby
  /// không qua Reservation flow (vd: lobby test).
  final String? reservationId;

  /// Lý do host đưa ra (echo từ request body). `null` nếu host không truyền.
  final String? reason;

  /// Timestamp backend dissolve lobby thành công.
  final DateTime dissolvedAt;

  const DissolveLobbyResult({
    required this.lobbyId,
    this.reservationId,
    this.reason,
    required this.dissolvedAt,
  });

  @override
  List<Object?> get props => [lobbyId, reservationId, reason, dissolvedAt];
}
