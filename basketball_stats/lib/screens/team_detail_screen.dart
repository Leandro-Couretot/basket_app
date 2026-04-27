import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import 'box_score_screen.dart';

class TeamDetailScreen extends StatefulWidget {
  final String teamId;
  final String teamName;

  const TeamDetailScreen({
    super.key,
    required this.teamId,
    required this.teamName,
  });

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen> {
  List<Map<String, dynamic>> _matches = [];
  Map<String, String> _teamNames = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final client = Supabase.instance.client;

    final season = await client.from('seasons').select().eq('is_active', true).single();
    final seasonId = season['id'] as String;

    final teamsData = await client.from('teams').select('id, name');
    final teamNames = {for (final t in teamsData) t['id'] as String: t['name'] as String};

    final matches = await client
        .from('matches')
        .select('id, home_team_id, away_team_id, home_score, away_score, match_date, round, status')
        .eq('season_id', seasonId)
        .or('home_team_id.eq.${widget.teamId},away_team_id.eq.${widget.teamId}')
        .order('round');

    setState(() {
      _matches = List<Map<String, dynamic>>.from(matches);
      _teamNames = teamNames;
      _loading = false;
    });
  }

  int get _wins => _matches.where((m) {
        final isHome = m['home_team_id'] == widget.teamId;
        final hs = m['home_score'] as int? ?? 0;
        final as_ = m['away_score'] as int? ?? 0;
        return m['status'] == 'finished' && (isHome ? hs > as_ : as_ > hs);
      }).length;

  int get _losses => _matches.where((m) {
        final isHome = m['home_team_id'] == widget.teamId;
        final hs = m['home_score'] as int? ?? 0;
        final as_ = m['away_score'] as int? ?? 0;
        return m['status'] == 'finished' && (isHome ? hs < as_ : as_ < hs);
      }).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.teamName),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : Column(
              children: [
                _TeamSummaryBar(wins: _wins, losses: _losses, played: _wins + _losses),
                Expanded(
                  child: RefreshIndicator(
                    color: AppTheme.primary,
                    onRefresh: _load,
                    child: _matches.isEmpty
                        ? const Center(child: Text('Sin partidos', style: TextStyle(color: AppTheme.textSecondary)))
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _matches.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (_, i) => _TeamMatchCard(
                              match: _matches[i],
                              myTeamId: widget.teamId,
                              myTeamName: widget.teamName,
                              teamNames: _teamNames,
                            ),
                          ),
                  ),
                ),
              ],
            ),
    );
  }
}

// ── Summary bar ───────────────────────────────────────────────────────────────

class _TeamSummaryBar extends StatelessWidget {
  final int wins;
  final int losses;
  final int played;

  const _TeamSummaryBar({required this.wins, required this.losses, required this.played});

  @override
  Widget build(BuildContext context) {
    final winPct = played > 0 ? (wins / played * 100).round() : 0;
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatPill(label: 'PJ', value: '$played', color: AppTheme.textSecondary),
          _StatPill(label: 'G', value: '$wins', color: AppTheme.success),
          _StatPill(label: 'P', value: '$losses', color: AppTheme.danger),
          _StatPill(label: 'WIN%', value: '$winPct%', color: AppTheme.primary),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatPill({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

// ── Match card ────────────────────────────────────────────────────────────────

class _TeamMatchCard extends StatelessWidget {
  final Map<String, dynamic> match;
  final String myTeamId;
  final String myTeamName;
  final Map<String, String> teamNames;

  const _TeamMatchCard({
    required this.match,
    required this.myTeamId,
    required this.myTeamName,
    required this.teamNames,
  });

  @override
  Widget build(BuildContext context) {
    final isHome = match['home_team_id'] == myTeamId;
    final opponentId = isHome ? match['away_team_id'] as String : match['home_team_id'] as String;
    final opponentName = teamNames[opponentId] ?? '?';
    final finished = match['status'] == 'finished';
    final homeScore = match['home_score'] as int? ?? 0;
    final awayScore = match['away_score'] as int? ?? 0;
    final myScore = isHome ? homeScore : awayScore;
    final theirScore = isHome ? awayScore : homeScore;
    final won = finished && myScore > theirScore;
    final date = _formatDate(match['match_date'] as String);
    final round = match['round'] as int;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: finished
            ? Border.all(color: (won ? AppTheme.success : AppTheme.danger).withValues(alpha: 0.2))
            : null,
      ),
      child: Column(
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text('Fecha $round', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                  const SizedBox(width: 6),
                  Text(isHome ? 'LOCAL' : 'VISITANTE',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
                ],
              ),
              if (finished)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: (won ? AppTheme.success : AppTheme.danger).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    won ? 'VICTORIA' : 'DERROTA',
                    style: TextStyle(
                      color: won ? AppTheme.success : AppTheme.danger,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else
                Text(date, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 12),
          // Score row
          Row(
            children: [
              Expanded(
                child: Text(
                  myTeamName,
                  style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
              if (finished)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      Text('$myScore', style: TextStyle(color: won ? AppTheme.primary : AppTheme.textSecondary, fontWeight: FontWeight.w800, fontSize: 18)),
                      const Text('  –  ', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                      Text('$theirScore', style: TextStyle(color: !won ? AppTheme.primary : AppTheme.textSecondary, fontWeight: FontWeight.w800, fontSize: 18)),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(10)),
                  child: Text(date, style: const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                ),
              Expanded(
                child: Text(
                  opponentName,
                  style: const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w500, fontSize: 14),
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
                      homeTeam: teamNames[match['home_team_id']] ?? '?',
                      awayTeam: teamNames[match['away_team_id']] ?? '?',
                      homeScore: homeScore,
                      awayScore: awayScore,
                    ),
                  )),
                ),
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
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppTheme.primary, size: 13),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
