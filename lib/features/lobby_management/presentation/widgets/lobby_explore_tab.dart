import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/theme.dart';
import '../../domain/entities/lobby_entity.dart';
import '../cubit/lobby_search_cubit.dart';
import '../cubit/lobby_state.dart';

/// Modern lobby explore tab với gradient cards và elevated design.
///
/// Phân biệt 2 luồng tap theo quyền của user với lobby:
/// - **Lobby của mình** (`lobby.hostId == currentUserId`): tap → mở
///   [LobbyPage] trực tiếp qua `onOpenOwned` (KHÔNG gọi `/join`, không
///   qua preview popup confirm). Server không cho phép user join lại
///   lobby do mình host (`409 — đã là thành viên`) nên flow `/join` là
///   thừa + gây UX kém.
/// - **Lobby của người khác**: tap → preview popup confirm (`onPreview`)
///   hoặc bấm nút "Vào" (`onJoin`) để gọi `/join`.
class LobbyExploreTab extends StatelessWidget {
  final LobbySearchCubit searchCubit;
  final DateFormat timeFormatter;
  final void Function(LobbyEntity) onPreview;
  final void Function(LobbyEntity) onOpenOwned;
  final void Function(String, String?) onJoin;
  final VoidCallback onCreateLobby;

  /// ID user hiện tại — dùng để phát hiện lobby do chính mình host.
  /// Truyền `null` nếu chưa resolve được (treat as "no owned lobby").
  final String? currentUserId;

  const LobbyExploreTab({
    super.key,
    required this.searchCubit,
    required this.timeFormatter,
    required this.onPreview,
    required this.onOpenOwned,
    required this.onJoin,
    required this.onCreateLobby,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LobbySearchCubit, LobbyState>(
      bloc: searchCubit,
      builder: (context, state) {
        if (state is LobbyListLoading) return const _LoadingView();
        if (state is LobbyFailure) {
          return _ErrorView(
            message: state.message,
            onRetry: () => searchCubit.loadDiscoverable(limit: 50),
          );
        }
        if (state is LobbyListEmpty || (state is LobbyListLoaded && state.entities.isEmpty)) {
          return _EmptyExploreView(onCreateLobby: onCreateLobby);
        }
        if (state is LobbyListLoaded) {
          return _LobbyList(
            lobbies: state.entities,
            timeFormatter: timeFormatter,
            currentUserId: currentUserId,
            onPreview: onPreview,
            onOpenOwned: onOpenOwned,
            onJoin: onJoin,
            onRefresh: () => searchCubit.loadDiscoverable(limit: 50),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: colors.primaryContainer.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: CircularProgressIndicator(color: colors.primary),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Đang tải phòng chờ...',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: colors.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(AppIcons.error, size: AppIcons.xxl, color: colors.onErrorContainer),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Đã xảy ra lỗi',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.xl),
            _GradientRetryButton(onTap: onRetry),
          ],
        ),
      ),
    );
  }
}

class _EmptyExploreView extends StatelessWidget {
  final VoidCallback onCreateLobby;

  const _EmptyExploreView({required this.onCreateLobby});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colors.primary.withValues(alpha: 0.1),
                    colors.primary.withValues(alpha: 0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(AppIcons.boardGame, size: AppIcons.massive, color: colors.primary.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Chưa có phòng chờ nào',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Hãy là người đầu tiên tạo phòng để mọi người cùng tham gia!',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.xl),
            _GradientRetryButton(
              onTap: onCreateLobby,
              label: 'Tạo phòng',
              icon: AppIcons.addSimple,
            ),
          ],
        ),
      ),
    );
  }
}

class _LobbyList extends StatelessWidget {
  final List<LobbyEntity> lobbies;
  final DateFormat timeFormatter;
  final String? currentUserId;
  final void Function(LobbyEntity) onPreview;
  final void Function(LobbyEntity) onOpenOwned;
  final void Function(String, String?) onJoin;
  final Future<void> Function() onRefresh;

