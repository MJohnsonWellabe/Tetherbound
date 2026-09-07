extends Node

## Fixed Stormwood recovery sites. This adapter deliberately delegates rest to
## RestPoint/NightRest, preserving the production shared-night authority.

const REST_POINT := preload("res://scripts/world/rest_point.gd")
const HEIGHTFIELD := preload("res://scripts/world/stormwood_heightfield.gd")

const CONFIG_PATH := "res://data/config/stormwood_camps.json"
const SURGE_PATH := "res://data/config/stormwood_surge.json"
const NPCS_PATH := "res://data/config/stormwood_npcs.json"
const SETTLEMENTS_PATH := "res://data/config/stormwood_settlements.json"
const MIN_NPC_DISTANCE_M := 10.0
const MODEL_PATHS := {
	"tent": "res://assets/props/generated_camp/camp_tent.glb",
	"fire": "res://assets/props/generated_camp/campfire_stone_ring.glb",
	"firewood": "res://assets/props/generated_camp/camp_firewood.glb",
	"lightning_rod": "res://assets/environment/team_tether/tether_pylon.glb",
}

var _field := HEIGHTFIELD.new()

func recovery_camps(world: Node3D) -> Array:
	var result: Array = []
	var gates := {"rodline_refuge": "stormwood:rodline_linked", "still_grove_shelter": "stormwood:varga_defeated", "lantern_hollow_waycamp": "stormwood:rootgate_released", "ember_bivouac": "stormwood:all_rods_disabled"}
	for camp: Dictionary in load_config().get("camps", []):
		result.append({"id": camp.id, "position": [camp.at[0], _ground(world, float(camp.at[0]), float(camp.at[1])), camp.at[1]], "requires_flag": gates.get(str(camp.id), "")})
	return result

func rod_positions(world: Node3D) -> Array:
	var result: Array = []
	for camp: Dictionary in load_config().get("camps", []):
		for prop: Dictionary in camp.props:
			if str(prop.model) == "lightning_rod":
				var x := float(camp.at[0]) + float(prop.offset[0])
				var z := float(camp.at[1]) + float(prop.offset[1])
				result.append(Vector3(x, _ground(world, x, z), z))
	return result


func mount(world: Node3D) -> void:
	if world.get_node_or_null(^"StormwoodCamps") != null:
		return
	var config := load_config()
	var errors := validate(config, _read(SURGE_PATH), _read(NPCS_PATH), _read(SETTLEMENTS_PATH))
	if not errors.is_empty():
		for error: String in errors:
			push_error("Stormwood camps: " + error)
		return
	var root := Node3D.new()
	root.name = "StormwoodCamps"
	world.add_child(root)
	for camp: Dictionary in config.get("camps", []):
		_build_camp(root, camp, world)


func _build_camp(root: Node3D, camp: Dictionary, world: Node3D) -> void:
	var at: Array = camp.at
	var ground := _ground(world, float(at[0]), float(at[1]))
	var rest := REST_POINT.new()
	rest.name = str(camp.id)
	root.add_child(rest)
	rest.build(rest_spec(camp, ground))
	# RestPoint uses world XZ for authored props. Its bed is a child, so correct
	# the child's transform after construction just as Cloudreach does.
	var bed := rest.get_node_or_null(^"CampCreatureBed") as Node3D
	var bed_spec: Dictionary = camp.creature_bed
	if bed != null:
		var bed_at: Array = bed_spec.at
		bed.global_position = Vector3(float(bed_at[0]), _ground(world, float(bed_at[0]), float(bed_at[1])), float(bed_at[1]))
	_build_dressing(root, camp, world)


func _build_dressing(root: Node3D, camp: Dictionary, world: Node3D) -> void:
	var simulation_only := false
	var simulation_value: Variant = world.get("simulation_only")
	if simulation_value != null:
		simulation_only = bool(simulation_value)
	if simulation_only:
		return
	var dressing := Node3D.new()
	dressing.name = str(camp.id) + "Dressing"
	root.add_child(dressing)
	var at: Array = camp.at
	for prop: Dictionary in camp.get("props", []):
		var offset: Array = prop.get("offset", [0, 0])
		var x := float(at[0]) + float(offset[0])
		var z := float(at[1]) + float(offset[1])
		var path := str(MODEL_PATHS.get(str(prop.get("model", "")), ""))
		if path.is_empty() or not ResourceLoader.exists(path):
			push_error("Stormwood camp prop is unavailable: " + path)
			continue
		var scene := load(path) as PackedScene
		if scene == null:
			continue
		var instance := scene.instantiate() as Node3D
		if instance == null:
			continue
		instance.name = str(prop.model)
		instance.position = Vector3(x, _ground(world, x, z), z)
		instance.rotation.y = deg_to_rad(float(prop.get("yaw_deg", 0.0)))
		if str(prop.model) == "lightning_rod":
			instance.scale = Vector3.ONE * 0.55
		dressing.add_child(instance)


