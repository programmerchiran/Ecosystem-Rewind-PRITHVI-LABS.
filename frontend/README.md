# Ecosystem Rewind – Frontend Architecture & Developer Guide
**PRITHVI LABS · Flutter Web Application**

This document provides technical guidelines and architectural documentation for the **Ecosystem Rewind** web client built with Flutter Web and Dart.

---

## 1. Overview & Technology Stack

The frontend is a single-page web application (SPA) designed to run natively in modern web browsers. It visualizes ecological datasets, renders interactive topological species networks, simulates trophic cascades, and projects multi-decade restoration scenarios.

### Core Stack
- **Framework**: Flutter Web (Dart 3.13.5 / Flutter 3.47.7)
- **UI Design System**: Material 3 with custom ecological color palette (`AppColors`)
- **State Management**: Flutter Riverpod 3.4.3
- **Navigation & Routing**: GoRouter 18.1.1
- **Visualizations**: `fl_chart 1.3.0` (radar charts, trajectory curves)
- **Geospatial Mapping**: `flutter_map 8.3.2` with `latlong2 0.10.1` (OpenStreetMap tile rendering, GeoJSON polygon boundaries)
- **Network Client**: `dio 5.11.1`

---

## 2. Directory Structure

```text
frontend/
├── lib/
│   ├── core/
│   │   ├── config/app_config.dart          # Environment variables and API base URL
│   │   └── constants/app_colors.dart       # Theme palette (forestDark, emerald, etc.)
│   ├── features/                           # Independent domain modules
│   │   ├── area_selection/                 # GIS study area selection map
│   │   │   └── area_selection_page.dart
│   │   ├── domino_simulator/               # Trophic extinction cascade simulator
│   │   │   └── domino_simulator_page.dart
│   │   ├── ecosystem_network/              # Custom painter network graph
│   │   │   ├── ecosystem_network_page.dart
│   │   │   ├── species_details_sheet.dart
│   │   │   └── species_network_canvas.dart
│   │   ├── health_dashboard/               # Indicators, KPI cards, radar charts
│   │   │   └── health_dashboard_page.dart
│   │   ├── landing/                        # Public marketing & hero page
│   │   │   └── landing_page.dart
│   │   ├── recommendations/                # Restoration action cards & budget filter
│   │   │   └── recommendations_page.dart
│   │   ├── report/                         # Markdown executive report renderer
│   │   │   └── executive_report_page.dart
│   │   ├── time_machine/                   # Multi-horizon trajectory projections
│   │   │   └── time_machine_page.dart
│   │   └── workspace/                      # Outer shell with sidebar and header
│   │       └── workspace_shell.dart
│   ├── models/                             # Immutable data contracts & JSON factories
│   │   ├── area_model.dart
│   │   ├── domino_model.dart
│   │   ├── indicator_model.dart
│   │   ├── network_model.dart
│   │   ├── recommendation_model.dart
│   │   ├── scenario_model.dart
│   │   └── species_model.dart
│   ├── providers/                          # Riverpod providers & state notifiers
│   │   └── ecosystem_providers.dart
│   ├── repositories/                       # HTTP API client abstraction
│   │   └── ecosystem_api_repository.dart
│   ├── shared/widgets/                     # Reusable design system components
│   │   ├── app_header.dart
│   │   ├── app_sidebar.dart
│   │   ├── area_switcher_dialog.dart
│   │   ├── empty_state_view.dart
│   │   ├── error_display.dart
│   │   ├── kpi_card.dart
│   │   ├── loading_skeleton.dart
│   │   └── status_badge.dart
│   └── main.dart                           # App root, Theme, and GoRouter setup
├── test/
│   ├── features_test.dart                  # Feature pages test suite (4 tests)
│   ├── new_features_test.dart              # Area selection, network, domino, details, switching (32 tests)
│   ├── responsive_viewports_test.dart      # 30 viewport tests (6 viewports x 5 pages)
│   └── widget_test.dart                    # App landing smoke test (1 test)
├── analysis_options.yaml                   # Static analysis rules
└── pubspec.yaml                            # Package manifest
```

---

## 3. Application Routing & Deep Linking

Navigation is managed declaratively by **GoRouter** in `lib/main.dart`:

