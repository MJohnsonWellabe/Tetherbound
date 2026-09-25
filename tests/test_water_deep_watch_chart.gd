extends "res://tests/test_case.gd"
## F13 `side_water_deep_watch_chart` (WORLD §Tidewake local chains): Orsen names
## Deep Watch; Tidecoil is resolved by catch/defeat; the separate chart control
## is operated. The existing Skill Candy III row in `deep_watch_tidecoil_cache`
## stays locked until the named resolution world flag is set, on BOTH the host
## claim rule and the pickup streamer. Pure data/rule checks plus one streamer
## pass in a fixture world (analytic ground, no Terrain3D, no traversal).
const RULE := preload("res://scripts/world/water_personal_pickup.gd")
const STREAMER := preload("res://scripts/world/water_scene_pickups.gd")
const DOCK_RULES := preload("res://scripts/world/water_dock_rules.gd")
const FIELD := preload("res://scripts/world/water_heightfield.gd")
const GREETINGS := preload("res://scripts/world/village_npcs.gd")
const PROGRESSION_STATE := preload("res://autoload/progression_state.gd")
const QUEST_LOG := preload("res://scripts/world/quest_log.gd")
const RELAY_PATH := "res://scripts/world/water_named_resolution.gd"

const GATED := "water:deep_watch:pickup:002"
const RESOLVED := "water_named_deep_watch_tidecoil_resolved"
const CHARTED := "water_dock_deep_watch_current_charted"
const RESTORED := "water_currents_restored"
const ORSEN := "water_orsen"

var _pickups: Dictionary
var _field

func before_each() -> void:
	super.before_each()
	_pickups = JSON.parse_string(FileAccess.get_file_as_string(RULE.DATA))
	_field = FIELD.new()

func _row(id: String) -> Dictionary:
	for row: Dictionary in _pickups.pickups:
		if str(row.id) == id:
			return row
	return {}

func _standing_at(row: Dictionary) -> Dictionary:
	var at: Array = row.position
	return {"peer": 7, "character_id": "deep-watch-check", "realm": "water",
		"position": Vector3(float(at[0]), _field.height_at(float(at[0]), float(at[2])), float(at[2]))}

## Called through the script so a missing helper fails per test, not per file.
func _met(row: Dictionary, flags: Variant) -> bool:
	var script: Script = RULE
	return bool(script.call("requirements_met", row, flags))

func _claim(id: String, flags: Variant) -> Dictionary:
	return RULE.evaluate({"pickup_id": id, "realm": "water", "personal_claimed": false},
		_standing_at(_row(id)), flags)

# --- the gate: host claim rule -------------------------------------------------

func test_gated_row_declares_the_named_resolution_requirement() -> void:
	var row := _row(GATED)
	assert_false(row.is_empty(), "Deep Watch Candy III row exists")
	assert_eq(row.get("reward_pocket_id", ""), "deep_watch_tidecoil_cache", "Row is the Tidecoil cache")
	assert_eq(row.get("item_id", ""), "skill_candy_iii", "Candy III identity unchanged")
	assert_eq(row.get("requires_world_flags", []), [RESOLVED], "Row names only the Tidecoil resolution flag")
	assert_eq(PROGRESSION_STATE.scope_of(RESOLVED), "world", "Resolution flag is world scoped on main")
	assert_false(str(row.get("locked_reason", "")).is_empty(), "Row carries a player-facing locked reason")

func test_host_rule_refuses_locked_before_resolution() -> void:
	for flags: Variant in [{}, PROGRESSION_STATE.new(), null, {CHARTED: true}]:
		var verdict := _claim(GATED, flags)
		assert_false(verdict.ok, "Locked Candy III refuses with flags %s" % str(flags))
		assert_eq(verdict.code, "locked", "Refusal code is locked")
		assert_true(verdict.ops.is_empty(), "Locked refusal writes nothing")
		assert_true(str(verdict.reason).contains("Tidecoil"), "Locked reason names what to resolve")

func test_host_rule_accepts_after_resolution_with_both_flag_shapes() -> void:
	var store := PROGRESSION_STATE.new()
	store.set_flag(RESOLVED)
	for flags: Variant in [{RESOLVED: true}, store]:
		var verdict := _claim(GATED, flags)
		assert_true(verdict.ok, "Resolved Tidecoil unlocks Candy III")
		assert_eq(verdict.ops.size(), 3, "Same three atomic claim ops")
		assert_eq(verdict.ops[2].item, "skill_candy_iii")
	# The receipt still refuses a second world award after the unlock.
	var receipt := "water_claim:deep-watch-check:" + GATED
	assert_eq(_claim(GATED, {RESOLVED: true, receipt: true}).code, "already_taken",
		"Unlock does not bypass the per-character receipt")
	# Proximity still applies to an unlocked row.
	var context := _standing_at(_row(GATED))
	context.position += Vector3(5, 0, 0)
	assert_eq(RULE.evaluate({"pickup_id": GATED, "realm": "water", "personal_claimed": false},
		context, {RESOLVED: true}).code, "too_far", "Unlocked row keeps host proximity")

