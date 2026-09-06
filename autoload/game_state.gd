extends Node

## The single place run-time state lives: the party, the satchel, the day.
##
## This is the project's first autoload, and it is meant to stay its only one.
## Before it, state was owned by whichever node happened to hold it — the fight
## owned the creatures, nothing owned the inventory because there was none — and a
## menu cannot read state that is scattered across three scenes.
##
## What belongs here: things that outlive the scene tree. What does NOT: the
## fight, the camera, the terrain, anything with a transform. If a system can
## reasonably own its own state, it should.
##
## It also stands up the pause menu (`_mount_menu`). That is a second job for
## one object and it is deliberate: the alternative is instancing the menu into
## every world scene by hand, and world scenes belong to other people. One
## autoload line in project.godot buys a menu that exists everywhere, including
## in scenes nobody has written yet.

const MENU_SCENE := "res://scenes/ui/game_menu.tscn"
const CREATURE_PROGRESSION := preload("res://scripts/creatures/progression.gd")
const HOME_RECOVERY := preload("res://scripts/creatures/home_recovery.gd")
## RG19-spec/D68. Rested/fed/happy, ticked here for every party member.
const CREATURE_CONDITION := preload("res://scripts/creatures/creature_condition.gd")
## OWNER-0901-BOND-MILESTONES: distance/landmark/rest-night crediting for the
## bond ladder's "travelling"/"visiting"/"resting" tasks.
const BOND_MILESTONES := preload("res://scripts/creatures/bond_milestones.gd")

const ITEM_DB := preload("res://autoload/item_db.gd")
const INVENTORY := preload("res://autoload/inventory.gd")
const BOOT_LOG := preload("res://scripts/boot/boot_log.gd")
const SAVE_GAME := preload("res://scripts/save/save_game.gd")
## Only to hand `local.feed` to its static entry points -- see `_ensure_containers()`.
const PROGRESSION_FEED := preload("res://scripts/creatures/progression_feed.gd")
## D98 / docs/specs/MP_STATE_SEAM.md §1-§2. The two containers this autoload
## became a facade over, and the merged flag view that keeps `Game.progression`
## one object across both of their stores.
const WORLD_STATE := preload("res://autoload/world_state.gd")
const PLAYER_STATE := preload("res://autoload/player_state.gd")
const MERGED_PROGRESSION := preload("res://autoload/merged_progression.gd")
## T3-ENCOUNTER. Only for `reset_for_new_game()`'s world-seed decision; the
## roll itself lives in `encounter_director.gd`, which is where the spawn table
## is.
const SPAWN_TABLES := preload("res://scripts/combat/spawn_tables.gd")
const SESSION := preload("res://scripts/net/session.gd")
const LEDGER_RPC := preload("res://scripts/net/ledger_rpc.gd")

## Seeds a sample party and satchel so the screens can be looked at before
## gathering and catching exist. Off in a normal run: inventing a starting kit
## would be inventing content the opening sequence owns.
const DEMO_FLAG := "--menu-demo"

## D98 / docs/specs/MP_STATE_SEAM.md §1. What has happened to this WORLD, and
## who THIS TRAINER is. Every state property below this line is a one-line
## forwarding property into one of them, so all 390 `Game.<field>` sites the
## assumption inventory counts keep working under their old names and types.
##
## `Game.party` permanently means "the LOCAL player's party" -- every process
## keeps exactly one local player (the execution plan's §2 simplification), so
## that is a settled meaning rather than a transitional one.
##
## `players` is the host's map of peer id -> PlayerState, holding itself under
## peer id 1. Empty until Wave 2 stands up a session; only authority-side code
## ever addresses it.
var world: RefCounted = null
var local: RefCounted = null
var players: Dictionary = {}

## D95/lane 2.A. The live `scripts/net/session.gd`, mounted as `/root/Game/Session`
## by `_ready()` below. A child of this autoload rather than a second autoload
## (the one-autoload rule); every process has one, and a process that never
## hosts or joins simply has an inactive one. Reached as `Game.session` --
## `is_host()` / `is_multi_peer()` right below are the two questions gameplay
## code actually asks, and they answer safely even before this is mounted.
var session: Node = null

## D103/lane 3.A. The live `scripts/net/ledger_rpc.gd`, mounted as
## `/root/Game/Session/LedgerRpc` beside the session. Every consequential world
## mutation goes through `Game.ledger.submit(intent)`; solo and host commit it
## in place, a client sends it and waits for the delta. Null only in a process
## that never mounted a session (a pure unit test, which should be talking to
## `WorldLedger` directly).
var ledger: Node = null

## `Game.progression`, the merged view over `world.flags` and `local.flags`.
var _merged_progression: RefCounted = null

## The one immutable item catalogue in the process. Stays on `Game` (the seam's
## "Game keeps" list) rather than moving to a container, because there is one
## per PROCESS, not one per world or one per player.
##
## The setter exists so a caller that swaps the catalogue -- `test_recipes.gd`
## builds a bare `GAME_STATE.new()` and assigns `items` before `inventory` --
## also re-points the local player, which needs it to answer `hotbar_can_hold`.
var items: RefCounted:
	get:
		return _items
	set(value):
		_items = value
		if local != null:
			local.call("configure", value)
var _items: RefCounted = null

var inventory: RefCounted:
	get:
		return local.inventory if local != null else null
	set(value):
		if local != null:
			local.inventory = value

var party: RefCounted:
	get:
		return local.party if local != null else null
	set(value):
		if local != null:
			local.party = value

## R7.7. The trainer's five armour slots (scripts/player/player_equipment.gd)
## -- reachable the same way `equipped_tool` is (a plain autoload field), and
## deliberately NOT persisted through save_game.gd, matching `equipped_tool`'s
## own precedent: it resets each session and the player re-equips, the same
## as re-picking a tool off the hotbar.
var player_equipment: RefCounted:
	get:
		return local.equipment if local != null else null
	set(value):
		if local != null:
			local.equipment = value

## D33's one map database — fog-of-war, landmark discovery, dynamic markers.
## See `autoload/map_state.gd`'s own header for why there is exactly one of
## these. Configured from `data/config/map_landmarks.json` in `_ready()`, the
## same "load+parse a data file" pattern `_species()` below already uses.
## The map of the realm the LOCAL player is standing in. Inactive realm maps
## retain their own fog/landmarks and their own EXTENT -- `map_state.gd` lost
## its `static var _grid_x/_grid_z/_origin` this lane, so two maps in one
## process can describe two differently-shaped worlds.
##
## The setter re-homes the ACTIVE realm's map (`smoke_alpha_pins.gd` swaps in a
## bare `MapState` that way); the instances themselves live on the player
## (`PlayerState.maps`), which is what "personal fog" means from Wave 3.
var map: RefCounted:
	get:
		return local.call("map") if local != null else null
	set(value):
		if local != null:
			(local.maps as Dictionary)[local.realm] = value

## SB9. The flag store behind objective/completion/world-state tracking —
## see `autoload/progression_state.gd`'s own header for the full contract.
## Instantiated in `_ready()`, same as `map` above.
var progression: RefCounted:
	get:
		return _merged_progression
	set(value):
		# A caller handing over ONE flat store (several unit tests do) gets the
		# pre-split behaviour back exactly: both halves become that object, so
		# every read and every routed write lands in the store they passed.
		if world != null:
			world.flags = value
		if local != null:
			local.flags = value
		if _merged_progression != null:
			_merged_progression.world_flags = value
			_merged_progression.player_flags = value

## Cloudreach Phase 1.  Realm Heart selection outlives scene transitions just
## like progression and map state, while remaining a composed RefCounted so
## Game stays the project's single autoload.
var realm_hearts: RefCounted:
	get:
		return local.hearts if local != null else null
	set(value):
		if local != null:
			local.hearts = value

## Which world scene a Continue or realm transition should enter.  Pose saves
## carry the same id so coordinates from one realm are never applied to another.
var current_realm: String:
	get:
		return local.realm if local != null else "meadows"
	set(value):
		if local != null:
			local.realm = value

## Authored arrival anchor requested by a realm gate. It survives the
## transition autosave so Continue after a crash lands at the destination
## gate, then the destination world consumes it and writes a settled autosave.
var pending_realm_entry: String:
	get:
		return local.pending_realm_entry if local != null else ""
	set(value):
		if local != null:
			local.pending_realm_entry = value

## SB11. Reads `progression`'s flags against `data/progression/objectives.json`
## to answer "what is the one tracked Main Story line" and "what does the
## two-list quest log show" — see its own header. Instantiated in `_ready()`,
## same as `map`/`progression` above.
var quest_log: RefCounted:
	get:
		return local.quest_log if local != null else null
	set(value):
		if local != null:
			local.quest_log = value

## What the HUD's objective pointer shows right now. Kept in step with
## `progression`'s flags by `_process()` below (recomputed only when
## `progression.revision` actually moves, the same polling idiom that file's
## own header describes) — never guessed at or scripted by hand, except
## through `set_objective()`, which stays available for a caller that wants
## to show something `data/progression/objectives.json` does not (a capture
## tool posing a demo objective, e.g.) and sticks until the next real flag
## change recomputes it.
var objective_text: String:
	get:
		return local.objective_text if local != null else ""
	set(value):
		if local != null:
			local.objective_text = value

## OBJECTIVE-HINT-ON-HUD (`HIST-036`, OP23-04). The HOW that goes with
## `objective_text`'s WHAT — `quest_log.gd::tracked_hint()`, with its
## `{action}` placeholders already resolved to the buttons the player has
## actually bound. Kept in step with `objective_text` by exactly the same two
## writes, so the pair can never disagree about which rung the player is on.
##
## "" is the normal state, not an error: OP23-04's directive authors a `how`
## for the opening ladder only, so every beat past tournament entry has none,
## and so does a chapter that is finished. A drawing caller must render an
## empty hint as NOTHING — never as a blank line under the objective.
var objective_hint: String:
	get:
		return local.objective_hint if local != null else ""
	set(value):
		if local != null:
			local.objective_hint = value

## `progression.revision` last seen by `_process()` — see `objective_text`'s
## own comment.
var _last_progression_revision: int = -1

## The DEVICE `objective_hint` was last resolved for.
##
## BINDINGS. `objective_hint` is a string with the button names already baked
## into it, and it was recomputed only when the rung changed — so it froze the
## device that happened to be live at the moment the player last advanced the
## chapter. `input_glyph.gd`'s whole `HD1` design is live switching "as the
## player's hands move between keyboard and pad", and this one cached string
## was the only place in the HUD that did not follow. Picking up the pad on a
## desktop left the first-catch card still naming F; setting it down on the
## Ally left it naming X.
##
## Recomputed on a device flip, which is a rare event polled with one boolean
## comparison. `objective_text` is recomputed with it rather than alone,
## because the two are written together everywhere else on purpose: the pair
## must never disagree about which rung the player is on.
##
## ONE EDGE, for a tool author: a capture tool that writes `objective_hint`
## STRAIGHT onto this node (`tools/_capture_objective_hint_card.gd` does, on
## purpose, to reproduce the shape `_process()` produces on a real flag change)
## is not covered by `_objective_is_posed` below -- only `set_objective()` sets
## that. If such a tool also pins the device, pin it BEFORE the write, or the
## first `_process()` after the flip resolves the real rung over the posed line.
var _last_hint_device_was_gamepad: bool = false

