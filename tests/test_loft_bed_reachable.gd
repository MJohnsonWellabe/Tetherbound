extends "res://tests/test_case.gd"

## CL-G12: *"I've never been able to sleep in the loft bed."*
##
## The bed's own smoke (`smoke_home_sleep.gd`) passes, and so does the sleep
## beat inside `smoke_gate_b_continuous`. Both TELEPORT the body onto the loft
## — `_stand_beside()` sets `global_position` to the bed marker plus 1.5 m and
## lets it drop — so neither has ever exercised the one route a player has: up
## the stair. Driven with held stick input from the ground floor, a real body
## froze on the top tread for 700 consecutive frames
## (`tools/gate_f/probe_loft_bed_climb.gd`), wedged in the corner between a
## 0.25 m unmarked lip at the loft edge (the flight stopped at the loft slab's
## UNDERSIDE) and a timber edge beam whose top stood 0.15 m proud of the loft
## floor across the one line a body walks off the stair.
##
## WHAT THIS FILE CAN AND CANNOT DO. `tests/run_tests.gd` calls each test with
## `callv`, so a coroutine would suspend at its first `await` and never resume,
## and `Engine.get_main_loop()` is null for that runner's whole life (see
## `tests/test_party_seam.gd`'s note) — so there is no live tree, no physics
## space, and no way to drive a body here. What this file does instead is
## measure the REAL colliders the real `grandpa_house.gd` builds — every box
## read off the node tree `build()` produces, not off any number restated here
## — against the REAL capsule in `scenes/player/player.tscn` and the REAL step
## budget in `player_controller.gd`. The walk itself is exercised for real, in
## a booted world, by `tests/smoke_gate_a_rest_torch.gd::
## _walk_up_the_loft_stair_and_sleep()` and by the two probes.
##
## Every assertion below went red on the geometry that shipped before CL-G12.

const GRANDPA_HOUSE := preload("res://scripts/world/grandpa_house.gd")
const PLAYER_SCENE_PATH := "res://scenes/player/player.tscn"
const CONTROLLER_PATH := "res://scripts/player/player_controller.gd"
const DIRECTOR_PATH := "res://scripts/story/sequence_director.gd"
const BED_MESH := "res://assets/props/quaternius_furniture/BedTwin.obj"

var _house: Node3D = null
## Every solid the house builds, as (centre, size) in house-local metres.
var _solids: Array = []


func before_each() -> void:
	super.before_each()
	_house = GRANDPA_HOUSE.new()
	# Off-tree on purpose (see the header). `grandpa_house.gd::_anchor()` is
	# what makes the markers survive that; every collider is a direct child
	# with no intermediate transform, so its own `position` IS house-local.
	_house.call("build", null, null)
	_solids = []
	for child in _house.get_children():
		var body := child as StaticBody3D
		if body == null:
			continue
		for grandchild in body.get_children():
			var shape := grandchild as CollisionShape3D
			if shape != null and shape.shape is BoxShape3D:
				_solids.append({
					"at": body.position,
					"size": (shape.shape as BoxShape3D).size,
					"yaw": body.rotation.y,
				})


func after_each() -> void:
	if _house != null and is_instance_valid(_house):
		_house.free()
	_house = null
	_solids = []
	super.after_each()


func _k(key: String) -> float:
	return float(_house.get_script().get_script_constant_map()[key])


func _step_height() -> float:
	return float((load(CONTROLLER_PATH) as GDScript).get_script_constant_map()["STEP_HEIGHT"])


## The player's real collision radius, off the real scene rather than a number
## restated here — the whole stair-head question is about how far the capsule
## reaches past its own centre.
func _capsule_radius() -> float:
	var packed := load(PLAYER_SCENE_PATH) as PackedScene
	var body := packed.instantiate() as CharacterBody3D
	var radius := 0.4
	for child in body.get_children():
		var shape := child as CollisionShape3D
		if shape != null and shape.shape is CapsuleShape3D:
			radius = (shape.shape as CapsuleShape3D).radius
	body.free()
	return radius


