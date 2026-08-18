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
      tieredBlockMinutes: _parseInt(json['tieredBlockMinutes']),
      isPricingLocked: json['isPricingLocked'] as bool? ?? false,
      hasSePayConfigured: json['hasSePayConfigured'] as bool? ?? false,
      // Capacity
      totalSeats: _parseInt(json['totalSeats']),
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
      depositRatePerPerson: _parseInt(json['depositRatePerPerson']) ?? 0,
      minDeposit: _parseInt(json['minDeposit']),
      // Capacity (live)
      availableSeats: _parseInt(json['availableSeats']) ?? 0,
      heldSeats: _parseInt(json['heldSeats']) ?? 0,
      inUseSeats: _parseInt(json['inUseSeats']) ?? 0,
      availableSeatsByTimeSlot: _parseTimeSlots(
          json['availableSeatsByTimeSlot'] as Map<String, dynamic>?),
      // Config
      cafeConfig: _parseCafeConfig(json['cafeConfig'] as Map<String, dynamic>?),
      // Schedule
      scheduleOverrides:
          (json['scheduleOverrides'] as List?)?.cast<String>() ?? const [],
      // Amenities
      numberOfTables: _parseInt(json['numberOfTables']) ?? 0,
      numberOfPrivateRooms: _parseInt(json['numberOfPrivateRooms']) ?? 0,
      numberOfGamesOwned: _parseInt(json['numberOfGamesOwned']) ?? 0,
      hasGameMaster: json['hasGameMaster'] as bool? ?? false,
      // Distance
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
    );
  }

  /// Safely parse an int from any JSON value, returning null if the value
  /// is not a valid int (e.g., a Map, List, or unexpected type).
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    // Handle case where backend returns a Map instead of int (API mismatch)
    if (value is Map) return null;
    if (value is List) return null;
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
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
            minHoursBeforeScheduled: _parseInt(m['minHoursBeforeScheduled']) ?? 0,
            refundPercent: _parseInt(m['refundPercent']) ?? 0,
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
      capacity: _parseInt(raw['capacity']) ?? 0,
      maxLobbiesPerUserPerDay:
          _parseInt(raw['maxLobbiesPerUserPerDay']) ?? 1,
      maxPlayersPerLobbySameDay:
          _parseInt(raw['maxPlayersPerLobbySameDay']) ?? 0,
      maxPlayersPerLobby1Day: _parseInt(raw['maxPlayersPerLobby1Day']) ?? 0,
      maxPlayersPerLobby2Days:
          _parseInt(raw['maxPlayersPerLobby2Days']) ?? 0,
      maxPlayersPerLobby3To4Days:
          _parseInt(raw['maxPlayersPerLobby3To4Days']) ?? 0,
      maxPlayersPerLobby5To7Days:
          _parseInt(raw['maxPlayersPerLobby5To7Days']) ?? 0,
      requireApprovalForDistant:
          raw['requireApprovalForDistant'] as bool? ?? false,
      distantThresholdDays: _parseInt(raw['distantThresholdDays']) ?? 0,
      approvalTimeoutHours: _parseInt(raw['approvalTimeoutHours']) ?? 0,
      maxTotalDepositPerUser:
          _parseInt(raw['maxTotalDepositPerUser']) ?? 0,
      recruitmentDeadlineBufferMinutes:
          _parseInt(raw['recruitmentDeadlineBufferMinutes']) ?? 0,
      cancellationGraceMinutes:
          _parseInt(raw['cancellationGraceMinutes']) ?? 0,
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
