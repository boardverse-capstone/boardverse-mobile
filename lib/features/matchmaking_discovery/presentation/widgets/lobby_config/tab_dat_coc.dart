import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../reservation/domain/entities/entities.dart';
import '../../../../reservation/presentation/cubit/reservation_cubit.dart';
import '../../../../reservation/presentation/cubit/reservation_state.dart';
import 'bottom_button.dart';
import 'info_card.dart';
import 'quote_loading_shimmer.dart';
import 'quote_preview_card.dart';
import 'summary_row.dart';

/// Tab 4 của LobbyConfigPage — đặt cọc + xác nhận.
class LobbyConfigTabDatCoc extends StatefulWidget {
  final String cafeName;
  final String gameName;
  final DateTime selectedDate;
  final TimeSlot selectedTimeSlot;
  final TimeOfDay? preferredStartTime;
  final int maxPlayers;
  final bool isPublic;
  final double minimumKarma;
  final ReservationQuoteEntity? quotePreview;
  final String? quoteError;
  final bool isQuoteLoading;
  final bool isCreatingLobby;
  final int bufferMinutes;
  final bool hasBufferWarning;
  final String Function(DateTime) formatDate;
  final String Function(TimeOfDay) formatTime;
  final String Function(int) formatBuffer;
  final String Function(TimeSlot) getSlotLabel;
  final String Function(TimeSlot) getSlotShortLabel;
  final IconData Function(TimeSlot) getSlotIcon;
  final VoidCallback onConfirm;
  final VoidCallback onRefreshQuote;
  final VoidCallback onLoadQuote;

  const LobbyConfigTabDatCoc({
    super.key,
    required this.cafeName,
    required this.gameName,
    required this.selectedDate,
    required this.selectedTimeSlot,
    required this.preferredStartTime,
    required this.maxPlayers,
    required this.isPublic,
    required this.minimumKarma,
    required this.quotePreview,
    required this.quoteError,
    required this.isQuoteLoading,
    required this.isCreatingLobby,
    required this.bufferMinutes,
    required this.hasBufferWarning,
    required this.formatDate,
    required this.formatTime,
    required this.formatBuffer,
    required this.getSlotLabel,
    required this.getSlotShortLabel,
    required this.getSlotIcon,
    required this.onConfirm,
    required this.onRefreshQuote,
    required this.onLoadQuote,
  });

  @override
  State<LobbyConfigTabDatCoc> createState() => _LobbyConfigTabDatCocState();
}

class _LobbyConfigTabDatCocState extends State<LobbyConfigTabDatCoc> {
  // Tab này không subscribe stream riêng — parent [LobbyConfigPage] đã có
  // subscription tới [ReservationCubit] và truyền [quotePreview]/[quoteError]
  // qua constructor. Tab chỉ đọc trực tiếp cubit state trong [build] để lấy
  // giá trị mới nhất (cubit là singleton qua GetIt).

