extends Node3D

## Collisionless identity layer for The Ironwood Grove. The five harvestable
## trees keep ownership of every prompt/yield. The hero geometry is rooted at
## the oldest live harvest seat and only augments its old-growth silhouette.
## This layer also supplies grounded age-specific roots, a worn arrival, and
## evidence that the adjacent clearing is actively used to work the wood.

const CONFIG_PATH := "res://data/config/ironwood_grove_presentation.json"
const RENDER_BOUNDS := preload("res://scripts/characters/render_bounds.gd")
const IMPORTED_MATERIALS := preload("res://scripts/world/imported_materials.gd")
const WORKBENCH := preload("res://assets/props/quaternius_fantasy/Workbench.gltf")
const ANVIL_LOG := preload("res://assets/props/quaternius_fantasy/Anvil_Log.gltf")
const AXE := preload("res://assets/props/quaternius_fantasy/Axe_Bronze.gltf")
const PICKAXE := preload("res://assets/props/quaternius_fantasy/Pickaxe_Bronze.gltf")
const LOG_SMALL := preload("res://assets/props/kenney_survival/tree-log-small.glb")
const STUMP := preload("res://assets/environment/nature/stump_round.glb")
const HERO_FOLIAGE := preload("res://assets/environment/stylized_nature/Bush_Common.gltf")
const ANCIENT_TREE_SHADER := preload("res://shaders/ironwood_ancient_tree.gdshader")

const BARK := Color("#392d27")
const BARK_EDGE := Color("#75604a")
const WORKED_WOOD := Color("#694a2f")
const WARM := Color("#e3a448")

var _root_segments := 0
var _installed_props := 0
var _path_markers := 0
var _lights := 0
var _hero_branches := 0
var _hero_leaf_clusters := 0
var _hero_model_installed := false
var _arrival_stations := 0
var _workyard_structures := 0
var _craft_processes := 0
var _habitation_cues := 0
var _lightning_scar_segments := 0
var _lightning_heart_built := false
var _lightning_lights := 0


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
	_build_arrival_floor(world, config.get("arrival_floor", {}))
	_build_hero_tree(world, config.get("hero_tree", {}))
	_build_lightning_heart(world, config.get("lightning_heart", {}), config.get("hero_tree", {}))
	_build_root_city(world, config.get("root_city", {}), config.get("hero_tree", {}))
	_build_crafting_glade(world, config.get("crafting_glade", {}))
	_build_lights(world, config.get("night_lights", []))
	return _root_segments >= 27 and _installed_props >= 14 and _path_markers >= 6 \
		and (_hero_model_installed or (_hero_branches >= 16 and _hero_leaf_clusters >= 9)) \
		and _arrival_stations >= 24 and _workyard_structures >= 4 \
		and _craft_processes >= 3 and _habitation_cues >= 11 and _lights == 5 \
		and _lightning_heart_built \
		and _lightning_lights >= 3


func stats() -> Dictionary:
	return {
		"root_segments": _root_segments,
		"installed_props": _installed_props,
		"path_markers": _path_markers,
		"night_lights": _lights,
		"hero_branches": _hero_branches,
		"hero_leaf_clusters": _hero_leaf_clusters,
		"hero_model_installed": _hero_model_installed,
		"arrival_stations": _arrival_stations,
		"workyard_structures": _workyard_structures,
		"craft_processes": _craft_processes,
		"habitation_cues": _habitation_cues,
		"lightning_heart_built": _lightning_heart_built,
		"lightning_scar_segments": _lightning_scar_segments,
		"lightning_lights": _lightning_lights,
		"collision_shapes": find_children("*", "CollisionShape3D", true, false).size(),
	}


