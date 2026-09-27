extends Node

## Scene adapter: dialogue and arrival actions use the existing host-led chapter
## event transport. The catalogue never grants progression merely by loading.
const EVENTS := preload("res://scripts/world/realm_chapter_events.gd")
const PEOPLE := preload("res://scripts/world/village_npcs.gd")
const RUNNER := preload("res://scripts/story/dialogue_runner.gd")
const PIMS_PARCELS := preload("res://scripts/world/stormwood_pims_parcels.gd")
const GLASS_FOR_BRYN := preload("res://scripts/world/stormwood_glass_for_bryn.gd")
const CROWN_GUARDIAN_CLEAR_FLAG := "stormwood:named:crown_guardian:cleared"
const WEN_REFUSAL_CONVERSATION := "stormwood_archivist_wen_guardian_refusal"
const WEN_RECORDS_RETURN_CONVERSATION := "stormwood_wen_crown_records_return"
const ENGINE_TRUTH_FLAG := "stormwood:engine_truth_learned"
const HESK_DARK_ARCHES_REPORT := "stormwood_hesk_dark_arches_report"
const ONDRA_ROAD_REPORT := "stormwood_ondra_raise_a_road_report"
var world: Node3D
var events: Node
var people: Node3D
var chapter: Dictionary
var _panel: Node
var _parcels: Node3D
var _glass_for_bryn: Node3D
var _local := false
var _arrival_check_left := 0.0
var _circuit_replay_revision := -1
const DIALOGUE_EVENTS := {
	"rodkeeper_hesk": "dialogue:hesk_long_storm",
	"warden_elect_bryn": "dialogue:bryn_shattered_road",
	"keeper_ondra": "dialogue:ondra_arch_recipe",
	"archivist_wen": "dialogue:wen_truth",
	"defector_sable": "dialogue:sable_captive",
}
const STORY_CONVERSATION_GATES := {
	"warden_elect_bryn": "stormwood:rodline_linked",
	"keeper_ondra": "stormwood:varga_defeated",
	"archivist_wen": CROWN_GUARDIAN_CLEAR_FLAG,
	"defector_sable": "stormwood:lantern_hollow_reached",
}
const ARRIVALS := [
	{"at": [-350, 450], "above_ground": 0, "flag": "stormwood:chapter_started", "event": "arrival:ashfoot"},
	{"at": [-450, 3960], "above_ground": 0, "flag": "stormwood:lantern_hollow_reached", "event": "arrival:lantern_hollow"},
	{"at": [-120, 5270], "above_ground": 0, "flag": "stormwood:ember_bivouac_reached", "event": "arrival:ember_bivouac"},
	{"at": [-100, 5470], "above_ground": 150, "flag": "stormwood:core_reached", "event": "arrival:dynamo_core"},
]

func mount(owner_world: Node3D) -> void:
	world = owner_world
	chapter = _read("res://data/config/stormwood_chapter.json")
	events = EVENTS.new()
	events.name = "Events"
	events.realm_id = "stormwood"
	events.chapter = chapter
	add_child(events)
	_local = not bool(world.get("simulation_only"))
	# Register this realm's authored conversations without changing another
	# chapter's ids or introducing a separate dialogue implementation.
	var conversations: Dictionary = _read("res://data/dialogue/stormwood.json").get("conversations", {})
	for id: String in conversations:
		RUNNER.table()[id] = conversations[id].duplicate(true)
	RUNNER.table()[WEN_REFUSAL_CONVERSATION] = wen_refusal_conversation()
	people = PEOPLE.new()
	people.name = "StormwoodPeople"
	world.add_child(people)
	var specs: Array = []
	for actor: Dictionary in _read("res://data/config/stormwood_npcs.json").get("characters", []):
		specs.append(npc_spec(actor))
	people.build_specs(world.get_node("Player"), specs)
	_parcels = PIMS_PARCELS.new()
	_parcels.name = "PimsParcels"
	world.add_child(_parcels)
	_parcels.call("mount", world)
	_glass_for_bryn = GLASS_FOR_BRYN.new()
	_glass_for_bryn.name = "GlassForBryn"
	world.add_child(_glass_for_bryn)
	_glass_for_bryn.call("mount", world)
	# A core NPC stands on the authored arena, not the terrain far below it.
	for actor: Dictionary in _read("res://data/config/stormwood_npcs.json").get("characters", []):
		if str(actor.get("surface_id", "")) == "dynamo_core":
			var body := people.get_node_or_null(NodePath(str(actor.name))) as Node3D
			if body != null:
				body.global_position = Vector3(float(actor.position[0]), float(actor.position[1]), float(actor.position[2]))
	if not _local:
		people.visible = false
		set_process(false)
		return
	_panel = world.get_node("DialoguePanel")
	_panel.finished.connect(_dialogue_finished)

