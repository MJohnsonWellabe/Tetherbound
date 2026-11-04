# v1/b25: Stormraven value lift ships ON; Fulgocobra, Voltwig, Mirejaw stay OFF (flat)

**Arms:** `creatures_ralph_{stormraven,fulgocobra,voltwig,mirejaw}_value_lift` in `creature_coat_flags.json`. Each is the same albedo-only lift as b21-b24 (midtone gamma 0.78, saturation x1.12).

**Frames:** `capture_f36_poses.gd --species=... --whole-body --context`, with base (OFF) and candidate (ON) captured in one run. Each species is its own stage set (hit 50/100, faint 50/100). CPU, Compatibility.

**Yardstick:**
- JUDGE_PROMPT verbatim, 3 anchor pairs (f36_0_gap C5, craft, f36_0_npc C3), three fresh code-blind judges.
- `calibrate.py`: linear, slope 1.61, intercept -3.29, r 0.86.

| Species | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand |
|---|---|---|---|---|
| Stormraven | 5.89 | **6.59** | +0.70 | 5.5 6.0 5.6 / 6.0 6.4 6.0 |
| Voltwig | 6.53 | 6.59 | +0.06 (flat) | 6.0 6.3 6.0 / 6.0 6.3 6.1 |
| Mirejaw | 5.89 | 5.84 | -0.05 | 5.8 5.9 5.4 / 5.8 5.8 5.4 |
| Fulgocobra | 5.78 | 5.78 | 0 | 5.5 5.9 5.5 / same |

**Verdict:**
- **Stormraven ships ON.** All three judges see the stronger cyan edge on its head and eye.
- **The other three stay OFF.** The judges call each pair identical. A gamma lift on a near-black body (cobra hood, salamander) stays near-black, and Voltwig is already mid-green.

**What the judges still name (top changes):**
- Dark heads (cobra hood, salamander, raven tail) still merge with the backdrop and their shadow. The next arm for these is a face/eye accent, not more albedo lift.
- The raven's tail fans into a flat black slab, and one wing juts upright at faint end.
- Cobra hit and faint poses barely differ from idle.

**Test:** `test_dark_value_lift_flags` adds Stormraven (6.59).
