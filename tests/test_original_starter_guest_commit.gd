extends "res://tests/test_case.gd"

## F01#6a (ralph/reports/INTEGRATION/reproof/f01-current/row6/VERDICT.md §1).
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
