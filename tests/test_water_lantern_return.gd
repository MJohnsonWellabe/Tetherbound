extends "res://tests/test_case.gd"
## F13 `side_water_lantern_return` (WORLD §Tidewake local chains): Pell points
## to Lantern Cove's rock arch; the optional swim; claim `lantern_hidden_cache`
## and return to the First Shore landing, where Pell acknowledges it. Payoff is
## the EXISTING Skill Candy I pocket via its original receipt -- no extra candy.
##
## Three recorded steps: the lead (world record), the character's own cache
## receipt (`water_claim:<character>:<row>`, written by the existing claim) and
## the return report (world record). Both chain records are host-validated
## through the existing `water_dock_action` intent (position beside Pell,
## prerequisites, the reporter's OWN receipt). Pure data/rule checks here; the
## production path is tests/smoke_water_lantern_return.gd.
const RULES_PATH := "res://scripts/world/water_local_chain_rules.gd"
const DOCK_RULES := preload("res://scripts/world/water_dock_rules.gd")
const NPCS := preload("res://scripts/world/water_scene_npcs.gd")
const PROGRESSION_STATE := preload("res://autoload/progression_state.gd")
const MERGED := preload("res://autoload/merged_progression.gd")
const QUEST_LOG := preload("res://scripts/world/quest_log.gd")
const PERSONAL := preload("res://scripts/world/water_personal_pickup.gd")

const CHAIN := "side_water_lantern_return"
const CACHE := "water:lantern_cove:pickup:002"
const LEAD := "water_claim:local:lantern_return:lead"
const DONE := "water_claim:local:lantern_return:complete"
const LESSON := "water_swim_lesson_complete"
const BRIEFED := "water_swim_lesson_briefed"
const RESTORED := "water_currents_restored"
const CHARACTER := "lantern-check"

var _cast: Dictionary
var _dialogue: Dictionary

func before_each() -> void:
	super.before_each()
	_cast = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_characters.json"))
	_dialogue = JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogue/water.json"))

## Loaded, not preloaded, so a missing rule module fails each test instead of
## aborting the file at parse time.
func _rules() -> Script:
	var script: Script = load(RULES_PATH) if ResourceLoader.exists(RULES_PATH) else null
	if script == null:
		_fail("Local chain rule module is missing: " + RULES_PATH)
	return script

func _defines(script: Script, method: String) -> bool:
	if script == null:
		return false
	for entry: Dictionary in script.get_script_method_list():
		if str(entry.name) == method:
			return true
	_fail("%s does not define %s()" % [script.resource_path, method])
	return false

func _npc(id: String) -> Dictionary:
	for spec: Dictionary in _cast.npcs:
		if str(spec.id) == id:
			return spec
	return {}

## Pell's standing point from the same data the scene places him with.
func _pell_xz() -> Vector2:
	var spec := _npc("water_pell")
	var world: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_world.json"))
	for island: Dictionary in world.islands:
		if str(island.id) == str(spec.island_id):
			return Vector2(float(island.center_xz_m[0]) + float(spec.island_local_offset[0]),
				float(island.center_xz_m[1]) + float(spec.island_local_offset[2]))
	return Vector2.INF

func _store(flags: Array) -> RefCounted:
	var store := PROGRESSION_STATE.new()
	for flag: String in flags:
		store.set_flag(flag)
	return store

## Through the real host rule the `water_dock_action` intent reaches.
func _verdict(step: String, flags: Array, offset := Vector2.ZERO, character := CHARACTER) -> Dictionary:
	var at := _pell_xz() + Vector2(2.0, 0.0) + offset
	return DOCK_RULES.evaluate({"action_id": step, "realm": "water", "inventory": {}},
		{"peer": 7, "character_id": character, "realm": "water", "position": Vector3(at.x, 3.0, at.y), "inventory": {}},
		_store(flags))

func _receipt(character: String) -> String:
	return "water_claim:%s:%s" % [character, CACHE]

# --- data ------------------------------------------------------------------------

func test_chain_records_are_declared_world_flags() -> void:
	var rules := _rules()
	if not _defines(rules, "step"):
		return
	var lead: Dictionary = rules.call("step", "lantern_return_lead")
	var report: Dictionary = rules.call("step", "lantern_return_report")
	assert_eq(str(lead.get("chain", "")), CHAIN, "Lead step belongs to the chain")
	assert_eq(str(report.get("chain", "")), CHAIN, "Report step belongs to the chain")
	assert_eq(str(lead.get("flag", "")), LEAD)
	assert_eq(str(report.get("flag", "")), DONE)
	assert_eq(str(lead.get("npc", "")), "water_pell", "Pell gives the lead")
	assert_eq(str(report.get("npc", "")), "water_pell", "Pell hears the return at the First Shore landing")
	for flag: String in [LEAD, DONE]:
		assert_eq(PROGRESSION_STATE.scope_of(flag), "world", "Chain record is a declared world flag: " + flag)