  @override
  void initState() {
    super.initState();
    // KHÔNG gọi widget.onLoadQuote() ở đây — parent đã trigger load quote
    // ngay trong initState của page. Trước đây tab gọi thêm dẫn đến
    // _loadQuotePreview() chạy 2 lần: clear state + subscribe + createQuote
    // ngay giữa build phase của tab, gây crash "setState during build".
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // BlocBuilder đảm bảo tab rebuild ngay khi cubit đổi state (loading,
    // loaded, error...) — không cần parent truyền lại quotePreview mỗi lần.
    return BlocBuilder<ReservationCubit, ReservationState>(
      bloc: GetIt.instance<ReservationCubit>(),
      builder: (context, reservationState) {
        return _buildBody(context, theme, reservationState);
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    ThemeData theme,
    ReservationState reservationState,
  ) {
    final cubit = GetIt.instance<ReservationCubit>();
    final liveQuote = switch (reservationState) {
      ReservationQuoteLoaded(quote: final q) => q,
      ReservationInsufficientBalance(quote: final q) => q,
      _ => cubit.currentQuote ?? widget.quotePreview,
    };

    // Ưu tiên dùng isQuoteLoading từ parent, fallback sang cubit state
    final isLoading = widget.isQuoteLoading || reservationState is ReservationQuoteLoading;
    final isInitial = reservationState is ReservationInitial;
    final hasErrorState = reservationState is ReservationQuoteError;
    // Đang hoạt động: cubit đang xử lý (Initial/Loading) → KHÔNG dùng
    // widget.quoteError cũ để tránh flash lỗi thoáng chốc khi parent vừa
    // reset state để trigger load mới.
    final cubitIsBusy = isLoading || isInitial;

    // Chỉ hiển thị lỗi khi:
    //  - cubit hiện tại đang ở QuoteError (không phải state trung gian), VÀ
    //  - CHƯA từng có quote nào (liveQuote == null) — nếu đã có quote thì
    //    giữ nguyên content, vì lỗi chỉ liên quan tới lần load mới nhất và
    //    sẽ tự được thay bằng shimmer khi người dùng bấm "Thử lại".
    //  - cubit không đang busy (đã settle ở error).
    final errorMsg = !cubitIsBusy &&
            hasErrorState &&
            liveQuote == null
        ? reservationState.message
        : (!cubitIsBusy && liveQuote == null ? widget.quoteError : null);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: AppSpacing.paddingAllMd,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thông tin đặt cọc',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Xem lại thông tin trước khi đặt cọc',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Summary card
                LobbyConfigInfoCard(
                  icon: Icons.event_note,
                  iconColor: theme.colorScheme.primary,
                  title: 'Tổng quan',
                  child: Column(
                    children: [
                      LobbyConfigSummaryRow(icon: Icons.extension, label: 'Game', value: widget.gameName),
                      LobbyConfigSummaryRow(icon: Icons.local_cafe, label: 'Quán', value: widget.cafeName),
                      LobbyConfigSummaryRow(
                        icon: Icons.calendar_today,
                        label: 'Ngày',
                        value: widget.formatDate(widget.selectedDate),
                      ),
                      LobbyConfigSummaryRow(
                        icon: widget.getSlotIcon(widget.selectedTimeSlot),
                        label: 'Phiên',
                        value: widget.getSlotShortLabel(widget.selectedTimeSlot),
                      ),
                      if (widget.preferredStartTime != null)
                        LobbyConfigSummaryRow(
                          icon: Icons.schedule,
                          label: 'Giờ',
                          value: widget.formatTime(widget.preferredStartTime!),
                        ),
                      LobbyConfigSummaryRow(
                        icon: Icons.people,
                        label: 'Người',
                        value: '${widget.maxPlayers} người',
                      ),
                      LobbyConfigSummaryRow(
                        icon: widget.isPublic ? Icons.public : Icons.lock,
                        label: 'Chế độ',
                        value: widget.isPublic ? 'Công khai' : 'Riêng tư',
                      ),
                      if (widget.minimumKarma > 0)
                        LobbyConfigSummaryRow(
                          icon: Icons.star,
                          label: 'Karma',
                          value: '${widget.minimumKarma.toInt()} điểm',
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Quote preview
                if (isLoading)
                  const LobbyConfigQuoteShimmer()
                else if (errorMsg != null)
                  Container(
                    padding: AppSpacing.paddingAllMd,
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: AppRadius.radiusMdAll,
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 36),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Lỗi khi tải cọc',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          errorMsg,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        OutlinedButton.icon(
                          onPressed: widget.onRefreshQuote,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  )
                else if (liveQuote != null)
                  LobbyConfigQuotePreviewCard(quote: liveQuote, formatBuffer: widget.formatBuffer)
                else
                  Container(
                    padding: AppSpacing.paddingAllMd,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHigh,
                      borderRadius: AppRadius.radiusMdAll,
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 48,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Chưa có thông tin cọc',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Nhấn "Làm mới" để xem chi tiết cọc',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        OutlinedButton.icon(
                          onPressed: widget.onRefreshQuote,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Làm mới'),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: AppSpacing.lg),

                // Buffer warning
                if (widget.hasBufferWarning)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: AppRadius.radiusMdAll,
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning, color: Colors.orange),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'Buffer chỉ ${widget.formatBuffer(widget.bufferMinutes)}. '
                            'Khuyến nghị chọn ngày xa hơn.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),

        LobbyConfigBottomButton(
          label: 'Xác nhận & Đặt cọc',
          // Bỏ block `isBufferTooShort` — cho phép đặt lobby sát giờ
          // (BR §XXI-B.4). Chỉ disable khi quote null / đang loading.
          onPressed: liveQuote == null || widget.isCreatingLobby
              ? null
              : widget.onConfirm,
          isLoading: widget.isCreatingLobby,
        ),
      ],
    );
  }
}