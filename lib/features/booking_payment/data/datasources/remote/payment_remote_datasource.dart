import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../../core/constants/api_endpoints.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/network/api_response.dart';
import '../../../domain/entities/deposit_payment_entity.dart';
import '../../../domain/entities/deposit_status_entity.dart';
import '../../models/deposit_payment_model.dart';
import '../../models/deposit_status_model.dart';

/// Datasource riêng cho `BookingDeposit` (SePay payment).
///
/// Tách khỏi `BookingRemoteDatasource` để:
/// - Độc lập unit test với `BookingRemoteDatasource`.
/// - Stub dễ dàng khi test polling SePay.
class PaymentRemoteDatasource {
  final Dio dio;

  PaymentRemoteDatasource({required this.dio});

  // ─── Player flow: Booking deposit ─────────────────────────────────

  /// `POST /api/payments/booking-deposit` — tạo đơn cọc mới.
  ///
  /// Body theo `payment.md`: `{cafeId, lobbyId?, scheduledStartTime,
  /// seatCount, amount}` (one-step). Một số version backend theo swagger
  /// lại dùng `{bookingId, depositId, amount}` (two-step) — backend
  /// controller sẽ resolve cả hai.
  Future<Either<Failure, DepositPaymentEntity>> createDepositPayment({
    required String bookingId,
    String? cafeId,
    String? lobbyId,
    DateTime? scheduledStartTime,
    int? seatCount,
    double? amount,
  }) =>
      _wrap(() async {
        final body = <String, dynamic>{
          // Luôn gửi bookingId (theo swagger CreatePaymentRequestDto).
          'bookingId': bookingId,
        };
        if (cafeId != null) body['cafeId'] = cafeId;
        if (lobbyId != null) body['lobbyId'] = lobbyId;
        if (scheduledStartTime != null) {
          body['scheduledStartTime'] = scheduledStartTime.toUtc().toIso8601String();
        }
        if (seatCount != null) body['seatCount'] = seatCount;
        if (amount != null) body['amount'] = amount;

        final res = await dio.post<Map<String, dynamic>>(
          ApiEndpoints.bookingDeposit,
          data: body,
        );
        final api = ApiResponse<Map<String, dynamic>>.fromJson(
          res.data ?? const {},
          fromJsonT: (json) => json as Map<String, dynamic>,
        );
        _ensureSuccess(api);
        return DepositPaymentModel.fromJson(api.data ?? const {}).toEntity();
      });

  /// `GET /api/payments/booking-deposit/{id}` — lấy chi tiết đơn cọc
  /// theo `depositId` (mobile polling).
  Future<Either<Failure, DepositStatusEntity>> getDepositStatus(
    String depositId,
  ) =>
      _wrap(() async {
        final path =
            ApiEndpoints.bookingDepositDetail.replaceAll('{id}', depositId);
        final res = await dio.get<Map<String, dynamic>>(path);
        final api = ApiResponse<Map<String, dynamic>>.fromJson(
          res.data ?? const {},
          fromJsonT: (json) => json as Map<String, dynamic>,
        );
        _ensureSuccess(api);
        return DepositStatusModel.fromJson(api.data ?? const {}).toEntity();
      });

  /// `GET /api/payments/booking-deposit/by-order/{orderId}` — tra theo
  /// `OrderId` (BV-prefix).
  Future<Either<Failure, DepositStatusEntity>> getDepositByOrder(
    String orderId,
  ) =>
      _wrap(() async {
        final path = ApiEndpoints.bookingDepositByOrder
            .replaceAll('{orderId}', orderId);
        final res = await dio.get<Map<String, dynamic>>(path);
        final api = ApiResponse<Map<String, dynamic>>.fromJson(
          res.data ?? const {},
          fromJsonT: (json) => json as Map<String, dynamic>,
        );
        _ensureSuccess(api);
        return DepositStatusModel.fromJson(api.data ?? const {}).toEntity();
      });

