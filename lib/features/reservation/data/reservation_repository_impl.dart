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
    int pageSize = 10,
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
    required int minPlayers,
    required int maxPlayers,
    required String idempotencyKey,
  }) async {
    final request = QuoteRequestModel(
      cafeId: cafeId,
      gameId: gameId,
      playDate: playDate,
      timeSlot: timeSlot.name,
      preferredStartTime: preferredStartTime,
      minPlayers: minPlayers,
      maxPlayers: maxPlayers,
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
    required int minPlayers,
    required int maxPlayers,
    required int expectedFinalDeposit,
    required String idempotencyKey,
  }) async {
    final request = ConfirmRequestModel(
      cafeId: cafeId,
      gameId: gameId,
      playDate: playDate,
      timeSlot: timeSlot.name,
      preferredStartTime: preferredStartTime,
      minPlayers: minPlayers,
      maxPlayers: maxPlayers,
      expectedFinalDeposit: expectedFinalDeposit,
      idempotencyKey: idempotencyKey,
    );

    return await remoteDatasource.confirmReservation(request);
  }

  @override
  Future<Either<Failure, ReservationCancelResult>> cancelReservation({
    required String reservationId,
    String? reason,
  }) async {
    return await remoteDatasource.cancelReservation(reservationId, reason);
  }

  @override
  Future<Either<Failure, ReservationEntity>> getReservation(String reservationId) async {
    return await remoteDatasource.getReservation(reservationId);
  }

  @override
  Future<Either<Failure, List<ReservationEntity>>> getMyHostedReservations() async {
    final result = await remoteDatasource.getMyHostedReservations();
    return result.map((list) => list.cast<ReservationEntity>());
  }

  @override
  Future<Either<Failure, List<ReservationEntity>>>
      getMyParticipatingReservations() async {
    final result = await remoteDatasource.getMyParticipatingReservations();
    return result.map((list) => list.cast<ReservationEntity>());
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
}
