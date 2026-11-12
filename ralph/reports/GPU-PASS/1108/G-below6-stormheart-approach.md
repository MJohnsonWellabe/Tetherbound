# G-below6-stormheart-approach: F41#1 Stormheart, new approach stands (GPU High)

**Frames:** `tb/gpu-frames-1108` 4ec37efdb, High. Both sides were captured from `tb/below6` 61a8487d2; its locations tool reads `approach_overrides`.
- **base:** `heartwood_1111` on, as main ships it, with the old stands.
- **arm:** `BELOW6-RAMP/overlay_approach.json`, which sets:
  - `heartwood_1111`;
  - `split_bark_finish.aged_heartwood_1112`;
  - `capture_stands.approach_overrides`. The approach camera moves to (−100, 5300), heading 0, looking up the road at the trunk.
- **Frames:** stormheart_tree and dynamo_core, day, approach and close: 4 per side.

**Render check:** blank frames 0 of 4 per side; script errors 0.

| View | Mean pixel difference | Notes |
|---|---|---|
| approach | 46.5 and 48.0 | new stand |
| close | 0.8 and 1.0 | unchanged |

- **Split wood not shown:** no arm frame faces the split, so this batch cannot judge `aged_heartwood_1112` (see "Not judged" below).

**Batch `G-sha`:**
- Three code-blind judges, standard prompt.
- Two F41#1 sets:
  - the row's 4 frames (2×2: approaches on top, closes below);
  - the 2 approach frames alone.
- Brief and recorded defect from `job.json`.
- Anchors: craft, f36_0_npc:C1 (7.47/7.53) and f10_2_r3_capacitor. This is a confirming batch.

**Fit:** linear, slope 1.4645, intercept −2.0299, r 0.917, anchor RMSE 0.553.

**Warning:** "some candidates lie more than 0.5 outside the anchors' measured range (extrapolated)". The base approach sits at 3.0–3.5 raw, below the lowest anchor.

## Verdict: SHIP. F41#1 rises 5.10 → 6.81 (+1.71, 3/3) and clears the 6 floor

| Set | Base raw → mapped | Arm raw → mapped | Gain | Prefer arm |
|---|---|---|---|---|
| **F41#1 row (4 frames)** | 5.0, 4.9, 4.7 → **5.10** | 6.1, 6.1, 5.9 → **6.81** | **+1.71** | 3/3 |
| F41#1 approach only (2 frames) | 3.4, 3.5, 3.0 → 2.80 | 5.7, 5.6, 6.0 → 6.42 | +3.62 | 3/3 |

**Recorded defect, for the approach frames:**
- base PRESENT 3/3;
- arm PARTIAL 3/3: it "reads as a giant tree base with root flares, an arched door and violet crystals under the purple storm sky", but the crown is cut off and no core shows from outside.

**Recorded defect, for the full row:** PARTIAL 3/3 on both sides. The interior close frames, which show the core, carry base.

**Base approach (3/3):** "camera jammed against the trunk ... vertical bark slabs and a flat saturated orange striped panel" that "looks untextured or back-facing". The arm's approach removes both.

**Close frames:** unchanged. The judges call the interior "the strongest Stormheart material in the batch". It has a white-blue lightning column, lantern walkways, and a board-like "ascend the core" read.

**Caution: the gain comes from new capture stands, not new art.**
- The old approach stands sat inside the bark. `G-below6-thundertunnel-heartwood.md` had already named "fix the approach stands" as the next F41#1 change, so this is the planned fix of a broken stand, not reframing to flatter a subject.
- The coordinator should confirm the new approach stand as F41#1's fixed camera set (`tools/visual_judge/camera_sets/`). Later rounds must use it on both sides.
- **Absolute level:** base here is 5.10, against the board's 5.78 and 5.66 for the heartwood arm in `G-below6-thundertunnel-heartwood.md`. Batch scales differ, so read the gain within this batch.

## Not judged
`split_bark_finish.aged_heartwood_1112` (the orange split slab) does not appear in any arm frame. A stand that faces the split is needed. Until a frame shows it, the arm can carry the flag only as untested, or drop it.

## What still holds F41#1 down (3/3)
1. **Crown cut off (scene):** the exterior frames show no branching crown and no core. Pull the approach stand back and up so the trunk, split, crown and lightning core read together against the sky.
2. **Interior materials (scene and new art):**
   - the banners are flat, saturated blue squares with a bolt glyph that read as UI decals (3/3);
   - a black pool with an orange or yellow crack line sits in the foreground; judge b says the orange is "close to warning red" (3/3);
   - the trunks are smooth mauve with no bark detail (2/3).
3. **No crown mesh (new art):** the exterior needs a branching living crown split by the core that reads from a distance. The teal-and-purple foreground roots look "rubbery" and pull focus (judge c).
