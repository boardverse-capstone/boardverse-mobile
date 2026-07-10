import 'dart:async';
import 'dart:math';

import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../../../domain/entities/booking_entity.dart';
import '../../../domain/entities/booking_history_entity.dart';
import '../../../domain/entities/deposit_config_entity.dart';
import '../../../domain/enums/payment_method.dart';
import '../../models/booking_history_model.dart';
import '../../models/booking_model.dart';
import '../../models/deposit_config_model.dart';
import '../base/booking_remote_datasource.dart';

/// Mock datasource — giả lập REST API trong bộ nhớ.
///
/// Dữ liệu được giữ trong `Map<String, BookingModel>` và stream
/// `broadcast` để mô phỏng real-time update (tương lai sẽ là WebSocket).
class MockBookingRemoteDatasource implements BookingRemoteDatasource {
  // In-memory store.
  final Map<String, BookingModel> _bookings = {};
  final Map<String, StreamController<BookingModel>> _statusStreams = {};

  // Cấu hình cọc mặc định cho tất cả cafe trong dev.
  static final _defaultConfig = DepositConfigModel(
    cafeId: '*',
    firstHourPrice: 100000,
    entryFee: 80000,
    maxDeposit: 50000,
    defaultDeposit: 50000,
    graceMinutes: 15,
    currency: 'VND',
    pricingModel: 'hourly',
  );

  /// Counter để sinh id duy nhất mỗi lần createBooking.
  int _idCounter = 1;

  MockBookingRemoteDatasource() {
    _seedMockHistory();
    _seedUpcomingBookings();
  }

  late List<BookingHistoryModel> _history;

  // Upcoming bookings (confirmed) - để test check-in/checkout flow
  final List<BookingModel> _upcomingBookings = [];

