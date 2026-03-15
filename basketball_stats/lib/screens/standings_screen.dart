import 'package:flutter/material.dart';
import '../models/team_standing.dart';
import '../utils/csv_parser.dart';

class StandingsScreen extends StatefulWidget {
  const StandingsScreen({super.key});

  @override
  State<StandingsScreen> createState() => _StandingsScreenState();
}

class _StandingsScreenState extends State<StandingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<TeamStanding> eastStandings = [];
  List<TeamStanding> westStandings = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final east = await CsvParser.loadStandings('assets/data/nba_standings_east.csv');
    final west = await CsvParser.loadStandings('assets/data/nba_standings_west.csv');
    setState(() {
      eastStandings = east;
      westStandings = west;
      isLoading = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Row(
          children: [
            const Icon(Icons.sports_basketball, color: Color(0xFFFF6B00), size: 28),
            const SizedBox(width: 10),
            const Text(
              'NBA Standings',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFF6B00),
          labelColor: const Color(0xFFFF6B00),
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'ESTE'),
            Tab(text: 'OESTE'),
          ],
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF6B00)),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildStandingsTab(eastStandings),
                _buildStandingsTab(westStandings),
              ],
            ),
    );
  }

  Widget _buildStandingsTab(List<TeamStanding> standings) {
    return Column(
      children: [
        _buildLegend(),
        _buildTableHeader(),
        Expanded(
          child: ListView.builder(
            itemCount: standings.length,
            itemBuilder: (context, index) {
              return _buildTeamRow(standings[index], index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _legendDot(const Color(0xFF00C853), 'Playoffs'),
          const SizedBox(width: 16),
          _legendDot(const Color(0xFF2979FF), 'Play-In'),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: const Color(0xFF1A1A2E),
      child: Row(
        children: [
          _headerCell('#', 30),
          _headerCell('EQUIPO', 0, flex: 3),
          _headerCell('G', 36),
          _headerCell('P', 36),
          _headerCell('%', 52),
          _headerCell('DIF', 44),
          _headerCell('ÚLT10', 52),
          _headerCell('RACHA', 52),
        ],
      ),
    );
  }

  Widget _headerCell(String text, double width, {int flex = 0}) {
    final style = const TextStyle(
      color: Colors.grey,
      fontSize: 11,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.5,
    );
    if (flex > 0) {
      return Expanded(
        flex: flex,
        child: Text(text, style: style),
      );
    }
    return SizedBox(
      width: width,
      child: Text(text, style: style, textAlign: TextAlign.center),
    );
  }

  Widget _buildTeamRow(TeamStanding team, int index) {
    Color? rowAccent;
    if (team.isPlayoffSpot) rowAccent = const Color(0xFF00C853);
    if (team.isPlayInSpot) rowAccent = const Color(0xFF2979FF);

    final bool isEven = index % 2 == 0;

    return Container(
      decoration: BoxDecoration(
        color: isEven ? const Color(0xFF111122) : const Color(0xFF0D0D1A),
        border: rowAccent != null
            ? Border(left: BorderSide(color: rowAccent, width: 3))
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Position
          SizedBox(
            width: 30,
            child: Text(
              '${team.pos}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Team name
          Expanded(
            flex: 3,
            child: Text(
              team.team,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // W
          _statCell('${team.wins}', Colors.white),
          // L
          _statCell('${team.losses}', Colors.white70),
          // PCT
          _statCell(
            team.pct.toStringAsFixed(3),
            const Color(0xFFFF6B00),
            width: 52,
          ),
          // GB
          _statCell(
            team.gb == 0.0 ? '-' : team.gb.toStringAsFixed(1),
            Colors.grey,
            width: 44,
          ),
          // Last 10
          _statCell(team.last10, Colors.white70, width: 52),
          // Streak
          SizedBox(
            width: 52,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: team.isWinStreak
                    ? const Color(0xFF00C853).withOpacity(0.2)
                    : const Color(0xFFD50000).withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                team.streak,
                style: TextStyle(
                  color: team.isWinStreak
                      ? const Color(0xFF00C853)
                      : const Color(0xFFFF4444),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCell(String value, Color color, {double width = 36}) {
    return SizedBox(
      width: width,
      child: Text(
        value,
        style: TextStyle(color: color, fontSize: 13),
        textAlign: TextAlign.center,
      ),
    );
  }
}
