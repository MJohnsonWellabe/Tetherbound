extends "res://tests/test_case.gd"
## F13 `side_water_garden_records` (WORLD §Tidewake local chains): Edda points
## to the visible above-water Drowned Garden vault; reach it by the lawful
## route; bring the recorded wall account back to Salt Crown, where Edda
## explains the pre-Tether dock history. Payoff: the EXISTING
## `garden_exposed_vault` Skill Candy II. No diving/oxygen, and the conclusion
## is Edda's history, not a chest.
##
## Three recorded steps, each a host-validated `water_dock_action`: the lead
## beside Edda, the wall account at the vault, the report beside Edda. Edda's
## Guardian ceremony keeps priority over her chain lines. Production path:
## tests/smoke_water_garden_records.gd.
const RULES_PATH := "res://scripts/world/water_local_chain_rules.gd"
const SCENE_PATH := "res://scripts/world/water_local_chains.gd"
const DOCK_RULES := preload("res://scripts/world/water_dock_rules.gd")
const NPCS := preload("res://scripts/world/water_scene_npcs.gd")
const FIELD := preload("res://scripts/world/water_heightfield.gd")
const PROGRESSION_STATE := preload("res://autoload/progression_state.gd")
const MERGED := preload("res://autoload/merged_progression.gd")
const QUEST_LOG := preload("res://scripts/world/quest_log.gd")
const PERSONAL := preload("res://scripts/world/water_personal_pickup.gd")

const REWARD := preload("res://scripts/world/water_guardian_reward.gd")
const CHAIN := "side_water_garden_records"
const CANDY := "water:drowned_garden:pickup:002"
const POCKET := "garden_exposed_vault"
const LEAD := "water_claim:local:garden_records:lead"
const ACCOUNT := "water_claim:local:garden_records:account"
const DONE := "water_claim:local:garden_records:complete"
const RESTORED := "water_currents_restored"
const FREED := "water_guardian_freed"
const CHARACTER := "garden-check"

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
	var at: Array = _step("garden_records_wall").get("at_xz", [0.0, 0.0])
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
	var expected := {"garden_records_lead": [LEAD, "speech"], "garden_records_wall": [ACCOUNT, "site"],
		"garden_records_report": [DONE, "speech"]}
	for id: String in expected:
		var row := _step(id)
		assert_eq(str(row.get("chain", "")), CHAIN, "Step belongs to the chain: " + id)
		assert_eq(str(row.get("flag", "")), expected[id][0])
		assert_eq(str(row.get("kind", "")), expected[id][1])
		assert_eq(PROGRESSION_STATE.scope_of(str(expected[id][0])), "world", "World-scoped record: " + id)
		assert_false(row.has("grant") or row.has("cost"), "The account moves no item: " + id)
	assert_eq(str(_step("garden_records_lead").get("npc", "")), "water_edda", "Edda points to the vault")
	assert_eq(str(_step("garden_records_report").get("npc", "")), "water_edda", "The account comes back to Edda")

func test_wall_site_is_in_the_above_water_vault_pocket() -> void:
	var pocket := _pocket()
	var site := _site_xz()
	var centre := Vector2(float(pocket.position[0]), float(pocket.position[2]))
	var field := FIELD.new()
	assert_true(site.distance_to(centre) <= float(pocket.radius_m), "Wall account is inside garden_exposed_vault")
	assert_eq(field.island_id_at(site.x, site.y), "drowned_garden", "The vault stands on the Drowned Garden")
	assert_true(field.height_at(site.x, site.y) >= 0.8, "Above water: no diving or oxygen")
	var pickups: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PERSONAL.DATA))
	for row: Dictionary in pickups.pickups + pickups.harvest:
		var at := Vector2(float(row.position[0]), float(row.position[2]))
		assert_true(at.distance_to(site) >= 4.0, "Wall prompt keeps apart from find %s" % str(row.id))
	assert_true(ResourceLoader.exists(str(_step("garden_records_wall").get("model", ""))), "Wall uses an installed piece")

func test_candy_ii_is_the_existing_pocket_row_and_stays_ungated() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PERSONAL.DATA))
	var row: Dictionary = {}
	for candidate: Dictionary in data.pickups:
		if str(candidate.id) == CANDY:
			row = candidate
	assert_eq(row.get("reward_pocket_id", ""), POCKET)
	assert_eq(row.get("item_id", ""), "skill_candy_ii")
	assert_eq(row.get("claim_policy", ""), "character_once")
	assert_false(row.has("requires_world_flags"), "Candy II claimable on its own receipt")

