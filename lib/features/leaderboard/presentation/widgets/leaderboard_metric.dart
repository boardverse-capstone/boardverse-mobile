import 'package:flutter/material.dart';

import 'package:boardverse/core/theme/app_colors.dart';
import 'package:boardverse/core/theme/app_icons.dart';
import 'package:boardverse/features/leaderboard/domain/entities/leaderboard_entry_entity.dart';
import 'package:boardverse/features/leaderboard/domain/entities/leaderboard_kind.dart';

/// Helper resolve metric value theo `LeaderboardKind` từ `LeaderboardEntryEntity`.
///
/// Trả về cả label + giá trị đã format + accent color + icon. Dùng cho
/// tile, podium, user-rank card để tránh lặp switch ở nhiều widget.
class LeaderboardMetric {
  const LeaderboardMetric({
    required this.label,
    required this.value,
    required this.accentColor,
    required this.icon,
  });

  /// Label tiếng Việt ("Elo", "Level", "Karma").
  final String label;

  /// Giá trị đã format (fallback `—` khi backend trả null).
  final String value;

  /// Màu accent cho metric — dùng làm shadow/foreground tone.
  final Color accentColor;

  /// Material icon đại diện metric.
  final IconData icon;

  /// Resolve từ entry + kind, fallback `—` khi backend không trả field.
  factory LeaderboardMetric.resolve(
    LeaderboardEntryEntity entry,
    LeaderboardKind kind,
  ) {
    switch (kind) {
      case LeaderboardKind.elo:
        return LeaderboardMetric(
          label: kind.primaryMetricLabel,
          value: entry.globalElo?.toString() ?? '—',
          accentColor: AppColors.primary,
          icon: AppIcons.elo,
        );
      case LeaderboardKind.level:
        return LeaderboardMetric(
          label: kind.primaryMetricLabel,
          value: entry.level?.toString() ?? '—',
          accentColor: AppColors.secondary,
          icon: AppIcons.level,
        );
      case LeaderboardKind.karma:
        return LeaderboardMetric(
          label: kind.primaryMetricLabel,
          value: entry.karmaPoints?.toString() ?? '—',
          accentColor: AppColors.accent,
          icon: AppIcons.karma,
        );
    }
  }
}
