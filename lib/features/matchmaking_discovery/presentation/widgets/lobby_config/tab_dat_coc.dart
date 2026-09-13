import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/neo_brutalism_theme.dart';
import '../../../../reservation/domain/entities/entities.dart';
import '../../../../reservation/presentation/cubit/reservation_cubit.dart';
import '../../../../reservation/presentation/cubit/reservation_state.dart';
import 'bottom_button.dart';
import 'info_card.dart';
import 'quote_loading_shimmer.dart';
import 'quote_preview_card.dart';
import 'summary_row.dart';

/// Tab 4 của LobbyConfigPage — đặt cọc + xác nhận.
///
/// Style: Neo-brutalism theo design system v4.0 (`.agents/docs/design_system.md`).
/// - Section headers: titleLarge w900, subtitle bodyMedium.
/// - Card: border 3px, hard offset shadow (5, 5), icon badge màu semantic.
/// - Status containers (error / warning / empty): border đậm + shadow màu.
class LobbyConfigTabDatCoc extends StatefulWidget {
  final String cafeName;
  final String gameName;
  final DateTime selectedDate;
  final TimeOfDay? preferredStartTime;
  final TimeOfDay? preferredEndTime;

  /// `true` khi lobby kéo dài qua đêm (endTime < startTime). Khi true,
  /// summary row "Giờ kết thúc" hiển thị thêm badge "+1 ngày" để user
  /// nhận biết rằng end time thuộc ngày kế tiếp. Xem BR-NEW-15.
  final bool endCrossesMidnight;

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
  final VoidCallback onConfirm;
  final VoidCallback onRefreshQuote;
  final VoidCallback onLoadQuote;

