extends "res://tests/test_case.gd"

## Detached fixtures; these do not establish actual encounter/runtime proof.
const LOG := preload("res://scripts/creatures/research_log.gd")
const STATE := preload("res://scripts/data/redesign_state.gd")
const RULES := preload("res://scripts/world/death_satchel_rules.gd")
const RECORD := preload("res://scripts/net/character_record_rules.gd")
const ACTIONS := preload("res://scripts/net/character_action_rules.gd")
const DELIVERY := preload("res://scripts/net/character_action_delivery.gd")
const AUTHORITY := preload("res://scripts/net/character_authority.gd")

func _record(character: String = "character-f45-a") -> Dictionary:
	return {"character_id": character, "party": [], "redesign_character": STATE.defaults("character"),
		"inventory": RULES.slots(RULES.inventory_from([])), "portal_escrow": {}, "vitals_escrow": {},
		"equipment": RECORD.empty_equipment(), "realm_hearts": {"active_id": ""}}

func _context(current: Dictionary, revision: int, kind: String, event: String, species: String = "bramblebun") -> Dictionary:
	return {"character_id": current.character_id, "expected_revision": revision, "in_range": true,
		"source_key": "encounter:fixture-1", "world_namespace": "world-f45", "session_id": "session-f45",
		"event_confirmed": true, "event_id": event, "participants": [current.character_id], "species_id": species,
		"kind": kind, "opponent_defeated": kind == "defeat", "move_id": LOG.catalogue()[species].moves.charged,
		"wild": true, "night": true}

func test_every_registered_species_tasks_types_and_no_unknown_catalog_ids() -> void:
	var cfg := LOG.config()
	assert_false(cfg.is_empty())
	assert_eq(LOG.configuration_errors(cfg), [])
	assert_eq(cfg.species.size(), LOG.catalogue().size())
	for id: String in LOG.catalogue():
		assert_true(cfg.species.has(id))
		assert_true(cfg.species[id].tasks.size() >= 3)
		for task: Dictionary in cfg.species[id].tasks:
			assert_false(LOG.reward(id, task).is_empty())
	var broken := cfg.duplicate(true)
	broken.species.erase("terrapup")
	assert_false(LOG.configuration_errors(broken).is_empty())
	broken = cfg.duplicate(true)
	broken.species.bramblebun.tasks[1].move = "invented_move"
	assert_false(LOG.configuration_errors(broken).is_empty())

func test_personal_replay_progress_released_and_never_owned_serialization() -> void:
	var current := _record()
	var first := ACTIONS.stage(current, 0, "research_event", {}, _context(current, 0, "defeat", "event-1"), RECORD.errors)
	assert_true(first.get("ok") == true)
	if first.get("ok") != true: return
	assert_true(preload("res://scripts/creatures/essence.gd")._equivalent(current.redesign_character.research, LOG.empty_log()))
	assert_eq(first.state.party, [])
	var restored: Dictionary = JSON.parse_string(JSON.stringify(first.state))
	assert_eq(STATE.validate("character", restored.redesign_character), [])
	assert_eq(LOG.view(restored.redesign_character, restored.character_id, "meadows").ready, true)
	assert_eq(ACTIONS.stage(restored, 1, "research_event", {}, _context(restored, 1, "defeat", "event-1"), RECORD.errors).code, "reconcile_original_decision")
	var second := ACTIONS.stage(restored, 1, "research_event", {}, _context(restored, 1, "defeat", "event-2"), RECORD.errors)
	assert_true(second.ok)
	assert_eq(second.state.redesign_character.research.species.bramblebun.tasks.defeats, 2)
	var other := _record("character-f45-b")
	var wrong := _context(other, 0, "defeat", "event-1")
	wrong.participants = [current.character_id]
	assert_false(ACTIONS.stage(other, 0, "research_event", {}, wrong, RECORD.errors).ok)
	assert_false(ACTIONS.stage(current, 0, "research_event", {"progress": 99}, _context(current, 0, "defeat", "event-1"), RECORD.errors).ok)
	var legacy := _record()
	legacy.redesign_character.erase("research")
	assert_eq(STATE.validate("character", legacy.redesign_character), [])
	assert_true(LOG.view(legacy.redesign_character, legacy.character_id, "meadows").ready)

