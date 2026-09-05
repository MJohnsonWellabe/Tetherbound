extends Node3D

## GAME_DESIGN.md §22, Player Death: on death, everything carried drops into
## a satchel at the death location, the player respawns healed at home, and
## nothing else is lost — no XP, no level (there is no XP/level system yet,
## Phase 4, so there is nothing to lose there), and the party is never
## touched. Old death satchels never move once dropped and several can
## coexist — see death_satchel.gd, which this spawns fresh, once per death.
##
## Wired the same way player_bed.gd/world_perimeter.gd are: a small component
## `playground_world.gd` builds and hands the player node to, rather than
## logic living inside the world script itself.

const DEATH_SATCHEL := preload("res://scripts/world/death_satchel.gd")
const WORLD_RECORDS := preload("res://scripts/world/realm_world_records.gd")

const FADE_SECONDS := 1.2
const MAP_ICON := "death_satchel"

## R3.2. This component's own group — mirrors `build_placer.gd` joining
## `"build_placer"`, and is how `GameState.save_game`/`load_game` reach
## `sync_state_to_game`/`restore_from_game` below without a direct handle on
## whichever world scene happens to be live.
const GROUP := "player_death"

## Which entry in `GameState.death_satchels` a given live satchel node is —
## the same role `build_placer.gd`'s `PLACED_INDEX_META` plays for a placed
## building's index into `placed_buildings`.
const SATCHEL_INDEX_META := "death_satchel_index"

var _world: Node3D = null
var _player: CharacterBody3D = null
var _fallback_home: Vector3 = Vector3.ZERO
var _satchel_count: int = 0
var _recovery_camps: Array = []
var _recovery_ground: Callable = Callable()


## World may inject already-resolved authored camps, or the canonical chapter
## camps plus a nearest-elevation ground callback (Vector3 -> float or Vector3).
## No checkpoint is earned here; each camp's real prerequisite remains binding.
func configure_recovery(camps: Array, ground_resolver: Callable = Callable()) -> void:
	_recovery_camps = camps.duplicate(true)
	_recovery_ground = ground_resolver


## `world` is where satchels get parented — the same level everything else
## `_build_settlement()` builds into. `spawn_position` is the opening's own
## drop point (`playground_world.gd::_place_player()`), the respawn point
## until the player has built a camp.
func build(world: Node3D, player: CharacterBody3D, spawn_position: Vector3) -> void:
	_world = world
	_player = player
	_fallback_home = spawn_position
	if _recovery_camps.is_empty():
		var chapter: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/cloudreach_chapter.json"))
		_recovery_camps = chapter.get("camping_contract", {}).get("camps", [])
	if not _recovery_ground.is_valid() and world.has_method("ground_height_near"):
		_recovery_ground = Callable(world, "ground_height_near")
	add_to_group(GROUP)
	if player.has_signal("died"):
		player.connect("died", _on_died)


func _on_died() -> void:
	var game := get_node_or_null(^"/root/Game")
	if game == null:
		return

	var carried: Array = []
	var bag: RefCounted = game.get("inventory")
	if bag != null:
		carried = bag.call("drain")
	if not carried.is_empty():
		_drop_satchel(carried, _player.global_position, game)

	var respawn_at := recovery_position(game, _player.global_position)
	_fade_and_respawn(respawn_at)


func recovery_position(game: Node, from: Vector3) -> Vector3:
	var realm := WORLD_RECORDS.active(game)
	var fallback := _fallback_home
	if realm == "cloudreach":
		fallback = resolve_safe_camp(_recovery_camps, game.get("progression"), from,
			_fallback_home, _recovery_ground)
	return resolve_home(game.get("placed_buildings"), fallback, realm)


static func resolve_safe_camp(camps: Array, flags: RefCounted, from: Vector3,
		fallback: Vector3, ground_resolver: Callable = Callable()) -> Vector3:
	var nearest := fallback
	var distance := INF
	for camp: Dictionary in camps:
		var required := str(camp.get("requires_flag", ""))
		if not required.is_empty() and (flags == null or not flags.call("has", required)):
			continue
		var raw: Array = camp.get("position", [])
		if raw.size() != 3:
			continue
		var at := Vector3(float(raw[0]), float(raw[1]), float(raw[2]))
		var authored_y := at.y
		# Keep the respawn capsule beside, rather than inside, the camp furniture.
		at += Vector3(2, 0, 2)
		if ground_resolver.is_valid():
			var resolved: Variant = ground_resolver.call(at)
			if resolved is Vector3:
				at = resolved
			elif typeof(resolved) in [TYPE_FLOAT, TYPE_INT]:
				at.y = float(resolved)
			else:
				continue
		if not at.is_finite() or absf(at.y - authored_y) > 8.0:
			continue
		var candidate_distance := from.distance_squared_to(at)
		if candidate_distance < distance:
			distance = candidate_distance
			nearest = at + Vector3.UP
	return nearest


func _drop_satchel(carried: Array, at: Vector3, game: Node) -> void:
	# R3.2. Register the persisted record FIRST, so the live node can carry
	# its own index into `GameState.death_satchels` from the moment it
	# exists — the same order `build_placer.gd::_place()` uses (compute the
	# index the entry is about to occupy, then spawn).
	var index := int(game.call("register_death_satchel", at))

	var satchel: Node3D = DEATH_SATCHEL.new()
	_satchel_count += 1
	satchel.name = "DeathSatchel_%d" % _satchel_count
	satchel.position = at
	satchel.set_meta(SATCHEL_INDEX_META, index)
	satchel.set_meta("realm", WORLD_RECORDS.active(game))
	_world.add_child(satchel)
	satchel.call("build", carried, game.get("items"))
	# Capture immediately, not only at the next scene/save synchronization.
	(game.get("death_satchels") as Array)[index]["state"] = satchel.get("state").call("save_data")

	var map: RefCounted = game.get("map")
	if map != null:
		map.call("add_dynamic_marker", "death_satchel_%d" % (index + 1), MAP_ICON, at)


