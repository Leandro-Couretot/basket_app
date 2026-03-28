import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';

class LiveStatsScreen extends StatefulWidget {
  const LiveStatsScreen({super.key});

  @override
  State<LiveStatsScreen> createState() => _LiveStatsScreenState();
}

class _LiveStatsScreenState extends State<LiveStatsScreen> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _matches = [];
  Map<String, dynamic>? _selectedMatch;
  List<Map<String, dynamic>> _playersHome = [];
  List<Map<String, dynamic>> _playersAway = [];
  late TabController _tabController;

  // playerId -> { pts, ast, reb, fal, d2c, d2i, d3c, d3i, tlc, tli }
  final Map<String, Map<String, int>> _stats = {};
  final Set<String> _saving = {};

  bool _loadingMatches = true;
  bool _loadingPlayers = false;

  int get _homeScore => _playersHome.fold(0, (s, p) => s + (_stats[p['id'] as String]?['pts'] ?? 0));
  int get _awayScore  => _playersAway.fold(0, (s, p) => s + (_stats[p['id'] as String]?['pts'] ?? 0));

  Map<String, int> _emptyStats() => {
    'pts': 0, 'ast': 0, 'reb': 0, 'fal': 0,
    'd2c': 0, 'd2i': 0, 'd3c': 0, 'd3i': 0, 'tlc': 0, 'tli': 0,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMatches();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMatches() async {
    final matches = await Supabase.instance.client
        .from('matches')
        .select('id, round, match_date, home_team_id, away_team_id, home_team:teams!matches_home_team_id_fkey(name), away_team:teams!matches_away_team_id_fkey(name)')
        .inFilter('status', ['scheduled', 'in_progress'])
        .order('match_date');
    setState(() {
      _matches = List<Map<String, dynamic>>.from(matches);
      _loadingMatches = false;
    });
  }

  Future<void> _selectMatch(Map<String, dynamic> match) async {
    setState(() { _selectedMatch = match; _loadingPlayers = true; });

    final client = Supabase.instance.client;
    final homeId = match['home_team_id'] as String;
    final awayId = match['away_team_id'] as String;
    final matchId = match['id'] as String;

    final homePlayers = await client.from('players').select('id, first_name, last_name, number').eq('team_id', homeId).order('number');
    final awayPlayers = await client.from('players').select('id, first_name, last_name, number').eq('team_id', awayId).order('number');

    final existingStats = await client.from('player_match_stats')
        .select('player_id, points, assists, rebounds, fouls, two_pt_made, two_pt_attempted, three_pt_made, three_pt_attempted, ft_made, ft_attempted')
        .eq('match_id', matchId);

    for (final p in [...homePlayers, ...awayPlayers]) {
      _stats[p['id'] as String] = _emptyStats();
    }
    for (final row in existingStats) {
      final pid = row['player_id'] as String;
      if (_stats.containsKey(pid)) {
        _stats[pid] = {
          'pts': (row['points']          as int?) ?? 0,
          'ast': (row['assists']          as int?) ?? 0,
          'reb': (row['rebounds']         as int?) ?? 0,
          'fal': (row['fouls']            as int?) ?? 0,
          'd2c': (row['two_pt_made']      as int?) ?? 0,
          'd2i': (row['two_pt_attempted'] as int?) ?? 0,
          'd3c': (row['three_pt_made']    as int?) ?? 0,
          'd3i': (row['three_pt_attempted'] as int?) ?? 0,
          'tlc': (row['ft_made']          as int?) ?? 0,
          'tli': (row['ft_attempted']     as int?) ?? 0,
        };
      }
    }

    setState(() {
      _playersHome = List<Map<String, dynamic>>.from(homePlayers);
      _playersAway = List<Map<String, dynamic>>.from(awayPlayers);
      _loadingPlayers = false;
    });
  }

  Future<void> _saveStats(String playerId, String teamId) async {
    final matchId = _selectedMatch!['id'] as String;
    final s = _stats[playerId]!;
    setState(() => _saving.add(playerId));
    try {
      final client = Supabase.instance.client;
      await client.from('player_match_stats').upsert({
        'match_id': matchId,
        'player_id': playerId,
        'team_id': teamId,
        'points':              s['pts'],
        'assists':             s['ast'],
        'rebounds':            s['reb'],
        'fouls':               s['fal'],
        'two_pt_made':         s['d2c'],
        'two_pt_attempted':    s['d2i'],
        'three_pt_made':       s['d3c'],
        'three_pt_attempted':  s['d3i'],
        'ft_made':             s['tlc'],
        'ft_attempted':        s['tli'],
      }, onConflict: 'match_id,player_id');
      await client.from('matches').update({
        'home_score': _homeScore,
        'away_score': _awayScore,
        'status': 'in_progress',
      }).eq('id', matchId);
    } finally {
      if (mounted) setState(() => _saving.remove(playerId));
    }
  }

  Future<void> _updateStat(String playerId, String teamId, String stat, int delta) async {
    final current = _stats[playerId]![stat]!;
    final next = (current + delta).clamp(0, 99);
    if (next == current) return;
    setState(() => _stats[playerId]![stat] = next);
    await _saveStats(playerId, teamId);
  }

  void _openShotBreakdown(Map<String, dynamic> player, String teamId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _ShotBreakdownSheet(
        player: player,
        initialStats: Map<String, int>.from(_stats[player['id'] as String]!),
        onApply: (shots) {
          final pid = player['id'] as String;
          final calcPts = shots['d2c']! * 2 + shots['d3c']! * 3 + shots['tlc']!;
          setState(() {
            _stats[pid]!.addAll(shots);
            _stats[pid]!['pts'] = calcPts;
          });
          _saveStats(pid, teamId);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _selectedMatch == null
            ? const Text('Acta en Vivo')
            : _MatchTitle(match: _selectedMatch!),
        leading: _selectedMatch != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded),
                onPressed: () => setState(() {
                  _selectedMatch = null;
                  _playersHome = [];
                  _playersAway = [];
                  _stats.clear();
                }),
              )
            : null,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loadingMatches) return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    if (_selectedMatch == null) return _MatchList(matches: _matches, onSelect: _selectMatch);
    if (_loadingPlayers) return const Center(child: CircularProgressIndicator(color: AppTheme.primary));

    final homeName = (_selectedMatch!['home_team'] as Map)['name'] as String;
    final awayName = (_selectedMatch!['away_team'] as Map)['name'] as String;

    return Column(
      children: [
        _Scoreboard(homeName: homeName, awayName: awayName, homeScore: _homeScore, awayScore: _awayScore),
        TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primary,
          dividerColor: AppTheme.divider,
          tabs: [Tab(text: homeName), Tab(text: awayName)],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _PlayerList(
                players: _playersHome,
                teamId: _selectedMatch!['home_team_id'] as String,
                stats: _stats,
                saving: _saving,
                onUpdate: _updateStat,
                onTapShots: _openShotBreakdown,
              ),
              _PlayerList(
                players: _playersAway,
                teamId: _selectedMatch!['away_team_id'] as String,
                stats: _stats,
                saving: _saving,
                onUpdate: _updateStat,
                onTapShots: _openShotBreakdown,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Scoreboard ───────────────────────────────────────────────────────────────

class _Scoreboard extends StatelessWidget {
  final String homeName;
  final String awayName;
  final int homeScore;
  final int awayScore;

  const _Scoreboard({required this.homeName, required this.awayName, required this.homeScore, required this.awayScore});

  @override
  Widget build(BuildContext context) {
    final homeWin = homeScore > awayScore;
    final awayWin = awayScore > homeScore;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(color: AppTheme.surfaceElevated, border: Border(bottom: BorderSide(color: AppTheme.divider))),
      child: Row(
        children: [
          Expanded(child: Text(homeName, textAlign: TextAlign.center, style: TextStyle(color: homeWin ? AppTheme.textPrimary : AppTheme.textSecondary, fontSize: 14, fontWeight: homeWin ? FontWeight.w700 : FontWeight.w500))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(12)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text('$homeScore', style: TextStyle(color: homeWin ? AppTheme.primary : AppTheme.textPrimary, fontSize: 32, fontWeight: FontWeight.w900)),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text('—', style: TextStyle(color: AppTheme.textSecondary, fontSize: 20))),
              Text('$awayScore', style: TextStyle(color: awayWin ? AppTheme.primary : AppTheme.textPrimary, fontSize: 32, fontWeight: FontWeight.w900)),
            ]),
          ),
          Expanded(child: Text(awayName, textAlign: TextAlign.center, style: TextStyle(color: awayWin ? AppTheme.textPrimary : AppTheme.textSecondary, fontSize: 14, fontWeight: awayWin ? FontWeight.w700 : FontWeight.w500))),
        ],
      ),
    );
  }
}

