import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/theme.dart';
import '../../domain/entities/booking_entity.dart';
import '../../domain/entities/booking_rating_submission_entity.dart';
import '../../domain/entities/deposit_status_entity.dart';
import '../../domain/entities/no_show_vote_result_entity.dart';
import '../../domain/entities/rating_status_entity.dart';
import '../../domain/entities/session_status_entity.dart';
import '../../domain/enums/booking_status.dart';
import '../cubit/booking_detail_actions_cubit.dart';
import '../cubit/booking_result_cubit.dart';
import '../cubit/booking_result_state.dart';
import '../widgets/booking_qr_card.dart';
import '../widgets/booking_ui_helpers.dart';
import '../widgets/cancel_booking_dialog.dart';
import '../widgets/deposit_refund_badge.dart';
import '../widgets/info_row.dart';
import '../widgets/no_show_vote_sheet.dart';
import '../widgets/rating_form_sheet.dart';
import '../widgets/refund_status_banner.dart';
import '../widgets/session_status_card.dart';
import '../widgets/status_pill.dart';

/// Trang chi tiết booking — read-only sau khi đã Confirmed.
///
/// Tích hợp mới (gaps #4, #5, #8, #11):
/// - Hiển thị `DepositRefundBadge` (gap #11) khi `depositRefundStatus` thuộc
///   Refunded/Forfeited.
/// - `NoShowVoteSheet` (gap #4) hiển thị sau khi `CheckedIn + 30 phút` và
///   trước `scheduleEndTime + 24h`.
/// - `RatingFormSheet` (gap #5) hiển thị sau khi `ScheduleEndTime` qua
///   (`canRate == true` từ `RatingStatusEntity`).
/// - `SessionStatusCard` (gap #8) realtime poll mỗi 30s khi `CheckedIn`.
class BookingDetailPage extends StatefulWidget {
  final BookingEntity booking;

  const BookingDetailPage({super.key, required this.booking});

  @override
  State<BookingDetailPage> createState() => _BookingDetailPageState();
}

class _BookingDetailPageState extends State<BookingDetailPage> {
  late BookingResultCubit _cubit;
  late BookingDetailActionsCubit _actionsCubit;
  late BookingEntity _booking;
  DepositStatusEntity? _refundStatus;

  /// Polling session-status mỗi 30s khi `CheckedIn` (gap #8).
  SessionStatusEntity? _sessionStatus;

  /// Rating status + NoShow vote result để enable/disable nút bấm.
  RatingStatusEntity? _ratingStatus;
  NoShowVoteResultEntity? _lastNoShowVote;

  @override
  void initState() {
    super.initState();
    _booking = widget.booking;
    _cubit = getIt<BookingResultCubit>()
      ..loadById(widget.booking.id)
      ..startPollingStatus(widget.booking.id);
    _actionsCubit = getIt<BookingDetailActionsCubit>();
    _actionsCubit.attach(widget.booking.id);
  }

  @override
  void dispose() {
    _cubit.close();
    _actionsCubit.detach();
    _actionsCubit.close();
    super.dispose();
  }

  Future<void> _cancelBooking() async {
    final reason = await CancelBookingDialog.show(
      context,
      bookingId: widget.booking.id,
    );
    if (reason == null || !mounted) return;
    await _cubit.cancelByPlayer(reason);
  }

  Future<void> _openNoShowSheet() async {
    final result = await showModalBottomSheet<NoShowVoteResultEntity>(
      context: context,
      isScrollControlled: true,
      builder: (_) => NoShowVoteSheet(
        booking: _booking,
        repository: getIt(),
      ),
    );
    if (result != null && mounted) {
      setState(() => _lastNoShowVote = result);
    }
  }

