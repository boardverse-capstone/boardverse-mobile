import 'package:equatable/equatable.dart';

import '../enums/booking_status.dart';
import '../enums/payment_method.dart';

/// Domain entity — đơn đặt chỗ của Host tại một quán.
///
/// Trường `qrPayload` chứa chuỗi raw mà nhân viên POS sẽ quét
/// để kích hoạt phiên chơi cho cả nhóm (Task 4 — Single Check-in).
class BookingEntity extends Equatable {
  final String id;
  final String cafeId;
  final String cafeName;
  final String gameId;
  final String gameName;
  final DateTime scheduledTime;

  /// Số ghế đặt (== tổng số thành viên, mỗi người 1 ghế theo BR-07).
  final int seatCount;
  final List<String> memberIds;
  final String hostId;

  final BookingStatus status;
  final double depositAmount;

  /// Deadline cọc do server set (BR-06), client chỉ render đếm ngược.
  final DateTime depositDeadline;

  final PaymentMethod paymentMethod;

  /// Mã giao dịch trả về từ cổng thanh toán.
  final String? paymentRef;

  /// Chuỗi mã hoá cho QR check-in.
  final String qrPayload;

  /// Nonce dùng một lần cho QR scan (Task 4 — Single Check-in).
  final String nonce;

  /// Đã được sử dụng chưa (nonce used = true sau khi scan thành công).
  final bool nonceUsed;

  final DateTime createdAt;
  final DateTime updatedAt;

  const BookingEntity({
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

  /// Thời gian còn lại để Host hoàn tất cọc.
  Duration get remainingGraceTime =>
      depositDeadline.difference(DateTime.now());

  /// true nếu đã quá deadline cọc nhưng chưa được server xác nhận EXPIRED.
  bool get isLocallyExpired =>
      DateTime.now().isAfter(depositDeadline) &&
      status == BookingStatus.pendingDeposit;

  /// Copy với 1 số field thay đổi.
  BookingEntity copyWith({
    BookingStatus? status,
    DateTime? depositDeadline,
    String? paymentRef,
    bool? nonceUsed,
    DateTime? updatedAt,
  }) {
    return BookingEntity(
      id: id,
      cafeId: cafeId,
      cafeName: cafeName,
      gameId: gameId,
      gameName: gameName,
      scheduledTime: scheduledTime,
      seatCount: seatCount,
      memberIds: memberIds,
      hostId: hostId,
      status: status ?? this.status,
      depositAmount: depositAmount,
      depositDeadline: depositDeadline ?? this.depositDeadline,
      paymentMethod: paymentMethod,
      paymentRef: paymentRef ?? this.paymentRef,
      qrPayload: qrPayload,
      nonce: nonce,
      nonceUsed: nonceUsed ?? this.nonceUsed,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        cafeId,
        cafeName,
        gameId,
        gameName,
        scheduledTime,
        seatCount,
        memberIds,
        hostId,
        status,
        depositAmount,
        depositDeadline,
        paymentMethod,
        paymentRef,
        qrPayload,
        nonce,
        nonceUsed,
        createdAt,
        updatedAt,
      ];
}