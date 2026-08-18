import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/failures.dart';
import '../models/player_scan_result_model.dart';

/// Remote datasource cho player-initiated check-in (BR §21A.7).
abstract class PlayerCheckInRemoteDatasource {
  Future<Either<Failure, PlayerScanResultModel>> scanToken(String token);
}

class PlayerCheckInRemoteDatasourceImpl implements PlayerCheckInRemoteDatasource {
  final Dio dio;

  PlayerCheckInRemoteDatasourceImpl({required this.dio});

  @override
  Future<Either<Failure, PlayerScanResultModel>> scanToken(String token) async {
    try {
      final response = await dio.post(
        ApiEndpoints.playerCheckInScanQr,
        data: {'token': token},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Backend bọc response trong envelope {statusCode, message, data}
        // — lấy `data` rồi parse sang model.
        final body = response.data;
        Map<String, dynamic>? payload;
        if (body is Map<String, dynamic>) {
          if (body['data'] is Map<String, dynamic>) {
            payload = body['data'] as Map<String, dynamic>;
          } else if (body['activeSessionId'] != null ||
              body['sessionId'] != null) {
            // Một số endpoint backend trả thẳng không qua envelope —
            // chấp nhận cả 2 dạng.
            payload = body;
          }
        }

        if (payload == null) {
          return const Left(
            ServerFailure(
              message: 'Phản hồi từ máy chủ không hợp lệ.',
            ),
          );
        }

        return Right(PlayerScanResultModel.fromJson(payload));
      }

      return Left(
        ServerFailure(
          message: 'Không check-in được. Mã lỗi: ${response.statusCode}',
        ),
      );
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  Failure _mapDioError(DioException e) {
    final code = e.response?.statusCode ?? 0;
    final message = e.response?.data is Map<String, dynamic>
        ? (e.response!.data['message'] as String?) ??
            (e.response!.data['detail'] as String?) ??
            _defaultMessage(code)
        : _defaultMessage(code);

    switch (code) {
      case 400:
        return BadRequestFailure(message: message);
      case 401:
        return UnauthorizedFailure(message: message);
      case 403:
        return ForbiddenFailure(message: message);
      case 404:
        return NotFoundFailure(message: message);
      case 409:
        return ConflictFailure(message: message);
      case 410:
        return ServerFailure(
          message: message,
          statusCode: 410,
        );
      case 422:
        return BadRequestFailure(message: message);
      default:
        if (code == 0) {
          return const NetworkFailure();
        }
        return ServerFailure(message: message, statusCode: code);
    }
  }

  String _defaultMessage(int code) {
    if (code == 410) return 'Mã QR đã hết hạn. Vui lòng nhờ nhân viên tạo mã mới.';
    if (code == 409) return 'Mã QR đã được sử dụng bởi người khác.';
    if (code == 403) {
      return 'Bạn không phải thành viên của đơn đặt chỗ này.';
    }
    if (code == 404) return 'Không tìm thấy mã QR hoặc đơn đặt chỗ.';
    if (code == 422) {
      return 'Chưa tới khung giờ check-in hoặc quán không còn bàn trống.';
    }
    if (code >= 500) return 'Lỗi máy chủ ($code). Vui lòng thử lại sau.';
    if (code == 0) return 'Không có kết nối mạng.';
    return 'Yêu cầu thất bại ($code).';
  }
}
