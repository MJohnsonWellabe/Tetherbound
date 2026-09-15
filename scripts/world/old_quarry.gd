extends Node3D

## SD16 — the Old Quarry, spec §3 Band 2 and §32 rung 2.
##
## Reachable past the South Bridge (`SC14`), the first place the player works
## Rootstone out of the ground, and the first physical evidence that Team
## Tether is routing something out from under the region.
##
## HARD RULE, from §32's reveal ladder and the backlog item: this is EVIDENCE,
## not explanation. Nothing here talks. There is no interactable on the
## hardware, no note, no villager standing by to say what it is. The player
## gets a working face somebody walked away from, foundations older than the
## village, ground that is visibly dying around the machinery, and a line of
## lit pylons leaving on the stronghold's own bearing — and draws their own
## conclusion, which is the one thing the relay (`SE23`) and the stronghold
## cannot do for them later if it is spent here.
##
## This file places the authored built elements that belong to the quarry itself:
##
##   * the old foundations, from the `quarry_foundation` prefab — the same
##     Medieval kit the village is built from (D24), sunk so only the bottom
##     course stands.
##   * the conduit run, by calling `severed_spokes.gd`'s own pylon builder.
##   * one modeled shift lantern and a visual-only supported end treatment for
##     the retained foundation slab. Neither adds gameplay collision.
##
## Everything else about the quarry is owned by the file that already owns
## that kind of thing, and is listed in `data/config/old_quarry.json`'s header:
## the terrain and the drain radii are `terrain_playground.json`, the thinned
## and dying vegetation is `vegetation.json`, the Rootstone deposits are
## `harvest.json` (placed by `playground_world.gd` like every other harvest
## node), the abandoned gear is `props.json`'s `quarry_station` cluster, and
## the named region on the map is `map_landmarks.json`.
##
## WHY THE PYLONS ARE NOT REBUILT HERE. `severed_spokes.gd::_build_pylons`
## already does mesh fitting, per-pylon lit/dead materials, aim-along-the-line
## orientation, box colliders and the sampled-parabola conduit spans between
## consecutive pylons — roughly a hundred lines that took a render pass and a
## material bug (`gl_compatibility` turning an emissive pylon into a white
## ghost) to get right. A second implementation would be a second set of those
## bugs. So an instance of that script is parented here as the holder and
## handed this quarry's own `pylons` block in the shape it already reads. The
## grammar is identical on purpose (D41: one drain network, one visual
## language); only the STATE differs, and that difference is the story —
## severed and dead at the seven spokes, whole and lit here.

const PREFABS := preload("res://scripts/world/building_prefabs.gd")
const SEVERED_SPOKES := preload("res://scripts/world/severed_spokes.gd")
const IMPORTED_MATERIALS := preload("res://scripts/world/imported_materials.gd")
const WALL_LANTERN := preload("res://assets/props/quaternius_fantasy/Lantern_Wall.gltf")
const CONFIG_PATH := "res://data/config/old_quarry.json"

var _foundations := 0
var _pylons := 0
var _work_lights := 0
var _foundation_finishes := 0
var _worked_cut_pieces := 0
var _arrival_scatter_removed := 0


## `world` is only ever asked for `ground_height_at` — the same duck-typed
## climb `village.gd`, `road_gate.gd` and `severed_spokes.gd` use (D09: never
## a raycast for ground).
func build(world: Node3D) -> void:
	var config := _load_config()
	if config.is_empty():
		push_warning("old_quarry.json missing or unreadable; the quarry has no foundations or hardware")
		return

	_clear_arrival_sightline(world, config.get("arrival_scatter_clear", {}))
	_clear_arrival_sightline(world, config.get("approach_scatter_clear", {}))
	_clear_arrival_sightline(world, config.get("cut_face_scatter_clear", {}))
	_build_foundations(world, config.get("foundations", []))
	_build_worked_cut(world, config.get("worked_cut", {}))
	_build_foundation_finish(world, config.get("foundation_finish", []))
	_build_work_lights(world, config.get("work_lights", []))
	_build_conduit_run(world, config.get("pylons", {}))
	_build_conduit_head_station(world)
	print("[quarry] %d foundations, %d pylons, %d finish treatment standing" % [
		_foundations, _pylons, _foundation_finishes])


## For tests and capture tools: what actually stood, so neither has to count
## nodes by name.
func stats() -> Dictionary:
	return {
		"foundations": _foundations,
		"pylons": _pylons,
		"work_lights": _work_lights,
		"foundation_finishes": _foundation_finishes,
		"worked_cut_pieces": _worked_cut_pieces,
		"arrival_scatter_removed": _arrival_scatter_removed,
	}


