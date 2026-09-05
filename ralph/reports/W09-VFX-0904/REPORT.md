# W09-VFX — combat and reward VFX (CL-A2) — lane report

Branch: `ralph/W09-VFX-0904` (from `origin/main` at `ef16544f`). Final commit: _(filled at the end)_.

## What the player sees

- **Every landed blow sparks.** A spray of 18 motes and streaks flies out of the point of
  contact, born white-hot and cooling to the move's element colour (ground tan, water blue,
  air white, dark violet, electric yellow, fire orange, psychic lilac, ice pale blue), falling
  under gravity and fading over 0.6 s. A charged move bursts 1.35× bigger; a blow that takes
  30 % of the bar bursts 1.8× the size of one that takes 4 %. The foe's own strikes carry the
  foe's element now too (they were always the default orange).
- **The struck creature flashes.** Its whole body lights for 0.16 s, brightest at the
  silhouette, per instance (no other creature of the species flashes).
- **A knockout puffs.** The blow that empties a bar lets a soft pale cloud out of the fainted
  creature, rising for 0.9 s. Fires for a wild fight ending and for a trainer's creature
  falling mid-battle alike.
- **A sealed catch sparkles.** Gold sparkles fly out of the orb and drift up for 1 s, on top of
  the existing warm seal flash.
- **A level-up is a picture.** For 1.5 s the creature that levelled stands in a column of
  light, two rings rise from its feet past its crown, gold motes climb around it and its body
  takes a gold rim. It plays on the deployed creature; a bench member levelling from the party
  share gets the HUD line only (D80 §4).

`data/config/vfx.json` holds every tunable; `enabled: false` is the whole revert.

## Files changed

| File | Change |
|---|---|
| `scripts/vfx/combat_vfx.gd` | new — the helper: static hooks `hit`, `catch_success`, `knockout`, `level_up`; the level-up watcher (polls `Game.party` by `revision`; `on_progression_event()` seam for `Game.progression_feed`) |
| `scripts/vfx/vfx_burst.gd` | new — the spark / puff / sparkle node (ImmediateMesh motes and streaks, physics-clocked, public `advance()`) |
| `scripts/vfx/body_glow.gd` | new — hit flash and level-up rim via per-instance `material_overlay` |
| `scripts/vfx/level_up_flourish.gd` | new — beam, rising rings, motes |
| `shaders/vfx_body_glow.gdshader` | new — fresnel-weighted unshaded overlay, MIX blend |
| `data/config/vfx.json` | new — tunables |
| `scripts/combat/combat_manager.gd` | `_flash_at()` takes the struck body and the damage fraction and calls `VFX.hit` (the one damage hook; both damage sites already funnel through it); the two player-strike calls and the enemy-strike call pass them; `_finish_catch()`'s seal branch calls `VFX.catch_success`. `_flee_pressed()` untouched. |
| `tests/test_combat_vfx.gd` | new — 8 tests, 52 assertions |
| `tools/_capture_vfx_moments.gd` | new — stages the fight, shoots 00–04, measures perf at band1_open |
| `tools/_probe_vfx_frame_energy.gd` | new — bright-warm / near-white / gold pixel counts per frame |
| `docs/decisions/D80-…md` | new — mesh-based not particles; overlay not material edit; KO from the damage hook; bench level-ups have no body |
| `docs/CURRENT_STATE.md` | CL-A2 row |
| `ralph/reports/W09-VFX-0904/` | this report, `_sheet_round1.png`, `_sheet_round2.png`, `JUDGE_round1.md`, `JUDGE_round2.md` |

`creature_body.gd` was not edited and needed no patch: the flash uses `material_overlay`,
which was free on every creature mesh.

## Tests and smokes (exact commands, from the repo root, `PATH=$HOME/godot-bin:$PATH`)

| Command | Result |
|---|---|
| `godot --headless --path . --script tests/run_tests.gd -- --only=test_combat_vfx.gd` | **8 tests, 52 assertions, 0 failed** (run after every edit; last on `77778f4b`) |
| same, with the `VFX.hit(...)` line in `_flash_at()` replaced by `pass` | **2 failed** — `test_a_landed_blow_spawns_a_spark…` ("no HitSpark under the arena after a landed blow", "the struck body did not get its flash") and `test_the_blow_that_empties_the_bar_adds_a_ko_puff` ("no KoPuff after the blow that emptied the bar"); the rest green. Restored; seen red for the right reason. |
| `godot --headless --path . --script tests/smoke_combat.gd` (baseline, before any change) | `combat: OK`, rc=0, zero `ERROR:` lines |
| `godot --headless --path . --script tests/smoke_combat.gd` (with the layer) | `combat: OK`, rc=0 |
| `godot --headless --path . --script tests/smoke_boss.gd` | rc=0 |
| `godot --headless --path . --script tests/smoke_trainer_battle.gd` | `trainer battle: OK`, rc=0 |
| `godot --headless --path . --script tests/smoke_catching.gd` | `catching: OK`, rc=0 |
| `godot --headless --path . --script tests/smoke_combat_camera.gd` | rc=0 |

`ERROR:` set across the five smokes: only `ERROR: Parameter "material" is null` from
`creature_body.gd::_build_model ← apply_size_multiplier ← encounter_director._make_alpha`
at world boot (2, 0, 1, 2, 1 occurrences) — the known-benign alpha-resize line
`docs/AGENT_WORKFLOW.md` §6 documents as count-unstable; it fires before any fight and
before any VFX node exists. No `SCRIPT ERROR`. The distinct set did not grow.

The unit test drives a real `combat_manager.gd::_on_enemy_strike()` (hit cone, rolled
damage, `take_damage`, faint handling) on a bare manager with stand-in bodies, and asserts
the spark, flash and puff came out of that path at the arena the manager parented them
under; lifetimes are walked through `advance()` because the unit runner never processes a
frame (`is_queued_for_deletion()` is the "freed" assertion). The watcher tests use the real
`autoload/party.gd` and a real `gain_xp()`.

## Runtime validation

Five smokes above exercise the hooks in the real scene (wild fight to a win, a boss, a
three-round trainer battle, a catch, the combat camera). The capture tool drove a further
two real fights per round through the real combat camera and confirmed at each shutter
which VFX nodes were alive (`[effects]` lines in the log): `HitSpark` + `foe/BodyGlow` at
01; `HitSpark`, `KoPuff`, `ally/LevelUpFlourish`, `ally/BodyGlow`, `foe/BodyGlow` at 02;
`KoPuff` + `ally/LevelUpFlourish` + `ally/BodyGlow` at 03; `CatchBurst` at 04. All eight
shots written, none failed, rc=0, both rounds.

## Frames and the blind judge

_(round 1 and round 2 sections filled below)_

## Perf

_(filled from the round-2 `[perf] DELTA` lines)_

## Known limitations and what was deliberately not done

- Bench level-ups (party share) show no world flourish; D80 §4. Tunable `bench_on_trainer`
  exists but is off and unimplemented on the trainer body by design.
- Level-ups are found by polling until `Game.progression_feed` lands (another lane). The
  seam is `combat_vfx.gd::on_progression_event()`; `min_gap` makes a poll detection and a
  feed event one flourish.
- No GPUParticles3D/CPUParticles3D (D80 §1). No new meshes, textures or generations.
- Frames are software GL: composition, scale, colour relationships and presence are what
  they can prove; fine lighting is not.
- The catch sparkle competes with `catching.json`'s existing white seal flash for its first
  third of a second; it is shot 16 ticks in, once that flash has faded.
- No sound cue: `data/config/audio.json` is not this lane's file.
