extends "res://tests/test_case.gd"

## F01#6a host-first install. The host stages a guest's original starter; the
## owner's installer (character_action_owner.gd) appends the guest's OWN pending
## live instance -- the follower's object, never a decoded copy -- through the
## guarded roster install (session.gd `_capture_roster_allowed`, which composes
## with F27's capture-guard projection comparison), and a failed install rolls
## back to the empty roster through the same guard (party.gd rollback=true).
## A terminal host refusal releases the choice (sequence_director.gd).

const ACTIONS := preload("res://scripts/net/foundation_actions.gd")
const STARTER := preload("res://scripts/net/starter_choice_action.gd")
const DELIVERY := preload("res://scripts/net/foundation_delivery.gd")
const RECORD := preload("res://scripts/net/character_record_rules.gd")
const OWNER := preload("res://scripts/net/character_action_owner.gd")
const PLAYER := preload("res://autoload/player_state.gd")
const PARTY := preload("res://autoload/party.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const TEACHING := preload("res://scripts/creatures/teaching.gd")
const CODEC := preload("res://scripts/save/water_capture_codec.gd")
const OPENING := preload("res://scripts/story/opening_beats.gd")
const SESSION := preload("res://scripts/net/session.gd")
const DIRECTOR := preload("res://scripts/story/sequence_director.gd")

const CHARACTER := "install-guest"


class GuardSession extends "res://scripts/net/session.gd":
	var fixture_row: Dictionary = {}
	func _owner_training_row() -> Dictionary:
		return fixture_row.duplicate(true)


class EncounterDouble extends Node:
	var dismissed := 0
	var ally: RefCounted = null
	func dismiss_active_creature() -> bool:
		dismissed += 1
		ally = null
		return true
	func ally_instance() -> RefCounted:
		return ally


class PickerDouble extends Node:
	var closed := 0
	var open := false
	func is_open() -> bool:
		return open
	func close() -> void:
		closed += 1
		open = false


func _starter() -> RefCounted:
	var creature: RefCounted = SPECIES.spawn("terrapup")
	creature.set_level(int(PROGRESSION.config().get("level", {}).get("starter_level", 3)), PROGRESSION.config())
	creature.nickname = "Bud"
	return creature


## A real staged row for `creature` against an empty admitted record.
func _row(creature: RefCounted) -> Dictionary:
	var player := PLAYER.new()
	player.configure(preload("res://autoload/item_db.gd").new())
	player.character_id = CHARACTER
	var saved: Dictionary = player.save_data()
	saved.redesign_character = TEACHING.character_loadout_mirror(saved.party, saved.redesign_character)
	var before := RECORD.portable_projection(saved)
	var context := STARTER.host_context(CHARACTER, 0, OPENING.config().get("starters", {}).get("species", []),
		int(PROGRESSION.config().get("level", {}).get("starter_level", 3)))
	context.foundation_runtime_authorized = true
	var staged := ACTIONS.stage(before, 0, "starter_choice", STARTER.intent(CODEC.encode(creature)), context, RECORD.errors)
	if staged.get("ok") != true:
		return {}
	staged.character_revision = 1
	return DELIVERY.make_record("install-slot", "install-world", "install-session", staged, null, RECORD.errors)


func test_the_installer_appends_the_very_live_instance() -> void:
	var creature := _starter()
	var row := _row(creature)
	assert_false(row.is_empty(), "the starter stages and journals")
	if row.is_empty():
		return
	var plan := OWNER._starter_plan([], row, creature)
	assert_true(plan.get("ok") == true, str(plan))
	assert_true((plan.get("capture_members", []) as Array).size() == 1 and plan.capture_members[0] == creature,
		"party[0] after install is the same object the follower pilots")


func test_the_installer_refuses_any_other_shape() -> void:
	var creature := _starter()
	var row := _row(creature)
	if row.is_empty():
		_fail("the starter row did not stage")
		return
	assert_eq(OWNER._starter_plan([], row, null).get("code"), "owner_starter_uid_changed", "no pending instance, no install")
	assert_eq(OWNER._starter_plan([], row, _starter()).get("code"), "owner_starter_uid_changed",
		"a different creature cannot stand in for the staged one")
	assert_eq(OWNER._starter_plan([_starter()], row, creature).get("code"), "owner_starter_shape_changed",
		"a starter joins only an empty roster")
	creature.set_level(int(PROGRESSION.config().get("level", {}).get("starter_level", 3)) + 4, PROGRESSION.config())
	assert_eq(OWNER._starter_plan([], row, creature).get("code"), "owner_starter_card_changed",
		"the live instance must still be the staged card")


func _guard_session(row: Dictionary, player: RefCounted, rollback: bool) -> GuardSession:
	var session := GuardSession.new()
	session.fixture_row = row
	session.set("_owner_training_install", true)
	session.set("_owner_training_install_rollback", rollback)
	session.set("_owner_training_retry", {"player": weakref(player), "world": weakref(player),
		"receipt": row.receipt, "capture_originals": [], "saved": false})
	return session


func test_the_composed_roster_guard_admits_only_the_staged_starter() -> void:
	var creature := _starter()
	var row := _row(creature)
	if row.is_empty():
		_fail("the starter row did not stage")
		return
	var player := PLAYER.new()
	var install := _guard_session(row, player, false)
	assert_true(install._capture_roster_allowed([creature], false, player),
		"the staged starter onto the empty roster, compared as the energy-free portable card")
	assert_false(install._capture_roster_allowed([_starter()], false, player), "any other creature is refused")
	assert_false(install._capture_roster_allowed([creature, _starter()], false, player), "exactly one newcomer")
	assert_false(install._capture_roster_allowed([], true, player), "a rollback call outside a rollback is refused")
	install.free()
	var rollback := _guard_session(row, player, true)
	assert_true(rollback._capture_roster_allowed([], true, player), "a failed install rolls back to the empty roster")
	assert_false(rollback._capture_roster_allowed([creature], true, player), "a rollback never keeps the newcomer")
	rollback.free()
	var crowded := row.duplicate(true)
	crowded.before.party = [CODEC.encode(_starter())]
	var refused := _guard_session(crowded, player, false)
	assert_false(refused._capture_roster_allowed([creature], false, player),
		"an original starter is never added to a non-empty roster")
	refused.free()


func test_party_rollback_reaches_the_guard_as_a_rollback() -> void:
	var party: RefCounted = PARTY.new()
	var seen: Array = []
	party.call("bind_owner_mutation_guard", func() -> bool: return false, Callable(), Callable(),
		func(members: Array, rollback: bool) -> bool:
			seen.append(rollback)
			return true)
	assert_true(party.call("install_owner_capture_roster", [], true))
	assert_true(party.call("install_owner_capture_roster", [_starter()]))
	assert_eq(seen, [true, false], "rollback=true reaches the guard; the default stays an install")
	assert_eq(party.call("size"), 1)


func test_a_terminal_host_refusal_releases_the_choice() -> void:
	var director: Node = DIRECTOR.new()
	var encounter := EncounterDouble.new()
	var picker := PickerDouble.new()
	var creature := _starter()
	encounter.ally = creature
	director.set("_encounter", encounter)
	director.set("_starter_picker", picker)
	director.set("_beat", OPENING.CHOOSE)
	director.set("_choice", 0)
	director.set("_adopting", true)
	director.set("_pending_starter_adoption", {"instance": creature, "nickname": "Bud", "character_id": CHARACTER,
		"world_instance_id": "w", "session_epoch": "e", "retry_at": 0})
	director.call("_on_starter_action_completed", "starter_choice", {"creature": {"uid": "someone-else"}},
		{"terminal_refusal": true, "code": "not_a_starter_species"})
	assert_false((director.get("_pending_starter_adoption") as Dictionary).is_empty(), "another request's refusal is not this one's")
	director.call("_on_starter_action_completed", "starter_choice", {"creature": {"uid": creature.uid}},
		{"terminal_refusal": false, "code": "awaiting_saved_decision"})
	assert_false((director.get("_pending_starter_adoption") as Dictionary).is_empty(), "a pending answer keeps waiting")
	director.call("_on_starter_action_completed", "starter_choice", {"creature": {"uid": creature.uid}},
		{"terminal_refusal": true, "code": "original_starter_already_chosen"})
	assert_true((director.get("_pending_starter_adoption") as Dictionary).is_empty(), "the refused choice is released")
	assert_eq(encounter.dismissed, 1, "no follower is left standing that nobody owns")
	assert_false(bool(director.get("_adopting")))
	assert_eq(int(director.get("_choice")), -1)
	assert_true(bool(director.get("_picker_pending")), "the picker is offered again for a fresh choice")
	encounter.free()
	picker.free()
	director.free()