## Whether `objective_text`/`objective_hint` are currently a `set_objective()`
## pose rather than the quest log's own line. Only the device-flip recompute
## above reads it: the rung-moved branch has always taken a pose back over, and
## that is the contract `set_objective()` documents.
var _objective_is_posed: bool = false

## In-game day, counted from 1. The release ledger and "time with you" on the
## ceremony screen both need a clock that is not wall time, and this is it.
## Nothing advances it yet; M10's day/night cycle will.
var day: int:
	get:
		return world.day if world != null else 1
	set(value):
		if world != null:
			world.day = value

## N14-ROUTED-FOLLOWUPS, from N13-NIGHT-RESUME §5: the hour of day, carried
## across everything that destroys and rebuilds the world scene.
##
## `world_look.gd` owns the live clock, but it is a node in the scene, so a
## Continue, a `enter_realm()` crossing and a title-screen Load all threw it
## away and rebuilt it at 08:00 -- N13 measured a player being able to run for
## hours without the world ever reaching hour 22, because every transition
## restarted the 350-second walk to nightfall. `Game` outlives those rebuilds,
## so it is where the number waits.
##
## `CLOCK_UNSET` (negative) means "no carried clock, open at the authored
## morning": a New Game, or a save written before VERSION 19. That distinction
## is the whole reason this lives here rather than in a `static var` on
## `world_look.gd` -- a static would survive New Game too, and start a fresh
## run at whatever hour the last one ended at.
const CLOCK_UNSET := -1.0
var clock_elapsed_seconds: float:
	get:
		return world.clock_elapsed_seconds if world != null else CLOCK_UNSET
	set(value):
		if world != null:
			world.clock_elapsed_seconds = value

## What the build menu last armed, or an empty string. The building system reads
## this when there is one; until then it is the honest end of the build screen.
var pending_build: String:
	get:
		return local.pending_build if local != null else ""
	set(value):
		if local != null:
			local.pending_build = value

## OF20. A one-line toast for a world node that just refused something (wrong
## tool, satchel full) and has no HUD handle of its own to say so through —
## `playground_hud.gd`'s own `_show_hotbar_message` covers refusals the HUD
## triggers itself (an item used off the hotbar), but a gather refused by
## walking up to `harvest_node.gd` happens with no HUD in the call stack at
## all. Read-and-cleared by `take_pending_world_message()`, the exact
## one-shot contract `map_state.gd`'s `take_pending_region_announcement()`
## already uses for the same reason: the event happens on one frame and a
## plain equality check would miss it the instant it is cleared.
var _pending_world_message: String = ""

## R4.10. The creature caught while the belt was already full, held here between
## the catch resolving and the release ceremony resolving. Exactly one, and it
## is NOT storage: it is never saved, a second overflow catch is refused rather
## than queued (`encounter_director.gd::_resolve_catch`), and `_process` below
## keeps reopening the Team screen until the ceremony has emptied it — the
## player cannot walk around owning six. Set by the encounter director, cleared
## only by `tab_creatures.gd`'s ceremony.
var pending_catch: RefCounted:
	get:
		return local.pending_catch if local != null else null
	set(value):
		if local != null:
			local.pending_catch = value

## R3.1. Every build piece the player has planted, as data — `{id, position:
## [x,y,z], yaw_deg}` — independent of whatever scene node currently renders
## it. This is the thing save/load actually persists; `build_placer.gd` reads
## it back to respawn the world on load and appends to it on every real
## placement. `yaw_deg` joined in the save format's VERSION 2 (see
## `scripts/save/save_game.gd`); every building placed before that defaults
## to facing 0.
var placed_buildings: Array:
	get:
		return world.placed_buildings if world != null else []
	set(value):
		if world != null:
			world.placed_buildings = value

## R7.6. What each bed of the berry farm is doing — `{state, ripe_on_day}` per
## entry, in the order `data/config/farm.json` lists its plots.
##
## The same "registry, not the scene node, is what a save persists" split
## `placed_buildings` draws above, and for a sharper reason: a crop is the
## only thing in this game whose state advances while the player is somewhere
## else entirely. `harvest_node.gd`'s piles can afford to respawn on a
## `_process` timer and come back fresh on every load because losing 60
## seconds of a respawn clock costs nobody anything; forgetting that six beds
## were sown two days ago costs the player the entire wait they were sitting
## through. Joined the save format at VERSION 8 -> 9 (see
## `scripts/save/save_game.gd`).
##
## Indexed by POSITION in farm.json rather than keyed by world coordinates:
## the plots are authored data, and a bed that gets nudged half a metre in a
## later tuning pass should keep the crop growing in it rather than silently
## forgetting it. Reordering that file WOULD shuffle a live save's crops,
## which is the honest trade and is written down in farm.json's own header.
##
## Read and written only through `farm_plot_at()`/`set_farm_plot()` below, so
## the "grow the array to fit" rule lives in one place — a save written when
## the farm had four beds must not error the day it has six.
var farm_plots: Array:
	get:
		return world.farm_plots if world != null else []
	set(value):
		if world != null:
			world.farm_plots = value

## The five action slots, as item ids — NOT satchel indices.
##
## Owner directive, after playing: the hotbar is "a separate assignable bar",
## and raw materials must never fill action slots. Before this it was neither:
## `playground_hud.gd` mirrored satchel slots 0-4 directly, so whatever the
## satchel happened to put first WAS the hotbar. Wood and stone sat in action
## slots answering "is not something you can use here", and rearranging the
## backpack silently rebound the bar under the player (the 2026-08-15 blind
## playtest's PT-11: a potion vanished from slot 2 with no indication).
##
## Ids rather than indices is the whole point. An index is a position in the
## satchel and moving a stack changes it; an id survives sorting, splitting,
## spending the last one and picking another up. A slot naming an item the
## satchel does not currently hold stays assigned and simply reads as empty —
## that is what makes "I keep potions on 2" a stable habit rather than a
## coincidence of bag order.
##
## `HOTBAR_KINDS_ALLOWED` is the material rule, applied at assignment time.
var hotbar: Array[String]:
	get:
		return local.hotbar if local != null else ([] as Array[String])
	set(value):
		if local != null:
			local.hotbar = value

## Item kinds that may occupy an action slot — an allow-list, not a refusal
## list. Owner board (docs/reference/owner-board-2026-08-15-systems-and-castle
## .png, "UI / SYSTEM FIXES CHECKLIST"): "Hotbar: consumables + tools only (no
## wood/stone/etc.)". `tool` is a held/equipped item (`_use_hotbar_slot()`'s
## own equip branch); `consumable` and `food` are the two kinds
## `_use_hotbar_slot()` actually knows how to spend on press (heal/revive/
## creature_buff, and satiety). Everything else this project's items carry a
## kind for — `resource` (wood/stone/fiber), `currency` (coin), `gear` (orbs,
## thrown through combat's own `throw_aim.gd`, never the bar; a saddle),
## `key`, `material` (saddle_frame), `tm` and `elixir` (both taught/drunk
## through the backpack's own target-picker onto a chosen creature, never a
## single field press) and `armor` — has no use-path in `_use_hotbar_slot()`
## at all, so assigning one used to load the bar with a dead button that only
## ever answers "is not something you can use here."
const HOTBAR_KINDS_ALLOWED := PLAYER_STATE.HOTBAR_KINDS_ALLOWED
const HOTBAR_SLOTS := PLAYER_STATE.HOTBAR_SLOTS

## The tool the trainer is holding, as an item id, or "" for empty-handed.
##
## Owner directive: "press slot, tool in hand" — the tool is visibly carried and
## stays there until you switch away, and swinging it is what harvests. Before
## this there was no equip concept at all: pressing a tool on the hotbar only
## repaired it, which is why the owner reported the tools existing but being
## impossible to pull out and use.
##
## Deliberately NOT saved. Which tool is in your hand is a moment-to-moment
## posture, not progression — the satchel that actually holds the tools is what
## persists, and loading a game with empty hands is both harmless and the
## expected reading of "you just arrived".
var equipped_tool: String:
	get:
		return local.equipped_tool if local != null else ""
	set(value):
		if local != null:
			local.equipped_tool = value

## R3.2. Every death satchel the player has left in the world, as data —
## `{position: [x,y,z], state: [...]}` — the same "registry, not the scene
## node, is what a save persists" split `placed_buildings` draws above.
## `state` is whatever `storage_state.gd::save_data()` last returned for that
## satchel (a chest's own contents shape); a freshly-registered satchel
## starts with an empty array and `player_death.gd::sync_state_to_game` fills
## it in right before every write, mirroring `_sync_placed_building_state()`
## below for a placed chest. Joined the save format at VERSION 4 (see
## `scripts/save/save_game.gd`) — a save written before this has none, and
## migrates to an empty list, the same "no fog trail predates the map"
## answer VERSION 1 -> 2 gave `map`.
var death_satchels: Array:
	get:
		return world.death_satchels if world != null else []
	set(value):
		if world != null:
			world.death_satchels = value

## HARVEST-ALL / D60. Every vegetation harvest point (a scattered tree or
## rock, `scripts/world/vegetation_harvest_point.gd`) the player has
## permanently chopped, as data — `{layer_name: bitset_b64}`, one entry per
## harvestable layer in `data/config/vegetation.json`. Same "registry, not
## the scene node, is what a save persists" split `placed_buildings`/
## `death_satchels` draw above. `vegetation.gd::sync_state_to_game` fills it
## in right before every write; a freshly-registered world starts with an
## empty dictionary (nothing chopped). Joined the save format at VERSION 10
## (see `scripts/save/save_game.gd`) — a save written before this has none,
## and migrates to `{}`, the same "no fog trail predates the map" answer
## VERSION 1 -> 2 gave `map`.
var harvested_vegetation: Dictionary:
	get:
		return world.harvested_vegetation if world != null else {}
	set(value):
		if world != null:
			world.harvested_vegetation = value

## T3-ENCOUNTER. Which world this save's rolled wild population is.
##
## `encounter_director.gd` builds the ROLLED half of the population as a pure
## function of `(world_seed, order)` -- so this one integer IS the population,
## and a rolled world needs no per-creature persistence: reload derives the same
## answer it derived before. Joined the save format at VERSION 15; a save written
## before this migrates to 0.
##
## **0 is the authored world**, and is the default deliberately. At 0 the roller
## is never entered and every rolled cluster stands up the species `spawns.json`
## authors, which is the world every smoke test, every `tools/gate_f` segment and
## every existing save already knows. A new game takes a real seed only when
## `data/config/spawn_tables.json`'s `roll_new_worlds` says so (it ships false);
## `TB_WORLD_SEED` in the environment overrides this for one process either way.
var world_seed: int:
	get:
		return world.world_seed if world != null else 0
	set(value):
		if world != null:
			world.world_seed = value

## RG9. Every chopped placement whose felled pickup has NOT yet been gathered
## -- `{"<layer>#<index>": {"item": String, "amount": int, "position":
## [x,y,z]}}`. A tree/rock present in `harvested_vegetation` but ABSENT here
## has already paid out; present in both means a real pile is still sitting
## on the ground waiting for the player, and `vegetation.gd::restore_from_game`
## stands it back up on load so the wood/stone it owes is never silently
## lost. `vegetation.gd::sync_state_to_game` fills it in right before every
## write, the same split `harvested_vegetation` above uses. Joined the save
## format at VERSION 11 (see `scripts/save/save_game.gd`) — a save written
## before this has none, and migrates to `{}`.
var felled_vegetation: Dictionary:
	get:
		return world.felled_vegetation if world != null else {}
	set(value):
		if world != null:
			world.felled_vegetation = value

