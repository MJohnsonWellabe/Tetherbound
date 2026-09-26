# F12#0: walked witness for every mandatory Tidewake hop

Criterion (ACCEPTANCE §6.1 F12#0): "With the original five and no owned swimmer, level-0 human
swimming finishes every mandatory Tidewake hop with at least 20% stamina after 15% steering
deviation."

**Result: PASS.** The 7 mandatory sheltered routes have 24 hops, and every one passed. Worst hop: 30.19% minimum stamina (`sluice_isle_to_veilfall_sheltered` hop 1). The 4 main-path direct alternatives also passed. Worst: 33.41%.

- Test: `tests/smoke_water_hop_walked.gd` (new, test-only). It changes nothing under `scripts/`, `data/`, `docs/` or `.github/`.
- Code under test: commit `1dba39073fc9a6f352baaf3d2980da17dbdc5a9e`, which is origin/main plus the test.
- Engine: Godot 4.7 stable, headless, Linux container. Four cores were shared with other agents, and runs went in parallel.

## What changed versus the earlier every-hop proof

The earlier proof is `ralph/reports/TIDEWAKE/f12_every_hop_original_five/`. It wrote the player's position onto every hop's start and forced a rest to full stamina before each hop. This witness chains the hops instead:

- **One position write per run.** It is the first route's departure anchor.
- **Within a route, no position write.** Each hop starts where the real arrival left the trainer. The largest distance to the authored hop start was 0.428 m, and the limit is 1.0 m.
- **Between routes, no position write.** The trainer walks from the arrival island's landing to the next route's departure anchor. Movement is real left-stick input (`tests/helpers/stick_navigator.gd`). The route comes from the harness-only baked-ground A* plan (`tests/smoke_water_pocket_walk_claim.gd::plan_route`, called statically). Every island walk had `confined_resets=0`.
- **No stamina write.** The idle-rest step exists, but it stands still with no input and no write. It never ran: `rest_frames=0` on all 28 committed hops (24 sheltered + 4 direct), and `arrive_pct=100.00` at every hop start.
  - Stamina was already full at every hop start. The last metres of each hop are wading in shallows and the dry landing. Normal dry-land regen (18/s) refills the meter there.
  - The island walks also end at 100%.
  - So no forced rest-to-full happened anywhere. A `--no-rest` run would take the same path. It was not run separately.
- **Unchanged from the earlier proof.** Every hop still has:
  - the original-five party checks (5 members, none a compatible swim mount, not mounted, no active MountedSwimming body, same party at start and arrival);
  - level-0 swim efficiency, with swimming XP cleared after each movement frame and minimum efficiency asserted at 1.0000;
  - `max_stamina` 100;
  - real `move_forward` input;
  - the arrival safe landing asserted;
  - health unchanged.
- **Steering.** Each hop swims a zigzag commanded at 1.155× the authored hop polyline. The test asserts it is between 1.14 and 1.17. Against the straight chord it reaches up to 1.228×. The largest single-frame stamina gain was 0.3000, which is within 18/s ÷ 60 + 0.02.

## Commands and results

Each command was run from the repository root with `XDG_DATA_HOME=$(mktemp -d) $HOME/godot-bin/godot --headless --path . --script tests/smoke_water_hop_walked.gd -- <args>`.

| args | log | result |
|---|---|---|
| `--from=0 --to=2` | `sheltered_0_2.log` | OK, 5 hops, worst 30.98%, 1 position write, 889.9 m walked, exit 0 |
| `--from=3 --to=4` | `sheltered_3_4.log` | OK, 7 hops, worst 38.59%, 1 position write, 713.3 m walked, exit 0 |
| `--from=5 --to=6` | `sheltered_5_6.log` | OK, 12 hops, worst 30.19%, 1 position write, 810.1 m walked, exit 0 |
| `--variant=direct --from=0 --to=3` | `direct_0_3.log` | OK, 4 hops, worst 33.41%, 1 position write, 1355.3 m walked, exit 0 |
| `--from=0 --to=6` (full chain, one position write in total) | `sheltered_0_6_full_chain.log` | INCOMPLETE at the deadline, see below |

**Chunk seams.** The three sheltered chunks run in separate processes, so each chunk starts with its own departure write. That gives two extra writes, at the reedhaven… → shellwatch_to_tidal_cradle departure and at the salt_crown departure. The full-chain run removes both.

## Full chain (0..6, one position write in total)

This run was **still running at the 21:05 UTC deadline and is not a pass claim.** `sheltered_0_6_full_chain.partial.log` is a snapshot taken at 21:00 UTC. At that point it had crossed routes 0–4 and part of route 5 with one position write in total: 17 of 24 hops, every one PASS, `rest_frames=0`. It had also done 4 island walks, each ending at 100% stamina. Its per-hop minimum stamina matches the chunk runs to within about 0.3 pp. The removal of the two chunk-seam writes stays open until a full run exits 0.

## Per-hop results (min stamina % while swimming)

"swim m" is the distance actually swum. Every hop started at 100% stamina, with no rest, and every hop result is PASS.

| route | hop | path m | swim m | steering vs path / chord | min stamina % |
|---|---|---|---|---|---|
| first_shore_to_reedhaven_sheltered | 1 | 118.3 | 90.1 | 1.155 / 1.178 | 30.98 |
| reedhaven_to_brine_steps_sheltered | 1 | 71.5 | 31.4 | 1.155 / 1.161 | 75.92 |
| reedhaven_to_brine_steps_sheltered | 2 | 71.5 | 31.8 | 1.155 / 1.161 | 75.64 |
| brine_steps_to_shellwatch_sheltered | 1 | 64.7 | 23.2 | 1.155 / 1.161 | 81.99 |
| brine_steps_to_shellwatch_sheltered | 2 | 64.7 | 23.5 | 1.155 / 1.161 | 81.66 |
| shellwatch_to_tidal_cradle_sheltered | 1 | 74.1 | 34.8 | 1.155 / 1.161 | 73.40 |
| shellwatch_to_tidal_cradle_sheltered | 2 | 74.1 | 35.2 | 1.155 / 1.161 | 72.89 |
| tidal_cradle_to_salt_crown_sheltered | 1 | 110.3 | 78.5 | 1.155 / 1.164 | 38.63 |
| tidal_cradle_to_salt_crown_sheltered | 2 | 92.3 | 54.5 | 1.155 / 1.155 | 57.25 |
| tidal_cradle_to_salt_crown_sheltered | 3 | 92.3 | 53.6 | 1.155 / 1.228 | 58.00 |
| tidal_cradle_to_salt_crown_sheltered | 4 | 92.3 | 54.6 | 1.155 / 1.155 | 56.88 |
| tidal_cradle_to_salt_crown_sheltered | 5 | 110.3 | 78.4 | 1.155 / 1.164 | 38.59 |
| salt_crown_to_sluice_isle_sheltered | 1 | 104.1 | 71.2 | 1.155 / 1.165 | 44.09 |
| salt_crown_to_sluice_isle_sheltered | 2 | 86.1 | 47.2 | 1.155 / 1.155 | 62.99 |
| salt_crown_to_sluice_isle_sheltered | 3 | 86.1 | 46.3 | 1.155 / 1.228 | 63.88 |
| salt_crown_to_sluice_isle_sheltered | 4 | 86.1 | 47.2 | 1.155 / 1.155 | 62.95 |
| salt_crown_to_sluice_isle_sheltered | 5 | 104.1 | 71.3 | 1.155 / 1.165 | 43.86 |
| sluice_isle_to_veilfall_sheltered | 1 | 117.8 | 87.5 | 1.155 / 1.164 | 30.19 |
| sluice_isle_to_veilfall_sheltered | 2 | 99.8 | 63.1 | 1.155 / 1.155 | 49.32 |
| sluice_isle_to_veilfall_sheltered | 3 | 99.8 | 63.2 | 1.155 / 1.155 | 49.18 |
| sluice_isle_to_veilfall_sheltered | 4 | 99.8 | 62.3 | 1.155 / 1.228 | 49.93 |
| sluice_isle_to_veilfall_sheltered | 5 | 99.8 | 63.1 | 1.155 / 1.155 | 49.18 |
| sluice_isle_to_veilfall_sheltered | 6 | 99.8 | 63.1 | 1.155 / 1.155 | 49.27 |
| sluice_isle_to_veilfall_sheltered | 7 | 117.8 | 87.2 | 1.155 / 1.164 | 30.33 |
| first_shore_to_reedhaven_direct | 1 | 116.0 | 86.7 | 1.155 / 1.155 | 33.41 |
| reedhaven_to_brine_steps_direct | 1 | 140.1 | 66.0 | 1.155 / 1.155 | 74.94 |
| brine_steps_to_shellwatch_direct | 1 | 126.7 | 49.9 | 1.155 / 1.155 | 81.05 |
| shellwatch_to_tidal_cradle_direct | 1 | 145.0 | 71.8 | 1.155 / 1.155 | 72.70 |

## Island walks between routes (real left stick, baked-ground A*)

| to departure | straight m | walked m | legs | off-trail m | stamina after |
|---|---|---|---|---|---|
| reedhaven_to_brine_steps_departure | 277.6 | 442.8 | 60 | 2 | 100% |
| brine_steps_to_shellwatch_departure | 273.8 | 447.1 | 70 | 0 | 100% |
| shellwatch_to_tidal_cradle_departure (direct chain) | 305.4 | 465.5 | 61 | 0 | 100% |
| tidal_cradle_to_salt_crown_departure | 376.3 | 713.3 | 105 | 8 | 100% |
| sluice_isle_to_veilfall_departure | 429.0 | 810.1 | 130 | 0 | 100% |

## Fixtures (disclosed)

- **Party.** `ORIGINAL_FIVE` (terrapup L44, bramblebun L43, mudsnout L42, pipwing L42, trailpup L41) is granted into the fresh game's real `Game.party` through `PartySeam.add()`. Provenance is the same as the earlier proof: `chapter_curve.json` `difficulty.party` plus the PROGRESSION Tidewake arrival band. The party is not earned through play.
- **Departure flags.** Every chained route's `required_departure_flag` is set true at the start. These are water_swim_lesson_complete, water_dock_reedhaven_repaired, water_dock_brine_steps_trial_won, water_dock_shellwatch_residents_freed_and_pump_disabled, water_aquaryn_resolved, water_dock_salt_crown_landing_charted and water_dock_sluice_isle_both_controls_disabled. This does **not** prove the story objectives were earned.
- **Realm.** `current_realm = "water"`. The Water scene is instanced directly.
- **Position writes.** There is one per process, onto the first route's departure anchor at baked height + 0.15 m. The sheltered chunk runs add two seam writes, as described above.
- **Swim level.** Swimming XP is cleared after every swim frame, which pins drain to level-0 efficiency. This is conservative.
- **Walk planner.** The island-walk planner is harness-only. It writes nothing into the world.

## Not covered

- The optional routes (lantern_cove, gull_rest) and the mounted `main_path: false` routes.
- Combat pause, reload and co-op across hops. Those belong to other F12 criteria.
- Wild encounters. The navigator pauses a walk if one starts, and the swim path fails loudly if locomotion is blocked. None interrupted these runs.

## Review follow-ups

- Hop count corrected: the committed logs hold 28 hops (24 sheltered + 4 direct), not 31.
- `rest_frames=0` is logged on every hop, but the test does not assert it. The idle-rest step defaults to on (`tests/smoke_water_hop_walked.gd:87`, `:207-211`), so a future regression that needs a rest would still pass. A follow-up should assert `rest_frames == 0` or make `--no-rest` the default. The evidence here shows that no rest ran.
- The steering ratio is measured on the commanded path, not the path actually swum. This is the same method as the prior proof.
- `sheltered_0_6_full_chain.log` (a single 0–6 chain with one position write) had not finished when this commit was made, so it is not claimed.
