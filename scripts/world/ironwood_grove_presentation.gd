extends Node3D

## Collisionless identity layer for The Ironwood Grove. The five harvestable
## trees remain the only ironwoods and keep ownership of every prompt/yield.
## This layer supplies what their source meshes cannot: grounded age-specific
## roots, a crown silhouette visible from the real road, and evidence that the
## adjacent clearing is actively used to work the wood.

const CONFIG_PATH := "res://data/config/ironwood_grove_presentation.json"
const RENDER_BOUNDS := preload("res://scripts/characters/render_bounds.gd")
const IMPORTED_MATERIALS := preload("res://scripts/world/imported_materials.gd")
const WORKBENCH := preload("res://assets/props/quaternius_fantasy/Workbench.gltf")
const ANVIL_LOG := preload("res://assets/props/quaternius_fantasy/Anvil_Log.gltf")
const AXE := preload("res://assets/props/quaternius_fantasy/Axe_Bronze.gltf")
const PICKAXE := preload("res://assets/props/quaternius_fantasy/Pickaxe_Bronze.gltf")
const LOG_SMALL := preload("res://assets/props/kenney_survival/tree-log-small.glb")
const STUMP := preload("res://assets/environment/nature/stump_round.glb")

const BARK := Color("#4b4e49")
const BARK_EDGE := Color("#74766d")
const WORKED_WOOD := Color("#694a2f")
const WARM := Color("#e3a448")

var _root_segments := 0
var _installed_props := 0
var _path_markers := 0
var _lights := 0


func build(world: Node) -> bool:
	if world == null or not world.has_method("ground_height_at"):
		push_error("Ironwood Grove presentation needs ground_height_at()")
		return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	if not parsed is Dictionary:
		push_error("Ironwood Grove presentation config did not parse")
		return false
	var config := parsed as Dictionary
	_build_tree_footings(world, config.get("tree_footings", []))
	_build_route_threshold(world, config.get("route_threshold", {}),
		_vec2(config.get("route_arrival", [])), _vec2(config.get("grove_centre", [])))
	_build_elder_crown(world, config.get("elder_crown", {}))
	_build_crafting_glade(world, config.get("crafting_glade", {}))
	_build_lights(world, config.get("night_lights", []))
	return _root_segments >= 27 and _installed_props >= 8 and _path_markers >= 6 and _lights == 3


func stats() -> Dictionary:
	return {
		"root_segments": _root_segments,
		"installed_props": _installed_props,
		"path_markers": _path_markers,
		"night_lights": _lights,
		"collision_shapes": find_children("*", "CollisionShape3D", true, false).size(),
	}


func _build_tree_footings(world: Node, raw_footings: Array) -> void:
	var roots := Node3D.new()
	roots.name = "VisibleAgeLadderRoots"
	add_child(roots)
	for raw: Variant in raw_footings:
		if not raw is Dictionary:
			continue
		var spec := raw as Dictionary
		var centre := _vec2(spec.get("at", []))
		var radius := float(spec.get("root_radius_m", 0.0))
		var count := int(spec.get("root_count", 0))
		var rise := float(spec.get("root_height_m", 0.0))
		var group := Node3D.new()
		group.name = "Harvest_%d_RootFooting" % int(spec.get("harvest_order", -1))
		roots.add_child(group)
		for i in count:
			var angle := TAU * float(i) / float(count) + float(i % 2) * 0.13
			var direction := Vector2(cos(angle), sin(angle))
			var start := centre + direction * 0.55
			var finish := centre + direction * radius
			var start_y := _ground(world, start) + rise
			var finish_y := _ground(world, finish) + 0.10
			_tapered_segment(group, "Root_%02d" % i,
				Vector3(start.x, start_y, start.y), Vector3(finish.x, finish_y, finish.y),
				0.18 + rise * 0.22, 0.055, BARK if i % 2 == 0 else BARK_EDGE)
			_root_segments += 1


func _build_route_threshold(world: Node, raw: Dictionary,
		arrival: Vector2, grove: Vector2) -> void:
	var centre := _vec2(raw.get("centre", []))
	var forward := (grove - arrival).normalized()
	var lateral := Vector2(forward.y, -forward.x)
	var half_width := float(raw.get("half_width_m", 4.0))
	var height := float(raw.get("height_m", 6.0))
	var crown_colour := Color(str(raw.get("crown_colour", "#b59043")))
	var threshold := Node3D.new()
	threshold.name = "RoadVisibleCrownThreshold"
	add_child(threshold)
	var left := centre + lateral * half_width
	var right := centre - lateral * half_width
	var apex_ground := maxf(_ground(world, left), _ground(world, right))
	_tapered_segment(threshold, "LeftSplitBough",
		Vector3(left.x, _ground(world, left) + 0.12, left.y),
		Vector3(centre.x - lateral.x * 0.75, apex_ground + height, centre.y - lateral.y * 0.75),
		0.36, 0.21, BARK)
	_tapered_segment(threshold, "RightSplitBough",
		Vector3(right.x, _ground(world, right) + 0.12, right.y),
		Vector3(centre.x + lateral.x * 0.75, apex_ground + height, centre.y + lateral.y * 0.75),
		0.36, 0.21, BARK)
	# Three uneven metal leaves form a crown-shaped route read without a text
	# billboard or another shrine. They hang above ordinary traversal height.
	var crown_width := float(raw.get("crown_width_m", 3.2))
	for i in 3:
		var offset := (float(i) - 1.0) * crown_width * 0.34
		var tip := Vector3(centre.x + lateral.x * offset,
			apex_ground + height - 0.7 + absf(float(i) - 1.0) * -0.45,
			centre.y + lateral.y * offset)
		var base := tip - Vector3(0.0, 1.45 if i == 1 else 1.0, 0.0)
		_tapered_segment(threshold, "CrownLeaf_%d" % i, base, tip,
			0.30 if i == 1 else 0.23, 0.04, crown_colour)


