extends "res://scripts/world/player_death.gd"
## Water keeps the production downed, owned storage, map and save seams.
## Only recovery location, surface placement and aquatic teardown differ.
const SWIMMING_CONFIG := "res://data/config/water_swimming.json"
@export var satchel_surface_clearance_m := 0.15 # Visible bag above the no-diving surface.
@export var respawn_clearance_m := 1.0 # Capsule settles onto the validated dry patch.
var _swimming_rules: Dictionary = {}
var _riding: Node
var _death_in_progress := false

func build(world: Node3D, player: CharacterBody3D, spawn_position: Vector3) -> void:
	_swimming_rules = JSON.parse_string(FileAccess.get_file_as_string(SWIMMING_CONFIG))
	super.build(world, player, spawn_position)
	_recovery_camps.clear() # Water has owned landing history, not Cloudreach camps.

## Bind the existing controller once available so death restores both mount
## following and rider/camera state through its ordinary dismount seam.
func configure_riding(controller: Node) -> void:
	_riding = controller

func _on_died() -> void:
	if not _death_in_progress:
		super._on_died()

func _die_now() -> void:
	if _death_in_progress:
		return
	_death_in_progress = true
	super._die_now()

func _swim_state() -> RefCounted:
	if _player == null:
		return null
	var controller: Node = _player.get("swim_controller") as Node
	return controller.get("state") as RefCounted if controller != null else null

func _sea_level() -> float:
	var field: RefCounted = _world.get("field") as RefCounted
	return float(field.call("water_level")) if field != null else 0.0

func _safe_ground(at: Vector3) -> Vector3:
	if not at.is_finite() or _world == null or not _world.has_method("ground_height_at"):
		return Vector3(INF, INF, INF)
	var ground: float = _world.call("ground_height_at", at.x, at.z)
	var rules: Dictionary = _swimming_rules.get("safe_landing", {})
	if not is_finite(ground) or ground < _sea_level() + float(rules.get("minimum_height_m", 0.6)):
		return Vector3(INF, INF, INF)
	var radius := float(rules.get("clear_radius_m", 1.5))
	var max_slope := float(rules.get("maximum_slope_deg", 35.0))
	for offset: Vector2 in [Vector2(radius, 0), Vector2(-radius, 0), Vector2(0, radius), Vector2(0, -radius)]:
		var adjacent: float = _world.call("ground_height_at", at.x + offset.x, at.z + offset.y)
		if not is_finite(adjacent) or adjacent < _sea_level() + float(rules.get("minimum_height_m", 0.6)) or rad_to_deg(atan2(absf(adjacent - ground), radius)) > max_slope:
			return Vector3(INF, INF, INF)
	return Vector3(at.x, ground + respawn_clearance_m, at.z)

func recovery_position(game: Node, _from: Vector3) -> Vector3:
	# Same last-placed-bed preference as the base component, restricted to this
	# realm and rechecked against terrain so flooded/removed beds cannot trap us.
	var buildings: Array = game.get("placed_buildings")
	for index in range(buildings.size() - 1, -1, -1):
		if not buildings[index] is Dictionary:
			continue
		var bed: Dictionary = buildings[index]
		if not WORLD_RECORDS.belongs(bed, "water") or bool(bed.get("removed", false)) or str(bed.get("id", "")) != "bedroll":
			continue
		var raw: Array = bed.get("position", [])
		if raw.size() != 3:
			continue
		var candidate := _safe_ground(Vector3(float(raw[0]) + 2.0, float(raw[1]), float(raw[2]) + 2.0))
		if candidate.is_finite():
			return candidate
	var state := _swim_state()
	if state != null and bool(state.get("has_safe_landing")):
		var landing := _safe_ground(state.get("safe_landing"))
		if landing.is_finite():
			return landing
	var first_shore := _safe_ground(_fallback_home)
	return first_shore if first_shore.is_finite() else _fallback_home

func satchel_position(at: Vector3) -> Vector3:
	var ground: float = _world.call("ground_height_at", at.x, at.z)
	if (is_finite(ground) and ground < _sea_level()) or (not is_finite(ground) and at.y <= _sea_level()):
		at.y = _sea_level() + satchel_surface_clearance_m
	return at

func _drop_satchel(carried: Array, at: Vector3, game: Node) -> void:
	super._drop_satchel(carried, satchel_position(at), game)

func _respawn(at: Vector3) -> void:
	if is_instance_valid(_riding) and _riding.has_method("dismount"):
		_riding.call("dismount")
	elif _player.has_method("set_carrier"):
		_player.call("set_carrier", null)
	var state := _swim_state()
	if state != null:
		state.call("reach_land", Vector3(at.x, at.y - respawn_clearance_m, at.z))
		state.set("stamina_fraction", 1.0)
	var controller: Node = _player.get("swim_controller") as Node
	if controller != null:
		controller.set("_horizontal", Vector3.ZERO)
	super._respawn(at)
	_death_in_progress = false

func restore_from_game(game: Node) -> void:
	# Recover old submerged Water records vertically; X/Z and ownership remain
	# fixed. New records already store the floating position before any save.
	for entry: Variant in game.get("death_satchels"):
		if not entry is Dictionary:
			continue
		var record: Dictionary = entry
		if not WORLD_RECORDS.belongs(record, "water"):
			continue
		var raw: Array = record.get("position", [])
		if raw.size() != 3:
			continue
		var at := Vector3(float(raw[0]), float(raw[1]), float(raw[2]))
		if at.is_finite() and at.y < _sea_level() + satchel_surface_clearance_m:
			at = satchel_position(at)
			record.position = [at.x, at.y, at.z]
	super.restore_from_game(game)
