extends "res://tests/test_case.gd"

const SEGMENT := preload("res://tests/helpers/stormwood_earned_dynamo_segment.gd")

class Flags extends RefCounted:
	var values: Dictionary = {}
	func has(flag: String) -> bool:
		return values.has(flag)

class QuietSegment extends SEGMENT:
	func _fail(message: String) -> bool:
		failures.append(message)
		return false

func test_each_earned_entry_prerequisite_is_required() -> void:
	var flags := Flags.new()
	for flag: String in SEGMENT.ENTRY_FLAGS:
		flags.values[flag] = true
	assert_true(SEGMENT.missing_entry_flags(flags).is_empty())
	for flag: String in SEGMENT.ENTRY_FLAGS:
		flags.values.erase(flag)
		assert_eq(SEGMENT.missing_entry_flags(flags), [flag])
		flags.values[flag] = true
	assert_eq(SEGMENT.missing_entry_flags(null).size(), SEGMENT.ENTRY_FLAGS.size())

func test_dynamo_null_entry_cannot_claim_core_completion() -> void:
	var segment := QuietSegment.new()
	assert_false(segment.result().passed)
	var observed: Dictionary = await segment.run(null, null, null)
	assert_false(observed.passed)
	assert_eq(observed.failures.size(), 1)
	assert_eq(observed.endpoint, "earned physical Dynamo core, before Marrow")

func test_named_rosters_and_switch_guards_match_production_catalogues() -> void:
	var cast: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/config/stormwood_trainers.json"))
	var authored: Dictionary = {}
	for row: Dictionary in cast.trainers:
		authored[str(row.id)] = row
	for id: String in SEGMENT.TRAINERS:
		assert_true(authored.has(id), id + " must be an actual production roster")
		assert_eq(authored[id].party.size(), 3)
	var rods: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/config/stormwood_rod_stations.json"))
	for pair in [["deepwood_rod_station", SEGMENT.TRAINERS[0]],
			["dynamo_approach_rod_station", SEGMENT.TRAINERS[1]]]:
		var found := false
		for row: Dictionary in rods.stations:
			if str(row.id) == pair[0]:
				found = true
				assert_eq(str(row.guard_trainer_id), pair[1])
				assert_eq(str(row.guard_defeat_flag), "stormwood:trainer:%s:defeated" % pair[1])
		assert_true(found)

func test_no_progression_or_pose_bypass_and_no_marrow_start() -> void:
	var source := FileAccess.get_file_as_string("res://tests/helpers/stormwood_earned_dynamo_segment.gd")
	for bypass in ["global_position =", "face_towards", "emit_event(", "enter_realm(",
		"travel_for_peer(", "request_stormwood_arch_travel(", "inventory.add(",
		"progression.set(", "begin_for_peer(", "captain_marrow_dynamo_core"]:
		assert_false(source.contains(bypass), bypass)
	for receipt in ["stormwood:captive_truth_learned", "stormwood:deepwood_station_disabled",
		"stormwood:all_rods_disabled", "stormwood:ember_bivouac_reached", "stormwood:kestrel_defeated",
		"_roster_ids() != _party_before", "ascent_point", "_player.is_on_floor()", "furthest >= 0.998"]:
		assert_true(source.contains(receipt), receipt)

func test_whole_ascent_matches_existing_smoke_clock_and_budget() -> void:
	var smoke := FileAccess.get_file_as_string("res://tests/smoke_stormheart_ascent.gd")
	assert_true(smoke.contains("const MAX_WALK_FRAMES := %d" % SEGMENT.ASCENT_FRAMES))
	assert_true(smoke.contains("const TEST_TIME_SCALE := %.1f" % SEGMENT.ASCENT_SCALE))
	assert_eq(SEGMENT.ASCENT_HZ, 60)
	assert_true(smoke.contains("const CORE_TOLERANCE := %.1f" % SEGMENT.CORE_TOLERANCE))
	var source := FileAccess.get_file_as_string("res://tests/helpers/stormwood_earned_dynamo_segment.gd")
	var from := source.find("func _walk_actual_ascent")
	var ascent := source.substr(from, source.find("\nfunc ", from + 1) - from)
	assert_true(ascent.contains("Engine.get_physics_frames() - started < ASCENT_FRAMES"))
	# The budget measures climbing only. A wild that engages on the approach
	# (relay DRY RUN a9b6da46) is fought outside it, and its frames are given
	# back; a trainer battle mid-ascent still fails.
	assert_false(ascent.contains("await _fight_current"), "the ascent body never fights inline")
	assert_true(ascent.contains("await _fight_ascent_wild()"))
	assert_true(ascent.contains("started += Engine.get_physics_frames() - fight_started"))
	assert_true(ascent.contains("trainer_battle_active()") and ascent.contains("unexpected trainer combat blocks"))