func _build_arrival_floor(world: Node, raw: Dictionary) -> void:
	var floor_root := Node3D.new()
	floor_root.name = "IronwoodWornArrival"
	add_child(floor_root)
	var waypoints: Array[Vector2] = []
	for raw_point: Variant in raw.get("waypoints", []):
		waypoints.append(_vec2(raw_point))
	if waypoints.size() < 2:
		return
	var spacing := maxf(0.75, float(raw.get("station_spacing_m", 1.35)))
	var centres: Array[Vector2] = []
	for segment_index in waypoints.size() - 1:
		var a := waypoints[segment_index]
		var b := waypoints[segment_index + 1]
		var steps := maxi(2, int(ceilf(a.distance_to(b) / spacing)) + 1)
		for step in steps:
			if segment_index > 0 and step == 0:
				continue
			centres.append(a.lerp(b, float(step) / float(steps - 1)))
	var left: Array[Vector3] = []
	var right: Array[Vector3] = []
	var half_width := float(raw.get("half_width_m", 2.15))
	var wander := float(raw.get("edge_wander_m", 0.42))
	for index in centres.size():
		var previous := centres[maxi(0, index - 1)]
		var following := centres[mini(centres.size() - 1, index + 1)]
		var forward := (following - previous).normalized()
		var lateral := Vector2(-forward.y, forward.x)
		var width := half_width + sin(float(index) * 0.73) * wander \
			+ sin(float(index) * 0.29 + 1.8) * wander * 0.45
		var left_at := centres[index] - lateral * width
		var right_at := centres[index] + lateral * width
		left.append(Vector3(left_at.x, _ground(world, left_at) + 0.018, left_at.y))
		right.append(Vector3(right_at.x, _ground(world, right_at) + 0.018, right_at.y))
		_arrival_stations += 1
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	tool.set_material(_arrival_material(raw))
	for index in centres.size() - 1:
		_add_ground_triangle(tool, left[index], left[index + 1], right[index],
			Vector2(0.0, float(index) * spacing), Vector2(0.0, float(index + 1) * spacing),
			Vector2(1.0, float(index) * spacing))
		_add_ground_triangle(tool, right[index], left[index + 1], right[index + 1],
			Vector2(1.0, float(index) * spacing), Vector2(0.0, float(index + 1) * spacing),
			Vector2(1.0, float(index + 1) * spacing))
	tool.generate_normals()
	var ribbon := MeshInstance3D.new()
	ribbon.name = "TerrainConformingWearRibbon"
	ribbon.mesh = tool.commit()
	floor_root.add_child(ribbon)