## R27 keeps R26's asymmetric battered cut but places its visible surfaces on
## the camera-facing side of the retained, collision-authoritative rock masses.
## Installed rocks remain visible around the crown and keep all production
## collision; the faceted faces, thick ledges and two apron branches are visual
## only, joining the worked floor to both retained wagon and conduit head.
func _build_worked_cut(world: Node, raw: Variant) -> void:
	if not raw is Dictionary:
		return
	var spec := raw as Dictionary
	var pieces := spec.get("pieces", []) as Array
	if pieces.is_empty():
		return
	var holder := Node3D.new()
	holder.name = "OldQuarryWorkedCut"
	add_child(holder)
	var texture_path := str(spec.get("albedo_texture", ""))
	var normal_path := str(spec.get("normal_texture", ""))
	var extraction_index := 0
	_build_worked_floor(world, holder, spec.get("floor", {}), texture_path, normal_path)
	for raw_piece: Variant in pieces:
		if not raw_piece is Dictionary:
			continue
		var piece := raw_piece as Dictionary
		var at_raw := piece.get("at", []) as Array
		var size_raw := piece.get("size", []) as Array
		if at_raw.size() != 2 or size_raw.size() != 3:
			continue
		var at := Vector2(float(at_raw[0]), float(at_raw[1]))
		var ground := float(world.call("ground_height_at", at.x, at.y))
		if is_nan(ground) or is_inf(ground):
			continue
		var size := Vector3(float(size_raw[0]), float(size_raw[1]), float(size_raw[2]))
		var centre := Vector3(at.x, ground + float(piece.get("lift_m", size.y * 0.5)), at.y)
		var instance: MeshInstance3D
		var shape := str(piece.get("shape", "box"))
		if shape == "grounded_strip":
			var from_raw := piece.get("from", []) as Array
			var to_raw := piece.get("to", []) as Array
			if from_raw.size() != 2 or to_raw.size() != 2:
				continue
			instance = _textured_ground_strip(world,
				str(piece.get("name", "WorkedCutStrip")),
				Vector2(float(from_raw[0]), float(from_raw[1])),
				Vector2(float(to_raw[0]), float(to_raw[1])),
				float(piece.get("width_m", size.z)),
				float(piece.get("thickness_m", size.y)),
				float(piece.get("lift_m", 0.08)),
				Color(str(piece.get("colour", "#a49a82"))), texture_path, normal_path)
			holder.add_child(instance)
			_worked_cut_pieces += 1
			continue
		elif shape == "faceted_wedge":
			instance = _textured_wedge(str(piece.get("name", "WorkedCutPiece")), size,
				Color(str(piece.get("colour", "#a49a82"))), texture_path, normal_path,
				float(piece.get("batter_m", 0.18)),
				float(piece.get("top_left_scale", 0.94)),
				float(piece.get("top_right_scale", 1.0)))
		else:
			instance = _textured_box(str(piece.get("name", "WorkedCutPiece")), size,
				Color(str(piece.get("colour", "#a49a82"))), texture_path, normal_path)
		instance.position = centre
		instance.rotation.y = deg_to_rad(float(piece.get("yaw_deg", 0.0)))
		holder.add_child(instance)
		if str(piece.get("role", "")) == "extraction_face":
			_add_embedded_face_strata(instance, size, extraction_index,
				texture_path, normal_path)
			extraction_index += 1
		_worked_cut_pieces += 1
	_build_quarry_shoring(world, holder)


func _build_worked_floor(world: Node, holder: Node3D, raw: Variant,
		texture_path: String, normal_path: String) -> void:
	if raw is not Dictionary:
		return
	var spec := raw as Dictionary
	var from_raw := spec.get("from", []) as Array
	var to_raw := spec.get("to", []) as Array
	if from_raw.size() != 2 or to_raw.size() != 2:
		return
	var start := Vector2(float(from_raw[0]), float(from_raw[1]))
	var finish := Vector2(float(to_raw[0]), float(to_raw[1]))
	var floor := _irregular_work_floor(world, start, finish,
		float(spec.get("width_m", 10.0)), float(spec.get("lift_m", 0.11)),
		Color(str(spec.get("colour", "#8f8067"))), texture_path, normal_path)
	holder.add_child(floor)
	# The floor is compacted work ground, not meadow. Runtime footprint markers
	# use GrassField's production exclusion path and do not invalidate scatter.
	var length := start.distance_to(finish)
	var steps := maxi(ceili(length / 4.0), 1)
	for index in steps + 1:
		var marker := Node3D.new()
		marker.name = "WorkedFloorGrassClear%02d" % index
		var at := start.lerp(finish, float(index) / float(steps))
		marker.position = Vector3(at.x, 0.0, at.y)
		marker.set_meta("grass_clear_radius", float(spec.get("grass_clear_radius_m", 6.2)))
		marker.add_to_group("grass_clear")
		holder.add_child(marker)


func _irregular_work_floor(world: Node, start: Vector2, finish: Vector2,
		width: float, lift: float, colour: Color, texture_path: String,
		normal_path: String) -> MeshInstance3D:
	var along := (finish - start).normalized()
	var across := Vector2(-along.y, along.x)
	var length := start.distance_to(finish)
	var rows := maxi(ceili(length / 1.15), 8)
	const COLUMNS := 7
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in rows + 1:
		var t := float(row) / float(rows)
		var centre := start.lerp(finish, t)
		centre += across * sin(t * TAU * 1.7 + 0.45) * 0.55
		var local_width := width * (0.88 + 0.10 * sin(t * TAU * 2.3 + 1.1))
		var end_fade := smoothstep(0.0, 0.09, t) * smoothstep(0.0, 0.09, 1.0 - t)
		for column in COLUMNS:
			var across_t := float(column) / float(COLUMNS - 1)
			var signed := across_t * 2.0 - 1.0
			var edge_wander := sin(t * TAU * 3.1 + float(column) * 1.37) * 0.16
			var at := centre + across * (signed * local_width * 0.5 + edge_wander)
			var ground := float(world.call("ground_height_at", at.x, at.y))
			var edge_alpha := smoothstep(0.0, 0.34, minf(across_t, 1.0 - across_t))
			surface.set_color(Color(1.0, 1.0, 1.0, edge_alpha * end_fade))
			surface.set_uv(Vector2(at.x, at.y) * 0.035)
			surface.add_vertex(Vector3(at.x, ground + lift, at.y))
	for row in rows:
		for column in COLUMNS - 1:
			var a := row * COLUMNS + column
			var b := a + 1
			var c := (row + 1) * COLUMNS + column
			var d := c + 1
			surface.add_index(a); surface.add_index(c); surface.add_index(b)
			surface.add_index(b); surface.add_index(c); surface.add_index(d)
	surface.generate_normals()
	var material := _worked_cut_material(colour, texture_path, normal_path)
	material.vertex_color_use_as_albedo = true
	material.uv1_triplanar = false
	material.uv1_world_triplanar = false
	material.uv1_scale = Vector3.ONE
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var floor := MeshInstance3D.new()
	floor.name = "WorkedQuarryFloor"
	floor.mesh = surface.commit()
	floor.material_override = material
	return floor


