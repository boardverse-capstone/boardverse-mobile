import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:boardverse/core/di/injection.dart';
import 'package:boardverse/core/theme/app_colors.dart';
import 'package:boardverse/core/theme/app_icons.dart';
import 'package:boardverse/core/theme/app_spacing.dart';
import 'package:boardverse/core/theme/neo_brutalism_theme.dart';
import 'package:boardverse/features/lobby_management/presentation/cubit/lobby_cubit.dart';
import 'package:boardverse/features/lobby_management/presentation/pages/lobby_page.dart';
import 'package:boardverse/features/lobby_management/presentation/pages/lobby_rating_page.dart';
import '../../../reservation/presentation/pages/reservation_detail_page.dart';
import '../../../wallet/presentation/cubit/wallet_cubit.dart';
import '../../../wallet/presentation/cubit/wallet_state.dart';
import '../../../wallet/presentation/pages/topup_page.dart';
import '../../../wallet/presentation/widgets/qr_network_image.dart';
import '../../domain/entities/player_session_entity.dart';
import '../cubit/in_game_cubit.dart';
import '../cubit/in_game_state.dart';
import '../widgets/inventory_checking_overlay.dart';
import '../widgets/play_duration_timer.dart';
import '../widgets/session_ended_notification_dialog.dart';

/// Neo-brutalism in-game session page.
/// Hiển thị thông tin phiên chơi, cho phép gia hạn và thanh toán bằng BVC.
class InGameSessionPage extends StatefulWidget {
  final String bookingId;
  final String? cafeName;
  final String? gameName;
  final int? tableNumber;

  /// Nếu true, bỏ qua `checkIn` trong initState — dùng khi user đã
  /// được staff check-in rồi (gọi từ LobbyCheckInSection sau khi
  /// nhận BookingCheckedInEvent). Tránh duplicate check-in call.
  final bool skipCheckIn;

  /// Dùng API mới để load session (lấy từ backend)
  final bool useApiSession;

  /// Lobby ID gốc — dùng để navigate ngược lại LobbyPage.
  final String? lobbyId;

  const InGameSessionPage({
    super.key,
    required this.bookingId,
    this.cafeName,
    this.gameName,
    this.tableNumber,
    this.skipCheckIn = false,
    this.useApiSession = true,
    this.lobbyId,
  });

  @override
  State<InGameSessionPage> createState() => _InGameSessionPageState();
}

class _InGameSessionPageState extends State<InGameSessionPage> {
  /// Cubit dùng trong scope page này. Lấy từ `BlocProvider` cha (route
  /// generator `lobbyRouteGenerator` wrap BlocProvider quanh page).
  late final InGameCubit _inGameCubit;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _inGameCubit = context.read<InGameCubit>();