## RG7. The last captured player/world pose. Transform data stays OUT of the
## ordinary long-lived gameplay state; this dictionary is only the save/load
## seam so a slot can return the trainer to the exact place and view it wrote.
## Shape: {position:[x,y,z], model_yaw, camera_yaw, camera_pitch}.
var saved_player_pose: Dictionary:
	get:
		return local.pose if local != null else {}
	set(value):
		if local != null:
			local.pose = value

## R3.1. Save/load logic — `scripts/save/save_game.gd`. A plain RefCounted,
## same split as `party`/`inventory` above, so it is testable without a scene
## tree. See that file's header for the format and versioning rule.
var save_system: RefCounted = null

## OF26 debug scaffolding. The public door onto `_find_player()` above —
## every other caller of that lookup is inside this file already; the debug
## teleport list (`scripts/ui/tab_settings.gd`) is the first one outside it,
## and this wraps rather than duplicates so there stays exactly one player
## lookup, not two that can drift apart.
func find_player() -> Node3D:
	return local_player()


## D-MP7. The rig the LOCAL peer drives. `find_player()` above stays as the name
## fifteen-plus call sites already know; 2.C rebinds this to the local rig when
## remote trainers start standing in the same scene, and the alias follows it.
func local_player() -> Node3D:
	return _find_player()


## Fallback satiety, read/written by `save_game.gd` ONLY when no live
## `PlayerVitals` is reachable through `player_vitals()` below — a running
## game always has one, since the project's single main scene always carries
## a `Player`, so in practice this is exercised by headless callers (tests,
## a save/load invoked before the world scene exists) rather than by real
## play. See `save_game.gd`'s header for the full seam this backs.
var satiety: float:
	get:
		return local.satiety if local != null else 100.0
	set(value):
		if local != null:
			local.satiety = value

## DEVELOPMENT CONVENIENCE, AND IT IS MEANT TO BE DELETED.
##
## The owner asked for "a toggle to free build without cost right now until we
## launch the real game". Off unless it is switched on in Settings > Gameplay,
## said out loud on the Build tab the whole time it is on, and confined to this
## block, one section of data/config/menu.json, one builder in
## scripts/ui/tab_settings.gd and one banner in scripts/ui/tab_build.gd.
## Removing it is deleting those four things — see docs/decisions/D16.
var free_build: bool = false

## The key `free_build` is stored under in user://settings.json.
const PREF_FREE_BUILD := "free_build"

## OF26. DEVELOPMENT CONVENIENCE, AND IT IS MEANT TO BE DELETED.
##
## Owner-reported: "Give me the ability to teleport and spawn in at different
## points so I can test different things. Like teleport to different named
## areas." Same D16 scaffolding pattern as `free_build` right above — off
## unless switched on in Settings > Gameplay, persisted the same way, and
## confined to this block, one section of data/config/menu.json and the
## teleport builder in scripts/ui/tab_settings.gd. Removing it is deleting
## those three things.
var debug_teleport: bool = false

## The key `debug_teleport` is stored under in user://settings.json.
const PREF_DEBUG_TELEPORT := "debug_teleport"

## OP23-13 (owner playtest 2026-08-23): "Auto-run is needed." A real player
## preference, not D16 scaffolding — persisted the same way `free_build`/
## `debug_teleport` are, but with no removal note, since this is meant to
## ship. Toggled by the `auto_run` input action (`player_controller.gd`);
## `true` makes the player run without holding `sprint`.
var auto_run: bool = false

## The key `auto_run` is stored under in user://settings.json.
const PREF_AUTO_RUN := "auto_run"

## OP23-03 (owner playtest 2026-08-23): "zoom level should persist" across map
## opens. Session-only on purpose -- unlike `auto_run`/`free_build` this is
## not written to user://settings.json; it just has to survive `tab_map.gd`
## rebuilding its whole canvas every time the tab opens (`game_menu.gd` forces
## a rebuild on open/select), the same "one thing across scene loads" job this
## autoload already does for `map` itself.
var map_last_zoom: float = 1.0

var _menu: CanvasLayer = null

## Throttle for fog-of-war discovery — see `_process()`. 0.5s is often enough
## that walking never outruns its own fog trail, and rare enough that this
## autoload is not doing a `get_node_or_null` tree walk every single frame.
const _DISCOVERY_INTERVAL_S := 0.5
var _discovery_elapsed: float = 0.0

## OWNER-0901-BOND-MILESTONES travel tracking, ticked alongside fog-of-war
## discovery above rather than every physics frame -- one more throttled
## poll on the same cadence, not a second per-frame cost.
##
## `_travel_pos_valid` starts false so the very first tick after a scene
## loads (or a `reset_for_new_game()`) has nothing to measure FROM yet — the
## first real position becomes the baseline instead of being read as however
## far the player spawned from Vector3.ZERO.
var _travel_pos: Vector3 = Vector3.ZERO
var _travel_pos_valid: bool = false
## A single tick's honest walking distance at sprint speed is a few metres
## (see player_controller.gd's `_sprint_speed`) times `_DISCOVERY_INTERVAL_S`.
## Anything past this in one tick is a teleport/respawn/scene change, not
## travel, and must not inflate the "travelled together" milestone.
const _TRAVEL_TELEPORT_GUARD_M := 30.0

## PT-23. `scripts/build/camp.gd` was the sole caller of `autosave_slot()`
## in the whole codebase -- building a camp is a mid-session action, so a
## new player who has not built anything yet has NO autosave at all for
## their entire first session. Day rollover (`advance_day()` below) was the
## other candidate hook, but `advance_day()` is ALSO only ever called from
## that same camp-rest path today, so tying autosave to it would just be the
## identical gap wearing a different name. A plain real-time cadence is the
## one hook that fires no matter what the player has or hasn't built or
## rested at yet. Tunable: 3 minutes is short enough to save most of a
## first session's early progress, long enough not to be a per-frame cost
## (see `_tick_autosave()`).
const _AUTOSAVE_FALLBACK_INTERVAL_S := 180.0
var _autosave_elapsed: float = 0.0

## Device the LAST real input came from, for `input_glyph.gd`'s icon choice
## (bible sec18 wants live switching as the player's hands move; `HD1`'s
## reproduction case was a keyboard/mouse player who still saw gamepad
## glyphs everywhere because the only signal was "is a pad connected").
##
## Starts true if a pad is already connected rather than false, so the
## common case -- the Ally, pad connected, keyboard never touched -- shows
## the right glyph on the very first frame instead of a keyboard icon
## nobody has pressed yet.
var _last_input_was_gamepad: bool = not Input.get_connected_joypads().is_empty()

## Idle stick drift on the Ally shouldn't flip the glyphs with nobody
## touching anything -- matches `input_devices/joy_deadzone` in
## project.godot rather than inventing a second number for the same idea.
const _MOTION_DEADZONE := 0.5


## The containers are built HERE rather than in `_ready()` because several unit
## tests instantiate this script directly (`test_recipes.gd`: `GAME_STATE.new()`,
## never added to a tree, so `_ready()` never runs) and then read and write the
## forwarding properties. A facade whose backing objects only appear on
## `_ready()` would hand those callers null for every field.
func _init() -> void:
	_ensure_containers()


## Idempotent: builds `world`, `local` and the merged flag view if they are not
## there yet, and points the merged view at the two live stores.
func _ensure_containers() -> void:
	if world == null:
		world = WORLD_STATE.new()
	if local == null:
		local = PLAYER_STATE.new()
	if _merged_progression == null:
		_merged_progression = MERGED_PROGRESSION.new(world.flags, local.flags)
	else:
		_merged_progression.world_flags = world.flags
		_merged_progression.player_flags = local.flags
	# The map and the Realm Hearts ask about flags across BOTH stores: a
	# Cloudreach landmark gated on a world flag and a hint gated on a personal
	# one have to answer from one object.
	local.flag_reader = _merged_progression
	local.call("configure", _items)
	# Hand the local player's feed to `progression_feed.gd`'s static entry
	# points, which every RefCounted producer and every presenter still calls.
	# Handed over rather than looked up on demand: see that file's `_active`.
	PROGRESSION_FEED.set_active(local.feed)


func _ready() -> void:
	BOOT_LOG.line("Game autoload: _ready start (first autoload, before any world scene)")
	items = ITEM_DB.new()
	save_system = SAVE_GAME.new()
	reset_for_new_game()

	if OS.get_cmdline_args().has(DEMO_FLAG):
		_seed_demo()

	_mount_session()
	_mount_menu()
	# After the menu, never before: the menu shell owns the settings file and has
	# only just read it (docs/decisions/D15).
	_adopt_preferences()
	BOOT_LOG.line("Game autoload: _ready done, menu mounted")


## Replace every piece of live, save-derived play state with the same empty
## state a process boot creates.  Save files are deliberately not touched:
## Start New Game means start a new run, not delete the player's other slots.
## Settings (`free_build`/`debug_teleport`) are preferences and likewise stay.
func reset_for_new_game() -> void:
	if items == null:
		items = ITEM_DB.new()
	_ensure_containers()
	# Both containers reset IN PLACE rather than being replaced: the merged flag
	# view and `progression_feed`'s epoch counter both hold on across a New Game,
	# and re-pointing them on every reset is one more thing to get wrong. Each
	# `reset()` rebuilds exactly what this function used to rebuild by hand.
	world.call("reset")
	local.call("reset")
	players.clear()
	bind_realm_map()
	objective_text = quest_log.call("tracked_text", progression)
	objective_hint = quest_log.call("tracked_hint", progression)
	_last_progression_revision = int(progression.get("revision"))
	_last_hint_device_was_gamepad = _last_input_was_gamepad
	_objective_is_posed = false

	# `day`, the clock, the build/catch holds, the hotbar, the two world-record
	# dictionaries, the pose and satiety are all cleared by `world.reset()` /
	# `local.reset()` above -- including `local.feed.clear()`, which is the
	# new-game reset `PROGRESSION_FEED.clear()` used to be.
	_pending_world_message = ""
	# T3-ENCOUNTER. A new run gets a new world only when the data says so, and
	# `roll_new_worlds` ships false -- so today this resets to 0, the authored
	# world, and every existing smoke test that starts a fresh game sees exactly
	# the meadow it has always seen. `TB_WORLD_SEED` overrides it at the point of
	# use (`encounter_director.world_seed()`) rather than here, so pinning a seed
	# for a Gate F capture cannot leak into what gets written to a save slot.
	world_seed = SPAWN_TABLES.new_world_seed() \
		if SPAWN_TABLES.rolls_new_worlds(SPAWN_TABLES.config()) else 0
	_discovery_elapsed = 0.0
	_autosave_elapsed = 0.0
	_travel_pos_valid = false


