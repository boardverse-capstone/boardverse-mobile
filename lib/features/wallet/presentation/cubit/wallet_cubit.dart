import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/entities.dart';
import '../../domain/repositories/wallet_repository.dart';
import 'wallet_state.dart';

/// Cubit quản lý ví BVC.
///
/// Tập trung vào trải nghiệm: tải số dư, refresh sau khi nạp, và kiểm
/// tra đủ tiền cho thao tác phía người dùng. Không chứa logic nghiệp vụ
/// (held, risk, cooling-off) — những thứ đó do backend xử lý và không
/// hiển thị trong UI ví.
class WalletCubit extends Cubit<WalletState> {
  final WalletRepository repository;
  WalletEntity? _cachedWallet;

  WalletCubit({required this.repository}) : super(const WalletInitial());

  /// Reset về trạng thái ban đầu — gọi khi logout để user kế tiếp không
  /// thấy dữ liệu cũ.
  void reset() {
    if (isClosed) return;
    _cachedWallet = null;
    emit(const WalletInitial());
  }

  /// Tải thông tin ví.
  Future<void> loadWallet() async {
    emit(const WalletLoading());

    final result = await repository.getWallet();

    if (isClosed) return;

    result.fold(
      (failure) => emit(WalletError(message: failure.message)),
      (wallet) {
        _cachedWallet = wallet;
        emit(WalletLoaded(wallet: wallet));
      },
    );
  }

  /// Refresh — gọi sau khi nạp thành công.
  Future<void> refresh() => loadWallet();

  /// Kiểm tra số dư có đủ cho một khoản cần thiết không.
  Future<bool> hasEnoughBalance(int amountBvc) async {
    if (_cachedWallet == null) {
      await loadWallet();
    }
    return _cachedWallet!.availableBalance >= amountBvc;
  }

  /// Ví đã cache (nếu có).
  WalletEntity? get cachedWallet => _cachedWallet;

  /// Quy đổi VND → BVC (1 BVC = 1.000 VND).
  static int vndToBvc(int amountVnd) => amountVnd ~/ 1000;

  /// Quy đổi BVC → VND (1 BVC = 1.000 VND).
  static int bvcToVnd(int amountBvc) => amountBvc * 1000;
}