func _build_quarry_shoring(world: Node, holder: Node3D) -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("#7a5437")
	material.roughness = 0.92
	var wood_texture := "res://assets/buildings/quaternius_medieval/T_WoodTrim_BaseColor.png"
	var wood_normal := "res://assets/buildings/quaternius_medieval/T_WoodTrim_Normal.png"
	if ResourceLoader.exists(wood_texture):
		material.albedo_texture = load(wood_texture)
	if ResourceLoader.exists(wood_normal):
		material.normal_enabled = true
		material.normal_texture = load(wood_normal)
		material.normal_scale = 0.6
	var frames: Array[Dictionary] = [
		{"centre": Vector2(382.0, 1788.8), "width": 4.2, "height": 3.15, "yaw": -8.0},
		{"centre": Vector2(388.8, 1787.5), "width": 3.7, "height": 2.75, "yaw": 18.0},
	]
	for frame_index in frames.size():
		var spec := frames[frame_index]
		var at := spec["centre"] as Vector2
		var ground := float(world.call("ground_height_at", at.x, at.y))
		if is_nan(ground) or is_inf(ground):
			continue
		var root := Node3D.new()
		root.name = "WorkedFaceShoring%02d" % frame_index
		root.position = Vector3(at.x, ground, at.y)
		root.rotation.y = deg_to_rad(float(spec["yaw"]))
		holder.add_child(root)
		var width := float(spec["width"])
		var height := float(spec["height"])
		var cavity := MeshInstance3D.new()
		cavity.name = "RecessedWorkedBay"
		var cavity_mesh := BoxMesh.new()
		cavity_mesh.size = Vector3(width - 0.55, height - 0.35, 0.18)
		var cavity_material := _worked_cut_material(Color("#514739"),
			"res://assets/environment/terrain/Rock030_Color.jpg",
			"res://assets/environment/terrain/Rock030_NormalGL.jpg")
		cavity_mesh.material = cavity_material
		cavity.mesh = cavity_mesh
		cavity.position = Vector3(0.0, height * 0.48, 2.05)
		root.add_child(cavity)
		var bay_floor := MeshInstance3D.new()
		bay_floor.name = "WorkedBayFloor"
		var bay_floor_mesh := BoxMesh.new()
		bay_floor_mesh.size = Vector3(width - 0.45, 0.16, 3.8)
		bay_floor_mesh.material = _worked_cut_material(Color("#756651"),
			"res://assets/environment/terrain/Rock030_Color.jpg",
			"res://assets/environment/terrain/Rock030_NormalGL.jpg")
		bay_floor.mesh = bay_floor_mesh
		bay_floor.position = Vector3(0.0, 0.05, 1.55)
		root.add_child(bay_floor)
		for side in [-1.0, 1.0]:
			var post := MeshInstance3D.new()
			post.name = "ShoringPost"
			var post_mesh := BoxMesh.new()
			post_mesh.size = Vector3(0.28, height, 0.32)
			post_mesh.material = material
			post.mesh = post_mesh
			post.position = Vector3(side * width * 0.5, height * 0.5, 0.0)
			post.rotation.z = deg_to_rad(side * -4.0)
			root.add_child(post)
		var header := MeshInstance3D.new()
		header.name = "ShoringHeader"
		var header_mesh := BoxMesh.new()
		header_mesh.size = Vector3(width + 0.55, 0.32, 0.38)
		header_mesh.material = material
		header.mesh = header_mesh
		header.position = Vector3(0.0, height - 0.12, 0.0)
		header.rotation.z = deg_to_rad(2.5 if frame_index == 0 else -3.0)
		root.add_child(header)
		_quarry_beam_between(root, "ShoringBraceLeft",
			Vector3(-width * 0.46, 0.3, -0.12),
			Vector3(-width * 0.08, height - 0.38, -0.12), 0.20, material)
		_quarry_beam_between(root, "ShoringBraceRight",
			Vector3(width * 0.46, 0.3, -0.12),
			Vector3(width * 0.08, height - 0.38, -0.12), 0.20, material)
		for side in [-1.0, 1.0]:
			var depth_rail := MeshInstance3D.new()
			depth_rail.name = "ShoringDepthRail"
			var depth_mesh := BoxMesh.new()
			depth_mesh.size = Vector3(0.24, 0.24, 2.4)
			depth_mesh.material = material
			depth_rail.mesh = depth_mesh
			depth_rail.position = Vector3(side * width * 0.48, height - 0.22, 1.12)
			root.add_child(depth_rail)
		var bay_light := OmniLight3D.new()
		bay_light.name = "BayWorkGlow"
		bay_light.position = Vector3(0.0, height * 0.58, 1.35)
		bay_light.light_color = Color("#ffc27a")
		bay_light.light_energy = 3.4
		bay_light.omni_range = 6.5
		bay_light.omni_attenuation = 1.35
		bay_light.shadow_enabled = false
		root.add_child(bay_light)
		var bay_source := MeshInstance3D.new()
		bay_source.name = "BayLanternSource"
		var bay_source_mesh := SphereMesh.new()
		bay_source_mesh.radius = 0.12
		bay_source_mesh.height = 0.24
		var source_material := StandardMaterial3D.new()
		source_material.albedo_color = Color("#ffd59a")
		source_material.emission_enabled = true
		source_material.emission = Color("#ff9a3d")
		source_material.emission_energy_multiplier = 2.0
		bay_source_mesh.material = source_material
		bay_source.mesh = bay_source_mesh
		bay_source.position = bay_light.position
		root.add_child(bay_source)
		for side in [-1.0, 1.0]:
			var back_rock := _textured_asset_rock(
				"BayBackRock%d_%d" % [frame_index, int(side)],
				Vector3(width * 0.42, height * 0.42, 1.15), Color("#756957"),
				"res://assets/environment/terrain/Rock030_Color.jpg",
				"res://assets/environment/terrain/Rock030_NormalGL.jpg")
			if back_rock != null:
				back_rock.position = Vector3(side * width * 0.27, height * 0.26, 1.72)
				back_rock.rotation.y = deg_to_rad(side * 18.0)
				root.add_child(back_rock)


