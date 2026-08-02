import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../domain/entities/booking_entity.dart';
import '../domain/entities/booking_history_entity.dart';
import '../domain/entities/booking_rating_submission_entity.dart';
import '../domain/entities/cafe_availability_entity.dart';
import '../domain/entities/cafe_booking_summary_entity.dart';
import '../domain/entities/cafe_table_entity.dart';
import '../domain/entities/deposit_config_entity.dart';
import '../domain/entities/deposit_payment_entity.dart';
import '../domain/entities/deposit_status_entity.dart';
import '../domain/entities/lobby_booking_summary_entity.dart';
import '../domain/entities/no_show_vote_result_entity.dart';
import '../domain/entities/rating_status_entity.dart';
import '../domain/entities/session_status_entity.dart';
import '../domain/enums/booking_status.dart';
import '../domain/repositories/booking_repository.dart';
import 'booking_persistence_service.dart';
import 'datasources/base/booking_rating_remote_datasource.dart';
import 'datasources/base/booking_remote_datasource.dart';
import 'datasources/base/bookings_by_cafe_remote_datasource.dart';
import 'datasources/base/cafe_availability_remote_datasource.dart';
import 'datasources/base/cafe_table_remote_datasource.dart';
import 'datasources/base/session_status_remote_datasource.dart';

/// Triển khai `BookingRepository` — orchestrate giữa remote datasource
/// (REST + SePay) và persistence service (secure storage cho resume).
///
/// Toàn bộ flow đi đúng đặc tả mới:
/// - Không lưu `pendingBookingId` ngay khi `createBooking`: chỉ lưu sau
///   khi `createDepositPayment` trả về `depositId` (BR-06: grace 30').
/// - `loadAllForUser` không gọi endpoint history cũ — duyệt
///   hosted + joined lobbies rồi fetch từng `GET /api/bookings/lobby/{id}`.
/// - Hỗ trợ walk-in (`lobbyId == null`) theo gap #3.
class BookingRepositoryImpl implements BookingRepository {
  final BookingRemoteDatasource datasource;
  final CafeTableRemoteDatasource? cafeTableDatasource;
  final CafeAvailabilityRemoteDatasource? cafeAvailabilityDatasource;
  final BookingRatingRemoteDatasource? bookingRatingDatasource;
  final SessionStatusRemoteDatasource? sessionStatusDatasource;
  final BookingsByCafeRemoteDatasource? bookingsByCafeDatasource;
  final BookingPersistenceService persistence;

  BookingRepositoryImpl({
    required this.datasource,
    this.cafeTableDatasource,
    this.cafeAvailabilityDatasource,
    this.bookingRatingDatasource,
    this.sessionStatusDatasource,
    this.bookingsByCafeDatasource,
    required this.persistence,
  });

  @override
  Future<Either<Failure, DepositConfigEntity>> getDepositConfig(
    String cafeId,
  ) =>
      datasource.getDepositConfig(cafeId);

  @override
  Future<Either<Failure, BookingEntity>> createBooking({
    String? lobbyId,
    required String cafeId,
    required String cafeTableId,
    required DateTime scheduledStartTime,
    required DateTime scheduleEndTime,
    int? playerQuantity,
  }) =>
      datasource.createBooking(
        lobbyId: lobbyId,
        cafeId: cafeId,
        cafeTableId: cafeTableId,
        scheduledStartTime: scheduledStartTime,
        scheduleEndTime: scheduleEndTime,
        playerQuantity: playerQuantity,
      );

  @override
  Future<Either<Failure, List<CafeTableEntity>>> getAvailableTables({
    required String cafeId,
    required DateTime scheduledStartTime,
    required DateTime scheduleEndTime,
    required int seatCount,
  }) {
    final tableDatasource = cafeTableDatasource;
    if (tableDatasource == null) {
      return Future.value(
        const Left<Failure, List<CafeTableEntity>>(
          ServerFailure(message: 'Chưa cấu hình dịch vụ tra bàn trống'),
        ),
      );
    }
    return tableDatasource.getAvailableTables(
      cafeId: cafeId,
      scheduledStartTime: scheduledStartTime,
      scheduleEndTime: scheduleEndTime,
      seatCount: seatCount,
    );
  }

