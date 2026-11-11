# G-floor2-harvest-presence: bigger harvest nodes with satellites and mild glow (F41#9; GPU High; 2 of 3 frames)

Frames: `tb/gpu-frames-1108` 8333275fc, High, seed 2042, `tb/floor2` c7612681b.
- Capture: `phase2_capture_world_inventory.gd --biome=stormwood --subset=stormwood__inventory__harvest__`.
- base = tree as is.
- arm = base + `FLOOR2-HARVEST/overlay_presence.json` (`stormwood_harvest_hero2.json` floor2_presence): the nodes grow, gain small satellite copies, get emission, and add violet or teal ground light.

**Two of the row's three frames are judged: stormglass and glowmoss.** The third frame, stormglass_crown, failed the GPU lane's pre-check and is held: a satellite cluster sits at the trainer's feet, with prisms in front of the leg and a clipped-white glare.

Sheet: stormglass above glowmoss, full size, on F41#9's brief and recorded defect ("Several harvest nodes look like ordinary stone mushrooms trees or foliage without a readable cue for their named Stormwood material").

Render check: 4.0% (stormglass) and 3.6% (glowmoss) of pixels changed. Blank frames: 0 of 2 per side.

Batch `G-hp`:
- three code-blind judges, standard prompt;
- anchors: craft, f36_0_npc:C1 (7.47/7.53) and f04_6_r22, so this is a confirming batch.

Fit: linear, slope 1.3459, intercept −1.7027, r 0.963, anchor RMSE 0.268. No warnings.

## Verdict: SHIP. +1.62, 3/3 prefer, on two of the row's three frames

| Row (frames) | Base | Arm | Gain | Judges preferring arm | Board |
|---|---|---|---|---|---|
| F41#9 harvest resource identity (stormglass, glowmoss) | 5.56 | **7.18** | **+1.62** | **3/3** | 5.86 |

Raw Bar A, base → arm (judges a, b, c): 5.6, 5.3, 5.3 → 6.6, 6.6, 6.6. Mapped arm: 7.18 for every judge.

Recorded defect:
- base: PRESENT for judges a and c, PARTIAL for judge b;
- arm: FIXED 3/3.

**Note.** 7.18 covers two of the row's three frames. The row figure needs the held stormglass_crown frame, fixed so no satellites stand at the trainer's feet. At 7.18 on these two, F41#9 counts under the close-out exception for a near-bar change.

## What the judges see
- **Arm, stormglass:** "a hero crystal spire with satellite clusters, soft emission and copper accents"; "it reads as a named storm-glass resource from a distance"; it matches "the board's copper-and-glass highlights" (3/3).
- **Arm, glowmoss:** "teal moss pads with glowing cyan caps spreading as satellites, so it reads as bioluminescent" (3/3).
- **Base:** the stormglass is "small ... with little glow". The glowmoss is "a small dark-blue lump with a few white mushroom caps ... a generic mushroom rock" (3/3).
- **What remains on the arm:**
  - **Satellites:** spaced "evenly ... around the main node, which reads as generated" (judges b and c).
  - **Base stones:** "flat, low-detail purple-navy blobs that read as placeholder geometry", "plasticky and toy-like" (3/3). Judge c calls this new_art: sculpted, weathered, copper-veined dark stone and a mossy root mound.
  - **Ground light:** no visible light spill onto the ground. This agrees with the GPU lane's pre-check (no distinct violet ground pool).
  - **Rest of the frame (not scored):** flat green ground with black blotch decals, and a flat banded purple sky.

## What would add the most
1. **Satellites (scene):** break the even ring into irregular, partly buried clusters, with stronger emissive spill onto the ground.
2. **Base rocks (new_art):** sculpted, weathered base rocks for the nodes.
3. **Crown frame:** fix the satellite placement at the trainer's feet so the third frame can be judged and the row figure completed.
