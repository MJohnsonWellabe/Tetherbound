extends SceneTree

## Photograph the trainer's arms through the walk, run and idle cycles, beside
## the rig the clips were authored on.
##
##   xvfb-run -a -s "-screen 0 1600x900x24" /opt/godot/godot --path . \
##     --rendering-driver opengl3 --resolution 1600x900 \
##     --script tools/preview_arms.gd
##
## Two subjects, not one. `Ranger.glb` wears the same 23-bone KayKit rig the 25
## clips are authored on, at the same node path the clip tracks address, so it
## plays them with NO retarget anywhere in the path. Whatever the Ranger's arms
## do at phase 0.25 of `Walking_A` is what the trainer's arms are supposed to do
## at phase 0.25 of `Walking_A`. Rendering the trainer alone only answers "does
## this look odd to me"; rendering both answers "is this the pose".
##
## Four phases per clip, because a limb that is merely out of phase and a limb
## that is swinging in the wrong PLANE look identical in a single still — one
## frame of a sideways flap is a pose you can talk yourself into.
##
## Front and side both. An arm behind the body is invisible head-on.

const TRAINER := preload("res://scripts/player/trainer_model.gd")
const RANGER := "res://assets/characters/Ranger.glb"
const LIBRARIES := [
	"res://assets/characters/Rig_Medium_General.glb",
	"res://assets/characters/Rig_Medium_MovementBasic.glb",
]
const OUT := "res://shots/_arms_%s_%s.png"

## Metres. What the trainer is fitted to; the Ranger is fitted to it as well, so
## the two figures are the same size in the frame and their limbs are comparable
## by eye rather than by proportion.
const HEIGHT := 1.8

## Where each subject stands. Far enough apart that the camera can be moved to
## one without the other intruding on the crop.
const SPOTS := {"ranger": Vector3(-6.0, 0.0, 0.0), "trainer": Vector3(6.0, 0.0, 0.0)}

## Clip per row of the contact sheet, keyed by the state the game drives it for.
const CLIPS := {"idle": "Idle_A", "walk": "Walking_A", "run": "Running_A"}

## Fractions of the clip. Quarter phases catch a full swing: on a correct walk
## the left arm should be forward at one of 0.00/0.50 and back at the other.
const PHASES := [0.0, 0.25, 0.5, 0.75]

## The full frame is mostly empty card. Cropping to the figure is what makes a
## forearm readable in a tiled sheet.
const CROP := Vector2i(520, 880)


func _init() -> void:
	_run()


func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	_light(world)
	_ground(world)

	var trainer := Node3D.new()
	trainer.set_script(TRAINER)
	world.add_child(trainer)
	trainer.position = SPOTS["trainer"]

	var ranger := _ranger()
	world.add_child(ranger)
	ranger.position = SPOTS["ranger"]

	var camera := Camera3D.new()
	camera.fov = 38.0
	world.add_child(camera)
	camera.make_current()

	for i in 90:
		await physics_frame

	var players := {
		"ranger": _player(ranger),
		"trainer": _player(trainer),
	}
	for who: String in players.keys():
		if players[who] == null:
			print("NO ANIMATION PLAYER for %s" % who)
			quit(1)
			return
		print("%s clips: %d" % [who, (players[who] as AnimationPlayer).get_animation_list().size()])

	var views := {
		# Camera offset from the subject's feet, and the height it aims at.
		"front": Vector3(0.0, 1.05, 3.4),
		"side": Vector3(3.4, 1.05, 0.0),
	}

	for label: String in CLIPS.keys():
		var clip: String = CLIPS[label]
		for view: String in views.keys():
			var rows: Array[Image] = []
			for who: String in ["ranger", "trainer"]:
				var strip: Array[Image] = []
				for phase: float in PHASES:
					var shot := await _shoot(
						camera, players[who], clip, phase, SPOTS[who], views[view]
					)
					if shot != null:
						strip.append(shot)
				var row := _tile(strip, true)
				if row != null:
					rows.append(row)
			var sheet := _tile(rows, false)
			if sheet != null:
				sheet.save_png(OUT % [label, view])
				print("wrote %s" % (OUT % [label, view]))

	print("rows: ranger (source rig, no retarget) on top, trainer below.")
	print("columns, left to right: phase %s of the clip." % [PHASES])
	quit(0)


