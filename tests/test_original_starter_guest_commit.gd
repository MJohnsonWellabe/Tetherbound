extends "res://tests/test_case.gd"

## F01#6a (ralph/reports/INTEGRATION/reproof/f01-current/row6/VERDICT.md on tb/reproof-f01 f5e2b5cb §1).
## In a two-peer opening the guest's starter never committed:
## `game_state.gd::commit_original_starter()` refused every non-host, so the
## director held `_pending_starter_adoption` forever, its opening stayed modal
## and Grandpa's catch-supply conversation could never open. The starter is a
## character fact, so the writer gate is per character: the host, or an admitted
## client writing only its own character file. A joiner whose snapshot has not
## landed still may not write.
##
## The writer gate and the character-only write are exercised on the real
## `game_state.gd`, `session.gd` and `save_game.gd`; the scene-ancestry half of
## `commit_original_starter()` needs a mounted opening and is proved by
## `smoke_net_meadows_identity_fresh_join.gd --opening-together`.

const GAME_STATE := preload("res://autoload/game_state.gd")
const SAVE_GAME := preload("res://scripts/save/save_game.gd")
const SESSION := preload("res://scripts/net/session.gd")

const TEST_DIR := "user://test_saves_original_starter_guest/"
const GUEST := "guest-starter-character"


## An admitted client with no portal or owner transaction in flight: the
## writer guards `save_game.gd` asks a live session are absent, as they are
## idle in the real run. The unmounted real `session.gd` reports a pending
## portal and would refuse for that reason alone.
class AdmittedClient extends Node:
	func is_host() -> bool:
		return false
	func client_character_save_ready() -> bool:
		return true


class HostSession extends Node:
	func is_host() -> bool:
		return true
	func client_character_save_ready() -> bool:
		return false


var game: Node = null
var saver: RefCounted = null


func before_each() -> void:
	game = GAME_STATE.new()
	saver = SAVE_GAME.new(TEST_DIR)
	game.save_system = saver
	_wipe_test_dir()


func after_each() -> void:
	if saver != null:
		saver.finish_fallback()
	if game != null:
		var session: Variant = game.get("session")
		game.session = null
		if session is Node and is_instance_valid(session):
			(session as Node).free()
		game.free()
		game = null
	_wipe_test_dir()


func _wipe_test_dir() -> void:
	for sub: String in ["", "characters/", "worlds/"]:
		var dir := DirAccess.open(TEST_DIR + sub)
		if dir == null:
			continue
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if not dir.current_is_dir():
				dir.remove(file_name)
			file_name = dir.get_next()
		dir.list_dir_end()


func _client_session(snapshot_applied: bool) -> Node:
	var session := SESSION.new()
	session.set("_mode", "client")
	(session.get("_box") as Dictionary)["handshake_snapshot_applied"] = snapshot_applied
	return session


func test_an_admitted_guest_is_ready_to_ask_for_its_starter() -> void:
	game.session = _client_session(true)
	assert_false(game.is_host(), "the fixture is a real client session")
	assert_true(game.original_starter_writer_ready(),
		"an admitted guest may ask the host for its starter instead of waiting forever on a host-only gate")


func test_a_joiner_whose_snapshot_has_not_landed_may_not_write() -> void:
	game.session = _client_session(false)
	assert_false(game.original_starter_writer_ready(),
		"a pending joiner's character file is not yet a valid save candidate")


func test_the_host_may_still_write() -> void:
	game.session = HostSession.new()
	assert_true(game.original_starter_writer_ready())


func test_no_session_or_no_saver_refuses() -> void:
	assert_false(game.original_starter_writer_ready(), "no session: the opening uses the legacy path")
	game.session = _client_session(true)
	game.save_system = null
	assert_false(game.original_starter_writer_ready(), "no saver: nothing can make the receipt durable")
	game.save_system = saver


func test_the_guest_install_save_is_its_own_character_file_and_never_a_world() -> void:
	game.session = AdmittedClient.new()
	game.local.character_id = GUEST
	game.relinquish_world_save_ownership()
	assert_true(game.original_starter_writer_ready())
	assert_true(bool(saver.call("save_character_prepared", game, GUEST)),
		"an admitted guest's prepared owner write (the starter row's install) succeeds")
	assert_true(saver.characters().has(GUEST), "the guest's own character file was written")
	assert_false(saver.has_slot(game.autosave_slot()), "a guest's starter commit never writes a world slot")


