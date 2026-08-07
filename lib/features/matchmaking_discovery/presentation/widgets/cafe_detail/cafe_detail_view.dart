import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/safe_network_image.dart';
import '../../../domain/entities/board_game_entity.dart';
import '../../../domain/entities/cafe_detail_entity.dart';
import '../../pages/lobby_cafe_selection_page.dart';
import '../../cubit/matchmaking_cubit.dart';
import 'book_cta_button.dart';
import 'cafe_info_row.dart';
import 'cafe_section_title.dart';
import 'pricing_card.dart';
import 'se_pay_badge.dart';
import 'tappable_info_row.dart';

/// Body của [CafeDetailPage] — render Stack(SliverAppBar + Content + Sticky CTA).
///
/// Nhận sẵn [cafe] đã được load (parent chịu trách nhiệm xử lý loading/error).
class CafeDetailView extends StatelessWidget {
  final CafeDetailEntity cafe;
  final BoardGameEntity? selectedGame;
  final MatchmakingCubit matchmakingCubit;

  const CafeDetailView({
    super.key,
    required this.cafe,
    required this.selectedGame,
    required this.matchmakingCubit,
  });

  @override
  Widget build(BuildContext context) {
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
                    PricingCard(cafe: cafe),
                    const SizedBox(height: AppSpacing.md),

                    // ── Contact Info ────────────────────────────────────
                    CafeSectionTitle(title: 'Liên hệ'),
                    const SizedBox(height: AppSpacing.sm),
                    CafeInfoRow(icon: Icons.place_outlined, text: cafe.address),
                    if (cafe.phoneNumber != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      TappableInfoRow(
                        icon: Icons.phone_outlined,
                        text: cafe.phoneNumber!,
                        onTap: () => _callPhone(cafe.phoneNumber!),
                      ),
                    ],
                    if (cafe.latitude != null && cafe.longitude != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      TappableInfoRow(
                        icon: Icons.map_outlined,
                        text: 'Xem trên bản đồ',
                        onTap: () => _openMap(cafe.latitude!, cafe.longitude!),
                      ),
                    ],

                    // ── Description ───────────────────────────────────────
                    if (cafe.description != null &&
                        cafe.description!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.lg),
                      CafeSectionTitle(title: 'Giới thiệu'),
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
                    CafeSectionTitle(title: 'Thông tin thêm'),
                    const SizedBox(height: AppSpacing.sm),
                    CafeInfoRow(
                      icon: Icons.calendar_today_outlined,
                      text: 'Tham gia: ${_formatDate(cafe.createdAt)}',
                    ),
                    if (cafe.totalSeats != null && cafe.totalSeats! > 0) ...[
                      const SizedBox(height: AppSpacing.sm),
                      CafeInfoRow(
                        icon: Icons.event_seat_outlined,
                        text: 'Sức chứa: ${cafe.totalSeats} ghế',
                      ),
                    ],

                    // ── SePay Badge ─────────────────────────────────────
                    if (cafe.hasSePayConfigured) ...[
                      const SizedBox(height: AppSpacing.md),
                      const SePayBadge(),
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
                child: BookCtaButton(
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