extends SceneTree

## MQ1A scratch probe: renders one frame per single-bone rotation so the gait
## rewrite keys every axis from EVIDENCE instead of inferring a rig convention
## from Python source. Blender authors pose eulers in the bone's own rest
## frame; Godot's pose rotation composes the same way as rest * pose, so each
## render below shows exactly what a keyed Blender euler will do to the
## shipped rig.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" ~/.cache/tetherbound-art/godot \
##     --path . --rendering-driver opengl3 --resolution 960x540 \
##     --script tools/_probe_pose_axes.gd

const CHARACTER_MODEL := preload("res://scripts/characters/character_model.gd")
const OUT_DIR := "res://shots/gait_probe"

## (label, bone, axis, degrees)
const PROBES := [
	["arm_r_x_neg40", "RightArm", Vector3(1, 0, 0), -40.0],
	["arm_r_x_pos40", "RightArm", Vector3(1, 0, 0), 40.0],
	["forearm_r_x_neg50", "RightForeArm", Vector3(1, 0, 0), -50.0],
	["forearm_r_x_pos50", "RightForeArm", Vector3(1, 0, 0), 50.0],
	["arm_r_z_pos45", "RightArm", Vector3(0, 0, 1), 45.0],
	["arm_r_z_neg45", "RightArm", Vector3(0, 0, 1), -45.0],
	["upleg_r_x_neg30", "RightUpLeg", Vector3(1, 0, 0), -30.0],
	["leg_r_x_pos60", "RightLeg", Vector3(1, 0, 0), 60.0],
	["foot_r_x_neg45", "RightFoot", Vector3(1, 0, 0), -45.0],
	["forearm_l_x_neg50", "LeftForeArm", Vector3(1, 0, 0), -50.0],
]


func _init() -> void:
	_run()


func _run() -> void:
	await process_frame

	var world := Node3D.new()
	root.add_child(world)

	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.55, 0.62, 0.68)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.8, 0.8, 0.8)
	e.ambient_light_energy = 1.5
	env.environment = e
	world.add_child(env)
	var light := DirectionalLight3D.new()
	light.rotation = Vector3(deg_to_rad(-45), deg_to_rad(-30), 0)
	world.add_child(light)

	var model := Node3D.new()
	model.set_script(CHARACTER_MODEL)
	world.add_child(model)
	if not bool(model.call("build", "trainer")):
		printerr("trainer failed to build")
		quit(1)
		return
	# Stop the idle clip so poses are not overwritten.
	var anim: AnimationPlayer = model.call("animation_player")
	if anim != null:
		anim.stop()

	var skeleton := _find_skeleton(model)
	if skeleton == null:
		printerr("no skeleton")
		quit(1)
		return

	var camera := Camera3D.new()
	camera.fov = 40.0
	world.add_child(camera)
	camera.make_current()

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	for probe: Array in PROBES:
		skeleton.reset_bone_poses()
		var idx: int = skeleton.find_bone(str(probe[1]))
		if idx < 0:
			printerr("no bone %s" % str(probe[1]))
			continue
		var rest := Quaternion(skeleton.get_bone_rest(idx).basis)
		var pose := Quaternion((probe[2] as Vector3).normalized(), deg_to_rad(float(probe[3])))
		skeleton.set_bone_pose_rotation(idx, rest * pose)
		# Three-quarter view from the character's front-left, plus the travel
		# frame: the model faces +Z here (unrotated), so front is +Z.
		camera.position = Vector3(2.2, 1.5, 3.2)
		camera.look_at(Vector3(0, 0.95, 0), Vector3.UP)
		await _settle()
		_save(str(probe[0]) + "-front34")
		camera.position = Vector3(3.6, 1.1, 0.6)
		camera.look_at(Vector3(0, 0.9, 0), Vector3.UP)
		await _settle()
		_save(str(probe[0]) + "-side")

	skeleton.reset_bone_poses()
	print("done: shots/gait_probe")
	quit(0)


func _settle() -> void:
	for i in 3:
		await process_frame
	await RenderingServer.frame_post_draw


func _save(name: String) -> void:
	var image := root.get_texture().get_image()
	if image != null:
		image.save_png("%s/%s.png" % [OUT_DIR, name])


func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node as Skeleton3D
	for child in node.get_children():
		var found := _find_skeleton(child)
		if found != null:
			return found
	return null
