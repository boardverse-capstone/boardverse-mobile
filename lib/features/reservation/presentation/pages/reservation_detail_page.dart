import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../in_game_experience/presentation/pages/in_game_session_page.dart';
import '../../../in_game_experience/presentation/cubit/in_game_cubit.dart';
import '../../../lobby_management/domain/entities/lobby_entity.dart';
import '../../../lobby_management/domain/repositories/lobby_repository.dart';
import '../../../lobby_management/lobby_routes.dart' show LobbyRoutes;
import '../../../lobby_management/presentation/cubit/lobby_cubit.dart';
import '../../../lobby_management/presentation/pages/lobby_page.dart';
import '../../../lobby_management/presentation/pages/lobby_pending_cafe_approval_page.dart';
import '../../../lobby_management/presentation/pages/lobby_rating_page.dart';
import '../../../player_check_in/presentation/pages/player_qr_check_in_page_args.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/reservation_repository.dart';
import '../cubit/reservation_detail_cubit.dart';
import '../cubit/reservation_detail_state.dart';
import 'reservation_cancel_sheet.dart';

/// Trang chi tiết một reservation — hiển thị đầy đủ thông tin từ API
/// và mã QR cho POS check-in.
///
/// Gọi `GET /api/v1/reservations/{id}` để lấy dữ liệu mới nhất từ server.
///
/// [reservation] - Optional snapshot từ list page để hiển thị tạm trong khi loading.
/// [bookingId] - Required khi navigation từ InGameSessionPage (không có reservation snapshot).
class ReservationDetailPage extends StatelessWidget {
  final ReservationEntity? reservation;
  final String? bookingId;

  const ReservationDetailPage({
    super.key,
    this.reservation,
    this.bookingId,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = ReservationDetailCubit(
      repository: sl<ReservationRepository>(),
      lobbyRepository: sl<LobbyRepository>(),
    );

    // Xác định reservationId để fetch
    final reservationId = reservation?.id ?? bookingId;
    final onInit = reservationId != null
        ? () => cubit.fetchReservation(
            reservationId: reservationId,
            snapshot: reservation,
          )
        : null;

    return BlocProvider.value(
      value: cubit,
      child: _ReservationDetailView(
        reservation: reservation,
        onInit: onInit,
      ),
    );
  }
}

class _ReservationDetailView extends StatefulWidget {
  final ReservationEntity? reservation;
  final VoidCallback? onInit;

  const _ReservationDetailView({
    this.reservation,
    this.onInit,
  });

