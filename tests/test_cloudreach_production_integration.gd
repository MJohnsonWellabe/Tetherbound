extends "res://tests/test_case.gd"

const WORLD := preload("res://scripts/world/cloudreach_world.gd")
const RUNTIME := preload("res://scripts/world/cloudreach_world_runtime.gd")


func test_spatial_surface_broadphase_preserves_stack_and_negative_cells() -> void:
	var world := WORLD.new()
	world.call("register_runtime_surface",{"kind":"rect","centre":Vector2(-128,-128),"half":Vector2(4,4),"height":100.0})
	world.call("register_runtime_surface",{"kind":"ellipse","centre":Vector2(-128,-128),"half":Vector2(20,3),"rotation":PI/2,"height":400.0})
	assert_eq(world.call("ground_height_at",-128.0,-128.0),400.0,"map takes highest real stratum")
	assert_eq(world.call("ground_height_near",Vector3(-128,101,-128)),100.0,"actor retains nearby lower stratum")
	assert_eq(world.call("ground_height_at",-128.0,-115.0),400.0,"rotated ellipse extends into adjacent grid cell")
	assert_true(is_nan(world.call("ground_height_at",-115.0,-128.0)),"conservative broad phase does not create ground")
	world.call("register_runtime_surface",{"kind":"segment","a":Vector3(120,20,-10),"b":Vector3(140,40,-10),"half_width":2.0})
	assert_eq(world.call("ground_height_at",130.0,-10.0),30.0,"late arena/path surface invalidates index and interpolates")
	world.free()


func test_counterweight_barrier_is_on_restricted_branch_not_lower_junction() -> void:
	var world:=WORLD.new()
	var config: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/config/cloudreach_world.json"))
	world.set("_config",config)
	var gate: Dictionary={}
	for spec: Dictionary in config.gates:
		if spec.id=="upper_counterweight_gate":
			gate=spec
	var at: Vector3=world.call("_vec3",gate.position)
	var junction:=Vector3(-100,470,2440)
	assert_true(at.distance_to(junction)>40.0,"locked gate leaves the mandatory lower junction open")
	# F06: the gate stands where the pass enters Upper Cloudreach, on the
	# [-820,620,3480]->[-720,700,3680] segment, past the Windscar beacon crown.
	assert_true(Geometry3D.get_closest_point_to_segment(at,Vector3(-820,620,3480),Vector3(-720,700,3680)).distance_to(at)<0.1,"gate still belongs to the protected upper route")
	assert_true(absf(float(world.call("_gate_yaw_for",gate.requires_unlock,at))-atan2(100.0,200.0))<0.001,"offset gate faces across its own slope")
	world.free()


func test_scene_composer_contract_has_no_meadows_story_or_duplicate_feed() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/world/cloudreach_world_runtime.gd")
	assert_false(source.contains("sequence_director.gd"),"Meadows opening cannot mount in Cloudreach")
	assert_false(source.contains("progression_feedback_hud.gd"),"composer reuses PlaygroundHUD feed")
	assert_false(source.contains("resolve_enemy_for_fixture"),"production composition has no test victory path")
	var runtime := RUNTIME.new()
	assert_false(runtime.get("_mounted"),"mount guard begins closed")
	runtime.free()


func test_bridge_cut_does_not_remove_its_neighboring_approach() -> void:
	var world:=WORLD.new()
	world.set("_config",JSON.parse_string(FileAccess.get_file_as_string("res://data/config/cloudreach_world.json")))
	var approach: Array=world.call("_ground_sections_for_segment","broken_causeway_main",Vector3(-320,300,1040),Vector3(-540,330,1280))
	assert_eq(approach.size(),1,"an endpoint nearby does not carve the approach")
	assert_eq(approach[0].b,Vector3(-540,330,1280),"approach reaches the exact west abutment")
	var span: Array=world.call("_ground_sections_for_segment","broken_causeway_main",Vector3(-540,330,1280),Vector3(-511.2,338.25,1305.625))
	assert_true(span.is_empty(),"real bridge span still has no supporting ground ribbon")
	assert_true(world.call("_bridge_interior_point","broken_causeway_main",Vector3(-511.2,338.25,1305.625)),"internal deck bend cannot acquire a blocking land cap")
	var join: Vector3=world.call("_landing_join",Vector3(-450,342,1360),Vector3(-468,338.25,1344),6.56,0.75)
	assert_true(join.x< -456.0 and is_equal_approx(join.y,342.0),"short bridge ramp reaches cap edge at cap height")
	world.free()


