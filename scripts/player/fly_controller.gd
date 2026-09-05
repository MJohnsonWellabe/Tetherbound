extends Node

## One collision owner: the trainer CharacterBody3D. This component replaces
## the ordinary locomotion tick while deployed; it never carries/hides it.
## World-authored AABBs are true 3D volumes, including progression restrictions.
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const CONFIG_PATH := "res://data/config/fly_traversal.json"

signal state_changed(state: String)
signal landed(position: Vector3, species_id: String)
signal recovered(reason: String)
signal denied(reason: String)

var state := "grounded"
var last_denial := ""
var config: Dictionary = {}
var updrafts: Array[Dictionary] = []
var restrictions: Array[Dictionary] = []
var safe_anchor := Vector3.INF
var safe_realm := ""
var flight_seconds := 0.0
var _player: CharacterBody3D
var _rig: Node3D
var _model: Node3D
var _game: Node
var _creature: RefCounted
var _mentor_loaner: RefCounted
var _last_flight_used_loaner := false
var _visual: Node3D
var _trial := AABB()
var _trial_enabled := false
var _saved_camera: Dictionary = {}
var _saved_snap := 0.4
var _saved_shape: Shape3D
var _saved_shape_position := Vector3.ZERO
var _grip_bones: Array = []
var _bird_skeleton: Skeleton3D
var _presentation: Dictionary = {}


func setup(player: CharacterBody3D, rig: Node3D, model: Node3D) -> void:
	_player = player
	_rig = rig
	_model = model
	_game = get_node_or_null(^"/root/Game")
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	config = raw if raw is Dictionary else {}
	if not InputMap.has_action("fly_descend"):
		InputMap.add_action("fly_descend", 0.2)
		var key := InputEventKey.new()
		key.physical_keycode = KEY_C
		InputMap.action_add_event("fly_descend", key)
		var trigger := InputEventJoypadMotion.new()
		trigger.axis = JOY_AXIS_TRIGGER_LEFT
		trigger.axis_value = 1.0
		InputMap.action_add_event("fly_descend", trigger)


func is_flying() -> bool:
	return state in ["glide", "climb", "descent", "exhausted"]


func register_updraft(id: String, bounds: AABB, lift_speed: float, ceiling_y: float, requires_flag: String = "") -> void:
	updrafts.append({"id": id, "bounds": bounds, "speed": lift_speed, "ceiling": ceiling_y, "requires_flag": requires_flag})


func register_restriction(id: String, bounds: AABB, requires_flag: String) -> void:
	restrictions.append({"id": id, "bounds": bounds, "requires_flag": requires_flag})


## The trial grants no global unlock. Leaving its volume before earning Fly is
## blocked by the same swept volume check as story gates. It is never saved.
func set_trial_authorization(bounds: AABB) -> void:
	_trial = bounds
	_trial_enabled = bounds.size.x > 0.0 and bounds.size.y > 0.0 and bounds.size.z > 0.0


func _has_flag(flag: String) -> bool:
	if flag.is_empty():
		return true
	var progression: Variant = _game.get("progression") if is_instance_valid(_game) else null
	return progression != null and bool(progression.call("has", flag))


func _unlocked() -> bool:
	return _has_flag(str(config.get("unlock_flag", "fly_traversal_unlocked")))


func _realm() -> String:
	return str(_game.get("current_realm")) if is_instance_valid(_game) else ""


## Prefer the party's existing active carrier. If a valid five-member Meadows
## team has no Fly species, Maela's transient story carrier prevents a chapter
## deadlock. It is never added to Party, saved, caught, or treated as a sixth
## owned creature.
func eligible_creature() -> RefCounted:
	var party: Variant = _game.get("party") if is_instance_valid(_game) else null
	if party != null:
		var active: RefCounted = party.call("active")
		if active != null and not bool(active.get("fainted")) and not bool(active.get("resting")) \
				and (party.call("members") as Array).has(active):
			var capability := SPECIES.fly_capability(str(active.get("species_id")))
			if bool(capability.get("can_carry", false)):
				return active
	var loaner: Dictionary = config.get("mentor_loaner", {})
	var loaner_available := (_trial_enabled and bool(loaner.get("available_during_trial", false))) \
		or (_unlocked() and bool(loaner.get("available_after_unlock", false)))
	if not loaner_available or _realm() != str(loaner.get("realm_id", "cloudreach")):
		return null
	var species_id := str(loaner.get("species_id", ""))
	if species_id.is_empty() or not bool(SPECIES.fly_capability(species_id).get("can_carry", false)):
		return null
	if _mentor_loaner == null or str(_mentor_loaner.get("species_id")) != species_id:
		_mentor_loaner = SPECIES.spawn(species_id)
	return _mentor_loaner


