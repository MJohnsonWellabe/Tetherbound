# G-things-meadowground: Meadows ground cause arm (P-GROUND; F38#21, #22, #30, #26; GPU High)

## Verdict: DO NOT SHIP. The judges barely see the arm, and F38#21, the new target row, loses.

| Set | Base | Arm | Gain | Prefer arm |
|---|---|---|---|---|
| **F38#21** ground cover (target) | 6.67 | 6.47 | **−0.20** | 0/3 (2 prefer base) |
| F38#22 mill and settlements (target) | 6.31 | 6.27 | −0.04 | 0/3 (1 prefers base) |
| F38#30 Burrow Warrens hillside (target; F38#24 shares the frames) | 5.32 | 5.56 | +0.24 | 3/3 |
| F38#26 creature ground contact (target) | 7.22 | 7.18 | −0.04 | 0/3 (1 prefers base) |
| F38#20 stronghold (no-loss) | 5.76 | 5.76 | 0.00 | identical |
| F38#3 fight (no-loss) | 6.98 | 6.98 | 0.00 | identical |
| F38#5 creature scale (no-loss) | 7.34 | 7.34 | 0.00 | identical |

- **The arm barely registers.** Render difference is 3.3–7.2 per set. The judges call five of the seven sets "near-identical" or "identical".
- **F38#21 loses.** Base's frame 2 has "a cluster of yellow flowers" that breaks the lilac repetition. The arm "leans back to lilac only".
  - Recorded defect: PARTIAL on base, PRESENT on the arm (2/3).
  - The cause arm thins the colour variety the row asks for.
- **F38#30's +0.24 is not the ground.** The hillside defect is PRESENT on both sides (3/3): "a broad, smeared ... terrain face with straight edges and a dark seam". The arm's gain comes from frame 2's badgers being caught in side profile, which is "more naturalistic", where base's face the camera "with a mascot-like face". The GPU lane confirms it: a different wild creature spawned on each side in walk_03 (badgers on base, an armoured creature on the arm). Spawn difference, not ground.
- **F38#26:** level. Mosshell's front sinks into grass on both sides.

- **The old-mill approach frame** (base camera against a trunk, GPU lane note) is not in these sets. F38#22 uses the old-mill close, village close and trail-camp close frames.

## Flag: red on a non-Tether creature (3/3, both sides)
- The badger-type creatures at the Burrow Warrens (F38#30 frames) carry "a bright red bush or crest on the back".
- Red and oxblood are reserved for Team Tether. This is a creature colour issue, not the arm's, and goes to THINGS (creatures).

## What holds these rows (3/3)
- **F38#30 / F38#24:** the smeared, straight-edged hillside face with a dark seam. It needs blended rock and root dressing, or a sculpted earth face (new art).
- **F38#21:** one repeated lilac stalk flower over even slopes. The judges ask for colour clusters and rock outcrops.
- **F38#22:**
  - the mill water is barely in frame;
  - the TRAIL CAMP sign "crowds the camera" in frame 2;
  - "a pale blue beam through the roof" in frame 3, likely the objective beacon that G-things-beam removes;
  - a blotchy mud foreground.
- **F38#20:** a small dark castle on approach, and a saturated orange, boxy interior with no Tether dressing.
- **All Meadows sets:** flat painted tree cards, and "a dark square shadow decal beside the trainer" in every creature frame (2/3).

## Next
- **Park this ground arm in its current form.** It is too subtle to read, and it removes the yellow cluster on F38#21.
- **For P-GROUND:** the judges' ask is clustering and breaks: colour patches, rock outcrops, shrub edges, blended dressing over straight terrain cuts. A tint or density change will not get there.
- **Pair with the beam fix.** F38#22's roof beam should go once G-things-beam lands.

## Frames
- **Source:** `tb/gpu-frames-1108` section `G-things-meadowground` (b6bcab64), High.
- **Build:** `tb/things` d2d7d5f16 on both sides.
  - **base:** no overlay.
  - **arm:** `THINGS-MEADOWGROUND/overlay_cause_ground.json`.
- **Frames:** each row's job.json frames. F38#24 shares F38#30's frames, and F38#11 shares F38#3's fight frame, so each pair is judged as one set.
- **Render check:** mean difference:
  - F38#21 5.1, F38#22 4.7, F38#30 5.8, F38#26 5.4;
  - F38#20 3.3, F38#3 7.2, F38#5 5.4.

## Batch `G-mg`
- Three code-blind judges, standard prompt, seven candidate sets.
- Anchors: craft, f36_0_npc:C1 and f10_2_r3_capacitor. This is a confirming batch.
- **Fit:** linear, slope 1.1883, intercept −0.5411, r 0.904, anchor RMSE 0.59.
