import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../di/injection.dart';
import '../../../features/profile/presentation/cubit/profile_cubit.dart';
import '../widgets/leaderboard_card.dart';

class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProfileCubit>(
      create: (_) => getIt<ProfileCubit>()..getProfile(),
      child: const _LeaderboardPageContent(),
    );
  }
}

class _LeaderboardPageContent extends StatefulWidget {
  const _LeaderboardPageContent();

  @override
  State<_LeaderboardPageContent> createState() => _LeaderboardPageContentState();
}

class _LeaderboardPageContentState extends State<_LeaderboardPageContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTimeframe = 0;

  final List<Map<String, dynamic>> _mockLeaderboard = [
    {
      'rank': 1,
      'username': 'MasterCatan',
      'elo': 2150,
      'level': 42,
      'wins': 156,
      'avatar': 'M',
      'isCurrentUser': false,
      'tier': 'Diamond',
    },
    {
      'rank': 2,
      'username': 'DiceRoller99',
      'elo': 2080,
      'level': 38,
      'wins': 142,
      'avatar': 'D',
      'isCurrentUser': false,
      'tier': 'Platinum',
    },
    {
      'rank': 3,
      'username': 'BoardKing',
      'elo': 2050,
      'level': 35,
      'wins': 138,
      'avatar': 'B',
      'isCurrentUser': false,
      'tier': 'Platinum',
    },
    {
      'rank': 4,
      'username': 'StrategyMaster',
      'elo': 2020,
      'level': 33,
      'wins': 130,
      'avatar': 'S',
      'isCurrentUser': false,
      'tier': 'Gold',
    },
    {
      'rank': 5,
      'username': 'GameNightHero',
      'elo': 1980,
      'level': 30,
      'wins': 125,
      'avatar': 'G',
      'isCurrentUser': true,
      'tier': 'Gold',
    },
    {
      'rank': 6,
      'username': 'CardShark',
      'elo': 1950,
      'level': 28,
      'wins': 118,
      'avatar': 'C',
      'isCurrentUser': false,
      'tier': 'Gold',
    },
    {
      'rank': 7,
      'username': 'TokenCollector',
      'elo': 1920,
      'level': 26,
      'wins': 112,
      'avatar': 'T',
      'isCurrentUser': false,
      'tier': 'Silver',
    },
    {
      'rank': 8,
      'username': 'RollHigh',
      'elo': 1890,
      'level': 24,
      'wins': 108,
      'avatar': 'R',
      'isCurrentUser': false,
      'tier': 'Silver',
    },
    {
      'rank': 9,
      'username': 'PieceMover',
      'elo': 1860,
      'level': 22,
      'wins': 102,
      'avatar': 'P',
      'isCurrentUser': false,
      'tier': 'Silver',
    },
    {
      'rank': 10,
      'username': 'HexExplorer',
      'elo': 1830,
      'level': 20,
      'wins': 98,
      'avatar': 'H',
      'isCurrentUser': false,
      'tier': 'Bronze',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bảng xếp hạng'),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              _buildTimeframeSelector(context),
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'ELO'),
                  Tab(text: 'Thắng'),
                  Tab(text: 'Karma'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          _buildTopThree(context),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRankingList(context, 'elo'),
                _buildRankingList(context, 'wins'),
                _buildRankingList(context, 'karma'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeframeSelector(BuildContext context) {
    final theme = Theme.of(context);
    final timeframes = ['Hôm nay', 'Tuần này', 'Tháng này', 'Mọi lúc'];

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: timeframes.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedTimeframe == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(timeframes[index]),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedTimeframe = index);
                }
              },
              labelStyle: TextStyle(
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopThree(BuildContext context) {
    final theme = Theme.of(context);
    final topThree = _mockLeaderboard.take(3).toList();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
            theme.colorScheme.surface,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (topThree.length > 1)
            _buildTopPlayerCard(context, topThree[1], 2, 80),
          if (topThree.isNotEmpty)
            _buildTopPlayerCard(context, topThree[0], 1, 100),
          if (topThree.length > 2)
            _buildTopPlayerCard(context, topThree[2], 3, 80),
        ],
      ),
    );
  }

  Widget _buildTopPlayerCard(
    BuildContext context,
    Map<String, dynamic> player,
    int rank,
    double height,
  ) {
    final theme = Theme.of(context);
    final isFirst = rank == 1;

    return GestureDetector(
      onTap: () => _showPlayerDetails(context, player),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.topCenter,
            children: [
              Container(
                width: isFirst ? 72 : 60,
                height: isFirst ? 72 : 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: _getRankColors(rank),
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _getRankColors(rank)[0].withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    player['avatar'],
                    style: TextStyle(
                      fontSize: isFirst ? 28 : 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getRankColors(rank)[0],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getRankIcon(rank),
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '$rank',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 80,
            child: Text(
              player['username'],
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: player['isCurrentUser'] ? FontWeight.bold : null,
                color: player['isCurrentUser']
                    ? theme.colorScheme.primary
                    : null,
              ),
            ),
          ),
          Text(
            '${player['elo']} ELO',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _getTierColor(player['tier']).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              player['tier'],
              style: theme.textTheme.labelSmall?.copyWith(
                color: _getTierColor(player['tier']),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankingList(BuildContext context, String sortBy) {
    final sortedList = List<Map<String, dynamic>>.from(_mockLeaderboard);
    
    if (sortBy == 'elo') {
      sortedList.sort((a, b) => b['elo'].compareTo(a['elo']));
    } else if (sortBy == 'wins') {
      sortedList.sort((a, b) => b['wins'].compareTo(a['wins']));
    }

    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sortedList.length,
        itemBuilder: (context, index) {
          final player = sortedList[index];
          final displayRank = index + 1;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: LeaderboardCard(
              player: player,
              rank: displayRank,
              sortBy: sortBy,
              onTap: () => _showPlayerDetails(context, player),
            ),
          );
        },
      ),
    );
  }

  void _showPlayerDetails(BuildContext context, Map<String, dynamic> player) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                player['avatar'],
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              player['username'],
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _getTierColor(player['tier']).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                player['tier'],
                style: TextStyle(
                  color: _getTierColor(player['tier']),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatItem(label: 'ELO', value: '${player['elo']}'),
                _StatItem(label: 'Level', value: '${player['level']}'),
                _StatItem(label: 'Thắng', value: '${player['wins']}'),
              ],
            ),
            const SizedBox(height: 24),
            if (!player['isCurrentUser'])
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã gửi lời mời kết bạn!'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.person_add),
                  label: const Text('Kết bạn'),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text('Đây là bạn!'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Color> _getRankColors(int rank) {
    switch (rank) {
      case 1:
        return [Colors.amber.shade700, Colors.amber.shade400];
      case 2:
        return [Colors.grey.shade600, Colors.grey.shade400];
      case 3:
        return [Colors.brown.shade600, Colors.brown.shade400];
      default:
        return [Colors.grey, Colors.grey.shade400];
    }
  }

  IconData _getRankIcon(int rank) {
    switch (rank) {
      case 1:
        return Icons.workspace_premium;
      case 2:
        return Icons.military_tech;
      case 3:
        return Icons.emoji_events;
      default:
        return Icons.tag;
    }
  }

  Color _getTierColor(String tier) {
    switch (tier) {
      case 'Diamond':
        return Colors.blue;
      case 'Platinum':
        return Colors.teal;
      case 'Gold':
        return Colors.amber.shade700;
      case 'Silver':
        return Colors.grey.shade600;
      case 'Bronze':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }
}
