import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:boardverse_mobile/core/di/injection.dart';
import 'package:boardverse_mobile/core/theme/theme.dart';
import 'package:boardverse_mobile/core/utils/cafe_info_helper.dart';
import 'package:boardverse_mobile/features/matchmaking_discovery/domain/entities/cafe_detail_entity.dart';
import 'package:boardverse_mobile/features/matchmaking_discovery/domain/repositories/matchmaking_repository.dart';
import '../../../reservation/domain/entities/entities.dart' as res;

/// Section hiển thị QR check-in cho thành viên lobby khi đến quán.
///
/// Phase A: QR + mã share code + Copy/Hiện QR.
/// Phase C: thêm "Mở chỉ đường" (Google Maps) + "Gọi quán" (`tel:`), banner
/// "Đang chơi" khi lobby.status == inProgress (kèm countdown tới giờ kết thúc
/// dự kiến). Tất cả hành động external app dùng `CafeInfoHelper` (Phase B
/// đã tạo) để tránh duplicate logic.
class LobbyCheckInSection extends StatefulWidget {
  final res.ReservationEntity reservation;

  /// Có phải host của reservation không (host thấy QR + có thể mở rộng
  /// thành check-in cho cả nhóm; member thường cũng thấy QR để xuất trình).
  final bool isHost;

  /// Callback khi user bấm "Mở rộng QR / Thu nhỏ" — UI sẽ toggle size.
  final VoidCallback? onExpand;

  /// Có đang ở trạng thái mở rộng (full-screen QR) hay không.
  final bool isExpanded;

  /// Lobby status hiện tại — dùng để quyết định banner "Đang chơi".
  final res.LobbyStatus lobbyStatus;

  /// Thời điểm bắt đầu chơi thực tế (nếu đã inProgress). Dùng để hiển thị
  /// "đã chơi được X phút".
  final DateTime? playStartedAt;

  const LobbyCheckInSection({
    super.key,
    required this.reservation,
    required this.isHost,
    this.onExpand,
    this.isExpanded = false,
    this.lobbyStatus = res.LobbyStatus.viable,
    this.playStartedAt,
  });

  @override
  State<LobbyCheckInSection> createState() => _LobbyCheckInSectionState();
}

class _LobbyCheckInSectionState extends State<LobbyCheckInSection> {
  CafeDetailEntity? _cafe;
  bool _cafeLoading = false;
  bool _directionsLaunching = false;
  bool _callLaunching = false;

  @override
  void initState() {
    super.initState();
    _fetchCafe();
  }

  Future<void> _fetchCafe() async {
    if (_cafeLoading || widget.reservation.cafeId.isEmpty) return;
    _cafeLoading = true;
    final repo = getIt<MatchmakingRepository>();
    final cafe = await CafeInfoHelper.fetchCafe(
      widget.reservation.cafeId,
      repo: repo,
    );
    if (!mounted) return;
    setState(() {
      _cafe = cafe;
      _cafeLoading = false;
    });
  }

  void _copyCode(BuildContext context) {
    final code = widget.reservation.lobbyShareCode ?? widget.reservation.id;
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã sao chép mã: $code'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _openDirections() async {
    if (_directionsLaunching) return;
    if (_cafe == null) {
      _showError('Đang tải thông tin quán...');
      return;
    }
    setState(() => _directionsLaunching = true);
    final ok = await CafeInfoHelper.openDirections(_cafe!);
    if (!mounted) return;
    setState(() => _directionsLaunching = false);
    if (!ok) {
      _showError('Không thể mở Google Maps trên thiết bị này.');
    }
  }

