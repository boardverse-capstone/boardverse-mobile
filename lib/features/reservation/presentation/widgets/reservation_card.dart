import 'package:flutter/material.dart';

import '../../domain/entities/reservation_entity.dart';
import 'reservation_card_neo.dart';

/// Adapter widget — `ReservationCard` → `ReservationCardNeo`.
///
/// Tại sao có wrapper:
/// - Caller cũ (`ReservationCard(reservation: r, onTap: ...)`) vẫn hoạt động
///   không cần sửa.
/// - Logic `isOwnedByMe` suy ra từ `reservation.isHost` — đỡ phải truyền từ
///   ngoài.
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
    return ReservationCardNeo(
      reservation: reservation,
      isOwnedByMe: reservation.isHost ?? false,
      onTap: onTap,
    );
  }
}
