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
const SPECIES_PATH := "res://data/creatures/species.json"
const MAP_LANDMARKS_PATH := "res://data/config/map_landmarks.json"
const CREATURE_INSTANCE := preload("res://scripts/creatures/creature_instance.gd")
const CREATURE_PROGRESSION := preload("res://scripts/creatures/progression.gd")

const ITEM_DB := preload("res://autoload/item_db.gd")
const INVENTORY := preload("res://autoload/inventory.gd")
const PARTY := preload("res://autoload/party.gd")
const MAP_STATE := preload("res://autoload/map_state.gd")
const PROGRESSION_STATE := preload("res://autoload/progression_state.gd")
const PLAYER_EQUIPMENT := preload("res://scripts/player/player_equipment.gd")
const QUEST_LOG := preload("res://scripts/world/quest_log.gd")
const BOOT_LOG := preload("res://scripts/boot/boot_log.gd")
const SAVE_GAME := preload("res://scripts/save/save_game.gd")
## R7.6. Only for `fresh()`/`sanitised()` — the shape of a farm bed is that
## file's business, and this autoload should not carry a second opinion about
## what a valid plot dictionary looks like.
const FARM_LOGIC := preload("res://scripts/world/farm_logic.gd")

## Seeds a sample party and satchel so the screens can be looked at before
## gathering and catching exist. Off in a normal run: inventing a starting kit
## would be inventing content the opening sequence owns.
const DEMO_FLAG := "--menu-demo"

var items: RefCounted = null
var inventory: RefCounted = null
var party: RefCounted = null

## R7.7. The trainer's five armour slots (scripts/player/player_equipment.gd)
## -- reachable the same way `equipped_tool` is (a plain autoload field), and
## deliberately NOT persisted through save_game.gd, matching `equipped_tool`'s
## own precedent: it resets each session and the player re-equips, the same
## as re-picking a tool off the hotbar.
var player_equipment: RefCounted = null

## D33's one map database — fog-of-war, landmark discovery, dynamic markers.
## See `autoload/map_state.gd`'s own header for why there is exactly one of
## these. Configured from `data/config/map_landmarks.json` in `_ready()`, the
## same "load+parse a data file" pattern `_species()` below already uses.
var map: RefCounted = null

## SB9. The flag store behind objective/completion/world-state tracking —
## see `autoload/progression_state.gd`'s own header for the full contract.
## Instantiated in `_ready()`, same as `map` above.
var progression: RefCounted = null

## SB11. Reads `progression`'s flags against `data/progression/objectives.json`
## to answer "what is the one tracked Main Story line" and "what does the
## two-list quest log show" — see its own header. Instantiated in `_ready()`,
## same as `map`/`progression` above.
var quest_log: RefCounted = null

## What the HUD's objective pointer shows right now. Kept in step with
## `progression`'s flags by `_process()` below (recomputed only when
## `progression.revision` actually moves, the same polling idiom that file's
## own header describes) — never guessed at or scripted by hand, except
## through `set_objective()`, which stays available for a caller that wants
## to show something `data/progression/objectives.json` does not (a capture
## tool posing a demo objective, e.g.) and sticks until the next real flag
## change recomputes it.
var objective_text: String = ""

## `progression.revision` last seen by `_process()` — see `objective_text`'s
## own comment.
var _last_progression_revision: int = -1

## In-game day, counted from 1. The release ledger and "time with you" on the
## ceremony screen both need a clock that is not wall time, and this is it.
## Nothing advances it yet; M10's day/night cycle will.
var day: int = 1

## What the build menu last armed, or an empty string. The building system reads
## this when there is one; until then it is the honest end of the build screen.
var pending_build: String = ""

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
var pending_catch: RefCounted = null

## R3.1. Every build piece the player has planted, as data — `{id, position:
## [x,y,z], yaw_deg}` — independent of whatever scene node currently renders
## it. This is the thing save/load actually persists; `build_placer.gd` reads
## it back to respawn the world on load and appends to it on every real
## placement. `yaw_deg` joined in the save format's VERSION 2 (see
## `scripts/save/save_game.gd`); every building placed before that defaults
## to facing 0.
var placed_buildings: Array = []

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
var farm_plots: Array = []

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
## `HOTBAR_KINDS_REFUSED` is the material rule, applied at assignment time.
var hotbar: Array[String] = ["", "", "", "", ""]

