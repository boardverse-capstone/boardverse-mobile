import 'package:flutter/material.dart';

/// Arguments passed to [PlayerQrCheckInPage] when navigating via named routes.
///
/// Dùng làm `arguments` trong `Navigator.pushNamed` với route
/// `LobbyRoutes.playerQrCheckIn`.
///
/// Example:
/// ```dart
/// Navigator.pushNamed(
///   context,
///   LobbyRoutes.playerQrCheckIn,
///   arguments: PlayerQrCheckInPageArgs(
///     reservationId: 'res-123',
///     lobbyShareCode: 'ABCDEFGH',
///     cafeName: 'BoardVerse Cafe',
///     gameName: 'Catan',
///     onCheckInSuccess: () {
///       // Refresh parent page sau khi check-in thành công
///       context.read<ReservationDetailCubit>().refresh('res-123');
///     },
///   ),
/// );
/// ```
class PlayerQrCheckInPageArgs {
  final String reservationId;

  /// Mã lobby/share code dùng để hiển thị QR cho staff đối chiếu.
  final String lobbyShareCode;

  final String cafeName;
  final String gameName;
  final int tableNumber;

  /// Callback được gọi sau khi check-in thành công.
  /// Dùng để parent page (VD: ReservationDetailPage) refresh data sau khi
  /// player quay lại — để `checkedInAt` được cập nhật và button
  /// "Phiên chơi của tôi" hiển thị đúng.
  final VoidCallback? onCheckInSuccess;

  const PlayerQrCheckInPageArgs({
    required this.reservationId,
    required this.lobbyShareCode,
    required this.cafeName,
    required this.gameName,
    this.tableNumber = 1,
    this.onCheckInSuccess,
  });
}
