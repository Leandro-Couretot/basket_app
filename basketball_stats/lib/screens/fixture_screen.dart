import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';

class FixtureScreen extends StatefulWidget {
  const FixtureScreen({super.key});

  @override
  State<FixtureScreen> createState() => _FixtureScreenState();
}

class _FixtureScreenState extends State<FixtureScreen> {
  int _selectedRound = 1;
  List<Map<String, dynamic>> _matches = [];
  Map<String, String> _teamNames = {};
  List<int> _rounds = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFixture();
  }

  Future<void> _loadFixture() async {
    final client = Supabase.instance.client;

    final season = await client.from('seasons').select().eq('is_active', true).single();
    final seasonId = season['id'] as String;

    final teamsData = await client.from('teams').select('id, name');
    final teamNames = {for (final t in teamsData) t['id'] as String: t['name'] as String};

    final matches = await client
        .from('matches')
        .select('id, home_team_id, away_team_id, home_score, away_score, match_date, round, status')
        .eq('season_id', seasonId)
        .order('round')
        .order('match_date');

    final rounds = (matches.map((m) => m['round'] as int).toSet().toList()..sort());

    setState(() {
      _matches = List<Map<String, dynamic>>.from(matches);
      _teamNames = teamNames;
      _rounds = rounds;
      _selectedRound = rounds.isNotEmpty ? rounds.first : 1;
      _loading = false;
    });
  }

  List<Map<String, dynamic>> get _filtered =>
      _matches.where((m) => m['round'] == _selectedRound).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fixture'),
        actions: [
          IconButton(icon: const Icon(Icons.filter_list_rounded), onPressed: () {}),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : Column(
              children: [
                _RoundSelector(
                  rounds: _rounds,
                  selected: _selectedRound,
                  onSelect: (r) => setState(() => _selectedRound = r),
                ),
                Expanded(
                  child: _filtered.isEmpty
                      ? const Center(child: Text('Sin partidos en esta fecha', style: TextStyle(color: AppTheme.textSecondary)))
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, i) => _MatchCard(
                            match: _filtered[i],
                            teamNames: _teamNames,
                          ),
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
  final Map<String, dynamic> match;
  final Map<String, String> teamNames;

  const _MatchCard({required this.match, required this.teamNames});

  @override
  Widget build(BuildContext context) {
    final finished = match['status'] == 'finished';
    final homeTeam = teamNames[match['home_team_id']] ?? '?';
    final awayTeam = teamNames[match['away_team_id']] ?? '?';
    final homeScore = match['home_score'] as int;
    final awayScore = match['away_score'] as int;
    final date = _formatDate(match['match_date'] as String);

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
              Text(date, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: finished
                      ? AppTheme.success.withValues(alpha: 0.15)
                      : AppTheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  finished ? 'FINALIZADO' : 'PRÓXIMO',
                  style: TextStyle(
                    color: finished ? AppTheme.success : AppTheme.primary,
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
                  homeTeam,
                  style: TextStyle(
                    color: finished && homeScore > awayScore ? AppTheme.textPrimary : AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              if (finished)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      Text('$homeScore', style: TextStyle(color: homeScore > awayScore ? AppTheme.primary : AppTheme.textSecondary, fontWeight: FontWeight.w800, fontSize: 18)),
                      const Text('  –  ', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                      Text('$awayScore', style: TextStyle(color: awayScore > homeScore ? AppTheme.primary : AppTheme.textSecondary, fontWeight: FontWeight.w800, fontSize: 18)),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(10)),
                  child: const Text('vs', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                ),
              Expanded(
                child: Text(
                  awayTeam,
                  style: TextStyle(
                    color: finished && awayScore > homeScore ? AppTheme.textPrimary : AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          if (finished) ...[
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

  String _formatDate(String iso) {
    final dt = DateTime.parse(iso);
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
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
