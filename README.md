
# 🚗 Retrofit ADAS Mobile App

> **Advanced Driver Assistance System for Non-ADAS Vehicles**
> Android mobile application that brings modern ADAS features to older vehicles through OBD-II integration.

[![Kotlin](https://img.shields.io/badge/Kotlin-1.9+-7F52FF?logo=kotlin&logoColor=white)](https://kotlinlang.org)
[![Android](https://img.shields.io/badge/Android-API_26+-3DDC84?logo=android&logoColor=white)](https://developer.android.com)
[![Architecture](https://img.shields.io/badge/Architecture-MVVM_+_Clean-blue)](https://developer.android.com/topic/architecture)
[![License](https://img.shields.io/badge/License-MIT-yellow)](LICENSE)

---

## 🎯 Problem & Motivation

### The Problem

Turkey has over **13 million registered vehicles** that are 15+ years old and lack any form of Advanced Driver Assistance System (ADAS). According to WHO data, Turkey ranks among the highest in Europe for traffic-related fatalities. Modern vehicles come equipped with lane departure warnings, collision alerts, and fatigue detection — but these life-saving features remain inaccessible to millions of drivers with older vehicles.

### Our Solution

Retrofit ADAS turns any smartphone into a portable ADAS unit. By connecting to the vehicle's **OBD-II diagnostic port** via a low-cost Bluetooth adapter (~$10-15), the app reads real-time vehicle data and combines it with the phone's built-in sensors (accelerometer, gyroscope, GPS) to deliver:

- ⚠️ **Speed limit warnings** — alerts when exceeding safe speeds
- 🛑 **Harsh braking detection** — identifies dangerous driving patterns
- 😴 **Fatigue alerts** — time-based driving duration warnings
- 📊 **Driving analytics** — trip scores, fuel efficiency, driving behavior reports

### Target Users

- Drivers of older vehicles (pre-2015) without built-in ADAS
- Fleet managers monitoring driver behavior
- Driving schools for student performance tracking
- Budget-conscious drivers seeking safety without a new car

---

## 🏗️ System Architecture

### High-Level Overview

```
┌─────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                    │
│  ┌─────────────┐  ┌──────────────┐  ┌───────────────┐  │
│  │  Dashboard   │  │  Trip History │  │   Settings    │  │
│  │  Screen      │  │  Screen      │  │   Screen      │  │
│  └──────┬──────┘  └──────┬───────┘  └───────┬───────┘  │
│         └────────────────┼──────────────────┘           │
│                    ViewModel (MVVM)                      │
├─────────────────────────────────────────────────────────┤
│                     DOMAIN LAYER                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │AnalyzeSpeed  │  │ DetectHarsh  │  │CalculateTrip │  │
│  │  UseCase     │  │  Braking UC  │  │  Score UC    │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
├─────────────────────────────────────────────────────────┤
│                      DATA LAYER                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │  OBD-II      │  │  Sensor      │  │  Room        │  │
│  │  Repository   │  │  Repository  │  │  Database    │  │
│  └──────┬───────┘  └──────┬───────┘  └──────────────┘  │
│         │                 │                              │
├─────────┼─────────────────┼──────────────────────────────┤
│         ▼                 ▼                              │
│  ┌──────────────┐  ┌──────────────┐                     │
│  │  Bluetooth   │  │ Accelerometer│                     │
│  │  ELM327      │  │ GPS / Gyro   │                     │
│  └──────┬───────┘  └──────────────┘                     │
│         │                                                │
│    OBD-II Port                                           │
│    (Vehicle)                                             │
└─────────────────────────────────────────────────────────┘
```

### Data Flow

```
Vehicle OBD-II Port
       │
       ▼ (Bluetooth SPP)
  ELM327 Adapter ──→ OBD-II Reader Service
       │                    │
       │              ┌─────┴─────┐
       │              ▼           ▼
       │         Speed Data    RPM Data
       │              │           │
       │              ▼           ▼
       │         ┌─────────────────┐
       │         │  Sensor Fusion  │◄── Phone Sensors
       │         │     Engine      │    (Accel, GPS)
       │         └────────┬────────┘
       │                  │
       │         ┌────────┴────────┐
       │         ▼                 ▼
       │   Alert System      Analytics Engine
       │   (Real-time)       (Trip Summary)
       │         │                 │
       │         ▼                 ▼
       │    Notifications     Room Database
       │    & Warnings        & Reports
       └──────────────────────────────────
```

### Key Modules

| Module | Responsibility | Key Classes |
|--------|---------------|-------------|
| **OBD-II Reader** | Bluetooth connection, ELM327 protocol, data parsing | `ObdConnection`, `ObdCommandExecutor` |
| **Sensor Fusion** | Combines OBD-II + phone sensor data | `SensorFusionEngine`, `AccelerometerReader` |
| **Alert System** | Real-time warnings (speed, braking, fatigue) | `AlertManager`, `SpeedMonitor`, `FatigueTracker` |
| **Analytics** | Trip history, driving score, fuel tracking | `TripAnalyzer`, `DrivingScoreCalculator` |
| **Dashboard UI** | Real-time gauges, maps, alerts display | `DashboardScreen`, `GaugeComposable` |

---

## 🛠️ Tech Stack

| Category | Technology | Purpose |
|----------|-----------|---------|
| **Language** | Kotlin 1.9+ | Primary development language |
| **UI** | Jetpack Compose | Declarative UI framework |
| **Architecture** | MVVM + Clean Architecture | Separation of concerns |
| **Database** | Room | Local trip & analytics storage |
| **DI** | Hilt | Dependency injection |
| **OBD-II** | OBD-II Java API | Vehicle diagnostic communication |
| **Bluetooth** | Bluetooth SPP (Serial Port Profile) | ELM327 adapter connection |
| **Location** | Google Maps SDK + Fused Location | Route tracking & speed context |
| **Sensors** | Android Sensor API | Accelerometer, gyroscope data |
| **Async** | Kotlin Coroutines + Flow | Reactive data streams |
| **Build** | Gradle (Kotlin DSL) | Build system |
| **Min SDK** | API 26 (Android 8.0) | Minimum supported version |

---

## ✨ Features (Detailed)

### 1. OBD-II Real-Time Data Reading
- Connect to any ELM327-compatible Bluetooth adapter
- Read PIDs: vehicle speed (0x0D), RPM (0x0C), engine coolant temp (0x05), throttle position (0x11)
- Auto-reconnect on connection loss
- Data refresh rate: ~2-5 Hz

### 2. Speed Monitoring & Alerts
- Real-time speed display with large, glanceable gauge
- Configurable speed limit thresholds
- Audio + vibration alerts when limit exceeded
- Speed history logging per trip

### 3. Harsh Braking Detection
- Combines OBD-II speed delta with accelerometer data
- Detects sudden deceleration events (> configurable g-force threshold)
- Logs events with timestamp, location, and severity
- Visual indicator on trip replay map

### 4. Fatigue Detection (Time-Based)
- Monitors continuous driving duration
- Progressive alerts: gentle reminder (1.5h) → warning (2h) → urgent (2.5h+)
- Suggests nearby rest stops (future: Google Places API integration)
- Resets timer on detected rest periods

### 5. Trip Analytics & Driving Score
- **Driving Score (0-100):** weighted calculation based on:
  - Speed compliance (30%)
  - Braking smoothness (25%)
  - Acceleration patterns (20%)
  - Trip duration management (15%)
  - Fuel efficiency estimate (10%)
- Trip summary: distance, duration, avg speed, max speed, fuel estimate
- Historical trend charts

### 6. Sensor Fusion Engine
- Fuses OBD-II data with phone sensors for enhanced accuracy
- GPS for route tracking & speed cross-validation
- Accelerometer for braking/acceleration detection
- Gyroscope for turn detection (future: sharp turn warnings)

---

## 📱 App Screens & UI Design

### Planned Screens

| # | Screen | Description | Status |
|---|--------|-------------|--------|
| 1 | **Splash Screen** | App logo, vehicle connection check | 🔲 Planned |
| 2 | **Home / Dashboard** | Real-time speed gauge, RPM, alerts | 🔲 Planned |
| 3 | **Connection Setup** | Bluetooth pairing, OBD-II adapter selection | 🔲 Planned |
| 4 | **Live Map View** | Current route with speed overlay | 🔲 Planned |
| 5 | **Trip History** | Past trips list with scores & stats | 🔲 Planned |
| 6 | **Trip Detail** | Individual trip analytics, route replay | 🔲 Planned |
| 7 | **Driving Score** | Overall score breakdown, improvement tips | 🔲 Planned |
| 8 | **Settings** | Alert thresholds, units, dark mode | 🔲 Planned |

### UI Wireframe (Dashboard)

```
┌────────────────────────────────┐
│  Retrofit ADAS        ⚙️  🔗  │
├────────────────────────────────┤
│                                │
│        ┌──────────┐            │
│        │   120    │            │
│        │  km/h    │            │
│        │  ◉ SPEED │            │
│        └──────────┘            │
│                                │
│   RPM: 2,400    Temp: 90°C    │
│                                │
│  ┌──────────────────────────┐  │
│  │ ⚠️  Speed limit: 110     │  │
│  │    Reduce speed!         │  │
│  └──────────────────────────┘  │
│                                │
│  Trip: 45 min  │  Score: 82   │
│                                │
├────────────────────────────────┤
│  🏠 Home  📊 Trips  👤 Profile │
└────────────────────────────────┘
```

> 📸 _Actual screenshots will replace wireframes as each screen is implemented._

---

## 🚀 Getting Started

### Prerequisites

- Android Studio Ladybug (2024.2) or later
- Android device (API 26+) with Bluetooth
- OBD-II Bluetooth adapter (ELM327 v1.5+ compatible)
- A vehicle with OBD-II port (1996+ for US, 2001+ for EU/TR vehicles)

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/ozge-devops/retrofit-adas-app.git
cd retrofit-adas-app

# 2. Open in Android Studio
# File → Open → select the project folder

# 3. Sync Gradle dependencies
./gradlew build

# 4. Run on physical device (Bluetooth required)
./gradlew installDebug
```

### OBD-II Hardware Setup

1. **Locate OBD-II port** — usually under the dashboard on the driver's side
2. **Plug in ELM327 adapter** — LED on adapter should turn on
3. **Turn ignition ON** (engine can be off for basic connection test)
4. **Pair via Bluetooth** — Settings → Bluetooth → pair "OBDII" device (PIN: 1234)
5. **Open app** → tap **Connect Vehicle** → select paired adapter

---

## 📁 Project Structure

```
retrofit-adas-app/
├── app/
│   ├── src/main/
│   │   ├── java/com/ozge/adas/
│   │   │   ├── data/
│   │   │   │   ├── local/              # Room DB, DAOs
│   │   │   │   ├── remote/             # OBD-II Bluetooth client
│   │   │   │   ├── sensor/             # Phone sensor readers
│   │   │   │   └── repository/         # Repository implementations
│   │   │   ├── domain/
│   │   │   │   ├── model/              # Trip, Alert, DrivingScore entities
│   │   │   │   ├── repository/         # Repository interfaces
│   │   │   │   └── usecase/            # Business logic use cases
│   │   │   ├── presentation/
│   │   │   │   ├── dashboard/          # Main dashboard screen
│   │   │   │   ├── trips/              # Trip history & detail
│   │   │   │   ├── settings/           # App settings
│   │   │   │   ├── connection/         # OBD-II setup screen
│   │   │   │   └── components/         # Reusable UI (Gauge, AlertBanner)
│   │   │   ├── di/                     # Hilt modules
│   │   │   ├── service/                # Foreground service for background data
│   │   │   └── util/                   # Extensions, constants
│   │   ├── res/
│   │   │   ├── drawable/               # Icons, illustrations
│   │   │   ├── values/                 # Strings, themes, colors
│   │   │   └── navigation/            # Nav graph
│   │   └── AndroidManifest.xml
│   ├── build.gradle.kts
│   └── proguard-rules.pro
├── gradle/
├── build.gradle.kts                    # Project-level
├── settings.gradle.kts
├── README.md
├── LICENSE
└── .gitignore
```

---

## 📅 Development Timeline

### 8-Week Implementation Plan

| Week | Phase | Tasks | Deliverable |
|------|-------|-------|-------------|
| **1** | 🏗️ Setup | Project init, architecture setup, Hilt DI config | Empty app with navigation skeleton |
| **2** | 🔗 OBD-II | Bluetooth connection, ELM327 protocol, basic PID reading | Working OBD-II data stream |
| **3** | 📊 Dashboard | Speed gauge UI, RPM display, real-time data binding | Live dashboard screen |
| **4** | ⚠️ Alerts | Speed limit engine, harsh braking detection, notification system | Working alert system |
| **5** | 🗺️ Location | GPS integration, route tracking, map overlay | Trip recording with map |
| **6** | 📈 Analytics | Driving score algorithm, trip summary, history screen | Analytics & trip history |
| **7** | 😴 Fatigue | Drive duration monitoring, rest alerts, sensor fusion refinement | Fatigue detection system |
| **8** | 🧪 Testing | UI polish, edge cases, performance optimization, documentation | Release-ready APK |

### Current Progress

```
Week 1: Setup & Architecture     ██████████ 100% ✅
Week 2: OBD-II Connection        ░░░░░░░░░░   0% 🔲
Week 3: Dashboard UI             ░░░░░░░░░░   0% 🔲
Week 4: Alert System             ░░░░░░░░░░   0% 🔲
Week 5: Location & Maps          ░░░░░░░░░░   0% 🔲
Week 6: Analytics & Scoring      ░░░░░░░░░░   0% 🔲
Week 7: Fatigue Detection        ░░░░░░░░░░   0% 🔲
Week 8: Testing & Polish         ░░░░░░░░░░   0% 🔲
```

---

## 🧪 Testing Strategy

| Type | Tool | Coverage Target |
|------|------|----------------|
| Unit Tests | JUnit 5 + MockK | Domain layer use cases (80%+) |
| Integration Tests | AndroidX Test | OBD-II + Sensor fusion |
| UI Tests | Compose Testing | Critical user flows |
| Manual Testing | Physical device + ELM327 | Real vehicle scenarios |

---

## 📚 References & Resources

- [OBD-II PID Reference](https://en.wikipedia.org/wiki/OBD-II_PIDs)
- [ELM327 Command Set](https://www.elmelectronics.com/wp-content/uploads/2016/07/ELM327DS.pdf)
- [Android Bluetooth Guide](https://developer.android.com/guide/topics/connectivity/bluetooth)
- [Jetpack Compose Docs](https://developer.android.com/jetpack/compose)
- [Clean Architecture in Android](https://developer.android.com/topic/architecture)

---

## 🤝 Contributing

This is a thesis project, but suggestions and feedback are welcome! Feel free to open an issue or start a discussion.

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

## 👩‍💻 Author

**Özge Zelal Küçük**
- GitHub: [@ozge-devops](https://github.com/ozge-devops)
MY ADVİSOR  PROF. ALİ GÜNEŞ
---

<p align="center">
  <b>🚗 Retrofit ADAS — Making road safety accessible to every driver</b><br>
  <i>Undergraduate Thesis Project • 2025-2026</i>
</p>
