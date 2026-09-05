extends "res://scripts/combat/cloudreach_encounter_director.gd"

## PhysicalRuntime may rebuild the canonical cast after a relocation or reload.
## Retarget the existing challenge, never keep a freed body or spawn a duplicate.
var chapter_source: Node
var authored_yard_positions: Dictionary={}
var _population_built := false
const CHALLENGE_OFFSET := Vector3(1.5,1.05,0)


## Facing is presentation, not navigation of the two distinct interaction zones.
## The NPC root turns toward the player; inheriting that rotation made its side
## challenge circle around them and lose to the central greeting at the press.
static func sync_challenge_anchor(prompt: Node3D, body: Node3D) -> void:
	prompt.top_level = true
	prompt.global_position = challenge_anchor_at(body.global_transform)


static func challenge_anchor_at(body_transform: Transform3D) -> Vector3:
	return body_transform.origin + CHALLENGE_OFFSET


func _build_trainers() -> void:
	for placement: Dictionary in encounter_config.get("trainers", []):
		var id := str(placement.id)
		if not trainer_specs.has(id):
			continue
		var npc: Node3D = reused_npcs.get(str(placement.get("reuse_npc_id", "")))
		if npc == null:
			npc = NPC_BODY.new()
			npc.name = id
			get_parent().add_child(npc)
			npc.call("setup_from_config", NPC_MODEL.config_for(str(trainer_specs[id].config_key)), _player)
			var at := _vector3_of(trainer_specs[id].position)
			if not npc.call("stand_at", at.x, at.z, at.y):
				push_error("Cloudreach trainer has no physical floor: " + id)
				npc.queue_free()
				continue
		_mount_challenge(id,npc)
	_population_built = true


func _mount_challenge(id: String, body: Node3D) -> void:
	if authored_yard_positions.has(id):
		var at: Vector3=authored_yard_positions[id]
		body.call("stand_at",at.x,at.z,at.y)
	# Finale's explicit arena contract supersedes the older gatehouse NPC pose.
	if id == "captain_veyra_storm_anchor":
		var origin := preload("res://scripts/world/cloudreach_finale_controller.gd").vec(
			preload("res://scripts/world/cloudreach_finale_controller.gd").read_config().arena_origin)
		body.call("stand_at",origin.x,origin.z,origin.y)
	trainer_nodes[id] = body
	# add_prompt() returns the NPC's EXISTING dialogue prompt. A challenge must
	# be its own offer, otherwise Talk fires a battle and both owners toggle it.
	var prompt := preload("res://scripts/world/interactable.gd").new()
	prompt.name = "CloudreachChallenge"
	prompt.configure("Challenge %s" % trainer_specs[id].name,
		float(encounter_config.get("trainer_prompt_radius_m",4.2)),false)
	body.add_child(prompt)
	sync_challenge_anchor(prompt, body)
	prompt.connect("activated",_challenge.bind(id))
	trainer_prompts[id] = prompt


func _process(delta: float) -> void:
	if _population_built and is_instance_valid(chapter_source):
		var bodies: Dictionary = chapter_source.call("npc_bodies")
		for placement: Dictionary in encounter_config.get("trainers", []):
			var reuse := str(placement.get("reuse_npc_id", ""))
			if reuse.is_empty():
				continue
			var id := str(placement.id)
			var body: Node3D = bodies.get(reuse)
			var previous: Variant = trainer_nodes.get(id)
			if is_instance_valid(previous) and previous == body:
				continue
			var old_prompt: Variant = trainer_prompts.get(id)
			if is_instance_valid(old_prompt):
				old_prompt.queue_free()
			trainer_prompts.erase(id)
			trainer_nodes.erase(id)
			if not is_instance_valid(body) or not trainer_specs.has(id):
				continue
			_mount_challenge(id,body)
	super._process(delta)
	for id: String in trainer_prompts:
		var prompt: Node3D = trainer_prompts[id]
		var body: Node3D = trainer_nodes.get(id)
		if is_instance_valid(prompt) and is_instance_valid(body):
			sync_challenge_anchor(prompt, body)
