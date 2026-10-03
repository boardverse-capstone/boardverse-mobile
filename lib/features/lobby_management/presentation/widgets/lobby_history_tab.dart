import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../domain/entities/lobby_entity.dart';
import '../cubit/my_lobbies_cubit.dart';
import '../cubit/my_lobbies_state.dart';
import 'lobby_card_base.dart';

/// Tab "Của tôi" trong Lobby Hub — chỉ hiển thị danh sách phòng chờ
/// mà user đã tạo hoặc tham gia (gồm cả lobby liên kết tới reservation).
///
/// BR-NEW-MY-LOBBY-HISTORY (2026-10-02): bổ sung segmented control
/// "Đang hoạt động" / "Đã kết thúc" để player xem lại các lobby đã đóng.
/// Backend trả 2 nhóm qua 2 API call song song (xem [MyLobbiesCubit]).
/// UI render chung 1 loại card (LobbyCardBase + lobbyItemFromEntity) —
/// chỉ khác data list được feed vào dựa trên segment được chọn.
///
/// MVP scope: không thêm filter chip / sort option — chỉ toggle giữa
/// 2 nhóm active vs history. Sẽ mở rộng filter khi có feedback từ user.
class LobbyHistoryTab extends StatefulWidget {
  final MyLobbiesCubit myLobbiesCubit;
  final void Function(LobbyEntity) onTapLobby;
  final VoidCallback onRefresh;

  /// Callback khi player bấm nút "Tạo phòng" từ empty state. `null` nếu
  /// không muốn hiển thị action button trong empty state (vd: page chỉ
  /// hiển thị danh sách không cho phép tạo mới).
  final VoidCallback? onCreateLobby;

  const LobbyHistoryTab({
    super.key,
    required this.myLobbiesCubit,
    required this.onTapLobby,
    required this.onRefresh,
    this.onCreateLobby,
  });

  @override
  State<LobbyHistoryTab> createState() => _LobbyHistoryTabState();
}

class _LobbyHistoryTabState extends State<LobbyHistoryTab> {
  /// Index của segmented control. Default mở "Đang hoạt động" — phù hợp
  /// với use-case phổ biến nhất (vừa tạo/vừa tham gia lobby).
  int _selectedSegment = 0;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => widget.onRefresh(),
      child: BlocBuilder<MyLobbiesCubit, MyLobbiesState>(
        bloc: widget.myLobbiesCubit,
        builder: (context, state) {
          // Lấy count cho segmented control từ state Loaded. Trong lúc
          // loading/initial, dùng 0 để UI không bị giật.
          final activeCount = state is MyLobbiesLoaded
              ? state.activeCount
              : 0;
          final historyCount = state is MyLobbiesLoaded
              ? state.historyCount
              : 0;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _HeaderSection(
                  theme: Theme.of(context),
                  colors: Theme.of(context).colorScheme,
                ),
              ),

              // Segmented control "Đang hoạt động" / "Đã kết thúc".
              // Hiển thị count badge trên label để user biết có bao nhiêu
              // lobby mà không cần mở segment.
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                sliver: SliverToBoxAdapter(
                  child: _SegmentedTabs(
                    selected: _selectedSegment,
                    activeCount: activeCount,
                    historyCount: historyCount,
                    onChanged: (v) =>
                        setState(() => _selectedSegment = v),
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  120,
                ),
                sliver: _HistorySliver(
                  state: state,
                  selectedSegment: _selectedSegment,
                  onTapLobby: widget.onTapLobby,
                  onCreateLobby: widget.onCreateLobby,
                  onRetry: widget.onRefresh,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Segmented control 2 option: Active vs History — Material 3
/// SegmentedButton với count badge inline. Layout full-width để vừa
/// với mobile portrait.
class _SegmentedTabs extends StatelessWidget {
  final int selected;
  final int activeCount;
  final int historyCount;
  final ValueChanged<int> onChanged;

  const _SegmentedTabs({
    required this.selected,
    required this.activeCount,
    required this.historyCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<int>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment<int>(
            value: 0,
            label: _SegmentLabel(
              icon: Icons.bolt_rounded,
              label: 'Đang hoạt động',
              count: activeCount,
              selected: selected == 0,
            ),
          ),
          ButtonSegment<int>(
            value: 1,
            label: _SegmentLabel(
              icon: Icons.history_rounded,
              label: 'Đã kết thúc',
              count: historyCount,
              selected: selected == 1,
            ),
          ),
        ],
        selected: {selected},
        onSelectionChanged: (set) => onChanged(set.first),
        style: ButtonStyle(
          backgroundColor:
              WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.selected)) {
              return colors.primaryContainer;
            }
            return colors.surface;
          }),
          foregroundColor:
              WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.selected)) {
              return colors.onPrimaryContainer;
            }
            return colors.onSurfaceVariant;
          }),
          side: WidgetStateProperty.all(
            BorderSide(color: colors.outlineVariant),
          ),
          textStyle: WidgetStateProperty.all(
            const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

/// Nhãn trong từng segment — icon + text + count badge gọn.
class _SegmentLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final bool selected;

  const _SegmentLabel({
    required this.icon,
    required this.label,
    required this.count,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 1,
          ),
          decoration: BoxDecoration(
            color: selected
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : Theme.of(context).colorScheme.outlineVariant,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: selected
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

/// Nội dung lobby list theo segment đang chọn — return sliver widget.
class _HistorySliver extends StatelessWidget {
  final MyLobbiesState state;
  final int selectedSegment;
  final void Function(LobbyEntity) onTapLobby;
  final VoidCallback? onCreateLobby;
  final VoidCallback onRetry;

  const _HistorySliver({
    required this.state,
    required this.selectedSegment,
    required this.onTapLobby,
    required this.onCreateLobby,
    required this.onRetry,
  });

  bool get _isHistorySegment => selectedSegment == 1;

  @override
  Widget build(BuildContext context) {
    if (state is MyLobbiesLoading) {
      return SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisExtent: 265,
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => const _HistoryItemSkeleton(),
          childCount: 4,
        ),
      );
    }

    if (state is MyLobbiesFailure) {
      return SliverToBoxAdapter(
        child: SizedBox(
          height: 480,
          child: ErrorStateWidget(
            message: (state as MyLobbiesFailure).message,
            onRetry: onRetry,
            compact: true,
          ),
        ),
      );
    }

    if (state is MyLobbiesLoaded) {
      final loaded = state as MyLobbiesLoaded;

      // Chọn list theo segment.
      final visibleHosted =
          _isHistorySegment ? loaded.historyHosted : loaded.activeHosted;
      final visibleJoined =
          _isHistorySegment ? loaded.historyJoined : loaded.activeJoined;

      final isSegmentEmpty = visibleHosted.isEmpty && visibleJoined.isEmpty;

      if (isSegmentEmpty) {
        // Empty state cho từng segment — message khác nhau vì CTA chỉ
        // phù hợp với "đang hoạt động" (history không có "Tạo phòng mới").
        return SliverToBoxAdapter(
          child: SizedBox(
            height: 480,
            child: _isHistorySegment
                ? const LobbyEmptyState(
                    customTitle: 'Chưa có lịch sử phòng chờ',
                    customMessage:
                        'Bạn chưa từng tham gia hoặc tạo phòng chờ nào '
                        'đã kết thúc.',
                  )
                : LobbyEmptyState(
                    customTitle: 'Chưa có phòng chờ của tôi',
                    customMessage:
                        'Bạn chưa tạo hoặc tham gia phòng chờ nào.\n'
                        'Hãy tạo phòng mới hoặc khám phá các phòng đang '
                        'mở để tham gia.',
                    onCreateLobby: onCreateLobby,
                  ),
          ),
        );
      }

      return SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisExtent: 265,
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final isJoined = index < visibleJoined.length;
            final lobby = isJoined
                ? visibleJoined[index]
                : visibleHosted[index - visibleJoined.length];
            return _HistoryLobbyCard(
              lobby: lobby,
              isJoined: isJoined,
              onTap: () => onTapLobby(lobby),
            );
          },
          childCount: visibleJoined.length + visibleHosted.length,
        ),
      );
    }

    // Initial state (chưa load lần đầu) — hiển thị active empty làm default.
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 480,
        child: LobbyEmptyState(
          customTitle: 'Chưa có phòng chờ của tôi',
          customMessage: 'Bạn chưa tạo hoặc tham gia phòng chờ nào.',
          onCreateLobby: onCreateLobby,
        ),
      ),
    );
  }
}

