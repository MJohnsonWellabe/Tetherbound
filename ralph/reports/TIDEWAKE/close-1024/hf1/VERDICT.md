# Tidewake close-1024 round hf1: F39#4 Veilfall heightfield relief, CPU pre-judge (25 Oct 2026, CT)

## What the faceted slabs are

A raycast probe plus an offline hillshade of the analytic heightfield showed what fills the veilfall-near close-up.

- **Not the gate crags.** The render-only relief arms change the crags but not this frame.
- **The cone flanks.** Veilfall's 620 m cone (power 1.65) has huge smooth flanks either side of its one landing sector.
- **The trail-grading cut walls.** These are long, straight, steep trenches where the hikes are graded into the cone (3 m walk plus 15 m shoulders).

## What changed

`water_heightfield.gd` gains `terrain.veilfall_relief` (in `water_world.json`):
- **Shape:** ridged value-noise crag relief, 8 m amplitude at a 20 m wavelength, Veilfall only.
- **Order:** applied after trail grading, so it also breaks up the graded cut walls.
- **Masks:** zero within 1 m beyond every trail's walk surface, fading in over 4 m. Zero on the 30 m shore band, near the summit, within 20 m (+15 m fade) of the gate entrance, and within each route, loop, shortcut or anchor's site clearance.

The relief is rebaked into the six Veilfall terrain regions (3.8 MB). No other region changed.

## Gameplay half: proved

- **Walk test:** `test_water_veilfall_relief_walk` samples every metre of `veilfall_exploration_spine` at the centreline and both 3 m walk edges (over 1000 samples). The walk band's height is identical with the relief on and off, so the graded slope and its limit are unchanged. Every Veilfall anchor's safe and shore positions and the gate entrance also keep their height, and the flanks change.
- **Route audit:** `tools/audit_water_route_grades.gd` output is byte-identical with the relief on and off (`veilfall_exploration_spine` max_slope 30.37 both ways).
- **Route impact is zero,** so there is no route change for an earned-save piece to prove.
- **Other tests:** heightfield and Veilfall tests, 29 tests and 14252 assertions, 0 failed.

## Mapped Bar A (CPU pre-judge; the GPU decides done)

Yardstick: standard prompt verbatim, three fresh code-blind judges, 3 anchor pairs (seed 13939). `calibrate.py`: slope 0.969, r 0.82, anchor RMSE 0.54; the close-up is extrapolated.

| View | Shipping | Relief | Δ | Judges |
|---|---|---|---|---|
| Veilfall close-up, clear and rain | 4.17 | **4.39** | +0.22 | higher x3 |
| Venn fight, matched moments | 5.36 | **5.72** | +0.36 | higher x3 |
| First Shore and lesson-dune distance views | 6.88 | 6.88 | 0.00 | level |

**Defect changes:**
- **Fight frame:** "the near-black slab intrudes" moved from PRESENT x3 to PARTIAL x3. The fight's top-right corner now shows "a grey hillside instead".
- **Close-up:** "near-black slabs" moved to PARTIAL x2. Stretch and two-families are still PRESENT. This is a modest step, not a fix.

## Status

The relief is ON on `tb/tidewake` (config plus bake), for the GPU lane to capture. It will not ride a land head until the GPU judges it.

GPU command: `capture_tidewake_f13_5.gd --camera-set=res://tools/visual_judge/camera_sets/F39-look.json --views=veilfall-near,veilfall-rain`, plus the Venn fight (`phase2_capture_tidewake_fights.gd --trainer=water_trainer_venn --seed=2042`). The control is any commit before this one.

## Files

- `batch.json`, `mapped.json`, `key.json`
- `_sheet_hf1.jpg` (left: shipping, right: relief)
