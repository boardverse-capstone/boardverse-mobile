import 'dart:typed_data';

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

  /// Lấy ảnh QR PNG bytes qua fallback endpoint.
  ///
  /// Dùng khi backend không embed `qrImageBase64` trong response của
  /// POST/PATCH /topup. Backend proxy từ vietqr.app server-side →
  /// bypass CORS trên Flutter Web.
  Future<Either<Failure, Uint8List>> getQrImageBytes(String orderId);

  /// Kiểm tra xem top-up đã thành công chưa bằng cách check transaction history.
  ///
  /// Quy trình 3-tier fallback (xem `WalletRepositoryImpl`):
  ///   1. **Tier 1** (lý tưởng): tìm transaction `relatedPaymentRef == orderId`.
  ///   2. **Tier 2** (backend không gắn ref): phát hiện transaction `TopUp`
  ///      tạo SAU [quoteCreatedAt] (xem BR §3.3). Loại trừ transaction do
  ///      chính quote này tạo (nếu có) → giúp không match nhầm cho lần top-up
  ///      kế tiếp.
  ///   3. **Tier 3** (fallback cuối): kiểm tra balance delta — nếu balance
  ///      hiện tại > [previousBalance] + 1 BVC → coi như đã nạp thành công.
  ///
  /// Trả về `true` khi BẤT KỲ tier nào match. Cờ [previousBalance] /
  /// [expectedBvc] / [quoteCreatedAt] là optional — nếu caller cung cấp thì
  /// tier 2 + 3 hoạt động chính xác hơn.
  Future<Either<Failure, bool>> checkTopUpSuccessByOrderId(
    String orderId, {
    int? previousBalance,
    int? expectedBvc,
    DateTime? quoteCreatedAt,
  });
}
