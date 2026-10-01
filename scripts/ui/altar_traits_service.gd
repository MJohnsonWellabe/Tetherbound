extends Node

## UI transport only. Foundation owns station admission, stable character
## generation, original-intent journal reconciliation, save/ACK and commit.
const TRAITS := preload("res://scripts/creatures/traits.gd")
const PANEL := preload("res://scripts/ui/altar_traits_panel.gd")
signal action_completed(result: Dictionary)
var _game: Node
var _session: Node
var _panel: CanvasLayer
var _pending: Dictionary = {}
var _original_context: Dictionary = {}
var _retry_left := 0.0
var _connection := Callable()
var _return_route := Callable()

func configure_return_route(route: Callable) -> void:
	_return_route = route
	if is_instance_valid(_panel): _panel.set("return_to", route)

static func attach(game: Node) -> Node:
	if game == null: return null
	var existing := game.get_node_or_null(^"AltarTraitsService")
	if existing != null:
		return existing if existing.get_script() == load("res://scripts/ui/altar_traits_service.gd") else null
	var service: Node = load("res://scripts/ui/altar_traits_service.gd").new()
	service.name = "AltarTraitsService"
	service.set("_game",game)
	game.add_child(service)
	return service

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _context() -> Dictionary:
	if not is_instance_valid(_game): return {}
	var local: Variant = _game.get("local")
	var world: Variant = _game.get("world")
	if not local is RefCounted or not world is RefCounted: return {}
	return {"character_id":local.get("character_id"),"world_id":world.get("world_id"),
		"world_namespace":world.get("reward_delivery_namespace")}

func _bind() -> bool:
	if not is_instance_valid(_game): return false
	var candidate: Variant = _game.get("session")
	if not candidate is Node or not is_instance_valid(candidate): return false
	for method: String in ["altar_station_available","quote_altar_traits","submit_altar_trait","reconcile_altar_trait"]:
		if not candidate.has_method(method): return false
	if not candidate.has_signal("altar_trait_completed"): return false
	if candidate != _session:
		if is_instance_valid(_session) and _connection.is_valid() and _session.is_connected("altar_trait_completed",_connection):
			_session.disconnect("altar_trait_completed",_connection)
		_session = candidate
		_connection = _completed.bind(_session)
		_session.connect("altar_trait_completed",_connection)
	return true

func _exit_tree() -> void:
	if is_instance_valid(_session) and _connection.is_valid() and _session.is_connected("altar_trait_completed",_connection):
		_session.disconnect("altar_trait_completed",_connection)

func open(station_key: String) -> bool:
	if not _pending.is_empty() or station_key.is_empty() or not _bind() \
		or _session.call("altar_station_available",station_key) != true: return false
	if not is_instance_valid(_panel):
		_panel = PANEL.new()
		add_child(_panel)
	_panel.set("return_to", _return_route)
	return _panel.call("open",self,station_key) == true

func creature_choices() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var party: Variant = _game.get("party")
	if not party is RefCounted or not party.has_method("members"): return result
	for creature: RefCounted in party.call("members"):
		result.append({"uid":creature.get("uid"),"name":creature.call("label")})
	return result

func quote(station_key: String, uid: String) -> Dictionary:
	if not _bind() or _session.call("altar_station_available",station_key) != true:
		return {"ok":false,"code":"authority_or_station_unavailable"}
	var raw: Variant = _session.call("quote_altar_traits",station_key,uid)
	return raw.duplicate(true) if raw is Dictionary else {"ok":false,"code":"quote_unavailable"}

func submit(station_key: String, request: Dictionary) -> void:
	if not TRAITS.intent_valid(request) or not _pending.is_empty() or not _bind():
		action_completed.emit({"ok":false,"code":"invalid_or_busy"})
		return
	if _session.call("altar_station_available",station_key) != true:
		action_completed.emit({"ok":false,"code":"station_unavailable"})
		return
	# Freeze before synchronous solo callback. No costs/traits/roster writes.
	_pending = {"station_key":station_key,"request":request.duplicate(true),"session":_session}
	_original_context = _context()
	_retry_left = 2.0
	var raw: Variant = _session.call("submit_altar_trait",station_key,request.duplicate(true))
	if raw is Dictionary: _completed(station_key,request.action_id,raw,_session)

func reconcile() -> void:
	if _pending.is_empty() or not _bind(): return
	# The original identity/request stays frozen across rejoin. Session must
	# route journal recovery to the current admitted generation of THAT owner.
	if _context() != _original_context:
		action_completed.emit({"ok":false,"code":"original_character_required","recoverable":true})
		return
	var raw: Variant = _session.call("reconcile_altar_trait",_pending.station_key,_pending.request.duplicate(true))
	if raw is Dictionary: _completed(_pending.station_key,_pending.request.action_id,raw,_session)

func _process(delta: float) -> void:
	if _pending.is_empty(): return
	_retry_left -= delta
	if _retry_left <= 0.0:
		_retry_left = 2.0
		reconcile()

func _completed(station_key: String, action_id: String, result: Dictionary, source: Node) -> void:
	if _pending.is_empty() or station_key != _pending.station_key \
		or action_id != _pending.request.action_id or _context() != _original_context or source != _session: return
	# Success means both journal durability and exact owner's bool-save ACK.
	# Failure after journal acceptance retains ORIGINAL request for retry.
	if result.get("ok") == true and result.get("durable") == true \
		and result.get("owner_saved") == true and result.get("owner_acknowledged") == true:
		_pending.clear()
		_original_context.clear()
	elif result.get("terminal") == true and result.get("durable") == false:
		_pending.clear()
		_original_context.clear()
	else:
		result = result.duplicate(true)
		result["recoverable"] = true
		result["ok"] = false
		result["code"] = result.get("code","owner_save_ack_required")
	action_completed.emit(result)

func busy() -> bool:
	return not _pending.is_empty()
