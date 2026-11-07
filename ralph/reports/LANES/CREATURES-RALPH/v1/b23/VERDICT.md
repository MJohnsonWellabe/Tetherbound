# v1/b23: stage value lifts for Stormbrush, Thundertunnel and Tuskroot ship ON

**Arms:** in `creature_coat_flags.json`, `creatures_ralph_{stormbrush,thundertunnel,tuskroot}_value_lift`. Each is a value-lifted copy of the live albedo (midtone gamma 0.78, saturation x1.12). Thundertunnel's is lifted from its shipped velvet coat, and Ashtusk shares Tuskroot's mesh and coat. Only the albedo changes.

**Frames:** `capture_f36_poses.gd --species=stormbrush,thundertunnel,tuskroot --whole-body --context`, base (all OFF) and candidate (all ON) from one run (`q_lift3.sh`). Each species is its own stage set (hit 50/100, faint 50/100). CPU, Compatibility.

**Yardstick:** JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges, `calibrate.py` (linear, slope 1.12, intercept -0.55, r 0.92).

| Species | Base (mapped) | Candidate (mapped) | Gain | Raw base / cand |
|---|---|---|---|---|
| Tuskroot | 6.57 | **7.16** | +0.59 | 6.4 6.1 6.6 / 6.9 6.6 7.2 |
| Thundertunnel | 5.64 | **5.78** | +0.14 | 6.0 5.2 5.4 / 6.1 5.3 5.6 |
| Stormbrush | 6.31 | **6.42** | +0.11 | 6.4 5.6 6.4 / 6.3 5.8 6.6 |

**Verdict:** all three gain, so all three ship ON under the owner's 4 Nov rule. Stormbrush is the weakest: two judges higher, one 0.1 lower. Test: `tests/test_dark_value_lift_flags.gd`.

**What the judges still name:**
- **Thundertunnel:** an upright, clay-like body with a speck face (new art).
- **Stormbrush:** a faint end that flattens into a dark rug, and no rim light.
- **Tuskroot:** a small face and no visible element glow.
