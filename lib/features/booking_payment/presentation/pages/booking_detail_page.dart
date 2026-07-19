import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/theme.dart';
import '../../data/datasources/mock/mock_booking_remote_datasource.dart';
import '../../domain/entities/booking_entity.dart';
import '../widgets/booking_ui_helpers.dart';
import '../widgets/info_row.dart';
import '../widgets/section_header.dart';
import '../widgets/status_pill.dart';
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
        return AppColors.info;
      case 'checkedIn':
        return AppColors.success;
      case 'pendingDeposit':
        return AppColors.warning;
      case 'cancelledByPlayer':
      case 'cancelledByCafe':
        return AppColors.textSecondary;
      case 'expired':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _statusIcon() {
    switch (_booking.status.name) {
      case 'confirmed':
        return Icons.check_circle_rounded;
      case 'checkedIn':
        return Icons.sports_esports_rounded;
      case 'pendingDeposit':
        return Icons.hourglass_top_rounded;
      case 'cancelledByPlayer':
      case 'cancelledByCafe':
        return Icons.cancel_rounded;
      case 'expired':
        return Icons.timer_off_rounded;
      default:
        return Icons.event_rounded;
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
      return _TimeBanner(
        icon: Icons.timer_rounded,
        label: 'Đang chơi',
        value: _formatDuration(elapsed),
        subtitle: 'Check-in lúc ${DateFormat('HH:mm').format(_booking.updatedAt)}',
        backgroundColor: AppColors.success.withValues(alpha: 0.10),
        borderColor: AppColors.success.withValues(alpha: 0.40),
        foreground: AppColors.success,
      );
    }

    if (status == 'confirmed') {
      final remaining = _booking.scheduledTime.difference(now);
      if (remaining.isNegative) {
        return _TimeBanner(
          icon: Icons.warning_amber_rounded,
          label: 'Đã qua giờ hẹn',
          value: _formatDuration(remaining.abs()),
          backgroundColor: AppColors.error.withValues(alpha: 0.10),
          borderColor: AppColors.error.withValues(alpha: 0.40),
          foreground: AppColors.error,
        );
      }
      return _TimeBanner(
        icon: Icons.schedule_rounded,
        label: 'Bắt đầu sau',
        value: _formatDuration(remaining),
        backgroundColor: AppColors.info.withValues(alpha: 0.10),
        borderColor: AppColors.info.withValues(alpha: 0.40),
        foreground: AppColors.info,
      );
    }

    if (status == 'pendingDeposit') {
      final remaining = _booking.remainingGraceTime;
      if (remaining.isNegative) {
        return _TimeBanner(
          icon: Icons.error_rounded,
          label: 'Đã quá hạn cọc',
          value: 'Booking sẽ bị huỷ',
          backgroundColor: AppColors.error.withValues(alpha: 0.10),
          borderColor: AppColors.error.withValues(alpha: 0.40),
          foreground: AppColors.error,
        );
      }
      return _TimeBanner(
        icon: Icons.hourglass_top_rounded,
        label: 'Hết hạn cọc sau',
        value: _formatDuration(remaining),
        backgroundColor: AppColors.warning.withValues(alpha: 0.10),
        borderColor: AppColors.warning.withValues(alpha: 0.40),
        foreground: AppColors.warning,
      );
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = _statusColor();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết lịch hẹn'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Header card ─────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                borderRadius: AppRadius.cardRadius,
                color: theme.colorScheme.surface,
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
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
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            accent.withValues(alpha: 0.12),
                            accent.withValues(alpha: 0.04),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.18),
                              borderRadius: AppRadius.radiusSmAll,
                            ),
                            child: Icon(
                              _statusIcon(),
                              color: accent,
                              size: AppIcons.lg,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _booking.gameName,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(
                                      AppIcons.location,
                                      size: AppIcons.sm,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        _booking.cafeName,
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          StatusPill(
                            label: BookingUiHelpers.labelFromStringName(
                                _booking.status.name),
                            variant: BookingUiHelpers.variantFromStringName(
                                _booking.status.name),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        children: [
                          InfoRow(
                            icon: AppIcons.schedule,
                            label: 'Thời gian',
                            value: BookingUiHelpers.formatLongDateTime(
                                _booking.scheduledTime),
                          ),
                          InfoRow(
                            icon: AppIcons.users,
                            label: 'Số người',
                            value:
                                '${_booking.seatCount} ghế • ${_booking.memberIds.length} thành viên',
                          ),
                          InfoRow(
                            icon: AppIcons.money,
                            label: 'Đã cọc',
                            value: BookingUiHelpers.formatVnd(
                                _booking.depositAmount),
                            iconColor: AppColors.primary,
                          ),
                          InfoRow(
                            icon: AppIcons.qrCode,
                            label: 'Mã đơn',
                            value: _booking.id,
                            iconColor: AppColors.secondary,
                            copyable: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ─── Countdown / Elapsed Time Banner ────────────────────
            _buildTimeBanner(theme),

            const SizedBox(height: AppSpacing.md),

            // ─── QR Code Section ────────────────────────────────────
            if (!_isTerminal) ...[
              _buildQrSection(theme, accent),
              const SizedBox(height: AppSpacing.md),
            ],

            // ─── Scan Result ────────────────────────────────────────
            if (_scanResult != null)
              _ScanResultBanner(text: _scanResult!),

            // ─── Action Buttons ─────────────────────────────────────
            if (_canCheckIn) _buildCheckInButton(),
            if (_isInGame) _buildInGameButton(),
            if (_isTerminal) _buildTerminalMessage(theme),

            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildQrSection(ThemeData theme, Color color) {
    final hasQr = _booking.qrPayload.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.cardRadius,
        color: theme.colorScheme.surface,
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: AppElevation.shadowXxs,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SectionHeader(
              icon: Icons.qr_code_2_rounded,
              title: 'Mã QR Check-in',
              subtitle: 'Đưa mã này cho nhân viên quán để bắt đầu phiên chơi',
              accent: color,
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark
                    ? AppColorsDark.surfaceElevated
                    : AppColors.surface,
                borderRadius: AppRadius.radiusMdAll,
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: hasQr
                  ? QrImageView(
                      data: _booking.qrPayload,
                      version: QrVersions.auto,
                      size: 220,
                      backgroundColor: Colors.transparent,
                      errorCorrectionLevel: QrErrorCorrectLevel.M,
                    )
                  : Column(
                      children: [
                        Icon(
                          Icons.qr_code_2_rounded,
                          size: AppIcons.xxl,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Chưa có mã QR cho booking này',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (_booking.nonceUsed)
              _InlineNotice(
                icon: Icons.warning_amber_rounded,
                text: 'QR đã được sử dụng',
                color: AppColors.warning,
              )
            else if (_booking.status.name == 'confirmed')
              _InlineNotice(
                icon: Icons.info_outline_rounded,
                text: 'Đưa mã này cho nhân viên quán để check-in',
                color: AppColors.info,
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
            : const Icon(Icons.qr_code_scanner_rounded),
        label: Text(_isScanning ? 'Đang quét...' : 'Mock: Quét QR (POS)'),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.info,
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
        icon: const Icon(Icons.sports_esports_rounded),
        label: const Text('Vào phiên chơi'),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.success,
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
        icon = Icons.hourglass_top_rounded;
        color = AppColors.warning;
        break;
      case 'cancelledByPlayer':
      case 'cancelledByCafe':
        message = 'Booking này đã bị hủy.';
        icon = Icons.cancel_rounded;
        color = AppColors.textSecondary;
        break;
      case 'expired':
        message = 'Booking đã hết hạn. Vui lòng tạo đơn mới.';
        icon = Icons.timer_off_rounded;
        color = AppColors.error;
        break;
      default:
        message = 'Booking không khả dụng.';
        icon = Icons.info_outline_rounded;
        color = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppRadius.radiusMdAll,
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: AppSpacing.sm),
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

/// Banner chung cho countdown / elapsed time / expired.
class _TimeBanner extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? subtitle;
  final Color backgroundColor;
  final Color borderColor;
  final Color foreground;

  const _TimeBanner({
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle,
    required this.backgroundColor,
    required this.borderColor,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppRadius.radiusMdAll,
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: foreground.withValues(alpha: 0.15),
              borderRadius: AppRadius.radiusSmAll,
            ),
            child: Icon(icon, color: foreground, size: AppIcons.lg),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: foreground.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
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
    final icon = ok ? Icons.check_circle_rounded : Icons.error_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
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

class _InlineNotice extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _InlineNotice({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: AppRadius.radiusXsAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppIcons.sm, color: color),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