## Relay DRY RUN 44adfbe4 wedged the player under the Outer Works approach
## slab (x -105..-95 from the rod station at z 5350 to the deck edge at z 5426,
## floating up to 3 m over the terrain) walking from Kestrel to its foot.
func test_the_walk_to_the_approach_foot_never_passes_under_the_slab() -> void:
	var kestrel := _seat("res://data/config/stormwood_trainers.json", "trainers", "officer_kestrel_outer_works")
	var kestrel_npc := _seat("res://data/config/stormwood_npcs.json", "characters", "officer_kestrel")
	for from: Vector2 in [kestrel, Vector2(-140, 5242)]:
		var route := SEGMENT.approach_foot_route(from)
		assert_eq(route[route.size() - 1], SEGMENT.APPROACH_FOOT, "every route ends on the slab's foot")
		var at := from
		for point: Vector2 in route:
			# Sample each leg; from the first sideways step on, no sample may be
			# over the slab's footprint (plus a body radius) north of its foot.
			for i in 21:
				var p := at.lerp(point, i / 20.0)
				var under := p.y > SEGMENT.APPROACH_FOOT.y + 0.5 and absf(p.x - SEGMENT.APPROACH_FOOT.x) < 5.0 + 0.5
				# Only a straight sideways step out from under it keeps headroom.
				if under and not (at == from and is_equal_approx(point.y, from.y)):
					assert_true(false, "leg %s -> %s passes under the slab at %s" % [str(at), str(point), str(p)])
				if at != from or i > 0:
					assert_true(p.distance_to(kestrel_npc) > 2.0 or p.distance_to(SEGMENT.APPROACH_FOOT) < 9.0,
						"leg passes %.1f m from Kestrel's NPC" % p.distance_to(kestrel_npc))
			at = point
	var sideways := SEGMENT.approach_foot_route(kestrel)[0]
	assert_eq(sideways.y, kestrel.y, "from under the slab the first step is straight sideways, keeping its headroom")


func _seat(path: String, key: String, id: String) -> Vector2:
	var parsed: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	for row: Dictionary in parsed.get(key, []):
		if str(row.get("id", "")) == id:
			return Vector2(float(row.position[0]), float(row.position[2]))
	assert_true(false, "%s seat %s missing" % [path, id])
	return Vector2.ZERO


## Relay run ec5febd1 left the approach slab during two ascent fights and ran
## out its climb budget on the ground 6 m beneath the slab's top.
func test_walking_under_the_approach_slab_is_detected() -> void:
	# Foot at ground + 0.2 (stormwood_world.gd add_approach), top 6 m over the tree base.
	var foot := Vector3(-100, 107.77, 5350)
	var top := Vector3(-100, 118.1, 5470 - 44)
	assert_true(SEGMENT.under_approach_slab(Vector3(-99.79, 111.95, 5429.64), foot, top),
		"run ec5febd1's stall: on the ground under the deck ring's rim, past the slab's top")
	assert_false(SEGMENT.under_approach_slab(Vector3(-100, 118.3, 5429.64), foot, top),
		"on the deck ring at the approach point")
	assert_true(SEGMENT.under_approach_slab(Vector3(-99.79, 111.95, 5420.0), foot, top),
		"run ec5febd1's line: on the ground well below the slab")
	assert_true(SEGMENT.under_approach_slab(Vector3(-96.1, 109.36, 5374.6), foot, top),
		"run 44adfbe4's wedge point is under the slab")
	var on := lerpf(foot.y, top.y, (5400.0 - foot.z) / (top.z - foot.z))
	assert_false(SEGMENT.under_approach_slab(Vector3(-100, on + 0.9, 5400), foot, top), "standing on the slab")
	assert_false(SEGMENT.under_approach_slab(Vector3(-108, 100, 5400), foot, top), "west of the footprint")