| Route Path | View | Description |
| :--- | :--- | :--- |
| `/` | `LandingPage` | Public introductory page with ecosystem overview. |
| `/areas` | `AreaSelectionPage` | Interactive map to select a study ecosystem. |
| `/explore` | Redirect &rarr; `/areas` | Backward compatibility redirect for header links. |
| `/workspace/:areaId` | Redirect &rarr; `.../dashboard` | Redirects bare workspace route to dashboard. |
| `/workspace/:areaId/dashboard` | `HealthDashboardPage` | Health metrics, radar charts, data lineage. |
| `/workspace/:areaId/network` | `EcosystemNetworkPage` | Interactive species interaction canvas. |
| `/workspace/:areaId/domino` | `DominoSimulatorPage` | Keystone species removal cascade simulator. |
| `/workspace/:areaId/recommendations` | `RecommendationsPage` | Restoration actions & budget optimizer. |
| `/workspace/:areaId/timemachine` | `TimeMachinePage` | 2025–2045 multi-horizon projection engine. |
| `/workspace/:areaId/report` | `ExecutiveReportPage` | Synthesized executive brief with copyable markdown. |

---

## 4. State Management Architecture

State is decoupled from UI presentation using **Flutter Riverpod**:

- **Repository Provider** (`ecosystemRepoProvider`): Exposes the abstract `EcosystemApiRepository`. In widget tests, this is cleanly overridden via `ecosystemRepoProvider.overrideWithValue(stubRepo)` without needing HTTP mocking.
- **Active Area Notifier** (`selectedAreaIdProvider`): Global `Notifier<String>` tracking the currently active study area ID across features.
- **Asynchronous Data Providers**:
  - `areasListProvider`: Fetches all supported study ecosystems.
  - `selectedAreaProvider`: Fetches the selected ecosystem's metadata.
  - `healthSummaryProvider.family`: Ingests health score and indicator vectors.
  - `speciesCatalogProvider.family`: Ingests the species roster with optional taxon filtering.
  - `networkGraphProvider.family`: Ingests NetworkX node and edge collections.
  - `recommendationsProvider.family`: Ingests ranked restoration action items.
  - `scenarioResultProvider.family`: Computes multi-decade trajectory curves.

---

## 5. API Client & Repository Pattern

All communication with the backend is routed through [`EcosystemApiRepository`](lib/repositories/ecosystem_api_repository.dart):

```dart
class EcosystemApiRepository {
  final Dio dio;
  EcosystemApiRepository({Dio? dioClient}) : dio = dioClient ?? Dio(...);

  Future<List<EcosystemAreaModel>> fetchAreas();
  Future<AreaSummaryModel> fetchAreaSummary(String areaId);
  Future<NetworkGraphModel> fetchNetworkGraph(String areaId);
  Future<DominoSimulationResultModel> simulateSpeciesRemoval(String areaId, String speciesId, ...);
  Future<RecommendationResponseModel> fetchRecommendations(String areaId, ...);
  Future<ScenarioResponseModel> calculateScenario(String areaId, ...);
  Future<Map<String, dynamic>> fetchExecutiveReport(String areaId);
}
```

- Standardized timeouts (`connectTimeout: 10s`, `receiveTimeout: 15s`).
- Graceful error mapping converting network failures to descriptive domain errors rendered by `ErrorDisplay`.

---

## 6. Responsive Design Approach

The UI adapts responsively to 6 benchmark viewports:
1. **320 &times; 568** (Ultra-compact mobile, iPhone SE 1st gen)
2. **375 &times; 667** (Compact mobile, iPhone SE 2nd gen)
3. **430 &times; 932** (Large modern mobile, iPhone 14/15 Pro Max)
4. **768 &times; 1024** (Tablet portrait, iPad Mini)
5. **1366 &times; 768** (Standard laptop display)
6. **1920 &times; 1080** (Full HD desktop display)

### Implementation Techniques
- Responsive layout branching via `MediaQuery.sizeOf(context).width < 768`.
- Non-overflowing flex containers using `Wrap(spacing: ..., runSpacing: ...)`, `Flexible`, and `Expanded`.
- Responsive stat rows with auto-aligning labels and values.
- Adaptive sidebars that collapse to top app bars on mobile viewports.

---

## 7. Development & Verification Commands

All commands are executed from the `frontend/` directory.

### Install Dependencies
```powershell
flutter pub get
```

### Static Analysis
```powershell
flutter analyze
```
*Current status: 0 issues found.*

### Run All Automated Tests
```powershell
flutter test
```
*Current status: 67 / 67 passing tests across 4 test suites.*

### Run Specific Test Suites
```powershell
# Responsive Viewports Suite (30 tests)
flutter test test/responsive_viewports_test.dart

# New Features Suite (32 tests: Area Selection, Network, Domino, Details, Ecosystem Switching)
flutter test test/new_features_test.dart

# Features Integration Suite (4 tests)
flutter test test/features_test.dart

# App Smoke Test (1 test)
flutter test test/widget_test.dart
```

### Run Locally in Chrome
```powershell
flutter run -d chrome --web-port 3000
```

### Compile Production Web Release
```powershell
flutter build web --release
```
*Build output: `build/web/`.*