func _process(delta: float) -> void:
	if not _local or not is_instance_valid(world):
		return
	_replay_circuit_wins_after_progression_change()
	_arrival_check_left -= delta
	if _arrival_check_left > 0:
		return
	_arrival_check_left = 0.25
	var player := world.get_node("Player") as Node3D
	var game := get_node("/root/Game")
	for arrival: Dictionary in ARRIVALS:
		if game.get("progression").has(str(arrival.flag)):
			continue
		var x := float(arrival.at[0])
		var z := float(arrival.at[1])
		var offset := player.global_position - Vector3(x, world.ground_height_at(x, z) + float(arrival.above_ground), z)
		if Vector2(offset.x, offset.z).length() < 30.0 and absf(offset.y) < 5.0:
			events.emit_event(str(arrival.event))

func _dialogue_finished(id: String) -> void:
	if _parcels != null and bool(_parcels.call("dialogue_finished", id, self)):
		return
	if id == "stormwood_rook_circuit_offer":
		events.emit_event("side:stormwood_deepwood_circuit:step_1")
		_replay_circuit_wins_after_progression_change(true)
		return
	if id == "stormwood_rook_circuit_return":
		events.emit_event("side:stormwood_deepwood_circuit:step_3")
		return
	if id == WEN_RECORDS_RETURN_CONVERSATION:
		events.emit_event("side:stormwood_crown_remembers:step_3")
		return
	if id == HESK_DARK_ARCHES_REPORT:
		events.emit_event("side:stormwood_dark_arches:step_3")
		return
	if id == ONDRA_ROAD_REPORT:
		events.emit_event("side:stormwood_raise_a_road:step_4")
		return
	for actor: String in DIALOGUE_EVENTS:
		if id == "stormwood_%s_in_progress" % actor:
			events.emit_event(str(DIALOGUE_EVENTS[actor]))

func emit_event(event: String) -> Dictionary:
	return events.emit_event(event)


func _credit_existing_circuit_wins() -> void:
	var progression: RefCounted = get_node("/root/Game").get("progression")
	# The authored trainer cast lives on StormwoodTrainers (stormwood_trainers.gd),
	# the node the encounter hub and the Dynamo read. The EncounterDirector has
	# no `authored_specs`: reading it there raised a SCRIPT ERROR on every
	# progression change after Rook's offer, so a circuit win was never credited
	# and step 2 could not complete (F10 two-peer proof, run 4).
	var cast := world.get_node_or_null(^"StormwoodTrainers")
	var trainers: Dictionary = cast.get("authored_specs") if cast != null else {}
	for event: String in circuit_win_events(trainers, progression):
		events.emit_event(event)


## A client's offer write is pending until the host delta advances progression.
## Replay the historical trainer facts only after acceptance is locally durable.
## The revision latch prevents a pending writer from resubmitting every frame;
## each accepted delta permits one new reconciliation attempt.
func _replay_circuit_wins_after_progression_change(force := false) -> void:
	var progression: RefCounted = get_node("/root/Game").get("progression")
	var revision := int(progression.get("revision"))
	if not bool(progression.call("has", "stormwood:side_deepwood_circuit_1")) \
			or bool(progression.call("has", "stormwood:side_deepwood_circuit_2")):
		_circuit_replay_revision = revision
		return
	if not force and revision == _circuit_replay_revision:
		return
	_circuit_replay_revision = revision
	_credit_existing_circuit_wins()
	_circuit_replay_revision = int(progression.get("revision"))


static func circuit_win_events(trainers: Dictionary, progression: RefCounted) -> Array[String]:
	var out: Array[String] = []
	for trainer_id: String in trainers:
		var spec: Dictionary = trainers[trainer_id]
		var count_flag := "stormwood:side_deepwood_circuit_win:%s" % trainer_id
		if str(spec.get("group", "")) == "deepwood_circuit" \
				and bool(progression.call("has", str(spec.get("defeat_flag", "")))) \
				and not bool(progression.call("has", count_flag)):
			out.append("count:stormwood:side_deepwood_circuit_win:%s" % trainer_id)
	return out


