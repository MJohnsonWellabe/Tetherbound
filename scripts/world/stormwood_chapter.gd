extends Node

## Scene adapter: dialogue and arrival actions use the existing host-led chapter
## event transport. The catalogue never grants progression merely by loading.
const EVENTS := preload("res://scripts/world/realm_chapter_events.gd")
const PEOPLE := preload("res://scripts/world/village_npcs.gd")
const RUNNER := preload("res://scripts/story/dialogue_runner.gd")
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
	"archivist_wen": "stormwood:crown_reached",
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
	people = PEOPLE.new()
	people.name = "StormwoodPeople"
	world.add_child(people)
	var specs: Array = []
	for actor: Dictionary in _read("res://data/config/stormwood_npcs.json").get("characters", []):
		var prefix := "stormwood_%s_" % actor.id
		specs.append({"name": actor.name, "config_key": actor.body_profile,
			"position": actor.position, "greeting": prefix + "arrival",
			"greeting_when": [
				{"if_flag": "stormwood:long_storm_ended", "conversation": prefix + "post_storm"},
				{"if_flag": str(STORY_CONVERSATION_GATES.get(str(actor.id), "stormwood:chapter_started")), "conversation": prefix + "in_progress"}]})
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

func _read(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}
