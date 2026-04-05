import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import 'live_stats_screen.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Panel Admin')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionLabel('Torneo'),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _ActionCard(
                icon: Icons.emoji_events_rounded,
                color: const Color(0xFFF39C12),
                title: 'Crear torneo',
                description: 'Nuevo torneo o temporada',
                onTap: () => _showCrearTorneo(context),
              )),
              const SizedBox(width: 10),
              Expanded(child: _ActionCard(
                icon: Icons.calendar_month_rounded,
                color: const Color(0xFF3498DB),
                title: 'Agregar partido',
                description: 'Sumar fecha al fixture',
                onTap: () => _showAgregarPartido(context),
              )),
            ]),
            const SizedBox(height: 24),
            _SectionLabel('Partido'),
            const SizedBox(height: 10),
            _ActionCard(
              icon: Icons.sports_score_rounded,
              color: AppTheme.primary,
              title: 'Acta en Vivo',
              description: 'Cargá stats en tiempo real con +/-',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LiveStatsScreen())),
            ),
            const SizedBox(height: 10),
            _ActionCard(
              icon: Icons.photo_camera_rounded,
              color: const Color(0xFF9B59B6),
              title: 'Fotos del partido',
              description: 'Subir y compartir fotos',
              onTap: () => _showSubirFotos(context),
            ),
            const SizedBox(height: 24),
            _SectionLabel('Plantilla'),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _ActionCard(
                icon: Icons.shield_rounded,
                color: const Color(0xFF2ECC71),
                title: 'Nuevo equipo',
                description: 'Registrar un equipo',
                onTap: () => _showNuevoEquipo(context),
              )),
              const SizedBox(width: 10),
              Expanded(child: _ActionCard(
                icon: Icons.person_add_rounded,
                color: const Color(0xFF1ABC9C),
                title: 'Nuevo jugador',
                description: 'Agregar jugador al equipo',
                onTap: () => _showNuevoJugador(context),
              )),
            ]),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ─── Section label ───────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2),
      );
}

// ─── Action card ─────────────────────────────────────────────────────────────

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _ActionCard({required this.icon, required this.color, required this.title, required this.description, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(description, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

// ─── Shared modal helpers ─────────────────────────────────────────────────────

void _showModal(BuildContext context, {required String title, required Widget child}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppTheme.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (_, scroll) => Column(children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.divider, borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(children: [
              Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
            ]),
          ),
          const Divider(height: 1),
          Expanded(child: SingleChildScrollView(controller: scroll, padding: const EdgeInsets.all(20), child: child)),
        ]),
      ),
    ),
  );
}

InputDecoration _inputDeco(String label, {String? hint}) => InputDecoration(
  labelText: label,
  hintText: hint,
  labelStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
  hintStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
  filled: true,
  fillColor: AppTheme.surfaceElevated,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
);

Widget _saveButton(String label, VoidCallback onTap) => SizedBox(
  width: double.infinity,
  child: ElevatedButton(
    onPressed: onTap,
    style: ElevatedButton.styleFrom(
      backgroundColor: AppTheme.primary,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
  ),
);

void _showSuccess(BuildContext context, String msg) {
  Navigator.pop(context);
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg),
    backgroundColor: AppTheme.success,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  ));
}

// ─── Crear torneo ─────────────────────────────────────────────────────────────

void _showCrearTorneo(BuildContext context) {
  _showModal(context, title: 'Crear torneo', child: _CrearTorneoForm());
}

class _CrearTorneoForm extends StatefulWidget {
  @override
  State<_CrearTorneoForm> createState() => _CrearTorneoFormState();
}

class _CrearTorneoFormState extends State<_CrearTorneoForm> {
  final _nombre = TextEditingController();
  final _inicio = TextEditingController();
  final _fin = TextEditingController();
  bool _saving = false;

  @override
  void dispose() { _nombre.dispose(); _inicio.dispose(); _fin.dispose(); super.dispose(); }

  DateTime? _parseDate(String s) {
    try {
      final parts = s.split('/');
      return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
    } catch (_) { return null; }
  }