func last_flight_used_mentor_loaner() -> bool:
	return _last_flight_used_loaner


func can_launch() -> String:
	if _player == null or _player.is_on_floor():
		return "Jump, then press Jump again to deploy Fly."
	if bool(_player.call("is_carried")) or not bool(_player.call("locomotion_enabled")):
		return "Fly is unavailable while riding or in combat."
	if not _unlocked() and not (_trial_enabled and _trial.has_point(_player.global_position)):
		return "Complete the Windscar flight trial to unlock Fly."
	if eligible_creature() == null:
		return "No healthy Fly carrier is available here."
	if float(_player.get("vitals").get("stamina")) < float(config.get("minimum_launch_stamina", 18.0)):
		return "Rest before launching: not enough stamina."
	if safe_anchor == Vector3.INF or safe_realm != _realm():
		return "Touch down on safe ground before launching."
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = _flight_shape()
	query.transform = _player.global_transform.translated(Vector3.UP * float(config.get("collision_height_m", 4.5)) * 0.5)
	query.collision_mask = _player.collision_mask
	query.exclude = [_player.get_rid()]
	if not _player.get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty():
		return "Find a clear launch with room for your companion overhead."
	return _restricted_reason(_player.global_position, _player.global_position)


func physics_step(delta: float, input_owned: bool) -> bool:
	if not is_flying():
		if not input_owned and Input.is_action_just_pressed("jump") and not _player.is_on_floor():
			var reason := can_launch()
			if reason.is_empty():
				_launch()
			else:
				_deny(reason)
		if not is_flying():
			return false
	_player.call("begin_environment_velocity_step")
	flight_seconds += delta
	var vitals: RefCounted = _player.get("vitals")
	if eligible_creature() != _creature or float(vitals.get("stamina")) <= 0.0 or flight_seconds >= float(config.get("maximum_flight_seconds", 180.0)):
		_set_state("exhausted")
	var stick := Vector2.ZERO if input_owned else Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var view_basis := Basis.IDENTITY
	if _rig != null and _rig.has_method("planar_basis"):
		view_basis = _rig.call("planar_basis")
	var direction := view_basis * Vector3(stick.x, 0.0, stick.y)
	var horizontal := Vector3(_player.velocity.x, 0.0, _player.velocity.z)
	horizontal = horizontal.move_toward(direction * float(config.get("speed_mps", 16.0)), float(config.get("acceleration_mps2", 12.0)) * delta)
	var vertical := -float(config.get("sink_mps", 2.0))
	if state == "exhausted":
		vertical = -float(config.get("exhausted_sink_mps", 9.0))
	elif not input_owned and Input.is_action_pressed("fly_descend"):
		_set_state("descent")
		vertical = -float(config.get("descent_mps", 8.0))
	else:
		_set_state("glide")
		if not input_owned and Input.is_action_pressed("jump"):
			for draft: Dictionary in updrafts:
				var bounds: AABB = draft["bounds"]
				var ceiling := minf(float(draft["ceiling"]), bounds.end.y) - 2.0
				if bounds.has_point(_player.global_position) and _player.global_position.y < ceiling and _has_flag(str(draft["requires_flag"])):
					vertical = minf(float(draft["speed"]), float(config.get("maximum_updraft_mps", 18.0)))
					vertical = minf(vertical, maxf(0.0, (ceiling - _player.global_position.y) / maxf(delta, 0.001)))
					_set_state("climb")
					break
	_player.velocity = Vector3(horizontal.x, move_toward(_player.velocity.y, vertical, float(config.get("vertical_acceleration_mps2", 12.0)) * delta), horizontal.z)
	# A ceiling is enforced on actual velocity too, so inertia cannot drift over
	# the current's authored roof when the climb input remains held.
	if state == "climb":
		_player.velocity.y = minf(_player.velocity.y, vertical)
	var restriction := _restricted_reason(_player.global_position, _player.global_position + _player.velocity * delta)
	if not restriction.is_empty():
		_deny(restriction)
		_player.velocity.x = 0.0
		_player.velocity.z = 0.0
		_player.velocity.y = minf(_player.velocity.y, 0.0)
		if not _restricted_reason(_player.global_position, _player.global_position + _player.velocity * delta).is_empty():
			_player.velocity = Vector3.ZERO
			if recover_to_anchor(restriction):
				return true
	else:
		last_denial = ""
	var spend := float(config.get("climb_stamina_per_second", 1.6)) if state == "climb" else float(config.get("stamina_per_second", 1.0))
	vitals.call("spend_traversal", spend * delta)
	var velocity_before_environment := _player.velocity
	_player.call("apply_environment_velocity_modifiers", delta)
	# External wind cannot bypass authored swept no-fly restrictions.
	var external_restriction := "" if _player.velocity.is_equal_approx(velocity_before_environment) else _restricted_reason(_player.global_position, _player.global_position + _player.velocity * delta)
	if not external_restriction.is_empty():
		_deny(external_restriction)
		_player.velocity = Vector3.ZERO
	_player.move_and_slide()
	_player.call("finish_environment_velocity_step", not external_restriction.is_empty())
	if horizontal.length() > 0.2:
		_player.call("_face", horizontal.normalized(), delta)
	if _visual != null and _model != null:
		_visual.rotation.y = _model.rotation.y
		_pose_bird()
		_align_grip()
	if _player.is_on_floor():
		var species_id := str(_creature.get("species_id")) if _creature != null else ""
		_finish("grounded")
		observe_ground()
		landed.emit(_player.global_position, species_id)
	elif safe_anchor != Vector3.INF and _player.global_position.y < safe_anchor.y - float(config.get("recovery_drop_m", 100.0)):
		recover_to_anchor("The wind carried you back to your last safe landing.")
	return true