  @override
  State<_ReservationDetailView> createState() => _ReservationDetailViewState();
}

class _ReservationDetailViewState extends State<_ReservationDetailView> {
  @override
  void initState() {
    super.initState();
    widget.onInit?.call();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReservationDetailCubit, ReservationDetailState>(
      builder: (context, state) {
        ReservationEntity? r;
        if (state is ReservationDetailLoaded) {
          r = state.reservation;
        } else if (state is ReservationDetailLoading && state.reservation != null) {
          r = state.reservation!;
        } else {
          r = widget.reservation;
        }

        final colors = Theme.of(context).colorScheme;
        final isLoading = state is ReservationDetailLoading;

        if (r == null && isLoading) {
          return Scaffold(
            backgroundColor: colors.surface,
            appBar: AppBar(
              title: const Text('Chi tiết đặt chỗ'),
              backgroundColor: colors.surface,
            ),
            body: _buildLoadingSkeleton(colors),
          );
        }

        if (r == null) {
          return Scaffold(
            backgroundColor: colors.surface,
            appBar: AppBar(
              title: const Text('Chi tiết đặt chỗ'),
              backgroundColor: colors.surface,
            ),
            body: const Center(
              child: Text('Không tìm thấy thông tin đặt chỗ'),
            ),
          );
        }

        return _buildContent(context, r, colors, isLoading, state);
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    ReservationEntity r,
    ColorScheme colors,
    bool isLoading,
    ReservationDetailState state,
  ) {
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
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Cập nhật',
              onPressed: () =>
                  context.read<ReservationDetailCubit>().refresh(r.id),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<ReservationDetailCubit>().refresh(r.id),
        child: Stack(
          children: [
            ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.xl,
              ),
              children: [
                _HeaderCard(reservation: r),
                const SizedBox(height: AppSpacing.md),

                // ─── Primary Action Strip (always visible at top) ───────────────
                _PrimaryActionStrip(reservation: r),
                const SizedBox(height: AppSpacing.md),

                if (r.lobbyShareCode != null && r.lobbyShareCode!.isNotEmpty) ...[
                  _ReservationCodeCard(code: r.lobbyShareCode!),
                  const SizedBox(height: AppSpacing.md),
                ],
                _TimeCard(reservation: r),
                const SizedBox(height: AppSpacing.md),
                _LocationCard(reservation: r),
                const SizedBox(height: AppSpacing.md),
                _PlayersCard(reservation: r),
                const SizedBox(height: AppSpacing.md),
                _DepositCard(reservation: r),
                const SizedBox(height: AppSpacing.md),
                _AdditionalInfoCard(reservation: r),
                const SizedBox(height: AppSpacing.md),

                // ─── Secondary Actions (bottom) ───────────────────────────
                _SecondaryActions(reservation: r),
              ],
            ),
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
      ),
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

// ─── Reservation Code Card ────────────────────────────────────────────────
//
/// Hiển thị mã lịch hẹn (reservation share code) — KHÔNG kèm QR image.
/// Lý do: Ở mobile flow, player không cần QR để đưa staff quét (player tự
/// quét QR POS ở màn hình check-in riêng). Code này chỉ là mã text để
/// player tham chiếu khi cần liên hệ quán hoặc dán vào nhập tay.
class _ReservationCodeCard extends StatelessWidget {
  final String code;
  const _ReservationCodeCard({required this.code});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.3),
        borderRadius: AppRadius.radiusLgAll,
        border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.15),
              borderRadius: AppRadius.radiusMdAll,
            ),
            child: Icon(
              Icons.confirmation_number_outlined,
              color: colors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Mã lịch hẹn',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  code,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                    color: colors.primary,
                  ),
                ),
              ],
            ),
          ),
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

    final playDateStr = DateFormatter.fullDate(r.playDate);
    final startTimeStr = DateFormatter.timeOnly(r.scheduledTime);
    // BR-NEW-15: ưu tiên `preferredEndTime` (giờ user đã chọn chính xác),
    // fallback `scheduledEndTime` từ server, fallback cuối cùng +3h từ start.
    final endTimeStr = r.preferredEndTime != null
        ? DateFormatter.stripSeconds(r.preferredEndTime)
        : (r.scheduledEndTime != null
            ? DateFormatter.timeOnly(r.scheduledEndTime!)
            : DateFormatter.timeOnly(
                r.scheduledTime.add(const Duration(hours: 3))));
    final deadlineStr = r.recruitmentDeadline != null
        ? DateFormatter.timeOnly(r.recruitmentDeadline!)
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
          value: r.preferredStartTime != null
              ? DateFormatter.stripSeconds(r.preferredStartTime)
              : startTimeStr,
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
      items.add(_InfoRow(
        label: 'Check-in lúc',
        value: DateFormatter.fullDateTime(r.checkedInAt!),
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
    if (status == LobbyStatus.rejectedByCafe ||
        status == LobbyStatus.expiredByCafe ||
        status == LobbyStatus.timeoutFailed) {
      return AppColors.error;
    }
    return colors.onSurfaceVariant;
  }
}