## D95/lane 2.A. The session node, mounted before the menu so anything the menu
## or a title screen touches on its first frame already has one to ask.
##
## PROCESS_MODE_ALWAYS (set in its own `_ready`) for the same reason the menu
## has it: opening the menu pauses the tree, and a paused session would stop
## answering the host clock while a player reads their party.
func _mount_session() -> void:
	if session != null:
		return
	session = SESSION.new()
	session.name = "Session"
	add_child(session)
	# D103/lane 3.A. The ledger transport is mounted here, with the session,
	# rather than by whichever consumer happens to submit the first intent.
	# Its RPCs only resolve because every process holds it at the identical
	# path (`/root/Game/Session/LedgerRpc`), and a node that appears when the
	# first pickup is touched would not be at that path on a peer that has not
	# touched one yet. `attach()` is idempotent.
	ledger = LEDGER_RPC.attach(self)


## D100's question at all four autosave sites, and D97's at `enter_realm()`:
## "may THIS process write the world?" True for solo, for a host, and for any
## process with no session at all (a headless test, a capture tool) -- see
## `session.gd`'s header for why that last case is a `true` and not a `false`.
func is_host() -> bool:
	if session == null:
		return true
	return bool(session.call("is_host"))


## Whether somebody else is in this session. False solo, and false before the
## session node exists.
func is_multi_peer() -> bool:
	if session == null:
		return false
	return bool(session.call("is_multi_peer"))


## D100's autosave routing, in one place so the four sites cannot drift apart.
## The host writes the world (which today, before the save split lands, is the
## same v22 file that also carries its character); every other peer writes only
## its own character, which `session.gd::_save_character_here()` documents as
## nothing to write yet.
func autosave_here() -> bool:
	if is_host():
		return save_game(autosave_slot())
	session.call("_save_character_here")
	return false


## The world as it goes on the wire to a joiner (`session.gd::_rpc_snapshot`).
## The four scene-facing sync seams run first, exactly as `save_game()` runs
## them, or the snapshot would describe the world one build behind the one the
## host is standing in.
func world_snapshot() -> Dictionary:
	_sync_placed_building_state()
	_sync_death_satchel_state()
	_sync_harvest_state()
	_sync_clock_state()
	return world.call("save_data")


## A joiner applying the host's world. `WorldState.load_data()` for the durable
## half, then the same live-scene reconciliation `load_game()` runs -- a joiner
## whose Meadows is already standing has to be told which one-shot pickups are
## gone and which fences exist, not merely handed the data.
func apply_world_snapshot(data: Dictionary) -> void:
	world.call("load_data", data)
	if not is_inside_tree():
		return
	var tree := get_tree()
	if tree == null:
		return
	for group in ["build_placer", "player_death", "harvest_state"]:
		for node in tree.get_nodes_in_group(group):
			if node.has_method("restore_from_game"):
				node.call("restore_from_game", self)
	for node in tree.get_nodes_in_group("progression_restore"):
		if node.has_method("restore_progression_from_game"):
			node.call("restore_progression_from_game", self)
	_restore_clock_to_world()


## D105. Host truth for `day` and the clock, arriving on a client. Written
## straight into this peer's `WorldState` and pushed into the live sky through
## the same `resume_at_elapsed` seam a loaded save uses -- a client never
## derives either number itself (`advance_day()` below refuses on a client).
func apply_host_clock(host_day: int, elapsed: float) -> void:
	if is_host():
		return
	world.set("day", maxi(1, host_day))
	if elapsed >= 0.0:
		clock_elapsed_seconds = elapsed
		_restore_clock_to_world()


## The menu, as a child of the autoload rather than of a world scene.
##
## PROCESS_MODE_ALWAYS because opening it pauses the tree, and a paused menu
## cannot close itself.
func _mount_menu() -> void:
	var packed: PackedScene = load(MENU_SCENE)
	if packed == null:
		push_error("menu scene missing: %s" % MENU_SCENE)
		return
	_menu = packed.instantiate()
	_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_menu)


func menu() -> CanvasLayer:
	return _menu


## Read by `input_glyph.gd`, which has no scene context of its own to poll
## `Input.get_connected_joypads()` against a live "last used" signal.
func last_input_was_gamepad() -> bool:
	return _last_input_was_gamepad


## Every real input event passes through here, tree-wide, regardless of
## whether a Control further down consumed it -- device intent doesn't care
## who handled the press.
func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton or event is InputEventKey or event is InputEventMouseButton:
		_last_input_was_gamepad = event is InputEventJoypadButton
	elif event is InputEventJoypadMotion:
		if absf((event as InputEventJoypadMotion).axis_value) >= _MOTION_DEADZONE:
			_last_input_was_gamepad = true
	elif event is InputEventMouseMotion:
		_last_input_was_gamepad = false


## D105: the day is host truth. `world_look.gd`'s automatic day roll calls this
## every `day_length_seconds` in EVERY process, so the refusal lives here rather
## than in that file -- one gate covers the passive roll, `night_rest.gd` and
## anything later that advances a day, and 2.A owns this file outright.
func advance_day() -> int:
	if not is_host():
		return day
	return int(world.call("advance_day"))


## R7.6. The state of farm bed `index`, or a fresh fallow one.
##
## Grows `farm_plots` on demand rather than requiring anyone to size it up
## front: a save written when `data/config/farm.json` listed four beds is
## loaded by a build that lists six, and the two new beds should read as
## unworked ground rather than as an out-of-range error. Same forgiving shape
## `_array_to_inventory` already gives a satchel that changed size.
func farm_plot_at(index: int) -> Dictionary:
	return world.call("farm_plot_at", index)


func set_farm_plot(index: int, plot: Dictionary) -> void:
	world.call("set_farm_plot", index, plot)


## PT-23 fallback autosave. Separate from the rest of `_process()` so a test
## can drive it in isolation without also standing up `progression`/
## `quest_log`/etc. the way a full `_process()` tick would demand -- see
## `tests/test_autosave_fallback.gd`.
func _tick_autosave(delta: float) -> void:
	_autosave_elapsed += delta
	if _autosave_elapsed < _AUTOSAVE_FALLBACK_INTERVAL_S:
		return
	_autosave_elapsed = 0.0
	# D100: the world half is the host's to write. A client still reaches here
	# every 180 s and still saves its own character (nothing, until the split).
	autosave_here()


## Fog-of-war discovery, throttled to `_DISCOVERY_INTERVAL_S`. Silently does
## nothing when no player can be found — a test scene, the menu-only boot
## screen, or a smoke test that instances the world without going through
## `SceneTree.change_scene_to` (and so never becomes `current_scene`) all hit
## this path, and none of them should ever see an error for it.
func _process(delta: float) -> void:
	_tick_autosave(delta)
	_tick_creature_bed_recovery(delta)
	_watch_pending_catch()
	# Tonic clocks (creature_instance.gd::tick_buffs). Ticked here rather than
	# from combat so a tonic runs down in and out of a fight alike -- "drink it
	# before the fight you drank it for", never a paused stockpile. Paused
	# menus pause the tree and this with it, so reading the backpack costs no
	# tonic time.
	if party != null:
		var condition_cfg: Dictionary = CREATURE_CONDITION.config()
		for member: Variant in (party.call("members") as Array):
			(member as RefCounted).call("tick_buffs", delta)
			# RG19-spec/D68. Every party member, not just the one out in
			# front: a five that only the active companion feeds is a five in
			# name only. Paused menus pause the tree and this with it, so
			# reading the backpack costs no nourishment.
			CREATURE_CONDITION.tick(member as RefCounted, condition_cfg, delta)
	var progression_revision: int = int(progression.get("revision"))
	var realm_changed: bool = bool(quest_log.call("set_realm", current_realm))
	var rung_moved := progression_revision != _last_progression_revision or realm_changed
	# BINDINGS. A device flip re-resolves the hint's baked-in button names, but
	# must NOT take a POSED objective down: `set_objective()`'s contract is that
	# the capture tools' demo line sticks until the rung moves, and several of
	# those tools pin the device and pose a line in the same run.
	var device_flipped := _last_input_was_gamepad != _last_hint_device_was_gamepad \
			and not _objective_is_posed
	if rung_moved or device_flipped:
		_last_progression_revision = progression_revision
		_last_hint_device_was_gamepad = _last_input_was_gamepad
		_objective_is_posed = false
		objective_text = quest_log.call("tracked_text", progression)
		objective_hint = quest_log.call("tracked_hint", progression)

	_discovery_elapsed += delta
	if _discovery_elapsed < _DISCOVERY_INTERVAL_S:
		return
	_discovery_elapsed = 0.0
	var player := _find_player()
	if player == null:
		return
	# OWNER-0901-BOND-MILESTONES: "travelling"/"visiting" milestone credit,
	# shared by every party member present (the same "whole five, not just
	# whoever is piloted" rule `battles_fought`/the old rest bonus already
	# used) — measured here rather than in player_controller.gd so the
	# player's own delicate movement/collision code stays untouched.
	var landmarks_before := int(map.discovered_landmark_count())
	var here := player.global_position
	if _travel_pos_valid:
		var stepped := here.distance_to(_travel_pos)
		if stepped > 0.0 and stepped <= _TRAVEL_TELEPORT_GUARD_M and party != null:
			for member: Variant in (party.call("members") as Array):
				BOND_MILESTONES.credit_distance(member as RefCounted, stepped)
	_travel_pos = here
	_travel_pos_valid = true

	map.mark_visited(here)
	map.update_region(here)
	var landmarks_gained := int(map.discovered_landmark_count()) - landmarks_before
	if landmarks_gained > 0 and party != null:
		for member: Variant in (party.call("members") as Array):
			BOND_MILESTONES.credit_landmark_visit(member as RefCounted)


## R4.10. While a catch is waiting on the release ceremony, the Team screen is
## the only place the game is allowed to be.
##
## Retried from `_process` rather than fired once at the moment of the catch,
## and that is the whole design: this autoload runs paused-inherit, so the loop
## is naturally silent while the menu is open (the ceremony itself is in
## charge there), and the moment the menu is closed by ANY route — the panic
## chord's settings jump, a future caller of close(), a code path nobody has
## written yet — the next unpaused frame puts the ceremony back on screen.
## `open()` refusing mid-fight is fine too: it returns false silently and this
## simply tries again when the fight is over. The ceremony cannot be dodged,
## only resolved.
func _watch_pending_catch() -> void:
	if pending_catch == null or _menu == null:
		return
	if bool(_menu.call("is_open")):
		return
	_menu.call("open", "creatures")


## The one Player in the running world, or null. Every existing test/tool in
## this codebase reaches the player as `world.get_node_or_null(^"Player")`
## (see e.g. `tests/smoke_playground.gd`); this is that same lookup rooted at
## `current_scene` instead of a hand-held `world` reference, since `Game` has
## none. There is no "player" group to join instead — this autoload is the
## first thing to need one, and adding a group for a single lookup site would
## be more machinery than the lookup itself.
func _find_player() -> Node3D:
	if not is_inside_tree():
		return null
	var tree := get_tree()
	if tree == null:
		return null
	var scene := tree.get_current_scene()
	if scene != null:
		return scene.get_node_or_null(^"Player") as Node3D
	# Capture tools and smoke tests instance the world manually, so
	# `current_scene` stays null there — which silently starved fog-of-war
	# discovery in every full-scene capture (the minimap looked far more
	# fogged in-scene than the isolated harness predicted). Fall back to
	# scanning the root's children for a world that carries a Player.
	for child in tree.root.get_children():
		var found := child.get_node_or_null(^"Player") as Node3D
		if found != null:
			return found
	return null


