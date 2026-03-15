import 'player_stats.dart';

enum MatchStatus { scheduled, live, finished }

class QuarterScore {
  final int q1;
  final int q2;
  final int q3;
  final int q4;
  final int? ot;

  const QuarterScore({
    this.q1 = 0,
    this.q2 = 0,
    this.q3 = 0,
    this.q4 = 0,
    this.ot,
  });

  int get total => q1 + q2 + q3 + q4 + (ot ?? 0);
}

class Match {
  final String id;
  final String seasonId;
  final String homeTeamId;
  final String awayTeamId;
  final DateTime date;
  final String? venue;
  final MatchStatus status;
  final QuarterScore? homeScore;
  final QuarterScore? awayScore;
  final List<PlayerStats> stats;
  final String? referee1;
  final String? referee2;

  const Match({
    required this.id,
    required this.seasonId,
    required this.homeTeamId,
    required this.awayTeamId,
    required this.date,
    this.venue,
    this.status = MatchStatus.scheduled,
    this.homeScore,
    this.awayScore,
    this.stats = const [],
    this.referee1,
    this.referee2,
  });

  bool get isFinished => status == MatchStatus.finished;

  String? get winnerId {
    if (!isFinished || homeScore == null || awayScore == null) return null;
    if (homeScore!.total > awayScore!.total) return homeTeamId;
    if (awayScore!.total > homeScore!.total) return awayTeamId;
    return null; // draw (shouldn't happen in basketball)
  }
}