// ─── Primary Action Strip ─────────────────────────────────────────────────
//
/// Hiển thị nút hành động ƯU TIÊN ngay dưới header — player không phải
/// cuộn xuống cuối mới thấy. Cấu trúc:
///
/// - **Primary button (1 nút, tùy trạng thái):**
///   - checkedIn / checkedInAt != null → "Phiên chơi của tôi" (green)
///   - chưa check-in + chưa terminal → "Quét QR check-in" (secondary color)
/// - **Secondary "Vào phòng chờ" button**: luôn hiển thị khi lobby tồn tại
///   VÀ lobby ở trạng thái cho phép xem chi tiết (không bị đóng/hủy/dissolved).
///   Điều này cho phép player đã check-in (đang chơi) vẫn có thể quay lại
///   xem lobby khi cần (xem danh sách thành viên, chat, v.v.).
class _PrimaryActionStrip extends StatelessWidget {
  final ReservationEntity reservation;

  const _PrimaryActionStrip({required this.reservation});

  @override
  Widget build(BuildContext context) {
    final r = reservation;
    final isTerminal = r.status.isTerminal;
    final hasActiveSession = r.checkedInAt != null ||
        r.status == ReservationStatus.checkedIn;
    final canQrCheckIn = r.checkedInAt == null &&
        r.status != ReservationStatus.checkedIn &&
        !isTerminal;

    // Lobby có thể xem chi tiết — bất kỳ trạng thái nào ngoại trừ terminal
    // (closed/timeoutFailed/hostCancelled/rejectedByCafe/expiredByCafe/
    // dissolved). pendingCafeApproval có trang riêng.
    final hasViewableLobby = r.lobbyId != null &&
        r.lobbyStatus != null &&
        !r.lobbyStatus!.isTerminal &&
        r.lobbyStatus != LobbyStatus.pendingCafeApproval;
    final showLobbyButton = hasViewableLobby;

    // BR §3.2 (user-ratings.md): mở đánh giá Karma khi lobby ở
    // `RatingOpen` hoặc `Closed` — POS đã thanh toán xong. `Closed`
    // thuộc nhóm terminal nhưng vẫn rate được vì cửa sổ rating được
    // host mở thủ công qua `POST /lobbies/{id}/open-karma-window`
    // trước khi lobby chuyển sang terminal.
    final canRateKarma = r.lobbyId != null &&
        r.lobbyStatus != null &&
        (r.lobbyStatus == LobbyStatus.ratingOpen ||
            r.lobbyStatus == LobbyStatus.closed);

    Widget? primaryButton;
    if (canRateKarma) {
      // Ưu tiên hiển thị nút đánh giá Karma khi lobby đã mở cửa sổ
      // rating — đây là action quan trọng nhất sau thanh toán.
      primaryButton = _buildPrimary(
        context: context,
        label: 'Đánh giá Karma',
        bgColor: AppColors.warning,
        icon: Icons.star_rate,
        onPressed: () => _navigateToKarmaRating(context, r),
      );
    } else if (hasActiveSession && !isTerminal) {
      primaryButton = _buildPrimary(
        context: context,
        label: 'Phiên chơi của tôi',
        bgColor: AppColors.success,
        icon: Icons.sports_esports,
        onPressed: () => _navigateToInGameSession(context, r),
      );
    } else if (canQrCheckIn) {
      primaryButton = _buildPrimary(
        context: context,
        label: 'Quét QR check-in',
        bgColor: AppColors.secondary,
        icon: Icons.qr_code_scanner,
        onPressed: () => _navigateToPlayerQrCheckIn(context, r),
      );
    }

    Widget? lobbyButton;
    if (showLobbyButton) {
      lobbyButton = _buildPrimary(
        context: context,
        label: 'Vào phòng chờ',
        bgColor: Theme.of(context).colorScheme.primary,
        icon: Icons.meeting_room,
        onPressed: () => _enterLobby(context, r),
      );
    }

    if (primaryButton == null && lobbyButton == null) {
      return const SizedBox.shrink();
    }

    // Nếu có 2 nút: primary ở trên, lobby button ở dưới.
    // Nếu chỉ 1 nút: dùng trực tiếp (tránh empty spacing).
    if (lobbyButton == null) return primaryButton!;
    if (primaryButton == null) return lobbyButton;

    return Column(
      children: [
        primaryButton,
        const SizedBox(height: AppSpacing.sm),
        lobbyButton,
      ],
    );
  }

