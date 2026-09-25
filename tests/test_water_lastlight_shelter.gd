extends "res://tests/test_case.gd"
## F13 `side_water_lastlight_shelter` (WORLD §Tidewake local chains): Halen
## reveals the sheltered route beside Lastlight; deliver 4 Driftwood + 4 Reed
## Fibre to the existing legal camp; rest one assigned companion there, before
## or after Venn. Payoff: one permanent shared sheltered creature-bed site and
## Halen's acknowledgement. Never interior access before the controls/Nerissa;
## the delivery and shelter stand on the exterior; the optional cost leaves a
## saddle's materials available.
##
## Three recorded steps, each a host-validated `water_dock_action`: Halen's
## lead, the delivery at the Veilfall camp (host debits the deliverer's
## materials, like the Reedhaven dock repair), and the rest at that camp's own
## creature bed (the requester's rest proof, as party/inventory proof).
## Production path: tests/smoke_water_lastlight_shelter.gd.
const RULES_PATH := "res://scripts/world/water_local_chain_rules.gd"
const SCENE_PATH := "res://scripts/world/water_local_chains.gd"
const DOCK_RULES := preload("res://scripts/world/water_dock_rules.gd")
const NPCS := preload("res://scripts/world/water_scene_npcs.gd")
const FIELD := preload("res://scripts/world/water_heightfield.gd")
const PROGRESSION_STATE := preload("res://autoload/progression_state.gd")
const MERGED := preload("res://autoload/merged_progression.gd")
const QUEST_LOG := preload("res://scripts/world/quest_log.gd")

const CHAIN := "side_water_lastlight_shelter"
const LEAD := "water_claim:local:lastlight_shelter:lead"
const SUPPLIED := "water_claim:local:lastlight_shelter:supplied"
const RESTED := "water_claim:local:lastlight_shelter:rested"
const RESTORED := "water_currents_restored"
const CAMP := "water_camp_veilfall"
const CHARACTER := "lastlight-check"

var _cast: Dictionary
var _dialogue: Dictionary
var _camps: Dictionary

func before_each() -> void:
	super.before_each()
	_cast = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_characters.json"))
	_dialogue = JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogue/water.json"))
	_camps = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_camps.json"))

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

func _camp() -> Dictionary:
	for row: Dictionary in _camps.camps:
		if str(row.id) == CAMP:
			return row
	return {}

func _camp_xz() -> Vector2:
	var row := _camp()
	return Vector2(float(row.at[0]), float(row.at[1]))

func _bed_xz() -> Vector2:
	var offset: Array = _camps.tuning.creature_bed_offset_xz
	return _camp_xz() + Vector2(float(offset[0]), float(offset[1]))

func _halen_xz() -> Vector2:
	var world := FIELD.load_config()
	for spec: Dictionary in _cast.npcs:
		if str(spec.id) == "water_halen":
			for island: Dictionary in world.islands:
				if str(island.id) == str(spec.island_id):
					return Vector2(float(island.center_xz_m[0]) + float(spec.island_local_offset[0]),
						float(island.center_xz_m[1]) + float(spec.island_local_offset[2]))
	return Vector2.INF

func _site_xz(id: String) -> Vector2:
	var at: Array = _step(id).get("at_xz", [0.0, 0.0])
	return Vector2(float(at[0]), float(at[1]))

func _store(flags: Array) -> RefCounted:
	var store := PROGRESSION_STATE.new()
	for flag: String in flags:
		store.set_flag(flag)
	return store

func _verdict(step: String, flags: Array, at: Vector2, extra: Dictionary = {}) -> Dictionary:
	var intent := {"action_id": step, "realm": "water", "inventory": extra.get("inventory", {})}
	intent.merge(extra, false)
	return DOCK_RULES.evaluate(intent,
		{"peer": 7, "character_id": CHARACTER, "realm": "water", "position": Vector3(at.x, 6.0, at.y),
			"inventory": extra.get("inventory", {})}, _store(flags))

