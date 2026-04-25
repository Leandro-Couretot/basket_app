import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';

class PlayerStatsScreen extends StatefulWidget {
  final String playerId;
  final String playerName;
  final String playerNumber;

  const PlayerStatsScreen({
    super.key,
    required this.playerId,
    required this.playerName,
    required this.playerNumber,
  });

  @override
  State<PlayerStatsScreen> createState() => _PlayerStatsScreenState();
}

class _PlayerStatsScreenState extends State<PlayerStatsScreen> {
  List<Map<String, dynamic>> _games = [];
  bool _loading = true;
  String _secondaryMetric = 'assists';

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final client = Supabase.instance.client;
    final rows = await client
        .from('player_match_stats')
        .select('''
          points, assists, rebounds, fouls,
          two_pt_made, two_pt_attempted,
          three_pt_made, three_pt_attempted,
          ft_made, ft_attempted,
          match:matches(
            id, match_date, round, home_score, away_score, status,
            home_team:teams!matches_home_team_id_fkey(id, name),
            away_team:teams!matches_away_team_id_fkey(id, name)
          ),
          team:teams(id, name)
        ''')
        .eq('player_id', widget.playerId);

    final games = List<Map<String, dynamic>>.from(rows)
      ..sort((a, b) {
        final dateA = (a['match'] as Map?)?['match_date'] as String? ?? '';
        final dateB = (b['match'] as Map?)?['match_date'] as String? ?? '';
        return dateB.compareTo(dateA);
      });