## Item kinds that may never occupy an action slot. `resource` is wood/stone/
## fiber and `currency` is coins: things you spend from the satchel or that a
## shop reads, never things you press a button to use.
const HOTBAR_KINDS_REFUSED := ["resource", "currency"]
const HOTBAR_SLOTS := 5

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
var equipped_tool: String = ""

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
var death_satchels: Array = []

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
var harvested_vegetation: Dictionary = {}

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
var felled_vegetation: Dictionary = {}

## RG7. The last captured player/world pose. Transform data stays OUT of the
## ordinary long-lived gameplay state; this dictionary is only the save/load
## seam so a slot can return the trainer to the exact place and view it wrote.
## Shape: {position:[x,y,z], model_yaw, camera_yaw, camera_pitch}.
var saved_player_pose: Dictionary = {}

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
	return _find_player()


## Fallback satiety, read/written by `save_game.gd` ONLY when no live
## `PlayerVitals` is reachable through `player_vitals()` below — a running
## game always has one, since the project's single main scene always carries
## a `Player`, so in practice this is exercised by headless callers (tests,
## a save/load invoked before the world scene exists) rather than by real
## play. See `save_game.gd`'s header for the full seam this backs.
var satiety: float = 100.0

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

var _menu: CanvasLayer = null

## Throttle for fog-of-war discovery — see `_process()`. 0.5s is often enough
## that walking never outruns its own fog trail, and rare enough that this
## autoload is not doing a `get_node_or_null` tree walk every single frame.
const _DISCOVERY_INTERVAL_S := 0.5
var _discovery_elapsed: float = 0.0

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


func _ready() -> void:
	BOOT_LOG.line("Game autoload: _ready start (first autoload, before any world scene)")
	items = ITEM_DB.new()
	save_system = SAVE_GAME.new()
	reset_for_new_game()

	if OS.get_cmdline_args().has(DEMO_FLAG):
		_seed_demo()

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
	inventory = INVENTORY.new(items)
	party = PARTY.new()
	player_equipment = PLAYER_EQUIPMENT.new()
	player_equipment.call("configure", items)
	map = MAP_STATE.new()
	map.configure(_map_landmarks_config())
	progression = PROGRESSION_STATE.new()
	quest_log = QUEST_LOG.new()
	objective_text = quest_log.call("tracked_text", progression)
	_last_progression_revision = int(progression.get("revision"))

	day = 1
	pending_build = ""
	_pending_world_message = ""
	pending_catch = null
	placed_buildings = []
	farm_plots = []
	hotbar = ["", "", "", "", ""]
	equipped_tool = ""
	death_satchels = []
	harvested_vegetation = {}
	felled_vegetation = {}
	saved_player_pose = {}
	satiety = 100.0
	_discovery_elapsed = 0.0
	_autosave_elapsed = 0.0


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


func advance_day() -> int:
	day += 1
	return day


## R7.6. The state of farm bed `index`, or a fresh fallow one.
##
## Grows `farm_plots` on demand rather than requiring anyone to size it up
## front: a save written when `data/config/farm.json` listed four beds is
## loaded by a build that lists six, and the two new beds should read as
## unworked ground rather than as an out-of-range error. Same forgiving shape
## `_array_to_inventory` already gives a satchel that changed size.
func farm_plot_at(index: int) -> Dictionary:
	if index < 0:
		return FARM_LOGIC.fresh()
	if index >= farm_plots.size():
		return FARM_LOGIC.fresh()
	return FARM_LOGIC.sanitised(farm_plots[index])


func set_farm_plot(index: int, plot: Dictionary) -> void:
	if index < 0:
		return
	while farm_plots.size() <= index:
		farm_plots.append(FARM_LOGIC.fresh())
	farm_plots[index] = FARM_LOGIC.sanitised(plot)