  /// `POST /api/payments/booking-deposit/{id}/regenerate-qr` — tạo lại
  /// QR mới khi QR cũ hết hạn (BR-06). QR cũ → `EXPIRED`.
  Future<Either<Failure, DepositPaymentEntity>> regenerateDepositQr(
    String depositId,
  ) =>
      _wrap(() async {
        final path = ApiEndpoints.bookingDepositRegenerateQr
            .replaceAll('{id}', depositId);
        final res = await dio.post<Map<String, dynamic>>(path);
        final api = ApiResponse<Map<String, dynamic>>.fromJson(
          res.data ?? const {},
          fromJsonT: (json) => json as Map<String, dynamic>,
        );
        _ensureSuccess(api);
        return DepositPaymentModel.fromJson(api.data ?? const {}).toEntity();
      });

  // ─── Manager/Admin flow: Refund ──────────────────────────────────

  /// `POST /api/payments/booking-deposit/refund` — hoàn cọc theo policy.
  /// Chỉ Manager/Admin. Trả về cùng `DepositStatusEntity` (status đã
  /// cập nhật sang `Refunded` hoặc `Forfeited`).
  Future<Either<Failure, DepositStatusEntity>> refundDeposit({
    required String depositId,
    required String reason,
  }) =>
      _wrap(() async {
        final res = await dio.post<Map<String, dynamic>>(
          ApiEndpoints.bookingDepositRefund,
          data: {
            'depositId': depositId,
            'reason': reason,
          },
        );
        final api = ApiResponse<Map<String, dynamic>>.fromJson(
          res.data ?? const {},
          fromJsonT: (json) => json as Map<String, dynamic>,
        );
        _ensureSuccess(api);
        return DepositStatusModel.fromJson(api.data ?? const {}).toEntity();
      });

  // ─── POS flow: Session payment & manual confirm ───────────────────
  // Reference only — mobile Player hiện không gọi trực tiếp; nhưng khai
  // báo ở đây để dễ test abstraction layer.

  /// `POST /api/payments/session-payment` — POS tạo QR cho hóa đơn
  /// phiên chơi (sau khi kiểm kê linh kiện).
  Future<Either<Failure, DepositPaymentEntity>> createSessionPayment({
    required String sessionId,
    String? customerEmail,
    String? notes,
  }) =>
      _wrap(() async {
        final body = <String, dynamic>{
          'sessionId': sessionId,
        };
        if (customerEmail != null) body['customerEmail'] = customerEmail;
        if (notes != null) body['notes'] = notes;

        final res = await dio.post<Map<String, dynamic>>(
          ApiEndpoints.sessionPayment,
          data: body,
        );
        final api = ApiResponse<Map<String, dynamic>>.fromJson(
          res.data ?? const {},
          fromJsonT: (json) => json as Map<String, dynamic>,
        );
        _ensureSuccess(api);
        return DepositPaymentModel.fromJson(api.data ?? const {}).toEntity();
      });

  /// `POST /api/payments/session-payment/{sessionId}/regenerate-qr`.
  Future<Either<Failure, DepositPaymentEntity>> regenerateSessionPaymentQr(
    String sessionId,
  ) =>
      _wrap(() async {
        final path = ApiEndpoints.sessionPaymentRegenerateQr
            .replaceAll('{sessionId}', sessionId);
        final res = await dio.post<Map<String, dynamic>>(path);
        final api = ApiResponse<Map<String, dynamic>>.fromJson(
          res.data ?? const {},
          fromJsonT: (json) => json as Map<String, dynamic>,
        );
        _ensureSuccess(api);
        return DepositPaymentModel.fromJson(api.data ?? const {}).toEntity();
      });

