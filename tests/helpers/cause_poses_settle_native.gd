extends SceneTree

## Child process for tests/test_cause_poses_settle.gd.
const BODY := preload("res://scripts/creatures/creature_body.gd")
const SCENE := preload("res://scenes/creatures/creature.tscn")
const SETTLE := preload("res://scripts/creatures/creature_pose_settle.gd")
var assertions := 0
var failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _check(ok: bool, message: String) -> void:
	assertions += 1
	if not ok:
		failures.append(message)


func _all_on() -> Dictionary:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SETTLE.PATH))
	for role: String in ["faint", "hit"]:
		for part: String in (cfg[role] as Dictionary):
			cfg[role][part]["enabled"] = true
	return cfg


func _spawn(species: String) -> Node3D:
	var body := SCENE.instantiate() as Node3D
	body.set_script(BODY)
	root.add_child(body)
	body.call("setup", species, false)
	body.set_physics_process(false)
	return body


func _player(body: Node3D) -> AnimationPlayer:
	var players := body.find_children("*", "AnimationPlayer", true, false)
	return players[0] as AnimationPlayer if players.size() == 1 else null


func _clip(body: Node3D, role: String) -> String:
	var animator: Object = body.get("_animator")
	return str((animator.get("_clips") as Dictionary).get(role, "")) if animator != null else ""


func _pivot_tracks(body: Node3D, clip: String) -> int:
	var player := _player(body)
	var animation := player.get_animation(StringName(clip))
	var model: Node3D = body.get("_model")
	var root_node := player.get_node_or_null(player.root_node)
	var count := 0
	for track in animation.get_track_count():
		if root_node.get_node_or_null(animation.track_get_path(track)) == model:
			count += 1
	return count


func _case(species: String, recipe: bool) -> void:
	SETTLE.set_config_for_test(JSON.parse_string(FileAccess.get_file_as_string(SETTLE.PATH)))
	var off := _spawn(species)
	var off_player := _player(off)
	_check(off_player != null, "%s has one AnimationPlayer" % species)
	if off_player == null:
		off.free()
		return
	_check(not bool(off.get_meta(SETTLE.META, false)), "%s OFF: settle not installed" % species)
	var faint := _clip(off, "faint")
	var off_faint_tracks := _pivot_tracks(off, faint)
	_check(off_faint_tracks == (2 if recipe else 0), "%s OFF: faint pivot tracks unchanged (%d)" % [species, off_faint_tracks])
	_check(not (off.get("_animator").get("_clips") as Dictionary).has("pivot_clips"), "%s OFF: no pivot_clips" % species)
	var off_keys := off_player.get_animation(StringName(faint)).track_get_key_count(0)
	off.free()

	SETTLE.set_config_for_test(_all_on())
	var on := _spawn(species)
	var player := _player(on)
	_check(bool(on.get_meta(SETTLE.META, false)), "%s ON: settle installed" % species)
	var clips: Dictionary = on.get("_animator").get("_clips")
	_check(faint in (clips.get("pivot_clips", []) as Array), "%s ON: faint listed as a pivot clip" % species)
	_check(_pivot_tracks(on, faint) == 2, "%s ON: faint keys the model pivot" % species)
	_check(player.get_animation(StringName(faint)).track_get_key_count(0) >= off_keys, "%s ON: authored keys kept" % species)
	# Measure the settled faint end with the same sampler.
	var model: Node3D = on.get("_model")
	var skeleton := model.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	var rig = SETTLE.Rig.new(model, skeleton, player.get_node(player.root_node), 2400)
	rig.measure_standing(player.get_animation(StringName(str(clips.get("idle", "")))))
	var animation := player.get_animation(StringName(faint))
	var end := animation.length
	var points: PackedVector3Array = rig.posed(animation, end, rig.pivot_rotation(animation, end), rig.pivot_position(animation, end))
	var height: float = SETTLE.Rig.height(points)
	_check(height < rig.standing_height * 0.7, "%s ON: faint ends collapsed (%.2f of %.2f m)" % [species, height, rig.standing_height])
	var low: float = SETTLE.Rig.min_y(points)
	_check(absf(low - (rig.ground_y - rig.standing_height * 0.015)) < 0.03 * rig.standing_height,
		"%s ON: faint end touches the ground line (%.3f vs %.3f)" % [species, low, rig.ground_y])
	var mid_t := end * 0.5
	var mid: PackedVector3Array = rig.posed(animation, mid_t, rig.pivot_rotation(animation, mid_t), rig.pivot_position(animation, mid_t))
	_check(SETTLE.Rig.min_y(mid) < rig.ground_y + 0.03 * rig.standing_height, "%s ON: faint mid does not float" % species)
	var offset: Vector2 = SETTLE.Rig.centre_xz(points) - rig.standing_centre
	_check(offset.length() < 0.05 * rig.standing_height, "%s ON: fainted body stays over its shadow" % species)
	var hit_name := _clip(on, "hit")
	var hit := player.get_animation(StringName(hit_name))
	_check(_pivot_tracks(on, hit_name) == 2, "%s ON: hit keys the model pivot" % species)
	var first: PackedVector3Array = rig.posed(hit, 0.0, rig.pivot_rotation(hit, 0.0), rig.pivot_position(hit, 0.0))
	var peak_t := hit.length * 0.45
	var peak: PackedVector3Array = rig.posed(hit, peak_t, rig.pivot_rotation(hit, peak_t), rig.pivot_position(hit, peak_t))
	_check(SETTLE.Rig.mean_shift(first, peak) >= 0.03 * rig.standing_height, "%s ON: hit visibly leaves the first frame" % species)
	_check(absf(SETTLE.Rig.min_y(peak) - rig.ground_y) < 0.03 * rig.standing_height, "%s ON: hit stays planted" % species)
	on.free()


func _run() -> void:
	_case("frostclaw", true)
	_case("veridian", false)
	SETTLE.set_config_for_test(null)
	await process_frame
	print("CAUSE_POSES_RESULT=" + JSON.stringify({"assertions": assertions, "failures": failures}))
	quit(0 if failures.is_empty() else 1)
