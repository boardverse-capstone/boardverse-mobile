import 'package:flutter/material.dart';

import 'pages/main_scaffold.dart';

/// Helpers cho navigation flow lobby/reservation — đảm bảo back an toàn
/// về `MainScaffold` thay vì có thể rơi vào trang rỗng/màn hình đen.
///
/// Trước đây các page con (`LobbyQuotePage`, `LobbyPendingCafeApprovalPage`,
/// `LobbyConfigPage`, ...) dùng `popUntil((r) => r.isFirst)`. Trong một
/// số edge case (deep-link, push từ root navigator), stack có thể rỗng →
/// user rơi vào nền đen của MaterialApp. Helper này cung cấp các API
/// navigate có guard để đảm bảo user luôn có đường về MainScaffold.
class LobbyFlowNavigator {
  LobbyFlowNavigator._();

  /// Pop cho đến khi gặp route MainScaffold (hoặc về root rồi dừng).
  /// Nếu stack không có route nào MainScaffold hoặc rỗng, push MainScaffold
  /// mới để user không bị kẹt ở màn hình rỗng.
  static void returnToRoot(BuildContext context) {
    final navigator = Navigator.of(context, rootNavigator: true);
    var found = false;
    navigator.popUntil((route) {
      // MainScaffold là route đầu tiên của AuthSuccess (home) hoặc fallback.
      // Dừng ở route đầu tiên vì MainScaffold được tạo đầu tiên trong stack.
      if (route.isFirst) {
        found = true;
        return true;
      }
      return false;
    });
    // Nếu navigator pop hết → stack rỗng → push MainScaffold.
    if (navigator.canPop()) {
      // Vẫn còn route (chưa xử lý được edge case) — bỏ qua.
      return;
    }
    if (!found) {
      navigator.push(
        MaterialPageRoute(
          settings: const RouteSettings(name: '/home'),
          builder: (_) => const MainScaffold(),
        ),
      );
    }
  }

  /// Push page với guard: nếu stack chỉ còn page này thì bấm back sẽ
  /// fallback về MainScaffold thay vì màn hình rỗng.
  static Future<T?> push<T>(
    BuildContext context,
    Widget page,
  ) {
    final navigator = Navigator.of(context, rootNavigator: true);
    final canPop = navigator.canPop();
    return navigator.push<T>(
      MaterialPageRoute<T>(
        builder: (_) => SafeBackWrapper(
          needsRootFallback: !canPop,
          child: page,
        ),
      ),
    );
  }

  /// `pushReplacement` đơn giản — page phía dưới đã có sẵn nên không cần
  /// guard root fallback.
  static Future<T?> pushReplacement<T, R>(
    BuildContext context,
    Widget page,
  ) {
    return Navigator.of(context, rootNavigator: true).pushReplacement<T, R>(
      MaterialPageRoute<T>(builder: (_) => page),
    );
  }
}

/// Wrapper widget giúp page con không bao giờ bị rỗng khi back.
///
/// Nếu page được push standalone (stack chỉ có nó), bấm back sẽ:
/// 1. `canPop = false` → handle thủ công để `returnToRoot` về MainScaffold.
/// 2. Ngăn PopScope pop route thực sự (vì sẽ làm stack rỗng).
class SafeBackWrapper extends StatelessWidget {
  final Widget child;
  final bool needsRootFallback;
  const SafeBackWrapper({
    super.key,
    required this.child,
    required this.needsRootFallback,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !needsRootFallback,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (needsRootFallback) {
          LobbyFlowNavigator.returnToRoot(context);
        }
      },
      child: child,
    );
  }
}
