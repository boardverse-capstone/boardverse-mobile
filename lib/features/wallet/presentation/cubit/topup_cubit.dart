import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/utils/uuid_generator.dart';
import '../../data/qr_download_service.dart';
import '../../domain/repositories/wallet_repository.dart';
import 'topup_state.dart';

/// Cubit xử lý luồng top-up BVC
///
/// Flow:
/// 1. User chọn số tiền nạp
/// 2. Tạo top-up quote qua API
/// 3. Mở SePay URL để thanh toán
/// 4. Polling kiểm tra transaction history (không phải balance)
/// 5. Cập nhật ví khi thành công
class TopUpCubit extends Cubit<TopUpState> {
  final WalletRepository repository;
  Timer? _pollingTimer;
  String? _currentOrderId;
  int? _lastExpectedBvc;
  int? _lastAmountVnd;
  int? _previousBalance;

  /// Thời điểm tạo quote (UTC). Dùng để fallback detect TopUp transaction
  /// mới tạo sau thời điểm này — workaround cho bug backend không gắn
  /// `relatedPaymentRef` cho transaction SePay.
  DateTime? _quoteCreatedAt;

  TopUpCubit({required this.repository}) : super(const TopUpInitial());

  /// Tạo instance mới sử dụng repository từ GetIt. Tiện cho việc mở
  /// top-up inline từ các flow khác (vd: insufficient balance trong đặt cọc).
  factory TopUpCubit.newInstance() {
    return TopUpCubit(repository: GetIt.I<WalletRepository>());
  }

  /// Tạo đơn top-up và mở gateway
  Future<void> createTopUp({
    required int amountVnd,
    required void Function() onSuccess,
  }) async {
    // Validate amount (BR §2.3)
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

    // Get current balance before topup
    final walletResult = await repository.getWallet();
    if (walletResult.isRight()) {
      _previousBalance = walletResult
          .getOrElse(() => throw Exception())
          .availableBalance;
    }

    // Generate idempotency key
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

        // Không auto-mở SePay paymentUrl nữa — player sẽ tải QR về máy
        // rồi mở app ngân hàng quét (xem [QrDownloadService]).

        // Emit awaiting state with deadline + QR
        emit(TopUpAwaitingPayment(quote: quote, deadline: quote.expiresAt));

        // Start polling with 5 second interval
        _startPolling(() {
          onSuccess();
        });
      },
    );
  }

  /// Tạo lại top-up với cùng amount (khi QR hết hạn)
  Future<void> retryTopUp({required void Function() onSuccess}) async {
    if (_lastAmountVnd == null) {
      emit(const TopUpFailed(reason: 'Không có thông tin top-up trước đó'));
      return;
    }

    await createTopUp(amountVnd: _lastAmountVnd!, onSuccess: onSuccess);
  }

  /// Đổi số tiền đơn top-up đang Pending.
  /// Gọi PATCH /api/v1/wallet/topup/{topUpId}.
  ///
  /// **Lưu ý về `topUpId`:**
  /// Backend lý tưởng phải trả `topUpId` (Guid) trong response. Nếu backend
  /// phiên bản hiện tại CHƯA trả, model fallback dùng `orderId` làm ID để
  /// gọi PATCH/DELETE — nếu backend thực sự yêu cầu Guid strict sẽ trả 404,
  /// UI sẽ nhận error và emit `TopUpFailed`.
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
              'Tính năng đổi số tiền đang bảo trì. '
              'Vui lòng tạo đơn mới.',
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

  /// Hủy đơn top-up đang Pending.
  /// Gọi DELETE /api/v1/wallet/topup/{topUpId}.
  ///
  /// **Lưu ý về `topUpId`:**
  /// Model fallback dùng `orderId` khi backend chưa trả Guid. Nếu backend
  /// yêu cầu Guid strict → DELETE sẽ 404, UI sẽ nhận error và emit failed.
  Future<void> cancelCurrentTopUp({required void Function() onCancel}) async {
    final currentQuote = state is TopUpAwaitingPayment
        ? (state as TopUpAwaitingPayment).quote
        : null;

    if (currentQuote == null || !currentQuote.hasTopUpId) {
      emit(
        const TopUpFailed(
          reason:
              'Tính năng hủy đang được bảo trì. '
              'Đơn sẽ tự hết hạn sau khoảng 10 phút hoặc được xử lý tự động.',
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
  /// Không emit state — download là side-effect pure, không thay đổi flow.
  Future<({bool success, String? fileName, String? errorMessage})>
  downloadCurrentQr() async {
    final state = this.state;
    if (state is! TopUpAwaitingPayment) {
      return (
        success: false,
        fileName: null,
        errorMessage: 'Không có đơn top-up đang chờ để tải QR.',
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

  /// User bấm "Kiểm tra ngay" để ép check trạng thái ngay lập tức
  /// (không phải đợi auto-polling 5s).
  ///
  /// Logic giống [_pollOnceSilent] nhưng trả về `true` nếu phát hiện
  /// thanh toán thành công (đã emit [TopUpSuccess]) — để UI biết
  /// có nên hiển thị snackbar "chưa nhận được" hay không.
  ///
  /// Trả về:
  /// - `true`  : đã emit [TopUpSuccess] (BlocConsumer sẽ tự show success dialog).
  /// - `false` : chưa thấy giao dịch / mạng lỗi / đơn hết hạn.
  Future<bool> manualCheckStatus() async {
    if (_currentOrderId == null) return false;

    // Check expiration first
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
        // Network error → silently ignore; UI sẽ giữ state hiện tại.
      },
      (isSuccess) async {
        if (isSuccess) {
          successDetected = true;
          _stopPolling();
          // Lấy balance server-side (BR § III.1) để tránh lệch local.
          final walletRes = await repository.getWallet(includeHeld: true);
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

  /// Reset về initial state
  void cancel() {
    _stopPolling();
    _currentOrderId = null;
    _quoteCreatedAt = null;
    emit(const TopUpInitial());
  }

  /// Start polling - chỉ kiểm tra ngầm, KHÔNG emit state mới
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

  /// Poll một lần SILENTLY - không emit state trung gian.
  /// Chỉ emit khi có thay đổi thực sự: success hoặc expired.
  Future<void> _pollOnceSilent({required void Function() onSuccess}) async {
    if (_currentOrderId == null) return;

    // Check expiration first
    if (state is TopUpAwaitingPayment) {
      final currentState = state as TopUpAwaitingPayment;
      if (DateTime.now().isAfter(currentState.deadline)) {
        _stopPolling();
        emit(const TopUpExpired());
        return;
      }
    }

    // Call API to check transaction history
    final result = await repository.checkTopUpSuccessByOrderId(
      _currentOrderId!,
      previousBalance: _previousBalance,
      expectedBvc: _lastExpectedBvc,
      quoteCreatedAt: _quoteCreatedAt,
    );

    if (isClosed) return;

    await result.fold(
      (failure) async {
        // Network error → continue silently, don't interrupt user
      },
      (isSuccess) async {
        if (isSuccess) {
          _stopPolling();
          // Lấy balance server-side thay vì cộng local (đề phòng lệch
          // nếu user có nhiều đơn top-up hoặc cộng Karma/bonus).
          final walletRes = await repository.getWallet(includeHeld: true);
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
        // Otherwise → do nothing, stay in current state
      },
    );
  }

  @override
  Future<void> close() async {
    _stopPolling();
    return super.close();
  }
}
