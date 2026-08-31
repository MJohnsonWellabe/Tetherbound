extends SceneTree

## BACKLOG-D6-SEAM-PAINT-BOUNDARY, testing the untested lead named at the end
## of `ralph/reports/audit/D6-seam-probe/SHADER-FIX-STATUS-2026-08-31.md`:
## the dashed terrain seam may be a control-map PAINT BOUNDARY artefact
## (texture_id[0] changing where the painted texture changes, e.g. path
## meeting grass) rather than a same-texture detiling-tile artefact. That
## report tried three fade mechanisms keyed on tile position/footprint/
## region_mip and none moved the seam; it also directly ruled out the
## footprint-vs-tile-size theory (fragment footprint measured <0.02 tile
## units via a lighting-independent EMISSION readout). Item 3/4 of its "what
## a real fix still needs" section asks to test the paint-boundary theory
## directly, through EMISSION (not albedo -- that channel was shown
## untrustworthy at this stand), before building any new fade.
##
## Same fixed camera as every prior D6 probe (band-1 opening stand, one frame
## per configuration, camera never moves): EYE_XZ (8,90) -> AIM_XZ (-40,180).
##
## Shots:
##   seam-probe-paint-default.png   unmodified shader (diag mode 0). Canary --
##                                   must show the same dashed line as
##                                   seam-probe-mip-default.png; if it doesn't,
##                                   the camera/scene state has drifted and the
##                                   rest of this run isn't comparable.
##   seam-probe-paint-idmap.png     diag mode 1: EMISSION = hashed colour per
##                                   texture_ids[3].x (the base painted
##                                   texture id at this fragment's nearest
##                                   control-map sample). Lighting-free.
##   seam-probe-paint-idedge.png    diag mode 2: EMISSION = white where
##                                   texture_ids[3].x OR .y changes across this
##                                   fragment's own screen footprint (a raw
##                                   control-map paint boundary), black
##                                   elsewhere.
##
## If idedge's white line lands where default's dashed seam sits (same crop
## box as every prior D6 probe, (820,510)-(1000,555)), the paint-boundary
## theory is CONFIRMED and a blend/texture_id-keyed fade is the next step.
## If idedge is blank or uncorrelated there, the theory is RULED OUT and the
## faint residual named in FOLLOWUP-2026-08-31.md is still unexplained.
##
## This tool changes NOTHING on disk. `diag_paint_boundary_mode` is a shader
## uniform pushed live via set_shader_param, restored to 0 before exit as
## paranoia (the process exits anyway; same pattern as the mipfilter probe).
##
## Invocation (never --headless with a rendering driver; see
## ralph/conventions.md "Art pipeline traps"):
##
##   xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/_audit_d6_paint_boundary_probe.gd

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const CAPTURE_CHECK := preload("res://tools/capture_check.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots/audit-d6"

const BOOT_FRAMES := 90
const ARRIVE_FRAMES := 15
const REFRAME_FRAMES := 15
const RECONFIG_FRAMES := 10
const POSE_FRAMES := 3
const FOV := 70.0
const GROUND_BACK := 2.2
const GROUND_UP := 2.0
const GROUND_AHEAD := 4.5

## Byte-identical to every prior D6 probe's stand -- the artefact's own
## reported location, and the frame all of them share.
const EYE_XZ := Vector2(8.0, 90.0)
const AIM_XZ := Vector2(-40.0, 180.0)

## Same crop box as seam-probe-mip-*-crop-isolated.jpg, so this session's
## crops line up pixel-for-pixel with the predecessor evidence.
const CROP_RECT := Rect2i(820, 510, 180, 45)
const CROP_SCALE := 6

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

	var default_mode: Variant = _material.call("get_shader_param", "diag_paint_boundary_mode")
	print("[paint-boundary-probe] shipped diag_paint_boundary_mode=%s" % str(default_mode))

	await _shoot("seam-probe-paint-default")

	_material.call("set_shader_param", "diag_paint_boundary_mode", 1)
	for i in RECONFIG_FRAMES:
		await physics_frame
	print("[paint-boundary-probe] diag mode 1 (raw id map)")
	await _shoot("seam-probe-paint-idmap")

	_material.call("set_shader_param", "diag_paint_boundary_mode", 2)
	for i in RECONFIG_FRAMES:
		await physics_frame
	print("[paint-boundary-probe] diag mode 2 (id-change edge mask)")
	await _shoot("seam-probe-paint-idedge")

	# Leave the live node as found -- paranoia only, the process exits anyway.
	_material.call("set_shader_param", "diag_paint_boundary_mode", 0)

	if not _failures.is_empty():
		for line in _failures:
			print("FAIL: %s" % line)
		quit(1)
		return
	print("[paint-boundary-probe] 3 frames + crops -> %s" % OUT_DIR)
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

	var crop := image.get_region(CROP_RECT)
	crop.resize(CROP_RECT.size.x * CROP_SCALE, CROP_RECT.size.y * CROP_SCALE, Image.INTERPOLATE_NEAREST)
	var crop_path := "%s/%s-crop-isolated.jpg" % [OUT_DIR, name]
	if crop.save_jpg(crop_path, 0.95) != OK:
		_failures.append("%s: crop save_jpg failed" % name)
		return
	print("  %-24s -> %s" % [name + "-crop", crop_path])


func _all(node: Node) -> Array[Node]:
	var out: Array[Node] = [node]
	for child in node.get_children():
		out.append_array(_all(child))
	return out
