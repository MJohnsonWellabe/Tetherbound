#!/usr/bin/env python3
"""Gate A batch 7: close verified owner-play world regressions.

Current inspection found water, ranger/cottage doors and full authored trail
baking already exist. The pond mill is the real door defect: it has a visible
Door_1_Flat leaf but no door spec and one giant collider across the whole tower.
This patch gives that existing leaf the same physical doorway contract every
other enterable village building uses.
"""
from pathlib import Path


def rep(root: Path, rel: str, old: str, new: str) -> bool:
    path = root / rel
    text = path.read_text(encoding="utf-8")
    if new in text:
        return False
    n = text.count(old)
    if n != 1:
        raise RuntimeError(f"{rel}: batch7 expected one anchor, got {n}")
    path.write_text(text.replace(old, new, 1), encoding="utf-8")
    print(f"batch7 patched {rel}")
    return True


def apply(root: Path) -> bool:
    changed = False

    old = '''      "colliders": [
        {
          "at": [
            0.0,
            4.7,
            0.0
          ],
          "size": [
            6.3,
            9.4,
            6.3
          ],
          "_why": "the tower"
        },
        {
          "at": [
            -4.0,
            2.1,
            0.0
          ],
          "size": [
            0.9,
            4.4,
            4.6
          ],
          "_why": "the wheel, for the player and the camera arm"
        }
      ],
      "retint": {'''

    new = '''      "_why_colliders_gate_a": "Gate A owner-play fix. The mill always had a real Door_1_Flat leaf at its front centre, but its collider was one 6.3x9.4x6.3 solid box, so the visible door could never become a real entrance. This uses the same doorway-hole contract as cottage_a/cottage_b/ranger_station/inn: side and rear walls, two front returns, a lintel, then a ceiling/upper-facade box whose bottom begins at first-storey wall-top. The water-wheel collider remains independent.",
      "colliders": [
        { "at": [-3.0, 1.56, 0.0], "size": [0.45, 3.12, 6.4], "_why": "west ground-floor wall" },
        { "at": [3.0, 1.56, 0.0], "size": [0.45, 3.12, 6.4], "_why": "east ground-floor wall" },
        { "at": [0.0, 1.56, -3.0], "size": [6.4, 3.12, 0.45], "_why": "rear ground-floor wall" },
        { "at": [-2.0, 1.56, 3.0], "size": [2.4, 3.12, 0.45], "_why": "front wall left of the 1.6m doorway" },
        { "at": [2.0, 1.56, 3.0], "size": [2.4, 3.12, 0.45], "_why": "front wall right of the 1.6m doorway" },
        { "at": [0.0, 2.71, 3.0], "size": [1.6, 0.82, 0.45], "_why": "lintel above the 2.3m doorway" },
        { "at": [0.0, 6.26, 0.0], "size": [6.4, 6.28, 6.4], "_why": "ceiling and upper facade; bottom is y=3.12 so the ground-floor room stays walkable" },
        { "at": [-4.0, 2.1, 0.0], "size": [0.9, 4.4, 4.6], "_why": "water wheel, for player and camera arm" }
      ],
      "door": {
        "leaf_module": "Door_1_Flat",
        "at": [0.0, 0.0, 3.0],
        "_why": "Gate A: the existing mill leaf now uses village_door.gd exactly like the other enterable village/pond buildings."
      },
      "retint": {'''
    changed |= rep(root, "data/config/building_prefabs.json", old, new)

    return changed
