extends Node

## The single place run-time state lives: the party, the satchel, the day.
##
## This is the project's first autoload, and it is meant to stay its only one.
## Before it, state was owned by whichever node happened to hold it — the fight
## owned the pals, nothing owned the inventory because there was none — and a
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
const SPECIES_PATH := "res://data/pals/species.json"
const MAP_LANDMARKS_PATH := "res://data/config/map_landmarks.json"
const PAL_INSTANCE := preload("res://scripts/pals/pal_instance.gd")

const ITEM_DB := preload("res://autoload/item_db.gd")
const INVENTORY := preload("res://autoload/inventory.gd")
const PARTY := preload("res://autoload/party.gd")
const MAP_STATE := preload("res://autoload/map_state.gd")
const BOOT_LOG := preload("res://scripts/boot/boot_log.gd")
const SAVE_GAME := preload("res://scripts/save/save_game.gd")

## Seeds a sample party and satchel so the screens can be looked at before
## gathering and catching exist. Off in a normal run: inventing a starting kit
## would be inventing content the opening sequence owns.
const DEMO_FLAG := "--menu-demo"

var items: RefCounted = null
var inventory: RefCounted = null
var party: RefCounted = null

## D33's one map database — fog-of-war, landmark discovery, dynamic markers.
## See `autoload/map_state.gd`'s own header for why there is exactly one of
## these. Configured from `data/config/map_landmarks.json` in `_ready()`, the
## same "load+parse a data file" pattern `_species()` below already uses.
var map: RefCounted = null

## What the HUD's objective pointer shows right now. A plain field, not a
## quest system — SB11's real one will replace it. `set_objective()` is the
## only writer, so a marker on `map` and this text can never disagree about
## what is currently tracked.
var objective_text: String = "Follow the road to the village"

## In-game day, counted from 1. The release ledger and "time with you" on the
## ceremony screen both need a clock that is not wall time, and this is it.
## Nothing advances it yet; M10's day/night cycle will.
var day: int = 1

## What the build menu last armed, or an empty string. The building system reads
## this when there is one; until then it is the honest end of the build screen.
var pending_build: String = ""

## R3.1. Every build piece the player has planted, as data — `{id, position:
## [x,y,z], yaw_deg}` — independent of whatever scene node currently renders
## it. This is the thing save/load actually persists; `build_placer.gd` reads
## it back to respawn the world on load and appends to it on every real
## placement. `yaw_deg` joined in the save format's VERSION 2 (see
## `scripts/save/save_game.gd`); every building placed before that defaults
## to facing 0.
var placed_buildings: Array = []

## R3.1. Save/load logic — `scripts/save/save_game.gd`. A plain RefCounted,
## same split as `party`/`inventory` above, so it is testable without a scene
## tree. See that file's header for the format and versioning rule.
var save_system: RefCounted = null

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

var _menu: CanvasLayer = null

## Throttle for fog-of-war discovery — see `_process()`. 0.5s is often enough
## that walking never outruns its own fog trail, and rare enough that this
## autoload is not doing a `get_node_or_null` tree walk every single frame.
const _DISCOVERY_INTERVAL_S := 0.5
var _discovery_elapsed: float = 0.0

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
	inventory = INVENTORY.new(items)
	party = PARTY.new()
	map = MAP_STATE.new()
	map.configure(_map_landmarks_config())
	save_system = SAVE_GAME.new()

	if OS.get_cmdline_args().has(DEMO_FLAG):
		_seed_demo()

	_mount_menu()
	# After the menu, never before: the menu shell owns the settings file and has
	# only just read it (docs/decisions/D15).
	_adopt_preferences()
	BOOT_LOG.line("Game autoload: _ready done, menu mounted")


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


## Fog-of-war discovery, throttled to `_DISCOVERY_INTERVAL_S`. Silently does
## nothing when no player can be found — a test scene, the menu-only boot
## screen, or a smoke test that instances the world without going through
## `SceneTree.change_scene_to` (and so never becomes `current_scene`) all hit
## this path, and none of them should ever see an error for it.
func _process(delta: float) -> void:
	_discovery_elapsed += delta
	if _discovery_elapsed < _DISCOVERY_INTERVAL_S:
		return
	_discovery_elapsed = 0.0
	var player := _find_player()
	if player == null:
		return
	map.mark_visited(player.global_position)


## The one Player in the running world, or null. Every existing test/tool in
## this codebase reaches the player as `world.get_node_or_null(^"Player")`
## (see e.g. `tests/smoke_playground.gd`); this is that same lookup rooted at
## `current_scene` instead of a hand-held `world` reference, since `Game` has
## none. There is no "player" group to join instead — this autoload is the
## first thing to need one, and adding a group for a single lookup site would
## be more machinery than the lookup itself.
func _find_player() -> Node3D:
	var tree := get_tree()
	if tree == null:
		return null
	var scene := tree.get_current_scene()
	if scene == null:
		return null
	return scene.get_node_or_null(^"Player") as Node3D


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


## Set (or clear) what the HUD's objective pointer shows. `world_pos` is
## optional: pass a `Vector3` to also drop a "objective" dynamic marker on
## `map` at that spot, or leave it null (the default) to track text only, or
## to clear a marker a previous objective left behind.
func set_objective(text: String, world_pos: Variant = null) -> void:
	objective_text = text
	if world_pos is Vector3:
		map.add_dynamic_marker("objective", "objective", world_pos as Vector3)
	else:
		map.remove_dynamic_marker("objective")


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
func register_building(id: String, position: Vector3, yaw_deg: float = 0.0) -> void:
	placed_buildings.append({
		"id": id,
		"position": [position.x, position.y, position.z],
		"yaw_deg": yaw_deg,
	})


## Write `slot`. Returns whether it succeeded.
func save_game(slot: int) -> bool:
	return bool(save_system.call("save", self, slot))


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
	return true


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


## Is there enough in the satchel to craft this right now?
func can_craft(id: String) -> bool:
	if items == null or inventory == null:
		return false
	if items.recipe(id).is_empty():
		return false
	for requirement in recipe_cost_for(id):
		if typeof(requirement) != TYPE_DICTIONARY:
			continue
		var entry := requirement as Dictionary
		if int(inventory.count(str(entry.get("id", "")))) < int(entry.get("n", 0)):
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
	var output: Dictionary = items.recipe(id).get("output", {})
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


func _adopt_preferences() -> void:
	var prefs := _preferences()
	if prefs == null:
		return
	var table: Dictionary = prefs.get("gameplay")
	free_build = bool(table.get(PREF_FREE_BUILD, false))


## The settings file, which the menu shell owns (docs/decisions/D15). There is
## exactly one file in user:// and this is how anything that is not a control
## gets into it.
func _preferences() -> RefCounted:
	return _menu.get("bindings") if _menu != null else null


## Build a live pal from a species id. Party membership still goes through
## `party.add`, which is the only thing that knows about the cap.
func make_pal(species_id: String, nickname: String = "") -> RefCounted:
	var definition := _species(species_id)
	if definition.is_empty():
		push_warning("unknown species: %s" % species_id)
		return null
	var pal: RefCounted = PAL_INSTANCE.from_species(species_id, definition)
	pal.nickname = nickname
	return pal


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
		var pal: RefCounted = make_pal(str(entry[0]), str(entry[1]))
		if pal != null:
			party.add(pal)
	# One of them is hurt, because a party screen where every bar is full cannot
	# show whether the bars work.
	var second: RefCounted = party.at(1)
	if second != null:
		second.take_damage(second.max_hp * 0.6)
