import 'package:equatable/equatable.dart';

/// Snapshot nhỏ gọn của Lobby — được nhúng trong `BookingResponseDto.LobbySummary`
/// (xem `.agents/docs/apis_docs/booking.md` §179).
///
/// Dùng để mobile hiển thị thông tin group khi booking walk-in (không qua
/// lobby) hoặc khi player mở `BookingDetailPage` từ tab "Sắp tới".
class LobbySummaryEntity extends Equatable {
  /// Lobby id (Guid) — có thể null cho walk-in booking (gap #3).
  final String? id;

  /// Host id (Guid).
  final String hostId;

  /// Game mà lobby chọn.
  final String gameId;
  final String gameName;

  /// Số thành viên hiện tại (snapshot thời điểm booking tạo).
  final int currentMembers;

  /// Sức chứa tối đa của lobby (theo board game config).
  final int maxMembers;

  /// Danh sách id các thành viên (cache để UI render avatar).
  final List<String> memberIds;

  const LobbySummaryEntity({
    this.id,
    required this.hostId,
    required this.gameId,
    required this.gameName,
    required this.currentMembers,
    required this.maxMembers,
    required this.memberIds,
  });

  @override
  List<Object?> get props => [
        id,
        hostId,
        gameId,
        gameName,
        currentMembers,
        maxMembers,
        memberIds,
      ];
}
