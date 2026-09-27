extends "res://tools/art_pipeline/capture_named_fight.gd"

var _relay_receipt: FileAccess
var _relay_enemy: Node3D
var _relay_serial := 0
var _relay_lunges := 0
var _relay_tells := 0
var _measured_origin := Vector3.ZERO
var _measured_heading := Vector3.ZERO

func _ensure_ally() -> void:
	await super._ensure_ally()
	var director := _world.get_node("EncounterDirector")
	var ally: RefCounted = director.call("ally_instance")
	ally.call("set_level", 12, COMBAT_MATH.config())
	ally.call("heal_fully")

func _capture_one() -> bool:
	root.size = Vector2i(1920, 1080)
	if not _collect_nodes():
		return false
	_stand_in_front_of_the_trainer()
	if not await _settle_on_ground():
		return false
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out))
	_relay_receipt = FileAccess.open(_out.path_join("manifest.jsonl"), FileAccess.WRITE)
	await _challenge()
	if not bool(_manager.call("is_fighting")):
		return false
	var previous: Node3D = null
	for sendout in 3:
		for frame in 900:
			await physics_frame
			var current := _manager.call("enemy_body") as Node3D
			if bool(_manager.call("is_fighting")) and is_instance_valid(current) and current != previous:
				_relay_enemy = current
				break
		if not is_instance_valid(_relay_enemy) or _relay_enemy == previous:
			push_error("Relay send-out unavailable")
			return false
		var enemy_instance: RefCounted = _relay_enemy.get("instance")
		print("RELAY_SENDOUT ", sendout, " species=", enemy_instance.get("species_id"))
		if str(enemy_instance.get("species_id")) == "tuskroot":
			break
		previous = _relay_enemy
		_manager.call("_begin_resolve", "won")
		for frame in 90:
			await physics_frame
	if str((_relay_enemy.get("instance") as RefCounted).get("species_id")) != "tuskroot":
		push_error("Required Tuskroot send-out not reached")
		return false
	_ally = _director.call("ally_body") as Node3D
	(_director.call("ally_instance") as RefCounted).call("heal_fully")
	_relay_enemy.connect("telegraph_started", _relay_tell)
	_relay_enemy.connect("lunge_started", _relay_lunge)
	_relay_enemy.connect("strike_ready", _relay_strike)
	print("RELAY_FIXTURE level12 starter; first two opponents resolved via manager; no enemy position/timing overrides; production camera and HUD")
	# First tell is observed stationary; later tells receive normal lateral input.
	for tick in 960:
		await physics_frame
		if not is_instance_valid(_relay_enemy) or not bool(_manager.call("is_fighting")):
			break
		if _relay_tells >= 2 and bool(_relay_enemy.call("is_winding_up")):
			Input.action_press("move_right")
		else:
			Input.action_release("move_right")
		if tick % 3 == 0:
			await _relay_frame(tick)
		if _relay_lunges >= 3 and not bool(_relay_enemy.get("_lunge_active")) and tick > 180:
			break
	Input.action_release("move_right")
	print("RELAY_RESULT tells=", _relay_tells, " lunges=", _relay_lunges, " frames=", _relay_serial)
	_relay_receipt.close()
	return _relay_lunges > 0

func _relay_tell(seconds: float) -> void:
	_relay_tells += 1
	print("RELAY_TELL ", _relay_tells, " seconds=", seconds, " enemy=", _relay_enemy.global_position)

func _relay_lunge(heading: Vector3, distance: float) -> void:
	_measured_origin = _relay_enemy.global_position
	_measured_heading = heading
	print("RELAY_CONTACT reach=", _relay_enemy.call("_lunge_contact_reach"), " ally_radius=", _ally.call("body_radius"), " enemy_radius=", _relay_enemy.call("body_radius"), " centre_gap=", Vector2(_ally.global_position.x - _relay_enemy.global_position.x, _ally.global_position.z - _relay_enemy.global_position.z).length())
	_relay_lunges += 1
	print("RELAY_LUNGE ", _relay_lunges, " heading=", heading, " distance=", distance, " enemy=", _relay_enemy.global_position)

func _relay_frame(tick: int) -> void:
	await RenderingServer.frame_post_draw
	_relay_serial += 1
	var file := "%04d.png" % _relay_serial
	var picture := root.get_texture().get_image()
	assert(picture.get_size() == Vector2i(1920, 1080))
	assert(picture.save_png(_out.path_join(file)) == OK)
	var lane: Node3D = _relay_enemy.get("_lunge_lane")
	var record := {"file":file, "tick":tick, "enemy":_relay_vec(_relay_enemy.global_position), "ally":_relay_vec(_ally.global_position), "camera":_relay_vec(_camera.global_position), "winding":_relay_enemy.call("is_winding_up"), "lunge":_relay_enemy.get("_lunge_active"), "lane":is_instance_valid(lane), "heading_locked":_relay_enemy.get("_lunge_heading_locked"), "tells":_relay_tells, "lunges":_relay_lunges, "fixture":"level12 starter; staged trainer stand; first two sendouts resolved; later sidestep input; no attack input"}
	_relay_receipt.store_line(JSON.stringify(record))
	_relay_receipt.flush()

func _relay_vec(v: Vector3) -> Array:
	return [v.x,v.y,v.z]

func _relay_strike() -> void:
	var moved := _relay_enemy.global_position - _measured_origin
	print("RELAY_MEASURE travelled=", Vector2(moved.x, moved.z).dot(Vector2(_measured_heading.x, _measured_heading.z)), " end=", _relay_enemy.global_position)
