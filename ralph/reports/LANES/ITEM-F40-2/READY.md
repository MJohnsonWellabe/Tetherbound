STATUS: parked
BRANCH: tb/item-f40-2  HEAD: (see the commit that adds this file)

# F40#2 P2-022 summit aviary (LANE-CR, 7 Nov 2026)

Row F40#2 P2-022. Live: 6.16 (NEAR6-CR CPU, `summit_silhouette` ON). This lane: no judged gain; nothing turned ON.
CPU llvmpipe, Compatibility, quick_judge, three code-blind judges, pinned anchors.

## Rounds
- **Built stone-ground candidate (`cloudreach_f40_items.json` candidates[9], `--cloudreach-f40-stone-ground-candidate`): not judged, invisible in F40#2's frames.**
  - Its SummitEyrieStronghold stand runs from the location target (local 111.3, 45.05) toward the dome.
  - The approach camera's trainer stands about 32 m back from that target, so the shelves land about 35–45 m out, at the dome's base.
  - Self-look of base vs candidate on the day approach frame: no visible difference. The capture was stopped before judging.
  - That stand is a matrix stand (`capture_cloudreach_f40_matrix.gd` stand 10), not a location stand.
- **r1 `qj/F40-2-r1`: new candidate candidates[12] `--cloudreach-f40-summit-stand-shelves`, OFF.**
  - Arm: the same shelves and scree re-keyed to the trainer's approach stand (local 140.96, 57.06), plus two outcrops at the dome base (out of frame).
  - Mapped 6.88 -> **6.15 (-0.73, worse)**. Raw base 6.4 / 5.6 / 6.3, candidate 5.9 / 5.2 / 5.9. Calibration RMSE 0.477.
  - All three judges: the evenly spaced, similar-sized chalk-white stacks read as generator scatter, and they are the brightest objects in the night frame. Stays OFF.
- **r2 (overlay `window_night_energy` 0.8 -> 2.4): not judged.**
  - Self-look of the night frame: no visible change; window emission does not bloom on CPU Low.
  - Not committed. It may read on the GPU, but it is not worth a CPU round.

Note: this round's base mapped 6.88, against NEAR6-CR's 6.16 for the same build state. That is calibration drift between batches; the GPU re-judge settles the live level.

## Flags
- ON: none.
- OFF, left in the tree: `cloudreach_f40_items.json` candidates[12] (r1, worse) and candidates[9] (built by VIS-CLOUDREACH, still unjudged on F40#2 because it is invisible there; it may still matter for the F40 matrix stands 0 and 10).

## Files touched
- `data/config/cloudreach_f40_items.json`: appended candidates[12], OFF.

## Tests
None: no flag turned ON. JSON parse checked.

## Judges' remaining asks (unanimous)
- Seat the aviary on a layered pale-stone cliff or plinth base, with arches or falls.
- A cloud sea below the summit. `cloud_ring` exists, but this camera sits on the flat top, far from the rim, and never sees it.
- A warm interior glow through the dome at night.
- The foreground is a uniform meadow lawn; any stone must be authored and varied, never even scatter.

## Next idea
- Blender row: a stratified plinth or skirt mesh under the drum that is visible from the approach camera, as one authored landform rather than scattered stacks. Keep it pale, with some value variation.
- Or a GPU-only check of the night window glow.
