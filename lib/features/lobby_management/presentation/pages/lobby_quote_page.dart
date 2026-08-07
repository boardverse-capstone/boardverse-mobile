import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/navigation/lobby_flow_navigator.dart';
import '../../../../core/theme/theme.dart';
import '../../../reservation/domain/entities/entities.dart';
import '../../../reservation/presentation/cubit/reservation_cubit.dart';
import '../../../reservation/presentation/cubit/reservation_state.dart';
import '../../domain/entities/lobby_entity.dart';
import '../cubit/lobby_cubit.dart';
import 'lobby_page.dart';
import 'lobby_pending_cafe_approval_page.dart';

/// Hiển thị quote từ `ReservationCubit` và xử lý toàn bộ reservation flow.
///
/// BG: Luồng nghiệp vụ đã được đơn giản hoá trong plan migrate Lobby sang
/// Reservation/BVC. User vào "Cấu hình phòng chờ" (LobbyConfigPage) →
/// bấm "Xác nhận" → trang này hiển thị quote cọc → user bấm "Xác nhận" lần
/// nữa → `ReservationCubit.confirmReservation()` chạy atomic transaction.
///
/// **Quan trọng**: Lobby CHƯA được tạo ở bước "Cấu hình" — chỉ tạo nguyên
/// tử trong `ReservationCubit.confirmReservation()` (kèm hold BVC +
/// hold seat + hold game). Trước đây có page `LobbyCreateSetupPage` bị
/// duplicate với `LobbyConfigPage` — đã bị xoá.
///
/// Các state được render trong Scaffold an toàn:
/// - `ReservationInitial` / `ReservationQuoteLoading` / `ReservationConfirming`:
///   CircularProgressIndicator có AppBar + Back an toàn.
/// - `ReservationQuoteError` / `ReservationConfirmError` / `ReservationCancelError`:
///   ErrorView có nút "Quay lại Setup" + "Về trang chủ".
/// - `ReservationInsufficientBalance`: render [ReservationInsufficientPage].
/// - `ReservationQuoteLoaded`: countdown + summary + nút Confirm.
/// - `ReservationQuoteExpired`: tự động `retryQuote`.
/// - `ReservationConfirmed` → pushReplacement sang [LobbyPage] (host vào
///   thẳng lobby vừa được tạo nguyên tử). Trang
///   `PostConfirmLobbyPage`("Tạo phòng thành công") đã bị loại bỏ vì
///   bị chồng với `LobbyConfigPage` — host vào lobby luôn để có
///   full context (members, chat, recruit).
/// - `ReservationPendingCafeApproval` → pushReplacement sang pending page.
/// - `ReservationCancelled` → snackbar + back về Setup.
/// - `ReservationRejectedByCafe` → render thông báo reject.
/// - `ReservationCancelling` → loading.
class LobbyQuotePage extends StatefulWidget {
  const LobbyQuotePage({super.key});

  @override
  State<LobbyQuotePage> createState() => _LobbyQuotePageState();
}

class _LobbyQuotePageState extends State<LobbyQuotePage> {
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

