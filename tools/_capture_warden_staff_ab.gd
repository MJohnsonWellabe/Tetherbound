extends SceneTree

## WARDEN-STAFF-0909: matched component-appearance A/B on the mature bare
## character stage from `_capture_npc_cast_test.gd`. No Meadows scene, terrain,
## gameplay camera or other cast member is loaded.
##
## Baseline is the actual `NPC_RANKS.config_for("warden")` result with ONLY
## accessories named `tether_staff_*` removed from a deep copy. After is the
## unchanged production rank config. Both variants use the baseline body's
## measured seating, fixed animation seeks, camera and light values.

const CHARACTER_MODEL := preload("res://scripts/characters/character_model.gd")
const NPC_RANKS := preload("res://scripts/characters/npc_ranks.gd")
const RENDER_BOUNDS := preload("res://scripts/characters/render_bounds.gd")

const WIDTH := 1280
const HEIGHT := 800
const IDLE_TIME := 0.72
const WALK_TIME := 0.28
const CAMERA_POSITION := Vector3(0.0, 1.1, 2.6)
const CAMERA_TARGET := Vector3(0.0, 0.9, 0.0)

var _out_dir := "res://.artifacts/warden-staff-capture-0909"
var _world: Node3D
var _camera: Camera3D
var _seat_y := 0.0
var _written := 0


func _init() -> void:
	_run.call_deferred()


func _fail(message: String) -> void:
	push_error("WARDEN STAFF A/B: %s" % message)
	quit(1)


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		_fail("requires a real Compatibility render context")
		return
	root.size = Vector2i(WIDTH, HEIGHT)
	DisplayServer.window_set_size(Vector2i(WIDTH, HEIGHT))
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--out="):
			_out_dir = argument.trim_prefix("--out=")
			if not _out_dir.begins_with("res://"):
				_out_dir = "res://" + _out_dir
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out_dir + "/baseline"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out_dir + "/after"))

	var after_cfg := NPC_RANKS.config_for("warden")
	if after_cfg.is_empty():
		_fail("production NPC_RANKS Warden config is empty")
		return
	var baseline_cfg := after_cfg.duplicate(true)
	var after_accessories: Array = after_cfg.get("accessories", [])
	var baseline_accessories: Array = []
	var removed := 0
	for entry: Variant in after_accessories:
		if entry is Dictionary and str((entry as Dictionary).get("name", "")).begins_with("tether_staff_"):
			removed += 1
			continue
		baseline_accessories.append((entry as Dictionary).duplicate(true) if entry is Dictionary else entry)
	baseline_cfg["accessories"] = baseline_accessories
	if removed != 5:
		_fail("baseline filter removed %d staff descriptors, expected exactly 5" % removed)
		return

	# Prove the subtraction did not rewrite another production field. Restoring
	# the five original descriptors must reconstruct the after config exactly;
	# non-staff accessories (the rank badge stack) must already compare equal.
	var reconstructed := baseline_cfg.duplicate(true)
	var reconstructed_accessories: Array = []
	for entry: Variant in after_accessories:
		if entry is Dictionary and str((entry as Dictionary).get("name", "")).begins_with("tether_staff_"):
			reconstructed_accessories.append((entry as Dictionary).duplicate(true))
	for entry: Variant in baseline_accessories:
		reconstructed_accessories.append((entry as Dictionary).duplicate(true) if entry is Dictionary else entry)
	# Production order is identity pieces then appended badges. Rebuild that
	# order explicitly rather than comparing an unordered set.
	reconstructed["accessories"] = reconstructed_accessories
	if reconstructed != after_cfg:
		_fail("baseline differs from production by more than the five staff descriptors")
		return
	var expected_badges: Array = []
	for entry: Variant in after_accessories:
		if not entry is Dictionary or not str((entry as Dictionary).get("name", "")).begins_with("tether_staff_"):
			expected_badges.append(entry)
	if baseline_accessories != expected_badges:
		_fail("baseline did not preserve the production rank badge descriptors byte-for-byte")
		return
	print("WARDEN STAFF A/B config: removed=%d preserved_badges=%d all_other_fields_equal=true" % [
		removed, baseline_accessories.size()])

	_world = Node3D.new()
	root.add_child(_world)
	_build_environment()
	for _frame in 15:
		await process_frame
	_camera = Camera3D.new()
	_camera.fov = 45.0
	_camera.far = 200.0
	_world.add_child(_camera)
	_camera.position = CAMERA_POSITION
	_camera.look_at(CAMERA_TARGET, Vector3.UP)
	_camera.make_current()

	var baseline: Node3D = await _build_subject(baseline_cfg)
	if baseline == null:
		return
	var body_box: AABB = RENDER_BOUNDS.measure(baseline)
	_seat_y = -body_box.position.y * baseline.scale.y
	baseline.position.y = _seat_y
	await _capture_variant(baseline, "baseline")
	baseline.queue_free()
	for _frame in 5:
		await process_frame

	var after: Node3D = await _build_subject(after_cfg)
	if after == null:
		return
	# Same body-derived seating as baseline. Measuring after would let the staff
	# change its own framing and invalidate the comparison.
	after.position.y = _seat_y
	await _capture_variant(after, "after")
	after.queue_free()
	await process_frame
	print("WARDEN STAFF A/B: wrote %d matched frames to %s" % [_written, _out_dir])
	quit(0 if _written == 6 else 1)


