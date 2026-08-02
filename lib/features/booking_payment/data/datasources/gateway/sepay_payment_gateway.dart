import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/error/failures.dart';
import '../../../domain/entities/deposit_payment_entity.dart';
import '../../../domain/entities/deposit_status_entity.dart';
import '../../../domain/enums/payment_method.dart';
import '../base/payment_gateway.dart';
import '../remote/payment_remote_datasource.dart';

/// Triển khai `PaymentGateway` cho cổng SePay.
///
/// Flow:
/// 1. `openGateway(bookingId)` → `paymentRemote.createDepositPayment(bookingId)`
///    → `launchUrl(paymentUrl)` qua `url_launcher`.
/// 2. `transactionRef = depositId` — dùng để `watchResult` polling trạng thái.
///
/// Polling: `watchResult(depositId)` emit `GatewayPending` cho tới khi
/// `DepositStatus.paid` → `GatewaySuccess(transactionRef: orderId, paidAt: ...)`;
/// `Refunded/Forfeited/Expired` → `GatewayFailed`.
class SepayPaymentGateway implements PaymentGateway {
  final PaymentRemoteDatasource paymentRemote;

  SepayPaymentGateway({required this.paymentRemote});

  /// Holds the last created payment so [watchResult] can reuse [orderId].
  static final Map<String, DepositPaymentEntity> _cache = {};

  @override
  Future<Either<Failure, String>> openGateway({
    required String bookingId,
    required double amount,
    required PaymentMethod method,
  }) async {
    final result = await paymentRemote.createDepositPayment(
      bookingId: bookingId,
    );
    return result.fold(
      (failure) => Left<Failure, String>(failure),
      (payment) async {
        _cache[payment.depositId] = payment;
        if (payment.paymentUrl.isEmpty) {
          return const Left<Failure, String>(
            ServerFailure(message: 'Không nhận được URL thanh toán SePay'),
          );
        }
        final uri = Uri.tryParse(payment.paymentUrl);
        if (uri == null) {
          return const Left<Failure, String>(
            BadRequestFailure(message: 'URL thanh toán không hợp lệ'),
          );
        }
        final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!ok) {
          return const Left<Failure, String>(
            ServerFailure(message: 'Không thể mở cổng thanh toán SePay'),
          );
        }
        return Right<Failure, String>(payment.depositId);
      },
    );
  }

  @override
  Stream<PaymentResult> watchResult(String transactionRef) async* {
    // Emit ngay `Pending` để UI fresh data.
    yield const GatewayPending();

    while (true) {
      final result = await paymentRemote.getDepositStatus(transactionRef);
      late final DepositStatusEntity entity;
      bool gotEntity = false;
      result.fold(
        (failure) {},
        (data) {
          entity = data;
          gotEntity = true;
        },
      );
      if (!gotEntity) {
        yield const GatewayFailed(reason: 'Không lấy được trạng thái đơn cọc');
        return;
      }

      switch (entity.status) {
        case DepositStatus.pending:
          yield const GatewayPending();
          break;
        case DepositStatus.paid:
          final cached = _cache[transactionRef];
          yield GatewaySuccess(
            transactionRef: cached?.orderId ?? entity.orderId,
            paidAt: entity.paidAt ?? DateTime.now(),
          );
          return;
        case DepositStatus.refunded:
          yield const GatewayFailed(reason: 'Đơn cọc đã được hoàn');
          return;
        case DepositStatus.forfeited:
          yield const GatewayFailed(reason: 'Đơn cọc bị tịch thu (no-show)');
          return;
        case DepositStatus.expired:
          yield const GatewayFailed(reason: 'QR cọc đã hết hạn');
          return;
      }

      await Future<void>.delayed(const Duration(seconds: 3));
    }
  }
}
