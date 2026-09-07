extends "res://scripts/world/trainer_npc.gd"

const CATALOGUE := preload("res://scripts/combat/stormwood_encounter_catalogue.gd")
const DIALOGUE := preload("res://scripts/story/dialogue_runner.gd")
var authored_specs: Dictionary = {}

func build_authored(player: Node3D) -> void:
	_player = player
	for spec: Dictionary in CATALOGUE.trainer_specs():
		spec["defeat_flag"] = "stormwood:trainer:%s:defeated" % spec.id
		spec["rechallenge"] = false
		spec["challenge"] = "stormwood_trainer_%s_challenge" % spec.id
		spec["defeated"] = "stormwood_trainer_%s_defeated" % spec.id
		DIALOGUE.table()[spec.challenge] = {"speaker": spec.name,
			"lines": ["Keep your team close. These woods test how well you work together.", "Show me what they can do."]}
		DIALOGUE.table()[spec.defeated] = {"speaker": spec.name,
			"lines": ["A good battle. Rest your team before you press on."]}
		authored_specs[str(spec.id)] = spec
		_spawn(spec)
		if str(spec.get("surface_id", "")) == "dynamo_core":
			var body := body_for(str(spec.id))
			var at: Vector3 = spec.get("source_position3D", Vector3.INF)
			if body != null and at.is_finite():
				body.global_position = at
	_watch_the_dialogue_panel()
	print("STORMWOOD TRAINERS READY count=", placed())

func _refresh_prompts(progression: RefCounted) -> void:
	for id: String in authored_specs:
		var body := body_for(id)
		if body == null:
			continue
		var prompt := body.call("prompt_node") as Node3D
		if prompt != null:
			prompt.set("label", prompt_for(authored_specs[id], progression))
