extends "res://tests/test_case.gd"

## F13#2 `reed_root_hollow` recipe half (role recipe_and_reed_fiber).
##
## The hollow's reed patch (water_pickups.json water:reedhaven:harvest:012) is a
## character-once claim: the host validates it through
## `water_personal_pickup.gd` and the committed delta grants that character its
## 3 Reed Fiber and teaches it Reed Camp Cordage (`water_camp_cordage`,
## unlocked_by `water_cordage_recipe_learned`). Chapter start alone no longer
## teaches it; a character that knew it from chapter start keeps it
## (`scripts/save/water_recipe_migration.gd`).
##
## Co-op per-character claim: two characters (host peer 1, guest peer 2) run
## through the real WorldLedger commit (the ledger_rpc host path minus the
## transport: `_water_actor` and `_actor_character_id` are what ledger_rpc
## fills from the session, never from the request), and each applies only the
## player ops `WorldLedger.player_ops_for()` addresses to its own peer -- the
## same filter `ledger_rpc.gd::_apply_player_ops()` uses. DISCLOSED FIXTURE:
## host positions are the authored row positions on the analytic heightfield
## (no walk; the walk is `tests/smoke_water_pocket_walk_claim.gd`).

const RULE := preload("res://scripts/world/water_personal_pickup.gd")
const MIGRATION := preload("res://scripts/save/water_recipe_migration.gd")
const CHAPTER := preload("res://scripts/world/water_chapter.gd")
const WORLD_LEDGER := preload("res://scripts/net/world_ledger.gd")
const WORLD_STATE := preload("res://autoload/world_state.gd")
const PLAYER_STATE := preload("res://autoload/player_state.gd")
const GAME_STATE := preload("res://autoload/game_state.gd")
const ITEM_DB := preload("res://autoload/item_db.gd")
const PROGRESSION_STATE := preload("res://autoload/progression_state.gd")
const CRAFTING := "res://data/config/water_crafting.json"
const REED_ROW := "water:reedhaven:harvest:012"
const RECIPE := "water_camp_cordage"

var db: RefCounted
var world: RefCounted
var ledger: RefCounted
var states: Array[Node] = []


func before_each() -> void:
	db = ITEM_DB.new()
	world = WORLD_STATE.new()
	ledger = WORLD_LEDGER.new(world)
	states.clear()


func after_each() -> void:
	for state: Node in states:
		if is_instance_valid(state):
			state.free()
	states.clear()


func _character() -> Node:
	var state: Node = GAME_STATE.new()
	state.items = db
	states.append(state)
	return state


func _json(path: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(path)) as Dictionary


func _row(id: String) -> Dictionary:
	return RULE.personal_row(_json(RULE.DATA), id)


func _at(row: Dictionary) -> Vector3:
	var at: Array = row.position
	return Vector3(float(at[0]), RULE.FIELD.new().height_at(float(at[0]), float(at[2])), float(at[2]))


## One host-side claim, applied to the claimant's own state the way
## ledger_rpc applies a committed delta on that peer.
func _claim(state: Node, peer: int, character: String, row_id: String, extra: Dictionary = {}) -> Dictionary:
	var intent := {"kind": "water_personal_pickup", "realm": "water", "pickup_id": row_id,
		"personal_claimed": state.local.flags.has(RULE.personal_flag(row_id)),
		"_actor_character_id": character,
		"_water_actor": {"peer": peer, "character_id": character, "realm": "water", "position": _at(_row(row_id))}}
	intent.merge(extra, true)
	var verdict: Dictionary = ledger.commit(intent, peer)
	if bool(verdict.ok):
		_apply(state, verdict.delta, peer)
	return verdict


func _apply(state: Node, delta: Dictionary, peer: int) -> void:
	for op: Dictionary in WORLD_LEDGER.player_ops_for(delta, peer):
		match str(op.op):
			"flag":
				state.local.flags.set_flag(str(op.id), bool(op.get("value", true)))
			"item_grant":
				state.inventory.add(str(op.item), int(op.count))


func _candy_pocket_row() -> String:
	for row: Dictionary in _json(RULE.DATA).pickups:
		if str(row.get("reward_pocket_id", "")) != "" and str(row.get("category", "")) == "skill_candy" \
				and (row.get("requires_world_flags", []) as Array).is_empty():
			return str(row.id)
	return ""


