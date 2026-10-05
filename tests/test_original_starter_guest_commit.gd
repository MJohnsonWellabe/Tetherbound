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


func test_an_admitted_guest_may_write_its_own_starter() -> void:
	game.session = _client_session(true)
	assert_false(game.is_host(), "the fixture is a real client session")
	assert_true(game.original_starter_writer_ready(),
		"an admitted guest commits its own starter instead of waiting forever on a host-only gate")


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


func test_the_guest_write_is_its_own_character_file_and_never_a_world() -> void:
	game.session = AdmittedClient.new()
	game.local.character_id = GUEST
	game.relinquish_world_save_ownership()
	assert_true(game.original_starter_writer_ready())
	assert_true(bool(saver.call("save_character_prepared", game, GUEST)),
		"the starter commit's prepared write succeeds on an admitted guest")
	assert_true(saver.characters().has(GUEST), "the guest's own character file was written")
	assert_false(saver.has_slot(game.autosave_slot()), "a guest's starter commit never writes a world slot")


## --- F01#6a staged half: the guest's local commit is not the end ------------

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


func test_a_guest_is_not_finished_until_the_host_admits_the_same_receipt() -> void:
	var client := RequestingClient.new()
	game.session = client
	game.local.character_id = GUEST
	game.world.reward_delivery_namespace = "starter-world"
	var starter := _fresh_starter()
	var receipt := "starter_choice:%s:%s" % [GUEST, str(starter.get("uid"))]
	assert_false(game._original_starter_admitted(starter, receipt),
		"a guest's local commit alone leaves the opening pending")
	assert_eq(client.requests.size(), 1, "the guest asks the host to stage the same starter")
	assert_eq(client.requests[0], preload("res://scripts/save/water_capture_codec.gd").encode(starter),
		"the request carries exactly the live starter's card")
	var delivery_id := preload("res://scripts/creatures/essence.gd").training_delivery_id("starter-world", GUEST)
	game.world.reward_deliveries[delivery_id] = {"action": "starter_choice", "receipt": receipt, "status": "pending"}
	assert_false(game._original_starter_admitted(starter, receipt), "a pending host row is not yet admission")
	assert_eq(client.requests.size(), 2, "re-asking is how a lost reply recovers; the host answers from its row")
	game.world.reward_deliveries[delivery_id] = {"action": "starter_choice", "receipt": receipt, "status": "accepted"}
	assert_true(game._original_starter_admitted(starter, receipt),
		"the host's accepted row means its admitted copy holds the same receipt")
	assert_eq(client.requests.size(), 2, "an admitted starter is never re-requested")
	game.world.reward_deliveries[delivery_id] = {"action": "starter_choice", "receipt": "starter_choice:%s:other" % GUEST, "status": "accepted"}
	assert_false(game._original_starter_admitted(starter, receipt), "a different starter's receipt is not this one's admission")


func test_the_host_is_its_own_admitted_record() -> void:
	game.session = HostSession.new()
	var starter := _fresh_starter()
	assert_true(game._original_starter_admitted(starter, "starter_choice:host:%s" % str(starter.get("uid"))),
		"the host path is unchanged: no request, no wait")
