extends SceneTree

## OWNER-0902-VILLAGE-SCALE-VS-TRAINER: does the trainer really dwarf
## villagers next to him, and if so is it a height/fit bug or something else?
##
## Two renders, both against a flat magenta backdrop over a grey ground so a
## Python pass can silhouette-extract each figure's on-screen pixel height by
## colour difference alone -- no reliance on `_fit()`'s own declared height,
## which is exactly the number this investigation cannot take on faith twice
## in a row (two prior sessions already asserted a cause without a render).
##
##   xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/_capture_trainer_villager_scale.gd
##
## SHOT A "equal-distance": trainer + both villagers standing in a row, same
## Z from camera, same lighting/framing per figure -- isolates whether
## `_fit()` scales every rig to its declared `art.json` height correctly when
## camera distance is held constant. If A's pixel-height ratio does not match
## the declared-height ratio, that is a real `_fit()`/`render_bounds.gd` bug.
##
## SHOT B "gameplay-realistic": the REAL third-person camera geometry from
## `data/config/movement.json` (distance 5.2m, height 1.75m, pitch -12deg,
## fov 70), trainer at the origin, one villager placed where a player
## actually stands to talk to one (a couple of metres in front of the
## trainer, the natural "walk up and face them" approach) -- so the villager
## sits farther from the camera than the trainer does, same as it would in
## the real game. If B's ratio is smaller than A's ratio even though both
## figures' declared heights are unchanged, that is a camera/depth framing
## effect, not a model or fit bug.

const CHARACTER_MODEL := preload("res://scripts/characters/character_model.gd")
const OUT_DIR := "res://shots/_diag/village_scale"

const CAM_HEIGHT_A := 1.55
const LOOK_HEIGHT_A := 1.05
const CAM_DIST_A := 7.5
const FOV_A := 40.0

## Real values from data/config/movement.json's `camera` block.
const CAM_DISTANCE := 5.2
const CAM_HEIGHT := 1.75
const CAM_PITCH_DEG := -12.0
const CAM_FOV := 70.0

const SETTLE_FRAMES := 30
const TURN_SETTLE := 10


func _init() -> void:
	_run()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("headless has no renderer; run this under xvfb-run")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	await _shot_equal_distance()
	await _shot_gameplay_realistic()
	await _shot_gameplay_side_by_side()

	print("")
	print("village-scale capture written to %s" % OUT_DIR)
	quit(0)


func _build_stage() -> Node3D:
	var world := Node3D.new()
	root.add_child(world)

	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	# Saturated magenta: nothing in either rig's albedo/hair/tint palette is
	# anywhere near this hue, which is what lets a plain colour-distance
	# threshold in the Python pass find every figure's silhouette edge
	# cleanly, including hair and skin tones that a neutral grey backdrop
	# would sit too close to.
	env.background_color = Color(1.0, 0.0, 1.0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.85, 0.87, 0.90)
	env.ambient_light_energy = 1.1
	env_node.environment = env
	world.add_child(env_node)

	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(200.0, 200.0)
	floor_mesh.mesh = plane
	var floor_mat := StandardMaterial3D.new()
	# Distinct from both the magenta backdrop and any character albedo, so the
	# ground/backdrop seam is also unambiguous -- the "feet" edge of the
	# silhouette scan needs a real line to stop at, not a guess.
	floor_mat.albedo_color = Color(0.42, 0.42, 0.42)
	floor_mesh.material_override = floor_mat
	world.add_child(floor_mesh)

	var key := DirectionalLight3D.new()
	key.rotation = Vector3(deg_to_rad(-45.0), deg_to_rad(-25.0), 0.0)
	key.light_energy = 1.3
	world.add_child(key)

	var fill := DirectionalLight3D.new()
	fill.rotation = Vector3(deg_to_rad(-20.0), deg_to_rad(155.0), 0.0)
	fill.light_energy = 0.7
	fill.light_color = Color(0.85, 0.88, 0.95)
	world.add_child(fill)

	return world


func _spawn(world: Node3D, key: String, pos: Vector3, facing_deg: float) -> Dictionary:
	var cfg: Dictionary = CHARACTER_MODEL.config_for(key)
	if cfg.is_empty():
		push_error("no art.json config for '%s'" % key)
		return {}
	var holder := Node3D.new()
	holder.set_script(CHARACTER_MODEL)
	holder.position = pos
	world.add_child(holder)
	if not bool(holder.call("build_from_config", cfg)):
		push_error("'%s' failed to build" % key)
		holder.queue_free()
		return {}
	if holder.has_method("play"):
		holder.call("play", "idle")
	holder.rotation.y = deg_to_rad(facing_deg)
	var declared_height: float = float(holder.call("height"))
	return {"holder": holder, "declared_height": declared_height, "key": key}


