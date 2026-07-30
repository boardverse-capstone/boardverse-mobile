import 'package:flutter/material.dart';

import '../../../../../core/widgets/safe_network_image.dart';

/// User avatar widget with initials fallback.
///
/// Displays network image if URL is valid, otherwise shows username initials.
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
    final theme = Theme.of(context);
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.primaryContainer.withValues(alpha: 0.7),
          ],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

/// Avatar with colored border based on gamer tier.
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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            borderColor,
            borderColor.withValues(alpha: 0.6),
          ],
        ),
      ),
      child: UserAvatar(
        username: username,
        avatarUrl: avatarUrl,
        radius: radius - borderWidth,
      ),
    );
  }
}
