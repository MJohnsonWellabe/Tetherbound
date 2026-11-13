# G-things-creature-closeout: Ashtusk embers + hit, Brooktail spots, embers on three species (F36 (1); GPU High and Medium)

## Verdicts

| Arm | Row | Base | Arm | Gain | Prefer arm | Verdict |
|---|---|---|---|---|---|---|
| ashtusk embers + hit | F36#33 Ashtusk | 7.02 | **7.32** (7.32, 7.19, 7.45) | +0.30 | 3/3 | **SHIP** (owner rule of 12 Nov: no 0.5 threshold). Not closed. |
| brooktail spots | F36#36 Brooktail | 6.09 | 6.09 | 0.00 | 2/3 | **Do not ship** (no gain). Not closed. |
| embers only | Stormtrail | 7.40 | 7.49 (7.57, 7.32, 7.57) | +0.09 | 2/3 | split |
| embers only | F36#62 Riftfrill | 6.34 | 6.30 | −0.04 | 1/3 | loses |
| embers only | Nightburrow | 6.73 | 6.68 | −0.05 | 0/3 (2 ties) | loses |

- **Embers arm: SPLIT, do not ship as one arm.** Stormtrail gains, but riftfrill and nightburrow lose.
- **Stormtrail sits at 7.49 on the arm,** 0.01 under the bar. It is a close-out candidate.

## Harness finding: High and Medium are the same image on the pose stage
- The judges flagged the High and Medium sheets as "pixel-identical" (3/3). A pixel check agrees:
  - mean difference between High and Medium sheets is 0.005–0.03 (on 0–255);
  - every judge gave each pair identical scores.
- **So `capture_f36_poses.gd` does not apply the preset on the neutral stage**, or the stage has nothing the preset changes.
- **Consequence 1: the earlier High-vs-Medium gaps were judge-pool differences.**
  - Ashtusk 8.03 High (G-rr) vs 7.28 Medium (G-abm).
  - Brooktail 7.69 vs 7.03.
  - These came from different judge panels on near-identical images, not from the preset.
- **Consequence 2: a pose-stage "Medium" capture is not separate Medium evidence.** The GPU lane should check whether the runner's per-preset graphics config reaches this tool. Until then:
  - treat a pose-stage row as one score;
  - pool its judge panels when deciding a close.
- **Pooled so far (mapped means):**

| Row | G-rr | G-abm | G-cc |
|---|---|---|---|
| Ashtusk | 8.03 | 7.28 | 7.32 (with embers + hit) |
| Brooktail | 7.69 | 7.03 | 6.09 |

  Neither row has a stable 7.5 across panels.
- **Brooktail in this batch.** Both of tonight's named defects were recorded for it ("oversized glowing spots read as a decal pattern", "dark head with unreadable eyes"), and every judge marked both PRESENT on both sides. That probably explains part of the drop to 6.09. The spot change did not fix either defect.

## Frames
- **Source:** `tb/gpu-frames-1108`.
  - G-things-embers-ashtusk (f760fb365): High and Medium.
  - G-things-brooktail-spots (436f7e5b7): High and Medium.
  - G-things-embers (b2bc93ed4): High.
- **Capture:** `capture_f36_poses.gd --whole-body --context --roles=hit,faint`.
- **Build:** `tb/things` 8e099fef8 on both sides (includes main b3dc21395, so the ruler is clear by default), imported for the new Brooktail textures.
- **Sides:**
  - **base:** no overlay.
  - **arms:**
    - Ashtusk: `THINGS-EMBERS/overlay_aspect_billboard.json` + `THINGS-ASHTUSK/overlay_ashtusk_hit.json`.
    - Brooktail: `THINGS-BROOKTAIL/overlay_brooktail_spots.json`.
    - The three species: embers only.
- **Health:** 0 script errors. Neutral stage, `PACK_STAGE_FRAMES=1`.
- **Sets:** the standard pose crop (560,200, 1000×640) and tiles (hit 000, hit 050, faint 050, faint 100), with the F36 (1) brief.
- **Recorded defects:**
  - Ashtusk: the roster cause plus tonight's two named defects (floating line, tusk floor clip).
  - Brooktail: tonight's two named defects.
  - Riftfrill and stormtrail: their roster causes.
  - Nightburrow: none.
- **Render check:** pixels changed per sheet:
  - Ashtusk 2.6%, Brooktail 1.4%.
  - Riftfrill 0.19%, stormtrail 0.13%, nightburrow 0.22%. Only the motes change on these three.

## Batch `G-cc`
- Three code-blind judges, standard prompt, seven candidate sets: Ashtusk and Brooktail at both presets, the three species at High.
- Anchors: craft, f36_0_npc:C1 and f04_6_r22. This is a confirming batch.
- **Fit:** linear, slope 1.2722, intercept −1.3318, r 0.973, anchor RMSE 0.23. No warnings.
- **Scoring note:** `batch.json` merged the identical High and Medium sets for Ashtusk and Brooktail, so those score lists appear twice. The means are unaffected. The preference counts in the table above are per set and were counted by hand from the hand-backs.

## What the judges see
### Ashtusk
- **Floating line:** FIXED on the arm (3/3).
- **Tusk floor clip:** PRESENT on base for 2/3, PARTIAL on the arm (3/3). "The tusk tip still meets the shadow line."
- **Dark plates:** PARTIAL on both sides (3/3). No rim light.
- **Amber motes:** 2/3 call them "natural for a fire creature and subtle". 1/3 says they "read as a floating effect".

### Brooktail
- Both versions keep "large flat white or cyan ovals in the faint frames that read as a decal", and "a near-black head with no readable eye" (3/3).
- The arm's spots are fewer but whiter, and 1/3 reads them as "giraffe".

### Embers on the three species
- Base's thin vertical streaks above the back are artefacts (3/3).
- The arm's purple orbs above riftfrill and nightburrow "drift away from the body", which is against the owner's "no big floating effects" (3/3).
- Stormtrail's small blue sparks are accepted as storm energy.

### Other defects
- **Riftfrill:** glossy dark purple PRESENT (3/3). The hind feet float in the hit frame, and the faint end is a headless lump.
- **Nightburrow:** a "tiled cobblestone-like" fur texture (1/3). A small dark face, and a faint end that becomes a mound (3/3).
- **Stormtrail:** the placeholder look is FIXED, and it is "the best creature in the batch". "Faint flattens to a sheet" is PARTIAL.

## Next
1. **Ashtusk:** land embers + hit. To reach 7.5, add rim light and lift the plate values (T-DARKRIM), and plant the tusk tip above its shadow.
2. **Stormtrail (7.49):** keep its sparks and remove the base streak artefact. A small faint-end fix should carry it over 7.5 under the close-out exception.
3. **Riftfrill and nightburrow:** remove both the streaks and the orbs, with no motes at all. Keep only effects attached to the body.
4. **Brooktail:** the spots need smaller, irregular markings, not fewer large ovals. The head needs eye value and a rim. This is texture work, not a spot count.
5. **GPU lane:** confirm whether Medium reaches the pose stage before capturing pose-stage Medium again.
