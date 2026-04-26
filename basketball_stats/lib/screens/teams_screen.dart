import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';

const _teamColors = [
  Color(0xFF3498DB),
  Color(0xFF2ECC71),
  Color(0xFF9B59B6),
  Color(0xFFE74C3C),
  Color(0xFFF39C12),
  Color(0xFF1ABC9C),
];

class TeamsScreen extends StatefulWidget {
  final AppRole role;
  const TeamsScreen({super.key, required this.role});

  @override
  State<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends State<TeamsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  List<Map<String, dynamic>> _teams = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  Future<void> _loadTeams() async {
    final client = Supabase.instance.client;

    final teams = await client.from('teams').select('id, name, city').order('name');

    // Get player counts per team
    final players = await client.from('players').select('team_id');
    final playerCounts = <String, int>{};
    for (final p in players) {
      final id = p['team_id'] as String;
      playerCounts[id] = (playerCounts[id] ?? 0) + 1;
    }

    // Get wins/losses from finished matches
    final matches = await client
        .from('matches')
        .select('home_team_id, away_team_id, home_score, away_score')
        .eq('status', 'finished');

    final wl = <String, Map<String, int>>{};
    for (final m in matches) {
      final h = m['home_team_id'] as String;
      final a = m['away_team_id'] as String;
      wl.putIfAbsent(h, () => {'w': 0, 'l': 0});
      wl.putIfAbsent(a, () => {'w': 0, 'l': 0});
      if ((m['home_score'] as int) > (m['away_score'] as int)) {
        wl[h]!['w'] = wl[h]!['w']! + 1;
        wl[a]!['l'] = wl[a]!['l']! + 1;
      } else {
        wl[a]!['w'] = wl[a]!['w']! + 1;
        wl[h]!['l'] = wl[h]!['l']! + 1;
      }
    }

    final enriched = teams.asMap().entries.map((e) {
      final t = Map<String, dynamic>.from(e.value);
      t['players'] = playerCounts[t['id']] ?? 0;
      t['wins'] = wl[t['id']]?['w'] ?? 0;
      t['losses'] = wl[t['id']]?['l'] ?? 0;
      t['color'] = _teamColors[e.key % _teamColors.length];
      return t;
    }).toList();

    setState(() {
      _teams = enriched;
      _loading = false;
    });
  }

  List<Map<String, dynamic>> get _filtered {
    if (_query.isEmpty) return _teams;
    return _teams.where((t) => (t['name'] as String).toLowerCase().contains(_query.toLowerCase())).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Equipos')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : Column(
              children: [
                _SearchBar(
                  controller: _searchController,
                  onChanged: (q) => setState(() => _query = q),
                ),
                Expanded(
                  child: _filtered.isEmpty
                      ? const _EmptySearch()
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, i) => _TeamCard(team: _filtered[i]),
                        ),
                ),
              ],
            ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Buscar equipo...',
          hintStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textSecondary, size: 20),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary, size: 18),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                )
              : null,
          filled: true,
          fillColor: AppTheme.surfaceElevated,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }
}

class _TeamCard extends StatelessWidget {
  final Map<String, dynamic> team;

  const _TeamCard({required this.team});

  @override
  Widget build(BuildContext context) {
    final color = team['color'] as Color;
    final wins = team['wins'] as int;
    final losses = team['losses'] as int;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                (team['name'] as String).substring(0, 1).toUpperCase(),
                style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(team['name'] as String, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 2),
                Text('${team['players']} jugadores', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          if (wins + losses > 0) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Text('$wins', style: const TextStyle(color: AppTheme.success, fontWeight: FontWeight.w800, fontSize: 16)),
                    const Text(' – ', style: TextStyle(color: AppTheme.textSecondary)),
                    Text('$losses', style: const TextStyle(color: AppTheme.danger, fontWeight: FontWeight.w800, fontSize: 16)),
                  ],
                ),
                const Text('G – P', style: TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
              ],
            ),
          ] else
            const Text('Sin partidos', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
        ],
      ),
    );
  }
}

class _EmptySearch extends StatelessWidget {
  const _EmptySearch();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, color: AppTheme.textSecondary, size: 48),
          SizedBox(height: 12),
          Text('Sin resultados', style: TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
        ],
      ),
    );
  }
}
