import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../models/player_session_model.dart';
import '../models/extend_session_model.dart';
import '../models/pay_session_model.dart';
import '../models/session_history_model.dart';
import '../models/split_bill_model.dart';

/// Remote datasource for Player Session APIs
class PlayerSessionRemoteDatasource {
  final Dio dio;

  PlayerSessionRemoteDatasource({required this.dio});

  /// GET /api/v1/sessions/me/current
  /// Lấy thông tin phiên chơi hiện tại của player
  Future<PlayerSessionModel> getCurrentSession() async {
    try {
      final response = await dio.get(ApiEndpoints.sessionCurrent);

      if (response.statusCode == 200) {
        return PlayerSessionModel.fromJson(response.data['data']);
      } else if (response.statusCode == 404) {
        throw PlayerSessionNotFoundException();
      } else {
        throw PlayerSessionApiException(
          message: response.data['message'] ?? 'Lỗi khi lấy phiên chơi',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw PlayerSessionApiException(
        message: e.message ?? 'Lỗi kết nối',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// POST /api/v1/sessions/me/extend
  /// Yêu cầu gia hạn thêm thời gian chơi
  Future<ExtendSessionResponseModel> extendSession(int minutes) async {
    try {
      final response = await dio.post(
        ApiEndpoints.sessionExtend,
        data: {'extensionMinutes': minutes},
      );

      if (response.statusCode == 200) {
        return ExtendSessionResponseModel.fromJson(response.data['data']);
      } else if (response.statusCode == 409) {
        throw PlayerSessionConflictException(
          message: response.data['message'] ?? 'Không thể gia hạn',
        );
      } else if (response.statusCode == 404) {
        throw PlayerSessionNotFoundException();
      } else {
        throw PlayerSessionApiException(
          message: response.data['message'] ?? 'Lỗi khi gia hạn',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw PlayerSessionConflictException(
          message: e.response?.data['message'] ?? 'Không thể gia hạn',
        );
      }
      throw PlayerSessionApiException(
        message: e.message ?? 'Lỗi kết nối',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// POST /api/v1/sessions/me/pay
  /// Thanh toán phiên chơi bằng BVC
  Future<PaySessionResponseModel> paySession(String sessionId) async {
    try {
      final response = await dio.post(
        ApiEndpoints.sessionPay,
        data: {'sessionId': sessionId},
      );

      if (response.statusCode == 200) {
        return PaySessionResponseModel.fromJson(response.data['data']);
      } else if (response.statusCode == 402) {
        throw InsufficientBvcException(
          message: response.data['message'] ?? 'Số dư BVC không đủ',
          requiredBvc: response.data['requiredBvc'],
        );
      } else if (response.statusCode == 409) {
        throw PlayerSessionConflictException(
          message: response.data['message'] ?? 'Không thể thanh toán',
        );
      } else if (response.statusCode == 429) {
        throw RateLimitException(
          message: response.data['message'] ?? 'Vượt quá giới hạn',
          retryAfterSeconds: response.data['retryAfterSeconds'],
        );
      } else {
        throw PlayerSessionApiException(
          message: response.data['message'] ?? 'Lỗi khi thanh toán',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 402) {
        throw InsufficientBvcException(
          message: e.response?.data['message'] ?? 'Số dư BVC không đủ',
          requiredBvc: e.response?.data['requiredBvc'],
        );
      }
      if (e.response?.statusCode == 429) {
        throw RateLimitException(
          message: e.response?.data['message'] ?? 'Vượt quá giới hạn',
          retryAfterSeconds: e.response?.data['retryAfterSeconds'],
        );
      }
      if (e.response?.statusCode == 409) {
        throw PlayerSessionConflictException(
          message: e.response?.data['message'] ?? 'Không thể thanh toán',
        );
      }
      throw PlayerSessionApiException(
        message: e.message ?? 'Lỗi kết nối',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// GET /api/v1/sessions/me/history
  /// Lấy lịch sử các phiên đã chơi
  Future<SessionHistoryResponseModel> getSessionHistory({
    int limit = 20,
    DateTime? beforePaidAt,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
      };

      if (beforePaidAt != null) {
        queryParams['beforePaidAt'] = beforePaidAt.toUtc().toIso8601String();
      }
      if (fromDate != null) {
        queryParams['fromDate'] = fromDate.toUtc().toIso8601String();
      }
      if (toDate != null) {
        queryParams['toDate'] = toDate.toUtc().toIso8601String();
      }

      final response = await dio.get(
        ApiEndpoints.sessionHistory,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return SessionHistoryResponseModel.fromJson(response.data);
      } else if (response.statusCode == 400) {
        throw PlayerSessionApiException(
          message: response.data['message'] ?? 'Tham số không hợp lệ',
          statusCode: response.statusCode,
        );
      } else {
        throw PlayerSessionApiException(
          message: response.data['message'] ?? 'Lỗi khi lấy lịch sử',
          statusCode: response.statusCode,
        );
      }
    }     on DioException catch (e) {
      throw PlayerSessionApiException(
        message: e.message ?? 'Lỗi kết nối',
        statusCode: e.response?.statusCode,
      );
    }
  }

  // ─── Split Bill APIs ──────────────────────────────────────────────

  /// GET /api/v1/sessions/me/split-bill
  /// Lấy thông tin chia bill của phiên hiện tại (danh sách member + trạng thái thanh toán)
  Future<SplitBillSessionModel> getSplitBillSession() async {
    try {
      final response = await dio.get(ApiEndpoints.splitBill);

      if (response.statusCode == 200) {
        return SplitBillSessionModel.fromJson(response.data['data']);
      } else if (response.statusCode == 404) {
        throw PlayerSessionNotFoundException(
            message: 'Không tìm thấy phiên chơi để chia bill.');
      } else {
        throw PlayerSessionApiException(
          message: response.data['message'] ?? 'Lỗi khi lấy thông tin chia bill',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw PlayerSessionNotFoundException(
            message: 'Không tìm thấy phiên chơi để chia bill.');
      }
      throw PlayerSessionApiException(
        message: e.message ?? 'Lỗi kết nối',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// GET /api/v1/sessions/me/split-bill/member
  /// Lấy thông tin QR thanh toán cá nhân của player trong phiên
  Future<MemberPaymentInfoModel> getMyMemberPaymentInfo() async {
    try {
      final response = await dio.get(ApiEndpoints.splitBillMember);

      if (response.statusCode == 200) {
        return MemberPaymentInfoModel.fromJson(response.data['data']);
      } else if (response.statusCode == 404) {
        throw PlayerSessionNotFoundException(
            message: 'Không tìm thấy thông tin thanh toán của bạn.');
      } else {
        throw PlayerSessionApiException(
          message: response.data['message'] ??
              'Lỗi khi lấy thông tin thanh toán cá nhân',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw PlayerSessionNotFoundException(
            message: 'Không tìm thấy thông tin thanh toán của bạn.');
      }
      throw PlayerSessionApiException(
        message: e.message ?? 'Lỗi kết nối',
        statusCode: e.response?.statusCode,
      );
    }
  }
}

/// Exception: No active session found
class PlayerSessionNotFoundException implements Exception {
  final String message;
  PlayerSessionNotFoundException({this.message = 'Không có phiên chơi nào đang hoạt động.'});
  
  @override
  String toString() => message;
}

/// Exception: API error
class PlayerSessionApiException implements Exception {
  final String message;
  final int? statusCode;
  PlayerSessionApiException({required this.message, this.statusCode});
  
  @override
  String toString() => message;
}

/// Exception: Conflict (e.g., session state doesn't allow operation)
class PlayerSessionConflictException implements Exception {
  final String message;
  PlayerSessionConflictException({required this.message});
  
  @override
  String toString() => message;
}

/// Exception: Insufficient BVC balance
class InsufficientBvcException implements Exception {
  final String message;
  final int? requiredBvc;
  InsufficientBvcException({required this.message, this.requiredBvc});
  
  @override
  String toString() => message;
}

/// Exception: Rate limit exceeded
class RateLimitException implements Exception {
  final String message;
  final int? retryAfterSeconds;
  RateLimitException({required this.message, this.retryAfterSeconds});
  
  @override
  String toString() => message;
}
