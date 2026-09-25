import '../../domain/entities/member_payment_info.dart';

/// Model for MemberPaymentInfo from API
/// Represents payment status of a member in split bill flow
class MemberPaymentInfoModel {
  final String memberId;
  final String? displayName;
  final String? avatarUrl;
  final PaymentStatus paymentStatus;
  final PaymentMethod? paymentMethod;
  final int? amountDue;
  final String? qrUrl;
  final String? qrImageBase64;
  final DateTime? paidAt;
  final bool isCurrentUser;

  const MemberPaymentInfoModel({
    required this.memberId,
    this.displayName,
    this.avatarUrl,
    required this.paymentStatus,
    this.paymentMethod,
    this.amountDue,
    this.qrUrl,
    this.qrImageBase64,
    this.paidAt,
    this.isCurrentUser = false,
  });

  factory MemberPaymentInfoModel.fromJson(Map<String, dynamic> json) {
    return MemberPaymentInfoModel(
      memberId: json['memberId'] as String,
      displayName: json['displayName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      paymentStatus: _parsePaymentStatus(json['paymentStatus'] as String?),
      paymentMethod: _parsePaymentMethod(json['paymentMethod'] as String?),
      amountDue: (json['amountDue'] as num?)?.toInt(),
      qrUrl: json['qrUrl'] as String?,
      qrImageBase64: json['qrImageBase64'] as String?,
      paidAt: json['paidAt'] != null
          ? DateTime.parse(json['paidAt'] as String)
          : null,
      isCurrentUser: json['isCurrentUser'] as bool? ?? false,
    );
  }

  static PaymentStatus _parsePaymentStatus(String? value) {
    if (value == null) return PaymentStatus.notPaid;
    switch (value.toLowerCase()) {
      case 'paidcash':
      case 'paid_cash':
        return PaymentStatus.paidCash;
      case 'paidqr':
      case 'paid_qr':
        return PaymentStatus.paidQr;
      case 'notpaid':
      case 'not_paid':
      case 'pending':
        return PaymentStatus.notPaid;
      default:
        return PaymentStatus.notPaid;
    }
  }

  static PaymentMethod? _parsePaymentMethod(String? value) {
    if (value == null) return null;
    switch (value.toLowerCase()) {
      case 'cash':
        return PaymentMethod.cash;
      case 'qr_code':
      case 'qrcode':
      case 'qr':
        return PaymentMethod.qrCode;
      default:
        return null;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'memberId': memberId,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'paymentStatus': paymentStatus.name,
      'paymentMethod': paymentMethod?.name,
      'amountDue': amountDue,
      'qrUrl': qrUrl,
      'qrImageBase64': qrImageBase64,
      'paidAt': paidAt?.toIso8601String(),
      'isCurrentUser': isCurrentUser,
    };
  }

  MemberPaymentInfo toEntity() => MemberPaymentInfo(
        memberId: memberId,
        displayName: displayName,
        avatarUrl: avatarUrl,
        paymentStatus: paymentStatus,
        paymentMethod: paymentMethod,
        amountDue: amountDue,
        qrUrl: qrUrl,
        qrImageBase64: qrImageBase64,
        paidAt: paidAt,
        isCurrentUser: isCurrentUser,
      );

  /// Check if this member has paid
  bool get isPaid =>
      paymentStatus == PaymentStatus.paidCash ||
      paymentStatus == PaymentStatus.paidQr;
}

/// Model for Split Bill session response from API
class SplitBillSessionModel {
  final String sessionId;
  final String cafeId;
  final String? lobbyId;
  final String? cafeName;
  final String? gameName;
  final SessionSplitStatus sessionStatus;
  final List<MemberPaymentInfoModel> members;
  final DateTime? lastUpdated;

  const SplitBillSessionModel({
    required this.sessionId,
    required this.cafeId,
    this.lobbyId,
    this.cafeName,
    this.gameName,
    required this.sessionStatus,
    required this.members,
    this.lastUpdated,
  });

  factory SplitBillSessionModel.fromJson(Map<String, dynamic> json) {
    return SplitBillSessionModel(
      sessionId: json['sessionId'] as String,
      cafeId: json['cafeId'] as String? ?? '',
      lobbyId: json['lobbyId'] as String?,
      cafeName: json['cafeName'] as String?,
      gameName: json['gameName'] as String?,
      sessionStatus: _parseSessionStatus(json['sessionStatus'] as String?),
      members: (json['members'] as List<dynamic>?)
              ?.map((e) =>
                  MemberPaymentInfoModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'] as String)
          : null,
    );
  }

  static SessionSplitStatus _parseSessionStatus(String? value) {
    if (value == null) return SessionSplitStatus.unknown;
    switch (value.toLowerCase()) {
      case 'active':
        return SessionSplitStatus.active;
      case 'unpaid':
        return SessionSplitStatus.unpaid;
      case 'pending':
        return SessionSplitStatus.pending;
      case 'paid':
        return SessionSplitStatus.paid;
      case 'closed':
        return SessionSplitStatus.closed;
      default:
        return SessionSplitStatus.unknown;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'cafeId': cafeId,
      'lobbyId': lobbyId,
      'cafeName': cafeName,
      'gameName': gameName,
      'sessionStatus': sessionStatus.name,
      'members': members.map((e) => e.toJson()).toList(),
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }

  /// Get current user's payment info
  MemberPaymentInfoModel? get currentUserMember {
    try {
      return members.firstWhere((m) => m.isCurrentUser);
    } catch (_) {
      return null;
    }
  }

  /// Get count of paid members
  int get paidMembersCount =>
      members.where((m) => m.isPaid).length;

  /// Get count of pending members
  int get pendingMembersCount =>
      members.where((m) => !m.isPaid).length;

  /// True nếu tất cả thành viên đã thanh toán.
  bool get allPaid =>
      members.isNotEmpty && pendingMembersCount == 0;

  /// Tổng tiền cả nhóm (sum amountDue của tất cả members).
  /// Dùng để hiển thị progress "X / Y VNĐ đã thanh toán".
  int get totalGroupAmountVnd => members.fold<int>(
        0,
        (sum, m) => sum + (m.amountDue ?? 0),
      );

  /// Số tiền đã được thanh toán trong group.
  int get paidAmountVnd => members.fold<int>(
        0,
        (sum, m) => sum + (m.isPaid ? (m.amountDue ?? 0) : 0),
      );
}

/// Session split status enum.
///
/// Theo docs swagger, session status từ `GetCurrentSessionResponseDto`
/// (`Active | Checking | Unpaid | Paid | Closed`) là enum `GroupSessionStatus`.
/// Split bill endpoint trả thêm `sessionStatus` ở root — ta map
/// 1-1 để UI dùng chung.
///
/// Khi split bill chưa khả dụng hoặc backend chưa trả → `unknown`.
enum SessionSplitStatus {
  unknown,
  active,
  unpaid,
  pending,
  paid,
  closed,
}
