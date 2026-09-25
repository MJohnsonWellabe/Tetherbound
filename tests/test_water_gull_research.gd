extends "res://tests/test_case.gd"
## F13 `side_water_gull_research` (WORLD §Tidewake local chains): Adair names
## Gull Rest; reach the researcher's satchel via the safe optional crossing;
## return the recorded observations on the next Brine Steps passage. Payoff is
## the EXISTING `gull_research_satchel` Skill Candy II plus the charted route.
## The satchel is a quest record (world flag), never an inventory object.
##
## Three recorded steps, each a host-validated `water_dock_action`: the lead
## beside Adair, the satchel site at Gull Rest, the report beside Adair. Pure
## data/rule checks here; production path: tests/smoke_water_gull_research.gd.
const RULES_PATH := "res://scripts/world/water_local_chain_rules.gd"
const SCENE_PATH := "res://scripts/world/water_local_chains.gd"
const DOCK_RULES := preload("res://scripts/world/water_dock_rules.gd")
const NPCS := preload("res://scripts/world/water_scene_npcs.gd")
const FIELD := preload("res://scripts/world/water_heightfield.gd")
const PROGRESSION_STATE := preload("res://autoload/progression_state.gd")
const MERGED := preload("res://autoload/merged_progression.gd")
const QUEST_LOG := preload("res://scripts/world/quest_log.gd")
const PERSONAL := preload("res://scripts/world/water_personal_pickup.gd")

const CHAIN := "side_water_gull_research"
const CANDY := "water:gull_rest:pickup:002"
const POCKET := "gull_research_satchel"
const LEAD := "water_claim:local:gull_research:lead"
const SATCHEL := "water_claim:local:gull_research:satchel"
const DONE := "water_claim:local:gull_research:complete"
const RESTORED := "water_currents_restored"
const CHARACTER := "gull-check"

var _cast: Dictionary
var _dialogue: Dictionary
var _world: Dictionary

func before_each() -> void:
	super.before_each()
	_cast = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_characters.json"))
	_dialogue = JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogue/water.json"))
	_world = FIELD.load_config()

func _script(path: String) -> Script:
	var script: Script = load(path) if ResourceLoader.exists(path) else null
	if script == null:
		_fail("Missing script: " + path)
	return script

func _defines(script: Script, method: String) -> bool:
	if script == null:
		return false
	for entry: Dictionary in script.get_script_method_list():
		if str(entry.name) == method:
			return true
	_fail("%s does not define %s()" % [script.resource_path, method])
	return false

func _step(id: String) -> Dictionary:
	var rules := _script(RULES_PATH)
	if not _defines(rules, "step"):
		return {}
	return rules.call("step", id)

func _npc_xz(id: String) -> Vector2:
	for spec: Dictionary in _cast.npcs:
		if str(spec.id) == id:
			for island: Dictionary in _world.islands:
				if str(island.id) == str(spec.island_id):
					return Vector2(float(island.center_xz_m[0]) + float(spec.island_local_offset[0]),
						float(island.center_xz_m[1]) + float(spec.island_local_offset[2]))
	return Vector2.INF

func _pocket() -> Dictionary:
	for pocket: Dictionary in _world.reward_pockets:
		if str(pocket.id) == POCKET:
			return pocket
	return {}

func _site_xz() -> Vector2:
	var at: Array = _step("gull_research_satchel").get("at_xz", [0.0, 0.0])
	return Vector2(float(at[0]), float(at[1]))

func _store(flags: Array) -> RefCounted:
	var store := PROGRESSION_STATE.new()
	for flag: String in flags:
		store.set_flag(flag)
	return store

func _verdict(step: String, flags: Array, at: Vector2) -> Dictionary:
	return DOCK_RULES.evaluate({"action_id": step, "realm": "water", "inventory": {}},
		{"peer": 7, "character_id": CHARACTER, "realm": "water", "position": Vector3(at.x, 3.0, at.y), "inventory": {}},
		_store(flags))

func _op(id: String) -> Dictionary:
	return {"op": "flag", "scope": "world", "realm": "water", "id": id, "value": true}

# --- data ------------------------------------------------------------------------

