extends "res://tests/test_case.gd"

## COMBAT §5 contact spacing (`scripts/combat/contact_spacing.gd`,
## `creature_body.gd::_hold_contact_spacing`).
##
## Tidewake F14#0/#1, Meadows F04#2/#7 and Stormwood F10#2 failed C3 on one
## defect: at contact range the RENDERED bodies interpenetrate, the ally stands
## in front of the opponent's head, and no camera can separate them. The rule
## holds the pair apart by their directional rendered half-extents plus a
## visible clearance, never beyond the opponent's own spacing floor (which every
## reach exceeds by 0.5 m), so hit/avoidance cannot change.
##
## The pure cases run in the unit runner; the physics cases need a physics
## world and run in an isolated child process (test_combat_arena_hold_inside's
## convention).

const SPACING := preload("res://scripts/combat/contact_spacing.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const MANAGER := preload("res://scripts/combat/combat_manager.gd")
const WILD := preload("res://scripts/creatures/wild_creature.gd")
const MATH := preload("res://scripts/combat/combat_math.gd")
const CREATURE_SCENE := preload("res://scenes/creatures/creature.tscn")
const BODY_SCRIPT := preload("res://scripts/creatures/creature_body.gd")
const EXPECTED_CHILD_ASSERTIONS := 15

var _root: Node3D = null


## --- the rule itself ---------------------------------------------------------

func test_config_block_is_present_and_documented() -> void:
	var cfg := SPACING.config()
	assert_true(bool(cfg.get("enabled", false)), "contact spacing ships enabled")
	assert_true(str(cfg.get("_why", "")).length() > 40, "the block carries its _why")
	assert_almost_eq(float(cfg.get("visible_clearance_m", 0.0)), 0.6, 0.0001,
		"COMBAT §5's 0.6 m visible clearance")
	assert_true(float(cfg.get("max_separation_m", 0.0)) >= 11.0, "the ceiling fits the largest shipped pair")


func test_directional_extent_is_longer_head_on_than_broadside() -> void:
	var head_on := SPACING.directional_extent(0.5, 1.6, Vector2(0.0, 1.0))
	var broadside := SPACING.directional_extent(0.5, 1.6, Vector2(1.0, 0.0))
	var diagonal := SPACING.directional_extent(0.5, 1.6, Vector2(1.0, 1.0))
	assert_almost_eq(head_on, 1.6, 0.0001, "head-on reach is the half-length")
	assert_almost_eq(broadside, 0.5, 0.0001, "broadside reach is the half-width")
	assert_between(diagonal, broadside, head_on, "a diagonal lies between the two")
	assert_almost_eq(SPACING.directional_extent(0.5, 1.6, Vector2.ZERO), 1.6, 0.0001,
		"no direction answers the larger half-extent")


func test_min_separation_is_floored_by_colliders_and_bounded_above() -> void:
	var cfg := SPACING.config()
	assert_almost_eq(SPACING.min_separation(0.1, 0.1, 0.6, 0.6, cfg), 1.2, 0.0001,
		"never less than the two colliders")
	assert_almost_eq(SPACING.min_separation(1.0, 1.2, 0.6, 0.7, cfg), 2.8, 0.0001,
		"half-extents plus the 0.6 m clearance")
	# Tess's Water Mirejaw (5.49 m head-on) against Ripplet (1.94 m): the
	# first cut capped this at the 2.75x collider floor (7.01 m) and the two
	# snouts still touched on judge B's frames.
	assert_almost_eq(SPACING.min_separation(5.49, 1.94, 1.18, 1.37, cfg), 8.03, 0.0001,
		"a long body is not capped back into contact")
	assert_almost_eq(SPACING.min_separation(40.0, 40.0, 0.6, 0.7, cfg), SPACING.max_separation(cfg), 0.0001,
		"a malformed model cannot push past the ceiling")


## The hit/avoidance invariant across the whole roster, smallest body to
## largest: every reach clears the pair's LONGEST separation by 0.5 m, and the
## separation actually enforced (any facing) never exceeds that.
func test_every_species_pair_keeps_reach_beyond_the_separation() -> void:
	var cfg := SPACING.config()
	var enemy: Dictionary = MATH.config().get("enemy", {})
	var rows := []
	for id: String in SPECIES.table().keys():
		var look := SPECIES.placeholder(id)
		var r := float(look.get("radius", 0.4))
		# The longest rendered half-extent the fit allows.
		rows.append([r, r * float(look.get("footprint_allowance", 2.4))])
	rows.sort()
	assert_true(rows.size() >= 10, "the roster is read")
	var picks := [rows[0], rows[rows.size() / 2], rows[rows.size() - 1]]
	var worst_margin := INF
	var checked := 0
	for a: Array in picks:
		for b: Array in picks:
			var reach_need := SPACING.min_separation(a[1], b[1], a[0], b[0], cfg)
			for turn: float in [0.0, 0.5, 1.0]:
				# Any facing: each body's directional extent lies between its
				# collider and its longest half-extent.
				var need := SPACING.min_separation(lerpf(a[0], a[1], turn), lerpf(b[0], b[1], turn), a[0], b[0], cfg)
				var ally_reach := float(MANAGER.floor_reach_for_bodies({"range": 2.6}, a[0], b[0], reach_need).get("range"))
				var foe := WILD.spaced_config_for(enemy, b[0], a[0], need, reach_need)
				assert_true(need >= a[0] + b[0] - 0.0001, "never inside the colliders")
				assert_true(float(foe.get("preferred_range")) >= need - 0.0001,
					"the opponent walks to where the bodies clear (%.2f vs %.2f)" % [float(foe.get("preferred_range")), need])
				worst_margin = minf(worst_margin, minf(ally_reach, float(foe.get("range"))) - need)
				checked += 1
	assert_eq(checked, 27)
	assert_true(worst_margin >= 0.5 - 0.0001,
		"every reach stays at least 0.5 m beyond the separation (worst %.3f m)" % worst_margin)


func test_host_profile_uses_the_same_reach_floor() -> void:
	var local := MANAGER.floor_reach_for_bodies({"range": 2.6}, 1.37, 1.18, 8.03)
	var host := MANAGER.host_move_profile(null, "player_quick", "", 1.37, 1.18, 1.0, 8.03)
	assert_almost_eq(float(host.get("range")), float(local.get("range")), 0.0001,
		"a peer's strike is tested against the reach the solo player has")
	assert_true(float(host.get("range")) >= 8.53 - 0.0001, "reach clears the longest separation by 0.5 m")


func test_the_ally_yields_and_the_opponent_holds_until_pinned() -> void:
	var cfg := SPACING.config()
	var wait := float(cfg.get("foe_yield_after_s", 0.35))
	assert_eq(SPACING.share_for(SPACING.ROLE_ALLY, 0.0, cfg), 1.0, "the ally takes the whole correction")
	assert_eq(SPACING.share_for(SPACING.ROLE_FOE, 0.0, cfg), 0.0, "the opponent holds its ground")
	assert_eq(SPACING.share_for(SPACING.ROLE_FOE, wait * 0.9, cfg), 0.0, "still holds inside the wait")
	assert_true(SPACING.share_for(SPACING.ROLE_FOE, wait, cfg) > 0.0, "a pinned ally makes the opponent yield")
	assert_eq(SPACING.share_for(SPACING.ROLE_NONE, 10.0, cfg), 0.0, "an unbound body never moves")


func test_correction_is_soft_but_always_stops_a_walk_in() -> void:
	var cfg := SPACING.config()
	var speed := float(cfg.get("push_speed_mps", 6.0))
	var dt := 1.0 / 60.0
	var mine := Vector3(2.0, 0.0, 0.0)
	var theirs := Vector3.ZERO
	var step := SPACING.correction(mine, theirs, 4.0, 1.0, 0.0, dt, Vector3.FORWARD, cfg)
	assert_almost_eq(step.length(), speed * dt, 0.0001, "a large overlap is closed at the push speed, not snapped")
	assert_true(step.x > 0.0 and is_zero_approx(step.z) and is_zero_approx(step.y), "straight away from the partner, flat")
	var walking := SPACING.correction(mine, theirs, 4.0, 1.0, speed * 2.0, dt, Vector3.FORWARD, cfg)
	assert_almost_eq(walking.length(), speed * 2.0 * dt, 0.0001, "the step covers the closing speed")
	var small := SPACING.correction(Vector3(3.95, 0.0, 0.0), theirs, 4.0, 1.0, 0.0, dt, Vector3.FORWARD, cfg)
	assert_almost_eq(small.length(), 0.05, 0.0001, "a small deficit closes exactly, without overshoot")
	assert_eq(SPACING.correction(Vector3(4.5, 0.0, 0.0), theirs, 4.0, 1.0, 0.0, dt, Vector3.FORWARD, cfg),
		Vector3.ZERO, "clear bodies are untouched")
	assert_eq(SPACING.correction(mine, theirs, 4.0, 0.0, 0.0, dt, Vector3.FORWARD, cfg),
		Vector3.ZERO, "a zero share never moves")
	var stacked := SPACING.correction(theirs, theirs, 4.0, 1.0, 0.0, dt, Vector3(0.0, 0.0, -1.0), cfg)
	assert_true(stacked.z < 0.0, "coincident centres separate along the fallback direction")


## --- live bodies in a physics world (child process) --------------------------

func _setup_fixture() -> void:
	_root = Node3D.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(_root)
	var floor_body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(80.0, 1.0, 80.0)
	shape.shape = box
	floor_body.add_child(shape)
	_root.add_child(floor_body)
	floor_body.global_position = Vector3(0.0, -0.5, 0.0)


func _free_fixture() -> void:
	if _root != null and is_instance_valid(_root):
		_root.free()
	_root = null


func _species_by_radius() -> Array:
	var rows := []
	for id: String in SPECIES.table().keys():
		if str(SPECIES.placeholder(id).get("model", "")) == "":
			continue
		rows.append([float(SPECIES.placeholder(id).get("radius", 0.4)), id])
	rows.sort()
	return rows


func _body(id: String, at: Vector3) -> CharacterBody3D:
	var body: CharacterBody3D = CREATURE_SCENE.instantiate()
	body.set_script(BODY_SCRIPT)
	body.set("species_id", id)
	_root.add_child(body)
	body.global_position = at
	return body


func _flat_gap(a: Node3D, b: Node3D) -> float:
	return Vector2(a.global_position.x - b.global_position.x, a.global_position.z - b.global_position.z).length()


func _need(a: Node3D, b: Node3D) -> float:
	return SPACING.min_separation(float(a.call("contact_extent_towards", b.global_position)),
		float(b.call("contact_extent_towards", a.global_position)),
		float(a.call("body_radius")), float(b.call("body_radius")))


func _frames(count: int) -> void:
	for _i in count:
		await (Engine.get_main_loop() as SceneTree).physics_frame


func _case_overlapping_pairs_separate_smallest_to_largest() -> void:
	var rows := _species_by_radius()
	var small: String = rows[0][1]
	var large: String = rows[rows.size() - 1][1]
	for pair: Array in [[small, large], [large, small], [large, large], [small, small]]:
		var ally := _body(pair[0], Vector3(0.0, 0.05, 0.0))
		var foe := _body(pair[1], Vector3(0.0, 0.05, 0.0))
		var start_gap := float(ally.call("body_radius")) + float(foe.call("body_radius")) + 0.05
		foe.global_position = Vector3(0.0, 0.05, start_gap)
		foe.call("face_towards", ally.global_position)
		ally.call("face_towards", foe.global_position)
		ally.call("set_contact_partner", foe, SPACING.ROLE_ALLY)
		foe.call("set_contact_partner", ally, SPACING.ROLE_FOE)
		var foe_start: Vector3 = foe.global_position
		await _frames(6)
		assert_true(Vector2(foe.global_position.x - foe_start.x, foe.global_position.z - foe_start.z).length() < 0.02,
			"%s holds its ground while %s yields" % [pair[1], pair[0]])
		await _frames(90)
		var need := _need(ally, foe)
		assert_true(_flat_gap(ally, foe) >= need - 0.05,
			"%s vs %s end at least %.2f m apart (gap %.2f)" % [pair[0], pair[1], need, _flat_gap(ally, foe)])
		ally.call("set_contact_partner", null)
		foe.call("set_contact_partner", null)
		ally.free()
		foe.free()


## A burst (the ally's dash, a CHARGER's travelling lunge) decides its own
## contact: spacing does not touch either body until it ends.
func _case_a_burst_is_exempt_until_it_ends() -> void:
	var rows := _species_by_radius()
	var id: String = rows[rows.size() / 2][1]
	var ally := _body(id, Vector3(0.0, 0.05, 0.0))
	var foe := _body(id, Vector3(0.0, 0.05, 20.0))
	foe.global_position.z = _need(ally, foe) + 0.3
	ally.call("set_contact_partner", foe, SPACING.ROLE_ALLY)
	foe.call("set_contact_partner", ally, SPACING.ROLE_FOE)
	await _frames(4)
	foe.call("begin_combat_burst", Vector3(0.0, 0.0, -1.0), 2.0, 0.2)
	var ally_start: Vector3 = ally.global_position
	var foe_start: Vector3 = foe.global_position
	await _frames(8)
	assert_true(foe.global_position.z < foe_start.z - 1.0, "the lunging body travels its lane inside the separation")
	assert_true(Vector2(ally.global_position.x - ally_start.x, ally.global_position.z - ally_start.z).length() < 0.02,
		"the target is not pushed out of the lane mid-lunge")
	await _frames(60)
	assert_true(_flat_gap(ally, foe) >= _need(ally, foe) - 0.05, "after the burst the pair settles apart")
	ally.free()
	foe.free()


## A wall behind the ally: it is never swept through; the opponent yields.
func _case_a_pinned_ally_is_not_pushed_through_a_wall() -> void:
	var rows := _species_by_radius()
	var id: String = rows[rows.size() - 1][1]
	var wall := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(20.0, 6.0, 1.0)
	shape.shape = box
	wall.add_child(shape)
	_root.add_child(wall)
	wall.global_position = Vector3(0.0, 3.0, -1.5)
	var ally := _body(id, Vector3(0.0, 0.05, 0.0))
	var r := float(ally.call("body_radius"))
	ally.global_position = Vector3(0.0, 0.05, -1.0 + r + 0.02)
	var foe := _body(id, Vector3(0.0, 0.05, ally.global_position.z + 2.0 * r + 0.05))
	ally.call("set_contact_partner", foe, SPACING.ROLE_ALLY)
	foe.call("set_contact_partner", ally, SPACING.ROLE_FOE)
	await _frames(120)
	assert_true(ally.global_position.z > -1.0, "the ally stays on its side of the wall (z %.2f)" % ally.global_position.z)
	assert_true(_flat_gap(ally, foe) >= _need(ally, foe) - 0.05,
		"the opponent yields the rest (gap %.2f, need %.2f)" % [_flat_gap(ally, foe), _need(ally, foe)])
	ally.free()
	foe.free()
	wall.free()


## Walking into the partner is a stop, not a creep: the stick held straight
## at the opponent for two seconds never closes inside the separation.
func _case_walking_into_the_opponent_stops_at_the_separation() -> void:
	var rows := _species_by_radius()
	var id: String = rows[0][1]
	var big: String = rows[rows.size() - 1][1]
	var ally := _body(id, Vector3(0.0, 0.05, 0.0))
	var foe := _body(big, Vector3(0.0, 0.05, 12.0))
	ally.call("set_contact_partner", foe, SPACING.ROLE_ALLY)
	foe.call("set_contact_partner", ally, SPACING.ROLE_FOE)
	var closest := INF
	for _i in 120:
		ally.call("request_move", Vector3(0.0, 0.0, 1.0))
		await _frames(1)
		closest = minf(closest, _flat_gap(ally, foe))
	assert_true(closest >= _need(ally, foe) - 0.12,
		"held stick never closes inside the separation (closest %.2f, need %.2f)" % [closest, _need(ally, foe)])
	ally.call("set_contact_partner", null)
	await _frames(60)
	for _i in 60:
		ally.call("request_move", Vector3(0.0, 0.0, 1.0))
		await _frames(1)
	assert_true(_flat_gap(ally, foe) < _need(ally, foe) - 0.2, "released, the old capsule contact returns (control)")
	ally.free()
	foe.free()


func test_contact_spacing_on_live_bodies_in_a_physics_world() -> void:
	var runner_path := "user://contact-spacing-child.gd"
	var runner := FileAccess.open(runner_path, FileAccess.WRITE)
	assert_true(runner != null)
	if runner == null:
		return
	runner.store_string('extends SceneTree\nfunc _initialize():\n\tcall_deferred("run")\nfunc run():\n\tvar test = load("res://tests/test_combat_contact_spacing.gd").new()\n\tfor method in ["_case_overlapping_pairs_separate_smallest_to_largest", "_case_a_burst_is_exempt_until_it_ends", "_case_a_pinned_ally_is_not_pushed_through_a_wall", "_case_walking_into_the_opponent_stops_at_the_separation"]:\n\t\ttest._setup_fixture()\n\t\tawait test.call(method)\n\t\ttest._free_fixture()\n\tprint("CONTACT_SPACING_RESULT=" + JSON.stringify({"assertions":test.assertion_count,"failures":test.failures}))\n\tquit(0 if test.failures.is_empty() else 1)\n')
	runner.close()
	var output: Array = []
	var absolute := ProjectSettings.globalize_path(runner_path)
	var log_path := ProjectSettings.globalize_path("user://contact-spacing-child.log")
	var code := OS.execute(OS.get_executable_path(), ["--headless", "--path", ProjectSettings.globalize_path("res://"),
		"--script", absolute, "--log-file", log_path], output, true)
	DirAccess.remove_absolute(absolute)
	var combined := "\n".join(output)
	assert_eq(code, 0, combined)
	assert_false(combined.contains("SCRIPT ERROR"), combined)
	var result: Dictionary = {}
	for line: String in combined.split("\n"):
		if line.begins_with("CONTACT_SPACING_RESULT="):
			result = JSON.parse_string(line.trim_prefix("CONTACT_SPACING_RESULT="))
	assert_eq(int(result.get("assertions", 0)), EXPECTED_CHILD_ASSERTIONS, "the child must run every case")
	assert_eq(result.get("failures", ["missing result"]), [])
