extends "res://scripts/world/riding_controller.gd"
const STATE := preload("res://scripts/player/swim_state.gd")
var water_world: Node3D

func _is_in_water() -> bool:
	return water_world != null and is_mounted() and water_world.water_depth_at(mount_body().global_position) >= 0.9

func ride_speed_now() -> float:
	if _is_in_water():
		return float(SPECIES.definition(str(mount_body().species_id)).get("swim_mount", {}).get("speed_mps", 0.0))
	return super.ride_speed_now()

func _physics_process(delta: float) -> void:
	if _is_in_water():
		_jump_cooldown_left = maxf(_jump_cooldown_left, delta * 2.0)
	if is_mounted() and _riding_allowed() and INPUT_OWNER.current(get_tree()) != null:
		mount_body().request_move(Vector3.ZERO, 0.0)
		return
	super._physics_process(delta)

func dismount() -> bool:
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
