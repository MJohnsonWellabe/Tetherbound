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
var _submissions: Array[Dictionary] = []
var _observations: Array[Dictionary] = []
var _evidence_order: Array[String] = []


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

class ObservedGateWriter extends GateWriter:
	var observed_calls := 0
	func write_snapshot_observed(request: Dictionary) -> bool:
		observed_calls += 1
		if days.is_empty():
			entered.post()
			release.wait()
		days.append(int(request.data.day))
		main_thread_writes.append(Thread.is_main_thread())
		return false if reject else bool(inner.write_snapshot_observed(request))
	func fallback_write_receipt() -> Dictionary: return inner.fallback_write_receipt()


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
	_submissions.clear()
	_observations.clear()
	_evidence_order.clear()


func after_each() -> void:
	_gate.release.post()
	_saver.finish_fallback()
	FIXTURE.wipe(_dir)


func _completed(success: bool) -> void:
	_completions.append(success)
	_completion_threads.append(Thread.is_main_thread())
	_evidence_order.append("bool")

func _submitted(job_id: String, request: Dictionary) -> void:
	_submissions.append({"id":job_id,"request":request,"main_thread":Thread.is_main_thread()})
	_evidence_order.append("submitted:"+str(request.data.day))

func _observed(job_id: String, request: Dictionary, success: bool, receipt: Dictionary) -> void:
	_observations.append({"id":job_id,"request":request,"success":success,"receipt":receipt,
		"main_thread":Thread.is_main_thread()})
	_evidence_order.append("request:"+str(request.data.day))

func _watch_requests(observed_writer: bool = true) -> void:
	if observed_writer:
		var gate := ObservedGateWriter.new()
		gate.inner=SAVE.new(_dir)
		_gate=gate
		_saver._fallback_writer=gate
	_saver.fallback_submitted.connect(_submitted)
	_saver.fallback_request_completed.connect(_observed)

func _assert_locked_receipt(observation: Dictionary) -> void:
	var receipt: Dictionary = observation.receipt
	assert_false(receipt.is_empty(),"only a real successful locked writer supplies committed-file proof")
	if receipt.is_empty(): return
	assert_true(observation.main_thread)
	assert_true(observation.success)
	assert_true(receipt.is_read_only())
	assert_eq(receipt.source,"SaveGame_locked_fallback_write_TRUE_BOOL")
	assert_eq(receipt.writer_script,"res://scripts/save/save_game.gd")
	assert_eq(receipt.writer_instance_id,_gate.inner.get_instance_id())
	assert_eq(receipt.request_sha256,preload("res://scripts/save/save_document.gd").stringify(observation.request).sha256_text())
	for kind: String in receipt.files:
		var bytes: PackedByteArray = Marshalls.base64_to_raw(receipt.files[kind].bytes_base64)
		var hash: HashingContext = HashingContext.new()
		hash.start(HashingContext.HASH_SHA256)
		hash.update(bytes)
		assert_eq(hash.finish().hex_encode(),receipt.files[kind].sha256,"exact original written "+kind+" bytes")
		assert_eq(preload("res://scripts/save/save_document.gd").parse(bytes.get_string_from_utf8()),receipt.files[kind].payload)


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
	var character_id := str(_game.local.character_id)
	_gate.entered.wait()
	_game.current_realm = "cloudreach"
	var release_thread := Thread.new()
	assert_eq(release_thread.start(_gate.release_later), OK)
	assert_true(_saver.save_character(_game, character_id))
	assert_false(_saver.fallback_busy())
	release_thread.wait_to_finish()
	_saver.finish_fallback()
	assert_eq(SAVE.new(_dir).characters().read(character_id).get("realm"), "cloudreach")


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
	_game.local.character_id = "joined-trainer"
	var accepted: bool = _saver.request_fallback(_game, 0, "joined-trainer")
	assert_true(accepted)
	if not accepted: return # A refused request never starts the worker gate.
	_gate.entered.wait()
	_gate.release.post()
	assert_true(_saver.finish_fallback())
	assert_false(_saver.has_slot(0))
	assert_true(_saver.worlds().list_ids().is_empty())
	assert_eq(SAVE.new(_dir).characters().read("joined-trainer").get("realm"), "cloudreach")


func test_client_cannot_queue_a_fallback_for_another_character() -> void:
	_game.host = false
	_game.local.character_id = "joined-trainer"
	assert_false(_saver.request_fallback(_game, 0, "another-trainer"))
	assert_false(_saver.fallback_busy())
	assert_eq(_completions, [false])
	assert_false(_saver.characters().has("another-trainer"))
	assert_false(_saver.has_slot(0))


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
	assert_eq(SAVE.new(_dir).characters().read(str(_game.local.character_id)).get("realm"), "cloudreach")