## --- F01#6a host-first: the guest asks, the host stages, the owner installs --

class RequestingClient extends Node:
	var requests: Array = []
	func is_host() -> bool:
		return false
	func client_character_save_ready() -> bool:
		return true
	func request_original_starter(card: Dictionary) -> Dictionary:
		requests.append(card.duplicate(true))
		return {"ok": false, "resolved": false, "code": "awaiting_saved_decision"}


func _fresh_starter() -> RefCounted:
	var creature: RefCounted = preload("res://scripts/creatures/creature_species.gd").spawn("terrapup")
	creature.set_level(int(preload("res://scripts/creatures/progression.gd").config().get("level", {}).get("starter_level", 3)),
		preload("res://scripts/creatures/progression.gd").config())
	return creature


func test_a_guest_asks_with_its_live_instance_and_never_writes_its_own_party() -> void:
	var client := RequestingClient.new()
	game.session = client
	game.local.character_id = GUEST
	var starter := _fresh_starter()
	assert_false(game._request_original_starter(starter, "Bud"), "a request is pending, never finished on its own")
	assert_eq(game.party.size(), 0, "the guest's party stays empty while the host stages it")
	assert_true(game.pending_original_starter_instance() == starter,
		"the installer will append this very instance, the follower's own object")
	assert_eq(str(starter.get("nickname")), "Bud")
	assert_eq(client.requests.size(), 1)
	assert_eq(client.requests[0], preload("res://scripts/save/water_capture_codec.gd").encode(starter),
		"the request carries exactly the live starter's card")
	var first: Dictionary = client.requests[0]
	starter.set("happiness", float(starter.get("happiness")) - 1.0)
	assert_false(game._request_original_starter(starter, "Bud"))
	assert_eq(client.requests.size(), 2, "re-asking is how a lost reply recovers; the host answers from its row")
	assert_eq(client.requests[1], first,
		"a retry re-sends the first request's card, so it stays the identical request the host already staged")
	assert_false(game._request_original_starter(_fresh_starter(), "Other"),
		"a second, different starter cannot replace the one in flight")
	assert_eq(client.requests.size(), 2)
	assert_true(game.cancel_original_starter_request())
	assert_eq(game.pending_original_starter_instance(), null, "a refused request releases the instance")


## Review finding (F01#6a): a terminal refusal of a RE-ask must not release a
## starter the host already journalled, or the arriving row finds no instance.
func test_a_journalled_starter_is_never_released_by_a_late_refusal() -> void:
	game.session = RequestingClient.new()
	game.local.character_id = GUEST
	game.world.reward_delivery_namespace = "starter-world"
	var starter := _fresh_starter()
	game._request_original_starter(starter, "Bud")
	var delivery_id := preload("res://scripts/creatures/essence.gd").training_delivery_id("starter-world", GUEST)
	game.world.reward_deliveries[delivery_id] = {"action": "starter_choice",
		"receipt": "starter_choice:%s:%s" % [GUEST, str(starter.get("uid"))], "status": "pending"}
	assert_false(game.cancel_original_starter_request(), "the host's row is the decision; the cancel is refused")
	assert_true(game.pending_original_starter_instance() == starter, "the installer still has the follower's own instance")
	game.world.reward_deliveries[delivery_id] = {"action": "wild_capture", "receipt": "x", "status": "accepted"}
	assert_true(game.cancel_original_starter_request(), "another action's row does not hold a starter request")


