# MP-1B-STATE-SEAM — report

**Lane:** 1.B World/Player split + facade (Opus), with Wave 1 lane 1.A folded in ·
**Branch:** `lane-1b-state-seam` in worktree `/home/user/tb-lane-1b` ·
**Base sha:** `6b71c024` ("Lane 0.F report; contract section 7 carries the satiety and
world_seed amendments"), the tip of `claude/tetherbound-roadmap-next-jrcjs8` ·
**Brief:** `docs/specs/STAGE_B_MULTIPLAYER_EXECUTION_PLAN.md` Wave 1 rows 1.A and 1.B ·
**Contract:** `docs/specs/MP_STATE_SEAM.md`, D98 / D99 / D100 ·
**Nothing pushed.** Six commits in the worktree, listed per item below.

## Two process notes the orchestrator should read first

1. **The lane was handed a stale base and then lost its worktree.** The assigned worktree
   (`.claude/worktrees/agent-ad4e87228c315578a`) was based on `55c64aaa`, ten commits behind
   the required `cb1eaf7c`; none of the Stage B contract documents existed in it. On the
   coordinator's instruction it was reset to `cb1eaf7c` — and partway through the contract
   read, the harness **deleted that worktree and its branch** while lane 0.F was landing, and
   the shell fell back to the shared main checkout. No edits had been made, so nothing was
   lost. The lane re-established isolation itself: `git worktree add /home/user/tb-lane-1b -b
   lane-1b-state-seam 6b71c024`, taking the branch tip rather than `cb1eaf7c` so 0.F's Cloudreach
   build fix and the §7 satiety/world_seed amendments were in the base. **A leftover worktree
   `/home/user/tb-base-check` (detached at `6b71c024`) exists for the ERROR-set baseline; remove
   it with `git worktree remove /home/user/tb-base-check` when convenient.**
2. **`scripts/save/save_game.gd` is untouched** — verified by `git diff --stat`. So are
   `project.godot`, `.github/`, `party.gd`, `inventory.gd`, `creature_instance.gd`,
   `item_db.gd`, `player_equipment.gd` and `quest_log.gd`.

## One line per item

| Item | Verdict |
|---|---|
| A `flag_scopes.json` + `objectives.json` scopes | **done** — 110 world ids / 17 player ids / 6+6 prefixes; every id in every shipped data file, every writer-site literal and every generated id resolves. 33 objective entries carry `scope`. |
| B `WorldState`, `PlayerState`, `MergedProgression`, `scope_of` | **done** — with ONE recorded deviation from seam §2 (the merged view must provide save/load; reason below). |
| C `Game` facade | **done** — `world` / `local` / `players`; every inventory §1 field is a forwarding property, readable AND writable; `find_player()` promoted to `local_player()` with the alias kept; the four tree-sync seams write into `world`; `_process` ticking unchanged; `save_game()`/`load_game()` produce and consume exactly today's v22 dictionary through an unchanged `save_game.gd`; `register_death_satchel` gained `owner` and `realm` with today's defaults. |
| D De-static feed + map extent | **done** — feed log is instance state on `PlayerState.feed`; map extent is instance fields set by `configure()`/`set_extent()`; Cloudreach's six overrides collapsed; alpha pins moved inside `MapState.save_data()` while `Game.save_game()` still emits the v22 top-level key. |
| E Explicit-store writer sites | **done** — all four, through three new named accessors on `Game`. |
| F New tests, each seen red first | **done** — 4 files, 61 tests, 464 assertions; five break/fail/revert triples; two deliberate expected-value changes in `test_characterize_map_state.gd` and two necessary call-site changes in `test_progression_feed.gd`. |
| G Proof | see the Proof section below. |

## Commits

| sha | item | what |
|---|---|---|
| `0161b960` | A | the flag scope table, `objectives.json` scopes, `progression_state.scope_of()` |
| `21e65c99` | B, C | `WorldState`, `PlayerState`, `MergedProgression`, `Game` as a forwarding facade |
| `dea785df` | D | de-static the progression feed and the map extent; alpha pins into the map |
| `695eac69` | E | the four writer sites that name a flag store explicitly |
| `ca8b8eae` | F | four new tests, each seen red first |
| `1bc8066a` | C | `test_title_new_game` asks `PlayerState` for its pristine map |

## The one deviation from `MP_STATE_SEAM.md`

**§2 says `MergedProgression` must NOT provide `save_data()`/`load_data()`, and that a call
should be a `push_error` so a missed save site is loud. It provides both.**

That design is right once 1.C has landed. Until then it cannot be: `scripts/save/save_game.gd`
— which this lane may not touch, and which must keep writing exactly today's v22 dictionary —
persists the flag store through `game.get("progression").call("save_data")` and restores it
through `.call("load_data", …)`. A `push_error` there would not find a missed site; it would
stop every save in the game from recording a single flag, and every load from restoring one.

So the merged view does the split one seam earlier than planned, and says so in its own header:
`save_data()` returns the UNION in `progression_state.gd`'s exact `{"flags": [...]}` shape, which
is byte-identical to what the flat store wrote, and `load_data()` SPLITS the saved list back into
the two stores by scope, replacing both wholesale. `test_merged_progression.gd` pins both
directions and the round trip. 1.C deletes them when it writes world.json and character.json from
`world.save_data()` / `local.save_data()`.

The same constraint is why `Game.save_game()` still routes through `save_game.gd`'s own assembly
rather than composing the dictionary from `world.save_data()` + `local.save_data()`: `save(game,
slot)` reads the properties off the game object itself, and the forwarding properties make it
produce a byte-identical file. `WorldState.save_data()` and `PlayerState.save_data()` exist,
carry the §4 partition, and are round-trip tested — they are the shape 1.C replaces the path
with, and the world half is what `MP_NET_HARNESS_CONTRACT.md` §7 says the desync hash uses from
Wave 1 on.

## Where a forwarding property was bypassed for an explicit store, and why

| Site | Bypass | Why |
|---|---|---|
| `night_rest.gd:77` (`player_slept_at_home`) | `Game.player_flags()` | The actor is "whoever bedded down". From Wave 5 this runs host-side over every peer in a bed (D105, sleep is a vote); routing one write by scope would credit the host's rest to the host alone. Solo it is one store and byte-for-byte today's behaviour. |
| `home_progress.gd` ×3 (`home_built`, `creature_bed_built*`, `home_materials_gathered`) | `Game.grant_player_flag()` | D-MP5/D99: player flags GRANTED TO EVERY CONNECTED PEER when the world gains the pieces. A shared camp is everyone's camp; a friend who walked in after the hut went up must not be sent to build a second one. Solo, one write to the local store. |
| `stronghold_climax.gd:922, :941` (`legendary_joined`) | `Game.player_flags()` via a new `_set_player_flag()` | The party owner's fact. `legendary_freed` stays the world's — the machine is dead for everyone — but which belt the freed creature landed on is one trainer's. |
| `realm_heart_state.gd::place()` | the merged view's `world_flags` | Placing a Heart is a world fact written to the world store BY NAME, so a client cannot record it locally from Wave 3. Duck-typed: a caller that hands over one flat store (every test in `test_realm_heart_state.gd`) has no `world_flags` field and gets exactly the store it passed. |
| `Game.push_progression_event` / `progression_feed_revision` / `peek_progression_events` / `take_progression_events` / `load_game` / `PlayerState.reset` | `local.feed.<instance method>` | These already know WHICH feed they mean, so they call `push_event`/`event_revision`/`events_since`/`drain_events`/`clear_events` directly instead of going through the static `active()` locator. |
| `Game.register_building` / `register_death_satchel` | pass `current_realm` down as an argument | `WorldState` deliberately holds no `current_realm`: two peers stand in two realms from Wave 6, and a record stamped with "whichever realm the local player is in" would file a Cloudreach fence in the Meadows. `Game`'s own signatures are unchanged, so no caller moved. |

Three named accessors were added to `Game` for the first four rows, so Waves 3 and 5 change the
bodies in one file instead of hunting the call sites again: `world_flags()`,
`player_flags(peer_id := 0)` and `grant_player_flag(id, value := true)`.

## Every flag id classified beyond the seam table — for Fable to ratify

`MP_STATE_SEAM.md` §3's table names some ids outright and others by rule ("every trainer
`defeat_flag` and `TRAINERS.reward_flags()` id", "every `item_gate.gd` `flag_id`", "Cloudreach
`physical_state_flags` and captain defeat flags", …). Everything below is what the sweep found
that neither an explicit name nor a stated rule covers. Each was classified by the seam's own
rule: **world** = something happened to the world once; **player** = a tutorial beat, personal
readiness, or a personal payoff.

### World — 57 ids

**Meadows / village (11).** `captive_rescued`, `meadows_acknowledged`,
`learned_legendary_is_the_source`, `band1_meadowhart_herd_met`, `lost_creature_rue_met`,
`night_watch_farro_met`, `old_champion_met`, `mira_shop_open`, `oskar_trade_open`,
`bram_shop_open`, `recipe_orb_basic`.

* The four `*_met` flags follow the seam's own ruling on `river_nest_clear.gd`/`cart_repair.gd`'s
  `MET_FLAG`, which it puts in world: an NPC has been met, in this world, once.
* The three `*_shop_open` flags are a facility standing open in the village, not a thing one
  trainer knows.
* `recipe_orb_basic` is **world for consistency with `recipe_saddle`**, which the seam already
  makes world by the reward-flag rule. The line drawn: a flag that records KNOWLEDGE (a recipe)
  is the world's; a flag that records RECEIVING ITEMS (`tam_tools_given`, `camp_hammer_given`) is
  the player's, because each trainer needs their own axe. **Worth an explicit ratification** —
  the alternative (both recipes player-scoped) is defensible and would mean a friend must talk to
  Mira themselves.
* `learned_legendary_is_the_source` and `cloudreach_crisis_learned` /
  `storm_anchor_engine_truth_learned` are all "learned" reveals that GATE chapter progress. They
  are world by D99's own failure test: default-player leaves a gate closed for the friend who did
  not open it. **Also worth ratifying** — the opposite reading (a reveal is personal knowledge) is
  the one the rule's "tutorial" half would suggest.
* `meadows_acknowledged` is the final main-chapter beat: the world responded, and the chapter is
  over for the world.

**Cloudreach (46).** `causeway_survivors_reconnected`, `cloudreach_act_i_complete`,
`cloudreach_act_ii_complete`, `cloudreach_chapter_complete`, `cloudreach_chapter_started`,
`cloudreach_crisis_learned`, `cloudreach_lower_anchors_investigated`,
`cloudreach_summit_relay_{crown,east,west}_disabled`, `cloudreach_upper_anchors_disabled`,
`cloudreach_upper_route_unlocked`, `cloudreach_winds_restored`,
`completed_cloudreach_maela_trial_battle`, `defeated_cloudreach_{ila,orrin,senn,tavi,voss}`,
`defeated_cloudreach_tavi_rematch`, `fly_traversal_unlocked`, `realm_heart_cloudreach_earned`,
`realm_key_water`, `sky_shrine_reached`, `summit_extraction_engine_reached`,
`waterward_route_revealed`, `windscar_aerie_prepared`, the seven `storm_anchor_*`, and the eleven
`side_*`.

Every one of these is a thing that happened to Cloudreach once — a relay went dark, a vane was
aligned, a bell was rung, a courier's pack was recovered, an act closed. `fly_traversal_unlocked`
is world because the winds being restored is what makes flight possible, not one trainer's
licence. The `side_*` set is the only place a case could be made for player scope (a side quest
one person did), and it was refused for the same reason as the reveals: half of them gate a
`side_*_complete` roll-up that another peer would then never see close.

### Player — 5 ids

`camp_hammer_given` (a gift, exactly like the seam's own `tam_tools_given`),
`band1_meadowhart_herd_found` (a one-time `give:` gift dialogue — note its partner
`band1_meadowhart_herd_met` is world, which is the same met/received split as Tam),
`tournament_quarter_at_ring`, `tournament_semi_at_ring`, `tournament_final_at_ring` (personal
staging, the family of the seam's own `tournament_entered`; the `*_won` partners are trainer
defeat flags and stay world).

### Prefixes beyond the table — 4

| prefix | scope | why |
|---|---|---|
| `warrens_once_` | world | `burrow_warrens.gd::_once_flag_for_nickname()`. A named Warrens resident beaten, caught or freed once — the same shape as the seam's `wild_once_`. |
| `opening:` | player | Covers `opening:mira_visited` and `opening:tournament_registered`, which the seam's `opening:beat:` does not reach. Both are opening-tutorial facts. `opening:beat:` is kept alongside it, redundantly, because the seam names it — longest-prefix resolution keeps them separable if either is ever re-scoped. |
| `creature_bed_built_` | player | The concrete form of the seam's `creature_bed_built_<n>`; the exact id `creature_bed_built` is declared separately so exact-beats-prefix is exercised. |
| `oskar_swap_taken_` | player | The concrete form of the seam's "`swap_panel.gd`'s `CREATURE_TRADE.swap_flag`". `swap_flag()` builds `<trader>_swap_taken_<period>`, which is a SUFFIX pattern, and the table only matches prefixes — so it is declared per trader id. `trade.json` names exactly one creature trader today, and `test_flag_scopes.gd` enumerates every trader in that file, so a second one fails the test until it is classified. That is D99 working as designed, but it is a maintenance edge worth knowing about. |

## Behaviours found surprising

1. **`save_game.gd` persists flags through the merged view.** The seam assumed the split store
   would be saved by 1.C's two savers; today the one path runs through
   `game.get("progression").call("save_data")`. This is the reason for the single deviation above.
2. **`bind_realm_map()` used to silently discard a caller-injected `Game.map`.**
   `smoke_alpha_pins.gd` "throws the map away entirely" with `_game.set("map", MAP_STATE.new())`,
   but the old `bind_realm_map()` reassigned `Game.map` from `_realm_map_instances` on every load,
   so the injected map was dropped and the assertions ran against the original. With the maps
   living on `PlayerState` and `Game.map`'s setter writing into `local.maps[local.realm]`, the
   injection now actually sticks — the smoke tests what its comment says it tests.
3. **`WorldState.load_data` inherited a real fragility from the shape it was copied from.**
   `int(data.get("world_seed", 0))` on a non-number is not a coercion in GDScript; `int([])` is a
   "Nonexistent 'int' constructor" error that ABORTS the function halfway and leaves a
   half-restored world. Found by `test_world_state.gd`'s garbage-input case and fixed with a
   type-checking `_int()`. `save_game.gd` has the same shape at its own `world_seed`/`day` reads;
   **flagged for 1.C**, not touched here.
4. **`cloudreach_map_state.gd::load_data` never cleared or restored `_alpha_pins` at all** — a
   full override that skipped `super`. Now symmetric with the base class.
5. **`progression_feed.gd::drain()` bumps `_revision`, not `_epoch`** — lane 0.E's finding,
   carried over unchanged as seam §6 requires, and re-pinned by the characterization fence.
6. **`test_title_new_game.gd` reached into a private `Game._map_landmarks_config()`** to build a
   pristine comparison map. It now asks a fresh `PlayerState` for one.
7. **The unit suite now emits `push_error` lines for 17 test-invented flag ids** (`"a"`, `"b"`,
   `"bridge_unlocked"`, `"warden_defeated"`, `"never_set"`, …) that no shipped writer produces.
   These are the unscoped-write path working as designed — the tests still pass, because an
   unscoped write lands in the world store — but they are new noise in the unit log. None of them
   is a real game flag; `warden_defeated` in particular is a KEY in
   `stronghold_climax.json`'s `flags` map, not a flag id (its value is `defeated_warden`).
8. **`merged_progression.revision` deliberately excludes `WorldState.revision`.** Seam §1 says the
   merged view "sums" the world's revision and §2 says it is `world.flags.revision +
   local.flags.revision`. §2 was implemented: `game_state.gd::_process` polls that number to decide
   whether the objective line moved, and placing a fence is not a reason to recompute the quest
   log. `WorldState.revision` still exists and still bumps on every world-record mutation, for
   Wave 3's delta detection.

## Item detail

### A — the scope table (`0161b960`)

`data/progression/flag_scopes.json` in seam §3's shape. 110 world ids, 17 player ids, 6 world
prefixes (`cache:`, `pickup:`, `tm:`, `harvest_node:`, `wild_once_`, `warrens_once_`), 6 player
prefixes (`opening:`, `opening:beat:`, `cloudreach_payout:`, `saddle_fitted_`,
`creature_bed_built_`, `oskar_swap_taken_`). All 33 entries in `objectives.json` (27 main + 6
local) gained a `scope` matching the table.

`progression_state.gd` gained `static func scope_of(id) -> String`: exact id first, then the
LONGEST matching prefix (so `opening:beat:` resolves ahead of `opening:`), else `""`. The parsed
table is cached in a `static var`, which is the config exemption the seam grants — it is
immutable data, identical for every player in the process, not per-player state.

### B — the containers (`21e65c99`)

`autoload/world_state.gd`, `autoload/player_state.gd`, `autoload/merged_progression.gd`. All three
are composed `RefCounted`s in `autoload/` beside `party.gd`/`inventory.gd`; **no second Godot
autoload was added** — `project.godot` is untouched. Methods moved verbatim where the seam says
so; the two that could not move verbatim are `register_building()` and `register_death_satchel()`,
which take the realm as an argument instead of reading `current_realm` (see the bypass table).

### C — the facade (`21e65c99`, `1bc8066a`)

Every field in assumption-inventory §1 is a forwarding property with its old name and type, and
every one has a SETTER as well as a getter — that mattered more than expected:
`save_game.gd::_array_to_hotbar` does `game.set("hotbar", …)`, and four unit tests assign
`state.progression`, `game.party`, `game.inventory`, `game.realm_hearts` or `game.map` outright.
`Game.progression`'s setter takes a caller handing over ONE flat store and makes both halves that
object, so the pre-split behaviour comes back exactly for those callers.

**Containers are built in `_init()`, not `_ready()`.** `test_recipes.gd` and others instantiate
`GAME_STATE.new()` directly and never add it to a tree, so `_ready()` never runs; a facade whose
backing objects appeared only on `_ready()` would hand them null for every field.

`reset_for_new_game()` resets both containers IN PLACE (`world.reset()` / `local.reset()`) rather
than replacing them. Two reasons, both load-bearing: `merged_progression` holds references to the
two flag stores, and `progression_feed`'s epoch must keep CLIMBING across a New Game or a
presenter that cached epoch 3 reads a fresh feed's epoch 0 as "no reset happened".

`find_player()` → `local_player()` with `find_player()` kept as the alias (D-MP7). The four
tree-sync seams (`_sync_placed_building_state`, `_sync_death_satchel_state`, `_sync_harvest_state`,
`_sync_clock_state`) are unchanged in body and now write into `world` through the forwarding
properties. `_process` ticking is unchanged.

Nine now-dead preloads and two dead helpers (`_species`, `_map_landmarks_config`) were removed
from `game_state.gd`; none had an external reference (checked for `Game.<CONST>` across the repo).

### D — de-static (`dea785df`)

**`progression_feed.gd`:** `_events`, `_seq`, `_revision`, `_epoch` are instance fields on
`PlayerState.feed`. `_config` stays static (config only, the seam's exemption). The static entry
points STAY and resolve `active()` — the local player's feed, or a process-local fallback when
there is no `Game` and no `SceneTree` at all. That is a departure from the letter of seam §2
("the static methods become instance methods") and a deliberate one: the producers are `RefCounted`
creatures with no tree to reach `Game` through, `Engine.get_main_loop()` is null for the life of
`run_tests.gd`, and lane 0.E's characterization fence calls all eight statics. Making them
instance methods would have broken ~24 call sites and the fence this lane must keep green. The
substantive hazard — shared log state between two players — is gone; only the locator is static.

**`map_state.gd`:** `_grid_x`/`_grid_z`/`_origin` are instance fields, plus a new `_cell`. They
are set either lazily from `world_extent.gd` (unchanged for every caller that never heard of the
new API) or outright by `set_extent()`. `cloudreach_map_state.gd`'s six overrides
(`cell_grid_x`, `cell_grid_z`, `cell_size`, `world_to_cell`, `cell_at`, `is_discovered`) and its
shadowing `_cell` collapse onto one `set_extent()` call; its `save_data()` override is down to the
realm tag. `tab_map.gd::bounds_for_map()` reads the map it was handed instead of one global answer.

**Alpha pins** moved into `MapState.save_data()` under `alpha_pins`, with `alpha_pin_save_data()`
kept as the accessor. `Game.save_game()` still emits the v22 top-level `alpha_pins` key, read back
off the active map by an unchanged `save_game.gd`.

### E — explicit stores (`695eac69`)

See the bypass table above. Three new accessors on `Game`: `world_flags()`,
`player_flags(peer_id := 0)`, `grant_player_flag(id, value := true)`.

### F — new tests (`ca8b8eae`)

| file | tests | assertions |
|---|---:|---:|
| `tests/test_flag_scopes.gd` | 11 | 235 |
| `tests/test_merged_progression.gd` | 17 | 51 |
| `tests/test_world_state.gd` | 15 | 81 |
| `tests/test_player_state.gd` | 18 | 97 |
| **total** | **61** | **464** |

`test_flag_scopes.gd` sweeps SOURCES rather than a copied list: every `.json` under `res://data`
(objectives, the six trainer tables, realm_hearts, the Cloudreach chapter/world/runtime data, the
relay, the Warrens, meadow healing, and every `flag:` dialogue effect), plus a fixture list of the
writer-site literals from inventory §8/§8b that live in `.gd` constants, plus ids built by their
own helpers (`riding_controller.saddle_fitted_flag`, `creature_trade.swap_flag` for every trader
in `trade.json`). A new trainer, objective or dialogue flag therefore fails the test until someone
classifies it.

#### The red/green triples

Every new test was broken deliberately and seen red for its own reason before being reverted.
`git diff` on every production file was empty afterwards, and the reverted tree was re-run green.

| # | break | red | revert |
|---|---|---|---|
| 1 | removed `"defeated_warden"` from `flag_scopes.json` | `test_every_flag_id_in_shipped_data_resolves_to_world_or_player` — *"undeclared flag ids … defeated_warden (from trainers.json)"*; and `test_every_objective_entry_carries_a_scope_matching_the_table` — *"objective 'defeat_the_warden' declares scope 'world' but the table says ''"* | restored, 11/235 green |
| 2 | removed the `"cache:"` prefix | `test_every_prefixed_id_resolves_through_its_prefix` — *"'cache:castle_gate_key' matches no prefix"* and the realm-qualified form too | restored, green |
| 3 | made `merged_progression.store_for()` never return the player store | the three routing tests — *"a personal payoff must not become everyone's"*, plus `test_store_for_names_the_store_without_writing_to_it` | restored, 17/51 green |
| 4 | dropped `"owner"` from `WorldState.register_death_satchel`'s record | both owner tests and the round trip — *"expected character-7, got "* | restored, 15/81 green |
| 5 | removed `cloudreach_map_state`'s `set_extent()` call | `test_the_two_realm_maps_describe_two_differently_shaped_worlds` — *"expected anything but (-1024.0, -512.0)"* | restored, 18/97 green |

A sixth, non-triple observation: removing the redundant `opening:beat:` prefix did NOT go red,
because `opening:` still covers it. That is correct behaviour and it is why
`test_the_longest_matching_prefix_wins` pins the resolution ORDER rather than either value.

#### Existing tests changed, and why none of them is a weakening

| file | change |
|---|---|
| `tests/test_characterize_map_state.gd` | **Deliberate expected-value change #1**, the one the brief names. `test_the_static_extent_is_the_same_object_across_two_instances` → `test_two_instances_can_now_hold_two_different_extents`, with lane 0.E's own prediction quoted in the comment. Two UNCONFIGURED maps still agree (both derive the same default), and a map told a different extent no longer drags the other with it — the second half is the evidence the hazard is gone, and it is exactly what the old assertion forbade. |
| `tests/test_characterize_map_state.gd` | **Deliberate expected-value change #2**, not named in the brief but required by item D: `test_save_data_has_exactly_these_nine_keys` → `…ten_keys`, because the alpha-pin set moved inside the map's payload. Commented in place. |
| `tests/test_progression_feed.gd` | Two Game-wrapper tests asserted `FEED.<static>()` against a DETACHED `GAME.new()`'s wrappers, with the message *"Game reads the same static log"* — the exact process-global property this lane removes. They now assert against that Game's own `local.feed`, which is the same claim after the split and a more specific one. The second also now pins that `reset()` KEEPS the feed object so a presenter cursor still resolves. |
| `tests/test_map_state.gd` | One line: `MAP_STATE.grid_x()` → `map.grid_x()`. Same numbers, same map; the static accessor no longer exists. |
| `tests/test_title_new_game.gd` | Built its pristine comparison map through the private `game._map_landmarks_config()`; now asks a fresh `PlayerState` for one. |

## G — Proof

All commands run with `~/godot-bin/godot --headless`, from the worktree, each with its own
private `XDG_DATA_HOME`. Smokes were run **sequentially**, never in parallel.

### Full unit suite

```
godot --headless --path . --script tests/run_tests.gd
  → 2441 tests, 3781499 assertions, 0 failed   (exit 0, 1874 s = 31.2 min)
```

31.2 min sits inside the fence's stated 28–39 min band. **The 62 characterization tests are all
present and green** — the exact count lane 0.E's report gives for `--only=characterize` (62 tests
/ 209 assertions), unchanged by this lane even though two of their expected values moved. 61 of
the 2441 are this lane's four new files, so the pre-lane suite was 2380.

### Smokes

Two full sequences were run. **Sequence 1** was stopped after 11 smokes when
`smoke_progression_feedback` failed, so its failure could be diagnosed before the rest of the
tree moved under it. **Sequence 2** is the one that counts: it ran the whole list on the tree at
`6732fac0`, and every line below is that smoke's FIRST attempt on that tree.

| smoke | exit | secs | `^ERROR:` lines |
|---|---:|---:|---:|
| `smoke_playground` | 0 | 104 | 2 |
| `smoke_opening` | 0 | 168 | 0 |
| `smoke_title_new_game` | 0 | 37 | 1 |
| `smoke_title_load_game` | 0 | 203 | 0 |
| `smoke_save_persistence` | 0 | 175 | 0 |
| `smoke_finale_persistence` | 0 | 462 | 8 |
| `smoke_clock_survives_a_reload` | 0 | 253 | 0 |
| `smoke_home_sleep` | 0 | 93 | 1 |
| **`smoke_progression_feedback`** | **1** | 150 | 0 |
| `smoke_alpha_pins` | 0 | 13 | 0 |
| `smoke_gate_a_map_cycle` | 0 | 132 | 0 |
| `smoke_menu` | 0 | 129 | 0 |
| `smoke_combat` | 0 | 115 | 0 |
| `smoke_catching` | 0 | 176 | 0 |
| `smoke_cloudreach_transition` | 0 | 172 | 0 |
| `smoke_cloudreach_arrival_walk` | 0 | 83 | 0 |
| `smoke_cloudreach_persistence_tail` | 0 | 5 | 0 |
| `smoke_gate_b_continuous` (CORE, no flag) | 0 | 220 | 0 |

**17 of 18 exit 0 on the first attempt. No smoke was retried into green.**

Every `^ERROR:` line above is one of two pre-existing engine notices — `Parameter "material" is
null.` and `N resources still in use at exit.` — and no line anywhere is a seam error. Sequence 1
produced one extra: `smoke_title_new_game` emitted `unscoped flag: warden_defeated`, which was a
finding rather than noise (see below) and is gone in sequence 2.

### `smoke_progression_feedback` — the one red, and why it is not this lane's

```
FAIL: the party strip ticked 0 time(s) for the win; expected the xp tick and the bond tick
Progression feedback: 1 failure(s)
```

Attribution, in the order it was established:

1. **Three attempts on this branch**, all with byte-identical output — not a flake.
2. A first hypothesis (the feed's static entry points resolving to two different objects) was
   implemented and the smoke re-run: **still red**. The fix was kept anyway, because the defect it
   removes is real — see `6732fac0` — but it is not this failure.
3. **The same smoke was run on the untouched base commit `6b71c024`**, in its own worktree
   (`/home/user/tb-base-check`, imported clean): `BASE EXIT=1`, same single failure, same message.

So `smoke_progression_feedback` is **already red on the Wave 0 branch this lane cut from**. It is
in **no CI shard** (`grep progression_feedback .github/workflows/ci.yml` → nothing), which is why
it stayed red unnoticed. This lane did not weaken it, did not touch it, and does not fix it.

**Handing it back:** the failure is a race in `party_strip.gd::_poll_feed()` that predates this
lane. It advances its cursor (`_feed_seq = newest`) BEFORE the
`if not progression_feedback_enabled: return` guard, so every event pushed while `combat_hud.gd`
has the strip disabled (`:269`) is consumed and dropped rather than deferred. The win's `xp_gained`
and `bond_credit` land in exactly that window — the smoke's own log confirms both reached the feed
— and the strip never flicks for them, while the meal / discovery / rest ticks later in the same
smoke all pass. Fixing it means deferring rather than dropping while disabled, which is a
behaviour change to a presenter and belongs to whoever owns that file, not to a state-seam lane.

### `smoke_playground`'s `^ERROR:` set vs the base commit

`smoke_playground` exits 0 on both trees, and the only content-bearing `^ERROR:` line on either is
the pre-existing `Parameter "material" is null.` A second line, `N resources still in use at
exit`, is an intermittent engine teardown notice — seen 2 of 5 lane runs and 0 of 3 base runs, and
on the LANE tree it appeared in one sequence and not the next. Not chased, on the coordinator's
instruction: it is printed after the game has already run and exited, it cannot affect a player,
and the same notice appears in other smokes on both trees. **No deterministic growth in the ERROR
set.**

### Two fixture defects the scope table exposed

Both are strengthenings, and both are recorded because a reviewer will otherwise read them as
scope creep:

1. `smoke_title_new_game.gd` seeded `game.progression.set_flag("warden_defeated")` and then
   asserted New Game had cleared it. **`warden_defeated` is not a flag id this game ever writes** —
   it is the KEY under it in `stronghold_climax.json`'s `flags` map, whose VALUE is
   `defeated_warden`. The old spelling seeded a string nothing in the game reads, so the assertion
   could not have caught a New Game that really did carry the Warden victory across. D99 made it
   visible (an undeclared id is a `push_error`) and the fixture now uses the real id. Still green.
2. `test_title_new_game.gd` built its pristine comparison map through the private
   `Game._map_landmarks_config()`; it now asks a fresh `PlayerState`.

## What this lane did NOT do

* `scripts/save/save_game.gd` is **byte-for-byte unchanged**. So are `project.godot`,
  `.github/`, `party.gd`, `inventory.gd`, `creature_instance.gd`, `item_db.gd`,
  `player_equipment.gd` and `quest_log.gd`'s public surface. Verified by `git diff --stat`
  against the base.
* **No second autoload.** `WorldState`, `PlayerState` and `MergedProgression` are composed
  `RefCounted`s in `autoload/`, the same shape as `party.gd` and `inventory.gd`.
* **No player-facing behaviour changed in solo**, with one deliberate exception recorded above:
  `smoke_title_new_game`'s fixture now seeds the real Warden flag, which makes an assertion mean
  what it always claimed to.
* **Nothing seam §6 pins was "fixed":** `progression_feed::drain()` still bumps `_revision` and
  not `_epoch`; `inventory::drain()` still returns a compacted array; `SceneTree.paused` is still
  untestable from a unit test.
* `docs/CURRENT_STATE.md` and `docs/TECHNICAL_ARCHITECTURE.md` were **not** updated — Wave 1 row
  1.D owns the ledger.

## For the orchestrator

1. **`smoke_progression_feedback` is red on `6b71c024`** and is in no CI shard. It needs an owner;
   the diagnosis is in the Proof section. Wave 1's exit criterion should not be blocked on this
   lane for it.
2. **`save_game.gd` has the same `int(<whatever arrived>)` fragility** at its `day` / `world_seed`
   reads that `WorldState.load_data` had — `int([])` aborts a load halfway. Worth handing to 1.C
   with the save split.
3. **Twelve residual flag classifications want ratifying** — chiefly `recipe_orb_basic` (world, for
   consistency with `recipe_saddle`), the three "learned" reveals (world, because they gate chapter
   progress), and the eleven Cloudreach `side_*` flags (world). All are listed above with the
   reasoning; none was defaulted.
4. **Leftover worktree:** `git worktree remove /home/user/tb-base-check` when convenient. This
   lane's own worktree is `/home/user/tb-lane-1b` on branch `lane-1b-state-seam`, six commits,
   nothing pushed.