  void _seedUpcomingBookings() {
    // ═══════════════════════════════════════════════════════════════════
    // MỐC THỜI GIAN: hôm nay là 09/07/2026 (UTC+7).
    // Hiện tại lúc chạy demo ≈ 18:54 ngày 09/07/2026.
    //
    // Bố trí mock data sao cho đủ kịch bản end-to-end:
    // - Còn 30 phút (count-down check-in)
    // - Đang chơi ~55 phút (test hiển thị elapsed time)
    // - Đang chơi ~2h54 (test gần kết thúc / overtime)
    // - Ngày mai (10/07): QR scan thành công
    // - Cuối tuần: confirmed future
    // - Pending deposit: cần thanh toán
    // - Cancelled: test view trạng thái huỷ
    // ═══════════════════════════════════════════════════════════════════

    final now = DateTime.now();

    // Helper: tạo DateTime local theo ngày 09/07/2026 với giờ cố định.
    DateTime at(int day, int hour, [int minute = 0]) =>
        DateTime(2026, 7, day, hour, minute);

    // ═══════════════════════════════════════════════════════════════════
    // B1: TỐI NAY 19:00 - Còn ~6 phút nữa - Test countdown check-in
    // ═══════════════════════════════════════════════════════════════════
    final booking1Time = at(9, 19, 0);
    final booking1 = _createBookingModel(
      id: 'BOOK2026_001',
      cafeId: 'cafe_thu_duc',
      cafeName: 'Meeple Station Thủ Đức',
      gameId: 'game_catan',
      gameName: 'Catan',
      scheduledTime: booking1Time,
      seatCount: 4,
      memberIds: ['user_001', 'user_002', 'user_003', 'user_004'],
      hostId: 'user_001',
      status: 'confirmed',
      depositAmount: 50000,
      nonce: 'catan2026nonce01',
      createdAt: now.subtract(const Duration(hours: 6)),
      updatedAt: now.subtract(const Duration(hours: 6)),
    );
    _upcomingBookings.add(booking1);
    _bookings[booking1.id] = booking1;

    // ═══════════════════════════════════════════════════════════════════
    // B3: ĐÃ CHECK-IN ~55 phút trước - Đang chơi Catan
    //    scheduledTime: 18:00 hôm nay (đã qua)
    //    Check-in lúc  18:00 → now() ≈ 18:55 → ~55 phút elapsed
    //    Cập nhật time để hiển thị "Đang chơi 0h55"
    // ═══════════════════════════════════════════════════════════════════
    final booking2Time = at(9, 18, 0);
    final booking2CheckinAt = now.subtract(const Duration(minutes: 55));
    final booking2 = _createBookingModel(
      id: 'BOOK2026_002',
      cafeId: 'cafe_binhtan',
      cafeName: 'Dice & Pieces Bình Tân',
      gameId: 'game_splendor',
      gameName: 'Splendor',
      scheduledTime: booking2Time,
      seatCount: 2,
      memberIds: ['user_001', 'user_006'],
      hostId: 'user_001',
      status: 'checkedIn',
      depositAmount: 40000,
      nonce: 'splendor2026nonce02',
      createdAt: now.subtract(const Duration(hours: 5)),
      updatedAt: booking2CheckinAt, // = thời điểm check-in
    );
    _upcomingBookings.add(booking2);
    _bookings[booking2.id] = booking2;

    // ═══════════════════════════════════════════════════════════════════
    // B4: ĐÃ CHECK-IN ~2h54 trước - Đang chơi Ma Sói gần kết thúc
    //    scheduledTime: 16:00 hôm nay
    //    Check-in lúc  16:00 → now() ≈ 18:55 → ~175 phút (2h55) elapsed
    //    Dùng để test cảnh báo "Sắp hết giờ"
    // ═══════════════════════════════════════════════════════════════════
    final booking3Time = at(9, 16, 0);
    final booking3CheckinAt = now.subtract(const Duration(hours: 2, minutes: 54));
    final booking3 = _createBookingModel(
      id: 'BOOK2026_003',
      cafeId: 'cafe_q1',
      cafeName: 'Board Game Hub Q1',
      gameId: 'game_ma_soi',
      gameName: 'Ma Sói',
      scheduledTime: booking3Time,
      seatCount: 5,
      memberIds: ['user_001', 'user_005', 'user_007', 'user_018', 'user_019'],
      hostId: 'user_001',
      status: 'checkedIn',
      depositAmount: 60000,
      nonce: 'masoi2026nonce03',
      createdAt: now.subtract(const Duration(hours: 8)),
      updatedAt: booking3CheckinAt,
    );
    _upcomingBookings.add(booking3);
    _bookings[booking3.id] = booking3;

    // ═══════════════════════════════════════════════════════════════════
    // B5: NGÀY MAI 10/07 - 10:00 sáng - Confirmed, QR sẵn sàng quét
    //    Test scan QR thành công → chuyển checkedIn
    // ═══════════════════════════════════════════════════════════════════
    final booking4 = _createBookingModel(
      id: 'BOOK2026_004',
      cafeId: 'cafe_tanbinh',
      cafeName: 'Roll & Play Tân Bình',
      gameId: 'game_ticket',
      gameName: 'Ticket to Ride',
      scheduledTime: at(10, 10, 0),
      seatCount: 2,
      memberIds: ['user_001', 'user_008'],
      hostId: 'user_001',
      status: 'confirmed',
      depositAmount: 45000,
      nonce: 'ticket2026nonce04',
      createdAt: now.subtract(const Duration(hours: 12)),
      updatedAt: now.subtract(const Duration(hours: 12)),
    );
    _upcomingBookings.add(booking4);
    _bookings[booking4.id] = booking4;

    // ═══════════════════════════════════════════════════════════════════
    // B6: CUỐI TUẦN 11/07 - 14:00 - Wingspan 6 người
    // ═══════════════════════════════════════════════════════════════════
    final booking5 = _createBookingModel(
      id: 'BOOK2026_005',
      cafeId: 'cafe_go_vap',
      cafeName: 'Gỗ Zone Gò Vấp',
      gameId: 'game_wingspan',
      gameName: 'Wingspan',
      scheduledTime: at(11, 14, 0),
      seatCount: 6,
      memberIds: [
        'user_001',
        'user_009',
        'user_010',
        'user_011',
        'user_012',
        'user_013'
      ],
      hostId: 'user_001',
      status: 'confirmed',
      depositAmount: 70000,
      nonce: 'wingspan2026nonce05',
      createdAt: now.subtract(const Duration(days: 1)),
      updatedAt: now.subtract(const Duration(days: 1)),
    );
    _upcomingBookings.add(booking5);
    _bookings[booking5.id] = booking5;

    // ═══════════════════════════════════════════════════════════════════
    // B7: Pending Deposit - 12/07 19:00 - King of Tokyo (chờ thanh toán)
    // ═══════════════════════════════════════════════════════════════════
    final booking6Deadline = now.add(const Duration(minutes: 12));
    final booking6 = _createBookingModel(
      id: 'BOOK2026_006',
      cafeId: 'cafe_7',
      cafeName: 'Dice Kingdom Quận 7',
      gameId: 'game_king_tokyo',
      gameName: 'King of Tokyo',
      scheduledTime: at(12, 19, 0),
      seatCount: 4,
      memberIds: ['user_001', 'user_014', 'user_015', 'user_020'],
      hostId: 'user_001',
      status: 'pendingDeposit',
      depositAmount: 55000,
      nonce: 'kingtokyo2026nonce06',
      createdAt: now.subtract(const Duration(minutes: 3)),
      updatedAt: now.subtract(const Duration(minutes: 3)),
      depositDeadlineOverride: booking6Deadline,
    );
    _upcomingBookings.add(booking6);
    _bookings[booking6.id] = booking6;

    // ═══════════════════════════════════════════════════════════════════
    // B8: ĐÃ HỦY - 13/07 21:00 - 7 Wonders (test view huỷ)
    // ═══════════════════════════════════════════════════════════════════
    final booking7 = _createBookingModel(
      id: 'BOOK2026_007',
      cafeId: 'cafe_3',
      cafeName: 'Board Game Paradise Q3',
      gameId: 'game_7w',
      gameName: '7 Wonders',
      scheduledTime: at(13, 21, 0),
      seatCount: 3,
      memberIds: ['user_001', 'user_016', 'user_021'],
      hostId: 'user_001',
      status: 'cancelledByPlayer',
      depositAmount: 50000,
      nonce: '7wonders2026nonce07',
      createdAt: now.subtract(const Duration(days: 2)),
      updatedAt: now.subtract(const Duration(hours: 30)),
    );
    _upcomingBookings.add(booking7);
    _bookings[booking7.id] = booking7;

    // ═══════════════════════════════════════════════════════════════════
    // B9: TỐI NAY 20:30 - Azul - Confirmed, để test scan thêm lần nữa
    // ═══════════════════════════════════════════════════════════════════
    final booking8 = _createBookingModel(
      id: 'BOOK2026_008',
      cafeId: 'cafe_10',
      cafeName: 'Game Haven Phú Nhuận',
      gameId: 'game_azul',
      gameName: 'Azul',
      scheduledTime: at(9, 20, 30),
      seatCount: 2,
      memberIds: ['user_001', 'user_017'],
      hostId: 'user_001',
      status: 'confirmed',
      depositAmount: 35000,
      nonce: 'azul2026nonce08',
      createdAt: now.subtract(const Duration(hours: 4)),
      updatedAt: now.subtract(const Duration(hours: 4)),
    );
    _upcomingBookings.add(booking8);
    _bookings[booking8.id] = booking8;
  }

