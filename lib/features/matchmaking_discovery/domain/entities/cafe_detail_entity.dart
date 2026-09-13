import 'package:equatable/equatable.dart';

/// Billing model của quán.
enum BillingModel {
  timeBased,
  fixed,
  tiered,
}

/// Trạng thái hoạt động của quán — map từ `operationalStatus` trong response.
enum CafeOperationalStatus {
  active,
  inactive,
  suspended,
}

/// Chính sách hoàn tiền — map từ `refundPolicy` trong response.
enum RefundPolicy {
  /// Hoàn 100%.
  full,

  /// Hoàn theo bậc (refundTiers).
  partial,

  /// Không hoàn.
  none,
}

/// Một bậc hoàn tiền theo số giờ trước giờ đã đặt.
///
/// Backend `refundTiers[]` chỉ chứa `minHoursBeforeScheduled` và
/// `refundPercent` — UI sẽ hiển thị dạng "Hủy trước X giờ → hoàn Y%".
class RefundTierEntity extends Equatable {
  final int minHoursBeforeScheduled;
  final int refundPercent;

  const RefundTierEntity({
    required this.minHoursBeforeScheduled,
    required this.refundPercent,
  });

  String get displayLabel {
    final pct = refundPercent;
    if (minHoursBeforeScheduled <= 0) {
      return 'Hủy trong ngày: hoàn $pct%';
    }
    return 'Hủy trước ${minHoursBeforeScheduled}h: hoàn $pct%';
  }

  @override
  List<Object?> get props => [minHoursBeforeScheduled, refundPercent];
}

/// Cấu hình lobby/booking của quán — map từ `cafeConfig` trong response.
class CafeConfigEntity extends Equatable {
  /// Sức chứa (capacity) của quán — mirror `totalSeats` ở level cha.
  final int capacity;

  /// Số lobby tối đa mỗi user có thể tạo trong ngày.
  final int maxLobbiesPerUserPerDay;

  /// Số player tối đa trong lobby tạo cùng ngày (same day).
  final int maxPlayersPerLobbySameDay;

  /// Số player tối đa trong lobby tạo trước 1 ngày.
  final int maxPlayersPerLobby1Day;

  /// Số player tối đa trong lobby tạo trước 2 ngày.
  final int maxPlayersPerLobby2Days;

  /// Số player tối đa trong lobby tạo trước 3-4 ngày.
  final int maxPlayersPerLobby3To4Days;

  /// Số player tối đa trong lobby tạo trước 5-7 ngày.
  final int maxPlayersPerLobby5To7Days;

  /// Có yêu cầu approve khi player đăng ký xa (xem `distantThresholdDays`) không.
  final bool requireApprovalForDistant;

  /// Ngưỡng "xa" tính theo ngày — đăng ký trước > threshold sẽ cần approve.
  final int distantThresholdDays;

  /// Timeout (giờ) cho approval — quá thời gian sẽ auto-reject.
  final int approvalTimeoutHours;

  /// Tổng deposit tối đa mỗi user có thể giữ (VNĐ).
  final int maxTotalDepositPerUser;

  /// Buffer (phút) cho recruitment deadline — host set deadline cộng thêm
  /// số phút này để tránh deadline quá sát giờ chơi.
  final int recruitmentDeadlineBufferMinutes;

  /// Grace period (phút) cho phép hủy sau khi tạo lobby.
  final int cancellationGraceMinutes;

  const CafeConfigEntity({
    required this.capacity,
    required this.maxLobbiesPerUserPerDay,
    required this.maxPlayersPerLobbySameDay,
    required this.maxPlayersPerLobby1Day,
    required this.maxPlayersPerLobby2Days,
    required this.maxPlayersPerLobby3To4Days,
    required this.maxPlayersPerLobby5To7Days,
    required this.requireApprovalForDistant,
    required this.distantThresholdDays,
    required this.approvalTimeoutHours,
    required this.maxTotalDepositPerUser,
    required this.recruitmentDeadlineBufferMinutes,
    required this.cancellationGraceMinutes,
  });

