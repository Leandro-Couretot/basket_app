class PlayerStats {
  final String playerId;
  final String matchId;

  // Basic
  final int minutes;
  final int seconds;
  final int points;
  final int rebounds;
  final int offensiveRebounds;
  final int defensiveRebounds;
  final int assists;
  final int steals;
  final int blocks;
  final int blocksReceived;
  final int turnovers;
  final int fouls;
  final int foulsReceived;

  // Shooting
  final int fieldGoalsMade;
  final int fieldGoalsAttempted;
  final int threesMade;
  final int threesAttempted;
  final int freeThrowsMade;
  final int freeThrowsAttempted;

  const PlayerStats({
    required this.playerId,
    required this.matchId,
    this.minutes = 0,
    this.seconds = 0,
    this.points = 0,
    this.rebounds = 0,
    this.offensiveRebounds = 0,
    this.defensiveRebounds = 0,
    this.assists = 0,
    this.steals = 0,
    this.blocks = 0,
    this.blocksReceived = 0,
    this.turnovers = 0,
    this.fouls = 0,
    this.foulsReceived = 0,
    this.fieldGoalsMade = 0,
    this.fieldGoalsAttempted = 0,
    this.threesMade = 0,
    this.threesAttempted = 0,
    this.freeThrowsMade = 0,
    this.freeThrowsAttempted = 0,
  });

  double get fieldGoalPct =>
      fieldGoalsAttempted > 0 ? fieldGoalsMade / fieldGoalsAttempted * 100 : 0;

  double get threePct =>
      threesAttempted > 0 ? threesMade / threesAttempted * 100 : 0;

  double get freeThrowPct =>
      freeThrowsAttempted > 0 ? freeThrowsMade / freeThrowsAttempted * 100 : 0;

  // PIR (Performance Index Rating)
  int get pir =>
      points +
      rebounds +
      assists +
      steals +
      blocks +
      foulsReceived -
      (fieldGoalsAttempted - fieldGoalsMade) -
      (freeThrowsAttempted - freeThrowsMade) -
      turnovers -
      fouls;

  String get minutesFormatted =>
      '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}