  Future<void> _save() async {
    if (_nombre.text.isEmpty) return;
    setState(() => _saving = true);
    try {
      await Supabase.instance.client.from('seasons').insert({
        'name': _nombre.text.trim(),
        'start_date': _parseDate(_inicio.text)?.toIso8601String().substring(0, 10),
        'end_date': _parseDate(_fin.text)?.toIso8601String().substring(0, 10),
        'is_active': false,
      });
      if (mounted) _showSuccess(context, 'Torneo "${_nombre.text}" creado');
    } catch (e) {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      TextField(controller: _nombre, style: const TextStyle(color: AppTheme.textPrimary), decoration: _inputDeco('Nombre del torneo', hint: 'Ej: Apertura 2026')),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: TextField(controller: _inicio, style: const TextStyle(color: AppTheme.textPrimary), decoration: _inputDeco('Fecha inicio', hint: 'DD/MM/AAAA'))),
        const SizedBox(width: 10),
        Expanded(child: TextField(controller: _fin, style: const TextStyle(color: AppTheme.textPrimary), decoration: _inputDeco('Fecha fin', hint: 'DD/MM/AAAA'))),
      ]),
      const SizedBox(height: 20),
      _saving ? const Center(child: CircularProgressIndicator(color: AppTheme.primary)) : _saveButton('Crear torneo', _save),
    ]);
  }
}

// ─── Agregar partido ──────────────────────────────────────────────────────────

void _showAgregarPartido(BuildContext context) {
  _showModal(context, title: 'Agregar partido', child: _AgregarPartidoForm());
}

class _AgregarPartidoForm extends StatefulWidget {
  @override
  State<_AgregarPartidoForm> createState() => _AgregarPartidoFormState();
}

class _AgregarPartidoFormState extends State<_AgregarPartidoForm> {
  List<Map<String, dynamic>> _teams = [];
  String? _homeId, _awayId, _seasonId;
  final _fecha = TextEditingController();
  final _hora = TextEditingController();
  final _fecha_num = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final client = Supabase.instance.client;
    final teams = await client.from('teams').select('id, name').order('name');
    final season = await client.from('seasons').select('id').eq('is_active', true).maybeSingle();
    setState(() {
      _teams = List<Map<String, dynamic>>.from(teams);
      _seasonId = season?['id'] as String?;
    });
  }

  Future<void> _save() async {
    if (_homeId == null || _awayId == null || _homeId == _awayId) return;
    setState(() => _saving = true);
    try {
      DateTime? matchDate;
      try {
        final parts = _fecha.text.split('/');
        final timeParts = _hora.text.split(':');
        matchDate = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]),
            timeParts.isNotEmpty ? int.parse(timeParts[0]) : 20, timeParts.length > 1 ? int.parse(timeParts[1]) : 0);
      } catch (_) {}

      await Supabase.instance.client.from('matches').insert({
        'season_id': _seasonId,
        'home_team_id': _homeId,
        'away_team_id': _awayId,
        'round': int.tryParse(_fecha_num.text) ?? 1,
        'match_date': matchDate?.toIso8601String(),
        'status': 'scheduled',
        'home_score': 0,
        'away_score': 0,
      });
      if (mounted) _showSuccess(context, 'Partido agregado al fixture');
    } catch (e) {
      setState(() => _saving = false);
    }
  }

  @override
  void dispose() { _fecha.dispose(); _hora.dispose(); _fecha_num.dispose(); super.dispose(); }

  Widget _teamDropdown(String label, String? value, void Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: AppTheme.surfaceElevated,
      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
      decoration: _inputDeco(label),
      items: _teams.map((t) => DropdownMenuItem(value: t['id'] as String, child: Text(t['name'] as String))).toList(),
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _teamDropdown('Local', _homeId, (v) => setState(() => _homeId = v)),
      const SizedBox(height: 12),
      _teamDropdown('Visitante', _awayId, (v) => setState(() => _awayId = v)),
      const SizedBox(height: 12),
      TextField(controller: _fecha_num, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], style: const TextStyle(color: AppTheme.textPrimary), decoration: _inputDeco('Número de fecha', hint: 'Ej: 4')),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: TextField(controller: _fecha, style: const TextStyle(color: AppTheme.textPrimary), decoration: _inputDeco('Fecha', hint: 'DD/MM/AAAA'))),
        const SizedBox(width: 10),
        Expanded(child: TextField(controller: _hora, style: const TextStyle(color: AppTheme.textPrimary), decoration: _inputDeco('Hora', hint: 'HH:MM'))),
      ]),
      const SizedBox(height: 20),
      _saving ? const Center(child: CircularProgressIndicator(color: AppTheme.primary)) : _saveButton('Agregar partido', _save),
    ]);
  }
}