func test_data_gates_cordage_on_the_hollow_claim_only() -> void:
	var recipes: Dictionary = _json(CRAFTING).recipes
	assert_eq(str(recipes[RECIPE].unlocked_by), MIGRATION.LEARNED)
	assert_true((recipes[RECIPE].requires_personal_flags as Array).has(MIGRATION.LEARNED))
	assert_eq(db.recipe_unlock_flag(RECIPE), MIGRATION.LEARNED, "ItemDB merged the gated recipe")
	for id: String in recipes:
		if id != RECIPE and id != "water_swim_saddle":
			assert_eq(str(recipes[id].unlocked_by), "water_chapter_started", id + " unchanged")
	var row := _row(REED_ROW)
	assert_eq(str(row.get("placement_kind", "")), "harvest")
	assert_eq(str(row.reward_pocket_id), "reed_root_hollow")
	assert_eq(str(row.learn_recipe_flag), MIGRATION.LEARNED)
	var taught := 0
	for harvest: Dictionary in _json(RULE.DATA).harvest:
		if harvest.has("learn_recipe_flag"):
			taught += 1
	assert_eq(taught, 1, "Only the hollow teaches a recipe")
	for flag: String in [MIGRATION.LEARNED, MIGRATION.GATE_MARKER]:
		assert_eq(PROGRESSION_STATE.scope_of(flag), PROGRESSION_STATE.SCOPE_PLAYER, flag + " is character scoped")
	assert_eq(PROGRESSION_STATE.scope_of(RULE.personal_flag(REED_ROW)), PROGRESSION_STATE.SCOPE_PLAYER)
	assert_eq(PROGRESSION_STATE.scope_of("water_claim:c:" + REED_ROW), PROGRESSION_STATE.SCOPE_WORLD)


func test_chapter_start_alone_no_longer_teaches_cordage() -> void:
	var state := _character()
	assert_true(CHAPTER.apply_personal_event(state.local.flags, "arrival", "water"))
	assert_true(state.local.flags.has("water_chapter_started"))
	assert_true(state.local.flags.has(MIGRATION.GATE_MARKER), "arrival stamps the gate marker")
	assert_false(state.recipe_known(RECIPE), "new character does not know cordage at chapter start")
	assert_false(state.known_recipe_ids().has(RECIPE), "craft list hides it")
	state.inventory.add("reed_fiber", 10)
	assert_false(state.can_craft(RECIPE))
	assert_false(state.craft(RECIPE))
	assert_eq(state.inventory.count("reed_fiber"), 10, "refused craft spends nothing")
	assert_true(state.recipe_known("water_camp_boards"), "other chapter recipes still known")
	# A later arrival (return trip) never grants it either.
	CHAPTER.apply_personal_event(state.local.flags, "arrival", "water")
	assert_false(state.recipe_known(RECIPE))


func test_two_characters_each_claim_the_hollow_and_a_candy_pocket_once() -> void:
	var host := _character()
	var guest := _character()
	for state: Node in [host, guest]:
		CHAPTER.apply_personal_event(state.local.flags, "arrival", "water")
	var candy := _candy_pocket_row()
	assert_false(candy.is_empty(), "an ungated candy pocket exists")
	var candy_item := str(_row(candy).item_id)
	var candy_count := int(_row(candy).quantity)

	# Host claims the hollow. A forged count/item in the request is ignored.
	var first := _claim(host, 1, "character-A", REED_ROW, {"item": "revive", "count": 99, "amount": 50})
	assert_true(bool(first.ok), "host claim accepted: %s" % str(first.get("code", "")))
	assert_eq(host.inventory.count("reed_fiber"), 3, "host got the authored 3 fiber")
	assert_eq(host.inventory.count("revive"), 0)
	assert_true(host.recipe_known(RECIPE), "host learned cordage from its own claim")
	assert_true(world.flags.has("water_claim:character-A:" + REED_ROW), "world receipt names character A")
	# The guest's process only applies ops addressed to it.
	_apply(guest, first.delta, 2)
	assert_false(guest.recipe_known(RECIPE), "host's claim teaches the guest nothing")
	assert_eq(guest.inventory.count("reed_fiber"), 0, "host's claim pays the guest nothing")

	# Host repeats: refused by portable proof, and by the world receipt alone.
	assert_eq(str(_claim(host, 1, "character-A", REED_ROW).code), "already_taken")
	host.local.flags.set_flag(RULE.personal_flag(REED_ROW), false)
	assert_eq(str(_claim(host, 7, "character-A", REED_ROW).code), "already_taken", "reconnect under a new peer cannot replay")
	host.local.flags.set_flag(RULE.personal_flag(REED_ROW), true)

	# Guest claims its own.
	var second := _claim(guest, 2, "character-B", REED_ROW)
	assert_true(bool(second.ok), "guest claim accepted: %s" % str(second.get("code", "")))
	assert_eq(guest.inventory.count("reed_fiber"), 3)
	assert_true(guest.recipe_known(RECIPE), "guest learned its own cordage")
	for op: Dictionary in second.delta.ops:
		if str(op.scope) == "player":
			assert_eq(op.peers, [2], "every personal op addresses only the guest")
	_apply(host, second.delta, 1)
	assert_eq(host.inventory.count("reed_fiber"), 3, "guest's claim pays the host nothing")
	assert_eq(str(_claim(guest, 2, "character-B", REED_ROW).code), "already_taken")

	# A second pocket, the ordinary candy route, per character once.
	assert_true(bool(_claim(host, 1, "character-A", candy).ok))
	assert_true(bool(_claim(guest, 2, "character-B", candy).ok))
	assert_eq(host.inventory.count(candy_item), candy_count)
	assert_eq(guest.inventory.count(candy_item), candy_count)
	assert_eq(str(_claim(host, 1, "character-A", candy).code), "already_taken")
	assert_eq(str(_claim(guest, 2, "character-B", candy).code), "already_taken")

	# Each crafts with its own recipe and satchel.
	assert_true(host.craft(RECIPE))
	assert_eq(host.inventory.count("fiber"), 6)
	assert_eq(guest.inventory.count("fiber"), 0)