func _build_hero_tree(world: Node, raw: Dictionary) -> void:
	var at := _vec2(raw.get("at", []))
	var base_y := _ground(world, at)
	var height := float(raw.get("height_m", 18.5))
	var model_path := str(raw.get("model", ""))
	if not model_path.is_empty():
		var packed := load(model_path) as PackedScene
		if packed != null:
			var installed := packed.instantiate() as Node3D
			if installed != null:
				installed.name = "AncientIronwoodHero"
				var installed_bounds := RENDER_BOUNDS.measure(installed)
				if installed_bounds.size.y > 0.001:
					var scale_factor := Vector3(
						float(raw.get("canopy_width_m", 38.0)) / maxf(installed_bounds.size.x, 0.001),
						height / installed_bounds.size.y,
						float(raw.get("canopy_depth_m", 28.0)) / maxf(installed_bounds.size.z, 0.001))
					installed.scale = scale_factor
					installed.rotation.y = deg_to_rad(float(raw.get("yaw_deg", 0.0)))
					installed.position = Vector3(at.x,
						base_y - installed_bounds.position.y * scale_factor.y
						- float(raw.get("bury_depth_m", 0.0)), at.y)
					_override_material(installed, _ancient_tree_material(raw))
					add_child(installed)
					_hero_model_installed = true
					return
				installed.free()
	var width := float(raw.get("canopy_width_m", 17.0))
	var depth := float(raw.get("canopy_depth_m", 11.5))
	var bark := Color(str(raw.get("bark_colour", "#392d27")))
	var edge := Color(str(raw.get("bark_edge_colour", "#75604a")))
	var leaves: Array[Color] = [
		Color(str(raw.get("leaf_dark", "#294b3d"))),
		Color(str(raw.get("leaf_mid", "#3f6848"))),
		Color(str(raw.get("leaf_gold", "#858044"))),
	]
	var hero := Node3D.new()
	hero.name = "AncientIronwoodHero"
	add_child(hero)
	var base := Vector3(at.x, base_y + 0.08, at.y)
	var lower_knee := base + Vector3(-0.35, height * 0.31, 0.18)
	var fork := base + Vector3(0.38, height * 0.55, -0.28)
	var crown := base + Vector3(-0.25, height * 0.72, 0.18)
	_tapered_segment(hero, "AncientTrunkLower", base, lower_knee, 1.78, 1.34, bark)
	_tapered_segment(hero, "AncientTrunkMiddle", lower_knee, fork, 1.38, 1.02, edge)
	_tapered_segment(hero, "AncientTrunkUpper", fork, crown, 1.08, 0.72, bark)
	_hero_branches += 3
	var branch_ends: Array[Vector3] = [
		base + Vector3(-width * 0.40, height * 0.68, -depth * 0.12),
		base + Vector3(width * 0.40, height * 0.69, -depth * 0.10),
		base + Vector3(-width * 0.34, height * 0.73, depth * 0.25),
		base + Vector3(width * 0.33, height * 0.76, depth * 0.24),
		base + Vector3(-width * 0.17, height * 0.84, -depth * 0.22),
		base + Vector3(width * 0.18, height * 0.86, depth * 0.08),
		base + Vector3(0.0, height * 0.89, -depth * 0.02),
	]
	for index in branch_ends.size():
		var end := branch_ends[index]
		var shoulder := fork.lerp(crown, 0.18 + float(index % 4) * 0.16)
		var elbow := shoulder.lerp(end, 0.52) + Vector3(0.0, 0.35 + float(index % 2) * 0.35, 0.0)
		_tapered_segment(hero, "AncientBough_%02d_A" % index, shoulder, elbow,
			0.76 - float(index) * 0.045, 0.43, bark if index % 2 == 0 else edge)
		_tapered_segment(hero, "AncientBough_%02d_B" % index, elbow, end,
			0.46, 0.22, edge if index % 2 == 0 else bark)
		_hero_branches += 2
	# R4 placed one small crown at every exposed branch tip, producing a literal
	# candelabra of pom-poms. R6 keeps a broad overlapping core but lowers and
	# varies the edge lobes so structural boughs remain legible beneath one ancient
	# mass rather than disappearing inside a uniform cyan block.
	for index in (raw.get("canopy_lobes", []) as Array).size():
		var lobe := (raw.get("canopy_lobes", []) as Array)[index] as Dictionary
		var offset_raw := lobe.get("offset", []) as Array
		var size_raw := lobe.get("size", []) as Array
		if offset_raw.size() < 3 or size_raw.size() < 3:
			continue
		var centre := base + Vector3(float(offset_raw[0]), float(offset_raw[1]), float(offset_raw[2]))
		var size := Vector3(float(size_raw[0]), float(size_raw[1]), float(size_raw[2]))
		_add_leaf_cluster(hero, "IronwoodCanopyLobe_%02d" % index, centre, size,
			leaves[clampi(int(lobe.get("palette", 0)), 0, leaves.size() - 1)],
			deg_to_rad(float(lobe.get("yaw_deg", 0.0))))
	# Forged collars make the dark gnarled trunk read as ironwood rather than a
	# generic enlarged tree, while remaining narrow enough to preserve bark.
	for index in 3:
		_add_trunk_ring(hero, "ForgedGrowthBand_%02d" % index,
			base + Vector3(-0.16 * float(index), 2.1 + float(index) * 2.25, 0.08),
			1.46 - float(index) * 0.14, _material(Color("#9a7a3f")))