  Future<void> _callCafe() async {
    if (_callLaunching) return;
    if (_cafe == null) {
      _showError('Đang tải thông tin quán...');
      return;
    }
    final phone = _cafe!.phoneNumber ?? '';
    if (phone.isEmpty) {
      _showError('Quán chưa cập nhật số điện thoại.');
      return;
    }
    setState(() => _callLaunching = true);
    final ok = await CafeInfoHelper.callCafe(phone);
    if (!mounted) return;
    setState(() => _callLaunching = false);
    if (!ok) {
      _showError('Không thể mở trình gọi điện trên thiết bị này.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final reservation = widget.reservation;
    final code = reservation.lobbyShareCode ?? reservation.id;

    final isInProgress = widget.lobbyStatus == res.LobbyStatus.inProgress;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        0,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.radiusLgAll,
        border: Border.all(
          color: isInProgress
              ? AppColors.primary.withValues(alpha: 0.50)
              : AppColors.success.withValues(alpha: 0.40),
        ),
        boxShadow: [
          BoxShadow(
            color: (isInProgress ? AppColors.primary : AppColors.success)
                .withValues(alpha: 0.10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // "Đang chơi" banner — Phase C
          if (isInProgress)
            _InProgressBanner(playStartedAt: widget.playStartedAt),

          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.15),
                        borderRadius: AppRadius.radiusMdAll,
                      ),
                      child: Icon(
                        AppIcons.location,
                        size: 18,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.isHost
                                ? 'Bạn có thể đến quán để check-in'
                                : 'Đưa mã này cho nhân viên quán',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Nhân viên quán sẽ quét QR hoặc nhập mã để xác nhận bạn đã đến.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.onExpand != null)
                      IconButton(
                        tooltip: widget.isExpanded ? 'Thu nhỏ' : 'Phóng to',
                        onPressed: widget.onExpand,
                        icon: Icon(
                          widget.isExpanded
                              ? Icons.fullscreen_exit
                              : Icons.fullscreen,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: AppSpacing.md),

                // "Đến quán" row — Phase C
                _ComeToCafeRow(
                  cafe: _cafe,
                  loading: _cafeLoading,
                  onDirections: _openDirections,
                  onCall: _callCafe,
                  directionsLoading: _directionsLaunching,
                  callLoading: _callLaunching,
                ),

                const SizedBox(height: AppSpacing.md),

                // QR + code
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppRadius.radiusMdAll,
                      border: Border.all(color: colors.outlineVariant),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        QrImageView(
                          data: reservation.id,
                          version: QrVersions.auto,
                          size: widget.isExpanded ? 240 : 160,
                          backgroundColor: Colors.white,
                          errorCorrectionLevel: QrErrorCorrectLevel.M,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Mã đặt chỗ',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colors.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          code,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // Action row
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _copyCode(context),
                        icon: Icon(AppIcons.copy, size: 16),
                        label: const Text('Sao chép mã'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.sm,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.radiusMdAll,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _showQrFullScreen(context, code),
                        icon: Icon(AppIcons.qrScan, size: 16),
                        label: const Text('Hiện QR'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.sm,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.radiusMdAll,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showQrFullScreen(BuildContext context, String code) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (_, _, _) => _QrFullScreen(code: code),
      ),
    );
  }
}

/// Banner "Đang chơi" — Phase C.
/// Hiển thị khi lobby.status == inProgress.
/// Nếu có `playStartedAt`, hiển thị thời gian đã chơi (HH:MM:SS) realtime.
class _InProgressBanner extends StatefulWidget {
  final DateTime? playStartedAt;
  const _InProgressBanner({required this.playStartedAt});

  @override
  State<_InProgressBanner> createState() => _InProgressBannerState();
}

class _InProgressBannerState extends State<_InProgressBanner> {
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

  String _elapsed() {
    final started = widget.playStartedAt;
    if (started == null) return '--:--';
    final d = DateTime.now().difference(started);
    if (d.isNegative) return '00:00';
    final hh = d.inHours.toString().padLeft(2, '0');
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return hh == '00' ? '$mm:$ss' : '$hh:$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppRadius.radiusLg),
          topRight: Radius.circular(AppRadius.radiusLg),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Đang chơi',
              style: theme.textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (widget.playStartedAt != null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.25),
                borderRadius: AppRadius.radiusMdAll,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    color: Colors.white,
                    size: 14,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    _elapsed(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Row với 2 button "Mở chỉ đường" + "Gọi quán" — Phase C.
class _ComeToCafeRow extends StatelessWidget {
  final CafeDetailEntity? cafe;
  final bool loading;
  final VoidCallback onDirections;
  final VoidCallback onCall;
  final bool directionsLoading;
  final bool callLoading;

  const _ComeToCafeRow({
    required this.cafe,
    required this.loading,
    required this.onDirections,
    required this.onCall,
    required this.directionsLoading,
    required this.callLoading,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final canDirections = !loading && cafe != null;
    final canCall = !loading &&
        cafe != null &&
        (cafe?.phoneNumber?.isNotEmpty ?? false);

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: canDirections ? onDirections : null,
            icon: directionsLoading
                ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: colors.primary,
                    ),
                  )
                : Icon(Icons.directions_outlined, size: 16),
            label: const Text('Mở chỉ đường'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.radiusMdAll,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: FilledButton.icon(
            onPressed: canCall ? onCall : null,
            icon: callLoading
                ? SizedBox(
                    width: 14,
                    height: 14,
                    child: const CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: Colors.white,
                    ),
                  )
                : Icon(Icons.phone_outlined, size: 16),
            label: const Text('Gọi quán'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.radiusMdAll,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _QrFullScreen extends StatelessWidget {
  final String code;
  const _QrFullScreen({required this.code});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            color: Colors.transparent,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppRadius.radiusLgAll,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      QrImageView(
                        data: code,
                        version: QrVersions.auto,
                        size: 280,
                        backgroundColor: Colors.white,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        code,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  'Chạm vào màn hình để đóng',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}