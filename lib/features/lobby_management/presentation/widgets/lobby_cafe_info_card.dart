import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:boardverse/core/di/injection.dart';
import 'package:boardverse/core/theme/app_colors.dart';
import 'package:boardverse/core/theme/app_icons.dart';
import 'package:boardverse/core/theme/app_radius.dart';
import 'package:boardverse/core/theme/app_spacing.dart';
import 'package:boardverse/core/widgets/safe_network_image.dart';
import 'package:boardverse/features/matchmaking_discovery/domain/entities/cafe_detail_entity.dart';
import 'package:boardverse/features/matchmaking_discovery/presentation/cubit/cafe_detail_cubit.dart';
import 'package:boardverse/features/matchmaking_discovery/presentation/cubit/cafe_detail_state.dart';

/// Card hiển thị thông tin chi tiết cafe cho [LobbyPage] (active lobby).
///
/// Đặt ngay dưới [LobbyHeroHeader] để player thấy ngay ảnh quán, địa chỉ,
/// trạng thái mở/đóng, số bàn & game có sẵn — thay vì phải mở trang
/// chi tiết cafe riêng.
///
/// **Fetch strategy**: khi mount → `cubit.loadCafeDetail(cafeId)`. Endpoint
/// public `GET /api/cafes/{id}` không cần token. Cubit là factory → tự
/// dispose khi widget dispose.
///
/// **Failure handling**: nếu fetch fail → ẩn card luôn (graceful degrade),
/// không crash UI vì thông tin cafe là "nice to have" chứ không block
/// lobby flow chính.
class LobbyCafeInfoCard extends StatefulWidget {
  final String cafeId;

  /// Optional cubit — dùng để test (inject fake cubit). Production sẽ lấy
  /// từ `getIt` nếu null.
  final CafeDetailCubit? cubit;

  const LobbyCafeInfoCard({
    super.key,
    required this.cafeId,
    this.cubit,
  });

  @override
  State<LobbyCafeInfoCard> createState() => _LobbyCafeInfoCardState();
}

class _LobbyCafeInfoCardState extends State<LobbyCafeInfoCard> {
  late final CafeDetailCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = widget.cubit ?? getIt<CafeDetailCubit>();
    _cubit.loadCafeDetail(widget.cafeId);
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CafeDetailCubit, CafeDetailState>(
      bloc: _cubit,
      builder: (context, state) {
        if (state is CafeDetailLoaded) {
          return _CafeInfoBody(cafe: state.cafe);
        }
        if (state is CafeDetailLoading) {
          return const _CafeInfoSkeleton();
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _CafeInfoBody extends StatelessWidget {
  final CafeDetailEntity cafe;

  const _CafeInfoBody({required this.cafe});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        0,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: AppRadius.radiusLgAll,
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CafeImage(cafe: cafe, theme: theme),
          _CafeInfoContent(cafe: cafe, theme: theme),
        ],
      ),
    );
  }
}

class _CafeImage extends StatelessWidget {
  final CafeDetailEntity cafe;
  final ThemeData theme;

  const _CafeImage({required this.cafe, required this.theme});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(12),
      ),
      child: AspectRatio(
        aspectRatio: 16 / 7,
        child: SafeNetworkImage(
          url: cafe.imageUrl ?? '',
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Container(
            color: theme.colorScheme.surfaceContainerHighest,
            alignment: Alignment.center,
            child: Icon(
              AppIcons.cafe,
              size: 40,
              color: theme.colorScheme.outline,
            ),
          ),
        ),
      ),
    );
  }
}

class _CafeInfoContent extends StatelessWidget {
  final CafeDetailEntity cafe;
  final ThemeData theme;

