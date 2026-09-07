extends "res://tests/test_case.gd"

const SAVE := preload("res://scripts/save/save_game.gd")
const WORKER := preload("res://scripts/save/fallback_save_worker.gd")
const FIXTURE := preload("res://tests/helpers/split_save_fixture.gd")
const ITEM_DB := preload("res://autoload/item_db.gd")
const ATOMIC_TEST := preload("res://tests/test_atomic_save_file.gd")
const GAME := preload("res://autoload/game_state.gd")

var _dir: String
var _game: RefCounted
var _saver: RefCounted
var _worker: RefCounted
var _gate: RefCounted
var _completions: Array[bool] = []
var _completion_threads: Array[bool] = []


class GateWriter:
	extends RefCounted
	var entered := Semaphore.new()
	var release := Semaphore.new()
	var inner: RefCounted
	var days: Array[int] = []
	var main_thread_writes: Array[bool] = []
	var reject := false
	func write_snapshot(request: Dictionary) -> bool:
		if days.is_empty():
			entered.post()
			release.wait()
		days.append(int(request.data.day))
		main_thread_writes.append(Thread.is_main_thread())
		return false if reject else bool(inner.write_snapshot(request))
	func release_later() -> void:
		OS.delay_msec(40)
		release.post()


class PausingWorldStore:
	extends RefCounted
	var inner: RefCounted
	var entered := Semaphore.new()
	var release := Semaphore.new()
	func path_for(id: String) -> String:
		return inner.path_for(id)
	func write(id: String, payload: Dictionary, envelope: Dictionary = {}, retained: bool = false) -> bool:
		entered.post() # Slot is committed with its recovery generation retained.
		release.wait()
		return inner.write(id, payload, envelope, retained)


func before_each() -> void:
	_dir = "user://test_fallback_worker_%s/" % Crypto.new().generate_random_bytes(12).hex_encode()
	_game = FIXTURE.game(ITEM_DB.new(), false)
	_saver = SAVE.new(_dir)
	_worker = WORKER.new()
	_gate = GateWriter.new()
	_gate.inner = SAVE.new(_dir)
	_saver._fallback = _worker
	_saver._fallback_writer = _gate
	_worker.completed.connect(_saver._on_fallback_completed)
	_saver.fallback_completed.connect(_completed)
	_completions.clear()
	_completion_threads.clear()


func after_each() -> void:
	_gate.release.post()
	_saver.finish_fallback()
	FIXTURE.wipe(_dir)


func _completed(success: bool) -> void:
	_completions.append(success)
	_completion_threads.append(Thread.is_main_thread())


func _queue(day: int) -> void:
	_game.day = day
	assert_true(_saver.request_fallback(_game, 0))


func _assert_day(day: int) -> void:
	var reader := SAVE.new(_dir)
	assert_eq(int(reader._read(0).get("day", -1)), day, "slot generation")
	assert_eq(int(reader.worlds().read("slot-0").get("day", -1)), day, "world generation")


func test_single_flight_coalesces_to_latest_snapshot_and_reports_on_main_thread() -> void:
	_queue(2)
	_gate.entered.wait()
	_queue(3)
	_queue(4)
	_game.day = 99 # Worker must not consult Game after the snapshot.
	assert_true(_saver.fallback_busy())
	assert_eq(_completions.size(), 0, "enqueue is not a completion")
	_gate.release.post()
	assert_true(_saver.finish_fallback())
	assert_eq(_gate.days, [2, 4], "intermediate request coalesced; commits ordered")
	assert_eq(_gate.main_thread_writes, [false, false])
	assert_eq(_completions, [true, true])
	assert_eq(_completion_threads, [true, true])
	assert_false(_saver.fallback_busy())
	_assert_day(4)


func test_snapshot_is_deep_read_only_and_rejects_live_objects() -> void:
	_game.farm_plots = [{"growth": [1, 2]}]
	var request: Dictionary = _saver._prepare_snapshot(_game, 0)
	_game.farm_plots[0].growth[0] = 9
	assert_eq(request.data.farm_plots[0].growth[0], 1)
	assert_true(request.is_read_only())
	assert_true(request.data.farm_plots.is_read_only())
	assert_true(request.data.farm_plots[0].is_read_only())
	assert_true(request.data.farm_plots[0].growth.is_read_only())
	_game.farm_plots = [{"live_object": _game}]
	assert_false(_saver.request_fallback(_game, 0), "live objects never reach Thread.start")
	assert_false(_saver.fallback_busy())
	assert_eq(_completions, [false])
	_game.farm_plots.clear() # Break the deliberately injected fixture cycle.


