import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import '../../../core/network/paginated_response.dart';
import '../domain/entities/entities.dart';
import '../domain/repositories/reservation_repository.dart';
import 'datasources/reservation_remote_datasource.dart';
import 'models/models.dart';

/// Implementation of ReservationRepository
class ReservationRepositoryImpl implements ReservationRepository {
  final ReservationRemoteDatasource remoteDatasource;

  ReservationRepositoryImpl({required this.remoteDatasource});

  @override
  Future<Either<Failure, PaginatedResponse<ReservationEntity>>> getReservations({
    List<String>? statuses,
    DateTime? playDate,
    String? cafeId,
    bool? hostedByMe,
    bool? joinedByMe,
    int page = 1,
    int pageSize = 20,
  }) async {
    final result = await remoteDatasource.getReservations(
      statuses: statuses,
      playDate: playDate,
      cafeId: cafeId,
      hostedByMe: hostedByMe,
      joinedByMe: joinedByMe,
      page: page,
      pageSize: pageSize,
    );
    return result;
  }

  @override
  Future<Either<Failure, ReservationQuoteEntity>> createQuote({
    required String cafeId,
    required String gameId,
    required DateTime playDate,
    required TimeSlot timeSlot,
    String? preferredStartTime,
    String? preferredEndTime,
    required int minPlayers,
    required int maxPlayers,
    required bool isPrivate,
    required String idempotencyKey,
  }) async {
    final request = QuoteRequestModel(
      cafeId: cafeId,
      gameId: gameId,
      playDate: playDate,
      timeSlot: timeSlot.name,
      preferredStartTime: preferredStartTime,
      preferredEndTime: preferredEndTime,
      minPlayers: minPlayers,
      maxPlayers: maxPlayers,
      isPrivate: isPrivate,
      idempotencyKey: idempotencyKey,
    );

    return await remoteDatasource.createQuote(request);
  }

  @override
  Future<Either<Failure, ReservationConfirmResult>> confirmReservation({
    required String cafeId,
    required String gameId,
    required DateTime playDate,
    required TimeSlot timeSlot,
    String? preferredStartTime,
    String? preferredEndTime,
    required int minPlayers,
    required int maxPlayers,
    required bool isPrivate,
    required int expectedFinalDeposit,
    required String idempotencyKey,
  }) async {
    final request = ConfirmRequestModel(
      cafeId: cafeId,
      gameId: gameId,
      playDate: playDate,
      timeSlot: timeSlot.name,
      preferredStartTime: preferredStartTime,
      preferredEndTime: preferredEndTime,
      minPlayers: minPlayers,
      maxPlayers: maxPlayers,
      isPrivate: isPrivate,
      expectedFinalDeposit: expectedFinalDeposit,
      idempotencyKey: idempotencyKey,
    );

    return await remoteDatasource.confirmReservation(request);
  }

  @override
  Future<Either<Failure, ReservationCancelResult>> cancelReservation({
    required String reservationId,
    String? reason,
    required String idempotencyKey,
  }) async {
    return await remoteDatasource.cancelReservation(
      reservationId,
      reason,
      idempotencyKey,
    );
  }

  @override
  Future<Either<Failure, ReservationEntity>> getReservation(String reservationId) async {
    return await remoteDatasource.getReservation(reservationId);
  }

  @override
  Future<Either<Failure, ReservationEntity>> getReservationDetail(
      String reservationId) async {
    return await remoteDatasource.getReservation(reservationId);
  }

  @override
  Future<Either<Failure, PaginatedResponse<ReservationEntity>>>
      getPendingCafeApprovals({
    String? cafeId,
    DateTime? playDate,
    int page = 1,
    int pageSize = 20,
  }) async {
    return await remoteDatasource.getReservations(
      statuses: const [
        'awaitingCafeApproval',
        'pendingCafeApproval',
      ],
      playDate: playDate,
      cafeId: cafeId,
      page: page,
      pageSize: pageSize,
    );
  }

  @override
  Future<Either<Failure, void>> cafeApproval({
    required String reservationId,
    required bool approve,
    String? reason,
  }) async {
    final request = CafeApprovalRequestModel(
      approve: approve,
      reason: reason,
    );

    return await remoteDatasource.cafeApproval(reservationId, request);
  }

  @override
  Future<Either<Failure, ReservationCancelAfterCheckinResult>>
      cancelAfterCheckin({
    required String reservationId,
    String? reason,
    required String idempotencyKey,
  }) async {
    final request = CancelAfterCheckinRequest(
      reservationId: reservationId,
      reason: reason,
      idempotencyKey: idempotencyKey,
    );

    return await remoteDatasource.cancelAfterCheckin(request);
  }

  @override
  Future<Either<Failure, ExtendAvailabilityResult>> checkExtendAvailability({
    required String reservationId,
    required int extensionMinutes,
  }) async {
    return await remoteDatasource.checkExtendAvailability(
      reservationId,
      extensionMinutes,
    );
  }

  @override
  Future<Either<Failure, CheckInByCodeResult>> checkInByCode({
    required String reservationCode,
    required String cafeId,
    required String activeSessionId,
    required String idempotencyKey,
  }) async {
    final request = CheckInByCodeRequest(
      cafeId: cafeId,
      reservationCode: reservationCode,
      activeSessionId: activeSessionId,
      idempotencyKey: idempotencyKey,
    );

    return await remoteDatasource.checkInByCode(reservationCode, request);
  }
}
