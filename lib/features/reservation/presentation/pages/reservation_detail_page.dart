import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/theme.dart';
import '../../../lobby_management/domain/repositories/lobby_repository.dart';
import '../../../lobby_management/presentation/cubit/lobby_cubit.dart';
import '../../../lobby_management/presentation/pages/lobby_page.dart';
import '../../../lobby_management/presentation/pages/lobby_pending_cafe_approval_page.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/reservation_repository.dart';
import '../cubit/reservation_detail_cubit.dart';
import '../cubit/reservation_detail_state.dart';
import 'reservation_cancel_sheet.dart';

/// Trang chi tiết một reservation — hiển thị đầy đủ thông tin từ API
/// và mã QR cho POS check-in.
///
/// Gọi `GET /api/v1/reservations/{id}` để lấy dữ liệu mới nhất từ server.
class ReservationDetailPage extends StatelessWidget {
  final ReservationEntity reservation;

  const ReservationDetailPage({super.key, required this.reservation});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ReservationDetailCubit>(
      create: (_) => ReservationDetailCubit(
        repository: sl<ReservationRepository>(),
        lobbyRepository: sl<LobbyRepository>(),
      )..fetchReservation(
          reservationId: reservation.id,
          snapshot: reservation,
        ),
      child: _ReservationDetailView(reservation: reservation),
    );
  }
}