  const LobbyConfigTabDatCoc({
    super.key,
    required this.cafeName,
    required this.gameName,
    required this.selectedDate,
    this.preferredStartTime,
    this.preferredEndTime,
    required this.endCrossesMidnight,
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
    //
    // Phân biệt 2 trường hợp `Initial`:
    //   - Parent đang trigger load (widget.isQuoteLoading = true) → cubit
    //     vừa `reset()` nên đang ở Initial → đây là bước trung gian của 1
    //     lần load mới → KHÔNG coi là settled. UI phải show shimmer.
    //   - Parent CHƯA từng trigger load (lần đầu mở tab, widget.isQuoteLoading
    //     = false) → cubit vẫn ở Initial từ trước → settled state → show
    //     empty state cho user bấm "Làm mới".
    final cubitIsBusy = isLoading || (isInitial && widget.isQuoteLoading);

    // Hiển thị error message — ưu tiên message trực tiếp từ cubit state
    // (nếu cubit đã settled ở QuoteError). Ngược lại fallback về parent
    // error (`widget.quoteError`) — parent set giá trị này qua stream
    // listener ở LobbyConfigPage.
    //
    // Lưu ý quan trọng: skip parent error khi `cubitIsBusy` (đang load
    // lại) để tránh flash lỗi cũ. Còn khi cubit ở Initial nhưng parent
    // đã có error từ lần load trước đó (chưa reset xong) → VẪN hiển thị
    // error vì user cần thấy lỗi để biết action cần làm.
    String? computedError;
    if (!cubitIsBusy && hasErrorState && liveQuote == null) {
      computedError = reservationState.message;
    } else if (!cubitIsBusy && liveQuote == null && widget.quoteError != null) {
      // Fallback: dùng parent error. Đây là trường hợp phổ biến vì:
      //   - Listener của parent capture `ReservationQuoteError.message`
      //     vào `_quoteError` → widget rebuild với `widget.quoteError`.
      //   - Sau đó user bấm "Làm mới" → parent gọi `_loadQuotePreview()`
      //     → `reservationCubit.reset()` làm cubit emit `ReservationInitial`
      //     → BlocBuilder của tab 4 build với state=Initial, parentError=vẫn
      //     có message cũ (parent chưa clear `_quoteError` vì stream listener
      //     đã cancel). Lúc này cần dùng parentError để user biết lỗi.
      computedError = widget.quoteError;
    }
    // Debug: log trạng thái để chẩn đoán nếu error không hiển thị.
    debugPrint(
      '[TabDatCoc] state=${reservationState.runtimeType} '
      'isLoading=$isLoading isInitial=$isInitial '
      'hasErrorState=$hasErrorState liveQuote=${liveQuote != null} '
      'parentError=${widget.quoteError} computedError=$computedError',
    );
    final errorMsg = computedError;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: AppSpacing.paddingAllMd,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Page Header ───────────────────────────────────────
                Text(
                  'Xác nhận đặt cọc',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Kiểm tra thông tin lobby và chi tiết cọc trước khi xác nhận',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: NeoBrutalismTheme.textSecondaryColor(context),
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // ── Section 1: Tổng quan ──────────────────────────────
                LobbyConfigInfoCard(
                  icon: Icons.event_note_rounded,
                  iconColor: AppColors.primary,
                  title: 'Tổng quan lobby',
                  useNeoStyle: true,
                  child: Column(
                    children: [
                      LobbyConfigSummaryRow(
                          icon: Icons.extension_rounded,
                          label: 'Game',
                          value: widget.gameName),
                      _NeoDivider(),
                      LobbyConfigSummaryRow(
                          icon: Icons.local_cafe_rounded,
                          label: 'Quán',
                          value: widget.cafeName),
                      _NeoDivider(),
                      LobbyConfigSummaryRow(
                        icon: Icons.calendar_today_rounded,
                        label: 'Ngày',
                        value: widget.formatDate(widget.selectedDate),
                      ),
                      if (widget.preferredStartTime != null) ...[
                        _NeoDivider(),
                        LobbyConfigSummaryRow(
                          icon: Icons.play_arrow_rounded,
                          label: 'Giờ bắt đầu',
                          value:
                              widget.formatTime(widget.preferredStartTime!),
                        ),
                      ],
                      if (widget.preferredEndTime != null) ...[
                        _NeoDivider(),
                        LobbyConfigSummaryRow(
                          icon: Icons.stop_rounded,
                          label: 'Giờ kết thúc',
                          value: widget.formatTime(widget.preferredEndTime!) +
                              (widget.endCrossesMidnight ? ' (+1 ngày)' : ''),
                        ),
                      ],
                      _NeoDivider(),
                      LobbyConfigSummaryRow(
                        icon: Icons.group_rounded,
                        label: 'Số người',
                        value: '${widget.maxPlayers} người',
                      ),
                      _NeoDivider(),
                      LobbyConfigSummaryRow(
                        icon: widget.isPublic
                            ? Icons.public_rounded
                            : Icons.lock_rounded,
                        label: 'Chế độ',
                        value: widget.isPublic ? 'Công khai' : 'Riêng tư',
                      ),
                      if (widget.minimumKarma > 0) ...[
                        _NeoDivider(),
                        LobbyConfigSummaryRow(
                          icon: Icons.star_rounded,
                          label: 'Karma tối thiểu',
                          value: '${widget.minimumKarma.toInt()} điểm',
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // ── Section 2: Quote / Status ─────────────────────────
                LobbyConfigInfoCard(
                  icon: Icons.payments_rounded,
                  iconColor: AppColors.success,
                  title: 'Chi tiết cọc',
                  useNeoStyle: true,
                  neoShadowColor: AppColors.success.withValues(alpha: 0.2),
                  child: _buildQuoteSection(
                    context,
                    theme,
                    isLoading,
                    errorMsg,
                    liveQuote,
                  ),
                ),

                if (widget.hasBufferWarning) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _BufferWarningBanner(
                    formatBuffer: widget.formatBuffer,
                    bufferMinutes: widget.bufferMinutes,
                  ),
                ],
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

  Widget _buildQuoteSection(
    BuildContext context,
    ThemeData theme,
    bool isLoading,
    String? errorMsg,
    ReservationQuoteEntity? liveQuote,
  ) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: LobbyConfigQuoteShimmer(),
      );
    }
    if (errorMsg != null) {
      return _ErrorState(
        message: errorMsg,
        onRetry: widget.onRefreshQuote,
      );
    }
    if (liveQuote != null) {
      return LobbyConfigQuotePreviewCard(
        quote: liveQuote,
        formatBuffer: widget.formatBuffer,
      );
    }
    return _EmptyState(onRefresh: widget.onRefreshQuote);
  }
}

// ══════════════════════════════════════════════════════════════════════════
// HELPER WIDGETS
// ══════════════════════════════════════════════════════════════════════════

/// Divider mỏng theo style neo-brutalism: thay vì `Divider` Flutter mặc định
/// (thickness 1px mờ), dùng container 1.5px với màu border.
class _NeoDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 1.5,
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      color: isDark ? AppColors.borderDark : AppColors.border,
    );
  }
}

/// Error state khi không tải được quote. Border + hard shadow đỏ nhạt,
/// icon badge màu error, action button retry theo style neo.
class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: AppSpacing.paddingAllMd,
      decoration: NeoBrutalismTheme.brutalBox(
        backgroundColor: AppColors.error.withValues(alpha: 0.08),
        borderColor: AppColors.error,
        bold: false,
        borderRadius: 12,
        shadowColor: AppColors.error.withValues(alpha: 0.3),
      ),
      child: Column(
        children: [
          // Icon badge
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.border,
                width: NeoBrutalismTheme.borderWidth,
              ),
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: AppColors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Lỗi khi tải cọc',
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.errorDark,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _NeoOutlineButton(
            label: 'Thử lại',
            icon: Icons.refresh_rounded,
            color: AppColors.error,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

/// Empty state khi chưa có quote (lần đầu mở tab). Icon badge + text +
/// button refresh.
class _EmptyState extends StatelessWidget {
  final VoidCallback onRefresh;

  const _EmptyState({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.border,
              width: NeoBrutalismTheme.borderWidth,
            ),
          ),
          child: Icon(
            Icons.info_outline_rounded,
            color: AppColors.primary,
            size: 28,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Chưa có thông tin cọc',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          'Nhấn "Làm mới" để xem chi tiết cọc',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: NeoBrutalismTheme.textSecondaryColor(context),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _NeoOutlineButton(
          label: 'Làm mới',
          icon: Icons.refresh_rounded,
          color: AppColors.primary,
          onPressed: onRefresh,
        ),
      ],
    );
  }
}

