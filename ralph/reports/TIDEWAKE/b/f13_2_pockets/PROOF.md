# F13#2 — Eight reward pockets reachable and paid (TIDEWAKE-B)

Criterion: ACCEPTANCE §6.1 F13#2. Branch `tb/tidewake-b-f13-2-pockets` from origin/main `32bd3307`.
Commit: see PR head (SHA recorded in the PR Evidence table).

## Changes

1. `data/config/water_pickups.json` — `reed_root_hollow` filled. The existing Reedhaven reed patch
   `water:reedhaven:harvest:012` (Reed Fiber, yield 3, unchanged) moved from (-174, 422) to
   (-99.0, 18.2175, 459.5), 2.65 m from the pocket centre (radius 5), with `reward_pocket_id:
   reed_root_hollow`. `gather_action` corrected `hand` -> `knife` to match Reed Fiber's registered
   `gathered_with` (water_crafting.json; the harvest node reads ItemDB, so behaviour is unchanged).
   Analytic heightfield: 18.2 m dry, slope 5.7° (5-point footing within 35°), main-route distance
   recomputed 47.594 m with the same segment method that reproduces the old row's 86.094 m.
   Census (per-island and per-item row counts) unchanged: a move, not an addition. Cradle precedent.
   Reed Fiber is what Reedhaven's pier repair spends (6 Reed Fiber, water_dock_actions.json), which is
   the pocket's authored purpose ("supporting pier repair").
2. `tests/test_water_reward_pockets.gd` — the reed hollow is no longer asserted unresolved. New
   `test_reed_hollow_pays_one_reed_seam_and_invents_no_recipe`: exactly the one documented seam in
   the hollow, row names the pocket, yield unchanged, tool matches registration, actually moved,
   full shared placement contract (dry footing, analytic y, landing-connected flood fill, 5.99 m
   spacing, NPC/camp/dock clearance, landings clear), census unchanged, no invented item for the
   composite role, no pickup row claims the recipe half. Every pocket must now be named by a row.
3. `tests/smoke_water_pocket_walk_claim.gd` — new generic `_seam_leg` + Reedhaven leg (`--no-reed`
   to skip, `--only=reed_root_hollow`). Gated pockets (`requires_world_flags`): the smoke now proves
   the Deep Watch candy is NOT resident before the Tidecoil flag, then writes the flag as a disclosed
   fixture and walks/claims. Before this, the full smoke failed at Deep Watch on main
   (`smoke_all_pockets_before_gate_fixture.log`: "candy not resident on arrival") because the gate
   added upstream was never met by the smoke.

## Commands

```
godot --headless --path . --import            # worktree .godot cache lacked newly added assets
godot --headless --path . --script tests/run_tests.gd -- --only=test_water_reward_pockets,test_water_harvest_density,test_water_reedhaven_segment,test_water_earned_swimmer_preparation_segment,test_water_lastlight_shelter,test_water_cradle_care,test_water_pickup,test_water_personal
godot --headless --path . --script tests/smoke_water_pocket_walk_claim.gd -- --only=reed_root_hollow
godot --headless --path . --script tests/smoke_water_pocket_walk_claim.gd -- --only=deep_watch_tidecoil_cache
godot --headless --path . --script tests/smoke_water_pocket_walk_claim.gd
```

