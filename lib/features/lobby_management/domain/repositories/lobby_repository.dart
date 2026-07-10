import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/lobby_entity.dart';
import '../entities/lobby_summary.dart';
import '../entities/friend_entity.dart';

abstract class LobbyRepository {
  Future<Either<Failure, LobbyEntity>> createLobby({
    required String gameId,
    required String cafeId,
    required DateTime scheduledTime,
    required int additionalSlots,
    required bool isPublic,
    double? searchRadiusKm,
    double? minimumKarma,
    Duration? leadTime,
  });

  /// Luồng B: Tạo lobby phụ thuộc vào 1 booking [confirmed] có sẵn.
  /// BR-07 — số slot tuyển thêm không được vượt quá `booking.seatCount`.
  Future<Either<Failure, LobbyEntity>> createLobbyForExistingBooking({
    required String bookingId,
    required int bookingSeatCount,
    required String gameId,
    required String cafeId,
    required DateTime scheduledTime,
    required int additionalSlots,
    required bool isPublic,
    double? searchRadiusKm,
    double? minimumKarma,
    Duration? leadTime,
  });

  Future<Either<Failure, LobbyEntity?>> getLobbyById(String lobbyId);

  Future<Either<Failure, bool>> joinLobby(String lobbyId, String? inviteCode);

  Future<Either<Failure, void>> leaveLobby(String lobbyId);

  Future<Either<Failure, void>> inviteFriend(String lobbyId, String friendId);

  Future<Either<Failure, List<FriendEntity>>> getOnlineFriends();

  /// Realtime stream — phát lobby mỗi lần có thay đổi (join/leave/status/...).
  /// Đống dữ liệu mock nên tự động mô phỏng join mỗi ~5s.
  Stream<LobbyEntity> watchLobbyRealtime(String lobbyId);

  Future<Either<Failure, void>> cancelLobby(String lobbyId, String reasonCode);

  // ─── Mới cho Task 3 ─────────────────────────────────────────────────

  /// Tìm các lobby khả dụng quanh [latitude]/[longitude] áp dụng BR-10 filter.
  Future<Either<Failure, List<LobbySummary>>> searchNearbyLobbies({
    required double latitude,
    required double longitude,
    required LobbySearchFilter filter,
    required double currentUserKarma,
  });

  /// Luồng A: khi lobby đầy → tự động tạo booking [pendingDeposit] cho host.
  /// Trả về booking vừa tạo để caller navigate tới BookingSummaryPage.
  Future<Either<Failure, String>> autoCreateBookingWhenFull(String lobbyId);

  /// Đổi trạng thái lobby (timeoutFailed / hostCancelled / full / ...).
  Future<Either<Failure, LobbyEntity>> updateLobbyStatus(
    String lobbyId,
    LobbyStatus newStatus,
  );

  // ─── Dev simulation ─────────────────────────────────────────────────

  /// Mô phỏng thêm friend vào lobby (chỉ dev mode).
  /// Trả về lobby đã cập nhật; Left nếu lobby không tồn tại hoặc đã đầy.
  Future<Either<Failure, LobbyEntity>> simulateAddFriend({
    required String lobbyId,
    required String friendId,
  });
}
