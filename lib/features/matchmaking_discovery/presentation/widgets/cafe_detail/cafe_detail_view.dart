import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/neo_brutalism_theme.dart';
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

/// Body của [CafeDetailPage] — Neo-brutalism style.
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
    final isDark = theme.brightness == Brightness.dark;

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            // SliverAppBar với neo-brutalism back button
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              backgroundColor:
                  isDark ? AppColors.surfaceDark : AppColors.surface,
              iconTheme: IconThemeData(
                color: AppColors.white,
              ),
              leading: Container(
                margin: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.black,
                    width: 2,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.black,
                      blurRadius: 0,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: AppColors.black,
                    size: 18,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
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
                              AppColors.black.withValues(alpha: 0.6),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: AppSpacing.paddingAllMd,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cafe.name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    PricingCard(cafe: cafe),
                    const SizedBox(height: AppSpacing.md),
                    const CafeSectionTitle(
                      title: 'Liên hệ',
                      icon: Icons.contact_phone,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    CafeInfoRow(
                      icon: Icons.place_outlined,
                      text: cafe.address,
                    ),
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
                        onTap: () =>
                            _openMap(cafe.latitude!, cafe.longitude!),
                      ),
                    ],
                    if (cafe.description != null &&
                        cafe.description!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.lg),
                      const CafeSectionTitle(
                        title: 'Giới thiệu',
                        icon: Icons.info_outline,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        padding: AppSpacing.paddingAllMd,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.surfaceDark
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark
                                ? AppColors.borderDark
                                : AppColors.border,
                            width: NeoBrutalismTheme.borderWidth,
                          ),
                        ),
                        child: Text(
                          cafe.description!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    const CafeSectionTitle(
                      title: 'Thông tin thêm',
                      icon: Icons.more_horiz,
                    ),
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

        // Sticky bottom CTA
        if (selectedGame != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surface,
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColors.borderDark : AppColors.border,
                    width: NeoBrutalismTheme.borderWidth,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.1),
                    blurRadius: 0,
                    offset: const Offset(0, -3),
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