  BookingModel _createBookingModel({
    required String id,
    required String cafeId,
    required String cafeName,
    required String gameId,
    required String gameName,
    required DateTime scheduledTime,
    required int seatCount,
    required List<String> memberIds,
    required String hostId,
    required String status,
    required double depositAmount,
    required String nonce,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? depositDeadlineOverride,
  }) {
    final now = DateTime.now();
    return BookingModel(
      id: id,
      cafeId: cafeId,
      cafeName: cafeName,
      gameId: gameId,
      gameName: gameName,
      scheduledTime: scheduledTime,
      seatCount: seatCount,
      memberIds: memberIds,
      hostId: hostId,
      status: status,
      depositAmount: depositAmount,
      depositDeadline: depositDeadlineOverride ?? now.add(const Duration(minutes: 30)),
      paymentMethod: 'sandboxMock',
      paymentRef: 'mock_ref_$id',
      qrPayload: _buildQrPayload(id, hostId, cafeId, scheduledTime, memberIds, nonce),
      nonce: nonce,
      nonceUsed: status == 'checkedIn',
      createdAt: createdAt ?? now.subtract(const Duration(hours: 2)),
      updatedAt: updatedAt ?? now,
    );
  }

  /// Get all upcoming bookings (tất cả trạng thái để user test mọi luồng).
  List<BookingModel> getUpcomingBookings() {
    return List.unmodifiable(_upcomingBookings);
  }