class _ReservationDetailView extends StatelessWidget {
  final ReservationEntity reservation;
  const _ReservationDetailView({required this.reservation});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReservationDetailCubit, ReservationDetailState>(
      builder: (context, state) {
        ReservationEntity r;
        if (state is ReservationDetailLoaded) {
          r = state.reservation;
        } else if (state is ReservationDetailLoading && state.reservation != null) {
          r = state.reservation!;
        } else {
          r = reservation;
        }

        final colors = Theme.of(context).colorScheme;
        final isLoading = state is ReservationDetailLoading;

        return Scaffold(
          backgroundColor: colors.surface,
          appBar: AppBar(
            title: const Text('Chi tiết đặt chỗ'),
            backgroundColor: colors.surface,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            actions: [
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.only(right: AppSpacing.md),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else if (state is ReservationDetailLoaded && state.isFromCache)
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Cập nhật',
                  onPressed: () =>
                      context.read<ReservationDetailCubit>().refresh(reservation.id),
                ),
            ],
          ),
          body: Stack(
            children: [
              ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  // ── Header: Game + Status ───────────────────────────────
                  _HeaderCard(reservation: r),
                  const SizedBox(height: AppSpacing.md),

                  // ── QR Code (hiển thị khi có reservationCode) ───────────
                  if (r.lobbyShareCode != null && r.lobbyShareCode!.isNotEmpty) ...[
                    _QrCodeCard(code: r.lobbyShareCode!),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // ── Thông tin thời gian ─────────────────────────────────
                  _TimeCard(reservation: r),
                  const SizedBox(height: AppSpacing.md),

                  // ── Địa điểm ──────────────────────────────────────────
                  _LocationCard(reservation: r),
                  const SizedBox(height: AppSpacing.md),

                  // ── Người chơi ───────────────────────────────────────
                  _PlayersCard(reservation: r),
                  const SizedBox(height: AppSpacing.md),

                  // ── Tiền cọc ─────────────────────────────────────────
                  _DepositCard(reservation: r),
                  const SizedBox(height: AppSpacing.md),

                  // ── Thông tin bổ sung (nếu có) ────────────────────────
                  _AdditionalInfoCard(reservation: r),
                  const SizedBox(height: AppSpacing.md),

                  // ── Actions ───────────────────────────────────────────
                  _ActionButtons(reservation: r),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),

              // Offline warning
              if (state is ReservationDetailLoaded && state.isFromCache)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: AppColors.warning.withValues(alpha: 0.95),
                    padding: EdgeInsets.only(
                      left: AppSpacing.md,
                      right: AppSpacing.md,
                      top: AppSpacing.sm + MediaQuery.of(context).padding.top,
                      bottom: AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.cloud_off, color: Colors.white, size: 16),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            state.errorMessage ?? 'Hiển thị dữ liệu cũ',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Header Card ─────────────────────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  final ReservationEntity reservation;
  const _HeaderCard({required this.reservation});

  @override
  Widget build(BuildContext context) {
    final r = reservation;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final statusColor = _getStatusColor(r.status);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            statusColor.withValues(alpha: 0.15),
            statusColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: AppRadius.radiusLgAll,
        border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Game icon
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: AppRadius.radiusMdAll,
                  ),
                  child: Icon(Icons.casino, color: colors.primary, size: 32),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.gameName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      _StatusBadge(status: r.status, color: statusColor),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(ReservationStatus status) {
    if (status.isTerminal) return AppColors.error;
    if (status.isActive) return AppColors.success;
    return AppColors.warning;
  }
}

class _StatusBadge extends StatelessWidget {
  final ReservationStatus status;
  final Color color;
  const _StatusBadge({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: AppRadius.radiusFullAll,
        border: Border.all(color: color, width: 1.5),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

// ─── QR Code Card ────────────────────────────────────────────────────────

class _QrCodeCard extends StatelessWidget {
  final String code;
  const _QrCodeCard({required this.code});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.radiusLgAll,
        border: Border.all(color: colors.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // QR Code lớn
          Container(
            margin: const EdgeInsets.all(AppSpacing.lg),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadius.radiusMdAll,
              border: Border.all(color: colors.outlineVariant),
            ),
            child: QrImageView(
              data: code,
              version: QrVersions.auto,
              size: 200,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Colors.black,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Colors.black,
              ),
            ),
          ),

          // Code hiển thị
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.primaryContainer.withValues(alpha: 0.3),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Mã check-in',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      code,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                        color: colors.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    IconButton(
                      icon: Icon(Icons.copy, color: colors.primary, size: 20),
                      tooltip: 'Sao chép mã',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: code));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Đã sao chép mã: $code'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Quét mã QR tại quán để check-in',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
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

// ─── Time Card ───────────────────────────────────────────────────────────

class _TimeCard extends StatelessWidget {
  final ReservationEntity reservation;
  const _TimeCard({required this.reservation});

  @override
  Widget build(BuildContext context) {
    final r = reservation;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final dateFormat = DateFormat('EEEE, dd/MM/yyyy', 'vi');
    final timeFormat = DateFormat('HH:mm');

    final playDateStr = dateFormat.format(r.playDate);
    final startTimeStr = timeFormat.format(r.scheduledTime.toLocal());
    final endTimeStr = r.scheduledEndTime != null
        ? timeFormat.format(r.scheduledEndTime!.toLocal())
        : timeFormat.format(
            r.scheduledTime.toLocal().add(const Duration(hours: 3)));
    final deadlineStr = r.recruitmentDeadline != null
        ? timeFormat.format(r.recruitmentDeadline!.toLocal())
        : 'N/A';

    return _SectionCard(
      title: 'Thời gian',
      icon: Icons.schedule,
      children: [
        _InfoRow(label: 'Ngày', value: playDateStr),
        _InfoRow(
          label: 'Khung giờ',
          value: r.timeSlot.displayName,
          trailing: Text(
            '${r.timeSlot.startTime} - ${r.timeSlot.endTime}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
        _InfoRow(
          label: 'Giờ bắt đầu',
          value: r.preferredStartTime ?? startTimeStr,
          valueColor: colors.primary,
        ),
        _InfoRow(
          label: 'Giờ kết thúc',
          value: endTimeStr,
        ),
        _InfoRow(
          label: 'Hạn tuyển người',
          value: deadlineStr,
          valueColor: r.isWithinRecruitmentWindow ? null : AppColors.error,
          trailing: Text(
            _timeUntilDeadline(r),
            style: theme.textTheme.bodySmall?.copyWith(
              color: r.isWithinRecruitmentWindow
                  ? AppColors.success
                  : AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  String _timeUntilDeadline(ReservationEntity r) {
    final diff = r.timeToDeadline;
    if (diff.isNegative) return 'Đã hết hạn';
    if (diff.inHours > 0) return 'còn ${diff.inHours}h';
    return 'còn ${diff.inMinutes}p';
  }
}

// ─── Location Card ───────────────────────────────────────────────────────

class _LocationCard extends StatelessWidget {
  final ReservationEntity reservation;
  const _LocationCard({required this.reservation});

  @override
  Widget build(BuildContext context) {
    final r = reservation;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return _SectionCard(
      title: 'Địa điểm',
      icon: Icons.store,
      children: [
        _InfoRow(
          label: 'Quán',
          value: r.cafeName,
          valueStyle: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        if (r.cafeAddress != null && r.cafeAddress!.isNotEmpty)
          _InfoRow(
            label: 'Địa chỉ',
            value: r.cafeAddress!,
            valueStyle: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        if (r.tableNumber != null && r.tableNumber!.isNotEmpty)
          _InfoRow(
            label: 'Bàn',
            value: r.tableNumber!,
            valueColor: colors.primary,
          ),
      ],
    );
  }
}

// ─── Players Card ────────────────────────────────────────────────────────

class _PlayersCard extends StatelessWidget {
  final ReservationEntity reservation;
  const _PlayersCard({required this.reservation});

  @override
  Widget build(BuildContext context) {
    final r = reservation;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final progress = r.maxPlayers > 0 ? r.currentPlayers / r.maxPlayers : 0.0;

    return _SectionCard(
      title: 'Người chơi',
      icon: Icons.group,
      children: [
        // Progress
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${r.currentPlayers} / ${r.maxPlayers} người',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: r.hasReachedMinPlayers
                              ? AppColors.success.withValues(alpha: 0.15)
                              : AppColors.warning.withValues(alpha: 0.15),
                          borderRadius: AppRadius.radiusFullAll,
                        ),
                        child: Text(
                          r.hasReachedMinPlayers ? 'Đủ người' : 'Cần thêm',
                          style: TextStyle(
                            color: r.hasReachedMinPlayers
                                ? AppColors.success
                                : AppColors.warning,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ClipRRect(
                    borderRadius: AppRadius.radiusFullAll,
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: colors.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation(
                        r.hasReachedMinPlayers
                            ? AppColors.success
                            : AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _InfoRow(
          label: 'Tối thiểu',
          value: '${r.minPlayers} người',
        ),
        _InfoRow(
          label: 'Còn trống',
          value: '${r.remainingSlots} ghế',
          valueColor: r.remainingSlots > 0 ? AppColors.info : AppColors.warning,
        ),
        if (r.isHost == true)
          _InfoRow(
            label: 'Vai trò',
            value: 'Bạn là chủ phòng',
            valueColor: AppColors.success,
          ),
      ],
    );
  }
}

// ─── Deposit Card ────────────────────────────────────────────────────────

class _DepositCard extends StatelessWidget {
  final ReservationEntity reservation;
  const _DepositCard({required this.reservation});

  @override
  Widget build(BuildContext context) {
    final r = reservation;
    final theme = Theme.of(context);

    return _SectionCard(
      title: 'Tiền cọc',
      icon: Icons.account_balance_wallet,
      children: [
        // Main deposit display
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.1),
            borderRadius: AppRadius.radiusMdAll,
            border:
                Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.toll, color: AppColors.accent, size: 32),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${r.finalDeposit}',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'BVC',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.sm),
        if (r.riskMultiplier > 1.0) ...[
          _InfoRow(
            label: 'Hệ số rủi ro',
            value: '×${r.riskMultiplier.toStringAsFixed(2)}',
            valueColor: AppColors.warning,
          ),
        ],
        if (r.refundPolicyApplied != null &&
            r.refundPolicyApplied!.isNotEmpty) ...[
          _InfoRow(
            label: 'Chính sách hoàn',
            value: r.refundPolicyApplied!.refundPolicyLabel,
          ),
        ],
        _InfoRow(
          label: 'Loại phòng',
          value: r.isPrivate ? 'Riêng tư' : 'Công khai',
        ),
        if (r.requiresCafeApproval) ...[
          _InfoRow(
            label: 'Cần quán duyệt',
            value: 'Có',
            valueColor: AppColors.warning,
          ),
        ],
      ],
    );
  }
}

// ─── Additional Info Card ────────────────────────────────────────────────

class _AdditionalInfoCard extends StatelessWidget {
  final ReservationEntity reservation;
  const _AdditionalInfoCard({required this.reservation});

  @override
  Widget build(BuildContext context) {
    final r = reservation;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final items = <_InfoRow>[];

    // Host info
    if (r.hostDisplayName != null && r.hostDisplayName!.isNotEmpty) {
      items.add(_InfoRow(
        label: 'Host',
        value: r.hostDisplayName!,
      ));
    }

    // Lobby info
    if (r.lobbyId != null) {
      items.add(_InfoRow(
        label: 'Lobby ID',
        value: '${r.lobbyId!.substring(0, 8)}...',
        monospace: true,
      ));
    }

    // Lobby status
    if (r.lobbyStatus != null) {
      final lobbyColor = _getLobbyStatusColor(r.lobbyStatus!, colors);
      items.add(_InfoRow(
        label: 'Trạng thái lobby',
        value: r.lobbyStatus!.displayName,
        valueColor: lobbyColor,
      ));
    }

    // Cafe rejection
    if (r.cafeRejectionReason != null && r.cafeRejectionReason!.isNotEmpty) {
      items.add(_InfoRow(
        label: 'Lý do từ chối',
        value: r.cafeRejectionReason!,
        valueColor: AppColors.error,
      ));
    }

    // Checked in
    if (r.checkedInAt != null) {
      final checkInFormat = DateFormat('dd/MM/yyyy HH:mm');
      items.add(_InfoRow(
        label: 'Check-in lúc',
        value: checkInFormat.format(r.checkedInAt!.toLocal()),
        valueColor: AppColors.success,
      ));
    }

    // Played ratio
    if (r.playedRatio != null) {
      items.add(_InfoRow(
        label: 'Tỷ lệ chơi',
        value: '${(r.playedRatio! * 100).toStringAsFixed(0)}%',
      ));
    }

    // End reason
    if (r.endReason != null && r.endReason!.isNotEmpty) {
      items.add(_InfoRow(
        label: 'Lý do kết thúc',
        value: r.endReason!,
      ));
    }

    // Cancelled by
    if (r.cancelledBy != null && r.cancelledBy!.isNotEmpty) {
      items.add(_InfoRow(
        label: 'Hủy bởi',
        value: r.cancelledBy!,
        valueColor: AppColors.error,
      ));
    }

    // Cancel reason
    if (r.cancelReason != null && r.cancelReason!.isNotEmpty) {
      items.add(_InfoRow(
        label: 'Lý do hủy',
        value: r.cancelReason!,
      ));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return _SectionCard(
      title: 'Thông tin khác',
      icon: Icons.info_outline,
      children: items,
    );
  }

  Color _getLobbyStatusColor(LobbyStatus status, ColorScheme colors) {
    if (status == LobbyStatus.open || status == LobbyStatus.viable) {
      return AppColors.info;
    }
    if (status == LobbyStatus.full || status == LobbyStatus.inProgress) {
      return AppColors.success;
    }
    if (status == LobbyStatus.pendingCafeApproval ||
        status == LobbyStatus.pendingActivation) {
      return AppColors.warning;
    }
    if (status.isRejectedByCafe ||
        status.isExpiredByCafe ||
        status == LobbyStatus.timeoutFailed) {
      return AppColors.error;
    }
    return colors.onSurfaceVariant;
  }
}

// ─── Action Buttons ──────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  final ReservationEntity reservation;
  const _ActionButtons({required this.reservation});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final r = reservation;

    // Check if can enter lobby
    final canEnterLobby = r.lobbyId != null &&
        (r.lobbyStatus == LobbyStatus.open ||
            r.lobbyStatus == LobbyStatus.viable ||
            r.lobbyStatus == LobbyStatus.full ||
            r.lobbyStatus == LobbyStatus.pendingCafeApproval ||
            r.lobbyStatus == LobbyStatus.inProgress);

    // Check if can cancel
    final canCancel = r.canCancel == true ||
        (r.status == ReservationStatus.holding ||
            r.status == ReservationStatus.confirmed);

    // Check if is terminal
    final isTerminal = r.status.isTerminal;

    return Column(
      children: [
        // Enter Lobby button
        if (canEnterLobby) ...[
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: Icon(
                r.lobbyStatus == LobbyStatus.pendingCafeApproval
                    ? Icons.pending_actions
                    : Icons.meeting_room,
              ),
              label: Text(
                r.lobbyStatus == LobbyStatus.pendingCafeApproval
                    ? 'Xem trạng thái duyệt'
                    : 'Vào phòng chờ',
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                backgroundColor: colors.primary,
              ),
              onPressed: () => _enterLobby(context, r),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],

        // Cancel button
        if (canCancel)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Hủy đặt chỗ'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                foregroundColor: colors.error,
                side: BorderSide(color: colors.error),
              ),
              onPressed: () => _showCancelDialog(context, r),
            ),
          ),

        // Terminal state message
        if (isTerminal)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: AppRadius.radiusMdAll,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline,
                    color: colors.onSurfaceVariant, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Đơn đặt chỗ này đã kết thúc',
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _enterLobby(BuildContext context, ReservationEntity r) {
    final lobbyCubit = getIt<LobbyCubit>();
    if (r.lobbyStatus == LobbyStatus.pendingCafeApproval) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => LobbyPendingCafeApprovalPage(
            reservationId: r.id,
            cafeId: r.cafeId,
            cafeName: r.cafeName,
            cafeApprovalDeadline: r.cafeApprovalDeadline,
          ),
        ),
      );
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => LobbyPage(
          lobbyId: r.lobbyId!,
          lobbyCubit: lobbyCubit,
        ),
      ),
    );
  }

  Future<void> _showCancelDialog(
      BuildContext context, ReservationEntity r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xác nhận hủy'),
        content: Text(
          'Hủy đặt chỗ tại ${r.cafeName}?\n'
          'Tiền cọc sẽ được hoàn theo policy.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Đóng'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Tiếp tục'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await ReservationCancelSheet.show(
      context,
      r.id,
      onCancelled: () {
        // Refresh detail page after cancellation
        context.read<ReservationDetailCubit>().refresh(r.id);
      },
    );
  }
}

// ─── Helper Widgets ─────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.radiusLgAll,
        border: Border.all(color: colors.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.1),
                    borderRadius: AppRadius.radiusSmAll,
                  ),
                  child: Icon(icon, size: 20, color: colors.primary),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final TextStyle? valueStyle;
  final Widget? trailing;
  final bool monospace;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.valueStyle,
    this.trailing,
    this.monospace = false,
  });

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
            width: 100,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    value,
                    textAlign: TextAlign.end,
                    style: valueStyle ??
                        theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: valueColor,
                          fontFamily: monospace ? 'monospace' : null,
                          letterSpacing: monospace ? 1.0 : null,
                        ),
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: AppSpacing.xs),
                  trailing!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
