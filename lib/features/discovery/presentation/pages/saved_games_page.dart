import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/neo_brutalism_theme.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/safe_network_image.dart';
import '../../../../core/widgets/unsaved_confirmation_dialog.dart';
import '../../../matchmaking_discovery/presentation/cubit/matchmaking_cubit.dart';
import '../../../matchmaking_discovery/presentation/pages/board_game_detail_page.dart';
import '../../domain/entities/saved_board_game_entity.dart';
import '../cubit/saved_games_cubit.dart';
import '../cubit/saved_games_state.dart';
import '../widgets/saved_games_shimmer.dart';

/// Trang danh sách game đã lưu.
///
/// Hiển thị danh sách board game mà player đã lưu (bookmark).
/// - Player có thể tap để xem chi tiết game (navigate đến board game detail).
/// - Player có thể bỏ lưu game bằng cách tap icon bookmark.
/// - Khi bỏ lưu, hiện confirmation dialog để xác nhận.
/// - Khi lưu, KHÔNG hiển thị dialog (lưu thoải mái không cần xác nhận).
///
/// **QUAN TRỌNG — Bloc lifecycle:**
/// Cubit được đăng ký là `LazySingleton` trong `getIt` (chia sẻ toàn app).
/// `MainScaffold` cung cấp cubit qua `BlocProvider.value(...)` và gọi
/// `loadSavedGames()` trong `initState`. Trang này dùng `BlocProvider.value`
/// (KHÔNG phải `create:`) để TIẾP TỤC dùng chung instance đó — tránh gọi
/// `close()` khi widget dispose. Nếu dùng `create:`, cubit bị close → lần
/// mở trang sau `emit(...)` trong `loadSavedGames()` throw trước khi gọi
/// API → treo loading vĩnh viễn (xem bug #saved-loading-stuck).
class SavedGamesPage extends StatefulWidget {
  const SavedGamesPage({super.key});

  @override
  State<SavedGamesPage> createState() => _SavedGamesPageState();
}

