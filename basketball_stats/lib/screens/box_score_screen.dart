import 'package:flutter/material.dart';
import '../main.dart';

class _Player {
  final int number;
  final String name;
  final int pts;
  final int reb;
  final int ast;
  final List<int> qpts;

  const _Player({
    required this.number,
    required this.name,
    required this.pts,
    required this.reb,
    required this.ast,
    required this.qpts,
  });
}

const _homeQuarterPts = [28, 24, 31, 27];
const _awayQuarterPts = [25, 26, 22, 26];

const _homePlayers = [
  _Player(number: 23, name: 'LeBron James',  pts: 28, reb: 8,  ast: 9, qpts: [8, 6, 9, 5]),
  _Player(number: 3,  name: 'A. Davis',       pts: 22, reb: 14, ast: 2, qpts: [6, 5, 7, 4]),
  _Player(number: 8,  name: 'R. Russell',     pts: 18, reb: 3,  ast: 6, qpts: [5, 5, 5, 3]),
  _Player(number: 2,  name: 'B. Ingram',      pts: 16, reb: 5,  ast: 3, qpts: [5, 4, 4, 3]),
  _Player(number: 7,  name: 'T. Prince',      pts: 14, reb: 4,  ast: 1, qpts: [4, 2, 4, 4]),
  _Player(number: 11, name: 'J. Nunn',        pts: 8,  reb: 2,  ast: 2, qpts: [0, 2, 2, 4]),
  _Player(number: 14, name: 'K. Pope',        pts: 4,  reb: 1,  ast: 0, qpts: [0, 0, 0, 4]),
];

const _awayPlayers = [
  _Player(number: 30, name: 'S. Curry',       pts: 35, reb: 5,  ast: 6, qpts: [10, 9, 8, 8]),
  _Player(number: 11, name: 'K. Thompson',    pts: 22, reb: 4,  ast: 1, qpts: [6,  6, 5, 5]),
  _Player(number: 23, name: 'D. Green',       pts: 6,  reb: 10, ast: 8, qpts: [2,  2, 1, 1]),
  _Player(number: 15, name: 'J. Wiseman',     pts: 14, reb: 8,  ast: 1, qpts: [4,  4, 3, 3]),
  _Player(number: 20, name: 'D. Lee',         pts: 12, reb: 3,  ast: 2, qpts: [3,  3, 3, 3]),
  _Player(number: 7,  name: 'E. Paschall',    pts: 7,  reb: 2,  ast: 0, qpts: [0,  2, 2, 3]),
  _Player(number: 18, name: 'A. Wiggins',     pts: 3,  reb: 3,  ast: 1, qpts: [0,  0, 0, 3]),
];

class BoxScoreScreen extends StatefulWidget {
  final String homeTeam;
  final String awayTeam;
  final int homeScore;
  final int awayScore;

  const BoxScoreScreen({
    super.key,
    required this.homeTeam,
    required this.awayTeam,
    required this.homeScore,
    required this.awayScore,
  });

  @override
  State<BoxScoreScreen> createState() => _BoxScoreScreenState();
}

