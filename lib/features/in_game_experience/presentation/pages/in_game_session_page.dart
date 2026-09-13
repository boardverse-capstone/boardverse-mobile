import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:boardverse/core/di/injection.dart';
import 'package:boardverse/core/theme/app_colors.dart';
import 'package:boardverse/core/theme/app_spacing.dart';
import 'package:boardverse/features/lobby_management/presentation/cubit/lobby_cubit.dart';
import 'package:boardverse/features/lobby_management/presentation/pages/lobby_page.dart';
import 'package:boardverse/features/lobby_management/presentation/pages/lobby_rating_page.dart';
import '../../../reservation/presentation/pages/reservation_detail_page.dart';
import '../../../wallet/presentation/cubit/wallet_cubit.dart';
import '../../../wallet/presentation/cubit/wallet_state.dart';
import '../../../wallet/presentation/pages/topup_page.dart';
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

  /// Cờ reload-in-progress. Set = true khi user bấm "Tải lại" trên
  /// bottom bar hoặc header → hiển thị spinner feedback trên button.
  /// Reset = false khi API trả về (dù success hay failure).
  bool _isReloading = false;

  /// Cờ đánh dấu đã start polling session hay chưa. Tránh gọi
  /// `startSessionPolling()` nhiều lần khi state phát ra liên tục
  /// (vd: mỗi tick reload → state mới → re-enter listener).
  bool _pollingStarted = false;

  /// Reload session data khi user bấm "Tải lại".
  ///
  /// Gọi `refreshSession()` (fetch API mà KHÔNG emit InGameLoading) để:
  ///   1. Staff check-out / mở phiên tính tiền → player tap "Tải lại"
  ///      → thấy thông tin mới nhất (trạng thái, chi phí, v.v.).
  ///   2. Không có full-screen loading → UI không bị blank.
  ///
  /// `_isReloading` được set = true ngay để hiển thị spinner feedback trên
  /// button "Tải lại". Reset về false trong BlocConsumer khi có state mới.
  Future<void> _onReload() async {
    if (_isReloading) return;
    setState(() => _isReloading = true);
    await _inGameCubit.refreshSession();
    if (!mounted) return;
    setState(() => _isReloading = false);
  }

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
        // Reset `_isReloading` khi cubit emit state mới sau khi
        // `refreshSession()` chạy xong (dù success hay failure) —
        // đảm bảo spinner trên button "Tải lại" biến mất.
        if (_isReloading) {
          // ignore: prefer-null-aware-operators — setState bên trong listener
          // là pattern hợp lệ: state đã đổi → rebuild để reflect flag.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() => _isReloading = false);
          });
        }
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
          final goRating = () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => LobbyRatingPage(
                lobbyId: widget.lobbyId ?? '',
              ),
            ),
          );
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
              _buildCostItem(context, 'Đơn giá', '${(cost.ratePerMinute / 1000).ceil()} BVC/p'),
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

            // ─── Reload (Manual Refresh) ─────────────────────────────
            // Nút "Tải lại" — cho player refresh dữ liệu phiên chơi thủ
            // công khi staff vừa check-out hoặc mở phiên tính tiền và
            // player muốn xem thông tin cập nhật ngay mà không cần pull.
            //
            // Hiển thị khi session chưa thanh toán (`!session.isPaid`).
            // Disable khi đang extending/payment để tránh xung đột.
            // Tap → gọi `inGameCubit.refreshSession()` (silent —
            // không emit InGameLoading) → UI update mượt khi state mới
            // về. Spinner feedback trên button trong khi chờ API.
            if (!session.isPaid && !isExtending && !isProcessingPayment) ...[
              const SizedBox(height: AppSpacing.sm),
              _NeoOutlineButton(
                label: 'Tải lại',
                loadingLabel: 'Đang tải...',
                icon: Icons.refresh,
                color: AppColors.info,
                isLoading: _isReloading,
                onPressed: _isReloading ? null : _onReload,
              ),
            ],

            // Back to reservation + back to lobby buttons
            if (widget.lobbyId != null) ...[
              const SizedBox(height: AppSpacing.sm),
              _NeoOutlineButton(
                label: 'Vào phòng chờ',
                icon: Icons.meeting_room,
                color: AppColors.primary,
                onPressed: () => _navigateToLobby(context),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            _NeoOutlineButton(
              label: 'Quay về lịch hẹn',
              icon: Icons.calendar_today,
              color: AppColors.textSecondary,
              onPressed: () => _navigateToReservationDetail(context),
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
                        child: const Icon(Icons.receipt_long, color: AppColors.white, size: 24),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      const Expanded(
                        child: Text(
                          'Chia Bill - Thanh toán cá nhân',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
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
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: AppSpacing.md),
              Text('Đang tải thông tin chia bill...'),
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
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: AppSpacing.md),
              Text(state.message, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _NeoOutlineButton(
                    label: 'Đóng',
                    icon: Icons.close,
                    color: AppColors.textSecondary,
                    onPressed: () {
                      _inGameCubit.restoreSessionAfterSplitBill();
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _NeoFilledButton(
                    label: 'Thử lại',
                    icon: Icons.refresh,
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
              const Icon(Icons.info_outline, size: 48, color: AppColors.textSecondary),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Chưa có thông tin chia bill',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Staff chưa tạo QR thanh toán riêng cho bạn.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              
              // Nếu session có thể thanh toán, hiển thị option trả hết
              if (session.canBePaid) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Bạn có thể trả hết bill một mình',
                        style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.success),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        session.costEstimate.formattedTotalDue,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      const Text(
                        '(Tất cả thành viên cùng chia)',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
                      icon: Icons.close,
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
                        icon: Icons.account_balance_wallet,
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

      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thông tin phiên
            if (state is InGameSplitBillLoaded) ...[
              _buildSessionInfoCard(context, state.session),
              const SizedBox(height: AppSpacing.md),
            ],

            // Thông tin thanh toán của user hiện tại
            if (currentUserPayment != null) ...[
              _buildCurrentUserPaymentCard(context, currentUserPayment),
              const SizedBox(height: AppSpacing.md),
            ],

            // Danh sách member và trạng thái thanh toán
            if (members.isNotEmpty) ...[
              const Text(
                'Trạng thái thanh toán',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ...members.map((m) => _buildMemberPaymentItem(context, m)),
            ],

            // Polling indicator
            if (state is InGameSplitBillPolling) ...[
              const SizedBox(height: AppSpacing.md),
              _buildPollingIndicator(context, state),
            ],

            const SizedBox(height: AppSpacing.lg),

            // Action buttons
            _buildSplitBillActions(context, state, currentUserPayment),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildSessionInfoCard(BuildContext context, PlayerSessionEntity session) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.business, color: AppColors.secondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.cafeName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  session.gameName,
                  style: const TextStyle(
                    fontSize: 12,
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

  Widget _buildCurrentUserPaymentCard(BuildContext context, MemberPaymentInfo payment) {
    if (payment.isPaid) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: AppColors.white, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bạn đã thanh toán!',
                    style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.success),
                  ),
                  Text(
                    payment.formattedAmountDue,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: const BoxDecoration(
                  color: AppColors.warning,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.pending, color: AppColors.white, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Thanh toán của bạn',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      payment.formattedAmountDue,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (payment.hasPendingQr && payment.qrImageBase64 != null) ...[
            const SizedBox(height: AppSpacing.md),
            // QR Code display
            Center(
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, width: 2),
                ),
                child: Image.memory(
                  Uri.parse(payment.qrImageBase64!).data!.contentAsBytes(),
                  width: 200,
                  height: 200,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.qr_code,
                    size: 200,
                    color: AppColors.black,
                  ),
                ),
              ),
            ),
            if (payment.qrExpiresAt != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer, size: 16, color: AppColors.error),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Hết hạn sau: ${payment.formattedQrRemainingTime}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.error,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildMemberPaymentItem(BuildContext context, MemberPaymentInfo member) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.secondary.withValues(alpha: 0.2),
            backgroundImage: member.avatarUrl != null
                ? NetworkImage(member.avatarUrl!)
                : null,
            child: member.avatarUrl == null
                ? Text(
                    (member.displayName ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  )
                : null,
          ),
          const SizedBox(width: AppSpacing.md),

          // Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      member.displayName ?? 'Unknown',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    if (member.isCurrentUser) ...[
                      const SizedBox(width: AppSpacing.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Bạn',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  member.formattedAmountDue,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Payment status
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: member.isPaid
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  member.isPaid ? Icons.check_circle : Icons.pending,
                  size: 14,
                  color: member.isPaid ? AppColors.success : AppColors.warning,
                ),
                const SizedBox(width: 4),
                Text(
                  member.isPaid ? 'Đã trả' : 'Chưa trả',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: member.isPaid ? AppColors.success : AppColors.warning,
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
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
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
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  'Kiểm tra lần ${state.pollCount}/60',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          _NeoOutlineButton(
            label: 'Hủy',
            icon: Icons.close,
            color: AppColors.textSecondary,
            onPressed: () {
              _inGameCubit.stopQrPaymentPolling();
              _inGameCubit.restoreSessionAfterSplitBill();
              Navigator.pop(context);
            },
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
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: AppColors.success),
                SizedBox(width: AppSpacing.sm),
                Text(
                  'Thanh toán thành công!',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _NeoFilledButton(
            label: 'Hoàn tất',
            icon: Icons.check,
            color: AppColors.primary,
            onPressed: () {
              _inGameCubit.restoreSessionAfterSplitBill();
              Navigator.pop(context);
            },
          ),
        ],
      );
    }

    if (currentUserPayment != null && !currentUserPayment.isPaid) {
      return Row(
        children: [
          Expanded(
            child: _NeoOutlineButton(
              label: 'Đóng',
              icon: Icons.close,
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
              label: currentUserPayment.hasPendingQr ? 'Đang theo dõi...' : 'Quét QR để thanh toán',
              icon: currentUserPayment.hasPendingQr ? Icons.sync : Icons.qr_code_scanner,
              color: AppColors.primary,
              onPressed: currentUserPayment.hasPendingQr
                  ? null
                  : () {
                      if (currentUserPayment.qrImageBase64 != null) {
                        _inGameCubit.startQrPaymentPolling(currentUserPayment);
                      }
                    },
            ),
          ),
        ],
      );
    }

    return _NeoFilledButton(
      label: 'Đóng',
      icon: Icons.close,
      color: AppColors.primary,
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
  /// (mặc định = `label`). Dùng cho button "Tải lại" — khi user bấm,
  /// button không cho tap thêm lần nữa và hiển thị spinner feedback
  /// cho tới khi API trả về.
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