func test_installed_timber_decks_keep_collision_without_a_visible_proxy_slab() -> void:
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/cloudreach_world.json"))
	var materials := {}
	for key: String in ["stone", "wood", "masonry_trim", "rope", "bronze"]:
		materials[key] = StandardMaterial3D.new()
	for id: String in ["first_rope_span", "split_stone_viaduct"]:
		var spec: Dictionary = {}
		for candidate: Dictionary in config.get("bridges", []):
			if str(candidate.get("id", "")) == id:
				spec = candidate
		assert_false(spec.is_empty(), "the actual authored bridge fixture exists")
		if spec.is_empty():
			continue
		var world := WORLD.new()
		world.set("_materials", materials)
		var section := Node3D.new()
		world.add_child(section)
		var points: Array = spec.get("deck_profile", spec.get("endpoints", []))
		var a: Vector3 = world.call("_vec3", points[0])
		var b: Vector3 = world.call("_vec3", points[1])
		var width := float(spec.get("width_m", 3.2))
		world.call("_build_bridge_section", section, spec, a, b)
		var stone := str(spec.get("type", "")).contains("stone")
		var deck := section.get_node(^"WalkableDeck") as Node3D
		var proxy := deck.get_child(0) as MeshInstance3D
		assert_eq(proxy.visible, stone, "only timber replaces the visible collision box with installed floors")
		var collider := deck.get_node(^"Collision") as StaticBody3D
		var shape_node := collider.get_child(0) as CollisionShape3D
		var shape := shape_node.shape as BoxShape3D
		assert_false(shape_node.disabled, "the original walking collider remains enabled")
		assert_eq(shape.size, Vector3(width, 0.42, a.distance_to(b)), "physical deck dimensions remain exact")
		var up := deck.basis.y.normalized()
		var lift := up * (0.2 if stone else 0.0)
		var top_centre := deck.position + up * shape.size.y * 0.5
		assert_almost_eq((top_centre - (a.lerp(b, 0.5) + lift)).length(), 0.0, 0.0001,
			"collision top stays on the authored deck datum")
		assert_almost_eq((top_centre - deck.basis.z * shape.size.z * 0.5 - a - lift).length(), 0.0, 0.0001)
		assert_almost_eq((top_centre + deck.basis.z * shape.size.z * 0.5 - b - lift).length(), 0.0, 0.0001)
		assert_eq((section.get_node(^"BatchedDeckPlanks") as MultiMeshInstance3D).visible, stone,
			"stone paving stays visible and timber has no second generic plank layer")
		var modules := 0
		for child: Node in section.get_children():
			if child is MultiMeshInstance3D and child.name == "VillageTimberDeckModules":
				modules += 1
				var batch := child as MultiMeshInstance3D
				assert_eq(batch.multimesh.instance_count,
					maxi(1, ceili(a.distance_to(b) / 2.0)) * maxi(1, ceili(width / 2.0)),
					"installed modules still cover the full authored span and width")
				var mesh := batch.multimesh.mesh
				assert_true(mesh.get_surface_count() > 0, "actual imported floor mesh is present")
				for surface in mesh.get_surface_count():
					var arrays := mesh.surface_get_arrays(surface)
					assert_true((arrays[Mesh.ARRAY_TEX_UV] as PackedVector2Array).size() > 0,
						"installed floor UVs survive instead of becoming a flat proxy")
					var material := mesh.surface_get_material(surface) as BaseMaterial3D
					assert_true(material != null, "installed floor material survives")
					if material != null:
						assert_true(material.get_texture(BaseMaterial3D.TEXTURE_ALBEDO) != null,
							"the authored timber texture is present")
		assert_eq(modules, 0 if stone else 1, "one installed timber batch, no new stone modules")
		var surfaces: Array = world.get("_surfaces")
		assert_eq(surfaces.size(), 1)
		assert_eq(surfaces[0].a, a)
		assert_eq(surfaces[0].b, b)
		assert_eq(surfaces[0].half_width, width * 0.5)
		world.free()


