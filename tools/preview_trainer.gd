extends SceneTree

## Render the trainer in every pose the game drives, from two angles.
##
##   xvfb-run -a -s "-screen 0 1600x900x24" /opt/godot/godot --path . \
##     --rendering-driver opengl3 --resolution 1600x900 \
##     --script tools/preview_trainer.gd
##
## This is the acceptance check for the retargeter, and it exists because the
## obvious check is worthless. Every way a retarget goes wrong — a forearm
## twisted 90°, hips sinking through the pelvis, `foot.l` wired to `DEF-foot.R`
## — produces a clip that loads, plays, reports the right length, and is wrong.
## `_anim.has_animation("Walking_A")` passes for all of them.
##
## So the trainer is stood on a plain card, held at a known frame of each clip,
## and photographed. Two angles because a mirrored limb is invisible head-on and
## obvious from three-quarters, and a sunk pelvis is the reverse.
##
## The reference bar beside him is 1.8m, the height the model is fitted to, so
## "his feet are below the ground" and "he is standing on his ankles" are
## different pictures rather than the same one.

## The script, not the scene: `trainer_model.gd` hangs off a bare Node3D inside
## `player.tscn`, and instancing the whole player here would bring a controller
## that immediately starts falling because there is no terrain under it.
const TRAINER := preload("res://scripts/player/trainer_model.gd")
const CONFIG_PATH := "res://data/config/art.json"
const OUT := "res://shots/_trainer_%s.png"

## Metres. The capsule the controller walks with, and what the model is fitted to.
const HEIGHT := 1.8

## Where in each clip to hold. Mid-clip rather than frame zero: frame zero of a
## walk cycle is very close to a bind pose in most libraries, which is exactly
## the pose a broken retarget also produces.
const HOLD := 0.5


func _init() -> void:
	_run()


func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	_light(world)

	var trainer := Node3D.new()
	trainer.set_script(TRAINER)
	world.add_child(trainer)

	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(20, 20)
	floor_mesh.mesh = plane
	var grey := StandardMaterial3D.new()
	grey.albedo_color = Color(0.32, 0.34, 0.33)
	floor_mesh.material_override = grey
	world.add_child(floor_mesh)

	# A 1.8m post at the trainer's shoulder, so his height is measured against
	# something in the frame rather than eyeballed.
	var ruler := MeshInstance3D.new()
	var bar := BoxMesh.new()
	bar.size = Vector3(0.05, HEIGHT, 0.05)
	ruler.mesh = bar
	var pale := StandardMaterial3D.new()
	pale.albedo_color = Color(0.85, 0.86, 0.88)
	ruler.material_override = pale
	world.add_child(ruler)
	ruler.position = Vector3(0.9, HEIGHT * 0.5, 0.0)

	var camera := Camera3D.new()
	camera.fov = 40.0
	world.add_child(camera)
	camera.make_current()

	for i in 90:
		await physics_frame

	var player := _animation_player(trainer)
	if player == null:
		print("NO ANIMATION PLAYER — the trainer has no clips to preview")
		quit(1)
		return

	var clips: Dictionary = _driven_clips()
	print("driven clips: %s" % [clips])

	var missing: Array[String] = []
	for state: String in clips.keys():
		if not player.has_animation(str(clips[state])):
			missing.append("%s -> %s" % [state, clips[state]])
	if not missing.is_empty():
		print("MISSING CLIPS: %s" % ", ".join(missing))

	# Two angles. Front-three-quarter finds mirrored limbs; side finds a pelvis
	# that has sunk or a foot that no longer reaches the ground.
	var angles := {
		"front": Vector3(2.0, 1.15, 3.1),
		"side": Vector3(3.6, 1.15, 0.2),
	}

	for view: String in angles.keys():
		camera.position = angles[view]
		camera.look_at(Vector3(0.0, 0.95, 0.0), Vector3.UP)
		var strip: Array[Image] = []
		for state: String in clips.keys():
			var clip := str(clips[state])
			if not player.has_animation(clip):
				continue
			player.play(clip)
			player.seek(minf(HOLD, player.get_animation(clip).length * 0.5), true)
			player.advance(0.0)
			for i in 4:
				await process_frame
			await RenderingServer.frame_post_draw
			var shot := root.get_texture().get_image()
			if shot != null:
				strip.append(shot)
		var sheet := _tile(strip)
		if sheet != null:
			sheet.save_png(OUT % view)
			print("wrote %s (%d poses)" % [OUT % view, strip.size()])

	print("poses, left to right: %s" % ", ".join(PackedStringArray(clips.keys())))
	quit(0)


## The clips the game actually asks for, straight from the config — so this
## previews what ships rather than a list that drifts from it.
func _driven_clips() -> Dictionary:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return {}
	var trainer: Dictionary = (parsed as Dictionary).get("trainer", {})
	return trainer.get("clips", {})


func _tile(frames: Array[Image]) -> Image:
	if frames.is_empty():
		return null
	var w: int = frames[0].get_width()
	var h: int = frames[0].get_height()
	var sheet := Image.create(w * frames.size(), h, false, frames[0].get_format())
	for i in frames.size():
		sheet.blit_rect(frames[i], Rect2i(0, 0, w, h), Vector2i(w * i, 0))
	return sheet


## Flat, bright and shadowless on purpose. This frame is asking "is the pose
## right", and a dramatic key light hides half a body in shadow.
func _light(world: Node3D) -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.18, 0.20, 0.23)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.78, 0.80, 0.84)
	e.ambient_light_energy = 1.6
	e.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.environment = e
	world.add_child(env)

	var key := DirectionalLight3D.new()
	key.rotation = Vector3(deg_to_rad(-40.0), deg_to_rad(-30.0), 0.0)
	key.light_energy = 1.5
	world.add_child(key)


func _animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found := _animation_player(child)
		if found != null:
			return found
	return null