  /// Helper: lấy maxPlayers theo số ngày trước giờ chơi.
  /// Dùng cho UI hiển thị "Đặt trư�c X ngày → tối đa Y người".
  int? maxPlayersForDaysAhead(int daysAhead) {
    if (daysAhead <= 0) return maxPlayersPerLobbySameDay;
    if (daysAhead == 1) return maxPlayersPerLobby1Day;
    if (daysAhead == 2) return maxPlayersPerLobby2Days;
    if (daysAhead <= 4) return maxPlayersPerLobby3To4Days;
    if (daysAhead <= 7) return maxPlayersPerLobby5To7Days;
    return null;
  }

  @override
  List<Object?> get props => [
        capacity,
        maxLobbiesPerUserPerDay,
        maxPlayersPerLobbySameDay,
        maxPlayersPerLobby1Day,
        maxPlayersPerLobby2Days,
        maxPlayersPerLobby3To4Days,
        maxPlayersPerLobby5To7Days,
        requireApprovalForDistant,
        distantThresholdDays,
        approvalTimeoutHours,
        maxTotalDepositPerUser,
        recruitmentDeadlineBufferMinutes,
        cancellationGraceMinutes,
      ];
}

/// Khung giờ trong ngày — dùng bởi `availableSeatsByTimeSlot` (key thô)
/// của API response và `TimeSlotGrid` (UI).
///
/// BR-NEW-15 (2026-08-18): schema `GET /cafes/{id}` response dùng
/// `additionalProperties: integer` (swagger.json line 26737), không pin
/// enum — keys có thể là `"Morning"`/`"Afternoon"`/`"Evening"`/`"LateNight"`
/// hoặc custom override của manager. Cafe dùng chuẩn này xem
/// `TimeSlotKey.fromApiName`.
///
/// Lưu ý: enum này tồn tại riêng cho cafe_detail — KHÔNG chia sẻ với
/// `reservation_entity.dart`'s `TimeSlot` (sẽ bị bỏ ở scope sau) cũng
/// như `matchmaking_discovery/.../default_time_slot_entity.dart`'s
/// `TimeSlotKey` (server-facing).
@Deprecated('Use TimeSlotKey.fromApiName + Map<String,int> raw keys instead.')
enum TimeSlot {
  morning, // "Morning"
  afternoon, // "Afternoon"
  evening, // "Evening"
  lateNight, // "LateNight"
}

extension TimeSlotX on TimeSlot {
  String get apiKey {
    switch (this) {
      case TimeSlot.morning:
        return 'Morning';
      case TimeSlot.afternoon:
        return 'Afternoon';
      case TimeSlot.evening:
        return 'Evening';
      case TimeSlot.lateNight:
        return 'LateNight';
    }
  }

  String get displayLabel {
    switch (this) {
      case TimeSlot.morning:
        return 'Sáng';
      case TimeSlot.afternoon:
        return 'Chiều';
      case TimeSlot.evening:
        return 'Tối';
      case TimeSlot.lateNight:
        return 'Khuya';
    }
  }
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
  final double basePrice; // VN� per session or per hour
  final int? tieredBlockMinutes; // Số phút mỗi block (cho tiered)
  final bool isPricingLocked;
  final bool hasSePayConfigured;

  // ─── Capacity (basic) ───────────────────────────────────────────────
  final int? totalSeats;

  // ─── Operational Status ─────────────────────────────────────────────
  final CafeOperationalStatus operationalStatus;
  final String? operationalStatusReason;
  final bool isCurrentlyOpen;

  // ─── Refund Policy ──────────────────────────────────────────────────
  final RefundPolicy refundPolicy;
  final List<RefundTierEntity> refundTiers;

  // ─── Deposit ────────────────────────────────────────────────────────
  /// T� lệ cọc (0.0–1.0) trên tổng hoá đơn.
  final double depositPercentage;

  /// Tỷ lệ cọc theo đầu người (%). Có thể khác `depositPercentage`.
  final int depositRatePerPerson;

  /// Cọc tối thiểu (VNĐ). Null = không có cọc tối thiểu.
  final int? minDeposit;

