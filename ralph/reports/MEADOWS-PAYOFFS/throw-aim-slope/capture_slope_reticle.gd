extends SceneTree

## Evidence capture for ralph/reports/MEADOWS-PAYOFFS/throw-aim-slope/.
##
## Builds the same constructed rise as tests/test_throw_aim_slope.gd (a
## HeightMapShape3D collider with a matching rendered mesh), drives the REAL
## scripts/combat/throw_aim.gd preview path (`_update_preview()` -> the same
## `_launch_direction()` `_release()` flies) and saves two frames:
##
##   <tag>_assist.jpg  -- assist committed on a creature standing beyond a crest
##   <tag>_reticle.jpg -- reticle on the slope face, no creature near the ray
##
## `--variant=<tag>:<res path>` (repeatable) renders the same two shots with a
## given copy of throw_aim.gd, so "before" can be the pre-fix file checked out
## beside it (`git show <base>:scripts/combat/throw_aim.gd`) in the same run.
##
## The white cross is the screen centre: where the camera's centre ray points.
## Run WITHOUT --headless, under the shared godot-writer flock:
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 \
##     --resolution 1280x720 --script <this> -- --variant=before:res://<old copy> \\
##     --variant=after:res://scripts/combat/throw_aim.gd

const OUT_DIR := "res://ralph/reports/MEADOWS-PAYOFFS/throw-aim-slope/"
const BODY_RADIUS := 0.67
const EYE := Vector3(0.9, 4.0, 3.4)
const TARGET_SOURCE := """extends CharacterBody3D
var radius := 0.67
func centre() -> Vector3:
	return global_position + Vector3.UP * radius
func body_radius() -> float:
	return radius
"""

var _variants: Array = []


static func _rise_height(distance: float) -> float:
	if distance < 1.5:
		return 0.0
	if distance < 5.0:
		return 3.55 * smoothstep(1.5, 5.0, distance)
	if distance < 6.5:
		return lerpf(3.55, 3.0, (distance - 5.0) / 1.5)
	return 3.0


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--variant="):
			_variants.append(arg.substr(10).split(":", true, 1))
	if _variants.is_empty():
		_variants.append(PackedStringArray(["after", "res://scripts/combat/throw_aim.gd"]))
	_run.call_deferred()


