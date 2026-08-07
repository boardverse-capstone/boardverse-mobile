import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/utils/uuid_generator.dart';
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
  String? _currentTopUpId;
  int? _lastExpectedBvc;
  int? _lastAmountVnd;
  int? _previousBalance;

  TopUpCubit({required this.repository}) : super(const TopUpInitial());

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
      _previousBalance = walletResult.getOrElse(() => throw Exception()).availableBalance;
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
        _currentTopUpId = quote.topUpId;
        _lastExpectedBvc = quote.expectedBvc;

        // Open SePay payment URL
        final paymentUri = Uri.parse(quote.paymentUrl);
        if (await canLaunchUrl(paymentUri)) {
          await launchUrl(paymentUri, mode: LaunchMode.externalApplication);
        }

        // Emit awaiting state with deadline + QR
        emit(TopUpAwaitingPayment(
          quote: quote,
          deadline: quote.expiresAt,
        ));

        // Start polling with 5 second interval
        _startPolling(() {
          onSuccess();
        });
      },
    );
  }

  /// Tạo lại top-up với cùng amount (khi QR hết hạn)
  Future<void> retryTopUp({
    required void Function() onSuccess,
  }) async {
    if (_lastAmountVnd == null) {
      emit(const TopUpFailed(reason: 'Không có thông tin top-up trước đó'));
      return;
    }

    await createTopUp(amountVnd: _lastAmountVnd!, onSuccess: onSuccess);
  }

  /// Đổi số tiền đơn top-up đang Pending.
  /// Gọi PATCH /api/v1/wallet/topup/{topUpId}.
  Future<void> updateCurrentTopUp({
    required int newAmountVnd,
    required void Function() onSuccess,
  }) async {
    if (_currentTopUpId == null) {
      emit(const TopUpFailed(reason: 'Không có đơn top-up đang chờ'));
      return;
    }
    if (newAmountVnd < 10000 || newAmountVnd % 1000 != 0) {
      emit(const TopUpFailed(reason: 'Số tiền không hợp lệ'));
      return;
    }

    emit(const TopUpCreating());
    final idempotencyKey = generateIdempotencyKey();
    final result = await repository.updateTopUp(
      topUpId: _currentTopUpId!,
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
        _currentTopUpId = quote.topUpId;
        _lastExpectedBvc = quote.expectedBvc;
        _lastAmountVnd = quote.amountVnd;
        emit(TopUpAwaitingPayment(
          quote: quote,
          deadline: quote.expiresAt,
        ));
        _startPolling(onSuccess);
      },
    );
  }

  /// Hủy đơn top-up đang Pending.
  /// Gọi DELETE /api/v1/wallet/topup/{topUpId}.
  Future<void> cancelCurrentTopUp({
    required void Function() onCancel,
  }) async {
    if (_currentTopUpId == null) {
      emit(const TopUpFailed(reason: 'Không có đơn top-up để hủy'));
      return;
    }

    emit(const TopUpCancelling());

    final result = await repository.cancelTopUp(_currentTopUpId!);

    if (isClosed) return;

    await result.fold(
      (failure) async {
        emit(TopUpFailed(reason: 'Không thể hủy: ${failure.message}'));
      },
      (_) async {
        _stopPolling();
        _currentOrderId = null;
        _currentTopUpId = null;
        emit(const TopUpCancelled());
        onCancel();
      },
    );
  }

  /// Mở lại URL thanh toán SePay
  Future<void> openPaymentUrl() async {
    if (state is TopUpAwaitingPayment) {
      final currentState = state as TopUpAwaitingPayment;
      final paymentUri = Uri.parse(currentState.quote.paymentUrl);
      if (await canLaunchUrl(paymentUri)) {
        await launchUrl(paymentUri, mode: LaunchMode.externalApplication);
      }
    }
  }

  /// Reset về initial state
  void cancel() {
    _stopPolling();
    _currentOrderId = null;
    _currentTopUpId = null;
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
  Future<void> _pollOnceSilent({
    required void Function() onSuccess,
  }) async {
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
    final result = await repository.checkTopUpSuccessByOrderId(_currentOrderId!);

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
          emit(TopUpSuccess(
            amountBvc: _lastExpectedBvc ?? 0,
            newBalance: newBalance,
          ));
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