import 'package:flutter/material.dart';

import 'package:boardverse_mobile/core/theme/theme.dart';
import 'package:boardverse_mobile/features/tournament/domain/entities/elo_history_entity.dart';

/// Lightweight line chart for Elo history drawn with [CustomPainter]
/// (avoid pulling in fl_chart for this single use case).
class EloChart extends StatelessWidget {
  final List<EloHistoryEntity> history;
  const EloChart({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 180,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: AppRadius.radiusMdAll,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: history.length < 2
          ? Center(
              child: Text(
                'Cần ít nhất 2 giải đấu để hiển thị biểu đồ',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            )
          : CustomPaint(
              size: Size.infinite,
              painter: _EloLineChartPainter(
                history: history,
                lineColor: theme.colorScheme.primary,
                fillColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                gridColor: theme.colorScheme.outlineVariant,
                textColor: theme.colorScheme.onSurfaceVariant,
                textStyle: theme.textTheme.labelSmall ?? const TextStyle(),
              ),
            ),
    );
  }
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

    const paddingLeft = 36.0;
    const paddingBottom = 24.0;
    const paddingTop = 8.0;
    const paddingRight = 8.0;

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

    // Grid + Y-axis labels
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    final labelPainter = TextPainter(textDirection: TextDirection.ltr);

    const gridLines = 4;
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
        style: textStyle.copyWith(color: textColor, fontSize: 10),
      );
      labelPainter.layout();
      labelPainter.paint(
        canvas,
        Offset(paddingLeft - labelPainter.width - 4, y - labelPainter.height / 2),
      );
    }

    // Map (i, elo) → (x, y)
    final points = <Offset>[];
    for (int i = 0; i < history.length; i++) {
      final x = paddingLeft + chartWidth * (i / (history.length - 1));
      final normalized =
          (history[i].finalElo.toDouble() - yMin) / yRange;
      final y = paddingTop + chartHeight * (1 - normalized);
      points.add(Offset(x, y));
    }

    // Filled area
    final fillPath = Path()..moveTo(points.first.dx, paddingTop + chartHeight);
    for (final p in points) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath.lineTo(points.last.dx, paddingTop + chartHeight);
    fillPath.close();
    canvas.drawPath(fillPath, Paint()..color = fillColor);

    // Line
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      linePath.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(linePath, linePaint);

    // Dots
    final dotPaint = Paint()..color = lineColor;
    final dotRingPaint = Paint()..color = Colors.white;
    for (final p in points) {
      canvas.drawCircle(p, 3.5, dotRingPaint);
      canvas.drawCircle(p, 2.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _EloLineChartPainter old) {
    return old.history != history || old.lineColor != lineColor;
  }
}