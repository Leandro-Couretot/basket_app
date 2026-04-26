-- =============================================
-- BEA Stats - Player Match Stats Seed
-- Pegar en Supabase SQL Editor y ejecutar
-- =============================================

-- Helper: gets match id by round + home team name
-- Helper: gets player id by last name
-- Helper: gets team id by name

-- ===== MATCH 1: Lakers 112 vs Warriors 105 (Round 1) =====
INSERT INTO player_match_stats (match_id, player_id, team_id, minutes_played, points, rebounds, assists, steals, blocks, turnovers, fouls)
VALUES
  ((SELECT id FROM matches WHERE round=1 AND home_team_id=(SELECT id FROM teams WHERE name='Lakers')),
   (SELECT id FROM players WHERE last_name='James'),
   (SELECT id FROM teams WHERE name='Lakers'), 38, 35, 9, 7, 2, 1, 3, 2),
  ((SELECT id FROM matches WHERE round=1 AND home_team_id=(SELECT id FROM teams WHERE name='Lakers')),
   (SELECT id FROM players WHERE last_name='Davis'),
   (SELECT id FROM teams WHERE name='Lakers'), 36, 45, 14, 2, 1, 4, 2, 3),
  ((SELECT id FROM matches WHERE round=1 AND home_team_id=(SELECT id FROM teams WHERE name='Lakers')),
   (SELECT id FROM players WHERE last_name='Reaves'),
   (SELECT id FROM teams WHERE name='Lakers'), 30, 32, 4, 3, 1, 0, 1, 2),
  ((SELECT id FROM matches WHERE round=1 AND home_team_id=(SELECT id FROM teams WHERE name='Lakers')),
   (SELECT id FROM players WHERE last_name='Curry'),
   (SELECT id FROM teams WHERE name='Warriors'), 38, 44, 4, 7, 2, 0, 3, 2),
  ((SELECT id FROM matches WHERE round=1 AND home_team_id=(SELECT id FROM teams WHERE name='Lakers')),
   (SELECT id FROM players WHERE last_name='Green'),
   (SELECT id FROM teams WHERE name='Warriors'), 35, 18, 11, 8, 2, 2, 2, 4),
  ((SELECT id FROM matches WHERE round=1 AND home_team_id=(SELECT id FROM teams WHERE name='Lakers')),
   (SELECT id FROM players WHERE last_name='Wiggins'),
   (SELECT id FROM teams WHERE name='Warriors'), 32, 43, 5, 2, 1, 1, 1, 2);

-- ===== MATCH 2: Celtics 118 vs Heat 98 (Round 1) =====
INSERT INTO player_match_stats (match_id, player_id, team_id, minutes_played, points, rebounds, assists, steals, blocks, turnovers, fouls)
VALUES
  ((SELECT id FROM matches WHERE round=1 AND home_team_id=(SELECT id FROM teams WHERE name='Celtics')),
   (SELECT id FROM players WHERE last_name='Tatum'),
   (SELECT id FROM teams WHERE name='Celtics'), 36, 42, 10, 5, 2, 1, 2, 2),
  ((SELECT id FROM matches WHERE round=1 AND home_team_id=(SELECT id FROM teams WHERE name='Celtics')),
   (SELECT id FROM players WHERE last_name='Brown'),
   (SELECT id FROM teams WHERE name='Celtics'), 34, 44, 6, 3, 3, 0, 2, 3),
  ((SELECT id FROM matches WHERE round=1 AND home_team_id=(SELECT id FROM teams WHERE name='Celtics')),
   (SELECT id FROM players WHERE last_name='Porzingis'),
   (SELECT id FROM teams WHERE name='Celtics'), 28, 32, 12, 2, 0, 4, 1, 3),
  ((SELECT id FROM matches WHERE round=1 AND home_team_id=(SELECT id FROM teams WHERE name='Celtics')),
   (SELECT id FROM players WHERE last_name='Butler'),
   (SELECT id FROM teams WHERE name='Heat'), 36, 38, 7, 4, 3, 1, 2, 3),
  ((SELECT id FROM matches WHERE round=1 AND home_team_id=(SELECT id FROM teams WHERE name='Celtics')),
   (SELECT id FROM players WHERE last_name='Adebayo'),
   (SELECT id FROM teams WHERE name='Heat'), 34, 32, 13, 2, 1, 3, 2, 4),
  ((SELECT id FROM matches WHERE round=1 AND home_team_id=(SELECT id FROM teams WHERE name='Celtics')),
   (SELECT id FROM players WHERE last_name='Herro'),
   (SELECT id FROM teams WHERE name='Heat'), 30, 28, 4, 3, 1, 0, 2, 2);