// ─── Subir fotos ──────────────────────────────────────────────────────────────

void _showSubirFotos(BuildContext context) {
  _showModal(context, title: 'Fotos del partido', child: _SubirFotosForm());
}

class _SubirFotosForm extends StatefulWidget {
  @override
  State<_SubirFotosForm> createState() => _SubirFotosFormState();
}

class _SubirFotosFormState extends State<_SubirFotosForm> {
  List<Map<String, dynamic>> _matches = [];
  String? _selectedMatchId;
  bool _shareInstagram = false;
  bool _shareFacebook = false;
  final _hashtags = TextEditingController(text: '#BEA #basquet');
  int _photoCount = 0;

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  @override
  void dispose() { _hashtags.dispose(); super.dispose(); }

  Future<void> _loadMatches() async {
    final matches = await Supabase.instance.client
        .from('matches')
        .select('id, round, home_team:teams!matches_home_team_id_fkey(name), away_team:teams!matches_away_team_id_fkey(name)')
        .eq('status', 'finished')
        .order('match_date', ascending: false);
    setState(() => _matches = List<Map<String, dynamic>>.from(matches));
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      DropdownButtonFormField<String>(
        value: _selectedMatchId,
        dropdownColor: AppTheme.surfaceElevated,
        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
        decoration: _inputDeco('Partido'),
        items: _matches.map((m) {
          final home = (m['home_team'] as Map)['name'] as String;
          final away = (m['away_team'] as Map)['name'] as String;
          return DropdownMenuItem(value: m['id'] as String, child: Text('F${m['round']} · $home vs $away'));
        }).toList(),
        onChanged: (v) => setState(() => _selectedMatchId = v),
      ),
      const SizedBox(height: 20),
      const Text('FOTOS', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
      const SizedBox(height: 10),
      GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        children: [
          ...List.generate(_photoCount, (i) => Container(
            decoration: BoxDecoration(color: AppTheme.surfaceElevated, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.image_rounded, color: AppTheme.textSecondary, size: 32),
          )),
          if (_photoCount < 9)
            GestureDetector(
              onTap: () => setState(() => _photoCount++),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.divider, style: BorderStyle.solid),
                ),
                child: const Icon(Icons.add_photo_alternate_rounded, color: AppTheme.primary, size: 32),
              ),
            ),
        ],
      ),
      const SizedBox(height: 20),
      const Text('COMPARTIR EN REDES', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
      const SizedBox(height: 8),
      _SocialToggle(icon: Icons.camera_alt_rounded, label: 'Instagram', color: const Color(0xFFE1306C), value: _shareInstagram, onChanged: (v) => setState(() => _shareInstagram = v)),
      const SizedBox(height: 8),
      _SocialToggle(icon: Icons.facebook_rounded, label: 'Facebook', color: const Color(0xFF1877F2), value: _shareFacebook, onChanged: (v) => setState(() => _shareFacebook = v)),
      if (_shareInstagram || _shareFacebook) ...[
        const SizedBox(height: 12),
        TextField(
          controller: _hashtags,
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
          decoration: _inputDeco('Hashtags', hint: '#BEA #basquet #torneo'),
        ),
      ],
      const SizedBox(height: 20),
      _saveButton(
        _shareInstagram || _shareFacebook ? 'Subir y compartir' : 'Subir fotos',
        () => _showSuccess(context, _photoCount > 0 ? 'Fotos subidas exitosamente' : 'Seleccioná al menos una foto'),
      ),
    ]);
  }
}

class _SocialToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SocialToggle({required this.icon, required this.label, required this.color, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: AppTheme.surfaceElevated, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
        const Spacer(),
        Switch(value: value, onChanged: onChanged, activeColor: color),
      ]),
    );
  }
}

// ─── Nuevo equipo ─────────────────────────────────────────────────────────────

void _showNuevoEquipo(BuildContext context) {
  _showModal(context, title: 'Nuevo equipo', child: _NuevoEquipoForm());
}

class _NuevoEquipoForm extends StatefulWidget {
  @override
  State<_NuevoEquipoForm> createState() => _NuevoEquipoFormState();
}

