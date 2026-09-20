extends "res://scripts/combat/stormwood_authoritative_fight.gd"

## One ordinary wild fight whose host simulation outlives the host player's
## local combat presentation. EncounterDirector owns transport and ecology;
## this node owns the live body, enemy AI, combat RNG and presentation clocks.

var body_generation := 0
var presentation_seq := 1
var pose_left_s := 0.0
var cue_serial := 0
var telegraph_count := 0
var strike_count := 0
var telegraph_until_ms := 0
var terminal_outcome := ""
var catch_claimant := 0
var authority_body: Node3D
var authority_link: Node
var _catch_paused := false
var _catch_physics_was_processing := true


func start_shared(body: Node3D, target: Node3D, centre: Vector3, radius: float,
		link: Node, encounter_id: String, generation: int) -> void:
	body_generation = generation
	authority_body = body
	authority_link = link
	# Bind the inherited resolver to this adapter so peer 1 is treated exactly
	# like every remote participant. Returning local id 0 prevents its special
	# local-fallback branch from dropping the listen server's damage.
	start_opponent(body, target, centre, radius, self, encounter_id, "wild")


func local_encounter_peer_id() -> int:
	return 0


func host_pick_struck_participant(encounter_id: String, cfg: Dictionary,
		origin: Vector3, facing: Vector3) -> Dictionary:
	return authority_link.call("host_pick_struck_participant", encounter_id, cfg, origin, facing)


func host_deliver_enemy_hit(encounter_id: String, peer_id: int, payload: Dictionary) -> void:
	authority_link.call("host_deliver_enemy_hit", encounter_id, peer_id, payload)


func body() -> Node3D:
	return authority_body


func roll() -> float:
	return _rng.randf()


func pause_for_catch() -> void:
	if is_instance_valid(_wild):
		# A catch owns the body until its wobble resolves. Cancelling the current
		# wind-up is deliberate; a failed catch resumes with the normal opening
		# read instead of releasing a strike stored before the orb landed.
		_catch_physics_was_processing = _wild.is_physics_processing()
		_wild.call("set_engaged", false)
		_wild.set_physics_process(false)
		_catch_paused = true


func resume_after_catch(target: Node3D) -> void:
	if is_instance_valid(_wild) and is_instance_valid(target):
		set_target_body(target)
		_wild.call("set_engaged", true, target)
		_wild.set_physics_process(_catch_physics_was_processing)
		_catch_paused = false


func mark_terminal(outcome: String) -> bool:
	if not terminal_outcome.is_empty():
		return false
	terminal_outcome = outcome
	stop_opponent()
	return true


func stop_opponent() -> void:
	if _catch_paused and is_instance_valid(_wild):
		_wild.set_physics_process(_catch_physics_was_processing)
	_catch_paused = false
	super.stop_opponent()
