extends "res://tests/test_case.gd"

## C1-S3 / R1-4 (docs/specs/C1_RIDEABLE_ROSTER_FLY_TELEPORT.md).
## Pins the rideable roster the owner named on 2026-09-04:
## "Burrowback and the grownup mudsnout should be rideable. Terrapup too."
##
## This is the DATA half of R1-4 -- exactly which species carry a `rideable`
## block in `data/creatures/species.json`, and the shape of the three new ones
## -- read from the real file the same way `tests/test_riding_saddle.gd`
## already does, so a species that gains or loses the block fails here rather
## than silently changing the roster.

const SPECIES := preload("res://scripts/creatures/creature_species.gd")

## The exact roster this contract names. Not derived from the file, on
## purpose: this is the ONE test allowed to say the names out loud, so a
## roster change is a deliberate edit here rather than a passive follow of
## whatever species.json happens to say today.
const EXPECTED_RIDEABLE: Array[String] = [
	"terrapup", "burrowback", "tuskroot", "meadowhart", "veridian",
]

## Water directive and owner board: only these five carry a swimmer.
const EXPECTED_WATER_SWIMMERS: Array[String] = [
	"water_aquaryn", "water_mosshell", "water_sirenseal", "water_riverdrake", "water_cannonback",
]

func test_water_swimmers_require_swim_saddle_and_other_water_species_cannot_carry() -> void:
	for id: String in _all_species_ids():
		if not id.begins_with("water_"):
			continue
		assert_eq(SPECIES.is_rideable(id), id in EXPECTED_WATER_SWIMMERS,
			"Water rideability must match the owner roster: " + id)
		if id in EXPECTED_WATER_SWIMMERS:
			assert_eq(str(SPECIES.rideable(id).get("requires_item", "")), "swim_saddle")
		else:
			assert_false(SPECIES.definition(id).has("rideable"),
				"Land-or-shallows species, Tidecoil and Guardian must not inherit mounts: " + id)


## The three this lane adds. Meadowhart and Veridian are unchanged by it.
const NEW_MOUNTS: Array[String] = ["terrapup", "burrowback", "tuskroot"]

## R1-4's own table: Mudsnout is explicitly excluded ("the grownup mudsnout",
## not the cub) and Ashtusk, D71's other evolution branch, is named as the
## other exclusion so a second rideable evolution never makes the Sunstone
## choice a traversal choice.
const NEVER_RIDEABLE: Array[String] = ["mudsnout", "ashtusk"]


func _all_species_ids() -> Array[String]:
	var found: Array[String] = []
	for id: String in SPECIES.table().keys():
		if not id.begins_with("_"):
			found.append(id)
	return found


func test_exactly_five_meadows_and_five_owner_water_species_are_rideable() -> void:
	var found: Array[String] = []
	for id in _all_species_ids():
		if SPECIES.is_rideable(id):
			found.append(id)
	found.sort()
	var expected := EXPECTED_RIDEABLE.duplicate()
	expected.append_array(EXPECTED_WATER_SWIMMERS)
	expected.sort()
	assert_eq(found, expected,
		"the rideable roster is %s, expected exactly %s" % [found, expected])


func test_mudsnout_and_ashtusk_carry_no_rideable_block_at_all() -> void:
	for id in NEVER_RIDEABLE:
		assert_true(SPECIES.has(id), "'%s' is missing from species.json entirely" % id)
		assert_false(SPECIES.is_rideable(id),
			"'%s' is rideable; R1-4 names only the grownup form and Tuskroot, never this one" % id)
		var raw: Variant = SPECIES.definition(id).get("rideable")
		assert_true(raw == null,
			"'%s' carries a `rideable` block in the data at all (even a disabled one); R1-4 says it should carry none" % id)


func test_the_three_new_mounts_require_a_saddle() -> void:
	for id in NEW_MOUNTS:
		var block := SPECIES.rideable(id)
		assert_false(block.is_empty(), "'%s' has no rideable block; C1-S3 was supposed to add one" % id)
		assert_eq(str(block.get("requires_item", "")), "saddle",
			"'%s' should require the generic saddle, per R1-4's table" % id)


