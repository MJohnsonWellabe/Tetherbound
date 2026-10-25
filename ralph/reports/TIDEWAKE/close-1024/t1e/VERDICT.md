# Tidewake close-1024 round t1e: currents follow-ups t1b-t1e against t1, CPU pre-judge (25 Oct 2026, CT)

## What changed on top of t1 (all OFF in play; `--tidewake-look-sections=current_flow`)

Driven by the t1, t2 and t2b judges:
- **t1b:** `moon_glint` foam emission (new optional shader uniform, 0 = unchanged).
- **t1c:**
  - The loud yellow triangles were the procedural pennant (3.0 x 1.2 m), not the Meshy buoy. They are now a 1.1 x 0.5 m navy pennant on a 1.4 m weathered pole.
  - The spar buoys are back at their measured 1.9 m, at an 8 degree lean.
  - `moon_glint` 0.3.
- **t1d:** the flat lane band is off, the channel tint 0.18 → 0.12, open-water flecks 0.25 → 0.1.
- **t1e:** the two bank seams, which were long straight pale bands from the dock to the horizon, break into wandering tongues:
  - gap 0.15 → 0.45;
  - wander 3 → 5 m;
  - width 1.2 → 0.9 m;
  - opacity 0.4 → 0.3.

## Mapped Bar A

- **Yardstick:** standard prompt verbatim, three fresh code-blind judges, 3 anchor pairs (seed 4421).
- **Calibration:** `calibrate.py` slope 1.21, r 0.90, anchor RMSE 0.41.

| Set | t1 | t1e | Δ | Judges |
|---|---|---|---|---|
| Swim views (along day, across day, along night) | 5.25 | **5.77** | +0.52 | higher x3 |
| First Shore, lesson dune, First Shore 18:00 | 6.54 | **6.66** | +0.12 | higher x3 (by 0.1) |

t1's swim views moved between batches: 5.92 in t1, 6.41 in t2, 5.25 here. Within each batch, t1e and t1 sit in the same batch, so the +0.52 is a matched comparison.

**Defect changes, t1 → t1e:**
- **"Channel markers read as loud or oversized placeholders":** PRESENT x3 → FIXED x2 and PARTIAL x1.
- **"Road markings, straight bands":** PRESENT x3 → PARTIAL x3.
- **"Path and direction cannot be read":** PARTIAL x3 → PRESENT x2 and PARTIAL x1. This is the cost of breaking up the seams.
- **"At night the current cannot be seen":** PARTIAL x3 → PRESENT x3. The t1 night read came from the straight seams, and the 0.3 glint does not replace it.

## Next (named by all three)

1. A curving, flow-following current read that says which way without straight bands.
2. A visible night current: a cooler sheen in the lane, not on the open sea.
3. Fewer evenly sized crescent caps on open water.

## GPU capture

Same commands as `t1/VERDICT.md`, at `tb/tidewake` 63aeaefe6 or later.
