extends SceneTree

## GOLDEN-HOUR. Why the SURVEY's `05-spawn-low-sun` is black when the same
## viewpoint at the same hour renders correctly on its own.
##
## tools/_diag_golden_hour.gd already eliminated every hypothesis in
## ralph/reports/finding-golden-hour-black-frame.md: golden renders at survey
## timing, at one frame, with the clock frozen, and captured last -- highest
## spread of the three times of day. So the black frame is not the preset, not
## the settle and not the sun pitch. What is left is that `05` is the FIFTH
## capture, taken after the camera and the trainer have been teleported across
## the world four times, and the survey's own frame is a literal single colour
## (every pixel exactly RGB 0,0,0 -- an empty buffer, not a dark scene).
##
## So this replays the survey's exact sequence and settle and dumps, at every
## shutter, the things that can blank a frame without erroring:
##   * which camera the viewport is ACTUALLY rendering from -- survey.gd calls
##     make_current() once at the start and never rechecks it;
##   * every visible CanvasLayer, and any full-rect opaque ColorRect on one --
##     the survey hides PlaygroundHUD by name, but sequence_director.gd builds
##     its own "OpeningFade" black rect on layer 15 at runtime, and CombatHUD,
##     DialoguePanel, NamePrompt and StarterPicker are all layers it never
##     touches;
##   * whether the opening sequence is mid-fade, and which beat it is on;
##   * whether combat is running, which relocates the player and can bring its
##     own camera.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/_diag_survey_black.gd

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots/survey_black"

const SETTLE_FRAMES := 240
const POSE_FRAMES := 4
const SETTLE_AFTER_MOVE := 20
const ACTOR_CLEARANCE := 0.4
const FOV := 70.0
const DEFAULT_HORIZON := 0.30

## tools/survey.gd's VIEWPOINTS, copied verbatim so this is the same run.
const VIEWPOINTS := [
	{
		"name": "01-spawn-outward",
		"eye": Vector2(-9.0, -7.0), "eye_h": 2.2,
		"target": Vector2(-140.0, 145.0), "target_h": 8.0,
		"time": "day", "horizon": 0.28,
		"actor": Vector2(-15.0, -1.0),
	},
	{
		"name": "02-valley-floor",
		"eye": Vector2(-120.0, 130.0), "eye_h": 2.2,
		"target": Vector2(40.0, 40.0), "target_h": 20.0,
		"time": "day", "horizon": 0.32,
		"actor": Vector2(-108.0, 118.0),
	},
	{
		"name": "03-rise-overlook",
		"eye": Vector2(172.0, -88.0), "eye_h": 15.0,
		"target": Vector2(-60.0, 60.0), "target_h": 0.0,
		"time": "day", "horizon": 0.24,
	},
	{
		"name": "04-three-quarter",
		"eye": Vector2(70.0, 40.0), "eye_h": 8.0,
		"target": Vector2(-90.0, -60.0), "target_h": 4.0,
		"time": "day", "horizon": 0.26,
	},
	{
		"name": "05-spawn-low-sun",
		"eye": Vector2(-9.0, -7.0), "eye_h": 2.2,
		"target": Vector2(-140.0, 145.0), "target_h": 8.0,
		"time": "golden", "horizon": 0.34,
		"actor": Vector2(-15.0, -1.0),
	},
]

var _world: Node = null
var _camera: Camera3D = null


func _init() -> void:
	_run()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	var packed: PackedScene = load(SCENE)
	if packed == null:
		push_error("could not load %s" % SCENE)
		quit(1)
		return

	_world = packed.instantiate()
	root.add_child(_world)
	for i in SETTLE_FRAMES:
		await physics_frame

	var rig: Node = _world.get_node_or_null(^"CameraRig")
	if rig != null:
		rig.set_process(false)
		rig.set_physics_process(false)
	var hud: CanvasLayer = _world.get_node_or_null(^"PlaygroundHUD") as CanvasLayer
	if hud != null:
		hud.visible = false

	_camera = Camera3D.new()
	_camera.fov = FOV
	_camera.far = 2000.0
	_world.add_child(_camera)
	_camera.make_current()

	var look: Node = _world.get_node_or_null(^"WorldLook")
	var player: Node3D = _world.get_node_or_null(^"Player") as Node3D
	var field: RefCounted = HEIGHTFIELD.new()
	var terrain: Node = _world.get_node_or_null(^"Terrain")
	if terrain != null and terrain.has_method("set_camera"):
		terrain.call("set_camera", _camera)

	print("")
	print("Replaying tools/survey.gd's exact sequence, with the state dumped at")
	print("each shutter. survey camera instance id = %d" % _camera.get_instance_id())
	print("")

	for entry: Variant in VIEWPOINTS:
		var view: Dictionary = entry
		var name: String = str(view["name"])

		_pose(field, view)
		_place_actor(player, field, view)
		if look != null:
			look.call("apply_time", str(view.get("time", "day")))

		for i in SETTLE_AFTER_MOVE:
			await physics_frame
		for i in POSE_FRAMES:
			await process_frame
		await RenderingServer.frame_post_draw

		var image := root.get_texture().get_image()
		var flat := _flatness(image) if image != null else -1.0
		if image != null:
			image.save_png("%s/%s.png" % [OUT_DIR, name])

		print("%-22s spread %.4f  %s" % [name, flat, "BLACK/FLAT" if flat < 0.01 else "rendered"])
		_dump(player)
		print("")

	print("%d frames -> %s" % [VIEWPOINTS.size(), OUT_DIR])
	quit(0)


