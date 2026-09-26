# F13#3 — normal-play route witness, six Tidewake local chains

Criterion: ACCEPTANCE §6.1 **F13#3** "Six selected local chains, one per group, satisfy §5"
(visible lure, distinct optional action, useful once-only reward, acknowledgement, saved completion).
Board gap addressed: normal-play route witness (the six per-chain smokes pose the trainer by teleport and
call prompts/conversations directly).

Test: `tests/smoke_tidewake_b_chain_route.gd` (production `scenes/world/water_archipelago.tscn`).
Base: origin/main `0e2a3b60c9263d4d96d447869d6e34d57efa2506`. The test file is the only code change; the commit SHA that carries it is the
branch head named in the PR (this file is committed in that same commit).

## Command
```
cd <worktree> && $HOME/godot-bin/godot --headless --path . --import   # stale copied .godot cache only
for c in lantern gull cradle garden deep lastlight; do
  XDG_DATA_HOME=$(mktemp -d) godot --headless --path . --script tests/smoke_tidewake_b_chain_route.gd -- --only=$c > ralph/reports/TIDEWAKE/b/f13_3_chain_route/$c.log 2>&1
done   # run as 6 parallel processes; each builds its own world and does its own save/reload
```
Godot 4 headless, Linux, 4 shared cores (3 other agents' Godot jobs running concurrently).

## What is real input
- Movement: left-stick `InputEventJoypadMotion` only, steered by `tests/helpers/stick_navigator.gd` along a
  harness A* plan over the **baked** ground (`smoke_water_pocket_walk_claim.gd` `plan_route`, reused unchanged).
- Every step is triggered by the ordinary `interact` action once the production interaction arbiter's
  winning provider is that step's own prompt (NPC Greet prompt, WaterLocalChains site prompt, pickup/seam
  `Interactable`, WaterDocks chart control). Conversations are opened by that press and every line is
  advanced by further `interact` presses read by the production DialoguePanel. The pickaxe is equipped by the
  real `hotbar_N` action.
- Messages are read off the player-visible HUD message strip (`playground_hud.gd` `_hotbar_message`).
- Saved completion: production `Game.save_game` -> `reset_for_new_game` -> `Game.load_game` -> rebuilt Water
  world (`tests/helpers/water_chain_reload.gd`), then records/receipts/items/quest-log re-asserted and the
  requester is walked to and greeted again by Interact (acknowledgement, no re-offer, no extra item).

## Fixtures disclosed (not done by input)
1. **Position writes**: when the next target is on another island, the trainer is placed on that island's
   authored arrival landing (`anchors[kind=arrival].safe_position`); inter-island swims are **not** traversed.
   First Shore has no arrival anchor: its first leg walks from the world's own start spawn with no write, and a
   later return re-places the trainer on that spawn. Deep Watch has one extra write to a dry stand in
   Tidecoil's reach. Every write is printed as `POSE` and listed per run.
2. **Upstream story facts** pre-set before load (the same facts the six per-chain smokes pre-set): world
   `water_swim_lesson_complete`, `water_dock_reedhaven_repaired`, `water_dock_brine_steps_trial_won`,
   `water_aquaryn_resolved`, `water_dock_salt_crown_landing_charted`; character `water_swim_lesson_briefed`,
   `water_swim_stone_earned`. (`water_aquaryn_resolved` also satisfies Otto's swimmer-or-trial gate, so the
   cradle return here does not exercise the owned-swimmer branch; that is `smoke_water_cradle_care.gd`.)
3. Carried pickaxe added and bound to hotbar slot 1 before load.
4. **Tidecoil fight not played**: its resident named body is marked engaged and the director's production
   won-fight handler `_on_combat_exited("won")` is invoked.
5. Lastlight: 4 driftwood + 4 reed fiber added to the satchel before the walk to the delivery prompt; after
   walking to the Veilfall camp bed the production `bed.assign_creature(0)` is called (bed panel UI not driven);
   a Brooktail is spawned into the party only if the reset party is empty.
6. Where the baked-ground planner has no dry cell route (NPCs on dock decks over water, e.g. Pell), the walk is
   one straight left-stick leg with navigator detours, printed `WALK <label> DIRECT`.
