import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/utils/uuid_generator.dart';
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
  // Cache preferredStartTime / preferredEndTime từ lần createQuote gần nhất
  // để dùng cho confirm. Trước đây code lưu `_preferredEndTime` — khi fix
  // BR-NEW-15 tôi đã bỏ sót dòng gán → dẫn đến bug "End time phải lớn hơn
  // start time" vì fallback về '00:00:00'. (2026-08-18)
  String? _preferredStartTime;
  String? _preferredEndTime;

  ReservationCubit({
    required this.repository,
    required this.walletRepository,
  }) : super(const ReservationInitial());

  String _fingerprint({
    required String cafeId,
    required String gameId,
    required DateTime playDate,
    required String preferredStartTime,
    required String preferredEndTime,
    required int minPlayers,
    required int maxPlayers,
    required bool isPrivate,
  }) {
    // BR-NEW-15 (2026-08-18): bỏ `timeSlot` khỏi fingerprint — server xác
    // định timeSlot hoàn toàn từ `preferredStartTime`/`preferredEndTime`.
    return jsonEncode({
      'cafeId': cafeId,
      'gameId': gameId,
      'playDate': playDate.toIso8601String().split('T').first,
      'preferredStartTime': preferredStartTime,
      'preferredEndTime': preferredEndTime,
      'minPlayers': minPlayers,
      'maxPlayers': maxPlayers,
      'isPrivate': isPrivate,
    });
  }

  String _stableKey(String seed) {
    // Deterministic key chỉ dùng cho cancel — để retry cancel không tạo
    // record mới trên server.
    final bytes = utf8.encode(seed);
    final hex = _hex(bytes);
    return '${hex.substring(0, 8)}'
        '-${hex.substring(8, 12)}'
        '-4${hex.substring(13, 16)}'
        '-${(0x8 | (int.parse(hex.substring(16, 17), radix: 16) & 0x3)).toRadixString(16)}'
        '${hex.substring(17, 20)}'
        '-${hex.substring(20, 32)}';
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
///
/// BR-NEW-15 (2026-08-18): backend đã BỎ `timeSlot` khỏi request body. FE
/// chỉ cần gửi `preferredStartTime` + `preferredEndTime` (HH:mm:ss) để
/// xác định khung giờ chơi (xem `ReservationRepository.createQuote` và
/// swagger.json `ReservationQuoteRequestDto` line 27806).
  Future<void> createQuote({
    required String cafeId,
    required String gameId,
    required DateTime playDate,
    required String preferredStartTime,
    required String preferredEndTime,
    required int minPlayers,
    required int maxPlayers,
    bool isPrivate = false,
  }) async {
    emit(const ReservationQuoteLoading());

    final fingerprint = _fingerprint(
      cafeId: cafeId,
      gameId: gameId,
      playDate: playDate,
      preferredStartTime: preferredStartTime,
      preferredEndTime: preferredEndTime,
      minPlayers: minPlayers,
      maxPlayers: maxPlayers,
      isPrivate: isPrivate,
    );

    // Phát hiện user mở flow tạo lobby MỚI so với lần trước:
    //   - Input thay đổi (cafeId khác, ngày khác, v.v.) → flow mới chắc chắn.
    //   - Input giống hệt nhưng đã từng có confirm thành công trước đó
    //     (state là ReservationConfirmed / ReservationPendingCafeApproval /
    //      ReservationCancelled) → user đang "tạo lại" sau khi lobby cũ
    //     bị giải tán → cũng phải đổi nonce để tránh đụng idempotency key
    //     cũ trong DB (lobby cũ đã dissolve → backend sẽ throw 500).
    final inputChanged = fingerprint != _lastInputsFingerprint;
    final previousTerminalConfirm = state is ReservationConfirmed ||
        state is ReservationPendingCafeApproval ||
        state is ReservationCancelled;
    if (inputChanged || previousTerminalConfirm) {
      // Reset confirm key cache để lần confirm kế sẽ sinh key mới.
      // KHÔNG reset _quoteIdempotencyKey vì quote an toàn để cache.
      _confirmIdempotencyKey = null;
    }

    _lastInputsFingerprint = fingerprint;
    _quoteIdempotencyKey = generateIdempotencyKey();

    // Cache lại preferredStartTime/preferredEndTime để dùng cho confirm
    // (BR-NEW-15): server verify `preferredStartTime`/`preferredEndTime` từ
    // confirm request phải khớp với quote fingerprint (BR §XVII.2). Nếu user
    // đổi input sau khi quote xong, fingerprint đổi → quote mới + cache mới.
    _preferredStartTime = preferredStartTime;
    _preferredEndTime = preferredEndTime;

    final result = await repository.createQuote(
      cafeId: cafeId,
      gameId: gameId,
      playDate: playDate,
      preferredStartTime: preferredStartTime,
      preferredEndTime: preferredEndTime,
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
        _confirmIdempotencyKey = generateIdempotencyKey();

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

    // Sinh confirm key MỚI cho mỗi "attempt" để:
    //   - Trong cùng 1 session (user vừa bấm Confirm → bị lỗi mạng → bấm
    //     lại): cùng nonce → cùng key → server dedupe, an toàn.
    //   - Khi user "tạo lại" lobby (giải tán lobby cũ rồi bấm Confirm lại):
    //     nonce mới → key mới → tránh đụng Reservation.IdempotencyKey cũ
    //     đã gắn với lobby đã bị dissolve.
    _confirmIdempotencyKey ??= generateIdempotencyKey();

    // Lấy preferred times theo thứ tự ưu tiên (BR-NEW-15 + BR §XVII.2):
    //   1. Cache local `_preferredStartTime`/`_preferredEndTime` (gán trong
    //      `createQuote`) — giá trị user vừa chọn.
    //   2. Fallback về `quote.preferredStartTime`/`preferredEndTime` từ
    //      response của server (server đã echo lại từ request, là single
    //      source of truth — bảo đảm khớp với quote fingerprint).
    //
    // Tuyệt đối KHÔNG fallback về '00:00:00' (bug 2026-08-18: trước đây
    // fallback hardcoded khiến confirm fail với
    // `preferredEndTime < preferredStartTime`).
    final startTime = _preferredStartTime ?? quote.preferredStartTime;
    final endTime = _preferredEndTime ?? quote.preferredEndTime;
    if (startTime == null ||
        endTime == null ||
        startTime.isEmpty ||
        endTime.isEmpty) {
      // Không có giờ hợp lệ → không gọi confirm, emit lỗi rõ ràng để user
      // biết cần re-quote.
      emit(const ReservationConfirmError(
        message: 'Thiếu thông tin giờ chơi — vui lòng tạo lại quote.',
      ));
      return;
    }

    final result = await repository.confirmReservation(
      cafeId: quote.cafeId,
      gameId: quote.gameId,
      playDate: quote.playDate,
      preferredStartTime: startTime,
      preferredEndTime: endTime,
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
          final quote = _currentQuote;
          emit(ReservationPendingCafeApproval(
            reservationId: confirmResult.reservationId,
            lobbyId: confirmResult.lobbyId,
            cafeId: quote?.cafeId,
            cafeName: quote?.cafeName,
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
        _stableKey('cancel|$reservationId|${reason ?? ''}');

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
    //
    // Ưu tiên đọc `preferredStartTime`/`preferredEndTime` từ cache (đã gán
    // trong lần createQuote gần nhất) — đây là giá trị thực user đã chọn.
    // Fallback về `quote.preferredStartTime` chỉ khi cache trống.
    final cachedStart = _preferredStartTime ?? quote.preferredStartTime;
    final cachedEnd = _preferredEndTime ?? quote.preferredEndTime;
    if (cachedStart == null || cachedEnd == null) {
      emit(ReservationConfirmError(
        message: 'Thiếu thông tin giờ chơi — vui lòng tạo lại quote.',
      ));
      return;
    }
    await createQuote(
      cafeId: quote.cafeId,
      gameId: quote.gameId,
      playDate: quote.playDate,
      preferredStartTime: cachedStart,
      preferredEndTime: cachedEnd,
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
    final cachedStart = _preferredStartTime ?? quote.preferredStartTime;
    final cachedEnd = _preferredEndTime ?? quote.preferredEndTime;
    if (cachedStart == null || cachedEnd == null) return;
    await createQuote(
      cafeId: quote.cafeId,
      gameId: quote.gameId,
      playDate: quote.playDate,
      preferredStartTime: cachedStart,
      preferredEndTime: cachedEnd,
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
    _preferredStartTime = null;
    _preferredEndTime = null;
    emit(const ReservationInitial());
  }
}