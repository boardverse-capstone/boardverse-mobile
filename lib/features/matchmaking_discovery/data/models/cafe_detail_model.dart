import '../../domain/entities/cafe_detail_entity.dart';

/// Model cho response `GET /api/cafes/{id}` — đầy đủ thông tin quán.
///
/// Tách riêng khỏi [CafeModel] vì response của detail endpoint có nhiều
/// field hơn (operationalStatus, refundPolicy, cafeConfig, scheduleOverrides,
/// seat availability theo time-slot, v.v.) — không phù hợp với model dùng
/// cho nearby search.
class CafeDetailModel {
  final String id;
  final String name;
  final String address;
  final String? imageUrl;
  final String? description;
  final String? phoneNumber;
  final double? latitude;
  final double? longitude;
  final DateTime? createdAt;

  // Pricing
  final BillingModel billingModel;
  final double basePrice;
  final int? tieredBlockMinutes;
  final bool isPricingLocked;
  final bool hasSePayConfigured;

  // Capacity (basic)
  final int? totalSeats;

  // Operational Status
  final CafeOperationalStatus operationalStatus;
  final String? operationalStatusReason;
  final bool isCurrentlyOpen;

  // Refund Policy
  final RefundPolicy refundPolicy;
  final List<RefundTierEntity> refundTiers;

  // Deposit
  final double depositPercentage;
  final int depositRatePerPerson;
  final int? minDeposit;

  // Capacity (live)
  final int availableSeats;
  final int heldSeats;
  final int inUseSeats;
  final Map<TimeSlot, int> availableSeatsByTimeSlot;

  // Config
  final CafeConfigEntity? cafeConfig;

  // Schedule
  final List<String> scheduleOverrides;

  // Amenities
  final int numberOfTables;
  final int numberOfPrivateRooms;
  final int numberOfGamesOwned;
  final bool hasGameMaster;

  // Distance
  final double? distanceKm;

  const CafeDetailModel({
    required this.id,
    required this.name,
    required this.address,
    this.imageUrl,
    this.description,
    this.phoneNumber,
    this.latitude,
    this.longitude,
    this.createdAt,
    required this.billingModel,
    required this.basePrice,
    this.tieredBlockMinutes,
    this.isPricingLocked = false,
    this.hasSePayConfigured = false,
    this.totalSeats,
    this.operationalStatus = CafeOperationalStatus.active,
    this.operationalStatusReason,
    this.isCurrentlyOpen = true,
    this.refundPolicy = RefundPolicy.none,
    this.refundTiers = const [],
    this.depositPercentage = 0.0,
    this.depositRatePerPerson = 0,
    this.minDeposit,
    this.availableSeats = 0,
    this.heldSeats = 0,
    this.inUseSeats = 0,
    this.availableSeatsByTimeSlot = const {},
    this.cafeConfig,
    this.scheduleOverrides = const [],
    this.numberOfTables = 0,
    this.numberOfPrivateRooms = 0,
    this.numberOfGamesOwned = 0,
    this.hasGameMaster = false,
    this.distanceKm,
  });