  /// `POST /api/payments/manual-confirm` — staff xác nhận thanh toán
  /// thủ công khi SePay + VietQR đều lỗi.
  Future<Either<Failure, DepositStatusEntity>> manualConfirm({
    required String orderId,
    required double amount,
    required String paymentType,
    required String paymentMethod,
    String? notes,
  }) =>
      _wrap(() async {
        final body = <String, dynamic>{
          'orderId': orderId,
          'amount': amount,
          'paymentType': paymentType,
          'paymentMethod': paymentMethod,
        };
        if (notes != null) body['notes'] = notes;

        final res = await dio.post<Map<String, dynamic>>(
          ApiEndpoints.manualConfirm,
          data: body,
        );
        final api = ApiResponse<Map<String, dynamic>>.fromJson(
          res.data ?? const {},
          fromJsonT: (json) => json as Map<String, dynamic>,
        );
        _ensureSuccess(api);
        return DepositStatusModel.fromJson(api.data ?? const {}).toEntity();
      });

  // ─── Dev helper: SePay mock webhook ──────────────────────────────
  // Gated bằng flag `EnableMockPayments` ở client (env var). KHÔNG dùng
  // trong production — chỉ phục vụ integration test khi backend chưa
  // nhận webhook thật từ SePay.

  /// `POST /api/payments/sepay/webhook/mock` — giả lập SePay gửi webhook
  /// xác nhận thanh toán (BR-18). Trả về response của webhook.
  Future<Either<Failure, Map<String, dynamic>>> mockSepayWebhook({
    required String orderId,
    required String status,
    required double amount,
    String currency = 'VND',
    String? referenceCode,
  }) =>
      _wrap(() async {
        final res = await dio.post<Map<String, dynamic>>(
          ApiEndpoints.sepayWebhookMock,
          data: {
            'orderId': orderId,
            'status': status,
            'amount': amount,
            'currency': currency,
            'referenceCode': ?referenceCode,
          },
        );
        return res.data ?? const <String, dynamic>{};
      });

  // ─── Helpers ──────────────────────────────────────────────────────

  Future<Either<Failure, T>> _wrap<T>(Future<T> Function() body) async {
    try {
      final value = await body();
      return Right<Failure, T>(value);
    } on Failure catch (f) {
      return Left<Failure, T>(f);
    } on DioException catch (e) {
      return Left<Failure, T>(_mapDioError(e));
    } catch (e) {
      return Left<Failure, T>(
        ServerFailure(message: 'Lỗi không xác định: $e'),
      );
    }
  }

  void _ensureSuccess(ApiResponse<dynamic> api) {
    if (api.isSuccess) return;
    throw FailureFromApiResponseX.fromApiResponse(
      api,
      fallbackMessage: 'Yêu cầu thất bại (${api.statusCode})',
    );
  }

  Failure _mapDioError(DioException e) {
    final code = e.response?.statusCode;
    final apiMsg = e.response?.data is Map
        ? (e.response!.data as Map)['message']?.toString()
        : null;
    switch (code) {
      case 400:
        return BadRequestFailure(message: apiMsg ?? 'Dữ liệu không hợp lệ');
      case 401:
        return UnauthorizedFailure(
          message: apiMsg ?? 'Phiên đăng nhập hết hạn',
        );
      case 403:
        return ForbiddenFailure(message: apiMsg ?? 'Bạn không có quyền');
      case 404:
        return NotFoundFailure(message: apiMsg ?? 'Không tìm thấy đơn cọc');
      case 409:
        return ConflictFailure(message: apiMsg ?? 'Xung đột dữ liệu');
      case 429:
        return RateLimitFailure(
          message: apiMsg ?? 'Bạn thao tác quá nhanh, thử lại sau',
        );
      case 500:
      case 502:
      case 503:
        return ServerFailure(
          message: apiMsg ?? 'Lỗi server ($code)',
          statusCode: code,
        );
      default:
        return NetworkFailure(
          message: e.message ?? 'Không thể kết nối server',
        );
    }
  }
}