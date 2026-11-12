STATUS: land

# READY: storm phase stills settle before the shot (LANE-PLACES, 12 Nov 2026)

Branch `tb/places-phasetool-land`, cut from current main. Capture tool only: `tools/phase2_capture_storm_phases.gd`. No game change.

## Why
GPU lane, swing-3 pre-check: the F41#2 stills did not match between two sides that differ only in the road (Building looked like Calm on one side, Break had no bolt on one, Fading had a bolt on the other). The game reported the right phases; the tool shot a few frames after each clock jump.

## Change
After pinning a phase the tool lets two seconds of game time run, settles the presentation again, then:
- Break: waits (up to 240 frames) for a decorative bolt at level 0.3 or more, so the Break still shows lightning;
- every other phase: fails the capture if any lightning is visible at the shot.
Each shot logs `STORM PHASE SHOT <phase> bolt_level=… lightning_visible=… waited=…` and records it in the manifest (`stormwood_lightning_at_shot`).

## CPU proof (`_sheet_cpu_four_phases.jpg`: calm, building, break, fading)
Log: calm 0.00 false, building 0.00 false, break 1.00 true (waited 7), fading 0.00 false. Mean brightness 94.9, 74.0, 69.7, 91.5: four distinct stills, bolts only in Break.

## After it lands
Re-capture F41#2 (base only, four phases) for a clean row score; earlier F41#2 stills, including the 6.19 re-score, may have caught a mid-transition frame.