func test_other_pickup_rows_are_unaffected_by_the_gate() -> void:
	var other_candy := 0
	for row: Dictionary in _pickups.pickups + _pickups.harvest:
		if str(row.id) == GATED:
			continue
		assert_false(row.has("requires_world_flags"), "Only the Tidecoil cache is gated: " + str(row.id))
		assert_true(_met(row, {}), "Ungated row has no requirement: " + str(row.id))
		if str(row.get("category", "")) == "skill_candy":
			other_candy += 1
			assert_true(_claim(str(row.id), {}).ok, "Ungated Candy stays claimable: " + str(row.id))
	assert_eq(other_candy, 11, "Eleven other Candy rows remain ungated")

func test_malformed_requirement_fails_closed() -> void:
	assert_false(_met({"requires_world_flags": "not-an-array"}, {}), "Malformed list locks")
	assert_false(_met({"requires_world_flags": [RESOLVED]}, null), "Missing world locks")
	assert_true(_met({"requires_world_flags": [RESOLVED]}, {RESOLVED: true}))

# --- the gate: streamer --------------------------------------------------------

func test_streamer_admission_uses_the_same_world_flag_rule() -> void:
	# The unit runner has no SceneTree; the real refresh()/residency pass is
	# exercised by smoke_water_scene_pickups and smoke_water_deep_watch_chart.
	var script: Script = STREAMER
	var row := _row(GATED)
	var store := PROGRESSION_STATE.new()
	assert_false(bool(script.call("admitted", row, store)), "Streamer withholds the locked row")
	assert_false(bool(script.call("admitted", row, null)), "Streamer withholds it with no world state")
	store.set_flag(RESOLVED)
	assert_true(bool(script.call("admitted", row, store)), "Streamer admits it once resolved")
	for other: Dictionary in _pickups.pickups + _pickups.harvest:
		if str(other.id) != GATED:
			assert_true(bool(script.call("admitted", other, PROGRESSION_STATE.new())), "Ungated row admitted: " + str(other.id))

# --- chain step 3: the separate chart control -------------------------------------

func _chart_verdict(flags: Dictionary) -> Dictionary:
	var data := DOCK_RULES.load_data()
	var action: Dictionary = {}
	for row: Dictionary in data.actions:
		if str(row.id) == "deep_watch_chart":
			action = row
	var target := DOCK_RULES.action_position(action, FIELD.load_config(), _field.height_at)
	var store := PROGRESSION_STATE.new()
	for flag: String in flags:
		store.set_flag(flag)
	return DOCK_RULES.evaluate({"action_id": "deep_watch_chart", "realm": "water"},
		{"peer": 7, "character_id": "chart-check", "realm": "water", "position": target, "inventory": {}}, store)

func test_chart_control_requires_resolution_and_is_a_separate_action() -> void:
	var locked := _chart_verdict({})
	assert_false(locked.ok, "Chart refuses before Tidecoil is resolved")
	assert_eq(locked.code, "prerequisite")
	assert_true(str(locked.reason).contains("Tidecoil"), "Chart refusal explains the Tidecoil step")
	var ready := _chart_verdict({RESOLVED: true})
	assert_true(ready.ok, "Resolved Tidecoil permits the physical chart action")
	assert_eq(ready.ops, [{"op": "flag", "scope": "world", "realm": "water", "id": CHARTED, "value": true}],
		"Chart writes only its own world flag")
	assert_eq(_chart_verdict({RESOLVED: true, CHARTED: true}).code, "already_done")
	# Victory alone never flips the chart flag: nothing in the resolution path
	# names it, and the encounter's completion flag is a different id.
	var encounters: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_encounters.json"))
	for named: Dictionary in encounters.named_encounters:
		assert_ne(str(named.completion_flag), CHARTED, "No named encounter completes the chart")
	for row: Dictionary in DOCK_RULES.load_data().actions:
		if str(row.id) == "shellwatch_release":
			assert_false(row.has("refusal"), "Other dock actions keep the generic refusal")

# --- chain step 1 and acknowledgements: Orsen's authored speech ---------------------

func _orsen() -> Dictionary:
	var cast: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_characters.json"))
	for spec: Dictionary in cast.npcs:
		if str(spec.id) == ORSEN:
			return spec
	return {}

func _greeting(flags: Array) -> String:
	var store := PROGRESSION_STATE.new()
	for flag: String in flags:
		store.set_flag(flag)
	return GREETINGS.greeting_for(_orsen(), store)

func _text(conversation: String) -> String:
	var dialogue: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogue/water.json"))
	var entry: Dictionary = dialogue.conversations.get(conversation, {})
	var out := ""
	for line: Variant in entry.get("lines", []):
		out += (str(line.text) if line is Dictionary else str(line)) + "\n"
		assert_false(line is Dictionary and (line.has("effect") or line.has("effects")),
			"Orsen speech carries no action effect: " + conversation)
	assert_eq(str(entry.get("speaker", "")), "Channel Keeper Orsen", "Speaker is Orsen: " + conversation)
	return out

