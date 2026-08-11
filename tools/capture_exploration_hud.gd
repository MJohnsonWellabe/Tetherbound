extends SceneTree

## Capture the real exploration HUD (EV9) over live gameplay, for the visual
## critic loop. Loads the full meadows scene the way tools/survey.gd does
## (proven reliable under xvfb+opengl3 — the trap that once made a bespoke
## loader die silently was in the loader, not in loading this scene), but
## keeps PlaygroundHUD visible instead of hiding it, since the HUD is exactly
## what this is judging.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" \
##     godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/capture_exploration_hud.gd
##
## Two frames:
##   hud_idle - just spawned, full health/stamina, vitals bars faded out
##   hud_hurt - health and stamina forced down, bars pulled to full opacity

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots/_diag"

const SETTLE_FRAMES := 240
const POSE_FRAMES := 6
const FADE_SETTLE_FRAMES := 30


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

	for i in SETTLE_FRAMES:
		await physics_frame

	var rig: Node = world.get_node_or_null(^"CameraRig")
	if rig != null:
		rig.set_process(false)
		rig.set_physics_process(false)

	var player: CharacterBody3D = world.get_node_or_null(^"Player") as CharacterBody3D
	var field: RefCounted = HEIGHTFIELD.new()

	var camera := Camera3D.new()
	camera.fov = 70.0
	camera.far = 2000.0
	world.add_child(camera)
	camera.make_current()

	var written: Array[String] = []
	var failures: Array[String] = []

	# A three-quarter view over the player's shoulder, close enough that the
	# HUD's real screen-space scale is judged, not a tiny figure in a wide shot.
	var eye_xz := Vector2(-9.0, -4.0)
	var eye_h := 3.4
	camera.global_position = Vector3(eye_xz.x, field.height_at(eye_xz.x, eye_xz.y) + eye_h, eye_xz.y)
	player.global_position = Vector3(-15.0, field.height_at(-15.0, -1.0) + 0.4, -1.0)
	camera.look_at(player.global_position + Vector3.UP, Vector3.UP)

	for i in 20:
		await physics_frame

	await _shoot(camera, "hud_idle", written, failures)

	# Force the vitals bars into their "relevant" state, so the fill colours
	# and the fade-in are both visible in a still.
	var vitals: RefCounted = player.get("vitals")
	if vitals != null:
		vitals.health = 34.0
		vitals.stamina = 22.0
	for i in FADE_SETTLE_FRAMES:
		await process_frame

	await _shoot(camera, "hud_hurt", written, failures)

	print("")
	print("%d frames -> %s" % [written.size(), OUT_DIR])
	print("Software rendering. Frame times from this harness are NOT a performance measurement.")

	if not failures.is_empty():
		print("")
		for line in failures:
			print("FAIL: %s" % line)
		quit(1)
		return
	quit(0)


func _shoot(camera: Camera3D, name: String, written: Array[String], failures: Array[String]) -> void:
	for i in POSE_FRAMES:
		await process_frame
	await RenderingServer.frame_post_draw

	var image := root.get_texture().get_image()
	if image == null:
		failures.append("%s: viewport returned no image" % name)
		return

	var path := "%s/%s.png" % [OUT_DIR, name]
	var error := image.save_png(path)
	if error != OK:
		failures.append("%s: save_png failed (%d)" % [name, error])
		return

	written.append(path)
	print("  %-16s -> %s" % [name, path])