## Low-relief installed rock strata sit partly inside each continuous cut panel.
## Their broken crowns and seams remove the last rectangular silhouette without
## turning the face back into a freestanding boulder pile.
func _add_embedded_face_strata(face: MeshInstance3D, size: Vector3, face_index: int,
		texture_path: String, normal_path: String) -> void:
	var strata := Node3D.new()
	strata.name = "EmbeddedWorkedStrata"
	face.add_child(strata)
	for face_side in [-1.0, 1.0]:
		for course in 2:
			for section in 3:
				var width := size.x * (0.39 if section == 1 else 0.34)
				var rock := _textured_asset_rock(
					"FaceStratum_%d_%d_%d_%d" % [face_index, int(face_side), course, section],
					Vector3(width, size.y * 0.24, size.z * 0.42),
					Color("#9f8b68" if course == 0 else "#b29b72"),
					texture_path, normal_path)
				if rock == null:
					continue
				rock.position = Vector3((float(section) - 1.0) * size.x * 0.29,
					-size.y * 0.29 + float(course) * size.y * 0.34
						+ sin(float(face_index * 3 + section)) * 0.10,
					face_side * size.z * 0.43)
				rock.rotation.y = deg_to_rad(float(section - 1) * 9.0
					+ (180.0 if face_side > 0.0 else 0.0))
				rock.rotation.z = deg_to_rad(float((face_index + section + course) % 3 - 1) * 5.0)
				strata.add_child(rock)
		for crown_index in 3:
			var crown := _textured_asset_rock(
				"FaceCrown_%d_%d_%d" % [face_index, int(face_side), crown_index],
				Vector3(size.x * 0.42, size.y * 0.30, size.z * 0.48),
				Color("#aa956f"), texture_path, normal_path)
			if crown == null:
				continue
			crown.position = Vector3((float(crown_index) - 1.0) * size.x * 0.30,
				size.y * 0.45 + sin(float(face_index + crown_index)) * 0.14,
				face_side * size.z * 0.30)
			crown.rotation.y = deg_to_rad(float(crown_index - 1) * 13.0
				+ (180.0 if face_side > 0.0 else 0.0))
			crown.rotation.z = deg_to_rad(float((face_index + crown_index) % 3 - 1) * 7.0)
			strata.add_child(crown)


func _quarry_beam_between(parent: Node3D, node_name: String, start: Vector3,
		finish: Vector3, thickness: float, material: Material) -> void:
	var delta := finish - start
	var beam := MeshInstance3D.new()
	beam.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = Vector3(thickness, delta.length(), thickness)
	mesh.material = material
	beam.mesh = mesh
	beam.position = (start + finish) * 0.5
	beam.quaternion = Quaternion(Vector3.UP, delta.normalized())
	parent.add_child(beam)


## Shallow, visual-only chisel channels break the broad extraction planes into
## worked stone without becoming structural bars or another collision owner.
func _add_cut_scars(face: MeshInstance3D, size: Vector3, face_index: int) -> void:
	var marks := Node3D.new()
	marks.name = "ToolScars"
	face.add_child(marks)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("#4f493d")
	material.roughness = 1.0
	for scar_index in 5:
		var scar := MeshInstance3D.new()
		scar.name = "ChiselScar%02d" % scar_index
		var mesh := BoxMesh.new()
		mesh.size = Vector3(size.x * (0.18 + float(scar_index % 2) * 0.05), 0.055, 0.045)
		mesh.material = material
		scar.mesh = mesh
		var across := (float(scar_index) - 2.0) * size.x * 0.13
		scar.position = Vector3(across, -size.y * 0.30 + float(scar_index) * size.y * 0.14,
			-size.z * 0.5 - 0.018)
		scar.rotation.z = deg_to_rad(-8.0 + float(face_index % 3) * 4.0
			+ float(scar_index % 2) * 11.0)
		marks.add_child(scar)


## The two work handoffs must follow the live quarry floor rather than span it
## as one flat box. R30 sampled only the two outer edges every two metres. The
## planar triangles between those samples still passed through a rolling floor,
## and their buried skirts became the capture tool's strongest-facing faces.
## R31 samples a sub-metre grid across and along the complete top, while keeping
## shallow skirts only on the two outer edges. The mesh is local to its sampled
## midpoint so its Node3D transform remains meaningful to live geometry checks.
func _textured_ground_strip(world: Node, node_name: String, from: Vector2,
		to: Vector2, width: float, thickness: float, lift: float, colour: Color,
		texture_path: String, normal_path: String) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var delta := to - from
	var length := delta.length()
	if length <= 0.05:
		return instance
	var forward := delta / length
	var right := Vector2(-forward.y, forward.x)
	var half_width := maxf(width, 0.8) * 0.5
	var along_segments := maxi(1, int(ceil(length / 0.75)))
	var across_segments := maxi(1, int(ceil(half_width * 2.0 / 0.75)))
	var anchor_xz := (from + to) * 0.5
	var anchor := Vector3(anchor_xz.x,
		float(world.call("ground_height_at", anchor_xz.x, anchor_xz.y)), anchor_xz.y)
	instance.position = anchor
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for along_index in along_segments:
		var t0 := float(along_index) / float(along_segments)
		var t1 := float(along_index + 1) / float(along_segments)
		var p0 := from.lerp(to, t0)
		var p1 := from.lerp(to, t1)
		for across_index in across_segments:
			var across_0 := lerpf(half_width, -half_width,
				float(across_index) / float(across_segments))
			var across_1 := lerpf(half_width, -half_width,
				float(across_index + 1) / float(across_segments))
			var top_left_0 := _strip_point(world, p0 + right * across_0, lift, anchor)
			var top_right_0 := _strip_point(world, p0 + right * across_1, lift, anchor)
			var top_left_1 := _strip_point(world, p1 + right * across_0, lift, anchor)
			var top_right_1 := _strip_point(world, p1 + right * across_1, lift, anchor)
			_add_strip_triangle(surface, top_left_0, top_right_0, top_right_1)
			_add_strip_triangle(surface, top_left_0, top_right_1, top_left_1)
			if across_index == 0:
				var bottom_left_0 := top_left_0 - Vector3.UP * thickness
				var bottom_left_1 := top_left_1 - Vector3.UP * thickness
				_add_strip_triangle(surface, top_left_0, top_left_1, bottom_left_1)
				_add_strip_triangle(surface, top_left_0, bottom_left_1, bottom_left_0)
			if across_index == across_segments - 1:
				var bottom_right_0 := top_right_0 - Vector3.UP * thickness
				var bottom_right_1 := top_right_1 - Vector3.UP * thickness
				_add_strip_triangle(surface, top_right_1, top_right_0, bottom_right_0)
				_add_strip_triangle(surface, top_right_1, bottom_right_0, bottom_right_1)
	surface.generate_normals()
	var mesh := surface.commit()
	mesh.surface_set_material(0, _worked_cut_material(colour, texture_path, normal_path))
	instance.mesh = mesh
	return instance