// ─── Match title in AppBar ────────────────────────────────────────────────────

class _MatchTitle extends StatelessWidget {
  final Map<String, dynamic> match;
  const _MatchTitle({required this.match});

  @override
  Widget build(BuildContext context) {
    final home = (match['home_team'] as Map)['name'] as String;
    final away = (match['away_team'] as Map)['name'] as String;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('$home vs $away', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
      Text('Fecha ${match['round']}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
    ]);
  }
}

// ─── Match list ───────────────────────────────────────────────────────────────

class _MatchList extends StatelessWidget {
  final List<Map<String, dynamic>> matches;
  final void Function(Map<String, dynamic>) onSelect;

  const _MatchList({required this.matches, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.sports_basketball, color: AppTheme.textSecondary, size: 48),
        SizedBox(height: 12),
        Text('No hay partidos programados', style: TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
      ]));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: matches.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final m = matches[i];
        final home = (m['home_team'] as Map)['name'] as String;
        final away = (m['away_team'] as Map)['name'] as String;
        return GestureDetector(
          onTap: () => onSelect(m),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppTheme.surfaceElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2))),
            child: Row(children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: AppTheme.primaryDim, borderRadius: BorderRadius.circular(8)), child: Text('F${m['round']}', style: const TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w800))),
              const SizedBox(width: 14),
              Expanded(child: Text('$home  vs  $away', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600))),
              const Icon(Icons.sports_score_rounded, color: AppTheme.primary, size: 20),
            ]),
          ),
        );
      },
    );
  }
}

