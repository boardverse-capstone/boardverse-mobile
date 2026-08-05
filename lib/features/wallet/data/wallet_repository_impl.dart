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
  Future<Either<Failure, TransactionEntity>> getTransactionById(
      String transactionId) async {
    return await remoteDatasource.getTransactionById(transactionId);
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
  Future<Either<Failure, bool>> checkTopUpSuccessByOrderId(String orderId) async {
    // Gọi transactions để check xem có transaction nào match với orderId
    final result = await remoteDatasource.getTransactions(page: 1, pageSize: 10);

    return result.map((page) {
      // Tìm transaction có relatedPaymentRef = orderId
      // Backend format orderId là "BVC-XXXXXXXXXX"
      return page.items.any((tx) => tx.relatedPaymentRef == orderId);
    });
  }
}
