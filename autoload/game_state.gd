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
const PAL_INSTANCE := preload("res://scripts/pals/pal_instance.gd")

const ITEM_DB := preload("res://autoload/item_db.gd")
const INVENTORY := preload("res://autoload/inventory.gd")
const PARTY := preload("res://autoload/party.gd")
const BOOT_LOG := preload("res://scripts/boot/boot_log.gd")

## Seeds a sample party and satchel so the screens can be looked at before
## gathering and catching exist. Off in a normal run: inventing a starting kit
## would be inventing content the opening sequence owns.
const DEMO_FLAG := "--menu-demo"

var items: RefCounted = null
var inventory: RefCounted = null
var party: RefCounted = null

## In-game day, counted from 1. The release ledger and "time with you" on the
## ceremony screen both need a clock that is not wall time, and this is it.
## Nothing advances it yet; M10's day/night cycle will.
var day: int = 1

## What the build menu last armed, or an empty string. The building system reads
## this when there is one; until then it is the honest end of the build screen.
var pending_build: String = ""

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


func _ready() -> void:
	BOOT_LOG.line("Game autoload: _ready start (first autoload, before any world scene)")
	items = ITEM_DB.new()
	inventory = INVENTORY.new(items)
	party = PARTY.new()

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


func advance_day() -> int:
	day += 1
	return day


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
