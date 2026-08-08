import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/neo_brutalism_theme.dart';

/// Neo-brutalism Loading Screen
class GameLoadingScreen extends StatefulWidget {
  final String? message;

  const GameLoadingScreen({super.key, this.message});

  @override
  State<GameLoadingScreen> createState() => _GameLoadingScreenState();
}

class _GameLoadingScreenState extends State<GameLoadingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _rotation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _rotation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.cardGradientOrange,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLoadingIndicator(),
                const SizedBox(height: 32),
                _buildLoadingText(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return AnimatedBuilder(
      animation: _rotation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotation.value * 6.28319,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.3),
                width: 3,
              ),
              boxShadow: NeoBrutalismTheme.lightShadow(
                shadowColor: AppColors.primary.withValues(alpha: 0.6),
              ),
            ),
            child: const Center(
              child: Text(
                '🎲',
                style: TextStyle(fontSize: 40),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingText() {
    return Column(
      children: [
        Text(
          widget.message ?? 'Đang truy cập...',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.white,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: 120,
          height: 6,
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: AppColors.white.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.white.withValues(alpha: 0.9),
              ),
              backgroundColor: Colors.transparent,
            ),
          ),
        ),
      ],
    );
  }
}

/// Ultra-minimal loading widget for inline use.
class MiniGameLoading extends StatefulWidget {
  final double size;
  final Color? color;

  const MiniGameLoading({
    super.key,
    this.size = 32,
    this.color,
  });

  @override
  State<MiniGameLoading> createState() => _MiniGameLoadingState();
}

class _MiniGameLoadingState extends State<MiniGameLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _controller.value * 6.28319,
          child: Text(
            '🎲',
            style: TextStyle(
              fontSize: widget.size,
              color: widget.color,
            ),
          ),
        );
      },
    );
  }
}
