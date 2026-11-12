STATUS: land

# READY: lightning goes out the moment Break ends (LANE-PLACES, 12 Nov 2026)

Branch `tb/places-breakonly-land`, cut from current main. A fix, not a judged arm: no flag.

## Why
Owner rule: lightning is Break's cue only. The GPU F41#2 Fading still showed a bolt on main and on every arm. The GPU lane's motion probe (`G-fading-bolt-motion-probe` 93b455abe) settled it: the game fires nothing in Fading, but a Break strike alive when the phase changes was left to decay into Fading (up to about 0.9 s in play, and frozen into the still, which is shot a few frames after the jump).

## Change
`stormwood_surge.gd _clear_decorative_lightning()`: when the phase moves to a row without `flashes` (on a cross-fade and on `settle_presentation`), live decorative bolts, the cloud flash, the sky flash and their lights go out at once. A drop in light, never a new onset. Break's own bolts are untouched; strikes, telegraphs and timing are untouched.

## Test
`tests/test_places_storm_phase_rain_grade.gd::test_leaving_break_puts_out_live_lightning_at_once` (both paths; entering Break keeps its bolts). `--only=places_storm,stormwood_surge_presentation,stormwood_lightning`: 66 tests, 0 failed.

## After it lands
F41#2 needs a fresh base capture: Fading should show no bolt with the existing tool (it calls `settle_presentation`), so no tool change is needed.
