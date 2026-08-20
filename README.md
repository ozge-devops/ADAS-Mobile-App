
# 🚗 Retrofit ADAS

**Advanced Driver Assistance System for Non-ADAS Vehicles**

Turn any smartphone into a portable ADAS unit through OBD-II integration.
[![Kotlin](https://img.shields.io/badge/Kotlin-1.9+-7F52FF?logo=kotlin&logoColor=white)](https://kotlinlang.org)
[![Jetpack Compose](https://img.shields.io/badge/Jetpack_Compose-Material_3-4285F4?logo=jetpackcompose&logoColor=white)](https://developer.android.com/jetpack/compose)
[![Architecture](https://img.shields.io/badge/Architecture-Clean_+_MVVM-blue)](https://developer.android.com/topic/architecture)
[![Min SDK](https://img.shields.io/badge/Min_SDK-26_(Android_8.0)-3DDC84?logo=android&logoColor=white)](https://developer.android.com)
[![License](https://img.shields.io/badge/License-MIT-yellow)](LICENSE)

</div>

---

## Problem & Motivation

Turkey has over **13 million registered vehicles** aged 15+ years without any Advanced Driver Assistance System. According to WHO data, Turkey ranks among the highest in Europe for traffic fatalities. Modern vehicles include lane departure warnings, collision alerts, and fatigue detection — but these features remain inaccessible to millions of drivers.

**Retrofit ADAS** bridges this gap by connecting to a vehicle's OBD-II diagnostic port via a low-cost Bluetooth ELM327 adapter (~$10–15) and combining real-time vehicle data with the phone's built-in sensors (accelerometer, gyroscope, GPS).

### Key Capabilities

- **Speed limit warnings** — configurable alerts with escalating severity
- **Harsh braking detection** — accelerometer + OBD-II speed delta fusion
- **Fatigue alerts** — progressive time-based driving duration monitoring
- **Driving analytics** — per-trip scoring, fuel efficiency estimates, behavior reports
- **Sensor fusion** — OBD-II + accelerometer + gyroscope for enhanced accuracy

---

## Architecture

The project follows **Clean Architecture** with **MVVM** pattern, enforcing strict layer separation:

```
┌─────────────────── PRESENTATION ───────────────────┐
│  Jetpack Compose Screens → ViewModels (Hilt)       │
│  Dashboard │ Connection │ Trips │ Settings │ Profile│
├──────────────────── DOMAIN ────────────────────────┤
│  Use Cases: MonitorSpeed │ DetectHarshBraking       │
│             MonitorFatigue │ CalculateDrivingScore  │
│  Models: Trip │ Alert │ VehicleData │ DrivingScore  │
│  Repository Interfaces (abstractions)               │
├───────────────────── DATA ─────────────────────────┤
│  Repository Implementations │ Entity↔Domain Mappers │
│  ObdConnectionManager (Bluetooth SPP / ELM327)      │
│  SensorReader │ SensorFusionEngine                   │
│  Room Database (TripDao, AlertDao, RoutePointDao)    │
│  UserPreferences (DataStore)                         │
├─────────────────── EXTERNAL ───────────────────────┤
│  Bluetooth ELM327 │ Phone Sensors │ GPS / Location  │
└────────────────────────────────────────────────────┘
```

Each layer depends only on the layer below it. Domain has zero Android framework dependencies.

---

## Tech Stack

| Category | Technology |
|----------|-----------|
| Language | Kotlin 1.9+ |
| UI Framework | Jetpack Compose (Material 3) |
| Architecture | MVVM + Clean Architecture |
| Dependency Injection | Hilt (Dagger) |
| Local Storage | Room + DataStore |
| OBD-II Protocol | ELM327 via Bluetooth SPP |
| Sensors | Android Sensor API (accelerometer, gyroscope) |
| Async | Kotlin Coroutines + Flow |
| Navigation | Compose Navigation |
| Build System | Gradle (Kotlin DSL) |

---

## Project Structure

```
app/src/main/java/com/ozge/adas/
├── data/
│   ├── local/           # Room entities, DAOs, Database, DataStore
│   ├── remote/           # ObdConnectionManager (Bluetooth)
│   ├── sensor/           # SensorReader, SensorFusionEngine
│   └── repository/       # Implementations + Entity↔Domain mappers
├── domain/
│   ├── model/            # Trip, Alert, VehicleData, DrivingScore
│   ├── repository/       # Repository interfaces (contracts)
│   └── usecase/          # MonitorSpeed, DetectHarshBraking,
│                         # MonitorFatigue, CalculateDrivingScore
├── presentation/
│   ├── dashboard/        # Main screen: speed gauge, metrics, alerts
│   ├── connection/       # Bluetooth pairing & OBD-II setup
│   ├── trips/            # Trip history list + detail with score
│   ├── settings/         # Speed limit, alerts, dark mode
│   ├── profile/          # Aggregate driver stats & safety summary
│   ├── navigation/       # Compose NavHost & route definitions
│   ├── theme/            # Material 3 color scheme & typography
│   └── components/       # Reusable: SpeedGaugeArc, InfoChip
├── di/                   # Hilt modules (Database, Repository)
├── service/              # Foreground service, notification manager
└── util/                 # Constants, extension functions
```

---

## Screens

| Screen | Description |
|--------|-------------|
| **Dashboard** | Real-time speed gauge with animated arc, RPM/temperature/throttle metrics, trip stats, active alert banner |
| **Connection** | Bluetooth device scanning, ELM327 adapter pairing, connection status with step-by-step instructions |
| **Trip History** | Chronological list of past trips with score badges, duration, and distance |
| **Trip Detail** | Circular score visualization, stat breakdown (speed compliance, braking, acceleration, duration, fuel), event log |
| **Settings** | Speed limit slider, sound/vibration alert toggles, dark mode switch |
| **Profile** | Aggregate driving statistics, average score, total distance/hours, safety summary |

---

## Driving Score Algorithm

Each trip receives a weighted score out of 100:

| Component | Weight | Logic |
|-----------|--------|-------|
| Speed compliance | 30% | `(1 - violations / total_readings) × 100` |
| Braking smoothness | 25% | 0 events → 100, ≤2 → 80, ≤5 → 60, >5 → 30 |
| Acceleration patterns | 20% | 0 events → 100, ≤3 → 75, >3 → 40 |
| Trip duration | 15% | ≤90 min → 100, ≤120 → 80, ≤150 → 50, >150 → 20 |
| Fuel efficiency | 10% | ≤6 L/100km → 100, ≤8 → 80, ≤10 → 60, >10 → 40 |

---

## Getting Started

### Prerequisites

- Android Studio Ladybug (2024.2) or later
- Physical Android device (API 26+) with Bluetooth
- ELM327 v1.5+ Bluetooth OBD-II adapter
- Vehicle with OBD-II port (1996+ US, 2001+ EU/TR)

### Build & Run

```bash
git clone https://github.com/ozge-devops/retrofit-adas-app.git
cd retrofit-adas-app
```

**Android Studio:** Open project → Sync Gradle → Run on physical device

**Command line:**
```bash
chmod +x setup.sh && ./setup.sh
./gradlew assembleDebug
```

### OBD-II Hardware Setup

1. Plug ELM327 adapter into vehicle's OBD-II port (under dashboard, driver side)
2. Turn ignition ON
3. Pair adapter via phone Bluetooth settings (default PIN: `1234`)
4. Open app → Connection screen → Select paired adapter

---

## OBD-II PIDs

| PID | Parameter | Formula | Unit |
|-----|-----------|---------|------|
| `0x0D` | Vehicle Speed | `A` | km/h |
| `0x0C` | Engine RPM | `((A×256)+B)/4` | rpm |
| `0x05` | Coolant Temperature | `A - 40` | °C |
| `0x11` | Throttle Position | `(A×100)/255` | % |

---

## Testing

| Type | Framework | Scope |
|------|-----------|-------|
| Unit | JUnit 5 + MockK | Domain use cases, driving score calculation |
| Integration | AndroidX Test | Room database operations |
| UI | Compose Testing | Critical user flows |
| Manual | Physical device + ELM327 | Real vehicle scenarios |

---

## Roadmap

- [ ] Live map view with speed overlay (Google Maps SDK)
- [ ] Splash screen with connection pre-check
- [ ] GPS speed cross-validation
- [ ] Sharp turn warnings (gyroscope-based)
- [ ] Nearby rest stop suggestions (Google Places API)
- [ ] Trip export (PDF report)
- [ ] CI/CD with GitHub Actions

---

## License

MIT License — see [LICENSE](LICENSE) for details.

## Author

**Özge Zelal Küçük** · [@ozge-devops](https://github.com/ozge-devops)

> Undergraduate Thesis Project · 2025–2026

---

<p align="center">
  <b>Making road safety accessible to every driver.</b>
</p>