## Routes-B 06k a1: a trainer climbing observatory_summit_link stopped dead at
## (432.5, 919.2, 4519.7), 20 m short of the Old Wind Observatory pad, against
## a 49-degree `LandmarkLedge` face. The ribbon joined the pad at the 6.6 m
## landing cap, but the landmark's walkable crown stays flat at its height out
## to `_landmark_cap_radius` (18 m, the 38x36 `ObservatoryWalkableCrown`), so a
## climbing ribbon ran 1-2 m under that crown at its rim. Every ground ribbon
## ending on a landmark must stay at crown height across that whole flat crown.
const LANDMARK_RIM_STEP_TOLERANCE_M := 0.15


func test_ribbons_reach_every_landmark_crown_at_crown_height() -> void:
	var world := WORLD.new()
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/cloudreach_world.json"))
	var visual: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/cloudreach_visual.json"))
	visual = preload("res://scripts/world/cloudreach_visual_candidate.gd").apply(visual, "visual")
	visual = preload("res://scripts/world/cloudreach_biome_look.gd").apply_visual(visual)
	world.set("_config", config)
	world.set("_visual_config", visual)
	world.call("_collect_all_route_lines")
	var lines: Array = world.get("_all_route_lines")
	var checked := {}
	for landmark: Dictionary in config.get("landmarks", []):
		if str(landmark.get("category", "")) == "settlement":
			continue # Its 48x48 terrace is the floor, not a ledge crown.
		var centre: Vector3 = world.call("_vec3", landmark.position)
		var cap := float(world.call("_landmark_cap_radius", str(landmark.id)))
		for route: Dictionary in config.get("routes", []):
			if str(route.get("traversal_mode", "ground")) != "ground":
				continue
			var polyline: Array = route.get("polyline", [])
			for i in polyline.size():
				if not (world.call("_vec3", polyline[i]) as Vector3).is_equal_approx(centre):
					continue
				for j: int in [i - 1, i + 1]:
					if j < 0 or j >= polyline.size():
						continue
					var away: Vector3 = world.call("_vec3", polyline[j])
					var direction := Vector3(away.x - centre.x, 0.0, away.z - centre.z).normalized()
					# The crown box is axis-aligned, so its rim along this
					# approach is the Chebyshev edge `_landing_join` uses.
					var rim := cap / maxf(absf(direction.x), absf(direction.z)) - 0.25
					var lowest := INF
					var r := 0.5
					while r <= rim:
						var at := centre + direction * r
						var height := _route_height_at(lines, str(route.id), at)
						if is_finite(height):
							lowest = minf(lowest, height)
						r += 0.5
					var label := "%s %s toward %s" % [str(landmark.id), str(route.id), str(away)]
					checked[label] = true
					assert_true(lowest >= centre.y - LANDMARK_RIM_STEP_TOLERANCE_M,
						"%s: ribbon stays at crown height %.2f across the %.1f m flat crown (lowest %.2f)" % [
							label, centre.y, rim, lowest])
	assert_true(checked.has("old_wind_observatory observatory_summit_link toward (450.0, 900.0, 4660.0)"),
		"the reported observatory_summit_link climb is checked (%s)" % str(checked.keys()))
	world.free()


func _route_height_at(lines: Array, route_id: String, at: Vector3) -> float:
	for line: Dictionary in lines:
		if str(line.route_id) != route_id:
			continue
		var a: Vector3 = line.a
		var b: Vector3 = line.b
		var flat := Vector2(b.x - a.x, b.z - a.z)
		var t := clampf(Vector2(at.x - a.x, at.z - a.z).dot(flat) / flat.length_squared(), 0.0, 1.0)
		if Vector2(a.x + flat.x * t - at.x, a.z + flat.y * t - at.z).length() < 0.1:
			return lerpf(a.y, b.y, t)
	return INF
