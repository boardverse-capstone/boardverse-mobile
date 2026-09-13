import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/in_game_session_entity.dart';
import '../entities/player_session_entity.dart';
import '../entities/session_payment_entity.dart';
import '../entities/session_history_entity.dart';

/// Repository interface cho Player Session - quản lý phiên chơi của player
abstract class InGameRepository {
  /// Lấy thông tin phiên chơi hiện tại của player
  Future<Either<Failure, PlayerSessionEntity>> getCurrentSession();

  /// Yêu cầu gia hạn thêm thời gian chơi
  /// [minutes] - số phút muốn gia hạn
  Future<Either<Failure, ExtensionRequestEntity>> requestExtension(int minutes);

  /// Thanh toán phiên chơi bằng BVC
  /// [sessionId] - id của phiên cần thanh toán
  Future<Either<Failure, SessionPaymentResultEntity>> payWithBvc(String sessionId);

  /// Lấy lịch sử các phiên đã chơi
  Future<Either<Failure, List<SessionHistoryEntity>>> getSessionHistory({
    int limit = 20,
    DateTime? beforePaidAt,
    DateTime? fromDate,
    DateTime? toDate,
  });

  /// Lấy thông tin chia bill của phiên hiện tại (Split Bill)
  /// Trả về danh sách member với trạng thái thanh toán
  Future<Either<Failure, List<MemberPaymentInfo>>> getSplitBillMembers();

  /// Lấy thông tin thanh toán cá nhân của player trong phiên
  Future<Either<Failure, MemberPaymentInfo>> getMyMemberPaymentInfo();

  /// Check-in vào phiên chơi (legacy - giữ lại cho tương thích)
  Future<Either<Failure, InGameSessionEntity>> checkIn({
    required String bookingId,
  });

  /// Watch session realtime updates (legacy - giữ lại cho tương thích)
  Stream<InGameSessionEntity> watchSession(String sessionId);

  /// Report missing component (legacy)
  Future<Either<Failure, void>> reportMissingComponent(
    String sessionId,
    String componentName,
    int quantity,
  );

  /// Complete session (legacy)
  Future<Either<Failure, void>> completeSession(String sessionId);
}
