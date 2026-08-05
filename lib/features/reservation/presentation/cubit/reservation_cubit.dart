import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../wallet/domain/repositories/wallet_repository.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/reservation_repository.dart';
import 'reservation_state.dart';

/// Cubit xử lý reservation flow (BR §6).
///
/// Flow chuẩn theo plan migrate Lobby sang Reservation/BVC:
/// 1. Tạo quote (idempotency key fingerprint input).
/// 2. Nếu thiếu BVC → [ReservationInsufficientBalance], đi top-up, quay lại
///    [refreshBalanceAndConfirm] để re-quote.
/// 3. Confirm với `expectedFinalDeposit` + idempotency key đã stable.
/// 4. Nếu confirm thành công & `requiresCafeApproval` → [ReservationPendingCafeApproval].
/// 5. Nếu confirm thành công & không cần duyệt → [ReservationConfirmed].
/// 6. Nếu quote hết hạn → [ReservationQuoteExpired] để UI re-quote.
class ReservationCubit extends Cubit<ReservationState> {
  final ReservationRepository repository;
  final WalletRepository walletRepository;

  ReservationQuoteEntity? _currentQuote;
  String? _quoteIdempotencyKey;
  String? _confirmIdempotencyKey;
  String? _lastInputsFingerprint;

  ReservationCubit({
    required this.repository,
    required this.walletRepository,
  }) : super(const ReservationInitial());

  String _fingerprint({
    required String cafeId,
    required String gameId,
    required DateTime playDate,
    required TimeSlot timeSlot,
    String? preferredStartTime,
    required int minPlayers,
    required int maxPlayers,
    required bool isPrivate,
  }) {
    return jsonEncode({
      'cafeId': cafeId,
      'gameId': gameId,
      'playDate': playDate.toIso8601String().split('T').first,
      'timeSlot': timeSlot.name,
      'preferredStartTime': preferredStartTime,
      'minPlayers': minPlayers,
      'maxPlayers': maxPlayers,
      'isPrivate': isPrivate,
    });
  }

  String _stableUuidV4(String seed) {
    // Dùng UUID v5 (deterministic từ SHA-1 của fingerprint) thay vì v4 để
    // cùng input luôn cho ra cùng key. Backend sẽ idempotent theo key này.
    // uuid package không expose v5 mặc định, nên thay bằng một hash ổn định.
    final bytes = utf8.encode(seed);
    final hex = _hex(bytes);
    return '${hex.substring(0, 8)}-'
        '${hex.substring(8, 12)}-'
        '4${hex.substring(13, 16)}-'
        '${(0x8 | (int.parse(hex.substring(16, 17), radix: 16) & 0x3)).toRadixString(16)}'
        '${hex.substring(17, 20)}-'
        '${hex.substring(20, 32)}';
  }

  String _hex(List<int> bytes) {
    final sb = StringBuffer();
    for (final b in bytes) {
      sb.write(b.toRadixString(16).padLeft(2, '0'));
    }
    var result = sb.toString();
    while (result.length < 32) {
      result = '0$result';
    }
    return result.substring(0, 32);
  }

  /// Tạo quote cho reservation.
  Future<void> createQuote({
    required String cafeId,
    required String gameId,
    required DateTime playDate,
    required TimeSlot timeSlot,
    String? preferredStartTime,
    required int minPlayers,
    required int maxPlayers,
    bool isPrivate = false,
  }) async {
    emit(const ReservationQuoteLoading());

    final fingerprint = _fingerprint(
      cafeId: cafeId,
      gameId: gameId,
      playDate: playDate,
      timeSlot: timeSlot,
      preferredStartTime: preferredStartTime,
      minPlayers: minPlayers,
      maxPlayers: maxPlayers,
      isPrivate: isPrivate,
    );
    _lastInputsFingerprint = fingerprint;
    _quoteIdempotencyKey = _stableUuidV4('quote|$fingerprint');

    final result = await repository.createQuote(
      cafeId: cafeId,
      gameId: gameId,
      playDate: playDate,
      timeSlot: timeSlot,
      preferredStartTime: preferredStartTime,
      minPlayers: minPlayers,
      maxPlayers: maxPlayers,
      isPrivate: isPrivate,
      idempotencyKey: _quoteIdempotencyKey!,
    );

    if (isClosed) return;

    await result.fold(
      (failure) async {
        emit(ReservationQuoteError(message: failure.message));
      },
      (quote) async {
        _currentQuote = quote;
        _confirmIdempotencyKey =
            _stableUuidV4('confirm|$_quoteIdempotencyKey');

        if (!quote.hasEnoughBalance) {
          emit(ReservationInsufficientBalance(
            quote: quote,
            missingBvc: quote.missingAmount,
          ));
        } else if (quote.isExpired) {
          emit(const ReservationQuoteExpired());
        } else {
          emit(ReservationQuoteLoaded(quote: quote));
        }
      },
    );
  }

