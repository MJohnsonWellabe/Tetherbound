# F09#3 round 7: pocket lures from the road, and the ordinary walk from an earned save

## Changes (presentation only; `data/config/stormwood_pockets.json`, `scripts/world/stormwood_pickup_runtime.gd`)

- **Gate/reward beam.** The beam is alpha-mixed instead of additive, drawn in the pocket's saturated tint with a pale core. Before this change it washed out against the pale storm horizon (judge 14).
  - Gate beam: 3.4 m wide, 24 m tall, alpha 0.72.
  - It now stands `gate_forward_m` 3 m in front of the gateway opening, on the road side of the trunks. Before, it hid behind a gate trunk.
- **Junction lamps.** Lantern 2.1 → 2.8, flame 0.24 → 0.32 m at energy 8 → 12, halo 1.2 → 2.0 m at alpha 0.6 → 0.8, light 2.2 → 3.0.
  - Deepwood's round-6 lamp override is dropped; it uses the new defaults.
  - Dynamo gets its own larger lamp (see r7d).
- **Trail stones.** They start at the junction (`start_m` 2.4 → 0) and are larger (1.6–2.1×, near 1.8×), so the trail visibly leaves the road.
- **Conductor.** Deeper cyan light and beam (alpha 0.95, 4.2 m wide).
- **Dynamo.** Beam cut to 8 m (the top edge cut it off), alpha 0.95.
- **Scatter bake.** `data/scatter/stormwood/manifest.json` is re-baked. Only the fingerprint changed; the scatter content is identical (kept 34638).

## Renders

- **Tool:** `tools/capture_stormwood_pocket_walks.gd --fast`, local xvfb + opengl3 at 1920×1080. The adapter is Mesa llvmpipe (LLVM 20.1.2), software GL.
- **Command:** `xvfb-run -a -s "-screen 0 1920x1080x24" godot --path . --rendering-driver opengl3 --resolution 1920x1080 --script tools/capture_stormwood_pocket_walks.gd -- --out=<dir> --fast`
- **Frame sets:** `road_r7b/` holds the five road frames of round 7b. `road_r7c/` holds all 20 frames of round 7c plus `frames_walks.json`.
- **Staging, disclosed:** the tool's own staging, which is a teleport to the stand, day pinned, Surge at Calm, and the Rootgate flag.

## Code-blind judges (subagents; they saw only the five road frames under shuffled neutral letters)

**Question:** "Would an ordinary player walking this road notice a side place worth a detour here?" The target is at least 4 of 5 YES.

| Pocket | r6 (judge 14, earlier) | r7b (`blind_key_r7b.json`: A–E) | r7c (`blind_key_r7c.json`: P–T) | **r7d** (`blind_key_r7d.json`: J–N) |
|---|---|---|---|---|
| verge_ash_hollow | AMBIGUOUS | **YES** (B) | **YES** (T), "clearest read" | **YES** (L) |
| hollows_moss_nook | PROBABLY | **YES** (E) | **YES** (Q) | **YES** (N) |
| deepwood_ridge_shelter | PROBABLY | **YES** (D) | **YES** (S) | **YES** (K) |
| conductor_ridge_cleft | YES | PROBABLY (A) | AMBIGUOUS (P) | PROBABLY (J) |
| dynamo_scorch_pen | NO | PROBABLY (C) | PROBABLY (R) | **YES** (M), "brightest element in the frame" |
| **YES** | 1/5 | **3/5** | **3/5** | **4/5** |

**Judges' reasons for the two misses (r7c):**
- **Conductor (P):** "Impossible to miss, but it does not read as a side place". The road bends right at the junction, so from the stand the gate stands dead ahead, where the road seems to end. This is a geometry and framing issue, not a lure one. A player on that road walks straight into the pocket.
- **Dynamo (R):** "Small and far away … near the top edge". A low line of stones leads to it.

**Observation both judges made:** every one of the five lures was identified as a strong landmark in its frame. The r7c judge wrote: "It is a strong landmark in every frame."

## Round 7d (final): Dynamo's own larger junction lamp

- **Change:** Dynamo alone gets its own larger junction lamp: lantern 3.6, flame 0.42 m, halo 3.0 m at alpha 0.9.
- **Render:** only `dynamo_scorch_pen` was re-rendered (`--pockets=dynamo_scorch_pen`, `road_r7d/`). The other four views are the r7c frames; their config did not change in r7d.
- **Judge:** a fresh code-blind judge on a new shuffle gave **4 of 5 YES** (K, L, M, N). Conductor (J) got PROBABLY: "very noticeable, but it sits straight ahead on the road, not beside it". That is the road-bend geometry noted above.
- **Record:** the three judges' reports are in `judge_r7b.txt`, `judge_r7c.txt` and `judge_r7d.txt`.

**Verdict: 4/5 ≥ 4/5 target. F09#3 lure half MET on r7d.**

## Ordinary walk witness from an earned save

`pocket_walks_from_3_rootgate.txt`:

```
godot --headless --path . --script tests/smoke_stormwood_pocket_walks.gd -- --from-save=user://swcp_a/3_rootgate
```

- **Result:** "102 checks, 0 failures", EXIT 0, 0 SCRIPT ERROR.
- **Start:** the title's Load of the continuous run's `3_rootgate` checkpoint (`../full_run/checkpoints/3_rootgate.tgz`). The Rootgate is earned, so seams 1 and 3 of the smoke are not used.
- **Per pocket:** a joypad-stick walk from its road (145–384 m) to the mouth, a reward claimed with `interact` and its receipt checked, and the back-wall negative control PASS for all five.
- **Remaining seams, disclosed:** one teleport per pocket onto its road, 32 m before the junction; waiting for Calm at time_scale 8.
