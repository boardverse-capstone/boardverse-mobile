import 'dart:async';
import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import '../domain/entities/deposit_entity.dart';
import '../domain/entities/booking_qr_entity.dart';
import '../domain/repositories/booking_repository.dart';
import 'datasources/mock_booking_datasource.dart';
import 'models/deposit_model.dart';

class BookingRepositoryImpl implements BookingRepository {
  final _depositStreamController = StreamController<DepositModel>.broadcast();

  BookingRepositoryImpl();

  @override
  Future<Either<Failure, DepositEntity>> initiateDeposit({
    required String lobbyId,
    required double amount,
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      final deposit = MockBookingDatasource.mockDepositStatusList;
      return Right(deposit.toEntity());
    } catch (e) {
      return Left(
        ServerFailure(message: 'Lỗi khởi tạo đặt cọc: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, DepositEntity>> makeDeposit(String depositId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      var deposit = MockBookingDatasource.mockDepositStatusList;
      deposit = MockBookingDatasource.simulateDepositMade(deposit, 'user_002');
      _depositStreamController.add(deposit);
      return Right(deposit.toEntity());
    } catch (e) {
      return Left(ServerFailure(message: 'Lỗi đặt cọc: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, BookingQrEntity>> confirmBooking(
    String depositId,
  ) async {
    try {
      await Future.delayed(const Duration(milliseconds: 800));
      final qr = MockBookingDatasource.mockBookingQrPayload;
      return Right(qr.toEntity());
    } catch (e) {
      return Left(
        ServerFailure(message: 'Lỗi xác nhận đặt chỗ: ${e.toString()}'),
      );
    }
  }

  @override
  Stream<DepositEntity> watchDepositStatus(String depositId) {
    _depositStreamController.add(MockBookingDatasource.mockDepositStatusList);
    return _depositStreamController.stream.map((m) => m.toEntity());
  }

  @override
  Future<Either<Failure, List<BookingHistoryEntity>>>
  getBookingHistory() async {
    try {
      await Future.delayed(const Duration(milliseconds: 400));
      return const Right([]);
    } catch (e) {
      return Left(ServerFailure(message: 'Lỗi lấy lịch sử: ${e.toString()}'));
    }
  }

  void dispose() {
    _depositStreamController.close();
  }
}