    // Trigger load session ngay lần đầu mount.
    if (!_initialized) {
      _initialized = true;
      if (widget.skipCheckIn) {
        // Dùng API mới để load session
        _inGameCubit.loadCurrentSession();
      } else {
        // Vẫn gọi checkIn trước (legacy) rồi load session
        _inGameCubit.checkIn(widget.bookingId);
      }
    }
  }

  bool _initialized = false;

  /// Cờ đánh dấu đã start polling session hay chưa. Tránh gọi
  /// `startSessionPolling()` nhiều lần khi state phát ra liên tục
  /// (vd: mỗi tick timer → state mới → re-enter listener).
  bool _pollingStarted = false;

  @override
  void dispose() {
    // Dừng background polling khi page bị dispose — tránh Timer chạy
    // mồ côi gọi API trong khi user đã back về lobby.
    _inGameCubit.stopSessionPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<InGameCubit, InGameState>(
      listener: (context, state) {
        // (Reload button đã ẩn tạm thời nên không cần reset
        // `_isReloading` ở đây nữa.)
        if (state is InGameCheckoutComplete) {
          // POS thanh toán xong → mở màn đánh giá Karma (real API).
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => LobbyRatingPage(
                lobbyId: widget.lobbyId ?? '',
              ),
            ),
          );
        }
        if (state is InGameSessionEnded) {
          // Map `onRateNow` / `onVoteNoShow` / `onLater` về cùng màn đánh
          // giá Karma — backend mới không còn tách no-show voting riêng,
          // thay vào đó tag NoShow nằm trong availableTags[].
          void goRating() {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => LobbyRatingPage(
                  lobbyId: widget.lobbyId ?? '',
                ),
              ),
            );
          }

          SessionEndedNotificationDialog.show(
            context: context,
            totalDuration: state.totalDuration,
            onRateNow: goRating,
            onVoteNoShow: goRating,
            onLater: goRating,
          );
        }
        if (state is InGameExtensionRequested) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.extensionRequest.isApproved
                  ? 'Yêu cầu gia hạn đã được duyệt!'
                  : 'Đã gửi yêu cầu gia hạn, đang chờ duyệt...'),
              backgroundColor: AppColors.success,
            ),
          );
        }
        if (state is InGamePaymentSuccess) {
          _showPaymentSuccessDialog(context, state);
        }
        if (state is InGamePaymentFailure) {
          _showPaymentFailureDialog(context, state);
        }

        // ─── Polling lifecycle ────────────────────────────────────
        // Bắt đầu background-poll khi session load thành công. Mục tiêu
        // là nhận update từ POS (staff check-out, mở phiên tính tiền,
        // manual confirm thanh toán) mà player không phải out/vào page.
        //
        // Chỉ bắt đầu 1 lần (sau load đầu tiên) — sau đó `cubit` tự
        // dừng khi `session.isPaid == true` hoặc khi user thoát trang.
        if (state is InGamePlayerSessionLoaded) {
          if (!_pollingStarted && mounted) {
            _pollingStarted = true;
            _inGameCubit.startSessionPolling();
          }
          // Stop ngay khi session đã paid — cubit tự dừng trong
          // timer callback nhưng gọi explicit từ page để settle UI
          // nhanh hơn (không cần đợi tới tick kế tiếp).
          if (state.session.isPaid && _pollingStarted) {
            _inGameCubit.stopSessionPolling();
          }
        }
      },
      builder: (context, state) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) {
              _showExitConfirmation(context);
            }
          },
          child: Scaffold(
            body: Stack(
              children: [
                _buildBody(context, state),
                if (state is InGameCheckingInventory ||
                    state is InGameExtending ||
                    state is InGamePaymentProcessing)
                  const InventoryCheckingOverlay(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, InGameState state) {
    // Loading state
    if (state is InGameLoading) {
      return _buildLoadingView(context);
    }

    // No active session
    if (state is InGameNoActiveSession) {
      return _buildNoSessionView(context);
    }

    // Failure state
    if (state is InGameFailure) {
      return _buildErrorView(context, state.message);
    }

    // Player session loaded from API
    if (state is InGamePlayerSessionLoaded) {
      return _buildPlayerSessionView(context, state);
    }

    // Extension in progress
    if (state is InGameExtending) {
      return _buildPlayerSessionView(
        context,
        InGamePlayerSessionLoaded(
          session: state.session,
          currentDuration: state.currentDuration,
        ),
        isExtending: true,
      );
    }

    // Payment processing
    if (state is InGamePaymentProcessing) {
      return _buildPlayerSessionView(
        context,
        InGamePlayerSessionLoaded(
          session: state.session,
          currentDuration: state.currentDuration,
        ),
        isProcessingPayment: true,
      );
    }

    // Legacy states
    if (state is InGameSessionActive) {
      return _buildLegacySessionView(context, state);
    }

    if (state is InGameCheckingInventory) {
      return _buildLegacySessionView(
        context,
        InGameSessionActive(
          session: state.session,
          currentDuration: Duration.zero,
        ),
      );
    }

    // ─── Split Bill States ────────────────────────────────────────────────
    // These states are emitted during split bill operations.
    // We keep showing the session view underneath the bottom sheet.

    if (state is InGameSplitBillLoading) {
      // Get session from cubit state if available
      final savedState = _inGameCubit.state;
      if (savedState is InGamePlayerSessionLoaded) {
        return _buildPlayerSessionView(
          context,
          InGamePlayerSessionLoaded(
            session: savedState.session,
            currentDuration: savedState.currentDuration,
          ),
        );
      }
      return _buildLoadingView(context);
    }

    if (state is InGameSplitBillError) {
      return _buildPlayerSessionView(
        context,
        InGamePlayerSessionLoaded(
          session: state.session,
          currentDuration: state.currentDuration,
        ),
      );
    }

    if (state is InGameSplitBillNotFound) {
      return _buildPlayerSessionView(
        context,
        InGamePlayerSessionLoaded(
          session: state.session,
          currentDuration: state.currentDuration,
        ),
      );
    }

    if (state is InGameSplitBillLoaded) {
      return _buildPlayerSessionView(
        context,
        InGamePlayerSessionLoaded(
          session: state.session,
          currentDuration: state.currentDuration,
        ),
      );
    }

    if (state is InGameSplitBillPolling) {
      return _buildPlayerSessionView(
        context,
        InGamePlayerSessionLoaded(
          session: state.session,
          currentDuration: state.currentDuration,
        ),
      );
    }

    if (state is InGameSplitBillPaymentSuccess) {
      return _buildPlayerSessionView(
        context,
        InGamePlayerSessionLoaded(
          session: state.session,
          currentDuration: state.currentDuration,
        ),
      );
    }

    // Default: show empty (should not happen in normal flow)
    return const SizedBox.shrink();
  }

  Widget _buildLoadingView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 4,
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Đang tải phiên chơi...',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSessionView(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.border,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.4),
                blurRadius: 0,
                offset: const Offset(5, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.warning,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.border,
                    width: 3,
                  ),
                ),
                child: const Icon(
                  Icons.hourglass_empty,
                  size: 48,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Không có phiên chơi',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Bạn chưa check-in tại quán.\nVui lòng đợi staff quét QR để bắt đầu phiên chơi.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _NeoFilledButton(
                label: 'Làm mới',
                icon: Icons.refresh,
                color: AppColors.primary,
                onPressed: () => _inGameCubit.loadCurrentSession(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.border,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.4),
                blurRadius: 0,
                offset: const Offset(5, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.border,
                    width: 3,
                  ),
                ),
                child: const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              _NeoFilledButton(
                label: 'Thử lại',
                icon: Icons.refresh,
                color: AppColors.primary,
                onPressed: () => _inGameCubit.loadCurrentSession(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerSessionView(
    BuildContext context,
    InGamePlayerSessionLoaded state, {
    bool isExtending = false,
    bool isProcessingPayment = false,
  }) {
    final session = state.session;
    final currentDuration = state.currentDuration;

    return SafeArea(
      child: Column(
        children: [
          // Header gradient
          _buildPlayerSessionHeader(context, session, currentDuration),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.md),

                  // Session Status Card
                  _buildSessionStatusCard(context, session),
                  const SizedBox(height: AppSpacing.md),

                  // Cost Estimate Card
                  _buildCostEstimateCard(context, session),
                  const SizedBox(height: AppSpacing.md),

                  // Extension Request Status
                  if (session.lastExtensionRequest != null)
                    _buildExtensionStatusCard(context, session),
                  const SizedBox(height: AppSpacing.md),

                  // Game Info Card
                  _buildGameInfoCard(context, session),
                ],
              ),
            ),
          ),

          // Bottom Action
          _buildPlayerSessionBottomActions(
            context,
            session,
            currentDuration,
            isExtending: isExtending,
            isProcessingPayment: isProcessingPayment,
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerSessionHeader(
    BuildContext context,
    PlayerSessionEntity session,
    Duration currentDuration,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hours = currentDuration.inHours;
    final minutes = currentDuration.inMinutes % 60;
    final seconds = currentDuration.inSeconds % 60;

    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.4),
            blurRadius: 0,
            offset: const Offset(5, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.store,
              color: AppColors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.cafeName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.extension, size: 14, color: AppColors.white),
                    const SizedBox(width: 4),
                    Text(
                      session.gameName,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: AppColors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Timer display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                const Icon(Icons.timer, size: 16, color: AppColors.white),
                const SizedBox(height: 2),
                Text(
                  '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: AppColors.white,
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

  Widget _buildSessionStatusCard(BuildContext context, PlayerSessionEntity session) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (session.sessionStatus) {
      case SessionStatus.active:
        statusColor = AppColors.success;
        statusText = 'Đang chơi';
        statusIcon = Icons.play_circle;
        break;
      case SessionStatus.checking:
        statusColor = AppColors.warning;
        statusText = 'Đang kiểm tra';
        statusIcon = Icons.inventory_2;
        break;
      case SessionStatus.unpaid:
        statusColor = AppColors.error;
        statusText = 'Chưa thanh toán';
        statusIcon = Icons.payment;
        break;
      case SessionStatus.paid:
        statusColor = AppColors.primary;
        statusText = 'Đã thanh toán';
        statusIcon = Icons.check_circle;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.4),
            blurRadius: 0,
            offset: const Offset(4, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.border,
                width: 2,
              ),
            ),
            child: Icon(statusIcon, color: AppColors.white, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${session.totalGroupMembers} người trong nhóm',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (session.isPaid)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.success,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border, width: 2),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check, size: 14, color: AppColors.white),
                  SizedBox(width: 4),
                  Text(
                    'Đã thanh toán',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCostEstimateCard(BuildContext context, PlayerSessionEntity session) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cost = session.costEstimate;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: 2.5,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.border,
                    width: 2,
                  ),
                ),
                child: const Icon(Icons.attach_money, size: 16, color: AppColors.white),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'CHI PHÍ ƯỚC TÍNH',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 1.0,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCostItem(context, 'Thời gian', '${cost.baseMinutes} phút'),
            ],
          ),
          const Divider(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCostItem(context, 'Tạm tính', cost.formattedSubtotal),
              if (cost.hasPenalty)
                _buildCostItem(context, 'Phí trễ', cost.formattedPenalty),
            ],
          ),
          if (cost.hasDepositApplied) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCostItem(context, 'Đặt cọc đã áp dụng', '-${cost.formattedDepositApplied}'),
              ],
            ),
          ],
          const Divider(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TỔNG CỘNG',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: session.canBePaid ? AppColors.primary : AppColors.success,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border, width: 2),
                ),
                child: Text(
                  cost.formattedTotalDue,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: AppColors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCostItem(BuildContext context, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 11,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildExtensionStatusCard(BuildContext context, PlayerSessionEntity session) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ext = session.lastExtensionRequest!;

    Color statusColor;
    IconData statusIcon;

    switch (ext.status) {
      case ExtensionStatus.pending:
        statusColor = AppColors.warning;
        statusIcon = Icons.hourglass_empty;
        break;
      case ExtensionStatus.approved:
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle;
        break;
      case ExtensionStatus.rejected:
        statusColor = AppColors.error;
        statusIcon = Icons.cancel;
        break;
      case ExtensionStatus.expired:
        statusColor = AppColors.textSecondary;
        statusIcon = Icons.timer_off;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.4),
            blurRadius: 0,
            offset: const Offset(4, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border, width: 2),
            ),
            child: Icon(statusIcon, color: AppColors.white, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Yêu cầu gia hạn: +${ext.requestedMinutes} phút',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  ext.statusText,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: statusColor,
                  ),
                ),
                if (ext.isRejected && ext.rejectionReason != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Lý do: ${ext.rejectionReason}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      color: AppColors.error,
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

  Widget _buildGameInfoCard(BuildContext context, PlayerSessionEntity session) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.4),
            blurRadius: 0,
            offset: const Offset(4, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.border,
                width: 2,
              ),
            ),
            child: const Icon(Icons.extension, color: AppColors.white, size: 28),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.gameName,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${session.totalGroupMembers} người chơi',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerSessionBottomActions(
    BuildContext context,
    PlayerSessionEntity session,
    Duration currentDuration, {
    bool isExtending = false,
    bool isProcessingPayment = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.border,
            width: 3,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.3),
            blurRadius: 0,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          // Wrap trong scroll để khi session có nhiều action (canBePaid
          // + !isPaid + lobbyId) không bị RenderFlex overflow ở màn hình
          // nhỏ. Bottom bar vẫn anchor bottom — padding dưới SafeArea
          // giữ action cuối ("Quay về lịch hẹn") không bị nav bar che.
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Column(
            children: [
            // Loading indicator for extending or payment
            if (isExtending || isProcessingPayment)
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      isExtending ? 'Đang gửi yêu cầu gia hạn...' : 'Đang xử lý thanh toán...',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),

            // Extend button
            if (session.canBeExtended && !isExtending && !isProcessingPayment)
              _NeoOutlineButton(
                label: 'Gia hạn thêm',
                icon: Icons.add_alarm,
                color: AppColors.secondary,
                onPressed: () => _showExtendBottomSheet(context, session),
              ),

            if (session.canBeExtended && !isExtending && !isProcessingPayment)
              const SizedBox(height: AppSpacing.sm),

            // ─── Thanh toán BVC ───
            // Button thanh toán chính - hiển thị khi session ở trạng thái Unpaid
            if (session.canBePaid && !isProcessingPayment)
              BlocBuilder<WalletCubit, WalletState>(
                builder: (context, walletState) {
                  final balance = walletState is WalletLoaded
                      ? walletState.wallet.availableBalance
                      : 0;
                  // `balance` là số BVC (int), `totalDue` là VND (double).
                  // So sánh phải cùng đơn vị → convert totalDue sang BVC (ceil).
                  final requiredBvc = (session.costEstimate.totalDue / 1000).ceil();
                  final hasEnoughBalance = balance >= requiredBvc;

                  return _NeoFilledButton(
                    label: hasEnoughBalance
                        ? 'Thanh toán ${session.costEstimate.formattedTotalDue}'
                        : 'Số dư không đủ ($balance BVC)',
                    icon: Icons.account_balance_wallet,
                    color: hasEnoughBalance ? AppColors.success : AppColors.textSecondary,
                    onPressed: hasEnoughBalance
                        ? () => _confirmPayment(context, session)
                        : () => _showInsufficientBalanceDialog(context, balance, session),
                  );
                },
              ),

            // Thông báo khi session chưa sẵn sàng thanh toán
            // (Staff chưa gọi tính tiền từ POS)
            if (!session.canBePaid && !session.isPaid && !isProcessingPayment)
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.info, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Đang chờ staff tính tiền. Bạn có thể gia hạn thêm giờ chơi.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.info,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // ─── Chia Bill (Optional) ───
            // Nút Chia Bill - chỉ hiển thị khi session có thể thanh toán
            // Đây là tính năng optional, không bắt buộc
            if (session.canBePaid && !isProcessingPayment) ...[
              const SizedBox(height: AppSpacing.sm),
              _NeoOutlineButton(
                label: 'Hoặc chia bill (QR)',
                icon: Icons.qr_code,
                color: AppColors.textSecondary,
                onPressed: () => _showSplitBillBottomSheet(context),
              ),
            ],

            // (Button "Tải lại" đã được ẩn tạm thời — sẽ bật lại sau khi
            // staff check-out flow hoàn thiện.)
            //
            // Back to reservation + back to lobby buttons (cùng hàng)
            Row(
              children: [
                if (widget.lobbyId != null) ...[
                  Expanded(
                    child: _NeoOutlineButton(
                      label: 'Vào phòng chờ',
                      icon: Icons.meeting_room,
                      color: AppColors.primary,
                      onPressed: () => _navigateToLobby(context),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  child: _NeoOutlineButton(
                    label: 'Quay về lịch hẹn',
                    icon: Icons.calendar_today,
                    color: AppColors.textSecondary,
                    onPressed: () => _navigateToReservationDetail(context),
                  ),
                ),
              ],
            ),
          ],
          ),
        ),
      ),
    );
  }

  void _showExtendBottomSheet(BuildContext context, PlayerSessionEntity session) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ratePerMinute = session.costEstimate.ratePerMinute;

    final extensionOptions = [
      {'minutes': 15, 'cost': ratePerMinute * 15},
      {'minutes': 30, 'cost': ratePerMinute * 30},
      {'minutes': 60, 'cost': ratePerMinute * 60},
      {'minutes': 120, 'cost': ratePerMinute * 120},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.border,
            width: 3,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border, width: 2),
                  ),
                  child: const Icon(Icons.add_alarm, color: AppColors.white, size: 24),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  'Gia hạn thêm thời gian',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Chọn số phút bạn muốn gia hạn. Yêu cầu sẽ được gửi đến staff để duyệt.',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ...extensionOptions.map((option) {
              final minutes = option['minutes'] as int;

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      _inGameCubit.extendSession(minutes);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.backgroundDark : AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : AppColors.border,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: AppColors.secondary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${minutes}p',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  minutes >= 60 ? '$minutes phút (${minutes ~/ 60}h)' : '$minutes phút',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  'Cộng thêm $minutes phút vào thời gian chơi',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: AppSpacing.md),
            _NeoOutlineButton(
              label: 'Hủy',
              icon: Icons.close,
              color: AppColors.textSecondary,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmPayment(BuildContext context, PlayerSessionEntity session) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.border,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.4),
                blurRadius: 0,
                offset: const Offset(6, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border, width: 3),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  size: 40,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Xác nhận thanh toán',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Bạn có chắc muốn thanh toán ${session.costEstimate.formattedTotalDue} bằng BVC?',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: _NeoOutlineButton(
                      label: 'Hủy',
                      icon: Icons.close,
                      color: AppColors.textSecondary,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _NeoFilledButton(
                      label: 'Thanh toán',
                      icon: Icons.check,
                      color: AppColors.success,
                      onPressed: () {
                        Navigator.pop(context);
                        _inGameCubit.payWithBvc();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInsufficientBalanceDialog(BuildContext context, int currentBalance, PlayerSessionEntity session) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final required = session.costEstimate.totalDue;
    final needed = required - currentBalance;
    // Dùng ceil để luôn hiển thị số BVC tối thiểu cần có.
    final neededBvc = (needed / 1000).ceil();
    final requiredBvc = (required / 1000).ceil();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.border,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.4),
                blurRadius: 0,
                offset: const Offset(6, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.warning,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border, width: 3),
                ),
                child: const Icon(
                  Icons.warning_amber,
                  size: 40,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Số dư BVC không đủ',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Bạn cần thêm $neededBvc BVC để thanh toán.\nSố dư hiện tại: $currentBalance BVC\nCần thanh toán: $requiredBvc BVC',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _NeoFilledButton(
                label: 'Nạp thêm BVC',
                icon: Icons.add_card,
                color: AppColors.primary,
                onPressed: () {
                  Navigator.pop(context);
                  _navigateToTopUp(context);
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              _NeoOutlineButton(
                label: 'Đóng',
                icon: Icons.close,
                color: AppColors.textSecondary,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToReservationDetail(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ReservationDetailPage(
          bookingId: widget.bookingId,
        ),
      ),
    );
  }

  void _navigateToLobby(BuildContext context) {
    final lobbyCubit = getIt<LobbyCubit>();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => LobbyPage(
          lobbyId: widget.lobbyId!,
          lobbyCubit: lobbyCubit,
        ),
      ),
    );
  }

  void _showPaymentSuccessDialog(BuildContext context, InGamePaymentSuccess state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final payment = state.paymentResult;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.border,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.4),
                blurRadius: 0,
                offset: const Offset(6, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border, width: 3),
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: 48,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Thanh toán thành công!',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.backgroundDark : AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.border,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    _buildInvoiceRow('Đã thanh toán', payment.formattedBvcDeducted),
                    const Divider(),
                    _buildInvoiceRow('Số dư còn lại', payment.formattedRemainingBalance),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _NeoFilledButton(
                label: 'Hoàn tất',
                icon: Icons.check,
                color: AppColors.success,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentFailureDialog(BuildContext context, InGamePaymentFailure state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.border,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.4),
                blurRadius: 0,
                offset: const Offset(6, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border, width: 3),
                ),
                child: const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Thanh toán thất bại',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                state.message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _NeoFilledButton(
                label: 'Đóng',
                icon: Icons.close,
                color: AppColors.primary,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Legacy session view for older InGameSessionActive state
  Widget _buildLegacySessionView(BuildContext context, InGameSessionActive state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final session = state.session;

    return SafeArea(
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(AppSpacing.md),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryLight],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.border,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.4),
                  blurRadius: 0,
                  offset: const Offset(5, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.white.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  child: const Icon(Icons.store, color: AppColors.white, size: 24),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.cafeName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.table_restaurant, size: 14, color: AppColors.white),
                          const SizedBox(width: 4),
                          Text(
                            'Bàn số ${session.tableNumber}',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: AppColors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PlayDurationTimer(startTime: session.startTime, isRunning: true),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : AppColors.border,
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.black.withValues(alpha: 0.4),
                          blurRadius: 0,
                          offset: const Offset(4, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark ? AppColors.borderDark : AppColors.border,
                              width: 2,
                            ),
                          ),
                          child: const Icon(Icons.extension, color: AppColors.white, size: 28),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                session.gameName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${session.players.length} người chơi',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surface,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.border,
                  width: 3,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.3),
                  blurRadius: 0,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  _NeoOutlineButton(
                    label: 'Mock: Kết thúc phiên (POS)',
                    icon: Icons.stop_circle_outlined,
                    color: AppColors.warning,
                    onPressed: () => _inGameCubit.endSession(),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _NeoFilledButton(
                    label: 'Yêu cầu tính tiền',
                    icon: Icons.shopping_cart_checkout,
                    color: AppColors.primary,
                    onPressed: () => _inGameCubit.requestCheckout(session.sessionId),
                    expand: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showExitConfirmation(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(AppSpacing.md),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.border,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.4),
                blurRadius: 0,
                offset: const Offset(6, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.warning,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border, width: 3),
                ),
                child: const Icon(Icons.warning_amber, size: 32, color: AppColors.black),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Xác nhận rời đi',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Bạn đang trong phiên chơi. Bạn có chắc muốn rời khỏi trang này?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: _NeoOutlineButton(
                      label: 'Hủy',
                      icon: Icons.cancel_outlined,
                      color: AppColors.textSecondary,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _NeoFilledButton(
                      label: 'Ở lại',
                      icon: Icons.check,
                      color: AppColors.primary,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Split Bill Methods ────────────────────────────────────────────────────

  /// Mở BottomSheet để xem thông tin Split Bill
  void _showSplitBillBottomSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Lưu lại state hiện tại trước khi mở split bill
    final currentState = _inGameCubit.state;
    PlayerSessionEntity? savedSession;

    if (currentState is InGamePlayerSessionLoaded) {
      savedSession = currentState.session;
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      builder: (bottomSheetContext) => BlocProvider.value(
        value: _inGameCubit,
        child: BlocBuilder<InGameCubit, InGameState>(
          builder: (context, state) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.border,
                  width: 3,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Title
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border, width: 2),
                        ),
                        child: const Icon(
                          Icons.receipt_long,
                          color: AppColors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CHIA BILL',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Thanh toán cá nhân theo phần của bạn',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(AppIcons.close),
                        onPressed: () {
                          // Khôi phục lại state session trước khi đóng
                          if (savedSession != null) {
                            _inGameCubit.restoreSessionAfterSplitBill();
                          }
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Content based on state
                  Flexible(
                    child: _buildSplitBillContent(context, state),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ).whenComplete(() {
      // Khi bottom sheet đóng hoàn toàn, khôi phục lại state
      if (savedSession != null) {
        _inGameCubit.restoreSessionAfterSplitBill();
      }
    });

    // Trigger load split bill
    _inGameCubit.openSplitBill();
  }

  Widget _buildSplitBillContent(BuildContext context, InGameState state) {
    if (state is InGameSplitBillLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 3,
              ),
              SizedBox(height: AppSpacing.md),
              Text(
                'Đang tải thông tin chia bill...',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (state is InGameSplitBillError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: NeoBrutalismTheme.autoBox(
                  context,
                  backgroundColor: AppColors.error.withValues(alpha: 0.1),
                  borderColor: AppColors.error,
                  bold: true,
                  borderRadius: 16,
                  shadowColor: AppColors.error.withValues(alpha: 0.3),
                ),
                child: const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                state.message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _NeoOutlineButton(
                    label: 'Đóng',
                    icon: AppIcons.close,
                    color: AppColors.textSecondary,
                    onPressed: () {
                      _inGameCubit.restoreSessionAfterSplitBill();
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _NeoFilledButton(
                    label: 'Thử lại',
                    icon: AppIcons.refresh,
                    color: AppColors.primary,
                    onPressed: () => _inGameCubit.refreshSplitBill(),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (state is InGameSplitBillNotFound) {
      final session = state.session;

      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: NeoBrutalismTheme.autoBox(
                  context,
                  backgroundColor: AppColors.info.withValues(alpha: 0.1),
                  borderColor: AppColors.info,
                  bold: true,
                  borderRadius: 16,
                  shadowColor: AppColors.info.withValues(alpha: 0.3),
                ),
                child: const Icon(
                  AppIcons.info,
                  size: 48,
                  color: AppColors.info,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'CHƯA CÓ THÔNG TIN CHIA BILL',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Staff chưa tạo QR thanh toán riêng cho nhóm.\nVui lòng đợi staff xử lý.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),

              // Nếu session có thể thanh toán, hiển thị option trả hết
              if (session.canBePaid) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: NeoBrutalismTheme.autoBox(
                    context,
                    backgroundColor: AppColors.success.withValues(alpha: 0.10),
                    borderColor: AppColors.success,
                    bold: true,
                    borderRadius: 12,
                    shadowColor: AppColors.success.withValues(alpha: 0.25),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'HOẶC BẠN CÓ THỂ TRẢ HẾT',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          letterSpacing: 0.8,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        session.costEstimate.formattedTotalDue,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        '(Thay mặt tất cả thành viên)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: _NeoOutlineButton(
                      label: 'Đóng',
                      icon: AppIcons.close,
                      color: AppColors.textSecondary,
                      onPressed: () {
                        _inGameCubit.restoreSessionAfterSplitBill();
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  if (session.canBePaid) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _NeoFilledButton(
                        label: 'Trả hết',
                        icon: AppIcons.money,
                        color: AppColors.success,
                        onPressed: () {
                          Navigator.pop(context); // Đóng bottom sheet
                          _inGameCubit.restoreSessionAfterSplitBill();
                          _confirmPayment(context, session);
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (state is InGameSplitBillLoaded || state is InGameSplitBillPolling) {
      final members = state is InGameSplitBillLoaded
          ? state.members
          : <MemberPaymentInfo>[];
      final currentUserPayment = state is InGameSplitBillLoaded
          ? state.currentUserPayment
          : state is InGameSplitBillPolling
              ? state.currentUserPayment
              : null;

      // Tính progress (paid/total) cho header member list.
      final paidCount = members.where((m) => m.isPaid).length;
      final totalCount = members.length;
      final allPaid = totalCount > 0 && paidCount == totalCount;

      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Session info card (cafe + game) ─────────────────────
            if (state is InGameSplitBillLoaded) ...[
              _buildSessionInfoCard(context, state.session),
              const SizedBox(height: AppSpacing.md),
            ],

            // ── Thông tin thanh toán của user hiện tại ─────────────
            if (currentUserPayment != null) ...[
              _buildCurrentUserPaymentCard(context, currentUserPayment),
              const SizedBox(height: AppSpacing.md),
            ],

            // ── Member list ─────────────────────────────────────────
            if (members.isNotEmpty) ...[
              // Header với progress
              _buildMemberListHeader(
                context,
                paidCount: paidCount,
                totalCount: totalCount,
                allPaid: allPaid,
              ),
              const SizedBox(height: AppSpacing.sm),
              ...members.map((m) => _buildMemberPaymentItem(context, m)),
            ],

            // ── Polling indicator ───────────────────────────────────
            if (state is InGameSplitBillPolling) ...[
              const SizedBox(height: AppSpacing.md),
              _buildPollingIndicator(context, state),
            ],

            const SizedBox(height: AppSpacing.lg),

            // ── Action buttons ──────────────────────────────────────
            _buildSplitBillActions(context, state, currentUserPayment),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  /// Header cho danh sách member — hiển thị progress (X/Y đã trả).
  /// Khi tất cả đã trả → highlight success color.
  Widget _buildMemberListHeader(
    BuildContext context, {
    required int paidCount,
    required int totalCount,
    required bool allPaid,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = allPaid ? AppColors.success : AppColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: NeoBrutalismTheme.autoBox(
        context,
        backgroundColor: accentColor.withValues(alpha: isDark ? 0.12 : 0.08),
        borderColor: accentColor,
        bold: true,
        borderRadius: 10,
        shadowColor: accentColor.withValues(alpha: 0.25),
      ),
      child: Row(
        children: [
          Icon(
            allPaid ? AppIcons.check : AppIcons.users,
            color: accentColor,
            size: 18,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Thành viên đã thanh toán',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13,
                letterSpacing: 0.5,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
          ),
          // Progress badge: X/Y
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.border, width: 1.5),
            ),
            child: Text(
              '$paidCount / $totalCount',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13,
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionInfoCard(BuildContext context, PlayerSessionEntity session) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: NeoBrutalismTheme.autoBox(
        context,
        backgroundColor: AppColors.secondary.withValues(alpha: isDark ? 0.15 : 0.10),
        borderColor: AppColors.secondary,
        bold: true,
        borderRadius: 12,
        shadowColor: AppColors.secondary.withValues(alpha: 0.25),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: const BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            child: const Icon(
              AppIcons.cafe,
              color: AppColors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.cafeName,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      AppIcons.boardGame,
                      size: 12,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        session.gameName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
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

  Widget _buildCurrentUserPaymentCard(BuildContext context, MemberPaymentInfo payment) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ── Case A: Đã thanh toán xong ─────────────────────────────────────
    if (payment.isPaid) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: NeoBrutalismTheme.autoBox(
          context,
          backgroundColor: AppColors.success.withValues(alpha: 0.12),
          borderColor: AppColors.success,
          bold: true,
          borderRadius: 14,
          shadowColor: AppColors.success.withValues(alpha: 0.25),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
              child: const Icon(AppIcons.check, color: AppColors.white, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'BẠN ĐÃ THANH TOÁN!',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: 0.5,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    payment.formattedAmountVnd,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '= ${payment.formattedAmountBvc}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // ── Case B: Chưa thanh toán ────────────────────────────────────────
    final hasQr = payment.hasQr;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: NeoBrutalismTheme.autoBox(
        context,
        backgroundColor: isDark
            ? AppColors.warning.withValues(alpha: 0.08)
            : AppColors.warning.withValues(alpha: 0.10),
        borderColor: AppColors.warning,
        bold: true,
        borderRadius: 14,
        shadowColor: AppColors.warning.withValues(alpha: 0.25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: icon + label + amount
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: const BoxDecoration(
                  color: AppColors.warning,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  hasQr ? AppIcons.qrCode : AppIcons.pending,
                  color: AppColors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PHẦN CỦA BẠN',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        letterSpacing: 1.0,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      payment.formattedAmountVnd,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.warning,
                      ),
                    ),
                    Text(
                      '= ${payment.formattedAmountBvc}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // QR Code section (chỉ hiển thị khi staff đã tạo QR)
          if (hasQr) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: NeoBrutalismTheme.brutalBox(
                backgroundColor: AppColors.white,
                borderColor: AppColors.border,
                bold: true,
                borderRadius: 12,
                shadowColor: AppColors.black.withValues(alpha: 0.4),
              ),
              child: Column(
                children: [
                  QrNetworkImage(
                    qrUrl: payment.qrUrl ?? '',
                    paymentUrl: '',
                    qrImageBase64: payment.qrImageBase64,
                    size: 220,
                    backgroundColor: AppColors.white,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.info.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(AppIcons.info, size: 16, color: AppColors.info),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'Mở app ngân hàng → Quét QR để thanh toán',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.info,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Khi staff chưa tạo QR
          if (!hasQr) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.info.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(AppIcons.pending, size: 18, color: AppColors.info),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Đang chờ staff tạo mã QR thanh toán cho bạn...',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.info,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMemberPaymentItem(BuildContext context, MemberPaymentInfo member) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Status chip theo neo-brutalism (design_system.md §12.2).
    final (chipBg, chipFg, chipIcon, chipLabel) = member.isPaid
        ? (
            AppColors.success,
            AppColors.white,
            AppIcons.check,
            member.paymentStatus == PaymentStatus.paidCash
                ? 'ĐÃ TRẢ (TIỀN MẶT)'
                : 'ĐÃ TRẢ (QR)',
          )
        : (
            AppColors.warning,
            AppColors.white,
            AppIcons.pending,
            'ĐANG CHỜ',
          );

    // Initials cho avatar fallback (design_system.md §12.5).
    final initials = (member.displayName ?? 'U').isNotEmpty
        ? (member.displayName ?? 'U')[0].toUpperCase()
        : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: NeoBrutalismTheme.autoBox(
        context,
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderColor: isDark ? AppColors.borderDark : AppColors.border,
        bold: true,
        borderRadius: 12,
        shadowColor: AppColors.black.withValues(alpha: 0.3),
      ),
      child: Row(
        children: [
          // ── Avatar với neo-brutalism border ────────────────────────
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: member.isCurrentUser
                    ? AppColors.primary
                    : (isDark ? AppColors.borderDark : AppColors.border),
                width: member.isCurrentUser ? 3 : 2,
              ),
            ),
            child: ClipOval(
              child: member.avatarUrl != null && member.avatarUrl!.isNotEmpty
                  ? Image.network(
                      member.avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Center(
                        child: Text(
                          initials,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        initials,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // ── Name + amount ──────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        member.displayName ?? 'Thành viên',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (member.isCurrentUser) ...[
                      const SizedBox(width: AppSpacing.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: AppColors.border,
                            width: 1.5,
                          ),
                        ),
                        child: const Text(
                          'BẠN',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  member.formattedAmountVnd,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // ── Status chip ────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xxs,
            ),
            decoration: NeoBrutalismTheme.brutalBox(
              backgroundColor: chipBg,
              borderColor: AppColors.border,
              bold: true,
              borderRadius: 8,
              shadowColor: chipBg.withValues(alpha: 0.4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(chipIcon, size: 12, color: chipFg),
                const SizedBox(width: 4),
                Text(
                  chipLabel,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    color: chipFg,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPollingIndicator(BuildContext context, InGameSplitBillPolling state) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: NeoBrutalismTheme.autoBox(
        context,
        backgroundColor: AppColors.primary.withValues(alpha: 0.10),
        borderColor: AppColors.primary,
        bold: true,
        borderRadius: 12,
        shadowColor: AppColors.primary.withValues(alpha: 0.25),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Đang chờ thanh toán...',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  'Tự động kiểm tra mỗi 5 giây',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(AppIcons.close, color: AppColors.textSecondary),
            onPressed: () {
              _inGameCubit.stopQrPaymentPolling();
              _inGameCubit.restoreSessionAfterSplitBill();
              Navigator.pop(context);
            },
            tooltip: 'Hủy chờ',
          ),
        ],
      ),
    );
  }

  Widget _buildSplitBillActions(
    BuildContext context,
    InGameState state,
    MemberPaymentInfo? currentUserPayment,
  ) {
    if (state is InGameSplitBillPaymentSuccess) {
      // ── Case: Player đã thanh toán xong phần của mình ──────────────
      // Theo yêu cầu: "Player pay xong thì phiên chơi hoàn tất, cái đó
      // chỉ cần xử lý UI, backend xử lý phần hệ thống."
      //
      // → Show success card + 2 action:
      //   1. "Đánh giá ngay" → navigate LobbyRatingPage (giống flow
      //      pay-with-BVC hiện tại).
      //   2. "Đóng" → user muốn xem lại trước khi rate.
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: NeoBrutalismTheme.autoBox(
              context,
              backgroundColor: AppColors.success.withValues(alpha: 0.12),
              borderColor: AppColors.success,
              bold: true,
              borderRadius: 14,
              shadowColor: AppColors.success.withValues(alpha: 0.25),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: AppColors.success, size: 28),
                SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    'BẠN ĐÃ THANH TOÁN THÀNH CÔNG!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      color: AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Nếu có lobbyId → cho đi đánh giá luôn
          if (widget.lobbyId != null && widget.lobbyId!.isNotEmpty) ...[
            _NeoFilledButton(
              label: 'Đánh giá ngay',
              icon: AppIcons.rating,
              color: AppColors.primary,
              expand: true,
              onPressed: () {
                final lobbyId = widget.lobbyId!;
                _inGameCubit.restoreSessionAfterSplitBill();
                Navigator.pop(context); // Đóng bottom sheet
                // Navigate sang LobbyRatingPage thay thế page hiện tại.
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LobbyRatingPage(lobbyId: lobbyId),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            _NeoOutlineButton(
              label: 'Để sau',
              icon: AppIcons.close,
              color: AppColors.textSecondary,
              onPressed: () {
                _inGameCubit.restoreSessionAfterSplitBill();
                Navigator.pop(context);
              },
            ),
          ] else
            _NeoFilledButton(
              label: 'Hoàn tất',
              icon: AppIcons.check,
              color: AppColors.success,
              expand: true,
              onPressed: () {
                _inGameCubit.restoreSessionAfterSplitBill();
                Navigator.pop(context);
              },
            ),
        ],
      );
    }

    if (currentUserPayment != null && !currentUserPayment.isPaid) {
      // ── Case: Member chưa thanh toán ──────────────────────────────
      // Chỉ enable button "Quét QR" khi staff đã tạo QR cho member này
      // (có qrImageBase64 hoặc qrUrl). Nếu chưa có → disable + hint
      // "đang chờ staff".
      final hasQrReady = currentUserPayment.hasQr;
      final buttonLabel = !hasQrReady
          ? 'Đang chờ staff tạo QR'
          : (currentUserPayment.hasPendingQr
              ? 'Đang theo dõi thanh toán...'
              : 'Bắt đầu chờ thanh toán');
      final buttonIcon =
          !hasQrReady ? AppIcons.pending : AppIcons.qrScan;
      final buttonColor = hasQrReady ? AppColors.primary : AppColors.textSecondary;

      return Row(
        children: [
          Expanded(
            child: _NeoOutlineButton(
              label: 'Đóng',
              icon: AppIcons.close,
              color: AppColors.textSecondary,
              onPressed: () {
                _inGameCubit.restoreSessionAfterSplitBill();
                Navigator.pop(context);
              },
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _NeoFilledButton(
              label: buttonLabel,
              icon: buttonIcon,
              color: buttonColor,
              onPressed: hasQrReady
                  ? () {
                      _inGameCubit.startQrPaymentPolling(currentUserPayment);
                    }
                  : null,
            ),
          ),
        ],
      );
    }

    // ── Default: Member đã paid hoặc không có currentUserPayment ──
    return _NeoFilledButton(
      label: 'Đóng',
      icon: AppIcons.close,
      color: AppColors.primary,
      expand: true,
      onPressed: () {
        _inGameCubit.restoreSessionAfterSplitBill();
        Navigator.pop(context);
      },
    );
  }

  void _navigateToTopUp(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const TopUpPage(),
      ),
    );
  }
}

/// Neo-brutalism filled button (used in page bottom).
class _NeoFilledButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;
  final bool expand;

  const _NeoFilledButton({
    required this.label,
    required this.icon,
    required this.color,
    this.onPressed,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 2.5),
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
          Icon(icon, size: 18, color: AppColors.white),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: expand ? SizedBox(width: double.infinity, child: child) : child,
      ),
    );
  }
}

/// Neo-brutalism outline button.
class _NeoOutlineButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final VoidCallback? onPressed;

  /// `true` → render spinner thay icon + thay label thành `loadingLabel`
  /// (mặc định = `label`). Khi user bấm, button không cho tap thêm
  /// lần nữa và hiển thị spinner feedback cho tới khi callback trả về.
  ///
  /// Nullable để tương thích với hot-reload cũ — nếu parent build lại
  /// trước khi default `false` được propagate, build method treat
  /// `null` là `false` (không error).
  final bool? isLoading;
  final String? loadingLabel;

  const _NeoOutlineButton({
    required this.label,
    required this.color,
    this.icon,
    this.onPressed,
    this.isLoading,
    this.loadingLabel,
  });

  @override
  Widget build(BuildContext context) {
    final loading = isLoading ?? false;
    final displayLabel = loading ? (loadingLabel ?? label) : label;
    final child = Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (loading) ...[
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: color,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
          ] else if (icon != null) ...[
            Icon(icon, size: 16, color: color),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            displayLabel,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
  }
}
