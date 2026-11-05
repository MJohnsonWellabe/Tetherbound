# v1/b26: Reedwing, Paddlenewt and Shadelet value lifts ship ON; Bramblebun stays OFF (flat)

**Arms:** `creatures_ralph_{bramblebun,reedwing,paddlenewt,shadelet}_value_lift`, albedo-only. Each lifted albedo uses midtone gamma 0.78 and saturation x1.12 about the per-pixel mean. These are the next-darkest live remake albedos without an albedo arm.

**Frames:** `capture_f36_poses.gd --species=bramblebun,reedwing,paddlenewt,shadelet --whole-body --context`, base (OFF) and candidate (ON) from one run. Each species is its own stage set (hit 50/100, faint 50/100). CPU, Compatibility.

**Yardstick:** JUDGE_PROMPT verbatim; 3 anchor pairs (craft, f36_0_npc C2, f10_2_r3 capacitor); three fresh code-blind judges; `calibrate.py` linear, slope 1.10, intercept -0.17, r 0.83.

| Species | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand |
|---|---|---|---|---|
| Reedwing | 6.04 | **6.70** | +0.66 | 5.9 5.4 5.6 / 6.4 6.0 6.3 |
| Paddlenewt (and Riftfrill, same albedo) | 6.15 | **6.70** | +0.55 | 6.0 5.5 5.7 / 6.4 6.1 6.2 |
| Shadelet | 5.97 | **6.26** | +0.29 | 5.8 5.5 5.4 / 6.1 5.7 5.7 |
| Bramblebun | 6.78 | 6.78 | 0 | 6.3 6.4 6.2 / 6.5 6.3 6.1 |

**Verdict:**
- Reedwing, Paddlenewt and Shadelet ship ON. Every judge scored each candidate higher.
- Bramblebun stays OFF. Its mid-brown body was never the dark-body problem.
- Riftfrill was not staged. It wears Paddlenewt's albedo, so the lift reaches it too.

**What the judges still name:**
- **Shadelet:** the tail stands rigid and upright in faint, and the body floats above its shadow in hit-react mid.
- **Paddlenewt:** the faint collapses into a spotted blob, and the body floats in hit-react mid.
- **Bramblebun:** the bark plates read as white porcelain.
- **Reedwing:** no elemental trait reads.

**Test:** `test_dark_value_lift_flags` adds Reedwing (6.70), Paddlenewt (6.70) and Shadelet (6.26).
