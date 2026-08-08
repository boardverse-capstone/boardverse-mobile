import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/navigation/lobby_flow_navigator.dart';
import '../../../../core/theme/theme.dart';
import '../../../lobby_management/domain/entities/lobby_entity.dart';
import '../../../lobby_management/presentation/cubit/lobby_cubit.dart';
import '../../../lobby_management/presentation/pages/lobby_page.dart';
import '../../../lobby_management/presentation/pages/lobby_pending_cafe_approval_page.dart';
import '../../domain/entities/entities.dart';
import '../cubit/reservation_cubit.dart';
import '../cubit/reservation_state.dart';

/// Trang xác nhận đặt cọc reservation — entry point nghiệp vụ của feature
/// `reservation`. Tách ra từ `LobbyQuotePage` (cũ) để UI thuộc về feature
/// đúng chủ sở hữu theo kiến trúc.
///
/// Luồng:
/// 1. User vào "Cấu hình phòng chờ" (`LobbyConfigPage`) → bấm "Xác nhận".
/// 2. `ReservationCubit.createQuote()` chạy → emit `ReservationQuoteLoaded`.
/// 3. Trang này hiển thị quote (finalDeposit + countdown).
/// 4. User bấm "Xác nhận & tạo lobby" → `ReservationCubit.confirmReservation()`
///    chạy atomic transaction (trừ BVC + giữ seat + giữ game + insert Reservation
///    + insert Lobby).
/// 5. Sau confirm:
///    - Nếu không cần cafe duyệt → push sang `LobbyPage` (host vào thẳng).
///    - Nếu cần duyệt → push sang `LobbyPendingCafeApprovalPage`.
///
/// State được render trong Scaffold an toàn (AppBar + Back an toàn).
/// Xem `reservation_state.dart` để biết đầy đủ sealed states.
class ReservationQuotePage extends StatefulWidget {
  const ReservationQuotePage({super.key});

  @override
  State<ReservationQuotePage> createState() => _ReservationQuotePageState();
}

class _ReservationQuotePageState extends State<ReservationQuotePage> {
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

  /// Mở `LobbyPage` sau khi confirm thành công. Lobby đã được tạo nguyên tử
  /// phía server trong `ReservationCubit.confirmReservation()` — backend trả
  /// về `lobbyId` → host vào thẳng lobby của mình.
  ///
  /// Dùng `pushAndKeepRootOnly` thay vì `pushReplacement` để clear hết stack
  /// trung gian (`LobbyConfigPage`, `LobbyQuotePage` cũ, ...). Stack sau khi
  /// push chỉ còn `[MainScaffold, LobbyPage]` → user bấm "Rời phòng" sẽ về
  /// thẳng MainScaffold, không rơi lại vào flow cũ.
  void _openCreatedLobby(ReservationConfirmResult result) {
    final lobbyCubit = getIt<LobbyCubit>();

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
            _openCreatedLobby(state.result);
          }
          if (state is ReservationPendingCafeApproval) {
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
            return _LoadedBody(
              quote: state.quote,
              onConfirm: () => context
                  .read<ReservationCubit>()
                  .confirmReservation(),
              onCancel: () {
                // Quote chưa tạo DB row → chỉ cần reset cubit + back về
                // Setup để user sửa thông số.
                context.read<ReservationCubit>().reset();
                _backToSetup();
              },
            );
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
}

class _LoadedBody extends StatelessWidget {
  final ReservationQuoteEntity quote;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _LoadedBody({
    required this.quote,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
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
              onPressed:
                  remaining.isNegative ? null : onConfirm,
              child: const Text('Xác nhận & tạo lobby'),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(
              onPressed: onCancel,
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