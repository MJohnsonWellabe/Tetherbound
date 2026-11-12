# G-rescore-tier2-batch-2: 13 more F36 (1) pose rows re-scored on main (GPU High)

## Frames
- **Source:** `tb/gpu-frames-1108`, main 0058b0d6c as it is, High, one-sided.
- **Capture:** `capture_f36_poses.gd --whole-body --context`.
- **Section a (3e31d870e):** abyssal guardian, cannonback, galewisp (+ fly_grip), mangrove monitor, reedwing, stormbrush, tempestwing.
- **Section b (1c2bfd173):** voltarach and the water variants: abyssal guardian, cragclaw, mangrove monitor, mirejaw, mosshell (+ ride and swim).
- **Crop and brief:** the same as batch 1. Crop 560,200 1000×640 at 1080p. Tiles are standing (hit 000), hit 050, faint 050 and faint 100. Galewisp adds fly_grip 050/100; water mosshell adds ride 050 and swim 050.
- **Render check:** blank frames 0 of 75 and 0 of 70.
  - Voltarach's legs fit inside the crop.
  - Water abyssal guardian's faint 100 is pulled back but readable.

## Batches
- **G-r3a** (section a) and **G-r3b** (section b), three fresh code-blind judges each, standard prompt.
- **Brief:** each species uses its F36 (1) brief, with its 24 Oct roster causes as the recorded defects.
- **Anchors:** craft, f36_0_npc:C1 (7.47/7.53) and f04_6_r22. Both are confirming batches.
- **Fit, G-r3a:** linear, slope 1.2583, intercept −1.0073, r 0.938, RMSE 0.346.
  - Warning: stormbrush meets the bar only above the top anchor (7.53). This is the confirming batch.
- **Fit, G-r3b:** linear, slope 1.1084, intercept −0.0237, r 0.916, RMSE 0.399. No warnings.
- **Reading the changes:** board scores come from the 24 Oct roster's judge pool, so read each change as indicative (about ±0.3).

## Results (sorted by change)

| Row | Board | Main now | Change | Raw a, b, c | Recorded defects |
|---|---|---|---|---|---|
| **F36#72 Stormbrush** | 6.82 | **7.68** ↑top | **+0.86** | 6.5, 7.2, 7.0 | plastic-blue fur FIXED 3/3; tail/bulk over ruler PARTIAL 3/3 |
| F36#91 Water Cragclaw | 6.32 | 6.92 | +0.60 | 6.4, 6.2, 6.2 | faint same as standing PARTIAL 3/3 |
| F36#60 Reedwing | 6.78 | 7.26 | +0.48 | 6.4, 6.7, 6.6 | decal blotches FIXED 3/3; faint deflates PARTIAL / FIXED / FIXED |
| F36#38 Cannonback | 6.92 | 7.21 | +0.29 | 6.2, 6.6, 6.8 | gear kitbash PARTIAL / PARTIAL / FIXED |
| F36#78 Tempestwing | 6.76 | 6.84 | +0.08 | 6.0, 6.5, 6.2 | thin/low contrast PARTIAL 3/3; perched faint FIXED 3/3 |
| F36#48 Galewisp | 6.84 | 6.88 | +0.04 | 6.0, 6.4, 6.4 | **carry carries nothing PRESENT 3/3**; faint wing over trainer FIXED 3/3 |
| F36#92 Water Mangrove Monitor | 6.24 | 6.26 | +0.02 | 5.8, 5.6, 5.6 | dark olive PARTIAL 3/3; face lost FIXED / PARTIAL / PARTIAL; wheel faint FIXED / FIXED / PARTIAL |
| F36#50 Mangrove Monitor | 6.92 | 6.25 | −0.67 | 5.5, 5.8, 6.0 | low contrast PARTIAL 3/3; **trainer inside the tail PRESENT 3/3** |
| F36#88 Water Abyssal Guardian | 6.63 | 5.85 | −0.78 | 5.6, 5.0, 5.3 | spindly PRESENT 3/3; **neck up in faint PRESENT 3/3** |
| F36#93 Water Mirejaw | 6.45 | 5.52 | −0.93 | 4.6, 5.0, 5.4 | crimson frills FIXED 3/3; dark blob FIXED 3/3 (now a **belly-up floating faint**) |
| F36#94 Water Mosshell | 6.99 | 5.81 | −1.18 | 5.2, 5.2, 5.4 | faint PARTIAL / FIXED / PARTIAL; **rider PRESENT 3/3** (inverted turtle, floating rider) |
| F36#30 Abyssal Guardian | 6.91 | 5.54 | −1.37 | 5.0, 5.0, 5.6 | vinyl PARTIAL 3/3; toy-like PRESENT / PRESENT / PARTIAL |
| F36#86 Voltarach | 6.87 | **5.11** | **−1.76** | 4.5, 4.7, 4.7 | **chrome-gold statue PRESENT 3/3; face lost PRESENT 3/3** |

