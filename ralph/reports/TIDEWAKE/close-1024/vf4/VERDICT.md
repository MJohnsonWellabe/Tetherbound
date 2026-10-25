# Tidewake close-1024 round vf4: Veilfall upper-fall fix on the vista, CPU pre-judge (25 Oct 2026, CT)

## The defect (vv1 judges x3)

- The upper fall, `veilfall_white_cascade` (top 520 m, foot 200 m), stops mid-mountain.
- Its foot sprays form a horizontal puff, so it reads as "a flat white quad with a cross-shaped mist puff".

## Arms (OFF in play; `veilfall_falls_candidate`, per-column overrides by id in `water_veilfall.gd`)

- **f1:** foot dropped to 40 m, smaller and lower sprays.
  - The column is hidden behind the gully floor below about 200 m, so the lower spray floated as a loose cloud mid-cliff.
- **f2 (the committed candidate):** foot 40 m with no foot spray.

## Mapped Bar A (on top of t1e in every arm)

- **Yardstick:** standard prompt verbatim, three fresh code-blind judges, 3 anchor pairs (seed 9967).
- **Calibration:** `calibrate.py` slope 1.08, r 0.91, anchor RMSE 0.56.

| Arm | t1e alone | Arm | Δ | Judges |
|---|---|---|---|---|
| f2 | 4.44 | **4.80** | +0.36 | higher x3 |
| f1 | 4.44 | 4.36 | -0.08 | level |

The t1e vista mapped 5.06 in vv1 and 4.44 here: batch-to-batch spread on the same frames. Each comparison above sits inside one batch.

**Defect changes with f2:**
- **"Detached or cross-shaped mist":** PRESENT x3 → PARTIAL x3.
- **Unchanged:** the remaining base spray reads as a cotton blob at the shoreline.
- **Unchanged:** the falls still read as flat sheets, and the mountain as a block heap.

## What is left

- **The mountain and the falls are new art:** Meshy request 10 already asks for a terraced cliff mountain with layered falls and mist.
- **Rain fog:** all three judges again say it flattens the island to one grey.

## GPU capture (`tb/tidewake` 0167e0e80 or later)

`F39-look.json --views=veilfall-vista,veilfall-vista-rain`, with `--tidewake-look-sections=current_flow` and with `--tidewake-look-sections=current_flow,veilfall_falls_candidate`.
