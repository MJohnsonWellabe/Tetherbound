extends SceneTree

## Creature-bed nest rework: one frame of a creature body actually seated at
## creature_bed.gd's REST_ANCHOR over a real built bed, so the re-derived
## anchor is verified by sight rather than arithmetic alone. Mirrors
## _sync_rest_body()'s own placement (same scene, same script) without
## standing up Game/party. Same stage rig as tools/_capture_t1_camp_assets.gd.
##
## BACKLOG-VISUAL-BED-FITS-CREATURE (2026-09-01): this used to call
## play_faint() directly, which predates play_rest()'s roll-onto-side
## behaviour (OWNER-0901-CREATURE-BED-POSE) and never reflected what
## _sync_rest_body() actually plays for a real occupant. The 2026-08-31
## visual census judged that stale play_faint() frame and reported the
## creature overflowing the rim -- a defect in the standing/faint pose this
## tool no longer needs to render, not in what ships. Calling play_rest()
## here, same as production, keeps this tool's evidence honest.
##
##   xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/_capture_creature_bed_rest.gd -- <out_dir>

const CREATURE_BED := preload("res://scripts/build/creature_bed.gd")
const CREATURE_SCENE := preload("res://scenes/creatures/creature.tscn")
const CREATURE_BODY := preload("res://scripts/creatures/creature_body.gd")

const POSE_FRAMES := 180
const FOV := 42.0

var _posed_torso_points: Array[Vector3] = []
var _posed_region_points: Dictionary = {}


func _init() -> void:
	_run()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("headless has no renderer; run under xvfb-run")
		quit(1)
		return

	var args := OS.get_cmdline_user_args()
	var out_dir := args[0] if args.size() > 0 else "res://shots/creature_bed_rest"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))

	var world := _stage(20.0)
	var bed: Node3D = CREATURE_BED.new()
	world.add_child(bed)
	bed.call("build_real", false)
	await process_frame

	var body := CREATURE_SCENE.instantiate() as Node3D
	body.set_script(CREATURE_BODY)
	world.add_child(body)
	body.call("setup", "terrapup", false)
	body.position = CREATURE_BED.REST_ANCHOR
	body.rotation.y = PI * 0.5
	body.collision_layer = 0
	body.collision_mask = 0
	body.set_physics_process(false)
	body.call_deferred("play_rest")

	var camera := Camera3D.new()
	camera.fov = FOV
	camera.far = 100.0
	world.add_child(camera)
	camera.make_current()
	camera.global_position = Vector3(7.5, 5.0, 8.0)
	camera.look_at(Vector3(0.0, 1.4, 0.0), Vector3.UP)

	for i in POSE_FRAMES:
		await physics_frame
		if bool((body.call("rest_pose_receipt") as Dictionary).get("active", false)):
			break
	var players := body.find_children("*", "AnimationPlayer", true, false)
	if not players.is_empty():
		var player := players[0] as AnimationPlayer
		print("rest diagnostic: clips=%s current=%s assigned=%s position=%.3f length=%.3f playing=%s receipt=%s" % [
			JSON.stringify(Array(player.get_animation_list())), player.current_animation,
			player.assigned_animation, player.current_animation_position,
			player.current_animation_length, player.is_playing(),
			JSON.stringify(body.call("rest_pose_receipt"))])
	var posed := _posed_visual_bounds(body)
	print("rest bounds: min_y=%.4f max_y=%.4f height=%.4f anchor_y=%.4f offset=%.4f" % [
		posed.position.y, posed.end.y, posed.size.y, CREATURE_BED.REST_ANCHOR.y,
		posed.position.y - CREATURE_BED.REST_ANCHOR.y])
	print("rest contact: torso_q1_offset=%.4f regions=%s" % [
		_lower_quartile_y(_posed_torso_points) - CREATURE_BED.REST_ANCHOR.y,
		JSON.stringify(_posed_region_bounds(CREATURE_BED.REST_ANCHOR.y))])
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image != null:
		image.save_png("%s/06-creature-resting.png" % out_dir)
		print("    -> %s/06-creature-resting.png" % out_dir)

	camera.global_position = Vector3(-7.5, 4.5, -7.5)
	camera.look_at(Vector3(0.0, 1.4, 0.0), Vector3.UP)
	for i in 3:
		await physics_frame
	await RenderingServer.frame_post_draw
	image = root.get_texture().get_image()
	if image != null:
		image.save_png("%s/07-creature-resting-far-side.png" % out_dir)
		print("    -> %s/07-creature-resting-far-side.png" % out_dir)

	print("done")
	quit(0)


func _stage(half_size: float) -> Node3D:
	var world := Node3D.new()
	root.add_child(world)

	var env_holder := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	sky.sky_material = ProceduralSkyMaterial.new()
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env_holder.environment = env
	world.add_child(env_holder)

	var sun := DirectionalLight3D.new()
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	sun.rotation_degrees = Vector3(-48.0, 40.0, 0.0)
	world.add_child(sun)

	var body := StaticBody3D.new()
	body.name = "Ground"
	var mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(half_size * 2.0, half_size * 2.0)
	mesh.mesh = plane
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.31, 0.38, 0.22)
	material.roughness = 1.0
	mesh.material_override = material
	body.add_child(mesh)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(half_size * 2.0, 0.4, half_size * 2.0)
	shape.shape = box
	shape.position = Vector3(0.0, -0.2, 0.0)
	body.add_child(shape)
	world.add_child(body)

	return world


