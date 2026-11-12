# G-stormwood-swing-1: wet-earth ground plus fine near rain (F41#4, #5, #12, #17)

Frames: `tb/gpu-frames-1108` b85e807e1, High. Live and arm as in the GPU lane's manifest.

**GPU lane's flag (read before judging):** the zone loam reads salmon to mauve-pink under the lilac sky on crown_arch, glass_field, fallen_giant, crown_heartstone and crown_overlook. The coordinator says a de-pinked version will follow, so this score is mainly a check on direction.

## Pre-judge render check
The arm is in frame:
- 4–33% of pixels change per view.
- Luma rises 3–15 levels.
- The biggest changes are crown_heartstone (33%), crown_arch (30%) and glass_field (21%), where the pink loam sits. The deepwood views change least.

## Judged
Batch `G-sw1`:
- Three code-blind judges and the standard prompt.
- Pinned anchors are craft, f10_2_r3_capacitor and f04_6_r22, so this is a confirming batch.
- Fit: linear, slope 1.3669, intercept −1.568, r 0.828, anchor RMSE 0.646. No warnings.

| Row | Live | Arm | Gain | Judges preferring arm |
|---|---|---|---|---|
| F41#17 Crown Arch | 6.77 (raw 5.8, 6.3, 6.2) | 6.45 (raw 5.7, 5.9, 6.0) | **−0.32** | 0/3 |
| F41#12 charged road | 6.04 (raw 5.4, 5.6, 5.7) | 5.63 (raw 5.1, 5.4, 5.3) | **−0.41** | 0/3 |
| F41#4 destinations | 5.72 (raw 5.2, 5.5, 5.3) | 5.49 (raw 5.0, 5.3, 5.2) | **−0.23** | 0/3 |
| F41#5 forest ground | 5.13 (raw 4.7, 4.9, 5.1) | 5.27 (raw 4.9, 5.2, 4.9) | +0.14 | 2/3 |

## Do the judges see the loam as red-family?
**As pink and off-palette, not as oxblood.** All three describe the arm's ground as "pink-tan mud", "salmon-pink patches", "pink-brown blotchy" or "large pink patches that read like an unfinished texture", and one judge says it is "off the Stormwood palette".

None of them flags the ground as an oxblood or Team Tether leak. One judge's only oxblood remark is about the red-brown tree trunks behind the arch, which are on both sides. So the pink is read as a palette and finish defect rather than a reserved-colour leak. It costs points either way: on Crown Arch, "pink mud with black blotches fights the arch".

## Are wet earth and fine rain the right direction?
- **Wet earth: not as rendered.** Removing the black gloss does not help, because the judges ask for the board's look, "dark wet moss and black pools", and some read the live side's dark wet ground as "closer to the board". Their asks are:
  - a darker moss-and-mud grade, not lighter earth;
  - capped specular on wet pools (the live side's crown_heartstone and glass_field frames have a blown-out highlight around the trainer);
  - real ground form, with ruts and puddle edges.
- **Fine rain: yes.** All three criticise the **live** side's rain as "thick white sticks" or "rain spikes". None objects to the arm's thinner rain. Keep the fine near rain.

## Verdict
**DO NOT SHIP.**
- Three of four rows drop (−0.23 to −0.41) with 0/3 judges preferring the arm.
- F41#5 is the only gain (+0.14, 2/3), which is far below 0.5.

**For the de-pinked follow-up:**
- Keep the fine rain.
- Take the ground darker, toward the board's moss and black pools, and avoid lighter or warmer earth.
- Cap the wet specular.

**Other gaps all three judges name**, independent of this arm:
- a single flat purple card treeline;
- open, evenly scattered trees;
- no fog layering between near and far;
- the square Crown Arch plinth.
