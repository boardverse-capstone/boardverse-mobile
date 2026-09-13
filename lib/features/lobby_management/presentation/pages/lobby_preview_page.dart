import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:boardverse/core/di/injection.dart';
import 'package:boardverse/core/error/failures.dart';
import 'package:boardverse/core/theme/app_colors.dart';
import 'package:boardverse/core/theme/app_icons.dart';
import 'package:boardverse/core/theme/app_shimmer.dart';
import 'package:boardverse/core/theme/app_spacing.dart';
import '../../../matchmaking_discovery/presentation/cubit/cafe_detail_cubit.dart';
import '../../../matchmaking_discovery/presentation/cubit/cafe_detail_state.dart';
import '../../domain/entities/lobby_entity.dart';
import '../cubit/lobby_cubit.dart';
import '../cubit/lobby_reservation_cubit.dart';
import '../cubit/lobby_state.dart';
import '../widgets/lobby_status_badge.dart';
import 'lobby_page.dart';

/// Neo-brutalism lobby preview page.
class LobbyPreviewPage extends StatefulWidget {
  final LobbyEntity lobby;
  final LobbyCubit lobbyCubit;

  /// CafeDetailCubit đã được khởi tạo sẵn (optional). Khi truyền null sẽ
  /// tự lấy từ `getIt`. Cho phép hub page pass cubit của nó nếu muốn
  /// chia sẻ state giữa nhiều màn.
  final CafeDetailCubit? cafeDetailCubit;

  const LobbyPreviewPage({
    super.key,
    required this.lobby,
    required this.lobbyCubit,
    this.cafeDetailCubit,
  });

  @override
  State<LobbyPreviewPage> createState() => _LobbyPreviewPageState();
}

class _LobbyPreviewPageState extends State<LobbyPreviewPage> {
  /// CafeDetailCubit dùng để fetch thông tin quán khi player mở preview.
  /// Lazily resolved — nếu DI chưa sẵn sàng (vd: trong unit test chưa
  /// setup `getIt`) thì fallback về cubit được pass t� widget, hoặc tạo
  /// cubit ad-hoc từ `MatchmakingRepository` của getIt.
  CafeDetailCubit? _cafeCubit;

  /// Cờ join-in-progress ở cấp preview page. Set = true ngay khi user
  /// bấm "Tham gia" trong dialog confirm → hiển thị shimmer overlay toàn
  /// trang trong khi chờ response API. Reset = false khi join fail (để
  /// user thấy lại preview content + retry); khi join thành công thì
  /// pushReplacement sang LobbyPage nên state này không còn ý nghĩa.
  ///
  /// `final` vì state lưu qua `setState` không phải qua reassign trực
  /// tiếp; chỉ mutable qua hàm setter nội bộ (không có ở đây).
  // ignore: prefer_final_fields
  bool _joining = false;

  @override
  void initState() {
    super.initState();
    _initCafeCubit();
    // Khi vào preview page, fetch thông tin chi tiết quán cafe để hiển thị
    // địa chỉ + SĐT. Lý do cần gọi riêng: API `/discoverable` và `/search`
    // trả về lobby không kèm `cafeAddress` / `cafePhone` — chỉ `cafeId` +
    // `cafeName`. Để UI có đủ thông tin liên hệ cho player trước khi join,
    // ta gọi `GET /api/cafes/{cafeId}` để lấy full cafe detail.
    if (widget.lobby.cafeId.isNotEmpty) {
      _cafeCubit?.loadCafeDetail(widget.lobby.cafeId);
    }
  }

