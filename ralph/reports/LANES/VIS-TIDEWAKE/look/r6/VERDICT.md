# VIS-TIDEWAKE look round 6: Tidewake night stars (CPU); s1 ships ON

- Base: round-5 base (Veilfall near ON). Candidates: `tidewake_look.json` `cause_tidewake.stars` at
  s1 = star_brightness 1.6 / density 0.025 (r6), s2 = 3.2 / 0.045 / scale 200 plus a navy night top (r6b).
- One packet, both arms, same stands; `look_spec.py`, `anchor_tiles.py`, 3 code-blind judges in one message,
  `calibrate.py`: r 0.97, anchor RMSE 0.32.

| Row | s1 base | s1 cand | s2 base | s2 cand |
|---|---|---|---|---|
| F39#30b night/dawn/approach | 4.77 | 4.89 | 4.89 | 4.72 |
| F13#5 currents + Veilfall vista | 5.45 | 5.84 | 5.39 | 5.84 |

- s1 gains on both rows and ships ON (`_why_on`, asserted in `test_tidewake_cause.gd`).
- s2 lost: judges saw stars in the overcast rain sky and the noon Veilfall sky. Cause: `world_look.gd`
  only wrote `star_brightness` when a sky cfg had it, so the night value carried into later day skies.
  Fixed: a sky cfg without `star_brightness` now sets 0. The s1 frames had the same carry-over at a lower
  brightness, so the fix only removes a defect from the shipped arm.
- The F13#5 move is in the night current streak frames as well as the vista; treated as partly run variance.
- Asks still open: moonlit blue night grade (not black), real rain grade, a tiered green Veilfall (new art),
  flow-aligned current foam.