  /// Confirm reservation. Idempotency key được cache theo quote fingerprint.
  Future<void> confirmReservation() async {
    final quote = _currentQuote;
    if (quote == null) {
      emit(const ReservationConfirmError(message: 'Không có thông tin quote'));
      return;
    }

    // Kiểm tra balance & expiry lần cuối.
    if (quote.isExpired) {
      emit(const ReservationQuoteExpired());
      return;
    }
    if (!quote.hasEnoughBalance) {
      emit(ReservationInsufficientBalance(
        quote: quote,
        missingBvc: quote.missingAmount,
      ));
      return;
    }

    emit(const ReservationConfirming());

    _confirmIdempotencyKey ??=
        _stableUuidV4('confirm|${_quoteIdempotencyKey ?? DateTime.now().toIso8601String()}');

    final result = await repository.confirmReservation(
      cafeId: quote.cafeId,
      gameId: quote.gameId,
      playDate: quote.playDate,
      timeSlot: quote.timeSlot,
      preferredStartTime: quote.preferredStartTime,
      minPlayers: quote.minPlayers,
      maxPlayers: quote.maxPlayers,
      isPrivate: quote.isPrivate,
      expectedFinalDeposit: quote.finalDeposit,
      idempotencyKey: _confirmIdempotencyKey!,
    );

    if (isClosed) return;

    await result.fold(
      (failure) async {
        // Nếu backend báo quote hết hạn thì chuyển state.
        final msg = failure.message.toLowerCase();
        if (msg.contains('expired') || msg.contains('hết hạn')) {
          emit(const ReservationQuoteExpired());
        } else {
          emit(ReservationConfirmError(message: failure.message));
        }
      },
      (confirmResult) async {
        if (confirmResult.requiresCafeApproval) {
          emit(ReservationPendingCafeApproval(
            reservationId: confirmResult.reservationId,
            lobbyId: confirmResult.lobbyId,
            cafeApprovalDeadline: confirmResult.cafeApprovalDeadline,
          ));
        } else {
          emit(ReservationConfirmed(result: confirmResult));
        }
      },
    );
  }

  /// Hủy reservation (idempotent theo key stable theo reservationId).
  Future<void> cancelReservation(
    String reservationId, {
    String? reason,
  }) async {
    emit(const ReservationCancelling());

    final idempotencyKey =
        _stableUuidV4('cancel|$reservationId|${reason ?? ''}');

    final result = await repository.cancelReservation(
      reservationId: reservationId,
      reason: reason,
      idempotencyKey: idempotencyKey,
    );

    if (isClosed) return;

    await result.fold(
      (failure) async {
        emit(ReservationCancelError(message: failure.message));
      },
      (cancelResult) async {
        emit(ReservationCancelled(result: cancelResult));
      },
    );
  }

  /// Re-quote sau khi top-up thành công.
  /// Gọi `walletRepository.getWallet(includeHeld: true)` để đảm bảo balance
  /// server khớp trước khi re-quote. Sau đó tự động confirm nếu đủ.
  Future<void> refreshBalanceAndConfirm({bool autoConfirm = false}) async {
    final quote = _currentQuote;
    if (quote == null) return;

    await walletRepository.getWallet(includeHeld: true);

    // Re-quote dùng cùng idempotencyKey fingerprint → server trả lại
    // quote mới với `currentBalance` đã cập nhật.
    await createQuote(
      cafeId: quote.cafeId,
      gameId: quote.gameId,
      playDate: quote.playDate,
      timeSlot: quote.timeSlot,
      preferredStartTime: quote.preferredStartTime,
      minPlayers: quote.minPlayers,
      maxPlayers: quote.maxPlayers,
      isPrivate: quote.isPrivate,
    );

    if (autoConfirm && _currentQuote?.hasEnoughBalance == true) {
      await confirmReservation();
    }
  }

  /// Re-quote khi user bấm retry (vd: quote vừa expire).
  Future<void> retryQuote() async {
    final fp = _lastInputsFingerprint;
    if (fp == null) return;
    final quote = _currentQuote;
    if (quote == null) return;
    await createQuote(
      cafeId: quote.cafeId,
      gameId: quote.gameId,
      playDate: quote.playDate,
      timeSlot: quote.timeSlot,
      preferredStartTime: quote.preferredStartTime,
      minPlayers: quote.minPlayers,
      maxPlayers: quote.maxPlayers,
      isPrivate: quote.isPrivate,
    );
  }

  /// Lấy quote hiện tại.
  ReservationQuoteEntity? get currentQuote => _currentQuote;

  /// Reset state.
  void reset() {
    _currentQuote = null;
    _quoteIdempotencyKey = null;
    _confirmIdempotencyKey = null;
    _lastInputsFingerprint = null;
    emit(const ReservationInitial());
  }
}