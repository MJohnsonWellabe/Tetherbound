# Tidewake close-1024 round t4: T4 surf line at the waterline, CPU pre-judge (25 Oct 2026, CT)

## What changed (OFF in play; `--tidewake-look-sections=shore_surf_candidate`)

Every water and shore batch (t1, t2, t2b, dw1) named "the sand meets the water at a hard line with no surf or foam".

- **Shader:** `water.gdshader` gains optional `surf_strength`, `surf_depth_m` and `surf_breakup`.
  - It draws a broken foam band over the last `surf_depth_m` of depth.
  - The band is cut by the two-scale foam noise, so it never forms the solid ring that blind round 1 rejected.
  - `surf_strength` 0 (the default for every realm) keeps the old contact foam exactly.
- **Wiring:** `water.gd` passes the keys from the surface config.
- **Candidate:** the `shore_surf_candidate` section sets strength 1.0, depth 1.2 m and breakup 0.3.
  - A first try at 0.4 m and breakup 0.42 did not show in captures.
- Water colours are unchanged. The colour route stays parked.

## Mapped Bar A (on top of the t1e currents in both arms)

- **Yardstick:** standard prompt verbatim, three fresh code-blind judges, 3 anchor pairs (seed 6631).
- **Calibration:** `calibrate.py` slope 1.56, r 0.993, anchor RMSE 0.13.

| Set | t1e | t1e + surf | Δ | Judges |
|---|---|---|---|---|
| First Shore, lesson dune, First Shore 18:00 | 6.10 | **6.67** | +0.57 | higher x3 |
| Deep Watch 08:00 and 23:00 | 5.37 | **5.89** | +0.52 | higher x3 |

**Defect changes:**
- **"Hard shoreline, no surf":** PRESENT x3 → PARTIAL x2 and FIXED x1 (Deep Watch), PARTIAL x3 (shore).
- **"Foam reads as a drawn outline":** PARTIAL or PRESENT.
  - The band is even in width and brightness along its length.
  - At 23:00 it glows like a line drawn round the beach.
  - At 18:00 it barely shows.

## Next

1. Vary the band's width and brightness along the shore, and dim it at night.
2. Wet-sand darkening on the beach side of the waterline.
3. Beach clumps instead of even pebble and tuft scatter. Named by all three judges, every batch.

## GPU capture (`tb/tidewake` 510f05426 or later, Medium and High)

- **Shore:** `F39-look.json --views=shore-day,lesson-dune,shore-golden`, with `--tidewake-look-sections=current_flow` and with `--tidewake-look-sections=current_flow,shore_surf_candidate`.
- **Deep Watch:** `P2-008-shore.json`, with the same two section lists.