func _build_root_city(world: Node, raw: Dictionary, hero_raw: Dictionary) -> void:
	var hero_at := _vec2(hero_raw.get("at", []))
	var city := Node3D.new()
	city.name = "IronwoodRootCity"
	add_child(city)
	for index in (raw.get("entries", []) as Array).size():
		var spec := (raw.get("entries", []) as Array)[index] as Dictionary
		var offset := _vec2(spec.get("offset", []))
		var at := hero_at + offset
		var holder := Node3D.new()
		holder.name = "RootGate_%02d" % index
		holder.position = Vector3(at.x, _ground(world, at), at.y)
		holder.rotation.y = deg_to_rad(float(spec.get("yaw_deg", 0.0)))
		city.add_child(holder)
		var width := float(spec.get("width_m", 2.4))
		var height := float(spec.get("height_m", 4.2))
		_box(holder, "DeepHollow", Vector3(width, height, 0.22),
			Vector3(0.0, height * 0.5, 0.0), Color("#151711"))
		_box(holder, "IronwoodLintel", Vector3(width + 0.75, 0.38, 0.52),
			Vector3(0.0, height + 0.08, -0.04), WORKED_WOOD)
		for side: float in [-1.0, 1.0]:
			_tapered_segment(holder, "RootGatePost", Vector3(side * (width * 0.5 + 0.23), 0.05, -0.04),
				Vector3(side * (width * 0.5 + 0.23), height, -0.04), 0.22, 0.17, BARK_EDGE)
		_add_warm_panel(holder, "GateLantern", Vector2(0.46, 0.62),
			Vector3(0.0, height * 0.68, -0.17))
		_habitation_cues += 1


	for index in (raw.get("hollows", []) as Array).size():
		var spec := (raw.get("hollows", []) as Array)[index] as Dictionary
		var offset := _vec2(spec.get("offset", []))
		var at := hero_at + offset
		var holder := Node3D.new()
		holder.name = "WarmHollow_%02d" % index
		holder.position = Vector3(at.x,
			_ground(world, at) + float(spec.get("height_m", 6.0)), at.y)
		holder.rotation.y = deg_to_rad(float(spec.get("yaw_deg", 0.0)))
		city.add_child(holder)
		var size_raw := spec.get("size", [0.9, 1.3]) as Array
		var size := Vector2(float(size_raw[0]), float(size_raw[1]))
		_box(holder, "HollowRecess", Vector3(size.x + 0.34, size.y + 0.34, 0.20),
			Vector3.ZERO, Color("#171813"))
		_add_warm_panel(holder, "OccupiedWindow", size, Vector3(0.0, 0.0, -0.13))
		_habitation_cues += 1


	for index in (raw.get("galleries", []) as Array).size():
		var spec := (raw.get("galleries", []) as Array)[index] as Dictionary
		var offset := _vec2(spec.get("offset", []))
		var at := hero_at + offset
		var holder := Node3D.new()
		holder.name = "TimberGallery_%02d" % index
		holder.position = Vector3(at.x,
			_ground(world, at) + float(spec.get("height_m", 10.0)), at.y)
		holder.rotation.y = deg_to_rad(float(spec.get("yaw_deg", 0.0)))
		city.add_child(holder)
		var width := float(spec.get("width_m", 6.0))
		_box(holder, "GalleryDeck", Vector3(width, 0.32, 1.35), Vector3.ZERO, WORKED_WOOD)
		for rail_index in 5:
			var x := -width * 0.42 + float(rail_index) * width * 0.21
			_box(holder, "GalleryPost", Vector3(0.12, 1.05, 0.12),
				Vector3(x, 0.66, -0.58), BARK_EDGE)
		_box(holder, "GalleryRail", Vector3(width * 0.92, 0.13, 0.13),
			Vector3(0.0, 1.05, -0.58), BARK_EDGE)
		_add_warm_panel(holder, "GalleryLamp", Vector2(0.34, 0.44),
			Vector3(0.0, 1.35, -0.64))
		_habitation_cues += 1


