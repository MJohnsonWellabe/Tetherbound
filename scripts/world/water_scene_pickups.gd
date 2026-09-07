extends Node3D
## Disposable physical residency over durable production ledger claims. The
## catalogue remains complete when no peer is nearby; scene counts are actual.
const CACHE := preload("res://scripts/world/item_cache_pickup.gd")
const HARVEST := preload("res://scripts/world/harvest_node.gd")
const PERSONAL := preload("res://scripts/world/water_personal_pickup.gd")
const DATA := "res://data/config/water_pickups.json"
const CRATE := "res://assets/props/quaternius_fantasy/Crate_Wooden.gltf"
const RESOURCE_MODELS := {
	"reef_stone": ["res://assets/environment/stylized_nature/Rock_Medium_1.gltf", 0.35],
	"driftwood": ["res://assets/environment/nature/log_large.glb", 0.5],
	"reed_fiber": ["res://assets/environment/stylized_nature/Grass_Wheat.gltf", 0.7],
	"tide_bloom": ["res://assets/environment/stylized_nature/Flower_3_Group.gltf", 0.7],
	"sluice_metal": ["res://assets/props/quaternius_fantasy/Crate_Wooden.gltf", 0.35],
}
@export var residency_radius_m := 140.0
@export var active_cap_per_peer := 96
var ready_for_play := false
var _world: Node3D
var _game: Node
var _rows: Dictionary = {}
var _nodes: Dictionary = {}
var _errors: Dictionary = {}
var _poll_left := 0.0

class WaterHarvest extends "res://scripts/world/harvest_node.gd":
	func _exit_tree() -> void:
		# Godot 4.7's dummy renderer queries an override during MeshInstance3D
		# destruction after its last material reference has been released.
		# log_large's two dielectric overrides reproduce this on residency exit.
		# Detach while retaining them; live visuals and harvest behavior stay intact.
		var retained: Array[Material] = []
		for instance: MeshInstance3D in find_children("*", "MeshInstance3D", true, false):
			for surface in instance.get_surface_override_material_count():
				var material := instance.get_surface_override_material(surface)
				if material != null:
					retained.append(material)
					instance.set_surface_override_material(surface, null)

class PersonalCandy extends "res://scripts/world/item_cache_pickup.gd":
	const RULE := preload("res://scripts/world/water_personal_pickup.gd")
	var authored_id := ""
	func _on_picked_up() -> void:
		if _taken or _claiming:
			return
		var game := get_node_or_null("/root/Game")
		if game == null or str(game.get("current_realm")) != "water":
			return
		if not game.get("inventory").has_room_for(_item_id, _count):
			game.call("push_world_message", "Satchel is full.")
			return
		_claiming = true
		var verdict := LEDGER_CLAIM.submit(self, {"kind": "water_personal_pickup", "realm": "water",
			"pickup_id": authored_id, "personal_claimed": game.get("local").flags.has(RULE.personal_flag(authored_id))})
		if not LEDGER_CLAIM.in_flight(verdict):
			_claiming = false
			claim_refused.emit(str(verdict.get("code", "")), str(verdict.get("reason", "")))
	func _on_delta_applied(delta: Dictionary) -> void:
		for op: Dictionary in delta.get("ops", []):
			if str(op.get("scope", "")) == "player" and str(op.get("op", "")) == "flag" and str(op.get("id", "")) == RULE.personal_flag(authored_id) and op.get("peers", []).has(multiplayer.get_unique_id()):
				_deactivate()
				return
	func restore_progression_from_game(game: Node) -> void:
		if game.get("local").flags.has(RULE.personal_flag(authored_id)):
			_deactivate()
	func _on_intent_refused(kind: String, code: String, reason: String, _detail: Dictionary) -> void:
		if kind != "water_personal_pickup" or not _claiming:
			return
		_claiming = false
		claim_refused.emit(code, reason)

func build(world: Node3D) -> Dictionary:
	if ready_for_play:
		return census()
	_world = world
	if get_parent() == null:
		world.add_child(self)
	_game = get_node_or_null("/root/Game")
	var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DATA))
	for kind: String in ["pickups", "harvest"]:
		for row: Dictionary in source.get(kind, []):
			var spec := row.duplicate(true)
			spec["placement_kind"] = kind
			_rows[str(spec.id)] = spec
	add_to_group("progression_restore")
	ready_for_play = true
	refresh()
	return census()

func _process(delta: float) -> void:
	_poll_left -= delta
	if ready_for_play and _poll_left <= 0.0:
		_poll_left = 0.5
		refresh()