func test_three_steps_are_declared_world_records() -> void:
	var expected := {"gull_research_lead": [LEAD, "speech"], "gull_research_satchel": [SATCHEL, "site"],
		"gull_research_report": [DONE, "speech"]}
	for id: String in expected:
		var row := _step(id)
		assert_eq(str(row.get("chain", "")), CHAIN, "Step belongs to the chain: " + id)
		assert_eq(str(row.get("flag", "")), expected[id][0])
		assert_eq(str(row.get("kind", "")), expected[id][1])
		assert_eq(PROGRESSION_STATE.scope_of(str(expected[id][0])), "world", "World-scoped record: " + id)
		assert_false(row.has("grant") or row.has("cost"), "The satchel chain moves no item: " + id)
	assert_eq(str(_step("gull_research_lead").get("npc", "")), "water_adair", "Adair names Gull Rest")
	assert_eq(str(_step("gull_research_report").get("npc", "")), "water_adair", "Observations return to Adair")

func test_satchel_site_sits_in_the_authored_pocket_on_dry_ground() -> void:
	var pocket := _pocket()
	var site := _site_xz()
	var centre := Vector2(float(pocket.position[0]), float(pocket.position[2]))
	var field := FIELD.new()
	assert_true(site.distance_to(centre) <= float(pocket.radius_m), "Satchel is inside gull_research_satchel")
	assert_eq(field.island_id_at(site.x, site.y), "gull_rest", "Satchel stands on Gull Rest")
	assert_true(field.height_at(site.x, site.y) >= 0.8, "Satchel footing is dry, never underwater")
	var pickups: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PERSONAL.DATA))
	for row: Dictionary in pickups.pickups + pickups.harvest:
		var at := Vector2(float(row.position[0]), float(row.position[2]))
		assert_true(at.distance_to(site) >= 4.0, "Satchel prompt keeps apart from find %s" % str(row.id))
	var step := _step("gull_research_satchel")
	assert_true(ResourceLoader.exists(str(step.get("model", ""))), "Satchel uses an installed prop")

func test_candy_ii_is_the_existing_pocket_row_and_stays_ungated() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PERSONAL.DATA))
	var row: Dictionary = {}
	for candidate: Dictionary in data.pickups:
		if str(candidate.id) == CANDY:
			row = candidate
		assert_ne(str(candidate.get("item_id", "")), "research_satchel", "No satchel inventory row")
	assert_eq(row.get("reward_pocket_id", ""), POCKET)
	assert_eq(row.get("item_id", ""), "skill_candy_ii")
	assert_eq(row.get("claim_policy", ""), "character_once")
	assert_false(row.has("requires_world_flags"), "Candy II claimable on its own receipt")

# --- host rule -------------------------------------------------------------------

func test_lead_is_heard_beside_adair() -> void:
	var adair := _npc_xz("water_adair") + Vector2(2.0, 0.0)
	var ok := _verdict("gull_research_lead", [], adair)
	assert_true(bool(ok.ok), "Adair's lead accepted: " + str(ok.get("reason", "")))
	assert_eq(ok.ops, [_op(LEAD)])
	assert_eq(_verdict("gull_research_lead", [], adair + Vector2(30.0, 0.0)).code, "too_far")
	assert_eq(_verdict("gull_research_lead", [LEAD], adair).code, "already_done")

func test_satchel_needs_the_lead_and_the_island() -> void:
	var site := _site_xz() + Vector2(1.5, 0.0)
	var early := _verdict("gull_research_satchel", [], site)
	assert_eq(early.code, "prerequisite", "No satchel before Adair names it")
	assert_eq(_verdict("gull_research_satchel", [LEAD], _npc_xz("water_adair")).code, "too_far",
		"The satchel is recorded at Gull Rest, not from Brine Steps")
	var ok := _verdict("gull_research_satchel", [LEAD], site)
	assert_true(bool(ok.ok), "Satchel recorded at the site: " + str(ok.get("reason", "")))
	assert_eq(ok.ops, [_op(SATCHEL)], "A world record only: no inventory object")
	assert_eq(_verdict("gull_research_satchel", [LEAD, SATCHEL], site).code, "already_done")

func test_report_needs_the_satchel_and_adair() -> void:
	var adair := _npc_xz("water_adair") + Vector2(2.0, 0.0)
	var early := _verdict("gull_research_report", [LEAD], adair)
	assert_eq(early.code, "prerequisite")
	assert_true(str(early.reason).contains("Gull Rest"), "Refusal points at Gull Rest: " + str(early.reason))
	assert_eq(_verdict("gull_research_report", [LEAD, SATCHEL], _site_xz()).code, "too_far",
		"Observations are returned at Brine Steps")
	var ok := _verdict("gull_research_report", [LEAD, SATCHEL], adair)
	assert_true(bool(ok.ok), "Report accepted: " + str(ok.get("reason", "")))
	assert_eq(ok.ops, [_op(DONE)], "Completion record only; Candy II stays the pocket's own claim")
	assert_eq(_verdict("gull_research_report", [LEAD, SATCHEL, DONE], adair).code, "already_done")

