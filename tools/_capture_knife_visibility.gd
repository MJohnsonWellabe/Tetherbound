extends SceneTree

## OWNER-0901-KNIFE-VISIBILITY: photograph the knife equipped and idle in the
## trainer's hand, the same staged-body rig `capture_chop_swing.gd` uses, so
## "isn't even visible in hand" can be judged by eye and measured by
## `_report_prop_size()` rather than asserted. Throwaway verification tool,
## not part of the shipped capture set.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" \
##     ~/.cache/tetherbound-art/godot --path . --rendering-driver opengl3 \
##     --resolution 1280x720 --script tools/_capture_knife_visibility.gd
##
## Frames land in shots/knife_visibility/<TAG>/ (TAG defaults to `current`).

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const CAMERA_RIG_SCRIPT := preload("res://scripts/player/camera_rig.gd")

const OUT_ROOT := "res://shots/knife_visibility"
const SETTLE_FRAMES := 45
const SHOT_FRAMES := 6

const TOOL_ID := "knife"

const BODY_YAW_DEG := 200.0
const BODY_PITCH_DEG := -8.0
const HAND_CAM_OFFSET := Vector3(1.05, 0.28, 0.30)
const HAND_CAM_FOV := 38.0


func _init() -> void:
	_run()


func _run() -> void:
	var tag := OS.get_environment("TAG")
	if tag == "":
		tag = "current"
	var out := "%s/%s" % [OUT_ROOT, tag]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))

	var world := Node3D.new()
	world.name = "KnifeStage"
	root.add_child(world)
	await process_frame

	_build_lighting(world)
	_build_ground(world)

	var rig: SpringArm3D = _build_camera_rig(world)
	if not rig.has_method("set_target"):
		push_error("camera_rig.gd did not attach to the rig; nothing can be framed")
		quit(1)
		return

	var player := PLAYER_SCENE.instantiate() as CharacterBody3D
	player.name = "Player"
	world.add_child(player)
	player.global_position = Vector3.ZERO
	rig.call("set_target", player)

	var game := root.get_node_or_null(^"/root/Game")
	if game == null:
		push_error("no /root/Game autoload; the tool would never reach the hand")
		quit(1)
		return
	game.set("equipped_tool", TOOL_ID)

	for i in SETTLE_FRAMES:
		await process_frame

	var hold := player.get_node_or_null(^"ToolHold")
	if hold == null:
		push_error("player scene has no ToolHold; nothing to photograph")
		quit(1)
		return

	var prop: Variant = hold.call("prop_node")
	print("prop in hand: %s" % ("<none>" if prop == null else str((prop as Node).name)))
	if prop != null:
		_report_prop_size(prop as Node3D, player)

	for i in SHOT_FRAMES:
		rig.set("yaw", deg_to_rad(BODY_YAW_DEG))
		rig.set("pitch", deg_to_rad(BODY_PITCH_DEG))
		await process_frame
	root.get_texture().get_image().save_png("%s/01-idle-body.png" % out)
	print("shot -> %s/01-idle-body.png" % out)

	await _shoot_hands(world, player, "%s/02-grip-closeup.png" % out)

	print("done: 2 frames in %s" % out)
	quit(0)


func _shoot_hands(world: Node3D, player: Node3D, path: String) -> void:
	var cam := Camera3D.new()
	cam.name = "GripCamera"
	cam.fov = HAND_CAM_FOV
	world.add_child(cam)
	cam.make_current()
	var hold: Node = player.get("tool_hold")
	var prop := (hold.call("prop_node") if hold != null else null) as Node3D
	var look_at := player.global_position + Vector3(0.0, 1.1, 0.0)
	if prop != null:
		look_at = prop.global_position
	for i in SHOT_FRAMES:
		cam.global_position = look_at + HAND_CAM_OFFSET
		cam.look_at(look_at, Vector3.UP)
		await process_frame
	root.get_texture().get_image().save_png(path)
	print("shot -> %s" % path)
	cam.queue_free()


func _report_prop_size(prop: Node3D, player: Node3D) -> void:
	var bounds := AABB()
	var seen := false
	for node in _all_descendants(prop):
		var mesh := node as VisualInstance3D
		if mesh == null:
			continue
		var box := mesh.global_transform * mesh.get_aabb()
		bounds = box if not seen else bounds.merge(box)
		seen = true
	if not seen:
		print("prop size: no VisualInstance3D under %s" % prop.name)
		return
	var body_bounds := AABB()
	var body_seen := false
	for node in _all_descendants(player):
		var mesh := node as VisualInstance3D
		if mesh == null or not mesh.visible:
			continue
		var box := mesh.global_transform * mesh.get_aabb()
		body_bounds = box if not body_seen else body_bounds.merge(box)
		body_seen = true
	var longest: float = maxf(bounds.size.x, maxf(bounds.size.y, bounds.size.z))
	print("prop size: %.3f x %.3f x %.3f m (longest %.3f m); trainer %.2f m tall; knife is %.1f%% of the body" % [
		bounds.size.x, bounds.size.y, bounds.size.z, longest,
		body_bounds.size.y, 100.0 * longest / maxf(body_bounds.size.y, 0.01)])


func _all_descendants(node: Node) -> Array[Node]:
	var out: Array[Node] = []
	for child in node.get_children():
		out.append(child)
		out.append_array(_all_descendants(child))
	out.append(node)
	return out


func _build_lighting(world: Node3D) -> void:
	var env_holder := WorldEnvironment.new()
	env_holder.name = "WorldEnvironment"
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
	sun.name = "Sun"
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	sun.rotation_degrees = Vector3(-48.0, 40.0, 0.0)
	world.add_child(sun)


func _build_ground(world: Node3D) -> void:
	var body := StaticBody3D.new()
	body.name = "Ground"
	var mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(40.0, 40.0)
	mesh.mesh = plane
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.31, 0.38, 0.22)
	material.roughness = 1.0
	mesh.material_override = material
	body.add_child(mesh)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(40.0, 0.4, 40.0)
	shape.shape = box
	shape.position = Vector3(0.0, -0.2, 0.0)
	body.add_child(shape)
	world.add_child(body)


func _build_camera_rig(world: Node3D) -> SpringArm3D:
	var rig := SpringArm3D.new()
	rig.name = "CameraRig"
	rig.spring_length = 5.2
	rig.margin = 0.6
	rig.set_script(CAMERA_RIG_SCRIPT)
	world.add_child(rig)

	var camera := Camera3D.new()
	camera.name = "Camera3D"
	camera.current = true
	camera.fov = 70.0
	camera.far = 2000.0
	rig.add_child(camera)
	return rig