# --- host rule -------------------------------------------------------------------

func test_lead_is_heard_beside_edda() -> void:
	var edda := _npc_xz("water_edda") + Vector2(2.0, 0.0)
	var ok := _verdict("garden_records_lead", [], edda)
	assert_true(bool(ok.ok), "Edda's lead accepted: " + str(ok.get("reason", "")))
	assert_eq(ok.ops, [_op(LEAD)])
	assert_eq(_verdict("garden_records_lead", [], edda + Vector2(30.0, 0.0)).code, "too_far")

func test_wall_account_is_copied_at_the_vault() -> void:
	var site := _site_xz() + Vector2(0.0, 1.5)
	assert_eq(_verdict("garden_records_wall", [], site).code, "prerequisite", "Not before Edda's lead")
	assert_eq(_verdict("garden_records_wall", [LEAD], _npc_xz("water_edda")).code, "too_far",
		"The account is copied at the vault, not from Salt Crown")
	var ok := _verdict("garden_records_wall", [LEAD], site)
	assert_true(bool(ok.ok), "Account copied at the wall: " + str(ok.get("reason", "")))
	assert_eq(ok.ops, [_op(ACCOUNT)], "A world record only")
	assert_eq(_verdict("garden_records_wall", [LEAD, ACCOUNT], site).code, "already_done")

func test_report_needs_the_account_and_edda() -> void:
	var edda := _npc_xz("water_edda") + Vector2(2.0, 0.0)
	var early := _verdict("garden_records_report", [LEAD], edda)
	assert_eq(early.code, "prerequisite")
	assert_true(str(early.reason).contains("vault"), "Refusal points at the vault: " + str(early.reason))
	assert_eq(_verdict("garden_records_report", [LEAD, ACCOUNT], _site_xz()).code, "too_far",
		"The account is brought back to Salt Crown")
	var ok := _verdict("garden_records_report", [LEAD, ACCOUNT], edda)
	assert_true(bool(ok.ok), "Report accepted: " + str(ok.get("reason", "")))
	assert_eq(ok.ops, [_op(DONE)], "Completion record only; Candy II stays the pocket's own claim")
	assert_eq(_verdict("garden_records_report", [LEAD, ACCOUNT, DONE], edda).code, "already_done")

func test_wall_is_offered_only_while_open() -> void:
	var scene := _script(SCENE_PATH)
	if not _defines(scene, "site_offered"):
		return
	var row := _step("garden_records_wall")
	assert_false(bool(scene.call("site_offered", row, _store([]))), "Unoffered before the lead")
	assert_true(bool(scene.call("site_offered", row, _store([LEAD]))), "Offered after the lead")
	assert_false(bool(scene.call("site_offered", row, _store([LEAD, ACCOUNT]))), "Unoffered once copied")
	assert_false(bool(row.get("hide_when_done", false)), "The vault wall itself stays standing")
	assert_true(bool(row.get("always_visible", false)), "The vault wall is visible before Edda's lead: it is the lure")

# --- dialogue gating -------------------------------------------------------------

func _edda() -> Dictionary:
	for candidate: Dictionary in _cast.npcs:
		if str(candidate.id) == "water_edda":
			return candidate
	return {}

func _choose(world: Array) -> String:
	var script: Script = NPCS
	if not _defines(script, "choose_conversation"):
		return ""
	var personal := _store([])
	var world_store := _store(world)
	return str(script.call("choose_conversation", _edda(), _cast.dialogue_event_guards, _dialogue.conversations,
		MERGED.new(world_store, personal), personal, world_store))

func _chain_choice(world: Array) -> String:
	var script: Script = NPCS
	if not _defines(script, "chain_conversation_for"):
		return ""
	var personal := _store([])
	var world_store := _store(world)
	return str(script.call("chain_conversation_for", _edda(), _cast.dialogue_event_guards, _dialogue.conversations,
		MERGED.new(world_store, personal), personal, world_store))

