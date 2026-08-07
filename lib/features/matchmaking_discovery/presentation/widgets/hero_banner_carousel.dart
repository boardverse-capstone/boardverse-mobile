import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/board_game_entity.dart';
import 'hero_banner/hero_banner_card.dart';
import 'hero_banner/hero_page_indicator.dart';

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
                  child: HeroBannerCard(
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
        HeroPageIndicator(
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