extends "res://tests/test_case.gd"

const LIBRARY := preload("res://scripts/vfx/move_effect_library.gd")
const BUDGET := preload("res://scripts/vfx/move_effect_budget.gd")

func test_every_move_resolves_and_all_24_bodies_impacts_trails_and_cues_exist() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/moves/moves.json"))
	var archetypes: Dictionary = LIBRARY.config().get("archetypes", {})
	var audio: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/audio.json"))
	var cues: Dictionary = audio.get("move_effect_cues", {})
	assert_eq(archetypes.size(), 24)
	for id: String in archetypes:
		var row: Dictionary = archetypes[id]
		assert_true(not str(row.body.get("shape", "")).is_empty(), id)
		assert_true(not str(row.trail.get("style", "")).is_empty(), id)
		assert_true(not str(row.impact.get("shape", "")).is_empty(), id)
		assert_true(int(row.budget.impact) + int(row.budget.trail) <= int(LIBRARY.config().ordinary_particle_limit), id)
		for role: String in ["launch", "travel", "launch_travel", "impact", "launch_mastery", "launch_travel_mastery", "impact_mastery"]:
			var cue := str(row.sound.get(role, ""))
			assert_true(cues.has(cue), id + ":" + role)
			assert_true(FileAccess.file_exists(str(cues.get(cue, ""))), cue)
	for id: String in data.moves:
		assert_false(LIBRARY.resolve(data.moves[id].vfx).is_empty(), id + " must resolve")
	assert_true(LIBRARY.resolve({"archetype": "unknown"}).is_empty())
	assert_true(LIBRARY.resolve({}).is_empty())
	var boulder := LIBRARY.resolve(data.moves.rock_throw.vfx, 5)
	assert_eq(int(boulder.parameters.count), 1, "Rock Throw retains one boulder at maximum mastery")
	assert_true(str(boulder.sound.launch).begins_with("vfx_stone_boulder"))
	assert_true(int(LIBRARY.resolve(data.moves.pebble_toss.vfx, 3).parameters.count) >= 3,
		"Pebble Toss retains several small stones")

func test_mastery_grows_presentation_without_changing_arrival_schedule() -> void:
	for id: String in LIBRARY.config().archetypes:
		var base := LIBRARY.resolve({"archetype": id}, 1)
		var grown := LIBRARY.resolve({"archetype": id}, 5)
		assert_true(float(grown.parameters.size) > float(base.parameters.size), id)
		assert_true(float(grown.parameters.trail) > float(base.parameters.trail), id)
		assert_true(grown.secondary_trail and grown.impact_layer, id)
		assert_eq(base.arrival, grown.arrival)
		assert_almost_eq(LIBRARY.travel_seconds(Vector3.ZERO, Vector3.ONE, {"archetype": id}, {"travel_seconds": 0.27, "mastery_rank": 1}), 0.27)
		assert_almost_eq(LIBRARY.travel_seconds(Vector3.ZERO, Vector3.ONE, {"archetype": id}, {"travel_seconds": 0.27, "mastery_rank": 5}), 0.27)

func test_critical_impact_prunes_trails_before_spending_beyond_encounter_cap() -> void:
	var encounter := "budget-unit"
	var first := BUDGET.reserve(encounter, 12, 20, 48)
	var second := BUDGET.reserve(encounter, 24, 18, 48)
	assert_eq(int(BUDGET.allocation(first).trail), 12)
	assert_eq(int(BUDGET.allocation(second).impact), 24)
	assert_eq(int(BUDGET.allocation(second).trail), 0)
	assert_eq(BUDGET.used(encounter), 48)
	BUDGET.release(first)
	BUDGET.release(second)
	assert_eq(BUDGET.used(encounter), 0)

func test_optional_receipt_is_recursively_frozen_and_detached() -> void:
	var source := {"action_id": "fight:1", "travel_seconds": 0.2, "mastery_rank": 3,
		"seed": 17, "waypoints": [Vector3.ONE], "nested": {"count": 3}}
	var frozen: Dictionary = LIBRARY.frozen_copy(source)
	source.waypoints.append(Vector3.ZERO)
	source.nested.count = 99
	assert_eq(frozen.waypoints.size(), 1)
	assert_eq(frozen.nested.count, 3)
	assert_true(frozen.is_read_only())
	assert_true(frozen.waypoints.is_read_only())
	assert_true(frozen.nested.is_read_only())

