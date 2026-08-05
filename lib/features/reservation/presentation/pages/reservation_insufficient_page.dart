import 'package:flutter/material.dart';

import '../../../../core/navigation/lobby_flow_navigator.dart';
import '../../../../core/theme/theme.dart';

/// Hiển thị khi `ReservationCubit` phát [ReservationInsufficientBalance].
/// Có 2 đường navigate:
///
/// 1. `onTopUp` → đẩy user về tab Wallet (MainScaffold) để nạp BVC.
///    Mặc định `null` → dùng helper `LobbyFlowNavigator.returnToRoot` để về
///    MainScaffold (nơi có tab Wallet).
/// 2. `onBack` → back về trang trước (SetupPage). Mặc định `null` → dùng
///    helper `Navigator.pop` an toàn.
class ReservationInsufficientPage extends StatelessWidget {
  final int missingBvc;
  final VoidCallback? onTopUp;
  final VoidCallback? onBack;

  const ReservationInsufficientPage({
    super.key,
    required this.missingBvc,
    this.onTopUp,
    this.onBack,
  });

  void _defaultBack(BuildContext context) {
    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) {
      nav.pop();
    } else {
      LobbyFlowNavigator.returnToRoot(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Số dư không đủ'),
        leading: IconButton(
          tooltip: 'Quay lại',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => (onBack ?? () => _defaultBack(context))(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 64,
                  color: Colors.orangeAccent,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Bạn cần thêm $missingBvc BVC',
                  style: textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Vui lòng nạp thêm BVC để tiếp tục tạo phòng chờ.',
                  style: textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton.icon(
                  onPressed: onTopUp ??
                      () => LobbyFlowNavigator.returnToRoot(context),
                  icon: const Icon(Icons.account_balance_wallet),
                  label: const Text('Mở Wallet'),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: () => (onBack ?? () => _defaultBack(context))(),
                  child: const Text('Quay lại'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
