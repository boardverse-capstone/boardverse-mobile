import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:boardverse_mobile/core/di/injection.dart';
import 'package:boardverse_mobile/core/theme/app_colors.dart';
import 'package:boardverse_mobile/core/theme/app_spacing.dart';
import '../../../match_summary_rating/presentation/pages/rating_page.dart';
import '../cubit/in_game_cubit.dart';
import '../cubit/in_game_state.dart';
import '../widgets/inventory_checking_overlay.dart';
import '../widgets/play_duration_timer.dart';
import '../widgets/session_ended_notification_dialog.dart';

/// Neo-brutalism in-game session page.
class InGameSessionPage extends StatefulWidget {
  final String bookingId;
  final String cafeName;
  final String gameName;
  final int tableNumber;

  const InGameSessionPage({
    super.key,
    required this.bookingId,
    required this.cafeName,
    required this.gameName,
    required this.tableNumber,
  });

  @override
  State<InGameSessionPage> createState() => _InGameSessionPageState();
}

class _InGameSessionPageState extends State<InGameSessionPage> {
  final _inGameCubit = getIt<InGameCubit>();

  @override
  void initState() {
    super.initState();
    _inGameCubit.checkIn(widget.bookingId);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _inGameCubit,
      child: BlocConsumer<InGameCubit, InGameState>(
        listener: (context, state) {
          if (state is InGameCheckoutComplete) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const RatingPage()),
            );
          }
          if (state is InGameSessionEnded) {
            SessionEndedNotificationDialog.show(
              context: context,
              totalDuration: state.totalDuration,
              onRateNow: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const RatingPage()),
                );
              },
              onVoteNoShow: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const RatingPage()),
                );
              },
              onLater: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const RatingPage()),
                );
              },
            );
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
                  if (state is InGameCheckingInventory)
                    const InventoryCheckingOverlay(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, InGameState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (state is InGameLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 4,
        ),
      );
    }

    if (state is InGameFailure) {
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
                  state.message,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                _NeoFilledButton(
                  label: 'Thử lại',
                  icon: Icons.refresh,
                  color: AppColors.primary,
                  onPressed: () => _inGameCubit.checkIn(widget.bookingId),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (state is InGameSessionActive) {
      return _buildSessionView(context, state);
    }

    if (state is InGameCheckingInventory) {
      return _buildSessionView(
        context,
        InGameSessionActive(
          session: state.session,
          currentDuration: Duration.zero,
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildSessionView(BuildContext context, InGameSessionActive state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final session = state.session;

    return SafeArea(
      child: Column(
        children: [
          // Header gradient
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
                          const Icon(
                            Icons.table_restaurant,
                            size: 14,
                            color: AppColors.white,
                          ),
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
                PlayDurationTimer(
                  startTime: session.startTime,
                  isRunning: true,
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Game Info Card
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surfaceDark
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.border,
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
                              color: isDark
                                  ? AppColors.borderDark
                                  : AppColors.border,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.extension,
                            color: AppColors.white,
                            size: 28,
                          ),
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
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${session.players.length} người chơi',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Players Section header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark
                                ? AppColors.borderDark
                                : AppColors.border,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.group,
                          color: AppColors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'NGƯỜI CÙNG CHƠI',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          letterSpacing: 1.0,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: session.players.map((player) {
                      final present = player.isPresent;
                      final fgColor =
                          present ? AppColors.white : AppColors.textSecondary;
                      final bgColor =
                          present ? AppColors.success : AppColors.textTertiary;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? AppColors.borderDark
                                : AppColors.border,
                            width: 2,
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
                            CircleAvatar(
                              radius: 12,
                              backgroundColor:
                                  AppColors.white.withValues(alpha: 0.3),
                              backgroundImage: player.avatarUrl.isNotEmpty
                                  ? NetworkImage(player.avatarUrl)
                                  : null,
                              onBackgroundImageError: (_, _) {},
                              child: player.avatarUrl.isEmpty
                                  ? Text(
                                      player.name.isNotEmpty
                                          ? player.name[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.white,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              player.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                                color: fgColor,
                              ),
                            ),
                            if (present) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.check_circle,
                                size: 14,
                                color: AppColors.white,
                              ),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Action
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
                  // Mock: End Session button
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
                    onPressed: () =>
                        _inGameCubit.requestCheckout(session.sessionId),
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
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(AppSpacing.md),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border, width: 3),
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
                child: const Icon(
                  Icons.warning_amber,
                  size: 32,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Xác nhận rời đi',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: AppColors.black,
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

  const _NeoOutlineButton({
    required this.label,
    required this.color,
    this.icon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
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
          if (icon != null) ...[
            Icon(icon, size: 16, color: color),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
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