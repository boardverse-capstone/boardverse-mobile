import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/navigation/widgets/booking_pending_resume_helper.dart';
import '../../../../core/theme/theme.dart';
import '../cubit/booking_summary_cubit.dart';
import '../cubit/booking_summary_state.dart';
import '../../domain/enums/payment_method.dart';
import '../widgets/availability_banner.dart';
import '../widgets/booking_ui_helpers.dart';
import '../widgets/deposit_breakdown_card.dart';
import '../widgets/payment_method_selector.dart';
import '../widgets/section_header.dart';
import '../widgets/table_picker_sheet.dart';
import 'payment_page.dart';

/// Trang tóm tắt trước khi thanh toán — hiển thị breakdown giá, gọi
/// `createBooking` rồi push `PaymentPage`.
///
/// Tích hợp mới (gaps #1, #2, #3):
/// - `lobbyId` nullable: walk-in flow (gap #3) cho phép đặt chỗ không qua lobby.
/// - Auto-load bàn trống + availability (gap #1, #2) — user có thể đổi bàn
///   qua `TablePickerSheet`.
/// - `autoBookingId` (Luồng A): skip createBooking, push thẳng PaymentPage.
class BookingSummaryPage extends StatefulWidget {
  /// Nullable cho walk-in booking (gap #3).
  final String? lobbyId;
  final String cafeId;
  final String cafeName;
  final String cafeTableId;
  final String gameId;
  final String gameName;
  final DateTime scheduledStartTime;
  final DateTime scheduleEndTime;
  final int seatCount;
  final int? playerQuantity;

  /// Id booking đã được auto-create từ Luồng A (lobby đầy).
  final String? autoBookingId;

  const BookingSummaryPage({
    super.key,
    this.lobbyId,
    required this.cafeId,
    required this.cafeName,
    this.cafeTableId = '',
    required this.gameId,
    required this.gameName,
    required this.scheduledStartTime,
    required this.scheduleEndTime,
    required this.seatCount,
    required this.playerQuantity,
    this.autoBookingId,
  });

  @override
  State<BookingSummaryPage> createState() => _BookingSummaryPageState();
}

class _BookingSummaryPageState extends State<BookingSummaryPage> {
  late final BookingSummaryCubit _cubit;
  late DateTime _scheduledEndTime;

  static const Duration _minDuration = Duration(hours: 1);
  static const Duration _maxDuration = Duration(hours: 6);

  @override
  void initState() {
    super.initState();
    _scheduledEndTime = widget.scheduleEndTime;
    _cubit = getIt<BookingSummaryCubit>()
      ..loadConfig(
        widget.cafeId,
        scheduledStartTime: widget.scheduledStartTime,
        scheduleEndTime: _scheduledEndTime,
        seatCount: widget.seatCount,
      );

    if (widget.autoBookingId != null) {
      // Luồng A: booking đã có → skip bước submit, nhảy thẳng PaymentPage
      // sau khi load config xong. Fetch booking thật để hiển thị deadline.
      _cubit.stream.first.then((_) => _fetchAutoBookingAndContinue());
    }
  }