func test_site_is_offered_only_while_open() -> void:
	var scene := _script(SCENE_PATH)
	if not _defines(scene, "site_offered"):
		return
	var row := _step("gull_research_satchel")
	assert_false(bool(scene.call("site_offered", row, _store([]))), "Hidden before the lead")
	assert_false(bool(scene.call("site_offered", row, null)), "Hidden without world state")
	assert_true(bool(scene.call("site_offered", row, _store([LEAD]))), "Offered after the lead")
	assert_false(bool(scene.call("site_offered", row, _store([LEAD, SATCHEL]))), "Gone once recorded")

# --- dialogue gating -------------------------------------------------------------

func _choose(world: Array) -> String:
	var script: Script = NPCS
	if not _defines(script, "choose_conversation"):
		return ""
	var spec: Dictionary = {}
	for candidate: Dictionary in _cast.npcs:
		if str(candidate.id) == "water_adair":
			spec = candidate
	var personal := _store([])
	var world_store := _store(world)
	return str(script.call("choose_conversation", spec, _cast.dialogue_event_guards, _dialogue.conversations,
		MERGED.new(world_store, personal), personal, world_store))

func _effect(conversation: String) -> String:
	for guard: Dictionary in _cast.dialogue_event_guards:
		if str(guard.get("conversation", "")) == conversation:
			return str(guard.get("effect", ""))
	return ""

func _text(conversation: String) -> String:
	var entry: Dictionary = _dialogue.conversations.get(conversation, {})
	assert_eq(str(entry.get("speaker", "")), "Surveyor Adair", "Speaker is Adair: " + conversation)
	var out := ""
	for line: Variant in entry.get("lines", []):
		assert_false(line is Dictionary and (line.has("effect") or line.has("effects")), "No line effect: " + conversation)
		out += (str(line.text) if line is Dictionary else str(line)) + "\n"
	return out

func test_adair_leads_reminds_hears_and_acknowledges() -> void:
	var lead := _choose([])
	assert_eq(lead, "water_adair_gull_lead", "Adair names Gull Rest first")
	assert_true(_text(lead).contains("Gull Rest") and _text(lead).contains("satchel"), "Lead names the island and satchel")
	assert_true(_text(lead).contains("foam"), "Lead keeps Adair's current-reading lesson")
	assert_eq(_effect(lead), "water:local_step:gull_research_lead")
	var reminder := _choose([LEAD])
	assert_eq(reminder, "water_adair_gull_reminder", "Open lead: reminder only")
	assert_eq(_effect(reminder), "")
	var report := _choose([LEAD, SATCHEL])
	assert_eq(report, "water_adair_gull_return", "Recovered satchel: Adair takes the observations")
	assert_eq(_effect(report), "water:local_step:gull_research_report")
	var thanks := _choose([LEAD, SATCHEL, DONE])
	assert_eq(thanks, "water_adair_gull_thanks", "Completed: acknowledgement")
	assert_true(_text(thanks).contains("route"), "Acknowledgement names the charted route")
	assert_eq(_effect(thanks), "")
	assert_eq(_choose([LEAD, SATCHEL, DONE, RESTORED]), "water_adair_post_gull")
	assert_eq(_choose([RESTORED]), "water_adair_gull_lead", "Lead still offered after restoration")

# --- quest log -------------------------------------------------------------------

func test_local_request_follows_the_chain() -> void:
	var store := PROGRESSION_STATE.new()
	var reader := QUEST_LOG.new()
	reader.set_realm("water")
	var find := func() -> Dictionary:
		for entry: Dictionary in reader.local_entries(store):
			if str(entry.label).contains("Gull Rest"):
				return entry
		return {}
	assert_true(find.call().is_empty(), "Not pre-labelled")
	store.set_flag(LEAD)
	var entry: Dictionary = find.call()
	assert_false(entry.is_empty(), "Adair's lead reveals the request")
	assert_false(bool(entry.get("done", true)))
	assert_eq(entry.get("scope", ""), "world")
	assert_true(str(entry.get("how", "")).contains("Brine Steps"), "Hint names where to return")
	store.set_flag(SATCHEL)
	assert_false(bool(find.call().get("done", true)), "Satchel alone does not finish it")
	store.set_flag(DONE)
	assert_true(bool(find.call().get("done", false)))