## Hold one subject at one phase of one clip and take the picture.
func _shoot(
	camera: Camera3D,
	player: AnimationPlayer,
	clip: String,
	phase: float,
	spot: Vector3,
	offset: Vector3
) -> Image:
	if not player.has_animation(clip):
		return null
	camera.global_position = spot + offset
	camera.look_at(spot + Vector3(0.0, 0.95, 0.0), Vector3.UP)
	player.play(clip)
	# `seek(..., true)` updates immediately; `advance(0.0)` flushes the pose so
	# the frame drawn is the frame asked for rather than the one before it.
	player.seek(player.get_animation(clip).length * phase, true)
	player.advance(0.0)
	for i in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	var shot := root.get_texture().get_image()
	if shot == null:
		return null
	var at := Vector2i(
		int((shot.get_width() - CROP.x) * 0.5), int((shot.get_height() - CROP.y) * 0.5)
	)
	return shot.get_region(Rect2i(at, CROP))


## The KayKit Ranger with the KayKit clips merged straight on — same rig, same
## bone names, same node path, so nothing is retargeted and nothing can be wrong
## except the clip itself. Fitted to the trainer's height so the two figures are
## measured against each other rather than against their own art packs.
func _ranger() -> Node3D:
	var node: Node3D = (load(RANGER) as PackedScene).instantiate() as Node3D
	var holder := Node3D.new()
	holder.add_child(node)

	var player := AnimationPlayer.new()
	node.add_child(player)
	player.root_node = player.get_path_to(node)
	var library := AnimationLibrary.new()
	player.add_animation_library("", library)
	for path: String in LIBRARIES:
		var source: Node = (load(path) as PackedScene).instantiate()
		var from := _player(source)
		if from != null:
			for clip in from.get_animation_list():
				if not library.has_animation(clip):
					library.add_animation(clip, from.get_animation(clip).duplicate())
		source.queue_free()

	var box := AABB()
	var started := false
	for mesh in _meshes(node):
		var local: AABB = mesh.transform * mesh.get_aabb()
		box = local if not started else box.merge(local)
		started = true
	if started and box.size.y > 0.0001:
		var fit := HEIGHT / box.size.y
		node.scale = Vector3.ONE * fit
		node.position = Vector3(0.0, -box.position.y * fit, 0.0)
	return holder


func _meshes(node: Node) -> Array[MeshInstance3D]:
	var found: Array[MeshInstance3D] = []
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		found.append(node as MeshInstance3D)
	for child in node.get_children():
		found.append_array(_meshes(child))
	return found


func _tile(frames: Array[Image], across: bool) -> Image:
	if frames.is_empty():
		return null
	var w: int = frames[0].get_width()
	var h: int = frames[0].get_height()
	var sheet := Image.create(
		w * (frames.size() if across else 1),
		h * (1 if across else frames.size()),
		false,
		frames[0].get_format()
	)
	for i in frames.size():
		sheet.blit_rect(
			frames[i],
			Rect2i(0, 0, w, h),
			Vector2i(w * i, 0) if across else Vector2i(0, h * i)
		)
	return sheet


func _ground(world: Node3D) -> void:
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(60, 60)
	floor_mesh.mesh = plane
	var grey := StandardMaterial3D.new()
	grey.albedo_color = Color(0.30, 0.32, 0.31)
	floor_mesh.material_override = grey
	world.add_child(floor_mesh)


## Flat and bright. This frame is asking where a forearm is, and a key light
## with shadows hides one arm against the body in half the phases.
func _light(world: Node3D) -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.16, 0.18, 0.21)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.80, 0.82, 0.86)
	e.ambient_light_energy = 1.7
	e.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.environment = e
	world.add_child(env)

	var key := DirectionalLight3D.new()
	key.rotation = Vector3(deg_to_rad(-35.0), deg_to_rad(-25.0), 0.0)
	key.light_energy = 1.4
	world.add_child(key)

	var fill := DirectionalLight3D.new()
	fill.rotation = Vector3(deg_to_rad(-20.0), deg_to_rad(150.0), 0.0)
	fill.light_energy = 0.7
	world.add_child(fill)


func _player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found := _player(child)
		if found != null:
			return found
	return null