  void _seedMockHistory() {
    final history = <BookingHistoryModel>[
      // History 1: 2 ngày trước - No Show
      BookingHistoryModel(
        id: 'HIST001',
        cafeName: 'Meeple Station',
        gameName: 'Ma Sói',
        scheduledTime: DateTime(2026, 7, 7, 19, 0),
        actualCheckinTime: null,
        status: 'noShow',
        hasNoShowBadge: true,
        depositAmount: 50000,
      ),
      // History 2: 4 ngày trước - Hoàn thành
      BookingHistoryModel(
        id: 'HIST002',
        cafeName: 'Board Game Hub Q1',
        gameName: 'Catan',
        scheduledTime: DateTime(2026, 7, 5, 19, 0),
        actualCheckinTime: DateTime(2026, 7, 5, 18, 55),
        status: 'completed',
        hasNoShowBadge: false,
        depositAmount: 60000,
      ),
      // History 3: 1 tuần trước - Huỷ
      BookingHistoryModel(
        id: 'HIST003',
        cafeName: 'Dice Kingdom Quận 7',
        gameName: 'Splendor',
        scheduledTime: DateTime(2026, 7, 2, 20, 0),
        actualCheckinTime: null,
        status: 'cancelled',
        hasNoShowBadge: false,
        depositAmount: 40000,
      ),
      // History 4: 10 ngày trước - Hoàn thành
      BookingHistoryModel(
        id: 'HIST004',
        cafeName: 'Gỗ Zone Gò Vấp',
        gameName: 'Wingspan',
        scheduledTime: DateTime(2026, 6, 29, 14, 0),
        actualCheckinTime: DateTime(2026, 6, 29, 13, 50),
        status: 'completed',
        hasNoShowBadge: false,
        depositAmount: 70000,
      ),
    ];
    _history = history;
  }

  @override
  Future<Either<Failure, DepositConfigEntity>> getDepositConfig(
    String cafeId,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Dev: trả cùng cấu hình cho mọi cafe; phase sau có thể map theo cafeId.
    return Right(_defaultConfig.toEntity());
  }

  @override
  Future<Either<Failure, BookingEntity>> createBooking({
    required String cafeId,
    required String gameId,
    required DateTime scheduledTime,
    required int seatCount,
    required double depositAmount,
    required PaymentMethod paymentMethod,
    required List<String> memberIds,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));

    final id =
        'BOOK${DateTime.now().year}_${_idCounter.toString().padLeft(3, '0')}';
    _idCounter++;

    final graceMinutes = _defaultConfig.graceMinutes;
    final now = DateTime.now();
    final nonce = _generateNonce();
    final hostId = memberIds.isNotEmpty ? memberIds.first : 'user_001';

    final model = BookingModel(
      id: id,
      cafeId: cafeId,
      cafeName: 'Mock Cafe ($cafeId)',
      gameId: gameId,
      gameName: 'Mock Game ($gameId)',
      scheduledTime: scheduledTime,
      seatCount: seatCount,
      memberIds: memberIds,
      hostId: hostId,
      status: 'pendingDeposit',
      depositAmount: depositAmount,
      depositDeadline: now.add(Duration(minutes: graceMinutes)),
      paymentMethod: paymentMethod.name,
      paymentRef: null,
      qrPayload: _buildQrPayload(id, hostId, cafeId, scheduledTime, memberIds, nonce),
      nonce: nonce,
      nonceUsed: false,
      createdAt: now,
      updatedAt: now,
    );

