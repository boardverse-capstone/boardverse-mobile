import 'dart:async';

import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../../../domain/enums/payment_method.dart';
import '../base/payment_gateway.dart';

/// Giả lập cổng thanh toán cho dev/test.
///
/// Hành vi:
/// - `openGateway()` → trả `transactionRef` sau 500ms.
/// - `watchResult(ref)` → stream mỗi 1s:
///     - tick 1: [PaymentPending]
///     - tick 2: [PaymentSuccess]
///   Có thể đổi sang `simulateFailure = true` để test luồng fail.
class MockPaymentGateway implements PaymentGateway {
  /// Bật = true sẽ làm gateway trả [PaymentFailed] thay vì success.
  /// Chỉ dùng khi dev test, không expose UI.
  bool simulateFailure = false;

  /// Độ trễ trước khi trả về kết quả cuối cùng (giây).
  /// Mặc định 2 giây — production mock; có thể chỉnh trong test.
  int successAfterTicks;

  MockPaymentGateway({this.successAfterTicks = 2, this.simulateFailure = false});

  @override
  Future<Either<Failure, String>> openGateway({
    required String bookingId,
    required double amount,
    required PaymentMethod method,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final ref = 'MOCK|$bookingId|${DateTime.now().millisecondsSinceEpoch}';
    return Right(ref);
  }

  @override
  Stream<PaymentResult> watchResult(String transactionRef) async* {
    final controller = StreamController<PaymentResult>();
    int tick = 0;

    final timer = Timer.periodic(const Duration(seconds: 1), (t) {
      tick++;
      if (tick >= successAfterTicks) {
        controller.add(
          simulateFailure
              ? const GatewayFailed(reason: 'Gateway giả lập thất bại')
              : GatewaySuccess(
                  transactionRef: transactionRef,
                  paidAt: DateTime.now(),
                ),
        );
        controller.close();
        t.cancel();
      } else {
        controller.add(const GatewayPending());
      }
    });

    controller.onCancel = () => timer.cancel();
    yield* controller.stream;
  }
}