class _BoxScoreScreenState extends State<BoxScoreScreen> {
  // 0 = Total, 1-4 = cuarto
  int _quarter = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('${widget.homeTeam} vs ${widget.awayTeam}'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _QuarterSelector(
            selected: _quarter,
            onSelect: (q) => setState(() => _quarter = q),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ScoreTable(
                    homeTeam: widget.homeTeam,
                    awayTeam: widget.awayTeam,
                    homeQuarterPts: _homeQuarterPts,
                    awayQuarterPts: _awayQuarterPts,
                    selectedQuarter: _quarter,
                  ),
                  const SizedBox(height: 20),
                  _TeamTable(
                    teamName: widget.homeTeam,
                    isHome: true,
                    players: _homePlayers,
                    quarter: _quarter,
                  ),
                  const SizedBox(height: 16),
                  _TeamTable(
                    teamName: widget.awayTeam,
                    isHome: false,
                    players: _awayPlayers,
                    quarter: _quarter,
                  ),
                  const SizedBox(height: 24),
                  _TeamComparisonChart(
                    homeTeam: widget.homeTeam,
                    awayTeam: widget.awayTeam,
                    quarter: _quarter,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quarter selector ──────────────────────────────────────────────────────────

class _QuarterSelector extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;

  const _QuarterSelector({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    const labels = ['Total', 'Q1', 'Q2', 'Q3', 'Q4'];
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Row(
        children: List.generate(labels.length, (i) {
          final isSelected = i == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primary : AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  labels[i],
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Score table (quarter breakdown) ──────────────────────────────────────────

class _ScoreTable extends StatelessWidget {
  final String homeTeam;
  final String awayTeam;
  final List<int> homeQuarterPts;
  final List<int> awayQuarterPts;
  final int selectedQuarter;

  const _ScoreTable({
    required this.homeTeam,
    required this.awayTeam,
    required this.homeQuarterPts,
    required this.awayQuarterPts,
    required this.selectedQuarter,
  });

  int get homeTotal => homeQuarterPts.fold(0, (a, b) => a + b);
  int get awayTotal => awayQuarterPts.fold(0, (a, b) => a + b);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(2.2),
          1: FlexColumnWidth(1),
          2: FlexColumnWidth(1),
          3: FlexColumnWidth(1),
          4: FlexColumnWidth(1),
          5: FlexColumnWidth(1.1),
        },
        children: [
          // Header
          TableRow(
            decoration: const BoxDecoration(color: AppTheme.primary),
            children: ['Equipo', 'Q1', 'Q2', 'Q3', 'Q4', 'Total']
                .asMap()
                .entries
                .map((e) => _headerCell(e.value, e.key > 0))
                .toList(),
          ),
          // Home
          _scoreRow(
            teamName: homeTeam,
            quarterPts: homeQuarterPts,
            total: homeTotal,
            won: homeTotal > awayTotal,
            selectedQuarter: selectedQuarter,
            dark: false,
          ),
          // Away
          _scoreRow(
            teamName: awayTeam,
            quarterPts: awayQuarterPts,
            total: awayTotal,
            won: awayTotal > homeTotal,
            selectedQuarter: selectedQuarter,
            dark: true,
          ),
        ],
      ),
    );
  }

  Widget _headerCell(String text, bool center) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
        child: Text(
          text,
          textAlign: center ? TextAlign.center : TextAlign.left,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      );

  TableRow _scoreRow({
    required String teamName,
    required List<int> quarterPts,
    required int total,
    required bool won,
    required int selectedQuarter,
    required bool dark,
  }) {
    final bg = dark
        ? AppTheme.background.withValues(alpha: 0.4)
        : Colors.transparent;

    // highlight the active quarter column
    List<Widget> cells = [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        child: Text(
          teamName,
          style: TextStyle(
            color: won ? AppTheme.textPrimary : AppTheme.textSecondary,
            fontWeight: won ? FontWeight.w700 : FontWeight.w500,
            fontSize: 12,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      ...List.generate(4, (i) {
        final isActiveQ = selectedQuarter == i + 1;
        return Container(
          color: isActiveQ ? AppTheme.primary.withValues(alpha: 0.15) : null,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          child: Text(
            '${quarterPts[i]}',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActiveQ ? AppTheme.primary : AppTheme.textSecondary,
              fontWeight: isActiveQ ? FontWeight.w700 : FontWeight.w400,
              fontSize: 13,
            ),
          ),
        );
      }),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        child: Text(
          '$total',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: won ? AppTheme.primary : AppTheme.textSecondary,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ),
    ];

    return TableRow(
      decoration: BoxDecoration(color: bg),
      children: cells,
    );
  }
}

// ── Team player table ─────────────────────────────────────────────────────────

class _TeamTable extends StatelessWidget {
  final String teamName;
  final bool isHome;
  final List<_Player> players;
  final int quarter; // 0=Total, 1-4=quarter

  const _TeamTable({
    required this.teamName,
    required this.isHome,
    required this.players,
    required this.quarter,
  });

  bool get isTotal => quarter == 0;

  @override
  Widget build(BuildContext context) {
    final accentColor = isHome ? AppTheme.primary : const Color(0xFF3EAFD4);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Team header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.12),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                teamName,
                style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                isHome ? 'LOCAL' : 'VISITANTE',
                style: TextStyle(
                  color: accentColor.withValues(alpha: 0.6),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        // Column headers
        Container(
          color: AppTheme.surfaceElevated,
          child: _tableRow(
            number: '#',
            name: 'Jugador',
            col1: 'PTS',
            col2: isTotal ? 'REB' : null,
            col3: isTotal ? 'AST' : null,
            isHeader: true,
            accentColor: accentColor,
          ),
        ),
        // Player rows
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceElevated,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
          ),
          child: Column(
            children: players.asMap().entries.map((e) {
              final i = e.key;
              final p = e.value;
              final pts = isTotal ? p.pts : p.qpts[quarter - 1];
              return _tableRow(
                number: '${p.number}',
                name: p.name,
                col1: '$pts',
                col2: isTotal ? '${p.reb}' : null,
                col3: isTotal ? '${p.ast}' : null,
                isHeader: false,
                accentColor: accentColor,
                dark: i.isOdd,
                isTopScorer: isTotal
                    ? p.pts == players.map((x) => x.pts).reduce((a, b) => a > b ? a : b)
                    : pts == players.map((x) => x.qpts[quarter - 1]).reduce((a, b) => a > b ? a : b),
              );
            }).toList(),
          ),
        ),
        // Totals row
        Container(
          margin: const EdgeInsets.only(top: 1),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.08),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
          ),
          child: _tableRow(
            number: '',
            name: 'TOTAL',
            col1: isTotal
                ? '${players.fold(0, (s, p) => s + p.pts)}'
                : '${players.fold(0, (s, p) => s + p.qpts[quarter - 1])}',
            col2: isTotal ? '${players.fold(0, (s, p) => s + p.reb)}' : null,
            col3: isTotal ? '${players.fold(0, (s, p) => s + p.ast)}' : null,
            isHeader: false,
            isTotal: true,
            accentColor: accentColor,
          ),
        ),
      ],
    );
  }

