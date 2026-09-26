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
| side_water_gull_research | Adair lead -> Gull Rest satchel site -> Candy II -> Adair return -> thanks | NOT FINISHED | no CHAIN line; no reload line; checks=? failures=? exit=not finished |
| side_water_cradle_care | Otto lead -> shell-nest Reef Stone seam (hotbar pickaxe) -> Otto return, 3 berries -> thanks | NOT FINISHED | no CHAIN line; no reload line; checks=? failures=? exit=not finished |
| side_water_garden_records | Edda lead -> Drowned Garden vault wall -> Candy II -> Edda return (pre-Tether history) -> post line | NOT FINISHED | no CHAIN line; no reload line; checks=? failures=? exit=not finished |
| side_water_deep_watch_chart | Orsen names Deep Watch -> Tidecoil resolved (fixture) -> Orsen chart lead -> Candy III cache -> chart control -> Orsen charted | NOT FINISHED | no CHAIN line; no reload line; checks=? failures=? exit=not finished |
| side_water_lastlight_shelter | Halen lead -> Veilfall delivery (4+4) -> Halen rest request -> bed rest -> thanks | NOT FINISHED | no CHAIN line; no reload line; checks=? failures=? exit=not finished |

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
```

### deep (`deep.log`)
```
     at: _instance_reset_physics_interpolation_bind_compat_104269 (servers/rendering/rendering_server.compat.inc:62)
     GDScript backtrace (most recent call first):
         [0] _ready (res://scripts/world/water_world.gd:63)
         [1] _build_world (res://tests/smoke_tidewake_b_chain_route.gd:124)
         [2] _run (res://tests/smoke_tidewake_b_chain_route.gd:105)
POSE sluice_isle arrival landing for water_orsen -> (650.68, 1.929, 2774.917)
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
```