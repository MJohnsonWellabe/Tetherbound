extends "res://tools/catalogue_survey.gd"

## Attribution-only supplement. Canonical catalogue frames remain untouched.
## A debug destination is a visual fixture, never earned progression evidence.
var _supplements: Array[Dictionary] = []
var _canonical_pitch := NAN

func _run() -> void:
	create_timer(580.0, true, false, true).timeout.connect(func() -> void:
		push_error("Veilfall visual attribution watchdog")
		quit(1))
	await super()

func _capture_row(row: Dictionary) -> void:
	# The ordinary context changes pitch with real input. Each catalogue row
	# must begin with the same original canonical pitch, including after context.
	if is_nan(_canonical_pitch):
		_canonical_pitch = float(_rig.get("pitch"))
	_rig.set("pitch", _canonical_pitch)
	await super(row)
	if not _failures.is_empty():
		return
	var veil: Node3D = _world.get_node_or_null("WaterVeilfall")
	if veil == null:
		_failures.append("Veilfall runtime missing")
		return
	var curtain: MeshInstance3D
	for child: Node in veil.exterior.get_children():
		if child is MeshInstance3D and child.mesh is PlaneMesh:
			curtain = child
			break
	if curtain == null:
		_failures.append("Veilfall curtain plane missing")
		return
	await _attribution_pair(str(row.frame_id) + "__canonical", curtain)
	# Walk 65m back along the final segment of the actual authored hike.
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_world.json"))
	var previous := Vector3.INF
	for route: Dictionary in config.get("land_routes", []):
		if str(route.get("id", "")) == "veilfall_exploration_spine":
			var point: Array = route.polyline[-2]
			previous = Vector3(float(point[0]), float(point[1]), float(point[2]))
	if previous == Vector3.INF:
		_failures.append("Authored Veilfall approach route missing")
		return
	var entrance: Vector3 = veil.get("entrance")
	var away := previous - entrance
	away.y = 0
	var stance := entrance + away.normalized() * 65.0
	stance.y = float(_world.call("ground_height_at", stance.x, stance.z))
	var nav := preload("res://tests/helpers/stick_navigator.gd").new(self, _player, _rig, _walk_stick)
	var arrived := false
	for tick in 3000:
		var distance := Vector2(_player.global_position.x - stance.x, _player.global_position.z - stance.z).length()
		if distance < 2.0:
			arrived = true
			break
		if not nav.can_walk():
			break
		nav.step(stance)
		await physics_frame
	_walk_stick(0, 0)
	print("VEILFALL CONTEXT WALK arrived=", arrived, " requested=", stance, " actual=", _player.global_position)
	# Aim yaw and pitch physically; never move the camera or actors to frame it.
	for tick in 360:
		var direction := curtain.global_position - _camera.global_position
		var desired_yaw := atan2(-direction.x, -direction.z)
		var desired_pitch := atan2(direction.y, Vector2(direction.x, direction.z).length())
		var yaw_error := wrapf(desired_yaw - float(_rig.get("yaw")), -PI, PI)
		var pitch_error := desired_pitch - float(_rig.get("pitch"))
		if absf(yaw_error) < 0.04 and absf(pitch_error) < 0.04:
			break
		_axis(JOY_AXIS_RIGHT_X, clampf(-yaw_error * 2.0, -0.8, 0.8))
		_axis(JOY_AXIS_RIGHT_Y, clampf(-pitch_error * 2.0, -0.8, 0.8))
		await physics_frame
	_axis(JOY_AXIS_RIGHT_X, 0.0)
	_axis(JOY_AXIS_RIGHT_Y, 0.0)
	for tick in 12:
		await physics_frame
	await RenderingServer.frame_post_draw
	await _save_supplement(str(row.frame_id) + "__ordinary_context", false, curtain)
	_manifest["supplemental_attribution_frames"] = _supplements
	_write_manifest()

func _attribution_pair(stem: String, curtain: MeshInstance3D) -> void:
	# Freeze only for the diagnostic matched pair so the visibility difference
	# cannot be explained by creatures moving between the two renders.
	paused = true
	await RenderingServer.frame_post_draw
	await _save_supplement(stem + "__curtain_visible", false, curtain)
	curtain.visible = false
	await RenderingServer.frame_post_draw
	await _save_supplement(stem + "__DIAGNOSTIC_curtain_hidden", true, curtain)
	curtain.visible = true
	paused = false

func _save_supplement(stem: String, hidden: bool, curtain: MeshInstance3D) -> void:
	var image := root.get_texture().get_image()
	var path := "%s/%s.png" % [_output_dir, stem]
	if image == null or image.is_empty() or image.save_png(path) != OK:
		_failures.append("Could not save attribution frame " + stem)
		return
	_supplements.append({"file": path, "diagnostic_only": paused or hidden,
		"curtain_hidden": hidden, "tree_paused_for_matched_pair": paused,
		"player_position": _vec3(_player.global_position),
		"camera_transform": _transform(_camera.global_transform),
		"curtain_path": str(curtain.get_path()),
		"curtain_transform": _transform(curtain.global_transform),
		"nearby_creatures": _nearby_creatures(_player.global_position)})
	print("VEILFALL ATTRIBUTION ", path)

func _walk_stick(x: float, y: float) -> void:
	_axis(JOY_AXIS_LEFT_X, x)
	_axis(JOY_AXIS_LEFT_Y, y)

func _axis(axis: JoyAxis, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = value
	Input.parse_input_event(event)
	Input.flush_buffered_events()