/// Buffer warning banner khi buffer quá ngắn. Border + hard shadow cam nhạt.
class _BufferWarningBanner extends StatelessWidget {
  final String Function(int) formatBuffer;
  final int bufferMinutes;

  const _BufferWarningBanner({
    required this.formatBuffer,
    required this.bufferMinutes,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: AppSpacing.paddingAllMd,
      decoration: NeoBrutalismTheme.brutalBox(
        backgroundColor: AppColors.warning.withValues(alpha: 0.1),
        borderColor: AppColors.warning,
        bold: false,
        borderRadius: 14,
        shadowColor: AppColors.warning.withValues(alpha: 0.3),
      ),
      child: Row(
        children: [
          // Icon badge
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.warning,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.border,
                width: NeoBrutalismTheme.borderWidth,
              ),
            ),
            child: const Icon(
              Icons.warning_rounded,
              color: AppColors.black,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Buffer ngắn',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.warningDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Buffer chỉ ${formatBuffer(bufferMinutes)}. '
                  'Khuyến nghị chọn ngày xa hơn để có đủ thời gian tuyển người.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.warningDark,
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

/// Outline button theo neo-brutalism: nền trắng/surface, border màu semantic,
/// hard shadow (3, 3). Dùng cho retry/refresh trong error/empty state.
class _NeoOutlineButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _NeoOutlineButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: isDark ? AppColors.surfaceDark : AppColors.white,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: color,
          width: NeoBrutalismTheme.borderWidthBold,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 0,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: NeoBrutalismTheme.lightShadow(
              shadowColor: color.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}