## PT-23 fallback autosave. Separate from the rest of `_process()` so a test
## can drive it in isolation without also standing up `progression`/
## `quest_log`/etc. the way a full `_process()` tick would demand -- see
## `tests/test_autosave_fallback.gd`.
func _tick_autosave(delta: float) -> void:
	_autosave_elapsed += delta
	if _autosave_elapsed < _AUTOSAVE_FALLBACK_INTERVAL_S:
		return
	_autosave_elapsed = 0.0
	save_game(autosave_slot())


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
		for member: Variant in (party.call("members") as Array):
			(member as RefCounted).call("tick_buffs", delta)
	var progression_revision: int = int(progression.get("revision"))
	if progression_revision != _last_progression_revision:
		_last_progression_revision = progression_revision
		objective_text = quest_log.call("tracked_text", progression)

	_discovery_elapsed += delta
	if _discovery_elapsed < _DISCOVERY_INTERVAL_S:
		return
	_discovery_elapsed = 0.0
	var player := _find_player()
	if player == null:
		return
	map.mark_visited(player.global_position)
	map.update_region(player.global_position)


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
	if world_pos is Vector3:
		map.add_dynamic_marker("objective", "objective", world_pos as Vector3)
	else:
		map.remove_dynamic_marker("objective")


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


# --- creature-bed recovery (Gate A) -----------------------------------------

func _tick_creature_bed_recovery(delta: float) -> void:
	if party == null or delta <= 0.0:
		return
	var cfg := CREATURE_PROGRESSION.config()
	var seconds := maxf(float(cfg.get("creature_bed", {}).get("full_heal_seconds", 120.0)), 1.0)
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
	var rest_xp := CREATURE_PROGRESSION.rest_xp(cfg)
	var rest_bond := CREATURE_PROGRESSION.rest_bond(cfg)
	var completed := 0
	for i in party.call("size"):
		var creature: RefCounted = party.call("at", i)
		if creature == null or not bool(creature.get("resting")):
			continue
		creature.call("heal_fully")
		creature.set("rested", true)
		creature.set("resting", false)
		creature.set("rest_bed_index", -1)
		if rest_xp > 0:
			creature.call("gain_xp", rest_xp, cfg)
		if rest_bond > 0:
			creature.call("gain_bond", rest_bond, cfg)
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
	placed_buildings.append({
		"id": id,
		"position": [position.x, position.y, position.z],
		"yaw_deg": yaw_deg,
		# BUILD-REMOVE: Free Build placements must not become a material faucet.
		# Missing on legacy saves means paid (the only pre-Free-Build economy).
		"paid": paid,
	})


## R3.2. `player_death.gd::_drop_satchel` calls this once, right before it
## spawns the live satchel node — the registry, not the scene node, is what a
## save actually persists, same split `register_building` draws above.
## Returns the new entry's index, which the caller stashes as node metadata
## so `sync_state_to_game`/`restore_from_game` can find their way back to it
## without a position-based search (the same role `PLACED_INDEX_META` plays
## for a placed building).
func register_death_satchel(position: Vector3) -> int:
	death_satchels.append({
		"position": [position.x, position.y, position.z],
		"state": [],
	})
	return death_satchels.size() - 1


## --- the hotbar ------------------------------------------------------------
##
## See `hotbar`'s own comment for why these are item ids and not satchel
## indices. Everything here is pure bookkeeping over that array; the HUD owns
## drawing it and resolving an id to a live stack.

## Whether `item_id` is allowed in an action slot at all. Unknown ids are
## refused rather than allowed: a slot naming something `items.json` has never
## heard of can only ever draw blank and refuse on press.
func hotbar_can_hold(item_id: String) -> bool:
	if item_id.is_empty():
		return false
	var definition := items.call("definition", item_id) as Dictionary
	if definition.is_empty():
		return false
	return not HOTBAR_KINDS_REFUSED.has(str(items.call("kind", item_id)))


## Put `item_id` on `slot`. Passing "" clears the slot. Returns false (and
## changes nothing) for an out-of-range slot or a refused kind, so a caller can
## tell the player exactly why rather than silently doing nothing.
##
## Assigning an item that already sits on another slot MOVES it rather than
## duplicating it: two slots holding the same id would both draw the same count
## and both spend from the same stack, which reads as a bug the first time a
## player presses the one they think is a spare.
func assign_hotbar(slot: int, item_id: String) -> bool:
	if slot < 0 or slot >= HOTBAR_SLOTS:
		return false
	if item_id.is_empty():
		hotbar[slot] = ""
		return true
	if not hotbar_can_hold(item_id):
		return false
	for i in HOTBAR_SLOTS:
		if hotbar[i] == item_id:
			hotbar[i] = ""
	hotbar[slot] = item_id
	return true


