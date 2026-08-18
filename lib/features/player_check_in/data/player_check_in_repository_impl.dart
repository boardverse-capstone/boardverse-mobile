import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import '../domain/entities/player_scan_result_entity.dart';
import '../domain/repositories/player_check_in_repository.dart';
import 'datasources/player_check_in_remote_datasource.dart';

/// Default implementation cho [PlayerCheckInRepository].
class PlayerCheckInRepositoryImpl implements PlayerCheckInRepository {
  final PlayerCheckInRemoteDatasource remote;

  PlayerCheckInRepositoryImpl({required this.remote});

  @override
  Future<Either<Failure, PlayerScanResultEntity>> scanToken({
    required String token,
  }) async {
    final normalized = PlayerCheckInRepository.normalize(token);
    if (normalized == null) {
      return const Left(
        BadRequestFailure(
          message: 'Vui lòng nhập mã QR mà quán cung cấp.',
        ),
      );
    }
    if (!PlayerCheckInRepository.isValidTokenFormat(normalized)) {
      return const Left(
        BadRequestFailure(
          message:
              'Mã QR phải gồm đúng 16 ký tự in hoa (A–Z, 2–9), ví dụ: ABCDEFGHJKLMNPQR.',
        ),
      );
    }

    final result = await remote.scanToken(normalized);
    return result.fold(
      Left.new,
      (model) => Right(
        PlayerScanResultEntity(
          activeSessionId: model.activeSessionId,
          reservationId: model.reservationId,
          cafeId: model.cafeId,
          checkedInAt: model.checkedInAt,
          reservationStatus: model.reservationStatus,
        ),
      ),
    );
  }
}