// ─── Player list ──────────────────────────────────────────────────────────────

class _PlayerList extends StatelessWidget {
  final List<Map<String, dynamic>> players;
  final String teamId;
  final Map<String, Map<String, int>> stats;
  final Set<String> saving;
  final Future<void> Function(String, String, String, int) onUpdate;
  final void Function(Map<String, dynamic>, String) onTapShots;

  const _PlayerList({
    required this.players,
    required this.teamId,
    required this.stats,
    required this.saving,
    required this.onUpdate,
    required this.onTapShots,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: players.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: AppTheme.divider),
      itemBuilder: (_, i) => _PlayerRow(
        player: players[i],
        teamId: teamId,
        stats: stats[players[i]['id'] as String] ?? {'pts': 0, 'ast': 0, 'reb': 0, 'fal': 0, 'd2c': 0, 'd2i': 0, 'd3c': 0, 'd3i': 0, 'tlc': 0, 'tli': 0},
        isSaving: saving.contains(players[i]['id'] as String),
        onUpdate: onUpdate,
        onTapShots: onTapShots,
      ),
    );
  }
}

// ─── Player row ───────────────────────────────────────────────────────────────

class _PlayerRow extends StatelessWidget {
  final Map<String, dynamic> player;
  final String teamId;
  final Map<String, int> stats;
  final bool isSaving;
  final Future<void> Function(String, String, String, int) onUpdate;
  final void Function(Map<String, dynamic>, String) onTapShots;

