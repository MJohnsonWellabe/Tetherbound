# G-land-cs-overlook-seams: F40#15 buried approach pavers not built (GPU High, base vs arm)

## Verdict: SHIP. F40#15 5.10 → 5.41 (+0.31, 3/3). Overlook other views 5.10 → 5.41 (+0.31, 3/3). The High Perches no-loss set reads 6.68 → 6.38 (−0.30, 0/3), but that drop comes from creature-spawn staging, not from the arm (see below).

| Set | Base | Arm | Gain | Prefer arm | Raw a / b / c (base → arm) | Defect (base → arm) |
|---|---|---|---|---|---|---|
| **F40#15** (overlook walk_02, walk_03) | 5.10 | **5.41** | **+0.31** | 3/3 | 4.3→4.6, 4.6→4.8, 4.9→5.2 | a PRESENT→PRESENT; b PARTIAL→PARTIAL; c PRESENT→PARTIAL |
| Overlook other (route_day, vista_dusk, walk_01) | 5.10 | 5.41 | +0.31 | 3/3 | 4.4→4.7, 4.4→4.6, 5.0→5.3 | a PRESENT→PRESENT; b PARTIAL→PARTIAL; c PRESENT→PARTIAL |
| High Perches no-loss (2x2) | 6.68 | 6.38 | −0.30 | 0/3 | 6.2→5.8, 5.7→5.5, 6.0→5.8 | none recorded |

- **Scores:** all mapped. Fit: r 0.910, slope 1.16, anchor RMSE 0.58; the batch is confirming.
- **Board baseline:** F40#15 is 5.60 on the board, from another panel; this panel reads base at 5.10. The paired gain is the measure.
- **Missing frame:** the windscar aerie job frame was not in the section, so F40#15 is read on the overlook walk pair, as the 5.60 was.

## Why the Perches drop is not counted as a loss caused by the arm
- **What the arm touches:** it removes buried approach pavers at the Stormward overlook (summit piece 12). The High Perches (piece 08) are a different place.
- **What differs in the Perches frames:** the GPU lane measured the 64 Perches frames at a mean pixel difference of 1.9, all rain and creature-spawn noise.
- **What the judges say decided it:** all three name creature staging, not the court. On the base side, "the blue wyverns are framed centrally with wings spread … a strong silhouette". On the arm side, "a creature is cut off at the left edge in frames 1 and 3". Court, cobbles, rails and pillars are described identically on both sides.
- **Precedent:** the AQUARYN beach-creature confound (G-below6-aquaryn-ride-c673) and the ROSTERNAMES camera-state withdrawal were handled the same way. The drop is disclosed, not hidden.
- **If the coordinator wants it proven:** re-capture the 2x2 with a fixed creature seed. I expect it to come back level.

## Addendum (14 Nov): Perches confound confirmed by a second run
- **The run:** the GPU lane pushed `G-land-cs-seams-perches-confirm`, a second base run and a second arm run of the same 64 Perches/Sky Shrine frames.
- **On the four frames judged here (my own diff):**
  - Base run 1 against base run 2: mean difference 5.6 to 7.9.
  - Base run 1 against the arm: 4.6 to 5.2.
  - So two base runs differ from each other by more than the arm differs from base, in every judged frame.
- **Pooled over all 64 frames (GPU lane):** base against base 3.20, best base against arm 1.74.
- **Conclusion:** the −0.30 is run-to-run creature and rain staging, not the arm. The verdict stands: SHIP, with no Perches loss.
- **Not re-judged:** no close is at stake, and the pixel evidence settles it.

## What the judges see
- **F40#15 and overlook (3/3):** the base adds "a dark green flat slab behind the trainer by the tree", "a dark slab in the grass" in walk_03, and "a cobblestone strip that crosses the wedge and runs off-frame" in route_day and vista_dusk. None of these are on the arm, so the arm removes what it was meant to remove.
- **What remains on both sides:**
  - The **dark brown wedge strip** right of the trainer in route_day and vista_dusk, which the GPU lane also flagged as staying.
  - A **thin dark slit strip** at the trainer's feet in walk_02.
  - The recorded defect stays PRESENT or PARTIAL on the arm.
- **Holding the row near 5.4 (3/3):**
  - The terrace reads as blockout: flat, blurry green ground with evenly scattered grass cards, and boxy moss-brick slab walls.
  - One rampart panel or tower "overhangs the cliff edge and floats over air" (walk_03, frame 3).
  - The "arch" is a single bent beam with a hanging ring, and the dirt path is a blurry pasted decal.
  - Nothing of the board's pale stratified stone, carved arches or gold accents.

## Next asks (LANE-LAND-CS)
1. **Remove the remaining dark wedge strip** (route_day, vista_dusk) **and the walk_02 slit strip.** They are the last instances of the recorded defect; the row moves only when it reads FIXED. Scene.
2. **Seat the rampart and tower on the cliff** instead of overhanging the void (walk_03). Scene.
3. **Replace the blurry pasted dirt-path decal and the flat green plane** with a stone-edged path and grouped grass clumps. Scene.
4. **Rebuild the terrace as the board's pale stratified stone with a carved arch,** replacing the slab walls and single-beam arch. New art (Meshy hero piece); it is the row's ceiling.
