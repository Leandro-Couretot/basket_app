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

  // playerId -> { 'pts':0, 'ast':0, 'reb':0, 'fal':0, 'd2c':0,'d2i':0,'d3c':0,'d3i':0,'tlc':0,'tli':0 }
  final Map<String, Map<String, int>> _stats = {};
  final Set<String> _saving = {};

  bool _loadingMatches = true;
  bool _loadingPlayers = false;

  int get _homeScore => _playersHome.fold(0, (int s, Map<String, dynamic> p) => s + (_stats[p['id'] as String]?['pts'] ?? 0));
  int get _awayScore  => _playersAway.fold(0, (int s, Map<String, dynamic> p) => s + (_stats[p['id'] as String]?['pts'] ?? 0));

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
      final pid = p['id'] as String;
      _stats[pid] = { 'pts': 0, 'ast': 0, 'reb': 0, 'fal': 0, 'd2c': 0, 'd2i': 0, 'd3c': 0, 'd3i': 0, 'tlc': 0, 'tli': 0 };
    }
    for (final row in existingStats) {
      final pid = row['player_id'] as String;
      if (_stats.containsKey(pid)) {
        _stats[pid] = {
          'pts': (row['points']   as int?) ?? 0,
          'ast': (row['assists']  as int?) ?? 0,
          'reb': (row['rebounds'] as int?) ?? 0,
          'fal': (row['fouls']    as int?) ?? 0,
          'd2c': (row['two_pt_made']        as int?) ?? 0,
          'd2i': (row['two_pt_attempted']   as int?) ?? 0,
          'd3c': (row['three_pt_made']      as int?) ?? 0,
          'd3i': (row['three_pt_attempted'] as int?) ?? 0,
          'tlc': (row['ft_made']            as int?) ?? 0,
          'tli': (row['ft_attempted']       as int?) ?? 0,
        };
      }
    }

    setState(() {
      _playersHome = List<Map<String, dynamic>>.from(homePlayers);
      _playersAway = List<Map<String, dynamic>>.from(awayPlayers);
      _loadingPlayers = false;
    });
  }

  Future<void> _updateStat(String playerId, String teamId, String stat, int delta) async {
    final int current = _stats[playerId]![stat]!;
    final int next = (current + delta).clamp(0, 99);
    if (next == current) return;

    setState(() => _stats[playerId]![stat] = next);

    final String matchId = _selectedMatch!['id'] as String;
    setState(() => _saving.add(playerId));
    try {
      final client = Supabase.instance.client;
      final Map<String, int> s = _stats[playerId]!;
      await client.from('player_match_stats').upsert({
        'match_id': matchId,
        'player_id': playerId,
        'team_id': teamId,
        'points':   s['pts'],
        'assists':  s['ast'],
        'rebounds': s['reb'],
        'fouls':    s['fal'],
      }, onConflict: 'match_id,player_id');
      if (stat == 'pts') {
        await client.from('matches').update({
          'home_score': _homeScore,
          'away_score': _awayScore,
          'status': 'in_progress',
        }).eq('id', matchId);
      }
    } finally {
      if (mounted) setState(() => _saving.remove(playerId));
    }
  }

  Future<void> _applyShotStats(String playerId, String teamId, Map<String, int> shots) async {
    final int d2c = shots['d2c']!;
    final int d3c = shots['d3c']!;
    final int tlc = shots['tlc']!;
    final int pts = d2c * 2 + d3c * 3 + tlc;

    setState(() {
      final Map<String, int> s = _stats[playerId]!;
      s['pts'] = pts;
      s['d2c'] = shots['d2c']!;
      s['d2i'] = shots['d2i']!;
      s['d3c'] = shots['d3c']!;
      s['d3i'] = shots['d3i']!;
      s['tlc'] = shots['tlc']!;
      s['tli'] = shots['tli']!;
    });

    final String matchId = _selectedMatch!['id'] as String;
    setState(() => _saving.add(playerId));
    try {
      final client = Supabase.instance.client;
      final Map<String, int> s = _stats[playerId]!;
      await client.from('player_match_stats').upsert({
        'match_id': matchId,
        'player_id': playerId,
        'team_id': teamId,
        'points':   s['pts'],
        'assists':  s['ast'],
        'rebounds': s['reb'],
        'fouls':    s['fal'],
        'two_pt_made':        s['d2c'],
        'two_pt_attempted':   s['d2i'],
        'three_pt_made':      s['d3c'],
        'three_pt_attempted': s['d3i'],
        'ft_made':            s['tlc'],
        'ft_attempted':       s['tli'],
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

  void _openShotBreakdown(String playerId, String teamId, String playerName, int playerNumber) {
    final Map<String, int> currentShots = {
      'd2c': _stats[playerId]!['d2c']!,
      'd2i': _stats[playerId]!['d2i']!,
      'd3c': _stats[playerId]!['d3c']!,
      'd3i': _stats[playerId]!['d3i']!,
      'tlc': _stats[playerId]!['tlc']!,
      'tli': _stats[playerId]!['tli']!,
    };
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext ctx) => _ShotBreakdownSheet(
        playerName: playerName,
        playerNumber: playerNumber,
        initialShots: currentShots,
        onApply: (Map<String, int> shots) => _applyShotStats(playerId, teamId, shots),
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
        bottom: null,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loadingMatches) return const Center(child: CircularProgressIndicator(color: AppTheme.primary));

    if (_selectedMatch == null) return _MatchList(matches: _matches, onSelect: _selectMatch);

    if (_loadingPlayers) return const Center(child: CircularProgressIndicator(color: AppTheme.primary));

    final String homeName = (_selectedMatch!['home_team'] as Map<String, dynamic>)['name'] as String;
    final String awayName = (_selectedMatch!['away_team'] as Map<String, dynamic>)['name'] as String;

    return Column(
      children: [
        _Scoreboard(
          homeName: homeName,
          awayName: awayName,
          homeScore: _homeScore,
          awayScore: _awayScore,
        ),
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

  const _Scoreboard({
    required this.homeName,
    required this.awayName,
    required this.homeScore,
    required this.awayScore,
  });

  @override
  Widget build(BuildContext context) {
    final bool homeWin = homeScore > awayScore;
    final bool awayWin = awayScore > homeScore;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        border: Border(bottom: BorderSide(color: AppTheme.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              homeName,
              style: TextStyle(
                color: homeWin ? AppTheme.textPrimary : AppTheme.textSecondary,
                fontSize: 14,
                fontWeight: homeWin ? FontWeight.w700 : FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$homeScore',
                  style: TextStyle(
                    color: homeWin ? AppTheme.primary : AppTheme.textPrimary,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text('—', style: TextStyle(color: AppTheme.textSecondary, fontSize: 20)),
                ),
                Text(
                  '$awayScore',
                  style: TextStyle(
                    color: awayWin ? AppTheme.primary : AppTheme.textPrimary,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              awayName,
              style: TextStyle(
                color: awayWin ? AppTheme.textPrimary : AppTheme.textSecondary,
                fontSize: 14,
                fontWeight: awayWin ? FontWeight.w700 : FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
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
    final String home = (match['home_team'] as Map<String, dynamic>)['name'] as String;
    final String away = (match['away_team'] as Map<String, dynamic>)['name'] as String;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$home vs $away', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        Text('Fecha ${match['round']}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
      ],
    );
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
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sports_basketball, color: AppTheme.textSecondary, size: 48),
            SizedBox(height: 12),
            Text('No hay partidos programados', style: TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: matches.length,
      separatorBuilder: (BuildContext _, int __) => const SizedBox(height: 10),
      itemBuilder: (BuildContext _, int i) {
        final Map<String, dynamic> m = matches[i];
        final String home = (m['home_team'] as Map<String, dynamic>)['name'] as String;
        final String away = (m['away_team'] as Map<String, dynamic>)['name'] as String;
        return GestureDetector(
          onTap: () => onSelect(m),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: AppTheme.primaryDim, borderRadius: BorderRadius.circular(8)),
                  child: Text('F${m['round']}', style: const TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text('$home  vs  $away', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                ),
                const Icon(Icons.sports_score_rounded, color: AppTheme.primary, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Player list with stat counters ──────────────────────────────────────────

class _PlayerList extends StatelessWidget {
  final List<Map<String, dynamic>> players;
  final String teamId;
  final Map<String, Map<String, int>> stats;
  final Set<String> saving;
  final Future<void> Function(String, String, String, int) onUpdate;
  final void Function(String, String, String, int) onTapShots;

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
      separatorBuilder: (BuildContext _, int __) => const Divider(height: 1, color: AppTheme.divider),
      itemBuilder: (BuildContext _, int i) {
        final Map<String, dynamic> p = players[i];
        final String pid = p['id'] as String;
        return _PlayerRow(
          player: p,
          teamId: teamId,
          stats: stats[pid] ?? {'pts': 0, 'ast': 0, 'reb': 0, 'fal': 0, 'd2c': 0, 'd2i': 0, 'd3c': 0, 'd3i': 0, 'tlc': 0, 'tli': 0},
          isSaving: saving.contains(pid),
          onUpdate: onUpdate,
          onTapShots: onTapShots,
        );
      },
    );
  }
}

// ─── Single player row ────────────────────────────────────────────────────────

class _PlayerRow extends StatelessWidget {
  final Map<String, dynamic> player;
  final String teamId;
  final Map<String, int> stats;
  final bool isSaving;
  final Future<void> Function(String, String, String, int) onUpdate;
  final void Function(String, String, String, int) onTapShots;

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
    final String pid = player['id'] as String;
    final String firstName = player['first_name'] as String;
    final String lastName = player['last_name'] as String;
    final int number = (player['number'] as int?) ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: AppTheme.primaryDim, borderRadius: BorderRadius.circular(10)),
                child: Center(child: Text('#$number', style: const TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w800))),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$firstName $lastName',
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.sports_basketball, size: 18),
                color: AppTheme.primary,
                tooltip: 'Desglose de tiros',
                onPressed: () => onTapShots(pid, teamId, '$firstName $lastName', number),
              ),
              if (isSaving)
                const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatCounter(label: 'PTS', value: stats['pts']!, color: const Color(0xFF2ECC71), onTap: (int d) => onUpdate(pid, teamId, 'pts', d)),
              const SizedBox(width: 8),
              _StatCounter(label: 'AST', value: stats['ast']!, color: const Color(0xFF3498DB), onTap: (int d) => onUpdate(pid, teamId, 'ast', d)),
              const SizedBox(width: 8),
              _StatCounter(label: 'REB', value: stats['reb']!, color: const Color(0xFFF39C12), onTap: (int d) => onUpdate(pid, teamId, 'reb', d)),
              const SizedBox(width: 8),
              _StatCounter(label: 'FAL', value: stats['fal']!, color: const Color(0xFFE74C3C), onTap: (int d) => onUpdate(pid, teamId, 'fal', d)),
            ],
          ),
        ],
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
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
            const SizedBox(height: 6),
            Text('$value', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 26, fontWeight: FontWeight.w800, height: 1)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Btn(icon: Icons.remove_rounded, color: color, onTap: () => onTap(-1)),
                const SizedBox(width: 8),
                _Btn(icon: Icons.add_rounded, color: color, onTap: () => onTap(1)),
              ],
            ),
          ],
        ),
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
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}

// ─── Shot breakdown bottom sheet ─────────────────────────────────────────────

class _ShotBreakdownSheet extends StatefulWidget {
  final String playerName;
  final int playerNumber;
  final Map<String, int> initialShots;
  final void Function(Map<String, int>) onApply;

  const _ShotBreakdownSheet({
    required this.playerName,
    required this.playerNumber,
    required this.initialShots,
    required this.onApply,
  });

  @override
  State<_ShotBreakdownSheet> createState() => _ShotBreakdownSheetState();
}

class _ShotBreakdownSheetState extends State<_ShotBreakdownSheet> {
  late Map<String, int> _shots;

  @override
  void initState() {
    super.initState();
    _shots = Map<String, int>.from(widget.initialShots);
  }

  int get _calcPts => _shots['d2c']! * 2 + _shots['d3c']! * 3 + _shots['tlc']!;

  void _change(String key, int delta) {
    setState(() {
      final int next = (_shots[key]! + delta).clamp(0, 99);
      _shots[key] = next;
      if (key == 'd2c' && _shots['d2c']! > _shots['d2i']!) _shots['d2i'] = _shots['d2c'];
      if (key == 'd3c' && _shots['d3c']! > _shots['d3i']!) _shots['d3i'] = _shots['d3c'];
      if (key == 'tlc' && _shots['tlc']! > _shots['tli']!) _shots['tli'] = _shots['tlc'];
    });
  }

  @override
  Widget build(BuildContext context) {
    final int d2c = _shots['d2c']!;
    final int d2i = _shots['d2i']!;
    final int d3c = _shots['d3c']!;
    final int d3i = _shots['d3i']!;
    final int tlc = _shots['tlc']!;
    final int tli = _shots['tli']!;
    final int pts = _calcPts;

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(color: AppTheme.divider, borderRadius: BorderRadius.circular(2)),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: AppTheme.primaryDim, borderRadius: BorderRadius.circular(10)),
                  child: Center(child: Text('#${widget.playerNumber}', style: const TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w800))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.playerName, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                      const Text('Desglose de tiros', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  color: AppTheme.textSecondary,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.divider),
          // Body
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              children: [
                _ShotRow(
                  label: 'Dobles',
                  sublabel: 'Tiros de 2 puntos',
                  color: const Color(0xFF2ECC71),
                  convValue: d2c,
                  intValue: d2i,
                  onConvChange: (int d) => _change('d2c', d),
                  onIntChange:  (int d) => _change('d2i', d),
                ),
                const SizedBox(height: 12),
                _ShotRow(
                  label: 'Triples',
                  sublabel: 'Tiros de 3 puntos',
                  color: const Color(0xFF9B59B6),
                  convValue: d3c,
                  intValue: d3i,
                  onConvChange: (int d) => _change('d3c', d),
                  onIntChange:  (int d) => _change('d3i', d),
                ),
                const SizedBox(height: 12),
                _ShotRow(
                  label: 'Tiros Libres',
                  sublabel: '1 punto cada uno',
                  color: const Color(0xFF3498DB),
                  convValue: tlc,
                  intValue: tli,
                  onConvChange: (int d) => _change('tlc', d),
                  onIntChange:  (int d) => _change('tli', d),
                ),
                const SizedBox(height: 16),
                // Calculated PTS
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryDim,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Puntos calculados', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text('$d2c×2 + $d3c×3 + $tlc×1', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                          ],
                        ),
                      ),
                      Text('$pts', style: const TextStyle(color: AppTheme.primary, fontSize: 28, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Apply button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      widget.onApply(Map<String, int>.from(_shots));
                      Navigator.of(context).pop();
                    },
                    child: const Text('Aplicar al marcador', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shot row inside the breakdown sheet ─────────────────────────────────────

class _ShotRow extends StatelessWidget {
  final String label;
  final String sublabel;
  final Color color;
  final int convValue;
  final int intValue;
  final void Function(int) onConvChange;
  final void Function(int) onIntChange;

  const _ShotRow({
    required this.label,
    required this.sublabel,
    required this.color,
    required this.convValue,
    required this.intValue,
    required this.onConvChange,
    required this.onIntChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(sublabel, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          Row(
            children: [
              _ShotCounter(label: 'CONV', value: convValue, color: color, onChange: onConvChange),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('/', style: TextStyle(color: AppTheme.textSecondary, fontSize: 18, fontWeight: FontWeight.w300)),
              ),
              _ShotCounter(label: 'INT', value: intValue, color: AppTheme.textSecondary, onChange: onIntChange),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShotCounter extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final void Function(int) onChange;

  const _ShotCounter({
    required this.label,
    required this.value,
    required this.color,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Btn(icon: Icons.remove_rounded, color: color, onTap: () => onChange(-1)),
            const SizedBox(width: 6),
            SizedBox(
              width: 28,
              child: Text('$value', textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w900)),
            ),
            const SizedBox(width: 6),
            _Btn(icon: Icons.add_rounded, color: color, onTap: () => onChange(1)),
          ],
        ),
      ],
    );
  }
}