## Everything that can blank a frame without logging anything.
func _dump(player: Node3D) -> void:
	var live: Camera3D = root.get_camera_3d()
	if live == null:
		print("    CAMERA: the viewport has NO current 3D camera")
	elif live == _camera:
		print("    camera: survey camera is current, at %v" % _camera.global_position)
	else:
		print("    CAMERA CHANGED: viewport renders from '%s' at %v, NOT the survey camera at %v"
			% [live.name, live.global_position, _camera.global_position])

	if player != null:
		print("    player at %v" % player.global_position)

	var seq: Node = _world.get_node_or_null(^"SequenceDirector")
	if seq != null:
		var fading: bool = bool(seq.call("is_fading")) if seq.has_method("is_fading") else false
		var beat: String = str(seq.call("beat")) if seq.has_method("beat") else "?"
		print("    sequence: beat=%s  fading=%s" % [beat, fading])

	var combat: Node = _world.get_node_or_null(^"CombatManager")
	if combat != null and combat.has_method("is_fighting"):
		print("    combat: is_fighting=%s" % bool(combat.call("is_fighting")))

	var covers: Array[String] = []
	_walk_layers(root, covers)
	if covers.is_empty():
		print("    overlays: none visible")
	else:
		for line in covers:
			print("    OVERLAY: %s" % line)


## Any visible CanvasLayer, and on it any Control that covers the whole frame
## with something opaque enough to be what the shutter caught.
func _walk_layers(node: Node, out: Array[String]) -> void:
	for child in node.get_children():
		if child is CanvasLayer:
			var layer := child as CanvasLayer
			if layer.visible:
				out.append("CanvasLayer '%s' (layer %d) visible%s"
					% [layer.name, layer.layer, _opaque_children(layer)])
		_walk_layers(child, out)


func _opaque_children(layer: CanvasLayer) -> String:
	var found := ""
	for c in layer.get_children():
		var ctrl := c as Control
		if ctrl == null or not ctrl.visible:
			continue
		var rect := ctrl as ColorRect
		if rect != null:
			found += "  [ColorRect '%s' colour %s alpha %.3f size %v]" % [
				rect.name, rect.color.to_html(false), rect.color.a * ctrl.modulate.a,
				ctrl.size]
		else:
			found += "  [%s '%s' alpha %.3f size %v]" % [
				ctrl.get_class(), ctrl.name, ctrl.modulate.a, ctrl.size]
	return found


func _pose(field: RefCounted, view: Dictionary) -> void:
	var eye_xz: Vector2 = view["eye"]
	var target_xz: Vector2 = view["target"]
	var eye := Vector3(eye_xz.x, field.height_at(eye_xz.x, eye_xz.y) + float(view["eye_h"]), eye_xz.y)
	var target := Vector3(
		target_xz.x, field.height_at(target_xz.x, target_xz.y) + float(view["target_h"]), target_xz.y)
	_camera.global_position = eye
	_camera.look_at(target, Vector3.UP)
	_camera.rotation = Vector3(
		_pitch_for_horizon(float(view.get("horizon", DEFAULT_HORIZON))), _camera.rotation.y, 0.0)


func _place_actor(player: Node3D, field: RefCounted, view: Dictionary) -> void:
	if player == null:
		return
	if not view.has("actor"):
		var eye_xz: Vector2 = view["eye"]
		player.global_position = Vector3(
			eye_xz.x, field.height_at(eye_xz.x, eye_xz.y) - 500.0, eye_xz.y)
		return
	var xz: Vector2 = view["actor"]
	player.global_position = Vector3(xz.x, field.height_at(xz.x, xz.y) + ACTOR_CLEARANCE, xz.y)
	var away := player.global_position - _camera.global_position
	player.rotation = Vector3(0.0, atan2(away.x, away.z) + 0.35, 0.0)


func _pitch_for_horizon(fraction: float) -> float:
	var half := tan(deg_to_rad(FOV) * 0.5)
	return -atan((0.5 - clampf(fraction, 0.05, 0.95)) * 2.0 * half)


func _flatness(image: Image) -> float:
	var width := image.get_width()
	var height := image.get_height()
	var step := maxi(1, width / 64)
	var lowest := Vector3(INF, INF, INF)
	var highest := Vector3(-INF, -INF, -INF)
	for y in range(0, height, step):
		for x in range(0, width, step):
			var c := image.get_pixel(x, y)
			lowest = Vector3(minf(lowest.x, c.r), minf(lowest.y, c.g), minf(lowest.z, c.b))
			highest = Vector3(maxf(highest.x, c.r), maxf(highest.y, c.g), maxf(highest.z, c.b))
	return (highest - lowest).length()
