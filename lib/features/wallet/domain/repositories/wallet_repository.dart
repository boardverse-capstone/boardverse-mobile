import 'dart:typed_data';

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/entities.dart';

/// Repository interface cho wallet.
abstract class WalletRepository {
  /// Lấy thông tin ví của user hiện tại (auto-create nếu chưa có).
  Future<Either<Failure, WalletEntity>> getWallet();

  /// Tạo đơn top-up BVC qua SePay.
  ///
  /// - [amountVnd] phải ≥ 10.000 và chia hết cho 1.000.
  /// - [idempotencyKey] để chống double-tap.
  Future<Either<Failure, TopUpQuoteEntity>> createTopUp({
    required int amountVnd,
    required String idempotencyKey,
  });

  /// Lấy lịch sử giao dịch (ledger).
  ///
  /// - [page] bắt đầu từ 1, [pageSize] 1-100.
  Future<Either<Failure, List<TransactionEntity>>> getTransactions({
    int page = 1,
    int pageSize = 20,
  });

  /// Đổi số tiền đơn top-up đang chờ thanh toán.
  Future<Either<Failure, TopUpQuoteEntity>> updateTopUp({
    required String topUpId,
    required int amountVnd,
    required String idempotencyKey,
  });

  /// Hủy đơn top-up đang chờ thanh toán.
  Future<Either<Failure, void>> cancelTopUp(String topUpId);

  /// Lấy ảnh QR PNG bytes qua fallback endpoint.
  ///
  /// Dùng khi backend không embed `qrImageBase64` trong response. Backend
  /// proxy từ vietqr.app server-side để bypass CORS trên Flutter Web.
  Future<Either<Failure, Uint8List>> getQrImageBytes(String orderId);

  /// Kiểm tra top-up đã thành công chưa qua transaction history.
  ///
  /// Trả về `true` khi phát hiện giao dịch nạp tương ứng hoặc balance đã
  /// tăng ≥ [expectedBvc].
  Future<Either<Failure, bool>> checkTopUpSuccessByOrderId(
    String orderId, {
    int? previousBalance,
    int? expectedBvc,
    DateTime? quoteCreatedAt,
  });
}
