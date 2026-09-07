extends RefCounted
const DATA := "res://data/config/water_dock_actions.json"
const FIELD := preload("res://scripts/world/water_heightfield.gd")

static func load_data() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(DATA))

static func action_position(action: Dictionary, world_config: Dictionary, ground: Callable) -> Vector3:
	for anchor: Dictionary in world_config.anchors:
		if str(anchor.id) != str(action.anchor):
			continue
		var x := float(anchor.safe_position[0]) + float(action.offset_xz[0])
		var z := float(anchor.safe_position[2]) + float(action.offset_xz[1])
		return Vector3(x, float(ground.call(x, z)), z)
	return Vector3.INF

static func evaluate(intent: Dictionary, context: Dictionary, flags: RefCounted) -> Dictionary:
	var data := load_data()
	var action: Dictionary = {}
	for row: Dictionary in data.actions:
		if str(row.id) == str(intent.get("action_id", "")):
			action = row
	if action.is_empty():
		return _refuse("unknown_action", "That dock action is not available.")
	if str(context.get("realm", "")) != "water" or str(intent.get("realm", "")) != "water":
		return _refuse("wrong_realm", "Reach this Water dock first.")
	var actor := int(context.get("peer", 0))
	if actor <= 0 or str(context.get("character_id", "")).is_empty():
		return _refuse("unknown_character", "Your character is not connected.")
	var position: Variant = context.get("position")
	var field := FIELD.new()
	var target := action_position(action, FIELD.load_config(), field.height_at)
	if not position is Vector3 or not position.is_finite() or not target.is_finite() or position.distance_to(target) > float(data.interaction_distance_m):
		return _refuse("too_far", "Move closer to the dock equipment.")
	if flags.has(str(action.flag)):
		return _refuse("already_done", "This dock task is already complete.")
	for flag: String in action.requires_flags:
		if not flags.has(flag):
			return _refuse("prerequisite", "Resolve the dock's challenge first.")
	var bag: Variant = context.get("inventory", {})
	if not bag is Dictionary:
		return _refuse("malformed", "The repair materials could not be checked.")
	for item: String in action.cost:
		var amount: Variant = bag.get(item, 0)
		if not (amount is int or amount is float) or not is_finite(float(amount)) or float(amount) < float(action.cost[item]):
			return _refuse("materials", "Bring 6 reed fiber and 4 driftwood to repair the dock.")
	var ops: Array = []
	for item: String in action.cost:
		ops.append({"op":"item_take", "scope":"player", "peers":[actor], "item":item, "count":int(action.cost[item])})
	ops.append({"op":"flag", "scope":"world", "realm":"water", "id":str(action.flag), "value":true})
	return {"ok":true, "code":"", "reason":"", "ops":ops}

static func _refuse(code: String, reason: String) -> Dictionary:
	return {"ok":false, "code":code, "reason":reason, "ops":[]}
