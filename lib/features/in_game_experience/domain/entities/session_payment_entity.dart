/// Session payment result entity
class SessionPaymentResultEntity {
  final bool success;
  final String message;
  final InvoiceEntity invoice;
  final int bvcDeducted;
  final int remainingBvcBalance;
  final String paymentMethod;

  const SessionPaymentResultEntity({
    required this.success,
    required this.message,
    required this.invoice,
    required this.bvcDeducted,
    required this.remainingBvcBalance,
    required this.paymentMethod,
  });

  /// Format deducted amount as BVC
  String get formattedBvcDeducted => '$bvcDeducted BVC';

  /// Format remaining balance as BVC
  String get formattedRemainingBalance => '$remainingBvcBalance BVC';
}

/// Invoice entity
class InvoiceEntity {
  final String sessionId;
  final int totalMinutes;
  final int subtotal;
  final int penaltyAmount;
  final int depositApplied;
  final int totalDue;
  final String currency;
  final List<InvoiceLineItemEntity> lineItems;

  const InvoiceEntity({
    required this.sessionId,
    required this.totalMinutes,
    required this.subtotal,
    required this.penaltyAmount,
    required this.depositApplied,
    required this.totalDue,
    required this.currency,
    required this.lineItems,
  });

  /// Format total due as display string
  String get formattedTotalDue {
    return '${(totalDue / 1000).toStringAsFixed(0)} BVC';
  }

  /// Check if there's penalty
  bool get hasPenalty => penaltyAmount > 0;

  /// Check if deposit was applied
  bool get hasDepositApplied => depositApplied > 0;

  /// Format penalty as display string
  String get formattedPenalty {
    return '${(penaltyAmount / 1000).toStringAsFixed(0)} BVC';
  }

  /// Format deposit applied as display string
  String get formattedDepositApplied {
    return '${(depositApplied / 1000).toStringAsFixed(0)} BVC';
  }

  /// Format duration
  String get formattedDuration {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}p';
    }
    return '${minutes}p';
  }
}

/// Invoice line item entity
class InvoiceLineItemEntity {
  final String type;
  final String description;
  final int minutes;
  final int ratePerMinute;
  final int amount;

  const InvoiceLineItemEntity({
    required this.type,
    required this.description,
    required this.minutes,
    required this.ratePerMinute,
    required this.amount,
  });

  /// Format amount as BVC
  String get formattedAmount => '${(amount / 1000).toStringAsFixed(0)} BVC';

  /// Format rate per minute
  String get formattedRatePerMinute => '${(ratePerMinute / 1000).toStringAsFixed(0)} BVC/p';

  /// Format duration
  String get formattedDuration {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) {
      return '${hours}h ${mins}p';
    }
    return '${mins}p';
  }

  /// Check if this is a base hourly item
  bool get isBaseHourly => type == 'BaseHourly';

  /// Check if this is a penalty item
  bool get isPenalty => type == 'Penalty';
}