class _NuevoEquipoFormState extends State<_NuevoEquipoForm> {
  final _nombre = TextEditingController();
  final _ciudad = TextEditingController();
  bool _saving = false;

  @override
  void dispose() { _nombre.dispose(); _ciudad.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (_nombre.text.isEmpty) return;
    setState(() => _saving = true);
    try {
      await Supabase.instance.client.from('teams').insert({
        'name': _nombre.text.trim(),
        'city': _ciudad.text.trim().isEmpty ? null : _ciudad.text.trim(),
      });
      if (mounted) _showSuccess(context, 'Equipo "${_nombre.text}" creado');
    } catch (e) {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      TextField(controller: _nombre, style: const TextStyle(color: AppTheme.textPrimary), decoration: _inputDeco('Nombre del equipo', hint: 'Ej: Los Pumas BC')),
      const SizedBox(height: 12),
      TextField(controller: _ciudad, style: const TextStyle(color: AppTheme.textPrimary), decoration: _inputDeco('Ciudad', hint: 'Ej: Buenos Aires')),
      const SizedBox(height: 20),
      _saving ? const Center(child: CircularProgressIndicator(color: AppTheme.primary)) : _saveButton('Crear equipo', _save),
    ]);
  }
}

// ─── Nuevo jugador ────────────────────────────────────────────────────────────

void _showNuevoJugador(BuildContext context) {
  _showModal(context, title: 'Nuevo jugador', child: _NuevoJugadorForm());
}

class _NuevoJugadorForm extends StatefulWidget {
  @override
  State<_NuevoJugadorForm> createState() => _NuevoJugadorFormState();
}

class _NuevoJugadorFormState extends State<_NuevoJugadorForm> {
  final _nombre = TextEditingController();
  final _apellido = TextEditingController();
  final _numero = TextEditingController();
  List<Map<String, dynamic>> _teams = [];
  String? _teamId;
  String? _position;
  bool _saving = false;

  final _positions = ['PG', 'SG', 'SF', 'PF', 'C'];

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  Future<void> _loadTeams() async {
    final teams = await Supabase.instance.client.from('teams').select('id, name').order('name');
    setState(() => _teams = List<Map<String, dynamic>>.from(teams));
  }

  Future<void> _save() async {
    if (_nombre.text.isEmpty || _apellido.text.isEmpty || _teamId == null) return;
    setState(() => _saving = true);
    try {
      await Supabase.instance.client.from('players').insert({
        'team_id': _teamId,
        'first_name': _nombre.text.trim(),
        'last_name': _apellido.text.trim(),
        'number': int.tryParse(_numero.text),
        'position': _position,
      });
      if (mounted) _showSuccess(context, '${_nombre.text} ${_apellido.text} agregado');
    } catch (e) {
      setState(() => _saving = false);
    }
  }

  @override
  void dispose() { _nombre.dispose(); _apellido.dispose(); _numero.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      DropdownButtonFormField<String>(
        value: _teamId,
        dropdownColor: AppTheme.surfaceElevated,
        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
        decoration: _inputDeco('Equipo'),
        items: _teams.map((t) => DropdownMenuItem(value: t['id'] as String, child: Text(t['name'] as String))).toList(),
        onChanged: (v) => setState(() => _teamId = v),
      ),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: TextField(controller: _nombre, style: const TextStyle(color: AppTheme.textPrimary), decoration: _inputDeco('Nombre'))),
        const SizedBox(width: 10),
        Expanded(child: TextField(controller: _apellido, style: const TextStyle(color: AppTheme.textPrimary), decoration: _inputDeco('Apellido'))),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: TextField(
          controller: _numero,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: _inputDeco('Número', hint: 'Ej: 23'),
        )),
        const SizedBox(width: 10),
        Expanded(child: DropdownButtonFormField<String>(
          value: _position,
          dropdownColor: AppTheme.surfaceElevated,
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
          decoration: _inputDeco('Posición'),
          items: _positions.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
          onChanged: (v) => setState(() => _position = v),
        )),
      ]),
      const SizedBox(height: 20),
      _saving ? const Center(child: CircularProgressIndicator(color: AppTheme.primary)) : _saveButton('Agregar jugador', _save),
    ]);
  }
}
