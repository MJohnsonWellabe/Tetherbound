# G-floor2-camp-r2: camp declutter, plain-wood gate, bonfire stand heading 90 (F38#32 attempt 2; GPU High)

**Frames:** `tb/gpu-frames-1108` 4eb98c34. High, seed 2042, tree `tb/floor2` 7ab457021.
- **Capture:** `phase2_capture_world_inventory.gd --biome=meadows`, subsets camp_tent, camp_bed and bonfire_fire.
- **base:** `trail_camp` OFF.
- **arm:** base plus `FLOOR2-CAMP/overlay_camp_hero.json`:
  - declutter only, with no scaling;
  - a single-sided sign;
  - the gate beam in plain weathered wood;
  - the bonfire stand at heading 90.
- **armplanned:** the extra bonfire frame from the planned stand. It has no sign in view, so it was **not judged**, as the coordinator asked.
- **The base bonfire frame comes from a broken stand.** The GPU lane found that the old stand put the trainer on top of the gate (an inside-collision reseat). So the bonfire gain mostly measures the stand fix, not the game change.

**Render check:**
- Pixels changed: tent 4.2%, bed 3.8%, bonfire 67.2% (the stand moved).
- Blank frames: base 0 of 3, arm 0 of 3, armplanned 0 of 1.

**Batch `G-c2`:**
- Three code-blind judges, standard prompt.
- Anchors: craft, f36_0_npc:C1 (7.47/7.53) and f10_2_r3_capacitor. This is a confirming batch.
- Sides are stacked at full size:
  - Tent + bed: two frames, game-only (same stand on both sides).
  - Bonfire: one frame.

**Fit:** linear, slope 1.1469, intercept −0.3353, r 0.901, anchor RMSE 0.601. No warnings.

## Verdict: tent and bed are level (+0.07, 2/3, no loss); the bonfire frame gains +1.83 (3/3, mostly the stand fix)

| Set | Base | Arm | Gain | Judges preferring arm | Raw base → arm (judges a, b, c) |
|---|---|---|---|---|---|
| **Tent + bed (game only)** | 6.78 | 6.85 | **+0.07** | 2/3 (judge b level) | 6.2, 6.2, 6.2 → 6.3, 6.2, 6.3 |
| Bonfire (broken base stand → heading 90) | 5.21 | 7.04 | +1.83 | 3/3 | 4.8, 5.1, 4.6 → 6.5, 6.4, 6.4 |
| F38#32 row (mean of the 3 frames) | 6.26 | 6.91 | +0.66 | n/a | n/a |

- **Ship rule:** passes on both sets. Every gain is above 0, at least 2/3 judges prefer the arm, and no frame loses.
- **Compared with attempt 1** (`G-floor2-camp-hero.md`), the tent and bed frames no longer lose: they went from −0.44 at 0/3 to +0.07 at 2/3. So dropping the scale-up removed the flat-flame-card foreground.
- **The game-only gain is within noise.** The arm adds almost nothing on its own. The row's lift is the stand fix.

**Recorded defect,** "small props overlap ... difficult to pick out":
- Tent + bed: PARTIAL 3/3 on both sides.
- Bonfire: base PRESENT 3/3; arm PARTIAL 3/3.

**Owner-rule flag (red and oxblood):**
- On the **base** bonfire frame, all three judges flagged the "CAMP" sign beam as dark red-brown close to oxblood. Judge c added that it reads as stained wood rather than faction red.
- On the arm bonfire frame, no judge flagged red. Judge b noted only that the "wooden gate or sign on the left reads poorly against the trees". The plain-wood gate removes the flag.

## What the judges say
- **Arm bonfire, heading 90:** "reads as an authored clearing ... props mostly separated on bare ground". Remaining problems:
  - Grass swallows the bases of the barrel, bucket and crate (3/3).
  - Light is flat midday with weak contact shadows (judges a and c).
- **Base bonfire:** "the camera sits behind a large dark-red CAMP sign ... with mirrored text" and a boulder. The camp is hidden (3/3).
- **Tent and bed, both sides:** these problems are unchanged by the arm.
  - A flat orange flame billboard is cropped at the left edge (3/3).
  - Planks lie at odd tilts (judges b and c).
  - The NPC overlaps the fire in the bed view (3/3).
- **Top changes named for the camp:**
  - Replace the flat flame card with a lit fire and ember effect: new_art for judges a and c, scene for judge b.
  - Trim grass around the props and add contact shadows (scene).
  - Ground and space the planks (scene).

## Recommendation
1. **Land the arm.**
   - It passes the ship rule with no frame losing.
   - It takes the near-oxblood beam off a friendly element.
   - It fixes a stand that seated the trainer on the gate.
   - The row moves from 6.26 to **6.91** on these three frames.
2. **Not at 7.5.** The bonfire frame alone is 7.04. The tent and bed frames (6.85) are capped by the flat flame card.
3. **Next swing:** a real campfire mesh with an ember effect (Meshy or a particle fire), plus a grass-clear radius around camp props. The judges name these on every frame.
