import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../../core/error/failures.dart';
import '../../domain/entities/entities.dart';
import '../models/models.dart';

/// Mock implementation for development/testing
/// Sử dụng khi backend chưa implement wallet API
class WalletMockDatasource {
  final Dio dio;
  final FlutterSecureStorage storage;

  WalletMockDatasource({
    required this.dio,
    required this.storage,
  });

  // In-memory mock data
  static int _mockAvailableBalance = 0;
  static int _mockHeldBalance = 0;
  static final List<TransactionModel> _mockTransactions = [];
  static final Map<String, TopUpQuoteModel> _mockTopUps = {};

  Future<Either<Failure, WalletModel>> getWallet({bool includeHeld = false}) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    return Right(WalletModel(
      userId: 'mock-user-id',
      availableBalance: _mockAvailableBalance,
      heldBalance: _mockHeldBalance,
      riskLevel: RiskLevel.low,
      isCoolingOff: false,
      accountStatus: AccountStatus.active,
    ));
  }

  Future<Either<Failure, TopUpQuoteModel>> createTopUp({
    required int amountVnd,
    required String idempotencyKey,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Validate amount
    if (amountVnd < 10000) {
      return Left(BadRequestFailure(
        message: 'Số tiền tối thiểu là 10.000 VND',
      ));
    }

    if (amountVnd % 1000 != 0) {
      return Left(BadRequestFailure(
        message: 'Số tiền phải chia hết cho 1.000',
      ));
    }

    final expectedBvc = amountVnd ~/ 1000;

    // Generate mock payment URL
    final orderId = 'BVC-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

    final quote = TopUpQuoteModel(
      paymentUrl: 'https://pay.sepay.vn/mock?order=$orderId',
      qrUrl: 'https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=$orderId',
      orderId: orderId,
      topUpId: orderId, // mock dùng orderId làm topUpId
      expectedBvc: expectedBvc,
      expiresAt: DateTime.now().add(const Duration(minutes: 15)),
      idempotencyKey: idempotencyKey,
    );
    _mockTopUps[orderId] = quote;
    return Right(quote);
  }

  Future<Either<Failure, TransactionListModel>> getTransactions({
    int page = 1,
    int pageSize = 20,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    return Right(TransactionListModel(
      items: _mockTransactions,
      page: page,
      pageSize: pageSize,
      totalItems: _mockTransactions.length,
      hasMore: false,
    ));
  }

  /// Simulate successful top-up (call after user pays)
  Future<void> simulateTopUpSuccess(int amountVnd) async {
    final expectedBvc = amountVnd ~/ 1000;
    _mockAvailableBalance += expectedBvc;

    final transaction = TransactionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: TransactionType.topUp,
      amount: expectedBvc,
      balanceSnapshot: _mockAvailableBalance,
      relatedPaymentRef: 'BVC-MOCK-${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
    );

    _mockTransactions.insert(0, transaction);
  }

  /// Simulate deposit hold (for testing)
  Future<void> simulateDepositHold(int amountBvc) async {
    if (_mockAvailableBalance >= amountBvc) {
      _mockAvailableBalance -= amountBvc;
      _mockHeldBalance += amountBvc;

      final transaction = TransactionModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: TransactionType.depositHold,
        amount: amountBvc,
        balanceSnapshot: _mockAvailableBalance,
        createdAt: DateTime.now(),
      );

      _mockTransactions.insert(0, transaction);
    }
  }

  /// Simulate deposit release (for testing)
  Future<void> simulateDepositRelease(int amountBvc) async {
    if (_mockHeldBalance >= amountBvc) {
      _mockHeldBalance -= amountBvc;
      _mockAvailableBalance += amountBvc;

      final transaction = TransactionModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: TransactionType.depositRelease,
        amount: amountBvc,
        balanceSnapshot: _mockAvailableBalance,
        createdAt: DateTime.now(),
      );

      _mockTransactions.insert(0, transaction);
    }
  }

  /// Reset mock data (for testing)
  static void resetMockData() {
    _mockAvailableBalance = 0;
    _mockHeldBalance = 0;
    _mockTransactions.clear();
    _mockTopUps.clear();
  }

  Future<Either<Failure, TopUpQuoteModel>> updateTopUp({
    required String topUpId,
    required int amountVnd,
    required String idempotencyKey,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));

    if (amountVnd < 10000) {
      return const Left(BadRequestFailure(
        message: 'Số tiền tối thiểu là 10.000 VND',
      ));
    }
    if (amountVnd % 1000 != 0) {
      return const Left(BadRequestFailure(
        message: 'Số tiền phải chia hết cho 1.000',
      ));
    }

    // Cancelled old order
    _mockTopUps.remove(topUpId);

    final expectedBvc = amountVnd ~/ 1000;
    final orderId = 'BVC-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
    final quote = TopUpQuoteModel(
      paymentUrl: 'https://pay.sepay.vn/mock?order=$orderId',
      qrUrl: 'https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=$orderId',
      orderId: orderId,
      topUpId: orderId, // mock dùng orderId làm topUpId
      expectedBvc: expectedBvc,
      expiresAt: DateTime.now().add(const Duration(minutes: 15)),
      idempotencyKey: idempotencyKey,
    );
    _mockTopUps[orderId] = quote;
    return Right(quote);
  }

  Future<Either<Failure, void>> cancelTopUp(String topUpId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _mockTopUps.remove(topUpId);
    return const Right(null);
  }
}
