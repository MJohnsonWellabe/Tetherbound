extends Node

## Scene adapter: dialogue and arrival actions use the existing host-led chapter
## event transport. The catalogue never grants progression merely by loading.
const EVENTS := preload("res://scripts/world/realm_chapter_events.gd")
const PEOPLE := preload("res://scripts/world/village_npcs.gd")
const RUNNER := preload("res://scripts/story/dialogue_runner.gd")
const CROWN_GUARDIAN_CLEAR_FLAG := "stormwood:named:crown_guardian:cleared"
const WEN_REFUSAL_CONVERSATION := "stormwood_archivist_wen_guardian_refusal"
var world: Node3D
var events: Node
var people: Node3D
var chapter: Dictionary
var _panel: Node
var _local := false
var _arrival_check_left := 0.0
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
	for actor: String in DIALOGUE_EVENTS:
		if id == "stormwood_%s_in_progress" % actor:
			events.emit_event(str(DIALOGUE_EVENTS[actor]))

func emit_event(event: String) -> Dictionary:
	return events.emit_event(event)


## Pure so the unit suite can prove Wen's pre-guardian refusal with the same
## branch shape the production NPC placer evaluates.
static func npc_spec(actor: Dictionary) -> Dictionary:
	var actor_id := str(actor.get("id", ""))
	var prefix := "stormwood_%s_" % actor_id
	var branches: Array = [
		{"if_flag": "stormwood:long_storm_ended", "conversation": prefix + "post_storm"},
	]
	if actor_id == "archivist_wen":
		branches.append({"if_flag": ["stormwood:crown_reached", CROWN_GUARDIAN_CLEAR_FLAG],
			"conversation": prefix + "in_progress"})
		branches.append({"if_flag": "stormwood:crown_reached",
			"unless_flag": CROWN_GUARDIAN_CLEAR_FLAG,
			"conversation": WEN_REFUSAL_CONVERSATION})
	else:
		branches.append({"if_flag": str(STORY_CONVERSATION_GATES.get(
			actor_id, "stormwood:chapter_started")), "conversation": prefix + "in_progress"})
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
