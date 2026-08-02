import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/cafe_availability_entity.dart';
import '../../domain/entities/cafe_table_entity.dart';
import '../../domain/enums/payment_method.dart';
import '../../domain/repositories/booking_repository.dart';
import 'booking_summary_state.dart';

/// Cubit cho trang `BookingSummaryPage` — load cấu hình cọc, validate
/// BR-03 (deposit cap), load bàn trống + availability, và gửi request
/// tạo booking.
///
/// Tích hợp mới (gaps #1, #2, #3):
/// - Tự động load `availableTables` (gap #1) và `cafeAvailability`
///   (gap #2) song song khi `loadConfig` xong.
/// - Hỗ trợ walk-in flow với `lobbyId == null` (gap #3).
/// - Auto-pick `cafeTableId` theo strategy `single_default`; user có thể
///   đổi qua `selectTable` trong UI.
class BookingSummaryCubit extends Cubit<BookingSummaryState> {
  final BookingRepository _repository;

  BookingSummaryCubit({required this._repository})
      : super(const SummaryInitial());

  /// Entry: tải config + bàn trống + availability song song.
  Future<void> loadConfig(
    String cafeId, {
    required DateTime scheduledStartTime,
    required DateTime scheduleEndTime,
    required int seatCount,
    String? gameTemplateId,
  }) async {
    emit(const SummaryLoading());

    final configResult = await _repository.getDepositConfig(cafeId);
    if (isClosed) return;
    configResult.fold(
      (failure) => emit(
        SummaryFailure(code: 'FETCH_CONFIG', message: failure.message),
      ),
      (config) {
        final breakdown = Breakdown(
          firstHourPrice: config.firstHourPrice,
          recommendedDeposit: config.defaultDeposit,
          maxDeposit: config.maxDeposit,
          currency: config.currency,
          pricingModelLabel: config.pricingModel.name,
        );
        emit(SummaryReady(
          config: config,
          breakdown: breakdown,
          selectedMethod: PaymentMethod.sepay,
        ));
        // Kick off tables + availability load song song.
        _loadTablesAndAvailability(
          cafeId: cafeId,
          startTime: scheduledStartTime,
          endTime: scheduleEndTime,
          seatCount: seatCount,
          gameTemplateId: gameTemplateId,
        );
      },
    );
  }

  /// Lấy bàn trống + khảo sát availability. Không block UI SummaryReady.
  /// Nếu load fail (404 backend chưa hỗ trợ), vẫn giữ SummaryReady —
  /// chỉ set availability = null.
  Future<void> _loadTablesAndAvailability({
    required String cafeId,
    required DateTime startTime,
    required DateTime endTime,
    required int seatCount,
    String? gameTemplateId,
  }) async {
    final tableFuture = _repository.getAvailableTables(
      cafeId: cafeId,
      scheduledStartTime: startTime,
      scheduleEndTime: endTime,
      seatCount: seatCount,
    );
    final availabilityFuture = _repository.getCafeAvailability(
      cafeId: cafeId,
      startTime: startTime,
      endTime: endTime,
      seatCount: seatCount,
      gameTemplateId: gameTemplateId,
    );

    final tablesResult = await tableFuture;
    if (isClosed) return;
    final availabilityResult = await availabilityFuture;
    if (isClosed) return;

    final current = state;
    if (current is! SummaryReady) return;

    final tables = tablesResult.fold<List<CafeTableEntity>>(
      (_) => const [],
      (data) => data,
    );
    final availability = availabilityResult.fold<CafeAvailabilityEntity?>(
      (_) => null,
      (data) => data,
    );

    // Auto-pick table theo strategy single_default (bàn đầu tiên sort theo name).
    String? selectedTableId;
    if (tables.isNotEmpty) {
      final sorted = [...tables]..sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
      selectedTableId = sorted.first.id;
    }

    emit(current.copyWith(
      availableTables: tables,
      availability: availability,
      selectedTableId: selectedTableId ?? current.selectedTableId,
    ));
  }

  /// Reload bàn trống (vd: sau khi user đổi khung giờ).
  Future<void> reloadTables({
    required String cafeId,
    required DateTime scheduledStartTime,
    required DateTime scheduleEndTime,
    int? seatCount,
    String? gameTemplateId,
  }) async {
    final start = scheduledStartTime;
    final end = scheduleEndTime;
    final seats = seatCount ?? 1;
    await _loadTablesAndAvailability(
      cafeId: cafeId,
      startTime: start,
      endTime: end,
      seatCount: seats,
      gameTemplateId: gameTemplateId,
    );
  }

