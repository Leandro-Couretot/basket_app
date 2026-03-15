import 'package:flutter/material.dart';
import '../main.dart';

class _Standing {
  final int pos;
  final String team;
  final int played;
  final int wins;
  final int losses;
  final int pointsFor;
  final int pointsAgainst;

  const _Standing({
    required this.pos,
    required this.team,
    required this.played,
    required this.wins,
    required this.losses,
    required this.pointsFor,
    required this.pointsAgainst,
  });

  int get diff => pointsFor - pointsAgainst;
  double get pct => played > 0 ? wins / played : 0;
}

class StandingsScreen extends StatelessWidget {
  const StandingsScreen({super.key});

  static const _standings = [
    _Standing(pos: 1, team: 'Lugano 80', played: 5, wins: 4, losses: 1, pointsFor: 392, pointsAgainst: 310),
    _Standing(pos: 2, team: 'Achaval City', played: 5, wins: 3, losses: 2, pointsFor: 358, pointsAgainst: 340),
    _Standing(pos: 3, team: 'Slow Motion', played: 4, wins: 2, losses: 2, pointsFor: 290, pointsAgainst: 285),
    _Standing(pos: 4, team: 'Super Ácidos', played: 5, wins: 1, losses: 4, pointsFor: 310, pointsAgainst: 415),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tabla de Posiciones'),
        actions: [
          IconButton(icon: const Icon(Icons.filter_alt_outlined), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          _TournamentSelector(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _StandingsTable(standings: _standings),
                  const SizedBox(height: 24),
                  _LastUpdated(),
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
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppTheme.surface,
      child: Row(
        children: [
          const Icon(Icons.emoji_events_rounded, color: AppTheme.primary, size: 16),
          const SizedBox(width: 8),
          const Text('Torneo Apertura 2025', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
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
                color: isFirst ? AppTheme.textPrimary : AppTheme.textPrimary,
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
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(Icons.update_rounded, color: AppTheme.textSecondary, size: 13),
        SizedBox(width: 4),
        Text('Actualizado tras fecha 2', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
      ],
    );
  }
}