7. Solo host only; co-op split stays covered by the rule unit tests.

## Per-chain expected vs observed
| Chain | Expected route | Result | Observed |
|---|---|---|---|
| side_water_lantern_return | Pell lead -> Lantern Cove Candy I cache -> Pell return -> thanks | PASS | CHAIN side_water_lantern_return PASS reward=Candy I +1 ack=water_pell_lantern_thanks; RELOAD lantern water_pell -> water_pell_lantern_thanks; checks=54 failures=0 exit=0 |
| side_water_gull_research | Adair lead -> Gull Rest satchel site -> Candy II -> Adair return -> thanks | PASS | CHAIN side_water_gull_research PASS reward=Candy II +1 ack=water_adair_gull_thanks; RELOAD gull water_adair -> water_adair_gull_thanks; checks=59 failures=0 exit=0 |
| side_water_cradle_care | Otto lead -> shell-nest Reef Stone seam (hotbar pickaxe) -> Otto return, 3 berries -> thanks | FAIL | CHAIN side_water_cradle_care FAIL reward=berries +0 reef_stone +0 ack=; RELOAD cradle water_otto -> ; checks=47 failures=14 exit=1; first failures: FAIL: water_otto: walk stalled at leg 1/1 player=(704.3495, 45.45381, 1539.247) goal=(700.0, 0.0, 1542.0) / FAIL: Cradle: Otto gives the lead () / FAIL: Cradle: lead recorded |
| side_water_garden_records | Edda lead -> Drowned Garden vault wall -> Candy II -> Edda return (pre-Tether history) -> post line | PASS | CHAIN side_water_garden_records PASS reward=Candy II +1 ack=return:water_edda_garden_return after=water_edda_garden_thanks; RELOAD garden water_edda -> water_edda_garden_thanks; checks=59 failures=0 exit=0 |
| side_water_deep_watch_chart | Orsen names Deep Watch -> Tidecoil resolved (fixture) -> Orsen chart lead -> Candy III cache -> chart control -> Orsen charted | PASS | CHAIN side_water_deep_watch_chart PASS reward=Candy III +1 ack=water_orsen_deep_watch_charted; RELOAD deep water_orsen -> water_orsen_deep_watch_charted; checks=61 failures=0 exit=0 |
| side_water_lastlight_shelter | Halen lead -> Veilfall delivery (4+4) -> Halen rest request -> bed rest -> thanks | NOT FINISHED | no CHAIN line; no reload line; checks=? failures=? exit=not finished; first failures: FAIL: water_halen: walk stalled at leg 1/1 player=(357.3599, 105.9417, 4096.896) goal=(191.0, 0.0, 4163.0) / FAIL: Lastlight: Halen gives the lead () / FAIL: Lastlight: lead recorded |

### lantern (`lantern.log`)
```
     at: _instance_reset_physics_interpolation_bind_compat_104269 (servers/rendering/rendering_server.compat.inc:62)
     GDScript backtrace (most recent call first):
         [0] _ready (res://scripts/world/water_world.gd:63)
         [1] _build_world (res://tests/smoke_tidewake_b_chain_route.gd:124)
         [2] _run (res://tests/smoke_tidewake_b_chain_route.gd:105)
WALK water_pell DIRECT (no baked-ground plan from (0.0, 1.931193, 162.0) to (53.368, 2.075612, 151.502))
WALK water_pell island=first_shore walked=53m legs=1
TALK water_pell conversation=water_pell_lantern_lead hud='Pell's lead: the dry nook beneath Lantern Cove's rock arch, west of First Shore.'
POSE lantern_cove arrival landing for water:lantern_cove:pickup:002 -> (-267.245, 1.929, 129.805)
WALK water:lantern_cove:pickup:002 island=lantern_cove walked=204m legs=34
CLAIM water:lantern_cove:pickup:002 skill_candy_i 0->1
POSE first_shore arrival landing for water_pell -> (0.0, 2.078572, 162.0)
WALK water_pell DIRECT (no baked-ground plan from (0.0, 1.931163, 162.0) to (53.368, 2.075612, 151.502))
WALK water_pell island=first_shore walked=53m legs=1
TALK water_pell conversation=water_pell_lantern_return hud='Pell marks your Lantern Cove return line. The swim back from the arch is yours to reuse.'
WALK water_pell island=first_shore walked=0m legs=1
TALK water_pell conversation=water_pell_lantern_thanks hud=''
WALK water_pell island=first_shore walked=0m legs=1
TALK water_pell conversation=water_pell_lantern_thanks hud=''
CHAIN side_water_lantern_return PASS reward=Candy I +1 ack=water_pell_lantern_thanks
RELOAD lantern water_pell -> water_pell_lantern_thanks
POSES (2 disclosed position writes):
  lantern_cove arrival landing for water:lantern_cove:pickup:002 -> (-267.245, 1.929, 129.805)
  first_shore arrival landing for water_pell -> (0.0, 2.078572, 162.0)
Walked total 309m with left-stick input
Tidewake-B chain route witness: 54 checks, 0 failures
exit=0
```