    _bookings[id] = model;
    _emitStatus(model);
    return Right(model.toEntity());
  }

  @override
  Future<Either<Failure, BookingEntity>> getBookingById(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final model = _bookings[id];
    if (model == null) {
      return Left(ServerFailure(message: 'Không tìm thấy đơn đặt chỗ ($id)'));
    }
    return Right(model.toEntity());
  }

  @override
  Future<Either<Failure, BookingEntity>> confirmBookingPayment({
    required String bookingId,
    required String paymentRef,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final model = _bookings[bookingId];
    if (model == null) {
      return Left(ServerFailure(message: 'Không tìm thấy đơn ($bookingId)'));
    }

    final updated = BookingModel(
      id: model.id,
      cafeId: model.cafeId,
      cafeName: model.cafeName,
      gameId: model.gameId,
      gameName: model.gameName,
      scheduledTime: model.scheduledTime,
      seatCount: model.seatCount,
      memberIds: model.memberIds,
      hostId: model.hostId,
      status: 'confirmed',
      depositAmount: model.depositAmount,
      depositDeadline: model.depositDeadline,
      paymentMethod: model.paymentMethod,
      paymentRef: paymentRef,
      qrPayload: model.qrPayload,
      nonce: model.nonce,
      nonceUsed: model.nonceUsed,
      createdAt: model.createdAt,
      updatedAt: DateTime.now(),
    );
    _bookings[bookingId] = updated;
    _emitStatus(updated);
    return Right(updated.toEntity());
  }

  @override
  Future<Either<Failure, BookingEntity>> cancelBookingByPlayer({
    required String bookingId,
    required String reason,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final model = _bookings[bookingId];
    if (model == null) {
      return Left(ServerFailure(message: 'Không tìm thấy đơn ($bookingId)'));
    }

    final updated = BookingModel(
      id: model.id,
      cafeId: model.cafeId,
      cafeName: model.cafeName,
      gameId: model.gameId,
      gameName: model.gameName,
      scheduledTime: model.scheduledTime,
      seatCount: model.seatCount,
      memberIds: model.memberIds,
      hostId: model.hostId,
      status: 'cancelledByPlayer',
      depositAmount: model.depositAmount,
      depositDeadline: model.depositDeadline,
      paymentMethod: model.paymentMethod,
      paymentRef: model.paymentRef,
      qrPayload: model.qrPayload,
      nonce: model.nonce,
      nonceUsed: model.nonceUsed,
      createdAt: model.createdAt,
      updatedAt: DateTime.now(),
    );
    _bookings[bookingId] = updated;
    _emitStatus(updated);
    return Right(updated.toEntity());
  }

  @override
  Stream<BookingEntity> watchBookingStatus(String bookingId) {
    final controller = _statusStreams.putIfAbsent(
      bookingId,
      () => StreamController<BookingModel>.broadcast(),
    );

    // Push current state ngay khi subscribe.
    final current = _bookings[bookingId];
    if (current != null) {
      Future.microtask(() {
        if (!controller.isClosed) controller.add(current);
      });
    }

    return controller.stream.map((m) => m.toEntity());
  }

  @override
  Future<Either<Failure, List<BookingHistoryEntity>>> getBookingHistory() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return Right(_history.map((m) => m.toEntity()).toList());
  }

  // ─── Helpers ────────────────────────────────────────────────────────

  void _emitStatus(BookingModel model) {
    final controller = _statusStreams[model.id];
    if (controller != null && !controller.isClosed) {
      controller.add(model);
    }
  }

  String _generateNonce() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random(timestamp).nextInt(99999999);
    return '${timestamp.toRadixString(16)}_${random.toRadixString(16)}';
  }

  String _buildQrPayload(
    String bookingId,
    String hostId,
    String cafeId,
    DateTime scheduledTime,
    List<String> memberIds,
    String nonce,
  ) {
    final stamp = scheduledTime
        .toIso8601String()
        .replaceAll('-', '')
        .replaceAll(':', '')
        .split('.')
        .first;
    return 'BOARDVERSE|v1|$bookingId|$hostId|$cafeId|$stamp|${memberIds.join(',')}|$nonce';
  }

  /// Mock POS scan — simulates the QR scan validation flow.
  ///
  /// Returns [QrScanResult] with success/failure reason.
  QrScanResult simulateQrScan({
    required String bookingId,
    required String scannedUserId,
  }) {
    final model = _bookings[bookingId];

    if (model == null) {
      return QrScanResult(
        success: false,
        errorCode: 'BOOKING_NOT_FOUND',
        message: 'Mã QR không hợp lệ',
      );
    }

    if (model.status != 'confirmed') {
      return QrScanResult(
        success: false,
        errorCode: 'NOT_CONFIRMED',
        message: 'Booking chưa thanh toán',
      );
    }

    if (model.nonceUsed) {
      return QrScanResult(
        success: false,
        errorCode: 'ALREADY_SCANNED',
        message: 'Mã QR đã được quét trước đó',
      );
    }

    if (!model.memberIds.contains(scannedUserId)) {
      return QrScanResult(
        success: false,
        errorCode: 'NOT_MEMBER',
        message: 'Bạn không phải thành viên của nhóm này',
      );
    }

    final updated = BookingModel(
      id: model.id,
      cafeId: model.cafeId,
      cafeName: model.cafeName,
      gameId: model.gameId,
      gameName: model.gameName,
      scheduledTime: model.scheduledTime,
      seatCount: model.seatCount,
      memberIds: model.memberIds,
      hostId: model.hostId,
      status: 'checkedIn',
      depositAmount: model.depositAmount,
      depositDeadline: model.depositDeadline,
      paymentMethod: model.paymentMethod,
      paymentRef: model.paymentRef,
      qrPayload: model.qrPayload,
      nonce: model.nonce,
      nonceUsed: true,
      createdAt: model.createdAt,
      updatedAt: DateTime.now(),
    );
    _bookings[bookingId] = updated;
    _emitStatus(updated);

    return QrScanResult(
      success: true,
      booking: updated.toEntity(),
      message: 'Check-in thành công!',
    );
  }

  /// Đóng tất cả stream khi datasource bị dispose (chưa dùng nhưng để sẵn).
  void dispose() {
    for (final c in _statusStreams.values) {
      c.close();
    }
  }
}

/// Kết quả mock QR scan.
class QrScanResult {
  final bool success;
  final String errorCode;
  final String message;
  final BookingEntity? booking;

  const QrScanResult({
    required this.success,
    this.errorCode = '',
    required this.message,
    this.booking,
  });
}