extends SceneTree

## BACKLOG-D6-SEAM-PROBE, follow-up to `tools/_audit_d_seam_probe.gd`.
##
## That probe changed Terrain3D's clipmap (`mesh_size`/`mesh_lods`) and the
## dashed seam did not move -- clipmap ruled out
## (`ralph/reports/audit/D6-seam-probe/`, `ralph/reports/audit/D-2026-08-31.md`
## D6). This probe tests the hypothesis the audit named as the next thing to
## check: a texture mipmap/filtering mismatch, specifically the per-tile
## detiling mechanism in `shaders/terrain_ground.gdshader::accumulate_material`
## -- every texture tile gets an independent random UV rotation
## (`_texture_detile_array`), and the fragment's anisotropic derivatives
## (`id_dd`) are rotated to match. At the boundary between two tiles the
## rotation is DISCONTINUOUS, so the two sides of that boundary select
## different mip levels / anisotropic footprints for the *same* screen-space
## pixel -- a textbook "filtering mismatch across a tile boundary", and
## unlike the clipmap it is a per-texture-tile artefact (tile size is
## `1/uv_scale`: 4-5m depending on surface), not a clipmap-mesh one.
##
## Same fixed camera as the predecessor probe (band-1 opening stand, one frame
## per configuration, nothing else differs), so a pixel diff isolates exactly
## what each change moved:
##
##   seam-probe-mip-default.png    shipped: detiling on, mipmap_bias as configured (0.92)
##   seam-probe-mip-nodetile.png   detiling OFF (rotation=0, shift=0) on every texture asset
##   seam-probe-mip-biashigh.png   detiling restored, mipmap_bias forced to 1.5 (hint_range max, heavy blur bias)
##
## If nodetile removes the dashed line, the per-tile derivative-rotation
## discontinuity IS the cause. If biashigh visibly softens/hides it while
## nodetile does not, the line is mip-selection noise rather than the detiling
## rotation specifically. If neither moves it, the mip/filter hypothesis is
## ruled out too and the defect is elsewhere (splat/control-map texel grid,
## most likely, per `_comment_blend_r9_4`'s already-fixed sibling defect).
##
## This tool changes NOTHING on disk. `mipmap_bias` is a shader uniform
## (`set_shader_param`, live-only for this process); detiling is set directly
## on the live `Terrain3DTextureAsset` resources obtained from
## `terrain.assets.get_texture_list()`, then pushed with
## `update_texture_list()`, also live-only -- restored before exit as
## paranoia, same as the predecessor probe.
##
## Invocation (never --headless with a rendering driver; see
## ralph/conventions.md "Art pipeline traps"):
##
##   xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/_audit_d6_mipfilter_probe.gd

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

## Byte-identical to _audit_d_seam_probe.gd's stand -- the artefact's own
## reported location, and the frame all three of that probe's captures share.
const EYE_XZ := Vector2(8.0, 90.0)
const AIM_XZ := Vector2(-40.0, 180.0)

const FORCED_BIAS := 1.5  # mipmap_bias hint_range(0.5, 1.5) max -- heaviest blur this uniform can express.

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

	var assets: Object = _terrain.get("assets")
	if assets == null or not assets.has_method("get_texture_list"):
		print("FAIL terrain.assets exposes no texture list; probe cannot run")
		quit(1)
		return
	var textures: Array = assets.call("get_texture_list")
	if textures.is_empty():
		print("FAIL terrain has zero textures; probe cannot run")
		quit(1)
		return

	# Record shipped state before touching anything, so the probe reports
	# facts rather than assumed defaults.
	var default_bias: Variant = _material.call("get_shader_param", "mipmap_bias")
	var default_rotations: Array[float] = []
	var default_shifts: Array[float] = []
	for tex: Object in textures:
		default_rotations.append(float(tex.get("detiling_rotation")))
		default_shifts.append(float(tex.get("detiling_shift")))
	print("[mipfilter-probe] %d textures; shipped mipmap_bias=%s (unreliable readback on this build -- see terrain_ground.gdshader header)" % [
		textures.size(), str(default_bias)])
	print("[mipfilter-probe] shipped detiling_rotation=%s detiling_shift=%s" % [
		str(default_rotations), str(default_shifts)])

	await _shoot("seam-probe-mip-default")

	for tex: Object in textures:
		tex.set("detiling_rotation", 0.0)
		tex.set("detiling_shift", 0.0)
	assets.call("update_texture_list")
	for i in RECONFIG_FRAMES:
		await physics_frame
	print("[mipfilter-probe] detiling forced to 0.0/0.0 on all %d textures" % textures.size())
	await _shoot("seam-probe-mip-nodetile")

	for i in textures.size():
		var tex: Object = textures[i]
		tex.set("detiling_rotation", default_rotations[i])
		tex.set("detiling_shift", default_shifts[i])
	assets.call("update_texture_list")
	_material.call("set_shader_param", "mipmap_bias", FORCED_BIAS)
	for i in RECONFIG_FRAMES:
		await physics_frame
	print("[mipfilter-probe] detiling restored; mipmap_bias forced to %s" % str(FORCED_BIAS))
	await _shoot("seam-probe-mip-biashigh")

	# Leave the live node as found -- paranoia only, the process exits anyway.
	_material.call("set_shader_param", "mipmap_bias", default_bias)

	if not _failures.is_empty():
		for line in _failures:
			print("FAIL: %s" % line)
		quit(1)
		return
	print("[mipfilter-probe] 3 frames -> %s" % OUT_DIR)
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