func test_other_refusals_on_the_hollow_row() -> void:
	var row := _row(REED_ROW)
	var context := {"peer": 3, "character_id": "character-C", "realm": "water", "position": _at(row) + Vector3(5, 0, 0)}
	var intent := {"pickup_id": REED_ROW, "realm": "water", "personal_claimed": false}
	assert_eq(str(RULE.evaluate(intent, context, {}).code), "too_far")
	context.position = _at(row)
	context.realm = "stormwood"
	assert_eq(str(RULE.evaluate(intent, context, {}).code), "wrong_realm")
	context.realm = "water"
	var ok := RULE.evaluate(intent, context, {})
	assert_true(bool(ok.ok))
	assert_eq(ok.ops.size(), 4, "receipt, personal receipt, fiber, recipe")
	assert_eq(str(ok.ops[3].id), MIGRATION.LEARNED)
	assert_eq(int(ok.ops[2].count), 3)
	# Ordinary (world-once) harvest rows stay off the personal route.
	for harvest: Dictionary in _json(RULE.DATA).harvest:
		if str(harvest.id) != REED_ROW:
			assert_true(RULE.personal_row(_json(RULE.DATA), str(harvest.id)).is_empty(), str(harvest.id))
			break


func test_legacy_character_keeps_cordage_and_repair_is_idempotent() -> void:
	# A character saved before the gate: chapter started, no marker.
	var legacy := PROGRESSION_STATE.new()
	legacy.set_flag("water_chapter_started")
	var saved: Dictionary = legacy.save_data()
	var loaded := PLAYER_STATE.new()
	loaded.load_data({"flags": saved})
	assert_true(loaded.flags.has(MIGRATION.LEARNED), "PlayerState load keeps the recipe the character knew")
	assert_true(loaded.flags.has(MIGRATION.GATE_MARKER))
	assert_false(MIGRATION.repair(loaded.flags), "second repair grants nothing")
	var state := _character()
	state.local.load_data({"flags": saved})
	assert_true(state.recipe_known(RECIPE), "legacy character still sees and can use cordage")
	# Arrival (the only other chapter-start writer) repairs the same way.
	var arriving := PROGRESSION_STATE.new()
	arriving.set_flag("water_chapter_started")
	CHAPTER.apply_personal_event(arriving, "arrival", "water")
	assert_true(arriving.has(MIGRATION.LEARNED))
	# A post-gate character that has not claimed: save/load does not grant it.
	var fresh := PROGRESSION_STATE.new()
	CHAPTER.apply_personal_event(fresh, "arrival", "water")
	var reloaded := PLAYER_STATE.new()
	reloaded.load_data({"flags": fresh.save_data()})
	assert_false(reloaded.flags.has(MIGRATION.LEARNED), "a new character is never granted it by load")
	# Never before the chapter; never removes a known recipe.
	var early := PROGRESSION_STATE.new()
	assert_false(MIGRATION.repair(early))
	assert_false(early.has(MIGRATION.LEARNED))
	var taught := PROGRESSION_STATE.new()
	taught.set_flag("water_chapter_started")
	taught.set_flag(MIGRATION.GATE_MARKER)
	taught.set_flag(MIGRATION.LEARNED)
	MIGRATION.repair(taught)
	assert_true(taught.has(MIGRATION.LEARNED))
	assert_false(MIGRATION.repair(null))
