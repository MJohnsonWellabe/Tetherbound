extends RefCounted

## Shared fixture for lane 1.C's four save-split tests
## (`test_world_save_format`, `test_character_save_format`,
## `test_legacy_slot_split_never_touches_the_original`,
## `test_split_key_coverage_equals_v22`).
##
## `FakeGame` is `tests/test_save_format.gd`'s, plus the three things D100 asks
## a game object for and that one does not carry: `world` and `local` (the two
## id holders `save_game.gd` stamps a world id and a character id onto) and
## `is_host()` (the ownership question every autosave site asks -- see
## `session.gd`'s header for why it is that question and never
## `multiplayer.is_server()`).
##
## Everything writes under a per-test scratch directory, so a unit run can never
## leave a world or a character where a real playthrough would find it:
## `save_game.gd::_init()` puts the split directories under any non-default slot
## directory rather than in the real `user://worlds/`.

const ITEM_DB := preload("res://autoload/item_db.gd")
const INVENTORY := preload("res://autoload/inventory.gd")
const PARTY := preload("res://autoload/party.gd")
const CREATURE := preload("res://scripts/creatures/creature_instance.gd")
const MAP_STATE := preload("res://autoload/map_state.gd")
const PROGRESSION_STATE := preload("res://autoload/progression_state.gd")
const REALM_HEART_STATE := preload("res://autoload/realm_heart_state.gd")

const MAP_LANDMARKS_PATH := "res://data/config/map_landmarks.json"


## The two id holders. Real `WorldState`/`PlayerState` instances are not used
## here on purpose: this fixture must exercise `save_game.gd`'s v22 dictionary,
## which is assembled from `Game`'s own forwarding properties, and a second
## source of the same fields would let a saver that read the wrong one pass.
class IdHolder:
	extends RefCounted
	var world_id: String = ""
	var character_id: String = ""
	var display_name: String = ""


class FakeGame:
	extends RefCounted
	var day: int = 1
	var party: RefCounted = null
	var inventory: RefCounted = null
	var placed_buildings: Array = []
	var farm_plots: Array = []
	var death_satchels: Array = []
	var harvested_vegetation: Dictionary = {}
	var felled_vegetation: Dictionary = {}
	var world_seed: int = 0
	var saved_player_pose: Dictionary = {}
	var clock_elapsed_seconds: float = -1.0
	var map: RefCounted = null
	var progression: RefCounted = null
	var realm_hearts: RefCounted = null
	var current_realm: String = "meadows"
	var pending_realm_entry: String = ""
	var satiety: float = 100.0
	var world: RefCounted = null
	var local: RefCounted = null
	## Flipped to false by the "a client writes no world file" tests.
	var host: bool = true
	## realm id -> MapState, exactly as `PlayerState.maps` holds them. The real
	## `Game` has `save_realm_maps()` and `Game.map` forwards to the ACTIVE
	## realm's instance; a fake with one map and no `save_realm_maps()` would
	## send `save_game.gd` down its legacy `_realm_map_payloads()` path and hide
	## whether the split reads the right realm's map.
	var maps: Dictionary = {}

	func player_vitals() -> RefCounted:
		return null

	func is_host() -> bool:
		return host

	func save_realm_maps() -> Dictionary:
		var out: Dictionary = {}
		for realm_id: String in ["meadows", "cloudreach"]:
			var instance: Variant = maps.get(realm_id)
			out[realm_id] = (instance as RefCounted).call("save_data") if instance != null else {}
		return out

	## Stand this trainer in `realm_id`, which is both `current_realm` and which
	## map `Game.map` hands out.
	func set_realm(realm_id: String) -> void:
		current_realm = realm_id
		map = maps.get(realm_id)


static func game(db: RefCounted, seed_party: bool = true) -> RefCounted:
	var g := FakeGame.new()
	g.party = PARTY.new()
	g.inventory = INVENTORY.new(db)
	g.progression = PROGRESSION_STATE.new()
	g.realm_hearts = REALM_HEART_STATE.new()
	g.world = IdHolder.new()
	g.local = IdHolder.new()
	for realm_id: String in ["meadows", "cloudreach"]:
		var instance: RefCounted = MAP_STATE.new()
		instance.call("configure", _json(MAP_LANDMARKS_PATH))
		g.maps[realm_id] = instance
	g.set_realm("meadows")
	if seed_party:
		var creature: RefCounted = CREATURE.from_species("terrapup", {
			"display_name": "Terrapup", "type": "ground", "base_hp": 100.0,
			"base_attack": 20.0, "base_defence": 20.0,
		})
		creature.nickname = "Biscuit"
		g.party.add(creature)
	return g


## A game with something in every partitioned field, so a key that silently
## fails to cross the split shows up as a value difference and not merely as an
## absent key that happened to default the same way.
static func populated_game(db: RefCounted) -> RefCounted:
	var g := game(db)
	g.day = 7
	g.world_seed = 4242
	g.clock_elapsed_seconds = 512.5
	g.satiety = 63.5
	g.current_realm = "meadows"
	g.pending_realm_entry = "south_gate"
	g.placed_buildings = [{
		"realm": "meadows", "uid": "b1", "id": "fence",
		"position": [3.0, 0.0, -4.0], "yaw_deg": 90.0, "paid": true,
	}]
	g.farm_plots = [{"state": "sown", "crop": "sunberry", "sown_day": 3}]
	g.death_satchels = [{
		"realm": "meadows", "owner": "", "position": [1.0, 2.0, 3.0], "state": [],
	}]
	g.harvested_vegetation = {"meadows": ["tree_11", "rock_4"]}
	g.felled_vegetation = {"meadows": ["tree_11"]}
	g.saved_player_pose = {
		"realm": "meadows", "position": [12.0, 1.0, -30.0],
		"model_yaw": 0.5, "camera_yaw": 0.25, "camera_pitch": -0.1,
	}
	g.inventory.add("wood", 12)
	# One world-scope flag and one player-scope flag, so the split key has
	# something to put on each side of the line.
	g.progression.set_flag("defeated_warden")
	g.progression.set_flag("tam_tools_given")
	# A different cell per realm, so a merge that handed back the wrong realm's
	# map would produce a DIFFERENT dictionary rather than an equal one.
	(g.maps["meadows"] as RefCounted).call("mark_visited", Vector3(10.0, 0.0, 10.0))
	(g.maps["cloudreach"] as RefCounted).call("mark_visited", Vector3(-60.0, 0.0, 25.0))
	return g


static func _json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if typeof(parsed) == TYPE_DICTIONARY else {}


## Remove a scratch tree completely -- files, then the directories the split
## savers created under it. `DirAccess.remove_absolute` refuses a non-empty
## directory, so this recurses depth first.
static func wipe(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		var child := path + ("" if path.ends_with("/") else "/") + name
		if dir.current_is_dir():
			wipe(child + "/")
		else:
			DirAccess.remove_absolute(child)
		name = dir.get_next()
	dir.list_dir_end()
	DirAccess.remove_absolute(path)