func _build_lightning_heart(world: Node, raw: Dictionary, hero_raw: Dictionary) -> void:
	if raw.is_empty():
		return
	var hero_at := _vec2(hero_raw.get("at", []))
	var base_y := _ground(world, hero_at)
	var heart := Node3D.new()
	heart.name = "IronwoodLightningHeart"
	heart.position = Vector3(hero_at.x, base_y, hero_at.y)
	add_child(heart)
	var colour := Color(str(raw.get("colour", "#9fe9ff")))
	var core_size_raw := raw.get("core_size", [8.0, 30.0, 2.4]) as Array
	var core_size := Vector3(float(core_size_raw[0]), float(core_size_raw[1]),
		float(core_size_raw[2]))
	var core := MeshInstance3D.new()
	core.name = "TrappedLegendaryCore"
	var core_mesh := SphereMesh.new()
	core_mesh.radius = 0.5
	core_mesh.height = 1.0
	core_mesh.radial_segments = 20
	core_mesh.rings = 12
	core_mesh.material = _lightning_material(colour, 2.8)
	core.mesh = core_mesh
	core.scale = core_size
	core.position = Vector3(0.0, float(raw.get("height_m", 70.0)),
		float(raw.get("front_offset_m", -15.0)))
	heart.add_child(core)
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.32, 1.0])
	gradient.colors = PackedColorArray([
		Color(colour, 0.88), Color(colour, 0.32), Color(colour, 0.0)])
	var aura_texture := GradientTexture2D.new()
	aura_texture.width = 128
	aura_texture.height = 128
	aura_texture.fill = GradientTexture2D.FILL_RADIAL
	aura_texture.fill_from = Vector2(0.5, 0.5)
	aura_texture.fill_to = Vector2(1.0, 0.5)
	aura_texture.gradient = gradient
	var aura := Sprite3D.new()
	aura.name = "LightningHeartAura"
	aura.texture = aura_texture
	aura.pixel_size = float(raw.get("aura_pixel_size", 0.24))
	aura.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	aura.shaded = false
	aura.modulate = Color(1.0, 1.0, 1.0, float(raw.get("aura_alpha", 0.72)))
	aura.position = core.position + Vector3(0.0, 0.0, -0.7)
	heart.add_child(aura)
	for index in (raw.get("scar_segments", []) as Array).size():
		var spec := (raw.get("scar_segments", []) as Array)[index] as Dictionary
		var from_raw := spec.get("from", []) as Array
		var to_raw := spec.get("to", []) as Array
		if from_raw.size() < 3 or to_raw.size() < 3:
			continue
		_emissive_segment(heart, "LightningScar_%02d" % index,
			Vector3(float(from_raw[0]), float(from_raw[1]), float(from_raw[2])),
			Vector3(float(to_raw[0]), float(to_raw[1]), float(to_raw[2])),
			float(spec.get("radius_m", 0.35)), colour)
		_lightning_scar_segments += 1
	for index in (raw.get("field_lights", []) as Array).size():
		var light_spec := (raw.get("field_lights", []) as Array)[index] as Dictionary
		var at_raw := light_spec.get("at", []) as Array
		if at_raw.size() < 3:
			continue
		var light := OmniLight3D.new()
		light.name = str(light_spec.get("name", "LightningSurge_%02d" % index))
		light.light_color = Color(str(raw.get("light_colour", "#75d8ff")))
		light.light_energy = float(light_spec.get("energy", raw.get("light_energy", 4.0)))
		light.omni_range = float(light_spec.get("range_m", raw.get("light_range_m", 48.0)))
		light.shadow_enabled = true
		light.position = Vector3(float(at_raw[0]), float(at_raw[1]), float(at_raw[2]))
		heart.add_child(light)
		_lightning_lights += 1
	_lightning_heart_built = true


func _add_warm_panel(parent: Node3D, node_name: String, size: Vector2, at: Vector3) -> void:
	var panel := MeshInstance3D.new()
	panel.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = Vector3(size.x, size.y, 0.08)
	var material := _material(Color("#76502a"))
	material.emission_enabled = true
	material.emission = Color("#c4792d")
	material.emission_energy_multiplier = 0.55
	mesh.material = material
	panel.mesh = mesh
	panel.position = at
	parent.add_child(panel)