func _op(id: String) -> Dictionary:
	return {"op": "flag", "scope": "world", "realm": "water", "id": id, "value": true}

# --- data ------------------------------------------------------------------------

func test_three_steps_are_declared_world_records() -> void:
	var expected := {"lastlight_shelter_lead": [LEAD, "speech"], "lastlight_shelter_supply": [SUPPLIED, "site"],
		"lastlight_shelter_rest": [RESTED, "rest"]}
	for id: String in expected:
		var row := _step(id)
		assert_eq(str(row.get("chain", "")), CHAIN, "Step belongs to the chain: " + id)
		assert_eq(str(row.get("flag", "")), expected[id][0])
		assert_eq(str(row.get("kind", "")), expected[id][1])
		assert_eq(PROGRESSION_STATE.scope_of(str(expected[id][0])), "world", "World-scoped record: " + id)
	assert_eq(str(_step("lastlight_shelter_lead").get("npc", "")), "water_halen", "Halen reveals the route")
	var cost: Dictionary = _step("lastlight_shelter_supply").get("cost", {})
	assert_eq(cost.keys().size(), 2, "Two delivered materials")
	assert_eq(int(cost.get("driftwood", 0)), 4, "4 Driftwood")
	assert_eq(int(cost.get("reed_fiber", 0)), 4, "4 Reed Fibre")
	assert_false(_step("lastlight_shelter_supply").has("grant"), "The shelter is the payoff, not an item")

func test_delivery_and_rest_are_at_the_existing_veilfall_camp_exterior() -> void:
	assert_false(_camp().is_empty(), "Existing legal Veilfall camp")
	var field := FIELD.new()
	var supply := _site_xz("lastlight_shelter_supply")
	assert_true(supply.distance_to(_camp_xz()) <= 8.0, "Delivery is at the existing camp")
	assert_eq(field.island_id_at(supply.x, supply.y), "veilfall")
	assert_true(field.height_at(supply.x, supply.y) >= 0.8, "Dry delivery footing")
	assert_true(supply.distance_to(_bed_xz()) >= 3.0, "Delivery prompt keeps apart from the bed's own prompt")
	var rest := _step("lastlight_shelter_rest")
	assert_almost_eq(_site_xz("lastlight_shelter_rest").distance_to(_bed_xz()), 0.0, 0.01, "Rest is the camp's own creature bed")
	assert_eq(int(rest.get("bed_index", 0)), int(_camp().creature_bed_index), "Same bed index as the camp")
	var veilfall: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_veilfall.json"))
	var interior := Vector2(float(veilfall.interior_origin[0]), float(veilfall.interior_origin[2]))
	assert_true(supply.distance_to(interior) > 500.0, "Nowhere near the concealed interior staging area")
	for control: Dictionary in veilfall.controls:
		for flag: Variant in control.get("requires", []):
			assert_false(str(flag).begins_with("water_claim:local:lastlight_shelter"), "The chain opens no interior control")
	for id: String in ["lastlight_shelter_lead", "lastlight_shelter_supply", "lastlight_shelter_rest"]:
		for flag: Variant in _step(id).get("requires_flags", []):
			assert_false(str(flag).contains("venn") or str(flag).contains("nerissa"), "Before or after Venn: " + id)

func test_optional_cost_leaves_every_character_a_saddle() -> void:
	# World-once harvest totals must pay the mandatory Reedhaven repair, four
	# characters' Swim Saddles and this shelter together.
	var pickups: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_pickups.json"))
	var crafting: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_crafting.json"))
	var dock: Dictionary = DOCK_RULES.load_data()
	var have := {"driftwood": 0, "reed_fiber": 0}
	for row: Dictionary in pickups.harvest:
		if have.has(str(row.item_id)):
			have[str(row.item_id)] += int(row.get("yield", 1))
	var saddle: Dictionary = {}
	for part: Dictionary in crafting.recipes.get("water_swim_saddle", {}).get("cost", []):
		saddle[str(part.id)] = int(part.n)
	assert_false(saddle.is_empty(), "Swim Saddle recipe found")
	var repair: Dictionary = {}
	for action: Dictionary in dock.actions:
		if str(action.id) == "reedhaven_repair":
			repair = action.cost
	var shelter: Dictionary = _step("lastlight_shelter_supply").get("cost", {})
	for item: String in have:
		var need := int(repair.get(item, 0)) + 4 * int(saddle.get(item, 0)) + int(shelter.get(item, 0))
		assert_true(int(have[item]) >= need, "%s: %d harvestable covers repair + four saddles + shelter (%d)" % [item, have[item], need])