  @override
  Future<Either<Failure, CafeAvailabilityEntity>> getCafeAvailability({
    required String cafeId,
    required DateTime startTime,
    required DateTime endTime,
    int? seatCount,
    String? gameTemplateId,
  }) {
    final availabilityDs = cafeAvailabilityDatasource;
    if (availabilityDs == null) {
      return Future.value(
        const Left<Failure, CafeAvailabilityEntity>(
          ServerFailure(message: 'Chưa cấu hình dịch vụ availability'),
        ),
      );
    }
    return availabilityDs.getAvailability(
      cafeId: cafeId,
      startTime: startTime,
      endTime: endTime,
      seatCount: seatCount,
      gameTemplateId: gameTemplateId,
    );
  }

  @override
  Future<Either<Failure, BookingEntity>> getBookingById(String id) =>
      datasource.getBookingById(id);

  @override
  Future<Either<Failure, BookingEntity?>> getBookingByLobby(String lobbyId) =>
      datasource.getBookingByLobby(lobbyId);

  @override
  Future<Either<Failure, BookingEntity>> cancelBookingByPlayer({
    required String bookingId,
    required String reason,
  }) =>
      datasource.cancelBookingByPlayer(
        bookingId: bookingId,
        reason: reason,
      ).then((result) async {
        return result.fold(
          (failure) async => Left<Failure, BookingEntity>(failure),
          (booking) async {
            await persistence.clearPendingBookingId();
            await persistence.clearPendingDepositId();
            return Right<Failure, BookingEntity>(booking);
          },
        );
      });

  // ─── Deposit ──────────────────────────────────────────────────────

  @override
  Future<Either<Failure, DepositPaymentEntity>> createDepositPayment(
    String bookingId,
  ) =>
      datasource.createDepositPayment(bookingId).then((result) async {
        return result.fold(
          (failure) async => Left<Failure, DepositPaymentEntity>(failure),
          (payment) async {
            await persistence.savePendingBookingId(bookingId);
            await persistence.savePendingDepositId(payment.depositId);
            return Right<Failure, DepositPaymentEntity>(payment);
          },
        );
      });

  @override
  Future<Either<Failure, DepositPaymentEntity>>
      createDepositPaymentWithDetails({
    required String bookingId,
    String? cafeId,
    String? lobbyId,
    DateTime? scheduledStartTime,
    int? seatCount,
    double? amount,
  }) =>
          datasource
              .createDepositPaymentWithDetails(
            bookingId: bookingId,
            cafeId: cafeId,
            lobbyId: lobbyId,
            scheduledStartTime: scheduledStartTime,
            seatCount: seatCount,
            amount: amount,
          )
              .then((result) async {
            return result.fold(
              (failure) async =>
                  Left<Failure, DepositPaymentEntity>(failure),
              (payment) async {
                await persistence.savePendingBookingId(bookingId);
                await persistence.savePendingDepositId(payment.depositId);
                return Right<Failure, DepositPaymentEntity>(payment);
              },
            );
          });

  @override
  Stream<Either<Failure, DepositStatusEntity>> pollDepositStatus(
    String depositId, {
    Duration interval = const Duration(seconds: 3),
  }) async* {
    bool shouldStop = false;
    while (!shouldStop) {
      final result = await datasource.getDepositStatus(depositId);
      yield result;
      if (result.isRight()) {
        final status = result.getOrElse(() => throw StateError('unreachable'));
        if (status.status == DepositStatus.paid) {
          await persistence.clearPendingBookingId();
          await persistence.clearPendingDepositId();
          shouldStop = true;
        } else if (status.status == DepositStatus.refunded ||
            status.status == DepositStatus.forfeited ||
            status.status == DepositStatus.expired) {
          shouldStop = true;
        }
      }
      if (shouldStop) return;
      await Future<void>.delayed(interval);
    }
  }