## The live `PlayerVitals` (`scripts/player/player_vitals.gd`) hanging off
## the current Player, or null when there is none to find. `player_vitals.gd`
## is deliberately a plain `RefCounted` on the player node, not something
## this autoload owns, so this is a lookup rather than a copy — the caller
## reads or writes it directly and never gets a stale snapshot. Read by
## `scripts/save/save_game.gd`, whose header explains why satiety is
## persisted through this seam rather than a copy kept here.
func player_vitals() -> RefCounted:
	var player := _find_player()
	if player == null:
		return null
	var vitals: Variant = player.get("vitals")
	return vitals as RefCounted if vitals is RefCounted else null


## A manual override for `objective_text`, for a caller that wants the HUD to
## show something `data/progression/objectives.json` does not know about (the
## map/minimap capture tools pose a demo objective this way). Sticks until
## `_process()` next sees `progression.revision` move, at which point the
## real quest-log line takes back over. `world_pos` is optional: pass a
## `Vector3` to also drop a "objective" dynamic marker on `map` at that spot,
## or leave it null (the default) to track text only, or to clear a marker a
## previous objective left behind.
func set_objective(text: String, world_pos: Variant = null) -> void:
	objective_text = text
	_objective_is_posed = true
	# A posed objective has no authored `how` behind it, and carrying the
	# previous rung's hint under someone else's line would be worse than
	# carrying none: the capture tools that use this pose a demo objective the
	# quest log has never heard of. Cleared rather than left, and it comes back
	# the moment `_process()` next sees `progression.revision` move, same as
	# `objective_text` itself.
	objective_hint = ""
	if world_pos is Vector3:
		map.add_dynamic_marker("objective", "objective", world_pos as Vector3)
	else:
		map.remove_dynamic_marker("objective")


# --- naming a flag store explicitly (MP_STATE_SEAM.md §3, last paragraph) ----
##
## Four writer sites must NOT go through `Game.progression`, because the ACTOR
## is not simply "whoever is local right now" and scope routing alone would put
## the flag in a store that is right today and wrong with a second player in the
## session. They name a store through these three instead, and Waves 3/5 change
## the bodies here rather than hunting the call sites again.

## The world's store. `realm_heart_state.place()` writes through this so a
## client cannot record a Heart placement locally from Wave 3.
func world_flags() -> RefCounted:
	return world.flags if world != null else null


## One player's store -- the local one, which is the only one that exists
## before Wave 2. `peer_id` 0 means "local"; from Wave 2 a host passes a real
## peer id and gets that peer's.
func player_flags(peer_id: int = 0) -> RefCounted:
	if peer_id != 0 and players.has(peer_id):
		return (players[peer_id] as Object).get("flags") as RefCounted
	return local.flags if local != null else null


## D99/D-MP5: home and creature-bed flags are PLAYER flags granted to EVERY
## connected peer when the world gains the pieces -- a shared camp is
## everyone's camp. Solo, that is exactly one store and exactly today's
## behaviour; from Wave 3 this fans out a per-peer delta and the call sites
## (`home_progress.gd`) do not change.
func grant_player_flag(id: String, value: bool = true) -> void:
	if local != null:
		local.flags.call("set_flag", id, value)
	for peer_id: Variant in players.keys():
		var peer: Object = players[peer_id]
		var store: Object = peer.get("flags") if peer != null else null
		if store != null and store != local.flags:
			store.call("set_flag", id, value)


## OF20. Any world node with no HUD handle of its own queues its one-line
## refusal here; see `_pending_world_message`'s own comment for why this
## exists instead of the node reaching for the HUD directly.
func push_world_message(text: String) -> void:
	_pending_world_message = text


## Read-and-clear: "" if nothing is waiting (the common case, polled every
## frame by `playground_hud.gd`), the queued line exactly once otherwise.
func take_pending_world_message() -> String:
	var text := _pending_world_message
	_pending_world_message = ""
	return text


# --- the progression feed (PROGRESSION-VISIBLE, prompt 73, D76) ---------------
##
## The same queue-plus-revision shape as the world message above, for every
## progression change: XP, levels, bond credits, bond milestones. The storage
## is `scripts/creatures/progression_feed.gd`'s static log, because the
## producers are RefCounted creatures with no tree to reach this autoload
## through -- these are the `Game`-shaped handles for anything that already
## talks to `Game`. Presenters poll `progression_feed_revision()` and read
## `peek_progression_events(seq)` past their own cursor; nothing in
## production takes (drains) the log, so several readers share it.

func push_progression_event(kind: String, creature: RefCounted, payload: Dictionary = {}) -> Dictionary:
	if creature != null and (party == null or not (party.call("members") as Array).has(creature)):
		return {}
	return local.feed.call("push_event", kind, creature, payload)


func progression_feed_revision() -> int:
	return int(local.feed.call("event_revision"))


func peek_progression_events(after_seq: int) -> Array:
	return local.feed.call("events_since", after_seq)


func take_progression_events() -> Array:
	return local.feed.call("drain_events")


# --- creature-bed recovery (Gate A) -----------------------------------------

func _tick_creature_bed_recovery(delta: float) -> void:
	if party == null or delta <= 0.0:
		return
	var cfg := CREATURE_PROGRESSION.config()
	var seconds := CREATURE_PROGRESSION.creature_bed_full_heal_seconds(cfg)
	for member: Variant in (party.call("members") as Array):
		var creature := member as RefCounted
		if creature == null or not bool(creature.get("resting")):
			continue
		var max_hp := float(creature.get("max_hp"))
		if max_hp <= 0.0:
			continue
		var hp := minf(max_hp, float(creature.get("hp")) + max_hp / seconds * delta)
		creature.set("hp", hp)
		# A bed is explicitly allowed to recover a fainted pal; unlike a potion,
		# it has paid the time/unavailability cost. Once it has real HP again the
		# faint flag no longer describes its physical state.
		if hp > 0.0:
			creature.set("fainted", false)


## Player sleep is the completion boundary. Only pals ACTUALLY assigned to a
## creature bed receive the full overnight recovery/rest reward; otherwise the
## bed would be optional decoration because ordinary sleep healed everyone.
func complete_creature_bed_rests() -> int:
	if party == null:
		return 0
	var cfg := CREATURE_PROGRESSION.config()
	var completed := 0
	for i in party.call("size"):
		var creature: RefCounted = party.call("at", i)
		if creature == null or not bool(creature.get("resting")):
			continue
		# What a completed rest does to a CREATURE lives in one place.
		#
		# These two lines used to be `heal_fully()` plus a `gain_xp(rest_xp)`
		# written out here, which is exactly what `home_recovery.rest()` already
		# did -- and that helper had no production callers at all, so the project
		# carried two definitions of "resting heals you and pays rest XP" with
		# only the duplicate running. `tests/test_fainting.gd` proved the copy
		# nothing called, and `smoke_stronghold.gd` simulated the stronghold's
		# recovery through it, so both would have kept passing if this loop
		# broke.
		#
		# The BED-specific state below stays here, because it is about the bed
		# rather than about resting: which slot the creature was in, and that it
		# is no longer occupying one.
		HOME_RECOVERY.rest(creature, cfg)
		creature.set("rested", true)
		creature.set("resting", false)
		creature.set("rest_bed_index", -1)
		# OWNER-0901-BOND-MILESTONES: bond's "resting" milestone -- what the
		# BED adds over an ordinary rest is now a night credited toward it
		# (RG19-spec/D68 is still why this lives here rather than in
		# home_recovery.rest()).
		BOND_MILESTONES.credit_rest_night(creature)
		# RG19-spec/D68: the night in the bed is what "well rested" means, and
		# it is worth a little mood on top. The bed does not carry the numbers.
		CREATURE_CONDITION.note_rest_completed(creature, CREATURE_CONDITION.config())
		completed += 1
	if completed > 0:
		party.set("revision", int(party.get("revision")) + 1)
	return completed


# --- save / load (R3.1) ------------------------------------------------------


## Record a real placement. `build_placer.gd` calls this once, right after the
## piece is spent and planted — the registry, not the scene node, is what a
## save actually persists.
##
## `yaw_deg` defaults to 0 rather than being required: BG1 is the first
## caller that ever has a non-zero orientation to record, and a save written
## before it simply has no `yaw_deg` key on its old entries. The field is
## carried by the save format's VERSION 2 (`scripts/save/save_game.gd`),
## whose v1 migration writes the same safe 0.0 default onto old entries —
## the read side (`build_placer.gd::restore_from_game`) tolerates both.
func register_building(id: String, position: Vector3, yaw_deg: float = 0.0, paid: bool = true) -> void:
	world.call("register_building", id, position, yaw_deg, paid, current_realm)


## R3.2. `player_death.gd::_drop_satchel` calls this once, right before it
## spawns the live satchel node — the registry, not the scene node, is what a
## save actually persists, same split `register_building` draws above.
## Returns the new entry's index, which the caller stashes as node metadata
## so `sync_state_to_game`/`restore_from_game` can find their way back to it
## without a position-based search (the same role `PLACED_INDEX_META` plays
## for a placed building).
## D104/D-MP10 added `owner` and an explicit `realm`. Both default to today's
## behaviour: no owner recorded (what `realm_world_records.normalized()` stamps
## on a legacy record) and the local player's realm.
func register_death_satchel(position: Vector3, owner: String = "", realm: String = "") -> int:
	return int(world.call("register_death_satchel", position, owner,
		realm if realm != "" else current_realm))


## --- the hotbar ------------------------------------------------------------
##
## See `hotbar`'s own comment for why these are item ids and not satchel
## indices. Everything here is pure bookkeeping over that array; the HUD owns
## drawing it and resolving an id to a live stack.

## Whether `item_id` is allowed in an action slot at all. Unknown ids are
## refused rather than allowed: a slot naming something `items.json` has never
## heard of can only ever draw blank and refuse on press.
func hotbar_can_hold(item_id: String) -> bool:
	return bool(local.call("hotbar_can_hold", item_id))


## Put `item_id` on `slot`. Passing "" clears the slot. Returns false (and
## changes nothing) for an out-of-range slot or a refused kind, so a caller can
## tell the player exactly why rather than silently doing nothing.
##
## Assigning an item that already sits on another slot MOVES it rather than
## duplicating it: two slots holding the same id would both draw the same count
## and both spend from the same stack, which reads as a bug the first time a
## player presses the one they think is a spare.
func assign_hotbar(slot: int, item_id: String) -> bool:
	return bool(local.call("assign_hotbar", slot, item_id))


## The slot `item_id` occupies, or -1. Lets the backpack mark which of its
## tiles are already bound without duplicating the search.
func hotbar_slot_of(item_id: String) -> int:
	return int(local.call("hotbar_slot_of", item_id))


## Fill any empty slots from what the satchel is actually carrying, in bag
## order, skipping refused kinds and anything already bound.
##
## Two callers, one reason: a brand new game (so the pack Grandpa hands over
## lands on the bar instead of leaving it blank), and a save written before the
## bar existed (`save_game.gd::_migrate_v6`) — where the honest reconstruction
## of "the hotbar mirrored satchel slots 0-4" is "the first few usable things
## you were carrying", minus the wood and stone that used to clog it.
func autofill_hotbar() -> void:
	local.call("autofill_hotbar")


## Write `slot`. Returns whether it succeeded.
func save_game(slot: int) -> bool:
	_capture_player_pose()
	_sync_placed_building_state()
	_sync_death_satchel_state()
	_sync_harvest_state()
	_sync_clock_state()
	return bool(save_system.call("save", self, slot))