func _ground(world: Node3D, x: float, z: float) -> float:
	return float(world.call("ground_height_at", x, z)) if world.has_method("ground_height_at") else _field.height_at(x, z)


static func load_config() -> Dictionary:
	return _read(CONFIG_PATH)


static func rest_spec(camp: Dictionary, ground: float) -> Dictionary:
	var at: Array = camp.get("at", [])
	return {
		"at": [float(at[0]), float(at[1])],
		"height": ground,
		"label": "Rest at " + str(camp.get("display_name", camp.get("id", "camp"))),
		"craft": true,
		"craft_label": "Cook and craft",
		"radius": 3.2,
		"creature_bed": (camp.get("creature_bed", {}) as Dictionary).duplicate(true),
	}


static func validate(config: Dictionary, surge: Dictionary = {}, npcs: Dictionary = {}, settlements: Dictionary = {}) -> Array[String]:
	var errors: Array[String] = []
	if str(config.get("realm_id", "")) != "stormwood":
		errors.append("realm_id must be stormwood")
	var camps: Array = config.get("camps", [])
	if camps.size() != 6:
		errors.append("exactly six authored camps are required")
	var safe_zones := {}
	for zone: Dictionary in surge.get("safe_zones", []):
		safe_zones[str(zone.get("id", ""))] = zone
	var ids := {}
	var beds := {}
	for camp: Dictionary in camps:
		var id := str(camp.get("id", ""))
		if id.is_empty() or ids.has(id):
			errors.append("camp ids must be non-empty and unique: " + id)
		ids[id] = true
		var at: Array = camp.get("at", [])
		if at.size() != 2:
			errors.append(id + " has no [x,z] position")
			continue
		var zone: Dictionary = safe_zones.get(str(camp.get("safe_zone_id", "")), {})
		if zone.is_empty():
			errors.append(id + " has no matching Surge safe zone")
		else:
			var centre: Array = zone.at
			if Vector2(float(at[0]), float(at[1])).distance_to(Vector2(float(centre[0]), float(centre[1]))) > float(zone.radius):
				errors.append(id + " lies outside its Surge safe zone")
		for service: String in ["save", "rest", "cook", "creature_recovery"]:
			if not (camp.get("services", []) as Array).has(service):
				errors.append(id + " lacks " + service)
		var bed: Dictionary = camp.get("creature_bed", {})
		var index := int(bed.get("bed_index", 0))
		if index > REST_POINT.AUTHORED_BED_INDEX_CEILING or index < -36 or index > -31 or beds.has(index):
			errors.append(id + " has an invalid or duplicate reserved bed index")
		beds[index] = true
		var bed_at: Array = bed.get("at", [])
		if bed_at.size() != 2:
			errors.append(id + " has no creature-bed [x,z] position")
		for npc: Dictionary in npcs.get("characters", []):
			var npc_at: Array = npc.get("position", [])
			if npc_at.size() >= 3 and Vector2(float(at[0]), float(at[1])).distance_to(Vector2(float(npc_at[0]), float(npc_at[2]))) < MIN_NPC_DISTANCE_M:
				errors.append(id + " overlaps NPC prompt space: " + str(npc.get("id", "?")))
		for structure: Dictionary in settlements.get("structures", []):
			var structure_at: Array = structure.get("at", [])
			if structure_at.size() >= 2 and Vector2(float(at[0]), float(at[1])).distance_to(Vector2(float(structure_at[0]), float(structure_at[1]))) < MIN_NPC_DISTANCE_M:
				errors.append(id + " overlaps settlement footprint: " + str(structure.get("id", "?")))
	if beds.size() != 6:
		errors.append("each camp needs one unique creature bed")
	return errors


static func _read(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}