-- ===== MATCH 3: Nuggets 99 vs Bucks 110 (Round 1) =====
INSERT INTO player_match_stats (match_id, player_id, team_id, minutes_played, points, rebounds, assists, steals, blocks, turnovers, fouls)
VALUES
  ((SELECT id FROM matches WHERE round=1 AND home_team_id=(SELECT id FROM teams WHERE name='Nuggets')),
   (SELECT id FROM players WHERE last_name='Jokic'),
   (SELECT id FROM teams WHERE name='Nuggets'), 38, 42, 15, 11, 1, 1, 3, 2),
  ((SELECT id FROM matches WHERE round=1 AND home_team_id=(SELECT id FROM teams WHERE name='Nuggets')),
   (SELECT id FROM players WHERE last_name='Murray'),
   (SELECT id FROM teams WHERE name='Nuggets'), 36, 35, 5, 7, 2, 0, 3, 2),
  ((SELECT id FROM matches WHERE round=1 AND home_team_id=(SELECT id FROM teams WHERE name='Nuggets')),
   (SELECT id FROM players WHERE last_name='Porter'),
   (SELECT id FROM teams WHERE name='Nuggets'), 30, 22, 8, 2, 1, 1, 1, 3),
  ((SELECT id FROM matches WHERE round=1 AND home_team_id=(SELECT id FROM teams WHERE name='Nuggets')),
   (SELECT id FROM players WHERE last_name='Antetokounmpo'),
   (SELECT id FROM teams WHERE name='Bucks'), 38, 48, 14, 5, 2, 3, 2, 3),
  ((SELECT id FROM matches WHERE round=1 AND home_team_id=(SELECT id FROM teams WHERE name='Nuggets')),
   (SELECT id FROM players WHERE last_name='Lillard'),
   (SELECT id FROM teams WHERE name='Bucks'), 36, 40, 4, 6, 1, 0, 3, 2),
  ((SELECT id FROM matches WHERE round=1 AND home_team_id=(SELECT id FROM teams WHERE name='Nuggets')),
   (SELECT id FROM players WHERE last_name='Middleton'),
   (SELECT id FROM teams WHERE name='Bucks'), 30, 22, 5, 3, 1, 0, 1, 2);

-- ===== MATCH 4: Warriors 121 vs Celtics 115 (Round 2) =====
INSERT INTO player_match_stats (match_id, player_id, team_id, minutes_played, points, rebounds, assists, steals, blocks, turnovers, fouls)
VALUES
  ((SELECT id FROM matches WHERE round=2 AND home_team_id=(SELECT id FROM teams WHERE name='Warriors')),
   (SELECT id FROM players WHERE last_name='Curry'),
   (SELECT id FROM teams WHERE name='Warriors'), 38, 52, 5, 8, 3, 0, 2, 1),
  ((SELECT id FROM matches WHERE round=2 AND home_team_id=(SELECT id FROM teams WHERE name='Warriors')),
   (SELECT id FROM players WHERE last_name='Green'),
   (SELECT id FROM teams WHERE name='Warriors'), 36, 14, 12, 9, 2, 2, 3, 4),
  ((SELECT id FROM matches WHERE round=2 AND home_team_id=(SELECT id FROM teams WHERE name='Warriors')),
   (SELECT id FROM players WHERE last_name='Wiggins'),
   (SELECT id FROM teams WHERE name='Warriors'), 34, 55, 6, 2, 2, 1, 1, 2),
  ((SELECT id FROM matches WHERE round=2 AND home_team_id=(SELECT id FROM teams WHERE name='Warriors')),
   (SELECT id FROM players WHERE last_name='Tatum'),
   (SELECT id FROM teams WHERE name='Celtics'), 38, 48, 11, 6, 2, 1, 3, 3),
  ((SELECT id FROM matches WHERE round=2 AND home_team_id=(SELECT id FROM teams WHERE name='Warriors')),
   (SELECT id FROM players WHERE last_name='Brown'),
   (SELECT id FROM teams WHERE name='Celtics'), 36, 42, 7, 4, 2, 0, 2, 2),
  ((SELECT id FROM matches WHERE round=2 AND home_team_id=(SELECT id FROM teams WHERE name='Warriors')),
   (SELECT id FROM players WHERE last_name='Porzingis'),
   (SELECT id FROM teams WHERE name='Celtics'), 28, 25, 13, 1, 0, 5, 2, 4);

