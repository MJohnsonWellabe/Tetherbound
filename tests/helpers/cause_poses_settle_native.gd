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
	cfg["enabled"] = true
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
	# Recipe rigs key the pivot already; own-clip rigs (remakes) do not.
	recipe = bool(off.get_meta("f36_pose_candidate_installed", false))
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
	var rig = SETTLE.Rig.new(model, skeleton, player.get_node(player.root_node), 1500)
	rig.measure_standing(player.get_animation(StringName(str(clips.get("idle", "")))))
	var right: Vector3 = rig.forward.cross(Vector3.UP)
	_check(absf(rig.leg_angle(Vector3.DOWN)) < 0.001, "%s: legs straight down read 0 deg" % species)
	_check(absf(rad_to_deg(rig.leg_angle(-right)) - 90.0) < 0.5, "%s: legs to the body's left read +90 (a +roll swings them there)" % species)
	var animation := player.get_animation(StringName(faint))
	var end := animation.length
	var points: PackedVector3Array = rig.posed(animation, end, rig.pivot_rotation(animation, end), rig.pivot_position(animation, end))
	var legs: Variant = rig.limb_direction(animation, end, rig.pivot_rotation(animation, end), rig.pivot_position(animation, end))
	var from_down := rad_to_deg((legs as Vector3).angle_to(Vector3.DOWN)) if legs is Vector3 else 0.0
	_check(from_down > 45.0 and from_down < 120.0, "%s ON: faint ends side-lying, legs out to the side (%.0f deg from down)" % [species, from_down])
	_check(_rests(rig, points), "%s ON: faint end rests on the ground (trunk on the line, limbs sink at most 20%%)" % species)
	var mid_t := end * 0.5
	var mid: PackedVector3Array = rig.posed(animation, mid_t, rig.pivot_rotation(animation, mid_t), rig.pivot_position(animation, mid_t))
	_check(SETTLE.Rig.min_y(mid) < rig.ground_y + 0.03 * rig.standing_height, "%s ON: faint mid does not float" % species)
	var offset: Vector2 = SETTLE.Rig.centre_xz(points) - rig.standing_centre
	_check(offset.length() < 0.05 * rig.standing_height, "%s ON: fainted body stays over its shadow" % species)
	if not recipe:
		var rest := str(clips.get("rest_faint", ""))
		_check(rest != faint and player.has_animation(StringName(rest)) and _pivot_tracks(on, rest) == 0,
			"%s ON: bed rests keep the unsettled installed faint (%s)" % [species, rest])
	var hit_name := _clip(on, "hit")
	var hit := player.get_animation(StringName(hit_name))
	_check(_pivot_tracks(on, hit_name) == 2, "%s ON: hit keys the model pivot" % species)
	var first: PackedVector3Array = rig.posed(hit, 0.0, rig.pivot_rotation(hit, 0.0), rig.pivot_position(hit, 0.0))
	var peak_t := hit.length * 0.45
	var peak: PackedVector3Array = rig.posed(hit, peak_t, rig.pivot_rotation(hit, peak_t), rig.pivot_position(hit, peak_t))
	_check(SETTLE.Rig.mean_shift(first, peak) >= 0.03 * rig.standing_height, "%s ON: hit visibly leaves the first frame" % species)
	_check(absf(SETTLE.Rig.min_y(peak) - rig.ground_y) < 0.03 * rig.standing_height, "%s ON: hit stays planted" % species)
	# A second body takes the cached bake as its own copy.
	var again := _spawn(species)
	var again_player := _player(again)
	var again_faint := again_player.get_animation(StringName(_clip(again, "faint")))
	_check(bool(again.get_meta(SETTLE.META, false)) and _pivot_tracks(again, faint) == 2, "%s ON: cached bake installs on a second body" % species)
	_check(again_faint != animation, "%s ON: each body owns its faint copy" % species)
	# play_faint's camera turn: a camera off the body's right turns the collapse.
	var turn := SETTLE.face_camera(again.get("_model"), again_player, _clip(again, "faint"), again.global_position + Vector3(0.0, 2.0, 8.0))
	_check(absf(turn) > 1.0, "%s ON: face_camera turns a collapse toward a camera ahead (%.0f deg)" % [species, turn])
	_check(animation.track_get_key_value(rig.pivot_track(animation, Animation.TYPE_ROTATION_3D), animation.track_get_key_count(rig.pivot_track(animation, Animation.TYPE_ROTATION_3D)) - 1) \
		== animation.get_meta("settle_faint").rotations[-1], "%s ON: turning one body's faint leaves another's untouched" % species)
	again.free()
	on.free()


func _rests(rig, points: PackedVector3Array) -> bool:
	var h: float = rig.standing_height
	var line: float = rig.ground_y - h * 0.015
	var low := SETTLE.Rig.min_y(points)
	var trunk: float = rig.trunk_min_y(points)
	var trunk_on := is_finite(trunk) and absf(trunk - line) < 0.03 * h
	var limbs_capped := absf(low - (rig.ground_y - 0.2 * h)) < 0.03 * h
	return low >= rig.ground_y - 0.21 * h and (trunk_on or limbs_capped or (not is_finite(trunk) and absf(low - line) < 0.03 * h))


func _width(points: PackedVector3Array) -> float:
	var lo := INF
	var hi := -INF
	for p in points:
		lo = minf(lo, p.x)
		hi = maxf(hi, p.x)
	return hi - lo


func _upright_case() -> void:
	SETTLE.set_config_for_test(_all_on())
	var body := _spawn("mosshell")
	var player := _player(body)
	var clips: Dictionary = body.get("_animator").get("_clips")
	var faint := player.get_animation(StringName(str(clips.get("faint", ""))))
	var model: Node3D = body.get("_model")
	var skeleton := model.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	var rig = SETTLE.Rig.new(model, skeleton, player.get_node(player.root_node), 1500)
	rig.measure_standing(player.get_animation(StringName(str(clips.get("idle", "")))))
	var end := faint.length
	var meta: Dictionary = faint.get_meta("settle_faint", {})
	_check(absf(float(meta.get("roll_deg", 999.0))) < 0.001, "mosshell ON (upright species): never spun through a full turn (roll %s)" % str(meta.get("roll_deg")))
	var settled := rig.posed(faint, end, rig.pivot_rotation(faint, end), rig.pivot_position(faint, end))
	_check(_rests(rig, settled), "mosshell ON: faint end grounded")
	var original := player.get_animation(StringName(str(clips.get("rest_faint", ""))))
	var installed := rig.posed(original, end, rig.pivot_rotation(original, end), rig.pivot_position(original, end))
	_check(_width(settled) > _width(installed) * 1.03, "mosshell ON: limbs splay wider than the installed faint (%.2f vs %.2f m)" % [_width(settled), _width(installed)])
	body.free()


func _run() -> void:
	_case("frostclaw", true)
	_case("veridian", false)
	_upright_case()
	SETTLE.set_config_for_test(null)
	await process_frame
	print("CAUSE_POSES_RESULT=" + JSON.stringify({"assertions": assertions, "failures": failures}))
	quit(0 if failures.is_empty() else 1)
