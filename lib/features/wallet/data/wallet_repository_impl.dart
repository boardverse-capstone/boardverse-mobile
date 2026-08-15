import 'dart:typed_data';

import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import '../domain/entities/entities.dart';
import '../domain/repositories/wallet_repository.dart';
import 'datasources/wallet_remote_datasource.dart';

/// Implementation of WalletRepository using remote datasource
class WalletRepositoryImpl implements WalletRepository {
  final WalletRemoteDatasource remoteDatasource;

  WalletRepositoryImpl({required this.remoteDatasource});

  @override
  Future<Either<Failure, WalletEntity>> getWallet({bool includeHeld = false}) async {
    return await remoteDatasource.getWallet(includeHeld: includeHeld);
  }

  @override
  Future<Either<Failure, TopUpQuoteEntity>> createTopUp({
    required int amountVnd,
    required String idempotencyKey,
  }) async {
    return await remoteDatasource.createTopUp(
      amountVnd: amountVnd,
      idempotencyKey: idempotencyKey,
    );
  }

  @override
  Future<Either<Failure, List<TransactionEntity>>> getTransactions({
    int page = 1,
    int pageSize = 20,
  }) async {
    final result = await remoteDatasource.getTransactions(
      page: page,
      pageSize: pageSize,
    );

    return result.map((list) => list.items.cast<TransactionEntity>());
  }

  @override
  Future<Either<Failure, TopUpQuoteEntity>> updateTopUp({
    required String topUpId,
    required int amountVnd,
    required String idempotencyKey,
  }) async {
    return await remoteDatasource.updateTopUp(
      topUpId: topUpId,
      amountVnd: amountVnd,
      idempotencyKey: idempotencyKey,
    );
  }

  @override
  Future<Either<Failure, void>> cancelTopUp(String topUpId) async {
    return await remoteDatasource.cancelTopUp(topUpId);
  }

  @override
  Future<Either<Failure, Uint8List>> getQrImageBytes(String orderId) async {
    return await remoteDatasource.getQrImageBytes(orderId);
  }

  @override
  Future<Either<Failure, bool>> checkTopUpSuccessByOrderId(
    String orderId, {
    int? previousBalance,
    int? expectedBvc,
    DateTime? quoteCreatedAt,
  }) async {
    // Lấy transactions + wallet balance song song để tiết kiệm thời gian
    // polling (mỗi lần 5s).
    final futures = <Future<dynamic>>[
      remoteDatasource.getTransactions(page: 1, pageSize: 10),
    ];
    if (previousBalance != null) {
      futures.add(remoteDatasource.getWallet());
    }

    final txResult = await futures[0];
    final walletResult = futures.length > 1 ? await futures[1] : null;

    if (txResult is! Either<Failure, dynamic>) {
      return Left(ServerFailure(message: 'Invalid datasource response'));
    }

    return txResult.map((txPage) {
      final txs = (txPage as dynamic).items as List<TransactionEntity>;

      // ── Tier 1: relatedPaymentRef match ─────────────────────────
      // Backend lý tưởng gắn `relatedPaymentRef` cho transaction SePay
      // trả về. Nếu có → match và trả true ngay.
      if (txs.any((tx) => tx.relatedPaymentRef == orderId)) return true;

      // ── Tier 2: TopUp transaction tạo SAU quoteCreatedAt ────────
      // Backend hiện tại không gắn `relatedPaymentRef` → fallback
      // phát hiện theo timestamp. Tier này vẫn an toàn vì user thường
      // chỉ tạo 1 top-up tại 1 thời điểm.
      if (quoteCreatedAt != null) {
        final recentTopUp = txs.any((tx) =>
            tx.type == TransactionType.topUp &&
            tx.amount > 0 &&
            !tx.createdAt.isBefore(quoteCreatedAt));
        if (recentTopUp) return true;
      }

      // ── Tier 3: Balance delta ────────────────────────────────────
      // Nếu balance hiện tại tăng >= expectedBvc so với trước khi
      // nạp → chắc chắn SePay đã webhook.
      if (previousBalance != null && walletResult is Either<Failure, WalletEntity>) {
        return walletResult.fold(
          (_) => false,
          (wallet) {
            final delta = wallet.availableBalance - previousBalance;
            final minDelta = expectedBvc ?? 1;
            return delta >= minDelta;
          },
        );
      }

      return false;
    });
  }
}