func current_realm_scene() -> String:
	if realm_hearts == null:
		return ""
	return str(realm_hearts.call("scene_for_realm", current_realm))


func can_enter_realm(realm_id: String) -> bool:
	if realm_hearts == null or progression == null:
		return false
	var scene := str(realm_hearts.call("scene_for_realm", realm_id))
	if scene == "":
		return false
	var key_flag := str(realm_hearts.call("entry_key_for_realm", realm_id))
	return key_flag == "" or bool(progression.call("has", key_flag))


## Cross a real realm boundary.  The transition autosave deliberately bypasses
## `save_game()`'s pose capture: after `current_realm` changes, a pose captured
## from the outgoing scene would be labelled as the destination and could drop
## the player at a valid but unrelated coordinate on Continue.
##
## ## Directive rule 16, lifted (Wave 6 lane 6.A)
##
## This used to REFUSE outright in a multi-peer session -- D97's interim rule,
## because a crossing rebuilds only this peer's scene and the host would have
## gone on simulating one realm for two players standing in different ones.
## The refusal is gone. What replaces it is not a removed guard but
## `Session.announce_realm()` below and the three things it drives:
##
##   1. the host's registry learns where this peer now is, and every peer's
##      copy of it does (`peer_registry.gd::set_realm` -> `_broadcast_registry`);
##   2. `trainer_spawn.gd` in the realm being LEFT despawns this peer's body,
##      while that world is still standing, so nobody there is left drawing a
##      trainer who has gone;
##   3. `realm_shells.gd` stands up a headless shell for the realm being
##      entered if the host is not itself in it, and folds down -- through the
##      host's own world save -- any realm this leaves empty.
##
## The call is made BEFORE `change_scene_to_file()` for step 2's sake. It is
## also made before the transition autosave is skipped or taken, so a client
## crossing a boundary never depends on having written anything.
##
## A client swapping its own world scene does NOT leave the session: nothing
## here touches the peer, and `Session` is a child of this autoload rather
## than of any scene, so it outlives the swap unchanged.
func enter_realm(realm_id: String, entry_id: String = "") -> bool:
	if not can_enter_realm(realm_id):
		return false
	var scene := str(realm_hearts.call("scene_for_realm", realm_id))
	if not ResourceLoader.exists(scene):
		push_error("realm '%s' points at missing scene %s" % [realm_id, scene])
		return false
	var leaving := current_realm
	if leaving == realm_id:
		# Not a crossing, and in a multi-peer session it is worse than a
		# no-op. A same-realm call would rebuild THIS peer's scene -- taking
		# every remote trainer body it had received down with it -- while
		# announcing nothing, because a realm change from X to X is not one.
		# The host would therefore never despawn and respawn anything, and
		# this peer would be left permanently unable to see the people
		# standing next to it. Nothing in the game does this (`realm_gate.gd`
		# is the only caller and always names the other side), so refusing is
		# free; leaving it open is not.
		return false
	_sync_placed_building_state()
	_sync_death_satchel_state()
	_sync_harvest_state()
	# N14: the crossing rebuilds the scene, which destroys the live clock. Read
	# it off the outgoing world BEFORE `change_scene_to_file()` so the arriving
	# `world_look.gd::_ready()` picks the same hour up instead of snapping the
	# player back to morning for having walked through a gate.
	_sync_clock_state()
	current_realm = realm_id
	bind_realm_map()
	pending_realm_entry = entry_id
	saved_player_pose = {}
	# Rule 16's ordering. Before the save and before the scene swap: the host
	# has to take this peer out of the world it is leaving while that world is
	# still standing on every peer that can see it.
	announce_realm(leaving, realm_id)
	# D100: the transition autosave is a WORLD write, so only the host makes it.
	if save_system != null and is_host():
		save_system.call("save", self, autosave_slot())
	get_tree().change_scene_to_file(scene)
	return true


## The realm-change seam, in one place so `enter_realm()` is the only caller
## that has to know a `Session` may not exist. Solo and session-less crossings
## are unchanged by construction: `session.gd::announce_realm()` returns
## immediately when there is no live session.
func announce_realm(from_realm: String, to_realm: String) -> void:
	if session == null or not session.has_method("announce_realm"):
		return
	session.call("announce_realm", from_realm, to_realm)


## Which realm a peer is standing in. `current_realm` answers that for the
## LOCAL player only, and D97 is explicit that nothing authoritative may read
## it for anybody else -- from Wave 6 two peers stand in two realms at once.
func realm_of_peer(peer_id: int) -> String:
	if session == null or not session.has_method("realm_of"):
		return current_realm
	return str(session.call("realm_of", peer_id))


## The host's live realm shells, or an empty report on a client or solo.
func realm_shell_report() -> Dictionary:
	if session == null or not session.has_method("realms"):
		return {}
	var realms: Variant = session.call("realms")
	if not (realms is Node) or not (realms as Node).has_method("report"):
		return {}
	return (realms as Node).call("report")


func pending_entry_for(realm_id: String) -> String:
	return pending_realm_entry if realm_id == current_realm else ""


## One scene-facing bind/sync seam. Call after realm selection and before
## configuring the minimap/atmosphere; pass Player.global_position to sync
## Cloudreach progression-gated navigation. This does not authorize travel,
## change scenes, grant flags, or change current_realm.
## The maps themselves live on the local player (`PlayerState.maps`), so
## "personal fog" is already true of the storage; `Game.map` is the active
## realm's, which is what every existing caller means by it.
func bind_realm_map(realm_id: String = "", player_position: Variant = null) -> RefCounted:
	var selected := current_realm if realm_id.is_empty() else realm_id
	var selected_map: RefCounted = local.call("map_for", selected)
	if selected_map == null:
		return null
	if selected_map.has_method("sync_navigation") and player_position is Vector3:
		selected_map.call("sync_navigation", progression, player_position)
	return selected_map


## SaveGame owns the file; Game owns these two live map instances. The legacy
## `map` field remains an active-map compatibility alias in the serialized file.
func save_realm_maps() -> Dictionary:
	return local.call("map_payloads")


## Load after progression so Cloudreach reads the same canonical flag object.
## Reuse existing instances: an already-mounted minimap can retain its handle.
func restore_realm_maps(payloads: Dictionary) -> void:
	local.call("load_map_payloads", payloads)
	bind_realm_map()


## Kept as the name several callers already know; the building itself moved to
## `PlayerState.map_for()`, which owns the per-realm extent.
func _ensure_realm_map(realm_id: String) -> RefCounted:
	return local.call("map_for", realm_id)


## Called only after the destination world has placed Player on its authored
## anchor. Clearing first and using the normal save path records the correct
## destination pose; a crash before this point retains the pending anchor.
func complete_realm_entry(realm_id: String) -> bool:
	if realm_id != current_realm:
		return false
	pending_realm_entry = ""
	return autosave_here()


## R3.1-remainder. A placed storage chest's own contents live on the live
## scene node (`storage_state.gd`), not in `placed_buildings` — `save_game
## .gd` deliberately never touches the scene tree (see its own header), so
## this is the one seam that does, right before every write. Mirrors
## `load_game`'s own "ask build_placer.gd" pattern below, just in reverse.
func _sync_placed_building_state() -> void:
	# Guarded the same way `_find_player()` guards its own `get_tree()` call:
	# a `GameState` not in any tree (a headless test, PT-23's own
	# `_tick_autosave` exercised in isolation) has no scene to sync FROM, so
	# there is nothing to do rather than something to crash on.
	if not is_inside_tree():
		return
	var tree := get_tree()
	if tree == null:
		return
	for node in tree.get_nodes_in_group("build_placer"):
		if node.has_method("sync_state_to_game"):
			node.call("sync_state_to_game", self)


## R3.2. Same seam as `_sync_placed_building_state` above, for death
## satchels — `player_death.gd` is the group's owner, not `build_placer.gd`,
## since a satchel is not a placed building (the player never built it).
func _sync_death_satchel_state() -> void:
	# Same "nothing to sync from without a tree" guard as
	# `_sync_placed_building_state()` above.
	if not is_inside_tree():
		return
	var tree := get_tree()
	if tree == null:
		return
	for node in tree.get_nodes_in_group("player_death"):
		if node.has_method("sync_state_to_game"):
			node.call("sync_state_to_game", self)


## HARVEST-ALL. Same seam as the two syncs above, for permanently-chopped
## vegetation — `vegetation.gd` is the group's owner (`"harvest_state"`,
## registered in its own `build()`).
func _sync_harvest_state() -> void:
	if not is_inside_tree():
		return
	var tree := get_tree()
	if tree == null:
		return
	for node in tree.get_nodes_in_group("harvest_state"):
		if node.has_method("sync_state_to_game"):
			node.call("sync_state_to_game", self)


## N14-ROUTED-FOLLOWUPS, from N13-NIGHT-RESUME §5. Read the live day/night
## clock off the world before anything that destroys it (a save write, a realm
## crossing), through the same "by group" seam the three syncs above use --
## `Game` has no direct handle on `world_look.gd`, and a scene with no world at
## all (a test harness, the title screen) must still save cleanly.
##
## Leaves `clock_elapsed_seconds` alone when there is no live clock to read, so
## a save written from the title screen keeps whatever hour the last world
## reported rather than silently rewriting it to the unset sentinel.
func _sync_clock_state() -> void:
	if not is_inside_tree():
		return
	var tree := get_tree()
	if tree == null:
		return
	for node in tree.get_nodes_in_group("day_cycle"):
		if node.has_method("elapsed_seconds"):
			clock_elapsed_seconds = float(node.call("elapsed_seconds"))
			return


## Load `slot` onto this live state and tell the world to rebuild whatever it
## placed. Returns whether a save was actually applied.
##
## Reached "by group" the same way `camp.gd::_pass_the_night` resets the
## day/night cycle — `Game` has no direct handle on the world scene, and a
## scene with no build-placer (a test scene, say) should load its party and
## satchel fine with nothing to rebuild.
func load_game(slot: int) -> bool:
	if not bool(save_system.call("load_slot", self, slot)):
		return false
	local.feed.call("clear_events")
	for node in get_tree().get_nodes_in_group("build_placer"):
		if node.has_method("restore_from_game"):
			node.call("restore_from_game", self)
	for node in get_tree().get_nodes_in_group("player_death"):
		if node.has_method("restore_from_game"):
			node.call("restore_from_game", self)
	for node in get_tree().get_nodes_in_group("harvest_state"):
		if node.has_method("restore_from_game"):
			node.call("restore_from_game", self)
	# RG7. Story directors and authored one-shot pickup owners have the same
	# live-world problem as buildings and vegetation: load_slot() restores the
	# durable data, then the already-running scene must reconcile what is active.
	# Keep this a generic lifecycle seam rather than teaching Game about Grandpa,
	# TMs, keys, or any future one-shot individually.
	for node in get_tree().get_nodes_in_group("progression_restore"):
		if node.has_method("restore_progression_from_game"):
			node.call("restore_progression_from_game", self)
	# N14: the same two-path problem the pose below has. A title-screen Continue
	# rebuilds the scene, and the new `world_look.gd::_ready()` picks the hour
	# up off `clock_elapsed_seconds` on its own; a MID-SESSION load leaves the
	# world standing, so the restored hour has to be pushed into the live clock
	# here or the sky would keep running from wherever the abandoned session had
	# got to.
	_restore_clock_to_world()
	# Mid-session loads can apply immediately. A title-screen load has no Player
	# yet; player_controller.gd calls apply_loaded_player_pose() from _ready(), so
	# the same saved dictionary is applied once the world exists.
	apply_loaded_player_pose()
	return true


