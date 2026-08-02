import '../../domain/entities/cafe_table_entity.dart';

/// JSON mapper cho một bàn trống từ `GET /api/cafes/{cafeId}/available-tables`.
class CafeTableModel {
  final String id;
  final String name;
  final int seatCount;
  final bool isAvailable;
  final double? pricePerHour;

  const CafeTableModel({
    required this.id,
    required this.name,
    required this.seatCount,
    required this.isAvailable,
    this.pricePerHour,
  });

  factory CafeTableModel.fromJson(Map<String, dynamic> json) {
    return CafeTableModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      seatCount: (json['seatCount'] as num?)?.toInt() ?? 0,
      isAvailable: json['isAvailable'] as bool? ?? true,
      pricePerHour: (json['pricePerHour'] as num?)?.toDouble(),
    );
  }

  CafeTableEntity toEntity() => CafeTableEntity(
        id: id,
        name: name,
        seatCount: seatCount,
        isAvailable: isAvailable,
        pricePerHour: pricePerHour,
      );
}
