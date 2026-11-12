# G-rescore-tier2-batch-1: Tidewake dialogue rows and six-species pose sample, re-scored on main (GPU High)

**Frames:** `tb/gpu-frames-1108`, main 0058b0d6c as it is, High, one-sided.
- **(a) G-rescore-tier2-dialogue (0bed8ee41):** F39#18, F39#26, F39#27 and F39#29, three frames each, per job.json. Soft water rim shipped. Grid 2×2 at 640×360.
- **(b) G-rescore-tier2-f36 (8442aba2a):** `capture_f36_poses.gd --whole-body --context` for skyrill, fulgocobra, cragclaw, glimmermoth, ribbonray and veridian.
  - Each frame is cropped 560,200 1000×640 at 1080p, as on the 24 Oct sheets.
  - Tiles: standing (hit 000), hit 050, faint 050 and faint 100. Veridian adds ride 050 and ride 100.
- **Render check:** blank frames 0 of 12 (dialogue) and 0 of 65 (f36).

**Batch `G-r2`:**
- Three code-blind judges, standard prompt.
- Each row is scored on its own brief and recorded defects. Dialogue rows use job.json. Species use the F36 (1) brief, with the 24 Oct roster causes as defects.
- Anchors: craft, f36_0_npc:C1 (7.47/7.53) and f04_6_r22. This is a confirming batch.
- A first launch on uncropped frames was stopped before scoring, when the coordinator asked for the 24 Oct crop.

**Fit:** linear, slope 1.2224, intercept −0.925, r 0.911, anchor RMSE 0.409. No warnings.

**Board scores** come from other batches and judge pools, so read each change as indicative (about ±0.3), not as a paired gain.

## Results

| Row | Board | Main now (mapped) | Change | Raw a, b, c | Recorded defects (a / b / c) |
|---|---|---|---|---|---|
| **F36#68 Skyrill** | 6.33 | **7.47** | **+1.14** | 7.0, 6.8, 6.8 | chrome FIXED 3/3; faint sail up PARTIAL / FIXED / PARTIAL |
| F36#42 Cragclaw | 6.40 | 6.94 | +0.54 | 6.5, 6.3, 6.5 | salmon plastic FIXED 3/3; faint same as standing FIXED 3/3 |
| F36#49 Glimmermoth | 6.43 | 6.90 | +0.47 | 6.7, 6.3, 6.2 | upright faint FIXED / PARTIAL / PARTIAL; pale body PARTIAL 3/3; trainer height FIXED / FIXED / PRESENT |
| F36#46 Fulgocobra | 6.38 | 6.78 | +0.40 | 6.4, 6.2, 6.3 | dark body FIXED / PARTIAL / PARTIAL; hood up PARTIAL / PRESENT / PARTIAL |
| F36#85 Veridian | 6.63 | 6.33 | **−0.30** | 6.0, 5.9, 5.9 | contorted faint neck PRESENT 3/3; moss noise PRESENT / PARTIAL / PARTIAL; tiny rider PRESENT 3/3 |
| F36#61 Ribbonray | 6.48 | **5.68** | **−0.80** | 5.3, 5.6, 5.3 | magenta effect PARTIAL 3/3; airborne hit FIXED 3/3 |
| **F39#18** dialogue framing | 6.16 | **7.06** | **+0.90** | 6.6, 6.6, 6.4 | FIXED / PARTIAL / FIXED |
| F39#26 dialogue obstruction | 6.01 | 6.49 | +0.48 | 6.2, 6.0, 6.0 | PARTIAL 3/3 |
| F39#29 speaker visibility | 6.61 | 6.41 | −0.20 | 6.0, 6.2, 5.8 | PARTIAL 3/3 |
| F39#27 grass around characters | 6.57 | 6.16 | −0.41 | 5.8, 6.0, 5.6 | FIXED 3/3 |

- **Pose sample:** 4 of 6 species rise and 2 fall. The mean change is **+0.24**, in line with the +0.3 ±0.8 estimate in `LOW-HANGING-6TO7.md`.
- **Skyrill, 7.47:** 0.03 under the bar, so it qualifies for the close-out exception. Medium is not warranted until High reaches 7.5.
- **F39#18, 7.06:** matches the earlier one-sided 7.07 in `G-confirm-f39-26.md`.
- **F39#26, 6.49:** lower than that note's 6.88.

## What the judges say (unprompted)

**Shared pose cause (3/3 top change, scene):** the faint and collapse poses leave wings, sails, hoods and antlers upright while the body goes down.
- Glimmermoth's wings, skyrill's sail in faint mid, fulgocobra's neck and hood, and veridian's antler slab, which "shoots up and back in a twisted spike" and "reads as broken geometry".
- One pose-data or rig fix would serve 4 of the 6 sample species, and probably more of the band.

**Ribbonray (3/3):**
- The whole body is saturated magenta and "reads as an effect, not a believable animal".
- Its anatomy is an unclear upright ray-lizard.
- Judge c saw the **tail tip floating detached on the floor in the hit frame**, which matches the GPU lane's note on hit 025 and 050.
- Two judges ask for a remake as a natural navy and cyan ray (new_art).

**Cragclaw (3/3):**
- The material is fixed, but it now reads as "a tortoise or golem, not the board's hermit crab", with claws and face hard to find.
- Judge b notes that a red crab would clash with the Team Tether rule anyway.

**Veridian:** the rider is "doll-sized" on the back in the ride frames (3/3).

**Owner-rule flag:** fulgocobra's copper or rust-brown neck and hood plates sit close to the reserved oxblood, raised as a check by 3/3 judges.

**Dialogue rows:**
- **F39#18:** speakers are now mid-shot beside the panel. The player's shoulder still fills the left edge, and Bex and Irva share one portrait.
- **F39#26:**
  - Frame 2 (Iona) has a huge curved green-grey sheet across the top right (3/3).
  - Adair's portrait shows a woman in glasses who looks like Iona, so the portrait does not match the speaker (3/3).
- **F39#29:** frame 3 (Captain Nerissa) is small, far off and half hidden behind the player in a dark chamber (3/3). Judge c says Nerissa's portrait and model are a bearded man. Judge b saw a sand wall curving up into the sky in frame 1.
- **F39#27:** the grass defect is FIXED 3/3. The row falls because the dunes are now "bare, flat-lit, nearly empty", with evenly scattered tufts and no clumps or edges.
- **Top change (3/3, scene):** dress the dune dialogue and post sites with grass clumps, driftwood, reeds and rocks; give the sand form and light; and keep the player's head out of the speaker's third.

## Answers
1. **Should the remaining ~14 pre-1-Nov pose rows be re-scored? Yes.**
   - It is a capture-and-judge pass with no code.
   - The sample moved 4 of 6 rows up, by +0.40 to +1.14, and found the two remakes that regressed.
   - Expected value is about +0.25 per row. The real value is replacing scores of meshes that no longer ship, and naming the per-species fix.
   - Batch them 7 per batch with this crop.
2. **Pass these to the board as the latest verdicts,** including the four rows that fell: Veridian, Ribbonray, F39#27 and F39#29.
3. **Next swings, in order of how many rows they touch:**
   - **Faint/collapse pose fix (shared, scene):** fold appendages down with the body. It touches glimmermoth, skyrill, fulgocobra and veridian, and would likely take Skyrill over 7.5.
   - **Tidewake dune dressing near speakers (scene):** F39#27, F39#26, F39#29 and F39#18.
   - **Portrait mismatches (data):** Adair shows Iona; Bex and Irva share one; check Nerissa.
   - **Ribbonray remake (Meshy, new_art).**
