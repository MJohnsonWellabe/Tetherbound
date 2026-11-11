# G-newapproach-charge-lines-r2: brighter cyan charge lines (F41#13 round 2; GPU High)

Frames: `tb/gpu-frames-1108` b494466c3, High, seed 2042. The command is the same as round 1.
- base = `tb/newapproach` a651204b1, with charged_1105 as shipped.
- arm = base + `overlay_charge_lines_r2.json`:
  - the line mask kept;
  - brighter saturated cyan lines;
  - glow-map boost on arcs and eyes;
  - white-violet rim;
  - cobra glow back near base.

The sheets, layout and brief are the same as round 1 (`G-newapproach-charge-lines.md`):
- F41#13: fulgocobra over stormraven, full-size frames stacked.
- Control: sparkit idle.

Render check:
- fulgocobra 0.81% of pixels changed;
- stormraven 0.89%;
- sparkit 0.58%, sub-pixel; the judges saw it as identical.

Blank frames: 0 of 3 per side.

Batch `G-chl2`:
- three code-blind judges, standard prompt, F41#13 brief;
- anchors: craft, f36_0_npc:C1 (7.47/7.53) and f04_6_r22, so this is a confirming batch.

Fit: linear, slope 1.2205, intercept −0.8657, r 0.964, anchor RMSE 0.265. No warnings.

## Verdict: DO NOT SHIP. F41#13 loses 0/3 again; the control is flat. Park the charge-lines approach.

| Set | Base | Arm | Gain | Judges preferring arm |
|---|---|---|---|---|
| F41#13 (fulgocobra, stormraven) | 6.34 | 5.85 | **−0.49** | **0/3** |
| Control (sparkit) | 5.93 | 5.89 | −0.04 | 0/3 prefer (2 ties, 1 a −0.1) |

Raw Bar A, base → arm (judges a, b, c):
- F41#13: 5.6, 5.8, 6.3 → 5.2, 5.3, 6.0.
- Control: 5.0, 5.5, 6.2 → 5.0, 5.5, 6.1.

Recorded defect, base / arm:
- judge a: PARTIAL / PRESENT;
- judge b: PARTIAL / PRESENT;
- judge c: PARTIAL / PARTIAL.

Round 1 lost by −0.62; round 2 loses by −0.49. Under the two-failure rule, **charge-lines is parked on F41#13** until there is a new idea.

## Why the arm still loses
1. **The cyan lines don't carry at view distance.** At normal creature-view distance the judges still see a dark bird.
   - Judge a: "a dark saturated blue with little glow, and at view distance it is a blue blob against the dark ground".
   - Judge b: "dark blue with small speckles. It barely separates from the ground".
   - Judge c: "a dark blue silhouette with faint flecks. It nearly disappears against the shadowed grass".
   - The GPU lane's close read (cyan feather-edge lines, lit eyes) does not survive to view distance.
2. **The base halo still wins.** All three judges again call the base raven's white-blue glow overdone: "a halo around the bird", "blown out", hiding feather detail. They still prefer it, because it reads as charged and separates from the ground.
3. **Fulgocobra:**
   - Judge b: the arm's glow is "limited to the tail coils, and the upper body is a dark blue blob against the dark trees".
   - Judge c: the arm's coil glow is brighter, but "the hood and body stay a dark, low-detail mass".
   - Judge a: the base is "slightly crisper".
   - Judges b and c both note the cobra's charge is warm gold or amber, not white-violet.
4. **The marks read as speckle at this distance:** "small speckles", "faint flecks". Neither round produced a line the judges named as a vein or arc.

## What the judges point to instead (all scene)
- **The underlying problem is the dark body on dark ground.** A line-only accent on a dark navy body over black-blotched moss cannot separate the creature. Two directions follow from this:
  - **Lighten the raven's body value** so it reads against the ground, then place the arcs on it. All three ask for "a lit, rim-lit body" with thin white-violet arcs and eyes.
  - **Fix the Stormwood ground under the creature stand** (the black blotches and pools, the flat lilac sky). All three name this as the first or second top change, and it is the same finding as round 1.
- **Scale:** all three judges say the raven stands at or below the 1.80 m trainer's height in this stand. That is a separate hard-rule flag for the creature row owner, not part of this arm.
