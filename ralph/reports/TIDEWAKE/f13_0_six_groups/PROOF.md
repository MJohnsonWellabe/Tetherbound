# F13#0 — the route reaches all six Tidewake island groups

**Criterion** (Acceptance Board F13#0; ACCEPTANCE §6.1 F13, T2): "Earned route reaches all six island groups". The groups (`water_world.json` `regions`): first_shores, marsh_channels, tidal_cradle, outer_reaches, tether_current, veilfall.

**Harness.** `tests/smoke_tidewake_dry_run.gd` runs the existing Water segment helpers by controller input. After every segment it does a production `Game.save_game`, destroys the world, runs `reset_for_new_game`, then `Game.load_game` into a fresh Water scene. The late route is `tests/helpers/water_human_late_segment.gd`: the player's own swimming along the authored `*_sheltered` crossings, with the same five throughout and no mount.

## Runs (local headless, Godot 4.7)
| Run | Commit | Path | Result |
|---|---|---|---|
| 1 (`run1_start_to_late.txt`) | 193e08f4 | start → Pell → Reedhaven → Brine → Shellwatch → Tidal → late | Every segment through Tidal PASS, each with reload drift 0.00 m and the same party. Late reached Salt Crown and Sluice and beat Bex, then hit the harness's 180 s fight bound on Calder (B7). |
| 2 (`run2_resume_tidal_to_late.txt`) | 5b67ea91 (B7 bound raised; no game change) | resumed from run 1's `tidal` checkpoint → late | **PASS**: Tidal → Salt Crown (4 rest shoals), chart, → Sluice (4), Bex, Calder, → Veilfall (6 rest shoals), Venn, interior pumps, Nerissa (4 opponents), tether released. Reload after late: drift 0.00 m, same party. 48.0 min. |

## Island groups reached (by the player, by input)
| Group | Where | Run |
|---|---|---|
| first_shores | First Shore arrival, Pell's lesson | 1 |
| marsh_channels | Reedhaven repair, Brine Steps trial, Shellwatch liberation | 1 |
| tidal_cradle | Aquaryn defeated, Swim Stone, Iona | 1 |
| outer_reaches | Salt Crown landing charted | 1 and 2 |
| tether_current | Sluice: Bex and Calder, both controls | 1 (Bex), 2 |
| veilfall | Veilfall crossing (6 rest shoals), Venn, Nerissa (4 opponents) and tether in the log. The waterfall entry, intake pump and return sluice have no log lines of their own; the segment cannot pass without the world flags `water_veilfall_intake_stopped` and `water_veilfall_return_opened` and the interior check (`water_human_late_segment.gd`) | 2 |

## Shortcuts (disclosed; owner ruling 2026-09-27 06:58)
1. **Declared start.** The world flags `realm_gate_water_unlocked` and `stormwood:waterward_revealed` are set; the Water key is consumed; the belt is sparkit/mudsnout/bramblebun/terrapup/brooktail at L44; knife and axe are carried. The Water world is instanced at its production arrival, not entered through the Stormwood gate.
2. **Checkpoint resume.** Run 2 resumed from run 1's production `tidal` save (production load, not a state write).
3. **Harness-driven fights and walking.** A scripted pilot (`water_combat_pilot.gd`) presses real input actions; stick navigation follows authored route polylines.
4. **Harness changes since the segments were written:** the pilot presses paid quicks while the charged is Energy-gated; the Aquaryn challenge stance is re-approached up to 4 times; the late fight bound is 600 s and the watchdog 120 min for the human route.
5. **Local chains, pockets and the side islands** (Lantern Cove, Gull Rest, Drowned Garden, Deep Watch) are not part of this run. Those belong to F13#2 and F13#3, which are Tidewake-B's.
6. **Clock and recovery.** The segment helpers force `Engine.time_scale = 1.0` and 60 Hz physics. Party recovery before and after named fights uses the production camp service by input.
7. **Rest shoals** logged "idled 0.0 s to stamina 100/100". At level 0 the player never ran low on these crossings, so rest-shoal recovery itself is not exercised here.
8. **The shared host-Wind fix** (X05 `encounter_host.advance_wind`, merged from `tb/x05` 7ff64a15) is on this branch. It is not yet on main; it lands with this close.
