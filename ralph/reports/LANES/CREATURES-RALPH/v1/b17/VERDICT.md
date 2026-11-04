# Visual lane v1/b17: Meadows Blender ridge ring (F38#24) (4 Nov 2026, ~02:45 UTC)

**Arm:** `meadows_ridge_vl.json` ON vs OFF. ON adds one continuous 360-degree Blender ridge ring that replaces the procedural FarRanges/Foothills rings. Frames: `phase2_capture_routes.gd` for the three F38#24 frames (Warrens walk_02/walk_03, stronghold route). Base and candidate were captured on the same branch head. CPU, Compatibility.

**Yardstick:** JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges. `calibrate.py`: linear, slope 1.40, r 0.97, anchor RMSE 0.33, no warnings.

| Row | Item | CPU base (mapped) | Ridge ON (mapped) | Decision |
|---|---|---|---|---|
| F38#24 | distant mountains | 4.19 | **3.44 (-0.75)** | **OFF** (worse) |

**Why it lost (3/3 judges):** in the stronghold route frame, the only one that shows the horizon, the ridge reads as "a pale, washed, smeared wall with a hard vertical edge, standing like a cliff curtain right behind the meadow". The shipped rings read as soft hills with "a faint blue ridge at the far right, closer to the key art's cool blue distance".

Two causes are likely:
- **Washed colour:** the ridge shader's fog keep (0.6) flattens it toward the sky colour.
- **Too near and too high:** the ring's near radius (1400 m) and height put a high flat face close to the meadow.

**The row's real blocker:** the two Burrow Warrens frames show a camera-occluding terrain mass and floating dark slab undersides crossing the sky (the Warrens earth-bank shell). All judges call these "the dark slash shapes" of the recorded defect, and no backdrop change touches them.

**Next for F38#24:**
1. The Warrens bank-shell occlusion. This is the Meadows region lane's area; I am flagging it to them via this verdict.
2. A ridge r2 that is further, lower, darker and more layered (two bands with aerial fade), with a peak over the stronghold bearing. It ships only on a judged gain.
