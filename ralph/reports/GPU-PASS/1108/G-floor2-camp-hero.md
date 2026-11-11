# G-floor2-camp-hero: larger trail-camp hero props and a bonfire stand heading (F38#32; GPU High)

Frames: `tb/gpu-frames-1108` 13a6d2ac4, High, seed 2042, `tb/floor2` 1078a130a.
- Capture: `phase2_capture_world_inventory.gd --biome=meadows`, subsets camp_tent, camp_bed and bonfire_fire.
- base = tree as is.
- arm = base + `FLOOR2-CAMP/overlay_camp_hero.json`:
  - tent 1.55×, bonfire 0.9×, stone ring 1.6×;
  - rope, bag, fern and clover dropped;
  - a single-sided sign;
  - `capture_stands.json` heading_overrides bonfire_fire heading 90, a **capture-staging change** on that frame.

Sets, on F38#32's brief and recorded defect as in `G-recheck-1111.md`, each stacked at full size:

| Set | Frames | Purpose |
|---|---|---|
| Row | camp_tent, camp_bed, bonfire_fire | the row figure |
| Tent + bed | camp_tent, camp_bed | game-only: same stand on both sides |
| Bonfire | bonfire_fire | partly staging: the stand heading changed |

Render check: tent 10.2%, bed 10.2%, bonfire 72.9% (stand moved) of pixels changed. Blank frames: 0 of 3 per side.

Batch `G-ch`:
- three code-blind judges, standard prompt;
- anchors: craft, f36_0_npc:C1 (7.47/7.53) and f10_2_r3_capacitor, so this is a confirming batch.

Fit: linear, slope 1.0967, intercept −0.0271, r 0.866, anchor RMSE 0.693. No warnings. The fit is looser than usual; read the paired gains.

## Verdict: DO NOT SHIP as one arm. The game-only frames lose 0/3; the row gain comes from the bonfire stand

| Set | Base | Arm | Gain | Judges preferring arm |
|---|---|---|---|---|
| F38#32 row (all three) | 5.97 | 6.48 | +0.51 | 3/3 |
| **Tent + bed (game-only)** | 6.59 | 6.15 | **−0.44** | **0/3** |
| Bonfire (staging: new heading) | 5.24 | 6.92 | +1.68 | 3/3 |

Raw Bar A, base → arm (judges a, b, c):
- Row: 5.2, 5.7, 5.5 → 5.7, 6.3, 5.8.
- Tent + bed: 5.8, 6.3, 6.0 → 5.2, 6.1, 5.6.
- Bonfire: 4.5, 5.1, 4.8 → 6.2, 6.6, 6.2.

Recorded defect, "small props overlap ... so individual objects are difficult to pick out":

| Set | Base | Arm |
|---|---|---|
| Tent + bed | PARTIAL 3/3 | PRESENT for judges a and c, PARTIAL for judge b |
| Bonfire | PRESENT 3/3 | PARTIAL 3/3 |

**The ship rule fails:** the game-only frames (tent, bed) lose at 0/3. All of the row's gain comes from the bonfire frame. Most of that is the capture stand turning away from the back of the sign, not the game change.

## Why the game-only frames lose
**The larger fire becomes a dominant flat flame card in the foreground (3/3):**
- judge a: "the flat flame card is huge in the left foreground and covers the fire ring and logs"; in the bed frame "the flame card overlaps the dwarf, so the fire, dwarf and crate fuse into one mass";
- judge c: "the flat orange flame cutout ... is huge and fills the left edge of the frame ... it overlaps the bearded NPC ... the worst element of the camp";
- judge b: "the flame card is even larger and covers the left foreground, hiding the stone ring and the log".

**Also on the arm (judges a and c):** the hare creature in the bed frame is "half hidden behind the trunk" (visible on base). The arm's spacing does not offset any of this.

## What the bonfire frame shows
- **Arm, the new heading:** "the best camp frame in the batch ... the whole clearing is staged around the fire ... props separate well on the pale pad" (3/3).
- **Base:** the camera "sits behind the camp gate. A huge dark-red sign beam with mirrored 'CAMP' lettering ... covers the lower-left half of the frame" (3/3).
- **Owner-rule flag:** all three judges flag that the beam's dark red-brown sits close to the reserved oxblood.

## Recommendation
1. **Split the arm.** Land the bonfire stand heading (heading 90) as its own capture-staging change. It is the whole of the gain, and the coordinator should decide whether to accept it as the row's camera.
2. **Rework the hero-prop part before landing:**
   - keep the fire small or out of the tent and bed foregrounds;
   - judge the decluttering (dropped rope, bag, fern and clover) and the single-sided sign without the scale-up.
3. **Fire asset (new_art, 3/3):** the fire is a flat faceted orange flame card. All three judges ask for a real campfire: logs and embers, layered or particle flame, smoke, and a warm firelight pool on the props. The judges see this as the main thing holding F38#32 down.
4. **Sign colour:** take the camp sign beam off the near-oxblood red-brown.