### gull (`gull.log`)
```
     at: _instance_reset_physics_interpolation_bind_compat_104269 (servers/rendering/rendering_server.compat.inc:62)
     GDScript backtrace (most recent call first):
         [0] _ready (res://scripts/world/water_world.gd:63)
         [1] _build_world (res://tests/smoke_tidewake_b_chain_route.gd:124)
         [2] _run (res://tests/smoke_tidewake_b_chain_route.gd:105)
POSE brine_steps arrival landing for water_adair -> (267.637, 1.929, 580.191)
WALK water_adair island=brine_steps walked=455m legs=70
TALK water_adair conversation=water_adair_gull_lead hud='Adair's request: recover the survey satchel left at Gull Rest, off Reedhaven's sheltered line.'
POSE gull_rest arrival landing for gull_research_satchel -> (-56.825, 1.929, 789.065)
WALK gull_research_satchel island=gull_rest walked=125m legs=21
SITE gull_research_satchel hud='Survey satchel recovered: Adair's current observations. Carry them back on your next Brine Steps passage.'
WALK water:gull_rest:pickup:002 island=gull_rest walked=3m legs=1
CLAIM water:gull_rest:pickup:002 skill_candy_ii 0->1
POSE brine_steps arrival landing for water_adair -> (267.637, 1.929, 580.191)
WALK water_adair island=brine_steps walked=455m legs=70
TALK water_adair conversation=water_adair_gull_return hud='Adair charts the safe Gull Rest crossing from the recovered observations.'
WALK water_adair island=brine_steps walked=0m legs=1
TALK water_adair conversation=water_adair_gull_thanks hud=''
WALK water_adair island=brine_steps walked=0m legs=1
TALK water_adair conversation=water_adair_gull_thanks hud=''
CHAIN side_water_gull_research PASS reward=Candy II +1 ack=water_adair_gull_thanks
RELOAD gull water_adair -> water_adair_gull_thanks
POSES (3 disclosed position writes):
  brine_steps arrival landing for water_adair -> (267.637, 1.929, 580.191)
  gull_rest arrival landing for gull_research_satchel -> (-56.825, 1.929, 789.065)
  brine_steps arrival landing for water_adair -> (267.637, 1.929, 580.191)
Walked total 1040m with left-stick input
Tidewake-B chain route witness: 59 checks, 0 failures
exit=0
```

