import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';

class _Standing {
  final int pos;
  final String team;
  final int played;
  final int wins;
  final int losses;
  final int pointsFor;
  final int pointsAgainst;

  _Standing({
    required this.pos,
    required this.team,
    required this.played,
    required this.wins,
    required this.losses,
    required this.pointsFor,
    required this.pointsAgainst,
  });

  int get diff => pointsFor - pointsAgainst;
}

class StandingsScreen extends StatefulWidget {
  const StandingsScreen({super.key});

  @override
  State<StandingsScreen> createState() => _StandingsScreenState();
}

class _StandingsScreenState extends State<StandingsScreen> {
  List<_Standing> _standings = [];
  String _seasonName = '';
  String? _lastRound;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStandings();
  }

  Future<void> _loadStandings() async {
    try {
      final client = Supabase.instance.client;

      // Get active season
      final season = await client
          .from('seasons')
          .select()
          .eq('is_active', true)
          .single();

      final seasonId = season['id'] as String;

      // Get teams and matches separately to avoid FK hint issues
      final teamsData = await client.from('teams').select('id, name');
      final teamNames = {for (final t in teamsData) t['id'] as String: t['name'] as String};

      final matches = await client
          .from('matches')
          .select('home_team_id, away_team_id, home_score, away_score, round')
          .eq('season_id', seasonId)
          .eq('status', 'finished');

      // Calculate standings
      final Map<String, Map<String, dynamic>> stats = {};

      for (final m in matches) {
        final homeId = m['home_team_id'] as String;
        final awayId = m['away_team_id'] as String;
        final homeScore = m['home_score'] as int;
        final awayScore = m['away_score'] as int;
        final homeName = teamNames[homeId] ?? homeId;
        final awayName = teamNames[awayId] ?? awayId;

        stats.putIfAbsent(homeId, () => {'name': homeName, 'w': 0, 'l': 0, 'pf': 0, 'pc': 0});
        stats.putIfAbsent(awayId, () => {'name': awayName, 'w': 0, 'l': 0, 'pf': 0, 'pc': 0});

        stats[homeId]!['pf'] += homeScore;
        stats[homeId]!['pc'] += awayScore;
        stats[awayId]!['pf'] += awayScore;
        stats[awayId]!['pc'] += homeScore;

        if (homeScore > awayScore) {
          stats[homeId]!['w'] += 1;
          stats[awayId]!['l'] += 1;
        } else {
          stats[awayId]!['w'] += 1;
          stats[homeId]!['l'] += 1;
        }
      }

      // Sort by wins desc, then diff desc
      final sorted = stats.entries.toList()
        ..sort((a, b) {
          final wDiff = (b.value['w'] as int) - (a.value['w'] as int);
          if (wDiff != 0) return wDiff;
          final aDiff = (a.value['pf'] as int) - (a.value['pc'] as int);
          final bDiff = (b.value['pf'] as int) - (b.value['pc'] as int);
          return bDiff - aDiff;
        });

      final standings = sorted.asMap().entries.map((e) {
        final s = e.value.value;
        final w = s['w'] as int;
        final l = s['l'] as int;
        return _Standing(
          pos: e.key + 1,
          team: s['name'] as String,
          played: w + l,
          wins: w,
          losses: l,
          pointsFor: s['pf'] as int,
          pointsAgainst: s['pc'] as int,
        );
      }).toList();

      // Get last played round
      final lastRound = matches.isNotEmpty
          ? matches.map((m) => m['round'] as int).reduce((a, b) => a > b ? a : b)
          : null;

      setState(() {
        _standings = standings;
        _seasonName = season['name'] as String;
        _lastRound = lastRound != null ? 'Actualizado tras fecha $lastRound' : null;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tabla de Posiciones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              setState(() => _loading = true);
              _loadStandings();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _TournamentSelector(name: _seasonName),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : _error != null
                    ? Center(child: Text(_error!, style: const TextStyle(color: AppTheme.danger)))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _StandingsTable(standings: _standings),
                            const SizedBox(height: 24),
                            if (_lastRound != null) _LastUpdated(label: _lastRound!),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _TournamentSelector extends StatelessWidget {
  final String name;
  const _TournamentSelector({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppTheme.surface,
      child: Row(
        children: [
          const Icon(Icons.emoji_events_rounded, color: AppTheme.primary, size: 16),
          const SizedBox(width: 8),
          Text(
            name.isEmpty ? '...' : name,
            style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          const Icon(Icons.expand_more, color: AppTheme.textSecondary),
        ],
      ),
    );
  }
}

class _StandingsTable extends StatelessWidget {
  final List<_Standing> standings;
  const _StandingsTable({required this.standings});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _TableHeader(),
          const Divider(height: 1),
          ...standings.asMap().entries.map((e) => Column(
                children: [
                  _TeamRow(standing: e.value, index: e.key),
                  if (e.key < standings.length - 1) const Divider(height: 1),
                ],
              )),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: const [
          SizedBox(width: 28, child: Text('#', style: _headerStyle, textAlign: TextAlign.center)),
          SizedBox(width: 10),
          Expanded(child: Text('EQUIPO', style: _headerStyle)),
          SizedBox(width: 36, child: Text('PJ', style: _headerStyle, textAlign: TextAlign.center)),
          SizedBox(width: 36, child: Text('G', style: _headerStyle, textAlign: TextAlign.center)),
          SizedBox(width: 36, child: Text('P', style: _headerStyle, textAlign: TextAlign.center)),
          SizedBox(width: 44, child: Text('PF', style: _headerStyle, textAlign: TextAlign.center)),
          SizedBox(width: 44, child: Text('PC', style: _headerStyle, textAlign: TextAlign.center)),
          SizedBox(width: 44, child: Text('DIF', style: _headerStyle, textAlign: TextAlign.center)),
        ],
      ),
    );
  }

  static const _headerStyle = TextStyle(
    color: AppTheme.textSecondary,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
  );
}

class _TeamRow extends StatelessWidget {
  final _Standing standing;
  final int index;
  const _TeamRow({required this.standing, required this.index});

  @override
  Widget build(BuildContext context) {
    final isFirst = standing.pos == 1;
    final diffPositive = standing.diff > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isFirst ? AppTheme.primary.withOpacity(0.06) : Colors.transparent,
        borderRadius: index == 0
            ? const BorderRadius.vertical(top: Radius.circular(16))
            : BorderRadius.zero,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: isFirst
                ? const Icon(Icons.emoji_events_rounded, color: AppTheme.primary, size: 16)
                : Text(
                    '${standing.pos}',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              standing.team,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: isFirst ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          _cell('${standing.played}', AppTheme.textSecondary),
          _cell('${standing.wins}', AppTheme.success, width: 36),
          _cell('${standing.losses}', AppTheme.danger, width: 36),
          _cell('${standing.pointsFor}', AppTheme.textSecondary, width: 44),
          _cell('${standing.pointsAgainst}', AppTheme.textSecondary, width: 44),
          SizedBox(
            width: 44,
            child: Text(
              diffPositive ? '+${standing.diff}' : '${standing.diff}',
              style: TextStyle(
                color: diffPositive ? AppTheme.success : AppTheme.danger,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _cell(String text, Color color, {double width = 36}) {
    return SizedBox(
      width: width,
      child: Text(text, style: TextStyle(color: color, fontSize: 13), textAlign: TextAlign.center),
    );
  }
}

class _LastUpdated extends StatelessWidget {
  final String label;
  const _LastUpdated({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.update_rounded, color: AppTheme.textSecondary, size: 13),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
      ],
    );
  }
}
