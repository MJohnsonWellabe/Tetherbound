# F35#1 — unique ultimates readable (lane tb/ev-ultimates)

Fix commits: 77b57674, c6746c4b (config only: `data/config/vfx.json`; no new meshes, no code).

## Root cause of the code-blind FAIL
- Every contact stage (flash/glow/shockwave/mark) of Veridian, Fulgocobra and Solmane sat on its
  `max_m` clamp at breakthrough 0, so breakthroughs 0 and 5 drew the same size.
- The contact burst ended 0.42 s after arrival, so the peak (+0.45 s) and late beats were empty.

## Change
- Veridian `root_stone_spikes.living_roots`: a ring of green root spires erupting at the target's feet,
  a green bloom and pollen, a green ground ring and glowing crack field; impact_scale 1.4 -> 2.0.
- Fulgocobra: new `chain_lightning.serpent_storm` variant; wider gold serpentine arc (size 0.55 -> 0.9),
  gold light, a gold contact burst, ground lightning cracks and ring. Gold keeps it apart from the
  blue-white sky bolts of Stormcapra / the storm bear.
- Solmane `wind_blade.solar_blades`: a sun-flare bloom, gold sunburst rays, a ground ring, a gold
  shockwave and scorch.
- All three hold contact through the late beat (duration 1.3–1.6 s, fade_hold_power 6). Stage scales sit
  under their caps (max_m <= 4, the existing test bound) so the size grows with breakthroughs.

## Terrapup "boulder"
Not a bug. `data/moves/ultimates.json` `ultimate_terrapup.launch.source_body` (also on Veridian) authors
a 0.7 s root spire 0.8 m *behind* the caster as the wind-up beat ("jaws lift beside the body"). The
spikes and contact use `target_ground` (`move_effect.gd` `_contact_position`). In the four-at-once
camera (behind the attackers) that wind-up spire stands between the lens and Terrapup. Changing it is a
design call; left unchanged.

## Checks
- `godot --headless --script res://tests/run_tests.gd -- --only=test_f23_live_moves.gd,test_move_effects.gd`
  -> 36 tests, 2867 assertions, 0 failed.
- `xvfb-run godot --rendering-driver opengl3 --resolution 1280x720 --fixed-fps 30 --script
  res://tests/smoke_move_effects_library.gd -- --batch=ultimates
  --ultimates=ultimate_veridian,ultimate_fulgocobra,ultimate_solmane` -> 6 cases, 0 failures,
  F23 override assertions 361/0. Sheet: `self-check-fixedfps-sheet.png` (rows: Fulgocobra b0/b5,
  Solmane b0/b5, Veridian b0/b5; columns travel/contact/peak/late).

## Disclosures
- The self-check sheet is the author's own look (llvmpipe), not the code-blind verdict. `--fixed-fps 30`
  (a stock Godot flag) was used so beats land at their nominal times; without it the llvmpipe frames
  (~2 s each) push peak/late past the 2.4 s presentation.
- The effects are still modest at the auto-frame camera distance. Look-alike pairs (Ripplet/Abyssal, the
  storm bear/Stormcapra, Terrapup/Veridian slab) are not changed beyond the Veridian and Fulgocobra rework.
- Four-at-once readability needs a real GPU (routed to Codex by the coordinator).
