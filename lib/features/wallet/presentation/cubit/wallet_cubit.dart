import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/entities.dart';
import '../../domain/repositories/wallet_repository.dart';
import 'wallet_state.dart';

/// Cubit quản lý ví BVC
///
/// Cung cấp các chức năng:
/// - Lấy thông tin ví (availableBalance, heldBalance)
/// - Kiểm tra số dư cho reservation
/// - Hiển thị cảnh báo khi không đủ số dư
class WalletCubit extends Cubit<WalletState> {
  final WalletRepository repository;
  WalletEntity? _cachedWallet;

  WalletCubit({required this.repository}) : super(const WalletInitial());

  /// Lấy thông tin ví
  Future<void> loadWallet({bool includeHeld = false}) async {
    emit(const WalletLoading());

    final result = await repository.getWallet(includeHeld: includeHeld);

    if (isClosed) return;

    result.fold(
      (failure) => emit(WalletError(message: failure.message)),
      (wallet) {
        _cachedWallet = wallet;
        emit(WalletLoaded(wallet: wallet));
      },
    );
  }

  /// Lấy ví với held balance để hiển thị đầy đủ
  Future<void> loadFullWallet() async {
    await loadWallet(includeHeld: true);
  }

  /// Refresh ví (gọi sau khi top-up thành công)
  Future<void> refresh() async {
    await loadFullWallet();
  }

  /// Kiểm tra xem có đủ số dư cho một khoản cần thiết không
  Future<bool> hasEnoughBalance(int amountBvc) async {
    if (_cachedWallet == null) {
      await loadWallet();
    }

    return _cachedWallet!.availableBalance >= amountBvc;
  }

  /// Kiểm tra và phát sinh state nếu không đủ số dư
  ///
  /// [requiredBvc] - số BVC cần thiết
  /// Returns true nếu đủ số dư, false nếu không đủ
  Future<bool> checkBalanceForReservation(int requiredBvc) async {
    if (_cachedWallet == null) {
      await loadWallet();
    }

    final wallet = _cachedWallet;
    if (wallet == null) return false;

    if (wallet.availableBalance >= requiredBvc) {
      emit(WalletLoaded(wallet: wallet));
      return true;
    }

    final missing = requiredBvc - wallet.availableBalance;
    emit(WalletInsufficientBalance(
      wallet: wallet,
      required: requiredBvc,
      missing: missing,
    ));
    return false;
  }

  /// Lấy ví đã cache (nếu có)
  WalletEntity? get cachedWallet => _cachedWallet;

  /// Tính toán số BVC từ VND
  static int vndToBvc(int amountVnd) => amountVnd ~/ 1000;

  /// Tính toán số VND từ BVC
  static int bvcToVnd(int amountBvc) => amountBvc * 1000;
}
