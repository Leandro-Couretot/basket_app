import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import '../models/team_standing.dart';

class CsvParser {
  static Future<List<TeamStanding>> loadStandings(String assetPath) async {
    final raw = await rootBundle.loadString(assetPath);
    final rows = const CsvToListConverter().convert(raw, eol: '\n');
    // Skip header row (index 0)
    return rows.skip(1).map((row) => TeamStanding.fromCsvRow(row)).toList()
      ..sort((a, b) => a.pos.compareTo(b.pos));
  }
}