func test_a_guest_is_finished_only_when_the_host_row_reads_accepted() -> void:
	game.session = RequestingClient.new()
	game.local.character_id = GUEST
	game.world.reward_delivery_namespace = "starter-world"
	var starter := _fresh_starter()
	game._request_original_starter(starter, "Bud")
	var receipt := "starter_choice:%s:%s" % [GUEST, str(starter.get("uid"))]
	var delivery_id := preload("res://scripts/creatures/essence.gd").training_delivery_id("starter-world", GUEST)
	assert_false(game._original_starter_admitted(starter, receipt), "nothing journaled is not admission")
	game.world.reward_deliveries[delivery_id] = {"action": "starter_choice", "receipt": receipt, "status": "pending"}
	assert_false(game._original_starter_admitted(starter, receipt), "a pending host row is not yet admission")
	game.world.reward_deliveries[delivery_id] = {"action": "starter_choice", "receipt": "starter_choice:%s:other" % GUEST, "status": "accepted"}
	assert_false(game._original_starter_admitted(starter, receipt), "a different starter's receipt is not this one's admission")
	game.world.reward_deliveries[delivery_id] = {"action": "starter_choice", "receipt": receipt, "status": "accepted"}
	assert_true(game._original_starter_admitted(starter, receipt),
		"the host's accepted row means its admitted copy holds the same receipt")
	assert_eq(game.pending_original_starter_instance(), null, "an admitted starter is no longer pending")


func test_the_host_is_its_own_admitted_record() -> void:
	game.session = HostSession.new()
	var starter := _fresh_starter()
	assert_true(game._original_starter_admitted(starter, "starter_choice:host:%s" % str(starter.get("uid"))),
		"the host path is unchanged: no request, no wait")


## --- F01#6a: the picker must not reopen over an in-flight staged choice ----
##
## Live --opening-together (op6): the host's journal and accept for the guest's
## starter arrived as world deltas while the guest's beat still read `choose`;
## `restore_progression_from_game()` re-armed the picker and forgot the choice,
## the picker reopened over the finished naming and stayed open after the
## adoption landed (input context `narrative_modal`, arbiter off, Grandpa
## unreachable).

const DIRECTOR := preload("res://scripts/story/sequence_director.gd")


func test_an_adoption_is_in_flight_only_for_its_own_character_world_and_epoch() -> void:
	var pending := {"character_id": GUEST, "world_instance_id": "world-a", "session_epoch": "epoch-1"}
	assert_true(DIRECTOR.adoption_bound_to(pending, GUEST, "world-a", "epoch-1"))
	assert_false(DIRECTOR.adoption_bound_to({}, GUEST, "world-a", "epoch-1"), "nothing pending is nothing in flight")
	assert_false(DIRECTOR.adoption_bound_to(pending, "someone-else", "world-a", "epoch-1"))
	assert_false(DIRECTOR.adoption_bound_to(pending, GUEST, "world-b", "epoch-1"), "a load into another world restores normally")
	assert_false(DIRECTOR.adoption_bound_to(pending, GUEST, "world-a", "epoch-2"), "a new session restores normally")
	assert_false(DIRECTOR.adoption_bound_to(pending, "", "world-a", "epoch-1"))


func test_restores_keep_an_in_flight_choice_and_finishing_closes_the_picker() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/story/sequence_director.gd")
	assert_true(source.contains("_picker_pending = _beat == BEATS.CHOOSE and not adoption_in_flight"),
		"a world-delta restore does not re-arm the picker over an in-flight choice")
	assert_true(source.contains("_picker_pending = _beat == BEATS.CHOOSE and not _starter_adoption_in_flight()"),
		"a forced beat restore does not either")
	var finish_at := source.find("func _finish_original_starter_adoption")
	var close_at := source.find("_starter_picker.call(\"close\")", finish_at)
	assert_true(finish_at >= 0 and close_at > finish_at and close_at - finish_at < 400,
		"finishing the adoption closes any picker left standing")



## --- F01#6a: the explicit retry after the opening's bound -----------------

## A real staged and journalled `starter_choice` row for `starter`, placed
## where this guest's mirror of the host's world holds it.
func _journal_pending_row(starter: RefCounted) -> Dictionary:
	var actions := preload("res://scripts/net/foundation_actions.gd")
	var action := preload("res://scripts/net/starter_choice_action.gd")
	var record := preload("res://scripts/net/character_record_rules.gd")
	var progression := preload("res://scripts/creatures/progression.gd")
	var player := preload("res://autoload/player_state.gd").new()
	player.configure(preload("res://autoload/item_db.gd").new())
	player.character_id = GUEST
	var saved: Dictionary = player.save_data()
	saved.redesign_character = preload("res://scripts/creatures/teaching.gd").character_loadout_mirror(saved.party, saved.redesign_character)
	var context := action.host_context(GUEST, 0, preload("res://scripts/story/opening_beats.gd").config().get("starters", {}).get("species", []),
		int(progression.config().get("level", {}).get("starter_level", 3)))
	context.foundation_runtime_authorized = true
	var staged := actions.stage(record.portable_projection(saved), 0, "starter_choice",
		action.intent(preload("res://scripts/save/water_capture_codec.gd").encode(starter)), context, record.errors)
	assert_true(staged.get("ok") == true, "the fixture starter stages (%s)" % str(staged))
	staged.character_revision = 1
	var row: Dictionary = preload("res://scripts/net/foundation_delivery.gd").make_record("starter-slot", "starter-world", "starter-session", staged, null, record.errors)
	game.world.world_id = "starter-slot"
	game.world.reward_deliveries[str(row.delivery_id)] = row
	return row


