# F19#5 (Meadows part): earned checkpoint chain, FAIL (blocked at `opening_team`)

Lane `meadows-route`, branch `tb/ev-meadows-route`. Times are US Central.

## Command (per piece, from `tools/earned_saves/earned_chain_runner.gd`'s header)

    godot --headless --path . --audio-driver Dummy \
      --script tools/earned_saves/earned_chain_runner.gd -- \
      --segment=opening_team --save-dir=<root>/opening_team/opening_team/save \
      --receipt=<root>/opening_team/opening_team/receipt.json

No `TB_WORLD_SEED` (the runner refuses it in new-order mode). Godot 4.7-stable headless. Injections: 0.

## Runs

| run | commit | world seed | result |
|---|---|---|---|
| attempt 1 | 9e39d0086 (main) | 1928975930 | FAIL `team`: wild training lost 4/4, **0 hits dealt** each |
| attempt 2 | 9e39d0086 (main) | 1408236928 | FAIL `team`: same, 0 hits dealt each |
| r2 | d05ce689 (fix below) | 1612717125 | FAIL `team`: "Native opening refused: actual production walk lost grounded floor" at (28.05, 1.07, -11.11) |
| r3 | d05ce689 | 150570182 | FAIL `team`: same refusal at (28.07, 1.08, -11.05) |

Filtered logs (per-frame navigator observations and duty spam removed) are the `*.filtered.gz` files here.

## Defect 1, fixed: stale client Energy vs host-owned move meter

- Symptom: the pilot pressed charged 65-113 times per fight; every press drew
  `[encounter] move_start refused: insufficient_energy (Land quick hits to build Energy.)` (315 refusals in one diagnostic run).
- Cause: `move_commit.runtime_enabled` routes solo wild moves through the encounter host, which starts each encounter's
  Energy at 0 (`encounter_host.gd` `move_resources`). The client creature kept Energy from an earlier fight
  (the solo tutorial filled it), so `combat_manager.charged_ready()` read true and the HUD/pilot offered a charged
  attack the host always refused. The pilot never fell back to quick hits, so it never built host Energy.
- Fix (d05ce689): `combat_manager.gd::bind_encounter` resets the party's client Energy to 0 when a new
  host-arbitrated encounter binds. This mirrors the host's starting row.
- Checks: `tests/run_tests.gd --only=` combat_progression (27/0 failed), director_join_snapshot (6/0),
  gate_f_charged_hit (4/0), move_commit_runtime (12/0), shared_boss_authored_pipeline (3/0),
  stormwood_hosted_combat (8/0).

## Defect 2, open: the team helper's walk refuses a terrain crest

- After the fix, catches and training proceed. The third catch (`Wild_bramblebun_1922_3`) is approached from the
  inn departure's field road (ending at (30,-40)) on a straight leg to the TrailGate (14,19).
- At about (28,-11) the player climbs from y 0.63 to 1.08 and is airborne for one frame (no contacts, falling).
  `tests/helpers/opening_geometry_navigator.gd:1994` then stops the walk with "actual production walk lost grounded floor".
- This reproduced at the same point in r2 and r3. Attempt 1 crossed the same area to the same gate on a slightly
  different line, about 1.5 m apart, and passed.
- Not patched. The fix belongs either to the terrain crest (Meadows geometry) or to the navigator's single-frame
  floor rule (a test helper's assertion). Changing either is outside "smallest fix without weakening a check" and
  needs a coordinator ruling.

## Not reached

- No piece after `opening_team` ran, so no fixtures are committed under `tests/fixtures/earned_saves/meadows_*`.
- Tidewake handoff gap: `earned_chain_runner.gd` new-order mode stops at `hall` (`HANDOFF.MEADOWS_PIECES` ends at hall).
  The `warden` piece is legacy-only and follows the obsolete Rift -> Cloudreach crossing. No new-order Meadows -> Tidewake
  handoff piece exists, so the last Meadows segment cannot end at the Tidewake handoff yet. This is a gap.
