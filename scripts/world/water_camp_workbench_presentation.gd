extends RefCounted

const CONFIG_PATH := "res://data/config/water_camp_workbench_presentation.json"
const BOUNDS := preload("res://scripts/characters/render_bounds.gd")
const FINISH := preload("res://scripts/build/build_material_finish.gd")

## Fit installed tools onto the actual scaled bench, so each camp's existing
## crafting offer has a recognizable work surface from either approach.
static func attach(bench: Node3D) -> void:
	if bench.has_node("WorkbenchTools"):
		return
	var top := BOUNDS.measure(bench)
	if top.size.x <= 0.0 or top.size.z <= 0.0:
		return
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	var root := Node3D.new()
	root.name = "WorkbenchTools"
	bench.add_child(root)
	for row: Dictionary in config.tools:
		var holder := Node3D.new()
		holder.name = str(row.id)
		root.add_child(holder)
		var model := (load(str(row.path)) as PackedScene).instantiate() as Node3D
		holder.add_child(model)
		model.rotation_degrees = Vector3(float(row.rotation_deg[0]), float(row.rotation_deg[1]), float(row.rotation_deg[2]))
		FINISH.apply(model)
		var bounds := BOUNDS.measure(holder)
		var factor := minf(top.size.x * float(row.width_fraction) / maxf(bounds.size.x, 0.001),
			top.size.z * float(row.depth_fraction) / maxf(bounds.size.z, 0.001))
		model.scale *= factor
		bounds = BOUNDS.measure(holder)
		holder.position = Vector3(
			top.get_center().x + top.size.x * float(row.at_fraction[0]) - bounds.get_center().x,
			top.end.y + 0.008 - bounds.position.y,
			top.get_center().z + top.size.z * float(row.at_fraction[1]) - bounds.get_center().z)
