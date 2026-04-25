import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import 'player_stats_screen.dart';

class DashboardScreen extends StatefulWidget {
  final AppRole role;
  const DashboardScreen({super.key, required this.role});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Map<String, dynamic>> _teams = [];
  String? _selectedTeamId;
  String _seasonId = '';

  Map<String, dynamic>? _topScorer;
  Map<String, dynamic>? _topAssists;
  Map<String, dynamic>? _topRebounds;
  int _wins = 0;
  int _losses = 0;

  bool _loadingTeams = true;
  bool _loadingStats = false;

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  Future<void> _loadTeams() async {
    final client = Supabase.instance.client;
    final season = await client.from('seasons').select().eq('is_active', true).single();
    final teams = await client.from('teams').select('id, name').order('name');
    setState(() {
      _seasonId = season['id'] as String;
      _teams = List<Map<String, dynamic>>.from(teams);
      _loadingTeams = false;
    });
    if (_teams.isNotEmpty) {
      _selectTeam(_teams.first['id'] as String, _teams.first['name'] as String);
    }
  }

  Future<void> _selectTeam(String teamId, String teamName) async {
    setState(() {
      _selectedTeamId = teamId;
      _loadingStats = true;
    });

    final client = Supabase.instance.client;

    // Get player stats for this team
    final statsRows = await client
        .from('player_match_stats')
        .select('player_id, points, assists, rebounds, players(first_name, last_name, number)')
        .eq('team_id', teamId);

    // Aggregate per player
    final Map<String, Map<String, dynamic>> agg = {};
    for (final row in statsRows) {
      final pid = row['player_id'] as String;
      final player = row['players'] as Map<String, dynamic>;
      agg.putIfAbsent(pid, () => {
        'player_id': pid,
        'name': '${player['first_name']} ${player['last_name']}',
        'number': player['number'],
        'games': 0, 'points': 0, 'assists': 0, 'rebounds': 0,
      });
      agg[pid]!['games'] += 1;
      agg[pid]!['points'] += row['points'] as int;
      agg[pid]!['assists'] += row['assists'] as int;
      agg[pid]!['rebounds'] += row['rebounds'] as int;
    }

    if (agg.isEmpty) {
      setState(() { _topScorer = null; _topAssists = null; _topRebounds = null; _loadingStats = false; });
      return;
    }

    Map<String, dynamic> _best(String stat) {
      return agg.values.reduce((a, b) {
        final avgA = (a[stat] as int) / (a['games'] as int);
        final avgB = (b[stat] as int) / (b['games'] as int);
        return avgA >= avgB ? a : b;
      });
    }

    final topScorer = _best('points');
    final topAssists = _best('assists');
    final topRebounds = _best('rebounds');

    // W/L for this team
    final matches = await client
        .from('matches')
        .select('home_team_id, away_team_id, home_score, away_score')
        .eq('season_id', _seasonId)
        .eq('status', 'finished')
        .or('home_team_id.eq.$teamId,away_team_id.eq.$teamId');

    int wins = 0, losses = 0;
    for (final m in matches) {
      final isHome = m['home_team_id'] == teamId;
      final teamScore = isHome ? m['home_score'] as int : m['away_score'] as int;
      final oppScore = isHome ? m['away_score'] as int : m['home_score'] as int;
      if (teamScore > oppScore) wins++; else losses++;
    }

    setState(() {
      _topScorer = topScorer;
      _topAssists = topAssists;
      _topRebounds = topRebounds;
      _wins = wins;
      _losses = losses;
      _loadingStats = false;
    });
  }

  double _avg(Map<String, dynamic> p, String stat) =>
      (p[stat] as int) / (p['games'] as int);

  void _openPlayer(BuildContext context, Map<String, dynamic> player) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PlayerStatsScreen(
        playerId: player['player_id'] as String,
        playerName: player['name'] as String,
        playerNumber: '${player['number'] ?? '-'}',
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: AppTheme.primaryDim, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.sports_basketball, color: AppTheme.primary, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('BEA Stats'),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.surfaceElevated,
              child: const Icon(Icons.person, color: AppTheme.textSecondary, size: 18),
            ),
          ),
        ],
      ),
      body: _loadingTeams
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TeamSelector(
                    teams: _teams,
                    selectedId: _selectedTeamId,
                    onChanged: (id, name) => _selectTeam(id, name),
                  ),
                  const SizedBox(height: 20),
                  _SectionTitle('Líderes del equipo'),
                  const SizedBox(height: 12),
                  if (_loadingStats)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    ))
                  else
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.4,
                      children: [
                        _LeaderCard(
                          icon: Icons.sports_basketball,
                          color: const Color(0xFF2ECC71),
                          statLabel: 'Puntos',
                          playerNumber: '#${_topScorer?['number'] ?? '-'}',
                          playerName: _topScorer?['name'] ?? '-',
                          value: _topScorer != null ? _avg(_topScorer!, 'points').toStringAsFixed(1) : '-',
                          games: '${_topScorer?['games'] ?? 0} partidos',
                          onTap: _topScorer != null ? () => _openPlayer(context, _topScorer!) : null,
                        ),
                        _LeaderCard(
                          icon: Icons.swap_horiz_rounded,
                          color: const Color(0xFFE74C3C),
                          statLabel: 'Asistencias',
                          playerNumber: '#${_topAssists?['number'] ?? '-'}',
                          playerName: _topAssists?['name'] ?? '-',
                          value: _topAssists != null ? _avg(_topAssists!, 'assists').toStringAsFixed(1) : '-',
                          games: '${_topAssists?['games'] ?? 0} partidos',
                          onTap: _topAssists != null ? () => _openPlayer(context, _topAssists!) : null,
                        ),
                        _LeaderCard(
                          icon: Icons.fitness_center_rounded,
                          color: const Color(0xFF3498DB),
                          statLabel: 'Rebotes',
                          playerNumber: '#${_topRebounds?['number'] ?? '-'}',
                          playerName: _topRebounds?['name'] ?? '-',
                          value: _topRebounds != null ? _avg(_topRebounds!, 'rebounds').toStringAsFixed(1) : '-',
                          games: '${_topRebounds?['games'] ?? 0} partidos',
                          onTap: _topRebounds != null ? () => _openPlayer(context, _topRebounds!) : null,
                        ),
                        _RecordCard(wins: _wins, losses: _losses),
                      ],
                    ),
                ],
              ),
            ),
    );
  }
}