  /// Khởi tạo `_cafeCubit` theo thứ tự ưu tiên:
  /// 1. `widget.cafeDetailCubit` (hub page có thể truyền vào)
  /// 2. `getIt<CafeDetailCubit>()` (DI singleton/factory)
  ///
  /// Thay vì dùng `late final` (gây `LateInitializationError` nếu DI chưa
  /// sẵn sàng), ta dùng nullable + defensive. Card cafe sẽ tự skip nếu
  /// cubit không có sẵn — UX an toàn cho cả prod và test.
  void _initCafeCubit() {
    if (widget.cafeDetailCubit != null) {
      _cafeCubit = widget.cafeDetailCubit;
      return;
    }
    try {
      _cafeCubit = getIt<CafeDetailCubit>();
    } catch (_) {
      // getIt chưa setup (vd: widget test không init DI) → để null,
      // _CafeInfoCard sẽ fallback chỉ dùng lobby.cafeAddress / cafePhone.
      _cafeCubit = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lobby = widget.lobby;
    final lobbyCubit = widget.lobbyCubit;
    final cafeCubit = _cafeCubit;

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: lobbyCubit),
        if (cafeCubit != null) BlocProvider.value(value: cafeCubit),
      ],
      child: Scaffold(
        body: BlocListener<LobbyCubit, LobbyState>(
          listener: (context, state) {
            // BlocListener chỉ còn dùng để hiển thị LobbyFailure (vd: 409)
            // khi user navigate đến preview page trong khi join đang chạy.
            // Navigation đến LobbyPage sau khi join thành công do
            // _confirmAndJoin xử lý trực tiếp (pushReplacement) — không
            // còn đợi cubit emit LobbyCreated rồi mới navigate như trước.
            if (state is LobbyFailure) {
              final is409 = state.message.contains('409') ||
                  state.message.contains('trạng thái mở') ||
                  state.message.contains('đã đóng') ||
                  state.message.contains('đang chờ cafe duyệt') ||
                  state.message.contains('đang chơi');
              if (is409) {
                _showLobbyStatusDialog(state.message);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            }
          },
          child: Stack(
            children: [
              // ── Preview content (bình thường) ────────────────────────
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  160, // extra space cho bottom CTA + back button stack
                ),
                child: Column(
                  children: [
                    // ── Hero Card ──────────────────────────────────────
                    _NeoHeroCard(lobby: lobby),

                    const SizedBox(height: AppSpacing.md),

                    // ── Detail Grid ────────────────────────────────────
                    _DetailGrid(lobby: lobby),

                    const SizedBox(height: AppSpacing.md),

                    // ── Cafe Info Card (fetch qua CafeDetailCubit) ─────
                    if (cafeCubit != null)
                      _CafeInfoCard(
                        lobby: lobby,
                        cafeCubit: cafeCubit,
                      )
                    else
                      _CafeInfoCardFallback(lobby: lobby),

                    const SizedBox(height: AppSpacing.md),

                    // ── Status Banner ───────────────────────────────────
                    _StatusBanner(lobby: lobby),

                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),

              // ── Join-in-progress overlay (shimmer toàn trang) ────────
              // Hiển thị khi user vừa bấm "Tham gia" trong dialog và API
              // đang chạy. Overlay che toàn bộ preview content + CTA →
              // user thấy ngay feedback "đang xử lý" thay vì phải đợi
              // navigation. Khi join thành công, page bị pushReplacement
              // đi nên overlay tự dispose.
              if (_joining)
                Positioned.fill(
                  child: AbsorbPointer(
                    absorbing: true,
                    child: _JoiningOverlay(),
                  ),
                ),
            ],
          ),
        ),
        bottomNavigationBar: _BottomCtaBar(
          lobby: lobby,
          lobbyCubit: lobbyCubit,
          onBack: () => Navigator.of(context).pop(),
          isJoining: _joining,
          onJoiningChanged: (value) {
            // CTA bar báo join state đã đổi — setState để shimmer overlay
            // toàn trang rebuild theo.
            if (!mounted) return;
            setState(() => _joining = value);
          },
        ),
      ),
    );
  }

  void _showLobbyStatusDialog(String message) {
    showLobbyStatusDialog(context, message);
  }
}

