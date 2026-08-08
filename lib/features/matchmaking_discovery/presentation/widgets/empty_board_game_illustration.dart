import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/neo_brutalism_theme.dart';

/// Empty state illustration — board game pieces (dice + cards + token).
/// Vẽ bằng CustomPainter, không phụ thuộc asset.
class EmptyBoardGameIllustration extends StatefulWidget {
  final double size;
  final Color? primaryColor;
  final Color? accentColor;

  const EmptyBoardGameIllustration({
    super.key,
    this.size = 160,
    this.primaryColor,
    this.accentColor,
  });

  @override
  State<EmptyBoardGameIllustration> createState() =>
      _EmptyBoardGameIllustrationState();
}

class _EmptyBoardGameIllustrationState
    extends State<EmptyBoardGameIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return CustomPaint(
          size: Size.square(widget.size),
          painter: _EmptyBoardGamePainter(
            t: _ctrl.value,
            primary: widget.primaryColor ?? AppColors.primary,
            accent: widget.accentColor ?? AppColors.accent,
            secondary: isDark
                ? AppColors.surfaceElevatedDark
                : AppColors.surfaceVariant,
          ),
        );
      },
    );
  }
}

class _EmptyBoardGamePainter extends CustomPainter {
  final double t;
  final Color primary;
  final Color accent;
  final Color secondary;

