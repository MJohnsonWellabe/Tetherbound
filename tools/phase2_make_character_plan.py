"""Pin authored Meadows villager and trainer post locations for Phase 2."""

from __future__ import annotations

import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / "tools/phase2_character_plan.json"


def slug(value: str) -> str:
    return re.sub(r"[^a-z0-9]+", "_", value.lower()).strip("_")


def main() -> None:
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
    data = json.loads(DEST.read_text(encoding="utf-8")) if DEST.exists() else {}
    data["meadows"] = rows
    DEST.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
    print(f"Meadows character posts: {len(rows)}")


if __name__ == "__main__":
    main()
