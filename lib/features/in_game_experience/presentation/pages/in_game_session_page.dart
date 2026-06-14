import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../match_summary_rating/presentation/pages/rating_page.dart';
import '../cubit/in_game_cubit.dart';
import '../cubit/in_game_state.dart';
import '../widgets/play_duration_timer.dart';

class InGameSessionPage extends StatefulWidget {
  final String bookingId;
  final String cafeName;
  final String gameName;
  final int tableNumber;

  const InGameSessionPage({
    super.key,
    required this.bookingId,
    required this.cafeName,
    required this.gameName,
    required this.tableNumber,
  });

  @override
  State<InGameSessionPage> createState() => _InGameSessionPageState();
}

class _InGameSessionPageState extends State<InGameSessionPage> {
  final _inGameCubit = getIt<InGameCubit>();

  @override
  void initState() {
    super.initState();
    _inGameCubit.checkIn(widget.bookingId);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _inGameCubit,
      child: BlocConsumer<InGameCubit, InGameState>(
        listener: (context, state) {
          if (state is InGameCheckoutComplete) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const RatingPage()),
            );
          }
        },
        builder: (context, state) {
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) {
              if (!didPop) {
                _showExitConfirmation(context);
              }
            },
            child: Scaffold(
              body: Stack(
                children: [
                  _buildBody(context, state),
                  if (state is InGameCheckingInventory)
                    const _InventoryCheckingOverlay(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, InGameState state) {
    if (state is InGameLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is InGameFailure) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(state.message),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => _inGameCubit.checkIn(widget.bookingId),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (state is InGameSessionActive) {
      return _buildSessionView(context, state);
    }

    if (state is InGameCheckingInventory) {
      return _buildSessionView(
        context,
        InGameSessionActive(
          session: state.session,
          currentDuration: Duration.zero,
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildSessionView(BuildContext context, InGameSessionActive state) {
    final theme = Theme.of(context);
    final session = state.session;

    return SafeArea(
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.primaryContainer,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session.cafeName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.table_restaurant,
                                size: 16,
                                color: theme.colorScheme.outline,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Bàn số ${session.tableNumber}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    PlayDurationTimer(
                      startTime: session.startTime,
                      isRunning: true,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Game Info Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.extension,
                              color: theme.colorScheme.secondary,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  session.gameName,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${session.players.length} người chơi',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.outline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Players Section
                  Text(
                    'Người cùng chơi',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: session.players.map((player) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: player.isPresent
                              ? Colors.green.shade50
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: player.isPresent
                                ? Colors.green.shade300
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundImage: NetworkImage(player.avatarUrl),
                              onBackgroundImageError: (_, _) {},
                              child: player.avatarUrl.isEmpty
                                  ? Text(
                                      player.name[0].toUpperCase(),
                                      style: const TextStyle(fontSize: 10),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              player.name,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: player.isPresent
                                    ? Colors.green.shade800
                                    : Colors.grey,
                              ),
                            ),
                            if (player.isPresent) ...[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.check_circle,
                                size: 14,
                                color: Colors.green.shade600,
                              ),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Action
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () =>
                      _inGameCubit.requestCheckout(session.sessionId),
                  icon: const Icon(Icons.shopping_cart_checkout),
                  label: const Text('Yêu cầu tính tiền'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showExitConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận rời đi'),
        content: const Text(
          'Bạn đang trong phiên chơi. Bạn có chắc muốn rời khỏi trang này?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ở lại'),
          ),
        ],
      ),
    );
  }
}

class _InventoryCheckingOverlay extends StatelessWidget {
  const _InventoryCheckingOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      child: Center(
        child: Card(
          margin: const EdgeInsets.all(32),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                Icon(
                  Icons.inventory_2_outlined,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Nhân viên đang tiến hành kiểm tra linh kiện hộp game...',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Vui lòng chờ trong giây lát',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
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
