import 'package:flutter/material.dart';

import '../../data/datasources/mock/mock_booking_remote_datasource.dart';

/// Dialog mock POS scanner cho việc test QR check-in.
///
/// Hiển thị các scenarios:
/// - Quét thành công
/// - Đã quét rồi (double scan)
/// - Không phải thành viên
/// - Booking không tồn tại
class QrScannerMockDialog extends StatefulWidget {
  final MockBookingRemoteDatasource datasource;
  final String bookingId;
  final List<String> memberIds;
  final String currentUserId;

  const QrScannerMockDialog({
    super.key,
    required this.datasource,
    required this.bookingId,
    required this.memberIds,
    required this.currentUserId,
  });

  static Future<void> show({
    required BuildContext context,
    required MockBookingRemoteDatasource datasource,
    required String bookingId,
    required List<String> memberIds,
    required String currentUserId,
  }) {
    return showDialog(
      context: context,
      builder: (_) => QrScannerMockDialog(
        datasource: datasource,
        bookingId: bookingId,
        memberIds: memberIds,
        currentUserId: currentUserId,
      ),
    );
  }

  @override
  State<QrScannerMockDialog> createState() => _QrScannerMockDialogState();
}

class _QrScannerMockDialogState extends State<QrScannerMockDialog> {
  String? _scanResult;
  bool _isScanning = false;

  void _simulateScan({String? userId, String? scenario}) {
    setState(() => _isScanning = true);

    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;

      QrScanResult result;
      if (scenario == 'not_found') {
        result = widget.datasource.simulateQrScan(
          bookingId: 'INVALID_BOOKING',
          scannedUserId: widget.currentUserId,
        );
      } else if (scenario == 'already_scanned') {
        result = widget.datasource.simulateQrScan(
          bookingId: widget.bookingId,
          scannedUserId: widget.currentUserId,
        );
      } else {
        result = widget.datasource.simulateQrScan(
          bookingId: widget.bookingId,
          scannedUserId: userId ?? widget.currentUserId,
        );
      }

      setState(() {
        _isScanning = false;
        _scanResult = result.success
            ? '✅ ${result.message}'
            : '❌ ${result.message}';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.qr_code_scanner, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          const Text('Mock: Quét QR POS'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Chọn scenario để mock:',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              const SizedBox(height: 16),

              // Quét thành công
              _ScanScenarioButton(
                label: '✅ Quét thành công',
                description: 'Scan với user hợp lệ',
                onTap: () => _simulateScan(userId: widget.currentUserId),
                isLoading: _isScanning,
              ),
              const SizedBox(height: 8),

              // Đã quét rồi
              _ScanScenarioButton(
                label: '⚠️ Đã quét rồi (Double Scan)',
                description: 'Nonce đã được sử dụng',
                onTap: () => _simulateScan(scenario: 'already_scanned'),
                isLoading: _isScanning,
              ),
              const SizedBox(height: 8),

              // Không phải thành viên
              _ScanScenarioButton(
                label: '🚫 Không phải thành viên',
                description: 'User không nằm trong danh sách',
                onTap: () => _simulateScan(userId: 'unknown_user_999'),
                isLoading: _isScanning,
              ),
              const SizedBox(height: 8),

              // Booking không tồn tại
              _ScanScenarioButton(
                label: '❓ Booking không tồn tại',
                description: 'Mã QR không hợp lệ',
                onTap: () => _simulateScan(scenario: 'not_found'),
                isLoading: _isScanning,
              ),

              if (_scanResult != null) ...[
                const SizedBox(height: 16),
                Container(
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
                  child: Text(
                    _scanResult!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 8),
              Text(
                'Thông tin booking:',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'ID: ${widget.bookingId}',
                style: theme.textTheme.bodySmall,
              ),
              Text(
                'Members: ${widget.memberIds.join(", ")}',
                style: theme.textTheme.bodySmall,
              ),
              Text(
                'Current User: ${widget.currentUserId}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Đóng'),
        ),
      ],
    );
  }
}

class _ScanScenarioButton extends StatelessWidget {
  final String label;
  final String description;
  final VoidCallback onTap;
  final bool isLoading;

  const _ScanScenarioButton({
    required this.label,
    required this.description,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
