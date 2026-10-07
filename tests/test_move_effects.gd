extends "res://tests/test_case.gd"

const LIBRARY := preload("res://scripts/vfx/move_effect_library.gd")
const BUDGET := preload("res://scripts/vfx/move_effect_budget.gd")
const ULTIMATES := preload("res://scripts/vfx/ultimates/ultimate_library.gd")

## F35#0: keep the previously passing catalogue probe in the existing suite.
## This checks production defaults and authored mappings, without enabling
## presentation, granting progress, or claiming the separate live-ultimate rows.
func test_shared_ultimate_catalogue_covers_every_live_species_type_and_role() -> void:
	var moves: RefCounted = preload("res://scripts/creatures/move_db.gd").load_default()
	var species: Dictionary = preload("res://scripts/creatures/creature_species.gd").table()
	var learnsets: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/moves/learnsets.json")).species
	var visuals: Dictionary = ULTIMATES.config().get("visuals", {})
	var shared: Array[String] = []
	var pairs: Dictionary = {}
	for id: String in moves.move_ids():
		var move: Dictionary = moves.move(id)
		if move.get("slot") != "ultimate" or move.get("ultimate", {}).get("unique") != false: continue
		shared.append(id)
		var visual: Dictionary = visuals.get(id, {})
		assert_false(visual.is_empty(), id + " has an authored signature body")
		assert_eq(visual.get("unique"), false, id + " is shared in both catalogues")
		assert_eq(visual.get("type"), move.get("type"), id + " retains its primary type")
		assert_true(visual.get("role") in ["WALL", "CHARGER", "DIVER", "CURRENT"], id + " has a species role")
		var pair := str(visual.get("type", "")) + ":" + str(visual.get("role", ""))
		assert_false(pairs.has(pair), pair + " has one shared signature")
		pairs[pair] = id
	assert_true(shared.size() >= 16 and shared.size() <= 20, "16–20 shared type×role signatures")
	assert_false(species.is_empty(), "the production catalogue includes live base and Water species")
	for id: String in species:
		var row: Dictionary = learnsets.get(id, {})
		assert_false(row.is_empty(), id + " has a learnset")
		var creature: RefCounted = preload("res://scripts/creatures/creature_species.gd").spawn(id)
		assert_true(creature != null, id + " actually spawns")
		if creature == null: continue
		var ultimate := str(creature.get("move_ultimate"))
		assert_eq(ultimate, str(row.get("ultimate", "")), id + " equips its authored signature")
		assert_eq(moves.slot(ultimate), "ultimate", id + " maps to a registered ultimate")
		var move: Dictionary = moves.move(ultimate)
		assert_true(move.get("ultimate", {}).get("unique") is bool, id + " declares shared or unique")
		if move.get("ultimate", {}).get("unique") != false: continue
		assert_true(shared.has(ultimate), id + " belongs to the shared catalogue")
		assert_eq(move.get("type"), species[id].get("type"), id + " uses its primary type")
		assert_eq(visuals.get(ultimate, {}).get("role"), row.get("role_family"), id + " uses its authored role")
		var pair := str(species[id].get("type", "")) + ":" + str(row.get("role_family", ""))
		assert_eq(pairs.get(pair), ultimate, id + " has an exact type×role mapping")
	for pair: String in ULTIMATES.config().get("unused_pair_visual_fallbacks", {}):
		assert_false(pairs.has(pair), pair + " fallback is only for an unused pair")
		assert_true(shared.has(ULTIMATES.config().unused_pair_visual_fallbacks[pair]), pair + " falls back to a shared row")

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