func test_claim_atomic_capacity_replay_and_existing_journal_owner_plan() -> void:
	var current := _record()
	var earned := ACTIONS.stage(current, 0, "research_event", {}, _context(current, 0, "sight", "event-sight"), RECORD.errors)
	assert_true(earned.ok)
	if not earned.ok: return
	current = earned.state
	var claim := {"species_id": "bramblebun", "task_id": "sight"}
	var context := {"character_id": current.character_id, "expected_revision": 1, "in_range": true, "source_key": "research_journal"}
	var proposal := ACTIONS.stage(current, 1, "research_claim", claim, context, RECORD.errors)
	assert_true(proposal.ok)
	if not proposal.ok: return
	assert_eq(RULES.inventory_from(current.inventory).count("essence_ground"), 0)
	assert_eq(RULES.inventory_from(proposal.state.inventory).count("essence_ground"), 5)
	assert_true(proposal.state.redesign_character.research_receipts.has("research:bramblebun:sight:" + current.character_id))
	context.expected_revision = 2
	assert_false(ACTIONS.stage(proposal.state, 2, "research_claim", claim, context, RECORD.errors).ok)
	var full := current.duplicate(true)
	for index: int in full.inventory.size(): full.inventory[index] = {"id": "wood", "n": RULES.db().stack_size("wood")}
	context.expected_revision = 1
	assert_eq(ACTIONS.stage(full, 1, "research_claim", claim, context, RECORD.errors).code, "reward_inventory_full")
	assert_eq(full.redesign_character.research_receipts, [])
	proposal.character_revision = 2
	var row := DELIVERY.make_record("world-id-f45", "world-f45", "session-f45", proposal, null, RECORD.errors)
	assert_false(row.is_empty())
	if row.is_empty(): return
	assert_true(DELIVERY.owner_plan(current, row, RECORD.errors).ok)
	assert_true(DELIVERY.owner_plan(proposal.state, row, RECORD.errors).duplicate)
	row.after.inventory[0] = {"id": "essence_ground", "n": 999}
	assert_false(DELIVERY.valid(row, RECORD.errors))
	var registry := AUTHORITY.new()
	assert_true(registry.bind_world("world-f45"))
	assert_true(registry.seed_admitted_character(current, current.character_id).ok)
	context.expected_revision = 0
	var pending := registry.stage_character_action(current.character_id, 0, "research_claim", claim, context)
	assert_true(pending.ok)
	if pending.ok:
		assert_true(registry.finish_creature_training(pending, false))
		assert_eq(registry.state(current.character_id), current)


