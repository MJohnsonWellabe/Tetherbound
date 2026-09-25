extends "res://tests/test_case.gd"
## F13 `side_water_cradle_care` (WORLD §Tidewake local chains): Otto points to
## `cradle_shell_nest`; reach the dry nest and gather its 4 Reef Stone; return
## to Otto with a legal owned swimmer or after declining Aquaryn. Payoff: the 4
## Reef Stone stay with the gatherer, plus 3 berries once, and an explicit
## alternate-swimmer habitat lead. Never a requirement to catch Aquaryn, never
## sixth-slot staging.
##
## Three recorded steps: Otto's lead (world record), the nest seam's own
## world-once harvest flag, and the return (world record + one 3-berry grant to
## the returning character, txn-guarded). The swimmer condition is checked by
## the host from the requester's party proof, the same trust model as dock
## inventory proof. Production path: tests/smoke_water_cradle_care.gd.
const RULES_PATH := "res://scripts/world/water_local_chain_rules.gd"
const DOCK_RULES := preload("res://scripts/world/water_dock_rules.gd")
const NPCS := preload("res://scripts/world/water_scene_npcs.gd")
const PROGRESSION_STATE := preload("res://autoload/progression_state.gd")
const MERGED := preload("res://autoload/merged_progression.gd")
const QUEST_LOG := preload("res://scripts/world/quest_log.gd")

const CHAIN := "side_water_cradle_care"
const SEAM := "harvest_node:order:water:tidal_cradle:harvest:007"
const LEAD := "water_claim:local:cradle_care:lead"
const DONE := "water_claim:local:cradle_care:complete"
const AQUARYN := "water_aquaryn_resolved"
const RESTORED := "water_currents_restored"
const CHARACTER := "cradle-check"

var _cast: Dictionary
var _dialogue: Dictionary

func before_each() -> void:
	super.before_each()
	_cast = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_characters.json"))
	_dialogue = JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogue/water.json"))

func _rules() -> Script:
	var script: Script = load(RULES_PATH) if ResourceLoader.exists(RULES_PATH) else null
	if script == null:
		_fail("Missing script: " + RULES_PATH)
	return script

func _defines(script: Script, method: String) -> bool:
	if script == null:
		return false
	for entry: Dictionary in script.get_script_method_list():
		if str(entry.name) == method:
			return true
	_fail("%s does not define %s()" % [script.resource_path, method])
	return false

func _spec(id: String) -> Dictionary:
	for spec: Dictionary in _cast.npcs:
		if str(spec.id) == id:
			return spec
	return {}

func _otto_xz() -> Vector2:
	var spec := _spec("water_otto")
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

func _verdict(step: String, flags: Array, party: Variant = [], offset := Vector2.ZERO) -> Dictionary:
	var at := _otto_xz() + Vector2(2.0, 0.0) + offset
	return DOCK_RULES.evaluate({"action_id": step, "realm": "water", "inventory": {}, "party_species": party},
		{"peer": 7, "character_id": CHARACTER, "realm": "water", "position": Vector3(at.x, 3.0, at.y), "inventory": {}},
		_store(flags))

func _op(id: String) -> Dictionary:
	return {"op": "flag", "scope": "world", "realm": "water", "id": id, "value": true}

# --- data ------------------------------------------------------------------------

