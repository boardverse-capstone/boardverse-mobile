import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
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
      shape: RoundedRectangleBorder(borderRadius: AppRadius.dialogRadius),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: AppRadius.radiusSmAll,
            ),
            child: Icon(
              Icons.qr_code_scanner_rounded,
              size: AppIcons.md,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          const Expanded(
            child: Text(
              'Mock: Quét QR POS',
              overflow: TextOverflow.ellipsis,
            ),
          ),
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
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              _ScanScenarioButton(
                label: 'Quét thành công',
                description: 'Scan với user hợp lệ',
                icon: Icons.check_circle_rounded,
                accent: AppColors.success,
                onTap: () =>
                    _simulateScan(userId: widget.currentUserId),
                isLoading: _isScanning,
              ),
              const SizedBox(height: AppSpacing.xs),

              _ScanScenarioButton(
                label: 'Đã quét rồi (Double Scan)',
                description: 'Nonce đã được sử dụng',
                icon: Icons.warning_amber_rounded,
                accent: AppColors.warning,
                onTap: () =>
                    _simulateScan(scenario: 'already_scanned'),
                isLoading: _isScanning,
              ),
              const SizedBox(height: AppSpacing.xs),

              _ScanScenarioButton(
                label: 'Không phải thành viên',
                description: 'User không nằm trong danh sách',
                icon: Icons.block_rounded,
                accent: AppColors.error,
                onTap: () =>
                    _simulateScan(userId: 'unknown_user_999'),
                isLoading: _isScanning,
              ),
              const SizedBox(height: AppSpacing.xs),

              _ScanScenarioButton(
                label: 'Booking không tồn tại',
                description: 'Mã QR không hợp lệ',
                icon: Icons.help_outline_rounded,
                accent: AppColors.textSecondary,
                onTap: () => _simulateScan(scenario: 'not_found'),
                isLoading: _isScanning,
              ),

              if (_scanResult != null) ...[
                const SizedBox(height: AppSpacing.sm),
                _ScanResultBanner(text: _scanResult!),
              ],

              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.4),
                  borderRadius: AppRadius.radiusXsAll,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thông tin booking',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
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
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;
  final bool isLoading;

  const _ScanScenarioButton({
    required this.label,
    required this.description,
    required this.icon,
    required this.accent,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: accent.withValues(alpha: 0.08),
      borderRadius: AppRadius.radiusMdAll,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: AppRadius.radiusMdAll,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: AppRadius.radiusMdAll,
            border: Border.all(color: accent.withValues(alpha: 0.30)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.18),
                  borderRadius: AppRadius.radiusXxsAll,
                ),
                child: Icon(icon, size: AppIcons.md, color: accent),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (isLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              else
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: AppIcons.sm,
                  color: accent.withValues(alpha: 0.7),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanResultBanner extends StatelessWidget {
  final String text;
  const _ScanResultBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ok = text.startsWith('✅');
    final color = ok ? AppColors.success : AppColors.error;
    final icon =
        ok ? Icons.check_circle_rounded : Icons.error_rounded;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: AppRadius.radiusMdAll,
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
