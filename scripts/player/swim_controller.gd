extends Node

const STATE := preload("res://scripts/player/swim_state.gd")
const CONFIG_PATH := "res://data/config/water_swimming.json"
const SAVE := preload("res://scripts/save/water_traversal_save.gd")
var state := STATE.new()
var _player: CharacterBody3D
var _world: Node3D
var _camera: Node3D
var _config: Dictionary
var _horizontal := Vector3.ZERO
var _pending_mount: Dictionary = {}


func setup(player: CharacterBody3D, world: Node3D, camera: Node3D) -> void:
	_player = player
	_world = world
	_camera = camera
	_config = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))


func is_swimming() -> bool:
	return state.mode != STATE.Mode.LAND


func snapshot() -> Dictionary:
	return state.snapshot()


func save_data() -> Dictionary:
	if not _pending_mount.is_empty():
		return _pending_mount.duplicate(true)
	var vitals: RefCounted = _player.get("vitals")
	var anchor: Array = [state.safe_landing.x, state.safe_landing.y, state.safe_landing.z] if state.has_safe_landing else []
	var saved := {"version": 1, "mode": state.mode, "safe_anchor": anchor,
		"stamina_fraction": clampf(vitals.stamina / vitals.max_stamina, 0.0, 1.0),
		"health_fraction": clampf(vitals.health / vitals.max_health, 0.0, 1.0)}
	var riding := _world.get_node_or_null("RidingController")
	var director := _world.get_node_or_null("EncounterDirector")
	if riding != null and riding.is_mounted() and director != null:
		var party: RefCounted = get_node("/root/Game").party
		var index: int = party.members().find(director.ally_instance())
		var body: Node3D = riding.mount_body()
		if index >= 0:
			saved.mount = {"party_index": index, "species_id": str(body.species_id),
				"position": [body.global_position.x, body.global_position.y, body.global_position.z]}
	return saved


func restore_save_data(raw: Dictionary) -> bool:
	var clean := SAVE.sanitise(raw)
	if clean.is_empty():
		return false
	# Slot loads can reuse the current world. Detach the old carrier before
	# reconstructing the saved one, without replacing the just-loaded pose.
	var riding := _world.get_node_or_null("RidingController")
	if riding != null and riding.is_mounted():
		var saved_position := _player.global_position
		riding.dismount()
		_player.global_position = saved_position
	var vitals: RefCounted = _player.get("vitals")
	vitals.stamina = vitals.max_stamina * float(clean.stamina_fraction)
	vitals.health = vitals.max_health * float(clean.health_fraction)
	state.owner_peer_id = int(get_node("/root/Game").session.local_peer_id())
	state.leave_water()
	state.has_safe_landing = false
	var anchor: Array = clean.safe_anchor
	if anchor.size() == 3:
		var at := Vector3(float(anchor[0]), float(anchor[1]), float(anchor[2]))
		var ground: float = _world.ground_height_at(at.x, at.z)
		if is_finite(ground) and ground >= float(_config.safe_landing.minimum_height_m):
			state.reach_land(Vector3(at.x, ground, at.z))
	if _world.water_depth_at(_player.global_position) >= float(_config.human.entry_depth_m):
		state.enter_water(false, _world.field.water_level())
		_player.global_position.y = state.surface_y + float(_config.human.surface_body_offset_m)
	state.stamina_fraction = float(clean.stamina_fraction)
	state.drowning = state.mode == STATE.Mode.HUMAN and vitals.stamina <= 0.0
	_horizontal = Vector3.ZERO
	if clean.has("mount") and not vitals.is_dead():
		_pending_mount = clean.duplicate(true)
		_restore_mount.call_deferred()
	if vitals.is_dead():
		_player.call_deferred("emit_signal", "died")
	return true


func _restore_mount() -> void:
	if _pending_mount.is_empty():
		return
	var director := _world.get_node_or_null("EncounterDirector")
	var restored := false
	if director != null:
		restored = await director.restore_swim_mount(_pending_mount.mount)
	_pending_mount.clear()
	if restored and _world.water_depth_at(_player.global_position) >= float(_config.human.entry_depth_m):
		state.enter_water(true, _world.field.water_level())
		state.stamina_fraction = director.ally_instance().swim_stamina_fraction
		state.drowning = state.stamina_fraction <= 0.0