  const _PlayerRow({
    required this.player,
    required this.teamId,
    required this.stats,
    required this.isSaving,
    required this.onUpdate,
    required this.onTapShots,
  });

  @override
  Widget build(BuildContext context) {
    final pid = player['id'] as String;
    final hasShotData = (stats['d2i']! + stats['d3i']! + stats['tli']!) > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header row
        Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: AppTheme.primaryDim, borderRadius: BorderRadius.circular(10)),
            child: Center(child: Text('#${player['number']}', style: const TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w800))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () => onTapShots(player, teamId),
              child: Row(children: [
                Text('${player['first_name']} ${player['last_name']}', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: hasShotData ? AppTheme.primaryDim : AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: hasShotData ? AppTheme.primary.withValues(alpha: 0.4) : AppTheme.divider),
                  ),
                  child: Text(
                    hasShotData
                        ? '${stats['d2c']}/${stats['d2i']} · ${stats['d3c']}/${stats['d3i']} · ${stats['tlc']}/${stats['tli']}'
                        : '+ tiros',
                    style: TextStyle(color: hasShotData ? AppTheme.primary : AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                ),
              ]),
            ),
          ),
          if (isSaving)
            const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary)),
        ]),
        const SizedBox(height: 12),
        // Stat counters
        Row(children: [
          _StatCounter(label: 'PTS', value: stats['pts']!, color: const Color(0xFF2ECC71), onTap: (d) => onUpdate(pid, teamId, 'pts', d)),
          const SizedBox(width: 8),
          _StatCounter(label: 'AST', value: stats['ast']!, color: const Color(0xFF3498DB), onTap: (d) => onUpdate(pid, teamId, 'ast', d)),
          const SizedBox(width: 8),
          _StatCounter(label: 'REB', value: stats['reb']!, color: const Color(0xFFF39C12), onTap: (d) => onUpdate(pid, teamId, 'reb', d)),
          const SizedBox(width: 8),
          _StatCounter(label: 'FAL', value: stats['fal']!, color: const Color(0xFFE74C3C), onTap: (d) => onUpdate(pid, teamId, 'fal', d)),
        ]),
      ]),
    );
  }
}

// ─── Shot breakdown bottom sheet ──────────────────────────────────────────────

class _ShotBreakdownSheet extends StatefulWidget {
  final Map<String, dynamic> player;
  final Map<String, int> initialStats;
  final void Function(Map<String, int>) onApply;

  const _ShotBreakdownSheet({required this.player, required this.initialStats, required this.onApply});

  @override
  State<_ShotBreakdownSheet> createState() => _ShotBreakdownSheetState();
}

class _ShotBreakdownSheetState extends State<_ShotBreakdownSheet> {
  late Map<String, int> _shots;

  @override
  void initState() {
    super.initState();
    _shots = Map<String, int>.from(widget.initialStats);
  }

  int get _calcPts => _shots['d2c']! * 2 + _shots['d3c']! * 3 + _shots['tlc']!;