func test_steps_are_world_records_and_the_nest_is_the_existing_seam() -> void:
	var rules := _rules()
	if not _defines(rules, "step"):
		return
	var lead: Dictionary = rules.call("step", "cradle_care_lead")
	var report: Dictionary = rules.call("step", "cradle_care_report")
	for row: Dictionary in [lead, report]:
		assert_eq(str(row.get("chain", "")), CHAIN)
		assert_eq(str(row.get("npc", "")), "water_otto", "Otto owns both speech steps")
	assert_eq(str(lead.get("flag", "")), LEAD)
	assert_eq(str(report.get("flag", "")), DONE)
	assert_true((report.get("requires_flags", []) as Array).has(SEAM), "Return needs the nest seam gathered")
	var grant: Dictionary = report.get("grant", {})
	assert_eq(grant.keys(), ["berries"], "Return pays berries only")
	assert_eq(int(grant.get("berries", 0)), 3, "Return pays 3 berries")
	for flag: String in [LEAD, DONE, SEAM]:
		assert_eq(PROGRESSION_STATE.scope_of(flag), "world", "World-scoped record: " + flag)
	var pickups: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_pickups.json"))
	var in_nest: Array = []
	for row: Dictionary in pickups.pickups + pickups.harvest:
		if str(row.get("reward_pocket_id", "")) == "cradle_shell_nest":
			in_nest.append(str(row.id))
	assert_eq(in_nest, ["water:tidal_cradle:harvest:007"], "The nest pays only its Reef Stone seam; berries are Otto's")

func test_swimmer_species_come_from_the_live_catalogue() -> void:
	var rules := _rules()
	if not _defines(rules, "swimmer_species"):
		return
	var species: Array = rules.call("swimmer_species")
	species.sort()
	assert_eq(species, ["water_aquaryn", "water_cannonback", "water_mosshell", "water_riverdrake", "water_sirenseal"],
		"The five swim-mount compatible species, as the live catalogue registers them")
	assert_false(species.has("mosshell"), "The Meadows Mosshell is not a swim mount")

# --- host rule -------------------------------------------------------------------

func test_lead_is_heard_beside_otto() -> void:
	var ok := _verdict("cradle_care_lead", [])
	assert_true(bool(ok.ok), "Otto's lead accepted: " + str(ok.get("reason", "")))
	assert_eq(ok.ops, [_op(LEAD)])
	assert_eq(_verdict("cradle_care_lead", [], [], Vector2(30.0, 0.0)).code, "too_far")

func test_return_needs_the_gathered_nest() -> void:
	var early := _verdict("cradle_care_report", [LEAD, AQUARYN], ["mosshell"])
	assert_eq(early.code, "prerequisite", "No return before the nest seam is gathered")
	assert_true(str(early.reason).contains("nest"), "Refusal points at the nest: " + str(early.reason))

func test_return_needs_an_owned_swimmer_or_a_settled_aquaryn_trial() -> void:
	var none := _verdict("cradle_care_report", [LEAD, SEAM], ["brooktail", "mosshell"])
	assert_false(bool(none.ok), "No swimmer and Aquaryn unresolved: refused")
	assert_eq(none.code, "swimmer")
	assert_false(str(none.reason).contains("catch Aquaryn"), "Never asks the player to catch Aquaryn")
	for party: Variant in ["water_mosshell", [3], null, {"water_mosshell": true}]:
		assert_eq(_verdict("cradle_care_report", [LEAD, SEAM], party).code, "swimmer",
			"Malformed party proof fails closed: %s" % str(party))
	var with_swimmer := _verdict("cradle_care_report", [LEAD, SEAM], ["brooktail", "water_mosshell"])
	assert_true(bool(with_swimmer.ok), "An owned Mosshell qualifies before Aquaryn: " + str(with_swimmer.get("reason", "")))
	var declined := _verdict("cradle_care_report", [LEAD, SEAM, AQUARYN], ["brooktail"])
	assert_true(bool(declined.ok), "A settled Aquaryn trial without catching it qualifies")

func test_return_pays_three_berries_once_to_the_returning_character() -> void:
	var ok := _verdict("cradle_care_report", [LEAD, SEAM, AQUARYN], [])
	assert_eq(ok.ops, [
		_op(DONE),
		{"op": "item_grant", "scope": "player", "peers": [7], "item": "berries", "count": 3, "txn_id": DONE}],
		"Completion plus one txn-guarded 3-berry grant; no Reef Stone duplicated")
	assert_eq(_verdict("cradle_care_report", [LEAD, SEAM, AQUARYN, DONE], []).code, "already_done", "Berries once")
	var curious := _verdict("cradle_care_report", [SEAM, AQUARYN], [])
	assert_true(bool(curious.ok), "A player who found the nest first can still return")
	assert_eq(curious.ops[0], _op(LEAD), "The lead is recorded with the return")