func _strip_point(world: Node, point: Vector2, lift: float, anchor: Vector3) -> Vector3:
	return Vector3(point.x, float(world.call("ground_height_at", point.x, point.y)) + lift,
		point.y) - anchor


func _add_strip_triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	for vertex: Vector3 in [a, b, c]:
		surface.set_uv(Vector2(vertex.x, vertex.z) * 0.18)
		surface.add_vertex(vertex)


func _textured_box(node_name: String, size: Vector3, colour: Color,
		texture_path: String, normal_path: String) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	var material := _worked_cut_material(colour, texture_path, normal_path)
	mesh.material = material
	instance.mesh = mesh
	return instance


## Tall authored masses are contiguous, hand-worked cliff panels. Short masses
## remain loose broken rock at the toe. Keeping those two silhouettes distinct
## is what makes this read as an excavation instead of a pile of slabs.
func _textured_wedge(node_name: String, size: Vector3, colour: Color,
		texture_path: String, normal_path: String, batter_m: float,
		top_left_scale: float, top_right_scale: float) -> MeshInstance3D:
	var natural_rock := _textured_asset_rock(node_name, size, colour,
		texture_path, normal_path)
	if not node_name.begins_with("WorkedFace") and natural_rock != null:
		return natural_rock
	if node_name.begins_with("WorkedFace") or size.y >= 2.0:
		return _textured_cliff_panel(node_name, size, colour, texture_path,
			normal_path, batter_m, top_left_scale, top_right_scale)
	return _textured_rock_chunk(node_name, size, colour, texture_path,
		normal_path, batter_m, top_left_scale, top_right_scale)


func _textured_asset_rock(node_name: String, size: Vector3, colour: Color,
		texture_path: String, normal_path: String) -> MeshInstance3D:
	var variants: Array[String] = [
		"res://assets/environment/stylized_nature/Rock_Medium_1.gltf",
		"res://assets/environment/stylized_nature/Rock_Medium_2.gltf",
		"res://assets/environment/stylized_nature/Rock_Medium_3.gltf",
	]
	var path := variants[abs(node_name.hash()) % variants.size()]
	var packed := load(path) as PackedScene
	if packed == null:
		return null
	var root := packed.instantiate()
	var source := _first_mesh_instance(root)
	if source == null or source.mesh == null:
		root.free()
		return null
	var source_bounds := source.get_aabb()
	if source_bounds.size.x <= 0.001 or source_bounds.size.y <= 0.001 \
			or source_bounds.size.z <= 0.001:
		root.free()
		return null
	var fitted := ArrayMesh.new()
	var fit := size / source_bounds.size
	var centre := source_bounds.get_center()
	for surface_index in source.mesh.get_surface_count():
		var arrays := source.mesh.surface_get_arrays(surface_index)
		var source_vertices := arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
		var vertices := PackedVector3Array()
		vertices.resize(source_vertices.size())
		for vertex_index in source_vertices.size():
			vertices[vertex_index] = (source_vertices[vertex_index] - centre) * fit
		arrays[Mesh.ARRAY_VERTEX] = vertices
		fitted.add_surface_from_arrays(source.mesh.surface_get_primitive_type(surface_index), arrays)
		fitted.surface_set_material(fitted.get_surface_count() - 1,
			_worked_cut_material(colour, texture_path, normal_path))
	root.free()
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = fitted
	return instance


