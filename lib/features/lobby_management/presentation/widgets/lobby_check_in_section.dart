import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:boardverse/core/di/injection.dart';
import 'package:boardverse/core/theme/theme.dart';
import 'package:boardverse/core/utils/cafe_info_helper.dart';
import 'package:boardverse/features/lobby_management/domain/entities/lobby_entity.dart';
import 'package:boardverse/features/lobby_management/lobby_routes.dart';
import 'package:boardverse/features/matchmaking_discovery/domain/entities/cafe_detail_entity.dart';
import 'package:boardverse/features/matchmaking_discovery/domain/repositories/matchmaking_repository.dart';
import '../../../reservation/domain/entities/entities.dart' as res;
import '../cubit/member_arrival_cubit.dart';
import 'confirmation_status_banner.dart';
import 'members_arrival_checklist.dart';
import 'pre_checkin_actions.dart';
import 'scheduled_time_countdown.dart';

/// Section hiển thị QR check-in cho thành viên lobby khi đến quán.
///
/// Phase A: QR + mã share code + Copy/Hiện QR.
/// Phase C: thêm "Mở chỉ đường" (Google Maps) + "Gọi quán" (`tel:`), banner
/// "Đang chơi" khi lobby.status == inProgress (kèm countdown tới giờ kết thúc
/// dự kiến). Tất cả hành động external app dùng `CafeInfoHelper` (Phase B
/// đã tạo) để tránh duplicate logic.
///
/// Phase D (mở rộng): ConfirmationStatusBanner + ScheduledTimeCountdown
/// + PreCheckinActions + MembersArrivalChecklist cho host view tổng hợp.
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

  /// UserId của player đang xem section này. Dùng cho self-report arrival.
  final String currentUserId;

  /// Map arrival status của từng player trong lobby (cho host view).
  /// Key = userId, value = arrival status (unknown/enRoute/arrived/checkedIn).
  final Map<String, MemberArrivalStatus>? arrivalByUserId;

  /// Tổng số players hiện tại trong lobby (cho host checklist).
  final List<LobbyPlayer>? lobbyPlayers;

  /// Callback khi user bấm "Vào phiên chơi" sau khi checked-in.
  /// Dùng để navigate sang InGameSessionPage.
  final VoidCallback? onEnterSession;

  const LobbyCheckInSection({
    super.key,
    required this.reservation,
    required this.isHost,
    this.onExpand,
    this.isExpanded = false,
    this.lobbyStatus = res.LobbyStatus.viable,
    this.playStartedAt,
    required this.currentUserId,
    this.arrivalByUserId,
    this.lobbyPlayers,
    this.onEnterSession,
  });

  /// Mở full-screen QR cho một reservation — dùng cho [LobbyPage] mở
  /// QR từ QR mini badge ở hero header (khi lobby ready + đã confirm).
  ///
  /// Khác với internal `_showQrFullScreen(String code)` — public API
  /// nhận vào `ReservationEntity` để lấy cả `reservation.id` (UUID, dùng
  /// cho POS scanner) + `lobbyShareCode` (8-char hiển thị dưới QR).
  ///
  /// Lưu ý: Phải gọi qua `LobbyCheckInSection.showQrFullScreen(...)` thay
  /// vì gọi trực tiếp `_showQrFullScreen` của instance vì method đó
  /// là private + chỉ là 1 dòng. Helper này chỉ làm thin wrapper.
  static Future<void> showQrFullScreenPublic({
    required BuildContext context,
    required res.ReservationEntity reservation,
  }) async {
    final code = reservation.lobbyShareCode ?? reservation.id;
    await Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (_, _, _) => _QrFullScreen(code: code),
      ),
    );
  }

  @override
  State<LobbyCheckInSection> createState() => _LobbyCheckInSectionState();
}

class _LobbyCheckInSectionState extends State<LobbyCheckInSection> {
  CafeDetailEntity? _cafe;
  bool _cafeLoading = false;
  bool _directionsLaunching = false;
  bool _callLaunching = false;

  late final MemberArrivalCubit _arrivalCubit;

