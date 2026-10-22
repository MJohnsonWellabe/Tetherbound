extends RefCounted

## Separate OFF gate: the queued shared-rig comparison never opts into this pass.
const PATH := "res://data/config/cloudreach_cliffhold_detail.json"
const PREFABS_PATH := "res://data/config/building_prefabs.json"
const LOOK := preload("res://scripts/world/cloudreach_biome_look.gd")
const CAPTURE_SCRIPTS := [
	"tools/capture_cloudreach_biome_look.gd",
	"tools/capture_cloudreach_f40_matrix.gd",
]
static var _loaded := false
static var _active: Dictionary = {}


static func preview_allowed(arguments: PackedStringArray, user_arguments: PackedStringArray) -> bool:
	if not user_arguments.has("--cloudreach-cliffhold-detail-candidate") \
			or not LOOK.preview_allowed(arguments, user_arguments):
		return false
	return LOOK.capture_script(arguments) in CAPTURE_SCRIPTS


static func config() -> Dictionary:
	if _loaded:
		return _active
	_loaded = true
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if raw is Dictionary and (bool(raw.get("enabled", false)) or preview_allowed(
			OS.get_cmdline_args(), OS.get_cmdline_user_args())
			or bool(preload("res://scripts/world/cloudreach_settlement_life.gd").config().get("cliffhold_detail", false))):
		# The settlement candidate may retune the cottage lights it turns on.
		_active = preload("res://scripts/world/cloudreach_settlement_life.gd").apply(raw, "cliffhold_detail_overrides")
	return _active


static func cottages(world: Node3D) -> Array[Node3D]:
	var result: Array[Node3D] = []
	var settlement := world.get_node_or_null(^"Landmarks/CliffholdSettlement")
	if settlement == null:
		return result
	for child: Node in settlement.get_children():
		if child is Node3D and (str(child.name).begins_with("Terrace_cottage_a_") \
				or str(child.name).begins_with("Terrace_cottage_b_")):
			result.append(child as Node3D)
			if result.size() == 4:
				break
	return result


static func lighting_sites(world: Node3D, spec: Dictionary) -> Array[Dictionary]:
	var sites: Array[Dictionary] = []
	if spec.is_empty():
		return sites
	var recipes: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PREFABS_PATH))
	var prefabs: Dictionary = recipes.get("prefabs", {})
	for house: Node3D in cottages(world):
		var site: Dictionary = spec.door_lantern.duplicate(true)
		site["id"] = "CliffholdSettlement/" + str(house.name)
		# The walk-path threshold is 1.1m OUTSIDE the facade. Mount against the
		# recipe's door plane, retaining the cottage's own elevation and yaw.
		var prefab := "cottage_a" if str(house.name).begins_with("Terrace_cottage_a_") else "cottage_b"
		var at := door_fixture_position(prefabs[prefab], site)
		site["fixtures"] = [{"at": [at.x, at.y, at.z]}]
		sites.append(site)
	return sites


static func door_fixture_position(recipe: Dictionary, site: Dictionary) -> Vector3:
	var door: Array = recipe.door.at
	var offset: Array = site.door_offset_m
	return Vector3(float(door[0]) + float(offset[0]), float(door[1]) + float(offset[1]),
		float(door[2]) + float(offset[2]))


static func lantern_back_shift(bounds: AABB, height: float, wall_mounted: bool) -> float:
	# Existing fixtures are depth-centred. A wall fixture moves forward by
	# half its scaled depth, placing its back (rather than centre) on its mount.
	return bounds.size.z * 0.5 * height / maxf(bounds.size.y, 0.01) if wall_mounted else 0.0


static func window_lamps(world: Node3D, spec: Dictionary) -> Array[Dictionary]:
	var lamps: Array[Dictionary] = []
	if spec.is_empty():
		return lamps
	var windows: Dictionary = spec.windows
	for house: Node3D in cottages(world):
		# Retinted prefab materials are shared with other houses/biomes. Clone
		# only this instance's glass, preserving its albedo, texture and normals.
		var copies: Dictionary = {}
		for node: Node in house.find_children("*", "MeshInstance3D", true, false):
			var mesh := node as MeshInstance3D
			if mesh.mesh == null:
				continue
			for surface in mesh.mesh.get_surface_count():
				var material := mesh.get_active_material(surface) as StandardMaterial3D
				if material == null or material.resource_name != "MI_WindowGlass":
					continue
				var id := material.get_instance_id()
				if not copies.has(id):
					var glass := material.duplicate() as StandardMaterial3D
					glass.emission_enabled = true
					glass.emission = Color(str(windows.colour))
					copies[id] = glass
					lamps.append({"light": null, "material": glass,
						"day_glow": float(windows.day_energy), "glow": float(windows.night_energy)})
				mesh.set_surface_override_material(surface, copies[id] as StandardMaterial3D)
	return lamps


static func wall_profile(top: Vector3, bottom: Vector3, outward: Vector3, spec: Dictionary) -> PackedVector3Array:
	var points := PackedVector3Array([top])
	if spec.is_empty():
		points.append(bottom)
		return points
	var height := top.y - bottom.y
	var depths: Array = spec.depths_m
	var recesses: Array = spec.recesses_m
	var warp := sin(top.x * float(spec.warp_frequency_x) + top.z * float(spec.warp_frequency_z)) \
		* float(spec.depth_warp_m)
	var compression := minf(1.0, maxf(height, 0.0) * 0.85 / (float(depths.back()) + warp))
	# All neighboring faces ask for the same endpoint profile. Crown/bottom
	# endpoints are exact and recesses go inward from the original wall only.
	for index in depths.size():
		var depth := (float(depths[index]) + warp) * compression
		points.append(top.lerp(bottom, depth / maxf(height, 0.001)) - outward * float(recesses[index]) * compression)
	points.append(bottom)
	return points
