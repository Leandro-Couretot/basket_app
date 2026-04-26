import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import 'box_score_screen.dart';

class FixtureScreen extends StatefulWidget {
  final AppRole role;
  const FixtureScreen({super.key, required this.role});

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
    if (!_loading) setState(() => _loading = true);
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
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _loadFixture),
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
                  child: RefreshIndicator(
                    color: AppTheme.primary,
                    onRefresh: _loadFixture,
                    child: _filtered.isEmpty
                        ? const SingleChildScrollView(
                            physics: AlwaysScrollableScrollPhysics(),
                            child: SizedBox(
                              height: 300,
                              child: Center(child: Text('Sin partidos en esta fecha', style: TextStyle(color: AppTheme.textSecondary))),
                            ),
                          )
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (_, i) => _MatchCard(
                              match: _filtered[i],
                              teamNames: _teamNames,
                              role: widget.role,
                              onRefresh: _loadFixture,
                            ),
                          ),
                  ),
                ),
              ],
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
  final AppRole role;
  final VoidCallback onRefresh;

  const _MatchCard({
    required this.match,
    required this.teamNames,
    required this.role,
    required this.onRefresh,
  });

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 36, height: 4, decoration: BoxDecoration(color: AppTheme.divider, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.edit_rounded, color: AppTheme.primary),
              title: const Text('Editar partido', style: TextStyle(color: AppTheme.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: AppTheme.surface,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                  builder: (_) => _EditMatchSheet(match: match, teamNames: teamNames, onSaved: onRefresh),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: AppTheme.danger),
              title: const Text('Eliminar partido', style: TextStyle(color: AppTheme.danger)),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: AppTheme.surface,
                    title: const Text('Eliminar partido', style: TextStyle(color: AppTheme.textPrimary)),
                    content: const Text('¿Estás seguro? Esta acción no se puede deshacer.', style: TextStyle(color: AppTheme.textSecondary)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await Supabase.instance.client.from('matches').delete().eq('id', match['id'] as String);
                          onRefresh();
                        },
                        child: const Text('Eliminar', style: TextStyle(color: AppTheme.danger)),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

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
              Row(
                children: [
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
                  if (role == AppRole.admin) ...[
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => _showOptions(context),
                      child: const Icon(Icons.more_vert_rounded, color: AppTheme.textSecondary, size: 18),
                    ),
                  ],
                ],
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
                _ActionChip(
                  icon: Icons.bar_chart_rounded,
                  label: 'Box Score',
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => BoxScoreScreen(
                      homeTeam: homeTeam,
                      awayTeam: awayTeam,
                      homeScore: homeScore,
                      awayScore: awayScore,
                    ),
                  )),
                ),
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

class _EditMatchSheet extends StatefulWidget {
  final Map<String, dynamic> match;
  final Map<String, String> teamNames;
  final VoidCallback onSaved;

  const _EditMatchSheet({required this.match, required this.teamNames, required this.onSaved});

  @override
  State<_EditMatchSheet> createState() => _EditMatchSheetState();
}

class _EditMatchSheetState extends State<_EditMatchSheet> {
  late final TextEditingController _homeScore;
  late final TextEditingController _awayScore;
  late String _status;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _homeScore = TextEditingController(text: '${widget.match['home_score']}');
    _awayScore = TextEditingController(text: '${widget.match['away_score']}');
    _status = widget.match['status'] as String;
  }

  @override
  void dispose() {
    _homeScore.dispose();
    _awayScore.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await Supabase.instance.client.from('matches').update({
        'home_score': int.tryParse(_homeScore.text) ?? 0,
        'away_score': int.tryParse(_awayScore.text) ?? 0,
        'status': _status,
      }).eq('id', widget.match['id'] as String);
      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
      }
    } catch (_) {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final homeTeam = widget.teamNames[widget.match['home_team_id']] ?? '?';
    final awayTeam = widget.teamNames[widget.match['away_team_id']] ?? '?';

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppTheme.divider, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            const Text('Editar partido', style: TextStyle(color: AppTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: Text(homeTeam, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('vs', style: TextStyle(color: AppTheme.textSecondary))),
                Expanded(child: Text(awayTeam, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _homeScore,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    textAlign: TextAlign.center,
                    decoration: _inputDeco('Pts local'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _awayScore,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    textAlign: TextAlign.center,
                    decoration: _inputDeco('Pts visitante'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Estado', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            Row(
              children: [
                _StatusChip(label: 'Próximo', value: 'scheduled', current: _status, onTap: (v) => setState(() => _status = v)),
                const SizedBox(width: 8),
                _StatusChip(label: 'Finalizado', value: 'finished', current: _status, onTap: (v) => setState(() => _status = v)),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Guardar cambios', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        filled: true,
        fillColor: AppTheme.surfaceElevated,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      );
}

class _StatusChip extends StatelessWidget {
  final String label;
  final String value;
  final String current;
  final ValueChanged<String> onTap;

  const _StatusChip({required this.label, required this.value, required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final selected = value == current;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(color: selected ? Colors.white : AppTheme.textSecondary, fontWeight: selected ? FontWeight.w600 : FontWeight.w400, fontSize: 13)),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ActionChip({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: onTap != null ? AppTheme.primary.withValues(alpha: 0.4) : AppTheme.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: onTap != null ? AppTheme.primary : AppTheme.textSecondary, size: 13),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: onTap != null ? AppTheme.primary : AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