-- ===== MATCH 5: Heat 95 vs Nuggets 108 (Round 2) =====
INSERT INTO player_match_stats (match_id, player_id, team_id, minutes_played, points, rebounds, assists, steals, blocks, turnovers, fouls)
VALUES
  ((SELECT id FROM matches WHERE round=2 AND home_team_id=(SELECT id FROM teams WHERE name='Heat')),
   (SELECT id FROM players WHERE last_name='Butler'),
   (SELECT id FROM teams WHERE name='Heat'), 38, 40, 8, 5, 3, 1, 2, 3),
  ((SELECT id FROM matches WHERE round=2 AND home_team_id=(SELECT id FROM teams WHERE name='Heat')),
   (SELECT id FROM players WHERE last_name='Adebayo'),
   (SELECT id FROM teams WHERE name='Heat'), 36, 34, 14, 3, 1, 3, 2, 3),
  ((SELECT id FROM matches WHERE round=2 AND home_team_id=(SELECT id FROM teams WHERE name='Heat')),
   (SELECT id FROM players WHERE last_name='Herro'),
   (SELECT id FROM teams WHERE name='Heat'), 30, 21, 3, 4, 1, 0, 2, 2),
  ((SELECT id FROM matches WHERE round=2 AND home_team_id=(SELECT id FROM teams WHERE name='Heat')),
   (SELECT id FROM players WHERE last_name='Jokic'),
   (SELECT id FROM teams WHERE name='Nuggets'), 38, 45, 16, 12, 2, 1, 2, 2),
  ((SELECT id FROM matches WHERE round=2 AND home_team_id=(SELECT id FROM teams WHERE name='Heat')),
   (SELECT id FROM players WHERE last_name='Murray'),
   (SELECT id FROM teams WHERE name='Nuggets'), 36, 38, 6, 8, 2, 0, 3, 2),
  ((SELECT id FROM matches WHERE round=2 AND home_team_id=(SELECT id FROM teams WHERE name='Heat')),
   (SELECT id FROM players WHERE last_name='Porter'),
   (SELECT id FROM teams WHERE name='Nuggets'), 30, 25, 9, 2, 1, 2, 1, 2);