  // ─── Capacity (live) ────────────────────────────────────────────────
  /// Ghế trống khả dụng hiện tại (Available).
  final int availableSeats;

  /// Ghế đang giữ chỗ (Held).
  final int heldSeats;

  /// Ghế đang sử dụng (InUse).
  final int inUseSeats;

  /// Ghế trống theo khung giờ. BR-NEW-15: giờ là `Map<String, int>` raw từ
  /// server response thay vì `Map<TimeSlot, int>` — tránh phải sync enum
  /// mỗi khi BE thêm key mới (vd: manager override custom slot).
  /// UI bind qua `TimeSlotKey.fromApiName` (extension ở
  /// `default_time_slot_entity.dart`) để lấy icon/label chuẩn.
  final Map<String, int> availableSeatsByTimeSlot;

  // ─── Cafe Config ────────────────────────────────────────────────────
  final CafeConfigEntity? cafeConfig;

  // ─── Schedule Overrides (giờ mở/đóng override) ────────────────────
  final List<String> scheduleOverrides;

  // ─── Amenities ──────────────────────────────────────────────────────
  final int numberOfTables;
  final int numberOfPrivateRooms;
  final int numberOfGamesOwned;
  final bool hasGameMaster;

  // ─── Distance ───────────────────────────────────────────────────────
  /// Khoảng cách (km) t� vị trí hiện tại của user. Null nếu không có vị trí.
  final double? distanceKm;

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
    this.isPricingLocked = false,
    this.hasSePayConfigured = false,
    // Capacity (basic)
    this.totalSeats,
    // Operational
    this.operationalStatus = CafeOperationalStatus.active,
    this.operationalStatusReason,
    this.isCurrentlyOpen = true,
    // Refund
    this.refundPolicy = RefundPolicy.none,
    this.refundTiers = const [],
    // Deposit
    this.depositPercentage = 0.0,
    this.depositRatePerPerson = 0,
    this.minDeposit,
    // Capacity (live)
    this.availableSeats = 0,
    this.heldSeats = 0,
    this.inUseSeats = 0,
    this.availableSeatsByTimeSlot = const {},
    // Config
    this.cafeConfig,
    // Schedule
    this.scheduleOverrides = const [],
    // Amenities
    this.numberOfTables = 0,
    this.numberOfPrivateRooms = 0,
    this.numberOfGamesOwned = 0,
    this.hasGameMaster = false,
    // Distance
    this.distanceKm,
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

  String _formatPrice(double price) {
    if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}k';
    }
    return price.toStringAsFixed(0);
  }

  /// Tổng ghế "đã dùng" (held + inUse).
  int get occupiedSeats => heldSeats + inUseSeats;

  /// Phần trăm ghế đang trống (0–100).
  double get availableSeatPercent {
    final total = totalSeats ?? 0;
    if (total <= 0) return 0;
    return (availableSeats / total) * 100;
  }

  /// Format depositPercentage thành string "X%".
  String get depositPercentDisplay =>
      '${(depositPercentage * 100).toStringAsFixed(0)}%';

  /// Format tổng deposit tối đa (VNĐ → "Xk" hoặc "Xm").
  String get maxTotalDepositDisplay {
    final v = cafeConfig?.maxTotalDepositPerUser ?? 0;
    if (v >= 1000000) {
      return '${(v / 1000000).toStringAsFixed(1)}m';
    }
    if (v >= 1000) {
      return '${(v / 1000).toStringAsFixed(0)}k';
    }
    return v.toString();
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
        isPricingLocked,
        hasSePayConfigured,
        totalSeats,
        operationalStatus,
        operationalStatusReason,
        isCurrentlyOpen,
        refundPolicy,
        refundTiers,
        depositPercentage,
        depositRatePerPerson,
        minDeposit,
        availableSeats,
        heldSeats,
        inUseSeats,
        availableSeatsByTimeSlot,
        cafeConfig,
        scheduleOverrides,
        numberOfTables,
        numberOfPrivateRooms,
        numberOfGamesOwned,
        hasGameMaster,
        distanceKm,
      ];
}