func _build_elder_crown(world: Node, raw: Dictionary) -> void:
	var centre := _vec2(raw.get("centre", []))
	var width := float(raw.get("width_m", 7.0))
	var height := float(raw.get("height_m", 7.4))
	var colour := Color(str(raw.get("crown_colour", "#c09a49")))
	var crown := Node3D.new()
	crown.name = "PairedElderCrown"
	add_child(crown)
	var left := centre + Vector2(-width * 0.5, 0.0)
	var right := centre + Vector2(width * 0.5, 0.0)
	var base_y := maxf(_ground(world, left), _ground(world, right))
	var peak := Vector3(centre.x, base_y + height, centre.y)
	_tapered_segment(crown, "WestElderBough", Vector3(left.x, _ground(world, left) + 0.35, left.y),
		peak + Vector3(-0.65, -0.25, 0.0), 0.42, 0.24, BARK)
	_tapered_segment(crown, "EastElderBough", Vector3(right.x, _ground(world, right) + 0.35, right.y),
		peak + Vector3(0.65, -0.25, 0.0), 0.42, 0.24, BARK)
	for i in 3:
		var x_offset := (float(i) - 1.0) * 1.05
		var top := peak + Vector3(x_offset, 0.20 if i == 1 else -0.22, 0.0)
		var bottom := top - Vector3(0.0, 1.2 if i == 1 else 0.85, 0.0)
		_tapered_segment(crown, "WorkedCrownLeaf_%d" % i, bottom, top,
			0.26 if i == 1 else 0.20, 0.035, colour)


func _build_crafting_glade(world: Node, raw: Dictionary) -> void:
	var glade := Node3D.new()
	glade.name = "WorkedIronwoodGlade"
	add_child(glade)
	var path_from := _vec2(raw.get("path_from", []))
	var path_to := _vec2(raw.get("path_to", []))
	for i in 7:
		var t := float(i) / 6.0
		var point := path_from.lerp(path_to, t)
		var marker := MeshInstance3D.new()
		marker.name = "IronwoodRound_%02d" % i
		var disc := CylinderMesh.new()
		disc.top_radius = 0.58 + 0.10 * float(i % 3)
		disc.bottom_radius = disc.top_radius * 1.04
		disc.height = 0.10
		disc.radial_segments = 12
		disc.material = _material(WORKED_WOOD if i % 2 == 0 else BARK_EDGE)
		marker.mesh = disc
		marker.position = Vector3(point.x, _ground(world, point) + 0.035, point.y)
		marker.rotation.y = float(i) * 0.71
		glade.add_child(marker)
		_path_markers += 1

	var workbench := raw.get("workbench", {}) as Dictionary
	_place_asset(world, glade, "InstalledWorkbench", WORKBENCH, workbench)
	var anvil := raw.get("anvil", {}) as Dictionary
	_place_asset(world, glade, "IronwoodAnvil", ANVIL_LOG, anvil)
	var stump := raw.get("stump", {}) as Dictionary
	_place_asset(world, glade, "ChoppingStump", STUMP, stump)
	for i in (raw.get("timber", []) as Array).size():
		var timber_spec := (raw.get("timber", []) as Array)[i] as Dictionary
		_place_asset(world, glade, "WorkedTimber_%02d" % i, LOG_SMALL, timber_spec)
	_build_tool_rack(world, glade, raw.get("tool_rack", {}))


func _build_tool_rack(world: Node, parent: Node3D, raw: Dictionary) -> void:
	var at := _vec2(raw.get("at", []))
	var yaw := deg_to_rad(float(raw.get("yaw_deg", 0.0)))
	var rack := Node3D.new()
	rack.name = "InstalledToolRack"
	rack.position = Vector3(at.x, _ground(world, at), at.y)
	rack.rotation.y = yaw
	parent.add_child(rack)
	_box(rack, "LeftPost", Vector3(0.16, 2.1, 0.16), Vector3(-0.95, 1.05, 0.0), WORKED_WOOD)
	_box(rack, "RightPost", Vector3(0.16, 2.1, 0.16), Vector3(0.95, 1.05, 0.0), WORKED_WOOD)
	_box(rack, "ToolRail", Vector3(2.15, 0.16, 0.18), Vector3(0.0, 1.55, 0.0), WORKED_WOOD)
	_place_local_asset(rack, "InstalledAxe", AXE, Vector3(-0.42, 0.50, -0.18),
		Vector3(deg_to_rad(12.0), 0.0, deg_to_rad(18.0)), 0.82)
	_place_local_asset(rack, "InstalledPickaxe", PICKAXE, Vector3(0.48, 0.52, -0.18),
		Vector3(deg_to_rad(-8.0), 0.0, deg_to_rad(-16.0)), 0.84)


