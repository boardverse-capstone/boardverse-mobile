import '../../domain/entities/booking_entity.dart';
import '../../domain/enums/booking_status.dart';
import '../../domain/enums/payment_method.dart';

/// JSON ↔ Entity cho `BookingEntity`.
///
/// Không dùng json_serializable để giữ dependency nhẹ cho phase này —
/// cấu trúc JSON tương đối đơn giản, parse thủ công dễ kiểm soát.
class BookingModel {
  final String id;
  final String cafeId;
  final String cafeName;
  final String gameId;
  final String gameName;
  final DateTime scheduledTime;
  final int seatCount;
  final List<String> memberIds;
  final String hostId;
  final String status;
  final double depositAmount;
  final DateTime depositDeadline;
  final String paymentMethod;
  final String? paymentRef;
  final String qrPayload;
  final String nonce;
  final bool nonceUsed;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BookingModel({
    required this.id,
    required this.cafeId,
    required this.cafeName,
    required this.gameId,
    required this.gameName,
    required this.scheduledTime,
    required this.seatCount,
    required this.memberIds,
    required this.hostId,
    required this.status,
    required this.depositAmount,
    required this.depositDeadline,
    required this.paymentMethod,
    this.paymentRef,
    required this.qrPayload,
    required this.nonce,
    this.nonceUsed = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] as String,
      cafeId: json['cafeId'] as String,
      cafeName: json['cafeName'] as String,
      gameId: json['gameId'] as String,
      gameName: json['gameName'] as String,
      scheduledTime: DateTime.parse(json['scheduledTime'] as String),
      seatCount: (json['seatCount'] as num).toInt(),
      memberIds: (json['memberIds'] as List).cast<String>(),
      hostId: json['hostId'] as String,
      status: json['status'] as String,
      depositAmount: (json['depositAmount'] as num).toDouble(),
      depositDeadline: DateTime.parse(json['depositDeadline'] as String),
      paymentMethod: json['paymentMethod'] as String,
      paymentRef: json['paymentRef'] as String?,
      qrPayload: json['qrPayload'] as String,
      nonce: json['nonce'] as String? ?? _generateNonce(),
      nonceUsed: json['nonceUsed'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  static String _generateNonce() {
    final now = DateTime.now();
    return '${now.millisecondsSinceEpoch}_${_randomHex(8)}';
  }

  static String _randomHex(int length) {
    const chars = '0123456789abcdef';
    final rand = DateTime.now().microsecond;
    return List.generate(length, (i) => chars[(rand + i * 7) % 16]).join();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'cafeId': cafeId,
        'cafeName': cafeName,
        'gameId': gameId,
        'gameName': gameName,
        'scheduledTime': scheduledTime.toIso8601String(),
        'seatCount': seatCount,
        'memberIds': memberIds,
        'hostId': hostId,
        'status': status,
        'depositAmount': depositAmount,
        'depositDeadline': depositDeadline.toIso8601String(),
        'paymentMethod': paymentMethod,
        'paymentRef': paymentRef,
        'qrPayload': qrPayload,
        'nonce': nonce,
        'nonceUsed': nonceUsed,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  BookingEntity toEntity() => BookingEntity(
        id: id,
        cafeId: cafeId,
        cafeName: cafeName,
        gameId: gameId,
        gameName: gameName,
        scheduledTime: scheduledTime,
        seatCount: seatCount,
        memberIds: memberIds,
        hostId: hostId,
        status: _statusFromString(status),
        depositAmount: depositAmount,
        depositDeadline: depositDeadline,
        paymentMethod: _methodFromString(paymentMethod),
        paymentRef: paymentRef,
        qrPayload: qrPayload,
        nonce: nonce,
        nonceUsed: nonceUsed,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  factory BookingModel.fromEntity(BookingEntity e) => BookingModel(
        id: e.id,
        cafeId: e.cafeId,
        cafeName: e.cafeName,
        gameId: e.gameId,
        gameName: e.gameName,
        scheduledTime: e.scheduledTime,
        seatCount: e.seatCount,
        memberIds: e.memberIds,
        hostId: e.hostId,
        status: e.status.name,
        depositAmount: e.depositAmount,
        depositDeadline: e.depositDeadline,
        paymentMethod: e.paymentMethod.name,
        paymentRef: e.paymentRef,
        qrPayload: e.qrPayload,
        nonce: e.nonce,
        nonceUsed: e.nonceUsed,
        createdAt: e.createdAt,
        updatedAt: e.updatedAt,
      );

  static BookingStatus _statusFromString(String s) =>
      BookingStatus.values.firstWhere(
        (e) => e.name == s,
        orElse: () => BookingStatus.pendingDeposit,
      );

  static PaymentMethod _methodFromString(String s) =>
      PaymentMethod.values.firstWhere(
        (e) => e.name == s,
        orElse: () => PaymentMethod.sandboxMock,
      );
}