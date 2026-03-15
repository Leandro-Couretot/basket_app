# Basketball Stats App

App móvil (iOS + Android) para ver standings de la NBA. Desarrollada con Flutter.

## Instalación de Flutter (primera vez)

### macOS
```bash
# 1. Descargar Flutter SDK
curl -O https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_arm64_3.19.0-stable.zip
unzip flutter_macos_arm64_3.19.0-stable.zip -d ~/development

# 2. Agregar al PATH (en ~/.zshrc o ~/.bash_profile)
export PATH="$PATH:$HOME/development/flutter/bin"

# 3. Recargar terminal
source ~/.zshrc

# 4. Verificar instalación
flutter doctor
```

### Windows
Descargar desde: https://docs.flutter.dev/get-started/install/windows

### Linux
```bash
sudo apt-get install curl git unzip xz-utils zip libglu1-mesa
curl -O https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.19.0-stable.tar.xz
tar xf flutter_linux_3.19.0-stable.tar.xz -C ~/development
export PATH="$PATH:$HOME/development/flutter/bin"
```

## Correr la app

```bash
# Clonar el repo
git clone <este-repo>
cd basketball_stats

# Instalar dependencias
flutter pub get

# Correr en emulador o dispositivo conectado
flutter run

# Correr en Chrome (para probar rápido sin emulador)
flutter run -d chrome
```

## Estructura del proyecto

```
basketball_stats/
├── lib/
│   ├── main.dart                  # Entrada de la app
│   ├── models/
│   │   └── team_standing.dart     # Modelo de datos
│   ├── screens/
│   │   └── standings_screen.dart  # Pantalla principal (standings)
│   └── utils/
│       └── csv_parser.dart        # Lector de CSV
└── assets/
    └── data/
        ├── nba_standings_east.csv  # Datos Conferencia Este
        └── nba_standings_west.csv  # Datos Conferencia Oeste
```

## Pantallas actuales

- **Standings Este/Oeste** con tabs
  - Posición, equipo, victorias, derrotas, porcentaje, diferencia
  - Últimos 10 partidos, racha actual
  - Indicador visual: verde = playoffs, azul = play-in

## Próximas pantallas (roadmap)

- [ ] Estadísticas por jugador
- [ ] Gráficos de rendimiento
- [ ] Búsqueda por equipo/jugador
- [ ] Detalle de partido

## Formato del CSV

```
pos,team,wins,losses,pct,gb,home,away,last10,streak
1,Boston Celtics,64,18,0.780,0.0,34-7,30-11,8-2,W3
```