  const _LobbyList({
    required this.lobbies,
    required this.timeFormatter,
    required this.onPreview,
    required this.onOpenOwned,
    required this.onJoin,
    required this.onRefresh,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 120),
        itemCount: lobbies.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.primary.withAlpha(204),
                        ],
                      ),
                      borderRadius: AppRadius.radiusFullAll,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(AppIcons.users, size: AppIcons.sm, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          '${lobbies.length} phòng đang hoạt động',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
          final lobby = lobbies[index - 1];
          final isMine = currentUserId != null &&
              currentUserId!.isNotEmpty &&
              lobby.hostId == currentUserId;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _LobbyExploreCard(
              lobby: lobby,
              timeFormatter: timeFormatter,
              isMine: isMine,
              onTap: () => isMine ? onOpenOwned(lobby) : onPreview(lobby),
              onJoin: () => onJoin(lobby.id, lobby.inviteCode),
            ),
          );
        },
      ),
    );
  }
}

/// Modern lobby card với gradient game thumbnail và elevated design.
///
/// Khi [isMine] = true (lobby do chính user hiện tại host):
/// - Border đổi sang màu primary, độ dày 1.5px (nổi bật).
/// - Header thêm badge "Phòng của bạn".
/// - Button đổi từ "Vào" gradient primary → "Mở" outlined primary.
/// - Tap card → mở LobbyPage trực tiếp (không qua preview).
///
/// Khi [isMine] = false: giữ nguyên UI cũ + button "Vào" / "Đầy".
class _LobbyExploreCard extends StatelessWidget {
  final LobbyEntity lobby;
  final DateFormat timeFormatter;
  final bool isMine;
  final VoidCallback onTap;
  final VoidCallback onJoin;