class _SavedGamesPageState extends State<SavedGamesPage> {
  @override
  void initState() {
    super.initState();
    // Fallback: nếu vì lý do nào đó cubit chưa được load (vd: page được
    // navigate tới mà không qua MainScaffold, hoặc login mới mà cubit
    // bị reset về Initial), trigger load sau khi frame đầu tiên build xong
    // để tránh emit trong lúc đang build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cubit = context.read<SavedGamesCubit>();
      if (cubit.state is SavedGamesInitial) {
        cubit.loadSavedGames();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Chia sẻ cubit với parent (MainScaffold) thông qua getIt.
    // KHÔNG dùng `BlocProvider(create: ...)` vì:
    // 1. `create:` sẽ gọi `close()` lên cubit khi widget dispose
    // 2. Cubit là LazySingleton → sau khi close, `isClosed = true` vĩnh viễn
    // 3. Lần mở trang sau: `loadSavedGames()` gọi `emit(...)` đầu tiên
    //    → throw "Cannot emit new states after calling close"
    // 4. Throw xảy ra TRƯỚC khi gọi `_repository.getSavedGames()`
    //    → API không bao giờ được gọi → treo loading mãi.
    return BlocProvider<SavedGamesCubit>.value(
      value: getIt<SavedGamesCubit>(),
      child: const _SavedGamesPageContent(),
    );
  }
}

class _SavedGamesPageContent extends StatelessWidget {
  const _SavedGamesPageContent();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: const Text('Game đã lưu'),
        centerTitle: true,
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        elevation: 0,
      ),
      body: BlocBuilder<SavedGamesCubit, SavedGamesState>(
        builder: (context, state) {
          if (state is SavedGamesInitial ||
              state is SavedGamesLoadingFromCache) {
            // Dùng shimmer grid thay cho CircularProgressIndicator — khớp
            // với pattern loading toàn app (Material Design 3 recommended
            // skeleton loaders). Giữ `physics: AlwaysScrollable` để
            // RefreshIndicator vẫn pull-to-refresh được khi rỗng.
            return const SavedGamesShimmer();
          }

          if (state is SavedGamesError && state.games == null) {
            return ErrorStateWidget(
              message: state.message,
              onRetry: () => context.read<SavedGamesCubit>().loadSavedGames(),
            );
          }

          final games = state is SavedGamesLoaded
              ? state.games
              : state is SavedGamesRefreshing
                  ? state.games
                  : state is SavedGamesError
                      ? state.games ?? []
                      : [];

          if (games.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.bookmark_border_rounded,
              title: 'Chưa có game nào',
              message:
                  'Lưu game bạn thích bằng cách nhấn icon bookmark trên game card',
            );
          }

          return RefreshIndicator(
            onRefresh: () => context.read<SavedGamesCubit>().refresh(),
            child: GridView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                childAspectRatio: 0.72,
              ),
              itemCount: games.length,
              itemBuilder: (context, i) {
                final game = games[i];
                // **Defensive (2026-10-03 fix):** nếu 1 game entity bị
                // malformed (vd: category list chứa non-String, weight
                // NaN, ...), 1 card throw sẽ làm crash cả grid → user
                // mất toàn bộ danh sách. Wrap trong try-catch để:
                // 1. Render placeholder card lỗi cho entry đó
                // 2. Các card khác vẫn hiển thị bình thường
                // 3. Log exception để debug.
                try {
                  return _SavedGameCard(
                    game: game,
                    onTap: () => _openBoardGameDetail(
                      context,
                      game.gameTemplateId,
                    ),
                    onUnsave: () => _showUnsaveConfirmation(context, game),
                  );
                } catch (e, stack) {
                  debugPrint(
                    '[SavedGamesPage] Failed to build card for game '
                    '${game.gameTemplateId}: $e\n$stack',
                  );
                  return _BrokenGameCard(
                    gameId: game.gameTemplateId,
                    gameName: game.gameName,
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }

  /// Show confirmation dialog before unsaving a game.
  Future<void> _showUnsaveConfirmation(
    BuildContext context,
    SavedBoardGameEntity game,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => UnsavedConfirmationDialog(
        gameName: game.gameName,
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<SavedGamesCubit>().toggleSave(game.gameTemplateId);
    }
  }

  /// Mở `BoardGameDetailPage` cho một game đã lưu.
  ///
  /// **Vì sao cần helper riêng:**
  /// - `MatchmakingCubit` được provide ở root MultiBlocProvider (main.dart),
  ///   nên `context.read<MatchmakingCubit>()` luôn trả về instance dùng
  ///   chung toàn app — khớp với luồng navigate từ DiscoveryResultsPage /
  ///   SearchPage / SimilarGamesCarousel.
  /// - Reuse đúng `BoardGameDetailPage` đã có sẵn → UX nhất quán với các
  ///   entry point khác: header save/unsave, "QUÁN CÓ BOARD GAME NÀY",
  ///   sticky CTA "MỘT MÌNH" / "TẠO LOBBY", alternative suggestions...
  ///
  /// **Defensive:** nếu vì lý do nào đó (test wrapper, deep-link route
  /// thiếu provider) `MatchmakingCubit` không có trong scope → fail soft
  /// bằng cách show snackbar thay vì crash đỏ.
  void _openBoardGameDetail(BuildContext context, String gameId) {
    try {
      final matchmakingCubit = context.read<MatchmakingCubit>();
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BoardGameDetailPage(
            gameId: gameId,
            matchmakingCubit: matchmakingCubit,
          ),
        ),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể mở chi tiết game. Vui lòng thử lại.'),
        ),
      );
    }
  }
}

/// Card hiển thị một game đã lưu trong danh sách.
///
/// UI tương tự RecommendedGameCard nhưng có mục đích sử dụng khác:
/// - Hiển thị trong màn hình "Game đã lưu" (SavedGamesPage).
/// - Có icon bookmark ở góc để bỏ lưu (với confirmation dialog).
/// - Tap vào card để xem chi tiết game.
class _SavedGameCard extends StatefulWidget {
  const _SavedGameCard({
    required this.game,
    required this.onTap,
    required this.onUnsave,
  });

  final SavedBoardGameEntity game;
  final VoidCallback onTap;
  final VoidCallback onUnsave;

  @override
  State<_SavedGameCard> createState() => _SavedGameCardState();
}

