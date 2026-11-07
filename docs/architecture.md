# Ecosystem Rewind - Architecture Overview

**Product**: Ecosystem Rewind  
**Organization**: PRITHVI LABS  
**Version**: Phase 1 (Flutter Web) + Phase 2 (Python FastAPI Backend) MVP  

---

## 1. System Architecture

Ecosystem Rewind is engineered with a decoupled, high-performance architecture:

```
+-----------------------------------------------------------------------------------+
|                           Flutter Web Client (Dart 3.x)                          |
|                                                                                   |
|  [Presentation Layer]                                                             |
|   - Landing Page (PRITHVI LABS brand, hero visuals, navigation)                  |
|   - Geographic Map Explorer (flutter_map, latlong2, interactive polygons)        |
|   - Ecosystem Health Dashboard (fl_chart, KPI cards, radar/bar indicators)        |
|   - Interactive Species Network (Interactive Canvas, node drag/hover, zoom/pan)   |
|   - Ecological Domino Simulator (Impact comparison, cascade inspection)           |
|   - Restoration Recommendation Engine (Rule-based ranking, action catalog)       |
|   - Restoration Time Machine (2025-2045 multi-horizon scenario projection)        |
|                                                                                   |
|  [State Management & Routing]                                                     |
|   - flutter_riverpod (AsyncNotifier, StateProvider, areaId state synchronization)|
|   - go_router (Deep linking: /areas/:areaId/dashboard, /network, /domino, etc.)   |
|                                                                                   |
|  [Networking & Repositories]                                                      |
|   - dio HTTP Client with retry, timeouts, custom interceptors                     |
|   - Typed Dart DTOs and Repository Layer                                          |
+------------------------------------------+----------------------------------------+
                                           | HTTP REST JSON API
                                           v
+-----------------------------------------------------------------------------------+
|                           FastAPI Backend (Python 3.12)                          |
|                                                                                   |
|  [API Router Layer]                                                               |
|   - /api/health                                                                   |
|   - /api/areas & /api/areas/{area_id}                                             |
|   - /api/areas/{area_id}/summary                                                  |
|   - /api/areas/{area_id}/species & /api/areas/{area_id}/network                   |
|   - /api/areas/{area_id}/simulate (NetworkX removal & dependency propagation)     |
|   - /api/areas/{area_id}/recommendations (Rule-based condition evaluation)        |
|   - /api/areas/{area_id}/scenarios & /api/areas/{area_id}/scenarios/{scenario_id} |
|   - /api/areas/{area_id}/report (Comprehensive Markdown & metric synthesis)       |
|                                                                                   |
|  [Domain Services]                                                                |
|   - HealthService: Composite score normalization, weighted indicators             |
|   - NetworkService: Graph construction, centrality, community structure           |
|   - DominoService: Immutable graph deepcopy, dependency cascade evaluation        |
|   - RecommendationService: Rule matrix, problem matching, prioritization ranking  |
|   - ScenarioService: Deterministic logistic/bounded indicator trajectory model    |
|                                                                                   |
|  [Data Access & Repository Layer]                                                 |
|   - JSON/CSV Seed Repository (Easily swappable with PostGIS / SQLAlchemy)         |
|   - Immutable in-memory cache of baseline graphs                                 |
+-----------------------------------------------------------------------------------+
```

---

## 2. Selected Area (`area_id`) Data Flow

All analytical features strictly depend on the geographic `area_id`:
1. When the user selects an area (e.g., `western_ghats_forest` or `sundarbans_wetland`), the Riverpod `selectedAreaIdProvider` updates.
2. The URL route syncs (`/workspace/western_ghats_forest/dashboard`, `/network`, `/domino`, etc.).
3. All backend requests carry `area_id` in their path.
4. The backend service queries the repository strictly filtered by that `area_id`.
5. Datasets, indicators, networks, simulations, recommendations, and time-machine projections are guaranteed never to bleed between ecosystems.

---

## 3. Future ML Integration Boundary

The current Phase 2 system employs transparent, documented, deterministic rule sets:
- **Domino propagation**: Evaluates trophic dependence thresholds and pollinator mutualism losses.
- **Restoration ranking**: Multi-criteria utility function weighing indicator deficit, network centrality, and cost-efficiency.
- **Time Machine projections**: Bounded non-linear trajectory modeling.

A future Phase 3 Machine Learning model (e.g., GNN for link prediction, species distribution models, habitat suitability Random Forest) can be seamlessly integrated into `services/recommendation_service.py` and `services/scenario_service.py` behind the existing interface without altering the Flutter frontend contracts.
