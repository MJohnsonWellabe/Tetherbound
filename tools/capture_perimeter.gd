extends SceneTree

## SA3's blind-judge capture: one close-up per boundary style (stone wall,
## ranch fence, hedgerow, rock formation) plus one wide shot showing the
## ring curve into the distance, per conventions.md's "visual-affecting
## work needs a blind pass, not a look."
##
##   xvfb-run -a -s "-screen 0 1280x720x24" \
##     godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/capture_perimeter.gd
##
## OF7: this header used to say `godot --headless ... --script ...`, and that
## command DOES NOT WORK — it hangs forever, silently, with no output and no
## error. `--headless` selects the dummy rendering driver, which never emits
## `RenderingServer.frame_post_draw`, so `_shoot()`'s own `await` on that
## signal below never resumes. The scene builds, the settle loop completes,
## and the process then spins the main loop at 100% CPU indefinitely without
## writing a single frame. Verified directly (a two-object scene reproduces
## it in isolation; the same scene under the command above writes a PNG in
## seconds). This is the same xvfb + `opengl3` invocation `tools/survey.sh`
## and `tools/capture_wayfinding.gd` already document, and it carries the
## same Compatibility-renderer caveat those do (D06).
##
## Throwaway: writes shots/_perimeter/*.png for the blind critic to read,
## not part of the survey and not committed.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots/_perimeter"
const SETTLE_FRAMES := 240

## RADIUS/SEGMENTS read from world_perimeter.gd itself rather than copied —
## this file used to carry its own `RADIUS := 235.0` / `SEGMENTS := 40`, a
## second hard-coded copy of the ring it photographs. world_perimeter.gd is
## the one place that answers "how big is the ring"; this preload keeps it
## that way instead of adding a second answer that can drift from the first.
##
## docs/decisions/D51 deletes this ring outright for a rectangular corridor
## boundary and, in the same breath, obsoletes this whole capture tool ("a
## tool that orbits a radius has nothing to orbit once the boundary is two
## 8 km polylines") — this file needs rewriting as a traverse then, not
## re-tuning now. Until that lands, the ring these constants describe is
## still the one in the game, so this preload keeps this file honest about
## it instead of quietly drifting from world_perimeter.gd if RADIUS/SEGMENTS
## ever change there.
const WORLD_PERIMETER := preload("res://scripts/world/world_perimeter.gd")
const RADIUS := WORLD_PERIMETER.RADIUS
const SEGMENTS := WORLD_PERIMETER.SEGMENTS

var _world: Node = null
var _camera: Camera3D = null


func _init() -> void:
	_run()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in SETTLE_FRAMES:
		await physics_frame

	# Out of Grandpa's bed. The opening's staging wakes the player there and
	# leaves the "Get up" prompt on screen (proximity-gated, see
	# interaction_arbiter.gd) until it's cleared — this capture is about the
	# perimeter, not the house, so get well clear before shooting anything.
	var player: CharacterBody3D = _world.get_node_or_null(^"Player") as CharacterBody3D
	if player != null:
		var clear := Vector3(60.0, 0.0, -60.0)
		clear.y = float(_world.call("ground_height_at", clear.x, clear.z)) + 1.0
		player.global_position = clear
		player.velocity = Vector3.ZERO
	for i in 30:
		await physics_frame

	var rig: Node = _world.get_node_or_null(^"CameraRig")
	if rig != null:
		rig.set_process(false)
		rig.set_physics_process(false)
	var hud: CanvasLayer = _world.get_node_or_null(^"PlaygroundHUD") as CanvasLayer
	if hud != null:
		hud.visible = false

	_camera = Camera3D.new()
	_camera.fov = 65.0
	_camera.far = 2000.0
	_world.add_child(_camera)
	_camera.make_current()

	# One close-up per style: segment i%4 == style, midpoint angle
	# (i + 0.5) * TAU/SEGMENTS, matching world_perimeter.gd's own cycle.
	var styles := ["stone-wall", "ranch-fence", "hedgerow", "rock-formation"]
	for style_index in 4:
		var mid_angle := (style_index + 0.5) * TAU / SEGMENTS
		var wall_point := Vector2(cos(mid_angle), sin(mid_angle)) * RADIUS
		var stand_point := Vector2(cos(mid_angle), sin(mid_angle)) * (RADIUS - 22.0)
		var ground: float = float(_world.call("ground_height_at", stand_point.x, stand_point.y))
		_camera.global_position = Vector3(stand_point.x, ground + 1.7, stand_point.y)
		var target_ground: float = float(_world.call("ground_height_at", wall_point.x, wall_point.y))
		_camera.look_at(Vector3(wall_point.x, target_ground + 1.5, wall_point.y), Vector3.UP)
		await _shoot("closeup-%s" % styles[style_index])

	# A wide shot: stand CLOSE to the boundary itself (not deep in the field)
	# and look along its own arc, so the ring stays the near/mid-ground
	# subject the whole way to the horizon instead of a thin, distant strip
	# competing with unrelated terrain. Round 3's blind critic named the
	# previous framing directly: "the actual boundary line... nearly
	# invisible... a viewer would not identify this as a boundary feature
	# from this shot." Same radius as the ring itself, offset a few metres
	# in so the near segment reads as foreground, not the boundary line.
	var wide_angle := 0.05
	var wide_point := Vector2(cos(wide_angle), sin(wide_angle)) * (RADIUS - 9.0)
	var wide_ground: float = float(_world.call("ground_height_at", wide_point.x, wide_point.y))
	_camera.global_position = Vector3(wide_point.x, wide_ground + 1.8, wide_point.y)
	var far_angle := 0.55
	var far_point := Vector2(cos(far_angle), sin(far_angle)) * (RADIUS - 2.0)
	var far_ground: float = float(_world.call("ground_height_at", far_point.x, far_point.y))
	_camera.look_at(Vector3(far_point.x, far_ground + 1.6, far_point.y), Vector3.UP)
	await _shoot("wide-ring-curve")

	print("done")
	quit(0)


func _shoot(name: String) -> void:
	for i in 6:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null:
		print("  %-24s no image" % name)
		return
	image.save_png("%s/%s.png" % [OUT_DIR, name])
	print("  wrote %s.png" % name)