  Widget _tableRow({
    required String number,
    required String name,
    required String col1,
    String? col2,
    String? col3,
    required bool isHeader,
    required Color accentColor,
    bool dark = false,
    bool isTopScorer = false,
    bool isTotal = false,
  }) {
    final textColor = isHeader
        ? AppTheme.textSecondary
        : isTotal
            ? accentColor
            : AppTheme.textPrimary;
    final fontSize = isHeader ? 11.0 : 13.0;
    final fontWeight = (isHeader || isTotal) ? FontWeight.w700 : FontWeight.w400;

    return Container(
      color: dark ? AppTheme.background.withValues(alpha: 0.3) : null,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: Row(
        children: [
          // Number
          SizedBox(
            width: 24,
            child: Text(
              number,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),
          // Name
          Expanded(
            child: Row(
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: isTotal ? accentColor : textColor,
                    fontSize: fontSize,
                    fontWeight: fontWeight,
                  ),
                ),
                if (isTopScorer && !isHeader && !isTotal) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'MVP',
                      style: TextStyle(color: accentColor, fontSize: 9, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Stats columns
          _statCell(col1, textColor, fontSize, fontWeight, highlight: isTopScorer && !isHeader),
          if (col2 != null) _statCell(col2, textColor, fontSize, fontWeight),
          if (col3 != null) _statCell(col3, textColor, fontSize, fontWeight),
          // Placeholder cells to keep alignment when in quarter view (only PTS)
          if (col2 == null && !isHeader) _statCell('', Colors.transparent, fontSize, fontWeight),
          if (col3 == null && !isHeader) _statCell('', Colors.transparent, fontSize, fontWeight),
        ],
      ),
    );
  }

  Widget _statCell(String value, Color color, double size, FontWeight weight, {bool highlight = false}) {
    return SizedBox(
      width: 40,
      child: Text(
        value,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: highlight ? AppTheme.primary : color,
          fontSize: size,
          fontWeight: highlight ? FontWeight.w700 : weight,
        ),
      ),
    );
  }
}

// ── Team comparison butterfly chart ──────────────────────────────────────────

class _TeamComparisonChart extends StatelessWidget {
  final String homeTeam;
  final String awayTeam;
  final int quarter;

