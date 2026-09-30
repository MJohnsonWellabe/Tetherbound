extends Node3D

## F32 reusable presentation mount, explicitly called by a world owner only
## after the foundation's typed site registry/atomic receipt carrier lands.
## Existing worlds do not call this helper yet. Body clearance is a physics
## query with the real trainer shape; it is not an ordinary-player-path proof.

const CATALOGUE := preload("res://scripts/world/essence_node_catalog.gd")
const RENEWABLE_SITES := preload("res://scripts/world/renewable_site_catalog.gd")
const HARVEST := preload("res://scripts/world/harvest_node.gd")

var _mounted: Dictionary = {}
var _refusals: Dictionary = {}


## Scene-local results for the later census witness; not durable world state.
func census() -> Dictionary:
	var living: Array[String] = []
	for id: String in _mounted:
		if is_instance_valid(_mounted[id]):
			living.append(id)
	return {"mounted_ids": living, "refusals": _refusals.duplicate(true),
		"ordinary_player_path_proven": false}


func mount(world: Node3D, realm: String, trainer: CharacterBody3D) -> Dictionary:
	if world == null or not world.is_inside_tree():
		return {"mounted_ids": [], "reason": "World residency is not ready."}
	var game := world.get_node_or_null(^"/root/Game")
	var state: Variant = game.get("world") if game != null else null
	if not state is Object or not state.has_method("renewable_stock_state"):
		return {"mounted_ids": [], "reason": "Host renewable registry is not ready."}
	var source := CATALOGUE.read()
	var errors := CATALOGUE.validation_errors(source)
	if not errors.is_empty():
		return {"mounted_ids": [], "errors": errors}
	var items: RefCounted = game.get("items")
	var tuning: Dictionary = source.get("placement_validation", {})
	for authored: Dictionary in CATALOGUE.nodes_for(realm, source):
		var id := str(authored["id"])
		if _mounted.has(id) and is_instance_valid(_mounted[id]):
			continue
		var spec := RENEWABLE_SITES.by_id(realm, id)
		if spec.is_empty():
			_refusals[id] = "Canonical renewable definition is unavailable."
			continue
		var stock: Variant = state.call("renewable_stock_state", realm, id)
		if not stock is Dictionary or stock.is_empty():
			_refusals[id] = "Host site is not registered."
			continue
		if not _items_registered(spec, items):
			_refusals[id] = "Canonical inventory items are not registered."
			continue
		var model := str(spec.get("model", ""))
		if model.is_empty() or not ResourceLoader.exists(model):
			_refusals[id] = "Installed resource model is unavailable."
			continue
		var verdict := placement_verdict(world, spec, trainer, tuning)
		if not bool(verdict.get("ok", false)):
			_refusals[id] = str(verdict.get("reason", "Placement unavailable."))
			continue
		var node := HARVEST.new()
		node.name = id
		add_child(node)
		node.global_position = verdict["position"]
		node.call("setup", CATALOGUE.harvest_spec(spec, stock))
		_mounted[id] = node
		_refusals.erase(id)
	return census()


static func _items_registered(spec: Dictionary, items: RefCounted) -> bool:
	if items == null:
		return false
	for item: String in spec.get("outputs", {}):
		if not bool(items.call("has", item)):
			return false
	var seed: Dictionary = spec.get("seed_drop", {})
	return seed.is_empty() or bool(items.call("has", str(seed.get("item", ""))))


static func placement_verdict(world: Node3D, spec: Dictionary,
		trainer: CharacterBody3D, tuning: Dictionary) -> Dictionary:
	if world == null or not world.has_method("ground_height_at") \
			or not world.is_inside_tree() or trainer == null or not trainer.is_inside_tree():
		return {"ok": false, "reason": "Actual terrain and trainer body are required."}
	var at: Variant = spec.get("at")
	if not at is Array or at.size() != 2:
		return {"ok": false, "reason": "Node coordinates are invalid."}
	var x := float(at[0])
	var z := float(at[1])
	var ground := float(world.call("ground_height_at", x, z))
	if not is_finite(x) or not is_finite(z) or not is_finite(ground):
		return {"ok": false, "reason": "No finite baked terrain at this candidate."}
	var step := maxf(0.1, float(tuning.get("slope_sample_m", 0.75)))
	var maximum := float(tuning.get("maximum_slope_degrees", 35.0))
	for offset: Vector2 in [Vector2(step, 0), Vector2(-step, 0), Vector2(0, step), Vector2(0, -step)]:
		var neighbour := float(world.call("ground_height_at", x + offset.x, z + offset.y))
		if not is_finite(neighbour) or rad_to_deg(atan(absf(neighbour - ground) / step)) > maximum:
			return {"ok": false, "reason": "Candidate slope is not walkable."}
	var collision: CollisionShape3D
	for child: Node in trainer.find_children("*", "CollisionShape3D", true, false):
		var candidate := child as CollisionShape3D
		if candidate != null and not candidate.disabled and candidate.shape != null:
			collision = candidate
			break
	if collision == null or trainer.collision_mask == 0:
		return {"ok": false, "reason": "Actual trainer collision shape is unavailable."}
	var site_position := Vector3(x, ground, z)
	var shape_transform := collision.global_transform
	shape_transform.origin = site_position + collision.global_position - trainer.global_position \
		+ Vector3.UP * maxf(0.0, float(tuning.get("body_ground_clearance_m", 0.06)))
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = collision.shape
	query.transform = shape_transform
	query.collision_mask = trainer.collision_mask
	query.exclude = [trainer.get_rid()]
	query.collide_with_areas = false
	if not world.get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty():
		return {"ok": false, "reason": "Trainer capsule overlaps a terrain or prop collider."}
	return {"ok": true, "position": site_position, "body_clearance_proven": true,
		"ordinary_player_path_proven": false}
