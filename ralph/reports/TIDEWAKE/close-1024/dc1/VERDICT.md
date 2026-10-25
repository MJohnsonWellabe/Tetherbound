# Tidewake close-1024 round dc1: First Shore declutter, CPU pre-judge (24 Oct 2026, CT)

- **Why.** The owner, on the GPU lt2 sheet: "The beach sand looks good to me. Just looks cluttered and the water maybe could use work."
- **Candidate.** Two OFF sections, judged together:
  - `first_shore_declutter_candidate` drops the two First Shore driftwood logs and the deck-work cluster that this lane added in p1.
  - `stones_candidate` thins the beach pebble tier from density 0.9 to 0.2, grouped, with wider bare gaps and a soft tide-line band.

  Sand, grade and regrade are untouched. A diagnostic capture with the stone tier off confirmed the beach "dot field" is that tier.
- **Capture.** `tb/tidewake` 57acc2c0a or later. CPU llvmpipe, Low. Six views: First Shore at midday, 18:00, 23:00 and in rain; the lesson dune at midday and 05:00.
- **Yardstick:**
  - Standard prompt verbatim, three fresh code-blind judges.
  - 3 anchor pairs, seed 12828.
  - `calibrate.py`: slope 1.107, r 0.85, anchor RMSE 0.49. No extrapolation warning.

## Mapped Bar A (CPU pre-judge; under the 24 Oct owner direction the GPU decides done)

| Side | Raw (j1/j2/j3) | Mapped |
|---|---|---|
| Shipping | 5.1 / 4.6 / 5.1 | 5.25 |
| Declutter | 5.6 / 5.0 / 5.6 | **5.77** |

The declutter gains **+0.52**, with every judge higher.

| Defect | Shipping | Declutter |
|---|---|---|
| Beach reads cluttered | PRESENT x3 | PARTIAL x2, FIXED x1 |
| Even scatter | PRESENT x3 | PARTIAL x3 |

## What the judges still ask for

- A night sky with a moon and stars. The Forward+ night candidate is queued for the GPU lane.
- Flat rain.
- Water: the judges say "a thin milky band with pier and buoy marks that look like flat decals" and "push to the board's cyan and navy". This is the owner's second point and comes next.
- Grouped dune grass and driftwood lines on the bare lesson dune.

## GPU queue

READY for the GPU lane. Capture on Medium and High:

- **Candidate:** `capture_tidewake_f13_5.gd --camera-set=res://tools/visual_judge/camera_sets/F39-look.json --views=shore-day,shore-golden,shore-night,shore-rain,lesson-dune,lesson-dawn --tidewake-look-sections=stones_candidate,first_shore_declutter_candidate`
- **Control:** the same command without `--tidewake-look-sections`.

## Files

- `batch.json`, `mapped.json`, `key.json`
- `_sheet_dc1.jpg` (left: shipping, right: declutter)