func test_light_cap_is_global_idempotent_and_reclaims_existing_lease() -> void:
	assert_eq(BUDGET.lights_used(), 0, "No previous test leaves a light lease")
	var tokens: Array[int] = []
	for i in 5:
		var encounter := "light-unit-%d" % i
		var token := BUDGET.reserve(encounter, 12, 8, 48)
		tokens.append(token)
		assert_eq(BUDGET.reserve_light(token, 4), i < 4, "Cap spans distinct encounter IDs")
		assert_eq(BUDGET.used(encounter), 20, "Light reservation preserves particle accounting")
	assert_eq(BUDGET.lights_used(), 4)
	assert_true(BUDGET.reserve_light(tokens[0], 4), "Repeating an active reservation is idempotent")
	assert_eq(BUDGET.lights_used(), 4)
	assert_false(BUDGET.reserve_light(tokens[4], 0), "Disabled light cap refuses a new light")
	assert_false(BUDGET.reserve_light(-1, 4), "An absent lifetime token cannot own a light")
	BUDGET.release(tokens[0])
	assert_eq(BUDGET.lights_used(), 3)
	assert_false(BUDGET.reserve_light(tokens[0], 4), "Released token cannot resurrect")
	assert_true(BUDGET.reserve_light(tokens[4], 4), "A released light slot admits another active effect")
	assert_eq(BUDGET.lights_used(), 4)
	BUDGET.release(tokens[0])
	assert_eq(BUDGET.lights_used(), 4, "Repeating stale release preserves the new owner")
	for token in tokens: BUDGET.release(token)
	assert_eq(BUDGET.lights_used(), 0)
	for i in 5: assert_eq(BUDGET.used("light-unit-%d" % i), 0)

## Authored launch/contact/aftermath stages are presentation-only meshes.
## Every one must name a style the ground-mark shader draws, stay within
## its metre caps and fixed per-effect mesh budget, and end in finite time
## so the effect (and its particle lease) is always released.
func test_authored_stages_are_bounded_and_drawable() -> void:
	const EFFECT := preload("res://scripts/vfx/move_effect.gd")
	var styles := ["scorch", "dust", "shockwave", "burn"]
	var authored := 0
	for id: String in LIBRARY.config().archetypes:
		var row := LIBRARY.resolve({"archetype": id}, 5)
		var launch: Dictionary = row.get("launch", {})
		var stages: Dictionary = (row.impact as Dictionary).get("stages", {})
		if launch.is_empty() and stages.is_empty(): continue
		authored += 1
		var meshes := 0
		var parts: Array[Dictionary] = []
		for key: String in ["flash", "ground", "sky_call"]:
			if launch.get(key) is Dictionary: parts.append(launch[key]); meshes += 1
		for key: String in ["flash", "glow", "shockwave", "mark"]:
			if stages.get(key) is Dictionary: parts.append(stages[key]); meshes += 1
		assert_true(meshes <= EFFECT.MAX_STAGE_MESHES, id + " stage meshes within the fixed cap")
		for part: Dictionary in parts:
			var duration := float(part.get("duration", 0.0))
			assert_true(duration > 0.0 and duration <= 2.5, id + " stage ends in bounded time")
			assert_true(float(part.get("min_m", 0.0)) <= float(part.get("max_m", 1.0)), id + " stage metre caps ordered")
			assert_true(float(part.get("max_m", 1.0)) <= 4.0, id + " stage never covers a whole arena")
			if part.has("style"): assert_true(str(part.style) in styles, id + " ground style " + str(part.style) + " is drawable")
		var linger := float(stages.get("mote_linger_seconds", 0.0))
		assert_true(linger >= 0.0 and linger <= 1.5, id + " settled debris lingers briefly")
	assert_true(authored >= 20, "most archetypes author a launch or impact stage")

## Stages never change gameplay timing: arrival and travel stay frozen at
## every rank whether or not an archetype authors stages.
func test_stages_do_not_change_arrival_or_travel() -> void:
	for id: String in LIBRARY.config().archetypes:
		var base := LIBRARY.resolve({"archetype": id}, 1)
		var grown := LIBRARY.resolve({"archetype": id}, 5)
		assert_eq(base.arrival, grown.arrival, id)
		assert_almost_eq(LIBRARY.travel_seconds(Vector3.ZERO, Vector3.ONE * 4.0, {"archetype": id}, {"travel_seconds": 0.31, "mastery_rank": 5}), 0.31)