## The slot `item_id` occupies, or -1. Lets the backpack mark which of its
## tiles are already bound without duplicating the search.
func hotbar_slot_of(item_id: String) -> int:
	if item_id.is_empty():
		return -1
	return hotbar.find(item_id)


## Fill any empty slots from what the satchel is actually carrying, in bag
## order, skipping refused kinds and anything already bound.
##
## Two callers, one reason: a brand new game (so the pack Grandpa hands over
## lands on the bar instead of leaving it blank), and a save written before the
## bar existed (`save_game.gd::_migrate_v6`) — where the honest reconstruction
## of "the hotbar mirrored satchel slots 0-4" is "the first few usable things
## you were carrying", minus the wood and stone that used to clog it.
func autofill_hotbar() -> void:
	for slot in HOTBAR_SLOTS:
		if not hotbar[slot].is_empty():
			continue
		for index in int(inventory.get("SLOT_COUNT")):
			var stack: Dictionary = inventory.call("stack_at", index)
			if stack.is_empty():
				continue
			var id := str(stack.get("id", ""))
			if not hotbar_can_hold(id) or hotbar.has(id):
				continue
			hotbar[slot] = id
			break


## Write `slot`. Returns whether it succeeded.
func save_game(slot: int) -> bool:
	_capture_player_pose()
	_sync_placed_building_state()
	_sync_death_satchel_state()
	_sync_harvest_state()
	return bool(save_system.call("save", self, slot))


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
	# Mid-session loads can apply immediately. A title-screen load has no Player
	# yet; player_controller.gd calls apply_loaded_player_pose() from _ready(), so
	# the same saved dictionary is applied once the world exists.
	apply_loaded_player_pose()
	return true


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
		"position": [player.global_position.x, player.global_position.y, player.global_position.z],
		"model_yaw": facing,
		"camera_yaw": float(rig.get("yaw")) if rig != null else facing,
		"camera_pitch": float(rig.get("pitch")) if rig != null else 0.0,
	}


## Apply a loaded pose if both the data and Player exist. False is the normal
## pre-world/title-screen case, not an error; Player._ready retries it.
func apply_loaded_player_pose() -> bool:
	if saved_player_pose.is_empty():
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
	return true


func _finite_number(value: Variant) -> bool:
	return (typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT) and is_finite(float(value))


## The slot `camp.gd` writes to on every rest. Exposed here rather than left
## as a magic `0` at the one call site that needs it.
func autosave_slot() -> int:
	return int(SAVE_GAME.AUTOSAVE_SLOT)


func has_save(slot: int) -> bool:
	return bool(save_system.call("has_slot", slot))


func save_slot_info(slot: int) -> Dictionary:
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
## empty for an unknown recipe. Unlike `build_cost_for`, free build does NOT
## waive this: free build is documented and scoped to building material costs
## (docs/decisions/D16), and silently extending it to crafting would be
## growing a development toggle into a second cheat nobody asked for.
func recipe_cost_for(id: String) -> Array:
	if items == null:
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


func _adopt_preferences() -> void:
	var prefs := _preferences()
	if prefs == null:
		return
	var table: Dictionary = prefs.get("gameplay")
	free_build = bool(table.get(PREF_FREE_BUILD, false))
	debug_teleport = bool(table.get(PREF_DEBUG_TELEPORT, false))


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
	var definition := _species(species_id)
	if definition.is_empty():
		push_warning("unknown species: %s" % species_id)
		return null
	var creature: RefCounted = CREATURE_INSTANCE.from_species(species_id, definition)
	creature.nickname = nickname
	return creature


## The parsed contents of `data/config/map_landmarks.json`, or `{}` if it is
## missing or malformed — `MapState.configure()` already treats an empty
## config as "no landmarks, default tuning", so there is nothing extra to
## guard here.
func _map_landmarks_config() -> Dictionary:
	var file := FileAccess.open(MAP_LANDMARKS_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if typeof(parsed) == TYPE_DICTIONARY else {}


func _species(species_id: String) -> Dictionary:
	var file := FileAccess.open(SPECIES_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	var table: Variant = (parsed as Dictionary).get("species", {})
	if typeof(table) != TYPE_DICTIONARY:
		return {}
	var entry: Variant = (table as Dictionary).get(species_id, {})
	return entry as Dictionary if typeof(entry) == TYPE_DICTIONARY else {}


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
