# G-storm-light-a: Stormwood storm-light pass, arm A

Frames: `tb/gpu-frames-1108` 56637b325, manifest `G-storm-light-a`, High, no script errors. Live is main 61693b5a3. The arm is live plus `ITEM-STORM-LIGHT/overlay_storm_key.json` at 4529ecd41: `storm_light` on, a violet key and fill, a fighter rim, and `height_fog` on.

Judged rows: F41#2, #3, #4, #5, #12, #15 and #17, paired. Not judged:
- **F41#21:** not like-for-like; per the GPU lane, the fight camera frames it differently between runs.
- **F41#6 and #7:** single frames, not in the coordinator's row list.

Batch `G-sla`:
- Three code-blind judges and the standard prompt.
- Pinned anchors are craft, f10_2_r3_capacitor and f04_6_r22, so this is a confirming batch.
- Fit: linear, slope 1.3299, intercept −1.2554, r 0.884, anchor RMSE 0.538. No warnings.

Ship rule per row: gain > 0 and ≥2/3 judges prefer the arm.

| Row | Item | Live | Arm | Gain | Judges preferring arm | Per-row verdict |
|---|---|---|---|---|---|---|
| F41#17 | Crown Arch | 6.68 (raw 6.1, 5.7, 6.1) | 6.99 (raw 6.3, 6.0, 6.3) | **+0.31** | 3/3 | gains |
| F41#2 | Surge phase presentation | 5.35 (raw 5.0, 4.9, 5.0) | 5.66 (raw 5.2, 5.2, 5.2) | **+0.31** | 3/3 | gains |
| F41#12 | charged road surface | 5.97 (raw 5.4, 5.4, 5.5) | 6.24 (raw 5.6, 5.6, 5.7) | **+0.27** | 3/3 | gains |
| F41#15 | dialogue foreground obstruction | 5.93 (raw 5.7, 5.3, 5.2) | 6.10 (raw 5.7, 5.5, 5.4) | +0.17 | 2/3 (1 tie) | gains (small) |
| F41#3 | named wild fight actor spacing | 5.66 (raw 5.6, 4.9, 5.1) | 5.75 (raw 5.2, 5.2, 5.4) | +0.09 | 2/3 | not attributable (non-deterministic fight; staging differs) |
| F41#4 | named destination identities | 6.37 (raw 6.0, 5.6, 5.6) | 6.06 (raw 5.8, 5.3, 5.4) | **−0.31** | 0/3 | **loses** |
| F41#5 | forest ground and distance layers | 5.44 (raw 5.0, 4.8, 5.3) | 5.22 (raw 4.9, 4.6, 5.1) | **−0.22** | 0/3 | **loses** |

**The arm is split, so do not ship it as one switch.**
- **Gains (3/3):** the Crown Arch, the Surge phases and the charged road each gain about 0.3.
- **Losses (3/3):** the two forest location rows lose by about the same amount.
- **Net mean:** +0.05 over the seven rows.
- **Biggest single gain:** +0.31. No row moves by 0.5, and nothing reaches 7.5. F41#17, the highest, ends at 6.99.

## Why the forest rows lose
On F41#4 and F41#5 the arm is the side all three judges call "darker, crushed grade that muddies the trunks and path", "B darker and loses ground form", "crushes the path to near-black". At these broad close and approach stands, the violet key and height fog read as a darker, lower-value grade, not as depth. The defect on both rows ("uniform carpet … flat treeline band", "destinations read as similar grass and trees") is unchanged or slightly worse.

On F41#17, F41#2 and F41#12 the arm is the lighter side. The live side is the one judges call "crushed teal-black" and "darker, with crushed shadows". There the storm key lifts the subject.

**For arm B:** keep the storm key and fighter rim, but stop the height fog and grade darkening the open forest stands. Either lift ambient and exposure at the location stands, or scope the fog's density so the near ground keeps its value.

## Red and oxblood drift
None reported. No judge flags new red. The only near-red comments are the salmon-pink background bears (F41#17, on both sides, as before) and the salmon "have 0" text in the craft anchor. Neither is the arm.

## Does the player's creature read now?
**No.** On F41#3, on the arm side:
- Judge a: "Sparkit is barely identifiable in any frame; only a dust trail sits under the boss."
- Judge b: "Sparkit is a small white shape lost in the dust trail, but it stays to one side of the boss."
- Judge c: "Sparkit is still hard to find under the boss legs."

The fighter rim does not lift the ally enough to read at frame size.

**A new problem on both sides, 3/3: Voltarach is "blown out to near-white gold bloom".** Judges say it "reads as an effect rather than a material, with no face or eyes", and "a gold bloom blob". This is on both sides, so it is not the arm. If arm B strengthens the fighter rim, check that it does not add to that bloom.

## Other recurring notes (both sides, 3/3)
- Captain Marrow's head is a blown-out white glow in F41#15 frames 1–2. This is the same metallic and emission suspect as `ITEM-NPC-ALBEDO/CAUSE.md`.
- The Stormwood fight telegraphs are flat magenta rings (code).
- In the fight anchor, live frames i13 and i15 are lost to the canopy.
