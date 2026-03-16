import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final _client = Supabase.instance.client;

  // --- Seasons ---
  static Future<List<Map<String, dynamic>>> getSeasons() async {
    return await _client.from('seasons').select().order('created_at', ascending: false);
  }

  static Future<Map<String, dynamic>> getActiveSeason() async {
    final result = await _client.from('seasons').select().eq('is_active', true).single();
    return result;
  }

  // --- Teams ---
  static Future<List<Map<String, dynamic>>> getTeams() async {
    return await _client.from('teams').select().order('name');
  }

  static Future<Map<String, dynamic>> createTeam({
    required String name,
    String? city,
    String? logoUrl,
  }) async {
    final result = await _client.from('teams').insert({
      'name': name,
      'city': city,
      'logo_url': logoUrl,
    }).select().single();
    return result;
  }

  // --- Players ---
  static Future<List<Map<String, dynamic>>> getPlayersByTeam(String teamId) async {
    return await _client
        .from('players')
        .select()
        .eq('team_id', teamId)
        .order('last_name');
  }

  static Future<Map<String, dynamic>> createPlayer({
    required String teamId,
    required String firstName,
    required String lastName,
    int? number,
    String? position,
  }) async {
    final result = await _client.from('players').insert({
      'team_id': teamId,
      'first_name': firstName,
      'last_name': lastName,
      'number': number,
      'position': position,
    }).select().single();
    return result;
  }

  // --- Matches ---
  static Future<List<Map<String, dynamic>>> getMatchesBySeason(String seasonId) async {
    return await _client
        .from('matches')
        .select('''
          *,
          home_team:teams!matches_home_team_id_fkey(id, name, logo_url),
          away_team:teams!matches_away_team_id_fkey(id, name, logo_url)
        ''')
        .eq('season_id', seasonId)
        .order('match_date');
  }

  static Future<Map<String, dynamic>> createMatch({
    required String seasonId,
    required String homeTeamId,
    required String awayTeamId,
    DateTime? matchDate,
    int? round,
  }) async {
    final result = await _client.from('matches').insert({
      'season_id': seasonId,
      'home_team_id': homeTeamId,
      'away_team_id': awayTeamId,
      'match_date': matchDate?.toIso8601String(),
      'round': round,
      'status': 'scheduled',
    }).select().single();
    return result;
  }

  static Future<void> updateMatchScore({
    required String matchId,
    required int homeScore,
    required int awayScore,
    String status = 'finished',
  }) async {
    await _client.from('matches').update({
      'home_score': homeScore,
      'away_score': awayScore,
      'status': status,
    }).eq('id', matchId);
  }

  // --- Standings ---
  static Future<List<Map<String, dynamic>>> getStandings(String seasonId) async {
    final matches = await _client
        .from('matches')
        .select('''
          home_team_id, away_team_id, home_score, away_score,
          home_team:teams!matches_home_team_id_fkey(id, name),
          away_team:teams!matches_away_team_id_fkey(id, name)
        ''')
        .eq('season_id', seasonId)
        .eq('status', 'finished');
    return List<Map<String, dynamic>>.from(matches);
  }

  // --- Acta Digital (Player Stats) ---
  static Future<List<Map<String, dynamic>>> getMatchStats(String matchId) async {
    return await _client
        .from('player_match_stats')
        .select('''
          *,
          player:players(id, first_name, last_name, number, position),
          team:teams(id, name)
        ''')
        .eq('match_id', matchId);
  }

  static Future<void> savePlayerStats({
    required String matchId,
    required String playerId,
    required String teamId,
    required Map<String, dynamic> stats,
  }) async {
    await _client.from('player_match_stats').upsert({
      'match_id': matchId,
      'player_id': playerId,
      'team_id': teamId,
      ...stats,
    });
  }

  // --- Match Photos ---
  static Future<List<Map<String, dynamic>>> getMatchPhotos(String matchId) async {
    return await _client
        .from('match_photos')
        .select()
        .eq('match_id', matchId)
        .order('created_at');
  }

  static Future<void> addMatchPhoto({
    required String matchId,
    required String photoUrl,
    String? caption,
  }) async {
    await _client.from('match_photos').insert({
      'match_id': matchId,
      'photo_url': photoUrl,
      'caption': caption,
    });
  }
}
