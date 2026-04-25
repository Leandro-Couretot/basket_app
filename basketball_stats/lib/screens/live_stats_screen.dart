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

  // quarter (1-4) → playerId → stat map
  final Map<int, Map<String, Map<String, int>>> _quarterStats = {1: {}, 2: {}, 3: {}, 4: {}};
  int _currentQuarter = 1;

  bool _loadingMatches = true;
  bool _loadingPlayers = false;

  Map<String, int> _emptyStats() => {
    'pts': 0, 'ast': 0, 'reb': 0, 'fal': 0,
    'd2c': 0, 'd2i': 0, 'd3c': 0, 'd3i': 0, 'tlc': 0, 'tli': 0,
  };

  Map<String, int> _statsFor(String playerId) =>
      _quarterStats[_currentQuarter]![playerId] ?? _emptyStats();

  // Cumulative score (sum of all quarters)
  int _teamScore(List<Map<String, dynamic>> players) => players.fold(0, (s, p) {
    final pid = p['id'] as String;
    return s + _quarterStats.values.fold(0, (qs, q) => qs + (q[pid]?['pts'] ?? 0));
  });

  int get _homeScore => _teamScore(_playersHome);
  int get _awayScore => _teamScore(_playersAway);

  // Score for a specific quarter
  int _qScore(int quarter, List<Map<String, dynamic>> players) => players.fold(0, (s, p) {
    final pid = p['id'] as String;
    return s + (_quarterStats[quarter]?[pid]?['pts'] ?? 0);
  });

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
    setState(() {
      _selectedMatch = match;
      _loadingPlayers = true;
      _currentQuarter = 1;
      for (final q in _quarterStats.values) q.clear();
    });

    final client = Supabase.instance.client;
    final homeId = match['home_team_id'] as String;
    final awayId = match['away_team_id'] as String;

    final homePlayers = await client.from('players').select('id, first_name, last_name, number').eq('team_id', homeId).order('number');
    final awayPlayers = await client.from('players').select('id, first_name, last_name, number').eq('team_id', awayId).order('number');

    // Pre-populate empty stats for all players in Q1
    for (final p in [...homePlayers, ...awayPlayers]) {
      _quarterStats[1]![p['id'] as String] = _emptyStats();
    }

    setState(() {
      _playersHome = List<Map<String, dynamic>>.from(homePlayers);
      _playersAway = List<Map<String, dynamic>>.from(awayPlayers);
      _loadingPlayers = false;
    });
  }

  void _updateStat(String playerId, String stat, int delta) {
    final q = _quarterStats[_currentQuarter]!;
    q.putIfAbsent(playerId, _emptyStats);
    final current = q[playerId]![stat]!;
    final next = (current + delta).clamp(0, 99);
    if (next == current) return;
    setState(() => q[playerId]![stat] = next);
  }

  void _applyShotStats(String playerId, Map<String, int> shots) {
    final q = _quarterStats[_currentQuarter]!;
    q.putIfAbsent(playerId, _emptyStats);
    setState(() {
      final s = q[playerId]!;
      s['pts'] = shots['d2c']! * 2 + shots['d3c']! * 3 + shots['tlc']!;
      s['d2c'] = shots['d2c']!;
      s['d2i'] = shots['d2i']!;
      s['d3c'] = shots['d3c']!;
      s['d3i'] = shots['d3i']!;
      s['tlc'] = shots['tlc']!;
      s['tli'] = shots['tli']!;
    });
  }

  void _openShotBreakdown(String playerId, String playerName, int playerNumber) {
    final current = Map<String, int>.from(_statsFor(playerId));
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _ShotBreakdownSheet(
        playerName: playerName,
        playerNumber: playerNumber,
        quarter: _currentQuarter,
        initialShots: current,
        onApply: (shots) => _applyShotStats(playerId, shots),
      ),
    );
  }

  void _switchQuarter(int q) {
    // Pre-populate new quarter with empty stats if needed
    for (final p in [..._playersHome, ..._playersAway]) {
      _quarterStats[q]!.putIfAbsent(p['id'] as String, _emptyStats);
    }
    setState(() => _currentQuarter = q);
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
                  for (final q in _quarterStats.values) q.clear();
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

    final homeName = (_selectedMatch!['home_team'] as Map<String, dynamic>)['name'] as String;
    final awayName = (_selectedMatch!['away_team'] as Map<String, dynamic>)['name'] as String;

    return Column(
      children: [
        _Scoreboard(
          homeName: homeName,
          awayName: awayName,
          homeScore: _homeScore,
          awayScore: _awayScore,
          quarterScores: List.generate(4, (i) => (
            home: _qScore(i + 1, _playersHome),
            away: _qScore(i + 1, _playersAway),
          )),
        ),
        _QuarterSelector(
          current: _currentQuarter,
          onSelect: _switchQuarter,
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
                statsFor: _statsFor,
                onUpdate: (pid, stat, d) => _updateStat(pid, stat, d),
                onTapShots: _openShotBreakdown,
              ),
              _PlayerList(
                players: _playersAway,
                statsFor: _statsFor,
                onUpdate: (pid, stat, d) => _updateStat(pid, stat, d),
                onTapShots: _openShotBreakdown,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Quarter selector ─────────────────────────────────────────────────────────

class _QuarterSelector extends StatelessWidget {
  final int current;
  final ValueChanged<int> onSelect;

  const _QuarterSelector({required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppTheme.surface,
      child: Row(
        children: [
          const Text('CUARTO',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
          const SizedBox(width: 12),
          ...List.generate(4, (i) {
            final q = i + 1;
            final isSelected = current == q;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => onSelect(q),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primary : AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? AppTheme.primary : AppTheme.divider,
                    ),
                  ),
                  child: Text(
                    'Q$q',
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Scoreboard ───────────────────────────────────────────────────────────────

class _Scoreboard extends StatelessWidget {
  final String homeName;
  final String awayName;
  final int homeScore;
  final int awayScore;
  final List<({int home, int away})> quarterScores;

  const _Scoreboard({
    required this.homeName,
    required this.awayName,
    required this.homeScore,
    required this.awayScore,
    required this.quarterScores,
  });

  @override
  Widget build(BuildContext context) {
    final homeWin = homeScore > awayScore;
    final awayWin = awayScore > homeScore;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceElevated,
        border: Border(bottom: BorderSide(color: AppTheme.divider)),
      ),
      child: Column(
        children: [
          // Main score
          Row(
            children: [
              Expanded(
                child: Text(homeName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: homeWin ? AppTheme.textPrimary : AppTheme.textSecondary,
                      fontSize: 14,
                      fontWeight: homeWin ? FontWeight.w700 : FontWeight.w500,
                    )),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$homeScore',
                        style: TextStyle(
                            color: homeWin ? AppTheme.primary : AppTheme.textPrimary,
                            fontSize: 30, fontWeight: FontWeight.w900)),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text('—', style: TextStyle(color: AppTheme.textSecondary, fontSize: 18)),
                    ),
                    Text('$awayScore',
                        style: TextStyle(
                            color: awayWin ? AppTheme.primary : AppTheme.textPrimary,
                            fontSize: 30, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
              Expanded(
                child: Text(awayName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: awayWin ? AppTheme.textPrimary : AppTheme.textSecondary,
                      fontSize: 14,
                      fontWeight: awayWin ? FontWeight.w700 : FontWeight.w500,
                    )),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Per-quarter breakdown
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) {
              final qs = quarterScores[i];
              final hasData = qs.home > 0 || qs.away > 0;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  children: [
                    Text('Q${i + 1}',
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 9, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(
                      hasData ? '${qs.home}-${qs.away}' : '—',
                      style: TextStyle(
                          color: hasData ? AppTheme.textPrimary : AppTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: hasData ? FontWeight.w700 : FontWeight.w400),
                    ),
                  ],
                ),
              );
            }),
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
    final home = (match['home_team'] as Map<String, dynamic>)['name'] as String;
    final away = (match['away_team'] as Map<String, dynamic>)['name'] as String;
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
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final m = matches[i];
        final home = (m['home_team'] as Map<String, dynamic>)['name'] as String;
        final away = (m['away_team'] as Map<String, dynamic>)['name'] as String;
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
                  child: Text('F${m['round']}',
                      style: const TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text('$home  vs  $away',
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
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

// ─── Player list ──────────────────────────────────────────────────────────────

class _PlayerList extends StatelessWidget {
  final List<Map<String, dynamic>> players;
  final Map<String, int> Function(String) statsFor;
  final void Function(String, String, int) onUpdate;
  final void Function(String, String, int) onTapShots;

  const _PlayerList({
    required this.players,
    required this.statsFor,
    required this.onUpdate,
    required this.onTapShots,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: players.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: AppTheme.divider),
      itemBuilder: (_, i) {
        final p = players[i];
        final pid = p['id'] as String;
        return _PlayerRow(
          player: p,
          stats: statsFor(pid),
          onUpdate: (stat, d) => onUpdate(pid, stat, d),
          onTapShots: () => onTapShots(
            pid,
            '${p['first_name']} ${p['last_name']}',
            (p['number'] as int?) ?? 0,
          ),
        );
      },
    );
  }
}

// ─── Single player row ────────────────────────────────────────────────────────

class _PlayerRow extends StatelessWidget {
  final Map<String, dynamic> player;
  final Map<String, int> stats;
  final void Function(String stat, int delta) onUpdate;
  final VoidCallback onTapShots;

  const _PlayerRow({
    required this.player,
    required this.stats,
    required this.onUpdate,
    required this.onTapShots,
  });

  @override
  Widget build(BuildContext context) {
    final firstName = player['first_name'] as String;
    final lastName = player['last_name'] as String;
    final number = (player['number'] as int?) ?? 0;

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
                child: Center(child: Text('#$number',
                    style: const TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w800))),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text('$firstName $lastName',
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
              ),
              IconButton(
                icon: const Icon(Icons.sports_basketball, size: 18),
                color: AppTheme.primary,
                tooltip: 'Desglose de tiros',
                onPressed: onTapShots,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatCounter(label: 'PTS', value: stats['pts']!, color: const Color(0xFF2ECC71),
                  onTap: (d) => onUpdate('pts', d), readOnly: true),
              const SizedBox(width: 8),
              _StatCounter(label: 'AST', value: stats['ast']!, color: const Color(0xFF3498DB),
                  onTap: (d) => onUpdate('ast', d)),
              const SizedBox(width: 8),
              _StatCounter(label: 'REB', value: stats['reb']!, color: const Color(0xFFF39C12),
                  onTap: (d) => onUpdate('reb', d)),
              const SizedBox(width: 8),
              _StatCounter(label: 'FAL', value: stats['fal']!, color: const Color(0xFFE74C3C),
                  onTap: (d) => onUpdate('fal', d)),
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
  final bool readOnly;

  const _StatCounter({required this.label, required this.value, required this.color, required this.onTap, this.readOnly = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: readOnly ? 0.12 : 0.25)),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(color: readOnly ? color.withValues(alpha: 0.5) : color, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
            const SizedBox(height: 6),
            Text('$value', style: TextStyle(color: readOnly ? AppTheme.textSecondary : AppTheme.textPrimary, fontSize: 26, fontWeight: FontWeight.w800, height: 1)),
            const SizedBox(height: 8),
            if (readOnly)
              const Icon(Icons.sports_basketball, size: 14, color: AppTheme.textSecondary)
            else
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
        width: 36, height: 36,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}

// ─── Shot breakdown bottom sheet ─────────────────────────────────────────────

class _ShotBreakdownSheet extends StatefulWidget {
  final String playerName;
  final int playerNumber;
  final int quarter;
  final Map<String, int> initialShots;
  final void Function(Map<String, int>) onApply;

  const _ShotBreakdownSheet({
    required this.playerName,
    required this.playerNumber,
    required this.quarter,
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
      final next = (_shots[key]! + delta).clamp(0, 99);
      _shots[key] = next;
      if (key == 'd2c') _shots['d2i'] = next;
      if (key == 'd3c') _shots['d3i'] = next;
      if (key == 'tlc') _shots['tli'] = next;
      if (key == 'd2i' && next < (_shots['d2c'] ?? 0)) _shots['d2c'] = next;
      if (key == 'd3i' && next < (_shots['d3c'] ?? 0)) _shots['d3c'] = next;
      if (key == 'tli' && next < (_shots['tlc'] ?? 0)) _shots['tlc'] = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(color: AppTheme.divider, borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: AppTheme.primaryDim, borderRadius: BorderRadius.circular(10)),
                  child: Center(child: Text('#${widget.playerNumber}',
                      style: const TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w800))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.playerName,
                          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                      Text('Tiros — Q${widget.quarter}',
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              children: [
                _ShotRow(label: 'Dobles', sublabel: 'Tiros de 2 puntos', color: const Color(0xFF2ECC71),
                    convValue: _shots['d2c']!, intValue: _shots['d2i']!,
                    onConvChange: (d) => _change('d2c', d), onIntChange: (d) => _change('d2i', d)),
                const SizedBox(height: 12),
                _ShotRow(label: 'Triples', sublabel: 'Tiros de 3 puntos', color: const Color(0xFF9B59B6),
                    convValue: _shots['d3c']!, intValue: _shots['d3i']!,
                    onConvChange: (d) => _change('d3c', d), onIntChange: (d) => _change('d3i', d)),
                const SizedBox(height: 12),
                _ShotRow(label: 'Tiros Libres', sublabel: '1 punto cada uno', color: const Color(0xFF3498DB),
                    convValue: _shots['tlc']!, intValue: _shots['tli']!,
                    onConvChange: (d) => _change('tlc', d), onIntChange: (d) => _change('tli', d)),
                const SizedBox(height: 16),
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
                            const Text('Puntos calculados',
                                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text('${_shots['d2c']}×2 + ${_shots['d3c']}×3 + ${_shots['tlc']}×1',
                                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                          ],
                        ),
                      ),
                      Text('$_calcPts',
                          style: const TextStyle(color: AppTheme.primary, fontSize: 28, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
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

// ─── Shot row ─────────────────────────────────────────────────────────────────

class _ShotRow extends StatelessWidget {
  final String label, sublabel;
  final Color color;
  final int convValue, intValue;
  final void Function(int) onConvChange, onIntChange;

  const _ShotRow({
    required this.label, required this.sublabel, required this.color,
    required this.convValue, required this.intValue,
    required this.onConvChange, required this.onIntChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: AppTheme.surfaceElevated, borderRadius: BorderRadius.circular(16)),
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

  const _ShotCounter({required this.label, required this.value, required this.color, required this.onChange});

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
            SizedBox(width: 28,
                child: Text('$value', textAlign: TextAlign.center,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w900))),
            const SizedBox(width: 6),
            _Btn(icon: Icons.add_rounded, color: color, onTap: () => onChange(1)),
          ],
        ),
      ],
    );
  }
}
