# F35#1 — unique ultimates readable (lane tb/ev-ultimates)

Fix commits 77b57674, c6746c4b; config only (`data/config/vfx.json`), no meshes, no code.

Root cause: Veridian/Fulgocobra/Solmane contact stages sat on their `max_m` clamps (b0 == b5), and the
burst ended 0.42 s after contact (empty peak/late).

Change:
- Veridian `living_roots`: green root-spire ring at the target's feet, bloom, pollen, ring, glowing cracks.
- Fulgocobra new `serpent_storm`: wide gold serpent arc, gold burst, ground cracks, ring (apart from the
  blue-white storm-bear/Stormcapra bolts).
- Solmane `solar_blades`: sun-flare bloom, gold rays, ring, gold scorch.
- Contact holds into the late beat; stage scales under caps (max_m <= 4) so breakthroughs grow.

Terrapup boulder: not a bug. It is the authored `launch.source_body` wind-up spire 0.8 m behind the
caster (`ultimates.json`, also Veridian); the spikes and contact use `target_ground`. Left unchanged.

Checks:
- `run_tests.gd --only=test_f23_live_moves.gd,test_move_effects.gd`: 36 tests, 2867 asserts, 0 failed.
- `xvfb-run godot --rendering-driver opengl3 --resolution 1280x720 --fixed-fps 30 --script
  res://tests/smoke_move_effects_library.gd -- --batch=ultimates --ultimates=ultimate_veridian,
  ultimate_fulgocobra,ultimate_solmane`: 6 cases, 0 failures. Sheet: `self-check-fixedfps-sheet.png`
  (rows Fulgocobra/Solmane/Veridian b0,b5; columns travel/contact/peak/late).

Disclosures: the sheet is the author's own look, not the code-blind verdict. `--fixed-fps 30` makes beats
land on time under llvmpipe. Look-alike pairs are unchanged. Four-at-once frames need a real GPU.
