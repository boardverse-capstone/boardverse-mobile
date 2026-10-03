import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/neo_brutalism_theme.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/safe_network_image.dart';
import '../../../discovery/presentation/cubit/saved_games_cubit.dart';
import '../../../discovery/presentation/cubit/saved_games_state.dart';
import '../../domain/entities/board_game_entity.dart';

/// Neo-brutalism hero SliverAppBar cho trang chi tiết board game.
///
/// TRẺN: Đặt trực tiếp trong `CustomScrollView.slivers` (KHÔNG lồng trong
/// `SliverMainAxisGroup`) để `pinned: true` hoạt động đúng. Khi SliverAppBar
/// bị wrap trong SliverMainAxisGroup, pinned bị ignore hoặc hoạt động sai.
/// Phần category/rating/stats bên dưới để riêng trong `GameDetailMetaInfo`.
///
/// **Bookmark icon** (góc trên bên phải):
/// - Hiển thị trạng thái `isSaved` ban đầu từ API (build 2026-10-03+:
///   field `isSaved` top-level trong response `GET .../active-cafes`).
/// - Tap → gọi `SavedGamesCubit.toggleSave(gameId)` (optimistic update).
/// - UI reactive: BlocBuilder + actions stream → icon flip ngay + toast
///   khi API hoàn tất (thành công/thất bại).
///
/// **Backward compat**: nếu `isSaved` prop = false (mặc định / user chưa
/// login / backend cũ), vẫn cho tap để gọi toggleSave — SavedGamesCubit
/// sẽ tự lấy state từ cache local.
class GameDetailSliverAppBar extends StatefulWidget {
  final BoardGameEntity game;
  final bool isSaved;

  const GameDetailSliverAppBar({
    super.key,
    required this.game,
    this.isSaved = false,
  });

  @override
  State<GameDetailSliverAppBar> createState() => _GameDetailSliverAppBarState();
}