  void _change(String key, int delta, {String? linkedMin}) {
    setState(() {
      _shots[key] = (_shots[key]! + delta).clamp(0, 99);
      // conv can't exceed attempted
      if (key == 'd2c' && _shots['d2c']! > _shots['d2i']!) _shots['d2i'] = _shots['d2c'];
      if (key == 'd3c' && _shots['d3c']! > _shots['d3i']!) _shots['d3i'] = _shots['d3c'];
      if (key == 'tlc' && _shots['tlc']! > _shots['tli']!) _shots['tli'] = _shots['tlc'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle
        Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12), decoration: BoxDecoration(color: AppTheme.divider, borderRadius: BorderRadius.circular(2))),
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Row(children: [
            Container(width: 36, height: 36, decoration: BoxDecoration(color: AppTheme.primaryDim, borderRadius: BorderRadius.circular(10)), child: Center(child: Text('#${widget.player['number']}', style: const TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w800)))),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${widget.player['first_name']} ${widget.player['last_name']}', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
              const Text('Desglose de tiros', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            ]),
          ]),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            _ShotRow(label: 'Dobles', sub: 'Tiros de 2 puntos', color: const Color(0xFF2ECC71), convVal: _shots['d2c']!, intVal: _shots['d2i']!, onConv: (d) => _change('d2c', d), onInt: (d) => _change('d2i', d)),
            const SizedBox(height: 10),
            _ShotRow(label: 'Triples', sub: 'Tiros de 3 puntos', color: const Color(0xFF9B59B6), convVal: _shots['d3c']!, intVal: _shots['d3i']!, onConv: (d) => _change('d3c', d), onInt: (d) => _change('d3i', d)),
            const SizedBox(height: 10),
            _ShotRow(label: 'Tiros Libres', sub: '1 punto cada uno', color: const Color(0xFF3498DB), convVal: _shots['tlc']!, intVal: _shots['tli']!, onConv: (d) => _change('tlc', d), onInt: (d) => _change('tli', d)),
            const SizedBox(height: 12),
            // PTS calculados
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: AppTheme.primaryDim, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3))),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Puntos calculados', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                  Text('${_shots['d2c']}×2 + ${_shots['d3c']}×3 + ${_shots['tlc']}×1', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                ])),
                Text('$_calcPts', style: const TextStyle(color: AppTheme.primary, fontSize: 32, fontWeight: FontWeight.w900)),
              ]),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () { Navigator.pop(context); widget.onApply(_shots); },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: const Text('Aplicar al marcador', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ─── Shot row ─────────────────────────────────────────────────────────────────

class _ShotRow extends StatelessWidget {
  final String label;
  final String sub;
  final Color color;
  final int convVal;
  final int intVal;
  final void Function(int) onConv;
  final void Function(int) onInt;

  const _ShotRow({required this.label, required this.sub, required this.color, required this.convVal, required this.intVal, required this.onConv, required this.onInt});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: AppTheme.surfaceElevated, borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
          Text(sub, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
        ])),
        _ShotCounter(label: 'CONV', value: convVal, color: color, onTap: onConv),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text('/', style: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.5), fontSize: 20))),
        _ShotCounter(label: 'INT', value: intVal, color: AppTheme.textSecondary, onTap: onInt),
      ]),
    );
  }
}

class _ShotCounter extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final void Function(int) onTap;

  const _ShotCounter({required this.label, required this.value, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
      const SizedBox(height: 4),
      Row(children: [
        _SBtn(color: color, icon: Icons.remove_rounded, onTap: () => onTap(-1)),
        const SizedBox(width: 6),
        SizedBox(width: 28, child: Text('$value', textAlign: TextAlign.center, style: TextStyle(color: color == AppTheme.textSecondary ? AppTheme.textPrimary : color, fontSize: 20, fontWeight: FontWeight.w900))),
        const SizedBox(width: 6),
        _SBtn(color: color, icon: Icons.add_rounded, onTap: () => onTap(1)),
      ]),
    ]);
  }
}

class _SBtn extends StatelessWidget {
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  const _SBtn({required this.color, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30, height: 30,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }
}

// ─── Stat counter widget ──────────────────────────────────────────────────────

class _StatCounter extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final void Function(int delta) onTap;

  const _StatCounter({required this.label, required this.value, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(color: AppTheme.surfaceElevated, borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withValues(alpha: 0.25))),
        child: Column(children: [
          Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
          const SizedBox(height: 6),
          Text('$value', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 26, fontWeight: FontWeight.w800, height: 1)),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _Btn(icon: Icons.remove_rounded, color: color, onTap: () => onTap(-1)),
            const SizedBox(width: 8),
            _Btn(icon: Icons.add_rounded, color: color, onTap: () => onTap(1)),
          ]),
        ]),
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _Btn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}
