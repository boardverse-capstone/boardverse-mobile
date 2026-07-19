import 'dart:async';

import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import '../domain/entities/lobby_entity.dart';
import '../domain/entities/lobby_summary.dart';
import '../domain/entities/friend_entity.dart';
import '../domain/repositories/lobby_repository.dart';
import 'datasources/mock_lobby_datasource.dart';
import 'models/lobby_model.dart';

class LobbyRepositoryImpl implements LobbyRepository {
  /// Lưu id booking do mock auto-create cho Luồng A.
  final Map<String, String> _autoCreatedBookings = {};
  int _bookingIdCounter = 1;

  LobbyRepositoryImpl();

  // ─── Create Lobby ────────────────────────────────────────────────────

  @override
  Future<Either<Failure, LobbyEntity>> createLobby({
    required String gameId,
    required String cafeId,
    required DateTime scheduledTime,
    required int additionalSlots,
    required bool isPublic,
    double? searchRadiusKm,
    double? minimumKarma,
    Duration? leadTime,
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      MockLobbyDatasource.ensureSeeded();
      final model = MockLobbyDatasource.createLobby(
        gameId: gameId,
        gameName: gameId,
        gameImageUrl: null,
        cafeId: cafeId,
        cafeName: cafeId,
        hostId: 'user_001',
        hostName: 'Bạn',
        scheduledTime: scheduledTime,
        maxPlayers: additionalSlots + 1,
        minPlayers: 2,
        isPublic: isPublic,
        minimumKarma: minimumKarma ?? 0,
        searchRadiusKm: searchRadiusKm ?? 5,
        leadTime: leadTime ?? const Duration(minutes: 20),
      );
      return Right(model.toEntity());
    } catch (e) {
      return Left(ServerFailure(message: 'Lỗi tạo phòng: ${e.toString()}'));
    }
  }

  // ─── Create Lobby For Existing Booking (Luồng B + BR-07) ────────────

