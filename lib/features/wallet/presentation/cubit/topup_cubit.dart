import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/utils/uuid_generator.dart';
import '../../data/qr_download_service.dart';
import '../../domain/repositories/wallet_repository.dart';
import 'topup_state.dart';

/// Cubit xử lý luồng nạp BVC.
///
/// Flow:
/// 1. User chọn số tiền nạp.
/// 2. Tạo đơn top-up qua API → nhận QR.
/// 3. User lưu QR về máy, mở app ngân hàng quét thanh toán.
/// 4. Polling kiểm tra transaction history để phát hiện thanh toán.
/// 5. Cập nhật ví khi thành công.
class TopUpCubit extends Cubit<TopUpState> {
  final WalletRepository repository;
  Timer? _pollingTimer;
  String? _currentOrderId;
  int? _lastExpectedBvc;
  int? _lastAmountVnd;
  int? _previousBalance;

  /// Thời điểm tạo quote (UTC). Dùng để phát hiện transaction TopUp mới
  /// sau thời điểm này khi backend không gắn `relatedPaymentRef`.
  DateTime? _quoteCreatedAt;

  TopUpCubit({required this.repository}) : super(const TopUpInitial());

  /// Tạo instance mới dùng repository từ GetIt. Tiện cho các flow inline
  /// (vd: insufficient balance từ trang đặt cọc).
  factory TopUpCubit.newInstance() {
    return TopUpCubit(repository: GetIt.I<WalletRepository>());
  }

  /// Tạo đơn nạp và bắt đầu polling.
  Future<void> createTopUp({
    required int amountVnd,
    required void Function() onSuccess,
  }) async {
    // Validate số tiền.
    if (amountVnd < 10000) {
      emit(const TopUpFailed(reason: 'Số tiền tối thiểu là 10.000 VND'));
      return;
    }

    if (amountVnd % 1000 != 0) {
      emit(const TopUpFailed(reason: 'Số tiền phải chia hết cho 1.000'));
      return;
    }

    _lastAmountVnd = amountVnd;
    emit(const TopUpCreating());

    // Lưu số dư trước khi nạp để detect tăng balance.
    final walletResult = await repository.getWallet();
    if (walletResult.isRight()) {
      _previousBalance = walletResult
          .getOrElse(() => throw Exception())
          .availableBalance;
    }

    final idempotencyKey = generateIdempotencyKey();

    final result = await repository.createTopUp(
      amountVnd: amountVnd,
      idempotencyKey: idempotencyKey,
    );

    if (isClosed) return;

    await result.fold(
      (failure) async {
        emit(TopUpFailed(reason: failure.message));
      },
      (quote) async {
        _currentOrderId = quote.orderId;
        _lastExpectedBvc = quote.expectedBvc;
        _quoteCreatedAt = DateTime.now().toUtc();

        emit(TopUpAwaitingPayment(quote: quote, deadline: quote.expiresAt));
        _startPolling(() => onSuccess());
      },
    );
  }

  /// Tạo lại đơn với cùng số tiền (khi QR hết hạn).
  Future<void> retryTopUp({required void Function() onSuccess}) async {
    if (_lastAmountVnd == null) {
      emit(const TopUpFailed(reason: 'Không có thông tin nạp trước đó'));
      return;
    }

    await createTopUp(amountVnd: _lastAmountVnd!, onSuccess: onSuccess);
  }

  /// Đổi số tiền đơn đang chờ qua PATCH /api/v1/wallet/topup/{topUpId}.
  Future<void> updateCurrentTopUp({
    required int newAmountVnd,
    required void Function() onSuccess,
  }) async {
    final currentQuote = state is TopUpAwaitingPayment
        ? (state as TopUpAwaitingPayment).quote
        : null;

    if (currentQuote == null || !currentQuote.hasTopUpId) {
      emit(
        const TopUpFailed(
          reason:
              'Không thể đổi số tiền lúc này. Vui lòng tạo đơn mới.',
        ),
      );
      return;
    }
    if (newAmountVnd < 10000 || newAmountVnd % 1000 != 0) {
      emit(const TopUpFailed(reason: 'Số tiền không hợp lệ'));
      return;
    }

    emit(const TopUpCreating());
    final idempotencyKey = generateIdempotencyKey();
    final result = await repository.updateTopUp(
      topUpId: currentQuote.topUpId!,
      amountVnd: newAmountVnd,
      idempotencyKey: idempotencyKey,
    );

    if (isClosed) return;

    await result.fold(
      (failure) async {
        emit(TopUpFailed(reason: failure.message));
      },
      (quote) async {
        _currentOrderId = quote.orderId;
        _lastExpectedBvc = quote.expectedBvc;
        _lastAmountVnd = quote.amountVnd;
        emit(TopUpAwaitingPayment(quote: quote, deadline: quote.expiresAt));
        _startPolling(onSuccess);
      },
    );
  }

  /// Hủy đơn đang chờ qua DELETE /api/v1/wallet/topup/{topUpId}.
  Future<void> cancelCurrentTopUp({required void Function() onCancel}) async {
    final currentQuote = state is TopUpAwaitingPayment
        ? (state as TopUpAwaitingPayment).quote
        : null;

    if (currentQuote == null || !currentQuote.hasTopUpId) {
      emit(
        const TopUpFailed(
          reason:
              'Không thể hủy lúc này. Đơn sẽ tự hết hạn sau khoảng 10 phút.',
        ),
      );
      return;
    }

    emit(const TopUpCancelling());

    final result = await repository.cancelTopUp(currentQuote.topUpId!);

    if (isClosed) return;

    await result.fold(
      (failure) async {
        emit(TopUpFailed(reason: 'Không thể hủy: ${failure.message}'));
      },
      (_) async {
        _stopPolling();
        _currentOrderId = null;
        _quoteCreatedAt = null;
        emit(const TopUpCancelled());
        onCancel();
      },
    );
  }

