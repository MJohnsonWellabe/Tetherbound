extends "res://tests/test_tm_teach_transaction.gd"

## Focused data and existing journal/owner-carrier proof; real two-peer UI
## rejoin remains a separate smoke requirement.
const MOVES := preload("res://scripts/creatures/move_db.gd")
const MASTERY := preload("res://scripts/creatures/move_mastery.gd")

func test_all_species_have_gated_learnsets_and_two_utility_choices() -> void:
	var moves := MOVES.load_default()
	assert_true(TEACHING.learnset_errors(JSON.parse_string(FileAccess.get_file_as_string(TEACHING.LEARNSETS_PATH)), moves).is_empty())
	assert_true(SPECIES.table().size() >= 57)
	var utilities: Array[String] = []
	for move: String in moves.move_ids():
		if moves.slot(move) == "utility": utilities.append(move)
	assert_true(utilities.size() >= 10)
	for species: String in SPECIES.table():
		assert_true(TEACHING.learnsets().has(species), species)
		var creature := SPECIES.spawn(species)
		assert_false(str(creature.move_quick).is_empty(), species)
		assert_false(str(creature.move_charged).is_empty(), species)
		assert_false(str(creature.move_ultimate).is_empty(), species)
		var first := TEACHING.available_moves(species, 1, [])
		var fifteen := TEACHING.available_moves(species, 15, [])
		var options := 0
		for move: String in fifteen:
			if moves.slot(move) == "utility": options += 1
		assert_true(options >= 2, species)
		assert_false(first.has(TEACHING.learnsets()[species].first_utility), "utility starts at L5: " + species)
		var tier_one := TEACHING.available_moves(species, 1, [1])
		assert_true(tier_one.size() > first.size(), "breakthrough adds options: " + species)

func _loadout_before() -> Dictionary:
	var player := _player()
	player.party.members()[1].set_level(15, preload("res://scripts/creatures/progression.gd").config())
	var saved: Dictionary = player.save_data()
	saved.redesign_character = TEACHING.character_loadout_mirror(saved.party, saved.redesign_character)
	return RECORD.portable_projection(saved)

func _loadout_intent(before: Dictionary) -> Dictionary:
	return {"edit_id": "loadout-original", "expected_revision": 0, "creature_uid": before.party[1].uid,
		"quick": before.party[1].move_quick, "charged": before.party[1].move_charged, "utility": "quake_ring"}

func _loadout_context(station: String = "altar") -> Dictionary:
	var context := _context()
	context.station_kind = station
	context.source_key = "paid-station:loadout"
	return context

func test_loadout_station_ownership_and_save_recovery_use_the_existing_original() -> void:
	var before := _loadout_before()
	var immutable_before := before.duplicate(true)
	assert_true(RECORD.errors(before, CHARACTER).is_empty())
	for station: String in ["altar", "forward_camp"]:
		var context := _loadout_context(station)
		var authority := AUTHORITY.new()
		assert_true(authority.bind_world(NAMESPACE))
		assert_true(authority.seed_admitted_character(before, CHARACTER).ok)
		var original := authority.stage_character_action(CHARACTER, 0, "loadout", _loadout_intent(before), context)
		assert_true(original.ok, str(original))
		if not original.ok: continue
		assert_true(authority.finish_creature_training(original, false))
		assert_eq(authority.state(CHARACTER), before, "failed world save rolls back the whole loadout")
		original = authority.stage_character_action(CHARACTER, 0, "loadout", _loadout_intent(before), context)
		var row := DELIVERY.make_record("tm-slot", NAMESPACE, "tm-session", original, null, RECORD.errors)
		assert_false(row.is_empty())
		if row.is_empty(): continue
		var codec := preload("res://scripts/save/save_document.gd")
		var restored: Dictionary = codec.parse(codec.stringify(row))
		assert_true(DELIVERY.valid(restored, RECORD.errors, CHARACTER, NAMESPACE, "tm-slot"))
		var rejoined := AUTHORITY.new()
		assert_true(rejoined.bind_world(NAMESPACE))
		assert_true(rejoined.seed_admitted_character(before, CHARACTER).ok)
		var recovered := rejoined.recover_durable_training(CHARACTER, {restored.delivery_id: restored})
		assert_true(recovered.ok, str(recovered))
		assert_true(ESSENCE._equivalent(rejoined.state(CHARACTER), row.after))
		assert_eq(row.after.party[0], before.party[0], "other owned UID is unchanged")
		assert_eq(row.after.party[1].move_utility, "quake_ring")
		assert_eq(row.after.party[1].move_ultimate, before.party[1].move_ultimate)
		assert_eq(row.after.party[1].move_mastery_uses, before.party[1].move_mastery_uses)
		assert_eq(row.after.party[1].loadout_revision, 1)
		assert_false(rejoined.acknowledge_creature_training(CHARACTER, restored))
		var owner := DELIVERY.owner_plan(before, restored, RECORD.errors)
		assert_true(owner.ok and owner.get("requires_owner_save", false), str(owner))
		if not owner.ok: continue
		var replay := DELIVERY.owner_plan(owner.state, restored, RECORD.errors)
		assert_true(replay.ok and replay.duplicate)
		assert_true(ESSENCE._equivalent(replay.state, owner.state))
		restored.status = "accepted"
		assert_true(rejoined.acknowledge_creature_training(CHARACTER, restored))
		assert_false(rejoined.creature_training_is_pending(CHARACTER))
	for defect: String in ["field", "combat", "range", "foreign_uid", "stale_revision", "signature_edit"]:
		var context := _loadout_context()
		var intent := _loadout_intent(before)
		match defect:
			"field": context.station_kind = "workbench"
			"combat": context.in_combat = true
			"range": context.in_range = false
			"foreign_uid": intent.creature_uid = "foreign-creature"
			"stale_revision": intent.expected_revision = 1
			"signature_edit": intent.ultimate = "ultimate_ground_current"
		assert_false(ACTIONS.stage(before, 0, "loadout", intent, context, RECORD.errors).ok, defect)
	assert_eq(before, immutable_before, "planner never mutates source")

func test_each_mastery_rank_freezes_damage_and_effect_tier_without_recrediting() -> void:
	for uses: int in [0, 25, 75, 150, 300]:
		var rank := MASTERY.rank_from_uses(uses)
		assert_eq(rank, [0, 25, 75, 150, 300].find(uses) + 1)
		assert_almost_eq(MASTERY.power_multiplier(rank), 1.0 + (rank - 1) * 0.05, 0.00001)
		var effect := MASTERY.effect_tier({"size": 1.0}, rank)
		assert_eq(effect.effect_tier, rank)
		assert_true(float(effect.size) >= 1.0)
