import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:boardverse/core/di/injection.dart';
import 'package:boardverse/core/navigation/lobby_flow_navigator.dart';
import 'package:boardverse/core/theme/theme.dart';
import 'package:boardverse/core/utils/cafe_info_helper.dart';
import 'package:boardverse/core/widgets/top_snack_bar.dart';
import 'package:boardverse/features/matchmaking_discovery/domain/entities/cafe_detail_entity.dart';
import 'package:boardverse/features/matchmaking_discovery/domain/repositories/matchmaking_repository.dart';
import 'package:boardverse/features/reservation/domain/entities/entities.dart';
import 'package:boardverse/features/reservation/domain/repositories/reservation_repository.dart';
import 'package:boardverse/features/reservation/presentation/cubit/reservation_cubit.dart';
import '../../domain/entities/lobby_entity.dart';
import 'package:boardverse/features/reservation/presentation/cubit/reservation_state.dart';
import '../widgets/lobby_page_shimmer.dart';

/// Page hiển thị khi lobby cần cafe duyệt (BR-NEW-11).
///
/// Phase B — bổ sung các tính năng:
/// - Hiển thị cafe name + address (lấy qua `CafeInfoHelper`).
/// - Countdown 24h tới `cafeApprovalDeadline` (cập nhật mỗi giây).
/// - Action "Hủy đặt chỗ" → gọi `ReservationCubit.cancelReservation` → hoàn
///   BVC theo BR-REFUND-02 (BVC v2 — đơn giản hoá còn 2 mốc):
///     + Grace 15 phút (chưa có member join) HOẶC ≥24h trước giờ chơi
///       → hoàn 100%.
///     + <24h trước giờ chơi (ngoài grace) → hoàn 0%, có thể bị trừ Karma.
/// - Auto re-route: poll reservation detail mỗi 15s. Khi cafe duyệt →
///   chuyển sang placeholder page (MainScaffold sẽ pick up join signal để
///   navigate sang `LobbyPage` thật). Khi cafe từ chối → hiển thị dialog
///   lý do + back về MainScaffold. Khi hết hạn → dialog + back về
///   MainScaffold.
///
/// Phase tiếp theo có thể bật SignalR realtime để cập nhật nhanh hơn.
class LobbyPendingCafeApprovalPage extends StatefulWidget {
  final String reservationId;
  final String? cafeId;
  final String? cafeName;
  final DateTime? cafeApprovalDeadline;

  const LobbyPendingCafeApprovalPage({
    super.key,
    required this.reservationId,
    this.cafeId,
    this.cafeName,
    this.cafeApprovalDeadline,
  });

  @override
  State<LobbyPendingCafeApprovalPage> createState() =>
      _LobbyPendingCafeApprovalPageState();
}