func _focus_positions() -> Array[Vector3]:
	var positions: Array[Vector3] = []
	if _game != null and str(_game.get("current_realm")) == "water":
		var local: Node3D = _world.call("local_rig")
		if local != null:
			positions.append(local.global_position)
	for proxy: Node in get_tree().get_nodes_in_group("remote_trainer"):
		if proxy is Node3D and str(proxy.get("net_realm")) == "water":
			positions.append(proxy.global_position)
	return positions

func refresh() -> void:
	if _game == null:
		return
	var wanted: Dictionary = {}
	for focus: Vector3 in _focus_positions():
		var candidates: Array = []
		for id: String in _rows:
			var row: Dictionary = _rows[id]
			if _taken(row):
				continue
			var at: Array = row.position
			var distance := Vector2(focus.x - float(at[0]), focus.z - float(at[2])).length_squared()
			if distance <= residency_radius_m * residency_radius_m:
				candidates.append({"id": id, "distance": distance})
		candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.distance < b.distance if a.distance != b.distance else str(a.id) < str(b.id))
		for index in mini(active_cap_per_peer, candidates.size()):
			wanted[str(candidates[index].id)] = true
	for id: String in _nodes.keys():
		if not is_instance_valid(_nodes[id]):
			_nodes.erase(id)
		elif not wanted.has(id):
			(_nodes[id] as Node).queue_free()
			_nodes.erase(id)
	for id: String in wanted:
		if not _nodes.has(id) and not _errors.has(id):
			_spawn(_rows[id])

func _taken(row: Dictionary) -> bool:
	if str(row.placement_kind) == "harvest":
		return HARVEST.was_taken(_game, "order:" + str(row.id))
	if str(row.get("claim_policy", "")) == "character_once":
		return _game.get("local").flags.has(PERSONAL.personal_flag(str(row.id)))
	return CACHE.was_taken(_game, str(row.item_id), str(row.id).trim_prefix("water:"), "water")

func _spawn(row: Dictionary) -> void:
	var id := str(row.id)
	var at: Array = row.position
	var spot := Vector3(float(at[0]), 0, float(at[2]))
	spot.y = _world.call("ground_height_at", spot.x, spot.z)
	if not spot.is_finite() or spot.y < 0.0:
		_errors[id] = "No dry baked terrain"
		return
	var definition: Dictionary = _game.get("items").definition(str(row.item_id))
	if definition.is_empty():
		_errors[id] = "ItemDB registration missing"
		return
	var node: Node3D
	if str(row.placement_kind) == "harvest":
		node = WaterHarvest.new()
		add_child(node)
		node.global_position = spot
		var model: Array = RESOURCE_MODELS.get(str(row.item_id), [CRATE, 0.35])
		node.call("setup", {"order": id, "realm": "water", "item": row.item_id, "amount": int(row.get("yield", 1)),
			"at": [spot.x, spot.y, spot.z], "label": "Gather " + str(definition.name), "model": model[0], "model_scale": model[1]})
	else:
		var personal := str(row.get("claim_policy", "")) == "character_once"
		node = PersonalCandy.new() if personal else CACHE.new()
		if personal:
			node.set("authored_id", id)
		add_child(node)
		node.global_position = spot
		node.call("setup", str(row.item_id), "Take " + str(definition.name), str(definition.get("world_model", CRATE)),
			float(definition.get("world_model_scale", 0.35)), id.trim_prefix("water:"), "water", int(row.get("quantity", 1)))
		if personal:
			var label := Label3D.new()
			label.text = str(row.get("tier_marking", ""))
			label.position.y = 0.9
			label.font_size = 48
			label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			node.add_child(label)
	node.name = id.replace(":", "_")
	node.set_meta("water_placement_id", id)
	node.set_meta("water_placement_kind", str(row.placement_kind))
	_nodes[id] = node

func node_for(id: String) -> Node3D:
	return _nodes.get(id) as Node3D

func census() -> Dictionary:
	var pickups := 0
	var harvest := 0
	var authored_pickups := 0
	var authored_harvest := 0
	for row: Dictionary in _rows.values():
		if str(row.placement_kind) == "harvest":
			authored_harvest += 1
		else:
			authored_pickups += 1
	for id: String in _nodes:
		if is_instance_valid(_nodes[id]) and not (_nodes[id] as Node).is_queued_for_deletion():
			if str(_rows[id].placement_kind) == "harvest":
				harvest += 1
			else:
				pickups += 1
	return {"ready": ready_for_play, "authored_pickups": authored_pickups, "authored_harvest": authored_harvest,
		"active_pickups": pickups, "active_harvest": harvest, "errors": _errors.duplicate(),
		"presentation_placeholders": ["resource bodies reuse installed nature models", "sluice metal and unmodelled gear use a supply crate"]}

func restore_progression_from_game(_game_state: Node) -> void:
	for node: Variant in _nodes.values():
		if is_instance_valid(node):
			node.queue_free()
	_nodes.clear()
	refresh()