func _first_mesh_instance(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		return node as MeshInstance3D
	for child in node.get_children():
		var found := _first_mesh_instance(child)
		if found != null:
			return found
	return null


func _textured_cliff_panel(node_name: String, size: Vector3, colour: Color,
		texture_path: String, normal_path: String, batter_m: float,
		top_left_scale: float, top_right_scale: float) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var half_x := size.x * 0.5
	var half_z := size.z * 0.5
	var bottom_y := -size.y * 0.5
	var top_left_y := bottom_y + size.y * clampf(top_left_scale, 0.72, 1.08)
	var top_right_y := bottom_y + size.y * clampf(top_right_scale, 0.72, 1.08)
	var seed_phase := float(abs(node_name.hash()) % 628) * 0.01
	const COLUMNS := 6
	const ROWS := 5
	var vertices := PackedVector3Array()
	# An irregular grid gives the exposed face broad, continuous fracture planes.
	# Only the internal vertices wander; its neighbours still knit into one cliff.
	for row in ROWS + 1:
		var row_t := float(row) / float(ROWS)
		for column in COLUMNS + 1:
			var column_t := float(column) / float(COLUMNS)
			var x := lerpf(-half_x, half_x, column_t) * (1.0 - row_t * 0.075)
			var crown_y := lerpf(top_left_y, top_right_y, column_t)
			crown_y += sin(float(column) * 1.77 + seed_phase) * size.y * 0.10
			var y := lerpf(bottom_y, crown_y, row_t)
			if row > 0 and row < ROWS:
				y += sin(float(column) * 1.71 + float(row) * 2.13 + seed_phase) * size.y * 0.055
			if column > 0 and column < COLUMNS:
				x += sin(float(column) * 2.37 + float(row) * 0.91 + seed_phase) * size.x * 0.035
			var z := -half_z + batter_m * row_t
			z += sin(float(column) * 1.89 + float(row) * 2.43 + seed_phase) * size.z * 0.11
			vertices.append(Vector3(x, y, z))
	var rear_start := vertices.size()
	vertices.append_array(PackedVector3Array([
		Vector3(-half_x, bottom_y, half_z), Vector3(half_x, bottom_y, half_z),
		Vector3(half_x, top_right_y, half_z), Vector3(-half_x, top_left_y, half_z),
	]))
	var indices := PackedInt32Array()
	for row in ROWS:
		for column in COLUMNS:
			var a := row * (COLUMNS + 1) + column
			var b := a + 1
			var d := (row + 1) * (COLUMNS + 1) + column
			var c := d + 1
			indices.append_array(PackedInt32Array([a, b, c, a, c, d]))
	var front_bl := 0
	var front_br := COLUMNS
	var front_tl := ROWS * (COLUMNS + 1)
	var front_tr := front_tl + COLUMNS
	# Close the mass without introducing horizontal facade courses.
	indices.append_array(PackedInt32Array([
		front_bl, rear_start + 1, front_br, front_bl, rear_start, rear_start + 1,
		front_br, rear_start + 2, front_tr, front_br, rear_start + 1, rear_start + 2,
		front_tr, rear_start + 3, front_tl, front_tr, rear_start + 2, rear_start + 3,
		front_tl, rear_start, front_bl, front_tl, rear_start + 3, rear_start,
		rear_start, rear_start + 3, rear_start + 2,
		rear_start, rear_start + 2, rear_start + 1,
	]))
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index: int in indices:
		surface.set_uv(Vector2(vertices[index].x,
			vertices[index].y + vertices[index].z) * 0.18)
		surface.add_vertex(vertices[index])
	surface.generate_normals()
	var mesh := surface.commit()
	mesh.surface_set_material(0, _worked_cut_material(colour, texture_path, normal_path))
	instance.mesh = mesh
	return instance


func _textured_rock_chunk(node_name: String, size: Vector3, colour: Color,
		texture_path: String, normal_path: String, batter_m: float,
		top_left_scale: float, top_right_scale: float) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var half_x := size.x * 0.5
	var half_z := size.z * 0.5
	var bottom_y := -size.y * 0.5
	var top_left_y := bottom_y + size.y * clampf(top_left_scale, 0.72, 1.08)
	var top_right_y := bottom_y + size.y * clampf(top_right_scale, 0.72, 1.08)
	var inset := clampf(batter_m, 0.0, minf(half_x * 0.24, half_z * 0.34))
	const SIDES := 10
	const RINGS := 6
	var seed_phase := float(abs(node_name.hash()) % 628) * 0.01
	var vertices := PackedVector3Array()
	# Deformed ellipsoid rings. Unequal deterministic radii prevent the repeated
	# authored pieces from sharing one manufactured profile or level course line.
	for ring in RINGS + 1:
		var ring_t := float(ring) / float(RINGS)
		var radial_profile := sin(PI * ring_t)
		var ring_inset := inset * ring_t
		for side in SIDES:
			var angle := TAU * float(side) / float(SIDES)
			var variation := 1.0 + sin(float(side) * 2.17 + seed_phase + float(ring) * 0.83) * 0.13
			var x := cos(angle) * maxf(half_x - ring_inset, half_x * 0.62) \
				* radial_profile * variation
			var z := sin(angle) * maxf(half_z - ring_inset, half_z * 0.55) \
				* radial_profile * (1.0 + cos(float(side) * 1.73 + seed_phase) * 0.12) \
				+ ring_inset * 0.35
			var side_height := lerpf(top_left_y, top_right_y,
				clampf((x / maxf(half_x, 0.01) + 1.0) * 0.5, 0.0, 1.0))
			var y := lerpf(bottom_y, side_height, ring_t)
			if ring > 0 and ring < RINGS:
				y += sin(float(side) * 1.91 + seed_phase + float(ring)) * size.y * 0.045
			vertices.append(Vector3(x, y, z))
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for ring in RINGS:
		for side in SIDES:
			var next := (side + 1) % SIDES
			var a := ring * SIDES + side
			var b := ring * SIDES + next
			var c := (ring + 1) * SIDES + next
			var d := (ring + 1) * SIDES + side
			for index: int in [a, b, c, a, c, d]:
				surface.set_uv(Vector2(vertices[index].x,
					vertices[index].y + vertices[index].z) * 0.18)
				surface.add_vertex(vertices[index])
	surface.generate_normals()
	var mesh := surface.commit()
	mesh.surface_set_material(0, _worked_cut_material(colour, texture_path, normal_path))
	instance.mesh = mesh
	return instance


func _worked_cut_material(colour: Color, texture_path: String,
		normal_path: String) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.94
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	material.uv1_triplanar = true
	material.uv1_world_triplanar = true
	material.uv1_scale = Vector3.ONE * 0.42
	if ResourceLoader.exists(texture_path):
		material.albedo_texture = load(texture_path)
	if ResourceLoader.exists(normal_path):
		material.normal_enabled = true
		material.normal_texture = load(normal_path)
		material.normal_scale = 0.55
	return material


## The band clearing is still the offline authority, but the inherited bake
## fingerprint does not include band-local clearings. Remove only the stale
## final-threshold scatter at runtime, using Vegetation's existing exact-instance
## path, so the ordinary approach cannot be bisected by a mature tree again.
func _clear_arrival_sightline(world: Node, spec: Variant) -> void:
	if not spec is Dictionary:
		return
	var at_raw := (spec as Dictionary).get("at", []) as Array
	var radius := float((spec as Dictionary).get("radius_m", 0.0))
	if at_raw.size() != 2 or radius <= 0.0:
		return
	var vegetation := world.get_node_or_null(^"Vegetation")
	if vegetation == null or not vegetation.has_method("clear_area"):
		return
	var at := Vector2(float(at_raw[0]), float(at_raw[1]))
	_arrival_scatter_removed += int(vegetation.call("clear_area",
		Vector3(at.x, float(world.call("ground_height_at", at.x, at.y)), at.y), radius))


## Complete the exposed end of the retained foundation with a shallow stone cap
## and two timber crib rails. These are visual finish pieces inside the prefab's
## existing footprint: the prefab remains the sole collision/route authority.
func _build_foundation_finish(world: Node, list: Array) -> void:
	var holder := Node3D.new()
	holder.name = "OldQuarryFoundationFinish"
	add_child(holder)
	for raw: Variant in list:
		if not raw is Dictionary:
			continue
		var spec := raw as Dictionary
		var at_raw := spec.get("at", []) as Array
		if at_raw.size() != 2:
			continue
		var at := Vector2(float(at_raw[0]), float(at_raw[1]))
		var ground := float(world.call("ground_height_at", at.x, at.y))
		if is_nan(ground) or is_inf(ground):
			continue
		var finish := Node3D.new()
		finish.name = "SupportedSlabEnd%02d" % (_foundation_finishes + 1)
		finish.position = Vector3(at.x, ground, at.y)
		finish.rotation.y = deg_to_rad(float(spec.get("yaw_deg", 0.0)))
		holder.add_child(finish)
		var width := clampf(float(spec.get("width_m", 5.8)), 4.0, 6.5)
		_visual_box(finish, "StoneEndCap", Vector3(width, 0.42, 0.62),
			Vector3(0.0, 0.22, 2.25), Color("#777568"), 0.96)
		for side in [-1.0, 1.0]:
			_visual_box(finish, "TimberCribPost", Vector3(0.24, 1.15, 0.24),
				Vector3(side * (width * 0.42), 0.57, 2.0), Color("#5f4028"), 0.88)
		_visual_box(finish, "TimberCribRail", Vector3(width * 0.9, 0.20, 0.26),
			Vector3(0.0, 0.76, 2.0), Color("#765034"), 0.86)
		_foundation_finishes += 1


## One presentation-only shift lantern restores a warm work hierarchy at night.
## It is intentionally not a camp or interaction and owns no StaticBody; the
## quarry's existing foundations, props and pylon builder remain authoritative.
func _build_work_lights(world: Node, list: Array) -> void:
	var holder := Node3D.new()
	holder.name = "OldQuarryWorkLights"
	add_child(holder)
	for raw: Variant in list:
		if not raw is Dictionary:
			continue
		var spec := raw as Dictionary
		var at_raw := spec.get("at", []) as Array
		if at_raw.size() != 2:
			continue
		var at := Vector2(float(at_raw[0]), float(at_raw[1]))
		var ground := float(world.call("ground_height_at", at.x, at.y))
		if is_nan(ground) or is_inf(ground):
			continue
		var height := clampf(float(spec.get("height_m", 2.8)), 2.2, 3.2)
		var fixture := Node3D.new()
		fixture.name = "WorkLantern%02d" % (_work_lights + 1)
		fixture.position = Vector3(at.x, ground, at.y)
		holder.add_child(fixture)
		_visual_box(fixture, "TimberPost", Vector3(0.16, height, 0.16),
			Vector3(0.0, height * 0.5, 0.0), Color("#493528"), 0.9)
		_visual_box(fixture, "IronArm", Vector3(0.82, 0.09, 0.09),
			Vector3(0.32, height - 0.12, 0.0), Color("#282522"), 0.72)
		var cage := WALL_LANTERN.instantiate() as Node3D
		if cage != null:
			cage.name = "LanternCage"
			cage.position = Vector3(0.62, height - 0.52, 0.0)
			cage.scale = Vector3.ONE * 0.44
			IMPORTED_MATERIALS.make_dielectric(cage)
			fixture.add_child(cage)
		var colour := Color(str(spec.get("colour", "#ffb867")))
		var lens := MeshInstance3D.new()
		lens.name = "VisibleAmberSource"
		var lens_mesh := SphereMesh.new()
		lens_mesh.radius = 0.075
		lens_mesh.height = 0.15
		var lens_material := StandardMaterial3D.new()
		lens_material.albedo_color = colour
		lens_material.emission_enabled = true
		lens_material.emission = colour
		lens_material.emission_energy_multiplier = clampf(
			float(spec.get("source_emission", 1.35)), 1.0, 1.8)
		lens_mesh.material = lens_material
		lens.mesh = lens_mesh
		lens.position = Vector3(0.62, height - 0.42, 0.10)
		fixture.add_child(lens)
		var light := OmniLight3D.new()
		light.name = "WarmWorkPool"
		light.position = lens.position
		light.light_color = colour
		light.light_energy = clampf(float(spec.get("energy", 2.0)), 0.5, 5.0)
		light.omni_range = clampf(float(spec.get("range_m", 10.5)), 4.0, 13.0)
		light.omni_attenuation = clampf(float(spec.get("attenuation", 1.45)), 1.0, 1.45)
		light.shadow_enabled = false
		fixture.add_child(light)
		_work_lights += 1


func _visual_box(parent: Node3D, node_name: String, size: Vector3, at: Vector3,
		colour: Color, roughness: float) -> void:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = roughness
	mesh.material = material
	instance.mesh = mesh
	instance.position = at
	parent.add_child(instance)


func _build_foundations(world: Node3D, list: Array) -> void:
	if list.is_empty():
		return
	var prefabs: RefCounted = PREFABS.new()
	if not prefabs.call("load_recipes"):
		push_error("no building recipes; the quarry has no foundations")
		return
	# See building_prefabs.gd's header on `_holder`: an un-parented template
	# tree leaks RenderingServer resources at engine shutdown, which reached an
	# exported build once as a heap-corrupting SIGABRT.
	var template_holder := Node3D.new()
	template_holder.name = "PrefabTemplates"
	template_holder.visible = false
	add_child(template_holder)
	prefabs.call("set_template_holder", template_holder)

	for entry: Variant in list:
		if not entry is Dictionary:
			continue
		var spec: Dictionary = entry
		var at: Array = spec.get("at", [])
		if at.size() < 2:
			push_warning("a quarry foundation has no `at` — skipped")
			continue
		var x := float(at[0])
		var z := float(at[1])
		var ground: float = float(world.call("ground_height_at", x, z))
		if is_nan(ground):
			push_error("no ground under a quarry foundation at %.0f, %.0f" % [x, z])
			continue
		var prefab_name := str(spec.get("prefab", "quarry_foundation"))
		var ruin: Node3D = prefabs.call("instantiate", prefab_name)
		if ruin == null:
			push_error("quarry foundation prefab missing: %s" % prefab_name)
			continue
		ruin.name = "Foundation_%d" % _foundations
		# Sunk the same 0.05m village.gd sinks its own structures: a building
		# seated exactly on a sampled height hovers on any residual slope.
		ruin.position = Vector3(x, ground - 0.05, z)
		ruin.rotation.y = deg_to_rad(float(spec.get("yaw_deg", 0.0)))
		add_child(ruin)
		_collide(prefabs, ruin, prefab_name)
		_foundations += 1


## The prefab's own authored collider boxes, in its local frame — the same
## walk `village.gd::_collide` does, and for its reason: a wall you can walk
## through is a hologram. No AABB fallback here on purpose. A ruin's combined
## AABB is a solid box the height of its tallest standing course and the full
## width of its floor slab, so falling back to one would seal the quarry's own
## floor behind an invisible crate; a prefab that authors no colliders should
## say so instead.
func _collide(prefabs: RefCounted, ruin: Node3D, prefab_name: String) -> void:
	var boxes: Array = prefabs.call("colliders", prefab_name)
	if boxes.is_empty():
		push_warning("prefab '%s' authors no colliders; its walls can be walked through" % prefab_name)
		return
	var body := StaticBody3D.new()
	body.name = "Collision"
	for entry: Variant in boxes:
		if not entry is Dictionary:
			continue
		var spec: Dictionary = entry
		var at: Array = spec.get("at", [0.0, 0.0, 0.0])
		var size: Array = spec.get("size", [1.0, 1.0, 1.0])
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(float(size[0]), float(size[1]), float(size[2]))
		shape.shape = box
		shape.position = Vector3(float(at[0]), float(at[1]), float(at[2]))
		body.add_child(shape)
	# A child of the ruin, so every box inherits its position and yaw.
	ruin.add_child(body)


## SF33's pylon run, borrowed rather than rewritten — see this file's header.
func _build_conduit_run(world: Node3D, pylons: Dictionary) -> void:
	var list: Array = pylons.get("list", [])
	if list.is_empty():
		return
	var builder: Node3D = SEVERED_SPOKES.new()
	builder.name = "TetherConduits"
	add_child(builder)
	# `_build_pylons` takes a spoke dictionary and reads only its `pylons`
	# key, so this quarry's own block goes in unchanged. Passing the builder
	# as its own holder keeps every pylon, collider and cable under one named
	# node in the scene tree.
	builder.call("_build_pylons", world, builder, {"pylons": pylons})
	_pylons = list.size()


func _build_conduit_head_station(world: Node3D) -> void:
	# Stand this beside the live Pylon_0 handoff, not back inside the worked
	# shoring. It turns the apron endpoint into a readable powered extraction
	# station while leaving the pylon/conduit route itself authoritative.
	var at := Vector2(396.5, 1796.0)
	var ground := float(world.call("ground_height_at", at.x, at.y))
	if is_nan(ground) or is_inf(ground):
		return
	var station := Node3D.new()
	station.name = "QuarryConduitHead"
	station.position = Vector3(at.x, ground, at.y)
	station.rotation.y = deg_to_rad(24.0)
	add_child(station)
	var timber := StandardMaterial3D.new()
	timber.albedo_color = Color("#67462d")
	timber.roughness = 0.92
	var metal := StandardMaterial3D.new()
	metal.albedo_color = Color("#26343a")
	metal.metallic = 0.55
	metal.roughness = 0.5
	var cyan := StandardMaterial3D.new()
	cyan.albedo_color = Color("#62dce8")
	cyan.emission_enabled = true
	cyan.emission = Color("#35c8df")
	cyan.emission_energy_multiplier = 2.2
	for side in [-1.0, 1.0]:
		var post := MeshInstance3D.new()
		post.name = "HeadFramePost"
		var post_mesh := BoxMesh.new()
		post_mesh.size = Vector3(0.32, 3.5, 0.36)
		post_mesh.material = timber
		post.mesh = post_mesh
		post.position = Vector3(side * 1.18, 1.75, 0.0)
		station.add_child(post)
	var crossbar := MeshInstance3D.new()
	crossbar.name = "HeadFrameCrossbar"
	var crossbar_mesh := BoxMesh.new()
	crossbar_mesh.size = Vector3(2.85, 0.34, 0.42)
	crossbar_mesh.material = timber
	crossbar.mesh = crossbar_mesh
	crossbar.position = Vector3(0.0, 3.35, 0.0)
	station.add_child(crossbar)
	var core := MeshInstance3D.new()
	core.name = "ConduitTerminationCore"
	var core_mesh := CylinderMesh.new()
	core_mesh.top_radius = 0.28
	core_mesh.bottom_radius = 0.38
	core_mesh.height = 2.25
	core_mesh.material = cyan
	core.mesh = core_mesh
	core.position = Vector3(0.0, 1.65, 0.0)
	station.add_child(core)
	for ring_index in 3:
		var ring := MeshInstance3D.new()
		ring.name = "ConduitHeadRing%02d" % ring_index
		var ring_mesh := TorusMesh.new()
		ring_mesh.inner_radius = 0.38
		ring_mesh.outer_radius = 0.48
		ring_mesh.material = metal
		ring.mesh = ring_mesh
		ring.position = Vector3(0.0, 0.85 + float(ring_index) * 0.8, 0.0)
		station.add_child(ring)
	var light := OmniLight3D.new()
	light.name = "ConduitHeadGlow"
	light.position = Vector3(0.0, 1.75, 0.0)
	light.light_color = Color("#4fdbe8")
	light.light_energy = 1.8
	light.omni_range = 6.0
	light.shadow_enabled = false
	station.add_child(light)


func _load_config() -> Dictionary:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}
