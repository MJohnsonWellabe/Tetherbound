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
var _pending_mount_owner: RefCounted
var _pending_mount_character := ""
var _mount_restore_generation := 0
var _mount_restore_busy := false


func setup(player: CharacterBody3D, world: Node3D, camera: Node3D) -> void:
	_player = player
	_world = world
	_camera = camera
	_config = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))


func is_swimming() -> bool:
	return state.mode != STATE.Mode.LAND


func snapshot() -> Dictionary:
	var result := state.snapshot()
	var riding := _world.get_node_or_null("RidingController") if _world != null else null
	result.ripplet_diving = riding != null and riding.has_method("dive_save") and bool(riding.diving)
	return result


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
			saved.mount = {"party_index": index, "creature_uid": str(director.ally_instance().uid), "species_id": str(body.species_id),
				"position": [body.global_position.x, body.global_position.y, body.global_position.z]}
			if riding.has_method("dive_save"):
				var dive: Dictionary = riding.dive_save()
				if not dive.is_empty(): saved.mount.dive = dive
	return saved


func restore_save_data(raw: Dictionary) -> bool:
	var clean := SAVE.sanitise(raw)
	print("F37 AQUATIC RESTORE " + JSON.stringify({"accepted": not clean.is_empty(),
		"payload_mount": raw.has("mount"), "clean_mount": clean.has("mount")}))
	if clean.is_empty():
		return false
	# A later accepted pose supersedes queued and in-flight reconstruction,
	# including a pose without a mount. Rejected data leaves the live restore.
	_mount_restore_generation += 1
	_pending_mount.clear()
	_pending_mount_owner = null
	_pending_mount_character = ""
	# Slot loads can reuse the current world. Detach the old carrier before
	# reconstructing the saved one, without replacing the just-loaded pose.
	var riding := _world.get_node_or_null("RidingController")
	if riding != null and riding.has_method("cancel_traversal_requests"):
		riding.cancel_traversal_requests()
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
	var had_mount := clean.has("mount")
	_refuse_closed_seal_placement(clean)
	print("F37 AQUATIC PLACEMENT " + JSON.stringify({"mount_before_seal": had_mount,
		"mount_after_seal": clean.has("mount"), "dead": vitals.is_dead()}))
	if _world.water_depth_at(_player.global_position) >= float(_config.human.entry_depth_m):
		state.enter_water(false, _world.field.water_level())
		_player.global_position.y = state.surface_y + float(_config.human.surface_body_offset_m)
	state.stamina_fraction = float(clean.stamina_fraction)
	state.drowning = state.mode == STATE.Mode.HUMAN and vitals.stamina <= 0.0
	_horizontal = Vector3.ZERO
	if clean.has("mount") and not vitals.is_dead():
		_pending_mount = clean.duplicate(true)
		_pending_mount_owner = get_node("/root/Game").local
		_pending_mount_character = str(_pending_mount_owner.character_id)
		_restore_mount.call_deferred()
	if vitals.is_dead():
		_player.call_deferred("emit_signal", "died")
	return true


## F12: the saved pose and mount live on the portable character, so a load or
## join into a world whose dock facts are missing could restore them behind a
## closed tide race. Such a mount stays in the party unsummoned, and the player
## goes to this world's recovery point (bed, reachable safe landing, First
## Shore). The saved safe anchor is left as restored; recovery skips it while
## its landform is sealed and trusts it again once the dock opens.
func _refuse_closed_seal_placement(clean: Dictionary) -> void:
	var recovery := _world.get_node_or_null("PlayerDeath")
	if recovery == null or not recovery.has_method("closed_seal_at"):
		return
	var game := get_node_or_null("/root/Game")
	if clean.has("mount"):
		var raw: Array = clean.mount.position
		if not recovery.closed_seal_at(game, Vector3(float(raw[0]), float(raw[1]), float(raw[2]))).is_empty():
			clean.erase("mount")
	if recovery.closed_seal_at(game, _player.global_position).is_empty():
		return
	clean.erase("mount")
	_player.global_position = recovery.recovery_position(game, _player.global_position)
	_player.velocity = Vector3.ZERO
	if _camera != null:
		_camera.global_position = _player.global_position


func _restore_mount() -> void:
	if _pending_mount.is_empty() or _mount_restore_busy:
		return
	_mount_restore_busy = true
	var generation := _mount_restore_generation
	var owner := _pending_mount_owner
	var current := _mount_restore_current.bind(generation, owner, _pending_mount_character)
	var director := _world.get_node_or_null("EncounterDirector")
	var restored := false
	var mount_save: Dictionary = _pending_mount.mount.duplicate(true)
	if director != null and current.call():
		restored = await director.restore_swim_mount(mount_save, current)
	print("F37 MOUNT RECONSTRUCTION " + JSON.stringify({"director_present": director != null,
		"restored": restored, "uid": mount_save.get("creature_uid", ""),
		"superseded": not current.call()}))
	_mount_restore_busy = false
	if not current.call():
		if generation == _mount_restore_generation:
			_pending_mount.clear()
			_pending_mount_owner = null
			_pending_mount_character = ""
		elif not _pending_mount.is_empty(): _restore_mount.call_deferred()
		return
	_pending_mount.clear()
	_pending_mount_owner = null
	_pending_mount_character = ""
	if restored and _world.water_depth_at(_player.global_position) >= float(_config.human.entry_depth_m):
		state.enter_water(true, _world.field.water_level())
		state.stamina_fraction = director.ally_instance().swim_stamina_fraction
		state.drowning = state.stamina_fraction <= 0.0
		var riding := _world.get_node_or_null("RidingController")
		if mount_save.has("dive") and riding != null and riding.has_method("restore_dive"):
			riding.restore_dive(mount_save.dive)


func _mount_restore_current(generation: int, owner: RefCounted, character: String) -> bool:
	var game := get_node_or_null("/root/Game")
	return generation == _mount_restore_generation and is_inside_tree() \
		and is_instance_valid(_world) and _world.is_inside_tree() and not _world.is_queued_for_deletion() \
		and is_instance_valid(_player) and not _player.is_queued_for_deletion() and _world.is_ancestor_of(_player) \
		and game != null and owner != null and game.local == owner and str(owner.character_id) == character


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
	# Only a live ride may publish MOUNTED. However control came back to the
	# trainer (shallow dismount, fainted mount, load), an unmounted swimmer is
	# a human swimmer; remote peers draw the ride and saves record it from this.
	if state.mode == STATE.Mode.MOUNTED and not _is_riding():
		state.enter_water(false, sea)
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
	var equipment := _hazard_equipment()
	if equipment != null: flow = equipment.current_push(flow) # F33#3: trainer gear eases the current.
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
	var drowning := float(change.health_lost)
	if equipment != null: drowning = equipment.mitigate_hazard_damage(drowning, "drowning")
	vitals.health = maxf(0.0, vitals.health - drowning)
	if alive and vitals.is_dead():
		_player.emit_signal("died")
	return true


## F33#3: the trainer's worn equipment, only while hazard mitigation is live.
func _hazard_equipment() -> RefCounted:
	if not preload("res://scripts/player/player_equipment.gd").hazards_live(): return null
	var game := get_node_or_null("/root/Game")
	return game.get("player_equipment") if game != null else null


func _is_riding() -> bool:
	var riding := _world.get_node_or_null("RidingController")
	return riding != null and bool(riding.call("is_mounted"))


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
