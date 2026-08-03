import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/safe_network_image.dart';
import '../../domain/entities/board_game_entity.dart';

/// Hero Carousel — banner nổi bật ở đầu SearchPage.
///
/// Tính năng:
/// - Auto-scroll mỗi 5 giây (dừng khi user chạm)
/// - Page indicator dots có animation
/// - Gradient overlay dưới cùng để text dễ đọc
/// - Parallax nhẹ khi user vuốt ngang
/// - Tap vào card → callback onTap
class HeroBannerCarousel extends StatefulWidget {
  final List<BoardGameEntity> featuredGames;
  final void Function(BoardGameEntity) onTapGame;

  const HeroBannerCarousel({
    super.key,
    required this.featuredGames,
    required this.onTapGame,
  });

  @override
  State<HeroBannerCarousel> createState() => _HeroBannerCarouselState();
}

class _HeroBannerCarouselState extends State<HeroBannerCarousel> {
  late final PageController _controller;
  Timer? _autoScrollTimer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.92);
    _controller.addListener(_handlePageScroll);
    _startAutoScroll();
  }

  @override
  void didUpdateWidget(covariant HeroBannerCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.featuredGames.length != widget.featuredGames.length) {
      _startAutoScroll();
    }
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _controller.removeListener(_handlePageScroll);
    _controller.dispose();
    super.dispose();
  }

  void _handlePageScroll() {
    if (!_controller.hasClients) return;
    final page = _controller.page ?? _currentPage.toDouble();
    final delta = (page - _currentPage).abs();
    if (delta > 0.1) setState(() {});
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    if (widget.featuredGames.length <= 1) return;
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_controller.hasClients) return;
      final next = (_currentPage + 1) % widget.featuredGames.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _onUserInteractionStart() {
    _autoScrollTimer?.cancel();
  }

  void _onUserInteractionEnd() {
    _startAutoScroll();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.featuredGames.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: GestureDetector(
            onPanStart: (_) => _onUserInteractionStart(),
            onPanEnd: (_) => _onUserInteractionEnd(),
            onLongPressStart: (_) => _onUserInteractionStart(),
            onLongPressEnd: (_) => _onUserInteractionEnd(),
            child: PageView.builder(
              controller: _controller,
              onPageChanged: (page) {
                setState(() => _currentPage = page);
              },
              itemCount: widget.featuredGames.length,
              itemBuilder: (context, index) {
                final game = widget.featuredGames[index];
                return AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    double delta = 0;
                    if (_controller.position.hasContentDimensions) {
                      final page = _controller.page ?? _currentPage.toDouble();
                      delta = (page - index).abs().clamp(0.0, 1.0);
                    }
                    final scale = 1 - (delta * 0.06);
                    final opacity = 1 - (delta * 0.35);
                    return Opacity(
                      opacity: opacity,
                      child: Transform.scale(
                        scale: scale,
                        child: child,
                      ),
                    );
                  },
                  child: _HeroBannerCard(
                    game: game,
                    badgeText: index == 0 ? 'NỔI BẬT' : null,
                    onTap: () => widget.onTapGame(game),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _PageIndicator(
          count: widget.featuredGames.length,
          current: _currentPage,
          onDotTapped: (index) {
            _onUserInteractionStart();
            _controller.animateToPage(
              index,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
            );
            Future.delayed(const Duration(milliseconds: 500), _onUserInteractionEnd);
          },
        ),
      ],
    );
  }
}

class _HeroBannerCard extends StatefulWidget {
  final BoardGameEntity game;
  final String? badgeText;
  final VoidCallback onTap;

  const _HeroBannerCard({
    required this.game,
    required this.badgeText,
    required this.onTap,
  });

  @override
  State<_HeroBannerCard> createState() => _HeroBannerCardState();
}