  const _CafeInfoContent({required this.cafe, required this.theme});

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      _CafeNameRow(cafe: cafe, theme: theme),
      const SizedBox(height: AppSpacing.sm),
    ];

    if (cafe.address.isNotEmpty) {
      children.add(
        _InfoLine(
          icon: AppIcons.location,
          text: cafe.address,
          onTap: _buildMapOnTap(context),
        ),
      );
    }

    if (cafe.phoneNumber != null && cafe.phoneNumber!.isNotEmpty) {
      children.add(const SizedBox(height: AppSpacing.xs));
      children.add(
        _InfoLine(
          icon: AppIcons.phone,
          text: cafe.phoneNumber!,
          onTap: () => _callPhone(context, cafe.phoneNumber!),
        ),
      );
    }

    if (cafe.description != null && cafe.description!.isNotEmpty) {
      children.add(const SizedBox(height: AppSpacing.sm));
      children.add(
        Text(
          cafe.description!,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
      );
    }

    if (cafe.numberOfTables > 0 || cafe.numberOfGamesOwned > 0) {
      children.add(const SizedBox(height: AppSpacing.sm));
      children.add(_StatsRow(cafe: cafe));
    }

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  VoidCallback? _buildMapOnTap(BuildContext context) {
    final lat = cafe.latitude;
    final lng = cafe.longitude;
    if (lat == null || lng == null) return null;
    return () => _openMap(context, lat, lng);
  }

  Future<void> _openMap(BuildContext context, double lat, double lng) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _callPhone(BuildContext context, String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

class _CafeNameRow extends StatelessWidget {
  final CafeDetailEntity cafe;
  final ThemeData theme;

  const _CafeNameRow({required this.cafe, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _CafeTitle(cafe: cafe, theme: theme)),
        const SizedBox(width: AppSpacing.sm),
        _OperationalBadge(cafe: cafe),
      ],
    );
  }
}

class _CafeTitle extends StatelessWidget {
  final CafeDetailEntity cafe;
  final ThemeData theme;

  const _CafeTitle({required this.cafe, required this.theme});

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      Text(
        cafe.name,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w900,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    ];

    if (cafe.distanceKm != null) {
      children.add(const SizedBox(height: 2));
      children.add(
        Row(
          children: [
            Icon(
              Icons.near_me_rounded,
              size: 13,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 4),
            Text(
              '${cafe.distanceKm!.toStringAsFixed(1)} km',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onTap;

  const _InfoLine({
    required this.icon,
    required this.text,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final tappable = onTap != null;

    final content = Row(
      children: [
        Icon(icon, size: 16, color: colors.onSurfaceVariant),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: tappable ? colors.primary : colors.onSurface,
              fontWeight: tappable ? FontWeight.w700 : FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (tappable) ...[
          const SizedBox(width: 4),
          Icon(
            Icons.open_in_new_rounded,
            size: 14,
            color: colors.primary,
          ),
        ],
      ],
    );

    if (!tappable) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: content,
      ),
    );
  }
}

class _OperationalBadge extends StatelessWidget {
  final CafeDetailEntity cafe;

  const _OperationalBadge({required this.cafe});

  @override
  Widget build(BuildContext context) {
    final isOpen = cafe.isCurrentlyOpen;
    final color = isOpen ? AppColors.success : AppColors.error;
    final icon =
        isOpen ? Icons.toggle_on_rounded : Icons.toggle_off_rounded;
    final label = isOpen ? 'ĐANG MỞ' : 'ĐÃ ĐÓNG';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final CafeDetailEntity cafe;

  const _StatsRow({required this.cafe});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final pills = <Widget>[];

    if (cafe.numberOfTables > 0) {
      pills.add(_MiniPill(
        icon: Icons.table_restaurant_rounded,
        label: '${cafe.numberOfTables} bàn',
      ));
    }
    if (cafe.numberOfGamesOwned > 0) {
      pills.add(_MiniPill(
        icon: Icons.casino_rounded,
        label: '${cafe.numberOfGamesOwned} game',
      ));
    }
    if (cafe.hasGameMaster) {
      pills.add(const _MiniPill(
        icon: Icons.support_agent_rounded,
        label: 'Có GM',
      ));
    }
    if (cafe.numberOfPrivateRooms > 0) {
      pills.add(_MiniPill(
        icon: Icons.meeting_room_rounded,
        label: '${cafe.numberOfPrivateRooms} phòng riêng',
      ));
    }

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: pills.map((p) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xxs,
          ),
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: colors.primary.withValues(alpha: 0.35),
              width: 1,
            ),
          ),
          child: p,
        );
      }).toList(),
    );
  }
}

class _MiniPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MiniPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: colors.primary),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: colors.primary,
            fontWeight: FontWeight.w800,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _CafeInfoSkeleton extends StatelessWidget {
  const _CafeInfoSkeleton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        0,
      ),
      height: 80,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: AppRadius.radiusLgAll,
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: 2,
        ),
      ),
      alignment: Alignment.center,
      child: const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}