func test_none_of_the_three_new_mounts_carries_a_climb_limit() -> void:
	for id in NEW_MOUNTS:
		var block := SPECIES.rideable(id)
		assert_eq(float(block.get("climb_max_slope_deg", 0.0)), 0.0,
			"'%s' carries a climb_max_slope_deg above the trainer's own 45 degrees; R1-4 says absent for every saddle mount but Meadowhart" % id)


## R1-4's [1.0, 2.0] band is stated for the SADDLE mounts (Terrapup,
## Burrowback, Tuskroot, Meadowhart) -- the legendary Veridian is the named
## exception above that ladder (2.8, no tack, a climb limit no saddle mount
## gets), exactly as `_comment_rideable` on `veridian` states, so it is
## deliberately excluded from this band rather than silently included.
func test_every_saddle_mount_multiplier_sits_in_one_to_two() -> void:
	for id in EXPECTED_RIDEABLE:
		if str(SPECIES.rideable(id).get("requires_item", "")) != "saddle":
			continue
		var block := SPECIES.rideable(id)
		var multiplier := float(block.get("ride_speed_multiplier", 0.0))
		assert_true(multiplier >= 1.0 and multiplier <= 2.0,
			"'%s' ride_speed_multiplier is %.2f, outside R1-4's [1.0, 2.0] band" % [id, multiplier])


## R1-4's own table values, pinned so a retune of the multipliers or the
## dismount distances is a deliberate edit to this file too, not a silent
## drift the design doc no longer matches.
func test_r1_4_table_values() -> void:
	var expected := {
		"terrapup": {"ride_speed_multiplier": 1.7, "dismount_distance": 1.6},
		"burrowback": {"ride_speed_multiplier": 1.5, "dismount_distance": 1.6},
		"tuskroot": {"ride_speed_multiplier": 1.8, "dismount_distance": 1.8},
		"meadowhart": {"ride_speed_multiplier": 2.0, "dismount_distance": 1.6},
	}
	for id: String in expected:
		var block := SPECIES.rideable(id)
		var want: Dictionary = expected[id]
		assert_eq(float(block.get("ride_speed_multiplier", 0.0)), float(want["ride_speed_multiplier"]),
			"'%s' ride_speed_multiplier drifted from R1-4's table" % id)
		assert_eq(float(block.get("dismount_distance", 0.0)), float(want["dismount_distance"]),
			"'%s' dismount_distance drifted from R1-4's table" % id)


## No saddle mount may out-run Meadowhart, the chapter's own dedicated
## traversal creature (R1-4's own "fails if").
func test_no_saddle_mount_out_runs_meadowhart() -> void:
	var meadowhart_multiplier := float(SPECIES.rideable("meadowhart").get("ride_speed_multiplier", 0.0))
	for id in NEW_MOUNTS:
		var multiplier := float(SPECIES.rideable(id).get("ride_speed_multiplier", 0.0))
		assert_true(multiplier <= meadowhart_multiplier,
			"'%s' (%.2f) out-runs Meadowhart (%.2f); R1-4 keeps every saddle mount at or below it" % [
				id, multiplier, meadowhart_multiplier
			])


## Every rideable species must at least declare a mount_offset that keeps the
## rider above the ground and inside the creature's own declared height --
## the sanity floor for "committed without its measurement" (R1-4's fails-if).
func test_mount_offset_is_measured_and_sane() -> void:
	for id in EXPECTED_RIDEABLE:
		var block := SPECIES.rideable(id)
		var offset: Vector3 = block.get("mount_offset", Vector3.ZERO)
		var height := float(SPECIES.placeholder(id).get("height", 0.0))
		assert_true(offset.y > 0.0,
			"'%s' mount_offset.y is at or below the ground" % id)
		assert_true(offset.y <= height,
			"'%s' mount_offset.y (%.2f) sits above the creature's own declared height (%.2f)" % [
				id, offset.y, height
			])
		var raw: Variant = SPECIES.definition(id).get("rideable")
		assert_true(raw is Dictionary, "'%s' rideable block missing" % id)
		if raw is Dictionary:
			assert_true((raw as Dictionary).has("mount_offset"),
				"'%s' rideable block has no explicit mount_offset; it is relying on the accessor's fallback" % id)