class _HeroBannerCardState extends State<_HeroBannerCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0,
      upperBound: 1,
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTapDown: (_) => _pressCtrl.forward(),
      onTapUp: (_) => _pressCtrl.reverse(),
      onTapCancel: () => _pressCtrl.reverse(),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _pressCtrl,
        builder: (context, child) {
          final scale = 1 - (_pressCtrl.value * 0.03);
          return Transform.scale(scale: scale, child: child);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Stack(
            children: [
              // Animated gradient border
              _AnimatedGradientBorder(
                borderRadius: AppRadius.radiusLgAll,
                child: ClipRRect(
                  borderRadius: AppRadius.radiusLgAll,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      SafeNetworkImage(
                        url: widget.game.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, st) => Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.extension,
                            size: AppSpacing.huge,
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ),
                      // Gradient overlay để text dễ đọc
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              AppColors.black.withValues(alpha: 0.75),
                            ],
                            stops: const [0.45, 1.0],
                          ),
                        ),
                      ),
                      // Text content
                      Positioned(
                        left: AppSpacing.md,
                        right: AppSpacing.md,
                        bottom: AppSpacing.md,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.badgeText != null)
                              Container(
                                margin: const EdgeInsets.only(
                                  bottom: AppSpacing.xs,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.xs,
                                  vertical: AppSpacing.xxs,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  borderRadius: AppRadius.radiusSmAll,
                                ),
                                child: Text(
                                  widget.badgeText!,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: AppColors.black,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                            Text(
                              widget.game.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                shadows: [
                                  Shadow(
                                    color: AppColors.black.withValues(
                                      alpha: 0.5,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Row(
                              children: [
                                if (widget.game.category.isNotEmpty) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.xs,
                                      vertical: AppSpacing.xxs,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.18,
                                      ),
                                      borderRadius: AppRadius.radiusFullAll,
                                    ),
                                    child: Text(
                                      widget.game.category,
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                ],
                                if (widget.game.rating > 0)
                                  Icon(
                                    Icons.star,
                                    size: AppSpacing.md,
                                    color: AppColors.warning,
                                  ),
                                if (widget.game.rating > 0) ...[
                                  const SizedBox(width: AppSpacing.xxs),
                                  Text(
                                    widget.game.rating.toStringAsFixed(1),
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Animated gradient border — viền gradient chuyển động liên tục tạo cảm
/// giác "alive" cho hero banner. Chỉ dùng cho banner lớn để tránh rối mắt.
class _AnimatedGradientBorder extends StatefulWidget {
  final Widget child;
  final BorderRadius borderRadius;

  const _AnimatedGradientBorder({
    required this.child,
    required this.borderRadius,
  });

  @override
  State<_AnimatedGradientBorder> createState() =>
      _AnimatedGradientBorderState();
}

class _AnimatedGradientBorderState extends State<_AnimatedGradientBorder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  static const double _borderWidth = 2;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return CustomPaint(
          painter: _GradientBorderPainter(
            angle: _ctrl.value * 2 * 3.14159,
            strokeWidth: _borderWidth,
            radius: widget.borderRadius.topLeft.x,
            colors: const [
              AppColors.primary,
              AppColors.accent,
              AppColors.warning,
              AppColors.primary,
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(_borderWidth),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                widget.borderRadius.topLeft.x - _borderWidth,
              ),
              child: child,
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}

class _GradientBorderPainter extends CustomPainter {
  final double angle;
  final double strokeWidth;
  final double radius;
  final List<Color> colors;

  _GradientBorderPainter({
    required this.angle,
    required this.strokeWidth,
    required this.radius,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));

    final shader = SweepGradient(
      startAngle: angle,
      endAngle: angle + 2 * 3.14159,
      colors: colors,
      tileMode: TileMode.clamp,
    ).createShader(rect);

    final paint = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawRRect(rrect.deflate(strokeWidth / 2), paint);
  }

  @override
  bool shouldRepaint(covariant _GradientBorderPainter old) =>
      old.angle != angle;
}

/// Page indicator dots có animation.
class _PageIndicator extends StatelessWidget {
  final int count;
  final int current;
  final ValueChanged<int> onDotTapped;

  const _PageIndicator({
    required this.count,
    required this.current,
    required this.onDotTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
          width: isActive ? AppSpacing.xl : AppSpacing.xs,
          height: AppSpacing.xs - 2,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary
                : AppColors.primary.withValues(alpha: 0.3),
            borderRadius: AppRadius.radiusFullAll,
          ),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onDotTapped(index),
          ),
        );
      }),
    );
  }
}