- **Direction:** 4 rows rise (+0.29 to +0.86), 3 are level (±0.1) and 6 fall (−0.67 to −1.76). The mean change is −0.33.
- **Across both batches (19 rows):** 8 rows gained more than 0.25, and the mean change is −0.15.

### Stormbrush
- At 7.68 it **meets the bar at High.** It is above the top anchor, but this batch is the confirming one.
- **Capture Medium for F36#72 next.** It closes if Medium also maps at 7.5 or above.

### Near the bar
- **Reedwing (7.26) and cannonback (7.21):** both are close-out candidates. Their remaining causes:
  - reedwing: no visible elemental trait, and only slightly taller than the trainer;
  - cannonback: the faint is a rigid camera-facing roll.

## Shared causes (unprompted, across all six judges)

| # | Cause | Rows (this batch; batch 1 in brackets) | Fix type |
|---|---|---|---|
| 1 | **The faint does not ground.** Neck stays up, the creature sits upright like a frog, or flips belly-up and floats. | water abyssal guardian, abyssal guardian, water mangrove monitor, water cragclaw, **water mirejaw (belly-up, floating clear of the stage, 3/3)**, cannonback (rigid roll); [glimmermoth, skyrill, fulgocobra, veridian] | pose data / animation (scene) |
| 2 | **Travel poses are broken.** | **galewisp fly-grip: nothing in the talons, trainer stands apart (3/3)**; **water mosshell ride: turtle belly-up, rider floating above it (3/3)**; its swim frame has the trainer standing on the water (2/3); [veridian rider tiny] | pose data (scene) |
| 3 | **Trainer inside or behind the tail on the pose stage.** | mangrove monitor (3/3, every frame), water mangrove monitor, water mirejaw, stormbrush (tail over the ruler) | capture-stand spacing, or the tail pose |
| 4 | **Off-style materials.** | voltarach chrome-gold statue with a lost face (3/3); abyssal guardian and water abyssal guardian glossy vinyl, toy-like (3/3); [ribbonray all-magenta] | new_art (Meshy remake or material) |

**Causes now fixed by the remakes** (FIXED 3/3 unless noted):
- stormbrush's plastic-blue fur;
- reedwing's decal blotches;
- water mirejaw's crimson frills;
- tempestwing's perched faint;
- galewisp's wing over the trainer;
- cannonback's brass gears (1/3 FIXED, 2/3 PARTIAL).

**Owner rules:**
- **Red and oxblood:** no flag this batch. Water mirejaw's frills are now orange-gold, and the cragclaw orange reads as coral.
- **Creatures taller than the trainer:** reedwing is "only slightly taller than the trainer" (2/3).

## Recommendation
1. **F36#72 Stormbrush:** capture Medium now; it is a close candidate.
2. **Put the falls on the board.**
   - Voltarach, abyssal guardian (both forms), water mosshell, water mirejaw and mangrove monitor are the remakes that regressed.
   - Their 24 Oct scores belong to meshes that no longer ship.
3. **Faint grounding (cause 1) is the biggest shared swing.**
   - 10 of the 19 re-scored rows name it.
   - One faint-pose pass that drops neck and head to the floor and keeps the body on the stage would serve all of them, as would a fix to the belly-up flip.
4. **Travel poses (cause 2):**
   - fix the galewisp fly-grip attach and the water mosshell ride orientation;
   - these two rows fell or stalled on that alone.
5. **Remakes for new_art:** voltarach and abyssal guardian (both forms), then ribbonray from batch 1. Hand these to LANE-MESHY.
