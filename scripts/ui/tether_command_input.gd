extends Node

## Shared CombatManager mounts this with two real adapters: local presentation
## snapshot reader and host intent sender. It sends no UID/HP/gear/hit/target.
## D-pad presses are consumed only while active, with no modal owner. Existing
## hotbar/combat cycle polls must yield these actions when F24 is enabled.
const COMMANDS := preload("res://scripts/combat/tether_commands.gd")
const OWNER := preload("res://scripts/ui/input_owner.gd")
var _read: Callable
var _send: Callable
var _sequence := 0
var _encounter_id := ""

func configure(read_local_snapshot: Callable, send_intent: Callable) -> void:
	_read = read_local_snapshot
	_send = send_intent

func _unhandled_input(event: InputEvent) -> void:
	if not COMMANDS.enabled() or not _read.is_valid() or not _send.is_valid() \
		or OWNER.current(get_tree()) != null or event.is_echo(): return
	for id: String in COMMANDS.COMMAND_IDS:
		var action := COMMANDS.input_action(id)
		if InputMap.has_action(action) and event.is_action_pressed(action):
			if request(id): get_viewport().set_input_as_handled()
			return

## The actual C2 pilot and optional tap-then-tap preset share this request path.
## No test may call the staging math as a substitute for executing a command.
func request(command_id: String) -> bool:
	if not COMMANDS.enabled() or not _read.is_valid() or not _send.is_valid() \
		or OWNER.current(get_tree()) != null or not COMMANDS.COMMAND_IDS.has(command_id): return false
	var snapshot: Variant = _read.call()
	return _request_snapshot(command_id, snapshot)

func _request_snapshot(command_id: String, snapshot: Variant) -> bool:
	if not COMMANDS.COMMAND_IDS.has(command_id): return false
	if not snapshot is Dictionary or snapshot.get("active") != true \
		or snapshot.get("input_context") != "combat" \
		or not snapshot.get("encounter_id") is String or not snapshot.get("generation") is int \
		or not snapshot.get("unlocked_commands") is Array or not snapshot.unlocked_commands.has(command_id): return false
	if _encounter_id != snapshot.encounter_id:
		_encounter_id = snapshot.encounter_id
		_sequence = int(snapshot.get("last_sequence", 0))
	_sequence = maxi(_sequence, int(snapshot.get("last_sequence", 0)))
	if _sequence >= 2147483647: return false
	_sequence += 1
	return _send.call(COMMANDS.intent(_encounter_id, int(snapshot.generation), _sequence, command_id)) == true