func test_cache_is_the_original_candy_i_row_and_stays_ungated() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PERSONAL.DATA))
	var row: Dictionary = {}
	for candidate: Dictionary in data.pickups:
		if str(candidate.id) == CACHE:
			row = candidate
	assert_eq(row.get("reward_pocket_id", ""), "lantern_hidden_cache", "Cache row sits in the arch pocket")
	assert_eq(row.get("item_id", ""), "skill_candy_i", "Payoff is the existing Candy I")
	assert_eq(row.get("claim_policy", ""), "character_once", "Original per-character receipt")
	assert_false(row.has("requires_world_flags"), "The pocket is discoverable without Pell's lead")
	var skill_candy := 0
	for candidate: Dictionary in data.pickups:
		skill_candy += 1 if str(candidate.get("category", "")) == "skill_candy" else 0
	assert_eq(skill_candy, 12, "No extra candy row authored for the chain")

# --- host rule -------------------------------------------------------------------

func test_lead_needs_the_lesson_and_pell_beside_the_speaker() -> void:
	var early := _verdict("lantern_return_lead", [])
	assert_false(bool(early.ok), "No lead before the swim lesson is complete")
	assert_eq(early.code, "prerequisite")
	var far := _verdict("lantern_return_lead", [LESSON], Vector2(25.0, 0.0))
	assert_eq(far.code, "too_far", "Lead must be heard beside Pell")
	var ok := _verdict("lantern_return_lead", [LESSON])
	assert_true(bool(ok.ok), "Lead accepted beside Pell after the lesson: " + str(ok.get("reason", "")))
	assert_eq(ok.ops, [{"op": "flag", "scope": "world", "realm": "water", "id": LEAD, "value": true}],
		"Lead writes only its world record")
	assert_eq(_verdict("lantern_return_lead", [LESSON, LEAD]).code, "already_done")

func test_return_requires_this_characters_own_cache_receipt() -> void:
	var none := _verdict("lantern_return_report", [LESSON, LEAD])
	assert_false(bool(none.ok), "Return refused before the cache is claimed")
	assert_eq(none.code, "claim")
	assert_true(str(none.reason).contains("arch"), "Refusal points back at the arch: " + str(none.reason))
	var someone_else := _verdict("lantern_return_report", [LESSON, LEAD, _receipt("another-character")])
	assert_eq(someone_else.code, "claim", "Another character's receipt does not count")
	var ok := _verdict("lantern_return_report", [LESSON, LEAD, _receipt(CHARACTER)])
	assert_true(bool(ok.ok), "Own receipt beside Pell completes the return: " + str(ok.get("reason", "")))
	assert_eq(ok.ops, [{"op": "flag", "scope": "world", "realm": "water", "id": DONE, "value": true}],
		"Return writes only the completion record: no item, no extra candy")
	assert_eq(_verdict("lantern_return_report", [LESSON, LEAD, _receipt(CHARACTER)], Vector2(25.0, 0.0)).code,
		"too_far", "Return is reported at the First Shore landing, beside Pell")
	assert_eq(_verdict("lantern_return_report", [LESSON, LEAD, DONE, _receipt(CHARACTER)]).code, "already_done")

func test_return_before_the_lead_also_records_the_lead() -> void:
	# A player who found the arch by curiosity still has three recorded steps.
	var ok := _verdict("lantern_return_report", [LESSON, _receipt(CHARACTER)])
	assert_true(bool(ok.ok), "Curious finder can report without the lead: " + str(ok.get("reason", "")))
	assert_eq(ok.ops, [
		{"op": "flag", "scope": "world", "realm": "water", "id": LEAD, "value": true},
		{"op": "flag", "scope": "world", "realm": "water", "id": DONE, "value": true}],
		"Lead is recorded with the return")
	assert_eq(_verdict("lantern_return_report", [_receipt(CHARACTER)]).code, "prerequisite",
		"Still needs the completed swim lesson")

func test_unknown_or_malformed_step_requests_refuse() -> void:
	var rules := _rules()
	if not _defines(rules, "evaluate"):
		return
	var context := {"peer": 7, "character_id": CHARACTER, "realm": "water", "position": Vector3.ZERO}
	assert_eq(DOCK_RULES.evaluate({"action_id": "lantern_return_nope", "realm": "water"}, context, _store([])).code,
		"unknown_action")
	var at := _pell_xz()
	context.position = Vector3(at.x, 3.0, at.y)
	context.character_id = ""
	assert_eq(DOCK_RULES.evaluate({"action_id": "lantern_return_lead", "realm": "water"}, context, _store([LESSON])).code,
		"unknown_character")
	context.character_id = CHARACTER
	context.realm = "stormwood"
	assert_eq(DOCK_RULES.evaluate({"action_id": "lantern_return_lead", "realm": "water"}, context, _store([LESSON])).code,
		"wrong_realm")

# --- dialogue gating -------------------------------------------------------------

