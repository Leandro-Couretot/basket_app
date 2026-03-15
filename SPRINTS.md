# BEA – Basketball Stats App · Sprint Tracker

App Flutter Web para la liga **Básquet Entre Amigos (BEA)**.
Referencia: Basketball Stats Assistant (Google Play).

---

## Sprint 1 – Fundación
**Objetivo:** Estructura base de la app: navegación, pantallas placeholder, tema visual moderno, y modelos de datos core.

### Tareas
- [ ] Renombrar app de "NBA Stats" a "BEA Stats"
- [ ] Definir paleta de colores y tema global (moderno, dark mode)
- [ ] Crear navegación principal con bottom nav bar (Dashboard, Fixture, Standings, Equipos)
- [ ] Pantallas placeholder para cada sección
- [ ] Definir modelos de datos: `Team`, `Player`, `Match`, `Season`
- [ ] Estructura de carpetas: `models/`, `screens/`, `widgets/`, `services/`
- [ ] Setup de backend/base de datos (Firebase o Supabase)

---

## Sprint 2 – Equipos y Jugadores
**Objetivo:** Gestión completa de equipos y rosters. El usuario puede ver equipos, buscar, y explorar jugadores.

### User Stories cubiertas
- US 1.1 (parcial): Cargar equipos y jugadores

### Tareas
- [ ] Pantalla de listado de equipos con **search box free text** (mejora vs app actual)
- [ ] Pantalla de detalle de equipo (logo, nombre, roster)
- [ ] Pantalla de roster con lista de jugadores (nº, nombre, posición)
- [ ] Pantalla de perfil de jugador (stats promedio, temporada)
- [ ] Selector de temporada en perfil de jugador
- [ ] CRUD de equipos (alta/baja/modificación) para administradores
- [ ] CRUD de jugadores

---

## Sprint 3 – Partidos y Box Score
**Objetivo:** Registro de partidos y visualización de estadísticas básicas.

### User Stories cubiertas
- US 1.2: Estadísticas básicas por jugador
- US 1.3: Consultar información histórica

### Tareas
- [ ] Modelo de datos completo de partido y box score
- [ ] Pantalla de detalle de partido (resultado, fecha, equipos)
- [ ] Box score básico: MIN, PTS, REB, AST, FGM/FGA, 3PM/3PA, FTM/FTA
- [ ] Box score avanzado: TOV, STL, BLK, PF, PIR (valoración)
- [ ] Stats de **ambos equipos** (mejora vs app actual que solo muestra ganador)
- [ ] Tabs en box score: Box Score / Puntos / Líderes / Equipos / Avanzadas
- [ ] Gráfico comparativo de partido (barras horizontales por categoría)
- [ ] Filtro por cuarto (Q1/Q2/Q3/Q4/TODOS)
- [ ] Link compartible de stats en tiempo real post-partido

---

## Sprint 4 – Acta Digital
**Objetivo:** Registro digital oficial de partidos con todos los datos requeridos.

### User Stories cubiertas
- US 1.1: Cargar equipos, jugadores y árbitros en el acta
- US 1.2: Ingresar estadísticas básicas por jugador
- US 1.3: Consultar actas históricas

### Criterios de aceptación
- Datos persistentes sin límite de 3 meses
- Exportable a PDF

### Tareas
- [ ] Formulario de creación de acta (equipos, árbitros, fecha, cancha)
- [ ] Carga de stats por jugador durante/post partido
- [ ] Validaciones del acta (jugadores mínimos, datos obligatorios)
- [ ] Almacenamiento histórico (≥ 1 año sin borrado)
- [ ] Exportar acta a PDF
- [ ] Compartir acta por link

---

## Sprint 5 – Fixture y Tabla de Posiciones
**Objetivo:** Calendario del torneo actualizado y standings dinámicos.

### User Stories cubiertas
- US 2.1: Cargar fixture completo
- US 2.4: Ver resultados históricos
- US 3.1: Auto-actualización de posiciones
- US 3.2: Tabla con PJ, PG, PP, PF, PC, diferencia
- US 3.3: Historial de posiciones por fecha

### Criterios de aceptación
- Tabla actualizada en tiempo real tras cada partido
- Filtro por torneo

### Tareas
- [ ] Pantalla de fixture (lista de fechas, horarios, rivales)
- [ ] Vista de partido próximo vs partido jugado
- [ ] Tabla de posiciones dinámica con columnas: PJ, PG, PP, PF, PC, DIF
- [ ] Auto-actualización de standings al cargar resultado
- [ ] Filtro de fixture/standings por torneo
- [ ] Historial de posiciones por fecha

---

## Sprint 6 – Multimedia y Redes Sociales
**Objetivo:** Integración de fotos de partidos y publicación automática en RRSS.

### User Stories cubiertas
- US 2.2: Adjuntar fotos al fixture
- US 2.3: Auto-publicar en RRSS con hashtags

### Criterios de aceptación
- Fotos en repositorio seguro y optimizado
- Integración automática y programable con RRSS

### Tareas
- [ ] Upload de fotos asociadas a partidos/fixture
- [ ] Galería de fotos por partido
- [ ] Generación automática de imagen de resultado para compartir
- [ ] Integración con Instagram / Twitter (hashtags #BEA + nombre torneo)
- [ ] Programación de publicaciones automáticas

---

## Sprint 7 – Pulido y Performance
**Objetivo:** UX final, optimizaciones y preparación para producción.

### Tareas
- [ ] Roles de usuario: Administrador, Entrenador, Jugador, Padre/Madre, Club
- [ ] Onboarding de selección de rol (primera vez)
- [ ] Diseño responsive (mobile + web)
- [ ] Optimización de consultas a base de datos
- [ ] Tests básicos
- [ ] Preparar arquitectura para otros deportes (extensibilidad)

---

## Notas técnicas
- **Stack:** Flutter Web + Firebase/Supabase
- **Deploy:** Netlify (ya configurado)
- **Historial mínimo:** 1 año de datos
- **Arquitectura:** preparada para escalar a otros deportes
