import json
import os
from typing import Optional
from backend.app.config import settings
from backend.app.schemas.models import (
    EcosystemArea,
    Species,
    EcologicalInteraction,
    Indicator,
    RestorationAction,
)

class EcosystemRepository:
    def __init__(self, data_dir: Optional[str] = None):
        self.data_dir = data_dir or settings.DATA_DIR
        self._areas_cache: Optional[dict[str, EcosystemArea]] = None
        self._species_cache: Optional[dict[str, list[Species]]] = None
        self._interactions_cache: Optional[dict[str, list[EcologicalInteraction]]] = None
        self._indicators_cache: Optional[dict[str, list[Indicator]]] = None
        self._actions_cache: Optional[dict[str, RestorationAction]] = None
        self._load_all()

    def _load_json(self, filename: str) -> list[dict]:
        path = os.path.join(self.data_dir, filename)
        if not os.path.exists(path):
            raise FileNotFoundError(f"Data file not found: {path}")
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)

    def _load_all(self):
        # 1. Areas
        areas_data = self._load_json("areas.json")
        self._areas_cache = {a["area_id"]: EcosystemArea(**a) for a in areas_data}

        # 2. Species
        species_data = self._load_json("species.json")
        self._species_cache = {}
        for sp in species_data:
            model = Species(**sp)
            self._species_cache.setdefault(model.area_id, []).append(model)

        # 3. Interactions
        interactions_data = self._load_json("interactions.json")
        self._interactions_cache = {}
        for item in interactions_data:
            model = EcologicalInteraction(**item)
            self._interactions_cache.setdefault(model.area_id, []).append(model)

        # 4. Indicators
        indicators_data = self._load_json("indicators.json")
        self._indicators_cache = {}
        for ind in indicators_data:
            model = Indicator(**ind)
            self._indicators_cache.setdefault(model.area_id, []).append(model)

        # 5. Actions
        actions_data = self._load_json("actions.json")
        self._actions_cache = {act["action_id"]: RestorationAction(**act) for act in actions_data}

    def list_areas(self) -> list[EcosystemArea]:
        return list(self._areas_cache.values())

    def get_area(self, area_id: str) -> Optional[EcosystemArea]:
        return self._areas_cache.get(area_id)

    def list_species(self, area_id: str, group: Optional[str] = None) -> list[Species]:
        species_list = self._species_cache.get(area_id, [])
        if group:
            species_list = [s for s in species_list if s.group.lower() == group.lower()]
        return species_list

    def get_species(self, area_id: str, species_id: str) -> Optional[Species]:
        for s in self._species_cache.get(area_id, []):
            if s.species_id == species_id:
                return s
        return None

    def list_interactions(self, area_id: str) -> list[EcologicalInteraction]:
        return self._interactions_cache.get(area_id, [])

    def list_indicators(self, area_id: str) -> list[Indicator]:
        return self._indicators_cache.get(area_id, [])

    def list_actions_for_area(self, area_id: str) -> list[RestorationAction]:
        area = self.get_area(area_id)
        if not area:
            return []
        ecosystem_type = area.ecosystem_type
        # Return actions matching the area's ecosystem type or prefixed with area abbreviation
        matched = []
        for action in self._actions_cache.values():
            if ecosystem_type in action.applicable_ecosystem_types or any(t.lower() in ecosystem_type.lower() for t in action.applicable_ecosystem_types):
                matched.append(action)
        return matched

    def get_action_by_id(self, action_id: str) -> Optional[RestorationAction]:
        return self._actions_cache.get(action_id)

# Singleton instance
ecosystem_repo = EcosystemRepository()