func _restore_clock_to_world() -> void:
	if clock_elapsed_seconds < 0.0 or not is_inside_tree():
		return
	var tree := get_tree()
	if tree == null:
		return
	for node in tree.get_nodes_in_group("day_cycle"):
		if node.has_method("resume_at_elapsed"):
			node.call("resume_at_elapsed", clock_elapsed_seconds)


## RG7. Capture exact trainer position/facing and camera view before each save.
func _capture_player_pose() -> void:
	var player := _find_player()
	if player == null:
		return
	var model := player.get_node_or_null(^"Model") as Node3D
	var rig: Node = null
	var scene := get_tree().get_current_scene()
	if scene != null:
		rig = scene.get_node_or_null(^"CameraRig")
	if rig == null and player.get_parent() != null:
		rig = player.get_parent().get_node_or_null(^"CameraRig")
	var facing := model.global_rotation.y if model != null else player.global_rotation.y
	saved_player_pose = {
		"realm": current_realm,
		"position": [player.global_position.x, player.global_position.y, player.global_position.z],
		"model_yaw": facing,
		"camera_yaw": float(rig.get("yaw")) if rig != null else facing,
		"camera_pitch": float(rig.get("pitch")) if rig != null else 0.0,
	}


## Apply a loaded pose if both the data and Player exist. False is the normal
## pre-world/title-screen case, not an error; Player._ready retries it.
func apply_loaded_player_pose() -> bool:
	if pending_realm_entry != "":
		return false
	if saved_player_pose.is_empty():
		return false
	if str(saved_player_pose.get("realm", "meadows")) != current_realm:
		return false
	var player := _find_player()
	if player == null:
		return false
	var raw: Variant = saved_player_pose.get("position", [])
	if not raw is Array or (raw as Array).size() < 3 \
			or not _finite_number(raw[0]) or not _finite_number(raw[1]) or not _finite_number(raw[2]):
		return false
	var model_yaw_raw: Variant = saved_player_pose.get("model_yaw")
	var camera_yaw_raw: Variant = saved_player_pose.get("camera_yaw")
	var camera_pitch_raw: Variant = saved_player_pose.get("camera_pitch")
	if not _finite_number(model_yaw_raw) or not _finite_number(camera_yaw_raw) \
			or not _finite_number(camera_pitch_raw):
		return false
	player.global_position = Vector3(float(raw[0]), float(raw[1]), float(raw[2]))
	if player is CharacterBody3D:
		(player as CharacterBody3D).velocity = Vector3.ZERO
	var model := player.get_node_or_null(^"Model") as Node3D
	if model != null:
		model.global_rotation.y = float(model_yaw_raw)
	var scene := get_tree().get_current_scene()
	var rig: Node3D = scene.get_node_or_null(^"CameraRig") as Node3D if scene != null else null
	if rig == null and player.get_parent() != null:
		rig = player.get_parent().get_node_or_null(^"CameraRig") as Node3D
	if rig != null:
		var yaw := float(camera_yaw_raw)
		var pitch := float(camera_pitch_raw)
		rig.set("yaw", yaw)
		rig.set("pitch", pitch)
		rig.rotation = Vector3(pitch, yaw, 0.0)
		# GATE-F-LEG-S09. `camera_rig.gd::set_target()` only snaps its own
		# `global_position` to the target on the FIRST call (`not had_target`);
		# every later frame follows via `_follow()`'s per-frame lerp. This rig
		# already has a target by the time a save loads (`_place_player()` set
		# it at world boot), so a load that moves the player far from wherever
		# the rig physically was left the CAMERA -- and anything that streams
		# terrain/collision off the camera's own position -- lagging behind for
		# as long as that lerp takes to close the gap. Measured here: loading a
		# save ~7400m from the rig's last position left it that far behind at
		# the moment of load, and the player fell through unstreamed terrain,
		# took lethal fall damage, and was respawned at the village fallback
		# home with the satchel drained into a death satchel, before the lerp
		# ever caught up. Snapping the rig's position along with its rotation
		# is the same one-time snap `set_target()` already does for a target
		# that has never been followed before; a load is exactly that case
		# again, whatever the rig was following last.
		rig.global_position = player.global_position
	return true


func _finite_number(value: Variant) -> bool:
	return (typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT) and is_finite(float(value))


## The slot `camp.gd` writes to on every rest. Exposed here rather than left
## as a magic `0` at the one call site that needs it.
func autosave_slot() -> int:
	return int(SAVE_GAME.AUTOSAVE_SLOT)


## Whether a slot holds a save. Safe to ask BEFORE this autoload has run its
## own `_ready()`, which is not a theoretical window: `title_screen.gd` asks
## twice while building its menu, and a boot that reached it first logged
## `Cannot call method 'call' on a null value` at this line every time. The
## screen self-healed on the next frame, so it never became a visible bug --
## it just meant every boot log opened with an engine error, which is exactly
## the noise that hides a real one.
##
## `false` rather than a push_error: a caller asking "is there a save" before
## the save system exists is asking too early, and the honest answer to give a
## menu is "do not offer Continue yet" -- it asks again once the autoload is
## up. Anything that needs to distinguish "no save" from "cannot tell yet"
## should wait for `Game` to be ready instead of reading this.
func has_save(slot: int) -> bool:
	if save_system == null:
		return false
	return bool(save_system.call("has_slot", slot))


## Same window, same reasoning as `has_save()` above: an empty Dictionary is
## what a slot with nothing in it returns anyway, so a too-early caller gets
## the same shape rather than a crash.
func save_slot_info(slot: int) -> Dictionary:
	if save_system == null:
		return {}
	return save_system.call("slot_info", slot)


# --- building costs ---------------------------------------------------------


## What a buildable costs RIGHT NOW. THE one place that answers that question.
##
## Every cost check goes through here, including the ones nobody has written yet:
## placement (M8) spends what this returns, so it spends nothing while free build
## is on without ever having heard of free build. That is the whole reason this
## is a function on the state rather than a boolean five callers each remember to
## consult — one of them always forgets, and the bug it makes looks like a
## costing bug rather than a cheat left switched on.
##
## Returns the cost entries from data/items/buildables.json, [{id, n}, ...],
## and an empty array for a piece that costs nothing or does not exist. Ask
## `can_afford` rather than reading an empty array as "free".
func build_cost_for(id: String) -> Array:
	if free_build or items == null:
		return []
	var raw: Variant = items.buildable(id).get("cost", [])
	return raw as Array if typeof(raw) == TYPE_ARRAY else []


## Is there enough in the satchel to build this? True for anything real while
## free build is on.
func can_afford(id: String) -> bool:
	if items == null or inventory == null:
		return false
	# An id no catalogue entry answers to is not buildable however rich you are.
	# Without this, free build's empty cost would make every typo affordable.
	if items.buildable(id).is_empty():
		return false
	for requirement in build_cost_for(id):
		if typeof(requirement) != TYPE_DICTIONARY:
			continue
		var entry := requirement as Dictionary
		if int(inventory.count(str(entry.get("id", "")))) < int(entry.get("n", 0)):
			return false
	return true


# --- crafting ----------------------------------------------------------------


## R2.4. What a recipe costs, from data/recipes/recipes.json -- [{id, n}, ...],
## empty for an unknown recipe.
##
## OP21-10 reversal (docs/decisions/D16 §"Amendment — OP21-10"): free build
## now waives this exactly the way it waives `build_cost_for` -- same toggle,
## same empty-array shape, same "ask can_craft/can_afford, don't read the
## empty array as free" rule. D16 originally scoped free build away from
## crafting on purpose, with a test asserting exactly that; the owner has
## since overruled the scoping itself -- free build meaning "structures cost
## nothing" while their prerequisite crafting still drains the satchel read
## as inconsistent friction in play, so the toggle now covers both.
func recipe_cost_for(id: String) -> Array:
	if free_build or items == null:
		return []
	var raw: Variant = items.recipe(id).get("cost", [])
	return raw as Array if typeof(raw) == TYPE_ARRAY else []


## OF30. Has the player been taught this recipe yet?
##
## A recipe with no `unlocked_by` in data/recipes/recipes.json is known from the
## first minute; one that names a flag waits for `progression` to hold it. Tam
## the blacksmith's second conversation is what writes `recipe_orb_basic`, which
## is the only gated recipe today.
##
## Every recipe unknown when there is no flag store at all -- rather than every
## recipe known -- because the store is the whole record of what has been
## taught, and answering "yes, you know it" with nothing to check against is
## how a gate silently stops being one. An unknown recipe id is likewise not
## known, matching `can_craft`'s existing refusal.
func recipe_known(id: String) -> bool:
	if items == null:
		return false
	var recipe: Dictionary = items.recipe(id)
	if recipe.is_empty():
		return false
	var flag := str(items.recipe_unlock_flag(id))
	if flag == "":
		return true
	if progression == null:
		return false
	return bool(progression.has(flag))


## Every recipe the craft screen should be showing right now, sorted the way it
## draws them. The screen asks for this rather than filtering `recipe_ids()`
## itself, so "what does the player know" has exactly one answer.
func known_recipe_ids() -> Array:
	if items == null:
		return []
	var out: Array = (items.recipe_ids() as Array).filter(
		func(id: Variant) -> bool: return recipe_known(str(id))
	)
	out.sort()
	return out


## Is there enough in the satchel to craft this right now?
func can_craft(id: String) -> bool:
	if items == null or inventory == null:
		return false
	if items.recipe(id).is_empty():
		return false
	# OF30: a recipe nobody has taught you refuses however full the satchel is.
	# Checked here rather than only in the craft screen's list: hiding a row is
	# presentation, and a gate that only exists in presentation is one hotbar
	# shortcut away from not existing.
	if not recipe_known(id):
		return false
	for requirement in recipe_cost_for(id):
		if typeof(requirement) != TYPE_DICTIONARY:
			continue
		var entry := requirement as Dictionary
		if int(inventory.count(str(entry.get("id", "")))) < int(entry.get("n", 0)):
			return false
	# SD18: a `reinforce` recipe (see recipes_rootstone.json) upgrades a
	# specific owned tool rather than granting a new item -- refuse if the
	# named tool is not actually in the satchel, the same "you cannot craft
	# what you do not have the base of" refusal an item-output recipe gets
	# for free from the cost loop above.
	var reinforce: Dictionary = items.recipe(id).get("reinforce", {})
	if not reinforce.is_empty():
		if int(inventory.find_slot(str(reinforce.get("tool", "")))) < 0:
			return false
		return true
	# Output capacity is measured after the cost is removed. A consumed last
	# stack can make room; a merely reduced stack cannot. Preflight on a copy
	# so a full satchel never spends ingredients and silently loses the result.
	var preview := INVENTORY.new(items)
	for slot in inventory.slot_count():
		if not inventory.is_slot_empty(slot):
			preview.set_slot(slot, inventory.stack_at(slot))
	for requirement: Dictionary in recipe_cost_for(id):
		if not preview.remove(str(requirement.get("id", "")), int(requirement.get("n", 0))):
			return false
	var output: Dictionary = items.recipe(id).get("output", {})
	if not output.is_empty():
		return preview.has_room_for(str(output.get("id", "")), int(output.get("n", 0)))
	return true