-- ===== MATCH 6: Bucks 119 vs Lakers 102 (Round 2) =====
INSERT INTO player_match_stats (match_id, player_id, team_id, minutes_played, points, rebounds, assists, steals, blocks, turnovers, fouls)
VALUES
  ((SELECT id FROM matches WHERE round=2 AND home_team_id=(SELECT id FROM teams WHERE name='Bucks')),
   (SELECT id FROM players WHERE last_name='Antetokounmpo'),
   (SELECT id FROM teams WHERE name='Bucks'), 38, 52, 15, 6, 2, 3, 2, 2),
  ((SELECT id FROM matches WHERE round=2 AND home_team_id=(SELECT id FROM teams WHERE name='Bucks')),
   (SELECT id FROM players WHERE last_name='Lillard'),
   (SELECT id FROM teams WHERE name='Bucks'), 36, 44, 5, 7, 2, 0, 3, 2),
  ((SELECT id FROM matches WHERE round=2 AND home_team_id=(SELECT id FROM teams WHERE name='Bucks')),
   (SELECT id FROM players WHERE last_name='Middleton'),
   (SELECT id FROM teams WHERE name='Bucks'), 30, 23, 6, 3, 1, 0, 1, 3),
  ((SELECT id FROM matches WHERE round=2 AND home_team_id=(SELECT id FROM teams WHERE name='Bucks')),
   (SELECT id FROM players WHERE last_name='James'),
   (SELECT id FROM teams WHERE name='Lakers'), 38, 38, 10, 9, 2, 1, 3, 2),
  ((SELECT id FROM matches WHERE round=2 AND home_team_id=(SELECT id FROM teams WHERE name='Bucks')),
   (SELECT id FROM players WHERE last_name='Davis'),
   (SELECT id FROM teams WHERE name='Lakers'), 36, 40, 13, 2, 1, 4, 2, 3),
  ((SELECT id FROM matches WHERE round=2 AND home_team_id=(SELECT id FROM teams WHERE name='Bucks')),
   (SELECT id FROM players WHERE last_name='Reaves'),
   (SELECT id FROM teams WHERE name='Lakers'), 28, 24, 4, 3, 1, 0, 1, 2);

-- ===== MATCH 7: Lakers 107 vs Celtics 114 (Round 3) =====
INSERT INTO player_match_stats (match_id, player_id, team_id, minutes_played, points, rebounds, assists, steals, blocks, turnovers, fouls)
VALUES
  ((SELECT id FROM matches WHERE round=3 AND home_team_id=(SELECT id FROM teams WHERE name='Lakers')),
   (SELECT id FROM players WHERE last_name='James'),
   (SELECT id FROM teams WHERE name='Lakers'), 38, 42, 11, 8, 2, 1, 3, 2),
  ((SELECT id FROM matches WHERE round=3 AND home_team_id=(SELECT id FROM teams WHERE name='Lakers')),
   (SELECT id FROM players WHERE last_name='Davis'),
   (SELECT id FROM teams WHERE name='Lakers'), 36, 43, 15, 3, 1, 5, 2, 3),
  ((SELECT id FROM matches WHERE round=3 AND home_team_id=(SELECT id FROM teams WHERE name='Lakers')),
   (SELECT id FROM players WHERE last_name='Reaves'),
   (SELECT id FROM teams WHERE name='Lakers'), 30, 22, 4, 2, 1, 0, 1, 2),
  ((SELECT id FROM matches WHERE round=3 AND home_team_id=(SELECT id FROM teams WHERE name='Lakers')),
   (SELECT id FROM players WHERE last_name='Tatum'),
   (SELECT id FROM teams WHERE name='Celtics'), 38, 50, 12, 7, 2, 1, 3, 2),
  ((SELECT id FROM matches WHERE round=3 AND home_team_id=(SELECT id FROM teams WHERE name='Lakers')),
   (SELECT id FROM players WHERE last_name='Brown'),
   (SELECT id FROM teams WHERE name='Celtics'), 36, 40, 8, 3, 3, 0, 2, 3),
  ((SELECT id FROM matches WHERE round=3 AND home_team_id=(SELECT id FROM teams WHERE name='Lakers')),
   (SELECT id FROM players WHERE last_name='Porzingis'),
   (SELECT id FROM teams WHERE name='Celtics'), 28, 24, 14, 1, 0, 5, 1, 4);

