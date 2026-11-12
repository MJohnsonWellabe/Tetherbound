# G-floor2-harvest-presence-confirm: landing version, all three frames (F41#9; GPU High)

Frames: `tb/gpu-frames-1108` 8e1ff92e1, High, seed 2042, `tb/floor2` f79383083.
- Capture: `phase2_capture_world_inventory.gd --biome=stormwood --subset=stormwood__inventory__harvest__`.
- base = tree as is.
- arm = base + `FLOOR2-HARVEST/overlay_presence.json` (floor2_presence on), landing version:
  - satellites sit on each node's own footprint, with a keep-out from the trainer;
  - the ground lights are removed.
- GPU lane pre-check: the trainer is whole and clear in all three frames, and there is no clipped-white glare on the crown.

Two sets on F41#9's brief and recorded defect, each stacked at full size:

| Set | Frames | Purpose |
|---|---|---|
| Row | stormglass, stormglass_crown, glowmoss | the row figure |
| Two-frame | stormglass, glowmoss | the same layout as round 1 (`G-floor2-harvest-presence.md`), to check the hold |

Render check: stormglass 3.3%, crown 5.7%, glowmoss 2.8% of pixels changed. Blank frames: 0 of 3 per side.

Batch `G-hpc`:
- three code-blind judges, standard prompt;
- anchors: craft, f36_0_npc:C1 (7.47/7.53) and f04_6_r22, so this is a confirming batch.

Fit: linear, slope 1.1638, intercept −0.6344, r 0.942, anchor RMSE 0.335. No warnings.

## Verdict: SHIP. Row figure 6.81, +1.00, 3/3

| Set | Base | Arm | Gain | Judges preferring arm |
|---|---|---|---|---|
| **F41#9 row (all three frames)** | 5.81 | **6.81** | **+1.00** | **3/3** |
| Two-frame (stormglass, glowmoss) | 5.69 | 6.66 | +0.97 | 3/3 |

Raw Bar A, base → arm (judges a, b, c):
- Row: 5.7, 5.6, 5.3 → 6.6, 6.5, 6.1.
- Two-frame: 5.5, 5.6, 5.2 → 6.4, 6.4, 6.0.

Recorded defect:
- **Row:** base PRESENT for judges a and c, PARTIAL for judge b; arm PARTIAL for judges a and c, FIXED for judge b.
- **Two-frame:** base PRESENT for judges a and c, PARTIAL for judge b; arm PARTIAL for judges a and c, FIXED for judge b.

The board has 5.86; the landing version takes F41#9 to **6.81** over all three frames.

## Do stormglass and glowmoss hold against round 1?

| Batch | Base | Arm | Gain |
|---|---|---|---|
| Round 1, `G-hp` (two frames) | 5.56 | 7.18 | +1.62, 3/3, defect FIXED 3/3 |
| This batch (same two frames, landing version) | 5.69 | 6.66 | +0.97, 3/3, defect FIXED 1/3, PARTIAL 2/3 |

**The win holds (3/3, +0.97), but it is smaller.** The arm maps about 0.5 lower than round 1. The base levels are close (5.56 against 5.69), so most of the drop is likely real, not scatter. The likely cause is the landing changes:
- **Ground light:** with the ground lights removed, nodes sit on the ground with "no contact darkening" and "no shadow grounds either node" (judge c).
- **Glowmoss:** reads "more as mushrooms than as moss that glows" (judges a and c).

It is still a clear win, and the crown frame (newly judgeable) adds to it.

## What the judges see
- **The crown on the arm** is "the strongest single subject in the batch", a "tall violet cluster ringed with copper" (3/3). On base it is "a short cluster on a ring of navy blocks ... evenly spaced ... generated rather than authored" (judge c).
- **Problems on the arm (3/3):**
  - the copper reads as "flat bright orange ... melted plastic or cheese" or "orange putty", with no metallic sheen;
  - the base rocks are flat-shaded navy blobs with no wet-stone material;
  - the crystals are faceted, untextured low-poly (judge b);
  - judge c notes a slight purple bloom halo on the crown tip.
- **Scene (not scored, 3/3):** black-splotch turf, a flat lavender sky band and a cut-out tree line.

## What would add the most
1. **Node materials (scene, or new_art per judge a):**
   - metallic copper with roughness and specular highlights;
   - wet dark-stone base rocks;
   - translucent crystals with a light core.
2. **Grounding (scene):** contact shadows under the nodes, plus a modest emissive spill onto the ground for glowmoss, since the ground lights were removed.
3. **Stormwood sky and ground (scene):** layered storm clouds, distance fog, and replace the black-blotch ground.