## Shot A: three figures in a row, identical Z, identical framing. Isolates
## `_fit()` correctness from any camera-distance effect.
func _shot_equal_distance() -> void:
	var world := _build_stage()
	for i in SETTLE_FRAMES:
		await process_frame

	var figures: Array[Dictionary] = []
	figures.append(_spawn(world, "trainer", Vector3(0.0, 0.0, 0.0), 180.0))
	figures.append(_spawn(world, "villager_keeper", Vector3(-2.4, 0.0, 0.0), 180.0))
	figures.append(_spawn(world, "villager_farmer", Vector3(2.4, 0.0, 0.0), 180.0))

	for i in SETTLE_FRAMES:
		await process_frame

	var camera := Camera3D.new()
	world.add_child(camera)
	camera.fov = FOV_A
	camera.global_position = Vector3(0.0, CAM_HEIGHT_A, CAM_DIST_A)
	camera.look_at(Vector3(0.0, LOOK_HEIGHT_A, 0.0), Vector3.UP)
	camera.make_current()

	for i in TURN_SETTLE:
		await process_frame

	print("== SHOT A: equal-distance line-up ==")
	print("camera: pos=%s fov=%.1f" % [camera.global_position, camera.fov])
	for f in figures:
		if f.is_empty():
			continue
		var holder: Node3D = f["holder"]
		var feet: Vector3 = holder.global_position
		var head: Vector3 = feet + Vector3.UP * float(f["declared_height"])
		var feet_px: Vector2 = camera.unproject_position(feet)
		var head_px: Vector2 = camera.unproject_position(head)
		var dist := camera.global_position.distance_to(feet)
		print("  %-16s declared=%.3fm  dist_to_cam=%.3fm  feet_px=%s head_px=%s  expected_px_height=%.1f" % [
			f["key"], f["declared_height"], dist, feet_px, head_px, feet_px.y - head_px.y
		])

	await _shoot("shot_a_equal_distance")
	for f in figures:
		if not f.is_empty():
			(f["holder"] as Node3D).queue_free()
	camera.queue_free()
	world.queue_free()
	await process_frame


## Shot B: real camera geometry from movement.json, villager placed where a
## player actually stands to face and talk to one -- a couple of metres in
## front of the trainer, so farther from the trailing camera than the trainer
## is. This is the framing the owner is actually looking at when they say
## villagers "look small next to our own character".
func _shot_gameplay_realistic() -> void:
	var world := _build_stage()
	for i in SETTLE_FRAMES:
		await process_frame

	# Trainer at the origin, facing -Z (away from the camera, which trails
	# behind at +Z) -- the standard third-person "back of the player" framing.
	var trainer := _spawn(world, "trainer", Vector3(0.0, 0.0, 0.0), 0.0)
	# The villager the player walked up to talk to: 1.8m in front of the
	# trainer (further along -Z, i.e. further from the trailing camera) and
	# 1.4m to the side so the trainer's own body does not occlude it from a
	# camera sitting directly behind him -- facing back toward the
	# trainer/camera the way an NPC being talked to would.
	var villager := _spawn(world, "villager_keeper", Vector3(1.4, 0.0, -1.8), 180.0)

	for i in SETTLE_FRAMES:
		await process_frame

	# Replicate camera_rig.gd's spring-arm geometry directly: pivot at the
	# target's position raised by CAM_HEIGHT, then back off along the pitched
	# direction by CAM_DISTANCE -- the same two-step `_follow()`/spring-arm
	# maths the real rig uses, just computed here instead of instantiated,
	# since the bare stage has no player node or collision layers to hang a
	# real SpringArm3D off.
	var trainer_holder: Node3D = trainer["holder"]
	var pivot: Vector3 = trainer_holder.global_position + Vector3.UP * CAM_HEIGHT
	var pitch := deg_to_rad(CAM_PITCH_DEG)
	# SpringArm3D with rotation (pitch, yaw=0, 0) shoots its ray/backs its
	# child off along its own local +Z in world space, which for yaw=0 is
	# world (0, sin(-pitch), cos(pitch)) once the pitch (a rotation about X)
	# is applied -- i.e. the arm swings the camera up as pitch goes more
	# negative ("look down" tilts the arm's own +Z upward behind the player).
	var back_dir := Vector3(0.0, sin(-pitch), cos(pitch)).normalized()
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.fov = CAM_FOV
	camera.global_position = pivot + back_dir * CAM_DISTANCE
	camera.rotation = Vector3(pitch, 0.0, 0.0)

	for i in TURN_SETTLE:
		await process_frame

	print("")
	print("== SHOT B: gameplay-realistic (real movement.json camera) ==")
	print("camera: pos=%s pitch=%.1fdeg fov=%.1f dist=%.2f height=%.2f" % [
		camera.global_position, CAM_PITCH_DEG, camera.fov, CAM_DISTANCE, CAM_HEIGHT
	])
	for f in [trainer, villager]:
		if f.is_empty():
			continue
		var holder: Node3D = f["holder"]
		var feet: Vector3 = holder.global_position
		var head: Vector3 = feet + Vector3.UP * float(f["declared_height"])
		var feet_px: Vector2 = camera.unproject_position(feet)
		var head_px: Vector2 = camera.unproject_position(head)
		var dist := camera.global_position.distance_to(feet)
		print("  %-16s declared=%.3fm  dist_to_cam=%.3fm  feet_px=%s head_px=%s  expected_px_height=%.1f" % [
			f["key"], f["declared_height"], dist, feet_px, head_px, feet_px.y - head_px.y
		])

	await _shoot("shot_b_gameplay_realistic")
	for f in [trainer, villager]:
		if not f.is_empty():
			(f["holder"] as Node3D).queue_free()
	camera.queue_free()
	world.queue_free()
	await process_frame


