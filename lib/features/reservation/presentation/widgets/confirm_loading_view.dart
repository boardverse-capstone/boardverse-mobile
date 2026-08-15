import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/neo_brutalism_theme.dart';

/// Loading view đẹp hơn `CircularProgressIndicator` đơn điệu — được dùng
/// cho các state blocking UI lâu (vd: `ReservationConfirming` gọi
/// atomic transaction tới backend).
///
/// Style neo-brutalism:
/// - Centred card có border 3px + hard shadow (5, 5).
/// - Icon badge màu semantic có pulse animation (scale 1.0 ↔ 1.08).
/// - "Spinning" outer ring quay quanh icon (rotation 0 → 2π trong 2s).
/// - Step text thay đổi theo timer (3 steps, mỗi step 2s) → cảm giác
///   "đang tiến hành" thay vì loading đứng yên.
/// - Sub-text đếm ngược (mm:ss) → user biết còn bao lâu.
///
/// Design system v4.0 — không dùng shadow đen, không dùng border đen.
class ConfirmLoadingView extends StatefulWidget {
  /// Danh sách step text hiển thị xoay vòng. Nếu null → dùng default
  /// cho flow reservation confirm.
  final List<String> steps;

  /// Sub-text mô tả phase hiện tại (subtitle dưới step text).
  final String? subtitle;

  /// Icon chính ở giữa (vd: `Icons.lock_outline` cho đặt cọc).
  final IconData icon;

  /// Màu accent của icon badge (thường là `AppColors.primary`).
  final Color accentColor;

  /// Labeling chính phía trên icon (vd: "Đặt cọc & tạo lobby").
  final String title;

  const ConfirmLoadingView({
    super.key,
    this.steps = const [
      'Đang trừ BVC trong ví...',
      'Đang giữ chỗ ngồi...',
      'Đang tạo lobby...',
    ],
    this.subtitle,
    this.icon = Icons.lock_outline_rounded,
    this.accentColor = AppColors.primary,
    this.title = 'Đặt cọc & tạo lobby',
  });

  @override
  State<ConfirmLoadingView> createState() => _ConfirmLoadingViewState();
}

class _ConfirmLoadingViewState extends State<ConfirmLoadingView>
    with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final AnimationController _spinCtrl;
  late final AnimationController _stepCtrl;

  late final Animation<double> _pulse;
  late final Animation<double> _spin;

  /// Step index đang hiển thị — thay đổi mỗi 2 giây.
  int _stepIndex = 0;

  @override
  void initState() {
    super.initState();

    // Pulse icon (1.0 ↔ 1.08 — 1.4s)
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    // Spinning outer ring (0 → 2π — 2s)
    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _spin = Tween<double>(begin: 0.0, end: 6.28319).animate(_spinCtrl);

    // Step switcher (2s/step)
    _stepCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _stepCtrl.addListener(() {
      // Mỗi 0.5s progress → re-evaluate step index
      final total = widget.steps.length;
      final newIndex = (_stepCtrl.value * total).floor() % total;
      if (newIndex != _stepIndex) {
        setState(() => _stepIndex = newIndex);
      }
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _spinCtrl.dispose();
    _stepCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final steps = widget.steps;

    return Center(
      child: Padding(
        padding: AppSpacing.paddingAllLg,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.xl,
          ),
          decoration: NeoBrutalismTheme.autoBox(
            context,
            backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
            borderRadius: 24,
            bold: true,
            shadowColor: widget.accentColor.withValues(alpha: 0.25),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Animated icon badge ────────────────────────────────
              SizedBox(
                width: 96,
                height: 96,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Spinning outer ring (arc)
                    RotationTransition(
                      turns: _spin,
                      child: CustomPaint(
                        size: const Size(96, 96),
                        painter: _SpinningRingPainter(
                          color: widget.accentColor,
                          isDark: isDark,
                        ),
                      ),
                    ),
                    // Pulsing icon badge
                    ScaleTransition(
                      scale: _pulse,
                      child: Container(
                        width: 64,
                        height: 64,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: widget.accentColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? AppColors.borderDark
                                : AppColors.border,
                            width: NeoBrutalismTheme.borderWidthBold,
                          ),
                          boxShadow: NeoBrutalismTheme.lightShadow(
                            shadowColor:
                                widget.accentColor.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Icon(
                          widget.icon,
                          color: AppColors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── Title ──────────────────────────────────────────────
              Text(
                widget.title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),

              // ── Step text (animated switch) ────────────────────────
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.3),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
                child: Text(
                  steps[_stepIndex],
                  key: ValueKey('step-$_stepIndex'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: widget.accentColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              if (widget.subtitle != null) ...[
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  widget.subtitle!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: NeoBrutalismTheme.textSecondaryColor(context),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// CustomPainter vẽ 1 arc quay quanh icon — dùng màu [color] với alpha
/// nhẹ ở phần "tail" (gradient effect thủ công).
class _SpinningRingPainter extends CustomPainter {
  final Color color;
  final bool isDark;

  _SpinningRingPainter({required this.color, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Background ring (subtle)
    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = color.withValues(alpha: 0.15);
    canvas.drawCircle(center, radius, bgPaint);

    // Foreground arc (3/4 circle, animated by parent rotation)
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.2, // start angle (radians) — top
      4.0, // sweep — khoảng 230 độ
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(_SpinningRingPainter oldDelegate) => false;
}