  const _TeamComparisonChart({
    required this.homeTeam,
    required this.awayTeam,
    required this.quarter,
  });

  static const _totalMetrics = [
    ('Puntos',          110, 99),
    ('Rebotes',          37, 35),
    ('Asistencias',      23, 19),
    ('Pts. titulares',   98, 89),
    ('Pts. banquillo',   12, 10),
    ('Pérdidas',         14, 12),
    ('Robos',             7,  5),
    ('Tapones',           3,  4),
    ('T. campo %',       47, 44),
    ('Triples %',        38, 42),
    ('T. dos %',         52, 48),
    ('T. libres %',      78, 62),
  ];

  static const _quarterMetrics = [
    // Q1: home 28 - away 25
    [
      ('Puntos',       28, 25),
      ('Rebotes',      10,  9),
      ('Asistencias',   6,  5),
      ('Pérdidas',      4,  3),
      ('Robos',         2,  1),
      ('T. campo %',   52, 48),
      ('Triples %',    40, 35),
    ],
    // Q2: home 24 - away 26
    [
      ('Puntos',       24, 26),
      ('Rebotes',       8,  9),
      ('Asistencias',   5,  6),
      ('Pérdidas',      3,  4),
      ('Robos',         1,  2),
      ('T. campo %',   44, 50),
      ('Triples %',    33, 44),
    ],
    // Q3: home 31 - away 22
    [
      ('Puntos',       31, 22),
      ('Rebotes',      10,  8),
      ('Asistencias',   7,  4),
      ('Pérdidas',      3,  5),
      ('Robos',         3,  1),
      ('T. campo %',   58, 40),
      ('Triples %',    50, 28),
    ],
    // Q4: home 27 - away 26
    [
      ('Puntos',       27, 26),
      ('Rebotes',       9,  8),
      ('Asistencias',   5,  4),
      ('Pérdidas',      4,  4),
      ('Robos',         1,  1),
      ('T. campo %',   50, 48),
      ('Triples %',    36, 38),
    ],
  ];

  List<(String, int, int)> get _metrics =>
      quarter == 0 ? _totalMetrics : _quarterMetrics[quarter - 1];

  @override
  Widget build(BuildContext context) {
    final globalMax = _metrics
        .expand((m) => [m.$2, m.$3])
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          // Header: team names + legend
          Row(
            children: [
              Expanded(
                child: Text(
                  homeTeam,
                  style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
              const SizedBox(width: 110),
              Expanded(
                child: Text(
                  awayTeam,
                  textAlign: TextAlign.right,
                  style: const TextStyle(color: Color(0xFF3EAFD4), fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: AppTheme.divider, height: 1),
          const SizedBox(height: 10),
          // Metric rows — all share the same global max scale
          ...(_metrics.map((m) => _MetricRow(
                label: m.$1,
                homeVal: m.$2,
                awayVal: m.$3,
                globalMax: globalMax,
              ))),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final int homeVal;
  final int awayVal;
  final double globalMax;

  const _MetricRow({
    required this.label,
    required this.homeVal,
    required this.awayVal,
    required this.globalMax,
  });

  @override
  Widget build(BuildContext context) {
    final homeFrac = globalMax > 0 ? homeVal / globalMax : 0.0;
    final awayFrac = globalMax > 0 ? awayVal / globalMax : 0.0;
    final homeWins = homeVal >= awayVal;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          // Home side: value then bar growing toward center
          Expanded(
            child: Row(
              children: [
                SizedBox(
                  width: 30,
                  child: Text(
                    '$homeVal',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: homeWins ? AppTheme.primary : AppTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: homeWins ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FractionallySizedBox(
                      widthFactor: homeFrac,
                      child: Container(
                        height: 13,
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            bottomLeft: Radius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Center label
          Container(
            width: 110,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
            ),
          ),
          // Away side: bar growing from center then value
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: awayFrac,
                      child: Container(
                        height: 13,
                        decoration: BoxDecoration(
                          color: const Color(0xFF3EAFD4),
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(4),
                            bottomRight: Radius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                SizedBox(
                  width: 30,
                  child: Text(
                    '$awayVal',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      color: !homeWins ? const Color(0xFF3EAFD4) : AppTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: !homeWins ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