## Owner-directed ultimate overrides (water reads as a wave or a water ball)
## must resolve through this library at every breakthrough tier and keep the
## ultimate's frozen timing (arrival unchanged by the override).
func test_ultimate_overrides_resolve_to_staged_presentations() -> void:
	var overrides: Dictionary = LIBRARY.config().get("ultimate_overrides", {})
	var count := 0
	for move_id: String in overrides:
		if move_id.begins_with("_"): continue
		count += 1
		var visual := LIBRARY.ultimate_override(move_id)
		for rank in range(1, 6):
			var row := LIBRARY.resolve(visual, rank)
			assert_false(row.is_empty(), move_id + " resolves at tier %d" % rank)
			if row.is_empty(): continue
			assert_true(not str((row.impact as Dictionary).get("shape", "")).is_empty(), move_id + " has an impact")
		assert_eq(LIBRARY.resolve(visual, 1).arrival, LIBRARY.resolve(visual, 5).arrival, move_id)
	assert_true(count >= 7, "every water ultimate has an authored wave or water-ball presentation")
	var ball := LIBRARY.resolve({"archetype": "bubble_volley", "presentation_variant": "water_ball"}, 3)
	assert_eq(str(ball.body.get("surface_material", "")), "water_stream", "water ball uses the flowing-water surface")
	assert_true(LIBRARY.resolve({"archetype": "bubble_volley", "presentation_variant": "missing"}, 1).is_empty(), "unknown variants refuse")

func check_actual_ultimate_override_preserves_earned_rank_and_independent_breakthrough_growth() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	assert_true(tree != null, "the existing smoke provides the initialized presentation tree")
	if tree == null: return
	var parent := Node3D.new()
	tree.root.add_child(parent)
	var previous_config := ULTIMATES._config
	ULTIMATES._config = ULTIMATES.config().duplicate(true)
	ULTIMATES._config["enabled"] = true
	var moves: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/moves/moves.json")).moves
	for move_id: String in ["ultimate_terrapup", "ultimate_ripplet"]:
		var visual := LIBRARY.ultimate_override(move_id)
		for count in [0, 2, 5]:
			var previous_size := 0.0
			for rank in range(1, 6):
				var id := "%s:b%d:r%d" % [move_id, count, rank]
				var binding := {"character_id":"rank-owner", "creature_uid":"rank-owned",
					"encounter_id":id, "generation":1, "action":1}
				var spec := {"slot":"ultimate", "move_id":move_id, "action_id":id + ":1",
					"actor_binding":binding, "mastery_rank":rank, "breakthrough_count":count,
					"ultimate":moves[move_id].ultimate.duplicate(true)}
				var context := {"current_actor":binding, "travel_seconds":0.25,
					"recipient_character_id":"rank-owner", "source_ground":Vector3.ZERO, "target_ground":Vector3.RIGHT * 4.0}
				var effect := ULTIMATES.launch(parent, Vector3.UP, Vector3.RIGHT * 4.0 + Vector3.UP, spec, context)
				assert_true(effect != null, id + " launches the actual authored override")
				if effect == null: continue
				var row: Dictionary = effect.get("_row")
				var frozen: Dictionary = effect.get("_context")
				var base := LIBRARY.resolve(visual, rank)
				var growth: Dictionary = ULTIMATES.resolve(move_id, count).growth
				assert_eq(row.mastery_rank, rank, id + " keeps the earned effect tier")
				assert_eq(frozen.mastery_rank, rank)
				assert_eq(frozen.breakthrough_count, count)
				assert_true(frozen.breakthrough_growth.is_read_only(), "only immutable growth values reach the effect")
				assert_almost_eq(float(row.parameters.size), float(base.parameters.size) * float(growth.size_scale))
				assert_true(float(row.parameters.size) > previous_size, "each earned rank visibly grows at fixed breakthroughs")
				previous_size = float(row.parameters.size)
				assert_eq(row.budget, base.budget, "growth cannot enlarge the allocation budget")
				assert_eq(row.arrival, base.arrival)
				assert_almost_eq(float(effect.get("_travel")), 0.25, 0.00001)
				var expected_count := 1 if int(visual.count) == 1 else mini(int(base.parameters.count) + int(growth.count_add), int(LIBRARY.config().max_body_count))
				assert_eq(int(row.parameters.count), expected_count, "single waves stay single; volleys retain the existing cap")
				assert_between(float(row.impact.accent_count), 4.0, 18.0)
				effect.free()
	ULTIMATES._config = previous_config
	parent.free()
