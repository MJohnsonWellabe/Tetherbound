extends SceneTree

## Capture the REAL minimap (D33 / spec §6A) as `PlaygroundHUD` actually
## draws it, over live gameplay, for the visual critic loop.
##
##   xvfb-run -a -s "-screen 0 1920x1080x24" \
##     godot --path . --rendering-driver opengl3 \
##     --script tools/capture_minimap.gd
##
## Rewritten: this used to build a SECOND, hand-assembled `minimap.gd`
## widget on top of the real scene, because at the time `playground_hud.gd`
## did not mount one yet. That stopped being true once the minimap was
## wired into the HUD (`playground_hud.gd::_mount_minimap()`) -- this file's
## own header comment saying otherwise went stale and nobody caught it,
## so every capture since kept drawing a demo widget ALONGSIDE the real
## HUD's own, now-live one. A blind reviewer looking at the result correctly
## read that as "two minimaps," which is not a real in-game defect -- a
## player only ever sees the one `PlaygroundHUD` owns -- but the capture
## tool itself was actively misleading about it. Fixed by seeding real
## `Game.map` state (the same public API a story beat or a walked-over
## landmark would call) and screenshotting the HUD's OWN minimap, not a
## stand-in.
##
## Two frames:
##   minimap_fogged.png      - fresh fog, only a player-local reveal, and a
##                              far-off objective so the rim-clamp + distance
##                              label are visible.
##   minimap_discovered.png  - a broad reveal around the village/house,
##                              several landmarks discovered, and a nearby
##                              wild pal (close enough that the HUD's own
##                              PAL_SHOW_DISTANCE logic actually draws it).

const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots/_diag"

const SETTLE_FRAMES := 240
const POSE_FRAMES := 6


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
	current_scene = world

	for i in SETTLE_FRAMES:
		await physics_frame

	var rig: Node = world.get_node_or_null(^"CameraRig")
	if rig != null:
		rig.set_process(false)
		rig.set_physics_process(false)

	var player: CharacterBody3D = world.get_node_or_null(^"Player") as CharacterBody3D
	if player == null:
		push_error("no Player node in %s" % SCENE)
		quit(1)
		return

	var hud: CanvasLayer = world.get_node_or_null(^"PlaygroundHUD") as CanvasLayer
	if hud == null:
		push_error("no PlaygroundHUD in %s -- nothing to capture" % SCENE)
		quit(1)
		return

	var game := root.get_node_or_null(^"/root/Game")
	if game == null:
		push_error("Game autoload not found — cannot reach Game.map")
		quit(1)
		return
	var map_state: RefCounted = game.get("map")

	# A three-quarter camera over the player, same idiom as
	# capture_exploration_hud.gd, so the frame reads as real gameplay rather
	# than the minimap floating over a black viewport.
	var camera := Camera3D.new()
	camera.fov = 70.0
	camera.far = 2000.0
	world.add_child(camera)
	camera.make_current()
	var eye_xz := Vector2(player.global_position.x - 9.0, player.global_position.z - 4.0)
	var ground_height: float = world.call("ground_height_at", eye_xz.x, eye_xz.y)
	camera.global_position = Vector3(eye_xz.x, ground_height + 3.4, eye_xz.y)
	camera.look_at(player.global_position + Vector3.UP, Vector3.UP)

	var written: Array[String] = []
	var failures: Array[String] = []

	# --- (a) fogged: player-local reveal only, objective far off-screen ---
	map_state.mark_visited(player.global_position)
	game.call("set_objective", "Restore the Old Mill Crossing", Vector3(200.0, 0.0, -140.0))
	await _shoot("minimap_fogged", written, failures)

	# --- (b) discovered: broad reveal + landmarks + a nearby wild pal ---
	# reveal_circle is the debug/testing-only broad reveal (no landmark side
	# effects, map_state.gd's own contract) — used here to give the shot a
	# visibly explored area wider than one player-radius reveal would.
	map_state.reveal_circle(Vector3(-6.0, 0.0, -13.0), 55.0)
	# mark_visited (unlike reveal_circle) also discovers any landmark whose
	# own discover_radius the point falls inside — a short walk over each
	# landmark's own position discovers grandpa_house, village and road_gate
	# without needing to know their individual radii here.
	for point in [Vector3(-22.0, 0.0, -16.0), Vector3(10.0, 0.0, -10.0), Vector3(27.5, 0.0, -16.0)]:
		map_state.mark_visited(point)

	# minimap.gd's own PAL_SHOW_DISTANCE (15m) hides a pal marker closer than
	# that — 20m keeps this frame honestly showing what the HUD draws by
	# default rather than a marker that only exists because this script
	# reached past the widget's own logic.
	var director := world.get_node_or_null(^"EncounterDirector")
	var wild: Node3D = director.call("wild_pal") if director != null else null
	if wild != null:
		wild.global_position = player.global_position + Vector3(20.0, 0.0, 0.0)
	await _shoot("minimap_discovered", written, failures)

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


func _shoot(name: String, written: Array[String], failures: Array[String]) -> void:
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
	print("  %-20s -> %s" % [name, path])
