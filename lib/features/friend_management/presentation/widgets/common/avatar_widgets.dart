import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/safe_network_image.dart';

/// Neo-brutalism User avatar widget with initials fallback.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.username,
    required this.avatarUrl,
    this.radius = 24,
  });

  final String username;
  final String avatarUrl;
  final double radius;

  String get _initials {
    if (username.isEmpty) return '?';
    return username.substring(0, 1).toUpperCase();
  }

  bool get _hasImage =>
      avatarUrl.isNotEmpty && avatarUrl.startsWith('http');

  @override
  Widget build(BuildContext context) {
    if (_hasImage) {
      return ClipOval(
        child: SizedBox(
          width: radius * 2,
          height: radius * 2,
          child: SafeNetworkImage(
            url: avatarUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                _InitialsFallback(initials: _initials, radius: radius),
          ),
        ),
      );
    }
    return _InitialsFallback(initials: _initials, radius: radius);
  }
}

class _InitialsFallback extends StatelessWidget {
  const _InitialsFallback({required this.initials, required this.radius});

  final String initials;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primaryLight,
          ],
        ),
        border: Border.all(color: AppColors.black, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          color: AppColors.white,
          fontSize: 16,
        ),
      ),
    );
  }
}

/// Neo-brutalism Avatar with colored border based on gamer tier.
class TieredAvatar extends StatelessWidget {
  const TieredAvatar({
    super.key,
    required this.username,
    required this.avatarUrl,
    required this.borderColor,
    this.radius = 26,
    this.borderWidth = 2,
  });

  final String username;
  final String avatarUrl;
  final Color borderColor;
  final double radius;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(borderWidth),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: borderColor,
        border: Border.all(color: AppColors.black, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: AppColors.black,
            blurRadius: 0,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: UserAvatar(
        username: username,
        avatarUrl: avatarUrl,
        radius: radius - borderWidth,
      ),
    );
  }
}