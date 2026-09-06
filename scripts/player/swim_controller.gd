extends Node

const STATE := preload("res://scripts/player/swim_state.gd")
const CONFIG_PATH := "res://data/config/water_swimming.json"
var state := STATE.new()
var _player: CharacterBody3D
var _world: Node3D
var _camera: Node3D
var _config: Dictionary
var _horizontal := Vector3.ZERO


func setup(player: CharacterBody3D, world: Node3D, camera: Node3D) -> void:
	_player = player
	_world = world
	_camera = camera
	_config = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))


func is_swimming() -> bool:
	return state.mode != STATE.Mode.LAND


func snapshot() -> Dictionary:
	return state.snapshot()


## Called by the owner rig instead of its ground integrator, never in addition
## to it. A remote trainer only displays the replicated state and transform.
func physics_step(delta: float, input_blocked: bool, combat_paused: bool) -> bool:
	if _player == null or _world == null or not bool(_world.call("shell_build_complete")):
		return false
	state.owner_peer_id = multiplayer.get_unique_id()
	var sea: float = _world.field.water_level()
	var depth: float = _world.water_depth_at(_player.global_position)
	var human: Dictionary = _config.human
	if state.mode == STATE.Mode.LAND:
		if depth < float(human.entry_depth_m) or _player.global_position.y > sea + float(human.get("entry_above_surface_m", 0.4)):
			return false
		state.enter_water(false, sea)
		_horizontal = Vector3(_player.velocity.x, 0, _player.velocity.z)
	elif depth <= float(human.exit_depth_m):
		state.leave_water()
		var ground: float = _world.ground_height_at(_player.global_position.x, _player.global_position.z)
		if is_finite(ground) and ground >= float(_config.safe_landing.minimum_height_m):
			state.reach_land(Vector3(_player.global_position.x, ground, _player.global_position.z))
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
