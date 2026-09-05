extends RefCounted

## Game-owned transient queue + read-only recent-event cursor for presenters.
## No signals, autoload, save fields or second progression model.
const CONFIG_PATH := "res://data/config/progression_feedback.json"
static var _config: Dictionary = {}
var revision := 0
var _queue: Array[Dictionary] = []
var _recent: Array[Dictionary] = []


static func config() -> Dictionary:
	if _config.is_empty():
		_config = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	return _config


static func game() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	return tree.root.get_node_or_null("Game") if tree != null else null


static func publish(creature: RefCounted, event: Dictionary) -> void:
	event = event.duplicate(true)
	event["instance_id"] = creature.get_instance_id()
	event["display_name"] = str(creature.call("label"))
	# Explicit sink enables behaviour tests and other game instances without
	# binding live creatures to a global event bus. Never serialized.
	var sink: Callable = creature.get_meta("progression_sink", Callable())
	if sink.is_valid():
		sink.call(event)
		return
	var owner := game()
	if owner != null and owner.has_method("push_progression_event"):
		owner.call("push_progression_event", creature, event)


static func enabled(creature: RefCounted) -> bool:
	if (creature.get_meta("progression_sink", Callable()) as Callable).is_valid():
		return true
	var owner := game()
	var party: RefCounted = owner.get("party") if owner != null else null
	return party != null and (party.call("members") as Array).has(creature)


func push_event(event: Dictionary) -> void:
	revision += 1
	var copy := event.duplicate(true)
	copy["sequence"] = revision
	_queue.append(copy)
	_recent.append(copy)
	while _recent.size() > 256:
		_recent.pop_front()


func drain() -> Array[Dictionary]:
	var events: Array[Dictionary] = _queue.duplicate(true)
	_queue.clear()
	if not events.is_empty():
		revision += 1
	return events


func since(cursor: int) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	for event: Dictionary in _recent:
		if int(event.sequence) > cursor:
			events.append(event.duplicate(true))
	return events


func latest_for(instance_id: int, kind: String) -> Dictionary:
	for index in range(_recent.size() - 1, -1, -1):
		if int(_recent[index].instance_id) == instance_id and str(_recent[index].kind) == kind:
			return _recent[index].duplicate(true)
	return {}


static func evolution_ready(creature: RefCounted) -> bool:
	var owner := game()
	var inventory: RefCounted = owner.get("inventory") if owner != null else null
	var evolution: Script = load("res://scripts/creatures/evolution.gd")
	var progression: Script = load("res://scripts/creatures/progression.gd")
	return bool(evolution.check(creature, progression.config(), inventory).get("eligible", false))


static func moment_text(event: Dictionary) -> String:
	if str(event.get("kind", "")) == "level_up":
		var stats: Dictionary = event.get("stat_deltas", {})
		var text := "%s reached Lv %d  ·  HP +%d / ATK +%d / DEF +%d" % [event.display_name, int(event.new_level),
			int(round(float(stats.get("hp", 0)))), int(round(float(stats.get("attack", 0)))), int(round(float(stats.get("defence", 0))))]
		if event.get("evolution_ready", false):
			text += "  ·  Evolution ready"
		return text
	return "%s  ·  Bond %d/5  ·  %s" % [event.display_name, int(event.get("node_index", 0)), str(event.get("benefit", ""))]