func _add_leaf_cluster(parent: Node3D, node_name: String, at: Vector3,
		size: Vector3, colour: Color, yaw: float = 0.0) -> void:
	var instance := HERO_FOLIAGE.instantiate() as Node3D
	if instance == null:
		return
	instance.name = node_name
	var bounds := RENDER_BOUNDS.measure(instance)
	if bounds.size.x <= 0.001 or bounds.size.y <= 0.001 or bounds.size.z <= 0.001:
		instance.free()
		return
	var scale_factor := Vector3(size.x / bounds.size.x, size.y / bounds.size.y, size.z / bounds.size.z)
	instance.scale = scale_factor
	instance.position = at - Vector3(bounds.get_center().x * scale_factor.x,
		bounds.get_center().y * scale_factor.y, bounds.get_center().z * scale_factor.z)
	instance.rotation.y = yaw
	_override_material(instance, _material(colour))
	parent.add_child(instance)
	_hero_leaf_clusters += 1


func _add_trunk_ring(parent: Node3D, node_name: String, at: Vector3,
		radius: float, material: Material) -> void:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var ring := TorusMesh.new()
	ring.inner_radius = radius
	ring.outer_radius = radius + 0.12
	ring.rings = 28
	ring.ring_segments = 7
	ring.material = material
	instance.mesh = ring
	instance.position = at
	parent.add_child(instance)


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
	_build_raw_stock(world, glade, raw.get("raw_stock", {}))
	_build_timber_shelter(world, glade, raw)
	_build_hewing_bay(world, glade, raw.get("hewing_bay", {}))
	_build_board_rack(world, glade, raw.get("board_rack", {}))


func _build_timber_shelter(world: Node, parent: Node3D, raw: Dictionary) -> void:
	var shelter := raw.get("timber_shelter", {}) as Dictionary
	var at := _vec2(shelter.get("at", []))
	var ground := _ground(world, at)
	var frame := Node3D.new()
	frame.name = "InstalledTimberShelter"
	frame.position = Vector3(at.x, ground, at.y)
	frame.rotation.y = deg_to_rad(float(shelter.get("yaw_deg", 0.0)))
	parent.add_child(frame)
	# R7's 6.2m portal plus second rail read as an oversized empty fence and hid
	# the conversion process. R8 keeps a compact installed saw gantry: enough
	# silhouette to frame the cut, with open sides and no chest-height rail.
	_box(frame, "SawGantryHeader", Vector3(3.8, 0.28, 0.34),
		Vector3(0.0, 2.55, 0.0), WORKED_WOOD)
	for side: float in [-1.0, 1.0]:
		_box(frame, "SawGantryPost", Vector3(0.28, 2.62, 0.32),
			Vector3(side * 1.65, 1.31, 0.0), BARK_EDGE)
		_tapered_segment(frame, "GantryKneeBrace", Vector3(side * 1.58, 1.72, 0.0),
			Vector3(side * 1.05, 2.46, 0.0), 0.12, 0.09, WORKED_WOOD)
	_installed_props += 1
	_workyard_structures += 1
	for index in (raw.get("lumber_stack", []) as Array).size():
		var log_spec := (raw.get("lumber_stack", []) as Array)[index] as Dictionary
		_place_asset(world, parent, "ShelteredIronwoodLog_%02d" % index, LOG_SMALL, log_spec)


