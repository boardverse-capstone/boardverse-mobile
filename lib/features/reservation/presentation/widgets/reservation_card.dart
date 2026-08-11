import 'package:flutter/material.dart';

import '../../../lobby_management/presentation/widgets/lobby_card_base.dart';
import '../../domain/entities/reservation_entity.dart';

/// Neo-brutalism card hiển thị một `ReservationEntity`.
///
/// Vui lòng đọc `lobby_card_base.dart` để hiểu design chung. File này chỉ là
/// adapter — chuyển `ReservationEntity` → `LobbyCardItem` rồi nhờ widget
/// `LobbyCardBase` render.
///
/// Tại sao file này tồn tại:
/// - Place-based: page `reservation_list_page.dart` import widget "nằm trong"
///   feature `reservation` để dễ đọc (call site ngắn hơn).
/// - API surface ổn định — page call code cũ (`ReservationCard(reservation: r, onTap: ...)`)
///   không cần sửa.
class ReservationCard extends StatelessWidget {
  final ReservationEntity reservation;
  final VoidCallback? onTap;

  const ReservationCard({
    super.key,
    required this.reservation,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LobbyCardBase(
      item: lobbyItemFromReservation(reservation),
      onTap: onTap,
    );
  }
}
