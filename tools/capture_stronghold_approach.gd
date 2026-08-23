extends SceneTree

## STRONGHOLD-R2. The three stronghold wayfinding viewpoints, shot in the REAL
## scene instead of the terrain-plus-landmark stage `tools/capture_castle_lite.
## gd` builds.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" ~/godot-bin/godot --path . \
##     --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/capture_stronghold_approach.gd
##
## ## Why this exists, when two capture tools for this site already do
##
## `capture_castle_lite.gd` deliberately skips the vegetation scatter, the
## water, the village and the props — its header explains that as a cost
## saving, and for judging the castle's own geometry and materials it is the
## right call. But it makes the frames LIE about one specific thing, and it is
## the thing this task is about: the ground. Every lite frame shows the
## stronghold standing in an unbroken mown lawn, because the ~130k scatter
## instances that would put grass, stones, verge fringe and path stones on that
## ground are the exact layer it does not build. A critic reading those frames
## correctly reports "the field is empty" and is describing the capture, not
## the world — and the road this task authored gets none of its own dressing
## either, since the path stones and the verge fringe are scatter layers.
##
## `capture_wayfinding.gd` does load the real scene, and shoots six viewpoints
## including two signpost close-ups in the village that have nothing to do with
## the stronghold. This is that tool's scene path with this task's three
## viewpoints and nothing else, plus the same staged trainer and creature
## `capture_castle_lite.gd` stands on the ramp for scale.
##
## Output goes to its own directory rather than over `shots/wayfinding`, so the
## lite frames (which are still the right tool for judging the castle's own
## materials without the world in the way) survive a run of this.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const CHARACTER_MODEL := preload("res://scripts/characters/character_model.gd")
const CREATURE_SCENE := preload("res://scenes/creatures/creature.tscn")
const CREATURE_BODY := preload("res://scripts/creatures/creature_body.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots/wayfinding_full"

const SETTLE_FRAMES := 240
const POSE_FRAMES := 4
const FOV := 70.0

const TOWER_AT := Vector2(229.8, -144.4)

## Identical to `capture_castle_lite.gd`'s, so the two sets are comparable
## frame for frame — the only difference between them is what is in the world.
const VIEWPOINTS := [
	{
		"name": "silhouette-close",
		"eye": Vector2(229.8, -214.4), "eye_h": 7.0,
		"target": TOWER_AT, "target_h": 14.0,
	},
	{
		"name": "silhouette-approach",
		"eye": Vector2(229.8, -170.4), "eye_h": 1.7,
		"target": TOWER_AT, "target_h": 11.0,
	},
	{
		"name": "gate-close",
		"eye": Vector2(229.8, -162.8), "eye_h": 2.5,
		"target": TOWER_AT, "target_h": 2.65,
	},
]

## Same staging constants as `capture_castle_lite.gd` — see that file's
## `_stage_actors` header for why the actors stand on the ramp.
const ACTORS_LOCAL_Z := -13.6
const TRAINER_LOCAL_X := -0.3
const CREATURE_LOCAL_X := 3.2
const CREATURE_SPECIES := "bramblebun"
const RAMP_RUN := 11.0
const PLINTH_TOP := 4.2
const RAMP_TOP_Z := -10.0


func _init() -> void:
	_run()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	var packed: PackedScene = load(SCENE)
	if packed == null:
		push_error("could not load %s" % SCENE)
		quit(1)
		return

	var world: Node = packed.instantiate()
	root.add_child(world)
	print("[approach] scene instantiated, settling %d frames" % SETTLE_FRAMES)

	for i in SETTLE_FRAMES:
		await physics_frame
	print("[approach] settled")

	var rig: Node = world.get_node_or_null(^"CameraRig")
	if rig != null:
		rig.set_process(false)
		rig.set_physics_process(false)

	var hud: CanvasLayer = world.get_node_or_null(^"PlaygroundHUD") as CanvasLayer
	if hud != null:
		hud.visible = false

	var camera := Camera3D.new()
	camera.fov = FOV
	camera.far = 2000.0
	world.add_child(camera)
	camera.make_current()

	var look: Node = world.get_node_or_null(^"WorldLook")
	if look != null:
		look.call("apply_time", "day")

	var field: RefCounted = HEIGHTFIELD.new()

	# The scene's own player is the trainer, but it is a live CharacterBody3D
	# with a camera rig on it; parking it out of the way and staging a separate
	# static body is what `capture_wayfinding.gd` already does, and it keeps the
	# ruler in exactly the pose the lite frames put it in.
	var player: Node3D = world.get_node_or_null(^"Player") as Node3D
	if player != null:
		var park: Vector2 = VIEWPOINTS[0]["eye"]
		player.global_position = Vector3(
			park.x, field.height_at(park.x, park.y) - 500.0, park.y)
		if player is CharacterBody3D:
			(player as CharacterBody3D).velocity = Vector3.ZERO

	var landmark: Node3D = _find_landmark(world)
	if landmark == null:
		push_warning("no StrongholdSilhouette in the scene; frames have no scale ruler")
	else:
		_stage_actors(world as Node3D, landmark)
		print("[approach] actors staged on the ramp")

	for i in 60:
		await physics_frame

	var written: Array[String] = []
	var failures: Array[String] = []

	for entry: Variant in VIEWPOINTS:
		var view: Dictionary = entry
		var name: String = str(view["name"])
		var eye_xz: Vector2 = view["eye"]
		var target_xz: Vector2 = view["target"]
		camera.global_position = Vector3(
			eye_xz.x, field.height_at(eye_xz.x, eye_xz.y) + float(view["eye_h"]), eye_xz.y)
		camera.look_at(Vector3(
			target_xz.x,
			field.height_at(target_xz.x, target_xz.y) + float(view["target_h"]),
			target_xz.y), Vector3.UP)

		for i in 30:
			await physics_frame
		for i in POSE_FRAMES:
			await process_frame
		await RenderingServer.frame_post_draw

		var image := root.get_texture().get_image()
		if image == null:
			failures.append("%s: viewport returned no image" % name)
			continue
		var path := "%s/%s.png" % [OUT_DIR, name]
		var error := image.save_png(path)
		if error != OK:
			failures.append("%s: save_png failed (%d)" % [name, error])
			continue
		written.append(path)
		print("  %-26s -> %s" % [name, path])

	print("")
	print("%d frames -> %s" % [written.size(), OUT_DIR])
	if not failures.is_empty():
		for line in failures:
			print("FAIL: %s" % line)
		quit(1)
		return
	quit(0)


func _find_landmark(node: Node) -> Node3D:
	if node.name == "StrongholdSilhouette" and node is Node3D:
		return node as Node3D
	for child in node.get_children():
		var found := _find_landmark(child)
		if found != null:
			return found
	return null


func _ramp_y(z: float) -> float:
	var foot := RAMP_TOP_Z - RAMP_RUN
	return PLINTH_TOP * clampf((z - foot) / RAMP_RUN, 0.0, 1.0)


func _stage_actors(stage: Node3D, landmark: Node3D) -> void:
	var base: Vector3 = landmark.global_position
	var deck := _ramp_y(ACTORS_LOCAL_Z) + 0.2

	var trainer: Node3D = CHARACTER_MODEL.new()
	trainer.name = "ScaleTrainer"
	stage.add_child(trainer)
	if not trainer.call("build", "trainer"):
		push_warning("no trainer model; these frames have no ruler in them")
	trainer.global_position = base + Vector3(TRAINER_LOCAL_X, deck, ACTORS_LOCAL_Z)

	var creature: Node3D = CREATURE_SCENE.instantiate()
	creature.name = "ScaleCreature"
	creature.set_script(CREATURE_BODY)
	stage.add_child(creature)
	creature.call("setup", CREATURE_SPECIES)
	var drop := _lowest_point(creature)
	creature.global_position = base + Vector3(
		CREATURE_LOCAL_X, deck - drop, ACTORS_LOCAL_Z + 0.9)
	creature.rotation.y = deg_to_rad(-20.0)
	creature.set_physics_process(false)


func _lowest_point(node: Node, xform: Transform3D = Transform3D.IDENTITY) -> float:
	var lowest := 0.0
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		var box: AABB = xform * (node as MeshInstance3D).mesh.get_aabb()
		lowest = minf(lowest, box.position.y)
	for child in node.get_children():
		var next := xform
		if child is Node3D:
			next = xform * (child as Node3D).transform
		lowest = minf(lowest, _lowest_point(child, next))
	return lowest
