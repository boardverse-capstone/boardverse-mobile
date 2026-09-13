import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/navigation/lobby_flow_navigator.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../lobby_management/domain/entities/lobby_entity.dart';
import '../../../lobby_management/presentation/cubit/lobby_cubit.dart';
import '../../../lobby_management/presentation/pages/lobby_page.dart';
import '../../../lobby_management/presentation/pages/lobby_pending_cafe_approval_page.dart';
import '../../../matchmaking_discovery/presentation/widgets/lobby_config/info_card.dart';
import '../../../matchmaking_discovery/presentation/widgets/lobby_config/summary_row.dart';
import '../../../matchmaking_discovery/presentation/widgets/lobby_config/quote_row.dart';
import '../../domain/entities/entities.dart';
import '../../../wallet/presentation/widgets/topup_bottom_sheet.dart';
import '../cubit/reservation_cubit.dart';
import '../cubit/reservation_state.dart';
import '../widgets/confirm_loading_view.dart';

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

  /// Được gọi sau khi user nạp BVC thành công qua [TopUpBottomSheet].
  ///
  /// Flow:
  /// 1. Re-quote để lấy balance mới + finalDeposit.
  /// 2. Nếu đủ tiền → emit `ReservationQuoteLoaded` → user có thể bấm
  ///    "Xác nhận & tạo lobby" (vì [refreshBalanceAndConfirm] được gọi
  ///    với `autoConfirm: false` mặc định).
  ///
  /// KHÔNG auto-confirm mặc định: user cần bấm tay để xác nhận (UX rõ ràng).
  /// Nếu user tick "Tự động đặt cọc sau khi nạp" toggle ở [InsufficientView],
  /// sẽ truyền `autoConfirm: true` → sau khi nạp xong tự động confirm.
  Future<void> _handleTopUpSuccess({bool autoConfirm = false}) async {
    final reservationCubit = context.read<ReservationCubit>();
    await reservationCubit.refreshBalanceAndConfirm(
      autoConfirm: autoConfirm,
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
            // Hiển thị toast báo thành công trước khi push sang lobby để
            // user biết đã đặt cọc thành công và bao nhiêu BVC đã bị trừ.
            _showSuccessToast(context, state.result);
            _openCreatedLobby(state.result);
          }
          if (state is ReservationPendingCafeApproval) {
            _showPendingApprovalToast(context, state);
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
          // Loading states — dùng ConfirmLoadingView đẹp (đang trừ BVC,
          // giữ chỗ, tạo lobby...) thay vì CircularProgressIndicator đơn điệu.
          if (state is ReservationInitial ||
              state is ReservationQuoteLoading) {
            return const ConfirmLoadingView(
              title: 'Đang tải báo giá',
              icon: Icons.receipt_long_rounded,
              steps: [
                'Đang tính cọc...',
                'Đang kiểm tra bàn trống...',
                'Đang tạo báo giá...',
              ],
              subtitle: 'Vui lòng đợi trong giây lát',
            );
          }

          if (state is ReservationConfirming) {
            return const ConfirmLoadingView(
              title: 'Đang đặt cọc & tạo lobby',
              icon: Icons.lock_outline_rounded,
              steps: [
                'Đang trừ BVC trong ví...',
                'Đang giữ chỗ ngồi...',
                'Đang tạo lobby...',
              ],
              subtitle: 'Xin đừng tắt app, quá trình đang hoàn tất',
            );
          }

          if (state is ReservationCancelling) {
            return const ConfirmLoadingView(
              title: 'Đang hủy đặt cọc',
              icon: Icons.cancel_outlined,
              accentColor: AppColors.error,
              steps: [
                'Đang hoàn BVC...',
                'Đang giải phóng chỗ...',
              ],
            );
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
              quote: state.quote,
              missingBvc: state.missingBvc,
              onBack: _backToSetup,
              onTopUpSuccess: _handleTopUpSuccess,
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

  /// Hiển thị toast báo đặt cọc thành công — neo-brutalism style.
  ///
  /// Thông báo:
  /// - Header: "Đặt cọc thành công"
  /// - Body: "Đã trừ {heldBvc} BVC. Lobby đã được tạo."
  /// - Màu success, có icon.
  ///
  /// Duration 3s, không cần user dismiss — tự ẩn.
  void _showSuccessToast(
    BuildContext context,
    ReservationConfirmResult result,
  ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(AppSpacing.md),
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: AppColors.border,
              width: NeoBrutalismTheme.borderWidth,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          content: Row(
            children: [
              // Icon badge
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.border,
                    width: NeoBrutalismTheme.borderWidth,
                  ),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Đặt cọc thành công',
                      style: TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Đã trừ ${result.heldBvc} BVC. Lobby đã được tạo.',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
  }

  /// Toast cho trường hợp lobby cần cafe duyệt — màu warning.
  void _showPendingApprovalToast(
    BuildContext context,
    ReservationPendingCafeApproval state,
  ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: AppColors.warning,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(AppSpacing.md),
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: AppColors.border,
              width: NeoBrutalismTheme.borderWidth,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          content: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.border,
                    width: NeoBrutalismTheme.borderWidth,
                  ),
                ),
                child: const Icon(
                  Icons.hourglass_top_rounded,
                  color: AppColors.warningDark,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Đã tạo lobby, đang chờ quán duyệt',
                      style: TextStyle(
                        color: AppColors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      state.cafeName != null
                          ? 'Quán "${state.cafeName}" sẽ phản hồi sớm.'
                          : 'Quán sẽ phản hồi sớm.',
                      style: const TextStyle(
                        color: AppColors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Risk / warning banner ───────────────────────────────
            if (quote.riskMultiplier > 1.0 || quote.warnings.isNotEmpty) ...[
              _WarningBanner(
                riskLevel: quote.riskLevel,
                riskMultiplier: quote.riskMultiplier,
                warnings: quote.warnings,
                baseDeposit: quote.baseDeposit,
                depositRatePerPerson: quote.depositRatePerPerson,
                minDepositApplied: quote.minDepositApplied,
                bufferMinutes: quote.bufferMinutes,
                bufferWarning: quote.bufferWarning,
                bufferWarningText: quote.bufferWarningLevel.message,
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // ── Section 1: Lobby info ───────────────────────────────
            LobbyConfigInfoCard(
              icon: Icons.event_note_rounded,
              iconColor: AppColors.primary,
              title: 'Thông tin lobby',
              useNeoStyle: true,
              child: Column(
                children: [
                  LobbyConfigSummaryRow(
                    icon: Icons.extension_rounded,
                    label: 'Game',
                    value: quote.gameName,
                  ),
                  _NeoDivider(isDark: isDark),
                  LobbyConfigSummaryRow(
                    icon: Icons.local_cafe_rounded,
                    label: 'Quán',
                    value: quote.cafeName,
                  ),
                  _NeoDivider(isDark: isDark),
                  LobbyConfigSummaryRow(
                    icon: Icons.calendar_today_rounded,
                    label: 'Ngày',
                    value: DateFormatter.dateOnly(quote.playDate),
                  ),
                  _NeoDivider(isDark: isDark),
                  LobbyConfigSummaryRow(
                    icon: Icons.schedule_rounded,
                    label: 'Giờ chơi',
                    value:
                        '${DateFormatter.timeOnly(quote.scheduledStartTime)} – ${DateFormatter.timeOnly(quote.scheduledEndTime)}',
                  ),
                  _NeoDivider(isDark: isDark),
                  LobbyConfigSummaryRow(
                    icon: Icons.group_rounded,
                    label: 'Số người',
                    value: '${quote.minPlayers} – ${quote.maxPlayers}',
                  ),
                  _NeoDivider(isDark: isDark),
                  LobbyConfigSummaryRow(
                    icon:
                        quote.isPrivate ? Icons.lock_rounded : Icons.public_rounded,
                    label: 'Chế độ',
                    value: quote.isPrivate ? 'Riêng tư' : 'Công khai',
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // ── Section 2: Deposit details ─────────────────────────
            LobbyConfigInfoCard(
              icon: Icons.payments_rounded,
              iconColor: AppColors.success,
              title: 'Chi tiết cọc',
              useNeoStyle: true,
              neoShadowColor: AppColors.success.withValues(alpha: 0.2),
              child: Column(
                children: [
                  // Deposit breakdown rows
                  LobbyConfigQuoteRow(
                    label: 'Cọc / người',
                    value: '${quote.depositRatePerPerson} BVC',
                  ),
                  _NeoDivider(isDark: isDark),
                  LobbyConfigQuoteRow(
                    label: 'Số người',
                    value: '${quote.minPlayers} – ${quote.maxPlayers}',
                  ),
                  _NeoDivider(isDark: isDark),
                  LobbyConfigQuoteRow(
                    label: 'Base deposit',
                    value: '${quote.baseDeposit} BVC',
                  ),
                  if (quote.riskMultiplier > 1.0) ...[
                    _NeoDivider(isDark: isDark),
                    LobbyConfigQuoteRow(
                      label: 'Hệ số rủi ro',
                      value: '×${quote.riskMultiplier.toStringAsFixed(2)}',
                    ),
                  ],
                  _NeoDivider(isDark: isDark),
                  LobbyConfigQuoteRow(
                    label: 'Buffer',
                    value: _formatBuffer(quote.bufferMinutes),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Final deposit highlight
                  Container(
                    padding: AppSpacing.paddingAllMd,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TỔNG CỌC',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: AppColors.white,
                            fontSize: 13,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          '${quote.finalDeposit} BVC',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: AppColors.white,
                            fontSize: 22,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Current balance row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Số dư hiện tại',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${quote.currentBalance} BVC',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),

                  // Private / cafe approval note
                  if (!quote.isPrivate && quote.requiresCafeApproval) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.warning,
                          width: NeoBrutalismTheme.borderWidth,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 16,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              'Sau khi xác nhận sẽ chờ quán duyệt.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.warningDark,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // ── Countdown timer ────────────────────────────────────
            Container(
              padding: AppSpacing.paddingAllMd,
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.border,
                  width: NeoBrutalismTheme.borderWidth,
                ),
                boxShadow: NeoBrutalismTheme.lightShadow(
                  shadowColor: AppColors.black.withValues(alpha: 0.06),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.timer_rounded,
                    color: remaining.isNegative
                        ? AppColors.error
                        : AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    remaining.isNegative
                        ? 'Đã hết hạn — đang tạo lại báo giá…'
                        : 'Còn ${_formatDuration(remaining)} để xác nhận',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: remaining.isNegative
                          ? AppColors.error
                          : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // ── Action buttons ─────────────────────────────────────
            FilledButton(
              onPressed: remaining.isNegative ? null : onConfirm,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                backgroundColor: AppColors.primary,
              ),
              child: const Text(
                'Xác nhận & Tạo lobby',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(
              onPressed: onCancel,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                side: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.border,
                  width: NeoBrutalismTheme.borderWidthBold,
                ),
              ),
              child: Text(
                'Huỷ báo giá',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatBuffer(int minutes) {
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return mins > 0 ? '$hours giờ $mins phút' : '$hours giờ';
    }
    return '$minutes phút';
  }

  String _formatDuration(Duration d) {
    if (d.isNegative) return '00:00:00';
    final hh = d.inHours.toString().padLeft(2, '0');
    final mm = (d.inMinutes % 60).toString().padLeft(2, '0');
    final ss = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hh:$mm:$ss';
  }
}

/// Neo-brutalism divider: 1.5px solid line.
class _NeoDivider extends StatelessWidget {
  final bool isDark;

  const _NeoDivider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1.5,
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      color: isDark ? AppColors.borderDark : AppColors.border,
    );
  }
}

/// Banner cảnh báo BR-NEW-15 — render `warnings[]` từ backend kèm risk
/// info. Show trước panel quote chính để user biết tại sao cọc cao / có
/// buffer / sắp chạm cap, v.v.
class _WarningBanner extends StatelessWidget {
  final RiskLevel riskLevel;
  final double riskMultiplier;
  final List<String> warnings;
  final int baseDeposit;
  final int depositRatePerPerson;
  final int minDepositApplied;
  final int bufferMinutes;
  final bool bufferWarning;
  final String? bufferWarningText;

  const _WarningBanner({
    required this.riskLevel,
    required this.riskMultiplier,
    required this.warnings,
    required this.baseDeposit,
    required this.depositRatePerPerson,
    required this.minDepositApplied,
    required this.bufferMinutes,
    required this.bufferWarning,
    this.bufferWarningText,
  });

  String _riskLabel(RiskLevel l) {
    switch (l) {
      case RiskLevel.low:
        return 'Bình thường';
      case RiskLevel.medium:
        return 'Trung bình';
      case RiskLevel.high:
        return 'Cao';
      case RiskLevel.critical:
        return 'Rất cao';
    }
  }

  Color _riskColor() {
    switch (riskLevel) {
      case RiskLevel.low:
        return AppColors.success;
      case RiskLevel.medium:
        return AppColors.warning;
      case RiskLevel.high:
        return AppColors.warning;
      case RiskLevel.critical:
        return AppColors.error;
    }
  }

  String? _warningMessage(String code) {
    switch (code) {
      case 'BUFFER_60_120':
        return 'Còn từ 60 – 120 phút tới giờ chơi — buffer cao ('
            '$bufferMinutes phút).';
      case 'NEAR_CAPACITY':
        return 'Quán sắp đầy chỗ — cọc có thể tăng theo cung cầu.';
      case 'RISK_MEDIUM':
        return 'Tài khoản bạn đang ở mức rủi ro trung bình (×$riskMultiplier).';
      case 'RISK_HIGH':
        return 'Tài khoản bạn đang ở mức rủi ro cao (×$riskMultiplier).';
      case 'NEAR_MAX_LOBBIES':
        return 'Bạn sắp chạm giới hạn số lobby/ngày.';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _riskColor();
    final reasonText = warnings
        .map(_warningMessage)
        .whereType<String>()
        .toList(growable: false);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: color, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Mức rủi ro: ${_riskLabel(riskLevel)}'
                  '${riskMultiplier > 1.0 ? ' (×${riskMultiplier.toStringAsFixed(2)})' : ''}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ],
          ),
          if (reasonText.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            ...reasonText.map(
              (msg) => Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '• $msg',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          ],
          if (bufferWarning && bufferWarningText != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              bufferWarningText!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ],
        ],
      ),
    );
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

class _InsufficientView extends StatefulWidget {
  final ReservationQuoteEntity quote;
  final int missingBvc;
  final VoidCallback onBack;
  final Future<void> Function({bool autoConfirm}) onTopUpSuccess;

  const _InsufficientView({
    required this.quote,
    required this.missingBvc,
    required this.onBack,
    required this.onTopUpSuccess,
  });

  @override
  State<_InsufficientView> createState() => _InsufficientViewState();
}

class _InsufficientViewState extends State<_InsufficientView> {
  bool _autoConfirmAfterTopUp = true;
  bool _isToppingUp = false;

  Future<void> _openTopUpSheet() async {
    setState(() => _isToppingUp = true);
    try {
      // Preset số tiền: nạp đủ + 20% buffer để tránh phải nạp lại nếu
      // backend recalculate deposit. Tối thiểu 50.000 VND.
      final missingVnd = widget.missingBvc * 1000;
      final bufferedVnd =
          ((missingVnd * 1.2) / 1000).ceil() * 1000;
      final initialVnd = bufferedVnd < 50000 ? 50000 : bufferedVnd;

      await TopUpBottomSheet.show(
        context: context,
        missingBvc: widget.missingBvc,
        initialAmountVnd: initialVnd,
        onSuccess: () {
          // Auto re-quote (và optional auto-confirm) sau khi sheet đóng.
          widget.onTopUpSuccess(autoConfirm: _autoConfirmAfterTopUp);
        },
      );
    } finally {
      if (mounted) setState(() => _isToppingUp = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;

    return Center(
      child: SingleChildScrollView(
        padding: AppSpacing.paddingAllMd,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header icon + title ──────────────────────────────
            Center(
              child: Container(
                width: 80,
                height: 80,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.warning,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor, width: 3),
                  boxShadow: NeoBrutalismTheme.lightShadow(
                    shadowColor: AppColors.warning.withValues(alpha: 0.5),
                  ),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: AppColors.black,
                  size: 40,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'SỐ DƯ KHÔNG ĐỦ',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Bạn cần thêm ${widget.missingBvc} BVC để hoàn tất đặt cọc',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Balance summary card ──────────────────────────────
            Container(
              padding: AppSpacing.paddingAllMd,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: borderColor,
                  width: NeoBrutalismTheme.borderWidthBold,
                ),
                boxShadow: NeoBrutalismTheme.lightShadow(
                  shadowColor: AppColors.black.withValues(alpha: 0.06),
                ),
              ),
              child: Column(
                children: [
                  _BalanceRow(
                    label: 'Số dư hiện tại',
                    value: '${widget.quote.currentBalance} BVC',
                    valueColor: AppColors.textPrimary,
                    borderColor: borderColor,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _BalanceRow(
                    label: 'Cọc cần trừ',
                    value: '${widget.quote.finalDeposit} BVC',
                    valueColor: AppColors.textPrimary,
                    borderColor: borderColor,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    height: 1.5,
                    color: borderColor,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _BalanceRow(
                    label: 'Thiếu',
                    value: '${widget.missingBvc} BVC',
                    valueColor: AppColors.error,
                    borderColor: borderColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Auto-confirm toggle ──────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.success,
                  width: NeoBrutalismTheme.borderWidth,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderColor, width: 2),
                    ),
                    child: const Icon(
                      Icons.bolt_rounded,
                      color: AppColors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Tự động đặt cọc sau khi nạp',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          'Sau khi nạp xong, hệ thống tự tạo lobby luôn',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: _autoConfirmAfterTopUp,
                    onChanged: (v) =>
                        setState(() => _autoConfirmAfterTopUp = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Primary action: Nạp BVC ngay (mở bottom sheet) ─
            _PrimaryAction(
              label: _isToppingUp ? 'ĐANG MỞ...' : 'NẠP BVC NGAY',
              icon: Icons.qr_code_2_rounded,
              onPressed: _isToppingUp ? null : _openTopUpSheet,
              borderColor: borderColor,
            ),
            const SizedBox(height: AppSpacing.sm),

            // ── Secondary actions ─────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _SecondaryAction(
                    label: 'MỞ WALLET',
                    icon: Icons.account_balance_wallet_rounded,
                    onPressed: () {
                      LobbyFlowNavigator.returnToRoot(context);
                    },
                    color: AppColors.textPrimary,
                    borderColor: borderColor,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _SecondaryAction(
                    label: 'QUAY LẠI',
                    icon: Icons.arrow_back_rounded,
                    onPressed: widget.onBack,
                    color: AppColors.textPrimary,
                    borderColor: borderColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final Color borderColor;

  const _BalanceRow({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color borderColor;

  const _PrimaryAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;
    return Container(
      decoration: BoxDecoration(
        color: isEnabled ? AppColors.primary : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: borderColor,
          width: NeoBrutalismTheme.borderWidthBold,
        ),
        boxShadow: isEnabled
            ? NeoBrutalismTheme.lightShadow(
                shadowColor: AppColors.primary.withValues(alpha: 0.5),
              )
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isEnabled ? AppColors.white : AppColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  label,
                  style: TextStyle(
                    color: isEnabled
                        ? AppColors.white
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;
  final Color borderColor;

  const _SecondaryAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.color,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: NeoBrutalismTheme.borderWidth,
        ),
        boxShadow: NeoBrutalismTheme.lightShadow(
          shadowColor: color.withValues(alpha: 0.2),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
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