  /// Download QR hiện tại về gallery (gọi từ nút "TẢI MÃ QR").
  ///
  /// Trả về `true` nếu lưu thành công, `false` nếu lỗi (để UI snackbar).
  Future<({bool success, String? fileName, String? errorMessage})>
  downloadCurrentQr() async {
    final state = this.state;
    if (state is! TopUpAwaitingPayment) {
      return (
        success: false,
        fileName: null,
        errorMessage: 'Không có đơn nạp đang chờ để tải QR.',
      );
    }

    final qrUrl = state.quote.qrUrl;
    final orderId = state.quote.orderId;
    // Ưu tiên dùng bytes đã có sẵn từ backend (qrImageBase64) để tiết kiệm
    // HTTP request và đảm bảo CORS-safe trên web. Fallback về qrUrl khi
    // backend cũ chưa trả `qrImageBase64`.
    final qrImageBytes = state.quote.qrImageBytes;
    if (qrUrl.isEmpty && qrImageBytes == null) {
      return (
        success: false,
        fileName: null,
        errorMessage: 'Mã QR trống — không thể tải.',
      );
    }

    try {
      final service = QrDownloadService();
      final fileName = await service.downloadAndSaveQr(
        qrUrl: qrUrl,
        orderId: orderId,
        qrImageBytes: qrImageBytes,
      );
      return (success: true, fileName: fileName, errorMessage: null);
    } on QrDownloadException catch (e) {
      return (success: false, fileName: null, errorMessage: e.message);
    } catch (e) {
      return (
        success: false,
        fileName: null,
        errorMessage: 'Lỗi không xác định: $e',
      );
    }
  }

  /// User bấm "Kiểm tra ngay" để ép check trạng thái ngay.
  ///
  /// Trả về `true` nếu phát hiện thanh toán thành công (đã emit
  /// [TopUpSuccess]).
  Future<bool> manualCheckStatus() async {
    if (_currentOrderId == null) return false;

    // Check expiration trước.
    if (state is TopUpAwaitingPayment) {
      final currentState = state as TopUpAwaitingPayment;
      if (DateTime.now().isAfter(currentState.deadline)) {
        _stopPolling();
        emit(const TopUpExpired());
        return false;
      }
    }

    final result = await repository.checkTopUpSuccessByOrderId(
      _currentOrderId!,
      previousBalance: _previousBalance,
      expectedBvc: _lastExpectedBvc,
      quoteCreatedAt: _quoteCreatedAt,
    );
    if (isClosed) return false;

    var successDetected = false;

    await result.fold(
      (failure) async {
        // Lỗi mạng → bỏ qua, giữ state hiện tại.
      },
      (isSuccess) async {
        if (isSuccess) {
          successDetected = true;
          _stopPolling();
          // Lấy balance server-side để tránh lệch local.
          final walletRes = await repository.getWallet();
          final newBalance = walletRes.fold(
            (_) => (_previousBalance ?? 0) + (_lastExpectedBvc ?? 0),
            (w) => w.availableBalance,
          );
          emit(
            TopUpSuccess(
              amountBvc: _lastExpectedBvc ?? 0,
              newBalance: newBalance,
            ),
          );
        }
      },
    );

    return successDetected;
  }

  /// Reset về initial state.
  void cancel() {
    _stopPolling();
    _currentOrderId = null;
    _quoteCreatedAt = null;
    emit(const TopUpInitial());
  }

  /// Bắt đầu polling — kiểm tra ngầm, KHÔNG emit state trung gian.
  /// Interval 5 giây để giảm tải server.
  void _startPolling(void Function() onSuccess) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _pollOnceSilent(onSuccess: onSuccess);
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Poll một lần SILENTLY — không emit state trung gian.
  /// Chỉ emit khi có thay đổi thực sự: success hoặc expired.
  Future<void> _pollOnceSilent({required void Function() onSuccess}) async {
    if (_currentOrderId == null) return;

    if (state is TopUpAwaitingPayment) {
      final currentState = state as TopUpAwaitingPayment;
      if (DateTime.now().isAfter(currentState.deadline)) {
        _stopPolling();
        emit(const TopUpExpired());
        return;
      }
    }

    final result = await repository.checkTopUpSuccessByOrderId(
      _currentOrderId!,
      previousBalance: _previousBalance,
      expectedBvc: _lastExpectedBvc,
      quoteCreatedAt: _quoteCreatedAt,
    );

    if (isClosed) return;

    await result.fold(
      (failure) async {
        // Lỗi mạng → tiếp tục silent.
      },
      (isSuccess) async {
        if (isSuccess) {
          _stopPolling();
          // Lấy balance server-side để tránh lệch local.
          final walletRes = await repository.getWallet();
          final newBalance = walletRes.fold(
            (_) => (_previousBalance ?? 0) + (_lastExpectedBvc ?? 0),
            (w) => w.availableBalance,
          );
          emit(
            TopUpSuccess(
              amountBvc: _lastExpectedBvc ?? 0,
              newBalance: newBalance,
            ),
          );
          onSuccess();
        }
      },
    );
  }

  @override
  Future<void> close() async {
    _stopPolling();
    return super.close();
  }
}