  @override
  Future<Either<Failure, DepositStatusEntity>> getDepositStatus(
    String depositId,
  ) =>
      datasource.getDepositStatus(depositId);

  @override
  Future<Either<Failure, DepositPaymentEntity>> regenerateDepositQr(
    String depositId,
  ) =>
      datasource.regenerateDepositQr(depositId);

  @override
  Future<Either<Failure, DepositStatusEntity>> getDepositByOrder(
    String orderId,
  ) =>
      datasource.getDepositByOrder(orderId);

  @override
  Future<Either<Failure, DepositStatusEntity>> refundDeposit({
    required String depositId,
    required String reason,
  }) =>
      datasource.refundDeposit(depositId: depositId, reason: reason);

  // ─── NoShow + Rating (gap #4, #5) ─────────────────────────────────

  @override
  Future<Either<Failure, NoShowVoteResultEntity>> submitNoShowVote({
    required String bookingId,
    required List<String> absentMemberIds,
    DateTime? votedAt,
  }) {
    final ds = bookingRatingDatasource;
    if (ds == null) {
      return Future.value(
        const Left<Failure, NoShowVoteResultEntity>(
          ServerFailure(message: 'Chưa cấu hình dịch vụ rating'),
        ),
      );
    }
    return ds.submitNoShowVote(
      bookingId: bookingId,
      absentMemberIds: absentMemberIds,
      votedAt: votedAt,
    );
  }

  @override
  Future<Either<Failure, RatingSubmissionResultEntity>> submitRatings(
    BookingRatingSubmissionEntity submission,
  ) {
    final ds = bookingRatingDatasource;
    if (ds == null) {
      return Future.value(
        const Left<Failure, RatingSubmissionResultEntity>(
          ServerFailure(message: 'Chưa cấu hình dịch vụ rating'),
        ),
      );
    }
    return ds.submitRatings(submission);
  }

  @override
  Future<Either<Failure, RatingStatusEntity>> getRatingStatus(
    String bookingId,
  ) {
    final ds = bookingRatingDatasource;
    if (ds == null) {
      return Future.value(
        const Left<Failure, RatingStatusEntity>(
          ServerFailure(message: 'Chưa cấu hình dịch vụ rating'),
        ),
      );
    }
    return ds.getRatingStatus(bookingId);
  }

  // ─── Session realtime (gap #8) ───────────────────────────────────

  @override
  Future<Either<Failure, SessionStatusEntity>> getSessionStatus(
    String bookingId,
  ) {
    final ds = sessionStatusDatasource;
    if (ds == null) {
      return Future.value(
        const Left<Failure, SessionStatusEntity>(
          ServerFailure(message: 'Chưa cấu hình dịch vụ session-status'),
        ),
      );
    }
    return ds.getSessionStatus(bookingId);
  }

  // ─── Cafe view cho Player (gap #14) ──────────────────────────────

  @override
  Future<Either<Failure, List<CafeBookingSummaryEntity>>> getBookingsForCafe(
    String cafeId,
  ) {
    final ds = bookingsByCafeDatasource;
    if (ds == null) {
      return Future.value(
        const Left<Failure, List<CafeBookingSummaryEntity>>(
          ServerFailure(message: 'Chưa cấu hình dịch vụ bookings-by-cafe'),
        ),
      );
    }
    return ds.getBookingsForCafe(cafeId);
  }

  // ─── Lobby helpers ────────────────────────────────────────────────

  @override
  Future<Either<Failure, LobbyBookingSummaryEntity>> getLobbyBookingSummary(
    String lobbyId,
  ) =>
      datasource.getLobbyBookingSummary(lobbyId);