Logs: `unit_tests.log` (7 files, 32 tests, 14831 assertions, 0 failed; the printed
"WATER SWIMMER PREPARATION FAILED" line is that suite's expected negative case),
`smoke_reed_only.log` (9 checks, 0 failures), `smoke_deep_watch_only.log` (8 checks, 0 failures),
`smoke_all_pockets.log` (full run after the gate fixture), `smoke_all_pockets_before_gate_fixture.log`
(first full run: 45 checks, 1 failure = Deep Watch gate, all others paid).

## Per-pocket result (production Water scene, baked ground, real stick walk + real Interact press)

| Pocket | Row | Walk from | Paid | Result |
|---|---|---|---|---|
| lantern_hidden_cache | water:lantern_cove:pickup:002 | first_shore_to_lantern_cove_arrival, 204 m | Skill Candy I | ACCEPTED |
| reed_root_hollow | water:reedhaven:harvest:012 | first_shore_to_reedhaven_arrival, 219 m | 3 Reed Fiber (knife) | PAID — reed half only; recipe half open |
| brine_upper_shelf | water:brine_steps:pickup:001 | reedhaven_to_brine_steps_arrival, 483 m | Skill Candy I | ACCEPTED |
| gull_research_satchel | water:gull_rest:pickup:002 | reedhaven_to_gull_rest_arrival, 129 m | Skill Candy I | ACCEPTED |
| salt_bell_terrace | water:salt_crown:pickup:001 | tidal_cradle_to_salt_crown_arrival, 464 m | Skill Candy | ACCEPTED |
| garden_exposed_vault | water:drowned_garden:pickup:002 | salt_crown_to_drowned_garden_arrival, 224 m | Skill Candy | ACCEPTED |
| deep_watch_tidecoil_cache | water:deep_watch:pickup:002 | sluice_isle_to_deep_watch_arrival, 231 m | Skill Candy III | ACCEPTED after gate; absent before gate |
| cradle_shell_nest | water:tidal_cradle:harvest:007 | Tidal Cradle arrival, 500 m | 4 Reef Stone (pickaxe) | PAID |

Full-run numbers above are from the first full run (unchanged legs) plus the per-pocket reruns;
`smoke_all_pockets.log` holds the post-fix full run (FULL_RUN_RESULT (post-fix, all eight pockets, one run on commit 3855a1654ed912ca3d0a3823051f62772daf4278 code): **48 checks, 0 failures, rc=0**. Six Skill Candy pockets ACCEPTED (Deep Watch via the gate fixture), Cradle +4 Reef Stone, reed hollow +3 Reed Fiber PAID. below).

FULL_RUN_RESULT (post-fix, all eight pockets, one run on commit 3855a1654ed912ca3d0a3823051f62772daf4278 code): **48 checks, 0 failures, rc=0**. Six Skill Candy pockets ACCEPTED (Deep Watch via the gate fixture), Cradle +4 Reef Stone, reed hollow +3 Reed Fiber PAID.

## Disclosed fixtures

- One position write per island onto its authored arrival landing (no swim between islands).
- Harness-only AStar route planner over the baked ground; movement is real left-stick input.
- Carried pickaxe and knife granted into hotbar slots 1–2 before the world loads.
- Deep Watch: `water_named_deep_watch_tidecoil_resolved` written directly after proving the candy
  absent without it; the real Tidecoil resolution is `tests/smoke_water_deep_watch_chart.gd`, not rerun here.
- Single local host; no co-op peer in this smoke.

## Remaining gaps (plain)

- **reed_root_hollow recipe half is not paid.** No data-only recipe-grant path exists: every Water
  recipe except the Swim Saddle unlocks at `water_chapter_started`, and pickups only grant items. Paying
  a recipe needs either an owner-chosen recipe with a new `unlocked_by` flag plus a pickup/harvest
  consumer that sets a personal flag — a runtime change outside this lane's owned files — or an owner
  decision that the reed fiber alone satisfies the role.
- **Deep Watch gate:** the gate itself is implemented in data (`requires_world_flags` read by the host
  claim rule and the streamer) and proven locked-then-open here; the walk used a flag fixture rather
  than fighting Tidecoil in the same run.
- **Long-range lure:** not implemented. No pocket has a data-only visible lure; the only lure pattern
  (`water_local_chains.json` props, `stormwood_pockets.json` mouth_lure) is outside owned paths and
  would need its consumer confirmed. WORLD's optional-activity rule requires a discoverable lure.
- No multiplayer (second character) claim of a pocket in the walked smoke; host claim rule unit-tested only.
