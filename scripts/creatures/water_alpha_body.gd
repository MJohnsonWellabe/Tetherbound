extends "res://scripts/creatures/wild_creature.gd"

## The authority chooses Aquaryn's movement and attacks. Other peers animate
## received movement without integrating another copy of the encounter.
var authority_node: Node
var _phase_id := ""

func _physics_process(delta: float) -> void:
	if authority_node == null:
		return
	if not authority_node.is_alpha_authority():
		if _animator != null:
			_animator.tick(delta, Vector2(velocity.x, velocity.z).length(), _speed)
		return
	var target: Node3D = authority_node.target_body()
	if target != null and authority_node.is_fight_active():
		if not engaged:
			set_engaged(true, target)
		_opponent = target
	elif engaged:
		set_engaged(false)
	super._physics_process(delta)

func _tick_peaceful(_delta: float) -> void:
	request_move(Vector3.ZERO, 0.0)

func _tick_combat(delta: float) -> void:
	var phase: Dictionary = authority_node.phase_definition()
	if _phase_id != str(phase.id):
		_phase_id = str(phase.id)
		combat_override = {
			"telegraph": float(phase.telegraph_s),
			"recovery": float(phase.recovery_s),
			"attack_cooldown": float(phase.cooldown_s),
			"range": float(phase.reach_m),
			"preferred_range": float(phase.reach_m) * float(authority_node.rules.movement.preferred_reach_fraction),
			"cone_degrees": float(phase.cone_degrees),
			"power": float(MATH.config().get("enemy", {}).get("power", 8.0)) * float(phase.power_multiplier)
		}
		refresh_combat_profile()
	var destination: Vector3 = authority_node.surface_run_target()
	if destination.is_finite():
		var offset := destination - global_position
		offset.y = 0.0
		if offset.length() <= float(authority_node.rules.movement.waypoint_reach_m):
			authority_node.reach_surface_waypoint()
		else:
			face_towards(destination)
			request_move(offset.normalized(), float(authority_node.rules.movement.surface_speed_m_s))
		return
	super._tick_combat(delta)

func apply_surface_velocity(actor: CharacterBody3D, _delta: float) -> void:
	if authority_node == null or not authority_node.is_alpha_authority():
		return
	var world: Node3D = authority_node.world
	var swimming: Dictionary = authority_node.swimming_rules.human
	if world.water_depth_at(actor.global_position) < float(swimming.entry_depth_m):
		return
	var offset := float(SPECIES.definition(species_id).get("water_mount_geometry", {}).get("surface_origin_offset_m", -0.65))
	actor.velocity.y = (world.field.water_level() + offset - actor.global_position.y) * float(swimming.vertical_follow_rate)
