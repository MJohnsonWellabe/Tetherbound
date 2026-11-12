# G-things-stormrim: player rim light off in Stormwood (F41#18, F41#15; GPU High)

## Verdict: SHIP
Every set gains, all three judges prefer the arm in every set, and nothing loses.

| Set | Base | Arm | Gain | Prefer arm |
|---|---|---|---|---|
| **F41#18 row** (Dace, Varga, Sable, inventory camera) | 5.60 | **6.22** | **+0.62** | 3/3 |
| F41#18 dialogue (Dace, Varga, Sable) | 6.18 | 6.63 | +0.45 | 3/3 |
| F41#15 row (Marrow ×2, Nysa) | 6.18 | 6.59 | +0.41 | 3/3 |
| Stormwood dialogue ride-along (Sera, Ivo, Tamsin) | 6.42 | 6.87 | +0.45 | 3/3 |

- **F41#18 clears the 6 floor:** 5.60 → 6.22. The +0.62 gain lets the change land on its own (over 0.5).
- **No loss** across the four sets, including the F41#18 no-loss frames the GPU lane named.

## Frames
- **Source:** `tb/gpu-frames-1108` section `G-things-stormrim` (eae078802), High.
- **Capture:** `phase2_capture_dialogue.gd --biome=stormwood --seed=2042 --fixed-fps 20`, every Stormwood post. 86 frames per side; dialogue blend 1.0. 0 script errors, 0 blank frames. The exit 1 is the known catalogue count check (86/45).
- **Build:** `tb/things` f468ccbe3 on both sides, no import.
  - **base:** `player_character_rim_scale` 1.0.
  - **arm:** `THINGS-STORMRIM/overlay_player_rim_off.json`, which sets it to 0.0 in `stormwood_look.json` and `stormwood_surge.json`.
- **Render check:**
  - Mean per-frame difference over all 86 frames is 2.8. The largest is Nysa's dialogue frame (8.0).
  - By eye, the player's head at the left edge goes from a white blob to readable hair and face. No frame gets hotter.
- **GPU lane pre-check:**
  - Near-white share of the head crop: Nysa 19.5% → 0.6%, Sera 14.8% → 2.0%.
  - Above the dialogue box, averaged over the 43 dialogue frames: 1.20% → 0.26%.

## Batch `G-srim`
- Three code-blind judges, standard prompt, four candidate sets of three frames each, stacked.
- Anchors: craft, f36_0_npc:C1 and f04_6_r22. This is a confirming batch.
- **Fit:** linear, slope 1.2285, intercept −0.9079, r 0.961, anchor RMSE 0.27. No warnings.

| Set | Base raw | Arm raw |
|---|---|---|
| F41#18 row | 5.0, 5.3, 5.6 | 5.5, 5.8, 6.1 |
| F41#18 dialogue | 5.6, 5.8, 5.9 | 6.0, 6.2, 6.2 |
| F41#15 row | 5.6, 5.8, 5.9 | 6.0, 6.1, 6.2 |
| Ride-along | 5.8, 6.0, 6.1 | 6.3, 6.4, 6.3 |

### What the judges see (3/3)
- **Base:**
  - The player trainer is "blown out to a pinkish-white glow" in every frame where he appears: the field frames and the left edge of the conversations.
  - Marrow's hair has a white bloom halo.
- **Arm:** the trainer "reads cleanly (blue shirt, brown hair, orange pack)".
- **F41#15 recorded defect** (speaker hidden): FIXED on both sides. The stormpost clearance holds.
- **F41#18 recorded defect:** PARTIAL on both sides.

## What still holds the rows down (3/3 unless noted)
1. **F41#18: bleached uniforms, no rank.**
   - In the world the officers render pale lilac or silver-grey, "ghostly", while their portraits show near-black uniforms.
   - At the inventory distance there are no rank or individual markers.
   - Judges ask for darker uniform values that match the portraits, and a readable rank badge or trim. One judge says copper, not oxblood. Two call this scene work and one calls it new art.
2. **Stormwood sky and ground.**
   - A flat lavender sky band with blocky clouds and flat-shaded canopies.
   - A harsh, flat green ground, and bright orange veins on the black path (2/3).
3. **F41#15 stage.** Marrow's two frames sit on "a flat plank deck with an untextured, wall-like bark trunk", which reads as a test box.
4. **Creature tints.** The salmon-pink bears and saturated cobalt ravens read as placeholder colour.
5. **Arm only, minor.** In the Tamsin frame the cobalt raven sits directly on her head "like a hat". This is scene motion between captures, not the rim change.

## Recommendation
1. **Land `overlay_player_rim_off`.** F41#18 is now 6.22, above the 6 floor.
2. **Next lever for F41#18:** world uniform albedo closer to the portraits (darker), plus a rank trim. Re-judge on the same frames.
3. **Ride-alongs:** fix the bear and raven tints, and give the Marrow deck stage authored backdrop dressing.
