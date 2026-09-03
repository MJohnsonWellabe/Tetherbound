extends SceneTree

## NIGHT-LEGIBILITY (ROADMAP 2.7) evidence capture.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" \
##     ~/godot-bin/godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/_capture_night_legibility.gd
##   python3 tools/_night_legibility_stats.py shots/night_legibility/*.png
##
## Two stands:
##   01-unlit-camp    a tent + bedroll (no campfire) at night -- "does an
##                     unlit camp go to black".
##   02-creature-pair  the trainer standing beside a real spawned wild
##                     creature at night -- "does the creature read like the
##                     trainer does".
##
## Ground heights come from `playground_heightfield.gd`'s analytic sampler
## (same one tools/capture_night_light.gd uses), not `ground_height_at()` --
## Terrain3D's own collision only exists in a radius around whichever camera
## it was last told about (docs/CURRENT_STATE.md's South Bridge entombment
## finding), so a query far from where the world booted can read garbage
## while the analytic heightfield is always right.
##
## HONEST LIMITS: Compatibility renderer, software rendering (D06/D01).

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots/night_legibility"
const TENT := preload("res://scripts/build/camp_tent.gd")
const BEDROLL := preload("res://scripts/build/player_bed.gd")
const CREATURE_SCENE := preload("res://scenes/creatures/creature.tscn")
const CREATURE_BODY := preload("res://scripts/creatures/creature_body.gd")

## Beside the mudsnout home-band spawn, confirmed this session to render open,
## unobstructed meadow.
const FIXED_SPOT := Vector2(-70.0, 22.0)

const SETTLE_FRAMES := 240
const SETTLE_AFTER_MOVE := 40
const POSE_FRAMES := 4
const FOV := 70.0

## Open meadow near the home-band mudsnout spawn (confirmed, this session, to
## actually render open ground) -- not `capture_night_light.gd`'s own
## "ranger-camp-close" (an authored, already-lit trail camp: wrong stand for
## an UNLIT one) and not smoke_gate_a_rest_torch.gd's build-placement
## coordinate (70,75), which turned out to render a flat, gradient-less
## frame at every camera angle tried -- consistent with the analytic
## heightfield disagreeing with real meshed terrain there (a "clear
## placement" fact never visually verified, only physics-verified) rather
## than anything this script does.
const CAMP_SPOT := Vector2(-75.0, 30.0)

var _field: RefCounted = null


func _init() -> void:
	_run()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	_field = HEIGHTFIELD.new()

	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await physics_frame

	var look: Node = world.get_node_or_null(^"WorldLook")
	var player: Node3D = world.get_node_or_null(^"Player") as Node3D
	var director: Node = world.get_node_or_null(^"EncounterDirector")
	if look == null or player == null or director == null:
		push_error("world missing WorldLook/Player/EncounterDirector")
		quit(1)
		return

	var rig: Node = world.get_node_or_null(^"CameraRig")
	if rig != null:
		rig.set_process(false)
		rig.set_physics_process(false)
	# The player is only a posed prop in these frames, never actually played.
	# Terrain3D's collision follows wherever the CAMERA last stood (docs/
	# CURRENT_STATE.md's South Bridge finding), so a hand-placed player at a
	# spot the camera has not visited yet has no floor under it and free-falls
	# under gravity for every settle frame before the shot -- freezing physics
	# keeps the placed transform exactly where this script put it.
	player.set_physics_process(false)
	var hud: CanvasLayer = world.get_node_or_null(^"PlaygroundHUD") as CanvasLayer
	if hud != null:
		hud.visible = false

	var camera := Camera3D.new()
	camera.fov = FOV
	camera.far = 2000.0
	world.add_child(camera)
	camera.make_current()

	var terrain: Node = world.get_node_or_null(^"Terrain")
	if terrain != null and terrain.has_method("set_camera"):
		terrain.call("set_camera", camera)

	look.call("apply_time", "night")
	for i in SETTLE_AFTER_MOVE:
		await physics_frame

	await _shoot_unlit_camp(world, player, camera)
	for prefix in ["Wild_mudsnout_", "Wild_bramblebun_"]:
		await _shoot_creature_pair(world, player, director, camera, prefix)
	# sparkit's own wild spawn order/id is not fixed run to run (unlike
	# mudsnout/bramblebun's stable "_0_1"/"_1_1" cluster, confirmed identical
	# across five separate runs this session), so a fair before/after needs a
	# creature placed at a coordinate this script controls -- same technique
	# tests/smoke_art.gd already uses to spawn a species directly rather than
	# through the encounter director.
	await _shoot_fixed_creature(world, player, camera, "sparkit", FIXED_SPOT)

	print("")
	print("frames -> %s" % OUT_DIR)
	print("Software rendering (D06/D01). Run tools/_night_legibility_stats.py for numbers.")
	quit(0)


func _pose(camera: Camera3D, eye_xz: Vector2, eye_h: float, target_xz: Vector2, target_h: float, horizon: float) -> void:
	var eye_ground: float = _field.height_at(eye_xz.x, eye_xz.y)
	var target_ground: float = _field.height_at(target_xz.x, target_xz.y)
	var eye := Vector3(eye_xz.x, eye_ground + eye_h, eye_xz.y)
	var target := Vector3(target_xz.x, target_ground + target_h, target_xz.y)
	camera.global_position = eye
	camera.look_at(target, Vector3.UP)
	camera.rotation = Vector3(_pitch_for_horizon(horizon), camera.rotation.y, 0.0)


func _pitch_for_horizon(fraction: float) -> float:
	var half := tan(deg_to_rad(FOV) * 0.5)
	return -atan((0.5 - clampf(fraction, 0.05, 0.95)) * 2.0 * half)