## R3.2. The reverse of `restore_from_game`'s `state` half: called by
## `GameState.save_game` right before it writes, so every live satchel's
## CURRENT contents (opened, withdrawn from, deposited into since the last
## save) land in the record a save actually persists — the exact same "ask
## the scene tree right before writing" seam `build_placer
## .gd::sync_state_to_game` already uses for a placed chest.
func sync_state_to_game(game: Node) -> void:
	if game == null:
		return
	var satchels: Array = game.get("death_satchels") as Array
	for node in get_tree().get_nodes_in_group(DEATH_SATCHEL.GROUP):
		var index := int(node.get_meta(SATCHEL_INDEX_META, -1))
		if index < 0 or index >= satchels.size():
			continue
		if not WORLD_RECORDS.belongs(satchels[index], WORLD_RECORDS.active(game)) \
				or str(node.get_meta("realm", "meadows")) != WORLD_RECORDS.active(game):
			continue
		var state: RefCounted = node.get("state")
		if state == null:
			continue
		(satchels[index] as Dictionary)["state"] = state.call("save_data")


## R3.2. Rebuild every satchel `GameState.death_satchels` remembers — called
## by `GameState.load_game`, mirroring `build_placer.gd::restore_from_game`.
## Existing satchels are cleared first so a mid-session load cannot leave two
## copies of the same satchel standing on top of each other. Deliberately
## does not touch the map's dynamic markers: `MapState.save_data`/
## `load_data` already round-trip `death_satchel_N` markers on their own
## (`autoload/map_state.gd`), so re-adding them here would just be a second,
## redundant writer.
func restore_from_game(game: Node) -> void:
	if game == null or _world == null:
		return
	for node in get_tree().get_nodes_in_group(DEATH_SATCHEL.GROUP):
		if not _world.is_ancestor_of(node):
			continue
		node.get_parent().remove_child(node)
		node.queue_free()

	var satchels: Array = game.get("death_satchels") as Array
	var db: RefCounted = game.get("items")
	_satchel_count = 0
	for i in satchels.size():
		var entry: Variant = satchels[i]
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var record := entry as Dictionary
		if not WORLD_RECORDS.belongs(record, WORLD_RECORDS.active(game)):
			continue
		var position: Array = record.get("position", [])
		if position.size() != 3:
			continue
		var at := Vector3(float(position[0]), float(position[1]), float(position[2]))

		var satchel: Node3D = DEATH_SATCHEL.new()
		_satchel_count += 1
		satchel.name = "DeathSatchel_%d" % _satchel_count
		satchel.position = at
		satchel.set_meta(SATCHEL_INDEX_META, i)
		satchel.set_meta("realm", WORLD_RECORDS.active(game))
		_world.add_child(satchel)
		satchel.call("restore", record.get("state", []), db)


## The last-placed bedroll, or the world's own opening spawn point if none
## has been built yet — the bedroll is already this project's one placed
## rest point (player_bed.gd), and §22 does not name a different "home."
## OWNER-0902-CAMP-SPLIT: used to search for the bundled `camp` id; the
## bedroll is the specific piece that carries the rest interaction now that
## tent/campfire/bedroll place independently. A static, dependency-free
## function so this is testable headless, no node required.
static func resolve_home(buildings: Variant, fallback: Vector3, realm: String = "meadows") -> Vector3:
	if not buildings is Array:
		return fallback
	var list: Array = buildings
	for i in range(list.size() - 1, -1, -1):
		if not list[i] is Dictionary:
			continue
		var entry: Dictionary = list[i]
		if not WORLD_RECORDS.belongs(entry, realm) or bool(entry.get("removed", false)):
			continue
		if str(entry.get("id", "")) != "bedroll":
			continue
		var pos: Array = entry.get("position", [])
		if pos.size() >= 3:
			var at := Vector3(float(pos[0]), float(pos[1]), float(pos[2]))
			if at.is_finite():
				return at
	return fallback


## The same fade-out/act/fade-in shape player_bed.gd's own rest uses, built
## here rather than shared: the bedroll's version also advances the day and
## autosaves, neither of which belongs to a death.
func _fade_and_respawn(at: Vector3) -> void:
	if _player.has_method("set_locomotion_enabled"):
		_player.call("set_locomotion_enabled", false)

	var layer := CanvasLayer.new()
	layer.layer = 15
	var rect := ColorRect.new()
	rect.color = Color(0, 0, 0, 0)
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(rect)
	_world.add_child(layer)

	var tween := create_tween()
	tween.tween_property(rect, "color:a", 1.0, FADE_SECONDS * 0.5)
	tween.tween_callback(func() -> void: _respawn(at))
	tween.tween_interval(0.4)
	tween.tween_property(rect, "color:a", 0.0, FADE_SECONDS * 0.5)
	tween.tween_callback(layer.queue_free)


func _respawn(at: Vector3) -> void:
	var fly := _player.get_node_or_null("FlyController")
	if fly != null and fly.has_method("end_for_carrier"):
		fly.call("end_for_carrier")
	_player.velocity = Vector3.ZERO
	_player.global_position = at
	var vitals: RefCounted = _player.get("vitals")
	if vitals != null and vitals.has_method("rest"):
		vitals.call("rest")
	if _player.has_method("set_locomotion_enabled"):
		_player.call("set_locomotion_enabled", true)
