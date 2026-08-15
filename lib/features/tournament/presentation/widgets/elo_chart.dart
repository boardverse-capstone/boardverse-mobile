import 'package:flutter/material.dart';

import 'package:boardverse/core/theme/app_colors.dart';
import 'package:boardverse/core/theme/app_spacing.dart';
import 'package:boardverse/core/theme/neo_brutalism_theme.dart';
import 'package:boardverse/features/tournament/domain/entities/elo_history_entity.dart';

/// Neo-brutalism Lightweight line chart for Elo history.
class EloChart extends StatelessWidget {
  final List<EloHistoryEntity> history;
  const EloChart({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;

    return Container(
      height: 180,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: NeoBrutalismTheme.borderWidth),
        boxShadow: NeoBrutalismTheme.lightShadow(
          shadowColor: AppColors.black.withValues(alpha: 0.06),
        ),
      ),
      child: history.length < 2
          ? const Center(
              child: Text(
                'Cần ít nhất 2 giải đấu để hiển thị biểu đồ',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
            )
          : CustomPaint(
              size: Size.infinite,
              painter: _EloLineChartPainter(
                history: history,
                lineColor: AppColors.primary,
                fillColor: AppColors.primary.withValues(alpha: 0.15),
                gridColor: isDark ? AppColors.borderDark : AppColors.border,
                textColor: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
                textStyle: const TextStyle(fontSize: 10),
              ),
            ),
    );
  }
}

class _ChartPadding {
  _ChartPadding._();

  static const double left = 36.0;
  static const double bottom = 24.0;
  static const double top = 8.0;
  static const double right = 8.0;
  static const double gridStrokeWidth = 1.0;
  static const double lineStrokeWidth = 2.5;
  static const double dotRadius = 3.5;
  static const double innerDotRadius = 2.5;
  static const int gridLines = 4;
}

class _EloLineChartPainter extends CustomPainter {
  final List<EloHistoryEntity> history;
  final Color lineColor;
  final Color fillColor;
  final Color gridColor;
  final Color textColor;
  final TextStyle textStyle;

  _EloLineChartPainter({
    required this.history,
    required this.lineColor,
    required this.fillColor,
    required this.gridColor,
    required this.textColor,
    required this.textStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (history.length < 2) return;

    const paddingLeft = _ChartPadding.left;
    const paddingBottom = _ChartPadding.bottom;
    const paddingTop = _ChartPadding.top;
    const paddingRight = _ChartPadding.right;

    final chartWidth = size.width - paddingLeft - paddingRight;
    final chartHeight = size.height - paddingTop - paddingBottom;

    final eloValues = history.map((e) => e.finalElo).toList();
    final minElo = eloValues.reduce((a, b) => a < b ? a : b).toDouble();
    final maxElo = eloValues.reduce((a, b) => a > b ? a : b).toDouble();
    final range = (maxElo - minElo).abs();
    final buffer = range < 40 ? 40.0 : range * 0.15;

    final yMin = minElo - buffer;
    final yMax = maxElo + buffer;
    final yRange = (yMax - yMin).abs().clamp(1, double.infinity);

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = _ChartPadding.gridStrokeWidth;
    final labelPainter = TextPainter(textDirection: TextDirection.ltr);

    const gridLines = _ChartPadding.gridLines;
    for (int i = 0; i <= gridLines; i++) {
      final y = paddingTop + chartHeight * (i / gridLines);
      final value = yMax - (yRange * (i / gridLines));

      canvas.drawLine(
        Offset(paddingLeft, y),
        Offset(size.width - paddingRight, y),
        gridPaint,
      );

      labelPainter.text = TextSpan(
        text: value.round().toString(),
        style: textStyle.copyWith(color: textColor, fontWeight: FontWeight.w800),
      );
      labelPainter.layout();
      labelPainter.paint(
        canvas,
        Offset(paddingLeft - labelPainter.width - 4, y - labelPainter.height / 2),
      );
    }

    final points = <Offset>[];
    for (int i = 0; i < history.length; i++) {
      final x = paddingLeft + chartWidth * (i / (history.length - 1));
      final normalized =
          (history[i].finalElo.toDouble() - yMin) / yRange;
      final y = paddingTop + chartHeight * (1 - normalized);
      points.add(Offset(x, y));
    }

    final fillPath = Path()..moveTo(points.first.dx, paddingTop + chartHeight);
    for (final p in points) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath.lineTo(points.last.dx, paddingTop + chartHeight);
    fillPath.close();
    canvas.drawPath(fillPath, Paint()..color = fillColor);

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = _ChartPadding.lineStrokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      linePath.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(linePath, linePaint);

    final dotPaint = Paint()..color = lineColor;
    final dotRingPaint = Paint()..color = AppColors.white;
    for (final p in points) {
      canvas.drawCircle(p, _ChartPadding.dotRadius, dotRingPaint);
      canvas.drawCircle(p, _ChartPadding.innerDotRadius, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _EloLineChartPainter old) {
    return old.history != history || old.lineColor != lineColor;
  }
}