  Widget _buildPrimary({
    required BuildContext context,
    required String label,
    required Color bgColor,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        icon: Icon(icon, color: AppColors.white),
        label: Text(label),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          backgroundColor: bgColor,
          foregroundColor: AppColors.white,
        ),
        onPressed: onPressed,
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

  /// Mở màn đánh giá Karma (real API) từ trang chi tiết reservation.
  ///
  /// Entry point phụ bên cạnh `LobbyEndedView.onRate` — cover trường hợp
  /// user chưa mở LobbyPage mà vào thẳng ReservationDetailPage sau khi
  /// POS thanh toán.
  void _navigateToKarmaRating(
    BuildContext context,
    ReservationEntity r,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (_) => LobbyRatingPage(
          lobbyId: r.lobbyId!,
          reservationId: r.id,
        ),
      ),
    );
  }

  void _navigateToInGameSession(BuildContext context, ReservationEntity r) {
    final inGameCubit = getIt<InGameCubit>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: inGameCubit,
          child: InGameSessionPage(
            bookingId: r.id,
            skipCheckIn: true,
            useApiSession: true,
            lobbyId: r.lobbyId,
          ),
        ),
      ),
    );
  }

  void _navigateToPlayerQrCheckIn(BuildContext context, ReservationEntity r) {
    final shareCode = r.lobbyShareCode ?? r.id;
    Navigator.of(context, rootNavigator: true).pushNamed(
      LobbyRoutes.playerQrCheckIn,
      arguments: PlayerQrCheckInPageArgs(
        reservationId: r.id,
        lobbyShareCode: shareCode,
        cafeName: r.cafeName,
        gameName: r.gameName,
        tableNumber: 1,
        onCheckInSuccess: () {
          context.read<ReservationDetailCubit>().refresh(r.id);
        },
      ),
    );
  }
}

// ─── Secondary Actions ──────────────────────────────────────────────────────
//
/// Các nút hành động THỨ YẾU: hủy đặt chỗ, terminal state message.
/// Tách riêng khỏi primary strip để player dễ phân biệt.
class _SecondaryActions extends StatelessWidget {
  final ReservationEntity reservation;
  const _SecondaryActions({required this.reservation});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final r = reservation;

    final isTerminal = r.status.isTerminal;
    final canCancel = r.canCancel == true ||
        (r.status == ReservationStatus.holding ||
            r.status == ReservationStatus.confirmed);

    if (!canCancel && !isTerminal) return const SizedBox.shrink();

    return Column(
      children: [
        if (canCancel && !isTerminal)
          OutlinedButton.icon(
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Hủy đặt chỗ'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              foregroundColor: colors.error,
              side: BorderSide(color: colors.error),
            ),
            onPressed: () => _showCancelDialog(context, r),
          ),

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
        context.read<ReservationDetailCubit>().refresh(r.id);
      },
    );
  }
}

Widget _buildLoadingSkeleton(ColorScheme colors) {
  return Shimmer.fromColors(
    baseColor: colors.surfaceContainerHighest,
    highlightColor: colors.surface,
    child: SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          // Header card skeleton
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadius.radiusLgAll,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // QR code card skeleton
          Container(
            height: 320,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadius.radiusLgAll,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Section card skeleton
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadius.radiusLgAll,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Section card skeleton
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadius.radiusLgAll,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Section card skeleton
          Container(
            height: 130,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadius.radiusLgAll,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Section card skeleton
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadius.radiusLgAll,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    ),
  );
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