func _guest_with_request() -> Array:
	var client := RequestingClient.new()
	game.session = client
	game.local.character_id = GUEST
	game.world.reward_delivery_namespace = "starter-world"
	var starter := _fresh_starter()
	game._request_original_starter(starter, "Bud")
	return [client, starter]


func test_a_retry_with_nothing_journalled_resends_the_first_card() -> void:
	var setup := _guest_with_request()
	var client: RequestingClient = setup[0]
	assert_eq(game.retry_original_starter().get("action"), "resent")
	assert_eq(client.requests.size(), 2)
	assert_eq(client.requests[1], client.requests[0], "the retry is the same request the host may already hold")


func test_a_retry_with_an_installable_pending_row_reinstalls_it() -> void:
	var setup := _guest_with_request()
	var starter: RefCounted = setup[1]
	_journal_pending_row(starter)
	starter.set("happiness", float(starter.get("happiness")) - 5.0) # passive drift the installer ignores
	assert_eq(game.retry_original_starter().get("action"), "reinstall",
		"the installer accepts the live instance, so the row is re-run, never re-adopted or re-requested")
	assert_true(game.pending_original_starter_instance() == starter, "the follower's own instance is kept")
	assert_eq(game.party.size(), 0, "the retry itself never writes the party")


func test_a_retry_offers_the_host_card_only_when_the_installer_refuses_the_follower() -> void:
	var setup := _guest_with_request()
	var starter: RefCounted = setup[1]
	var row := _journal_pending_row(starter)
	starter.set("nickname", "Changed") # a field the installer does compare
	var owner := preload("res://scripts/net/character_action_owner.gd")
	assert_eq(owner._starter_plan([], row, starter).get("code"), "owner_starter_card_changed", "the installer refuses the drifted follower")
	var outcome: Dictionary = game.retry_original_starter()
	assert_eq(outcome.get("action"), "readopt")
	var adopted: RefCounted = outcome.get("instance")
	assert_true(adopted != null and adopted != starter)
	assert_true(game.pending_original_starter_instance() == starter, "nothing changes until the opening has swapped the follower")
	assert_true(owner._starter_plan([], row, adopted).get("ok") == true, "the installer accepts the adopted instance")
	assert_true(game.adopt_original_starter_instance(adopted))
	assert_true(game.pending_original_starter_instance() == adopted, "the installer now appends the host's staged card")
	assert_false(game.adopt_original_starter_instance(_fresh_starter()), "an instance the installer would refuse is never adopted")
	assert_eq(game.party.size(), 0)


func test_an_invalid_row_is_never_adopted() -> void:
	var setup := _guest_with_request()
	var starter: RefCounted = setup[1]
	var row := _journal_pending_row(starter)
	row.after.party[0]["base_attack"] = 400.0 # a tampered mirror row
	starter.set("nickname", "Changed")
	var outcome: Dictionary = game.retry_original_starter()
	assert_true(outcome.get("action") != "readopt" and outcome.get("action") != "reinstall",
		"a row that fails owner validation is never installed or adopted; at most the request is re-sent (%s)" % str(outcome))
	assert_true(game.pending_original_starter_instance() == starter)


func test_a_late_acceptance_is_seen_without_a_resend() -> void:
	var setup := _guest_with_request()
	var client: RequestingClient = setup[0]
	var starter: RefCounted = setup[1]
	var row := _journal_pending_row(starter)
	assert_false(game.original_starter_admitted_now())
	row.status = "accepted"
	assert_true(game.original_starter_admitted_now(), "an accepted row is admission")
	assert_eq(client.requests.size(), 1, "checking sends nothing")
