extends Node

## Adds buoyancy/current velocity to the existing owner creature integrator.
## The body still slides and animates once per frame; peers display its packet.
const STATE := preload("res://scripts/player/swim_state.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
var state := STATE.new()
var world: Node3D
var riding: Node
var director: Node
var body: CharacterBody3D
var _instance: RefCounted
var _rules: Dictionary
var _species: Dictionary
var _last_position := Vector3.ZERO

func setup(owner_world: Node3D, riding_controller: Node, encounter: Node) -> void:
	world = owner_world
	riding = riding_controller
	director = encounter
	_rules = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_swimming.json"))

func _physics_process(_delta: float) -> void:
	if world == null or world.simulation_only:
		return
	var current: CharacterBody3D = director.ally_body()
	if current == body and is_instance_valid(body):
		return
	if is_instance_valid(body):
		body.clear_environment_velocity_modifier(&"water_buoyancy")
		body.remove_meta("water_aquatic")
	body = current
	state = STATE.new()
	if body == null:
		return
	_species = SPECIES.definition(str(body.species_id)).get("swim_mount", {})
	if not bool(_species.get("compatible", false)):
		body = null
		return
	_instance = director.ally_instance()
	_last_position = body.global_position
	body.register_environment_velocity_modifier(&"water_buoyancy", self, _apply_buoyancy, 100, Vector3(1, 0, 1))

func _apply_buoyancy(actor: CharacterBody3D, delta: float) -> void:
	if _instance == null or not is_instance_valid(riding):
		return
	state.owner_peer_id = int(get_node("/root/Game").session.local_peer_id())
	var depth: float = world.water_depth_at(actor.global_position)
	var mounted: bool = riding.is_mounted() and riding.mount_body() == actor
	var player := world.local_rig() as CharacterBody3D
	var human: Node = player.swim_controller
	var fighting: bool = world.get_node("CombatManager").is_fighting() or director.trainer_battle_active()
	if depth <= float(_rules.human.exit_depth_m):
		if state.mode != STATE.Mode.LAND:
			state.leave_water()
		if mounted and human.state.mode != STATE.Mode.LAND:
			human.state.leave_water()
		if actor.is_on_floor() and not fighting and world.ground_height_at(actor.global_position.x, actor.global_position.z) >= float(_rules.safe_landing.minimum_height_m):
			_instance.swim_stamina_fraction = minf(1.0, _instance.swim_stamina_fraction + float(_rules.mount.land_recovery_per_s) * delta / float(_species.stamina_capacity))
		if not is_equal_approx(state.stamina_fraction, _instance.swim_stamina_fraction):
			state.stamina_fraction = _instance.swim_stamina_fraction
			state.revision += 1
		actor.set_meta("water_aquatic", state.snapshot())
		_last_position = actor.global_position
		return
	if depth < float(_rules.human.entry_depth_m) and state.mode == STATE.Mode.LAND:
		return
	var desired := STATE.Mode.MOUNTED if mounted else STATE.Mode.HUMAN
	if state.mode == STATE.Mode.COMBAT_PAUSED and not fighting:
		state.resume_after_combat(mounted)
	if state.mode != desired and not fighting:
		state.enter_water(mounted, world.field.water_level())
	if fighting:
		state.pause_for_combat()
	var flow: Vector3 = Vector3.ZERO if fighting else world.current_at(actor.global_position)
	actor.velocity += flow
	var origin := float(SPECIES.definition(str(actor.species_id)).get("water_mount_geometry", {}).get("surface_origin_offset_m", -0.7))
	actor.velocity.y = (world.field.water_level() + origin - actor.global_position.y) * float(_rules.human.vertical_follow_rate)
	if mounted:
		if human.state.mode != STATE.Mode.MOUNTED and not fighting:
			human.state.enter_water(true, world.field.water_level())
		var game := get_node("/root/Game")
		var change := state.advance(state.owner_peer_id, delta,
			_instance.swim_stamina_fraction * float(_species.stamina_capacity), float(_species.stamina_capacity),
			float(_species.stamina_drain_per_s), float(_rules.mount.drowning_damage_per_s), game.local.skills.efficiency("swimming"))
		_instance.swim_stamina_fraction = maxf(0.0, _instance.swim_stamina_fraction - float(change.stamina_spent) / float(_species.stamina_capacity))
		human.state.stamina_fraction = state.stamina_fraction
		human.state.drowning = state.drowning
		human.state.revision += 1
		if _instance.take_damage(float(change.health_lost)):
			riding.call_deferred("dismount")
		var activity: RefCounted = player.get("_skills_activity")
		var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		var direction := Vector3(input.x, 0, input.y)
		var camera: Node = player.get("_camera_rig")
		if camera != null and camera.has_method("planar_basis"):
			direction = (camera.call("planar_basis") as Basis) * direction
		if activity != null:
			activity.record_movement("swimming", actor.global_position - _last_position - flow * delta,
				direction, delta, float(_species.speed_mps), fighting)
	actor.set_meta("water_aquatic", state.snapshot())
	_last_position = actor.global_position