func _bed_half_extent() -> Vector3:
	var mesh: Mesh = load(BED_MESH)
	return Vector3.ZERO if mesh == null else mesh.get_aabb().size * _k("FURNITURE_SCALE") * 0.5


## The flight has to arrive at the floor it serves. It used to stop at
## `FLOOR_H` — the loft slab's underside — leaving a quarter-metre of unmarked
## lip that only `player_controller.gd::_try_step_up` could cross.
func test_the_flight_arrives_at_the_loft_walking_surface() -> void:
	var steps := int(_k("STAIR_STEPS"))
	var rise := _k("LOFT_TOP") / float(steps)
	var loft_top := _k("LOFT_TOP")
	var top_tread := _tallest_solid_top_in(
		Rect2(_k("INNER_W") * -0.5 + _k("LOFT_W"), -_k("INNER_D") * 0.5 + 0.6 - 0.3, 0.3, 0.6))
	assert_almost_eq(top_tread, loft_top, 0.02,
		"the top tread tops out at %.3f but the loft floor it serves is at %.3f"
			% [top_tread, loft_top])
	assert_true(rise < _step_height(),
		"a %.3fm riser is not climbable inside player_controller's %.2fm step budget"
			% [rise, _step_height()])
	# Not merely under the budget: under it by enough that the raised probe has
	# somewhere to land. Ten risers to LOFT_TOP would be 0.345m — five
	# millimetres of clearance, which is no clearance at all.
	assert_true(_step_height() - rise > 0.02,
		"riser %.3fm leaves only %.3fm under the step budget" % [rise, _step_height() - rise])


## The stair-head marker has to name a point on the loft. It named
## (0.5, FLOOR_H, ...) — three tenths of a metre east of the loft edge and a
## quarter-metre below the floor, i.e. the exact spot a real body wedges on —
## so anything that "walked to the stair head" arrived there and stopped.
func test_the_stairs_top_marker_stands_on_the_loft() -> void:
	var top: Vector3 = _house.call("marker", "stairs_top")
	assert_almost_eq(top.y, _k("LOFT_TOP"), 0.01,
		"stairs_top must sit on the loft's walking surface")
	assert_true(top.x < -_k("INNER_W") * 0.5 + _k("LOFT_W"),
		"stairs_top must be west of the loft edge, i.e. actually on the loft slab")


## Nothing solid may stand proud of the loft floor across the stair opening.
## The loft edge beam's top used to sit 0.15m above the loft slab, lying
## exactly across the exit from the flight — `_try_step_up`'s second gate
## (advance with the capsule raised `STEP_HEIGHT`) refused against that box
## while a real body sat wedged on the top tread.
##
## The band tested is one capsule DIAMETER of loft west of the edge and the
## stair's own width plus a capsule radius either side, because a body leaving
## the flight occupies its centre plus that radius — which is how the beam,
## already shortened once to clear the "stair opening", still caught the
## capsule's south shoulder.
func test_nothing_stands_proud_of_the_loft_floor_at_the_stair_head() -> void:
	var radius := _capsule_radius()
	var loft_top := _k("LOFT_TOP")
	var edge_x := -_k("INNER_W") * 0.5 + _k("LOFT_W")
	var stair_z := -_k("INNER_D") * 0.5 + 0.6
	var band := Rect2(edge_x - radius * 2.0, stair_z - _k("STAIR_WIDTH") * 0.5 - radius,
		radius * 2.0, _k("STAIR_WIDTH") + radius * 2.0)
	var offenders: Array[String] = []
	for solid: Dictionary in _solids:
		var at: Vector3 = solid["at"]
		var size: Vector3 = solid["size"]
		var top := at.y + size.y * 0.5
		var bottom := at.y - size.y * 0.5
		# Only things that rise ABOVE the loft floor and start at or below it:
		# the walls and the ceiling are legitimately up there, the treads are
		# legitimately below it.
		if top <= loft_top + 0.01 or bottom > loft_top + 0.01:
			continue
		var foot := Rect2(at.x - size.x * 0.5, at.z - size.z * 0.5, size.x, size.z)
		if not foot.intersects(band):
			continue
		# The perimeter walls are meant to be there and are not walked into.
		if size.x > _k("INNER_W") or size.z > _k("INNER_D"):
			continue
		offenders.append("box %s at %s (top %.3f, loft floor %.3f)"
			% [str(size.snapped(Vector3.ONE * 0.01)), str(at.snapped(Vector3.ONE * 0.01)),
				top, loft_top])
	assert_true(offenders.is_empty(),
		"solid geometry stands on the loft floor across the stair head: %s" % str(offenders))