  void _backToSetup() {
    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) {
      nav.pop();
    } else {
      LobbyFlowNavigator.returnToRoot(context);
    }
  }

  void _returnHome() {
    LobbyFlowNavigator.returnToRoot(context);
  }

  /// Mở LobbyPage sau khi confirm thành công.
  ///
  /// Lobby đã được tạo nguyên tử phía server trong
  /// `ReservationCubit.confirmReservation()`. Backend trả về
  /// `lobbyId` → host vào thẳng lobby của mình (status tuỳ theo
  /// `requiresCafeApproval` — Open / PendingActivation).
  ///
  /// `LobbyPage.initState` sẽ gọi `initLobbyState(lobbyId)` để fetch
  /// full chi tiết từ server (bỏ qua join — host đã là member).
  ///
  /// **Navigation**: dùng `pushAndKeepRootOnly` thay vì `pushReplacement`
  /// để clear hết stack trung gian (`LobbyConfigPage`, `LobbyQuotePage`,
  /// `LobbyCafeSelectionPage`, `LobbyHubPage`...). Stack sau khi push chỉ
  /// còn `[MainScaffold, LobbyPage]` → user bấm "Rời phòng" sẽ về thẳng
  /// MainScaffold, không rơi lại vào tab "Đặt cọc" của `LobbyConfigPage`
  /// cũ (UI stale, không phản ánh lobby mới đã tạo).
  void _openCreatedLobby(ReservationConfirmResult result) {
    final lobbyCubit = context.read<LobbyCubit>();

    LobbyFlowNavigator.pushAndKeepRootOnly<LobbyEntity>(
      context,
      LobbyPage(
        lobbyId: result.lobbyId,
        lobbyCubit: lobbyCubit,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Xác nhận đặt cọc'),
        leading: IconButton(
          tooltip: 'Quay lại',
          icon: const Icon(Icons.arrow_back),
          onPressed: _backToSetup,
        ),
      ),
      body: BlocConsumer<ReservationCubit, ReservationState>(
        listener: (context, state) {
          if (state is ReservationConfirmed) {
            // Lobby đã được tạo nguyên tử qua `confirmReservation`.
            // Route thẳng tới LobbyPage để host vào phòng chờ của mình —
            // bỏ qua "Tạo phòng thành công" trung gian (PostConfirmLobbyPage
            // đã deprecated vì lobby mở luôn cho host xem).
            _openCreatedLobby(state.result);
          }
          if (state is ReservationPendingCafeApproval) {
            // Clear stack trung gian (config/quote/cafe/hub) → stack chỉ
            // còn [MainScaffold, LobbyPendingCafeApprovalPage]. Khi user
            // bấm back từ pending page, về thẳng MainScaffold.
            LobbyFlowNavigator.pushAndKeepRootOnly(
              context,
              LobbyPendingCafeApprovalPage(
                reservationId: state.reservationId,
                cafeId: state.cafeId,
                cafeName: state.cafeName,
                cafeApprovalDeadline: state.cafeApprovalDeadline,
              ),
            );
          }
          if (state is ReservationCancelled) {
            // Sau khi huỷ, đóng QuotePage + về SetupPage để user sửa thông số.
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Đã hủy phiên đặt cọc. Hoàn ${state.result.refundBvc} BVC.',
                ),
              ),
            );
            _backToSetup();
          }
          if (state is ReservationQuoteExpired) {
            context.read<ReservationCubit>().retryQuote();
          }
        },
        builder: (context, state) {
          // Initial / đang loading quote hoặc confirm
          if (state is ReservationInitial ||
              state is ReservationQuoteLoading ||
              state is ReservationConfirming ||
              state is ReservationCancelling) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ReservationQuoteError ||
              state is ReservationConfirmError ||
              state is ReservationCancelError) {
            final message = state is ReservationQuoteError
                ? state.message
                : state is ReservationConfirmError
                    ? state.message
                    : (state as ReservationCancelError).message;
            return _ErrorView(
              message: message,
              onBack: _backToSetup,
              onHome: _returnHome,
            );
          }

          if (state is ReservationInsufficientBalance) {
            return _InsufficientView(
              missingBvc: state.missingBvc,
              onBack: _backToSetup,
            );
          }

          if (state is ReservationRejectedByCafe) {
            return _RejectedView(
              reason: state.reason,
              refundBvc: state.refundBvc,
              policy: state.refundPolicyApplied,
              onHome: _returnHome,
            );
          }

          if (state is ReservationQuoteLoaded) {
            return _loadedBody(context, state);
          }

          // State chưa từng gặp → render loading fallback để tránh màn hình
          // rỗng/đen.
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Text('Đang xử lý...'),
            ),
          );
        },
      ),
    );
  }

  Widget _loadedBody(BuildContext context, ReservationQuoteLoaded state) {
    final quote = state.quote;
    final remaining = quote.expiresAt.difference(DateTime.now());
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Phòng: ${quote.cafeName} • ${quote.gameName}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Cọc cần trừ: ${quote.finalDeposit} BVC',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text('Số dư hiện tại: ${quote.currentBalance} BVC'),
                    if (quote.isPrivate)
                      const Padding(
                        padding: EdgeInsets.only(top: AppSpacing.sm),
                        child: Text(
                          'Phòng riêng tư — không cần cafe duyệt.',
                        ),
                      )
                    else if (quote.requiresCafeApproval)
                      const Padding(
                        padding: EdgeInsets.only(top: AppSpacing.sm),
                        child: Text(
                          'Sau khi xác nhận sẽ chờ cafe duyệt.',
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              remaining.isNegative
                  ? 'Đã hết hạn — đang tạo lại báo giá…'
                  : 'Còn ${_formatDuration(remaining)} để xác nhận',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: remaining.isNegative
                  ? null
                  : () => context
                      .read<ReservationCubit>()
                      .confirmReservation(),
              child: const Text('Xác nhận & tạo lobby'),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(
              onPressed: () {
                // Quote chưa tạo DB row → chỉ cần reset cubit + back về
                // Setup để user sửa thông số.
                context.read<ReservationCubit>().reset();
                _backToSetup();
              },
              child: const Text('Huỷ báo giá'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    if (d.isNegative) return '00:00:00';
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${d.inHours.toString().padLeft(2, '0')}:$mm:$ss';
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onBack;
  final VoidCallback onHome;
  const _ErrorView({
    required this.message,
    required this.onBack,
    required this.onHome,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: AppSpacing.sm),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Quay lại'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: onHome,
              child: const Text('Về trang chủ'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InsufficientView extends StatelessWidget {
  final int missingBvc;
  final VoidCallback onBack;
  const _InsufficientView({
    required this.missingBvc,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.account_balance_wallet_outlined,
              size: 48,
              color: Colors.orangeAccent,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('Bạn thiếu $missingBvc BVC để tạo phòng.'),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Hãy vào tab Wallet để nạp thêm BVC rồi quay lại tiếp tục.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: () {
                // Đưa user về MainScaffold (tab Wallet) rồi pop QuotePage.
                LobbyFlowNavigator.returnToRoot(context);
              },
              icon: const Icon(Icons.account_balance_wallet),
              label: const Text('Mở Wallet'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: onBack,
              child: const Text('Quay lại'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RejectedView extends StatelessWidget {
  final String? reason;
  final int refundBvc;
  final String policy;
  final VoidCallback onHome;
  const _RejectedView({
    required this.reason,
    required this.refundBvc,
    required this.policy,
    required this.onHome,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cancel_outlined, size: 48, color: Colors.redAccent),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Quán đã từ chối duyệt phòng.',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (reason != null && reason!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text('Lý do: $reason', textAlign: TextAlign.center),
            ],
            const SizedBox(height: AppSpacing.sm),
            Text('Đã hoàn $refundBvc BVC ($policy).'),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: onHome,
              child: const Text('Về trang chủ'),
            ),
          ],
        ),
      ),
    );
  }
}
