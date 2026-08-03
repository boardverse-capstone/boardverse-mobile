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

  /// Lấy chi tiết một giao dịch
  Future<Either<Failure, TransactionEntity>> getTransactionById(String transactionId);

  /// Kiểm tra xem top-up đã thành công chưa (polling)
  ///
  /// Backend sẽ trả về wallet với balance đã cập nhật nếu thành công
  Future<Either<Failure, WalletEntity>> checkTopUpStatus(String orderId);
}