func _choose(personal: Array, world: Array) -> String:
	var script: Script = NPCS
	if not _defines(script, "choose_conversation"):
		return ""
	var personal_store := _store(personal)
	var world_store := _store(world)
	return str(script.call("choose_conversation", _npc("water_pell"), _cast.dialogue_event_guards,
		_dialogue.conversations, MERGED.new(world_store, personal_store), personal_store, world_store))

func _guard_effect(conversation: String) -> String:
	for guard: Dictionary in _cast.dialogue_event_guards:
		if str(guard.get("conversation", "")) == conversation:
			return str(guard.get("effect", ""))
	return ""

func _text(conversation: String) -> String:
	var entry: Dictionary = _dialogue.conversations.get(conversation, {})
	assert_eq(str(entry.get("speaker", "")), "Swimmer Pell", "Speaker is Pell: " + conversation)
	var out := ""
	for line: Variant in entry.get("lines", []):
		out += (str(line.text) if line is Dictionary else str(line)) + "\n"
	return out

func test_pell_briefs_first_then_leads_to_the_arch() -> void:
	assert_eq(_choose([], []), "water_pell_lesson_briefing", "Fresh arrival hears the lesson briefing")
	assert_eq(_choose([], [LESSON]), "water_pell_lesson_briefing", "A late co-op joiner is still briefed first")
	assert_eq(_choose([BRIEFED], []), "water_pell_pre", "Briefed before the lesson: ordinary lesson advice")
	var lead := _choose([BRIEFED], [LESSON])
	assert_eq(lead, "water_pell_lantern_lead", "After the lesson Pell points at Lantern Cove")
	assert_true(_text(lead).contains("Lantern Cove") and _text(lead).contains("arch"), "Lead names the cove and its arch")
	assert_eq(_guard_effect(lead), "water:local_step:lantern_return_lead", "Lead conversation requests the host step")

func test_pell_hears_the_return_only_from_a_character_who_claimed() -> void:
	var claimed := PERSONAL.personal_flag(CACHE)
	assert_eq(_choose([BRIEFED], [LESSON, LEAD]), "water_pell_lantern_reminder", "Without a claim: a reminder, no request")
	assert_eq(_guard_effect("water_pell_lantern_reminder"), "", "Reminder requests nothing")
	var report := _choose([BRIEFED, claimed], [LESSON, LEAD])
	assert_eq(report, "water_pell_lantern_return", "Claimed: Pell hears the return")
	assert_eq(_guard_effect(report), "water:local_step:lantern_return_report")
	assert_true(_text(report).contains("back"), "Return lines acknowledge the swim back")
	assert_eq(_choose([BRIEFED, claimed], [LESSON]), "water_pell_lantern_return", "A curious finder reports directly")
	var thanks := _choose([BRIEFED, claimed], [LESSON, LEAD, DONE])
	assert_eq(thanks, "water_pell_lantern_thanks", "Completed: acknowledgement, no second request")
	assert_eq(_guard_effect(thanks), "")
	assert_eq(_choose([BRIEFED], [LESSON, LEAD, DONE]), "water_pell_lantern_thanks", "Co-op partner hears the world acknowledgement")
	assert_eq(_choose([BRIEFED], [LESSON, LEAD, DONE, RESTORED]), "water_pell_post_lantern", "Restored archipelago keeps the acknowledgement")
	assert_eq(_choose([BRIEFED], [LESSON, RESTORED]), "water_pell_lantern_lead", "Lead still offered after restoration")
	assert_true(_text("water_pell_post_lantern").contains("Lantern"))

func test_chain_speech_carries_no_line_effects() -> void:
	for id: String in ["water_pell_lantern_lead", "water_pell_lantern_reminder", "water_pell_lantern_return",
			"water_pell_lantern_thanks", "water_pell_post_lantern"]:
		var entry: Dictionary = _dialogue.conversations.get(id, {})
		assert_false(entry.is_empty(), "Conversation authored: " + id)
		for line: Variant in entry.get("lines", []):
			assert_false(line is Dictionary and (line.has("effect") or line.has("effects")),
				"Only the guard requests an action: " + id)

# --- quest log -------------------------------------------------------------------

func test_local_request_is_revealed_by_the_lead_and_completed_by_the_return() -> void:
	var store := PROGRESSION_STATE.new()
	var reader := QUEST_LOG.new()
	reader.set_realm("water")
	var find := func() -> Dictionary:
		for entry: Dictionary in reader.local_entries(store):
			if str(entry.label).contains("Lantern Cove"):
				return entry
		return {}
	store.set_flag(LESSON)
	assert_true(find.call().is_empty(), "Not pre-labelled before Pell's lead")
	store.set_flag(LEAD)
	var entry: Dictionary = find.call()
	assert_false(entry.is_empty(), "Lead reveals the local request")
	assert_false(bool(entry.get("done", true)))
	assert_eq(entry.get("scope", ""), "world")
	assert_true(str(entry.get("how", "")).contains("Pell"), "Hint says where to return")
	store.set_flag(DONE)
	assert_true(bool(find.call().get("done", false)), "Return completes the request")