func _build_lights(world: Node, raw_lights: Array) -> void:
	var lighting := Node3D.new()
	lighting.name = "RestrainedNightWayfinding"
	add_child(lighting)
	for raw: Variant in raw_lights:
		if not raw is Dictionary:
			continue
		var spec := raw as Dictionary
		var at := _vec2(spec.get("at", []))
		var holder := Node3D.new()
		holder.name = str(spec.get("name", "GroveLantern"))
		holder.position = Vector3(at.x, _ground(world, at) + float(spec.get("height_m", 2.0)), at.y)
		lighting.add_child(holder)
		var source := MeshInstance3D.new()
		source.name = "VisibleAmberSource"
		var orb := SphereMesh.new()
		orb.radius = 0.11
		orb.height = 0.22
		var glow := _material(WARM)
		glow.emission_enabled = true
		glow.emission = WARM
		glow.emission_energy_multiplier = 1.25
		orb.material = glow
		source.mesh = orb
		holder.add_child(source)
		var light := OmniLight3D.new()
		light.name = "LocalWarmPool"
		light.light_color = WARM
		light.light_energy = float(spec.get("energy", 1.0))
		light.omni_range = float(spec.get("range_m", 6.0))
		light.shadow_enabled = false
		holder.add_child(light)
		_lights += 1


func _place_asset(world: Node, parent: Node3D, node_name: String,
		scene: PackedScene, raw: Dictionary) -> void:
	var model := scene.instantiate() as Node3D
	if model == null:
		return
	model.name = node_name
	IMPORTED_MATERIALS.make_dielectric(model)
	var bounds := RENDER_BOUNDS.measure(model)
	if bounds.size.y <= 0.001:
		model.free()
		return
	var target_height := float(raw.get("target_height_m", 1.0))
	var scale_factor := target_height / bounds.size.y
	var at := _vec2(raw.get("at", []))
	model.scale = Vector3.ONE * scale_factor
	model.rotation.y = deg_to_rad(float(raw.get("yaw_deg", 0.0)))
	model.position = Vector3(at.x, _ground(world, at) - bounds.position.y * scale_factor - 0.04, at.y)
	parent.add_child(model)
	_installed_props += 1


func _place_local_asset(parent: Node3D, node_name: String, scene: PackedScene,
		at: Vector3, rotation: Vector3, target_height: float) -> void:
	var model := scene.instantiate() as Node3D
	if model == null:
		return
	model.name = node_name
	IMPORTED_MATERIALS.make_dielectric(model)
	var bounds := RENDER_BOUNDS.measure(model)
	if bounds.size.y <= 0.001:
		model.free()
		return
	var scale_factor := target_height / bounds.size.y
	model.scale = Vector3.ONE * scale_factor
	model.position = at - Vector3(0.0, bounds.position.y * scale_factor, 0.0)
	model.rotation = rotation
	parent.add_child(model)
	_installed_props += 1


func _tapered_segment(parent: Node3D, node_name: String, start: Vector3,
		finish: Vector3, bottom_radius: float, top_radius: float, colour: Color) -> void:
	var direction := finish - start
	if direction.length() <= 0.01:
		return
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var mesh := CylinderMesh.new()
	mesh.height = direction.length()
	mesh.bottom_radius = bottom_radius
	mesh.top_radius = top_radius
	mesh.radial_segments = 10
	mesh.rings = 3
	mesh.material = _material(colour)
	instance.mesh = mesh
	instance.position = (start + finish) * 0.5
	instance.basis = _basis_from_y(direction.normalized())
	parent.add_child(instance)


func _box(parent: Node3D, node_name: String, size: Vector3,
		at: Vector3, colour: Color) -> void:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = _material(colour)
	instance.mesh = mesh
	instance.position = at
	parent.add_child(instance)


func _material(colour: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.88
	return material


func _basis_from_y(axis: Vector3) -> Basis:
	var helper := Vector3.FORWARD if absf(axis.dot(Vector3.FORWARD)) < 0.92 else Vector3.RIGHT
	var x_axis := helper.cross(axis).normalized()
	var z_axis := x_axis.cross(axis).normalized()
	return Basis(x_axis, axis, z_axis)


func _ground(world: Node, at: Vector2) -> float:
	var value := float(world.call("ground_height_at", at.x, at.y))
	return 0.0 if is_nan(value) else value


func _vec2(raw: Variant) -> Vector2:
	if raw is Array and (raw as Array).size() >= 2:
		return Vector2(float(raw[0]), float(raw[1]))
	return Vector2.ZERO