## Spend the cost and grant the output, or change nothing at all.
##
## All-or-nothing on both ends: `can_craft` is checked again here (not just
## trusted from an earlier frame, in case the satchel changed in between), and
## `inventory.remove` is itself all-or-nothing per ingredient -- see its own
## comment on why a craft must never eat half its cost and then fail.
func craft(id: String) -> bool:
	if not can_craft(id):
		return false
	for requirement in recipe_cost_for(id):
		var entry := requirement as Dictionary
		if not bool(inventory.remove(str(entry.get("id", "")), int(entry.get("n", 0)))):
			push_error("craft '%s': afford check passed but remove failed on '%s'" % [
				id, str(entry.get("id", ""))
			])
			return false
	var recipe: Dictionary = items.recipe(id)
	# SD18: a `reinforce` recipe upgrades the named owned tool in place
	# instead of granting a new satchel item -- see `inventory.gd`'s own
	# `reinforce_tool()` comment for why this is a permanent durability-ceiling
	# raise and not just a paid re-skin of the already-free `repair_tool()`.
	var reinforce: Dictionary = recipe.get("reinforce", {})
	if not reinforce.is_empty():
		var slot: int = int(inventory.find_slot(str(reinforce.get("tool", ""))))
		if slot < 0:
			push_error("craft '%s': afford check passed but the tool to reinforce is gone" % id)
			return false
		inventory.reinforce_tool(slot, int(reinforce.get("bonus", 0)))
		return true
	var output: Dictionary = recipe.get("output", {})
	inventory.add(str(output.get("id", "")), int(output.get("n", 0)))
	return true


## Turn free build on or off and write it down.
##
## Returns whether the choice reached the settings file. False means it holds for
## this session only, which the settings screen says out loud rather than letting
## the owner find out on the next launch.
func set_free_build(on: bool) -> bool:
	free_build = on
	var prefs := _preferences()
	if prefs == null:
		return false
	var table: Dictionary = prefs.get("gameplay")
	table[PREF_FREE_BUILD] = on
	return bool(prefs.call("save"))


## OF26. Turn the debug teleport list on or off and write it down. Same
## contract as `set_free_build` above, including the "false means this
## session only" return.
func set_debug_teleport(on: bool) -> bool:
	debug_teleport = on
	var prefs := _preferences()
	if prefs == null:
		return false
	var table: Dictionary = prefs.get("gameplay")
	table[PREF_DEBUG_TELEPORT] = on
	return bool(prefs.call("save"))


## OP23-13. Turn auto-run on or off and write it down. Same contract as
## `set_free_build` above, including the "false means this session only"
## return.
func set_auto_run(on: bool) -> bool:
	auto_run = on
	var prefs := _preferences()
	if prefs == null:
		return false
	var table: Dictionary = prefs.get("gameplay")
	table[PREF_AUTO_RUN] = on
	return bool(prefs.call("save"))


func _adopt_preferences() -> void:
	var prefs := _preferences()
	if prefs == null:
		return
	var table: Dictionary = prefs.get("gameplay")
	free_build = bool(table.get(PREF_FREE_BUILD, false))
	debug_teleport = bool(table.get(PREF_DEBUG_TELEPORT, false))
	auto_run = bool(table.get(PREF_AUTO_RUN, false))


## The settings file, which the menu shell owns (docs/decisions/D15). There is
## exactly one file in user:// and this is how anything that is not a control
## gets into it.
func _preferences() -> RefCounted:
	return _menu.get("bindings") if _menu != null else null


# --- debug teleport (OF26) ---------------------------------------------------
#
# TEMPORARY, D16-style — see `debug_teleport`'s own comment above. Two jobs:
# name every place the list can send the player (`debug_teleport_destinations`)
# and actually move the player there (`debug_teleport_to`). Both are read by
# scripts/ui/tab_settings.gd, which owns the UI half.

const TERRAIN_PLAYGROUND_PATH := "res://data/config/terrain_playground.json"

## How close two destinations have to sit before the list treats them as the
## same place. Exists for one concrete case: the landmark "The Village"
## (10,-10) and the region "Grandpa's Village" (centre 6,-22) are 12.6m apart
## and are, in play, the same dooryard — a teleport list that offers both is
## not two destinations, it is one destination twice. 15m catches that pair
## with room to spare while staying well short of "Road Gate" (27.5,-16),
## which sits 18.5m from the village and is a genuinely separate destination.
const DEBUG_TELEPORT_DEDUPE_RADIUS := 15.0

## How far above the ground a teleported player lands. Matches
## `playground_world.gd`'s own SPAWN_CLEARANCE (2.0) — not read from it
## directly, since that constant lives on the world scene script and this
## autoload has no guaranteed world node to read it from except at teleport
## time itself, by which point a plain literal is simpler than reaching for one.
const DEBUG_TELEPORT_CLEARANCE := 2.0

## OF26 debug scaffolding. Every place the pause menu's debug teleport list
## can send the player, in file order — `map.regions()`, then
## `map.landmarks()`, then the seven severed-spoke road-ends from
## `data/config/terrain_playground.json`. Deliberately NOT a hand-authored
## table: everything here already exists for other reasons (the full map, the
## road signs), so a new region or a re-routed spoke shows up here for free
## instead of needing a second list kept in sync by hand.
##
## Deduped by position (`DEBUG_TELEPORT_DEDUPE_RADIUS`) rather than by id or
## name: "The Village" and "Grandpa's Village" do not share either, only a
## dooryard. Regions are read before landmarks before spokes, so ties keep
## the REGION's name — the Fortnite-style area name the map itself already
## favours for "the village" over the older single-point landmark.
func debug_teleport_destinations() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if map != null:
		for region: Dictionary in (map.regions() as Array):
			_debug_teleport_add(out, str(region.get("display_name", "")), region.get("centre", Vector2.ZERO))
		for landmark: Dictionary in (map.landmarks() as Array):
			# Dynamic markers (camps, the tracked objective) come and go with
			# play and are never a fixed "place" worth naming in a debug list.
			if bool(landmark.get("dynamic", false)):
				continue
			_debug_teleport_add(out, str(landmark.get("display_name", "")), landmark.get("position", Vector2.ZERO))
	for spoke: Dictionary in _debug_teleport_spokes():
		_debug_teleport_add(out, str(spoke.get("display_name", "")), spoke.get("position", Vector2.ZERO))
	return out


func _debug_teleport_add(out: Array[Dictionary], display_name: String, position: Vector2) -> void:
	if display_name.is_empty():
		return
	for existing: Dictionary in out:
		if (existing.get("position", Vector2.ZERO) as Vector2).distance_to(position) <= DEBUG_TELEPORT_DEDUPE_RADIUS:
			return
	out.append({"display_name": display_name, "position": position})


## The seven severed-spoke road-ends from `data/config/terrain_playground.json`
## — each spoke's `road` polyline's own LAST point, which is where the road
## itself actually stops (the blocker prop sits a little further on; the road
## end is honestly walkable ground, not inside the gorge/rockslide/gate).
## Labelled from the spoke's own fingerpost sign, falling back to its id if a
## spoke somehow has none. Read fresh on every call rather than cached — this
## backs a menu list opened rarely, not a per-frame read.
func _debug_teleport_spokes() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var file := FileAccess.open(TERRAIN_PLAYGROUND_PATH, FileAccess.READ)
	if file == null:
		return out
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return out
	var spokes: Variant = (parsed as Dictionary).get("spokes", {})
	if typeof(spokes) != TYPE_DICTIONARY:
		return out
	var routes: Variant = (spokes as Dictionary).get("routes", [])
	if typeof(routes) != TYPE_ARRAY:
		return out
	for entry: Variant in routes as Array:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var route := entry as Dictionary
		var road: Variant = route.get("road", [])
		if typeof(road) != TYPE_ARRAY or (road as Array).is_empty():
			continue
		var end: Variant = (road as Array).back()
		if typeof(end) != TYPE_ARRAY or (end as Array).size() < 2:
			continue
		var sign: Dictionary = route.get("sign", {}) as Dictionary
		var label := str(sign.get("label", route.get("id", "")))
		out.append({
			"display_name": label,
			"position": Vector2(float((end as Array)[0]), float((end as Array)[1])),
		})
	return out


## OF26 debug scaffolding. Moves the live player to world `(x, z)`, at
## `ground_height_at(x, z) + DEBUG_TELEPORT_CLEARANCE` — NEVER a raycast for
## ground (D09, `tools/capture_region_and_map.gd` and every other
## `ground_height_at` caller in this codebase). Refuses (returns false,
## touches nothing) with no live player, no world that answers
## `ground_height_at`, or a fight running — the pause menu already refuses to
## OPEN mid-fight (`game_menu.gd::open()`), so the combat check here is a
## second, redundant guard for whichever future caller reaches this some
## other way.
func debug_teleport_to(x: float, z: float) -> bool:
	if _debug_teleport_combat_running():
		return false
	var player := _find_player()
	if player == null:
		return false
	var world := _debug_teleport_world()
	if world == null:
		return false
	var ground: float = float(world.call("ground_height_at", x, z))
	if is_nan(ground):
		return false
	player.global_position = Vector3(x, ground + DEBUG_TELEPORT_CLEARANCE, z)
	if player is CharacterBody3D:
		(player as CharacterBody3D).velocity = Vector3.ZERO
	return true


## The world node that answers `ground_height_at` — `current_scene` itself on
## every real scene this project has (`playground_world.gd`), the same lookup
## `playground_hud.gd::_ensure_minimap_baked` and `_combat_is_running` already
## use rather than a group, since a single "the current scene" is already the
## whole answer.
func _debug_teleport_world() -> Node:
	var tree := get_tree()
	if tree == null:
		return null
	var world := tree.get_current_scene()
	if world != null and world.has_method("ground_height_at"):
		return world
	return null


## Same defensive CombatManager lookup `playground_hud.gd::_combat_is_running`
## already uses, copied rather than shared (that file is UI-owned, this is the
## autoload).
func _debug_teleport_combat_running() -> bool:
	var tree := get_tree()
	if tree == null:
		return false
	var world := tree.get_current_scene()
	if world == null:
		return false
	var combat := world.get_node_or_null(^"CombatManager")
	return combat != null and combat.has_method("is_fighting") and bool(combat.call("is_fighting"))


## Build a live creature from a species id. Party membership still goes through
## `party.add`, which is the only thing that knows about the cap.
func make_creature(species_id: String, nickname: String = "") -> RefCounted:
	return local.call("make_creature", species_id, nickname)


## Everything the party and satchel screens need to be worth looking at, and
## nothing the game would otherwise give you. Reached only via --menu-demo.
func _seed_demo() -> void:
	inventory.add("wood", 62)
	inventory.add("stone", 18)
	inventory.add("fibre", 7)
	inventory.add("berries", 33)

	var seeds := [
		["terrapup", "Biscuit"],
		["ripplet", ""],
		["galewisp", "Kite"],
	]
	for entry in seeds:
		var creature: RefCounted = make_creature(str(entry[0]), str(entry[1]))
		if creature != null:
			party.add(creature)
	# One of them is hurt, because a party screen where every bar is full cannot
	# show whether the bars work.
	var second: RefCounted = party.at(1)
	if second != null:
		second.take_damage(second.max_hp * 0.6)