func _build_raw_stock(world: Node, parent: Node3D, raw: Dictionary) -> void:
	var at := _vec2(raw.get("at", []))
	var stock := Node3D.new()
	stock.name = "RawIronwoodStockCradle"
	stock.position = Vector3(at.x, _ground(world, at), at.y)
	stock.rotation.y = deg_to_rad(float(raw.get("yaw_deg", 0.0)))
	parent.add_child(stock)
	var length := float(raw.get("log_length_m", 3.5))
	var count := clampi(int(raw.get("log_count", 4)), 3, 5)
	for side: float in [-1.0, 1.0]:
		_tapered_segment(stock, "StockCradleLeg", Vector3(side * 1.35, 0.02, -0.62),
			Vector3(side * 1.05, 0.72, 0.0), 0.12, 0.09, WORKED_WOOD)
	for index in count:
		var layer := index / 2
		var z := (-0.36 if index % 2 == 0 else 0.36) if layer == 0 else 0.0
		var y := 0.42 + float(layer) * 0.48
		_tapered_segment(stock, "UnmilledIronwoodLog_%02d" % index,
			Vector3(-length * 0.5, y, z), Vector3(length * 0.5, y, z),
			0.27, 0.24, BARK if index % 2 == 0 else BARK_EDGE)
	_workyard_structures += 1
	_craft_processes += 1


func _build_hewing_bay(world: Node, parent: Node3D, raw: Dictionary) -> void:
	var at := _vec2(raw.get("at", []))
	var bay := Node3D.new()
	bay.name = "ActiveHewingBay"
	bay.position = Vector3(at.x, _ground(world, at), at.y)
	bay.rotation.y = deg_to_rad(float(raw.get("yaw_deg", 0.0)))
	parent.add_child(bay)
	var length := float(raw.get("beam_length_m", 5.4))
	for side: float in [-1.0, 1.0]:
		var x := side * length * 0.29
		_tapered_segment(bay, "TrestleLegFront", Vector3(x - 0.38, 0.02, -0.48),
			Vector3(x, 0.78, -0.18), 0.12, 0.09, BARK_EDGE)
		_tapered_segment(bay, "TrestleLegBack", Vector3(x + 0.38, 0.02, 0.48),
			Vector3(x, 0.78, 0.18), 0.12, 0.09, BARK_EDGE)
		_box(bay, "TrestleCrossbar", Vector3(0.22, 0.18, 1.35),
			Vector3(x, 0.75, 0.0), WORKED_WOOD)
	# A short round infeed, a visible saw gap and a squared outfeed blank make the
	# raw-to-shaped conversion readable in silhouette instead of one long rail.
	_tapered_segment(bay, "RoundInfeedStock", Vector3(-length * 0.47, 1.05, 0.0),
		Vector3(-0.28, 1.05, 0.0), 0.30, 0.28, BARK)
	_box(bay, "ShapedIronwoodBlank", Vector3(length * 0.43, 0.54, 0.64),
		Vector3(length * 0.25, 1.05, 0.0), Color("#6a452b"))
	_box(bay, "FreshHewnFace", Vector3(length * 0.39, 0.07, 0.67),
		Vector3(length * 0.25, 1.32, 0.0), Color("#b9854b"))
	_box(bay, "SuspendedFrameSawBlade", Vector3(0.08, 1.64, 0.58),
		Vector3(0.0, 1.79, -0.08), Color("#c5c9bd"))
	_box(bay, "FrameSawSpine", Vector3(1.18, 0.13, 0.18),
		Vector3(0.0, 2.52, -0.08), Color("#7a512f"))
	for side: float in [-1.0, 1.0]:
		_box(bay, "FrameSawHandle", Vector3(0.12, 1.32, 0.15),
			Vector3(side * 0.50, 1.90, -0.08), WORKED_WOOD)
	# The installed axe makes this visibly a work process rather than another log pile.
	_place_local_asset(bay, "HewingAxe", AXE, Vector3(0.35, 0.83, -0.38),
		Vector3(deg_to_rad(14.0), deg_to_rad(18.0), deg_to_rad(-62.0)), 1.05)
	for index in 14:
		var chip := MeshInstance3D.new()
		chip.name = "FreshIronwoodChip_%02d" % index
		var chip_mesh := BoxMesh.new()
		chip_mesh.size = Vector3(0.18 + 0.07 * float(index % 3), 0.035,
			0.07 + 0.025 * float((index + 1) % 3))
		chip_mesh.material = _material(Color("#b8884d"))
		chip.mesh = chip_mesh
		chip.position = Vector3(-0.95 + float(index % 7) * 0.31, 0.035,
			-0.72 - float(index / 7) * 0.30)
		chip.rotation.y = float(index) * 0.71
		bay.add_child(chip)
	_workyard_structures += 1
	_craft_processes += 1


