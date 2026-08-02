import 'package:equatable/equatable.dart';

/// Bàn tại quán có thể nhận booking trong khung giờ được yêu cầu.
class CafeTableEntity extends Equatable {
  final String id;
  final String name;
  final int seatCount;
  final bool isAvailable;
  final double? pricePerHour;

  const CafeTableEntity({
    required this.id,
    required this.name,
    required this.seatCount,
    required this.isAvailable,
    this.pricePerHour,
  });

  @override
  List<Object?> get props => [id, name, seatCount, isAvailable, pricePerHour];
}
