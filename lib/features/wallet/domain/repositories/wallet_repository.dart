import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/entities.dart';

/// Repository interface cho wallet feature (BR §2, §3)
///
/// Định nghĩa các operations liên quan đến ví BVC và ledger.
abstract class WalletRepository {
  /// Lấy thông tin ví của user hiện tại (auto-create nếu chưa có)
  ///
  /// [includeHeld] = true để trả về cả heldBalance
  Future<Either<Failure, WalletEntity>> getWallet({bool includeHeld = false});

  /// Tạo đơn top-up BVC qua SePay
  ///
  /// [amountVnd] phải ≥ 10.000 và chia hết cho 1.000
  /// [idempotencyKey] để chống double-tap (8-128 ký tự)
  ///
  /// Trả về [TopUpQuoteEntity] chứa paymentUrl để mở SePay
  Future<Either<Failure, TopUpQuoteEntity>> createTopUp({
    required int amountVnd,
    required String idempotencyKey,
  });

  /// Lấy lịch sử giao dịch (ledger)
  ///
  /// [page] bắt đầu từ 1, [pageSize] 1-100
  Future<Either<Failure, List<TransactionEntity>>> getTransactions({
    int page = 1,
    int pageSize = 20,
  });

  /// Đổi số tiền đơn top-up đang Pending (chưa thanh toán).
  /// Đơn cũ = Cancelled; đơn mới trả về qua [TopUpQuoteEntity].
  Future<Either<Failure, TopUpQuoteEntity>> updateTopUp({
    required String topUpId,
    required int amountVnd,
    required String idempotencyKey,
  });

  /// Hủy đơn top-up đang Pending (chưa thanh toán).
  Future<Either<Failure, void>> cancelTopUp(String topUpId);

  /// Kiểm tra xem top-up đã thành công chưa bằng cách check transaction history.
  ///
  /// Thay vì check balance (sai), ta check transaction có relatedPaymentRef = orderId.
  /// Đây là cách đúng để xác nhận topup đã được xử lý bởi SePay webhook.
  Future<Either<Failure, bool>> checkTopUpSuccessByOrderId(String orderId);
}