  @override
  void initState() {
    super.initState();
    _fetchCafe();
    _arrivalCubit = MemberArrivalCubit(
      reservationId: widget.reservation.id,
      userId: widget.currentUserId,
    );
  }

  @override
  void dispose() {
    _arrivalCubit.close();
    super.dispose();
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

  /// Navigate sang [PlayerQrCheckInPage] — chiều 2 check-in BR §21A.7.
  ///
  /// Cho phép player self check-in bằng cách nhập/paste token 16-char
  /// hiển thị trên POS. Sau khi thành công → tự động navigate sang
  /// `InGameSessionPage` (vì PlayerQrCheckInPage làm navigate thay).
  void _openPlayerQrCheckIn() {
    Navigator.of(context, rootNavigator: true).pushNamed(
      LobbyRoutes.playerQrCheckIn,
      arguments: PlayerQrCheckInPageArgs(
        reservationId: widget.reservation.id,
        cafeName: widget.reservation.cafeName,
        gameName: widget.reservation.gameName,
        tableNumber: 1, // tableNumber sẽ được backend/SignalR cập nhật realtime
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reservation = widget.reservation;
    // Lưu ý về QR data encoding:
//
// QR chứa `reservation.id` (UUID 36-char) — POS scanner sẽ đọc ra UUID
// này và dùng làm path param cho endpoint BR §21A.7:
//   POST /api/v1/reservations/{reservationId}/check-in
//
// Dưới QR hiển thị `lobbyShareCode` (8-char ReservationCode, vd
// "ABC234XY") — staff nhập thủ công vào body field `reservationCode`
// của DTO `ReservationCheckInRequestDto` (cùng với cafeId/activeSessionId/
// idempotencyKey mà POS UI tự sin).
//
// Endpoint POS canonical khác (`/api/cafes/{cafeId}/pos/check-in`) chỉ
// cần `code: "ABC234XY"` là đủ — staff có thể gõ tay nếc POS scanner
// không tự fill body từ QR.
//
// QR UUID nằm trong QR code (machine-readable); ReservationCode 8-char
// hiển thị bên dưới để staff dễ đọc khi cần nhập tay.
final code = reservation.lobbyShareCode ?? reservation.id;

    final isInProgress = widget.lobbyStatus == res.LobbyStatus.inProgress;

    return BlocProvider<MemberArrivalCubit>.value(
      value: _arrivalCubit,
      child: Container(
        margin: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          0,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isInProgress
                ? AppColors.primary
                : AppColors.success,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.4),
              blurRadius: 0,
              offset: const Offset(4, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // "Đang chơi" banner — Phase C
            if (isInProgress)
              _InProgressBanner(playStartedAt: widget.playStartedAt),

            // Status banner (Phase D) — dựa trên reservation + lobby status.
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                0,
              ),
              child: ConfirmationStatusBanner(
                reservationStatus: reservation.status,
                lobbyStatus: widget.lobbyStatus,
                scheduledTime: reservation.scheduledTime,
                currentPlayers: reservation.currentPlayers,
                minPlayers: reservation.minPlayers,
                maxPlayers: reservation.maxPlayers,
                playersNeededToConfirm:
                    reservation.minPlayers - reservation.currentPlayers,
              ),
            ),

            // Countdown tới scheduledTime (Phase D).
            if (reservation.status.isActive)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  0,
                ),
                child: ScheduledTimeCountdown(
                  scheduledTime: reservation.scheduledTime,
                  title: reservation.status == res.ReservationStatus.checkedIn
                      ? 'Đã chơi được'
                      : 'Đến quán trong',
                  subtitle: reservation.cafeName,
                  accentColor: AppColors.primary,
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark
                                ? AppColors.borderDark
                                : AppColors.border,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          AppIcons.location,
                          size: 20,
                          color: AppColors.white,
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
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Nhân viên quán sẽ quét QR hoặc nhập mã để xác nhận bạn đã đến.',
                              style: TextStyle(
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondary,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.onExpand != null)
                        Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.surfaceElevatedDark
                                : AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.borderDark
                                  : AppColors.border,
                              width: 2,
                            ),
                          ),
                          child: IconButton(
                            tooltip: widget.isExpanded
                                ? 'Thu nhỏ'
                                : 'Phóng to',
                            onPressed: widget.onExpand,
                            icon: Icon(
                              widget.isExpanded
                                  ? Icons.fullscreen_exit
                                  : Icons.fullscreen,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Pre-checkin actions row (Phase D).
                  PreCheckinActions(
                    onEnRoute: () => _arrivalCubit.markEnRoute(),
                    onArrived: () => _arrivalCubit.markArrived(),
                    onDirections: _openDirections,
                    onCallCafe: _callCafe,
                    shareCode: code,
                    cafePhone: _cafe?.phoneNumber,
                    cafeLatitude: _cafe?.latitude,
                    cafeLongitude: _cafe?.longitude,
                    // Host có thể không cần "Đang trên đường"
                    showEnRoute: !widget.isHost,
                    showArrived: !widget.isHost,
                    showAlarm: true,
                  ),

                  // Self-report status pill.
                  BlocBuilder<MemberArrivalCubit, MemberArrivalState>(
                    builder: (context, state) {
                      if (state is MemberArrivalEnRoute) {
                        return Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xs),
                          child: _ArrivalStatusChip(
                            icon: Icons.directions_car_rounded,
                            label: 'Đã báo đang trên đường',
                            color: AppColors.warning,
                          ),
                        );
                      }
                      if (state is MemberArrivalArrived) {
                        return Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xs),
                          child: _ArrivalStatusChip(
                            icon: Icons.location_on_rounded,
                            label: 'Đã báo đang ở quán',
                            color: AppColors.info,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Row 1: Nút "Đã tới quán" (action chính khi player ở quán
                  // và muốn staff biết đã đến — BR §21A.7 chiều 2 hỗ trợ).
                  // Spans full-width vì đây là CTA chính của section.
                  _ArrivedAtCafeButton(
                    onPressed: () =>
                        _arrivalCubit.markArrived(),
                    visible: !widget.isHost,
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // Row 2: QR + code
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.border,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.black.withValues(alpha: 0.4),
                            blurRadius: 0,
                            offset: const Offset(4, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          QrImageView(
                            data: reservation.id,
                            version: QrVersions.auto,
                            size: widget.isExpanded ? 240 : 160,
                            backgroundColor: AppColors.white,
                            errorCorrectionLevel: QrErrorCorrectLevel.M,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Mã đặt chỗ',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            code,
                            style: const TextStyle(
                              color: AppColors.black,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Action row: Sao chép mã + Hiện QR
                  Row(
                    children: [
                      Expanded(
                        child: _NeoOutlineButton(
                          label: 'Sao chép mã',
                          icon: AppIcons.copy,
                          onPressed: () => _copyCode(context),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _NeoFilledButton(
                          label: 'Hiện QR',
                          icon: AppIcons.qrScan,
                          color: AppColors.success,
                          onPressed: () => _showQrFullScreen(context, code),
                        ),
                      ),
                    ],
                  ),

                  // Nút "Quét QR từ POS" — chiều 2 check-in BR §21A.7.
                  // Hiển thị khi reservation còn ở trạng thái confirmed (player
                  // chưa được staff check-in). Sau khi checkedIn, ẩn đi để
                  // tránh duplicate / token đã consumed.
                  if (reservation.status == res.ReservationStatus.confirmed)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: _ScanPosQrButton(
                        onPressed: _openPlayerQrCheckIn,
                      ),
                    ),

                  // Nút "Vào phiên chơi" — chỉ hiện khi staff đã scan/check-in.
                  if (reservation.status == res.ReservationStatus.checkedIn)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: _EnterSessionButton(onPressed: widget.onEnterSession),
                    ),
                ],
              ),
            ),

            // Members checklist cho host (Phase D)
            if (widget.isHost &&
                widget.lobbyPlayers != null &&
                widget.lobbyPlayers!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                child: MembersArrivalChecklist(
                  players: widget.lobbyPlayers!,
                  arrivalByUserId:
                      widget.arrivalByUserId ?? const <String, MemberArrivalStatus>{},
                  isHostView: true,
                ),
              ),
          ],
        ),
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
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppColors.primary,
            AppColors.primaryLight,
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const Expanded(
            child: Text(
              'Đang chơi',
              style: TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w900,
                fontSize: 15,
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
                color: AppColors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.white.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    color: AppColors.white,
                    size: 14,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    _elapsed(),
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w900,
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
/// Đã chuyển sang dùng `PreCheckinActions` (Phase D) — giữ xóa.
/// [_ComeToCafeRow]: removed in Phase D — replaced by PreCheckinActions.

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

/// Chip nhỏ hiển thị self-report arrival state (vd: "Đã báo đang trên đường").
class _ArrivalStatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _ArrivalStatusChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.black,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.3),
            blurRadius: 0,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w900,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

/// Neo-brutalism filled button (used for primary actions).
class _NeoFilledButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  const _NeoFilledButton({
    required this.label,
    required this.icon,
    required this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm,
            horizontal: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.border,
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.4),
                blurRadius: 0,
                offset: const Offset(3, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: AppColors.white),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Neo-brutalism outline button (used for secondary actions).
class _NeoOutlineButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  const _NeoOutlineButton({
    required this.label,
    required this.icon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm,
            horizontal: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.border,
              width: 2.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: TextStyle(
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Nút "Đã tới quán" — player self-report đã đến quán (BR §21A.7 khuyến
/// nghị self-report trước khi staff scan/check-in). Hidden cho host vì host
/// không cần tự báo (staff đã có view checklist riêng từ
/// `MembersArrivalChecklist`). Drives [MemberArrivalCubit.markArrived].
class _ArrivedAtCafeButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool visible;

  const _ArrivedAtCafeButton({
    required this.onPressed,
    this.visible = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: BlocBuilder<MemberArrivalCubit, MemberArrivalState>(
        builder: (context, state) {
          final alreadyReported =
              state is MemberArrivalArrived || state is MemberArrivalEnRoute;
          return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: alreadyReported ? null : onPressed,
            child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.md,
                horizontal: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: alreadyReported
                    ? (isDark
                        ? AppColors.surfaceDark
                        : AppColors.surfaceVariant)
                    : AppColors.success,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? AppColors.borderDark
                      : AppColors.border,
                  width: 2.5,
                ),
                boxShadow: alreadyReported
                    ? null
                    : [
                        BoxShadow(
                          color: AppColors.black.withValues(alpha: 0.4),
                          blurRadius: 0,
                          offset: const Offset(3, 3),
                        ),
                      ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: alreadyReported
                          ? AppColors.textTertiary
                          : AppColors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      alreadyReported
                          ? Icons.check_circle_rounded
                          : Icons.location_on_rounded,
                      color: AppColors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    alreadyReported
                        ? 'Đã báo tới quán'
                        : 'Tôi đã tới quán',
                    style: TextStyle(
                      color: alreadyReported
                          ? (isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary)
                          : AppColors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  if (!alreadyReported) ...[
                    const SizedBox(width: AppSpacing.sm),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: AppColors.white,
                      size: 18,
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Nút "Quét QR từ POS" — neo-brutalism filled button, chiều 2 check-in
/// BR §21A.7. Mở `PlayerQrCheckInPage` để player paste token 16-char
/// hiển thị trên POS.
class _ScanPosQrButton extends StatelessWidget {
  final VoidCallback? onPressed;
  const _ScanPosQrButton({this.onPressed});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.secondary, AppColors.info],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.border,
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.4),
                blurRadius: 0,
                offset: const Offset(3, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.qr_code_scanner_rounded,
                  color: AppColors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Flexible(
                child: Text(
                  'Quét QR từ POS',
                  style: TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    letterSpacing: 0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Icon(
                Icons.arrow_forward_rounded,
                color: AppColors.white,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Nút "Vào phiên chơi" — neo-brutalism filled button, hiện sau khi checked-in.
class _EnterSessionButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const _EnterSessionButton({this.onPressed});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.primaryDark,
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.border,
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 0,
                offset: const Offset(3, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.sports_esports_rounded,
                  color: AppColors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Text(
                'Vào phiên chơi',
                style: TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Icon(
                Icons.arrow_forward_rounded,
                color: AppColors.white,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}