# --- host rule -------------------------------------------------------------------

func test_lead_is_heard_beside_halen() -> void:
	var ok := _verdict("lastlight_shelter_lead", [], _halen_xz() + Vector2(2.0, 0.0))
	assert_true(bool(ok.ok), "Halen's lead accepted: " + str(ok.get("reason", "")))
	assert_eq(ok.ops, [_op(LEAD)])

func test_delivery_debits_the_deliverer_once() -> void:
	var at := _site_xz("lastlight_shelter_supply") + Vector2(1.0, 0.0)
	var enough := {"inventory": {"driftwood": 5, "reed_fiber": 4}}
	assert_eq(_verdict("lastlight_shelter_supply", [], at, enough).code, "prerequisite", "Not before Halen's lead")
	var short := _verdict("lastlight_shelter_supply", [LEAD], at, {"inventory": {"driftwood": 4, "reed_fiber": 3}})
	assert_eq(short.code, "materials", "Short delivery refused")
	assert_true(str(short.reason).contains("4 driftwood") and str(short.reason).contains("4 reed fiber"),
		"Refusal names the delivery: " + str(short.reason))
	assert_eq(_verdict("lastlight_shelter_supply", [LEAD], at, {"inventory": "lots"}).code, "malformed")
	assert_eq(_verdict("lastlight_shelter_supply", [LEAD], _halen_xz(), enough).code, "too_far",
		"Delivered at the camp, not to Halen")
	var ok := _verdict("lastlight_shelter_supply", [LEAD], at, enough)
	assert_true(bool(ok.ok), "Delivery accepted: " + str(ok.get("reason", "")))
	var takes: Array = []
	for op: Dictionary in ok.ops:
		if str(op.op) == "item_take":
			takes.append([op.item, int(op.count), op.peers, op.get("txn_id", "")])
	takes.sort()
	assert_eq(takes, [["driftwood", 4, [7], SUPPLIED], ["reed_fiber", 4, [7], SUPPLIED]],
		"Exactly the deliverer's 4 + 4, txn-guarded by the record")
	assert_true(ok.ops.has(_op(SUPPLIED)), "Shelter record committed with the debit")
	assert_eq(_verdict("lastlight_shelter_supply", [LEAD, SUPPLIED], at, enough).code, "already_done",
		"One permanent shelter: never a second delivery")

func test_rest_needs_the_shelter_and_the_camp_bed() -> void:
	var bed := _bed_xz() + Vector2(1.5, 0.0)
	var proof := {"resting_bed_index": int(_camp().creature_bed_index)}
	assert_eq(_verdict("lastlight_shelter_rest", [LEAD], bed, proof).code, "prerequisite", "No rest record before the delivery")
	assert_eq(_verdict("lastlight_shelter_rest", [LEAD, SUPPLIED], bed, {"resting_bed_index": -41}).code, "rest",
		"A companion resting in another camp's bed does not count")
	assert_eq(_verdict("lastlight_shelter_rest", [LEAD, SUPPLIED], bed, {}).code, "rest", "No rest proof")
	var ok := _verdict("lastlight_shelter_rest", [LEAD, SUPPLIED], bed, proof)
	assert_true(bool(ok.ok), "Rest recorded: " + str(ok.get("reason", "")))
	assert_eq(ok.ops, [_op(RESTED)], "Record only; rest recovery stays the bed's own")
	assert_eq(_verdict("lastlight_shelter_rest", [LEAD, SUPPLIED, RESTED], bed, proof).code, "already_done")

