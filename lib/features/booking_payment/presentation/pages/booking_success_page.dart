import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/injection.dart';
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
    // Phase sau sẽ lookup địa chỉ quán từ API để build URL chính xác.
    // Tạm thời mở Google Maps search theo tên.
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
      memberIds: ['user_001', 'user_002', 'user_003'],
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
            const SnackBar(
              content: Text('Đã huỷ đơn đặt chỗ'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        if (state is ResultFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: theme.colorScheme.error,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is ResultLoading || state is ResultInitial) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final booking = _extractBooking(state);
        if (booking == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: Text(state is ResultFailure ? state.message : 'Không tải được đơn'),
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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSuccessHeader(theme),
                const SizedBox(height: 16),
                BookingQrCard(booking: booking),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => _openMaps(booking.cafeId),
                  icon: const Icon(Icons.directions),
                  label: const Text('Mở chỉ đường (Google Maps)'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                if (canCancel) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _cancelBooking,
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Huỷ đơn'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      foregroundColor: Colors.red.shade700,
                      side: BorderSide(color: Colors.red.shade300),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _mockQrScan,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Mock: Quét QR (POS)'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    foregroundColor: Colors.orange.shade700,
                    side: BorderSide(color: Colors.orange.shade300),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green.shade700, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Đặt cọc thành công!',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade900,
                  ),
                ),
                Text(
                  'Đưa mã QR cho nhân viên quán để bắt đầu phiên chơi.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.green.shade900,
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