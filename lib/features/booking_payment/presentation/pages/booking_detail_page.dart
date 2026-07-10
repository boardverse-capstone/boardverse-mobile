import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/di/injection.dart';
import '../../data/datasources/mock/mock_booking_remote_datasource.dart';
import '../../domain/entities/booking_entity.dart';
import 'booking_success_page.dart';

/// Trang chi tiết booking — hiển thị QR code + các actions tùy theo trạng thái.
///
/// Flow nghiệp vụ:
/// - confirmed: hiển thị QR + nút "Mock: Quét QR (POS)" để giả lập check-in
/// - checkedIn: hiển thị QR (đã dùng) + nút "Vào phiên chơi"
/// - pendingDeposit: hiển thị message "Chờ cọc"
/// - cancelled/expired: chỉ hiển thị thông tin
class BookingDetailPage extends StatefulWidget {
  final BookingEntity booking;

  const BookingDetailPage({super.key, required this.booking});

  @override
  State<BookingDetailPage> createState() => _BookingDetailPageState();
}

class _BookingDetailPageState extends State<BookingDetailPage> {
  late BookingEntity _booking;
  bool _isScanning = false;
  String? _scanResult;

  /// Timer để tick mỗi giây cho booking đang chơi / sắp tới (countdown).
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _booking = widget.booking;
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _simulateQrScan() async {
    setState(() {
      _isScanning = true;
      _scanResult = null;
    });

    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    try {
      final datasource = getIt<MockBookingRemoteDatasource>();
      final result = datasource.simulateQrScan(
        bookingId: _booking.id,
        scannedUserId: _booking.hostId,
      );

      if (!mounted) return;

      setState(() {
        _isScanning = false;
        _scanResult = result.success
            ? '✅ ${result.message}'
            : '❌ ${result.message}';
      });

      if (result.success && result.booking != null) {
        await Future.delayed(const Duration(milliseconds: 600));
        if (!mounted) return;

        final navigator = Navigator.of(context);
        navigator.pop(true);

        // ignore: use_build_context_synchronously
        navigator.push(
          MaterialPageRoute(
            builder: (_) => BookingSuccessPage(bookingId: _booking.id),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isScanning = false;
        _scanResult = '❌ Lỗi khi mô phỏng quét QR: $e';
      });
    }
  }

  void _openInGameSession() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingSuccessPage(bookingId: _booking.id),
      ),
    ).then((_) {
      if (mounted) Navigator.of(context).pop(true);
    });
  }

  Color _statusColor() {
    switch (_booking.status.name) {
      case 'confirmed':
        return Colors.blue;
      case 'checkedIn':
        return Colors.green;
      case 'pendingDeposit':
        return Colors.orange;
      case 'cancelledByPlayer':
      case 'cancelledByCafe':
        return Colors.grey;
      case 'expired':
        return Colors.red.shade400;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel() {
    switch (_booking.status.name) {
      case 'confirmed':
        return 'Đã xác nhận';
      case 'checkedIn':
        return 'Đang chơi';
      case 'pendingDeposit':
        return 'Chờ cọc';
      case 'cancelledByPlayer':
        return 'Đã hủy';
      case 'cancelledByCafe':
        return 'Quán hủy';
      case 'expired':
        return 'Hết hạn';
      default:
        return _booking.status.name;
    }
  }

  IconData _statusIcon() {
    switch (_booking.status.name) {
      case 'confirmed':
        return Icons.check_circle;
      case 'checkedIn':
        return Icons.sports_esports;
      case 'pendingDeposit':
        return Icons.hourglass_empty;
      case 'cancelledByPlayer':
      case 'cancelledByCafe':
        return Icons.cancel;
      case 'expired':
        return Icons.timer_off;
      default:
        return Icons.event;
    }
  }

  bool get _canCheckIn =>
      _booking.status.name == 'confirmed' &&
      _booking.qrPayload.isNotEmpty &&
      !_booking.nonceUsed;

  bool get _isInGame => _booking.status.name == 'checkedIn';

  bool get _isTerminal =>
      _booking.status.name == 'cancelledByPlayer' ||
      _booking.status.name == 'cancelledByCafe' ||
      _booking.status.name == 'expired' ||
      _booking.status.name == 'pendingDeposit';

  String _formatVnd(double v) {
    final f = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '',
      decimalDigits: 0,
    );
    return '${f.format(v).trim()} đ';
  }

  /// Format Duration → "1h 23m 45s" hoặc "23m 45s" hoặc "45s".
  String _formatDuration(Duration d) {
    final isNegative = d.isNegative;
    final abs = d.abs();
    final h = abs.inHours;
    final m = abs.inMinutes.remainder(60);
    final s = abs.inSeconds.remainder(60);

    String core;
    if (h > 0) {
      core = '${h}h ${m.toString().padLeft(2, '0')}m ${s.toString().padLeft(2, '0')}s';
    } else if (m > 0) {
      core = '${m}m ${s.toString().padLeft(2, '0')}s';
    } else {
      core = '${s}s';
    }

    return isNegative ? 'Quá giờ $core' : core;
  }

  /// Banner đếm giờ:
  /// - checkedIn → "Đang chơi: 1h 23m" (tính từ updatedAt)
  /// - confirmed → "Bắt đầu sau: 30m" (countdown tới scheduledTime)
  /// - pendingDeposit → "Hết hạn cọc sau: 12m"
  Widget _buildTimeBanner(ThemeData theme) {
    final now = DateTime.now();
    final status = _booking.status.name;

    if (status == 'checkedIn') {
      final elapsed = now.difference(_booking.updatedAt);
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade100, Colors.green.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.timer, color: Colors.green.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Đang chơi',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.green.shade900,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _formatDuration(elapsed),
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.green.shade900,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Check-in lúc ${DateFormat('HH:mm').format(_booking.updatedAt)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (status == 'confirmed') {
      final remaining = _booking.scheduledTime.difference(now);
      if (remaining.isNegative) {
        // Đã qua giờ mà chưa check-in → cảnh báo.
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.shade300),
          ),
          child: Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.red.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Đã qua giờ hẹn ${_formatDuration(remaining.abs())}',
                  style: TextStyle(
                    color: Colors.red.shade900,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      }
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.schedule, color: Colors.blue.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bắt đầu sau',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.blue.shade900,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _formatDuration(remaining),
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.blue.shade900,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (status == 'pendingDeposit') {
      final remaining = _booking.remainingGraceTime;
      if (remaining.isNegative) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.shade300),
          ),
          child: Row(
            children: [
              Icon(Icons.error, color: Colors.red.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Đã quá hạn cọc — booking sẽ bị huỷ',
                  style: TextStyle(
                    color: Colors.red.shade900,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      }
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.hourglass_empty, color: Colors.orange.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hết hạn cọc sau',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.orange.shade900,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _formatDuration(remaining),
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.orange.shade900,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _statusColor();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết lịch hẹn'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Header ────────────────────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: color.withValues(alpha: 0.1),
                          child: Icon(_statusIcon(), color: color, size: 28),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _booking.gameName,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '📍 ${_booking.cafeName}',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _statusLabel(),
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 16, color: theme.colorScheme.outline),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            DateFormat('EEEE, dd/MM/yyyy — HH:mm')
                                .format(_booking.scheduledTime),
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.group, size: 16, color: theme.colorScheme.outline),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${_booking.seatCount} người • ${_booking.memberIds.length} thành viên',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.attach_money, size: 16, color: theme.colorScheme.outline),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Đã cọc: ${_formatVnd(_booking.depositAmount)}',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.qr_code, size: 16, color: theme.colorScheme.outline),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Mã: ${_booking.id}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ─── Countdown / Elapsed Time Banner ───────────────────────
            _buildTimeBanner(theme),

            const SizedBox(height: 16),

            // ─── QR Code Card ──────────────────────────────────────────
            if (!_isTerminal) ...[
              _buildQrSection(theme, color),
              const SizedBox(height: 16),
            ],

            // ─── Scan Result ───────────────────────────────────────────
            if (_scanResult != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _scanResult!.startsWith('✅')
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _scanResult!.startsWith('✅')
                        ? Colors.green.shade300
                        : Colors.red.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _scanResult!.startsWith('✅')
                          ? Icons.check_circle
                          : Icons.error,
                      color: _scanResult!.startsWith('✅')
                          ? Colors.green
                          : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _scanResult!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // ─── Action Buttons ────────────────────────────────────────
            if (_canCheckIn) _buildCheckInButton(),
            if (_isInGame) _buildInGameButton(),
            if (_isTerminal) _buildTerminalMessage(theme),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildQrSection(ThemeData theme, Color color) {
    final hasQr = _booking.qrPayload.isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.qr_code_2, color: color),
                const SizedBox(width: 8),
                Text(
                  'Mã QR Check-in',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: hasQr
                  ? QrImageView(
                      data: _booking.qrPayload,
                      version: QrVersions.auto,
                      size: 220,
                      backgroundColor: Colors.white,
                      errorCorrectionLevel: QrErrorCorrectLevel.M,
                    )
                  : Column(
                      children: [
                        Icon(
                          Icons.qr_code_2,
                          size: 80,
                          color: theme.colorScheme.outlineVariant,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Chưa có mã QR cho booking này',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 12),
            if (_booking.nonceUsed)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning_amber, size: 16, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'QR đã được sử dụng',
                      style: TextStyle(
                        color: Colors.orange.shade900,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              )
            else if (_booking.status.name == 'confirmed')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Đưa mã này cho nhân viên quán để check-in',
                      style: TextStyle(
                        color: Colors.blue.shade900,
                        fontSize: 12,
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

  Widget _buildCheckInButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton.icon(
        onPressed: _isScanning ? null : _simulateQrScan,
        icon: _isScanning
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.qr_code_scanner),
        label: Text(_isScanning ? 'Đang quét...' : 'Mock: Quét QR (POS)'),
        style: FilledButton.styleFrom(
          backgroundColor: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildInGameButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton.icon(
        onPressed: _openInGameSession,
        icon: const Icon(Icons.sports_esports),
        label: const Text('Vào phiên chơi'),
        style: FilledButton.styleFrom(
          backgroundColor: Colors.green,
        ),
      ),
    );
  }

  Widget _buildTerminalMessage(ThemeData theme) {
    String message;
    IconData icon;
    Color color;

    switch (_booking.status.name) {
      case 'pendingDeposit':
        message = 'Bạn cần hoàn tất đặt cọc để kích hoạt booking này.';
        icon = Icons.hourglass_empty;
        color = Colors.orange;
        break;
      case 'cancelledByPlayer':
      case 'cancelledByCafe':
        message = 'Booking này đã bị hủy.';
        icon = Icons.cancel;
        color = Colors.grey;
        break;
      case 'expired':
        message = 'Booking đã hết hạn. Vui lòng tạo đơn mới.';
        icon = Icons.timer_off;
        color = Colors.red.shade400;
        break;
      default:
        message = 'Booking không khả dụng.';
        icon = Icons.info_outline;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
