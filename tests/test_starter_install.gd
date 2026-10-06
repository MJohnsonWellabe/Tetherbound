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
	var fighting := false
	func dismiss_active_creature() -> bool:
		if fighting:
			return false
		dismissed += 1
		ally = null
		return true
	func ally_instance() -> RefCounted:
		return ally
	var spawned: RefCounted = null
	func _spawn_ally_body(creature: RefCounted) -> bool:
		spawned = creature
		ally = creature
		return true


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


## --- F01#6a: a starter row that stays pending never strands the opening ---
##
## Coordinator condition 3: after `starters.admission_retry_after_seconds` the
## automatic retries stop and the player gets a clear retry; a definite host
## refusal resets to the picker (test_a_terminal_host_refusal_releases_the_choice).

class FenceSession extends Node:
	func _altar_current_epoch() -> String:
		return "e"


class FenceLocal extends RefCounted:
	var character_id := CHARACTER


class FenceWorld extends RefCounted:
	var reward_delivery_namespace := "w"


class RetryGame extends Node:
	var session := FenceSession.new()
	var local := FenceLocal.new()
	var world := FenceWorld.new()
	var committed := true
	var commits := 0
	func commit_original_starter(_source: Node, _instance: RefCounted, _nickname: String) -> bool:
		commits += 1
		return committed
	func _notification(what: int) -> void:
		if what == NOTIFICATION_PREDELETE and is_instance_valid(session):
			session.free()
	var outcome: Dictionary = {"action": "resent"}
	var retries := 0
	var messages: Array = []
	var host := false
	var admitted := false
	var adopted: RefCounted = null
	func is_host() -> bool:
		return host
	func original_starter_admitted_now() -> bool:
		return admitted
	func adopt_original_starter_instance(instance: RefCounted) -> bool:
		adopted = instance
		return true
	func retry_original_starter() -> Dictionary:
		retries += 1
		return outcome
	func push_world_message(text: String) -> void:
		messages.append(text)


class GameSeamDirector extends "res://scripts/story/sequence_director.gd":
	var test_game: Node = null
	var finished := ""
	func _effect_game() -> Node:
		return test_game
	func _finish_original_starter_adoption(chosen: String, _typed: bool) -> void:
		finished = chosen
		_adopting = false


func _stalled_director(encounter: EncounterDouble, creature: RefCounted) -> Node:
	var director: Node = GameSeamDirector.new()
	director.set("_encounter", encounter)
	director.set("_beat", OPENING.CHOOSE)
	director.set("_adopting", true)
	var bound_ms := int(1000.0 * float(OPENING.config().get("starters", {}).get("admission_retry_after_seconds", 45.0)))
	director.set("_pending_starter_adoption", {"instance": creature, "nickname": "Bud", "character_id": CHARACTER,
		"world_instance_id": "w", "session_epoch": "e", "retry_at": 0,
		"started_ms": Time.get_ticks_msec() - bound_ms - 1000, "notice_at": 0})
	return director


func test_the_wait_is_bounded_and_then_offers_a_clear_retry() -> void:
	var bound := float(OPENING.config().get("starters", {}).get("admission_retry_after_seconds", 0.0))
	assert_true(bound > 0.0, "the bound is a configured tunable (opening.json)")
	var encounter := EncounterDouble.new()
	var creature := _starter()
	encounter.ally = creature
	var director := _stalled_director(encounter, creature)
	var game := RetryGame.new()
	director.set("test_game", game)
	assert_false(bool(director.call("starter_adoption_stalled")))
	director.call("_retry_original_starter_save")
	assert_true(bool(director.call("starter_adoption_stalled")), "past the bound the automatic retries stop")
	assert_false((director.get("_pending_starter_adoption") as Dictionary).is_empty(),
		"the choice is kept: nothing was refused, so nothing is released")
	assert_eq(encounter.dismissed, 0, "the follower stays while the player decides to retry")
	game.free()
	encounter.free()
	director.free()


