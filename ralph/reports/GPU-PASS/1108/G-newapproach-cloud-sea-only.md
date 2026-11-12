# G-newapproach-cloud-sea-only: soft lit cloud-sea floor (F40#11, F40#6; GPU High)

Frames: `tb/gpu-frames-1108` fe749ec0a, High, `--fixed-fps 20`, seed 2042.
- Tree: main 63d6abd25 (#904) plus `cloudreach_world.gd` and the new cloudreach_cloud_sea_soft / cloudreach_cloud_card shaders from `tb/newapproach` 2078f6442, on both sides.
- base = that tree; the floor is faceted.
- softsea = base + `cloudreach_visual.json` cloud_sea.soft_sea.enabled. The #904 edge cards are unchanged and still lilac on both sides.

Sets, each with its brief and recorded defect:

| Row | Frames | Layout | Brief as in |
|---|---|---|---|
| F40#11 | 16, 17, 18 | stacked at full size | `G-newapproach-edge-cards.md` |
| F40#6 | 17, 18, 27, 28 | 2×2 | `G-newapproach-cloud-plane.md` |

Render check (pixels changed): 16 16.2%, 17 7.1%, 18 16.4%, 27 13.3%, 28 4.1%. Blank frames: 0 of 5 per side.

Batch `G-cs`:
- three code-blind judges, standard prompt;
- anchors: craft, f36_0_npc:C1 (7.47/7.53) and f10_2_r3_capacitor, so this is a confirming batch.

Fit: linear, slope 1.1983, intercept −0.299, r 0.900, anchor RMSE 0.604. No warnings.

## Verdict: SHIP. Both rows gain at 3/3

| Row | Base | Soft sea | Gain | Judges preferring soft sea | Board |
|---|---|---|---|---|---|
| **F40#11** terrace edge clouds | 6.17 | **6.97** | **+0.80** | **3/3** | 5.99 |
| **F40#6** mounted terrace edge and cloud crossing | 5.61 | **6.33** | **+0.72** | **3/3** | 5.10 |

Raw Bar A, base → soft sea (judges a, b, c):
- F40#11: 5.5, 5.4, 5.3 → 6.2, 6.0, 6.0.
- F40#6: 4.8, 5.0, 5.0 → 5.4, 5.6, 5.6.

Recorded defects:
- **F40#11** (loose edge puffs): PARTIAL 3/3 on both sides. The #904 lilac cards are unchanged here.
- **F40#6** (unsupported mounted ride over the cloud floor): PRESENT 3/3 on both sides. The floor change does not address the ride.

F40#6 rises above 6 (6.33). F40#11 rises to 6.97.

## What the judges see
- **Floor (3/3, both rows):**
  - **Soft sea:** "a soft, rolling, textured surface that reads far better as a sea of cloud", "a continuous sheet with soft cloud texture".
  - **Base:** "flat, faceted, blocky polygon tiles in grey-white ... an unfinished placeholder".
- **Edge puffs (3/3):** still "lavender-grey cumulus ... clumped against the cliff foot as separate foreground shapes", "stuck on the cliff rather than part of the cloud floor". This is the same finding as `G-newapproach-edge-cards.md`. The cards keep their #904 shading here.
- **Frame 27 ribbon sheets (the GPU lane's note):** no judge named straight-edged translucent ribbon sheets.
  - Judge c saw "dark diagonal streaks run under the deer" in F40#6's bottom-left frame, but on the **base** side, over the faceted floor.
  - At 2×2 grid size the ribbons did not register as a defect on the soft-sea side.
- **F40#6 ride (3/3):** the deer and rider keep their upright riding pose "out on the cloud floor, with nothing under them".
- **Cliffs:** blurry, low-detail cliff faces in the distance (judge c).

## What would add the most (all scene)
1. **Edge puffs:** blend them into the new floor, matching its white with soft depth-faded bases, instead of lilac clumps on the cliff. This moves F40#11 toward the bar.
2. **Mounted ride:** keep the deer off the open cloud floor (clamped pathing or an authored drop). This is the F40#6 defect.
3. **Ribbon sheets:** check the frame-27 ribbons at full size before landing. The judges did not see them at grid size.
