extends SceneTree

## CL-G10 / D73 §6. Evidence for the conversation push-in: does a villager
## actually read at handheld size once the camera has pushed in, and does the
## shot clip anything on the way?
##
##   xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/_capture_dialogue_camera.gd
##
## NEVER with `--headless` and a real rendering driver.
##
## THE FRAMES ARE SHOT THROUGH THE GAME'S OWN CAMERA. Every other capture tool
## in `tools/` parks a free Camera3D at a hand-authored eye point, because what
## those tools are judging is the world. What this one is judging IS the camera,
## so a second camera posed by hand would prove nothing at all — it would only
## show that this file can do arithmetic. The player is walked to the villager,
## `interaction_arbiter.gd::activate()` is pressed for real, the villager's own
## `_on_greeted` opens the dialogue panel, the panel tells the rig to push in,
## and the frame is whatever `CameraRig/Camera3D` is looking at when the blend
## finishes. If the hook is not wired the "after" frame is identical to the
## "before" frame and the sheet says so.
##
## Each stand is captured twice — once with the box shut, once mid-conversation —
## because "the villager reads too small" is a comparison and a single frame
## cannot answer it.
##
## Two stands, both named by the brief:
##   * Halda outdoors on the village's east side, the ordinary open-air case;
##   * Bram inside the inn, the cramped-room case the push-in has to survive
##     without putting the lens through a wall.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const OUT_DIR := "res://shots/_diag/dialogue_camera"

## Long enough for the village to build, the NPCs to be placed and the ground to
## settle under the player. Copied from `tools/_capture_band1_places.gd`, which
## records why a short settle produces a maroon wash and a floating trainer.
const SETTLE_FRAMES := 240
const SETTLE_AFTER_MOVE := 40
## `camera.json`'s blend is 0.45s; this is comfortably past it at 60Hz, and the
## rig re-solves every frame so extra frames only make the shot more settled.
const BLEND_FRAMES := 60
const POSE_FRAMES := 4

const STANDS := [
	{
		"name": "halda-outdoors",
		# Halda stands at (23.5, 11.5) facing 215 deg (data/config/village_npcs.json).
		# The player is put 2.3m off her front, which is where you end up when
		# you walk up to somebody and the prompt appears (npc_body.gd's prompt
		# radius is 3.8m).
		"npc": "Halda",
		"stand": Vector2(25.4, 10.2),
	},
	{
		"name": "bram-indoors",
		# Bram is inside the inn: the prefab is sited at (-1.5,-9.0) yaw 90 deg
		# (data/config/village.json), a 6x10 shell, so its floor runs roughly
		# x -6.5..3.5 by z -12..-6, and Bram at (-5.89,-9.0) stands against the
		# west wall. The player is put between him and the door, facing west --
		# the approach a player actually makes coming in off the square.
		"npc": "Bram",
		"stand": Vector2(-3.5, -9.0),
	},
	{
		# The same room with the player backed into the east half of it, so the
		# camera has a wall where its 3.5m arm wants to be. This is the stand
		# the collision fallback exists for; captured so the judge can say
		# whether the closer over-shoulder still reads, not just that it fired.
		"name": "bram-indoors-cramped",
		"npc": "Bram",
		"stand": Vector2(-5.0, -10.6),
	},
]

var _failures: Array[String] = []
var _written: Array[String] = []


func _init() -> void:
	_run()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("headless has no renderer; run this under xvfb-run")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	var packed: PackedScene = load(SCENE)
	if packed == null:
		push_error("could not load %s" % SCENE)
		quit(1)
		return
	var world: Node = packed.instantiate()
	root.add_child(world)

	# Weather and clock frozen for the same reason every capture tool freezes
	# them: a drifting sun makes two frames of the same stand incomparable.
	var weather: Node = world.get_node_or_null(^"WorldWeather")
	if weather != null and weather.has_method("set_weather"):
		weather.call("set_weather", "clear")
		weather.set_process(false)
		weather.set_physics_process(false)

	for _i in SETTLE_FRAMES:
		await physics_frame

	var look: Node = world.get_node_or_null(^"WorldLook")
	if look != null:
		if look.has_method("set_clock_frozen"):
			look.call("set_clock_frozen", true)
		if look.has_method("apply_time"):
			look.call("apply_time", "day")

	var rig: Node3D = world.get_node_or_null(^"CameraRig") as Node3D
	var camera: Camera3D = rig.get_node_or_null(^"Camera3D") as Camera3D if rig != null else null
	var player: Node3D = world.get_node_or_null(^"Player") as Node3D
	var arbiter: Node = world.get_node_or_null(^"InteractionArbiter")
	var panel: Node = world.get_node_or_null(^"DialoguePanel")
	if rig == null or camera == null or player == null or arbiter == null or panel == null:
		push_error("the playground is missing CameraRig/Camera3D, Player, InteractionArbiter or DialoguePanel")
		quit(1)
		return
	camera.make_current()

	var terrain: Node = world.get_node_or_null(^"Terrain")
	if terrain != null and terrain.has_method("set_camera"):
		terrain.call("set_camera", camera)

	# The world HUD would otherwise sit over both halves of every comparison.
	var hud: CanvasLayer = world.get_node_or_null(^"PlaygroundHUD") as CanvasLayer
	if hud != null:
		hud.visible = false

	var field: RefCounted = HEIGHTFIELD.new()

	for entry: Variant in STANDS:
		await _capture_stand(entry as Dictionary, world, rig, camera, player, arbiter, panel, field)

	print("")
	print("%d frames -> %s" % [_written.size(), OUT_DIR])
	print("Software rendering. Frame times from this harness are NOT a performance measurement.")
	if not _failures.is_empty():
		print("")
		for line in _failures:
			print("FAIL: %s" % line)
		quit(1)
		return
	quit(0)