func _restricted_reason(from: Vector3, to: Vector3) -> String:
	var margin := float(config.get("body_clearance_m", 0.5))
	var height := float(config.get("collision_height_m", 4.5))
	if not _unlocked() and _trial_enabled and (not _trial.grow(-margin).has_point(to) or not _trial.has_point(to + Vector3.UP * height) or not _trial.has_point(from)):
		return "Stay inside the marked flight trial."
	for restriction: Dictionary in restrictions:
		if _has_flag(str(restriction["requires_flag"])):
			continue
		var box: AABB = restriction["bounds"]
		# Sweep the whole hanging silhouette, not only its feet/origin.
		box.position -= Vector3(margin, height, margin)
		box.size += Vector3(2.0 * margin, height + margin, 2.0 * margin)
		if box.has_point(from) or box.has_point(to) or box.intersects_segment(from, to) != null:
			return "This wind route is still sealed: %s." % str(restriction["id"])
	return ""


func observe_ground() -> void:
	if not is_flying() and _player.is_on_floor() and not bool(_player.call("is_carried")):
		safe_anchor = _player.global_position
		safe_realm = _realm()
		_set_state("grounded")


func set_recovery_anchor(position: Vector3, realm: String) -> bool:
	if not _player.is_on_floor() or _player.global_position.distance_to(position) > 1.0 or realm != _realm():
		return false
	safe_anchor = position
	safe_realm = realm
	return true


