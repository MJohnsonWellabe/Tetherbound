extends SceneTree

## BACKLOG-D6-SEAM-PROBE, second follow-up. The mip/filter probe
## (_audit_d6_mipfilter_probe.gd) found the dashed line's contrast UNCHANGED
## by disabling per-tile detiling or forcing mipmap_bias to its blurriest
## setting -- ruling that hypothesis out too, the same way the predecessor
## probe ruled out the clipmap. A perfectly straight, perfectly regular
## dashed line that is insensitive to BOTH clipmap settings AND texture
## sampling settings is not behaving like ground material at all -- which
## points at Terrain3DMaterial's own debug overlays
## (show_region_grid/show_vertex_grid/show_contours/show_navigation), a
## separate render pass layered on top of the material and untouched by
## either prior probe. This just reads their live values and, if any is on,
## captures one frame with all four forced off at the same fixed camera.
##
##   xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/_audit_d6_debug_overlay_probe.gd

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const CAPTURE_CHECK := preload("res://tools/capture_check.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots/audit-d6"

const BOOT_FRAMES := 90
const ARRIVE_FRAMES := 15
const REFRAME_FRAMES := 15
const RECONFIG_FRAMES := 30
const POSE_FRAMES := 3
const FOV := 70.0
const GROUND_BACK := 2.2
const GROUND_UP := 2.0
const GROUND_AHEAD := 4.5

const EYE_XZ := Vector2(8.0, 90.0)
const AIM_XZ := Vector2(-40.0, 180.0)

const DEBUG_FLAGS := ["show_region_grid", "show_vertex_grid", "show_contours",
	"show_navigation", "show_instancer_grid"]

var _field: RefCounted = null
var _world: Node = null
var _camera: Camera3D = null
var _player: Node3D = null
var _terrain: Node = null
var _material: Object = null
var _failures: Array[String] = []


func _init() -> void:
	_run()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("headless has no renderer; run under xvfb-run (see header)")
		quit(1)
		return

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	_field = HEIGHTFIELD.new()
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in BOOT_FRAMES:
		await physics_frame

	var rig: Node = _world.get_node_or_null(^"CameraRig")
	if rig != null:
		rig.set_process(false)
		rig.set_physics_process(false)
	for node in _all(_world):
		if node is CanvasLayer:
			(node as CanvasLayer).visible = false

	_player = _world.get_node_or_null(^"Player") as Node3D
	_camera = Camera3D.new()
	_camera.fov = FOV
	_camera.far = 4000.0
	_world.add_child(_camera)
	_camera.make_current()

	_terrain = _world.get_node_or_null(^"Terrain")
	if _terrain == null:
		print("FAIL no Terrain node; nothing to probe")
		quit(1)
		return
	if _terrain.has_method("set_camera"):
		_terrain.call("set_camera", _camera)
	_material = _terrain.get("material")
	if _material == null:
		print("FAIL terrain has no material; nothing to probe")
		quit(1)
		return

	var look: Node = _world.get_node_or_null(^"WorldLook")
	var weather: Node = _world.get_node_or_null(^"WorldWeather")
	if weather != null:
		weather.call("set_weather", "clear")
		weather.set_process(false)
		weather.set_physics_process(false)
	if look != null:
		look.call("apply_time", "day")
		look.set_process(false)
		look.set_physics_process(false)

	var forward := (AIM_XZ - EYE_XZ).normalized()
	var cam_xz := EYE_XZ - forward * GROUND_BACK
	var target_xz := EYE_XZ + forward * GROUND_AHEAD
	if _player != null:
		_player.global_position = Vector3(EYE_XZ.x,
			_field.height_at(EYE_XZ.x, EYE_XZ.y) + 0.4, EYE_XZ.y)
	_frame(cam_xz, _field.height_at(cam_xz.x, cam_xz.y),
		target_xz, _field.height_at(target_xz.x, target_xz.y))
	for i in ARRIVE_FRAMES:
		await physics_frame
	if _player != null:
		_player.global_position = Vector3(EYE_XZ.x, _surface(EYE_XZ) + 0.4, EYE_XZ.y)
	_frame(cam_xz, _surface(cam_xz), target_xz, _surface(target_xz))
	for i in REFRAME_FRAMES:
		await physics_frame

	var default_values: Dictionary = {}
	for flag in DEBUG_FLAGS:
		default_values[flag] = _material.get(flag)
	print("[overlay-probe] live debug overlay flags: %s" % str(default_values))

	var any_on := false
	for flag in DEBUG_FLAGS:
		if bool(default_values[flag]):
			any_on = true
	if not any_on:
		print("[overlay-probe] all debug overlays already OFF; capturing baseline only for the record")

	await _shoot("seam-probe-overlay-asfound")

	for flag in DEBUG_FLAGS:
		_material.set(flag, false)
	for i in RECONFIG_FRAMES:
		await physics_frame
	print("[overlay-probe] forced all debug overlays OFF")
	await _shoot("seam-probe-overlay-forcedoff")

	for flag in DEBUG_FLAGS:
		_material.set(flag, default_values[flag])

	if not _failures.is_empty():
		for line in _failures:
			print("FAIL: %s" % line)
		quit(1)
		return
	print("[overlay-probe] 2 frames -> %s" % OUT_DIR)
	quit(0)


func _frame(cam_xz: Vector2, cam_ground: float, target_xz: Vector2, target_ground: float) -> void:
	_camera.global_position = Vector3(cam_xz.x, cam_ground + GROUND_UP, cam_xz.y)
	_camera.look_at(Vector3(target_xz.x, target_ground, target_xz.y), Vector3.UP)


func _surface(at: Vector2) -> float:
	var analytic: float = _field.height_at(at.x, at.y)
	var space: PhysicsDirectSpaceState3D = (_world as Node3D).get_world_3d().direct_space_state
	if space == null:
		return analytic
	var query := PhysicsRayQueryParameters3D.create(
		Vector3(at.x, analytic + 400.0, at.y), Vector3(at.x, analytic - 400.0, at.y))
	query.collide_with_areas = false
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		print("  WARN no collision under (%.0f, %.0f); using analytic %.2f" % [at.x, at.y, analytic])
		return analytic
	return float((hit["position"] as Vector3).y)


func _shoot(name: String) -> void:
	for i in POSE_FRAMES:
		await process_frame
	await RenderingServer.frame_post_draw
	var problems := CAPTURE_CHECK.warn_only(self, _camera, "clear")
	for p: String in problems:
		_failures.append("%s: %s" % [name, p])
	var image := root.get_texture().get_image()
	if image == null:
		_failures.append("%s: viewport returned no image" % name)
		return
	var path := "%s/%s.png" % [OUT_DIR, name]
	if image.save_png(path) != OK:
		_failures.append("%s: save_png failed" % name)
		return
	print("  %-24s -> %s" % [name, path])


func _all(node: Node) -> Array[Node]:
	var out: Array[Node] = [node]
	for child in node.get_children():
		out.append_array(_all(child))
	return out
