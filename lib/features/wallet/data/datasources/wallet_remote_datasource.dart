import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../../core/constants/api_endpoints.dart';
import '../../../../../core/error/failures.dart';
import '../models/models.dart';

/// Base interface cho wallet remote datasource
abstract class WalletRemoteDatasource {
  /// Lấy thông tin ví (auto-create nếu chưa có)
  Future<Either<Failure, WalletModel>> getWallet({bool includeHeld = false});

  /// Tạo đơn top-up
  Future<Either<Failure, TopUpQuoteModel>> createTopUp({
    required int amountVnd,
    required String idempotencyKey,
  });

  /// Lấy lịch sử giao dịch
  Future<Either<Failure, TransactionListModel>> getTransactions({
    int page = 1,
    int pageSize = 20,
  });

  /// Lấy chi tiết giao dịch
  Future<Either<Failure, TransactionModel>> getTransactionById(String transactionId);

  /// PATCH /api/v1/wallet/topup/{topUpId}
  /// Đổi số tiền đơn top-up BVC đang Pending (chưa thanh toán).
  /// Đơn cũ = Cancelled, đơn mới = Pending với SePay URL mới.
  Future<Either<Failure, TopUpQuoteModel>> updateTopUp({
    required String topUpId,
    required int amountVnd,
    required String idempotencyKey,
  });

  /// DELETE /api/v1/wallet/topup/{topUpId}
  /// Hủy đơn top-up BVC đang Pending (chưa thanh toán).
  /// Set local flag Status = Cancelled. Webhook SePay sau sẽ tự reject.
  Future<Either<Failure, void>> cancelTopUp(String topUpId);
}

/// Implementation using Dio
class WalletRemoteDatasourceImpl implements WalletRemoteDatasource {
  final Dio dio;

  WalletRemoteDatasourceImpl({required this.dio});

  @override
  Future<Either<Failure, WalletModel>> getWallet({bool includeHeld = false}) async {
    try {
      final response = await dio.get(
        ApiEndpoints.wallet,
        queryParameters: {'includeHeld': includeHeld},
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>;
        return Right(WalletModel.fromJson(data));
      }

      return Left(ServerFailure(message: 'Failed to get wallet: ${response.statusCode}'));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, TopUpQuoteModel>> createTopUp({
    required int amountVnd,
    required String idempotencyKey,
  }) async {
    try {
      final response = await dio.post(
        ApiEndpoints.walletTopup,
        data: {
          'amountVnd': amountVnd,
          'idempotencyKey': idempotencyKey,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>;
        return Right(TopUpQuoteModel.fromJson(data));
      }

      return Left(ServerFailure(message: 'Failed to create top-up: ${response.statusCode}'));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, TransactionListModel>> getTransactions({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await dio.get(
        ApiEndpoints.walletTransactions,
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>;
        return Right(TransactionListModel.fromJson(data));
      }

      return Left(ServerFailure(message: 'Failed to get transactions: ${response.statusCode}'));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, TransactionModel>> getTransactionById(String transactionId) async {
    try {
      final response = await dio.get(
        '${ApiEndpoints.walletTransactions}/$transactionId',
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>;
        return Right(TransactionModel.fromJson(data));
      }

      return Left(ServerFailure(message: 'Failed to get transaction: ${response.statusCode}'));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, TopUpQuoteModel>> updateTopUp({
    required String topUpId,
    required int amountVnd,
    required String idempotencyKey,
  }) async {
    try {
      final response = await dio.patch(
        ApiEndpoints.walletTopupUpdate(topUpId),
        data: {
          'amountVnd': amountVnd,
          'idempotencyKey': idempotencyKey,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>;
        return Right(TopUpQuoteModel.fromJson(data));
      }

      return Left(ServerFailure(
        message: 'Failed to update top-up: ${response.statusCode}',
      ));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> cancelTopUp(String topUpId) async {
    try {
      final response = await dio.delete(ApiEndpoints.walletTopupCancel(topUpId));

      if (response.statusCode == 200) {
        return const Right(null);
      }

      return Left(ServerFailure(
        message: 'Failed to cancel top-up: ${response.statusCode}',
      ));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  Failure _handleDioError(DioException e) {
    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final message = e.response!.data?['message'] as String? ?? 'Unknown error';

      switch (statusCode) {
        case 400:
          return BadRequestFailure(message: message);
        case 401:
          return UnauthorizedFailure(message: 'Unauthorized');
        case 403:
          return ForbiddenFailure(message: message);
        case 404:
          return NotFoundFailure(message: message);
        case 409:
          return ConflictFailure(message: message);
        default:
          return ServerFailure(message: message);
      }
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkFailure(message: 'Connection timeout');
      case DioExceptionType.connectionError:
        return NetworkFailure(message: 'No internet connection');
      default:
        return ServerFailure(message: e.message ?? 'Unknown error');
    }
  }
}