/// Single lobby card — dùng chung cho cả 2 segment (active + history).
/// Reuse [LobbyCardBase] với factory [lobbyItemFromEntity] để đảm bảo
/// UI đồng nhất với tab Explore và các chỗ khác trong app. Card tự
/// render màu sắc theo status variant (closed/timeoutFailed/etc).
class _HistoryLobbyCard extends StatelessWidget {
  final LobbyEntity lobby;
  final bool isJoined;
  final VoidCallback onTap;

  const _HistoryLobbyCard({
    required this.lobby,
    required this.isJoined,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LobbyCardBase(
      item: lobbyItemFromEntity(
        lobby,
        isOwnedByMe: !isJoined,
      ),
      onTap: onTap,
      layout: LobbyCardLayout.vertical,
    );
  }
}

/// Header section for "Phòng chờ của tôi".
class _HeaderSection extends StatelessWidget {
  final ThemeData theme;
  final ColorScheme colors;

  const _HeaderSection({required this.theme, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        0,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colors.primary, colors.primary.withAlpha(204)],
              ),
              borderRadius: AppRadius.radiusSmAll,
            ),
            child:
                const Icon(Icons.meeting_room, color: Colors.white, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Phòng chờ của tôi',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Phòng đã tạo hoặc tham gia',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
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

/// Shimmer skeleton tile cho history section — match layout của _HistoryLobbyCard.
class _HistoryItemSkeleton extends StatelessWidget {
  const _HistoryItemSkeleton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgBase = isDark ? AppColors.surfaceElevatedDark : AppColors.surface;

    return AppShimmer.shimmer(
      context: context,
      child: Container(
        decoration: BoxDecoration(
          color: bgBase,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? AppColors.borderDark.withValues(alpha: 0.4)
                : AppColors.border.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Artwork cover placeholder
            Container(
              height: 88,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.casino_rounded,
                  size: 42,
                  color: Colors.white30,
                ),
              ),
            ),
            // Content — match vertical card padding/sizes
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title placeholder
                    Container(
                      width: double.infinity,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Cafe placeholder
                    Container(
                      width: 80,
                      height: 11,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Time chip placeholder (2-row stacked: date + time)
                    Container(
                      width: 140,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const Spacer(),
                    // Share code pill placeholder — full width
                    Container(
                      width: double.infinity,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 7),
                    // Hint line placeholder
                    Container(
                      width: 120,
                      height: 9,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}