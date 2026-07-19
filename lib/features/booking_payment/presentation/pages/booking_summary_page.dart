import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/theme.dart';
import '../cubit/booking_summary_cubit.dart';
import '../cubit/booking_summary_state.dart';
import '../widgets/booking_ui_helpers.dart';
import '../widgets/deposit_breakdown_card.dart';
import '../widgets/payment_method_selector.dart';
import '../widgets/section_header.dart';

/// Trang tóm tắt trước khi thanh toán — hiển thị breakdown giá, phương thức
/// thanh toán, gọi cubit tạo booking rồi push `PaymentPage`.
class BookingSummaryPage extends StatefulWidget {
  final String lobbyId;
  final String cafeId;
  final String cafeName;
  final String gameId;
  final String gameName;
  final DateTime scheduledTime;
  final int seatCount;
  final List<String> memberIds;

  /// Id booking đã được auto-create từ Luồng A (lobby đầy). Khi có giá trị,
  /// summary page có thể hiển thị badge "Đã được tạo tự động" hoặc skip bước
  /// createBooking. (Hiện tại chỉ dùng cho UI label, không dùng để skip bước
  /// vì server đã tạo sẵn — phase sau sẽ resume flow dùng trực tiếp id này.)
  final String? autoBookingId;

  const BookingSummaryPage({
    super.key,
    required this.lobbyId,
    required this.cafeId,
    required this.cafeName,
    required this.gameId,
    required this.gameName,
    required this.scheduledTime,
    required this.seatCount,
    required this.memberIds,
    this.autoBookingId,
  });

  @override
  State<BookingSummaryPage> createState() => _BookingSummaryPageState();
}

class _BookingSummaryPageState extends State<BookingSummaryPage> {
  late final BookingSummaryCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<BookingSummaryCubit>()..loadConfig(widget.cafeId);
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<bool> _confirmLeave() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.dialogRadius),
        icon: Icon(
          Icons.help_outline_rounded,
          size: AppIcons.xxl,
          color: AppColors.warning,
        ),
        title: const Text('Rời trang?'),
        content: const Text(
          'Nếu rời bây giờ, thông tin đặt chỗ sẽ bị huỷ. Bạn có chắc?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Ở lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Rời đi'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocConsumer<BookingSummaryCubit, BookingSummaryState>(
        listener: (context, state) {
          if (state is SummarySuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle_rounded,
                        color: AppColors.white, size: AppIcons.md),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        'Tạo booking thành công! bookingId=${state.bookingId}, '
                        'cọc=${state.depositAmount}đ (payment tạm khoá)',
                      ),
                    ),
                  ],
                ),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 5),
              ),
            );
            Navigator.popUntil(context, (route) => route.isFirst);
          }
          if (state is SummaryFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) async {
              if (didPop) return;
              if (await _confirmLeave() && context.mounted) {
                Navigator.pop(context);
              }
            },
            child: Scaffold(
              appBar: AppBar(title: const Text('Xác nhận đặt chỗ')),
              body: _buildBody(context, state),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, BookingSummaryState state) {
    if (state is SummaryInitial || state is SummaryLoading) {
      return _buildLoadingState(context);
    }
    if (state is SummaryFailure && state.code == 'FETCH_CONFIG') {
      return _buildError(context, state.message);
    }
    if (state is SummaryReady) {
      return _buildReady(context, state);
    }
    if (state is SummarySubmitting) {
      return const Center(child: CircularProgressIndicator());
    }
    return const SizedBox.shrink();
  }

  Widget _buildLoadingState(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        AppShimmer.boxRadius(
          context: context,
          height: 160,
          borderRadius: AppRadius.cardRadius,
        ),
        const SizedBox(height: AppSpacing.md),
        AppShimmer.boxRadius(
          context: context,
          height: 200,
          borderRadius: AppRadius.cardRadius,
        ),
        const SizedBox(height: AppSpacing.md),
        AppShimmer.boxRadius(
          context: context,
          height: 120,
          borderRadius: AppRadius.cardRadius,
        ),
      ],
    );
  }

  Widget _buildReady(BuildContext context, SummaryReady state) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: AppRadius.cardRadius,
              border: Border.all(
                color:
                    theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
              boxShadow: AppElevation.shadowXxs,
            ),
            child: ClipRRect(
              borderRadius: AppRadius.cardRadius,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.12),
                          AppColors.primary.withValues(alpha: 0.02),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: SectionHeader(
                      icon: AppIcons.cafe,
                      title: widget.gameName,
                      subtitle: widget.cafeName,
                      accent: AppColors.primary,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _kv(theme, AppIcons.clock, 'Giờ hẹn',
                            BookingUiHelpers.formatDateTime(
                                widget.scheduledTime,
                                pattern: 'HH:mm • dd/MM/yyyy')),
                        _kv(theme, AppIcons.users, 'Số ghế',
                            widget.seatCount.toString()),
                        _kv(theme, AppIcons.users, 'Số thành viên',
                            widget.memberIds.length.toString()),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          DepositBreakdownCard(breakdown: state.breakdown),
          const SizedBox(height: AppSpacing.md),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: AppRadius.cardRadius,
              border: Border.all(
                color:
                    theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
              boxShadow: AppElevation.shadowXxs,
            ),
            child: PaymentMethodSelector(
              selected: state.selectedMethod,
              onChanged: _cubit.selectPaymentMethod,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: () => _cubit.submit(
              cafeId: widget.cafeId,
              gameId: widget.gameId,
              scheduledTime: widget.scheduledTime,
              seatCount: widget.seatCount,
              memberIds: widget.memberIds,
            ),
            icon: const Icon(Icons.lock_outline_rounded),
            label: const Text('Xác nhận & Thanh toán'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _kv(ThemeData theme, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.10),
              borderRadius: AppRadius.radiusXxsAll,
            ),
            child: Icon(icon, size: AppIcons.md, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: AppIcons.xxl,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: () => _cubit.loadConfig(widget.cafeId),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }
}
