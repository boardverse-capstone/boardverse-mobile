import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/neo_brutalism_theme.dart';

/// Loading screen đẹp & hấp dẫn thay cho spinner/shimmer khi đang tìm
/// board game sau khi player nhấn "ÁP DỤNG".
///
/// Design gồm:
/// - **Background**: gradient + animated dot pattern (subtle, không gây
///   rối mắt nhưng vẫn có chuyển động nhẹ).
/// - **Hero**: xúc xắc 3D xoay liên tục kết hợp pulse scale — neo-brutal
///   style (border đậm + shadow offset cứng).
/// - **Orbit**: 4 icon board game (dice, card, pawn, trophy) quay quanh
///   hero theo quỹ đạo tròn — đảo chiều để tạo depth.
/// - **Rotating tips**: tin nhắn trạng thái đổi mỗi 2.5s với fade in/out
///   — player cảm thấy hệ thống đang "làm việc" tích cực.
/// - **Progress steps**: thanh 4 bước với hiệu ứng fill dần → hoàn thành.
class BeautifulDiscoveryLoader extends StatefulWidget {
  const BeautifulDiscoveryLoader({super.key});

  @override
  State<BeautifulDiscoveryLoader> createState() =>
      _BeautifulDiscoveryLoaderState();
}

class _BeautifulDiscoveryLoaderState extends State<BeautifulDiscoveryLoader>
    with TickerProviderStateMixin {
  // ─── Controllers ──────────────────────────────────────────────────
  late final AnimationController _spinCtrl; // Hero dice rotation
  late final AnimationController _orbitCtrl; // Orbit pieces rotation
  late final AnimationController _pulseCtrl; // Hero scale pulse
  late final AnimationController _progressCtrl; // Progress bar fill
  late final AnimationController _tipFadeCtrl; // Tip text fade
  late final AnimationController _dotCtrl; // Background dots drift

  late final Animation<double> _pulse;

  // ─── State ────────────────────────────────────────────────────────
  static const _tips = <String>[
    'Đang phân tích gu của bạn...',
    'Lọc theo độ phức tạp & thời gian...',
    'Tìm quán cafe board game phù hợp...',
    'Sắp xếp kết quả tốt nhất...',
    'Lắc xúc xắc vận may 🎲',
  ];

  int _currentTip = 0;

  // Icons orbit quanh hero dice
  static const _orbitIcons = <IconData>[
    Icons.style_rounded, // card
    Icons.sports_esports_rounded, // game controller
    Icons.emoji_events_rounded, // trophy
    Icons.extension_rounded, // puzzle
  ];

  // Màu cho 4 orbit icons (xen kẽ)
  static const _orbitColors = <Color>[
    AppColors.secondary,
    AppColors.accent,
    Color(0xFF7B2FF7),
    AppColors.success,
  ];

  @override
  void initState() {
    super.initState();

    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _orbitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulse = Tween<double>(begin: 0.94, end: 1.08).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat();

    _tipFadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _dotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    // Rotate tip xóa các vòng lặp khác.
    _startTipRotation();
  }

  Future<void> _startTipRotation() async {
    while (mounted) {
      await Future.delayed(const Duration(milliseconds: 2500));
      if (!mounted) return;
      await _tipFadeCtrl.forward();
      if (!mounted) return;
      setState(() => _currentTip = (_currentTip + 1) % _tips.length);
      await _tipFadeCtrl.reverse();
    }
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    _orbitCtrl.dispose();
    _pulseCtrl.dispose();
    _progressCtrl.dispose();
    _tipFadeCtrl.dispose();
    _dotCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;

    return Container(
      width: double.infinity,
      color: isDark ? AppColors.backgroundDark : AppColors.background,
      child: Stack(
        children: [
          // ─── Background dot pattern (subtle drift) ──────────────
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _dotCtrl,
              builder: (context, _) {
                return CustomPaint(
                  painter: _DotPatternPainter(
                    progress: _dotCtrl.value,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : AppColors.primary.withValues(alpha: 0.08),
                  ),
                );
              },
            ),
          ),

          // ─── Orbit pieces (background) ──────────────────────────
          Positioned.fill(child: _buildOrbitLayer(borderColor)),

          // ─── Main content ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ─── Hero dice ─────────────────────────────────
                _buildHeroDice(borderColor),

                const SizedBox(height: AppSpacing.xl),

                // ─── Title ─────────────────────────────────────
                Text(
                  'Đang tìm game cho bạn',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // ─── Rotating tip (fade in/out) ────────────────
                SizedBox(
                  height: 22,
                  child: FadeTransition(
                    opacity: Tween<double>(begin: 0.3, end: 1.0).animate(
                      _tipFadeCtrl,
                    ),
                    child: Text(
                      _tips[_currentTip],
                      key: ValueKey(_currentTip),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // ─── Progress bar ──────────────────────────────
                _buildProgressBar(),

                const SizedBox(height: AppSpacing.md),

                // ─── Step labels ──────────────────────────────
                _buildStepLabels(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Hero dice (rotating + pulsing) ──────────────────────────────────
  Widget _buildHeroDice(Color borderColor) {
    return AnimatedBuilder(
      animation: Listenable.merge([_spinCtrl, _pulseCtrl]),
      builder: (context, _) {
        return Transform.scale(
          scale: _pulse.value,
          child: SizedBox(
            width: 140,
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Glow halo (subtle)
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.25),
                        AppColors.primary.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
                // Dice cube (rotating)
                Transform.rotate(
                  angle: _spinCtrl.value * 2 * math.pi,
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderColor, width: 3.5),
                      boxShadow: NeoBrutalismTheme.lightShadow(
                        shadowColor: AppColors.primary.withValues(alpha: 0.5),
                      ),
                    ),
                    child: const Icon(
                      Icons.casino_rounded,
                      size: 56,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Orbit pieces (4 icons quay quanh hero) ───────────────────────
  Widget _buildOrbitLayer(Color borderColor) {
    return AnimatedBuilder(
      animation: _orbitCtrl,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            // Orbit radius — co giãn theo width nhưng cap lại.
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;
            final radius = math
                .min(w * 0.38, h * 0.32)
                .clamp(120.0, 200.0);
            final center = Offset(w / 2, h * 0.42);

            return Stack(
              children: List.generate(_orbitIcons.length, (i) {
                final baseAngle = (i / _orbitIcons.length) * 2 * math.pi;
                final angle = baseAngle + _orbitCtrl.value * 2 * math.pi;
                final x = center.dx + radius * math.cos(angle);
                final y = center.dy + radius * math.sin(angle);

                return Positioned(
                  left: x - 28,
                  top: y - 28,
                  child: Transform.rotate(
                    angle: -angle * 1.5, // icons xoay nguoc orbit
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: _orbitColors[i].withValues(alpha: 0.35),
                            offset: const Offset(2, 2),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Icon(
                        _orbitIcons[i],
                        size: 28,
                        color: _orbitColors[i],
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        );
      },
    );
  }

  // ─── Progress bar ──────────────────────────────────────────────────
  Widget _buildProgressBar() {
    return AnimatedBuilder(
      animation: _progressCtrl,
      builder: (context, _) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: null, // indeterminate feel
            minHeight: 8,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppColors.primary,
            ),
          ),
        );
      },
    );
  }

  // ─── Step labels ───────────────────────────────────────────────────
  Widget _buildStepLabels(bool isDark) {
    final steps = const ['Phân tích', 'Tìm kiếm', 'Lọc', 'Sắp xếp'];
    return AnimatedBuilder(
      animation: _progressCtrl,
      builder: (context, _) {
        // Step active dựa trên progress (cycle 4 steps).
        final activeIdx = (_progressCtrl.value * steps.length).floor() %
            steps.length;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(steps.length, (i) {
            final isActive = i == activeIdx;
            final isDone = i < activeIdx ||
                (_progressCtrl.value > 0.95 && i == steps.length - 1);
            final color = isActive
                ? AppColors.primary
                : (isDone
                    ? AppColors.success
                    : (isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary));
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Step dot
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.5),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  steps[i],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight:
                        isActive ? FontWeight.w900 : FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            );
          }),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Background dot pattern (subtle drift)
// ─────────────────────────────────────────────────────────────────────────────

class _DotPatternPainter extends CustomPainter {
  final double progress;
  final Color color;

  _DotPatternPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const dotRadius = 1.5;
    const spacing = 28.0;

    // Drift offset theo progress.
    final dx = progress * spacing;
    final dy = progress * spacing * 0.6;

    for (double y = -spacing + dy; y < size.height + spacing; y += spacing) {
      for (double x = -spacing + dx; x < size.width + spacing; x += spacing) {
        canvas.drawCircle(Offset(x, y), dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotPatternPainter old) =>
      old.progress != progress || old.color != color;
}