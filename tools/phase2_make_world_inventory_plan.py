"""Select one authored example of each visible world-item family.

Run at the pinned capture checkout; the JSON plan is committed with the
capture script so any frame can be reproduced from its recorded commit.
"""

from __future__ import annotations

import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / "tools/phase2_world_inventory_plan.json"


def slug(value: str) -> str:
    return re.sub(r"[^a-z0-9]+", "_", value.lower()).strip("_")


def add_family(rows: list[dict], seen: set[tuple[str, str]],
               family_type: str, key: str, position: list[float],
               band: str, source: str, authored_id: str,
               view: str = "close") -> None:
    unique = (family_type, key)
    if unique in seen:
        return
    if len(position) not in (2, 3):
        return
    seen.add(unique)
    rows.append({
        "family_type": family_type, "slug": slug(key), "subject": key,
        "position_xz": [position[0], position[-1]], "band": band,
        "source": source, "authored_id": authored_id,
        "heading_deg": 0.0, "route": "off", "view": view,
    })


def meadows_plan() -> list[dict]:
    rows: list[dict] = []
    seen: set[tuple[str, str]] = set()
    for band in sorted((ROOT / "data/config/bands").iterdir()):
        if not band.is_dir():
            continue
        pickups = band / "pickups.json"
        if pickups.exists():
            for obj in json.loads(pickups.read_text(encoding="utf-8")).get("pickups", []):
                add_family(rows, seen, "pickup", obj["item"], obj["pos"],
                           band.name, pickups.relative_to(ROOT).as_posix(), obj["id"])
        harvest = band / "harvest.json"
        if harvest.exists():
            for obj in json.loads(harvest.read_text(encoding="utf-8")).get("nodes", []):
                add_family(rows, seen, "harvest", obj["item"], obj["at"],
                           band.name, harvest.relative_to(ROOT).as_posix(), str(obj.get("order", "")))
        props = band / "props.json"
        if props.exists():
            for cluster in json.loads(props.read_text(encoding="utf-8")).get("clusters", []):
                for obj in cluster.get("props", []):
                    add_family(rows, seen, "prop", obj["model"], obj["at"],
                               band.name, props.relative_to(ROOT).as_posix(),
                               str(cluster.get("name", "")), "approach" if obj["model"] in {"camp_tent", "Prop_Wagon"} else "close")
    return rows


def water_plan() -> list[dict]:
    data = json.loads((ROOT / "data/config/water_pickups.json").read_text(encoding="utf-8"))
    rows: list[dict] = []
    seen: set[tuple[str, str]] = set()
    source = "data/config/water_pickups.json"
    for obj in data["pickups"]:
        add_family(rows, seen, "pickup", obj["item_id"], obj["position"],
                   obj["island_id"], source, obj["id"])
    for obj in data["harvest"]:
        add_family(rows, seen, "harvest", obj["item_id"], obj["position"],
                   obj["island_id"], source, obj["id"])
    return rows


def cloudreach_plan() -> list[dict]:
    data = json.loads((ROOT / "data/config/cloudreach_chapter.json").read_text(encoding="utf-8"))
    runtime = json.loads((ROOT / "data/config/cloudreach_physical_runtime.json").read_text(encoding="utf-8"))
    overrides = runtime.get("pickup_overrides", {})
    rows: list[dict] = []
    seen: set[tuple[str, str]] = set()
    for obj in data["pickups"]:
        add_family(rows, seen, "pickup", obj["item_id"], overrides.get(obj["id"], obj["position"]),
                   obj["region_id"], "data/config/cloudreach_chapter.json", obj["id"])
    return rows


def stormwood_plan() -> list[dict]:
    rows: list[dict] = []
    seen: set[tuple[str, str]] = set()
    pickups = json.loads((ROOT / "data/config/stormwood_pickups.json").read_text(encoding="utf-8"))
    for obj in pickups["pickups"]:
        add_family(rows, seen, "pickup", obj["item_id"], obj["position"],
                   obj["region_id"], "data/config/stormwood_pickups.json", obj["id"])
    harvests = json.loads((ROOT / "data/config/stormwood_harvests.json").read_text(encoding="utf-8"))
    for obj in harvests["sites"]:
        add_family(rows, seen, "harvest", obj["item"], obj["position"],
                   obj["region_id"], "data/config/stormwood_harvests.json", obj["id"])
    return rows


def main() -> None:
    existing = json.loads(DEST.read_text(encoding="utf-8")) if DEST.exists() else {}
    existing["meadows"] = meadows_plan()
    existing["water"] = water_plan()
    existing["cloudreach"] = cloudreach_plan()
    existing["stormwood"] = stormwood_plan()
    DEST.write_text(json.dumps(existing, indent=2) + "\n", encoding="utf-8")
    print("World inventory families: " + ", ".join(
        f"{biome}={len(rows)}" for biome, rows in existing.items()))


if __name__ == "__main__":
    main()