func _material(colour: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = colour
	m.roughness = 0.9
	return m


func _terrain(parent: Node3D) -> void:
	var size := 61
	var shape := HeightMapShape3D.new()
	shape.map_width = size
	shape.map_depth = size
	var data := PackedFloat32Array()
	for zi in size:
		for _xi in size:
			data.append(_rise_height(-(float(zi) - 30.0)))
	shape.map_data = data
	var body := StaticBody3D.new()
	var collider := CollisionShape3D.new()
	collider.shape = shape
	body.add_child(collider)
	parent.add_child(body)
	# The rendered surface: the same heights, 0.25 m cells, so what the camera
	# sees is the collision the ray and the orb meet.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var cells := 160
	var span := 40.0
	for zi in cells:
		for xi in cells:
			var x0 := -span * 0.5 + span * float(xi) / cells
			var x1 := -span * 0.5 + span * float(xi + 1) / cells
			var z0 := -span * 0.5 + span * float(zi) / cells
			var z1 := -span * 0.5 + span * float(zi + 1) / cells
			var a := Vector3(x0, _rise_height(-z0), z0)
			var b := Vector3(x1, _rise_height(-z0), z0)
			var c := Vector3(x0, _rise_height(-z1), z1)
			var d := Vector3(x1, _rise_height(-z1), z1)
			for v in [a, c, b, b, c, d]:
				st.add_vertex(v)
	st.generate_normals()
	var mesh := MeshInstance3D.new()
	mesh.mesh = st.commit()
	mesh.material_override = _material(Color(0.36, 0.52, 0.27))
	parent.add_child(mesh)


func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.62, 0.76, 0.9)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.7, 0.72, 0.75)
	world.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50.0, 30.0, 0.0)
	world.add_child(sun)
	_terrain(world)

	var player := CharacterBody3D.new()
	player.name = "Trainer"
	var trainer_mesh := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.height = 1.8
	capsule.radius = 0.3
	trainer_mesh.mesh = capsule
	trainer_mesh.position = Vector3.UP * 0.9
	trainer_mesh.material_override = _material(Color(0.25, 0.3, 0.45))
	player.add_child(trainer_mesh)
	world.add_child(player)

	var target_script := GDScript.new()
	target_script.source_code = TARGET_SOURCE
	target_script.reload()
	var target := CharacterBody3D.new()
	target.set_script(target_script)
	var creature := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = BODY_RADIUS
	sphere.height = BODY_RADIUS * 2.0
	creature.mesh = sphere
	creature.position = Vector3.UP * BODY_RADIUS
	creature.material_override = _material(Color(0.78, 0.6, 0.3))
	target.add_child(creature)
	var target_shape := CollisionShape3D.new()
	var target_sphere := SphereShape3D.new()
	target_sphere.radius = BODY_RADIUS
	target_shape.shape = target_sphere
	target_shape.position = Vector3.UP * BODY_RADIUS
	target.add_child(target_shape)
	world.add_child(target)
	target.global_position = Vector3(0.0, _rise_height(8.0), -8.0)

	var rig := Node3D.new()
	rig.name = "CameraRig"
	var camera := Camera3D.new()
	camera.name = "Camera3D"
	camera.fov = 52.0
	rig.add_child(camera)
	world.add_child(rig)
	camera.global_position = EYE
	camera.current = true

	var overlay := CanvasLayer.new()
	root.add_child(overlay)
	var size := Vector2(root.size)
	for bar: Rect2 in [Rect2(size * 0.5 - Vector2(14, 1.5), Vector2(28, 3)),
			Rect2(size * 0.5 - Vector2(1.5, 14), Vector2(3, 28))]:
		var rect := ColorRect.new()
		rect.color = Color.WHITE
		rect.position = bar.position
		rect.size = bar.size
		overlay.add_child(rect)
	var label := Label.new()
	label.position = Vector2(16, 12)
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color.BLACK)
	overlay.add_child(label)

	for variant: PackedStringArray in _variants:
		await _shots(variant[0], load(variant[1]), world, player, target, rig, camera, label)
	quit(0)


func _shots(tag: String, aim_script: Script, world: Node3D, player: Node3D, target: Node3D,
		rig: Node3D, camera: Camera3D, label: Label) -> void:
	var aim: Node = aim_script.new()
	world.add_child(aim)
	aim.set("_player", player)
	aim.set("_camera_rig", rig)
	target.visible = true
	await physics_frame
	await physics_frame

	# Shot 1: assist committed on a creature beyond the crest.
	var centre: Vector3 = target.call("centre")
	camera.look_at(centre)
	aim.set("_target", target)
	aim.set("_committed_assist_point", centre)
	label.text = "%s -- assist committed on the creature beyond the crest" % tag.to_upper()
	await _settle(aim)
	_save("%s_assist.jpg" % tag)

	# Shot 2: reticle on the slope face, nothing to pull toward.
	aim.set("_committed_assist_point", Vector3.INF)
	aim.set("_target", null)
	target.visible = false
	camera.look_at(Vector3(0.0, _rise_height(3.5), -3.5))
	label.text = "%s -- reticle (white cross) on the slope face" % tag.to_upper()
	await _settle(aim)
	_save("%s_reticle.jpg" % tag)
	var preview: Node = world.get_node_or_null(^"ThrowPreview")
	if preview != null:
		preview.queue_free()
	aim.queue_free()
	await process_frame


func _settle(aim: Node) -> void:
	for _i in 4:
		await physics_frame
		aim.call("_update_preview")
	for _i in 3:
		await process_frame


func _save(file: String) -> void:
	var image := root.get_texture().get_image()
	var path := ProjectSettings.globalize_path(OUT_DIR + file)
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var err := image.save_jpg(path, 0.9)
	print("capture: %s -> %s (err=%d)" % [file, path, err])