### cradle (`cradle.log`)
```
     at: _instance_reset_physics_interpolation_bind_compat_104269 (servers/rendering/rendering_server.compat.inc:62)
     GDScript backtrace (most recent call first):
         [0] _ready (res://scripts/world/water_world.gd:63)
         [1] _build_world (res://tests/smoke_tidewake_b_chain_route.gd:124)
         [2] _run (res://tests/smoke_tidewake_b_chain_route.gd:105)
POSE tidal_cradle arrival landing for water_otto -> (535.497, 1.929, 1352.51)
WALK water_otto DIRECT (no baked-ground plan from (535.497, 1.931604, 1352.51) to (700.0, 56.9451, 1542.0))
FAIL: water_otto: walk stalled at leg 1/1 player=(704.3495, 45.45381, 1539.247) goal=(700.0, 0.0, 1542.0)
FAIL: Cradle: Otto gives the lead ()
FAIL: Cradle: lead recorded
WALK water:tidal_cradle:harvest:007 island=tidal_cradle walked=175m legs=24
MINE water:tidal_cradle:harvest:007 reef_stone 0->4
WALK water_otto DIRECT (no baked-ground plan from (816.8746, 55.36427, 1644.533) to (700.0, 56.9451, 1542.0))
FAIL: water_otto: walk stalled at leg 1/1 player=(705.2583, 45.63467, 1542.092) goal=(700.0, 0.0, 1542.0)
FAIL: Cradle: Otto takes the report ()
FAIL: Cradle: completion recorded
FAIL: Cradle: return pays exactly 3 berries
FAIL: water_otto: walk stalled at leg 1/1 player=(701.3607, 45.29795, 1537.236) goal=(700.0, 0.0, 1542.0)
FAIL: Cradle: acknowledgement ()
FAIL: Cradle: quest log done
FAIL: Reload keeps world record water_claim:local:cradle_care:complete
FAIL: Reloaded quest log: shell nest done
FAIL: water_otto: walk stalled at leg 1/1 player=(704.0841, 45.48841, 1540.099) goal=(700.0, 0.0, 1542.0)
FAIL: Reload: water_otto acknowledges, no re-offer ()
CHAIN side_water_cradle_care FAIL reward=berries +0 reef_stone +0 ack=
RELOAD cradle water_otto -> 
POSES (1 disclosed position writes):
  tidal_cradle arrival landing for water_otto -> (535.497, 1.929, 1352.51)
Walked total 175m with left-stick input
Tidewake-B chain route witness: 47 checks, 14 failures
exit=1
```

### garden (`garden.log`)
```
     at: _instance_reset_physics_interpolation_bind_compat_104269 (servers/rendering/rendering_server.compat.inc:62)
     GDScript backtrace (most recent call first):
         [0] _ready (res://scripts/world/water_world.gd:63)
         [1] _build_world (res://tests/smoke_tidewake_b_chain_route.gd:124)
         [2] _run (res://tests/smoke_tidewake_b_chain_route.gd:105)
POSE salt_crown arrival landing for water_edda -> (289.458, 1.929, 2112.224)
WALK water_edda island=salt_crown walked=478m legs=73
TALK water_edda conversation=water_edda_garden_lead hud='Edda's request: copy the account on the Drowned Garden's exposed vault wall and bring it to Salt Crown.'
POSE drowned_garden arrival landing for garden_records_wall -> (1058.315, 1.929, 2249.446)
WALK garden_records_wall island=drowned_garden walked=220m legs=35
SITE garden_records_wall hud='Vault wall account copied: the old dock ledgers carved before the Tether. Bring it to Edda at Salt Crown.'
WALK water:drowned_garden:pickup:002 island=drowned_garden walked=4m legs=1
CLAIM water:drowned_garden:pickup:002 skill_candy_ii 0->1
POSE salt_crown arrival landing for water_edda -> (289.458, 1.929, 2112.224)
WALK water_edda island=salt_crown walked=478m legs=73
TALK water_edda conversation=water_edda_garden_return hud='Edda adds the vault's dock account to the Salt Crown records.'
WALK water_edda island=salt_crown walked=0m legs=1
TALK water_edda conversation=water_edda_garden_thanks hud=''
WALK water_edda island=salt_crown walked=0m legs=1
TALK water_edda conversation=water_edda_garden_thanks hud=''
CHAIN side_water_garden_records PASS reward=Candy II +1 ack=return:water_edda_garden_return after=water_edda_garden_thanks
RELOAD garden water_edda -> water_edda_garden_thanks
POSES (3 disclosed position writes):
  salt_crown arrival landing for water_edda -> (289.458, 1.929, 2112.224)
  drowned_garden arrival landing for garden_records_wall -> (1058.315, 1.929, 2249.446)
  salt_crown arrival landing for water_edda -> (289.458, 1.929, 2112.224)
Walked total 1180m with left-stick input
Tidewake-B chain route witness: 59 checks, 0 failures
exit=0
```