  @override
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
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      // BR-07: maxPlayers tuyển thêm không được vượt quá số ghế trống còn lại
      // của booking. Luồng B gọi sau khi booking confirmed → seatCount là
      // tổng ghế, và các thành viên từ booking đã ngồi 1 phần.
      if (additionalSlots + 1 > bookingSeatCount) {
        return Left(
          ServerFailure(
            message:
                'Số người trong phòng chờ (${additionalSlots + 1}) vượt quá số ghế còn lại của đơn đặt chỗ ($bookingSeatCount). Vui lòng chọn số slot nhỏ hơn.',
          ),
        );
      }
      MockLobbyDatasource.ensureSeeded();
      final model = MockLobbyDatasource.createLobby(
        gameId: gameId,
        gameName: gameId,
        gameImageUrl: null,
        cafeId: cafeId,
        cafeName: cafeId,
        hostId: 'user_001',
        hostName: 'Bạn',
        scheduledTime: scheduledTime,
        maxPlayers: additionalSlots + 1,
        minPlayers: 2,
        isPublic: isPublic,
        minimumKarma: minimumKarma ?? 0,
        searchRadiusKm: searchRadiusKm ?? 5,
        leadTime: leadTime ?? const Duration(minutes: 20),
        bookingId: bookingId,
      );
      return Right(model.toEntity());
    } catch (e) {
      return Left(ServerFailure(message: 'Lỗi tạo phòng: ${e.toString()}'));
    }
  }

  // ─── Read ────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, LobbyEntity?>> getLobbyById(String lobbyId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      MockLobbyDatasource.ensureSeeded();
      final model = MockLobbyDatasource.getLobbyById(lobbyId);
      if (model == null) {
        return const Right(null);
      }
      return Right(model.toEntity());
    } catch (e) {
      return Left(
        ServerFailure(message: 'Lỗi lấy thông tin phòng: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, bool>> joinLobby(
    String lobbyId,
    String? inviteCode,
  ) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      MockLobbyDatasource.ensureSeeded();
      final lobby = MockLobbyDatasource.getLobbyById(lobbyId);
      if (lobby == null) {
        return const Left(ServerFailure(message: 'Phòng không tồn tại'));
      }
      if (lobby.status != LobbyStatusModel.open) {
        return const Left(
          ServerFailure(message: 'Phòng không còn nhận thành viên'),
        );
      }
      if (lobby.currentPlayers >= lobby.maxPlayers) {
        return const Left(ServerFailure(message: 'Phòng đã đủ người'));
      }
      // (Không thêm player thật vào store trong mock — chỉ succeed.)
      return const Right(true);
    } catch (e) {
      return Left(
        ServerFailure(message: 'Lỗi tham gia phòng: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> leaveLobby(String lobbyId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Lỗi rời phòng: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> inviteFriend(
    String lobbyId,
    String friendId,
  ) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Lỗi mời bạn bè: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<FriendEntity>>> getOnlineFriends() async {
    try {
      await Future.delayed(const Duration(milliseconds: 400));
      return Right(
        MockLobbyDatasource.mockOnlineFriendsList
            .map((f) => f.toEntity())
            .toList(),
      );
    } catch (e) {
      return Left(
        ServerFailure(message: 'Lỗi lấy danh sách bạn bè: ${e.toString()}'),
      );
    }
  }

  // ─── Realtime ────────────────────────────────────────────────────────

  @override
  Stream<LobbyEntity> watchLobbyRealtime(String lobbyId) {
    return MockLobbyDatasource.watchLobby(lobbyId).map((m) => m.toEntity());
  }

  // ─── Cancel ──────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, void>> cancelLobby(
    String lobbyId,
    String reasonCode,
  ) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      final lobby = MockLobbyDatasource.getLobbyById(lobbyId);
      if (lobby == null) return const Right(null);
      // Map reasonCode → status.
      final newStatus = reasonCode == 'TIMEOUT_FAILED'
          ? LobbyStatusModel.timeoutFailed
          : LobbyStatusModel.hostCancelled;
      // Cập nhật store (LobbyModel immutable → copyWith + gán lại).
      _mutateStore(lobbyId, (m) => m.copyWith(status: newStatus));
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Lỗi hủy phòng: ${e.toString()}'));
    }
  }

  // ─── Phase 1: search + auto-create booking + status update ──────────

  @override
  Future<Either<Failure, List<LobbySummary>>> searchNearbyLobbies({
    required double latitude,
    required double longitude,
    required LobbySearchFilter filter,
    required double currentUserKarma,
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 400));
      MockLobbyDatasource.ensureSeeded();
      final all = MockLobbyDatasource.getAll();

      final filtered = all.where((lobby) {
        // BR-10: lọc theo Karma — host yêu cầu minimumKarma, ta so với user.
        if (currentUserKarma < lobby.minimumKarma) return false;
        // Chỉ trả các lobby còn mở (open) và còn slot.
        if (lobby.status != LobbyStatusModel.open) return false;
        if (lobby.isFull) return false;
        // Filter game id.
        if (filter.gameId != null && lobby.gameId != filter.gameId) {
          return false;
        }
        // Bỏ lobby do chính user tạo.
        if (filter.excludeOwnLobbies && lobby.hostId == 'user_001') {
          return false;
        }
        // Filter bán kính — nếu không có distance thì lấy hết.
        if (filter.radiusKm != null &&
            lobby.distanceKm != null &&
            lobby.distanceKm! > filter.radiusKm!) {
          return false;
        }
        // Filter minKarma người dùng kéo lên — lobby yêu cầu cao hơn thì loại.
        if (filter.minKarma != null && lobby.minimumKarma < filter.minKarma!) {
          // Không thực sự cần filter ở đây — BR-10 chỉ chặn user thiếu Karma,
          // không chặn lobby yêu cầu thấp. Giữ lại để nâng cao filter tương lai.
        }
        return true;
      }).toList();

      // Sắp xếp theo distance (gần nhất trước).
      filtered.sort((a, b) {
        final da = a.distanceKm ?? double.infinity;
        final db = b.distanceKm ?? double.infinity;
        return da.compareTo(db);
      });

      return Right(filtered.map(_toSummary).toList());
    } catch (e) {
      return Left(ServerFailure(message: 'Lỗi tìm phòng: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, String>> autoCreateBookingWhenFull(
    String lobbyId,
  ) async {
    try {
      await Future.delayed(const Duration(milliseconds: 400));
      final lobby = MockLobbyDatasource.getLobbyById(lobbyId);
      if (lobby == null) {
        return const Left(ServerFailure(message: 'Không tìm thấy phòng'));
      }
      if (lobby.status != LobbyStatusModel.full && !lobby.isFull) {
        return const Left(
          ServerFailure(
            message: 'Phòng chưa đủ người, chưa thể tạo booking tự động',
          ),
        );
      }
      final newBookingId =
          'AUTO_BOOK_${DateTime.now().year}_${_bookingIdCounter.toString().padLeft(3, '0')}';
      _bookingIdCounter++;
      _autoCreatedBookings[lobbyId] = newBookingId;
      // Set bookingId trên lobby để UI biết.
      _mutateStore(lobbyId, (m) => m.copyWith(bookingId: newBookingId));
      return Right(newBookingId);
    } catch (e) {
      return Left(
        ServerFailure(message: 'Lỗi auto-create booking: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, LobbyEntity>> updateLobbyStatus(
    String lobbyId,
    LobbyStatus newStatus,
  ) async {
    try {
      await Future.delayed(const Duration(milliseconds: 200));
      final lobby = MockLobbyDatasource.getLobbyById(lobbyId);
      if (lobby == null) {
        return const Left(ServerFailure(message: 'Không tìm thấy phòng'));
      }
      _mutateStore(
        lobbyId,
        (m) => m.copyWith(
          status: LobbyStatusModel.values.firstWhere(
            (s) => s.name == newStatus.name,
            orElse: () => LobbyStatusModel.open,
          ),
        ),
      );
      return Right(lobby.toEntity().copyWith(status: newStatus));
    } catch (e) {
      return Left(
        ServerFailure(message: 'Lỗi cập nhật trạng thái: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, LobbyEntity>> simulateAddFriend({
    required String lobbyId,
    required String friendId,
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 200));
      final friendModel = MockLobbyDatasource.getFriendById(friendId);
      if (friendModel == null) {
        return const Left(ServerFailure(message: 'Không tìm thấy bạn bè'));
      }
      final player = LobbyPlayerModel(
        id: friendModel.id,
        name: friendModel.name,
        avatarUrl: friendModel.avatarUrl,
        isHost: false,
        isReady: false,
        joinedAt: DateTime.now().toIso8601String(),
        karma: 70,
      );
      final updated = MockLobbyDatasource.simulateJoinPlayerById(
        lobbyId,
        player,
      );
      if (updated == null) {
        return const Left(
          ServerFailure(message: 'Phòng đã đầy hoặc không tồn tại'),
        );
      }
      return Right(updated.toEntity());
    } catch (e) {
      return Left(ServerFailure(message: 'Lỗi thêm bạn: ${e.toString()}'));
    }
  }

  // ─── Private helpers ────────────────────────────────────────────────

  void _mutateStore(String id, LobbyModel Function(LobbyModel) fn) {
    final lobby = MockLobbyDatasource.getLobbyById(id);
    if (lobby == null) return;
    final updated = fn(lobby);
    // Cập nhật lại store — mock dùng static map nên cần gán lại.
    _setInStore(id, updated);
  }

  /// Hàm setter thuần cần thiết vì `_lobbiesById` là private trong MockLobbyDatasource.
  /// Mock cung cấp static `setLobby(...)` để update store từ repository.
  void _setInStore(String id, LobbyModel updated) {
    MockLobbyDatasource.setLobby(id, updated);
  }

  LobbySummary _toSummary(LobbyModel m) => LobbySummary(
    id: m.id,
    gameId: m.gameId,
    gameName: m.gameName,
    gameImageUrl: m.gameImageUrl ?? '',
    cafeId: m.cafeId,
    cafeName: m.cafeName,
    hostName: m.hostName,
    distanceKm: m.distanceKm ?? 0,
    currentPlayers: m.currentPlayers,
    maxPlayers: m.maxPlayers,
    minPlayers: m.minPlayers,
    minimumKarma: m.minimumKarma,
    scheduledTime: m.scheduledTime,
    timeoutAt: m.timeoutAt,
    status: LobbyStatusModelX.toEntity(m.status),
    isPublic: m.isPublic,
  );

  void dispose() {
    MockLobbyDatasource.stopAllTimers();
  }
}

/// Extension: chuyển trực tiếp status model → entity status.
extension LobbyStatusModelX on LobbyStatusModel {
  static LobbyStatus toEntity(LobbyStatusModel m) {
    switch (m) {
      case LobbyStatusModel.open:
        return LobbyStatus.open;
      case LobbyStatusModel.full:
        return LobbyStatus.full;
      case LobbyStatusModel.inProgress:
        return LobbyStatus.inProgress;
      case LobbyStatusModel.closed:
        return LobbyStatus.closed;
      case LobbyStatusModel.timeoutFailed:
        return LobbyStatus.timeoutFailed;
      case LobbyStatusModel.hostCancelled:
        return LobbyStatus.hostCancelled;
    }
  }
}
