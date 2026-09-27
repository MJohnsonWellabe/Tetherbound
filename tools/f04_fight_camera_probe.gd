extends "res://tools/art_pipeline/capture_named_fight.gd"

## F04 diagnosis: why the fight camera sits inside the player's creature in
## forest arenas. Starts the named fight through capture_named_fight.gd's
## production path, then every PROBE_STEP_S prints the rig's arm state and
## what the arm's own mask hits between the pivot and the configured
## distance. Headless is fine: physics and the SpringArm3D run without a
## display.
##
##   godot --headless --path . --script tools/f04_fight_camera_probe.gd \
##     -- --trainer=captain_riverwatch [--seconds=8]

const PROBE_STEP_S := 0.25
var _probe_seconds := 8.0


func _run() -> void:
	var ids: PackedStringArray = ["captain_riverwatch"]
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--trainer="):
			ids = arg.trim_prefix("--trainer=").split(",", false)
		elif arg.begins_with("--seconds="):
			_probe_seconds = float(arg.trim_prefix("--seconds="))
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	current_scene = _world
	for i in SETTLE_FRAMES:
		await physics_frame
	await _ensure_ally()
	for id in ids:
		_tid = id
		_spec = TRAINERS.trainer(_tid)
		if not _collect_nodes():
			continue
		_stand_in_front_of_the_trainer()
		if not await _settle_on_ground():
			continue
		for i in 30:
			await physics_frame
		await _challenge()
		if not bool(_manager.call("is_fighting")):
			print("probe %s: no fight" % _tid)
			continue
		var steps := int(_probe_seconds / PROBE_STEP_S)
		for n in steps:
			_probe_line(n)
			for f in int(PROBE_STEP_S * Engine.physics_ticks_per_second):
				await physics_frame
		if bool(_manager.call("is_fighting")):
			_manager.call("_begin_resolve", "lost")
		for i in 240:
			if bool(_panel.call("is_open")):
				await _press("interact")
			await physics_frame
	quit(0)


func _probe_line(n: int) -> void:
	var ally := _director.call("ally_body") as Node3D
	var foe := _director.get("_trainer_body") as Node3D
	var distance := float(_rig.get("_distance"))
	var body_limit := float(_rig.get("_body_limit"))
	var cam := _camera.global_position
	var ally_d := cam.distance_to(ally.global_position) if ally != null else -1.0
	var foe_d := cam.distance_to(foe.global_position) if foe != null and is_instance_valid(foe) else -1.0
	var hit := _arm_hit(distance)
	print("probe %s t=%.2f spring=%.2f want=%.2f body_limit=%s hit_len=%.2f height=%.2f cam_to_ally=%.2f cam_to_foe=%.2f target=%s arm_hit=%s" % [
		_tid, n * PROBE_STEP_S, _rig.spring_length, distance,
		"INF" if is_inf(body_limit) else "%.2f" % body_limit, _rig.get_hit_length(),
		float(_rig.get("_height")), ally_d, foe_d, _node_label(_rig.get("_target")), hit])


## What the arm's own mask meets from the pivot out to `length` along the
## arm (SpringArm3D casts along its +Z).
func _arm_hit(length: float) -> String:
	var space := _rig.get_world_3d().direct_space_state
	var from := _rig.global_position
	var to := from + _rig.global_transform.basis.z.normalized() * length
	var q := PhysicsRayQueryParameters3D.create(from, to, _rig.collision_mask)
	var ex: Array[RID] = []
	var target := _rig.get("_target") as CollisionObject3D
	if target != null:
		ex.append(target.get_rid())
	ex.append(_player.get_rid())
	q.exclude = ex
	var h := space.intersect_ray(q)
	if h.is_empty():
		return "none"
	var c := h.collider as CollisionObject3D
	var layer := c.collision_layer if c != null else 0
	return "%s@%.2fm layer=%d" % [str(_world.get_path_to(h.collider)) if h.collider is Node else "?",
		from.distance_to(h.position), layer]
