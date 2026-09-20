extends "res://tests/test_case.gd"

const DIRECTOR := preload("res://scripts/combat/encounter_director.gd")
const CREATURE := preload("res://scripts/creatures/creature_instance.gd")
const PARTY := preload("res://autoload/party.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const CONDITION := preload("res://scripts/creatures/creature_condition.gd")
const TOURNAMENT := preload("res://scripts/world/tournament.gd")
const ENCOUNTER_HOST := preload("res://scripts/net/encounter_host.gd")


class FakeManager extends Node:
	var fighting := false

	func is_fighting() -> bool:
		return fighting


class FailingPresentationDirector extends DIRECTOR:
	var party_override: RefCounted = null
	var body_calls := 0

	func _party() -> RefCounted:
		return party_override

	func _progression() -> RefCounted:
		return null

	func _begin_legacy_encounter_body(_encounter_id: String, _announced: Dictionary) -> bool:
		body_calls += 1
		return false


func _uid() -> String:
	return CREATURE.mint_uid()


func _party_with_five(level: int = -1) -> RefCounted:
	var party := PARTY.new()
	var actual_level := TOURNAMENT.required_level() if level < 0 else level
	for _index in 5:
		var creature: RefCounted = SPECIES.spawn("bramblebun")
		creature.call("set_level", actual_level, PROGRESSION.config())
		party.call("add", creature)
	assert_true(party.call("set_tournament_selection", [0, 1, 2]))
	return party


func _ready_selected(party: RefCounted) -> void:
	var cfg: Dictionary = CONDITION.config()
	for creature: RefCounted in party.call("tournament_selection"):
		creature.set("nourishment", float((cfg.get("nourishment", {}) as Dictionary).get("max", 100.0)))
		creature.set("happiness", float((cfg.get("happiness", {}) as Dictionary).get("max", 100.0)))
		CONDITION.note_rest_completed(creature, cfg)


func test_tournament_roster_accepts_exactly_three_unique_durable_ids() -> void:
	var director := DIRECTOR.new()
	var ids := [_uid(), _uid(), _uid()]
	assert_eq(director._valid_tournament_uid_list(ids), ids)
	assert_eq(director._valid_tournament_uid_list([ids[0], ids[0], ids[2]]), [])
	assert_eq(director._valid_tournament_uid_list([ids[0], ids[1]]), [])
	assert_eq(director._valid_tournament_uid_list([ids[0], ids[1], "terrapup"]), [])
	director.free()


func test_frozen_roster_rejects_an_outside_deployment_without_replacing_current() -> void:
	var director := DIRECTOR.new()
	director._encounter_host = ENCOUNTER_HOST.new(1)
	var record: Dictionary = director._encounter_host.open(1, "meadows", "trainer",
		{"species_id": "bramblebun", "owner_npc": "tournament_quarter_mira"})
	var encounter_id := str(record.encounter_id)
	var ids: Array[String] = [_uid(), _uid(), _uid()]
	director._freeze_tournament_roster(encounter_id, 2, ids)
	director._host_set_deployed(2, {"creature_uid": ids[0], "species_id": "terrapup",
		"shiny": false, "character_id": "guest", "card": {}})
	assert_eq(str((director._deployed_by[2] as Dictionary).creature_uid), ids[0])
	director._host_set_deployed(2, {"creature_uid": _uid(), "species_id": "terrapup",
		"shiny": false, "character_id": "guest", "card": {}})
	assert_eq(str((director._deployed_by[2] as Dictionary).creature_uid), ids[0],
		"an outside companion cannot replace the admitted deployment")
	director._encounter_host.set_phase(encounter_id, "done")
	director._host_after_encounter_change(encounter_id)
	assert_false(director._tournament_rosters_by_encounter.has(encounter_id),
		"a terminal round outside a continuing trainer battle releases its roster")
	var replacement := _uid()
	director._host_set_deployed(2, {"creature_uid": replacement, "species_id": "terrapup",
		"shiny": false, "character_id": "guest", "card": {}})
	assert_eq(str((director._deployed_by[2] as Dictionary).creature_uid), replacement,
		"a closed round must not leave a roster that blocks later deployments")
	director.free()


func test_tournament_record_detection_uses_the_authored_round_identity() -> void:
	var director := DIRECTOR.new()
	assert_true(director._record_is_tournament({"kind": "trainer",
		"opponent": {"owner_npc": "tournament_quarter_mira"}}))
	assert_false(director._record_is_tournament({"kind": "trainer",
		"opponent": {"owner_npc": "bryn_practice"}}))
	assert_false(director._record_is_tournament({"kind": "wild",
		"opponent": {"owner_npc": "tournament_quarter_mira"}}))
	director.free()


func test_join_state_refuses_uncared_or_no_longer_active_selection() -> void:
	var director := DIRECTOR.new()
	var party := _party_with_five()
	var selected: Array = party.call("tournament_selection")
	director._ally = selected[0]
	assert_false(director._tournament_join_state_valid(party, selected),
		"an uncared selection cannot be announced to a tournament host")
	_ready_selected(party)
	assert_true(director._tournament_join_state_valid(party, selected))
	director._ally = selected[1]
	assert_false(director._tournament_join_state_valid(party, selected),
		"host acceptance cannot admit a different active creature")
	director.free()


func test_admitted_body_failure_keeps_id_available_for_disengage() -> void:
	var director := FailingPresentationDirector.new()
	var party := _party_with_five()
	_ready_selected(party)
	var selected: Array = party.call("tournament_selection")
	director.party_override = party
	director._ally = selected[0]
	director._manager = FakeManager.new()
	director._pending_tournament_join_id = "host-round"
	director._pending_tournament_join_announcement = {"kind": "trainer", "phase": "active"}
	director._pending_tournament_members.assign(selected)
	assert_false(director._begin_admitted_tournament_join())
	assert_eq(director.body_calls, 1)
	assert_eq(director._pending_tournament_join_id, "host-round",
		"the failure cleanup still needs this id to send disengage")
	director._manager.free()
	director.free()


func test_admitted_response_revalidates_no_concurrent_fight() -> void:
	var director := FailingPresentationDirector.new()
	var party := _party_with_five()
	_ready_selected(party)
	var selected: Array = party.call("tournament_selection")
	director.party_override = party
	director._ally = selected[0]
	var manager := FakeManager.new()
	manager.fighting = true
	director._manager = manager
	director._pending_tournament_join_id = "host-round"
	director._pending_tournament_join_announcement = {"kind": "trainer", "phase": "active"}
	director._pending_tournament_members.assign(selected)
	assert_false(director._begin_admitted_tournament_join())
	assert_eq(director.body_calls, 0, "an acceptance cannot replace a fight started while waiting")
	assert_eq(director._pending_tournament_join_id, "host-round")
	manager.free()
	director.free()


func test_guest_loss_restore_recovers_only_the_snapshotted_three() -> void:
	var director := DIRECTOR.new()
	var party := _party_with_five()
	_ready_selected(party)
	director._tournament_members.assign(party.call("tournament_selection"))
	director._snapshot_tournament_entry_condition()
	var reserve: RefCounted = party.call("at", 4)
	reserve.set("nourishment", 13.0)
	for entrant: RefCounted in director._tournament_members:
		entrant.set("hp", 0.0)
		entrant.set("fainted", true)
		entrant.set("nourishment", 0.0)
	director._restore_tournament_entry_condition()
	for entrant: RefCounted in director._tournament_members:
		assert_false(bool(entrant.get("fainted")))
		assert_true(float(entrant.get("nourishment")) > 0.0)
	assert_eq(float(reserve.get("nourishment")), 13.0,
		"retry recovery must not touch an unregistered reserve")
	director.free()


func test_entry_milestones_still_require_all_five_to_be_trained() -> void:
	var director := FailingPresentationDirector.new()
	var party := _party_with_five(1)
	for index in 3:
		(party.call("at", index) as RefCounted).call("set_level", TOURNAMENT.required_level(),
			PROGRESSION.config())
	assert_false(director._tournament_entry_milestones_ready(party),
		"three trained entrants cannot bypass the sticky five-member achievement")
	for index in 5:
		(party.call("at", index) as RefCounted).call("set_level", TOURNAMENT.required_level(),
			PROGRESSION.config())
	assert_true(director._tournament_entry_milestones_ready(party))
	director.free()
