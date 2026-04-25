import 'package:flutter/material.dart';
import '../main.dart';
import 'shell_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  void _enter(BuildContext context, AppRole role) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => ShellScreen(role: role)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.primaryDim,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.sports_basketball, color: AppTheme.primary, size: 36),
              ),
              const SizedBox(height: 24),
              const Text(
                'BEA Stats modificado',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.5),
              ),
              const SizedBox(height: 8),
              const Text(
                '¿Con qué perfil querés entrar?',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
              ),
              const Spacer(),
              _RoleCard(
                icon: Icons.admin_panel_settings_rounded,
                title: 'Administrador',
                description: 'Cargá estadísticas, fixtures, torneos y fotos.',
                color: AppTheme.primary,
                onTap: () => _enter(context, AppRole.admin),
              ),
              const SizedBox(height: 14),
              _RoleCard(
                icon: Icons.sports_basketball_rounded,
                title: 'Jugador',
                description: 'Consultá estadísticas, posiciones y resultados.',
                color: AppTheme.accent,
                onTap: () => _enter(context, AppRole.player),
              ),
              const SizedBox(height: 14),
              _RoleCard(
                icon: Icons.sports_rounded,
                title: 'Entrenador',
                description: 'Consultá estadísticas, posiciones y resultados.',
                color: AppTheme.success,
                onTap: () => _enter(context, AppRole.player),
              ),
              const SizedBox(height: 14),
              _RoleCard(
                icon: Icons.family_restroom_rounded,
                title: 'Padre / Madre',
                description: 'Consultá estadísticas, posiciones y resultados.',
                color: const Color(0xFF3EAFD4),
                onTap: () => _enter(context, AppRole.player),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(description, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: color, size: 16),
          ],
        ),
      ),
    );
  }
}
