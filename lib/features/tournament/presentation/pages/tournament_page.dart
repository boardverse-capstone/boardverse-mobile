import 'package:flutter/material.dart';

import '../../data/mock_tournaments.dart';
import '../../domain/entities/tournament_entity.dart';
import '../../domain/entities/tournament_status.dart';
import '../widgets/tournament_empty_state.dart';
import '../widgets/tournament_list_card.dart';

class TournamentPage extends StatefulWidget {
  const TournamentPage({super.key});

  @override
  State<TournamentPage> createState() => _TournamentPageState();
}

class _TournamentPageState extends State<TournamentPage> {
  static const _allLabel = 'Tất cả';
  static const _filterLabels = <String>[
    _allLabel,
    'Đang mở',
    'Sắp diễn ra',
    'Đang diễn ra',
    'Đã kết thúc',
  ];

  int _selectedFilter = 0;
  late List<TournamentEntity> _allTournaments;

  @override
  void initState() {
    super.initState();
    _allTournaments = MockTournaments.getAll();
  }

  List<TournamentEntity> get _filtered {
    switch (_selectedFilter) {
      case 1:
        return _allTournaments
            .where((t) => t.status == TournamentStatus.registrationOpen)
            .toList();
      case 2:
        return _allTournaments
            .where((t) => t.status == TournamentStatus.upcoming)
            .toList();
      case 3:
        return _allTournaments
            .where((t) => t.status == TournamentStatus.ongoing)
            .toList();
      case 4:
        return _allTournaments
            .where((t) => t.status == TournamentStatus.finished)
            .toList();
      default:
        return _allTournaments;
    }
  }

  void _showTournamentDetail(TournamentEntity tournament) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _TournamentDetailSheet(tournament: tournament),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filtered;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            automaticallyImplyLeading: false,
            pinned: true,
            centerTitle: false,
            actions: [
              IconButton(
                tooltip: 'Thông báo',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tính năng thông báo đang phát triển'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.notifications_outlined),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              color: theme.colorScheme.surface,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(_filterLabels.length, (index) {
                    final selected = _selectedFilter == index;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(_filterLabels[index]),
                        selected: selected,
                        onSelected: (_) =>
                            setState(() => _selectedFilter = index),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
        body: filtered.isEmpty
            ? const TournamentEmptyState()
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final tournament = filtered[index];
                  return TournamentListCard(
                    tournament: tournament,
                    onTap: () => _showTournamentDetail(tournament),
                  );
                },
              ),
      ),
    );
  }
}

class _TournamentDetailSheet extends StatelessWidget {
  final TournamentEntity tournament;

  const _TournamentDetailSheet({required this.tournament});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canRegister = tournament.status == TournamentStatus.registrationOpen;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                tournament.name,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${tournament.gameName} · ${tournament.cafeName}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                tournament.description,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Text(
                'Thông tin giải đấu',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _detailRow(theme, Icons.calendar_today, 'Bắt đầu',
                  _dateFmt.format(tournament.startDate)),
              _detailRow(theme, Icons.event_busy, 'Hạn đăng ký',
                  _dateFmt.format(tournament.registrationDeadline)),
              _detailRow(theme, Icons.people, 'Người tham gia',
                  '${tournament.currentParticipants}/${tournament.maxParticipants}'),
              if (tournament.requiresElo)
                _detailRow(
                    theme, Icons.trending_up, 'ELO tối thiểu',
                    '${tournament.minEloRequired}'),
              if (tournament.entryFee != null && tournament.entryFee! > 0)
                _detailRow(theme, Icons.payments, 'Phí tham gia',
                    '${_vnd(tournament.entryFee!)}đ')
              else
                _detailRow(theme, Icons.local_offer, 'Phí tham gia', 'Miễn phí'),
              if (tournament.prizePool > 0)
                _detailRow(theme, Icons.workspace_premium, 'Tổng giải thưởng',
                    '${_vnd(tournament.prizePool)}đ'),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: canRegister
                      ? () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Đã gửi yêu cầu đăng ký "${tournament.name}". Tính năng sẽ được kích hoạt khi backend sẵn sàng.'),
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                      : null,
                  icon: const Icon(Icons.how_to_reg),
                  label: Text(canRegister ? 'Đăng ký tham gia' : 'Hiện chưa mở đăng ký'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(
      ThemeData theme, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: theme.textTheme.bodyMedium),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  static final _dateFmt = _DateFormat();

  String _vnd(int value) {
    final s = value.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

class _DateFormat {
  String format(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
  }
}
