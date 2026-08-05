import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/navigation/lobby_flow_navigator.dart';
import '../../../../core/theme/theme.dart';

/// Countdown `cafeApprovalDeadline`. Sau khi cafe duyệt lobby sẽ mở (open).
///
/// Phase sau sẽ kết nối realtime + `LobbyCubit.loadPendingApproval`.
/// Page này có:
/// - Scaffold + AppBar + back an toàn
/// - Nút "Về trang chủ" fallback về MainScaffold
/// - `PopScope` đảm bảo bấm back khi stack rỗng sẽ không kết thúc ở màn hình đen
class LobbyPendingCafeApprovalPage extends StatefulWidget {
  final String reservationId;
  final DateTime? cafeApprovalDeadline;

  const LobbyPendingCafeApprovalPage({
    super.key,
    required this.reservationId,
    this.cafeApprovalDeadline,
  });

  @override
  State<LobbyPendingCafeApprovalPage> createState() =>
      _LobbyPendingCafeApprovalPageState();
}

class _LobbyPendingCafeApprovalPageState
    extends State<LobbyPendingCafeApprovalPage> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _back() {
    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) {
      nav.pop();
    } else {
      LobbyFlowNavigator.returnToRoot(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final deadline = widget.cafeApprovalDeadline;
    final remaining = deadline == null
        ? Duration.zero
        : deadline.difference(DateTime.now());
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chờ quán duyệt'),
        leading: IconButton(
          tooltip: 'Đóng',
          icon: const Icon(Icons.close),
          onPressed: _back,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.hourglass_top,
                    size: 56, color: Colors.amber),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Phòng đang được quán xem xét.',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Reservation: ${widget.reservationId}',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                if (deadline != null)
                  Text(
                    remaining.isNegative
                        ? 'Đã quá hạn duyệt'
                        : 'Còn lại: ${_format(remaining)}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                const SizedBox(height: AppSpacing.lg),
                OutlinedButton.icon(
                  onPressed: () =>
                      LobbyFlowNavigator.returnToRoot(context),
                  icon: const Icon(Icons.home),
                  label: const Text('Về trang chủ'),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: _back,
                  child: const Text('Đóng'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _format(Duration d) {
    final hh = d.inHours.toString().padLeft(2, '0');
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$hh:$mm:$ss';
  }
}