func _build_board_rack(world: Node, parent: Node3D, raw: Dictionary) -> void:
	var at := _vec2(raw.get("at", []))
	var rack := Node3D.new()
	rack.name = "SeasoningBoardRack"
	rack.position = Vector3(at.x, _ground(world, at), at.y)
	rack.rotation.y = deg_to_rad(float(raw.get("yaw_deg", 0.0)))
	parent.add_child(rack)
	for side: float in [-1.0, 1.0]:
		_box(rack, "RackPost", Vector3(0.18, 2.0, 0.18),
			Vector3(side * 1.65, 1.0, 0.0), BARK_EDGE)
		_tapered_segment(rack, "RackFoot", Vector3(side * 1.9, 0.04, -0.55),
			Vector3(side * 1.45, 0.62, 0.0), 0.11, 0.08, WORKED_WOOD)
	var board_count := clampi(int(raw.get("board_count", 6)), 4, 8)
	for index in board_count:
		var y := 0.45 + float(index) * 0.22
		_box(rack, "SeasoningBoard_%02d" % index, Vector3(3.35, 0.12, 0.38),
			Vector3(0.0, y, sin(float(index) * 1.7) * 0.11),
			Color("#815b37") if index % 2 == 0 else Color("#9a7043"))
	_box(rack, "FinishedBoardBundle", Vector3(2.75, 0.36, 0.78),
		Vector3(0.0, 0.22, 0.72), Color("#a97843"))
	_workyard_structures += 1
	_craft_processes += 1


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


func _emissive_segment(parent: Node3D, node_name: String, start: Vector3,
		finish: Vector3, radius: float, colour: Color) -> void:
	var direction := finish - start
	if direction.length() <= 0.01:
		return
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var mesh := CylinderMesh.new()
	mesh.height = direction.length()
	mesh.bottom_radius = radius
	mesh.top_radius = maxf(0.12, radius * 0.58)
	mesh.radial_segments = 8
	mesh.rings = 2
	mesh.material = _lightning_material(colour, 3.2)
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


func _arrival_material(raw: Dictionary) -> StandardMaterial3D:
	var material := _material(Color(str(raw.get("soil_colour", "#5b4a38"))))
	var texture_path := str(raw.get("soil_texture", ""))
	if not texture_path.is_empty():
		material.albedo_texture = load(texture_path) as Texture2D
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return material


func _add_ground_triangle(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3,
		uv_a: Vector2, uv_b: Vector2, uv_c: Vector2) -> void:
	tool.set_uv(uv_a)
	tool.add_vertex(a)
	tool.set_uv(uv_b)
	tool.add_vertex(b)
	tool.set_uv(uv_c)
	tool.add_vertex(c)


func _material(colour: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.88
	return material


func _lightning_material(colour: Color, energy: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.emission_enabled = true
	material.emission = colour
	material.emission_energy_multiplier = energy
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.roughness = 0.25
	return material


func _ancient_tree_material(raw: Dictionary) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = ANCIENT_TREE_SHADER
	material.set_shader_parameter("albedo_texture",
		load(str(raw.get("albedo_texture", ""))) as Texture2D)
	material.set_shader_parameter("leaf_tint", Color(str(raw.get("leaf_tint", "#75ad66"))))
	material.set_shader_parameter("bark_tint", Color(str(raw.get("bark_tint", "#9e633d"))))
	material.set_shader_parameter("exposure", float(raw.get("texture_exposure", 0.72)))
	material.set_shader_parameter("tree_centre_xz", _vec2(raw.get("at", [])))
	return material


func _override_material(node: Node, material: Material) -> void:
	if node is MeshInstance3D:
		(node as MeshInstance3D).material_override = material
	for child: Node in node.get_children():
		_override_material(child, material)


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