func test_the_retry_rearms_the_wait_and_asks_again() -> void:
	var encounter := EncounterDouble.new()
	var creature := _starter()
	encounter.ally = creature
	var director := _stalled_director(encounter, creature)
	var game := RetryGame.new()
	director.set("test_game", game)
	director.call("_retry_original_starter_save")
	assert_true(bool(director.call("starter_adoption_stalled")))
	assert_true(game.messages.size() == 1 and str(game.messages[0]).contains("Interact"),
		"the player is told plainly that Interact asks again (%s)" % str(game.messages))
	await director.call("retry_starter_adoption")
	assert_false(bool(director.call("starter_adoption_stalled")), "the retry re-arms the bounded wait")
	assert_eq(game.retries, 1, "the game is asked to resend, reinstall or re-adopt")
	assert_true(game.messages.size() == 2, "the player is told it is asking again")
	var pending: Dictionary = director.get("_pending_starter_adoption")
	assert_true(Time.get_ticks_msec() - int(pending.started_ms) < 2000, "a fresh bound starts now")
	game.free()
	encounter.free()
	director.free()


func test_a_readopted_card_replaces_the_follower() -> void:
	var encounter := EncounterDouble.new()
	var creature := _starter()
	encounter.ally = creature
	var director := _stalled_director(encounter, creature)
	var game := RetryGame.new()
	var staged := _starter()
	game.outcome = {"action": "readopt", "instance": staged}
	director.set("test_game", game)
	director.call("_retry_original_starter_save")
	await director.call("retry_starter_adoption")
	assert_true((director.get("_pending_starter_adoption") as Dictionary).instance == staged,
		"the pending choice is now the host's staged card")
	assert_eq(encounter.dismissed, 1, "the stale follower is dismissed")
	assert_true(encounter.spawned == staged, "the follower is rebuilt from the instance the installer will append")
	assert_true(game.adopted == staged, "the game confirms the adopted instance only after the new body exists")
	game.free()
	encounter.free()
	director.free()


func test_the_host_never_stalls() -> void:
	var encounter := EncounterDouble.new()
	var creature := _starter()
	encounter.ally = creature
	var director := _stalled_director(encounter, creature)
	var game := RetryGame.new()
	game.host = true
	director.set("test_game", game)
	director.call("_retry_original_starter_save")
	assert_false(bool(director.call("starter_adoption_stalled")), "the host keeps retrying its own local save")
	game.free()
	encounter.free()
	director.free()


func test_a_late_acceptance_finishes_a_stalled_wait() -> void:
	var encounter := EncounterDouble.new()
	var creature := _starter()
	encounter.ally = creature
	var director := _stalled_director(encounter, creature)
	var game := RetryGame.new()
	director.set("test_game", game)
	director.call("_retry_original_starter_save")
	assert_true(bool(director.call("starter_adoption_stalled")))
	game.admitted = true
	director.call("_retry_original_starter_save")
	assert_eq(str(director.get("finished")), "Bud", "the host's late accept finishes the adoption without a press")
	assert_true((director.get("_pending_starter_adoption") as Dictionary).is_empty())
	assert_eq(game.retries, 0, "nothing was re-sent")
	assert_eq(game.commits, 1, "it finished through the ordinary commit check")
	game.free()
	encounter.free()
	director.free()


func test_a_readopt_waits_while_the_follower_is_fighting() -> void:
	var encounter := EncounterDouble.new()
	var creature := _starter()
	encounter.ally = creature
	encounter.fighting = true
	var director := _stalled_director(encounter, creature)
	var game := RetryGame.new()
	game.outcome = {"action": "readopt", "instance": _starter()}
	director.set("test_game", game)
	director.call("_retry_original_starter_save")
	await director.call("retry_starter_adoption")
	assert_true(encounter.spawned == null, "no second body is spawned while the first cannot be put away")
	assert_true(game.adopted == null, "the pending instance is unchanged")
	assert_true(bool(director.call("starter_adoption_stalled")), "the player can retry once the fight is over")
	game.free()
	encounter.free()
	director.free()


func test_a_stalled_accept_without_the_local_install_keeps_waiting() -> void:
	var encounter := EncounterDouble.new()
	var creature := _starter()
	encounter.ally = creature
	var director := _stalled_director(encounter, creature)
	var game := RetryGame.new()
	director.set("test_game", game)
	director.call("_retry_original_starter_save")
	game.admitted = true
	game.committed = false # the mirror row reads accepted, but this owner has not saved it
	director.call("_retry_original_starter_save")
	assert_eq(str(director.get("finished")), "", "an accepted mirror row alone never finishes an empty party")
	assert_true(bool(director.call("starter_adoption_stalled")))
	director.call("_retry_original_starter_save")
	assert_eq(game.commits, 1, "the check is rate-limited, never a request every frame")
	game.free()
	encounter.free()
	director.free()