class _LobbyPendingCafeApprovalPageState
    extends State<LobbyPendingCafeApprovalPage> {
  Timer? _ticker;
  Timer? _pollTimer;

  /// ReservationCubit scope cho page này — dùng để cancel reservation.
  late final ReservationCubit _reservationCubit;

  /// Reservation gần nhất fetch được (qua poll hoặc init).
  ReservationEntity? _reservation;

  /// Cafe info (Phase B) — fetch một lần lúc mount.
  CafeDetailEntity? _cafe;
  bool _cafeLoading = false;

  /// Đã trigger điều hướng rời page (cafe duyệt / từ chối / hết hạn) hay chưa.
  /// Tránh navigate 2 lần khi poll liên tục.
  bool _navigated = false;

  static const Duration _pollInterval = Duration(seconds: 15);

  @override
  void initState() {
    super.initState();
    _reservationCubit = getIt<ReservationCubit>();

    // Tick mỗi giây để countdown realtime.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });

    // Fetch cafe info (best-effort).
    if (widget.cafeId != null && widget.cafeId!.isNotEmpty) {
      _fetchCafe();
    }

    // Poll reservation detail để nhận cafe approval/reject update.
    _pollNow();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _pollNow());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchCafe() async {
    if (_cafeLoading) return;
    _cafeLoading = true;
    final repo = getIt<MatchmakingRepository>();
    final cafe = await CafeInfoHelper.fetchCafe(
      widget.cafeId!,
      repo: repo,
    );
    if (!mounted) return;
    setState(() {
      _cafe = cafe;
      _cafeLoading = false;
    });
  }

  Future<void> _pollNow() async {
    final repo = getIt<ReservationRepository>();
    final result = await repo.getReservationDetail(widget.reservationId);
    if (!mounted) return;
    result.fold(
      (_) {/* giữ state cũ, poll lần sau */},
      (reservation) {
        if (!mounted) return;
        setState(() => _reservation = reservation);
        _handleStateTransition(reservation);
      },
    );
  }

  /// Xử lý transition: cafe duyệt / từ chối / expired.
  void _handleStateTransition(ReservationEntity reservation) {
    if (_navigated) return;

    // 1. Cafe đã duyệt → lobby đã chuyển sang `open`. Mở LobbyPage.
    final lobbyStatus = reservation.lobbyStatus;
    if (lobbyStatus != null &&
        lobbyStatus != LobbyStatus.pendingCafeApproval &&
        reservation.status != ReservationStatus.cancelledByCafe &&
        reservation.status != ReservationStatus.rejectedByCafe &&
        reservation.lobbyId != null) {
      _navigated = true;
      _openLobbyPage(reservation.lobbyId!);
      return;
    }

    // 2. Cafe từ chối hoặc hết hạn → show dialog + back root.
    final isRejected = reservation.status == ReservationStatus.rejectedByCafe ||
        reservation.status == ReservationStatus.cancelledByCafe ||
        lobbyStatus == LobbyStatus.rejectedByCafe ||
        lobbyStatus == LobbyStatus.expiredByCafe;

    if (isRejected) {
      _navigated = true;
      _showRejectedDialog(reservation);
    }
  }

  void _openLobbyPage(String lobbyId) {
    if (!mounted) return;
    context.showTopSnackBar('Quán đã duyệt — đang mở phòng chờ...');
    // Caller (LobbyHubPage / MainScaffold) sẽ nhận signal rồi navigate
    // sang LobbyPage thật. Ở đây dùng placeholder safe.
    LobbyFlowNavigator.pushAndKeepRootOnly(
      context,
      _PendingApprovalClosedPage(lobbyId: lobbyId),
    );
  }

  Future<void> _showRejectedDialog(ReservationEntity reservation) async {
    if (!mounted) return;
    final reason = reservation.cafeRejectionReason?.trim();
    final isExpired = reservation.status == ReservationStatus.cancelledByCafe ||
        reservation.lobbyStatus == LobbyStatus.expiredByCafe;
    final title = isExpired ? 'Hết hạn duyệt' : 'Quán đã từ chối';
    final body = isExpired
        ? 'Quán không duyệt trong 24h. BVC đã được hoàn 100% về ví.'
        : (reason?.isNotEmpty == true
            ? reason!
            : 'BVC đã được hoàn 100% về ví.');

    final colors = Theme.of(context).colorScheme;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLgAll),
        icon: Icon(
          isExpired ? Icons.timer_off_outlined : AppIcons.cancelBooking,
          size: AppIcons.massive,
          color: colors.error,
        ),
        title: Text(title),
        content: Text(body),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              LobbyFlowNavigator.returnToRoot(context);
            },
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAndCancel() async {
    final reason = await _askCancelReason();
    if (reason == null) return;
    if (!mounted) return;

    _reservationCubit.cancelReservation(
      widget.reservationId,
      reason: reason,
    );
    // BlocListener bọc ở `build` sẽ xử lý state emitted.
  }

  Future<String?> _askCancelReason() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLgAll),
        title: const Text('Hủy đặt chỗ?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'BVC sẽ được hoàn theo chính sách BR-REFUND-02 (BVC v2):',
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text('• Trong grace 15 phút (chưa có member): 100%'),
            const Text('• ≥ 24 giờ trước giờ chơi: 100%'),
            const Text('• < 24 giờ trước giờ chơi (ngoài grace): 0% — '
                'có thể bị trừ Karma.'),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: controller,
              maxLength: 200,
              decoration: const InputDecoration(
                labelText: 'Lý do (tuỳ chọn)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Không'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(
              controller.text.trim().isEmpty ? null : controller.text.trim(),
            ),
            child: const Text('Hủy đặt chỗ'),
          ),
        ],
      ),
    );
    return result;
  }

  void _back() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      LobbyFlowNavigator.returnToRoot(context);
    }
  }

  String _formatCountdown(Duration d) {
    if (d.isNegative) return '00:00:00';
    final hh = d.inHours.toString().padLeft(2, '0');
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$hh:$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    // BR-NEW-11: Ưu tiên dùng `cafeApprovalDeadline` (absolute time) để
    // countdown chính xác. Nếu backend không trả (vd khi poll từ
    // MyReservations API chỉ có remaining* relative fields) → fallback
    // sang `_reservation?.remainingApprovalHours/Minutes` để render
    // countdown đúng BR-NEW-11 yêu cầu hiển thị "Còn lại 23 giờ 45 phút".
    DateTime? deadline = widget.cafeApprovalDeadline;
    Duration remaining;
    if (deadline == null && _reservation != null) {
      final hours = _reservation!.remainingApprovalHours ?? 0;
      final minutes = _reservation!.remainingApprovalMinutes ?? 0;
      if (hours > 0 || minutes > 0) {
        deadline = DateTime.now().add(Duration(hours: hours, minutes: minutes));
      }
    }
    remaining = deadline == null
        ? Duration.zero
        : deadline.difference(DateTime.now());
    final isExpired = remaining.isNegative && deadline != null;

    final cafeName = _cafe?.name ??
        widget.cafeName ??
        _reservation?.cafeName ??
        'Cafe';
    final cafeAddress = _cafe?.address ?? '';

    return BlocProvider<ReservationCubit>.value(
      value: _reservationCubit,
      child: BlocListener<ReservationCubit, ReservationState>(
        listener: _onReservationStateChanged,
        child: _buildScaffold(
          isExpired: isExpired,
          remaining: remaining,
          deadline: deadline,
          cafeName: cafeName,
          cafeAddress: cafeAddress,
        ),
      ),
    );
  }

  Widget _buildScaffold({
    required bool isExpired,
    required Duration remaining,
    required DateTime? deadline,
    required String cafeName,
    required String cafeAddress,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chờ quán duyệt'),
        leading: IconButton(
          tooltip: 'Đóng',
          icon: const Icon(Icons.close),
          onPressed: _back,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Hero banner ───────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      isExpired ? colors.error : AppColors.warning,
                      (isExpired ? colors.error : AppColors.warning)
                          .withAlpha(204),
                    ],
                  ),
                  borderRadius: AppRadius.radiusLgAll,
                  boxShadow: [
                    BoxShadow(
                      color: (isExpired ? colors.error : AppColors.warning)
                          .withAlpha(51),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isExpired
                            ? Icons.timer_off_outlined
                            : Icons.hourglass_top,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      isExpired
                          ? 'Đã quá hạn duyệt'
                          : 'Phòng đang được quán xem xét',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      cafeName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (cafeAddress.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        cafeAddress,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    if (deadline != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.25),
                          borderRadius: AppRadius.radiusMdAll,
                        ),
                        child: Text(
                          isExpired
                              ? 'Hết hạn'
                              : 'Còn lại: ${_formatCountdown(remaining)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 22,
                            letterSpacing: 1.2,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // ── Reservation info ─────────────────────────────────────
              _InfoCard(
                icon: AppIcons.info,
                title: 'Đặt chỗ',
                rows: [
                  if (_reservation != null) ...[
                    _InfoRow(label: 'Mã đặt chỗ', value: _reservation!.id),
                    _InfoRow(
                      label: 'Game',
                      value: _reservation!.gameName,
                    ),
                    _InfoRow(
                      label: 'Cọc',
                      value: '${_reservation!.finalDeposit} BVC',
                    ),
                  ] else ...[
                    _InfoRow(label: 'Mã đặt chỗ', value: widget.reservationId),
                  ],
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

              // ── Action buttons ───────────────────────────────────────
              FilledButton.icon(
                onPressed: isExpired ? null : _confirmAndCancel,
                style: FilledButton.styleFrom(
                  backgroundColor: colors.error,
                  foregroundColor: colors.onError,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.md,
                  ),
                ),
                icon: const Icon(AppIcons.cancelBooking),
                label: const Text('Hủy đặt chỗ'),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: _back,
                icon: const Icon(AppIcons.home),
                label: const Text('Về trang chủ'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.md,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onReservationStateChanged(BuildContext ctx, ReservationState state) {
    if (state is ReservationCancelled) {
      ctx.showTopSnackBar(
        'Đã hủy đặt chỗ. Hoàn ${state.result.refundBvc} BVC'
        ' (${state.result.refundPolicyApplied}).',
        duration: const Duration(seconds: 4),
      );
      // Pop về root sau khi user đọc snackbar.
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) LobbyFlowNavigator.returnToRoot(context);
      });
    } else if (state is ReservationCancelError) {
      ctx.showTopSnackBar(
        'Hủy thất bại: ${state.message}',
        isError: true,
      );
    }
  }
}

/// Placeholder page — mở tạm khi cafe duyệt xong. Caller
/// (LobbyHubPage / MainScaffold) sẽ pick up join signal để navigate sang
/// `LobbyPage` thật. Hiển thị shimmer skeleton trùng với layout LobbyPage.
class _PendingApprovalClosedPage extends StatelessWidget {
  final String lobbyId;
  const _PendingApprovalClosedPage({required this.lobbyId});

  @override
  Widget build(BuildContext context) {
    return const LobbyPageShimmer(
      playerSlots: 4,
      showChatSection: false,
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<_InfoRow> rows;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.radiusLgAll,
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: colors.primary, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...rows,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}