/// Top-level helper để show modal bottom sheet "Phòng không khả dụng"
/// khi join lobby fail với 409 (phòng đã đóng / đang chờ duyệt / ...).
///
/// Tách ra khỏi `_LobbyPreviewPageState` vì cả 2 chỗ đều cần dùng:
///   1. BlocListener trong `_LobbyPreviewPageState` (khi cubit emit
///      `LobbyFailure` mà user đang ở preview).
///   2. `_confirmAndJoin` trong `_BottomCtaBarState` (khi joinLobby trả
///      Left(Failure) sau khi user bấm "Tham gia" trong dialog).
///
/// Stateless helper → dùng `context` của caller, không capture state.
void showLobbyStatusDialog(BuildContext context, String message) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: 3,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.warning,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.border,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.black,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.border,
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    AppIcons.info,
                    color: AppColors.warning,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Phòng không khả dụng',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        message,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: AppColors.black.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _NeoFilledButton(
            label: 'Đã hiểu',
            icon: AppIcons.check,
            color: AppColors.primary,
            onPressed: () => Navigator.pop(ctx),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
//  HERO CARD — Neo-brutalism
// ══════════════════════════════════════════════════════════════════════════════

class _NeoHeroCard extends StatelessWidget {
  final LobbyEntity lobby;

  const _NeoHeroCard({required this.lobby});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheduled = lobby.scheduledTime;
    final hh = scheduled.hour.toString().padLeft(2, '0');
    final mm = scheduled.minute.toString().padLeft(2, '0');

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.4),
            blurRadius: 0,
            offset: const Offset(5, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Top: gradient bar ───────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryLight],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [
                // Game image / initial
                if (lobby.gameImageUrl != null &&
                    lobby.gameImageUrl!.isNotEmpty)
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.white.withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.network(
                      lobby.gameImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _GameInitial(name: lobby.gameName),
                    ),
                  )
                else
                  _GameInitial(name: lobby.gameName),

                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lobby.gameName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusChip(lobby: lobby),
              ],
            ),
          ),

          // ── Bottom: time row ─────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surface,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [
                // Time pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.border,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.black.withValues(alpha: 0.4),
                        blurRadius: 0,
                        offset: const Offset(2, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 16,
                        color: AppColors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$hh:$mm',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: AppColors.white,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Capacity
                _CapacityBadge(lobby: lobby),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GameInitial extends StatelessWidget {
  final String name;

  const _GameInitial({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.white.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 28,
            color: AppColors.white,
          ),
        ),
      ),
    );
  }
}

class _CapacityBadge extends StatelessWidget {
  final LobbyEntity lobby;

