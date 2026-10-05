extends "res://tests/test_case.gd"

## F27#3: the host's own five drift passively (nourishment, happiness) and
## every refresh bumps the admitted revision, so the Altar's displayed quote
## is always stale by the press (found by smoke_f27_altar_spend.gd: every solo
## spend refused `stale_revision`). The FIRST send adopts a fresh host quote
## only for the same creature, level and affordable payment; a guest request
## and a changed level keep the original revision. Reuses the shipping
## service/panel and the quote bridge's Session double.
const BRIDGE := preload("res://tests/test_altar_essence_quote_bridge.gd")
const STATION := "altar:meadows:quote-fixture"
const CASES := ["host_first_send_adopts_fresh_revision_for_unchanged_offer",
	"host_first_send_never_rebases_a_changed_level",
	"host_first_send_never_rebases_an_unaffordable_payment",
	"guest_request_is_never_rebased_locally"]
var _tree: SceneTree


func _fixture(host: bool) -> Array:
	var bridge: RefCounted = BRIDGE.new()
	bridge.set("_fixture_tree", _tree)
	var f: Dictionary = bridge.call("_fixture", host)
	assert_eq(bridge.get("failures"), [], "bridge fixture builds cleanly")
	assert_true(f.service.open(STATION))
	if not host:
		f.session.deliver(f.session.sent_quotes[0], f.session.price(f.uid))
	assert_eq(f.panel._quote.get("expected_character_revision"), 7)
	return [bridge, f]


func _case_host_first_send_adopts_fresh_revision_for_unchanged_offer() -> void:
	var pair := _fixture(true)
	var f: Dictionary = pair[1]
	f.session.quote_revision = 11 # Passive care drift since the panel quoted.
	f.panel._spend("essence_ground")
	assert_eq(f.session.spent.intent.expected_character_revision, 11)
	assert_eq(f.session.spent.intent.expected_level, 9)
	assert_eq(f.session.spent.intent.payment_item, "essence_ground")
	assert_eq(f.service._pending.request, f.session.spent.intent, "retries keep the one rebased original")
	pair[0].call("_free_fixture", f)


func _case_host_first_send_never_rebases_a_changed_level() -> void:
	var pair := _fixture(true)
	var f: Dictionary = pair[1]
	f.session.quote_revision = 11
	f.session.quote_record.party[0].level = 8 # Host truth no longer matches the panel.
	f.panel._spend("essence_ground")
	assert_eq(f.session.spent.intent.expected_character_revision, 7, "stale UI stays stale for Session to refuse")
	pair[0].call("_free_fixture", f)


func _case_host_first_send_never_rebases_an_unaffordable_payment() -> void:
	var pair := _fixture(true)
	var f: Dictionary = pair[1]
	f.session.quote_revision = 11
	var inventory := preload("res://scripts/world/death_satchel_rules.gd").inventory_from(f.session.quote_record.inventory)
	inventory.remove("essence_ground", inventory.count("essence_ground"))
	f.session.quote_record.inventory = preload("res://scripts/world/death_satchel_rules.gd").slots(inventory)
	f.panel._spend("essence_ground")
	assert_eq(f.session.spent.intent.expected_character_revision, 7)
	pair[0].call("_free_fixture", f)


func _case_guest_request_is_never_rebased_locally() -> void:
	var pair := _fixture(false)
	var f: Dictionary = pair[1]
	var quotes_before: int = f.session.sent_quotes.size()
	f.session.quote_revision = 11
	f.panel._spend("essence_ground")
	assert_eq(f.session.spent.intent.expected_character_revision, 7)
	assert_eq(f.session.sent_quotes.size(), quotes_before, "no extra guest quote round trip on send")
	pair[0].call("_free_fixture", f)


func run_initialized_cases(tree: SceneTree) -> Dictionary:
	_tree = tree
	var counts: Array[int] = []
	for name: String in CASES:
		var before := assertion_count
		call("_case_" + name)
		counts.append(assertion_count - before)
	_tree = null
	return {"cases": CASES, "case_assertions": counts, "failures": failures}


## The ordinary runner calls tests during SceneTree._init, before a main loop
## exists; run the cases in one real initialized child tree, as the quote
## bridge does, and require every case to finish with its exact count.
func test_altar_first_send_cases_in_initialized_tree() -> void:
	var suffix := "%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	var path := "user://f27-altar-first-send-" + suffix + ".gd"
	var runner := FileAccess.open(path, FileAccess.WRITE)
	assert_true(runner != null)
	if runner == null: return
	runner.store_string('''extends SceneTree
func _initialize():
	call_deferred("run")
func run():
	var test = load("res://tests/test_f27_altar_first_send.gd").new()
	var result = test.run_initialized_cases(self)
	test = null
	await process_frame
	print("F27_FIRST_SEND_RESULT=" + JSON.stringify(result))
	quit(0)
''')
	runner.close()
	var output: Array = []
	var absolute := ProjectSettings.globalize_path(path)
	OS.execute(OS.get_executable_path(), ["--headless", "--path", ProjectSettings.globalize_path("res://"),
		"--script", absolute], output, true)
	DirAccess.remove_absolute(absolute)
	var combined := "\n".join(output)
	var result: Dictionary = {}
	for line: String in combined.split("\n"):
		if line.begins_with("F27_FIRST_SEND_RESULT="):
			var parsed: Variant = JSON.parse_string(line.trim_prefix("F27_FIRST_SEND_RESULT="))
			if parsed is Dictionary: result = parsed
	assert_false(combined.contains("SCRIPT ERROR"), combined)
	assert_eq(result.get("cases", []), CASES, combined)
	assert_eq((result.get("case_assertions", []) as Array).map(func(n: Variant) -> int: return int(n)), [7, 4, 4, 5], "every case completes with its exact assertions")
	assert_eq(result.get("failures", ["missing result"]), [], combined)