  /// Load tổng hợp bookings cho 1 user.
  ///
  /// Backend không còn `GET /api/bookings/history` cho Player — phải
  /// duyệt hosted + joined lobbies rồi fetch từng booking.
  @override
  Future<Either<Failure, UpcomingAndHistory>> loadAllForUser() async {
    final hosted = await datasource.getHostedLobbyIds();
    final joined = await datasource.getJoinedLobbyIds();
    final ids = <String>{};
    for (final hostedResult in [hosted, joined]) {
      final list = hostedResult.getOrElse(() => const <String>[]);
      ids.addAll(list);
    }

    if (ids.isEmpty) {
      return const Right<Failure, UpcomingAndHistory>(
        UpcomingAndHistory(upcoming: [], history: []),
      );
    }

    final bookings = <BookingEntity>[];
    for (final lobbyId in ids) {
      final r = await datasource.getBookingByLobby(lobbyId);
      final BookingEntity? maybeBooking;
      maybeBooking = r.fold<BookingEntity?>(
        (failure) => null,
        (data) => data,
      );
      if (maybeBooking != null) bookings.add(maybeBooking);
    }

    final upcoming = <BookingEntity>[];
    final history = <BookingHistoryEntity>[];
    for (final b in bookings) {
      if (b.status.isActive || b.status == BookingStatus.checkedIn) {
        upcoming.add(b);
      } else {
        history.add(
          BookingHistoryEntity(
            id: b.id,
            lobbyId: b.lobbyId ?? '',
            cafeId: b.cafeId,
            cafeName: b.cafeName,
            gameName: b.gameName,
            scheduledTime: b.scheduledTime,
            scheduleEndTime: b.scheduleEndTime,
            status: b.status,
            depositAmount: b.depositAmount,
            verificationQrCode: b.verificationQrCode,
          ),
        );
      }
    }

    upcoming.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
    history.sort((a, b) => b.scheduledTime.compareTo(a.scheduledTime));

    return Right<Failure, UpcomingAndHistory>(
      UpcomingAndHistory(upcoming: upcoming, history: history),
    );
  }

  // ─── Resume helpers ──────────────────────────────────────────────

  @override
  Future<Either<Failure, Unit>> savePendingBookingId(String id) async {
    try {
      await persistence.savePendingBookingId(id);
      return const Right<Failure, Unit>(unit);
    } catch (e) {
      return Left<Failure, Unit>(
        CacheFailure(message: 'Không thể lưu booking id: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, Unit>> savePendingDepositId(String id) async {
    try {
      await persistence.savePendingDepositId(id);
      return const Right<Failure, Unit>(unit);
    } catch (e) {
      return Left<Failure, Unit>(
        CacheFailure(message: 'Không thể lưu deposit id: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, String?>> getPendingBookingId() async {
    try {
      final id = await persistence.getPendingBookingId();
      return Right<Failure, String?>(id);
    } catch (e) {
      return Left<Failure, String?>(
        CacheFailure(message: 'Không thể đọc booking id: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, String?>> getPendingDepositId() async {
    try {
      final id = await persistence.getPendingDepositId();
      return Right<Failure, String?>(id);
    } catch (e) {
      return Left<Failure, String?>(
        CacheFailure(message: 'Không thể đọc deposit id: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, Unit>> clearPendingBookingId() async {
    try {
      await persistence.clearPendingBookingId();
      return const Right<Failure, Unit>(unit);
    } catch (e) {
      return Left<Failure, Unit>(
        CacheFailure(message: 'Không thể xoá booking id: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, Unit>> clearPendingDepositId() async {
    try {
      await persistence.clearPendingDepositId();
      return const Right<Failure, Unit>(unit);
    } catch (e) {
      return Left<Failure, Unit>(
        CacheFailure(message: 'Không thể xoá deposit id: $e'),
      );
    }
  }
}
