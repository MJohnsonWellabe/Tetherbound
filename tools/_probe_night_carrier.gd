extends SceneTree

## WHICH property carries the red at night?
##
##   xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/_probe_night_carrier.gd
##
## What is already ruled out, and how:
##
## * The colour grade. An A/B at pinned hour 22 changing only
##   `Environment.adjustment_enabled` gave grade-on R/B 0.44 and grade-off 2.82
##   -- the opposite direction from the hypothesis.
## * The `adjustment_enabled` boolean snap at hour 21.0. Declaring the flag so it
##   never toggles left a twelve-hour sweep unchanged (R/B 3.42 -> 3.43).
## * A live clock outrunning the renderer. Pinned AND FROZEN 2.90 against live
##   2.91 at the same hour.
## * The config, the blend and the weather. Resolving art.json's own merge and
##   lerp offline at hours 20.5 / 22.0 / 23.5 gives nothing warm anywhere: sky
##   top #223e6d, horizon #767485, ground bottom #1c1b1a, ambient #4c5c8b, sun
##   #cfccd2 at hour 22. Every weather preset is grey-blue too. No lerp between
##   those can produce a frame at R/B 2.9.
##
## So the red is introduced BELOW the config, by what `_apply_environment` and
## `_apply_sky` write into the live nodes or by how the renderer resolves it.
## This probe bisects that, in one boot, at one pinned and frozen hour, by
## neutralising ONE property at a time and restoring it before the next -- the
## same controlled shape as the grade A/B, which is the one probe in this
## sequence that gave a clean signal.
##
## It asserts nothing and fixes nothing. Whichever line moves R/B back toward
## the 0.54 a correct night reads at is the carrier, and the next session starts
## there instead of at another guess.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots/night_carrier"
const SETTLE_FRAMES := 240
const SHOT_SETTLE := 12
const HOUR := 22.0

const EYE := Vector2(-250.0, 2266.0)
const EYE_H := 1.8
const TARGET := Vector2(-258.0, 2258.0)
const TARGET_H := 0.9

var _env: Environment = null
var _sky_material: ProceduralSkyMaterial = null


func _init() -> void:
	_run()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await physics_frame

	var rig: Node = world.get_node_or_null(^"CameraRig")
	if rig != null:
		rig.set_process(false)
		rig.set_physics_process(false)
	var hud: CanvasLayer = world.get_node_or_null(^"PlaygroundHUD") as CanvasLayer
	if hud != null:
		hud.visible = false
	var look: Node = world.get_node_or_null(^"WorldLook")
	if look == null:
		print("no WorldLook")
		quit(1)
		return
	var player: Node3D = world.get_node_or_null(^"Player") as Node3D
	if player != null:
		player.global_position = Vector3(EYE.x + 5000.0, -500.0, EYE.y + 5000.0)

	var camera := Camera3D.new()
	camera.fov = 70.0
	camera.far = 2000.0
	world.add_child(camera)
	camera.make_current()
	var terrain: Node = world.get_node_or_null(^"Terrain")
	if terrain != null and terrain.has_method("set_camera"):
		terrain.call("set_camera", camera)

	var field: RefCounted = HEIGHTFIELD.new()
	camera.global_position = Vector3(EYE.x, field.height_at(EYE.x, EYE.y) + EYE_H, EYE.y)
	camera.look_at(Vector3(TARGET.x, field.height_at(TARGET.x, TARGET.y) + TARGET_H, TARGET.y), Vector3.UP)

	var cycle: RefCounted = look.get("_cycle")
	if cycle != null:
		look.set("_elapsed_seconds", float(cycle.call("elapsed_for_hour", HOUR)))
	look.call("_apply_blended", HOUR)
	look.set_process(false)
	look.set_physics_process(false)

	_env = _environment(world, camera)
	if _env == null:
		print("no Environment")
		quit(1)
		return
	if _env.sky != null:
		_sky_material = _env.sky.sky_material as ProceduralSkyMaterial

	print("live values at pinned hour %.1f:" % HOUR)
	print("   ambient colour=%s energy=%.3f sky_contribution=%.3f source=%d" % [
		_env.ambient_light_color.to_html(false), _env.ambient_light_energy,
		_env.ambient_light_sky_contribution, _env.ambient_light_source])
	print("   tonemap mode=%d exposure=%.3f white=%.3f" % [
		_env.tonemap_mode, _env.tonemap_exposure, _env.tonemap_white])
	print("   fog enabled=%s colour=%s density=%.5f" % [
		str(_env.fog_enabled), _env.fog_light_color.to_html(false), _env.fog_density])
	if _sky_material != null:
		print("   sky top=%s horizon=%s ground_horizon=%s ground_bottom=%s energy=%.3f" % [
			_sky_material.sky_top_color.to_html(false), _sky_material.sky_horizon_color.to_html(false),
			_sky_material.ground_horizon_color.to_html(false), _sky_material.ground_bottom_color.to_html(false),
			_sky_material.energy_multiplier])

	await _shoot("baseline")

	var ambient := _env.ambient_light_energy
	_env.ambient_light_energy = 0.0
	await _shoot("ambient-energy-0")
	_env.ambient_light_energy = ambient

	var exposure := _env.tonemap_exposure
	_env.tonemap_exposure = 0.6
	await _shoot("exposure-0.6")
	_env.tonemap_exposure = exposure

	var mode := _env.tonemap_mode
	_env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	await _shoot("tonemap-linear")
	_env.tonemap_mode = mode

	var fog := _env.fog_enabled
	_env.fog_enabled = false
	await _shoot("fog-off")
	_env.fog_enabled = fog

	if _sky_material != null:
		var sky_energy := _sky_material.energy_multiplier
		_sky_material.energy_multiplier = 1.0
		await _shoot("sky-energy-1")
		_sky_material.energy_multiplier = sky_energy

	var contribution := _env.ambient_light_sky_contribution
	_env.ambient_light_sky_contribution = 0.0
	await _shoot("sky-contribution-0")
	_env.ambient_light_sky_contribution = contribution

	print("\na correct night at this viewpoint reads about R/B 0.54; the red baseline is about 2.90")
	print("done -> %s" % OUT_DIR)
	quit(0)


func _shoot(label: String) -> void:
	for i in SHOT_SETTLE:
		await process_frame
	var image := root.get_texture().get_image()
	image.save_png("%s/%s.png" % [OUT_DIR, label])
	var r := 0.0
	var g := 0.0
	var b := 0.0
	var step := 7
	var n := 0
	for y in range(0, image.get_height(), step):
		for x in range(0, image.get_width(), step):
			var c := image.get_pixel(x, y)
			r += c.r
			g += c.g
			b += c.b
			n += 1
	var count := maxf(float(n), 1.0)
	print("%-20s R %6.1f  G %6.1f  B %6.1f   R/B %.2f" % [
		label, r / count * 255.0, g / count * 255.0, b / count * 255.0,
		(r / count) / maxf(b / count, 0.0001)])


func _environment(world: Node, camera: Camera3D) -> Environment:
	if camera.environment != null:
		return camera.environment
	var stack: Array[Node] = [world]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is WorldEnvironment:
			return (node as WorldEnvironment).environment
		stack.append_array(node.get_children())
	return null