## Called by the owner rig instead of its ground integrator, never in addition
## to it. A remote trainer only displays the replicated state and transform.
func physics_step(delta: float, input_blocked: bool, combat_paused: bool) -> bool:
	if not _pending_mount.is_empty():
		_player.velocity = Vector3.ZERO
		return true
	if _player == null or _world == null or not bool(_world.call("shell_build_complete")):
		return false
	state.owner_peer_id = int(get_node("/root/Game").session.local_peer_id())
	var sea: float = _world.field.water_level()
	var depth: float = _world.water_depth_at(_player.global_position)
	var human: Dictionary = _config.human
	if state.mode == STATE.Mode.LAND:
		_record_safe_landing()
		if depth < float(human.entry_depth_m) or _player.global_position.y > sea + float(human.get("entry_above_surface_m", 0.4)):
			return false
		state.enter_water(false, sea)
		_horizontal = Vector3(_player.velocity.x, 0, _player.velocity.z)
	elif depth <= float(human.exit_depth_m):
		state.leave_water()
		return false
	if combat_paused:
		state.pause_for_combat()
	elif state.mode == STATE.Mode.COMBAT_PAUSED:
		state.resume_after_combat(false)
	var input := Vector2.ZERO if input_blocked or combat_paused else Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := Vector3.ZERO
	if input != Vector2.ZERO and _camera != null:
		var basis: Basis = _camera.call("planar_basis")
		direction = (basis * Vector3(input.x, 0, input.y)).normalized()
	var speed := float(human.speed_m_s)
	_horizontal = _horizontal.move_toward(direction * speed, float(human.acceleration_m_s2) * delta)
	var flow: Vector3 = Vector3.ZERO if combat_paused else _world.current_at(_player.global_position)
	_player.velocity = _horizontal + flow
	_player.velocity.y = (sea + float(human.surface_body_offset_m) - _player.global_position.y) * float(human.vertical_follow_rate)
	var before := _player.global_position
	_player.move_and_slide()
	var activity: RefCounted = _player.get("_skills_activity")
	if activity != null:
		activity.record_movement("swimming", _player.global_position - before - flow * delta, direction, delta, speed,
			input_blocked or combat_paused)
	if direction != Vector3.ZERO:
		_player.call("_face", direction, delta)
	var vitals: RefCounted = _player.get("vitals")
	var efficiency := 1.0
	var game := get_node_or_null("/root/Game")
	if game != null:
		var local: RefCounted = game.get("local")
		var skills: RefCounted = local.get("skills") if local != null else null
		if skills != null:
			efficiency = skills.efficiency("swimming")
	var change: Dictionary = state.advance(state.owner_peer_id, delta, vitals.stamina, vitals.max_stamina,
		float(human.stamina_drain_per_s), float(human.drowning_damage_per_s), efficiency)
	if float(change.stamina_spent) > 0.0:
		vitals.spend_traversal(float(change.stamina_spent))
	var alive: bool = not vitals.is_dead()
	vitals.health = maxf(0.0, vitals.health - float(change.health_lost))
	if alive and vitals.is_dead():
		_player.emit_signal("died")
	return true


## Leaving the swim depth can still be underwater. Earn recovery only after
## the real capsule settles beside an authored, dry landing on baked terrain.
func _record_safe_landing() -> void:
	if not _player.is_on_floor():
		return
	for anchor: Dictionary in _world.config.get("anchors", []):
		var raw: Array = anchor.get("safe_position", [])
		if raw.size() != 3:
			continue
		var at := Vector3(float(raw[0]), float(raw[1]), float(raw[2]))
		if Vector2(at.x - _player.global_position.x, at.z - _player.global_position.z).length() > float(anchor.get("safe_radius_m", 3.0)):
			continue
		var ground: float = _world.ground_height_at(at.x, at.z)
		if not is_finite(ground) or ground < float(_config.safe_landing.minimum_height_m):
			continue
		at.y = ground
		if absf(_player.global_position.y - at.y) > float(_config.safe_landing.get("maximum_anchor_height_difference_m", 1.5)):
			continue
		if not state.has_safe_landing or not state.safe_landing.is_equal_approx(at):
			state.reach_land(at)
		return