  const _LobbyExploreCard({
    required this.lobby,
    required this.timeFormatter,
    required this.onTap,
    required this.onJoin,
    this.isMine = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final capacity = '${lobby.currentPlayers}/${lobby.maxPlayers}';
    final isFull = lobby.currentPlayers >= lobby.maxPlayers;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.radiusLgAll,
        // Border màu primary + đậm hơn khi là lobby của mình — đánh dấu
        // visual rõ ràng để user dễ phân biệt với lobby của người khác.
        border: Border.all(
          color: isMine
              ? colors.primary.withValues(alpha: 0.55)
              : colors.outlineVariant.withValues(alpha: 0.5),
          width: isMine ? 1.5 : 1,
        ),
        boxShadow: AppElevation.shadowMd,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.radiusLgAll,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            children: [
              // ── Gradient thumbnail + game info header ──────────────
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colors.primary,
                      colors.primary.withAlpha(179),
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    // Game initial avatar
                    _GameAvatar(lobby: lobby, theme: theme, colors: colors),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  lobby.gameName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              // Badge "Phòng của bạn" — chỉ khi isMine.
                              if (isMine) ...[
                                const SizedBox(width: AppSpacing.xs),
                                _OwnedBadge(),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(AppIcons.cafe, size: AppIcons.sm, color: Colors.white.withValues(alpha: 0.8)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  lobby.cafeName.isNotEmpty ? lobby.cafeName : 'Chưa chọn quán',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.85),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    _CapacityBadge(capacity: capacity, isFull: isFull, colors: colors),
                  ],
                ),
              ),

              // ── Footer: time + host + join ─────────────────────────
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    // Time + host info
                    Expanded(
                      child: Row(
                        children: [
                          _InfoChip(
                            icon: AppIcons.schedule,
                            label: timeFormatter.format(lobby.scheduledTime),
                            color: colors.primary,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          _InfoChip(
                            icon: AppIcons.user,
                            label: lobby.hostName,
                            color: colors.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    // Join button — khác UI giữa lobby của mình vs người khác.
                    SizedBox(
                      width: 96,
                      child: isMine
                          ? _OpenOwnedButton(onTap: onTap)
                          : _JoinButton(
                              isFull: isFull,
                              onTap: isFull ? null : onJoin,
                            ),
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
}

/// Badge "Phòng của bạn" — hiển thị trên header card khi user là host.
/// Dùng white-on-primary vì header có gradient primary (đảm bảo tương phản).
class _OwnedBadge extends StatelessWidget {
  const _OwnedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.radiusXsAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
            Icon(AppIcons.warning, size: 10, color: AppColors.warning),
          const SizedBox(width: 2),
          const Text(
            'Của bạn',
            style: TextStyle(
              color: Color(0xFF6B4A00),
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _GameAvatar extends StatelessWidget {
  final LobbyEntity lobby;
  final ThemeData theme;
  final ColorScheme colors;

  const _GameAvatar({
    required this.lobby,
    required this.theme,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = lobby.gameImageUrl != null && lobby.gameImageUrl!.isNotEmpty;

    if (hasImage) {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: AppRadius.radiusMdAll,
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.network(
          lobby.gameImageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _InitialAvatar(lobby: lobby),
        ),
      );
    }

    return _InitialAvatar(lobby: lobby);
  }
}

class _InitialAvatar extends StatelessWidget {
  final LobbyEntity lobby;

  const _InitialAvatar({required this.lobby});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: AppRadius.radiusMdAll,
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Center(
        child: Text(
          lobby.gameName.isNotEmpty ? lobby.gameName[0].toUpperCase() : '?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _CapacityBadge extends StatelessWidget {
  final String capacity;
  final bool isFull;
  final ColorScheme colors;

  const _CapacityBadge({
    required this.capacity,
    required this.isFull,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isFull ? colors.error : Colors.white.withValues(alpha: 0.25);
    final textColor = isFull ? Colors.white : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.radiusSmAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isFull) Icon(AppIcons.users, size: AppIcons.sm, color: textColor),
          if (!isFull) const SizedBox(width: 4),
          Text(
            capacity,
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppRadius.radiusSmAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _JoinButton extends StatelessWidget {
  final bool isFull;
  final VoidCallback? onTap;

  const _JoinButton({required this.isFull, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: isFull
            ? null
            : LinearGradient(colors: [colors.primary, colors.primary.withAlpha(204)]),
        color: isFull ? colors.surfaceContainerHighest : null,
        borderRadius: AppRadius.radiusMdAll,
        boxShadow: isFull
            ? null
            : [
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.radiusMdAll,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.radiusMdAll,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isFull ? Icons.block : AppIcons.login,
                  size: 16,
                  color: isFull ? colors.onSurfaceVariant : Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  isFull ? 'Đầy' : 'Vào',
                  style: TextStyle(
                    color: isFull ? colors.onSurfaceVariant : Colors.white,
                    fontWeight: FontWeight.w700,
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

/// Button "Mở" cho lobby do chính user hiện tại host.
///
/// Khác với `_JoinButton` (gradient đặc):
/// - Background trong suốt, border 1.5px primary — nhấn "neutral" hơn,
///   tránh gây hiểu nhầm là action đăng ký/join.
/// - Icon mở khoá (`lock_open`) + label "Mở" — semantic rõ ràng là
///   "mở lobby đã tạo để xem chi tiết", khác với "Vào" (= join).
class _OpenOwnedButton extends StatelessWidget {
  final VoidCallback onTap;

  const _OpenOwnedButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.35),
        border: Border.all(color: colors.primary, width: 1.5),
        borderRadius: AppRadius.radiusMdAll,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.radiusMdAll,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.radiusMdAll,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_open, size: 16, color: colors.primary),
                const SizedBox(width: 4),
                Text(
                  'Mở',
                  style: TextStyle(
                    color: colors.primary,
                    fontWeight: FontWeight.w800,
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

/// Gradient retry/create button.
class _GradientRetryButton extends StatelessWidget {
  final VoidCallback onTap;
  final String label;
  final IconData icon;

  const _GradientRetryButton({
    required this.onTap,
    this.label = 'Thử lại',
    this.icon = AppIcons.refresh,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.primary, colors.primary.withAlpha(204)],
        ),
        borderRadius: AppRadius.radiusMdAll,
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.radiusMdAll,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.radiusMdAll,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
