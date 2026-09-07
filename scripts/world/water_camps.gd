extends Node3D

## Authored preparation stops, using the same sleep vote and recipe transaction
## as every other realm. Scene construction never grants a build objective.
const REST := preload("res://scripts/world/rest_point.gd")
const TENT := preload("res://scripts/build/camp_tent.gd")
const FIRE := preload("res://scripts/build/campfire.gd")
const BED := preload("res://scripts/build/creature_bed.gd")
const PIECE := preload("res://scripts/build/build_piece.gd")
const PLAYER_BED := preload("res://scripts/build/player_bed.gd")
const WORKBENCH := "res://assets/props/quaternius_fantasy/Workbench.gltf"
var camps: Dictionary = {}
var world: Node3D

func build(owner_world: Node3D) -> void:
	world = owner_world
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_camps.json"))
	var tuning: Dictionary = data.tuning
	for row: Dictionary in data.camps:
		var at := Vector3(float(row.at[0]), 0, float(row.at[1]))
		at.y = world.ground_height_at(at.x, at.z)
		if not is_finite(at.y) or at.y < 0.6:
			push_error("Water camp lacks dry terrain: " + str(row.id))
			continue
		var craft := at + _offset(tuning.craft_offset_xz)
		var rest := REST.new()
		rest.name = str(row.id)
		add_child(rest)
		rest.build({"at":row.at, "label":row.label, "radius":tuning.prompt_radius_m,
			"craft_at":[craft.x, craft.z], "craft_label":"Craft at workbench"})
		camps[str(row.id)] = rest
		var tent := TENT.new()
		tent.name = str(row.id) + "_shelter"
		add_child(tent)
		tent.global_position = at
		tent.build_real()
		var sleeping_mat := PIECE.new()
		sleeping_mat.name = str(row.id) + "_bedroll"
		add_child(sleeping_mat)
		sleeping_mat.global_position = at + Vector3.UP * PLAYER_BED.BED_SINK
		sleeping_mat.build_real(PLAYER_BED.MESH_PATH)
		var bench := PIECE.new()
		bench.name = str(row.id) + "_workbench"
		add_child(bench)
		bench.global_position = _grounded(craft)
		bench.build_real(WORKBENCH, {}, Vector3.ONE * float(tuning.workbench_scale))
		rest.get_node("CraftInteractable").global_position = bench.global_position + Vector3.UP * 0.6
		var fire := FIRE.new()
		fire.name = str(row.id) + "_fire"
		add_child(fire)
		fire.global_position = _grounded(at + _offset(tuning.fire_offset_xz))
		fire.build_real()
		# One crafting offer per camp, on the visible workbench.
		fire.get_node("CraftInteractable").queue_free()
		var bed := BED.new()
		bed.name = str(row.id) + "_creature_bed"
		add_child(bed)
		bed.global_position = _grounded(at + _offset(tuning.creature_bed_offset_xz))
		bed.build_real(false)
		bed.set_build_index(int(row.creature_bed_index))
	if world.simulation_only:
		visible = false
		_disable_prompts(self)

func _grounded(at: Vector3) -> Vector3:
	return Vector3(at.x, world.ground_height_at(at.x, at.z), at.z)

static func _offset(raw: Array) -> Vector3:
	return Vector3(float(raw[0]), 0, float(raw[1]))

func _disable_prompts(node: Node) -> void:
	if node.has_method("interaction_offer") and node.get("enabled") != null:
		node.set("enabled", false)
	for child: Node in node.get_children():
		_disable_prompts(child)