### deep (`deep.log`)
```
     at: _instance_reset_physics_interpolation_bind_compat_104269 (servers/rendering/rendering_server.compat.inc:62)
     GDScript backtrace (most recent call first):
         [0] _ready (res://scripts/world/water_world.gd:63)
         [1] _build_world (res://tests/smoke_tidewake_b_chain_route.gd:124)
         [2] _run (res://tests/smoke_tidewake_b_chain_route.gd:105)
POSE sluice_isle arrival landing for water_orsen -> (650.68, 1.929, 2774.917)
WALK water_orsen island=sluice_isle walked=998m legs=156
TALK water_orsen conversation=water_orsen_pre hud=''
POSE tidecoil stand (fight fixture) -> (1456.812, -0.406972, 3442.196)
POSE sluice_isle arrival landing for water_orsen -> (650.68, 1.929, 2774.917)
WALK water_orsen island=sluice_isle walked=998m legs=156
TALK water_orsen conversation=water_orsen_deep_watch_chart_lead hud=''
POSE deep_watch arrival landing for water:deep_watch:pickup:002 -> (1260.318, 1.929, 3403.144)
WALK water:deep_watch:pickup:002 island=deep_watch walked=231m legs=31
CLAIM water:deep_watch:pickup:002 skill_candy_iii 0->1
WALK deep_watch_chart island=deep_watch walked=218m legs=29
POSE sluice_isle arrival landing for water_orsen -> (650.68, 1.929, 2774.917)
WALK water_orsen island=sluice_isle walked=998m legs=156
TALK water_orsen conversation=water_orsen_deep_watch_charted hud=''
WALK water_orsen island=sluice_isle walked=0m legs=1
TALK water_orsen conversation=water_orsen_deep_watch_charted hud=''
CHAIN side_water_deep_watch_chart PASS reward=Candy III +1 ack=water_orsen_deep_watch_charted
RELOAD deep water_orsen -> water_orsen_deep_watch_charted
POSES (5 disclosed position writes):
  sluice_isle arrival landing for water_orsen -> (650.68, 1.929, 2774.917)
  tidecoil stand (fight fixture) -> (1456.812, -0.406972, 3442.196)
  sluice_isle arrival landing for water_orsen -> (650.68, 1.929, 2774.917)
  deep_watch arrival landing for water:deep_watch:pickup:002 -> (1260.318, 1.929, 3403.144)
  sluice_isle arrival landing for water_orsen -> (650.68, 1.929, 2774.917)
Walked total 3442m with left-stick input
Tidewake-B chain route witness: 61 checks, 0 failures
exit=0
```

### lastlight (`lastlight.log`)
```
     at: _instance_reset_physics_interpolation_bind_compat_104269 (servers/rendering/rendering_server.compat.inc:62)
     GDScript backtrace (most recent call first):
         [0] _ready (res://scripts/world/water_world.gd:63)
         [1] _build_world (res://tests/smoke_tidewake_b_chain_route.gd:124)
         [2] _run (res://tests/smoke_tidewake_b_chain_route.gd:105)
POSE veilfall arrival landing for water_halen -> (384.311, 1.929, 3805.405)
WALK water_halen DIRECT (no baked-ground plan from (384.311, 1.931604, 3805.405) to (191.0, 616.1026, 4163.0))
FAIL: water_halen: walk stalled at leg 1/1 player=(357.3599, 105.9417, 4096.896) goal=(191.0, 0.0, 4163.0)
FAIL: Lastlight: Halen gives the lead ()
FAIL: Lastlight: lead recorded
FAIL: lastlight_shelter_supply visible and offered after the lead
WALK lastlight_shelter_supply island=veilfall walked=274m legs=46
FAIL: lastlight_shelter_supply prompt offered (winner=)
FAIL: Lastlight: delivery recorded by walk + Interact
FAIL: Lastlight: host debited 4 + 4
FAIL: Lastlight: delivery message: 
FAIL: Lastlight: shelter piece stands
WALK water_halen DIRECT (no baked-ground plan from (374.1692, 5.997751, 3822.694) to (191.0, 616.1026, 4163.0))
```## Findings at the deadline (21:00 UTC)
- **PASS, walked end to end with save/reload:** lantern (54 checks, 0 failures), gull (59/0), and garden (59/0).
- **deep (finished after the deadline note):** PASS, 61 checks, 0 failures; Candy III +1; Orsen acknowledges `water_orsen_deep_watch_charted` before and after reload.
- **cradle, real failure:** Otto's authored standing point is (700.0, 56.9, 1542.0). The baked-ground planner found no dry route from the Tidal Cradle arrival landing, so the witness fell back to a direct stick leg. That leg stalled at (704.3, 45.5, 1539.2), about 5 m away horizontally but 11 m lower. The trainer never reached Otto's Greet prompt, so the lead was never given. Otto may stand on a ledge that ground movement cannot reach, or this navigator/planner may just fail to find the way up. That is not yet decided.
- **lastlight, real failure:** Halen's resident body is at (191.0, **616.1**, 4163.0), 616 m above the Veilfall landing. The walk stalled at (357.4, 105.9, 4096.9), so the lead was never given and every later step failed. This looks like a Halen placement defect rather than a navigation limit: something to do with the ground or the body at that point puts him far above any walkable ground. It needs checking before the chain can be witnessed.
- These two failures come from walked approaches only. The per-chain smokes (teleport poses) still pass in CI. This witness shows that **the requesters Otto and Halen cannot currently be reached on foot from their island's arrival landing** with this navigator.

