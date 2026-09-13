/// Cost estimate entity for session pricing
class CostEstimateEntity {
  final int baseMinutes;
  final int subtotal;
  final int penaltyAmount;
  final int depositApplied;
  final int totalDue;
  final String currency;

  const CostEstimateEntity({
    required this.baseMinutes,
    required this.subtotal,
    required this.penaltyAmount,
    required this.depositApplied,
    required this.totalDue,
    required this.currency,
  });

  /// Format total due as display string. Dùng `ceil` để luôn hiển
  /// thị số BVC TỐI THIỂU cần có — vd: 12.500 VND = 12.5 BVC → hiển
  /// thị "13 BVC". Tránh trường hợp player thấy "12 BVC" rồi bấm thanh
  /// toán nhưng ví chỉ có 12 BVC → backend reject 402 Insufficient BVC.
  String get formattedTotalDue {
    final bvc = (totalDue / 1000).ceil();
    return '$bvc BVC';
  }

  /// Format subtotal as display string. Dùng `ceil` để hiển thị
  /// số BVC tối thiểu tương ứng.
  String get formattedSubtotal {
    final bvc = (subtotal / 1000).ceil();
    return '$bvc BVC';
  }

  /// Format penalty as display string.
  String get formattedPenalty {
    final bvc = (penaltyAmount / 1000).ceil();
    return '$bvc BVC';
  }

  /// Format deposit applied as display string.
  String get formattedDepositApplied {
    final bvc = (depositApplied / 1000).ceil();
    return '$bvc BVC';
  }

  /// Check if there's penalty
  bool get hasPenalty => penaltyAmount > 0;

  /// Check if deposit was applied
  bool get hasDepositApplied => depositApplied > 0;

  /// Get estimated cost per minute (in VND)
  double get ratePerMinute {
    if (baseMinutes <= 0) return 0;
    return subtotal / baseMinutes;
  }

  CostEstimateEntity copyWith({
    int? baseMinutes,
    int? subtotal,
    int? penaltyAmount,
    int? depositApplied,
    int? totalDue,
    String? currency,
  }) {
    return CostEstimateEntity(
      baseMinutes: baseMinutes ?? this.baseMinutes,
      subtotal: subtotal ?? this.subtotal,
      penaltyAmount: penaltyAmount ?? this.penaltyAmount,
      depositApplied: depositApplied ?? this.depositApplied,
      totalDue: totalDue ?? this.totalDue,
      currency: currency ?? this.currency,
    );
  }
}