func _shoot_unlit_camp(world: Node, player: Node3D, camera: Camera3D) -> void:
	var ground: float = _field.height_at(CAMP_SPOT.x, CAMP_SPOT.y)
	var tent: Node3D = TENT.new()
	world.add_child(tent)
	tent.global_position = Vector3(CAMP_SPOT.x, ground, CAMP_SPOT.y)
	tent.call("build_real")

	var bedroll: Node3D = BEDROLL.new()
	world.add_child(bedroll)
	bedroll.global_position = Vector3(CAMP_SPOT.x + 2.2, ground, CAMP_SPOT.y + 0.6)
	bedroll.call("build_real")

	player.global_position = Vector3(CAMP_SPOT.x + 5000.0, -500.0, CAMP_SPOT.y + 5000.0)

	_pose(camera, CAMP_SPOT + Vector2(-3.0, -3.0), 1.5, CAMP_SPOT + Vector2(0.5, 0.5), 0.8, 0.35)
	for i in SETTLE_AFTER_MOVE:
		await physics_frame
	for i in POSE_FRAMES:
		await process_frame
	await RenderingServer.frame_post_draw
	print("camp debug: ground=%.2f cam_pos=%s cam_rot=%s tent_children=%d bedroll_children=%d" % [
		ground, str(camera.global_position), str(camera.rotation), tent.get_child_count(), bedroll.get_child_count()])
	await _shoot("01-unlit-camp-night")


func _shoot_creature_pair(world: Node, player: Node3D, director: Node, camera: Camera3D, prefix: String) -> void:
	var wilds: Array = director.call("wild_creatures")
	var target_body: Node3D = null
	for wild: Variant in wilds:
		if wild is Node3D and str((wild as Node3D).name).begins_with(prefix):
			target_body = wild as Node3D
			break
	if target_body == null:
		printerr("no wild creature body found for prefix %s; skipping" % prefix)
		return

	var spot := target_body.global_position
	var spot_xz := Vector2(spot.x, spot.z)
	var stand_xz := spot_xz + Vector2(1.6, 0.0)
	# The creature's own Y (already correct -- encounter_director placed it on
	# real ground) rather than a fresh heightfield query at a nearby-but-
	# distinct x/z: the analytic sampler answered wrong once already this
	# session for a coordinate its own internal chunking had not "seen" near
	# whichever spot the camera visited last, and terrain is locally flat
	# enough over 1.6m that reusing the creature's Y is the safer read.
	player.global_position = Vector3(stand_xz.x, spot.y + 0.2, stand_xz.y)
	player.velocity = Vector3.ZERO
	for i in SETTLE_AFTER_MOVE:
		await physics_frame

	var eye := spot + Vector3(-3.0, 1.6, 3.0)
	var mid := spot.lerp(player.global_position, 0.5) + Vector3(0.0, 0.9, 0.0)
	camera.global_position = eye
	camera.look_at(mid, Vector3.UP)
	for i in SETTLE_AFTER_MOVE:
		await physics_frame
	for i in POSE_FRAMES:
		await process_frame
	await RenderingServer.frame_post_draw
	print("creature-pair stand: %s at %s, trainer at %s" % [
		str(target_body.name), str(spot), str(player.global_position)])
	await _shoot("02-creature-pair-night-%s" % prefix.trim_prefix("Wild_").trim_suffix("_"))


## A species built directly (tests/smoke_art.gd's own pattern) at a fixed
## coordinate this script controls, rather than whatever the encounter
## director's own spawn table happens to roll this run. Needed because the
## director's sparkit cluster's exact individual/order id was NOT stable
## across runs this session (unlike mudsnout/bramblebun's), which would have
## made a before/after comparison compare two different placements, not one
## fix.
func _shoot_fixed_creature(world: Node, player: Node3D, camera: Camera3D, species: String, spot_xz: Vector2) -> void:
	var body: Node3D = CREATURE_SCENE.instantiate() as Node3D
	body.set_script(CREATURE_BODY)
	body.set("species_id", species)
	world.add_child(body)
	await process_frame
	body.set_physics_process(false)

	var ground: float = _field.height_at(spot_xz.x, spot_xz.y)
	var spot := Vector3(spot_xz.x, ground, spot_xz.y)
	body.global_position = spot
	if body.has_method("place_on_ground"):
		body.call("place_on_ground", spot)

	var stand_xz := spot_xz + Vector2(1.6, 0.0)
	player.global_position = Vector3(stand_xz.x, body.global_position.y + 0.2, stand_xz.y)
	player.velocity = Vector3.ZERO
	for i in SETTLE_AFTER_MOVE:
		await physics_frame

	var eye := body.global_position + Vector3(-3.0, 1.6, 3.0)
	var mid := body.global_position.lerp(player.global_position, 0.5) + Vector3(0.0, 0.9, 0.0)
	camera.global_position = eye
	camera.look_at(mid, Vector3.UP)
	for i in SETTLE_AFTER_MOVE:
		await physics_frame
	for i in POSE_FRAMES:
		await process_frame
	await RenderingServer.frame_post_draw
	print("fixed-creature stand: %s at %s, trainer at %s" % [
		species, str(body.global_position), str(player.global_position)])
	await _shoot("03-fixed-creature-night-%s" % species)


func _shoot(name: String) -> void:
	var image := root.get_texture().get_image()
	if image == null:
		print("  %-28s no image" % name)
		return
	var path := "%s/%s.png" % [OUT_DIR, name]
	var error := image.save_png(path)
	print("  %-28s -> %s (%s)" % [name, path, "ok" if error == OK else "FAILED"])