func _posed_visual_bounds(body: Node3D) -> AABB:
	var points: Array[Vector3] = []
	_posed_torso_points.clear()
	_posed_region_points.clear()
	for raw: Node in body.find_children("*", "MeshInstance3D", true, false):
		var instance := raw as MeshInstance3D
		if instance.mesh == null or not instance.is_visible_in_tree():
			continue
		if instance.name == "ContactShadow":
			continue
		var skeleton := _skeleton_for(instance)
		var skin := instance.skin
		for surface in instance.mesh.get_surface_count():
			var arrays := instance.mesh.surface_get_arrays(surface)
			var vertices := arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
			var bones := _bone_indices(arrays[Mesh.ARRAY_BONES])
			var weights := _bone_weights(arrays[Mesh.ARRAY_WEIGHTS])
			if bones.is_empty() and weights.is_empty():
				for vertex: Vector3 in vertices:
					points.append(instance.global_transform * vertex)
				continue
			if skeleton == null or skin == null or bones.size() != weights.size() \
					or vertices.is_empty() or bones.size() % vertices.size() != 0:
				continue
			var stride := int(bones.size() / vertices.size())
			for vertex_index in vertices.size():
				var posed := Vector3.ZERO
				var total := 0.0
				var torso_weight := 0.0
				var region_weights: Dictionary = {}
				for influence in stride:
					var offset := vertex_index * stride + influence
					var weight := float(weights[offset])
					var bind_index := int(bones[offset])
					if weight <= 0.0 or bind_index < 0 or bind_index >= skin.get_bind_count():
						continue
					var bone := skin.get_bind_bone(bind_index)
					if bone < 0:
						bone = skeleton.find_bone(skin.get_bind_name(bind_index))
					if bone < 0:
						continue
					posed += (skeleton.get_bone_global_pose(bone) \
						* skin.get_bind_pose(bind_index) * vertices[vertex_index]) * weight
					total += weight
					var bone_name := str(skeleton.get_bone_name(bone))
					if bone_name == "pelvis" or bone_name == "spine":
						torso_weight += weight
					var region := _rest_region_for_bone(bone_name)
					if region != "":
						region_weights[region] = float(region_weights.get(region, 0.0)) + weight
				if total > 0.0:
					var world_point := skeleton.global_transform * (posed / total)
					points.append(world_point)
					if torso_weight / total >= 0.35:
						_posed_torso_points.append(world_point)
					var dominant_region := _dominant_rest_region(region_weights)
					if dominant_region != "":
						if not _posed_region_points.has(dominant_region):
							_posed_region_points[dominant_region] = []
						(_posed_region_points[dominant_region] as Array).append(world_point)
	if points.is_empty():
		return AABB()
	var low := points[0]
	var high := points[0]
	for point: Vector3 in points:
		low = Vector3(minf(low.x, point.x), minf(low.y, point.y), minf(low.z, point.z))
		high = Vector3(maxf(high.x, point.x), maxf(high.y, point.y), maxf(high.z, point.z))
	return AABB(low, high - low)


func _rest_region_for_bone(bone_name: String) -> String:
	var lower := bone_name.to_lower()
	if lower.contains("tail"):
		return "tail"
	if lower.contains("head") or lower.contains("neck") or lower.contains("jaw"):
		return "head"
	if lower.contains("front") or lower.contains("fore"):
		return "front_leg_l" if lower.ends_with("_l") or lower.ends_with(".l") else "front_leg_r"
	if lower.contains("rear") or lower.contains("hind"):
		return "rear_leg_l" if lower.ends_with("_l") or lower.ends_with(".l") else "rear_leg_r"
	if lower.contains("pelvis") or lower.contains("spine") or lower.contains("chest") \
			or lower.contains("root"):
		return "torso"
	return ""


func _dominant_rest_region(weights: Dictionary) -> String:
	var result := ""
	var strongest := 0.0
	for region: String in weights:
		var value := float(weights[region])
		if value > strongest:
			strongest = value
			result = region
	return result


func _posed_region_bounds(anchor_y: float) -> Dictionary:
	var receipt := {}
	for region: String in _posed_region_points:
		var points := _posed_region_points[region] as Array
		if points.is_empty():
			continue
		var min_y := (points[0] as Vector3).y
		var max_y := min_y
		for raw_point: Variant in points:
			var y := (raw_point as Vector3).y
			min_y = minf(min_y, y)
			max_y = maxf(max_y, y)
		receipt[region] = {
			"count": points.size(),
			"min_offset_m": min_y - anchor_y,
			"max_offset_m": max_y - anchor_y,
		}
	return receipt


func _lower_quartile_y(points: Array[Vector3]) -> float:
	if points.is_empty():
		return NAN
	var heights: Array[float] = []
	for point: Vector3 in points:
		heights.append(point.y)
	heights.sort()
	return heights[int(floor(float(heights.size() - 1) * 0.25))]


func _skeleton_for(instance: MeshInstance3D) -> Skeleton3D:
	var named := instance.get_node_or_null(instance.skeleton) as Skeleton3D
	if named != null:
		return named
	var node: Node = instance.get_parent()
	while node != null:
		if node is Skeleton3D:
			return node as Skeleton3D
		node = node.get_parent()
	return null


func _bone_indices(raw: Variant) -> PackedInt32Array:
	if raw is PackedInt32Array:
		return raw as PackedInt32Array
	var out := PackedInt32Array()
	if raw is PackedFloat32Array:
		var values := raw as PackedFloat32Array
		out.resize(values.size())
		for index in values.size():
			out[index] = int(values[index])
	return out


func _bone_weights(raw: Variant) -> PackedFloat32Array:
	if raw is PackedFloat32Array:
		return raw as PackedFloat32Array
	return PackedFloat32Array()