func _capture_stand(stand: Dictionary, world: Node, rig: Node3D, camera: Camera3D,
		player: Node3D, arbiter: Node, panel: Node, field: RefCounted) -> void:
	var label := str(stand["name"])
	var npc := _find_npc(world, str(stand["npc"]))
	if npc == null:
		_failures.append("%s: no villager named '%s' in the built village" % [label, stand["npc"]])
		return

	var xz: Vector2 = stand["stand"]
	player.global_position = Vector3(xz.x, field.height_at(xz.x, xz.y) + 0.4, xz.y)
	# Facing the person, because the interaction arbiter tests line of sight and
	# because a trainer photographed from behind their own back is not the shot.
	var toward := npc.global_position - player.global_position
	player.rotation = Vector3(0.0, atan2(toward.x, toward.z), 0.0)
	if rig.has_method("_recentre_behind_target"):
		rig.call("_recentre_behind_target")

	for _i in SETTLE_AFTER_MOVE:
		await physics_frame
	await _shoot("%s-before" % label, player, camera, npc)

	# The real press. `activate()` is what `interaction_arbiter.gd` calls when
	# the player pushes the button, so everything downstream of it -- the
	# villager's greeting branch, the dialogue panel, the push-in -- runs exactly
	# as it does in the game.
	var prompt := str(arbiter.call("prompt")) if arbiter.has_method("prompt") else ""
	if not bool(arbiter.call("activate")):
		_failures.append("%s: the arbiter refused to activate (prompt was '%s')" % [label, prompt])
		return
	for _i in BLEND_FRAMES:
		await physics_frame

	if not bool(panel.call("is_open")):
		_failures.append("%s: pressing the prompt did not open a conversation" % label)
		return
	if rig.has_method("is_in_conversation") and not bool(rig.call("is_in_conversation")):
		_failures.append("%s: the conversation opened but the camera never pushed in" % label)
		return
	var shot: Dictionary = rig.call("conversation_shot") if rig.has_method("conversation_shot") else {}
	print("  %-24s prompt '%s'  arm %.2fm  fov %.1f  fallback %s" % [
		label, prompt, rig.get("spring_length"), camera.fov,
		"yes" if bool(shot.get("fallback", false)) else "no"])

	await _shoot("%s-conversation" % label, player, camera, npc)

	# Put the world back so the next stand starts from the exploration camera.
	panel.call("close")
	for _i in BLEND_FRAMES:
		await physics_frame


## The villagers are children of the node that placed them, each named for the
## person, so the body is found by name rather than by walking every node in the
## world (`village_npcs.gd::_spawn`).
func _find_npc(world: Node, who: String) -> Node3D:
	var found: Node3D = null
	var pending: Array[Node] = [world]
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		if node.name == who and node is Node3D and node.has_method("height"):
			found = node as Node3D
			break
		for child in node.get_children():
			pending.append(child)
	return found


func _shoot(name: String, player: Node3D, camera: Camera3D, npc: Node3D) -> void:
	for _i in POSE_FRAMES:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null:
		_failures.append("%s: the viewport returned no image" % name)
		return
	var path := "%s/%s.png" % [OUT_DIR, name]
	if image.save_png(path) != OK:
		_failures.append("%s: save_png failed" % name)
		return
	_written.append(path)

	# Two numbers decided before the render, printed so the report can quote
	# them rather than describe the picture: how much of the frame's height the
	# speaker's own body subtends, and how far the lens is from them. The first
	# is the whole claim ("villagers read too small"); the second is the claim
	# that nothing is clipping.
	var subtended := _subtended_height_fraction(camera, npc)
	var lens_gap := camera.global_position.distance_to(npc.global_position)
	print("    %-26s speaker fills %.1f%% of frame height, lens %.2fm from them, player %.2fm" % [
		name, subtended * 100.0, lens_gap,
		camera.global_position.distance_to(player.global_position)])


## The fraction of the viewport's height the speaker's body occupies, projected
## through the real camera. Measured rather than eyeballed: "reads too small" is
## a number, and a push-in that does not raise it has not done anything.
func _subtended_height_fraction(camera: Camera3D, npc: Node3D) -> float:
	var height: float = float(npc.call("height")) if npc.has_method("height") else 1.8
	var feet := npc.global_position
	var head := feet + Vector3.UP * height
	if camera.is_position_behind(feet) or camera.is_position_behind(head):
		return 0.0
	var viewport_height := float(camera.get_viewport().get_visible_rect().size.y)
	if viewport_height <= 0.0:
		return 0.0
	var top := camera.unproject_position(head)
	var bottom := camera.unproject_position(feet)
	return absf(bottom.y - top.y) / viewport_height
