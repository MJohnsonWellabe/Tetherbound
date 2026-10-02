extends Node3D

## Whole-biome mount owned by F32. World owner replaces matching legacy tier
## nodes with this mount when ROOT activates the proven cut. Scene residency
## never creates stock or authorizes rewards; service readers are host mirrors.
const SITES := preload("res://scripts/world/renewable_site_catalog.gd")
const VALIDATOR := preload("res://scripts/world/essence_node_mount.gd")
const HARVEST := preload("res://scripts/world/harvest_node.gd")
const FARM := preload("res://scripts/world/type_crop_plot.gd")
var _mounted: Dictionary = {}
var _refusals: Dictionary = {}

func mount(world: Node3D, trainer: CharacterBody3D, service: Node) -> Dictionary:
	var runtime := _read("res://data/config/f32_runtime.json")
	if runtime.get("runtime_enabled") != true: return {"mounted_ids": [], "code": "disabled"}
	if world == null or trainer == null or service == null or not world.is_inside_tree() \
			or not is_inside_tree() or not world.is_ancestor_of(self) or not world.is_ancestor_of(trainer) \
			or not world.has_method("world_realm") or world.get_world_3d() != trainer.get_world_3d():
		return {"mounted_ids": [], "code": "actual_world_residency_required"}
	var realm := str(world.call("world_realm"))
	var essence := _read("res://data/config/essence_nodes.json")
	var tuning: Dictionary = essence.get("placement_validation", {})
	var missing: Array[Dictionary] = []
	for spec: Dictionary in SITES.sites_for(realm):
		if node_for(str(spec.id)) == null: missing.append(spec)
	if missing.is_empty(): return census()
	var legacy_nodes: Array[Node] = world.find_children("*", "Node3D", true, false)
	for spec: Dictionary in missing:
		var id := str(spec.id)
		if _mounted.has(id) and is_instance_valid(_mounted[id]): continue
		var stock: Dictionary = service.call("stock", realm, id)
		if stock.is_empty():
			_refusals[id] = "Host has no registered live stock for this placement."
			continue
		var verdict := VALIDATOR.placement_verdict(world, spec, trainer, tuning)
		if verdict.get("ok") != true:
			_refusals[id] = verdict.get("reason", "Placement unavailable.")
			continue
		if realm == "water" and not VALIDATOR._additional_water_dry(world, verdict.position, tuning):
			_refusals[id] = "Actual baked ground and water surface do not establish a dry resource bed."
			continue
		var model := str(spec.get("model", ""))
		if model.is_empty() or not ResourceLoader.exists(model):
			_refusals[id] = "Installed model unavailable."
			continue
		var adopted: Node3D
		for existing: Node in legacy_nodes:
			if not existing.has_method("adopt_renewable_source") or existing.is_queued_for_deletion() \
				or not str(existing.get("_renewable_site_id")).is_empty(): continue
			var flag := "harvest_node:" + str(existing.get("_node_id"))
			var prefix := str(spec.get("legacy_flag_day_prefix", ""))
			if flag != spec.get("legacy_flag", "") and flag != spec.get("legacy_flag_alias", "") \
				and (prefix.is_empty() or not flag.begins_with(prefix)): continue
			if (existing as Node3D).global_position.distance_to(verdict.position) > 1.0: continue
			if existing.call("adopt_renewable_source", spec, service, stock) == true:
				adopted = existing as Node3D
				break
		if adopted != null:
			_mounted[id] = adopted
			_refusals.erase(id)
			continue
		var node := HARVEST.new()
		node.name = id.replace(":", "_")
		add_child(node)
		node.global_position = verdict.position
		node.call("bind_source_service", service)
		var mounted_spec := spec.duplicate(true)
		mounted_spec["renewable_site_id"] = id
		mounted_spec["renewable_stock"] = stock
		node.call("setup", mounted_spec)
		_mounted[id] = node
		_refusals.erase(id)
	return census()

func mount_authored_farm(world: Node3D, trainer: CharacterBody3D, service: Node) -> Dictionary:
	var config := _read("res://data/config/farm.json")
	if config.get("runtime_enabled") != true or _read("res://data/config/f32_runtime.json").get("runtime_enabled") != true:
		return {"mounted_ids": [], "code": "disabled"}
	if world == null or not world.has_method("world_realm") or world.call("world_realm") != "meadows" \
			or trainer == null or service == null or not world.is_ancestor_of(self) or not world.is_ancestor_of(trainer):
		return {"mounted_ids": [], "code": "actual_world_residency_required"}
	for index: int in config.get("plots", []).size():
		var id := "authored:%d" % index
		if _mounted.has(id) and is_instance_valid(_mounted[id]): continue
		var plot: Dictionary = service.call("plot", "meadows", id)
		if plot.is_empty():
			_refusals[id] = "Host plot is not registered."
			continue
		var verdict := VALIDATOR.placement_verdict(world, config.plots[index], trainer,
			_read("res://data/config/essence_nodes.json").get("placement_validation", {}))
		if verdict.get("ok") != true:
			_refusals[id] = verdict.get("reason", "Plot unavailable.")
			continue
		var node := FARM.new()
		add_child(node)
		node.global_position = verdict.position
		node.call("setup_source", id, config, service)
		# Retire the matching legacy berry consumer only once its replacement
		# has a real grounded placement and the same saved plot index.
		var legacy := world.get_node_or_null("BerryFarm/Plot%d" % index)
		if legacy != null and legacy.get_script() == preload("res://scripts/world/farm_plot.gd"):
			legacy.get_parent().remove_child(legacy)
			legacy.queue_free()
		_mounted[id] = node
		_refusals.erase(id)
	return census()

func node_for(id: String) -> Node3D:
	var node: Node3D = _mounted.get(id)
	return node if is_instance_valid(node) and node.is_inside_tree() and not node.is_queued_for_deletion() else null

func census() -> Dictionary:
	var ids: Array[String] = []
	for id: String in _mounted:
		if is_instance_valid(_mounted[id]): ids.append(id)
	return {"mounted_ids": ids, "refusals": _refusals.duplicate(true), "ordinary_player_path_proven": false}

static func _read(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}
