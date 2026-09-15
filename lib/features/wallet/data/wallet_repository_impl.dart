import 'dart:typed_data';

import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import '../domain/entities/entities.dart';
import '../domain/repositories/wallet_repository.dart';
import 'datasources/wallet_remote_datasource.dart';

/// Implementation of [WalletRepository] using remote datasource.
class WalletRepositoryImpl implements WalletRepository {
  final WalletRemoteDatasource remoteDatasource;

  WalletRepositoryImpl({required this.remoteDatasource});

  @override
  Future<Either<Failure, WalletEntity>> getWallet() async {
    return await remoteDatasource.getWallet();
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
    // Tải transactions và (nếu cần) wallet song song để giảm thời gian
    // polling.
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

      // 1. Tìm transaction có `relatedPaymentRef` khớp orderId.
      if (txs.any((tx) => tx.relatedPaymentRef == orderId)) return true;

      // 2. Tìm TopUp transaction tạo sau quoteCreatedAt (fallback khi
      //    backend không gắn relatedPaymentRef).
      if (quoteCreatedAt != null) {
        final recentTopUp = txs.any((tx) =>
            tx.type == TransactionType.topUp &&
            tx.amount > 0 &&
            !tx.createdAt.isBefore(quoteCreatedAt));
        if (recentTopUp) return true;
      }

      // 3. Balance delta — nếu balance tăng >= expectedBvc thì chắc
      //    chắn SePay đã webhook.
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