  const _CapacityBadge({required this.lobby});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isFull = lobby.currentPlayers >= lobby.maxPlayers;
    final color = isFull ? AppColors.success : AppColors.info;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.3),
            blurRadius: 0,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.people, size: 16, color: AppColors.white),
          const SizedBox(width: 6),
          Text(
            '${lobby.currentPlayers}/${lobby.maxPlayers}',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14,
              color: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final LobbyEntity lobby;

  const _StatusChip({required this.lobby});

  @override
  Widget build(BuildContext context) {
    final variant = resolveBadgeVariant(
      lobbyStatus: lobby.status,
      reservationStatus: lobby.reservationStatus,
    );
    return LobbyStatusBadge(variant: variant, dense: true);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  DETAIL GRID — Neo-brutalism
// ══════════════════════════════════════════════════════════════════════════════

class _DetailGrid extends StatelessWidget {
  final LobbyEntity lobby;

  const _DetailGrid({required this.lobby});

  @override
  Widget build(BuildContext context) {
    final capacityProgress = lobby.maxPlayers == 0
        ? 0.0
        : (lobby.currentPlayers / lobby.maxPlayers).clamp(0.0, 1.0);

    return Column(
      children: [
        // Row 1: Members + Slots
        Row(
          children: [
            Expanded(
              child: _NeoTile(
                icon: AppIcons.users,
                label: 'THÀNH VIÊN',
                value: '${lobby.currentPlayers}/${lobby.maxPlayers}',
                progress: capacityProgress,
                accentColor: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _NeoTile(
                icon: AppIcons.userAdd,
                label: 'SLOT TRỐNG',
                value: '${lobby.slotsRemaining}',
                accentColor: AppColors.info,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // Row 2: Mode + Karma
        Row(
          children: [
            Expanded(
              child: _NeoTile(
                icon: lobby.isPublic ? AppIcons.globe : AppIcons.lock,
                label: 'CHẾ ĐỘ',
                value: lobby.isPublic ? 'Công khai' : 'Riêng tư',
                accentColor: AppColors.secondary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _NeoTile(
                icon: AppIcons.karma,
                label: 'KARMA TỐI THIỂU',
                value: lobby.minimumKarma > 0
                    ? '${lobby.minimumKarma.toInt()}+'
                    : 'Không yêu cầu',
                accentColor: AppColors.accent,
              ),
            ),
          ],
        ),

        // Invite code row
        if (lobby.inviteCode != null && lobby.inviteCode!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          _NeoInviteTile(
            code: lobby.inviteCode!,
          ),
        ],
      ],
    );
  }
}

class _NeoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final double? progress;
  final Color accentColor;

  const _NeoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.progress,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.4),
            blurRadius: 0,
            offset: const Offset(3, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.border,
                    width: 1.5,
                  ),
                ),
                child: Icon(icon, size: 14, color: AppColors.white),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 9,
                    letterSpacing: 0.8,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 20,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
          if (progress != null) ...[
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor:
                    isDark ? AppColors.borderDark : AppColors.border,
                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NeoInviteTile extends StatelessWidget {
  final String code;

  const _NeoInviteTile({required this.code});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.4),
            blurRadius: 0,
            offset: const Offset(3, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.border,
                width: 1.5,
              ),
            ),
            child: const Icon(
              AppIcons.copy,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MÃ MỜI PHÒNG',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 9,
                    letterSpacing: 0.8,
                    color: AppColors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  code,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    color: AppColors.white,
                    letterSpacing: 2.0,
                    fontFamily: 'monospace',
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

// ══════════════════════════════════════════════════════════════════════════════
//  CAFE INFO CARD — Neo-brutalism
// ══════════════════════════════════════════════════════════════════════════════

/// Card hiển thị thông tin quán (địa chỉ + SĐT) dưới dạng row có thể tap.
///
/// Trước đây lobby chỉ có `cafeId` + `cafeName` — UI chỉ show tên ở hero
/// header. Sau khi backend lobby trả thêm `cafeAddress` / `cafePhone`,
/// ta bind vào đây để player thấy được địa chỉ + SĐT ngay trong preview
/// mà không cần mở cafe detail page.
class _CafeInfoCard extends StatelessWidget {
  final LobbyEntity lobby;

  /// CafeDetailCubit đã được wrap trong widget tree — `BlocBuilder` lắng
  /// nghe state trực tiếp qua context. Khi cubit đổi state, card tự
  /// re-render với data mới nhất.
  final CafeDetailCubit cafeCubit;

  const _CafeInfoCard({
    required this.lobby,
    required this.cafeCubit,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<CafeDetailCubit, CafeDetailState>(
      bloc: cafeCubit,
      builder: (context, cafeState) {
        // Ưu tiên dữ liệu từ CafeDetailCubit (đầy đủ nhất). Fallback về
        // các field trên LobbyEntity nếu cubit chưa load xong / load lỗi.
        final String? resolvedAddress = cafeState is CafeDetailLoaded
            ? cafeState.cafe.address
            : lobby.cafeAddress;
        final String? resolvedPhone = cafeState is CafeDetailLoaded
            ? cafeState.cafe.phoneNumber
            : lobby.cafePhone;
        final String resolvedName = cafeState is CafeDetailLoaded
            ? (cafeState.cafe.name.isNotEmpty
                ? cafeState.cafe.name
                : lobby.cafeName)
            : lobby.cafeName;
        final bool isLoadingCafe =
            cafeState is CafeDetailLoading && lobby.cafeAddress == null;
        final String? cafeError = cafeState is CafeDetailError
            ? cafeState.message
            : null;

        // Không có dữ liệu cafe (cả từ lobby lẫn cubit) + lobby không có
        // cafeId → bỏ qua card luôn để tránh render rỗng.
        if (resolvedAddress == null &&
            resolvedPhone == null &&
            lobby.cafeId.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.border,
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.4),
                blurRadius: 0,
                offset: const Offset(3, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header bar
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(11),
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color:
                          isDark ? AppColors.borderDark : AppColors.border,
                      width: 1.5,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.border,
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        AppIcons.cafe,
                        size: 16,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        resolvedName.isEmpty
                            ? 'Thông tin quán'
                            : resolvedName,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    // Loading indicator khi đang fetch cafe detail
                    if (isLoadingCafe)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                  ],
                ),
              ),

              // Address row — fallback về "Đang tải..." nếu cả lobby và cubit
              // đều chưa có.
              if (resolvedAddress != null && resolvedAddress.isNotEmpty)
                _CafeInfoRow(
                  icon: Icons.place_outlined,
                  text: resolvedAddress,
                  onTap: null,
                )
              else if (isLoadingCafe)
                _CafeInfoRow(
                  icon: Icons.place_outlined,
                  text: 'Đang tải địa chỉ...',
                  onTap: null,
                  dimmed: true,
                ),

              // Phone row (tap để gọi)
              if (resolvedPhone != null && resolvedPhone.isNotEmpty)
                _CafeInfoRow(
                  icon: Icons.phone_outlined,
                  text: resolvedPhone,
                  onTap: () => _callPhone(context, resolvedPhone),
                )
              else if (isLoadingCafe)
                _CafeInfoRow(
                  icon: Icons.phone_outlined,
                  text: 'Đang tải SĐT...',
                  onTap: null,
                  dimmed: true,
                ),

              // Error row — chỉ hiện khi cubit fail và lobby cũng không có
              if (cafeError != null &&
                  lobby.cafeAddress == null &&
                  lobby.cafePhone == null)
                _CafeInfoRow(
                  icon: Icons.error_outline,
                  text: cafeError,
                  onTap: null,
                  dimmed: true,
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _callPhone(BuildContext context, String phoneNumber) async {
    // Tap-to-call: mở dialer native với tel URI. Nếu thiết bị không
    // hỗ trợ (vd: Chrome/Web không có tel handler), fallback hiện
    // snackbar để user copy số thủ công.
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    final ok = await launchUrl(uri);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Số điện thoại: $phoneNumber')),
      );
    }
  }
}

/// Fallback card khi không có `CafeDetailCubit` (vd: widget test không
/// setup DI). Chỉ render khi lobby có sẵn `cafeAddress` hoặc `cafePhone`
/// — không cố fetch, không có loading state.
class _CafeInfoCardFallback extends StatelessWidget {
  final LobbyEntity lobby;

  const _CafeInfoCardFallback({required this.lobby});

  @override
  Widget build(BuildContext context) {
    final hasAddress =
        lobby.cafeAddress != null && lobby.cafeAddress!.isNotEmpty;
    final hasPhone = lobby.cafePhone != null && lobby.cafePhone!.isNotEmpty;
    if (!hasAddress && !hasPhone && lobby.cafeId.isEmpty) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.4),
            blurRadius: 0,
            offset: const Offset(3, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(11),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    AppIcons.cafe,
                    size: 16,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  lobby.cafeName.isEmpty ? 'Thông tin quán' : lobby.cafeName,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (hasAddress)
            _CafeInfoRow(
              icon: Icons.place_outlined,
              text: lobby.cafeAddress!,
              onTap: null,
            ),
          if (hasPhone)
            _CafeInfoRow(
              icon: Icons.phone_outlined,
              text: lobby.cafePhone!,
              onTap: () => _callPhone(context, lobby.cafePhone!),
            ),
        ],
      ),
    );
  }

  Future<void> _callPhone(BuildContext context, String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    final ok = await launchUrl(uri);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Số điện thoại: $phoneNumber')),
      );
    }
  }
}

class _CafeInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onTap;

  /// Khi `true`, text được hiển thị mờ + icon dùng màu outline thay vì
  /// primary — dùng cho placeholder state ("Đang tải..." hoặc error).
  final bool dimmed;

  const _CafeInfoRow({
    required this.icon,
    required this.text,
    this.onTap,
    this.dimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dimmed
        ? (isDark
            ? AppColors.textSecondaryDark
            : AppColors.textSecondary)
        : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary);
    final iconBg = dimmed
        ? AppColors.textSecondary.withValues(alpha: 0.12)
        : AppColors.primary.withValues(alpha: 0.12);
    final iconColor = dimmed ? AppColors.textSecondary : AppColors.primary;

    final content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.border,
                width: 1.5,
              ),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: textColor,
                height: 1.3,
              ),
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: AppSpacing.xs),
            const Icon(
              Icons.call,
              size: 16,
              color: AppColors.primary,
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: content,
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  STATUS BANNER — Neo-brutalism
// ══════════════════════════════════════════════════════════════════════════════

class _StatusBanner extends StatelessWidget {
  final LobbyEntity lobby;

  const _StatusBanner({required this.lobby});

  @override
  Widget build(BuildContext context) {
    if (lobby.status == LobbyStatus.full) {
      return _NeoBanner(
        icon: Icons.groups,
        iconColor: AppColors.warning,
        text:
            'Phòng đã đầy. Bạn có thể đăng ký vào danh sách chờ hoặc tìm phòng khác.',
      );
    }
    if (lobby.status != LobbyStatus.open) {
      return _NeoBanner(
        icon: AppIcons.lock,
        iconColor: AppColors.error,
        text: 'Phòng này hiện không nhận thêm thành viên.',
      );
    }
    return _NeoBanner(
      icon: AppIcons.info,
      iconColor: AppColors.primary,
      text:
          'Bấm "Tham gia phòng" để vào lobby. Hệ thống sẽ kiểm tra Karma và số slot trống trước khi xác nhận.',
    );
  }
}

class _NeoBanner extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;

  const _NeoBanner({
    required this.icon,
    required this.iconColor,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: iconColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.4),
            blurRadius: 0,
            offset: const Offset(3, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.border,
                width: 1.5,
              ),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: AppColors.white,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  BOTTOM CTA — Neo-brutalism
// ══════════════════════════════════════════════════════════════════════════════

class _BottomCtaBar extends StatefulWidget {
  final LobbyEntity lobby;
  final LobbyCubit lobbyCubit;

  /// Callback cho nút "Quay lại" — mặc định pop preview page. Hub page có
  /// thể override để làm navigation khác (vd: cập nhật list trước khi pop).
  final VoidCallback onBack;

  /// Cờ join-in-progress do parent (`_LobbyPreviewPageState`) quản lý —
  /// set = true ngay khi user bấm "Tham gia" trong dialog confirm, truyền
  /// xuống CTA bar để:
  ///   1. Hiển thị spinner + label "Đang tham gia..." thay vì chờ cubit.
  ///   2. Disable nút "Quay lại" tránh race với pushReplacement.
  ///   3. Disable CTA chính tránh user bấm lần 2.
  ///
  /// Parent cũng dùng flag này để toggle shimmer overlay toàn trang —
  /// đảm bảo CTA bar và overlay đồng bộ chỉ qua 1 nguồn state.
  final bool isJoining;

  /// Callback báo cho parent biết trạng thái `_joining` đã đổi (true khi
  /// bắt đầu join, false khi join fail). Parent dùng để:
  ///   - Toggle shimmer overlay toàn trang.
  ///   - Khi join thành công thì parent pushReplacement sang LobbyPage.
  /// Khi join thành công thì CTA bar cũng dispose cùng page — không cần
  /// callback báo `false` cho parent.
  final ValueChanged<bool> onJoiningChanged;

  const _BottomCtaBar({
    required this.lobby,
    required this.lobbyCubit,
    required this.onBack,
    required this.isJoining,
    required this.onJoiningChanged,
  });

  @override
  State<_BottomCtaBar> createState() => _BottomCtaBarState();
}

class _BottomCtaBarState extends State<_BottomCtaBar> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.border,
            width: 3,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.3),
            blurRadius: 0,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: BlocBuilder<LobbyCubit, LobbyState>(
          builder: (context, state) {
            // Ưu tiên `widget.isJoining` (parent flag) — set ngay khi user
            // bấm "Tham gia" trong dialog → phản hồi tức thì, không đợi
            // cubit emit `LobbyLoading` (có thể trễ 1-2 frame). Cubit
            // loading vẫn dùng làm fallback.
            final isLoading = widget.isJoining || state is LobbyLoading;
            final canJoin = !isLoading &&
                widget.lobby.status == LobbyStatus.open &&
                widget.lobby.slotsRemaining > 0;
            return Row(
              children: [
                // Nút "Quay lại" — luôn hiển thị để player thoát preview
                // về danh sách phòng chờ công khai. Style outline để không
                // cạnh tranh với CTA chính (THAM GIA PHÒNG). Disable khi
                // đang join để tránh race với pushReplacement.
                _NeoOutlineButton(
                  label: 'Quay lại',
                  icon: Icons.arrow_back,
                  color: AppColors.textSecondary,
                  onPressed: isLoading ? null : widget.onBack,
                ),
                const SizedBox(width: AppSpacing.sm),
                // CTA chính — THAM GIA / Đang tham gia / Phòng không mở
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: _NeoFilledButton(
                      label: _buttonLabel(isLoading),
                      icon: canJoin ? AppIcons.userAdd : AppIcons.lock,
                      color:
                          canJoin ? AppColors.primary : AppColors.textTertiary,
                      isLoading: isLoading,
                      onPressed: canJoin ? () => _confirmAndJoin() : null,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _buttonLabel(bool isLoading) {
    // �u tiên `_joining` (local flag) — user vừa bấm "Tham gia" trong
    // dialog, phản hồi ngay "Đang tham gia..." thay vì đợi cubit emit.
    if (widget.isJoining || isLoading) return 'Đang tham gia...';
    if (widget.lobby.status != LobbyStatus.open) return 'Phòng không mở';
    if (widget.lobby.slotsRemaining <= 0) return 'Phòng đã đầy';
    return 'THAM GIA PHÒNG';
  }

  /// Hiển thị dialog xác nhận, rồi **join lobby ngay tại preview page** —
  /// không pop về hub. Trong khi chờ response API, hiển thị shimmer overlay
  /// toàn trang qua `setState(_joining = true)`. Khi join thành công, push
  /// LobbyPage lên stack (preview page tự pop ngay trước khi push để UX
  /// mượt — user không thấy quay về hub).
  ///
  /// Luồng cũ (delay): dialog → pop(true) → hub.joinAndOpen → API → push.
  /// → User thấy preview page pop về hub, sau đó mới vào LobbyPage.
  ///
  /// Luồng mới (no-delay): dialog → API tại chỗ + shimmer → push LobbyPage
  /// (kèm pop preview). Giảm một navigation step + user cảm giác liền mạch.
  Future<void> _confirmAndJoin() async {
    final lobby = widget.lobby;
    final timeText =
        '${lobby.scheduledTime.hour.toString().padLeft(2, '0')}:${lobby.scheduledTime.minute.toString().padLeft(2, '0')}';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(AppSpacing.md),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.4),
                blurRadius: 0,
                offset: const Offset(6, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border, width: 3),
                ),
                child: const Icon(
                  AppIcons.boardGame,
                  size: 32,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Xác nhận tham gia',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Info rows
              _ConfirmRow(
                icon: AppIcons.boardGame,
                label: 'Game',
                value: lobby.gameName,
              ),
              _ConfirmRow(
                icon: AppIcons.schedule,
                label: 'Giờ hẹn',
                value: timeText,
              ),
              _ConfirmRow(
                icon: AppIcons.users,
                label: 'Slot trống',
                value: '${lobby.slotsRemaining} chỗ',
              ),
              if (lobby.minimumKarma > 0)
                _ConfirmRow(
                  icon: AppIcons.karma,
                  label: 'Yêu cầu Karma',
                  value: '${lobby.minimumKarma.toInt()}+',
                ),

              if (!lobby.isPublic) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border, width: 2),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        AppIcons.lock,
                        size: 16,
                        color: AppColors.black,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          'Phòng riêng tư. Bạn cần mã mời hoặc là bạn bè của Host.',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            color: AppColors.black.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.lg),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: _NeoOutlineButton(
                      label: 'Huỷ',
                      color: AppColors.textSecondary,
                      onPressed: () => Navigator.pop(dialogContext, false),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _NeoFilledButton(
                      label: 'Tham gia',
                      icon: AppIcons.userAdd,
                      color: AppColors.primary,
                      onPressed: () => Navigator.pop(dialogContext, true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    // ── Join flow mới: gọi joinLobby tại chỗ, báo parent bật shimmer overlay,
    // push LobbyPage (kèm pop preview) khi thành công.
    widget.onJoiningChanged(true);

    final joinResult = await widget.lobbyCubit.joinLobby(
      lobby.id,
      lobby.inviteCode,
    );

    if (!mounted) return;

    final failure = joinResult.fold<Failure?>(
      (f) => f,
      (_) => null,
    );

    if (failure != null) {
      // Tắt shimmer + rollback state cubit (LobbyFailure) → preview page
      // sẽ tự rebuild nhờ BlocListener phía trên.
      widget.onJoiningChanged(false);

      final msg = failure.message;
      final isAlreadyMember = msg.contains('đã là thành viên') ||
          msg.contains('already');
      final is409 = msg.contains('409') ||
          msg.contains('trạng thái mở') ||
          msg.contains('đã đóng') ||
          msg.contains('đang ch� cafe duyệt') ||
          msg.contains('đang chơi');

      if (isAlreadyMember) {
        // Đã là thành viên từ trước — vẫn đẩy vào LobbyPage thẳng.
        _navigateToLobbyPage(lobby.id);
        return;
      }
      if (is409) {
        // Top-level helper — dùng chung với BlocListener ở preview state.
        showLobbyStatusDialog(context, msg);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
      return;
    }

    // Join thành công — push LobbyPage. Preview page tự pop để user
    // không back về được preview sau khi đã vào lobby.
    _navigateToLobbyPage(lobby.id);
  }

  /// Push LobbyPage đè lên preview page, đồng thời pop preview ngay
  /// lập tức để user không nhìn thấy transition "back to hub".
  void _navigateToLobbyPage(String lobbyId) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => BlocProvider<LobbyReservationCubit>(
          create: (_) => getIt<LobbyReservationCubit>()
            ..startWatching(reservationId: lobbyId),
          child: BlocProvider.value(
            value: widget.lobbyCubit,
            child: LobbyPage(lobbyId: lobbyId, lobbyCubit: widget.lobbyCubit),
          ),
        ),
      ),
    );
  }
}

class _ConfirmRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ConfirmRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13,
                color: AppColors.black,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  NEO-BRUTALISM BUTTONS
// ══════════════════════════════════════════════════════════════════════════════

class _NeoFilledButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final VoidCallback? onPressed;
  final bool isLoading;

  const _NeoFilledButton({
    required this.label,
    this.icon,
    required this.color,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: 2.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 0,
                offset: Offset(3, 3),
              ),
            ],
          ),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.white,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 18, color: AppColors.white),
                        const SizedBox(width: AppSpacing.xs),
                      ],
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            letterSpacing: 0.5,
                          ),
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

