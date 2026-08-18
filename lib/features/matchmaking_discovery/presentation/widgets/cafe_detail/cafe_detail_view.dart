import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/neo_brutalism_theme.dart';
import '../../../../../core/widgets/safe_network_image.dart';
import '../../../../lobby_management/presentation/widgets/lobby_game_picker_sheet.dart';
import '../../../domain/entities/board_game_entity.dart';
import '../../../domain/entities/cafe_detail_entity.dart';
import '../../../domain/entities/cafe_entity.dart';
import '../../pages/lobby_config_page.dart';
import '../../cubit/matchmaking_cubit.dart';
import '../../cubit/matchmaking_state.dart';
import 'amenities_card.dart';
import 'book_cta_button.dart';
import 'cafe_info_row.dart';
import 'cafe_section_title.dart';
import 'deposit_card.dart';
import 'lobby_config_card.dart';
import 'operational_status_card.dart';
import 'pricing_card.dart';
import 'refund_policy_card.dart';
import 'seat_capacity_card.dart';
import 'se_pay_badge.dart';
import 'tappable_info_row.dart';
import 'time_slot_grid.dart';

/// Body của [CafeDetailPage] — Neo-brutalism style.
class CafeDetailView extends StatelessWidget {
  final CafeDetailEntity cafe;
  final BoardGameEntity? selectedGame;
  final CafeEntity? cafeEntity;
  final MatchmakingCubit matchmakingCubit;

  const CafeDetailView({
    super.key,
    required this.cafe,
    this.selectedGame,
    this.cafeEntity,
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
                    // ─── Header: name + distance ─────────────────────
                    Text(
                      cafe.name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                      ),
                    ),
                    if (cafe.distanceKm != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          const Icon(
                            Icons.near_me_rounded,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${cafe.distanceKm!.toStringAsFixed(1)} km từ bạn',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),

                    // ─── Operational status (BR-05) ──────────────────
                    OperationalStatusCard(cafe: cafe),
                    const SizedBox(height: AppSpacing.md),

                    // ─── Pricing card ────────────────────────────────
                    PricingCard(cafe: cafe),
                    const SizedBox(height: AppSpacing.md),

                    // ─── Seat capacity (live) ────────────────────────
                    SeatCapacityCard(cafe: cafe),

                    // ─── Ghế trống theo khung giờ ────────────────────
                    TimeSlotGrid(cafe: cafe),

                    // ─── Tiện ích ────────────────────────────────────
                    if ((cafe.numberOfTables > 0 ||
                            cafe.numberOfPrivateRooms > 0 ||
                            cafe.numberOfGamesOwned > 0 ||
                            cafe.hasGameMaster)) ...[
                      const SizedBox(height: AppSpacing.lg),
                      const CafeSectionTitle(
                        title: 'Tiện ích',
                        icon: Icons.dashboard_customize_rounded,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AmenitiesCard(
                        numberOfTables: cafe.numberOfTables,
                        numberOfPrivateRooms: cafe.numberOfPrivateRooms,
                        numberOfGamesOwned: cafe.numberOfGamesOwned,
                        hasGameMaster: cafe.hasGameMaster,
                      ),
                    ],

                    // ─── Đặt cọc ─────────────────────────────────────
                    if (cafe.depositPercentage > 0 ||
                        cafe.depositRatePerPerson > 0 ||
                        (cafe.minDeposit != null && cafe.minDeposit! > 0)) ...[
                      const SizedBox(height: AppSpacing.lg),
                      const CafeSectionTitle(
                        title: 'Đặt cọc',
                        icon: Icons.account_balance_wallet_rounded,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      DepositCard(cafe: cafe),
                    ],

                    // ─── Refund policy ───────────────────────────────
                    const SizedBox(height: AppSpacing.lg),
                    const CafeSectionTitle(
                      title: 'Chính sách hoàn tiền',
                      icon: Icons.replay_circle_filled_rounded,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    RefundPolicyCard(cafe: cafe),

                    // ─── Lobby config ────────────────────────────────
                    if (cafe.cafeConfig != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      const CafeSectionTitle(
                        title: 'Quy định lobby',
                        icon: Icons.groups_rounded,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      LobbyConfigCard(cafe: cafe),
                    ],

                    // ─── Liên hệ ────────────────────────────────────
                    const SizedBox(height: AppSpacing.lg),
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

                    // ─── Giới thiệu ──────────────────────────────────
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

                    // ─── Thông tin thêm ──────────────────────────────
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
                    // Bottom safe-area cho CTA.
                    const SizedBox(height: AppSpacing.huge + AppSpacing.lg),
                  ],
                ),
              ),
            ),
          ],
        ),

        // ─── Sticky bottom CTA — luôn hiển thị ─────────────────────
        // Player có thể chọn quán trước (từ tab Cafe) → ấn "Đặt chỗ"
        // → hiện game picker để chọn game. Hoặc chọn game trước → chọn cafe
        // → đi thẳng sang LobbyCafeSelectionPage.
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
                gameName: selectedGame?.name,
                onPressed: selectedGame == null
                    ? () => _showGamePicker(context)
                    : () {
                        // Dùng push (không phải pushReplacement) để giữ
                        // CafeDetailPage trong stack — khi player ấn back
                        // từ LobbyConfigPage sẽ quay lại đây.
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LobbyConfigPage(
                              gameId: selectedGame!.id,
                              gameName: selectedGame!.name,
                              cafeId: cafe.id,
                              cafeName: cafe.name,
                              cafeEntity: cafeEntity,
                              matchmakingCubit: matchmakingCubit,
                              gameEntity: selectedGame,
                            ),
                          ),
                        );
                      },
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Hiện bottom sheet chọn game khi player ấn "Đặt chỗ" mà chưa chọn game.
  ///
  /// Sau khi chọn game → đi thẳng sang [LobbyConfigPage] với cafe đã có.
  /// Không cần qua [LobbyCafeSelectionPage] vì player đã ở trong cafe rồi.
  ///
  /// Stack navigation: dùng `Navigator.push` (không phải pushReplacement)
  /// để giữ CafeDetailPage trong stack — khi player ấn back từ
  /// LobbyConfigPage sẽ quay lại trang chi tiết cafe thay vì thoát ra
  /// SearchPage.
  Future<void> _showGamePicker(BuildContext context) async {
    // Đảm bảo cubit có search results để picker hiển thị. Pattern này
    // giống [LobbyCafeSelectionPage._onChangeGamePressed] — chỉ fetch nếu
    // state chưa có, tránh gọi API thừa.
    if (matchmakingCubit.state is! MatchmakingSearchResults) {
      await matchmakingCubit.searchGames();
      if (!context.mounted) return;
    }

    final state = matchmakingCubit.state;
    final games = state is MatchmakingSearchResults
        ? state.games
        : const <BoardGameEntity>[];

    if (!context.mounted) return;

    // Mở bottom sheet chọn game
    final picked = await showModalBottomSheet<BoardGameEntity>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => LobbyGamePickerSheet(games: games),
    );

    if (picked == null || !context.mounted) return;

    // Đi thẳng sang LobbyConfigPage với cafe đã chọn.
    // Dùng push (không phải pushReplacement) để giữ CafeDetailPage trong
    // stack — khi player ấn back từ LobbyConfigPage sẽ quay lại trang chi
    // tiết cafe.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LobbyConfigPage(
          gameId: picked.id,
          gameName: picked.name,
          cafeId: cafe.id,
          cafeName: cafe.name,
          cafeEntity: cafeEntity,
          matchmakingCubit: matchmakingCubit,
          gameEntity: picked,
        ),
      ),
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