func test_rest_is_watched_only_while_open() -> void:
	var scene := _script(SCENE_PATH)
	if not _defines(scene, "rest_wanted"):
		return
	var row := _step("lastlight_shelter_rest")
	var bed := int(_camp().creature_bed_index)
	assert_false(bool(scene.call("rest_wanted", row, _store([LEAD]), [bed])), "Before the delivery")
	assert_false(bool(scene.call("rest_wanted", row, _store([LEAD, SUPPLIED]), [])), "No companion resting")
	assert_false(bool(scene.call("rest_wanted", row, _store([LEAD, SUPPLIED]), [-41])), "Resting elsewhere")
	assert_true(bool(scene.call("rest_wanted", row, _store([LEAD, SUPPLIED]), [-41, bed])), "Resting in the Veilfall bed")
	assert_false(bool(scene.call("rest_wanted", row, _store([LEAD, SUPPLIED, RESTED]), [bed])), "Already recorded")

# --- dialogue gating -------------------------------------------------------------

func _choose(world: Array) -> String:
	var script: Script = NPCS
	if not _defines(script, "choose_conversation"):
		return ""
	var spec: Dictionary = {}
	for candidate: Dictionary in _cast.npcs:
		if str(candidate.id) == "water_halen":
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
	assert_eq(str(entry.get("speaker", "")), "Campkeeper Halen", "Speaker is Halen: " + conversation)
	var out := ""
	for line: Variant in entry.get("lines", []):
		assert_false(line is Dictionary and (line.has("effect") or line.has("effects")), "No line effect: " + conversation)
		out += (str(line.text) if line is Dictionary else str(line)) + "\n"
	return out

func test_halen_leads_reminds_and_acknowledges() -> void:
	var lead := _choose([])
	assert_eq(lead, "water_halen_shelter_lead", "Halen reveals the sheltered route first")
	assert_true(_text(lead).contains("Lastlight") and _text(lead).contains("driftwood") and _text(lead).contains("reed"),
		"Lead names Lastlight and the delivery")
	assert_true(_text(lead).contains("Venn"), "Lead keeps Halen's climb guidance")
	assert_eq(_effect(lead), "water:local_step:lastlight_shelter_lead")
	assert_eq(_choose([LEAD]), "water_halen_shelter_reminder")
	var rest := _choose([LEAD, SUPPLIED])
	assert_eq(rest, "water_halen_shelter_rest", "Built: Halen asks for a companion to rest there")
	assert_eq(_effect(rest), "", "Resting is done at the bed, not in speech")
	var thanks := _choose([LEAD, SUPPLIED, RESTED])
	assert_eq(thanks, "water_halen_shelter_thanks")
	assert_true(_text(thanks).contains("shelter"))
	assert_eq(_choose([LEAD, SUPPLIED, RESTED, RESTORED]), "water_halen_post_shelter")
	assert_eq(_choose([RESTORED]), "water_halen_shelter_lead", "Lead still offered after restoration")

# --- quest log -------------------------------------------------------------------

func test_local_request_follows_the_chain() -> void:
	var store := PROGRESSION_STATE.new()
	var reader := QUEST_LOG.new()
	reader.set_realm("water")
	var find := func() -> Dictionary:
		for entry: Dictionary in reader.local_entries(store):
			if str(entry.label).contains("Lastlight"):
				return entry
		return {}
	assert_true(find.call().is_empty(), "Not pre-labelled")
	store.set_flag(LEAD)
	var entry: Dictionary = find.call()
	assert_false(entry.is_empty(), "Halen's lead reveals the request")
	assert_eq(entry.get("scope", ""), "world")
	assert_true(str(entry.get("how", "")).contains("4 driftwood") and str(entry.get("how", "")).contains("4 reed fiber"))
	store.set_flag(SUPPLIED)
	assert_false(bool(find.call().get("done", true)), "Delivery alone does not finish it")
	store.set_flag(RESTED)
	assert_true(bool(find.call().get("done", false)))