class _NeoOutlineButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onPressed;

  /// Icon hiển thị bên trái label (optional).
  final IconData? icon;

  const _NeoOutlineButton({
    required this.label,
    required this.color,
    this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: icon != null ? AppSpacing.sm : AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color, width: 2.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: color, size: 18),
                const SizedBox(width: AppSpacing.xs),
              ],
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  JOIN-IN-PROGRESS OVERLAY
// ══════════════════════════════════════════════════════════════════════════════

/// Overlay toàn trang hiển thị khi user vừa bấm "Tham gia" trong dialog
/// confirm và API `joinLobby` đang chạy.
///
/// Layout: màn nền dim (theme.surface + alpha) + spinner + label ngắn
/// "Đang vào phòng..." ở giữa. Background còn có shimmer nhẹ chạy ngang
/// để cho cảm giác "đang tải" thay vì spinner đơn điệu.
///
/// Wrap trong `AbsorbPointer(absorbing: true)` ở call-site — chặn tap
/// trong khi join để tránh user bấm "Quay lại" / "Tham gia" lần 2 gây
/// race với pushReplacement.
class _JoiningOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surface;

    return AppShimmer.shimmer(
      context: context,
      child: Container(
        color: surface.withValues(alpha: 0.92),
        alignment: Alignment.center,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.border,
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.3),
                blurRadius: 0,
                offset: const Offset(3, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Flexible(
                child: Text(
                  'Đang vào phòng...',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}