func _launch() -> void:
	_creature = eligible_creature()
	_last_flight_used_loaner = _creature != null and _creature == _mentor_loaner
	last_denial = ""
	flight_seconds = 0.0
	_saved_snap = _player.floor_snap_length
	_player.floor_snap_length = 0.0
	var collider := _player.get_node_or_null(^"Collision") as CollisionShape3D
	if collider != null:
		_saved_shape = collider.shape
		_saved_shape_position = collider.position
		collider.shape = _flight_shape()
		collider.position = Vector3.UP * float(config.get("collision_height_m", 4.5)) * 0.5
	_player.get("vitals").call("spend_traversal", float(config.get("launch_stamina", 8.0)))
	_set_state("glide")
	_build_visual(SPECIES.fly_capability(str(_creature.get("species_id"))))
	if _model != null and _model.has_method("set_fly_hang"):
		_model.call("set_fly_hang", true, config.get("hang_pose", {}))
	_pose_bird()
	_align_grip()
	if _rig != null and _rig.has_method("set_target"):
		_saved_camera = {"distance": _rig.get("_distance"), "height": _rig.get("_height")}
		_rig.call("set_target", _player, {"distance": config.get("camera_distance", 7.5), "height": config.get("camera_height", 2.0)})


func _finish(next: String) -> void:
	_player.floor_snap_length = _saved_snap
	var collider := _player.get_node_or_null(^"Collision") as CollisionShape3D
	if collider != null and _saved_shape != null:
		collider.shape = _saved_shape
		collider.position = _saved_shape_position
		_saved_shape = null
	if is_instance_valid(_visual):
		_visual.queue_free()
	_visual = null
	_bird_skeleton = null
	if _model != null and _model.has_method("set_fly_hang"):
		_model.call("set_fly_hang", false)
	if _rig != null and _rig.has_method("set_target"):
		_rig.call("set_target", _player, _saved_camera)
	_creature = null
	_set_state(next)


## Riding owns the next camera/collision transition. End Fly before the
## carrier saves the ground collision state, so dismount cannot retain it.
func end_for_carrier() -> void:
	if is_flying():
		_finish("grounded")


func _set_state(next: String) -> void:
	if state != next:
		state = next
		state_changed.emit(state)


func _deny(reason: String) -> void:
	if last_denial != reason:
		last_denial = reason
		denied.emit(reason)


func recover_to_anchor(reason: String) -> bool:
	if safe_anchor == Vector3.INF or safe_realm != _realm():
		return false
	# This ray is local to a previously stood-on anchor. Never ask a world's
	# highest-XZ height function: Cloudreach has bridges and stacked plateaus.
	var query := PhysicsRayQueryParameters3D.create(safe_anchor + Vector3.UP, safe_anchor + Vector3.DOWN * 2.0, _player.collision_mask, [_player.get_rid()])
	var hit := _player.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty() or (hit["normal"] as Vector3).y < cos(_player.floor_max_angle):
		return false
	_finish("recovery")
	_player.global_position = (hit["position"] as Vector3) + Vector3.UP * 0.08
	_player.velocity = Vector3.ZERO
	if _rig != null:
		_rig.global_position = _player.global_position
	recovered.emit(reason)
	return true


func save_data() -> Dictionary:
	var party: Variant = _game.get("party") if _game != null else null
	var index := -1
	if party != null:
		index = (party.call("members") as Array).find(party.call("active"))
	return {"version": 1, "mode": state, "realm": _realm(), "safe_anchor": [] if safe_anchor == Vector3.INF else [safe_anchor.x, safe_anchor.y, safe_anchor.z], "velocity": [_player.velocity.x, _player.velocity.y, _player.velocity.z], "stamina_fraction": float(_player.get("vitals").call("stamina_fraction")), "active_index": index}


func apply_pending_load() -> void:
	if _game == null or not _game.has_meta("pending_fly_load"):
		return
	var payload: Dictionary = _game.get_meta("pending_fly_load")
	if str(payload.get("realm", "")) != _realm():
		return
	_game.remove_meta("pending_fly_load")
	if is_flying():
		_finish("recovery")
	var raw: Array = payload.get("safe_anchor", [])
	if raw.size() == 3:
		safe_anchor = Vector3(float(raw[0]), float(raw[1]), float(raw[2]))
		safe_realm = _realm()
	var vitals: RefCounted = _player.get("vitals")
	vitals.set("stamina", float(vitals.get("max_stamina")) * float(payload.get("stamina_fraction", 1.0)))
	_player.velocity = Vector3.ZERO
	_set_state("recovery")


