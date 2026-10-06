extends "res://tests/test_case.gd"

const CANDY := preload("res://scripts/creatures/candy.gd")
const ACTIONS := preload("res://scripts/net/character_action_rules.gd")
const RECORD := preload("res://scripts/net/character_record_rules.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const P := preload("res://scripts/creatures/progression.gd")
const REST := preload("res://scripts/creatures/home_recovery.gd")
const BAG := preload("res://scripts/world/death_satchel_rules.gd")
const PANEL := preload("res://scripts/masters/breakthrough_panel.gd")
const EVOLUTION := preload("res://scripts/creatures/evolution.gd")
const FEED := preload("res://scripts/creatures/progression_feed.gd")
const BACKPACK := preload("res://scripts/ui/tab_backpack.gd")
const SERVICE := preload("res://scripts/masters/breakthrough_service.gd")

class MenuOwner extends Node:
	var game: Node
	var message := ""
	func say(value: String) -> void: message = value

class GameOwner extends Node:
	var party: RefCounted

func _player(level: int) -> RefCounted:
	var player := preload("res://autoload/player_state.gd").new()
	player.configure(preload("res://autoload/item_db.gd").new())
	player.character_id = "f28-boundary-owner"
	var creature: RefCounted = SPECIES.spawn("terrapup")
	creature.set_level(level, P.config())
	player.party.add(creature)
	player.inventory.add("rare_candy", 2)
	var saved: Dictionary = player.save_data()
	player.redesign_character = preload("res://scripts/creatures/breakthrough.gd").initialize_caught(saved.redesign_character, saved.party[0])
	return player

func _admitted(player: RefCounted) -> Dictionary:
	var record := RECORD.portable_projection(player.save_data())
	assert_eq(RECORD.errors(record, player.character_id), [], "real save produces a canonical admission")
	return record

func _intent(record: Dictionary) -> Dictionary:
	return {"creature_uid": record.party[0].uid, "candy_item": "rare_candy", "action_id": "0123456789abcdef0123456789abcdef"}

func _context(record: Dictionary) -> Dictionary:
	return {"character_id": record.character_id, "expected_revision": 7, "owns_character": true,
		"in_range": true, "in_combat": false, "source_key": "personal_candy_feed"}

func test_candy_clamps_every_admitted_cap_and_stages_one_debit() -> void:
	for cap: int in [10, 20, 30, 40, 50, 60]:
		var before := _admitted(_player(cap - 1))
		var snapshot := before.duplicate(true)
		var staged := ACTIONS.stage(before, 7, "candy_feed", _intent(before), _context(before), RECORD.errors)
		assert_true(staged.get("ok") == true, str(staged))
		if staged.get("ok") != true: continue
		assert_eq(before, snapshot, "proposal cannot mutate the live baseline")
		assert_eq(staged.state.party[0].level, cap)
		assert_eq(staged.state.party[0].xp, 0, "no XP is banked past a locked cap")
		assert_eq(BAG.inventory_from(staged.state.inventory).count("rare_candy"), 1)
		assert_eq(staged.state.redesign_character.creatures[before.party[0].uid].cap_level, cap)
		assert_eq(RECORD.errors(JSON.parse_string(JSON.stringify(staged.state)), before.character_id), [], "candidate survives persisted JSON admission")
		assert_false(staged.durable, "detached stage never claims a save")
		assert_false(staged.resolved)

func test_candy_refuses_cap_faint_missing_item_and_changed_owner_without_mutation() -> void:
	var before := _admitted(_player(10))
	assert_eq(CANDY.stage(before, 7, _intent(before), _context(before)).get("code"), "breakthrough_needed")
	before = _admitted(_player(9))
	var snapshot := before.duplicate(true)
	var context := _context(before)
	context.in_combat = true
	assert_false(CANDY.stage(before, 7, _intent(before), context).get("ok", false))
	context = _context(before)
	context.character_id = "other-owner"
	assert_false(CANDY.stage(before, 7, _intent(before), context).get("ok", false))
	assert_eq(before, snapshot)
	before.party[0].hp = 0
	before.party[0].fainted = true
	assert_eq(CANDY.stage(before, 7, _intent(before), _context(before)).get("code"), "fainted")
	before = snapshot.duplicate(true)
	before.inventory = BAG.slots(BAG.inventory_from([]))
	assert_eq(CANDY.stage(before, 7, _intent(before), _context(before)).get("code"), "insufficient_items")

func test_candy_original_receipt_refuses_a_second_debit_even_below_cap() -> void:
	var before := _admitted(_player(3))
	var intent := _intent(before)
	var staged := CANDY.stage(before, 7, intent, _context(before))
	assert_true(staged.get("ok") == true, str(staged))
	if staged.get("ok") != true: return
	var context := _context(before)
	context.expected_revision = 8
	assert_eq(CANDY.stage(staged.state, 8, intent, context).get("code"), "reconcile_original_decision")
	assert_eq(BAG.inventory_from(staged.state.inventory).count("rare_candy"), 1)

func test_two_stable_characters_share_no_candy_receipt_or_inventory() -> void:
	var first := _admitted(_player(3))
	var other_player := _player(3)
	other_player.character_id = "f28-other-owner"
	var second := _admitted(other_player)
	var first_snapshot := first.duplicate(true)
	var second_snapshot := second.duplicate(true)
	var one := CANDY.stage(first, 7, _intent(first), _context(first))
	var two := CANDY.stage(second, 7, _intent(second), _context(second))
	assert_true(one.get("ok") == true and two.get("ok") == true)
	if one.get("ok") != true or two.get("ok") != true: return
	assert_false(one.receipt == two.receipt, "even the same action id is scoped to its admitted character")
	assert_eq(first, first_snapshot)
	assert_eq(second, second_snapshot)
	assert_eq(BAG.inventory_from(one.state.inventory).count("rare_candy"), 1)
	assert_eq(BAG.inventory_from(two.state.inventory).count("rare_candy"), 1)
	var foreign := _intent(first)
	assert_eq(CANDY.stage(second, 7, foreign, _context(second)).get("code"), "not_owned")

func test_personal_rest_heals_but_cannot_bank_xp_or_cross_locked_cap() -> void:
	var player := _player(9)
	var admitted := _admitted(player)
	var creature: RefCounted = player.party.members()[0]
	var cfg := P.config().duplicate(true)
	cfg.xp_award.rest_bonus = 100000
	creature.hp = 0
	creature.fainted = true
	REST.rest(creature, cfg, admitted.redesign_character)
	assert_eq(creature.level, 10)
	assert_eq(creature.xp, 0)
	assert_false(creature.fainted)
	assert_true(creature.hp > 0)
	REST.rest(creature, cfg, admitted.redesign_character)
	assert_eq(creature.level, 10)
	assert_eq(creature.xp, 0)
	assert_eq(P.config().level.cap, 100, "personal adapter never rewrites shared config")
	assert_eq(creature.call("_admitted_level_cap", P.config(), admitted.redesign_character), 10)
	assert_eq(creature.call("_admitted_level_cap", P.config(), {}), -1, "unresolved mirror cannot use the shared ceiling")
	creature.xp = 100
	creature.gain_xp(0, REST.training_config(creature, cfg, admitted.redesign_character))
	assert_eq(creature.xp, 0, "zero-award cap observation also discards stale XP")

func test_feast_completion_requires_original_intent_and_all_saved_fences() -> void:
	var panel := PANEL.new()
	panel.hide()
	panel.set("_pending_action", "feast_cook")
	panel.set("_pending_intent", {"recipe_id": "one", "craft_id": "original"})
	panel.set("_craft_id", "original")
	var intent: Dictionary = panel.get("_pending_intent").duplicate(true)
	var saved := {"ok": true, "settled": true, "durable": true, "owner_saved": true, "owner_acknowledged": true}
	for fence: String in ["settled", "durable", "owner_saved", "owner_acknowledged"]:
		var incomplete := saved.duplicate(true)
		incomplete[fence] = false
		assert_false(panel.accept_completion("feast_cook", intent, incomplete), fence)
		assert_eq(panel.get("_craft_id"), "original")
	assert_false(panel.accept_completion("feast_cook", {"recipe_id": "one", "craft_id": "other"}, saved))
	assert_true(panel.accept_completion("feast_cook", intent, saved))
	assert_eq(panel.get("_craft_id"), "")
	assert_false(panel.accept_completion("feast_cook", intent, saved), "delayed completion cannot settle a new cook")
	panel.free()

func test_guest_master_refusal_releases_only_the_matching_attempt() -> void:
	var panel := PANEL.new()
	panel.hide()
	panel.set("_pending_action", "master_duel")
	var intent := {"master_id": "master_t1", "creature_uid": "chosen"}
	panel.set("_pending_intent", intent.duplicate(true))
	var service := SERVICE.new()
	service.set("_panel", panel)
	service.call("_foundation_reply", {"op": "master_duel", "intent": {"master_id": "master_t1", "creature_uid": "other"}}, {"ok": false, "code": "deploy_chosen_owned_creature"})
	assert_eq(panel.get("_pending_intent"), intent, "another attempt cannot release the current choice")
	service.call("_foundation_reply", {"op": "master_duel", "intent": intent}, {"ok": true, "encounter_id": "started"})
	assert_eq(panel.get("_pending_intent"), intent, "admission success is never a saved reward")
	service.call("_foundation_reply", {"op": "master_duel", "intent": intent}, {"ok": false, "code": "deploy_chosen_owned_creature"})
	assert_eq(panel.get("_pending_action"), "")
	assert_true(panel.get("_pending_intent").is_empty(), "guest can choose a different conscious companion")
	service.set("_panel", null)
	service.free()
	panel.free()

func test_shipping_evolution_uses_feast_and_catalyst_text_names_actual_gate() -> void:
	assert_eq(P.config().get("evolution_mode"), "breakthrough")
	var creature: RefCounted = SPECIES.spawn("mudsnout")
	creature.set_level(20, P.config())
	assert_true(EVOLUTION.requirements("mudsnout", P.config()).is_empty(), "held-stone shortcut is disabled")
	assert_false(EVOLUTION.check(creature, P.config(), null).get("eligible", false))
	for item: String in ["heartstone", "sunstone"]:
		var text := FEED.catalyst_pickup_text(item)
		assert_true(text.contains("Lv 20") and text.contains("Kitchen") and text.contains("choose"), text)
		assert_false(text.contains("bond tier"), text)

func test_saved_candy_completion_announces_partial_growth_once() -> void:
	var player := _player(9)
	var before := _admitted(player)
	var intent := _intent(before)
	var creature: RefCounted = player.party.members()[0]
	creature.set_level(10, P.config()) # Represents the already installed saved candidate.
	var game := GameOwner.new()
	game.party = player.party
	var menu := MenuOwner.new()
	menu.game = game
	var tab := BACKPACK.new()
	tab.menu = menu
	tab.set("_candy_intent", intent)
	tab.set("_candy_before", before.party[0].duplicate(true))
	tab.set("_candy_cap", 10)
	FEED.clear()
	var pending := {"ok": true, "settled": false, "durable": true, "owner_saved": false, "owner_acknowledged": false}
	tab.call("_candy_completed", "candy_feed", intent, pending)
	assert_eq(FEED.events().size(), 0, "prepared write cannot announce unsaved growth")
	var saved := {"ok": true, "settled": true, "durable": true, "owner_saved": true, "owner_acknowledged": true}
	tab.call("_candy_completed", "candy_feed", intent, saved)
	assert_true(menu.message.contains("+1 of +3") and menu.message.contains("level cap, 10"), menu.message)
	assert_eq(FEED.events().size(), 1)
	assert_eq(FEED.events()[0].kind, "level_up")
	assert_eq(FEED.events()[0].levels_gained, 1)
	tab.call("_candy_completed", "candy_feed", intent, saved)
	assert_eq(FEED.events().size(), 1, "duplicate authenticated completion cannot replay presentation")
	tab.free()
	menu.free()
	game.free()