func test_async_character_failure_rolls_back_every_written_half() -> void:
	_game.day = 7
	assert_true(_saver.save(_game, 0))
	_gate.inner._characters = ATOMIC_TEST.FailingCharacterStore.new(_gate.inner.characters())
	_queue(12)
	_gate.entered.wait()
	_gate.release.post()
	assert_false(_saver.finish_fallback())
	assert_eq(_completions, [false])
	_assert_day(7)
	assert_false(FileAccess.file_exists(_saver.slot_path(0) + ".previous"))


func test_manual_save_joins_inflight_and_pending_before_its_new_generation() -> void:
	_queue(2)
	_gate.entered.wait()
	_queue(3)
	_game.day = 8
	var release_thread := Thread.new()
	assert_eq(release_thread.start(_gate.release_later), OK)
	assert_true(_saver.save(_game, 0))
	assert_false(_saver.fallback_busy(), "manual return is a durability boundary")
	release_thread.wait_to_finish()
	_saver.finish_fallback()
	assert_eq(_gate.days, [2, 3])
	_assert_day(8)


func test_character_save_joins_before_writing_new_character_state() -> void:
	_queue(2)
	_gate.entered.wait()
	_game.current_realm = "cloudreach"
	var release_thread := Thread.new()
	assert_eq(release_thread.start(_gate.release_later), OK)
	assert_true(_saver.save_character(_game, "slot-0"))
	assert_false(_saver.fallback_busy())
	release_thread.wait_to_finish()
	_saver.finish_fallback()
	assert_eq(SAVE.new(_dir).characters().read("slot-0").get("realm"), "cloudreach")


func test_game_shutdown_joins_all_accepted_fallback_requests() -> void:
	_queue(2)
	_gate.entered.wait()
	_queue(5)
	var node := GAME.new()
	node.save_system = _saver
	var release_thread := Thread.new()
	assert_eq(release_thread.start(_gate.release_later), OK)
	node._exit_tree()
	assert_false(_saver.fallback_busy())
	release_thread.wait_to_finish()
	node.free()
	_assert_day(5)


func test_poll_is_nonblocking_and_delivers_completion_once() -> void:
	_queue(2)
	_gate.entered.wait()
	_saver.poll_fallback() # A blocking poll would deadlock this test.
	assert_eq(_completions.size(), 0)
	_gate.release.post()
	var deadline := Time.get_ticks_msec() + 5000
	while _saver.fallback_busy() and Time.get_ticks_msec() < deadline:
		_saver.poll_fallback()
		OS.delay_msec(1)
	assert_false(_saver.fallback_busy())
	_saver.poll_fallback()
	assert_eq(_completions, [true])
	_assert_day(2)


func test_client_fallback_writes_only_its_character() -> void:
	_game.host = false
	_game.current_realm = "cloudreach"
	assert_true(_saver.request_fallback(_game, 0, "joined-trainer"))
	_gate.entered.wait()
	_gate.release.post()
	assert_true(_saver.finish_fallback())
	assert_false(_saver.has_slot(0))
	assert_true(_saver.worlds().list_ids().is_empty())
	assert_eq(SAVE.new(_dir).characters().read("joined-trainer").get("realm"), "cloudreach")


func test_separate_savers_cannot_interleave_split_transactions() -> void:
	var paused := PausingWorldStore.new()
	paused.inner = _gate.inner.worlds()
	_gate.inner._worlds = paused
	_queue(2)
	_gate.entered.wait()
	_gate.release.post()
	paused.entered.wait()
	var other := SAVE.new(_dir)
	_game.day = 9
	_game.current_realm = "cloudreach"
	var later: Dictionary = other._prepare_snapshot(_game, 0)
	var contender := Thread.new()
	assert_eq(contender.start(other.write_snapshot.bind(later)), OK)
	# While the first split is paused, the later transaction cannot return.
	OS.delay_msec(30)
	var serialized := contender.is_alive()
	paused.release.post()
	assert_true(_saver.finish_fallback())
	assert_true(bool(contender.wait_to_finish()))
	assert_true(serialized, "other saver must wait for all three commits")
	_assert_day(9)
	assert_eq(SAVE.new(_dir).characters().read("slot-0").get("realm"), "cloudreach")