## Pure so the unit suite can prove Wen's pre-guardian refusal with the same
## branch shape the production NPC placer evaluates.
static func npc_spec(actor: Dictionary) -> Dictionary:
	var actor_id := str(actor.get("id", ""))
	var prefix := "stormwood_%s_" % actor_id
	var branches: Array = [
		{"if_flag": "stormwood:long_storm_ended", "conversation": prefix + "post_storm"},
	]
	var chain_branches: Array = PIMS_PARCELS.branches_for(actor_id)
	chain_branches.append_array(GLASS_FOR_BRYN.branches_for(actor_id))
	if actor_id == "rodkeeper_hesk":
		# Hesk's report outranks his ordinary and post-storm lines while owed.
		branches.push_front({"if_flag": "stormwood:side_dark_arches_2",
			"unless_flag": "stormwood:side_dark_arches_complete",
			"conversation": HESK_DARK_ARCHES_REPORT})
	if actor_id == "keeper_ondra":
		# The road report outranks Ondra's ordinary and post-storm lines while
		# owed; it needs the recipe conversation long since finished.
		branches.push_front({"if_flag": "stormwood:side_raise_a_road_3",
			"unless_flag": "stormwood:side_raise_a_road_complete",
			"conversation": ONDRA_ROAD_REPORT})
	if actor_id == "archivist_wen":
		# The records report never pre-empts the main truth conversation: Wen
		# tells the truth first, then acknowledges the completed reading, even
		# after the Long Storm has ended.
		branches.push_front({"if_flag": ["stormwood:side_crown_remembers_2", ENGINE_TRUTH_FLAG],
			"unless_flag": "stormwood:side_crown_remembers_complete",
			"conversation": WEN_RECORDS_RETURN_CONVERSATION})
		branches.append({"if_flag": ["stormwood:crown_reached", CROWN_GUARDIAN_CLEAR_FLAG],
			"conversation": prefix + "in_progress"})
		branches.append({"if_flag": "stormwood:crown_reached",
			"unless_flag": CROWN_GUARDIAN_CLEAR_FLAG,
			"conversation": WEN_REFUSAL_CONVERSATION})
	elif actor_id == "ace_trainer_rook":
		branches.push_front({"if_flag": "stormwood:side_deepwood_circuit_2",
			"unless_flag": "stormwood:side_deepwood_circuit_complete",
			"conversation": "stormwood_rook_circuit_return"})
		branches.push_front({"if_flag": "stormwood:side_deepwood_circuit_1",
			"unless_flag": "stormwood:side_deepwood_circuit_2",
			"conversation": "stormwood_rook_circuit_progress"})
		branches.push_front({"if_flag": "stormwood:lantern_hollow_reached",
			"unless_flag": "stormwood:side_deepwood_circuit_1",
			"conversation": "stormwood_rook_circuit_offer"})
		branches.append({"if_flag": str(STORY_CONVERSATION_GATES.get(
			actor_id, "stormwood:chapter_started")), "conversation": prefix + "in_progress"})
	else:
		branches.append({"if_flag": str(STORY_CONVERSATION_GATES.get(
			actor_id, "stormwood:chapter_started")), "conversation": prefix + "in_progress"})
	# Side-chain branches outrank ordinary and post-storm lines while active.
	for i in range(chain_branches.size() - 1, -1, -1):
		branches.push_front(chain_branches[i])
	return {"name": str(actor.get("name", "")),
		"config_key": str(actor.get("body_profile", "")),
		"position": (actor.get("position", []) as Array).duplicate(),
		"greeting": prefix + "arrival", "greeting_when": branches}


static func wen_refusal_conversation() -> Dictionary:
	return {
		"speaker": "Archivist Wen",
		"portrait": "res://assets/ui/portraits/old_perrin.png",
		"state": "in_progress",
		"requires_flags": ["stormwood:crown_reached"],
		"lines": [
			"Archivist Wen: The guardian is part of the Crown's living record. I cannot ask the heartstone to speak while it still defends this place.",
			"Settle the guardian — defeat it or catch it — then return. Only then can I read the truth without the Crown fighting us.",
		],
	}

func _read(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}