class _SavedGameCardState extends State<_SavedGameCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // **Defensive (2026-10-03 fix):** chuẩn hoá các field có thể null
    // hoặc rỗng từ entity. Nếu entity bị malformed (vd: BE trả data
    // thiếu field), tránh widget build ném exception không bắt được.
    //
    // Lưu ý: Ở tầng cubit đã có try-catch emit SavedGamesError khi
    // model parse lỗi, nên user thường sẽ thấy ErrorStateWidget thay
    // vì danh sách game. Nhưng đây là lớp phòng thủ cuối cùng để đảm
    // bảo UI không bao giờ render đỏ do dữ liệu lỗi.
    final game = widget.game;
    final gameName = game.gameName.isEmpty ? '(Chưa có tên)' : game.gameName;
    final categories = game.categories;
    final weight = game.weight;
    final playTime = game.playTime;
    final thumbnailUrl = game.thumbnailUrl;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Container(
          decoration: NeoBrutalismTheme.autoBox(
            context,
            backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
            borderRadius: 16,
            shadowColor: AppColors.accent.withValues(alpha: 0.15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail with bookmark overlay
              Expanded(
                child: Stack(
                  children: [
                    // Thumbnail image
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(14),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: double.infinity,
                        child: thumbnailUrl != null && thumbnailUrl.isNotEmpty
                            ? SafeNetworkImage(
                                url: thumbnailUrl,
                                fit: BoxFit.cover,
                              )
                            : _buildPlaceholder(isDark),
                      ),
                    ),

                    // Gradient overlay for better text contrast
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(14),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.1),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.25),
                            ],
                            stops: const [0.0, 0.4, 1.0],
                          ),
                        ),
                      ),
                    ),

                    // Unsave button (bookmark filled)
                    Positioned(
                      top: AppSpacing.xs,
                      right: AppSpacing.xs,
                      child: _UnsaveButton(onTap: widget.onUnsave),
                    ),

                    // Category chip (bottom-left)
                    if (categories.isNotEmpty)
                      Positioned(
                        bottom: AppSpacing.xs,
                        left: AppSpacing.xs,
                        child: _CategoryChip(
                          category: categories.first,
                        ),
                      ),
                  ],
                ),
              ),

              // Info section
              Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Game name
                    Text(
                      gameName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xxs + 2),

                    // Stats row: weight + play time
                    Row(
                      children: [
                        if (weight != null) ...[
                          _StatBadge(
                            icon: Icons.balance_rounded,
                            label: weight.toStringAsFixed(1),
                            color: _weightColor(weight),
                          ),
                          const SizedBox(width: AppSpacing.xxs + 2),
                        ],
                        if (playTime != null)
                          _StatBadge(
                            icon: Icons.schedule_rounded,
                            label: '$playTime phút',
                            color: AppColors.primary,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(bool isDark) {
    return Container(
      color: isDark
          ? AppColors.surfaceContainerDark
          : AppColors.surfaceVariant,
      child: Center(
        child: Icon(
          Icons.sports_esports_outlined,
          size: 40,
          color: isDark
              ? AppColors.textTertiaryDark
              : AppColors.textTertiary,
        ),
      ),
    );
  }

  Color _weightColor(double w) {
    if (w <= 1.99) return AppColors.success;
    if (w <= 2.99) return const Color(0xFF8BC34A);
    if (w <= 3.49) return AppColors.warning;
    if (w <= 3.99) return AppColors.primary;
    return AppColors.error;
  }
}

/// Bookmark button to unsave a game.
///
/// Uses GestureDetector with HitTestBehavior.opaque for reliable tap handling.
class _UnsaveButton extends StatefulWidget {
  const _UnsaveButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_UnsaveButton> createState() => _UnsaveButtonState();
}

class _UnsaveButtonState extends State<_UnsaveButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.85 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.9),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.85),
              width: 2,
            ),
            boxShadow: NeoBrutalismTheme.lightShadow(
              shadowColor: Colors.black.withValues(alpha: 0.3),
            ),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.bookmark_rounded,
            size: 20,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// Category chip overlay at bottom-left of thumbnail.
class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs + 2,
        vertical: AppSpacing.xxs + 1,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Text(
        category.toUpperCase(),
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: 0.5,
          height: 1.0,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// Small stat badge showing weight or play time.
class _StatBadge extends StatelessWidget {
  const _StatBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxs + 2,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

/// Placeholder card hiển thị khi 1 [SavedBoardGameEntity] bị lỗi
/// build (vd: field malformed, cast fail, image loader crash...).
///
/// **Mục đích (2026-10-03):** trước đây nếu 1 card trong GridView
/// throw exception, toàn bộ GridView bị Flutter đánh dấu broken →
/// user mất trắng danh sách. Sau fix: card lỗi render placeholder
/// này, các card khác vẫn hiển thị bình thường.
class _BrokenGameCard extends StatelessWidget {
  final String gameId;
  final String gameName;

  const _BrokenGameCard({
    required this.gameId,
    required this.gameName,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: NeoBrutalismTheme.autoBox(
        context,
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: 16,
        shadowColor: AppColors.error.withValues(alpha: 0.15),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image_rounded,
            size: 32,
            color: AppColors.error.withValues(alpha: 0.7),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Lỗi hiển thị',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          if (gameName.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Text(
                gameName,
                style: TextStyle(
                  fontSize: 10,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}