## Shot C: same real camera geometry as Shot B, but the villager stands
## SHOULDER TO SHOULDER with the trainer (same Z, just off to the side)
## instead of a couple of metres further from the camera. Isolates whether
## the real camera itself uniformly shrinks NPCs (it should not -- both
## figures are ~equidistant from the lens here) versus the specific "walked
## up to face them" framing in Shot B being what produces the size gap.
func _shot_gameplay_side_by_side() -> void:
	var world := _build_stage()
	for i in SETTLE_FRAMES:
		await process_frame

	var trainer := _spawn(world, "trainer", Vector3(0.0, 0.0, 0.0), 0.0)
	var villager := _spawn(world, "villager_keeper", Vector3(1.6, 0.0, 0.0), 200.0)

	for i in SETTLE_FRAMES:
		await process_frame

	var trainer_holder: Node3D = trainer["holder"]
	var pivot: Vector3 = trainer_holder.global_position + Vector3.UP * CAM_HEIGHT
	var pitch := deg_to_rad(CAM_PITCH_DEG)
	var back_dir := Vector3(0.0, sin(-pitch), cos(pitch)).normalized()
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.fov = CAM_FOV
	camera.global_position = pivot + back_dir * CAM_DISTANCE
	camera.rotation = Vector3(pitch, 0.0, 0.0)

	for i in TURN_SETTLE:
		await process_frame

	print("")
	print("== SHOT C: gameplay-realistic, side by side (same depth) ==")
	print("camera: pos=%s pitch=%.1fdeg fov=%.1f dist=%.2f height=%.2f" % [
		camera.global_position, CAM_PITCH_DEG, camera.fov, CAM_DISTANCE, CAM_HEIGHT
	])
	for f in [trainer, villager]:
		if f.is_empty():
			continue
		var holder: Node3D = f["holder"]
		var feet: Vector3 = holder.global_position
		var head: Vector3 = feet + Vector3.UP * float(f["declared_height"])
		var feet_px: Vector2 = camera.unproject_position(feet)
		var head_px: Vector2 = camera.unproject_position(head)
		var dist := camera.global_position.distance_to(feet)
		print("  %-16s declared=%.3fm  dist_to_cam=%.3fm  feet_px=%s head_px=%s  expected_px_height=%.1f" % [
			f["key"], f["declared_height"], dist, feet_px, head_px, feet_px.y - head_px.y
		])

	await _shoot("shot_c_gameplay_side_by_side")
	for f in [trainer, villager]:
		if not f.is_empty():
			(f["holder"] as Node3D).queue_free()
	camera.queue_free()
	world.queue_free()
	await process_frame


func _shoot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null:
		print("FAIL %s: viewport returned no image" % name)
		return
	var path := "%s/%s.png" % [OUT_DIR, name]
	if image.save_png(path) != OK:
		print("FAIL %s: save_png" % name)
		return
	print("  wrote %s" % path)