func _effect(conversation: String) -> String:
	for guard: Dictionary in _cast.dialogue_event_guards:
		if str(guard.get("conversation", "")) == conversation:
			return str(guard.get("effect", ""))
	return ""

func _text(conversation: String) -> String:
	var entry: Dictionary = _dialogue.conversations.get(conversation, {})
	assert_eq(str(entry.get("speaker", "")), "Shrinekeeper Edda", "Speaker is Edda: " + conversation)
	var out := ""
	for line: Variant in entry.get("lines", []):
		assert_false(line is Dictionary and (line.has("effect") or line.has("effects")), "No line effect: " + conversation)
		out += (str(line.text) if line is Dictionary else str(line)) + "\n"
	return out

func test_edda_leads_reminds_hears_and_explains_the_docks() -> void:
	var lead := _choose([])
	assert_eq(lead, "water_edda_garden_lead", "Edda points to the vault first")
	assert_true(_text(lead).contains("Drowned Garden") and _text(lead).contains("vault"), "Lead names the garden vault")
	assert_true(_text(lead).contains("Tideglass Compass") and _text(lead).contains("Deep Watcher"),
		"Lead keeps Edda's relic and Deep Watcher guidance")
	assert_eq(_effect(lead), "water:local_step:garden_records_lead")
	assert_eq(_choose([LEAD]), "water_edda_garden_reminder")
	assert_eq(_effect("water_edda_garden_reminder"), "")
	var report := _choose([LEAD, ACCOUNT])
	assert_eq(report, "water_edda_garden_return", "Copied account: Edda hears it")
	assert_eq(_effect(report), "water:local_step:garden_records_report")
	assert_true(_text(report).contains("dock") and _text(report).contains("Tether"), "Edda explains pre-Tether dock history")
	assert_eq(_choose([LEAD, ACCOUNT, DONE]), "water_edda_garden_thanks")
	assert_eq(_choose([LEAD, ACCOUNT, DONE, RESTORED]), "water_edda_post_garden")
	assert_eq(_choose([RESTORED]), "water_edda_garden_lead", "Lead still offered after restoration")

func test_guardian_ceremony_keeps_priority_over_the_chain() -> void:
	# After the freeing Edda's greet is routed by the Guardian participant gate;
	# a pending chain step outranks her neutral/post line, never the offer.
	assert_eq(_chain_choice([FREED, LEAD, ACCOUNT]), "water_edda_garden_return", "Chain report available post-freeing")
	assert_eq(_chain_choice([FREED, LEAD]), "", "An open lead has no chain request to make")
	assert_eq(_chain_choice([FREED]), "", "The routed greeting offers no new lead: an answered character hears her post line")
	var script: Script = REWARD
	if not _defines(script, "edda_with_chain"):
		return
	assert_eq(script.call("edda_with_chain", REWARD.EDDA_OFFER, "water_edda_garden_return"), REWARD.EDDA_OFFER,
		"The Guardian offer always wins")
	assert_eq(script.call("edda_with_chain", REWARD.EDDA_NEUTRAL, "water_edda_garden_return"), "water_edda_garden_return")
	assert_eq(script.call("edda_with_chain", REWARD.EDDA_POST, ""), REWARD.EDDA_POST)
	assert_eq(script.call("edda_with_chain", "", "water_edda_garden_lead"), "water_edda_garden_lead")

# --- quest log -------------------------------------------------------------------

func test_local_request_follows_the_chain() -> void:
	var store := PROGRESSION_STATE.new()
	var reader := QUEST_LOG.new()
	reader.set_realm("water")
	var find := func() -> Dictionary:
		for entry: Dictionary in reader.local_entries(store):
			if str(entry.label).contains("Drowned Garden"):
				return entry
		return {}
	assert_true(find.call().is_empty(), "Not pre-labelled")
	store.set_flag(LEAD)
	var entry: Dictionary = find.call()
	assert_false(entry.is_empty(), "Edda's lead reveals the request")
	assert_eq(entry.get("scope", ""), "world")
	assert_true(str(entry.get("how", "")).contains("Salt Crown"), "Hint names where to return")
	assert_false(str(entry.get("how", "")).to_lower().contains("dive"), "No diving")
	store.set_flag(ACCOUNT)
	assert_false(bool(find.call().get("done", true)))
	store.set_flag(DONE)
	assert_true(bool(find.call().get("done", false)))