## The bed offers "Sleep" to a body that can actually stand next to it — on
## the loft floor, not on the mattress.
func test_the_sleep_prompt_reaches_a_body_standing_on_the_loft() -> void:
	var prompt := _house.get_node_or_null(^"SleepPrompt") as Node3D
	assert_true(prompt != null, "the loft bed must carry a Sleep interactable")
	if prompt == null:
		return
	assert_eq(str(prompt.get("label")), "Sleep")
	var radius := float(prompt.get("radius"))
	var bed_at := Vector3(-_k("INNER_W") * 0.5 + 1.3, _k("LOFT_TOP"), -_k("INNER_D") * 0.5 + 1.9)
	var half := _bed_half_extent()
	# Beside the bed, on the loft floor, one capsule radius clear of the
	# mattress: the nearest a walking body gets without climbing onto it.
	var beside := Vector3(bed_at.x + half.x + _capsule_radius(), _k("LOFT_TOP"), bed_at.z)
	var gap := beside.distance_to(prompt.position)
	assert_true(gap < radius,
		"a body beside the bed on the loft floor is %.2fm from the Sleep prompt, "
			% gap + "outside its %.2fm radius" % radius)


## The wake beat has to leave the body ON the mattress, along it and inside
## it. `BED_LIE_REACH` was 1.5, which put the feet 0.135m past the footboard
## and out over the loft floor — so the body settled on the FLOOR, a full
## mattress-height below the sheet it was supposed to be lying on.
func test_the_wake_pose_lies_inside_the_mattress() -> void:
	var reach := float((load(DIRECTOR_PATH) as GDScript)
		.get_script_constant_map()["BED_LIE_REACH"])
	var bed: Vector3 = _house.call("marker", "bed")
	var bed_at_z := -_k("INNER_D") * 0.5 + 1.9
	var half := _bed_half_extent()
	# `character_model.gd::set_lying()` swings the head toward -Z from the
	# feet, so the body occupies [feet - height, feet]. The trainer's own
	# height is the length of that body.
	var body_length := _trainer_height()
	var feet_z := bed.z + reach
	var head_z := feet_z - body_length
	assert_true(feet_z <= bed_at_z + half.z,
		"the sleeper's feet land at z %.3f, past the footboard at %.3f"
			% [feet_z, bed_at_z + half.z])
	assert_true(head_z >= bed_at_z - half.z,
		"the sleeper's head lands at z %.3f, past the headboard at %.3f"
			% [head_z, bed_at_z - half.z])


func _trainer_height() -> float:
	var file := FileAccess.open("res://data/config/art.json", FileAccess.READ)
	if file == null:
		return 1.8
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return 1.8
	var characters: Dictionary = (parsed as Dictionary).get("characters", {})
	var trainer: Dictionary = characters.get("trainer", {})
	return float(trainer.get("height", 1.8))


## The tallest solid whose footprint falls inside `area` (x/z, house-local).
func _tallest_solid_top_in(area: Rect2) -> float:
	var tallest := -INF
	for solid: Dictionary in _solids:
		var at: Vector3 = solid["at"]
		var size: Vector3 = solid["size"]
		# Walls and the ceiling span the whole room; the question here is about
		# the flight, so anything room-sized is not a tread.
		if size.x > _k("INNER_W") or size.z > _k("INNER_D"):
			continue
		var foot := Rect2(at.x - size.x * 0.5, at.z - size.z * 0.5, size.x, size.z)
		if foot.intersects(area):
			tallest = maxf(tallest, at.y + size.y * 0.5)
	return tallest
