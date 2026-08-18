import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/player_scan_result_entity.dart';
import '../../domain/repositories/player_check_in_repository.dart';

/// State cho PlayerCheckInCubit — sealed cho exhaustive switch.
sealed class PlayerCheckInState extends Equatable {
  const PlayerCheckInState();

  @override
  List<Object?> get props => [];
}

class PlayerCheckInIdle extends PlayerCheckInState {
  const PlayerCheckInIdle();
}

class PlayerCheckInSubmitting extends PlayerCheckInState {
  /// Token hiện đang được submit — dùng để disable form & hiển thị spinner.
  final String token;

  const PlayerCheckInSubmitting(this.token);

  @override
  List<Object?> get props => [token];
}

class PlayerCheckInSuccess extends PlayerCheckInState {
  final PlayerScanResultEntity result;
  final String token;

  const PlayerCheckInSuccess({required this.result, required this.token});

  @override
  List<Object?> get props => [
    result.activeSessionId,
    result.reservationId,
    result.cafeId,
    result.checkedInAt,
    result.reservationStatus,
    token,
  ];
}

class PlayerCheckInFailure extends PlayerCheckInState {
  final String message;

  /// Token người dùng đã nhập — để UI giữ lại trong input field khi error.
  final String lastToken;

  const PlayerCheckInFailure({
    required this.message,
    required this.lastToken,
  });

  @override
  List<Object?> get props => [message, lastToken];
}

/// Cubit xử lý luồng player tự check-in bằng cách quét/ paste QR token
/// từ POS (BR §21A.7 — `/api/check-in/scan-qr`).
///
/// Đây là luồng CHIỀU 2 của check-in 2 chiều — player cầm điện thoại
/// quét QR do POS tạo. Khác với chiều 1 (staff scan QR player) — chiều
/// này hoàn toàn là self-service.
class PlayerCheckInCubit extends Cubit<PlayerCheckInState> {
  final PlayerCheckInRepository repository;

  PlayerCheckInCubit({required this.repository})
    : super(const PlayerCheckInIdle());

  /// Gửi token 16-char lên backend. Token sẽ được validate format và
  /// normalize (trim + uppercase) trước khi gọi API.
  ///
  /// Side-effects:
  /// - `PlayerCheckInSubmitting` được emit ngay để UI hiển thị spinner.
  /// - Sau khi backend phản hồi: `PlayerCheckInSuccess` hoặc
  ///   `PlayerCheckInFailure` tuỳ status code.
  /// - Idempotent cho cùng (player, token): re-submit trả cùng result.
  Future<void> submitToken(String rawToken) async {
    final token = rawToken.trim().toUpperCase();
    if (token.isEmpty) {
      emit(
        PlayerCheckInFailure(
          message: 'Vui lòng nhập mã QR.',
          lastToken: rawToken,
        ),
      );
      return;
    }

    if (!PlayerCheckInRepository.isValidTokenFormat(token)) {
      emit(
        PlayerCheckInFailure(
          message:
              'Mã phải gồm đúng 16 ký tự in hoa (A–Z, 2–9), ví dụ: ABCDEFGHJKLMNPQR.',
          lastToken: token,
        ),
      );
      return;
    }

    emit(PlayerCheckInSubmitting(token));

    final result = await repository.scanToken(token: token);
    if (isClosed) return;

    result.fold(
      (failure) => emit(
        PlayerCheckInFailure(
          message: failure.message,
          lastToken: token,
        ),
      ),
      (scanResult) => emit(
        PlayerCheckInSuccess(result: scanResult, token: token),
      ),
    );
  }

  /// Reset về idle — dùng khi user tắt page hoặc bắt đầu nhập lại.
  void reset() {
    if (state is PlayerCheckInIdle) return;
    emit(const PlayerCheckInIdle());
  }
}