  Future<void> _openRatingSheet() async {
    final result = await showModalBottomSheet<RatingSubmissionResultEntity>(
      context: context,
      isScrollControlled: true,
      builder: (_) => RatingFormSheet(
        booking: _booking,
        ratingStatus: _ratingStatus,
        repository: getIt(),
      ),
    );
    if (result != null && mounted) {
      // Refresh rating status sau khi submit.
      _actionsCubit.refreshRatingStatus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cảm ơn bạn đã chấm điểm! Karma đã được cập nhật.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Color _statusColor() {
    switch (_booking.status.name) {
      case 'confirmed':
        return AppColors.info;
      case 'checkedIn':
        return AppColors.success;
      case 'pendingDeposit':
        return AppColors.warning;
      case 'cancelled':
        return AppColors.textSecondary;
      case 'noShow':
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
      case 'cancelled':
        return Icons.cancel_rounded;
      case 'noShow':
        return Icons.person_off_rounded;
      default:
        return Icons.event_rounded;
    }
  }

  /// `_isTerminal` phải loại bỏ `pendingDeposit` (chỉ là "chờ thanh toán",
  /// không phải đã chốt). Một booking chỉ terminal khi `cancelled`, `noShow`,
  /// hoặc `checkedIn` (đã chốt + có thể chấm điểm).
  bool get _isTerminal =>
      _booking.status == BookingStatus.cancelled ||
      _booking.status == BookingStatus.noShow;

  bool get _canCancel =>
      _booking.status == BookingStatus.confirmed ||
      _booking.status == BookingStatus.pendingDeposit;

  bool get _isCheckedIn => _booking.status == BookingStatus.checkedIn;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<BookingResultCubit>.value(value: _cubit),
        BlocProvider<BookingDetailActionsCubit>.value(value: _actionsCubit),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<BookingResultCubit, BookingResultState>(
            listener: (context, state) {
              if (state is ResultCheckedIn) {
                setState(() => _booking = state.booking);
                // Trigger realtime session-status khi vừa vào CheckedIn.
                _actionsCubit.startSessionPolling();
              } else if (state is ResultConfirmed) {
                setState(() => _booking = state.booking);
              }
              if (state is RefundContextLoaded) {
                setState(() => _refundStatus = state.depositStatus);
              }
            },
          ),
          BlocListener<BookingDetailActionsCubit, BookingDetailActionsState>(
            listener: (context, state) {
              if (state is SessionStatusLoaded) {
                setState(() => _sessionStatus = state.session);
              }
              if (state is RatingStatusLoaded) {
                setState(() => _ratingStatus = state.status);
              }
            },
          ),
        ],
        child: Builder(
          builder: (innerContext) {
            final extracted = _extractBooking(_cubit.state);
            if (extracted != null && extracted.status != _booking.status) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() => _booking = extracted);
              });
            }
            final theme = Theme.of(innerContext);
            final accent = _statusColor();
            return Scaffold(
              appBar: AppBar(title: const Text('Chi tiết lịch hẹn')),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderCard(theme, accent),
                    const SizedBox(height: AppSpacing.md),
                    // Deposit refund badge (gap #11)
                    if (_booking.depositRefundStatus != null &&
                        _booking.depositRefundStatus!.isRefundRelevant)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: DepositRefundBadge(
                          status: _booking.depositRefundStatus!,
                          refundAmount: _booking.depositRefundAmount,
                        ),
                      ),
                    // QR — ẩn khi terminal, nhưng vẫn hiển thị cho CheckedIn
                    // (player cần QR để share cho Staff scan partial).
                    if (!_isTerminal || _isCheckedIn) ...[
                      BookingQrCard(booking: _booking),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    if (_isCheckedIn) ...[
                      _buildInGameNotice(theme),
                      const SizedBox(height: AppSpacing.md),
                      // Session status realtime (gap #8)
                      if (_sessionStatus != null)
                        SessionStatusCard(session: _sessionStatus!),
                      const SizedBox(height: AppSpacing.md),
                      // NoShow vote (gap #4)
                      if (_booking.canVoteNoShow)
                        _buildActionRow(
                          theme,
                          icon: Icons.how_to_vote_rounded,
                          label: _lastNoShowVote != null
                              ? 'Cập nhật vote vắng mặt'
                              : 'Vote vắng mặt',
                          color: AppColors.error,
                          onPressed: _openNoShowSheet,
                        ),
                    ],
                    if (_canCancel) ...[
                      OutlinedButton.icon(
                        onPressed: _cancelBooking,
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text('Huỷ đơn'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          foregroundColor: AppColors.error,
                          side: BorderSide(
                            color: AppColors.error.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    // Rating (gap #5) — chỉ khi đã scheduleEndTime + chưa rate.
                    if (_booking.status == BookingStatus.noShow ||
                        _booking.status == BookingStatus.checkedIn ||
                        _booking.scheduleEndTime.isBefore(DateTime.now()))
                      _buildRatingSection(theme),
                    if (_isTerminal) _buildTerminalMessage(theme),
                    if (_refundStatus != null)
                      RefundStatusBanner(depositStatus: _refundStatus!),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRatingSection(ThemeData theme) {
    final canRate = _ratingStatus?.canRate ?? false;
    final alreadyRated = _ratingStatus?.alreadyRated ?? false;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.30),
        borderRadius: AppRadius.cardRadius,
        border: Border.all(
          color: theme.colorScheme.tertiary.withValues(alpha: 0.30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.star_rate_rounded,
                color: theme.colorScheme.tertiary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  alreadyRated
                      ? 'Bạn đã chấm điểm cho booking này.'
                      : 'Chấm điểm các thành viên trong lobby',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (!canRate && !alreadyRated) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Cửa sổ chấm điểm chưa mở hoặc đã đóng.',
              style: theme.textTheme.bodySmall,
            ),
          ],
          if (canRate || alreadyRated) ...[
            const SizedBox(height: AppSpacing.sm),
            FilledButton.icon(
              onPressed: _openRatingSheet,
              icon: Icon(
                alreadyRated ? Icons.edit_rounded : Icons.star_outline_rounded,
              ),
              label: Text(alreadyRated ? 'Sửa đánh giá' : 'Chấm điểm ngay'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionRow(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: color),
        label: Text(label, style: TextStyle(color: color)),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          side: BorderSide(color: color.withValues(alpha: 0.5)),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(ThemeData theme, Color accent) {
    return Container(
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
                                style: theme.textTheme.bodySmall?.copyWith(
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
                    label: BookingUiHelpers.statusToLabel(_booking.status),
                    variant: BookingUiHelpers.statusToVariant(_booking.status),
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
                    label: 'Bắt đầu',
                    value: BookingUiHelpers.formatLongDateTime(
                      _booking.scheduledTime,
                    ),
                  ),
                  InfoRow(
                    icon: AppIcons.timer,
                    label: 'Kết thúc',
                    value: BookingUiHelpers.formatLongDateTime(
                      _booking.scheduleEndTime,
                    ),
                  ),
                  InfoRow(
                    icon: AppIcons.users,
                    label: 'Số ghế',
                    value: '${_booking.seatCount} chỗ',
                  ),
                  InfoRow(
                    icon: AppIcons.money,
                    label: 'Đã cọc',
                    value: BookingUiHelpers.formatVnd(_booking.depositAmount),
                    iconColor: AppColors.primary,
                  ),
                  InfoRow(
                    icon: AppIcons.qrCode,
                    label: 'Mã đơn',
                    value: _booking.id,
                    iconColor: AppColors.secondary,
                    copyable: true,
                  ),
                  if (_booking.cafeTableName != null &&
                      _booking.cafeTableName!.isNotEmpty)
                    InfoRow(
                      icon: Icons.table_restaurant_rounded,
                      label: 'Bàn',
                      value: _booking.cafeTableName!,
                    ),
                  if (_booking.isWalkIn)
                    InfoRow(
                      icon: Icons.directions_walk_rounded,
                      label: 'Walk-in',
                      value: 'Đặt trực tiếp (không qua lobby)',
                      iconColor: theme.colorScheme.tertiary,
                    ),
                  if (_booking.checkedInAt != null)
                    InfoRow(
                      icon: Icons.qr_code_scanner_rounded,
                      label: 'Check-in lúc',
                      value: BookingUiHelpers.formatLongDateTime(
                        _booking.checkedInAt!,
                      ),
                      iconColor: AppColors.success,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInGameNotice(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.10),
        borderRadius: AppRadius.radiusMdAll,
        border: Border.all(color: AppColors.success.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.sports_esports_rounded,
            color: AppColors.success,
            size: AppIcons.lg,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Đã check-in tại quán',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Vui lòng tận hưởng phiên chơi. Có thể vote vắng mặt sau 30 phút.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTerminalMessage(ThemeData theme) {
    String message;
    IconData icon;
    Color color;

    switch (_booking.status.name) {
      case 'cancelled':
        message =
            'Bạn đã huỷ đơn này. Cọc sẽ được hoàn theo chính sách quán.';
        icon = Icons.cancel_rounded;
        color = AppColors.textSecondary;
        break;
      case 'noShow':
        message =
            'Bạn đã không đến quán trong khung giờ đã đặt. Cọc đã bị tịch thu theo chính sách BR-10.';
        icon = Icons.person_off_rounded;
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

  BookingEntity? _extractBooking(BookingResultState state) {
    if (state is ResultConfirmed) return state.booking;
    if (state is ResultCheckedIn) return state.booking;
    if (state is ResultCancelled) return state.booking;
    return null;
  }
}