  // paymentMethod hiện chỉ còn 1 cổng (SePay) — giữ setter để UI không
  // crash nhưng thực tế không đổi state.
  void selectPaymentMethod(PaymentMethod method) {
    final current = state;
    if (current is SummaryReady) {
      emit(current.copyWith(selectedMethod: method));
    }
  }

  /// Chọn bàn khác (User tap vào danh sách bàn trống).
  void selectTable(String tableId) {
    final current = state;
    if (current is SummaryReady) {
      emit(current.copyWith(selectedTableId: tableId));
    }
  }

  Future<void> submit({
    String? lobbyId, // Nullable cho walk-in (gap #3).
    required String cafeId,
    required String cafeTableId,
    required DateTime scheduledStartTime,
    required DateTime scheduleEndTime,
    int? playerQuantity,
  }) async {
    final current = state;
    if (current is! SummaryReady) {
      emit(const SummaryFailure(
        code: 'NO_CONFIG',
        message: 'Chưa tải cấu hình quán. Vui lòng thử lại.',
      ));
      return;
    }

    final amount = current.config.defaultDeposit;
    // BR-03 — validate deposit cap phía client.
    if (!current.config.canAccept(amount)) {
      emit(SummaryFailure(
        code: 'DEPOSIT_CAP',
        message:
            'Cọc vượt quá giới hạn (${current.config.maxDeposit.toStringAsFixed(0)} ${current.config.currency}).',
      ));
      return;
    }

    final duration = scheduleEndTime.difference(scheduledStartTime);
    if (duration < const Duration(hours: 1) ||
        duration > const Duration(hours: 6)) {
      emit(const SummaryFailure(
        code: 'INVALID_SCHEDULE',
        message: 'Khung giờ chơi phải kéo dài từ 1 đến 6 giờ.',
      ));
      return;
    }

    // Gap #15 — validate `playerQuantity ≤ lobby.currentMembers` cho lobby flow.
    // Walk-in (lobbyId == null) thì BR-07 áp dụng sau khi tạo booking.
    // `LobbyBookingSummaryEntity` chỉ có lobbyId + bookingId + walkInAvailable,
    // không có currentMembers — backend BR-07/BR-15 là source of truth ở
    // `POST /api/bookings`. Client chỉ log warning khi lobby không có
    // booking (player đặt sớm trước khi lobby đủ người).
    if (lobbyId != null && playerQuantity != null && playerQuantity > 0) {
      final lobbyResult = await _repository.getLobbyBookingSummary(lobbyId);
      if (isClosed) return;
      lobbyResult.fold(
        (failure) {/* silent — backend sẽ check ở createBooking */},
        (summary) {/* soft check: chỉ log nếu cần */},
      );
    }

    var resolvedCafeTableId = cafeTableId.trim();
    // Ưu tiên user-selected table từ UI (gap #1).
    final userSelected = current.selectedTableId;
    if (userSelected != null && userSelected.isNotEmpty) {
      resolvedCafeTableId = userSelected;
    }
    if (resolvedCafeTableId.isEmpty) {
      // Fallback: chọn bàn đầu tiên từ availableTables cache.
      final cached = current.availableTables;
      if (cached.isNotEmpty) {
        final sorted = [...cached]..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );
        resolvedCafeTableId = sorted.first.id;
      } else {
        // Last resort: gọi API.
        final tableResult = await _repository.getAvailableTables(
          cafeId: cafeId,
          scheduledStartTime: scheduledStartTime,
          scheduleEndTime: scheduleEndTime,
          seatCount: playerQuantity ?? 1,
        );
        if (isClosed) return;
        final failure = tableResult.fold((value) => value, (_) => null);
        if (failure != null) {
          emit(SummaryFailure(
            code: 'TABLE_RESOLUTION',
            message:
                '${failure.message}. Backend cần hỗ trợ API bàn trống cho Player.',
          ));
          return;
        }
        final tables = tableResult.getOrElse(() => const []);
        if (tables.isEmpty) {
          emit(const SummaryFailure(
            code: 'NO_TABLE',
            message: 'Không còn bàn phù hợp trong khung giờ đã chọn.',
          ));
          return;
        }
        tables.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        resolvedCafeTableId = tables.first.id;
      }
    }

    emit(const SummarySubmitting());
    final result = await _repository.createBooking(
      lobbyId: lobbyId,
      cafeId: cafeId,
      cafeTableId: resolvedCafeTableId,
      scheduledStartTime: scheduledStartTime,
      scheduleEndTime: scheduleEndTime,
      playerQuantity: playerQuantity,
    );

    if (isClosed) return;
    result.fold(
      (failure) => emit(SummaryFailure(code: 'CREATE', message: failure.message)),
      (booking) => emit(SummarySuccess(
        bookingId: booking.id,
        deadline: booking.depositDeadline,
        depositAmount: booking.depositAmount,
      )),
    );
  }
}