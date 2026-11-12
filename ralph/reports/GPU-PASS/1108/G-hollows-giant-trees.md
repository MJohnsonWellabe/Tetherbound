# G-hollows-giant-trees: Meshy giant trees in the fight sight fade + hall post retint (F41#3, F41#22 fight, F41#24, F38#0 arch_home; GPU High)

Frames: `tb/gpu-frames-1108` ffe0f840f, High, 63 per side.
- base = `tb/item-hollows-trunk` 1c45229d9.
- arm = base + `line_of_sight_fade.giant_trees_1110` (giant_tree_a/b and scarred_trunk added to the fight-only sight fade) + `hall_waymark timber_1110` (the Hall nave post retinted out of the red family).

Sheets, each 3×3, base against arm:
- Hollows Alpha: i00, i02, i04, tell1 a/d/e, tell3-b-mid, tell4-a-start, 99-after.
- Capacitor Alpha: i00, i02, i04, tell1 a/d/e, tell2-d, tell3-b-mid, 99-after.
- giant_calm (one frame).
- arch_home golden detail + gameplay (2×1).

Batch `G-hg`:
- three code-blind judges, standard prompt;
- both fight sheets on the F41#3 brief and on the F41#22 fight brief;
- giant_calm on the F41#24 cleanliness brief;
- arch_home on the F38#0 brief, with the neutral red/salmon/oxblood question;
- anchors: craft, f36_0_npc:C1 (7.47/7.53) and f04_6_r22, so this is a confirming batch. The usual f10_2 Stormwood-fight anchor was left out so its magenta telegraphs would not blur notes on these fights.

Fit: linear, slope 1.208, intercept −0.3933, r 0.923, anchor RMSE 0.382.
Warning (verbatim): `some candidates lie more than 0.5 outside the anchors' measured range (extrapolated)`.

## Verdict: SHIP
- Hollows is a clear win on both rows: +1.09, 3/3.
- Capacitor is neutral within noise: +0.12 at 2/3 on F41#3, and −0.04 on F41#22 with 2 ties and 1 preferring base.
- giant_calm is unchanged, so no loss.
- **The post no longer reads red: the judges read the *base* post as salmon or orange-red, and the arm's as brown wood.**

| Sheet | Brief | Base | Arm | Gain | Judges preferring arm |
|---|---|---|---|---|---|
| **Hollows Alpha fight** | F41#3 spacing | 4.80 | **5.89** | **+1.09** | **3/3** |
| **Hollows Alpha fight** | F41#22 fight | 4.80 | **5.89** | **+1.09** | **3/3** |
| Capacitor Alpha fight | F41#3 spacing | 5.77 | 5.89 | +0.12 | 2/3 (1 tie) |
| Capacitor Alpha fight | F41#22 fight | 5.97 | 5.93 | −0.04 | 0/3 (2 ties, 1 base by 0.1) |
| giant_calm (no-loss check) | F41#24 | 6.53 | 6.53 | 0.00 | tie (identical; exploration unchanged) |
| **arch_home detail + gameplay** | F38#0 + red question | 6.13 | **6.37** | **+0.24** | **3/3** |

**F41#3 row** (Hollows and Capacitor): base 5.29 → arm **5.89** (+0.60).

## What the arm fixes
- **Hollows:** on base, frames 1 and 7 (i00, tell3-b-mid) are taken from inside the teal giant trunk, all bark and no fighter (3/3). On the arm the fight is in view in every frame; a trunk still partly covers the last one or two frames, 99-after included.
- **Capacitor:** the fight looks the same on both sides; no frame is filled by a trunk on either. Both have a foreground trunk on one late frame and a pale slab in a corner. As expected, the sight solver's divergence after tell1 makes the late frames differ.
- **Hall post (red rule):** all three judges single out the base post as "a saturated orange-red wood that leans toward salmon" or "close to salmon". The arm's reads browner, "as wood", and the arm is preferred 3/3. **The red-rule issue is resolved.** The post still blocks the centre of the detail view, which is a framing issue for that stand.

## What still keeps F41#3 low: spacing, untouched by this arm
- **The F41#3 defect is PRESENT on every side from every judge.** Sparkit sits under or among Voltarach's legs in most frames, and the trainer is barely readable.
- The tree fade fixes occlusion, not spacing. The next gain needs the ally pushed to a clear flank of the boss.
- **Other notes:**
  - heavy HUD;
  - the player creature is small and pale against the dark floor;
  - **giant_calm (both sides):** a dithered strip at the base of the giant trunk, the trainer's rim blooming to white, and flat leaf cards (F41#24 PARTIAL).
