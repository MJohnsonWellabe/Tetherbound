extends SceneTree

## AUDIT-D (2026-08-31): the deciding test for exit-criterion D6's residual
## dashed-hairline artefact, exactly as `ralph/reports/handover-T1-GROUND-3-
## 2026-08-30.md` §2 specified it and no lane has yet run it:
##
##   "render one frame with Terrain3D's `mesh_lods`/`mesh_size` changed. If
##    the line spacing moves, it is the clipmap and the fix is an addon
##    setting or an upstream issue; if it does not, the clipmap is out too."
##
## Three frames from ONE fixed camera transform at the band-1 opening stand
## (the frame the artefact was originally reported in), day/clear, differing
## only in the terrain clipmap configuration:
##
##   seam-probe-default.png     mesh_size / mesh_lods as shipped
##   seam-probe-meshsize.png    mesh_size halved
##   seam-probe-lods.png        mesh_size restored, mesh_lods reduced to 4
##
## The camera never moves between the three, so a pixel diff isolates what the
## clipmap change moved. This tool changes NOTHING on disk and nothing in any
## game file: `mesh_size`/`mesh_lods` are set on the live Terrain3D node for
## the lifetime of this process only.
##
## Invocation (never --headless with a rendering driver; see
## ralph/conventions.md "Art pipeline traps"):
##
##   xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/_audit_d_seam_probe.gd
##
## Boot/seat/settle constants and helpers are lifted from
## tools/_capture_ground_and_sky.gd, which already paid for every trap they
## avoid (analytic-vs-collision surface disagreement, HUD layers built during
## _ready, Terrain3D needing the capture camera handed to it).

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const CAPTURE_CHECK := preload("res://tools/capture_check.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots/audit-d"

const BOOT_FRAMES := 90
const ARRIVE_FRAMES := 15
const REFRAME_FRAMES := 15
const RECONFIG_FRAMES := 30  # clipmap rebuild + restream after a mesh_size/lods change
const POSE_FRAMES := 3
const FOV := 70.0
const GROUND_BACK := 2.2
const GROUND_UP := 2.0
const GROUND_AHEAD := 4.5

## The band-1 opening stand, byte-identical to _capture_ground_and_sky.gd's
## `ground-01-band1-opening` entry -- the artefact's own reported location.
const EYE_XZ := Vector2(8.0, 90.0)
const AIM_XZ := Vector2(-40.0, 180.0)

var _field: RefCounted = null
var _world: Node = null
var _camera: Camera3D = null
var _player: Node3D = null
var _terrain: Node = null
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

	# Arrive: analytic seat first so Terrain3D streams, then reseat on the
	# real collision surface (the two disagree by metres in places).
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

	# Record what the shipped clipmap actually is before touching it, so the
	# probe reports facts rather than assumed defaults.
	var default_mesh_size: Variant = _terrain.get("mesh_size")
	var default_mesh_lods: Variant = _terrain.get("mesh_lods")
	print("[seam-probe] shipped clipmap: mesh_size=%s mesh_lods=%s" % [
		str(default_mesh_size), str(default_mesh_lods)])
	if default_mesh_size == null or default_mesh_lods == null:
		print("FAIL Terrain3D exposes no mesh_size/mesh_lods; probe cannot run")
		quit(1)
		return

	await _shoot("seam-probe-default")

	_terrain.set("mesh_size", int(default_mesh_size) / 2)
	for i in RECONFIG_FRAMES:
		await physics_frame
	print("[seam-probe] mesh_size now %s" % str(_terrain.get("mesh_size")))
	await _shoot("seam-probe-meshsize")

	_terrain.set("mesh_size", default_mesh_size)
	_terrain.set("mesh_lods", 4)
	for i in RECONFIG_FRAMES:
		await physics_frame
	print("[seam-probe] mesh_size restored %s, mesh_lods now %s" % [
		str(_terrain.get("mesh_size")), str(_terrain.get("mesh_lods"))])
	await _shoot("seam-probe-lods")

	# Leave the live node as found -- paranoia only, the process exits anyway.
	_terrain.set("mesh_lods", default_mesh_lods)

	if not _failures.is_empty():
		for line in _failures:
			print("FAIL: %s" % line)
		quit(1)
		return
	print("[seam-probe] 3 frames -> %s" % OUT_DIR)
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