    setState(() {
      _games = games.where((g) {
        final match = g['match'] as Map?;
        return match != null && match['status'] == 'finished';
      }).toList();
      _loading = false;
    });
  }

  // Newest-first list → oldest-first for the chart
  List<Map<String, dynamic>> get _chartGames => _games.reversed.toList();

  bool _won(Map<String, dynamic> game) {
    final match = (game['match'] as Map?)?.cast<String, dynamic>();
    final myTeam = (game['team'] as Map?)?.cast<String, dynamic>();
    final homeTeam = (match?['home_team'] as Map?)?.cast<String, dynamic>();
    final isHome = myTeam?['id'] == homeTeam?['id'];
    final myScore = isHome ? (match?['home_score']) : (match?['away_score']);
    final oppScore = isHome ? (match?['away_score']) : (match?['home_score']);
    if (myScore == null || oppScore == null) return false;
    return (myScore as int) > (oppScore as int);
  }

  String _opponentShort(Map<String, dynamic> game) {
    final match = (game['match'] as Map?)?.cast<String, dynamic>();
    final myTeam = (game['team'] as Map?)?.cast<String, dynamic>();
    final homeTeam = (match?['home_team'] as Map?)?.cast<String, dynamic>();
    final awayTeam = (match?['away_team'] as Map?)?.cast<String, dynamic>();
    final isHome = myTeam?['id'] == homeTeam?['id'];
    final name = isHome ? (awayTeam?['name'] as String? ?? '-') : (homeTeam?['name'] as String? ?? '-');
    final parts = name.split(' ');
    return parts.last.length > 6 ? parts.last.substring(0, 6) : parts.last;
  }

  double _avg(String key) {
    if (_games.isEmpty) return 0;
    return _games.fold(0.0, (s, g) => s + ((g[key] as int?) ?? 0)) / _games.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('#${widget.playerNumber} ${widget.playerName}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _games.isEmpty
              ? const Center(
                  child: Text('Sin partidos registrados',
                      style: TextStyle(color: AppTheme.textSecondary)))
              : CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                        child: _AveragesRow(
                          pts: _avg('points'),
                          ast: _avg('assists'),
                          reb: _avg('rebounds'),
                          games: _games.length,
                          wins: _games.where(_won).length,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: _ChartSection(
                          games: _chartGames,
                          secondaryMetric: _secondaryMetric,
                          onMetricChanged: (m) => setState(() => _secondaryMetric = m),
                          won: _won,
                          opponentShort: _opponentShort,
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                      sliver: SliverList.separated(
                        itemCount: _games.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => _CompactGameRow(
                          game: _games[i],
                          won: _won(_games[i]),
                          opponentName: _opponentShort(_games[i]),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

// ─── Averages row ─────────────────────────────────────────────────────────────

class _AveragesRow extends StatelessWidget {
  final double pts, ast, reb;
  final int games, wins;

  const _AveragesRow({
    required this.pts, required this.ast, required this.reb,
    required this.games, required this.wins,
  });

  @override
  Widget build(BuildContext context) {
    final winPct = games > 0 ? wins / games : 0.0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'PROMEDIOS — $games PARTIDOS',
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 10,
                    fontWeight: FontWeight.w700, letterSpacing: 1.2),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$wins-${games - wins}',
                  style: const TextStyle(
                      color: AppTheme.success, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _AvgCell(label: 'PTS', value: pts, color: AppTheme.primary),
              _Divider(),
              _AvgCell(label: 'AST', value: ast, color: const Color(0xFFE74C3C)),
              _Divider(),
              _AvgCell(label: 'REB', value: reb, color: const Color(0xFF3498DB)),
              _Divider(),
              _WinPctCell(pct: winPct),
            ],
          ),
        ],
      ),
    );
  }
}

class _AvgCell extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _AvgCell({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value.toStringAsFixed(1),
              style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w800)),
          Text(label,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _WinPctCell extends StatelessWidget {
  final double pct;
  const _WinPctCell({required this.pct});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text('${(pct * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                  color: AppTheme.success, fontSize: 22, fontWeight: FontWeight.w800)),
          const Text('VIC%',
              style: TextStyle(
                  color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 36, color: AppTheme.divider);
}

// ─── Chart section ────────────────────────────────────────────────────────────

class _ChartSection extends StatelessWidget {
  final List<Map<String, dynamic>> games;
  final String secondaryMetric;
  final ValueChanged<String> onMetricChanged;
  final bool Function(Map<String, dynamic>) won;
  final String Function(Map<String, dynamic>) opponentShort;

  const _ChartSection({
    required this.games,
    required this.secondaryMetric,
    required this.onMetricChanged,
    required this.won,
    required this.opponentShort,
  });

  List<FlSpot> _spots(String key) {
    return List.generate(games.length, (i) {
      return FlSpot(i.toDouble(), ((games[i][key] as int?) ?? 0).toDouble());
    });
  }

  double get _maxY {
    final maxPts = games.fold(0.0, (m, g) => ((g['points'] as int?) ?? 0) > m ? ((g['points'] as int?) ?? 0).toDouble() : m);
    final maxSec = games.fold(0.0, (m, g) => ((g[secondaryMetric] as int?) ?? 0) > m ? ((g[secondaryMetric] as int?) ?? 0).toDouble() : m);
    return (maxPts > maxSec ? maxPts : maxSec) + 5;
  }

  @override
  Widget build(BuildContext context) {
    final secLabel = secondaryMetric == 'assists' ? 'AST' : 'REB';
    final secColor = secondaryMetric == 'assists'
        ? const Color(0xFFE74C3C)
        : const Color(0xFF3498DB);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 16, 16, 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('EVOLUCIÓN',
                  style: TextStyle(
                      color: AppTheme.textSecondary, fontSize: 10,
                      fontWeight: FontWeight.w700, letterSpacing: 1.2)),
              const Spacer(),
              _LegendDot(color: AppTheme.primary, label: 'PTS'),
              const SizedBox(width: 10),
              _LegendDot(color: secColor, label: secLabel, dashed: true),
              const SizedBox(width: 12),
              _MetricToggle(
                selected: secondaryMetric,
                onChanged: onMetricChanged,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const SizedBox(width: 4),
              _WLLegend(),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: _maxY,
                clipData: const FlClipData.all(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 10,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppTheme.divider,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: 10,
                      getTitlesWidget: (v, _) => Text(
                        '${v.toInt()}',
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 9),
                      ),
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, _) {
                        final i = value.toInt();
                        if (i < 0 || i >= games.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            opponentShort(games[i]),
                            style: const TextStyle(
                                color: AppTheme.textSecondary, fontSize: 9),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: _spots('points'),
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: AppTheme.primary,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, _, __, i) {
                        final color = won(games[i]) ? AppTheme.success : AppTheme.danger;
                        return FlDotCirclePainter(
                          radius: 5,
                          color: color,
                          strokeColor: AppTheme.surfaceElevated,
                          strokeWidth: 1.5,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppTheme.primary.withValues(alpha: 0.15),
                          AppTheme.primary.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                  LineChartBarData(
                    spots: _spots(secondaryMetric),
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: secColor,
                    barWidth: 2,
                    dashArray: [5, 4],
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                        radius: 3.5,
                        color: secColor,
                        strokeColor: AppTheme.surfaceElevated,
                        strokeWidth: 1,
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AppTheme.surface,
                    getTooltipItems: (spots) {
                      return spots.map((s) {
                        final isFirst = s.barIndex == 0;
                        return LineTooltipItem(
                          '${s.y.toInt()}',
                          TextStyle(
                            color: isFirst ? AppTheme.primary : secColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                          children: [
                            TextSpan(
                              text: isFirst ? ' PTS' : ' $secLabel',
                              style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w400),
                            ),
                          ],
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final bool dashed;

  const _LegendDot({required this.color, required this.label, this.dashed = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 2,
          decoration: BoxDecoration(
            color: dashed ? Colors.transparent : color,
            border: dashed ? Border(bottom: BorderSide(color: color, width: 2)) : null,
          ),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                color: color, fontSize: 10, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _WLLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _WLDot(color: AppTheme.success, label: 'Victoria'),
        const SizedBox(width: 10),
        _WLDot(color: AppTheme.danger, label: 'Derrota'),
      ],
    );
  }
}

class _WLDot extends StatelessWidget {
  final Color color;
  final String label;
  const _WLDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9)),
      ],
    );
  }
}

class _MetricToggle extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _MetricToggle({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleBtn(label: 'AST', value: 'assists', selected: selected, onChanged: onChanged),
          _ToggleBtn(label: 'REB', value: 'rebounds', selected: selected, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final String label, value, selected;
  final ValueChanged<String> onChanged;

  const _ToggleBtn({
    required this.label, required this.value,
    required this.selected, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accent.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.accent : AppTheme.textSecondary,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

// ─── Compact game row ─────────────────────────────────────────────────────────

class _CompactGameRow extends StatelessWidget {
  final Map<String, dynamic> game;
  final bool won;
  final String opponentName;

  const _CompactGameRow({
    required this.game,
    required this.won,
    required this.opponentName,
  });

  String _formatDate(String? raw) {
    if (raw == null) return '-';
    try {
      final dt = DateTime.parse(raw).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
    } catch (_) {
      return '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    final match = (game['match'] as Map?)?.cast<String, dynamic>();
    final myTeam = (game['team'] as Map?)?.cast<String, dynamic>();
    final homeTeam = (match?['home_team'] as Map?)?.cast<String, dynamic>();
    final isHome = myTeam?['id'] == homeTeam?['id'];
    final myScore = isHome ? (match?['home_score']) : (match?['away_score']);
    final oppScore = isHome ? (match?['away_score']) : (match?['home_score']);

    final pts = (game['points'] as int?) ?? 0;
    final ast = (game['assists'] as int?) ?? 0;
    final reb = (game['rebounds'] as int?) ?? 0;
    final fouls = (game['fouls'] as int?) ?? 0;
    final twoPtMade = (game['two_pt_made'] as int?) ?? 0;
    final twoPtAtt = (game['two_pt_attempted'] as int?) ?? 0;
    final threePtMade = (game['three_pt_made'] as int?) ?? 0;
    final threePtAtt = (game['three_pt_attempted'] as int?) ?? 0;
    final ftMade = (game['ft_made'] as int?) ?? 0;
    final ftAtt = (game['ft_attempted'] as int?) ?? 0;

    final wlColor = won ? AppTheme.success : AppTheme.danger;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: wlColor, width: 3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: wlColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  won ? 'V' : 'D',
                  style: TextStyle(color: wlColor, fontSize: 10, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'vs $opponentName',
                  style: const TextStyle(
                      color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                _formatDate(match?['match_date'] as String?),
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
              ),
              const SizedBox(width: 10),
              Text(
                myScore != null ? '$myScore - $oppScore' : '-',
                style: TextStyle(
                    color: wlColor, fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _InlineStat(label: 'PTS', value: pts, color: AppTheme.primary),
              const SizedBox(width: 6),
              _InlineStat(label: 'AST', value: ast, color: const Color(0xFFE74C3C)),
              const SizedBox(width: 6),
              _InlineStat(label: 'REB', value: reb, color: const Color(0xFF3498DB)),
              const SizedBox(width: 6),
              _InlineStat(label: 'FAL', value: fouls, color: AppTheme.textSecondary),
              const Spacer(),
              _ShootingGroup(
                twoPt: '$twoPtMade/$twoPtAtt',
                threePt: '$threePtMade/$threePtAtt',
                ft: '$ftMade/$ftAtt',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InlineStat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _InlineStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: RichText(
        text: TextSpan(children: [
          TextSpan(
              text: '$value',
              style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w800)),
          TextSpan(
              text: ' $label',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9)),
        ]),
      ),
    );
  }
}

class _ShootingGroup extends StatelessWidget {
  final String twoPt, threePt, ft;
  const _ShootingGroup({required this.twoPt, required this.threePt, required this.ft});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ShootingPill(label: '2PT', value: twoPt),
        const SizedBox(width: 6),
        _ShootingPill(label: '3PT', value: threePt),
        const SizedBox(width: 6),
        _ShootingPill(label: 'TL', value: ft),
      ],
    );
  }
}

class _ShootingPill extends StatelessWidget {
  final String label, value;
  const _ShootingPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(value,
            style: const TextStyle(
                color: AppTheme.textPrimary, fontSize: 10, fontWeight: FontWeight.w700)),
        Text(label,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 8)),
      ],
    );
  }
}
