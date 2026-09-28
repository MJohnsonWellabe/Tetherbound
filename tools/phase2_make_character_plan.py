"""Pin authored character and trainer post locations for Phase 2."""

from __future__ import annotations

import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / "tools/phase2_character_plan.json"


def slug(value: str) -> str:
    return re.sub(r"[^a-z0-9]+", "_", value.lower()).strip("_")


def meadows_plan() -> list[dict]:
    rows: list[dict] = []
    villagers_path = ROOT / "data/config/village_npcs.json"
    villagers = json.loads(villagers_path.read_text(encoding="utf-8"))
    for obj in villagers["villagers"]:
        rows.append({
            "family_type": "character", "slug": slug(obj["name"]),
            "subject": obj["name"], "position_xz": obj["position"],
            "band": "meadows", "source": villagers_path.relative_to(ROOT).as_posix(),
            "authored_id": obj["name"], "heading_deg": (obj.get("facing_deg", 0) + 180) % 360,
            "route": "main", "view": "post",
        })
    for path in sorted((ROOT / "data/config/bands").glob("*/trainers.json")):
        for obj in json.loads(path.read_text(encoding="utf-8"))["trainers"]:
            # Village dual-role trainers are already represented by their post.
            if obj.get("placed_by") == "village_npcs":
                continue
            rows.append({
                "family_type": "trainer", "slug": slug(obj["id"]),
                "subject": obj.get("name", obj["id"]),
                "position_xz": obj["position"], "band": path.parent.name,
                "source": path.relative_to(ROOT).as_posix(),
                "authored_id": obj["id"], "heading_deg": (obj.get("facing_deg", 0) + 180) % 360,
                "route": "main", "view": "post",
            })
    return rows


def cloudreach_plan() -> list[dict]:
    source = ROOT / "data/config/cloudreach_chapter.json"
    data = json.loads(source.read_text(encoding="utf-8"))
    runtime = json.loads((ROOT / "data/config/cloudreach_npc_runtime.json").read_text(encoding="utf-8"))
    facing = {row["id"]: row.get("facing_deg", 0) for row in runtime["npcs"]}
    return [{
        "family_type": "character", "slug": slug(obj["id"]),
        "subject": obj["name"], "position_xz": obj["position"],
        "band": obj["region_id"], "source": source.relative_to(ROOT).as_posix(),
        "authored_id": obj["id"], "heading_deg": (facing.get(obj["id"], 0) + 180) % 360,
        "route": "main", "view": "post",
    } for obj in data["npcs"]]


def stormwood_plan() -> list[dict]:
    rows: list[dict] = []
    for filename, list_key, name_key, family in [
        ("stormwood_npcs.json", "characters", "name", "character"),
        ("stormwood_trainers.json", "trainers", "display_name", "trainer"),
    ]:
        source = ROOT / "data/config" / filename
        data = json.loads(source.read_text(encoding="utf-8"))
        for obj in data[list_key]:
            rows.append({
                "family_type": family, "slug": slug(obj["id"]),
                "subject": obj.get(name_key, obj["id"]),
                "position_xz": obj["position"], "band": obj.get("region_id", ""),
                "source": source.relative_to(ROOT).as_posix(),
                "authored_id": obj["id"],
                "heading_deg": (obj.get("facing_deg", 0) + 180) % 360,
                "route": "main", "view": "post",
            })
    return rows


def main() -> None:
    data = json.loads(DEST.read_text(encoding="utf-8")) if DEST.exists() else {}
    data["meadows"] = meadows_plan()
    data["cloudreach"] = cloudreach_plan()
    data["stormwood"] = stormwood_plan()
    DEST.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
    print("Character posts: " + ", ".join(f"{biome}={len(rows)}" for biome, rows in data.items()))


if __name__ == "__main__":
    main()