func _build_visual(capability: Dictionary) -> void:
	_presentation = capability
	var path := str(capability.get("model", ""))
	if path.is_empty() or not ResourceLoader.exists(path):
		return
	var scene := load(path) as PackedScene
	if scene == null:
		return
	_visual = Node3D.new()
	_visual.name = "FlyCompanionPresentation"
	_player.add_child(_visual)
	var art := scene.instantiate() as Node3D
	_visual.add_child(art)
	var bounds := AABB()
	var first := true
	for mesh: Node in art.find_children("*", "MeshInstance3D", true, false):
		var instance := mesh as MeshInstance3D
		var box := art.global_transform.affine_inverse() * instance.global_transform * instance.get_aabb()
		bounds = box if first else bounds.merge(box)
		first = false
	if bounds.size.y > 0.001:
		var scale_factor := float(capability.get("height_m", 2.1)) / bounds.size.y
		art.scale *= scale_factor
		art.position = -Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z) * scale_factor
	var offset: Array = capability.get("feet_offset", [0.0, 2.45, 0.0])
	_visual.position = Vector3(float(offset[0]), float(offset[1]), float(offset[2]))
	_grip_bones = capability.get("grip_bones", [])
	var skeletons := art.find_children("*", "Skeleton3D", true, false)
	_bird_skeleton = skeletons[0] as Skeleton3D if not skeletons.is_empty() else null
	for animation: Node in art.find_children("*", "AnimationPlayer", true, false):
		var player := animation as AnimationPlayer
		if bool(capability.get("procedural_wing_pose", false)):
			player.stop()
			continue
		var clip := str(capability.get("animation", "idle"))
		if player.has_animation(clip):
			player.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
			player.play(clip)


func _flight_shape() -> CapsuleShape3D:
	var shape := CapsuleShape3D.new()
	shape.radius = float(config.get("collision_radius_m", 0.7))
	shape.height = float(config.get("collision_height_m", 4.5))
	return shape


## Align actual installed leg joints with the trainer's posed wrists. Species
## can replace their art/socket names without changing movement or ownership.
func _align_grip() -> void:
	if _bird_skeleton == null or _model == null or not _model.has_method("skeleton") or _grip_bones.size() != 2:
		return
	var trainer: Skeleton3D = _model.call("skeleton")
	if trainer == null:
		return
	var hands := Vector3.ZERO
	var feet := Vector3.ZERO
	for i in 2:
		var hand := trainer.find_bone("LeftHand" if i == 0 else "RightHand")
		var foot := _bird_skeleton.find_bone(str(_grip_bones[i]))
		if hand < 0 or foot < 0:
			return
		hands += trainer.to_global(trainer.get_bone_global_pose(hand).origin) * 0.5
		feet += _bird_skeleton.to_global(_bird_skeleton.get_bone_global_pose(foot).origin) * 0.5
	_visual.global_position += hands - feet


func _pose_bird() -> void:
	if _bird_skeleton == null or not bool(_presentation.get("procedural_wing_pose", false)):
		return
	var flap := sin(flight_seconds * float(_presentation.get("wing_flap_frequency", 2.2)) * TAU) * float(_presentation.get("wing_flap_amplitude", 0.16))
	for side: String in ["l", "r"]:
		for section: String in ["upper", "fore"]:
			var bone := _bird_skeleton.find_bone("wing_%s_%s" % [section, side])
			var next := _bird_skeleton.find_bone("wing_%s_%s" % ["fore" if section == "upper" else "tip", side])
			if bone < 0 or next < 0:
				continue
			var side_sign := signf(_bird_skeleton.get_bone_global_rest(bone).origin.x)
			var parent := _bird_skeleton.get_bone_parent(bone)
			var parent_basis := _bird_skeleton.get_bone_global_pose(parent).basis if parent >= 0 else Basis.IDENTITY
			var rest := _bird_skeleton.get_bone_rest(bone).basis
			var axis := _bird_skeleton.get_bone_rest(next).origin.normalized()
			var desired := (parent_basis.inverse() * Vector3(side_sign, flap, 0.0)).normalized()
			var aim := Quaternion((rest * axis).normalized(), desired)
			_bird_skeleton.set_bone_pose_rotation(bone, aim * rest.get_rotation_quaternion())
