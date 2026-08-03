import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/entities/entities.dart';
import '../../domain/repositories/wallet_repository.dart';
import 'topup_state.dart';

/// Cubit xử lý luồng top-up BVC
///
/// Flow:
/// 1. User chọn số tiền nạp
/// 2. Tạo top-up quote qua API
/// 3. Mở SePay URL để thanh toán
/// 4. Polling kiểm tra trạng thái
/// 5. Cập nhật ví khi thành công
class TopUpCubit extends Cubit<TopUpState> {
  final WalletRepository repository;
  Timer? _pollingTimer;
  String? _currentOrderId;
  int? _lastAmountVnd;
  int? _lastExpectedBvc;

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

    // Generate idempotency key
    final idempotencyKey =
        'topup-${DateTime.now().millisecondsSinceEpoch}-${_generateRandomString(8)}';

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

        // Open SePay payment URL
        final paymentUri = Uri.parse(quote.paymentUrl);
        if (await canLaunchUrl(paymentUri)) {
          await launchUrl(paymentUri, mode: LaunchMode.externalApplication);
        }

        // Emit awaiting state with deadline
        emit(TopUpAwaitingPayment(
          quote: quote,
          deadline: quote.expiresAt,
        ));

        // Start polling
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

  /// Kiểm tra trạng thái top-up (gọi thủ công)
  Future<void> checkStatus({
    required void Function() onSuccess,
  }) async {
    if (_currentOrderId == null) return;
    await _pollStatus(onSuccess: onSuccess);
  }

  /// Mở lại URL thanh toán
  Future<void> openPaymentUrl() async {
    if (state is TopUpAwaitingPayment) {
      final currentState = state as TopUpAwaitingPayment;
      final paymentUri = Uri.parse(currentState.quote.paymentUrl);
      if (await canLaunchUrl(paymentUri)) {
        await launchUrl(paymentUri, mode: LaunchMode.externalApplication);
      }
    }
  }

  /// Hủy top-up
  void cancel() {
    _stopPolling();
    _currentOrderId = null;
    emit(const TopUpInitial());
  }

  void _startPolling(void Function() onSuccess) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _pollStatus(onSuccess: onSuccess);
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _pollStatus({
    required void Function() onSuccess,
  }) async {
    if (_currentOrderId == null) return;

    // Check if expired
    if (state is TopUpAwaitingPayment) {
      final currentState = state as TopUpAwaitingPayment;
      if (DateTime.now().isAfter(currentState.deadline)) {
        _stopPolling();
        emit(const TopUpExpired());
        return;
      }
    }

    emit(const TopUpCheckingStatus());

    final walletResult = await repository.checkTopUpStatus(_currentOrderId!);

    if (isClosed) return;

    await walletResult.fold(
      (failure) async {
        // Continue polling on network error - don't fail immediately
      },
      (wallet) async {
        // Check if balance has increased (rough check)
        // In production, backend would return the specific top-up status
        if (wallet.availableBalance > 0 &&
            _lastExpectedBvc != null &&
            wallet.availableBalance >= _lastExpectedBvc!) {
          _stopPolling();
          emit(TopUpSuccess(
            amountBvc: _lastExpectedBvc!,
            newBalance: wallet.availableBalance,
          ));
          onSuccess();
        } else {
          // Continue waiting
          if (state is! TopUpAwaitingPayment) {
            // Re-emit awaiting state if we changed it
            final lastQuote = _currentOrderId != null
                ? TopUpQuoteEntity(
                    paymentUrl: '',
                    qrUrl: '',
                    orderId: _currentOrderId!,
                    expectedBvc: _lastExpectedBvc ?? 0,
                    expiresAt: DateTime.now().add(const Duration(minutes: 15)),
                    idempotencyKey: '',
                  )
                : null;

            if (lastQuote != null) {
              emit(TopUpAwaitingPayment(
                quote: lastQuote,
                deadline: lastQuote.expiresAt,
              ));
            }
          }
        }
      },
    );
  }

  String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = DateTime.now().microsecondsSinceEpoch;
    return List.generate(length, (index) => chars[random % chars.length])
        .join();
  }

  @override
  Future<void> close() async {
    _stopPolling();
    return super.close();
  }
}