  /// Parse từ `GET /api/cafes/{id}` response.
  factory CafeDetailModel.fromJson(Map<String, dynamic> json) {
    return CafeDetailModel(
      id: json['id'] as String,
      name: json['name'] as String,
      address: (json['address'] as String?) ?? '',
      imageUrl: json['imageUrl'] as String?,
      description: json['description'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      // Pricing
      billingModel: _parseBillingModel(json['billingModel'] as String?),
      basePrice: ((json['basePrice'] as num?) ?? 0).toDouble(),
      tieredBlockMinutes: json['tieredBlockMinutes'] as int?,
      isPricingLocked: json['isPricingLocked'] as bool? ?? false,
      hasSePayConfigured: json['hasSePayConfigured'] as bool? ?? false,
      // Capacity
      totalSeats: json['totalSeats'] as int?,
      // Operational
      operationalStatus: _parseOperationalStatus(
          json['operationalStatus'] as String?),
      operationalStatusReason: json['operationalStatusReason'] as String?,
      isCurrentlyOpen: json['isCurrentlyOpen'] as bool? ?? true,
      // Refund
      refundPolicy: _parseRefundPolicy(json['refundPolicy'] as String?),
      refundTiers: _parseRefundTiers(json['refundTiers'] as List?),
      // Deposit
      depositPercentage:
          ((json['depositPercentage'] as num?) ?? 0).toDouble(),
      depositRatePerPerson: (json['depositRatePerPerson'] as int?) ?? 0,
      minDeposit: json['minDeposit'] as int?,
      // Capacity (live)
      availableSeats: (json['availableSeats'] as int?) ?? 0,
      heldSeats: (json['heldSeats'] as int?) ?? 0,
      inUseSeats: (json['inUseSeats'] as int?) ?? 0,
      availableSeatsByTimeSlot: _parseTimeSlots(
          json['availableSeatsByTimeSlot'] as Map<String, dynamic>?),
      // Config
      cafeConfig: _parseCafeConfig(json['cafeConfig'] as Map<String, dynamic>?),
      // Schedule
      scheduleOverrides:
          (json['scheduleOverrides'] as List?)?.cast<String>() ?? const [],
      // Amenities
      numberOfTables: (json['numberOfTables'] as int?) ?? 0,
      numberOfPrivateRooms: (json['numberOfPrivateRooms'] as int?) ?? 0,
      numberOfGamesOwned: (json['numberOfGamesOwned'] as int?) ?? 0,
      hasGameMaster: json['hasGameMaster'] as bool? ?? false,
      // Distance
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
    );
  }

  static BillingModel _parseBillingModel(String? raw) {
    switch (raw) {
      case 'FIXED':
        return BillingModel.fixed;
      case 'TIERED':
        return BillingModel.tiered;
      case 'TIME_BASED':
      default:
        return BillingModel.timeBased;
    }
  }

  static CafeOperationalStatus _parseOperationalStatus(String? raw) {
    switch (raw?.toUpperCase()) {
      case 'INACTIVE':
        return CafeOperationalStatus.inactive;
      case 'SUSPENDED':
        return CafeOperationalStatus.suspended;
      case 'ACTIVE':
      default:
        return CafeOperationalStatus.active;
    }
  }

  static RefundPolicy _parseRefundPolicy(String? raw) {
    switch (raw?.toLowerCase()) {
      case 'full':
        return RefundPolicy.full;
      case 'partial':
        return RefundPolicy.partial;
      case 'none':
      default:
        return RefundPolicy.none;
    }
  }

  static List<RefundTierEntity> _parseRefundTiers(List? raw) {
    if (raw == null) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(
          (m) => RefundTierEntity(
            minHoursBeforeScheduled:
                (m['minHoursBeforeScheduled'] as int?) ?? 0,
            refundPercent: (m['refundPercent'] as int?) ?? 0,
          ),
        )
        .toList();
  }

  static Map<TimeSlot, int> _parseTimeSlots(Map<String, dynamic>? raw) {
    if (raw == null) return const {};
    final result = <TimeSlot, int>{};
    for (final slot in TimeSlot.values) {
      final v = raw[slot.apiKey];
      if (v is int) result[slot] = v;
    }
    return result;
  }

  static CafeConfigEntity? _parseCafeConfig(Map<String, dynamic>? raw) {
    if (raw == null) return null;
    return CafeConfigEntity(
      capacity: (raw['capacity'] as int?) ?? 0,
      maxLobbiesPerUserPerDay:
          (raw['maxLobbiesPerUserPerDay'] as int?) ?? 1,
      maxPlayersPerLobbySameDay:
          (raw['maxPlayersPerLobbySameDay'] as int?) ?? 0,
      maxPlayersPerLobby1Day: (raw['maxPlayersPerLobby1Day'] as int?) ?? 0,
      maxPlayersPerLobby2Days:
          (raw['maxPlayersPerLobby2Days'] as int?) ?? 0,
      maxPlayersPerLobby3To4Days:
          (raw['maxPlayersPerLobby3To4Days'] as int?) ?? 0,
      maxPlayersPerLobby5To7Days:
          (raw['maxPlayersPerLobby5To7Days'] as int?) ?? 0,
      requireApprovalForDistant:
          raw['requireApprovalForDistant'] as bool? ?? false,
      distantThresholdDays: (raw['distantThresholdDays'] as int?) ?? 0,
      approvalTimeoutHours: (raw['approvalTimeoutHours'] as int?) ?? 0,
      maxTotalDepositPerUser:
          (raw['maxTotalDepositPerUser'] as int?) ?? 0,
      recruitmentDeadlineBufferMinutes:
          (raw['recruitmentDeadlineBufferMinutes'] as int?) ?? 0,
      cancellationGraceMinutes:
          (raw['cancellationGraceMinutes'] as int?) ?? 0,
    );
  }

  CafeDetailEntity toEntity() => CafeDetailEntity(
        id: id,
        name: name,
        address: address,
        imageUrl: imageUrl,
        description: description,
        phoneNumber: phoneNumber,
        latitude: latitude,
        longitude: longitude,
        createdAt: createdAt ?? DateTime.now(),
        // Pricing
        billingModel: billingModel,
        basePrice: basePrice,
        tieredBlockMinutes: tieredBlockMinutes,
        isPricingLocked: isPricingLocked,
        hasSePayConfigured: hasSePayConfigured,
        // Capacity
        totalSeats: totalSeats,
        // Operational
        operationalStatus: operationalStatus,
        operationalStatusReason: operationalStatusReason,
        isCurrentlyOpen: isCurrentlyOpen,
        // Refund
        refundPolicy: refundPolicy,
        refundTiers: refundTiers,
        // Deposit
        depositPercentage: depositPercentage,
        depositRatePerPerson: depositRatePerPerson,
        minDeposit: minDeposit,
        // Capacity (live)
        availableSeats: availableSeats,
        heldSeats: heldSeats,
        inUseSeats: inUseSeats,
        availableSeatsByTimeSlot: availableSeatsByTimeSlot,
        // Config
        cafeConfig: cafeConfig,
        // Schedule
        scheduleOverrides: scheduleOverrides,
        // Amenities
        numberOfTables: numberOfTables,
        numberOfPrivateRooms: numberOfPrivateRooms,
        numberOfGamesOwned: numberOfGamesOwned,
        hasGameMaster: hasGameMaster,
        // Distance
        distanceKm: distanceKm,
      );
}