func test_request_identity_freezes_at_submission_and_only_started_coalesced_jobs_complete() -> void:
	_watch_requests()
	_queue(2)
	_gate.entered.wait()
	_queue(3)
	_queue(4)
	_game.day=99
	assert_eq(_submissions.size(),3)
	assert_true(_submissions[0].request.is_read_only())
	assert_true(_submissions[0].request.data.is_read_only())
	assert_eq(_submissions[0].request.data.day,2)
	assert_eq(_submissions[2].request.data.day,4)
	assert_ne(_submissions[0].id,_submissions[1].id)
	assert_ne(_submissions[1].id,_submissions[2].id)
	for submitted: Dictionary in _submissions:
		assert_true(submitted.main_thread)
		assert_eq(submitted.id.length(),32)
	assert_eq(_observations.size(),0,"submission is never reported as completion")
	_gate.release.post()
	assert_true(_saver.finish_fallback())
	assert_eq(_observations.size(),2)
	if _observations.size() != 2: return
	assert_eq(_gate.days,[2,4])
	assert_eq(_completions,[true,true])
	assert_eq(_observations[0].id,_submissions[0].id)
	assert_eq(_observations[1].id,_submissions[2].id)
	assert_eq(_observations[0].request,_submissions[0].request)
	assert_eq(_observations[1].request,_submissions[2].request)
	assert_ne(_observations[1].id,_submissions[1].id,"superseded pending job has no invented completion")
	assert_eq(_evidence_order,["submitted:2","submitted:3","submitted:4","bool","request:2","bool","request:4"])
	_assert_locked_receipt(_observations[0])
	_assert_locked_receipt(_observations[1])
	assert_eq(_observations[0].receipt.files.slot.payload.day,2,"first receipt cannot borrow pending successor's current file")
	assert_eq(_observations[1].receipt.files.slot.payload.day,4)
	_assert_day(4)

func test_false_writer_BOOL_has_no_success_receipt_and_generic_BOOL_writer_stays_compatible() -> void:
	_watch_requests(false)
	_queue(2)
	_gate.entered.wait()
	_gate.release.post()
	assert_true(_saver.finish_fallback())
	assert_eq(_observations.size(),1)
	assert_true(_observations[0].success)
	assert_true(_observations[0].receipt.is_empty(),"generic BOOL callable has explicitly unavailable file receipt")
	assert_eq(_observations[0].id,_submissions[0].id)
	_gate.reject=true
	_queue(3)
	assert_false(_saver.finish_fallback())
	assert_eq(_observations.size(),2)
	assert_false(_observations[1].success)
	assert_true(_observations[1].receipt.is_empty())
	assert_eq(_observations[1].id,_submissions[1].id)
	assert_eq(_completions,[true,false])
	_assert_day(2)

func test_unwatched_fallback_preserves_original_writer_without_receipt_IO() -> void:
	var gate := ObservedGateWriter.new()
	gate.inner=SAVE.new(_dir)
	_gate=gate
	_saver._fallback_writer=gate
	_queue(2)
	_gate.entered.wait()
	_gate.release.post()
	assert_true(_saver.finish_fallback())
	assert_eq(gate.observed_calls,0)
	assert_true(gate.inner.fallback_write_receipt().is_empty())
	assert_eq(_gate.days,[2])
	assert_eq(_completions,[true])
	_assert_day(2)

func test_observed_real_split_failure_rolls_back_and_cannot_certify_a_success_receipt() -> void:
	_watch_requests()
	_game.day=7
	assert_true(_saver.save(_game,0))
	_gate.inner._characters=ATOMIC_TEST.FailingCharacterStore.new(_gate.inner._characters)
	_queue(12)
	_gate.entered.wait()
	_gate.release.post()
	assert_false(_saver.finish_fallback())
	assert_eq(_observations.size(),1)
	assert_false(_observations[0].success)
	assert_true(_observations[0].receipt.is_empty())
	assert_true(_gate.inner.fallback_write_receipt().is_empty())
	assert_eq(_observations[0].id,_submissions[0].id)
	assert_eq(_completions,[false])
	_assert_day(7)

func test_receipt_captures_full_original_primaries_before_contending_writer_can_replace_them() -> void:
	_watch_requests()
	var paused := PausingWorldStore.new()
	paused.inner=_gate.inner._worlds
	_gate.inner._worlds=paused
	_queue(2)
	_gate.entered.wait()
	_gate.release.post()
	paused.entered.wait()
	var other := SAVE.new(_dir)
	_game.day=9
	_game.current_realm="cloudreach"
	var later: Dictionary = other._prepare_snapshot(_game,0)
	var contender := Thread.new()
	assert_eq(contender.start(other.write_snapshot.bind(later)),OK)
	paused.release.post()
	assert_true(_saver.finish_fallback())
	assert_true(contender.wait_to_finish() == true)
	assert_eq(_observations.size(),1)
	if _observations.size() != 1: return
	_assert_locked_receipt(_observations[0])
	assert_eq(_observations[0].receipt.files.slot.payload.day,2)
	assert_eq(_observations[0].receipt.files.world.payload.day,2)
	assert_eq(_observations[0].receipt.files.character.payload.realm,"meadows")
	assert_eq(_observations[0].request.data.day,2)
	assert_eq(_observations[0].id,_submissions[0].id)
	_assert_day(9)
	assert_eq(SAVE.new(_dir).characters().read(str(_game.local.character_id)).get("realm"),"cloudreach")