func test_character_file_reload_preserves_unowned_history_paid_reward_and_replay_refusal() -> void:
	var current := _record()
	var earned := ACTIONS.stage(current, 0, "research_event", {},
		_context(current, 0, "sight", "persisted-sight"), RECORD.errors)
	assert_true(earned.get("ok") == true)
	if earned.get("ok") != true: return
	var claim := {"species_id": "bramblebun", "task_id": "sight"}
	var context := {"character_id": current.character_id, "expected_revision": 1,
		"in_range": true, "source_key": "research_journal"}
	var paid := ACTIONS.stage(earned.state, 1, "research_claim", claim, context, RECORD.errors)
	assert_true(paid.get("ok") == true)
	if paid.get("ok") != true: return
	var player := preload("res://autoload/player_state.gd").new()
	var items := preload("res://autoload/item_db.gd").new()
	player.configure(items)
	player.character_id = current.character_id
	player.redesign_character = paid.state.redesign_character.duplicate(true)
	player.inventory = RULES.inventory_from(paid.state.inventory)
	var store := preload("res://scripts/save/character_save.gd").new("user://test_f45_research/")
	store.delete(player.character_id)
	assert_true(store.write(player.character_id, player.save_data()), "real atomic character writer succeeds")
	var restored := preload("res://autoload/player_state.gd").new()
	restored.configure(items)
	restored.character_id = player.character_id
	restored.load_data(store.state(player.character_id))
	assert_eq(restored.party.size(), 0, "never-owned research needs no creature slot after file reload")
	assert_eq(restored.redesign_character.research, paid.state.redesign_character.research)
	assert_eq(restored.redesign_character.research_receipts, paid.state.redesign_character.research_receipts)
	assert_eq(restored.inventory.count("essence_ground"), 5)
	var view := LOG.view(restored.redesign_character, restored.character_id, "meadows")
	var row: Dictionary = {}
	for species: Dictionary in view.species:
		if species.species_id == "bramblebun": row = species
	assert_true(row.get("seen") == true and row.get("caught") == false)
	assert_eq(row.tasks[0].progress, 1)
	assert_true(row.tasks[0].paid)
	context.expected_revision = 2
	var replay := ACTIONS.stage(restored.save_data(), 2, "research_claim", claim, context, RECORD.errors)
	assert_false(replay.get("ok") == true, "persisted receipt cannot pay again")
	assert_eq(restored.inventory.count("essence_ground"), 5)
	var other := _record("character-f45-b")
	assert_true(preload("res://scripts/creatures/essence.gd")._equivalent(other.redesign_character.research, LOG.empty_log()), "another character inherits no research")
	assert_true(store.delete(player.character_id))

func test_cast_signature_catch_history_and_unconfirmed_events_refuse() -> void:
	var current := _record()
	var context := _context(current, 0, "cast", "cast-1", "terrapup")
	var cast := ACTIONS.stage(current, 0, "research_event", {}, context, RECORD.errors)
	assert_true(cast.ok)
	if not cast.ok: return
	assert_eq(cast.state.redesign_character.research.species.terrapup.tasks.signature, 1)
	assert_eq(cast.state.redesign_character.research.species.terrapup.tasks.casts, 1)
	var forged := context.duplicate(true)
	forged.move_id = "invented_cast"
	assert_false(ACTIONS.stage(current, 0, "research_event", {}, forged, RECORD.errors).ok)
	forged = context.duplicate(true)
	forged.event_confirmed = false
	assert_false(ACTIONS.stage(current, 0, "research_event", {}, forged, RECORD.errors).ok)
	context = _context(current, 0, "catch", "catch-1")
	var caught := ACTIONS.stage(current, 0, "research_event", {}, context, RECORD.errors)
	assert_true(caught.ok)
	if not caught.ok: return
	assert_true(caught.state.redesign_character.research.species.bramblebun.caught)
	# No party membership is required, and release cannot infer or delete facts.
	assert_eq(caught.state.party, [])
	context.wild = false
	assert_false(ACTIONS.stage(current, 0, "research_event", {}, context, RECORD.errors).ok)

func test_all_tasks_complete_biome_title_and_no_combat_reward() -> void:
	var current := _record()
	var cfg := LOG.config()
	var log := LOG.empty_log()
	for id: String in cfg.species:
		if cfg.species[id].biome != "meadows": continue
		var tasks := {}
		for task: Dictionary in cfg.species[id].tasks: tasks[task.id] = int(task.required)
		log.species[id] = {"seen": true, "caught": false, "tasks": tasks}
	# The final actual event proposal earns the title; fixture prior progress
	# is disclosed and never offered as a player-path witness.
	log.species.bramblebun.tasks.defeats = 2
	current.redesign_character.research = log
	assert_true(LOG.completion(log, "meadows", cfg) < 100)
	var final := ACTIONS.stage(current, 0, "research_event", {}, _context(current, 0, "defeat", "event-final"), RECORD.errors)
	assert_true(final.ok)
	if not final.ok: return
	assert_eq(LOG.completion(final.state.redesign_character.research, "meadows", cfg), 100)
	assert_eq(LOG.view(final.state.redesign_character, final.state.character_id, "meadows").title, "Meadows Naturalist")
	assert_eq(final.state.inventory, current.inventory)
	assert_eq(final.state.party, current.party)
	assert_eq(final.state.redesign_character.research_receipts, [])
