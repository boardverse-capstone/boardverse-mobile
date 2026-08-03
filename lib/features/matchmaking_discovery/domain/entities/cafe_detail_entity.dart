import 'package:equatable/equatable.dart';

/// Billing model của quán.
enum BillingModel {
  timeBased,
  fixed,
  tiered,
}

/// Entity cho trang chi tiết quán cafe (GET /api/cafes/{id}).
class CafeDetailEntity extends Equatable {
  final String id;
  final String name;
  final String address;
  final String? imageUrl;
  final String? description;
  final String? phoneNumber;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;

  // ─── Pricing ────────────────────────────────────────────────────────
  final BillingModel billingModel;
  final double basePrice; // VNĐ per session or per hour
  final int? tieredBlockMinutes; // Số phút mỗi block (cho tiered)
  final double? depositPercentage; // % tiền cọc (0.5 = 50%)
  final bool isPricingLocked;
  final bool hasSePayConfigured;

  // ─── Capacity ──────────────────────────────────────────────────────
  final int? totalSeats;

  const CafeDetailEntity({
    required this.id,
    required this.name,
    required this.address,
    this.imageUrl,
    this.description,
    this.phoneNumber,
    this.latitude,
    this.longitude,
    required this.createdAt,
    // Pricing
    required this.billingModel,
    required this.basePrice,
    this.tieredBlockMinutes,
    this.depositPercentage,
    this.isPricingLocked = false,
    this.hasSePayConfigured = false,
    // Capacity
    this.totalSeats,
  });

  /// Format giá cơ bản theo billing model.
  String get priceDisplay {
    switch (billingModel) {
      case BillingModel.timeBased:
        return '${_formatPrice(basePrice)}/giờ';
      case BillingModel.fixed:
        return '${_formatPrice(basePrice)}/lượt';
      case BillingModel.tiered:
        return '${_formatPrice(basePrice)}/${tieredBlockMinutes ?? 15}ph';
    }
  }

  /// Format tiền cọc.
  String get depositDisplay {
    if (depositPercentage == null) return 'Không cọc';
    return '${(depositPercentage! * 100).toStringAsFixed(0)}% cọc';
  }

  String _formatPrice(double price) {
    if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}k';
    }
    return price.toStringAsFixed(0);
  }

  @override
  List<Object?> get props => [
        id,
        name,
        address,
        imageUrl,
        description,
        phoneNumber,
        latitude,
        longitude,
        createdAt,
        billingModel,
        basePrice,
        tieredBlockMinutes,
        depositPercentage,
        isPricingLocked,
        hasSePayConfigured,
        totalSeats,
      ];
}
