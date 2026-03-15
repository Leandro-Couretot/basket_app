import 'package:flutter/material.dart';
import '../main.dart';

class FixtureScreen extends StatefulWidget {
  const FixtureScreen({super.key});

  @override
  State<FixtureScreen> createState() => _FixtureScreenState();
}

class _FixtureScreenState extends State<FixtureScreen> {
  int _selectedRound = 1;

  final List<_MockMatch> _matches = const [
    _MockMatch(round: 1, homeTeam: 'Lugano 80', awayTeam: 'Super Ácidos', homeScore: 84, awayScore: 37, date: '21/09/2025', finished: true),
    _MockMatch(round: 1, homeTeam: 'Achaval City', awayTeam: 'Slow Motion', homeScore: 71, awayScore: 65, date: '21/09/2025', finished: true),
    _MockMatch(round: 2, homeTeam: 'Super Ácidos', awayTeam: 'Slow Motion', date: '28/09/2025', finished: false),
    _MockMatch(round: 2, homeTeam: 'Lugano 80', awayTeam: 'Achaval City', date: '28/09/2025', finished: false),
    _MockMatch(round: 3, homeTeam: 'Slow Motion', awayTeam: 'Lugano 80', date: '05/10/2025', finished: false),
    _MockMatch(round: 3, homeTeam: 'Achaval City', awayTeam: 'Super Ácidos', date: '05/10/2025', finished: false),
  ];

  List<int> get _rounds => _matches.map((m) => m.round).toSet().toList()..sort();

  List<_MockMatch> get _filtered => _matches.where((m) => m.round == _selectedRound).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fixture'),
        actions: [
          IconButton(icon: const Icon(Icons.filter_list_rounded), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          _RoundSelector(
            rounds: _rounds,
            selected: _selectedRound,
            onSelect: (r) => setState(() => _selectedRound = r),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _MatchCard(match: _filtered[i]),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nuevo partido', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _RoundSelector extends StatelessWidget {
  final List<int> rounds;
  final int selected;
  final ValueChanged<int> onSelect;

  const _RoundSelector({required this.rounds, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: rounds.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final round = rounds[i];
            final isSelected = round == selected;
            return GestureDetector(
              onTap: () => onSelect(round),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primary : AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Fecha $round',
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  final _MockMatch match;

  const _MatchCard({required this.match});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(match.date, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: match.finished ? AppTheme.success.withOpacity(0.15) : AppTheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  match.finished ? 'FINALIZADO' : 'PRÓXIMO',
                  style: TextStyle(
                    color: match.finished ? AppTheme.success : AppTheme.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  match.homeTeam,
                  style: TextStyle(
                    color: match.finished && match.homeScore! > match.awayScore! ? AppTheme.textPrimary : AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              if (match.finished)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Text('${match.homeScore}',
                          style: TextStyle(
                              color: match.homeScore! > match.awayScore! ? AppTheme.primary : AppTheme.textSecondary,
                              fontWeight: FontWeight.w800,
                              fontSize: 18)),
                      const Text('  –  ', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                      Text('${match.awayScore}',
                          style: TextStyle(
                              color: match.awayScore! > match.homeScore! ? AppTheme.primary : AppTheme.textSecondary,
                              fontWeight: FontWeight.w800,
                              fontSize: 18)),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('vs', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                ),
              Expanded(
                child: Text(
                  match.awayTeam,
                  style: TextStyle(
                    color: match.finished && match.awayScore! > match.homeScore! ? AppTheme.textPrimary : AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          if (match.finished) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                _ActionChip(icon: Icons.bar_chart_rounded, label: 'Box Score'),
                const SizedBox(width: 8),
                _ActionChip(icon: Icons.share_rounded, label: 'Compartir'),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ActionChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.textSecondary, size: 13),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _MockMatch {
  final int round;
  final String homeTeam;
  final String awayTeam;
  final int? homeScore;
  final int? awayScore;
  final String date;
  final bool finished;

  const _MockMatch({
    required this.round,
    required this.homeTeam,
    required this.awayTeam,
    this.homeScore,
    this.awayScore,
    required this.date,
    required this.finished,
  });
}