-- ===== MATCH 8: Nuggets 118 vs Warriors 109 (Round 3) =====
INSERT INTO player_match_stats (match_id, player_id, team_id, minutes_played, points, rebounds, assists, steals, blocks, turnovers, fouls)
VALUES
  ((SELECT id FROM matches WHERE round=3 AND home_team_id=(SELECT id FROM teams WHERE name='Nuggets')),
   (SELECT id FROM players WHERE last_name='Jokic'),
   (SELECT id FROM teams WHERE name='Nuggets'), 38, 48, 18, 13, 2, 1, 2, 1),
  ((SELECT id FROM matches WHERE round=3 AND home_team_id=(SELECT id FROM teams WHERE name='Nuggets')),
   (SELECT id FROM players WHERE last_name='Murray'),
   (SELECT id FROM teams WHERE name='Nuggets'), 36, 42, 7, 9, 2, 0, 3, 2),
  ((SELECT id FROM matches WHERE round=3 AND home_team_id=(SELECT id FROM teams WHERE name='Nuggets')),
   (SELECT id FROM players WHERE last_name='Porter'),
   (SELECT id FROM teams WHERE name='Nuggets'), 30, 28, 10, 2, 1, 2, 1, 2),
  ((SELECT id FROM matches WHERE round=3 AND home_team_id=(SELECT id FROM teams WHERE name='Nuggets')),
   (SELECT id FROM players WHERE last_name='Curry'),
   (SELECT id FROM teams WHERE name='Warriors'), 38, 50, 5, 9, 3, 0, 3, 2),
  ((SELECT id FROM matches WHERE round=3 AND home_team_id=(SELECT id FROM teams WHERE name='Nuggets')),
   (SELECT id FROM players WHERE last_name='Green'),
   (SELECT id FROM teams WHERE name='Warriors'), 36, 16, 13, 10, 2, 3, 2, 4),
  ((SELECT id FROM matches WHERE round=3 AND home_team_id=(SELECT id FROM teams WHERE name='Nuggets')),
   (SELECT id FROM players WHERE last_name='Wiggins'),
   (SELECT id FROM teams WHERE name='Warriors'), 30, 43, 6, 2, 1, 1, 1, 2);

-- ===== MATCH 9: Heat 88 vs Bucks 101 (Round 3) =====
INSERT INTO player_match_stats (match_id, player_id, team_id, minutes_played, points, rebounds, assists, steals, blocks, turnovers, fouls)
VALUES
  ((SELECT id FROM matches WHERE round=3 AND home_team_id=(SELECT id FROM teams WHERE name='Heat')),
   (SELECT id FROM players WHERE last_name='Butler'),
   (SELECT id FROM teams WHERE name='Heat'), 38, 35, 9, 6, 3, 1, 2, 3),
  ((SELECT id FROM matches WHERE round=3 AND home_team_id=(SELECT id FROM teams WHERE name='Heat')),
   (SELECT id FROM players WHERE last_name='Adebayo'),
   (SELECT id FROM teams WHERE name='Heat'), 36, 32, 15, 4, 1, 3, 2, 4),
  ((SELECT id FROM matches WHERE round=3 AND home_team_id=(SELECT id FROM teams WHERE name='Heat')),
   (SELECT id FROM players WHERE last_name='Herro'),
   (SELECT id FROM teams WHERE name='Heat'), 30, 21, 4, 3, 1, 0, 2, 2),
  ((SELECT id FROM matches WHERE round=3 AND home_team_id=(SELECT id FROM teams WHERE name='Heat')),
   (SELECT id FROM players WHERE last_name='Antetokounmpo'),
   (SELECT id FROM teams WHERE name='Bucks'), 38, 46, 16, 7, 2, 3, 2, 2),
  ((SELECT id FROM matches WHERE round=3 AND home_team_id=(SELECT id FROM teams WHERE name='Heat')),
   (SELECT id FROM players WHERE last_name='Lillard'),
   (SELECT id FROM teams WHERE name='Bucks'), 36, 38, 5, 8, 2, 0, 3, 2),
  ((SELECT id FROM matches WHERE round=3 AND home_team_id=(SELECT id FROM teams WHERE name='Heat')),
   (SELECT id FROM players WHERE last_name='Middleton'),
   (SELECT id FROM teams WHERE name='Bucks'), 28, 17, 7, 4, 1, 0, 1, 3);