class _GameDetailSliverAppBarState extends State<GameDetailSliverAppBar> {
  @override
  void initState() {
    super.initState();
    // Lưu ý: actions stream subscription đã được chuyển vào
    // [_HeaderSaveButton] (StatefulWidget, tự quản lý lifecycle). Tap
    // + toast + pulse animation đều handle trong button → không cần
    // subscribe ở parent, tránh duplicate toast khi user bấn save.
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // SliverAppBar ở đây — pinned=true bắt buộc phải nằm trực tiếp
    // trong CustomScrollView.slivers, không lồng trong SliverMainAxisGroup.
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      stretch: true,
      scrolledUnderElevation: 4,
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shadowColor: AppColors.black.withValues(alpha: 0.15),
      title: Text(
        widget.game.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      titleTextStyle: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w900,
        color: isDark
            ? AppColors.textPrimaryDark
            : AppColors.textPrimary,
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
      actions: [
        _HeaderSaveButton(
          gameId: widget.game.id,
          initialIsSaved: widget.isSaved,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsetsDirectional.only(
          start: AppSpacing.md,
          end: AppSpacing.md,
          bottom: AppSpacing.md + 40,
        ),
        title: Text(
          widget.game.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: AppColors.white,
            shadows: [
              Shadow(
                offset: Offset(0, 1),
                blurRadius: 4,
                color: AppColors.black,
              ),
            ],
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            SafeNetworkImage(
              url: widget.game.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: theme.colorScheme.surfaceContainerHighest,
                alignment: Alignment.center,
                child: Icon(
                  Icons.extension,
                  size: 80,
                  color: theme.colorScheme.outline,
                ),
              ),
            ),
            // Gradient bottom fade
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 100,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppColors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      // Border dưới AppBar — đảm bảo user luôn phân biệt được
      // AppBar với body content khi scroll.
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.border,
                width: NeoBrutalismTheme.borderWidth,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Wrapper giữ backward-compat: gộp SliverAppBar + meta info vào 1
/// SliverMainAxisGroup. Dùng trực tiếp trong CustomScrollView.slivers.
class GameDetailHeader extends StatelessWidget {
  final BoardGameEntity game;
  final bool isSaved;

  const GameDetailHeader({
    super.key,
    required this.game,
    this.isSaved = false,
  });

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        // SliverAppBar — đặt trực tiếp trong group (không lồng thêm),
        // pinned=true vẫn hoạt động vì group nằm trực tiếp trong
        // CustomScrollView.slivers, không phải lồng trong group khác.
        SliverDetailAppBar(game: game, isSaved: isSaved),
        // Category + rating + stats — scroll bình thường.
        GameDetailMetaInfo(game: game),
      ],
    );
  }
}

/// SliverAppBar cho game detail — tách riêng để dùng được trong
/// CustomScrollView.slivers mà không qua SliverMainAxisGroup trung gian.
///
/// Cũng hỗ trợ bookmark icon reactive với `SavedGamesCubit` (xem
/// [_GameDetailSliverAppBarState] để biết logic chung — 2 class này
/// có UI giống nhau, chỉ khác vị trí đặt trong widget tree).
class SliverDetailAppBar extends StatefulWidget {
  final BoardGameEntity game;
  final bool isSaved;

  const SliverDetailAppBar({
    super.key,
    required this.game,
    this.isSaved = false,
  });

  @override
  State<SliverDetailAppBar> createState() => _SliverDetailAppBarState();
}

class _SliverDetailAppBarState extends State<SliverDetailAppBar> {
  @override
  void initState() {
    super.initState();
    // Lưu ý: actions stream subscription đã được chuyển vào
    // [_HeaderSaveButton] (StatefulWidget, tự quản lý lifecycle). Tap
    // + toast + pulse animation đều handle trong button → không cần
    // subscribe ở parent, tránh duplicate toast khi user bấn save.
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      stretch: true,
      scrolledUnderElevation: 4,
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shadowColor: AppColors.black.withValues(alpha: 0.15),
      title: Text(
        widget.game.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      titleTextStyle: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w900,
        color: isDark
            ? AppColors.textPrimaryDark
            : AppColors.textPrimary,
      ),
      leading: Container(
        margin: const EdgeInsets.all(AppSpacing.xs),
        decoration: BoxDecoration(
          color: AppColors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.black, width: 2),
          boxShadow: const [
            BoxShadow(
              color: AppColors.black,
              blurRadius: 0,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        _HeaderSaveButton(
          gameId: widget.game.id,
          initialIsSaved: widget.isSaved,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsetsDirectional.only(
          start: AppSpacing.md,
          end: AppSpacing.md,
          bottom: AppSpacing.md + 40,
        ),
        title: Text(
          widget.game.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: AppColors.white,
            shadows: [
              Shadow(
                offset: Offset(0, 1),
                blurRadius: 4,
                color: AppColors.black,
              ),
            ],
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            SafeNetworkImage(
              url: widget.game.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: theme.colorScheme.surfaceContainerHighest,
                alignment: Alignment.center,
                child: Icon(
                  Icons.extension,
                  size: 80,
                  color: theme.colorScheme.outline,
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 100,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppColors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.border,
                width: NeoBrutalismTheme.borderWidth,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Icon save/unsave trên header — reactive với [SavedGamesCubit].
///
/// **Source of truth**:
/// - Ưu tiên 1: [SavedGamesCubit] state (khi cubit đã load xong /
///   refresh) — phản ánh đúng DB state qua mọi toggle.
/// - Ưu tiên 2: `initialIsSaved` từ API (`isSaved` field trong response
///   `GET .../active-cafes`) — dùng khi cubit chưa có data (Initial /
///   Error không có savedIds) → icon vẫn hiển thị đúng ngay từ frame đầu.
///
/// **Visual**:
/// - Chưa lưu: `bookmark_border_rounded` (icon rỗng)
/// - Đã lưu: `bookmark_rounded` (icon đặc)
///
/// **Pattern tham khảo từ `_CardSaveButton` (recommended_game_card.dart)**:
/// - `GestureDetector + HitTestBehavior.opaque` thay vì `IconButton` để
///   đảm bảo tap area rõ ràng, không bị Material ancestor nuốt hit.
/// - Pulse animation khi state toggle (scale 1.0 → 1.35 → 1.0) để
///   user thấy feedback rõ ràng sau khi save/unsave.
/// - Press feedback (`_localPressed`) → scale 0.85 khi đang giữ icon,
///   scale về 1.0 khi release → cảm giác "bấm" rõ ràng.
/// - Subscribe `SavedGamesCubit.actions` stream trong chính button
///   (không ở parent) → tự quản lý lifecycle, tránh duplicate toast.
///   `BlocListener` ở parent (`BoardGameDetailPage`) sync state sang
///   `MatchmakingCubit.setIsSaved` vẫn chạy độc lập với toast ở đây.
class _HeaderSaveButton extends StatefulWidget {
  final String gameId;

  /// Trạng thái `isSaved` ban đầu từ API (response `GET .../active-cafes`).
  /// Fallback khi [SavedGamesCubit] chưa có data đáng tin → icon vẫn hiển
  /// thị đúng DB state ngay từ frame đầu tiên.
  final bool initialIsSaved;

  const _HeaderSaveButton({
    required this.gameId,
    required this.initialIsSaved,
  });

  @override
  State<_HeaderSaveButton> createState() => _HeaderSaveButtonState();
}

class _HeaderSaveButtonState extends State<_HeaderSaveButton>
    with SingleTickerProviderStateMixin {
  StreamSubscription<SaveActionMessage>? _actionSub;

  /// Pulse animation khi state thay đổi (saved ↔ unsaved). Trigger
  /// qua `_onAction` khi nhận `isSuccess = true` từ cubit stream.
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseScale;

  /// Local press state — khi user nhấn giữ icon, scale nhỏ lại để
  /// tạo cảm giác "bấm". Reset khi tap up / cancel.
  ///
  /// **Tại sao cần state riêng (không dùng `_pulseScale`)?**
  /// - `_pulseScale` chỉ kích khi save action thành công (subscribe
  ///   từ cubit stream) → scale 1.35 rồi về 1.0.
  /// - `_localPressed` kích ngay khi user nhấn (onTapDown) → scale
  ///   0.85 rồi về 1.0. 2 animation độc lập, không xung đột.
  bool _localPressed = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      duration: const Duration(milliseconds: 320),
      vsync: this,
    );
    _pulseScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.35)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.35, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_pulseCtrl);

    // Subscribe actions stream để show toast + pulse khi save/unsave
    // hoàn tất. Lọc theo `gameId` để tránh nhận nhầm action của game
    // khác (vd: 2 game trên carousel cùng listen).
    //
    // **Defensive**: try-catch vì cubit có thể bị close (closed stream
    // → `.actions` trả empty stream). Ở đây cubit được provide ở root
    // MultiBlocProvider nên bình thường luôn có — check phòng test env
    // / setup wrapper thiếu cubit.
    try {
      _actionSub = context
          .read<SavedGamesCubit>()
          .actions
          .where((action) => action.gameTemplateId == widget.gameId)
          .listen(_onAction);
    } catch (_) {
      // Không có cubit → bỏ qua, button vẫn render bình thường
      // (chỉ không có toast + pulse).
    }
  }

  @override
  void dispose() {
    _actionSub?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _onAction(SaveActionMessage action) {
    if (!mounted) return;
    // Pulse animation để user biết icon đã thay đổi thành công.
    // Chỉ pulse khi action thành công — fail thì giữ nguyên (không
    // tạo ảo giác "đã save" khi thực tế đã rollback).
    if (action.isSuccess) {
      _pulseCtrl.forward(from: 0);
      AppToast.showSuccess(context, action.message);
    } else {
      AppToast.showError(context, action.message);
    }
  }

  /// Tap handler — gọi cubit `toggleSave` với try/catch.
  ///
  /// **Tại sao KHÔNG show toast trên error ở đây?**
  /// Sau khi chuyển `SavedGamesCubit` lên root `MultiBlocProvider`, cubit
  /// LUÔN có sẵn trong scope → exception gần như không xảy ra. Nếu vẫn
  /// throw (test env / thiếu provider) → chỉ log debug, KHÔNG spam toast.
  /// Toast thật sự sẽ đến từ `_onAction` khi cubit phát action failure.
  void _onTap() {
    HapticFeedback.mediumImpact();
    try {
      final cubit = context.read<SavedGamesCubit>();
      cubit.toggleSave(widget.gameId);
    } catch (e, stack) {
      debugPrint(
        '[_HeaderSaveButton] cubit not found when toggling save: $e\n$stack',
      );
    }
  }

  /// Tính `isSaved` từ `SavedGamesState` (nếu cubit có data đáng tin).
  /// Fallback về `initialIsSaved` khi cubit không có data reliable.
  ///
  /// Logic y hệt `_CardSaveButton._computeIsSaved` (recommended_game_card.dart)
  /// để behavior đồng nhất giữa 2 vị trí hiển thị save button.
  bool _computeIsSaved(SavedGamesState state) {
    Set<String> ids = const <String>{};
    bool reliable = false;
    if (state is SavedGamesLoaded) {
      ids = state.savedIds;
      reliable = true;
    } else if (state is SavedGamesRefreshing && state.games.isNotEmpty) {
      ids = state.games.map((g) => g.gameTemplateId).toSet();
      reliable = true;
    } else if (state is SavedGamesLoadingFromCache) {
      ids = state.cachedIds;
      reliable = true;
    } else if (state is SavedGamesError && state.savedIds != null) {
      ids = state.savedIds!;
      reliable = true;
    }
    return reliable ? ids.contains(widget.gameId) : widget.initialIsSaved;
  }

  @override
  Widget build(BuildContext context) {
    // Thử lấy cubit — nếu không có (test env / thiếu provider) → render
    // static button dùng `initialIsSaved`.
    SavedGamesCubit? cubit;
    try {
      cubit = context.read<SavedGamesCubit>();
    } catch (_) {
      cubit = null;
    }

    if (cubit == null) {
      return _buildButton(isSaved: widget.initialIsSaved);
    }

    return BlocBuilder<SavedGamesCubit, SavedGamesState>(
      // Chỉ rebuild khi `savedIds` set thay đổi (toggle save/unsave).
      // Tránh rebuild header khi cubit refresh games list → kéo theo
      // toàn bộ SliverAppBar rebuild (mất pinned state).
      buildWhen: (prev, curr) {
        return _computeIsSaved(prev) != _computeIsSaved(curr);
      },
      builder: (context, state) {
        return _buildButton(isSaved: _computeIsSaved(state));
      },
    );
  }

  Widget _buildButton({required bool isSaved}) {
    // **Tap reliability**:
    // - `GestureDetector + HitTestBehavior.opaque` đảm bảo hit area
    //   consume pointer event ngay tại icon → không bị parent
    //   (SliverAppBar leading/back button) hoặc GestureDetector lân
    //   cận "nuốt" tap.
    // - Không dùng `Material + InkWell` vì trên web (DDC) đôi khi
    //   InkWell không fire onTap khi lồng trong widget có render
    //   boundary riêng (xem comment trong `_CardSaveButton`).
    // - `IconButton` (cách cũ) thỉnh thoảng bị "nuốt" tap khi nằm
    //   trong `SliverAppBar.actions` do Material ink-ripple layer +
    //   gesture arena không ổn định qua hot-reload → fix bằng cách
    //   dùng `GestureDetector` trực tiếp.
    return Container(
      margin: const EdgeInsets.all(AppSpacing.xs),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) {
          if (mounted) setState(() => _localPressed = true);
        },
        onTapUp: (_) {
          if (mounted) setState(() => _localPressed = false);
        },
        onTapCancel: () {
          if (mounted) setState(() => _localPressed = false);
        },
        onTap: _onTap,
        child: Tooltip(
          message: isSaved
              ? 'Đã lưu vào danh sách yêu thích'
              : 'Lưu vào danh sách yêu thích',
          preferBelow: false,
          waitDuration: const Duration(milliseconds: 400),
          child: AnimatedScale(
            // Press feedback: scale nhỏ lại khi user đang giữ icon,
            // về 1.0 khi release. Độc lập với `_pulseScale` (khi
            // save thành công → scale 1.35 rồi về 1.0).
            scale: _localPressed ? 0.85 : 1.0,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.black, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.black,
                    blurRadius: 0,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: AnimatedBuilder(
                animation: _pulseScale,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseScale.value,
                    child: child,
                  );
                },
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(
                      scale: animation,
                      child: FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                    );
                  },
                  child: Icon(
                    isSaved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    key: ValueKey(isSaved),
                    color: AppColors.black,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Phần category badge + rating + quick stats row — nằm ngay dưới
/// SliverAppBar, bọc trong SliverMainAxisGroup để giữ scroll behavior.
class GameDetailMetaInfo extends StatelessWidget {
  final BoardGameEntity game;

  const GameDetailMetaInfo({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (game.category.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm + 2,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.border,
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
                    child: Text(
                      game.category.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],
                if (game.rating > 0)
                  _RatingBadge(rating: game.rating),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _QuickStatsRow(
              minPlayers: game.minPlayers,
              maxPlayers: game.maxPlayers,
              playTime: game.estimatedMinutes,
            ),
          ],
        ),
      ),
    );
  }
}

class _RatingBadge extends StatelessWidget {
  final double rating;

  const _RatingBadge({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.warning,
        borderRadius: BorderRadius.circular(8),
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.star_rounded,
            size: AppSpacing.md,
            color: AppColors.black,
          ),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
              color: AppColors.black,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickStatsRow extends StatelessWidget {
  final int minPlayers;
  final int maxPlayers;
  final int playTime;

  const _QuickStatsRow({
    required this.minPlayers,
    required this.maxPlayers,
    required this.playTime,
  });

  String get _playerRangeText =>
      minPlayers == maxPlayers ? '$minPlayers' : '$minPlayers-$maxPlayers';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: NeoBrutalismTheme.borderWidth,
        ),
        boxShadow: NeoBrutalismTheme.lightShadow(
          shadowColor: AppColors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.people_rounded,
                    size: AppSpacing.md,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  _playerRangeText,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 2,
            height: 24,
            color: isDark ? AppColors.borderDark : AppColors.border,
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.schedule_rounded,
                    size: AppSpacing.md,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  playTime > 0 ? '~$playTime phút' : '-',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
