import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/theme.dart';
import '../../../lobby_management/presentation/cubit/lobby_cubit.dart';
import '../../../lobby_management/presentation/pages/lobby_page.dart';
import '../../../lobby_management/presentation/pages/lobby_pending_cafe_approval_page.dart';
import '../../domain/entities/entities.dart';
import '../cubit/reservation_cubit.dart';
import 'reservation_cancel_sheet.dart';

/// Trang chi tiết một reservation — entry point xem thông tin đầy đủ + các
/// hành động liên quan (Vào lobby, Hủy đặt chỗ).
///
/// Truy cập từ:
/// - `ReservationListPage` (bấm vào card trong tab "Lịch đặt").
/// - Deep link từ notification.
/// - `LobbyPendingCafeApprovalPage` (sau khi cafe reject → xem chi tiết).
///
/// Đóng gói reservation ban đầu qua constructor (snapshot từ list page);
/// nếu cần fresh data, gọi `repository.getReservation(id)` (TODO phase 2).
class ReservationDetailPage extends StatelessWidget {
  final ReservationEntity reservation;

  const ReservationDetailPage({super.key, required this.reservation});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ReservationCubit>.value(
      value: sl<ReservationCubit>(),
      child: _ReservationDetailView(reservation: reservation),
    );
  }
}

class _ReservationDetailView extends StatelessWidget {
  final ReservationEntity reservation;
  const _ReservationDetailView({required this.reservation});

  @override
  Widget build(BuildContext context) {
    final r = reservation;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final canCancel = r.status == ReservationStatus.holding ||
        r.status == ReservationStatus.confirmed;
    final canEnterLobby = r.lobbyId != null &&
        (r.lobbyStatus == LobbyStatus.open ||
            r.lobbyStatus == LobbyStatus.viable ||
            r.lobbyStatus == LobbyStatus.full ||
            r.lobbyStatus == LobbyStatus.pendingCafeApproval);

    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết đặt chỗ')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            _HeaderCard(reservation: r),
            const SizedBox(height: AppSpacing.md),
            _DetailCard(reservation: r),
            const SizedBox(height: AppSpacing.md),
            if (canEnterLobby) ...[
              FilledButton.icon(
                icon: const Icon(Icons.meeting_room),
                label: Text(
                  r.lobbyStatus == LobbyStatus.pendingCafeApproval
                      ? 'Xem trạng thái duyệt'
                      : 'Vào phòng chờ',
                ),
                onPressed: () => _enterLobby(context, r),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            if (canCancel)
              OutlinedButton.icon(
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Hủy đặt chỗ'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.error,
                  side: BorderSide(color: colors.error),
                ),
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Xác nhận hủy'),
                      content: Text(
                        'Hủy đặt chỗ tại ${r.cafeName}?\n'
                        'Hoàn cọc áp dụng theo policy BR-REFUND-02/03 '
                        '(tùy thời điểm hủy).',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Đóng'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Tiếp tục'),
                        ),
                      ],
                    ),
                  );
                  if (ok != true || !context.mounted) return;
                  await ReservationCancelSheet.show(context, r.id);
                },
              ),
          ],
        ),
      ),
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
}

class _HeaderCard extends StatelessWidget {
  final ReservationEntity reservation;
  const _HeaderCard({required this.reservation});

  @override
  Widget build(BuildContext context) {
    final r = reservation;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final statusColor = _statusColor(colors, r.status);
    final dateText = DateFormat('EEEE • dd/MM/yyyy', 'vi')
        .format(r.playDate);
    final timeText = r.preferredStartTime != null
        ? '${r.timeSlot.displayName} (${r.preferredStartTime})'
        : r.timeSlot.displayName;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.3),
        borderRadius: AppRadius.radiusMdAll,
        border: Border.all(color: colors.primary.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  r.cafeName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: AppRadius.radiusFullAll,
                ),
                child: Text(
                  r.status.displayName,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            r.gameName,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          _iconLine(context, Icons.event, dateText),
          _iconLine(context, Icons.schedule, timeText),
          if (r.lobbyShareCode != null && r.lobbyShareCode!.isNotEmpty)
            _iconLine(
              context,
              Icons.qr_code,
              'Mã chia sẻ: ${r.lobbyShareCode}',
              monospace: true,
            ),
        ],
      ),
    );
  }

  Widget _iconLine(
    BuildContext context,
    IconData icon,
    String text, {
    bool monospace = false,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xxs),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: monospace ? 'monospace' : null,
                fontWeight: monospace ? FontWeight.w700 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(ColorScheme colors, ReservationStatus status) {
    if (status.isTerminal) return colors.error;
    if (status.isActive) return colors.primary;
    return AppColors.warning;
  }
}

class _DetailCard extends StatelessWidget {
  final ReservationEntity reservation;
  const _DetailCard({required this.reservation});

  @override
  Widget build(BuildContext context) {
    final r = reservation;
    final theme = Theme.of(context);
    final deadline = DateFormat('HH:mm • dd/MM')
        .format(r.recruitmentDeadline.toLocal());

    final rows = <_DetailRow>[
      _DetailRow(
        icon: Icons.confirmation_number,
        label: 'Mã reservation',
        value: r.id.length > 12
            ? '${r.id.substring(0, 8)}…${r.id.substring(r.id.length - 4)}'
            : r.id,
        monospace: true,
      ),
      _DetailRow(
        icon: Icons.group,
        label: 'Số người',
        value: '${r.currentPlayers}/${r.maxPlayers} '
            '(tối thiểu ${r.minPlayers})',
      ),
      _DetailRow(
        icon: Icons.account_balance_wallet,
        label: 'Tiền cọc',
        value: '${r.finalDeposit} BVC '
            '(${r.depositRatePerPerson}/người × ${r.maxPlayers})',
      ),
      _DetailRow(
        icon: Icons.timer_outlined,
        label: 'Hạn tuyển người',
        value: deadline,
      ),
      _DetailRow(
        icon: r.isPrivate ? Icons.lock_outline : Icons.public,
        label: 'Loại phòng',
        value: r.isPrivate ? 'Riêng tư' : 'Công khai',
      ),
      if (r.lobbyStatus != null)
        _DetailRow(
          icon: Icons.meeting_room_outlined,
          label: 'Trạng thái lobby',
          value: r.lobbyStatus!.displayName,
        ),
      if (r.cafeRejectionReason != null &&
          r.cafeRejectionReason!.isNotEmpty)
        _DetailRow(
          icon: Icons.report_outlined,
          label: 'Lý do cafe từ chối',
          value: r.cafeRejectionReason!,
        ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.radiusMdAll,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        children: [
          for (final row in rows) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                children: [
                  Icon(row.icon,
                      size: 18, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          row.label,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          row.value,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontFamily: row.monospace ? 'monospace' : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (row != rows.last)
              Divider(
                height: 1,
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow {
  final IconData icon;
  final String label;
  final String value;
  final bool monospace;

  _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.monospace = false,
  });
}