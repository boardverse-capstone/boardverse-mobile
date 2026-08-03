import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/safe_network_image.dart';
import '../../domain/entities/board_game_entity.dart';
import '../../domain/entities/cafe_detail_entity.dart';
import '../cubit/cafe_detail_cubit.dart';
import '../cubit/cafe_detail_state.dart';
import '../cubit/matchmaking_cubit.dart';
import 'lobby_cafe_selection_page.dart';

/// Trang xem chi tiết quán cafe.
///
/// User tap vào CafeCard → vào đây xem thông tin quán.
/// Từ đây mới có CTA để đặt lobby.
class CafeDetailPage extends StatelessWidget {
  final String cafeId;
  final BoardGameEntity? selectedGame;
  final MatchmakingCubit matchmakingCubit;

  const CafeDetailPage({
    super.key,
    required this.cafeId,
    this.selectedGame,
    required this.matchmakingCubit,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          CafeDetailCubit(matchmakingCubit.repository)..loadCafeDetail(cafeId),
      child: _CafeDetailView(
        selectedGame: selectedGame,
        matchmakingCubit: matchmakingCubit,
      ),
    );
  }
}

class _CafeDetailView extends StatelessWidget {
  final BoardGameEntity? selectedGame;
  final MatchmakingCubit matchmakingCubit;

  const _CafeDetailView({
    required this.selectedGame,
    required this.matchmakingCubit,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<CafeDetailCubit, CafeDetailState>(
        builder: (context, state) {
          if (state is CafeDetailLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is CafeDetailError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Quay lại'),
                  ),
                ],
              ),
            );
          }

          if (state is CafeDetailLoaded) {
            return _buildContent(context, state.cafe);
          }

          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, CafeDetailEntity cafe) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            // ── AppBar with image ────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              backgroundColor: theme.colorScheme.surface,
              iconTheme: const IconThemeData(color: Colors.white),
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    SafeNetworkImage(
                      url: cafe.imageUrl ?? '',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.storefront,
                          size: 80,
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ),
                    // Gradient overlay
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 80,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.6),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Cafe info ────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: AppSpacing.paddingAllMd,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      cafe.name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // ── Pricing Card ────────────────────────────────────
                    _PricingCard(cafe: cafe),
                    const SizedBox(height: AppSpacing.md),

                    // ── Contact Info ────────────────────────────────────
                    _SectionTitle(title: 'Liên hệ'),
                    const SizedBox(height: AppSpacing.sm),
                    _InfoRow(icon: Icons.place_outlined, text: cafe.address),
                    if (cafe.phoneNumber != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _TappableInfoRow(
                        icon: Icons.phone_outlined,
                        text: cafe.phoneNumber!,
                        onTap: () => _callPhone(cafe.phoneNumber!),
                      ),
                    ],
                    if (cafe.latitude != null && cafe.longitude != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _TappableInfoRow(
                        icon: Icons.map_outlined,
                        text: 'Xem trên bản đồ',
                        onTap: () => _openMap(cafe.latitude!, cafe.longitude!),
                      ),
                    ],

                    // ── Description ───────────────────────────────────────
                    if (cafe.description != null &&
                        cafe.description!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.lg),
                      _SectionTitle(title: 'Giới thiệu'),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        cafe.description!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                        ),
                      ),
                    ],

                    // ── Additional Info ──────────────────────────────────
                    const SizedBox(height: AppSpacing.lg),
                    _SectionTitle(title: 'Thông tin thêm'),
                    const SizedBox(height: AppSpacing.sm),
                    _InfoRow(
                      icon: Icons.calendar_today_outlined,
                      text: 'Tham gia: ${_formatDate(cafe.createdAt)}',
                    ),
                    if (cafe.totalSeats != null && cafe.totalSeats! > 0) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _InfoRow(
                        icon: Icons.event_seat_outlined,
                        text: 'Sức chứa: ${cafe.totalSeats} ghế',
                      ),
                    ],

                    // ── SePay Badge ─────────────────────────────────────
                    if (cafe.hasSePayConfigured) ...[
                      const SizedBox(height: AppSpacing.md),
                      _SePayBadge(),
                    ],

                    const SizedBox(height: AppSpacing.huge + AppSpacing.lg),
                  ],
                ),
              ),
            ),
          ],
        ),

        // ── Sticky bottom CTA ─────────────────────────────────────────
        if (selectedGame != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.colorScheme.surface.withValues(alpha: 0.95),
                    theme.colorScheme.surface,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: _BookCtaButton(
                  gameName: selectedGame!.name,
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LobbyCafeSelectionPage(
                        game: selectedGame!,
                        matchmakingCubit: matchmakingCubit,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _callPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openMap(double lat, double lng) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

/// Pricing card hiển thị giá và tiền cọc.
class _PricingCard extends StatelessWidget {
  final CafeDetailEntity cafe;

  const _PricingCard({required this.cafe});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: AppRadius.radiusMdAll,
        border: Border.all(color: theme.colorScheme.primaryContainer),
      ),
      child: Column(
        children: [
          // Price row
          Row(
            children: [
              Icon(
                Icons.sell_outlined,
                size: 24,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Giá thuê',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    Text(
                      cafe.priceDisplay,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: AppRadius.radiusSmAll,
                ),
                child: Text(
                  _billingModelLabel(cafe.billingModel),
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
            ],
          ),
          if (cafe.depositPercentage != null) ...[
            const SizedBox(height: AppSpacing.sm),
            const Divider(),
            const SizedBox(height: AppSpacing.sm),
            // Deposit row
            Row(
              children: [
                Icon(
                  Icons.payments_outlined,
                  size: 20,
                  color: theme.colorScheme.secondary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text('Tiền cọc', style: theme.textTheme.bodyMedium),
                ),
                Text(
                  cafe.depositDisplay,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _billingModelLabel(BillingModel model) {
    switch (model) {
      case BillingModel.timeBased:
        return 'Theo giờ';
      case BillingModel.fixed:
        return 'Cố định';
      case BillingModel.tiered:
        return 'Lũy tiến';
    }
  }
}

/// Section title.
class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: theme.colorScheme.primary,
      ),
    );
  }
}

/// Info row đơn giản.
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.outline),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
      ],
    );
  }
}

/// Info row có thể tap để thực hiện action.
class _TappableInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const _TappableInfoRow({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.radiusSmAll,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: theme.colorScheme.outline,
            ),
          ],
        ),
      ),
    );
  }
}

/// SePay badge hiển thị quán có thanh toán SePay.
class _SePayBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: AppRadius.radiusSmAll,
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified, size: 18, color: Colors.green),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'Hỗ trợ thanh toán SePay',
            style: theme.textTheme.labelMedium?.copyWith(
              color: Colors.green.shade700,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// CTA button nổi bật để đặt chỗ.
class _BookCtaButton extends StatelessWidget {
  final String gameName;
  final VoidCallback onPressed;

  const _BookCtaButton({required this.gameName, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md + 4,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.calendar_today_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Đặt chỗ ngay',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Chơi $gameName',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
