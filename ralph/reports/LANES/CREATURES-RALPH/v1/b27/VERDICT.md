# v1/b27: Staticub, Riverdrake, Riptusk and Sirenseal value lifts ship ON

**Arms:** `creatures_ralph_{riverdrake,staticub,sirenseal,riptusk}_value_lift`. Each is an albedo-only coat flag using the same recipe as b21-b26. Staticub and Sirenseal are lifted on their live r10 albedo.

**Frames:** `capture_f36_poses.gd --species=riverdrake,staticub,sirenseal,riptusk --whole-body --context`, base (OFF) and candidate (ON) from one run (captured 5 Nov; judged 7 Nov after the usage-limit pause, with no change to the arms in between). Each species is its own stage set (hit 50/100, faint 50/100). CPU, Compatibility.

**Yardstick:** JUDGE_PROMPT verbatim; 3 anchor pairs (craft, f36_0_npc C6, f36_0_gap C2); three fresh code-blind judges.

`calibrate.py` gave a linear fit with slope 0.79, intercept 1.34 and **r 0.51, a weak fit**. The npc C6 anchor pair scored identically on both sides, so the mapping is close to identity here. The raw gains below carry the verdict.

| Species | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand (j1 j2 j3) |
|---|---|---|---|---|
| Staticub | 6.59 | **6.80** | +0.21 | 6.5 6.8 6.6 / 6.7 7.0 7.0 |
| Riverdrake | 6.37 | **6.69** | +0.32 | 6.2 6.5 6.4 / 6.6 6.8 6.9 |
| Riptusk | 6.22 | **6.32** | +0.10 | 6.0 6.3 6.2 / 6.2 6.4 6.3 |
| Sirenseal | 6.53 | **6.61** | +0.08 | 6.2 6.9 6.6 / 6.4 6.9 6.7 |

**Verdict:** all four ship ON under the owner rule (every judged improvement ships ON).
- Staticub, Riverdrake and Riptusk: all three judges scored the candidate higher.
- Sirenseal: two judges scored it higher and one equal, with none lower. This is the smallest gain shipped so far. By comparison, Voltwig in b25 had one judge higher and two equal, and was called flat.

**What the judges still name:**
- **Riptusk:** full-body tiled stone plates (over the creature rule's "partial plates").
- **Sirenseal:** dense all-over glow markings, and the head dips into the floor at faint mid.
- **Staticub:** hit react reads close to standing, and the veins fade at faint end.
- **Riverdrake:** glossy, toy-like blue.

**Test:** `test_dark_value_lift_flags` adds the four. It now also resolves r10 albedo paths.
