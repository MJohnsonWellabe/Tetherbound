# F19#5 (Meadows part): earned checkpoint chain (in progress)

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

## Defect 2, fixed: woodpile on cottage_b_8's door approach (the "lift")

- r2/r3 and r4 refused "actual production walk lost grounded floor" with the trainer 0.15-0.2 m above the
  ground and no contacts. A scratch replay of r4's path (scripts kept out of the repo) reproduced it
  deterministically: the controller's 0.35 m step-up climbs `Props/cottage_b_backyard/log_large_Collision`
  (StaticBody3D, layer 1, BoxShape3D 1.27 x 0.42 x 1.05, top y 1.27), which sits on `doorstep_26`
  (top y 0.95), only 0.32 m below the log top. The capsule rolls off the box edge (normals tilt to 0.90),
  floor snap finds no floor-angle contact, and the trainer falls for 4 frames.
- The village move had left this "back-yard" woodpile between doorstep_26 and cottage_b_8's front door
  (south wall z 24). Fix 67bb3047 (data): moved to the real back wall (z 29.1). The same replay now has
  0 airborne frames. The r3 crate (`village_twins_yard/Crate_Wooden`, 0.93 m) is too tall to step onto;
  the r3 lift was not re-identified, but every later refusal now prints its colliders.
- Checks: 17 prop/band/village unit files pass (band_content 6/0, vegetation_siting 19/0,
  village_road_topology 15/0, the props.json visual-identity tests, and others).

## Navigator alignments (coordinator rulings; tests/helpers/opening_geometry_navigator.gd)

1. Deep overlap (ca277f4d). Live zero-motion recovery is queried with margin = safe_margin (0.001 m), so the
   engine's recovery is that inflation plus penetration. The observed case against `Vegetation/Rock_Medium_1`
   had contact depth 0.000275 m (inside skin) and recovery 0.00151 m. The bound is now margin + safe_margin
   = 2 x safe_margin, consistent with the per-contact depth <= safe_margin rule. Larger recoveries still fail.
2. Contact count (ca277f4d). The total slide contact count is an observation, not a pass/fail cap: a run
   stopped on 9 points (6+2+1), all plain Terrain on a ~13 deg slope, against CONTACTS = 8. Every point of every
   slide is still validated, and slide count is still bounded by max_slides <= 8.
   `tests/probe_f19_fresh_contact_overflow.gd`, a diagnostic probe for the old cap and not a test, no longer triggers.
3. Lost-floor message (ca277f4d) now prints slide colliders, class, layer, owner, normal and point.
4. Request budget (49ad747b). MAX_REQUESTS (24000) is now per walk_to destination. r6 reused one navigator
   for the whole training phase: 24001 requests, ~1979 m walked, 27+ wild wins, no geometry fault.
   MAX_QUERIES_LIFETIME (250000; r6 used 71973) remains the lifetime guard.
- Navigator unit tests after each change: deferral 14/0, low_prop 2/0, gate_a_npc_gather_segment_contract 22/0.

Infrastructure: r5 stalled on repeated "production input dispatch deadline" deferrals (the navigator's 10 ms
per-frame budget) while 17 unit files ran in parallel on this 4-core host. Chains now run on an idle machine.

## Runner extension (8ba3e4cd, coordinator ruling 3)

`warden` (new order) runs `tests/helpers/f49_warden_finale.gd` `run_finale` with no Rift. It declines the freed
legendary so the same five UIDs survive every handoff identity check, as `f49_campaign_journey.gd` does; accepting
with warden_accept would release a member. `tidewake_handoff` uses Home Key home, hangs the Meadows relic and enters
the Tidewake portal (`f49_portal_travel.gd`), and is exported in realm `water`.
`HANDOFF.MEADOWS_PIECES/REALMS` gain both pieces. Hall-segment unit test 16/0.

## Superseded: the original "terrain crest" reading (kept for the record)

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