  _EmptyBoardGamePainter({
    required this.t,
    required this.primary,
    required this.accent,
    required this.secondary,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);

    // Background soft circle
    final bgPaint = Paint()..color = primary.withValues(alpha: 0.12);
    canvas.drawCircle(center, w * 0.45, bgPaint);

    final floatOffset = math.sin(t * 2 * math.pi) * 4;

    // ─── 1. Game board (rectangle nghiêng) ở giữa ───
    canvas.save();
    canvas.translate(center.dx, center.dy + floatOffset);
    canvas.rotate(-0.08);

    final boardRect = Rect.fromCenter(
      center: Offset.zero,
      width: w * 0.55,
      height: h * 0.32,
    );
    final boardRRect = RRect.fromRectAndRadius(
      boardRect,
      const Radius.circular(12),
    );

    // Neo-brutalism: hard shadow, no blur
    final boardShadow = Paint()
      ..color = AppColors.black.withValues(alpha: 0.4);
    canvas.drawRRect(
      boardRRect.shift(const Offset(3, 3)),
      boardShadow,
    );

    final boardPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primary, accent],
      ).createShader(boardRect);
    canvas.drawRRect(boardRRect, boardPaint);

    // Board border
    final boardBorderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = AppColors.black.withValues(alpha: 0.3);
    canvas.drawRRect(boardRRect, boardBorderPaint);

    // Grid dots trên board
    final dotPaint = Paint()..color = Colors.white.withValues(alpha: 0.6);
    for (var row = 0; row < 3; row++) {
      for (var col = 0; col < 4; col++) {
        final x = boardRect.left +
            (boardRect.width / 4) * col +
            boardRect.width / 8;
        final y = boardRect.top +
            (boardRect.height / 3) * row +
            boardRect.height / 6;
        canvas.drawCircle(Offset(x, y), 1.8, dotPaint);
      }
    }

    // ─── 2. Token trên board (white circles) ───
    final tokenPaint = Paint()..color = AppColors.white;
    canvas.drawCircle(
      Offset(boardRect.left + boardRect.width * 0.3,
          boardRect.top + boardRect.height * 0.4),
      10,
      tokenPaint,
    );
    canvas.drawCircle(
      Offset(boardRect.left + boardRect.width * 0.6,
          boardRect.top + boardRect.height * 0.6),
      10,
      tokenPaint,
    );

    canvas.restore();

    // ─── 3. Dice ở góc trên phải (rotate nhẹ) ───
    canvas.save();
    canvas.translate(w * 0.78, h * 0.25 - floatOffset);
    canvas.rotate(0.15 + math.sin(t * 2 * math.pi) * 0.1);

    final diceRect = Rect.fromCenter(
      center: Offset.zero,
      width: 32,
      height: 32,
    );

    // Hard shadow for dice
    final diceShadow = Paint()..color = AppColors.black.withValues(alpha: 0.4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        diceRect.shift(const Offset(2, 2)),
        const Radius.circular(6),
      ),
      diceShadow,
    );

    final dicePaint = Paint()..color = AppColors.white;
    canvas.drawRRect(
      RRect.fromRectAndRadius(diceRect, const Radius.circular(6)),
      dicePaint,
    );

    // Dots trên dice
    final dot = Paint()..color = primary;
    canvas.drawCircle(const Offset(-6, -6), 2, dot);
    canvas.drawCircle(const Offset(6, -6), 2, dot);
    canvas.drawCircle(const Offset(-6, 6), 2, dot);
    canvas.drawCircle(const Offset(6, 6), 2, dot);
    canvas.drawCircle(Offset.zero, 2, dot);

    canvas.restore();

    // ─── 4. Card ở góc dưới trái (nghiêng ngược) ───
    canvas.save();
    canvas.translate(w * 0.22, h * 0.72 + floatOffset);
    canvas.rotate(0.2);

    final cardRect = Rect.fromCenter(
      center: Offset.zero,
      width: 28,
      height: 40,
    );

    // Hard shadow for card
    final cardShadow = Paint()..color = AppColors.black.withValues(alpha: 0.4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        cardRect.shift(const Offset(2, 2)),
        const Radius.circular(4),
      ),
      cardShadow,
    );

    final cardPaint = Paint()..color = AppColors.white;
    canvas.drawRRect(
      RRect.fromRectAndRadius(cardRect, const Radius.circular(4)),
      cardPaint,
    );

    // Icon trên card
    final iconPaint = Paint()..color = accent;
    canvas.drawCircle(Offset.zero, 8, iconPaint);

    canvas.restore();

    // ─── 5. Sparkles xung quanh ───
    final sparklePaint = Paint()..color = accent;
    final sparklePositions = [
      Offset(w * 0.15, h * 0.3),
      Offset(w * 0.85, h * 0.7),
      Offset(w * 0.5, h * 0.1),
      Offset(w * 0.12, h * 0.65),
    ];
    for (var i = 0; i < sparklePositions.length; i++) {
      final opacity =
          (math.sin(t * 2 * math.pi + i * 0.7) + 1) / 2;
      sparklePaint.color = accent.withValues(alpha: 0.4 + opacity * 0.6);
      final pos = sparklePositions[i];
      // 4-pointed sparkle
      final path = Path()
        ..moveTo(pos.dx, pos.dy - 4)
        ..lineTo(pos.dx + 1.5, pos.dy - 1.5)
        ..lineTo(pos.dx + 4, pos.dy)
        ..lineTo(pos.dx + 1.5, pos.dy + 1.5)
        ..lineTo(pos.dx, pos.dy + 4)
        ..lineTo(pos.dx - 1.5, pos.dy + 1.5)
        ..lineTo(pos.dx - 4, pos.dy)
        ..lineTo(pos.dx - 1.5, pos.dy - 1.5)
        ..close();
      canvas.drawPath(path, sparklePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _EmptyBoardGamePainter old) => old.t != t;
}

/// Empty state UI đầy đủ — Neo-brutalism style.
class EmptyBoardGameState extends StatelessWidget {
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? actionIcon;

  const EmptyBoardGameState({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.actionIcon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: AppSpacing.paddingAllXl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const EmptyBoardGameIllustration(size: 180),
            const SizedBox(height: AppSpacing.xl),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
                height: 1.5,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.brightness == Brightness.dark
                        ? AppColors.borderDark
                        : AppColors.border,
                    width: NeoBrutalismTheme.borderWidth,
                  ),
                  boxShadow: NeoBrutalismTheme.lightShadow(
                    shadowColor: AppColors.primary.withValues(alpha: 0.5),
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onAction,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                        vertical: AppSpacing.md,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            actionIcon ?? Icons.refresh,
                            color: AppColors.white,
                            size: 18,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            actionLabel!.toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
