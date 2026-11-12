# G-things-convclear-meadows: conversation-camera clearance (LANE-THINGS, T6), Meadows, GPU High

## Frames
`tb/gpu-frames-1108` fc6e1866e, High. Capture: `phase2_capture_dialogue.gd --biome=meadows --seed=2042` on `tb/things` eb250d657, 48 `__dialogue` frames per side.

Sides:
- **stand:** `--sight-stand`, no overlay.
- **arm:** `--sight-stand` plus `THINGS-CONVCLEAR/overlay_clearance.json` (`camera.json conversation.twoshot_v2.clearance_1112`).
- **base:** main as judged in `G-dialogue-recapture-meadows` (1c7b2f364).

Every frame has blend 1.000 and none timed out. 0 blank frames, 0 script errors.

## Render check
- arm and stand are identical only on `character__bram` (mean difference < 1).
- The F38#36 frames look the same on stand and base: judges saw identical images in both F38#36 sets.

## Sets
The same grouping as `G-dm`:
- the four Meadows board rows (F38#16, #17, #36, #37) as 2×2 sheets of their `job.json` frames, each judged twice: **stand vs arm** and **base vs arm**;
- the other 36 conversations as four 3×3 sample sheets (`samples.json`; `warrens_watch_pell` left out as before), judged **stand vs arm**.

**Batch `G-cc2`:**
- Three code-blind judges, standard prompt, 12 candidate sets.
- Anchors: craft, f36_0_npc:C1 (7.47/7.53) and f10_2_r3_capacitor. It is a confirming batch.
- **Fit:** slope 1.1438, intercept −0.3487, r 0.900, anchor RMSE 0.603. No warnings.
- The capacitor anchor pair fits worst again (residuals −0.61 and +1.16).

## Verdict: SHIP
The arm beats the stand on all 8 sets: all three judges prefer it on 7 sets, and two judges on the eighth (F38#37), with one tie. It also beats main on all four board rows (3/3). Nothing loses.

### Clearance alone (stand → arm, same capture)

| Set | Stand raw → mapped | Arm raw → mapped | Gain | Prefer arm |
|---|---|---|---|---|
| F38#16 tournament subject identity | 5.2, 5.0, 5.2 → 5.52 | 6.0, 5.8, 6.0 → **6.44** | **+0.92** | 3/3 |
| F38#17 named trainer subject visibility | 5.8, 5.7, 5.9 → 6.29 | 6.3, 6.4, 6.5 → **6.97** | **+0.68** | 3/3 |
| F38#36 dialogue speaker occlusion | 6.6, 6.6, 6.4 → 7.12 | 6.8, 6.8, 6.7 → **7.39** | +0.27 | 3/3 |
| F38#37 dialogue rock obstruction | 6.2, 6.3, 6.1 → 6.74 | 6.4, 6.3, 6.3 → **6.90** | +0.16 | 2/3 (1 tie) |
| sample 1 (characters ada–oskar) | 5.8, 5.8, 6.0 → 6.36 | 6.4, 6.4, 6.6 → **7.05** | +0.69 | 3/3 |
| sample 2 (rae–captain_ridge) | 5.6, 5.4, 5.6 → 5.98 | 6.3, 6.2, 6.4 → **6.86** | +0.88 | 3/3 |
| sample 3 (riverwatch–relay_officer_dell) | 5.0, 5.2, 4.9 → 5.41 | 6.5, 6.4, 6.6 → **7.09** | **+1.68** | 3/3 |
| sample 4 (relay_picket_hess–warden_aldis) | 5.6, 5.6, 5.7 → 6.09 | 6.6, 6.3, 6.5 → **7.05** | +0.96 | 3/3 |

### Arm vs main (the four board rows)

| Row | Main → arm | Gain | Prefer arm |
|---|---|---|---|
| F38#17 | 5.75 → 6.97 | **+1.22** | 3/3 |
| F38#16 | 5.83 → 6.32 | +0.49 | 3/3 |
| F38#36 | 7.12 → 7.39 | +0.27 | 3/3 |
| F38#37 | 6.70 → 6.90 | +0.20 | 3/3 |

### New Meadows dialogue levels (arm)
- **Rows:**
  - F38#36 7.39: near the bar; the close-out exception applies.
  - F38#17 6.97.
  - F38#37 6.90.
  - F38#16 ≈6.38 (mean of its two sets).
- **Samples:** mean ≈7.01.
- **All 47 judged frames, frame-weighted:** ≈6.99. The `G-dm` baseline was ≈6.60.

### Recorded defects on the arm
- **F38#17** "no speaker visible": FIXED 3/3.
- **F38#36** "creature intrusion": FIXED 3/3.
- **F38#16** "same grey-haired character": FIXED 2/3, PARTIAL 1/3. Judge a cannot confirm it while Mira is hidden.
- **F38#37** "rock faces": PARTIAL 2/3, FIXED 1/3.

## What the judges say
**Where the stand and main lose (3/3 on every losing side):** "the black plated dog" crosses the speaker:
- on the stand: Orrin, Warder Ness, Watchman Corr, Tobin, Wilhelm, Kest, Juno, Dorn, Oreth, Tether Patrol, Tether Grunt, Bryn, Ada, Halda and Garrick;
- on main: Tam, Old Bram and Keeper Hald. On main, Hald's frame is "half covered by the flank".

The arm removes the dog from all of these, and from Nessa's frame where "the player's back fills the left half".

**Still wrong on the arm:**
1. **Mira, tournament quarter (F38#16), 3/3 on all sides:** the camera sits behind a wooden lattice and glass, so Mira is hidden. This is the single biggest hole in F38#16. Main showed her small, through a window. It is a sight-stand regression; the clearance arm does not fix it.
2. **Blown key lights:**
   - Warder Solene's face is overexposed (3/3, F38#17);
   - Mira's wall lamp, sample 1 (2/3);
   - Warden Aldis's lamp in a dark interior, sample 4 (3/3).

   Keeper Hald's interior is dim with a green cast (3/3).
3. **Dog still in the arm frame:**
   - Rae: dark mass in the right third, sample 2, 3/3;
   - Old Perrin: right edge, sample 1, 2/3.

   This matches the GPU lane's list (ada, garrick, old_perrin, rae). Judges did not flag ada or garrick on the arm.
4. **F38#37 Quarry Foreman:** "boxed in by dark rock", with muddy, low-contrast rock material. The speaker is visible.
5. **Red near friendly speakers, needs checking:**
   - a saturated crimson banner behind Captain Halder (F38#36, 3/3), with a magenta specular glare on it on the stand side;
   - red banners behind Hess and Verrick (sample 4, 2/3).

   Fine if these are Team Tether staging; otherwise it is an oxblood leak.
6. **Minor:**
   - a flat cyan pillar beside Captain Oreth reads as a placeholder (judge b);
   - relay_picket_hess is cut off at the left edge (GPU lane note; not raised by the judges).

## Recommendation
1. **Land the clearance overlay.** Every set gains (+0.16 to +1.68 against the stand; +0.20 to +1.22 against main), with no loss.
2. **Next, ride-along fixes:** the Mira tournament stand, and the Solene, Aldis and Mira key-light exposure. F38#36 at 7.39 is the closest row to the bar. The remaining fixes are the Halder banner glare and red check, and the over-the-shoulder framing.
3. **The `--sight-stand` flag needs a decision:**
   - if it is how the game places the player for dialogue, the Mira lattice regression is real;
   - if it is only a capture choice, the coordinator should confirm it as the Meadows dialogue fixed camera set before rows close on it.
