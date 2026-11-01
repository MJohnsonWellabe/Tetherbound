# CREATURES-F36 r1: arm 1 near-bar fixes vs main (CPU, three judges)

**Verdict: no gain on any species. Not sent to the GPU.**

Control: main 3a0e1fa0d. Candidate: tb/creatures-f36 cd45d921b (Ripplet, Aquaryn) and its r2 commit (Breezetail, stronger flatten). Neither commit changes any other judged species.

| Species | Change | Mapped main | Mapped arm | Gain | Defect (main / arm) |
|---|---|---|---|---|---|
| Ripplet | r3 grade: lighter, grey-white underside | 6.30 | 6.30 | 0.00 | flat teal coat PARTIAL x3 / PARTIAL x3 |
| Aquaryn | rear-up hit with the lift pivot pitch cut to 45%, stronger spine/neck recoil | 7.01 | 7.01 | 0.00 | forefeet lift PRESENT x3 / PRESENT x3 |
| water_aquaryn | (same recipe) | 6.97 | 7.01 | +0.04 | PRESENT x3 / PRESENT x3 |
| Breezetail | blue harness print flattened to one strap tone | 6.58 | 6.58 | 0.00 | busy harness PRESENT x3 / PRESENT x3 |

- **Fit:** linear, slope 1.06, intercept -0.30, r 0.79, RMSE 0.57. Confirming batch (top anchor 7.53, craft and f36_0_npc:C1 included).
- **Raw scores:** in `batch.json`. All three judges gave identical scores to both sides of every candidate set, and said the two sides looked the same.

**Why it failed:**
- At the roster crop the creature fills about 150 px, so belly value, harness print and a 10° pitch change all fall below what the judges can see.
- Arm 1's own sides show the changes: Ripplet's flank is visibly greyer and Aquaryn's forefeet sit closer to the ground. They are still under the judges' threshold.
- **Lesson:** at this crop only silhouette changes register (a faint that collapses, a pose that changes shape). Texture fixes need a close crop, and the GPU score of record does not use one.

**Dropped during the round (never judged):**
- **Solmane.** A full side-roll faint stood the near wing straight up. A 30° slump raised the head instead of dropping it. The wings are static mesh with no bones, so no pose recipe can fold them. Solmane needs wing bones or a new mesh (coordinator).

**Stop-rule count:** round 1 under 0.5 for Ripplet, Aquaryn and Breezetail.

Tile layout: standing, hit 050, faint 050, faint 100. Sheet `_sheet_r1.jpg`: main on the left, arm on the right; rows are Ripplet, Aquaryn, Breezetail.
