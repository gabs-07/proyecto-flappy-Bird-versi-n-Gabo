# 🐦 Flappy Bird Adventure

Clon avanzado de Flappy Bird construido en **Flutter / Dart** con modo día y noche, obstáculos, power-ups, monedas, skins y logros. Funciona en Android, iOS, Windows, macOS, Linux y Web.

---

## 📋 Tabla de contenido

1. [Requisitos](#requisitos)
2. [Instalación y ejecución](#instalación-y-ejecución)
3. [Estructura del proyecto](#estructura-del-proyecto)
4. [Assets necesarios](#assets-necesarios)
5. [Cómo jugar](#cómo-jugar)
6. [Sistema de niveles y modo noche](#sistema-de-niveles-y-modo-noche)
7. [Obstáculos nocturnos](#obstáculos-nocturnos)
8. [Monedas y power-ups](#monedas-y-power-ups)
9. [Skins](#skins)
10. [Logros](#logros)
11. [Pulido visual](#pulido-visual)
12. [Ajustar dificultad](#ajustar-dificultad)
13. [Generar APK para Android](#generar-apk-para-android)
14. [Historial de versiones](#historial-de-versiones)
15. [Créditos](#créditos)

---

## Requisitos

| Herramienta | Versión mínima | Cómo instalar |
|---|---|---|
| Flutter SDK | 3.22+ | [flutter.dev/install](https://flutter.dev/install) |
| Dart SDK | 3.11+ | incluido con Flutter |
| Android Studio | 2023+ | para Android / emulador |
| Xcode | 15+ | solo para iOS/macOS (requiere Mac) |

Verifica tu instalación con:

```bash
flutter doctor
```

Todos los ítems deben estar en ✓ verde. El más común que falla es **Android licenses**; corrígelo con:

```bash
flutter doctor --android-licenses
```

---

## Instalación y ejecución

### 1. Instalar dependencias

```bash
cd poryectofinal
flutter pub get
```

### 2. Ejecutar en cada plataforma

```bash
# Ver dispositivos disponibles
flutter devices

# Android (celular conectado por USB o emulador)
flutter run -d android

# iOS (requiere Mac + Xcode + iPhone conectado)
flutter run -d ios

# Windows
flutter run -d windows

# macOS
flutter run -d macos

# Web (Chrome)
flutter run -d chrome

# Linux
flutter run -d linux
```

### 3. Modo release (más rápido, sin debug)

```bash
flutter run --release
```

### Solución de errores comunes

**`SDK location not found`** → Abre Android Studio → SDK Manager → copia la ruta del SDK → crea el archivo `android/local.properties` con:
```
sdk.dir=/ruta/al/android/sdk
```

**`Gradle build failed`** → Corre `flutter clean` y luego `flutter pub get`.

**`CocoaPods not installed`** (iOS/macOS) → Corre `sudo gem install cocoapods && pod setup`.

**`MissingPluginException: audioplayers`** → Los assets de audio son opcionales. Si no tienes los archivos `.mp3`, comenta las líneas de `assets/audio/` en `pubspec.yaml`.

---

## Estructura del proyecto

```
poryectofinal/
├── lib/
│   ├── main.dart                      # Punto de entrada, Provider, SystemChrome
│   │
│   ├── game/                          # Lógica pura del juego (sin UI)
│   │   ├── bird.dart                  # Modelo del pájaro: física, animación, rotación
│   │   ├── pipe.dart                  # Modelo de un par de tubos con gap
│   │   ├── obstacle.dart              # 5 tipos de obstáculos nocturnos con movimiento
│   │   ├── coin.dart                  # Moneda coleccionable con bobbing
│   │   ├── powerup_item.dart          # Ítem de power-up flotante en pantalla
│   │   ├── skin.dart                  # Definición de los 6 skins del pájaro
│   │   ├── achievement.dart           # Catálogo de los 10 logros
│   │   └── game_logic.dart            # Constantes, colisiones, niveles, dificultad
│   │
│   ├── providers/
│   │   └── game_provider.dart         # Estado central (ChangeNotifier): todo el game loop
│   │
│   ├── audio/
│   │   └── audio_controller.dart      # Wrapper de audioplayers para salto/puntos/hit/bgm
│   │
│   └── ui/                            # Pantallas y widgets visuales
│       ├── game_screen.dart           # Pantalla principal: capas, input, shake
│       ├── start_screen.dart          # Pantalla de inicio con bounce + tienda
│       ├── game_over_screen.dart      # Panel de Game Over con animación
│       ├── shop_screen.dart           # Tienda de skins con grid y preview
│       ├── achievement_toast.dart     # Toast animado de logro desbloqueado
│       ├── intro_animation.dart       # Animación de entrada al abrir la app
│       └── parallax_background.dart   # 3 capas de parallax (montañas, nubes, arbustos)
│
├── assets/
│   ├── images/
│   │   ├── background.png             # Fondo de día  288×512
│   │   ├── ground.png                 # Suelo de día  336×112
│   │   ├── pipe_top.png               # Tubo superior  80×320
│   │   ├── pipe_bottom.png            # Tubo inferior  80×320
│   │   ├── pipe_cap.png               # Capucha del tubo  96×28
│   │   ├── bird_1.png … bird_3.png    # Frames de aleteo día  68×48
│   │   ├── bird_dead.png              # Pájaro muerto día  68×48
│   │   │
│   │   ├── night/                     # Sprites del modo noche
│   │   │   ├── background_night.png   # Cielo nocturno con luna y estrellas  288×512
│   │   │   ├── ground_night.png       # Suelo nocturno con luciérnagas  336×112
│   │   │   ├── pipe_top_night.png     # Tubo superior noche  80×320
│   │   │   ├── pipe_bottom_night.png  # Tubo inferior noche  80×320
│   │   │   └── bird_night_0..3.png    # Frames noche + dead  68×48
│   │   │
│   │   ├── obstacles/                 # Sprites de obstáculos nocturnos
│   │   │   ├── meteor.png             # Meteorito  96×120
│   │   │   ├── bat_enemy.png          # Murciélago  120×70
│   │   │   ├── laser_barrier.png      # Láser doble  200×80
│   │   │   ├── ufo_enemy.png          # OVNI  140×110
│   │   │   └── ghost_enemy.png        # Fantasma  90×120
│   │   │
│   │   └── skins/                     # Sprites de skins (opcionales, hay fallback)
│   │       ├── bird_yellow_0..3.png + bird_yellow_dead.png
│   │       ├── bird_red_0..3.png + bird_red_dead.png
│   │       ├── bird_blue_0..3.png + bird_blue_dead.png
│   │       ├── bird_ninja_0..3.png + bird_ninja_dead.png
│   │       ├── bird_astro_0..3.png + bird_astro_dead.png
│   │       └── bird_dark_0..3.png + bird_dark_dead.png
│   │
│   └── audio/                         # Efectos de sonido (opcionales)
│       ├── game-jump.mp3
│       ├── game-over.mp3
│       └── musica_de_fondo.mp3
│
└── pubspec.yaml                       # Dependencias y declaración de assets
```

> **Nota:** Todos los sprites tienen **fallback dibujado con `CustomPainter`**. El juego corre aunque no tengas los archivos PNG.

---

## Assets necesarios

Los assets de los ZIPs entregados se organizan así dentro del proyecto:

| ZIP entregado | Carpeta destino |
|---|---|
| `flappy_bird_pro_con_sprites.zip` | `assets/images/` (sprites de día) |
| `flappy_night_pack.zip` | `assets/images/night/` y `assets/images/obstacles/` |
| `flappy_skins_sprites.zip` | `assets/images/skins/` y `assets/images/ui/` |

Si no tienes los sprites, el juego igual funciona con los fallbacks procedurales.

---

## Cómo jugar

### Controles

| Acción | Teclado | Móvil / Mouse |
|---|---|---|
| Saltar / Volar | `ESPACIO` o `↑` | Tap / Click |
| Pausar / Reanudar | `P` o `ESC` | Botón ⏸ en el HUD |
| Silenciar | `M` | Botón 🔊 en el HUD |
| Abrir tienda | — | Botón en pantalla de inicio |

### Objetivo

Vuela esquivando los tubos verdes. Cada tubo que superas vale **1 punto** (o 2 si tienes el power-up ×2 activo). El juego termina si tocas un tubo, el suelo, el techo o un obstáculo nocturno (sin escudo).

### Pantalla de inicio

- Muestra tu récord histórico
- Indica el skin activo
- Botón **TIENDA** para comprar skins con monedas

### Pantalla de Game Over

Muestra puntos de la partida, récord histórico, monedas ganadas en esa partida, nivel alcanzado y cuántos logros tienes desbloqueados.

---

## Sistema de niveles y modo noche

El nivel sube automáticamente cada 5 puntos:

| Puntuación | Nivel | Qué ocurre |
|---|---|---|
| 0 – 4 | 0 | Modo día, solo tubos |
| **5 – 9** | **1** | **🌙 Modo noche activa** — cielo oscurece, luna aparece, tubos cambian, meteoritos y murciélagos |
| 10 – 14 | 2 | + Láser parpadeante |
| 15 – 19 | 3 | + OVNI con rayo tractor |
| 25+ | 5 | + Fantasma semi-transparente |

La transición día → noche es gradual: el cielo, suelo, tubos y pájaro cambian de color suavemente durante varios segundos.

---

## Obstáculos nocturnos

| Obstáculo | Patrón de movimiento | Hitbox | Aparece desde |
|---|---|---|---|
| ☄️ **Meteorito** | Diagonal + rotación, cae hacia abajo | Círculo r≈30px | Nivel 1 |
| 🦇 **Murciélago** | Horizontal + zigzag sinusoidal en Y | Elipse 80×40px | Nivel 1 |
| 🔴 **Láser doble** | Horizontal lento, **parpadea** ON 1.5s / OFF 0.8s | 2 rect. de 4px de alto | Nivel 2 |
| 🛸 **OVNI** | Horizontal muy lento + flotación suave | Elipse 140×30px + rayo abajo | Nivel 3 |
| 👻 **Fantasma** | Horizontal + zigzag rápido, **semi-transparente** | Círculo r reducido (55% hitbox) | Nivel 5 |

El **escudo** absorbe cualquier colisión con obstáculo o tubo (no con el suelo). Tras absorber el golpe desaparece.

---

## Monedas y power-ups

### Monedas 💰

- Aparecen cada **3 segundos** en grupos de 1–3 monedas encadenadas
- Flotan con un bobbing suave
- Se recogen por proximidad al pájaro
- Se acumulan entre partidas (persistentes)
- Sirven para comprar skins en la tienda
- El contador de sesión se muestra en la esquina superior izquierda durante el juego
- Al morir, las monedas de la sesión se suman al total y se muestran en el panel de Game Over

### Power-ups ⚡

Aparecen como ítems flotantes cada **12 segundos**. Se activan al tocarlos.

| Power-up | Duración | Efecto |
|---|---|---|
| 🛡 **Escudo** | 5 segundos | Absorbe 1 colisión con tubo u obstáculo. Visible como aura azul alrededor del pájaro |
| ⏱ **Slow-Motion** | 5 segundos | Reduce la velocidad de todo al 45%. El pájaro también va más lento |
| ×2 **Doble Puntos** | 8 segundos | Cada tubo vale 2 puntos. El score se pone dorado |

Los power-ups activos muestran una **barra de tiempo** en la parte inferior de la pantalla con icono y progreso visual.

---

## Skins

Se desbloquean con monedas en la **Tienda** (botón en la pantalla de inicio).

| Skin | Costo | Descripción |
|---|---|---|
| 🐤 **Clásico** | Gratis | Pájaro amarillo dorado original |
| 🔴 **Rojo fuego** | 15 💰 | Cuerpo rojo con ala carmesí |
| 🔵 **Oceánico** | 20 💰 | Azul celeste con degradado marino |
| 🥷 **Ninja** | 30 💰 | Negro oscuro con máscara |
| 👨‍🚀 **Astronauta** | 40 💰 | Blanco con casco y visor |
| 🌑 **Oscuro** | 50 💰 | Negro profundo con aura morada (ideal para noche) |

Los skins desbloqueados y el skin seleccionado **se guardan** entre sesiones.

---

## Logros

Los logros se desbloquean automáticamente. Al conseguirse aparece un **toast animado** en la parte superior del juego que se cierra solo a los 2.5 segundos.

| Logro | Ícono | Condición |
|---|---|---|
| ¡Primer vuelo! | 🐦 | Pasar el primer tubo |
| Volador novato | ⭐ | Alcanzar 10 puntos |
| Volador experto | 🌟 | Alcanzar 25 puntos |
| Maestro del vuelo | 🏆 | Alcanzar 50 puntos |
| Hijo de la noche | 🌙 | Sobrevivir 10 segundos en modo noche |
| Coleccionista | 💰 | Recoger 10 monedas en una sola partida |
| Intocable | 🛡 | Activar un escudo |
| Tiempo detenido | ⏱ | Activar slow-motion |
| Esquivador cósmico | 🛸 | Pasar junto a un OVNI |
| Estilo propio | 🎨 | Desbloquear cualquier skin |

Los logros conseguidos **se guardan** entre sesiones.

---

## Pulido visual

### Parallax de 3 capas

El fondo tiene profundidad real con tres capas que se mueven a velocidades distintas:

- **Capa 1 — Montañas** (15% velocidad del suelo): siluetas de picos con nieve de día, brillo lunar de noche
- **Capa 2 — Nubes medias** (35%): nubes de tamaño variable
- **Capa 3 — Arbustos** (90%): vegetación en primer plano que cambia de color con el modo noche

### Animación de entrada

Al abrir la app por primera vez en la sesión, se muestra una animación de 1.4 segundos:
1. El pájaro entra volando desde la izquierda con un arco natural
2. El título cae desde arriba con efecto elástico (bounce)
3. El texto de carga sube desde abajo

### Contador animado

Cada vez que el score sube:
- El número hace un **pop** (escala 1.0 → 1.40 → 0.95 → 1.0) en 280ms
- El color transiciona de blanco a dorado brevemente con `ColorTween`
- Cuando el ×2 está activo, el número permanece dorado
- El número tiene sombra borrosa debajo para profundidad

### Vibración háptica

| Evento | Intensidad |
|---|---|
| Saltar | Leve (`lightImpact`) |
| Puntuar / recoger moneda | Click (`selectionClick`) |
| Activar power-up / escudo absorbe golpe | Media (`mediumImpact`) |
| Morir | Fuerte (`heavyImpact`) |

### Transición día → noche

Todos los elementos cambian de color gradualmente: cielo, suelo, tubos, pájaro, montañas, nubes y arbustos. Las estrellas y la luna aparecen con `opacity` que aumenta progresivamente. Las luciérnagas del suelo también se encienden con el blend.

---

## Ajustar dificultad

Edita `lib/game/game_logic.dart`:

```dart
// ── Física ───────────────────────────────────────────────────
static const double baseGravity   = 0.00090;  // más alto = más pesado
static const double jumpVelocity  = -0.038;   // más negativo = salta más alto

// ── Velocidad ───────────────────────────────────────────────
static const double basePipeSpeed = 0.0035;   // velocidad inicial
static const double speedIncrease = 0.0010;   // cuánto acelera con dificultad

// ── Gap (hueco entre tubos) ──────────────────────────────────
static const double minGapHeight  = 0.38;     // mínimo (más difícil)
static const double maxGapHeight  = 0.52;     // máximo (más fácil al inicio)
```

Para cambiar cuándo activa el modo noche, edita `game_logic.dart`:

```dart
// Actualmente: modo noche en nivel 1 (score >= 5)
static bool isNightMode(int score) => levelFromScore(score) >= 1;

// Para activar en score >= 10:
static bool isNightMode(int score) => levelFromScore(score) >= 2;
```

Para cambiar el intervalo de aparición de obstáculos, edita `game_provider.dart`:

```dart
double get _obstacleInterval {
  final lvl = level;
  if (lvl < 1) return 9999.0;  // sin obstáculos
  if (lvl < 2) return 5.0;     // uno cada 5s
  if (lvl < 4) return 3.5;     // uno cada 3.5s
  return 2.5;                   // uno cada 2.5s en niveles altos
}
```

---

## Generar APK para Android

```bash
# APK de release (optimizado, listo para distribuir)
flutter build apk --release

# El APK queda en:
# build/app/outputs/flutter-apk/app-release.apk
```

Instálalo en cualquier Android:
1. Pasa el APK por WhatsApp, Google Drive, cable USB o correo
2. En el celular ve a **Ajustes → Seguridad → Instalar apps desconocidas** → actívalo para el app desde donde abrirás el APK
3. Abre el APK y toca **Instalar**

Para subir a Google Play Store necesitas un **App Bundle**:
```bash
flutter build appbundle --release
# Genera: build/app/outputs/bundle/release/app-release.aab
```

---

## Historial de versiones

### v4.0 — Módulos completos
- Sistema de logros con 10 trofeos y toasts animados
- Monedas coleccionables con spawn en cadena y persistencia
- Power-ups activos: escudo, slow-motion y doble puntos
- 6 skins desbloqueables con tienda en pantalla completa
- Vibración háptica en salto, puntuación, power-up y muerte

### v3.0 — Pulido visual
- Parallax de 3 capas independientes (montañas, nubes medias, arbustos)
- Animación de entrada al iniciar la sesión
- Contador de score con pop animation y ColorTween
- Estrellas con efecto de centelleo en modo noche
- Rayos del sol animados en modo día
- Halo lunar en modo noche

### v2.0 — Modo noche y obstáculos
- Transición gradual día → noche a partir de score 5
- 5 obstáculos nocturnos con lógica de movimiento propia
- Pájaro azul nocturno con sprites independientes
- Tubos nocturnos en verde oscuro
- Suelo nocturno con luciérnagas animadas
- Badge de nivel en pantalla
- Velocidad progresiva con el nivel

### v1.0 — Base jugable
- Física con gravedad progresiva y velocidad máxima
- Rotación del pájaro según velocidad vertical
- Animación de aleteo en 4 frames
- Sistema de estados: START → PLAYING → PAUSED → GAME_OVER
- Detección de colisiones precisa con hitbox reducido
- Generación infinita de tubos con reciclaje de objetos
- Dificultad progresiva
- Best score persistente
- Soporte de teclado (ESPACIO, ↑, P, ESC) y touch/mouse
- Efecto de shake al morir
- Fondo con parallax de nubes y suelo animado

### Bugs corregidos a lo largo del desarrollo
- **Colisión falsa sin tocar tubos**: el hitbox visual y el de colisión usaban coordenadas incompatibles. Corregido unificando la conversión a espacio normalizado
- **Pájaro debajo del suelo**: el `LayoutBuilder` medía toda la pantalla incluyendo el suelo. Corregido excluyendo `kGroundH` y `kTopBarH` del área de juego
- **Modo noche no activaba en nivel 5**: `isNightMode` requería `level >= 5` (score = 25). Corregido a `level >= 1` (score = 5)
- **Tunneling al caer**: sin límite de velocidad el pájaro podía atravesar el suelo en un tick. Corregido con `velocity.clamp(max: 0.050)`
- **Colisión activa desde el primer tick**: causaba muerte instantánea antes de que el jugador reaccionara. Corregido con gracia de 20 ticks al inicio

---

## Créditos

Proyecto desarrollado en Flutter/Dart.

**Dependencias:**
- [`provider`](https://pub.dev/packages/provider) — gestión de estado
- [`shared_preferences`](https://pub.dev/packages/shared_preferences) — persistencia de datos
- [`audioplayers`](https://pub.dev/packages/audioplayers) — efectos de sonido y música

**Inspirado en:** Flappy Bird original de Dong Nguyen (2013)
