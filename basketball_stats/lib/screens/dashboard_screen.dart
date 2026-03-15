import 'package:flutter/material.dart';
import '../main.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryDim,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.sports_basketball, color: AppTheme.primary, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('BEA Stats'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events_rounded, color: AppTheme.primary),
            onPressed: () {},
          ),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SeasonSelector(),
            const SizedBox(height: 20),
            _SectionTitle('Líderes del equipo'),
            const SizedBox(height: 12),
            _LeadersGrid(),
            const SizedBox(height: 24),
            _SectionTitle('Últimos resultados'),
            const SizedBox(height: 12),
            _RecentMatchCard(
              homeTeam: 'Lugano 80',
              awayTeam: 'Super Ácidos',
              homeScore: 84,
              awayScore: 37,
              date: '21/09/2025',
            ),
            const SizedBox(height: 10),
            _RecentMatchCard(
              homeTeam: 'Achaval City',
              awayTeam: 'Slow Motion',
              homeScore: 71,
              awayScore: 65,
              date: '14/09/2025',
            ),
            const SizedBox(height: 24),
            _SectionTitle('MVPs de la fecha'),
            const SizedBox(height: 12),
            _MVPCard(),
          ],
        ),
      ),
    );
  }
}

class _SeasonSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          const Icon(Icons.sports_basketball, color: AppTheme.primary, size: 16),
          const SizedBox(width: 8),
          const Text('Achaval City Básquet', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
          const Spacer(),
          const Icon(Icons.expand_more, color: AppTheme.textSecondary, size: 20),
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
      style: const TextStyle(
        color: AppTheme.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _LeadersGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.4,
      children: const [
        _LeaderCard(
          icon: Icons.sports_basketball,
          color: Color(0xFF2ECC71),
          statLabel: 'Puntos',
          playerNumber: '#11',
          playerName: 'player11',
          value: '9.0',
          games: '5 partidos',
        ),
        _LeaderCard(
          icon: Icons.swap_horiz_rounded,
          color: Color(0xFFE74C3C),
          statLabel: 'Asistencias',
          playerNumber: '#8',
          playerName: 'player8',
          value: '1.3',
          games: '3 partidos',
        ),
        _LeaderCard(
          icon: Icons.fitbit,
          color: Color(0xFF3498DB),
          statLabel: 'Rebotes',
          playerNumber: '#10',
          playerName: 'player10',
          value: '3.4',
          games: '5 partidos',
        ),
        _ResultsCard(wins: 3, losses: 2),
      ],
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

  const _LeaderCard({
    required this.icon,
    required this.color,
    required this.statLabel,
    required this.playerNumber,
    required this.playerName,
    required this.value,
    required this.games,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
              Text(statLabel, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w600)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(text: value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.w800)),
                    const TextSpan(text: ' avg', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                  ],
                ),
              ),
              Text('$playerNumber $playerName', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
              Text(games, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResultsCard extends StatelessWidget {
  final int wins;
  final int losses;

  const _ResultsCard({required this.wins, required this.losses});

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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('$wins', style: const TextStyle(color: AppTheme.success, fontSize: 22, fontWeight: FontWeight.w800)),
                  const Text(' - ', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
                  Text('$losses', style: const TextStyle(color: AppTheme.danger, fontSize: 22, fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: winPct,
                  backgroundColor: AppTheme.danger.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.success),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 2),
              Text('${(winPct * 100).toStringAsFixed(0)}% victorias', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecentMatchCard extends StatelessWidget {
  final String homeTeam;
  final String awayTeam;
  final int homeScore;
  final int awayScore;
  final String date;

  const _RecentMatchCard({
    required this.homeTeam,
    required this.awayTeam,
    required this.homeScore,
    required this.awayScore,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final homeWon = homeScore > awayScore;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              homeTeam,
              style: TextStyle(
                color: homeWon ? AppTheme.textPrimary : AppTheme.textSecondary,
                fontWeight: homeWon ? FontWeight.w700 : FontWeight.w400,
                fontSize: 13,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Text('$homeScore', style: TextStyle(color: homeWon ? AppTheme.primary : AppTheme.textSecondary, fontWeight: FontWeight.w800, fontSize: 16)),
                const Text('  –  ', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                Text('$awayScore', style: TextStyle(color: !homeWon ? AppTheme.primary : AppTheme.textSecondary, fontWeight: FontWeight.w800, fontSize: 16)),
              ],
            ),
          ),
          Expanded(
            child: Text(
              awayTeam,
              style: TextStyle(
                color: !homeWon ? AppTheme.textPrimary : AppTheme.textSecondary,
                fontWeight: !homeWon ? FontWeight.w700 : FontWeight.w400,
                fontSize: 13,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _MVPCard extends StatelessWidget {
  const _MVPCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star_rounded, color: AppTheme.primary, size: 16),
              const SizedBox(width: 6),
              const Text('Lugano 80  84 – 37  Super Ácidos', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
              const Spacer(),
              Text('21/09', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
            ],
          ),
          const Divider(height: 16),
          _mvpRow('19 Puntos', 'martin di placido'),
          _mvpRow('6 Rebotes', 'Krukovsky / lucas di placio'),
          _mvpRow('6 Asistencias', 'martin di placido'),
          _mvpRow('29 Valoración', 'martin di placido'),
        ],
      ),
    );
  }

  Widget _mvpRow(String stat, String player) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(stat, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(player, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12))),
        ],
      ),
    );
  }
}