  Future<void> _fetchAutoBookingAndContinue() async {
    final repo = sl<BookingPersistenceResumeHelper>();
    final booking = await repo.fetchBooking(widget.autoBookingId!);
    if (!mounted || booking == null) return;
    final config = await repo.fetchDepositConfig(booking.cafeId);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentPage(
          bookingId: booking.id,
          cafeId: booking.cafeId,
          cafeName: booking.cafeName,
          depositAmount: booking.depositAmount,
          deadline: booking.depositDeadline,
          config: config,
          method: PaymentMethod.sepay,
        ),
      ),
    );
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
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => PaymentPage(
                  bookingId: state.bookingId,
                  cafeId: widget.cafeId,
                  cafeName: widget.cafeName,
                  depositAmount: state.depositAmount,
                  deadline: state.deadline,
                  config: null,
                  method: PaymentMethod.sepay,
                ),
              ),
            );
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
              appBar: AppBar(title: const Text('Xác nhận đặt cọc')),
              body: _buildBody(context, state),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, BookingSummaryState state) {
    if (state is SummaryInitial ||
        state is SummaryLoading ||
        state is SummaryLoadingTables) {
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
    final availability = state.availability;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner availability (gap #2) — chỉ render khi backend trả về
          if (availability != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: AvailabilityBanner(
                availability: availability,
                onPickAlternative: (slot) {
                  setState(() {
                    _scheduledEndTime = slot.endTime;
                  });
                  _cubit.reloadTables(
                    cafeId: widget.cafeId,
                    scheduledStartTime: slot.startTime,
                    scheduleEndTime: slot.endTime,
                    seatCount: widget.seatCount,
                  );
                },
              ),
            ),
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
                        _kv(
                          theme,
                          AppIcons.clock,
                          'Giờ hẹn',
                          BookingUiHelpers.formatDateTime(
                            widget.scheduledStartTime,
                            pattern: 'HH:mm • dd/MM/yyyy',
                          ),
                        ),
                        _kv(
                          theme,
                          AppIcons.timer,
                          'Kết thúc',
                          BookingUiHelpers.formatDateTime(
                            _scheduledEndTime,
                            pattern: 'HH:mm • dd/MM/yyyy',
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: _pickEndTime,
                            icon: const Icon(Icons.edit_calendar_rounded),
                            label: const Text('Đổi giờ kết thúc'),
                          ),
                        ),
                        _kv(
                          theme,
                          AppIcons.users,
                          'Số ghế',
                          widget.seatCount.toString(),
                        ),
                        if (widget.lobbyId == null)
                          Padding(
                            padding:
                                const EdgeInsets.only(top: AppSpacing.xs),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.directions_walk_rounded,
                                  size: AppIcons.sm,
                                  color: theme.colorScheme.tertiary,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  'Walk-in (không qua lobby)',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.tertiary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        // Table picker (gap #1)
                        if (state.availableTables.isNotEmpty)
                          Padding(
                            padding:
                                const EdgeInsets.only(top: AppSpacing.sm),
                            child: OutlinedButton.icon(
                              onPressed: () => _openTablePicker(state),
                              icon: const Icon(Icons.table_restaurant_rounded),
                              label: Text(
                                state.selectedTableId == null
                                    ? 'Chọn bàn (${state.availableTables.length} bàn trống)'
                                    : 'Đã chọn: ${_tableLabel(state)}',
                              ),
                            ),
                          ),
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
          // Chỉ 1 cổng SePay — render chip tóm tắt thay vì selector.
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.30),
              borderRadius: AppRadius.cardRadius,
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.30),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.account_balance_wallet_rounded,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Thanh toán qua SePay — QR ngân hàng sẽ hiển thị sau khi bạn xác nhận.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: () => _cubit.submit(
              lobbyId: widget.lobbyId,
              cafeId: widget.cafeId,
              cafeTableId: widget.cafeTableId,
              scheduledStartTime: widget.scheduledStartTime,
              scheduleEndTime: _scheduledEndTime,
              playerQuantity: widget.playerQuantity,
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

  String _tableLabel(SummaryReady state) {
    final id = state.selectedTableId;
    if (id == null) return 'chưa chọn';
    final match = state.availableTables.where((t) => t.id == id);
    return match.isEmpty ? id : '${match.first.name} (${match.first.seatCount} ghế)';
  }

  Future<void> _openTablePicker(SummaryReady state) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => TablePickerSheet(
        tables: state.availableTables,
        initialId: state.selectedTableId,
      ),
    );
    if (picked != null && picked.isNotEmpty) {
      _cubit.selectTable(picked);
    }
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

  Future<void> _pickEndTime() async {
    final initial = _scheduledEndTime;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: widget.scheduledStartTime,
      lastDate: widget.scheduledStartTime.add(const Duration(days: 30)),
    );
    if (pickedDate == null || !mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (pickedTime == null || !mounted) return;
    final candidate = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
    final diff = candidate.difference(widget.scheduledStartTime);
    if (diff < _minDuration || diff > _maxDuration) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Khung giờ chơi phải kéo dài từ 1 đến 6 giờ.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _scheduledEndTime = candidate);
    // Reload tables sau khi đổi end time.
    _cubit.reloadTables(
      cafeId: widget.cafeId,
      scheduledStartTime: widget.scheduledStartTime,
      scheduleEndTime: candidate,
      seatCount: widget.seatCount,
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
            onPressed: () => _cubit.loadConfig(
              widget.cafeId,
              scheduledStartTime: widget.scheduledStartTime,
              scheduleEndTime: _scheduledEndTime,
              seatCount: widget.seatCount,
            ),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }
}

/// Convenience export để tránh lint "unused" cho [PaymentMethodSelector]
/// không còn được dùng trong flow mới (chỉ 1 cổng SePay). Imports trong
/// `payment_page.dart` vẫn giữ reference để tương thích ngược.
// ignore: unused_element
typedef _KeepSelectors = PaymentMethodSelector;