import 'package:flutter/material.dart';
import '../main.dart';

enum _NewsType { reschedule, suspension, venue, general }

class _NewsItem {
  final String id;
  final _NewsType type;
  final String title;
  final String body;
  final String? teamName;
  final int? affectedRound;
  final DateTime date;

  const _NewsItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.teamName,
    this.affectedRound,
    required this.date,
  });
}

// Static demo news — in production these come from Supabase
final _allNews = [
  _NewsItem(
    id: '1',
    type: _NewsType.reschedule,
    title: 'Partido reprogramado — Fecha 5',
    body: 'El partido Lakers vs Heat se mueve al domingo 22/03 a las 19:00 hs por un conflicto de cancha. El horario anterior quedó sin efecto.',
    teamName: 'Lakers',
    affectedRound: 5,
    date: DateTime(2026, 4, 25),
  ),
  _NewsItem(
    id: '2',
    type: _NewsType.suspension,
    title: 'Partido suspendido — Fecha 7',
    body: 'Bulls vs Nets queda suspendido hasta nuevo aviso por problemas con el gimnasio. La nueva fecha se confirmará en los próximos días.',
    teamName: null,
    affectedRound: 7,
    date: DateTime(2026, 4, 24),
  ),
  _NewsItem(
    id: '3',
    type: _NewsType.venue,
    title: 'Cambio de sede — Fecha 6',
    body: 'Clippers vs Suns se jugará en el Gimnasio Municipal (Av. Corrientes 1234) en lugar del habitual. Recordar llevar el carnet de la liga.',
    teamName: 'Clippers',
    affectedRound: 6,
    date: DateTime(2026, 4, 23),
  ),
  _NewsItem(
    id: '4',
    type: _NewsType.general,
    title: 'Inscripciones abiertas — Temporada 2026/2027',
    body: 'Están abiertas las inscripciones para la próxima temporada. Equipos nuevos y renovaciones hasta el 30 de mayo. Contactar al administrador.',
    teamName: null,
    affectedRound: null,
    date: DateTime(2026, 4, 20),
  ),
  _NewsItem(
    id: '5',
    type: _NewsType.general,
    title: 'Actualización del reglamento de faltas',
    body: 'A partir de esta fecha, acumular 2 faltas técnicas en el mismo partido implica expulsión automática. El jugador no podrá estar en el banco.',
    teamName: null,
    affectedRound: null,
    date: DateTime(2026, 4, 18),
  ),
  _NewsItem(
    id: '6',
    type: _NewsType.reschedule,
    title: 'Partido adelantado — Fecha 8',
    body: 'Lakers vs Warriors se adelanta al sábado 25/04 a las 17:00 hs. El partido estaba programado para el domingo. Confirmar asistencia.',
    teamName: 'Lakers',
    affectedRound: 8,
    date: DateTime(2026, 4, 17),
  ),
];

// Rounds with active news — used by FixtureScreen to show badge
final affectedRounds = _allNews
    .where((n) => n.affectedRound != null)
    .map((n) => n.affectedRound!)
    .toSet();

// Team names with active news
final affectedTeams = _allNews
    .where((n) => n.teamName != null)
    .map((n) => n.teamName!)
    .toSet();

// ── Screen ────────────────────────────────────────────────────────────────────

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  String? _selectedTeam; // null = all

  List<String> get _teams {
    final teams = _allNews
        .where((n) => n.teamName != null)
        .map((n) => n.teamName!)
        .toSet()
        .toList()
      ..sort();
    return teams;
  }

  List<_NewsItem> get _filtered {
    if (_selectedTeam == null) return _allNews;
    return _allNews
        .where((n) => n.teamName == null || n.teamName == _selectedTeam)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Novedades'),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              const Icon(Icons.notifications_none_rounded, color: AppTheme.textSecondary),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppTheme.danger,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.background, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          _TeamFilter(
            teams: _teams,
            selected: _selectedTeam,
            onSelect: (t) => setState(() => _selectedTeam = _selectedTeam == t ? null : t),
          ),
          Expanded(
            child: _filtered.isEmpty
                ? const Center(
                    child: Text('Sin novedades para tu equipo', style: TextStyle(color: AppTheme.textSecondary)),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _NewsCard(item: _filtered[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Team filter chips ─────────────────────────────────────────────────────────

class _TeamFilter extends StatelessWidget {
  final List<String> teams;
  final String? selected;
  final ValueChanged<String> onSelect;

  const _TeamFilter({required this.teams, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Filtrar por equipo', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _FilterChip(label: 'Todos', selected: selected == null, onTap: () => onSelect('')),
                const SizedBox(width: 8),
                ...teams.map((t) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _FilterChip(
                        label: t,
                        selected: selected == t,
                        onTap: () => onSelect(t),
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

// ── News card ─────────────────────────────────────────────────────────────────

class _NewsCard extends StatefulWidget {
  final _NewsItem item;
  const _NewsCard({required this.item});

  @override
  State<_NewsCard> createState() => _NewsCardState();
}

class _NewsCardState extends State<_NewsCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final cfg = _typeConfig(item.type);

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cfg.color.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Type badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: cfg.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(cfg.icon, color: cfg.color, size: 11),
                      const SizedBox(width: 4),
                      Text(cfg.label, style: TextStyle(color: cfg.color, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Team badge
                if (item.teamName != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(item.teamName!, style: const TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.w600)),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.divider,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('Todos', style: TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w500)),
                  ),
                const Spacer(),
                Text(_formatDate(item.date), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
              ],
            ),
            const SizedBox(height: 10),
            Text(item.title, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(item.body, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.5)),
              ),
              crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
            if (!_expanded) ...[
              const SizedBox(height: 6),
              Text(
                item.body,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (item.affectedRound != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.calendar_today_rounded, color: cfg.color, size: 12),
                  const SizedBox(width: 4),
                  Text('Afecta Fecha ${item.affectedRound}', style: TextStyle(color: cfg.color, fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt).inDays;
    if (diff == 0) return 'Hoy';
    if (diff == 1) return 'Ayer';
    if (diff < 7) return 'Hace $diff días';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
  }
}

class _TypeConfig {
  final Color color;
  final IconData icon;
  final String label;
  const _TypeConfig(this.color, this.icon, this.label);
}

_TypeConfig _typeConfig(_NewsType type) {
  switch (type) {
    case _NewsType.reschedule:
      return const _TypeConfig(Color(0xFFF59E0B), Icons.schedule_rounded, 'REPROGRAMADO');
    case _NewsType.suspension:
      return _TypeConfig(AppTheme.danger, Icons.cancel_rounded, 'SUSPENDIDO');
    case _NewsType.venue:
      return const _TypeConfig(Color(0xFF3EAFD4), Icons.location_on_rounded, 'CAMBIO DE SEDE');
    case _NewsType.general:
      return _TypeConfig(AppTheme.success, Icons.info_outline_rounded, 'GENERAL');
  }
}
