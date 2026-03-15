import 'package:flutter/material.dart';
import '../main.dart';

class _MockTeam {
  final String name;
  final int players;
  final int wins;
  final int losses;
  final Color color;

  const _MockTeam({
    required this.name,
    required this.players,
    required this.wins,
    required this.losses,
    required this.color,
  });
}

class TeamsScreen extends StatefulWidget {
  const TeamsScreen({super.key});

  @override
  State<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends State<TeamsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  final List<_MockTeam> _teams = const [
    _MockTeam(name: 'Lugano 80', players: 10, wins: 4, losses: 1, color: Color(0xFF3498DB)),
    _MockTeam(name: 'Achaval City Básquet', players: 12, wins: 3, losses: 2, color: Color(0xFF2ECC71)),
    _MockTeam(name: 'Slow Motion', players: 9, wins: 2, losses: 2, color: Color(0xFF9B59B6)),
    _MockTeam(name: 'Super Ácidos', players: 11, wins: 1, losses: 4, color: Color(0xFFE74C3C)),
    _MockTeam(name: 'Los Pinos BC', players: 8, wins: 0, losses: 0, color: Color(0xFFF39C12)),
    _MockTeam(name: 'Barracas Norte', players: 10, wins: 0, losses: 0, color: Color(0xFF1ABC9C)),
  ];

  List<_MockTeam> get _filtered {
    if (_query.isEmpty) return _teams;
    return _teams.where((t) => t.name.toLowerCase().contains(_query.toLowerCase())).toList();
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
      body: Column(
        children: [
          _SearchBar(controller: _searchController, onChanged: (q) => setState(() => _query = q)),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nuevo equipo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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
  final _MockTeam team;

  const _TeamCard({required this.team});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: team.color, width: 3)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: team.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                team.name.substring(0, 1).toUpperCase(),
                style: TextStyle(color: team.color, fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(team.name, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 2),
                Text('${team.players} jugadores', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          if (team.wins + team.losses > 0) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Text('${team.wins}', style: const TextStyle(color: AppTheme.success, fontWeight: FontWeight.w800, fontSize: 16)),
                    const Text(' – ', style: TextStyle(color: AppTheme.textSecondary)),
                    Text('${team.losses}', style: const TextStyle(color: AppTheme.danger, fontWeight: FontWeight.w800, fontSize: 16)),
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
