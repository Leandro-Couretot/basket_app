class TeamStanding {
  final int pos;
  final String team;
  final int wins;
  final int losses;
  final double pct;
  final double gb;
  final String home;
  final String away;
  final String last10;
  final String streak;

  TeamStanding({
    required this.pos,
    required this.team,
    required this.wins,
    required this.losses,
    required this.pct,
    required this.gb,
    required this.home,
    required this.away,
    required this.last10,
    required this.streak,
  });

  factory TeamStanding.fromCsvRow(List<dynamic> row) {
    return TeamStanding(
      pos: int.parse(row[0].toString().trim()),
      team: row[1].toString().trim(),
      wins: int.parse(row[2].toString().trim()),
      losses: int.parse(row[3].toString().trim()),
      pct: double.parse(row[4].toString().trim()),
      gb: double.parse(row[5].toString().trim()),
      home: row[6].toString().trim(),
      away: row[7].toString().trim(),
      last10: row[8].toString().trim(),
      streak: row[9].toString().trim(),
    );
  }

  bool get isPlayoffSpot => pos <= 6;
  bool get isPlayInSpot => pos == 7 || pos == 8;
  bool get isWinStreak => streak.startsWith('W');
}
