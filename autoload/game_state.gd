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

var _menu: CanvasLayer = null


func _ready() -> void:
	items = ITEM_DB.new()
	inventory = INVENTORY.new(items)
	party = PARTY.new()

	if OS.get_cmdline_args().has(DEMO_FLAG):
		_seed_demo()

	_mount_menu()


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