func _build_subject(cfg: Dictionary) -> Node3D:
	var holder := Node3D.new()
	holder.set_script(CHARACTER_MODEL)
	_world.add_child(holder)
	if not bool(holder.call("build_from_config", cfg)):
		holder.queue_free()
		_fail("actual ranked Warden failed to build")
		return null
	for _frame in 15:
		await process_frame
	return holder


func _capture_variant(holder: Node3D, folder: String) -> void:
	var anim: AnimationPlayer = holder.call("animation_player")
	if anim == null or not anim.has_animation("idle") or not anim.has_animation("walk"):
		_fail("actual Warden lacks idle or walk animation")
		return
	await _pose_and_shoot(holder, anim, "idle", IDLE_TIME, 0.0, folder, "front-idle")
	await _pose_and_shoot(holder, anim, "idle", IDLE_TIME, 35.0, folder, "three-quarter-idle")
	await _pose_and_shoot(holder, anim, "walk", WALK_TIME, 0.0, folder, "front-walk")


func _pose_and_shoot(holder: Node3D, anim: AnimationPlayer, clip: String,
		time: float, yaw_degrees: float, folder: String, stem: String) -> void:
	holder.rotation.y = deg_to_rad(yaw_degrees)
	anim.play(clip)
	anim.seek(time, true)
	anim.pause()
	for _frame in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null or image.is_empty() or image.get_width() != WIDTH or image.get_height() != HEIGHT:
		_fail("%s/%s returned an invalid viewport image" % [folder, stem])
		return
	var path := "%s/%s/%s.png" % [_out_dir, folder, stem]
	if image.save_png(ProjectSettings.globalize_path(path)) != OK:
		_fail("could not write %s" % path)
		return
	_written += 1
	print("wrote %s clip=%s time=%.2f yaw=%.1f seat_y=%.4f" % [
		path, clip, time, yaw_degrees, _seat_y])


func _build_environment() -> void:
	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.28, 0.30, 0.33)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.85, 0.87, 0.90)
	env.ambient_light_energy = 0.28
	env_node.environment = env
	_world.add_child(env_node)

	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(400.0, 400.0)
	floor_mesh.mesh = plane
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.34, 0.35, 0.37)
	floor_mesh.material_override = floor_mat
	_world.add_child(floor_mesh)

	var key := DirectionalLight3D.new()
	key.rotation = Vector3(deg_to_rad(-52.0), deg_to_rad(-18.0), 0.0)
	key.light_energy = 0.9
	key.shadow_enabled = true
	_world.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation = Vector3(deg_to_rad(-20.0), deg_to_rad(170.0), 0.0)
	fill.light_energy = 0.5
	fill.light_color = Color(0.80, 0.85, 0.95)
	_world.add_child(fill)