class _TeamSelector extends StatelessWidget {
  final List<Map<String, dynamic>> teams;
  final String? selectedId;
  final void Function(String id, String name) onChanged;

  const _TeamSelector({required this.teams, required this.selectedId, required this.onChanged});

  String get _selectedName {
    if (selectedId == null) return 'Seleccionar equipo';
    final team = teams.where((t) => t['id'] == selectedId).firstOrNull;
    return team?['name'] as String? ?? 'Seleccionar equipo';
  }

  void _openModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (_) => _TeamPickerModal(
        teams: teams,
        selectedId: selectedId,
        onSelect: (id, name) {
          Navigator.pop(context);
          onChanged(id, name);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openModal(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Row(
          children: [
            const Icon(Icons.sports_basketball, color: AppTheme.primary, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _selectedName,
                style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
            const Icon(Icons.expand_more, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _TeamPickerModal extends StatefulWidget {
  final List<Map<String, dynamic>> teams;
  final String? selectedId;
  final void Function(String id, String name) onSelect;

  const _TeamPickerModal({required this.teams, required this.selectedId, required this.onSelect});

  @override
  State<_TeamPickerModal> createState() => _TeamPickerModalState();
}

class _TeamPickerModalState extends State<_TeamPickerModal> {
  final _controller = TextEditingController();
  String _query = '';

  List<Map<String, dynamic>> get _filtered {
    if (_query.isEmpty) return widget.teams;
    return widget.teams
        .where((t) => (t['name'] as String).toLowerCase().contains(_query.toLowerCase()))
        .toList();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.divider, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _controller,
              autofocus: true,
              onChanged: (v) => setState(() => _query = v),
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Buscar equipo...',
                hintStyle: const TextStyle(color: AppTheme.textSecondary),
                prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textSecondary, size: 20),
                filled: true,
                fillColor: AppTheme.surfaceElevated,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.45),
            child: _filtered.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('Sin resultados', style: TextStyle(color: AppTheme.textSecondary)),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final team = _filtered[i];
                      final isSelected = team['id'] == widget.selectedId;
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        leading: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryDim,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.sports_basketball, color: AppTheme.primary, size: 18),
                        ),
                        title: Text(
                          team['name'] as String,
                          style: TextStyle(
                            color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 20)
                            : null,
                        onTap: () => widget.onSelect(team['id'] as String, team['name'] as String),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2),
    );
  }
}

class _LeaderCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String statLabel;
  final String playerNumber;
  final String playerName;
  final String value;
  final String games;
  final VoidCallback? onTap;

  const _LeaderCard({
    required this.icon, required this.color, required this.statLabel,
    required this.playerNumber, required this.playerName,
    required this.value, required this.games, this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(statLabel, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w600)),
          ]),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            RichText(text: TextSpan(children: [
              TextSpan(text: value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.w800)),
              const TextSpan(text: ' avg', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
            ])),
            Text('$playerNumber $playerName', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
            Text(games, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
          ]),
        ],
      ),
    ),
  );
  }
}

class _RecordCard extends StatelessWidget {
  final int wins;
  final int losses;

  const _RecordCard({required this.wins, required this.losses});

  @override
  Widget build(BuildContext context) {
    final total = wins + losses;
    final winPct = total > 0 ? wins / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('RESULTADOS', style: TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w600)),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('$wins', style: const TextStyle(color: AppTheme.success, fontSize: 22, fontWeight: FontWeight.w800)),
              const Text(' - ', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
              Text('$losses', style: const TextStyle(color: AppTheme.danger, fontSize: 22, fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: winPct,
                backgroundColor: AppTheme.danger.withValues(alpha: 0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.success),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 2),
            Text('${(winPct * 100).toStringAsFixed(0)}% victorias', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
          ]),
        ],
      ),
    );
  }
}