# --- dialogue gating -------------------------------------------------------------

func _choose(world: Array, party: Array = []) -> String:
	var script: Script = NPCS
	if not _defines(script, "choose_conversation"):
		return ""
	var personal := _store([])
	var world_store := _store(world)
	return str(script.call("choose_conversation", _spec("water_otto"), _cast.dialogue_event_guards,
		_dialogue.conversations, MERGED.new(world_store, personal), personal, world_store, party))

func _effect(conversation: String) -> String:
	for guard: Dictionary in _cast.dialogue_event_guards:
		if str(guard.get("conversation", "")) == conversation:
			return str(guard.get("effect", ""))
	return ""

func _text(conversation: String) -> String:
	var entry: Dictionary = _dialogue.conversations.get(conversation, {})
	assert_eq(str(entry.get("speaker", "")), "Tracker Otto", "Speaker is Otto: " + conversation)
	var out := ""
	for line: Variant in entry.get("lines", []):
		assert_false(line is Dictionary and (line.has("effect") or line.has("effects")), "No line effect: " + conversation)
		out += (str(line.text) if line is Dictionary else str(line)) + "\n"
	return out

func test_otto_leads_waits_and_pays_without_pushing_aquaryn() -> void:
	var lead := _choose([])
	assert_eq(lead, "water_otto_nest_lead", "Otto points at the shell nest first")
	assert_true(_text(lead).contains("nest") and _text(lead).contains("Reef Stone"), "Lead names the nest and its stone")
	assert_eq(_effect(lead), "water:local_step:cradle_care_lead")
	assert_eq(_choose([LEAD]), "water_otto_nest_reminder", "Open lead: reminder")
	var wait := _choose([LEAD, SEAM], ["brooktail"])
	assert_eq(wait, "water_otto_nest_wait", "Gathered but no swimmer and Aquaryn unsettled: Otto waits")
	assert_eq(_effect(wait), "", "Waiting requests nothing")
	assert_false(_text(wait).contains("catch Aquaryn"), "Otto never pushes catching Aquaryn")
	var report := _choose([LEAD, SEAM], ["water_mosshell"])
	assert_eq(report, "water_otto_nest_return", "Owned swimmer: Otto takes the report")
	assert_eq(_effect(report), "water:local_step:cradle_care_report")
	assert_eq(_choose([LEAD, SEAM, AQUARYN], []), "water_otto_nest_return", "Settled trial without Aquaryn also qualifies")
	for id: String in ["Mosshell", "Riverdrake", "Sirenseal"]:
		assert_true(_text(report).contains(id), "Return names an alternate swimmer habitat: " + id)
	var thanks := _choose([LEAD, SEAM, DONE], [])
	assert_eq(thanks, "water_otto_nest_thanks")
	assert_eq(_effect(thanks), "")
	assert_eq(_choose([LEAD, SEAM, DONE, RESTORED], []), "water_otto_post_nest")
	assert_eq(_choose([RESTORED]), "water_otto_nest_lead", "Lead still offered after restoration")

# --- quest log -------------------------------------------------------------------

func test_local_request_follows_the_chain() -> void:
	var store := PROGRESSION_STATE.new()
	var reader := QUEST_LOG.new()
	reader.set_realm("water")
	var find := func() -> Dictionary:
		for entry: Dictionary in reader.local_entries(store):
			if str(entry.label).contains("nest"):
				return entry
		return {}
	assert_true(find.call().is_empty(), "Not pre-labelled")
	store.set_flag(LEAD)
	var entry: Dictionary = find.call()
	assert_false(entry.is_empty(), "Otto's lead reveals the request")
	assert_eq(entry.get("scope", ""), "world")
	assert_false(str(entry.get("how", "")).contains("catch Aquaryn"), "Hint never requires Aquaryn")
	store.set_flag(SEAM)
	assert_false(bool(find.call().get("done", true)))
	store.set_flag(DONE)
	assert_true(bool(find.call().get("done", false)))