## Final results (logs completed after the first push)

| Chain | Final | Source |
|---|---|---|
| lantern_return | PASS, 54 checks / 0 failures | lantern.log |
| gull_research | PASS, 59 / 0 | gull.log |
| garden_records | PASS, 59 / 0 | garden.log |
| deep_watch_chart | **PASS, 61 / 0** (Tidecoil resolved by the director's won handler, as disclosed) | deep.log (now complete) |
| cradle_care | **FAIL**: Tracker Otto at (700, 56.9, 1542) is not reachable on foot. The walk stalls about 4–5 m away and 11 m lower, both from the arrival and after the nest. Mining the nest works (+4 Reef Stone), but the lead, return, berries and acknowledgement all fail. | cradle.log (now complete) |
| lastlight_shelter | **FAIL**: Campkeeper Halen resolves to (191, 616.1, 4163) on top of the Veilfall massif (`water_characters.json` `island_local_offset [-9,0,23]`), far from the Lastlight camp at about (381, 5, 3822). The walk stalls at y≈106. | lastlight.log (the rerun was stopped by the lane lead; the first failures are unchanged) |

F13#3 is **not met**: 4 of 6 chains pass the walked witness. The two failures are NPC placement defects in `data/config/water_characters.json`, owned by the main Tidewake lane. A SHARED-FILE REQUEST is on PR #310. The existing CI chain smokes teleport onto the NPC body (e.g. `tests/smoke_water_lastlight_shelter.gd:68`), which hides this.

## Rerun with the main Tidewake lane's NPC move (21:46–21:51 UTC)

The main Tidewake lane moved `water_otto` to `island_local_offset [-145, 0, -168]` and `water_halen` to `[175.2, 0, -322.1]` in `data/config/water_characters.json`. That change is on `tb/tidewake-top-trainer-damage` and `tb/integration-31` (`040c039594dd5d9055ab2f874d3436630187a4e0`); it is not on main yet. For this rerun that single file was taken from `tb/integration-31` into the working tree, **uncommitted**, and restored afterwards. This PR still changes no data. The test code is unchanged (`164c4f68`).

| Chain | Result | Log |
|---|---|---|
| cradle_care | **PASS, 55 checks / 0 failures**: walked to Otto (lead), the nest's Reef Stone +4, walked back, return pays berries +3, ack `water_otto_nest_thanks`, and completion survives reload | cradle_npc_moved.log |
| lastlight_shelter | **PASS, 60 / 0**: walked to Halen beside the camp, lead, delivery 4+4, shelter built, rest, ack `water_halen_shelter_thanks`, and completion survives reload | lastlight_npc_moved.log |

With the four earlier passes, **all six chains pass the walked witness** once the NPC move is on main. F13#3 becomes met when this evidence lands together with or after that move (integration-31). Until then, on current main, Cradle and Lastlight still fail as recorded above.

Review note: Lastlight's 4 driftwood + 4 reed fiber and the bed `assign_creature(0)` rest step are fixtures, not gathered or driven through the bed UI. They are disclosed above, and they weaken the normal-play claim for that one chain's delivery and rest step. The walks to Halen, the delivery prompt, the build, the acknowledgement and the reload are real.