func test_orsen_names_deep_watch_before_and_after_the_currents() -> void:
	var pre := _greeting([])
	assert_eq(pre, "water_orsen_pre", "Default Sluice greeting unchanged")
	assert_true(_text(pre).contains("Deep Watch") and _text(pre).contains("Tidecoil"), "Orsen names Deep Watch and Tidecoil")
	assert_true(_text(pre).contains("control"), "Main-route control guidance retained")
	var post := _greeting([RESTORED])
	assert_eq(post, "water_orsen_post")
	assert_true(_text(post).contains("Deep Watch"), "Post-restoration Orsen still names optional Deep Watch")

func test_orsen_gives_the_chart_lead_only_after_resolution() -> void:
	for flags: Array in [[RESOLVED], [RESOLVED, RESTORED]]:
		var lead := _greeting(flags)
		assert_eq(lead, "water_orsen_deep_watch_chart_lead", "Resolution reveals the chart lead: %s" % str(flags))
		assert_true(_text(lead).contains("chart"), "Lead points at the chart control")
		assert_true(_text(lead).contains("cache"), "Lead mentions the now-open cache")

func test_orsen_acknowledges_the_charted_current() -> void:
	var ack := _greeting([RESOLVED, CHARTED])
	assert_eq(ack, "water_orsen_deep_watch_charted", "Charted before restoration acknowledges")
	assert_true(_text(ack).contains("control"), "Acknowledgement keeps main-route guidance")
	var post_ack := _greeting([RESOLVED, CHARTED, RESTORED])
	assert_eq(post_ack, "water_orsen_post_charted", "Charted after restoration acknowledges")
	assert_true(_text(post_ack).contains("Deep Watch"))

# --- quest log: the chart lead becomes visible after resolution -------------------------

func test_local_request_is_revealed_by_resolution_and_completed_by_chart() -> void:
	var store := PROGRESSION_STATE.new()
	var reader := QUEST_LOG.new()
	reader.set_realm("water")
	var find := func() -> Dictionary:
		for entry: Dictionary in reader.local_entries(store):
			if str(entry.label).contains("Deep Watch"):
				return entry
		return {}
	assert_true(find.call().is_empty(), "No pre-labelled Deep Watch request before resolution")
	store.set_flag(RESOLVED)
	var entry: Dictionary = find.call()
	assert_false(entry.is_empty(), "Resolution reveals the chart request")
	assert_false(bool(entry.get("done", true)), "Resolution alone does not complete the chart")
	assert_eq(entry.get("scope", ""), "world")
	store.set_flag(CHARTED)
	assert_true(bool(find.call().get("done", false)), "Chart completes the request")

# --- co-op: named resolution reaches the host world ----------------------------------

func _relay() -> RefCounted:
	var script: GDScript = load(RELAY_PATH) if ResourceLoader.exists(RELAY_PATH) else null
	assert_true(script != null, "Named-resolution relay exists")
	return script.new() if script != null else null

func test_relay_names_only_world_scoped_named_completion_flags() -> void:
	var relay := _relay()
	if relay == null:
		return
	assert_true(relay.flags.has(RESOLVED), "Tidecoil resolution is relayed")
	var encounters: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_encounters.json"))
	var expected: Array[String] = []
	for named: Dictionary in encounters.named_encounters:
		if PROGRESSION_STATE.scope_of(str(named.completion_flag)) == "world":
			expected.append(str(named.completion_flag))
	assert_eq(relay.flags, expected, "Exactly the declared world-scoped named completion flags")
	for flag: String in relay.flags:
		assert_eq(PROGRESSION_STATE.scope_of(flag), "world", "Relayed flag is world scoped: " + flag)

func test_relay_forwards_only_local_transitions_once() -> void:
	var relay := _relay()
	if relay == null:
		return
	var store := PROGRESSION_STATE.new()
	store.set_flag(RESOLVED)
	relay.baseline(store)
	assert_eq(relay.pending(store), [], "Snapshot/baseline flags are never re-sent")
	store = PROGRESSION_STATE.new()
	relay.baseline(store)
	store.set_flag(RESOLVED)
	assert_eq(relay.pending(store), [RESOLVED], "A local-only once write is forwarded")
	assert_eq(relay.pending(store), [], "Forwarded once per session")
	var other := _relay()
	other.baseline(PROGRESSION_STATE.new())
	other.note_delta({"ops": [{"op": "flag", "scope": "world", "realm": "water", "id": RESOLVED, "value": true}]})
	store = PROGRESSION_STATE.new()
	store.set_flag(RESOLVED)
	assert_eq(other.pending(store), [], "A flag the host already published is not echoed back")
	var third := _relay()
	third.baseline(PROGRESSION_STATE.new())
	third.note_delta({"ops": [{"op": "flag", "scope": "player", "realm": "water", "id": RESOLVED, "value": true}]})
	assert_eq(third.pending(store), [RESOLVED], "Only a world op counts as host knowledge")
	assert_eq(relay.flag_op(RESOLVED), {"op": "flag", "scope": "world", "realm": "water", "id": RESOLVED, "value": true})
