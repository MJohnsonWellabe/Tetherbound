extends "res://scripts/world/riding_controller.gd"
const STATE := preload("res://scripts/player/swim_state.gd")
var water_world: Node3D
const RIPPLET := preload("res://scripts/player/ripplet_traversal.gd")
var diving := false
var dive_remaining_s := 0.0
var _ripplet_approved := false
var _ripplet_requesting := false
var _ripplet_hint_shown := false

func mount() -> bool:
	var candidate := _mountable_body()
	if candidate != null and str(candidate.species_id) == "ripplet" and not _ripplet_approved:
		if not _ripplet_requesting:
			_ripplet_requesting = true
			water_world.get_node("RippletWaterService").request("mount", str(_encounter.ally_instance().uid))
		return is_mounted()
	return super.mount()

func apply_ripplet_action(action: String, uid: String) -> void:
	_ripplet_requesting = false
	if _encounter.ally_instance() == null or str(_encounter.ally_instance().uid) != uid: return
	if action == "mount":
		_ripplet_approved = true
		var attached := super.mount()
		_ripplet_approved = false
		if attached and not _ripplet_hint_shown:
			_ripplet_hint_shown = true
			get_node("/root/Game").push_world_message("Ripplet swims across currents. Tap Jump to Dive or surface after its L30 breakthrough.")
	elif action == "dive" and is_mounted() and not diving and _is_in_water() and _riding_allowed():
		if not RIPPLET.can_dive(RIPPLET.local_record(get_node("/root/Game")), uid): return
		diving = true
		dive_remaining_s = float(RIPPLET.config().dive_seconds)
		if has_meta("restored_dive_budget") and get_meta("restored_dive_uid", "") == uid:
			dive_remaining_s = minf(dive_remaining_s, float(get_meta("restored_dive_budget")))
			remove_meta("restored_dive_budget")
			remove_meta("restored_dive_uid")
		get_node("/root/Game").push_world_message("Ripplet is diving. Tap Jump to surface.")
	elif action == "surface":
		surface()

func surface() -> void:
	if diving:
		get_node("/root/Game").push_world_message("Ripplet has surfaced.")
	diving = false
	dive_remaining_s = 0.0

func dive_save() -> Dictionary:
	if diving: return {"remaining_s":dive_remaining_s}
	if is_mounted() and _encounter.ally_instance() != null and get_meta("restored_dive_uid", "") == str(_encounter.ally_instance().uid) and has_meta("restored_dive_budget"):
		return {"remaining_s":float(get_meta("restored_dive_budget"))}
	return {}

func restore_dive(saved: Dictionary) -> void:
	# Restore mounted at the surface, with no stamina refund. A fresh tap starts
	# another dive; the saved underwater pose never seats a reconnect in rock.
	# Keep the previous timer as a ceiling for that next tap, preventing reload
	# from refreshing a nearly-expired dive.
	if not saved.is_empty() and _encounter.ally_instance() != null:
		set_meta("restored_dive_budget", float(saved.remaining_s))
		set_meta("restored_dive_uid", str(_encounter.ally_instance().uid))

func interaction_offer(from: Vector3) -> Dictionary:
	var offer := super.interaction_offer(from)
	# A sunken find owns Interact nearby. Dismount remains available elsewhere;
	# Jump always surfaces, using the existing input action without a hold.
	if diving and is_mounted(): offer.priority = -2
	return offer

func _is_in_water() -> bool:
	return water_world != null and is_mounted() and water_world.water_depth_at(mount_body().global_position) >= 0.9

func ride_speed_now() -> float:
	if _is_in_water():
		if str(mount_body().species_id) == "ripplet":
			return RIPPLET.route_speed(mount_body().global_position, diving)
		return float(SPECIES.definition(str(mount_body().species_id)).get("swim_mount", {}).get("speed_mps", 0.0))
	return super.ride_speed_now()

func _physics_process(delta: float) -> void:
	if not is_mounted() or not _riding_allowed(): surface()
	if is_mounted() and str(mount_body().species_id) == "ripplet" and _is_in_water():
		if diving:
			dive_remaining_s -= delta
			if dive_remaining_s <= 0.0 or _encounter.ally_instance().swim_stamina_fraction <= 0.0 \
				or water_world.water_depth_at(mount_body().global_position) < float(RIPPLET.config().minimum_dive_depth_m): surface()
		if INPUT_OWNER.current(get_tree()) == null and Input.is_action_just_pressed("jump") and not _ripplet_requesting:
			_ripplet_requesting = true
			water_world.get_node("RippletWaterService").request("surface" if diving else "dive", str(_encounter.ally_instance().uid))
	if _is_in_water():
		_jump_cooldown_left = maxf(_jump_cooldown_left, delta * 2.0)
	if is_mounted() and _riding_allowed() and INPUT_OWNER.current(get_tree()) != null:
		mount_body().request_move(Vector3.ZERO, 0.0)
		return
	super._physics_process(delta)

func dismount() -> bool:
	surface()
	var result := super.dismount()
	if result and water_world != null and _player != null:
		var depth: float = water_world.water_depth_at(_player.global_position)
		var swim: Node = _player.swim_controller
		var config: Dictionary = swim.get("_config")
		if depth >= float(config.human.entry_depth_m):
			_player.global_position.y = water_world.field.water_level() + float(config.human.surface_body_offset_m)
			swim.state.enter_water(false, water_world.field.water_level())
		elif swim.state.mode == STATE.Mode.MOUNTED:
			# Between the exit and entry depths the trainer keeps swimming as a
			# human until the next landing; at wading depth they stand. Either
			# way the ride's state must end with the ride.
			if depth > float(config.human.exit_depth_m):
				swim.state.enter_water(false, water_world.field.water_level())
			else:
				swim.state.leave_water()
	return result
