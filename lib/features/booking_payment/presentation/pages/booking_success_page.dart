import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/theme.dart';
import '../../data/datasources/mock/mock_booking_remote_datasource.dart';
import '../../domain/enums/booking_status.dart';
import '../cubit/booking_result_cubit.dart';
import '../cubit/booking_result_state.dart';
import '../widgets/booking_qr_card.dart';
import '../widgets/cancel_booking_dialog.dart';
import '../widgets/qr_scanner_mock_dialog.dart';

/// Trang hiển thị QR sau khi thanh toán thành công — Host show cho nhân viên quán.
class BookingSuccessPage extends StatefulWidget {
  final String bookingId;

  const BookingSuccessPage({super.key, required this.bookingId});

  @override
  State<BookingSuccessPage> createState() => _BookingSuccessPageState();
}

class _BookingSuccessPageState extends State<BookingSuccessPage> {
  late final BookingResultCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<BookingResultCubit>()..loadById(widget.bookingId);
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _openMaps(String? cafeId) async {
    final query = Uri.encodeComponent('board game cafe ${cafeId ?? ''}');
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _cancelBooking() async {
    final reason = await CancelBookingDialog.show(
      context,
      bookingId: widget.bookingId,
    );
    if (reason == null || !mounted) return;
    await _cubit.cancelByPlayer(reason);
  }

  Future<void> _mockQrScan() async {
    final datasource = getIt<MockBookingRemoteDatasource>();
    await QrScannerMockDialog.show(
      context: context,
      datasource: datasource,
      bookingId: widget.bookingId,
      memberIds: const ['user_001', 'user_002', 'user_003'],
      currentUserId: 'user_001',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<BookingResultCubit, BookingResultState>(
      listener: (context, state) {
        if (state is ResultCancelled) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: AppColors.white, size: AppIcons.md),
                  const SizedBox(width: AppSpacing.xs),
                  const Text('Đã huỷ đơn đặt chỗ'),
                ],
              ),
              backgroundColor: AppColors.warning,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        if (state is ResultFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: theme.colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is ResultLoading || state is ResultInitial) {
          return Scaffold(
            appBar: AppBar(title: const Text('Đặt chỗ thành công')),
            body: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                AppShimmer.boxRadius(
                  context: context,
                  height: 96,
                  borderRadius: AppRadius.radiusMdAll,
                ),
                const SizedBox(height: AppSpacing.md),
                AppShimmer.card(context: context),
              ],
            ),
          );
        }

        final booking = _extractBooking(state);
        if (booking == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Đặt chỗ')),
            body: _ErrorState(
              message:
                  state is ResultFailure ? state.message : 'Không tải được đơn',
            ),
          );
        }

        final canCancel = booking.status == BookingStatus.confirmed;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Đặt chỗ thành công'),
            automaticallyImplyLeading: false,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSuccessHeader(theme),
                const SizedBox(height: AppSpacing.md),
                BookingQrCard(booking: booking),
                const SizedBox(height: AppSpacing.md),
                FilledButton.icon(
                  onPressed: () => _openMaps(booking.cafeId),
                  icon: const Icon(Icons.directions_rounded),
                  label: const Text('Mở chỉ đường (Google Maps)'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: AppColors.primary,
                  ),
                ),
                if (canCancel) ...[
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton.icon(
                    onPressed: _cancelBooking,
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Huỷ đơn'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      foregroundColor: AppColors.error,
                      side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: _mockQrScan,
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  label: const Text('Mock: Quét QR (POS)'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    foregroundColor: AppColors.warning,
                    side:
                        BorderSide(color: AppColors.warning.withValues(alpha: 0.5)),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextButton(
                  onPressed: () =>
                      Navigator.popUntil(context, (r) => r.isFirst),
                  child: const Text('Về trang chính'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuccessHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.success.withValues(alpha: 0.15),
            AppColors.success.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.radiusMdAll,
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.20),
              borderRadius: AppRadius.radiusSmAll,
            ),
            child: Icon(
              Icons.check_circle_rounded,
              color: AppColors.success,
              size: AppIcons.xl,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Đặt cọc thành công!',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Đưa mã QR cho nhân viên quán để bắt đầu phiên chơi.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  dynamic _extractBooking(BookingResultState state) {
    if (state is ResultConfirmed) return state.booking;
    if (state is ResultCheckedIn) return state.booking;
    if (state is ResultExpired) return state.booking;
    if (state is ResultCancelled) return state.booking;
    return null;
  }
}

class _ErrorState extends StatelessWidget {
  final String message;

  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
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
        ],
      ),
    );
  }
}
