extends "res://tests/test_case.gd"

## Actual Altar service, panel controls, canonical read-only price planner and
## Session reply correlation. Physical station and quote-send/spend boundaries
## are doubles; no ENet, earned level, disk write or saved ACK is claimed.
const SERVICE := preload("res://scripts/ui/altar_service.gd")
const PANEL := preload("res://scripts/ui/altar_panel.gd")
const DATA := preload("res://tests/test_foundation_resources.gd")
const RECORD := preload("res://scripts/net/character_record_rules.gd")
const ESSENCE := preload("res://scripts/creatures/essence.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const STATION := "altar:meadows:quote-fixture"
const NATIVE_CASES := [
	"host_quote_uses_three_arguments_and_builds_actual_payment_without_mutating_owner",
	"guest_quote_rebuilds_from_correlated_actual_session_reply_once",
	"quote_rejects_wrong_id_key_uid_source_and_session_transport_scope",
	"inline_quote_signal_is_not_overwritten_by_pending_return",
	"malformed_correlated_quote_never_enables_payment",
	"quote_rejects_same_session_new_epoch_or_changed_character_world_context",
	"closed_reopened_or_reselected_panel_rejects_previous_quote",
	"spend_keeps_original_five_fields_and_requests_fresh_quote_after_terminal_result",
]
const NATIVE_ASSERTIONS := [12, 11, 12, 7, 18, 48, 29, 20]
var _fixture_tree: SceneTree

class FixtureGame extends Node:
	var local: RefCounted
	var world: RefCounted
	var session: Node

class FixtureSession extends "res://scripts/net/session.gd":
	var fixture: Node
	var fixture_host := true
	var epoch := "a".repeat(32)
	var station := true
	var quote_record: Dictionary = {}
	var quote_revision := 7
	var inline_quote_reply := false
	var sent_quotes: Array[Dictionary] = []
	var spent: Dictionary = {}
	func _ready() -> void: pass # No physical transport or realm is started.
	func _game() -> Node: return fixture
	func is_host() -> bool: return fixture_host
	func _altar_current_epoch() -> String: return epoch
	func _local_character_id() -> String: return fixture.local.character_id
	func altar_station_available(_key: String) -> bool: return station
	func quote_altar_essence_spend(key: String, uid: String, quote_id: String) -> Dictionary:
		# Exactly the shipping three-argument contract. Only network send is
		# replaced; the guest's receiver below is the actual Session method.
		var envelope := _altar_envelope("altar_quote", key)
		envelope["owned_uid"] = uid
		envelope["quote_id"] = quote_id
		_altar_quote_request = envelope.duplicate(true)
		sent_quotes.append(envelope.duplicate(true))
		if inline_quote_reply:
			altar_essence_quote_completed.emit(key, uid, quote_id, price(uid))
			return {"ok": false, "pending": true, "code": "quote_pending"}
		return price(uid) if fixture_host else {"ok": false, "pending": true, "code": "quote_pending"}
	func price(uid: String) -> Dictionary:
		return ESSENCE.quote_spend(quote_record, fixture.local.character_id, uid,
			quote_revision, ESSENCE.config(), PROGRESSION.config())
	func deliver(envelope: Dictionary, result: Dictionary) -> void:
		_rpc_altar_quote_result(envelope, result)
	func submit_altar_essence_spend(key: String, intent: Dictionary) -> Dictionary:
		spent = {"station_key": key, "intent": intent.duplicate(true)}
		return {"ok": false, "resolved": false, "code": "fixture_no_write"}
	func reconcile_altar_essence_spend(_key: String, _intent: Dictionary) -> Dictionary:
		return {"ok": false, "resolved": false, "code": "fixture_no_write"}

class FixturePanel extends "res://scripts/ui/altar_panel.gd":
	var fixture_party: RefCounted
	var rebuilds := 0
	func _party() -> RefCounted: return fixture_party
	func _rebuild(prefer_payment: bool = false) -> void:
		rebuilds += 1
		super._rebuild(prefer_payment)

func _fixture(host: bool = true, two_creatures: bool = false) -> Dictionary:
	var game := FixtureGame.new()
	game.local = DATA.new()._player()
	game.world = DATA.new()._world()
	var first: RefCounted = game.local.party.at(0)
	first.set("level", 9)
	first.call("_apply_level_stats", PROGRESSION.config())
	game.local.inventory.add("essence_ground", 100)
	if two_creatures:
		game.local.party.add(preload("res://scripts/creatures/creature_species.gd").spawn("terrapup"))
	var session := FixtureSession.new()
	session.fixture_host = host
	session.fixture = game
	game.session = session
	session.quote_record = RECORD.portable_projection(game.local.save_data())
	assert_eq(RECORD.errors(session.quote_record, DATA.CHARACTER), [], "quote starts from a canonical retained owner")
	var holder := Node.new()
	holder.name = "AltarQuoteFixture_" + Crypto.new().generate_random_bytes(8).hex_encode()
	_fixture_tree.root.add_child(holder)
	holder.add_child(session)
	holder.add_child(game)
	var service := SERVICE.new()
	service.set("_game", game)
	game.add_child(service)
	var panel := FixturePanel.new()
	panel.fixture_party = game.local.party
	service.add_child(panel)
	service.set("_panel", panel)
	assert_true(panel.configure_service(service))
	return {"holder": holder, "game": game, "session": session, "service": service,
		"panel": panel, "uid": str(first.uid)}

func _free_fixture(f: Dictionary) -> void:
	f.holder.free()

func _buttons(root: Node, label: String, enabled_only: bool = true) -> Array[Button]:
	var found: Array[Button] = []
	if root is Button and root.is_visible_in_tree() and root.text == label and (not enabled_only or not root.disabled): found.append(root)
	for child: Node in root.get_children(): found.append_array(_buttons(child, label, enabled_only))
	return found

func _has_ground_payment(f: Dictionary) -> bool:
	return _buttons(f.panel, "Ground Essence · Cost 20 · Have 100").size() == 1

func _case_host_quote_uses_three_arguments_and_builds_actual_payment_without_mutating_owner() -> void:
	var f := _fixture()
	var before := var_to_bytes(f.session.quote_record)
	assert_true(f.service.open(STATION))
	assert_eq(f.session.sent_quotes.size(), 1)
	var request: Dictionary = f.session.sent_quotes[0]
	assert_true(f.session._altar_hex_id(request.quote_id))
	assert_eq(request.owned_uid, f.uid)
	assert_eq(request.station_key, STATION)
	assert_true(_has_ground_payment(f), "the shipping panel must expose the real quoted price")
	assert_eq(f.panel._quote.expected_character_revision, 7)
	assert_true(f.service._quote_pending.is_empty(), "a synchronous quote is consumed, not cached")
	assert_eq(var_to_bytes(f.session.quote_record), before)
	assert_true(f.game.world.reward_deliveries.is_empty())
	_free_fixture(f)

func _case_guest_quote_rebuilds_from_correlated_actual_session_reply_once() -> void:
	var f := _fixture(false)
	assert_true(f.service.open(STATION))
	assert_false(_has_ground_payment(f))
	var request: Dictionary = f.session.sent_quotes[0]
	var quote: Dictionary = f.session.price(f.uid)
	assert_true(quote.get("ok") == true, str(quote))
	var rebuilds: int = f.panel.rebuilds
	f.session.deliver(request, quote)
	assert_true(_has_ground_payment(f))
	assert_eq(f.panel.rebuilds, rebuilds + 1)
	assert_eq(f.panel._quote, quote)
	assert_true(f.service._quote_pending.is_empty())
	f.session.altar_essence_quote_completed.emit(STATION, f.uid, request.quote_id, quote)
	assert_eq(f.panel.rebuilds, rebuilds + 1, "consumed replies cannot apply twice")
	assert_true(f.game.world.reward_deliveries.is_empty())
	_free_fixture(f)

func _case_quote_rejects_wrong_id_key_uid_source_and_session_transport_scope() -> void:
	var f := _fixture(false)
	assert_true(f.service.open(STATION))
	var request: Dictionary = f.session.sent_quotes[0]
	var quote: Dictionary = f.session.price(f.uid)
	var rebuilds: int = f.panel.rebuilds
	for field: String in ["quote_id", "station_key", "owned_uid", "session_epoch", "character_id", "world_namespace"]:
		var forged := request.duplicate(true)
		forged[field] = "b".repeat(32) if field in ["quote_id", "session_epoch"] else "foreign"
		f.session.deliver(forged, quote)
		assert_eq(f.panel.rebuilds, rebuilds, field + " must fail Session correlation")
	f.session.altar_essence_quote_completed.emit(STATION, f.uid, "b".repeat(32), quote)
	f.session.altar_essence_quote_completed.emit("foreign", f.uid, request.quote_id, quote)
	f.session.altar_essence_quote_completed.emit(STATION, "foreign", request.quote_id, quote)
	var other := FixtureSession.new()
	f.service._on_session_quote_completed(STATION, f.uid, request.quote_id, quote, other)
	other.free()
	assert_eq(f.panel.rebuilds, rebuilds, "the UI bridge independently checks its exact correlation")
	assert_false(_has_ground_payment(f))
	f.session.deliver(request, quote)
	assert_true(_has_ground_payment(f), "refused foreign replies do not consume the current original")
	_free_fixture(f)

func _case_inline_quote_signal_is_not_overwritten_by_pending_return() -> void:
	var f := _fixture(false)
	f.session.inline_quote_reply = true
	assert_true(f.service.open(STATION))
	assert_true(_has_ground_payment(f))
	assert_eq(f.panel._quote.expected_character_revision, 7)
	assert_false(f.panel._quote_waiting)
	assert_true(f.service._quote_pending.is_empty())
	_free_fixture(f)

func _case_malformed_correlated_quote_never_enables_payment() -> void:
	var f := _fixture(false)
	assert_true(f.service.open(STATION))
	for defect: String in ["creature", "level", "revision", "payment", "duplicate_payment"]:
		if defect != "creature": f.panel._refresh_quote()
		var request: Dictionary = f.session.sent_quotes.back()
		var quote: Dictionary = f.session.price(f.uid)
		match defect:
			"creature": quote.creature_uid = "foreign"
			"level": quote.level = 61
			"revision": quote.expected_character_revision = -1
			"payment": quote.payments[0].cost = 0
			"duplicate_payment": quote.payments.append(quote.payments[0].duplicate(true))
		f.session.deliver(request, quote)
		assert_true(f.panel._quote.is_empty(), defect)
		assert_false(_has_ground_payment(f), defect)
		assert_true(f.session.spent.is_empty())
	_free_fixture(f)

func _case_quote_rejects_same_session_new_epoch_or_changed_character_world_context() -> void:
	for field: String in ["epoch", "character", "world", "namespace", "local_object", "world_object", "session_object", "station"]:
		var f := _fixture(false)
		assert_true(f.service.open(STATION))
		var request: Dictionary = f.session.sent_quotes[0]
		var quote: Dictionary = f.session.price(f.uid)
		var rebuilds: int = f.panel.rebuilds
		var replacement: Node = null
		match field:
			"epoch": f.session.epoch = "b".repeat(32)
			"character": f.game.local.character_id = "other-owner"
			"world": f.game.world.world_id = "other-slot"
			"namespace": f.game.world.reward_delivery_namespace = "other-namespace"
			"local_object": f.game.local = DATA.new()._player()
			"world_object": f.game.world = DATA.new()._world()
			"session_object":
				replacement = FixtureSession.new()
				f.game.session = replacement
			"station": f.session.station = false
		# Model even a wrongly forwarded signal: UI fences supplement Session.
		f.session.altar_essence_quote_completed.emit(STATION, f.uid, request.quote_id, quote)
		assert_eq(f.panel.rebuilds, rebuilds, field)
		assert_true(f.panel._quote.is_empty(), field)
		assert_true(f.service._quote_pending.is_empty(), field + " invalidates the candidate")
		if replacement != null: replacement.free()
		_free_fixture(f)

func _case_closed_reopened_or_reselected_panel_rejects_previous_quote() -> void:
	for change: String in ["close", "reopen", "same_selection", "other_selection"]:
		var f := _fixture(false, true)
		assert_true(f.service.open(STATION))
		var original: Dictionary = f.session.sent_quotes[0]
		var quote: Dictionary = f.session.price(f.uid)
		if change in ["close", "reopen"]:
			f.panel.close()
			assert_true(f.service._quote_pending.is_empty())
			if change == "reopen":
				f.panel._process(0.0)
				assert_true(f.service.open(STATION))
		else:
			f.panel._select_creature(f.uid if change == "same_selection" else str(f.game.local.party.at(1).uid))
		var rebuilds: int = f.panel.rebuilds
		f.session.altar_essence_quote_completed.emit(STATION, f.uid, original.quote_id, quote)
		assert_eq(f.panel.rebuilds, rebuilds, change)
		assert_true(f.panel._quote.is_empty(), change)
		if change != "close":
			var current: Dictionary = f.session.sent_quotes.back()
			assert_ne(current.quote_id, original.quote_id)
			f.session.deliver(current, f.session.price(current.owned_uid))
			assert_false(f.panel._quote.is_empty(), "the new open/selection still receives its own quote")
		_free_fixture(f)

func _case_spend_keeps_original_five_fields_and_requests_fresh_quote_after_terminal_result() -> void:
	var f := _fixture(false)
	assert_true(f.service.open(STATION))
	var original: Dictionary = f.session.sent_quotes[0]
	f.session.deliver(original, f.session.price(f.uid))
	f.panel._spend("essence_ground")
	var intent: Dictionary = f.session.spent.intent
	assert_eq(intent.size(), 5, "no quote id, cost, balance or cap is sent as authority")
	assert_true(f.session._altar_hex_id(intent.spend_id))
	assert_eq(intent.creature_uid, f.uid)
	assert_eq(intent.expected_level, 9)
	assert_eq(intent.expected_character_revision, 7)
	assert_eq(intent.payment_item, "essence_ground")
	assert_eq(f.service._pending.request, intent, "the original transaction survives quote invalidation")
	assert_eq(f.panel._pending_id, intent.spend_id)
	assert_true(f.service._quote_pending.is_empty())
	assert_true(f.panel._quote.is_empty())
	f.service.invalidate_essence_quote()
	assert_eq(f.service._pending.request, intent)
	f.session.altar_essence_quote_completed.emit(STATION, f.uid, original.quote_id, f.session.price(f.uid))
	assert_true(f.panel._quote.is_empty(), "late quote cannot restore buttons during an original spend")
	# Explicit terminal refusal fixture: no journal/owner-save success claim.
	f.session.altar_essence_spend_completed.emit(STATION, intent.spend_id,
		{"ok": false, "resolved": true, "durable": false, "code": "fixture_refused"})
	assert_true(f.service._pending.is_empty())
	assert_eq(f.session.sent_quotes.size(), 2)
	var fresh: Dictionary = f.session.sent_quotes.back()
	assert_ne(fresh.quote_id, original.quote_id)
	f.session.deliver(fresh, f.session.price(f.uid))
	assert_true(_has_ground_payment(f))
	assert_true(f.game.world.reward_deliveries.is_empty())
	_free_fixture(f)


func run_initialized_cases(tree: SceneTree) -> Dictionary:
	_fixture_tree = tree
	var completed: Array[String] = []
	var counts: Array[int] = []
	for name: String in NATIVE_CASES:
		var before := assertion_count
		call("_case_" + name)
		completed.append(name)
		counts.append(assertion_count - before)
	_fixture_tree = null
	return {"cases": completed, "case_assertions": counts, "assertions": assertion_count, "failures": failures}


static func _exact_native_counts(raw: Variant, expected: Array) -> bool:
	if not raw is Array or raw.size() != expected.size(): return false
	for index: int in expected.size():
		var value: Variant = raw[index]
		if not (value is int or value is float) or not is_finite(float(value)) or value != expected[index]: return false
	return true


func test_native_count_guard_compares_json_numbers_without_rounding_or_coercion() -> void:
	assert_true(_exact_native_counts([12.0, 11.0], [12, 11]))
	assert_false(_exact_native_counts([12.5, 11.0], [12, 11]))
	assert_false(_exact_native_counts([12.0, 11.0, 0.0], [12, 11]))
	assert_false(_exact_native_counts(["12", 11.0], [12, 11]))
	assert_false(_exact_native_counts([true, 11.0], [1, 11]))
	assert_false(_exact_native_counts([INF, 11.0], [12, 11]))


func run_initialized_focus_case(tree: SceneTree) -> Dictionary:
	_fixture_tree = tree
	var f := _fixture()
	assert_true(f.service.open(STATION))
	var stale: Button = _buttons(f.panel, "Ground Essence · Cost 20 · Have 100")[0]
	var obsolete: WeakRef = weakref(stale)
	f.panel._rebuild(true)
	assert_false(stale.is_inside_tree(), "the original deferred target is orphaned by the actual rebuild")
	var current: Button = _buttons(f.panel, "Ground Essence · Cost 20 · Have 100")[0]
	await tree.process_frame
	await tree.process_frame
	assert_true(obsolete.get_ref() == null, "old presentation is freed without focus retaining its button")
	assert_true(current.has_focus(), "valid current payment button still receives deferred focus")
	var sentinel := Button.new()
	f.holder.add_child(sentinel)
	sentinel.grab_focus()
	assert_true(sentinel.has_focus())
	current.disabled = true
	f.panel.call_deferred("_focus_current_button", weakref(current))
	await tree.process_frame
	await tree.process_frame
	assert_true(sentinel.has_focus(), "disabled targets cannot steal current focus")
	current.disabled = false
	var foreign := Button.new()
	f.holder.add_child(foreign)
	f.panel.call_deferred("_focus_current_button", weakref(foreign))
	await tree.process_frame
	await tree.process_frame
	assert_true(sentinel.has_focus(), "an enabled button outside the current root is refused")
	f.panel.call("_focus_current_button", obsolete)
	assert_true(sentinel.has_focus(), "a dead weak target is harmless")
	current.queue_free()
	f.panel.call("_focus_current_button", weakref(current))
	assert_true(sentinel.has_focus(), "a queued current button is refused before it leaves the tree")
	f.panel._rebuild(true)
	f.panel.close()
	sentinel.grab_focus()
	await tree.process_frame
	await tree.process_frame
	assert_true(sentinel.has_focus(), "close prevents pending current-root focus from stealing focus")
	_free_fixture(f)
	_fixture_tree = null
	return {"assertions": assertion_count, "failures": failures, "completed": true}


func test_initialized_native_tree_preserves_all_altar_quote_bridge_assertions() -> void:
	# The ordinary runner calls cases during SceneTree._init, before the engine
	# main loop is available. Use the existing cue/focus test pattern: one real
	# initialized child tree, explicit injection, exact case/assertion accounting.
	var suffix := "%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	var path := "user://altar-quote-bridge-" + suffix + ".gd"
	var log_path := ProjectSettings.globalize_path("user://altar-quote-bridge-" + suffix + ".log")
	var runner := FileAccess.open(path, FileAccess.WRITE)
	assert_true(runner != null)
	if runner == null: return
	runner.store_string('''extends SceneTree
func _initialize():
	call_deferred("run")
func run():
	var test = load("res://tests/test_altar_essence_quote_bridge.gd").new()
	var result = test.run_initialized_cases(self)
	test = null
	await process_frame
	var focus_test: RefCounted = load("res://tests/test_altar_essence_quote_bridge.gd").new()
	var focus_result: Dictionary = await focus_test.call("run_initialized_focus_case", self)
	focus_test = null
	await process_frame
	print("ALTAR_QUOTE_BRIDGE_RESULT=" + JSON.stringify(result))
	print("ALTAR_QUOTE_FOCUS_RESULT=" + JSON.stringify(focus_result))
	quit(0 if result.failures.is_empty() and result.cases.size() == 8 and result.assertions == 157 and focus_result.completed == true and focus_result.assertions == 12 and focus_result.failures.is_empty() else 1)
''')
	runner.close()
	var output: Array = []
	var absolute := ProjectSettings.globalize_path(path)
	var code := OS.execute(OS.get_executable_path(), ["--headless", "--path", ProjectSettings.globalize_path("res://"),
		"--script", absolute, "--log-file", log_path], output, true)
	DirAccess.remove_absolute(absolute)
	var combined := "\n".join(output)
	assert_true(FileAccess.file_exists(log_path), "retain the real initialized child log")
	if FileAccess.file_exists(log_path): combined += "\n" + FileAccess.get_file_as_string(log_path)
	var result: Dictionary = {}
	var result_count := 0
	var focus_result: Dictionary = {}
	var focus_result_count := 0
	for line: String in "\n".join(output).split("\n"):
		if line.begins_with("ALTAR_QUOTE_BRIDGE_RESULT="):
			print(line) # Preserve the original child case/count proof in the parent artifact.
			result_count += 1
			var parsed: Variant = JSON.parse_string(line.trim_prefix("ALTAR_QUOTE_BRIDGE_RESULT="))
			if parsed is Dictionary: result = parsed
		elif line.begins_with("ALTAR_QUOTE_FOCUS_RESULT="):
			print(line)
			focus_result_count += 1
			var parsed: Variant = JSON.parse_string(line.trim_prefix("ALTAR_QUOTE_FOCUS_RESULT="))
			if parsed is Dictionary: focus_result = parsed
	assert_eq(result_count, 1, combined)
	assert_eq(result.get("cases", []), NATIVE_CASES, "every original quote case must execute")
	assert_true(_exact_native_counts(result.get("case_assertions"), NATIVE_ASSERTIONS), "no case can abort and still appear green")
	assert_eq(result.get("assertions", 0), 157, "preserve all original assertions")
	assert_eq(result.get("failures", ["missing result"]), [], combined)
	assert_eq(focus_result_count, 1, combined)
	assert_eq(focus_result.get("assertions", 0), 12)
	assert_true(focus_result.get("completed") == true)
	assert_eq(focus_result.get("failures", ["missing result"]), [], combined)
	assert_false(combined.contains("ERROR:") or combined.contains("SCRIPT ERROR"), combined)
	assert_false(combined.contains("ObjectDB instances leaked") or combined.contains("resources still in use") \
		or combined.contains("RID allocations") or combined.contains("RIDs of type"), combined)
	assert_eq(code, 0, combined)
