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
const MASTER_ACTIONS := preload("res://scripts/masters/breakthrough_actions.gd")

class MenuOwner extends Node:
	var game: Node
	var message := ""
	func say(value: String) -> void: message = value

class GameOwner extends Node:
	var party: RefCounted

class DuelGame extends Node:
	var local: RefCounted

class DuelDirector extends Node:
	signal deployment_ready
	var party: RefCounted
	var selected: RefCounted
	var _shared_active_id := ""
	var _manager: Node
	var busy := false
	var summons := 0
	var on_summon: Callable
	var hold_summon := false
	var accepted_offers := 0
	var body := Node3D.new()
	var ready_for_duel := true
	func _init() -> void: add_child(body)
	func trainer_battle_active() -> bool: return busy
	func ally_instance() -> RefCounted: return selected
	func ally_body() -> Node3D: return body
	func ally_deployment_ready() -> bool: return ready_for_duel and body.visible
	func dismiss_active_creature() -> bool:
		selected = null
		return true
	func accept_guest_master_offer(_site: Node3D, _intent: Dictionary, _result: Dictionary) -> bool:
		accepted_offers += 1
		return true
	func summon_active_creature() -> bool:
		summons += 1
		selected = party.active()
		if on_summon.is_valid(): on_summon.call()
		if hold_summon: await deployment_ready
		return true

class DuelProducer extends Node:
	var game: Node
	var director: Node
	var epoch := "current"
	var submissions := 0
	func submit(_op: String, _intent: Dictionary, _source: Node) -> Dictionary:
		submissions += 1
		return {}
	func view() -> Dictionary: return game.local.save_data()
	func _game() -> Node: return game
	func _foundation_master_director(_site: Node3D) -> Node: return director
	func personal_tm_scope() -> Dictionary:
		return {"character_id": "owner", "world_namespace": "world", "session_epoch": epoch}

class StormwoodDuelDirector extends "res://scripts/combat/stormwood_encounter_director.gd":
	var allowed := true
	var sent := 0
	func can_challenge(_spec: Dictionary) -> bool: return allowed
	func _send_out_next_creature() -> bool:
		sent += 1
		return true

class ChapterHub extends Node:
	var requested := ""
	func request_start(id: String) -> void: requested = id

class CloudMasterAdmission extends "res://scripts/combat/cloudreach_encounter_director.gd":
	func _progression() -> RefCounted: return null
	func _party() -> RefCounted: return null

class WaterMasterAdmission extends "res://scripts/combat/water_encounter_director.gd":
	func _progression() -> RefCounted: return null
	func _party() -> RefCounted: return null

class AdmissionManager extends Node:
	var fighting := false
	func is_fighting() -> bool: return fighting

class DivingRider extends Node:
	var diving := false

class DetachedDuelChooser extends "res://scripts/masters/breakthrough_panel.gd":
	# This unit exercises chooser state and async cancellation, not layout or
	# controller focus. The existing runner has no SceneTree in _init. Use the
	# exact cancellation state method invoked by real open/close, without their
	# input-owner/tree calls. Native presentation remains a separate gate.
	func close() -> void:
		_cancel_duel_preparation()
		hide()

class RecordedDuelChooser extends DetachedDuelChooser:
	# Exercise the ordinary rebuild from saved cards without claiming native
	# layout, controller focus, encounter admission or a real Master outcome.
	var choices: Array[Dictionary] = []
	func _button(label: String, action: Callable, disabled: bool = false) -> void:
		choices.append({"label": label, "action": action, "disabled": disabled})

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

func test_each_master_recipe_is_personal_and_replays_never_pay_again() -> void:
	# Canonical detached planner coverage only; host duel validation and native
	# owner save/ACK are exercised separately by the existing two-peer smoke.
	for tier: int in range(1, 6):
		var master_id := "master_t%d" % tier
		var first_player := _player(10)
		var second_player := _player(10)
		first_player.character_id = "f28-master-first"
		second_player.character_id = "f28-master-second"
		var records: Array[Dictionary] = [_admitted(first_player), _admitted(second_player)]
		for owner: int in 2:
			var current: Dictionary = records[owner]
			var before := current.duplicate(true)
			var bystander: Dictionary = records[1 - owner].duplicate(true)
			var context := _context(current)
			context.merge({"master_id": master_id, "validated_host_outcome": "win", "participant_count": 1,
				"encounter_id": "f28-master-unit-%d-%d" % [tier, owner], "creature_uid": str(current.party[0].uid)})
			var chest_intent := {"master_id": master_id}
			var not_won := MASTER_ACTIONS.stage(current, 7, "master_chest", chest_intent, context, Callable(), Callable(), Callable())
			assert_eq(not_won.get("code"), "win_your_own_duel_first", "another character's win cannot unlock this chest")
			var win_intent := {"master_id": master_id, "encounter_id": context.encounter_id, "creature_uid": context.creature_uid}
			var win := MASTER_ACTIONS.stage(current, 7, "master_win", win_intent, context, Callable(), Callable(), Callable())
			assert_true(win.get("ok") == true)
			if win.get("ok") != true: return
			var chest := MASTER_ACTIONS.stage(win.state, 7, "master_chest", chest_intent, context, Callable(), Callable(), Callable())
			assert_true(chest.get("ok") == true)
			if chest.get("ok") != true: return
			assert_eq(current, before, "staging never mutates its admitted input")
			assert_eq(records[1 - owner], bystander, "the bystander's record is untouched")
			var claimed: Dictionary = chest.state
			var personal: Dictionary = claimed.redesign_character
			assert_eq(personal.master_wins.count(master_id), 1)
			assert_eq(personal.feast_recipes.count("feast_t%d" % tier), 1)
			assert_eq(BAG.inventory_from(claimed.inventory).count("tether_candy"), BAG.inventory_from(before.inventory).count("tether_candy") + 2)
			assert_eq(personal.transaction_receipts.count("master_recipe:%s:%s:win" % [master_id, current.character_id]), 1)
			assert_eq(personal.transaction_receipts.count("master_recipe:%s:%s" % [master_id, current.character_id]), 1)
			assert_eq(RECORD.errors(claimed, str(current.character_id)), [], "each claimed record remains canonically admissible")
			var original := claimed.duplicate(true)
			for operation: String in ["master_win", "master_chest"]:
				var intent: Dictionary = win_intent if operation == "master_win" else chest_intent
				var replay := MASTER_ACTIONS.stage(claimed, 7, operation, intent, context, Callable(), Callable(), Callable())
				assert_false(replay.get("ok", true), "replay must reconcile the original delivery rather than pay again")
				assert_true(replay.get("duplicate") == true)
				assert_eq(replay.get("code"), "reconcile_original_delivery")
				assert_eq(claimed, original)
			records[owner] = claimed
		assert_false(records[0].redesign_character.transaction_receipts == records[1].redesign_character.transaction_receipts,
			"identical Masters still have distinct stable-character receipts")

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

func test_fresh_starter_saved_mirror_allows_rest_xp_without_inventing_missing_history() -> void:
	var player := _player(3)
	player.redesign_character = preload("res://scripts/data/redesign_state.gd").defaults("character")
	var creature: RefCounted = player.party.members()[0]
	var cfg := P.config()
	REST.rest(creature, cfg, player.redesign_character)
	assert_eq(creature.xp, 0, "unresolved live state remains fail-closed")
	# The original-starter producer retains this real owner-save projection.
	player.redesign_character = player.save_data().redesign_character
	assert_eq(creature.call("_admitted_level_cap", cfg, player.redesign_character), 10)
	REST.rest(creature, cfg, player.redesign_character)
	assert_eq(creature.xp, P.rest_xp(cfg), "an admitted fresh starter earns the real rest bonus")
	creature.set_level(11, cfg)
	REST.rest(creature, cfg, player.redesign_character)
	assert_eq(creature.level, 11)
	assert_eq(creature.xp, 0, "an above-cap fixture is healed without inventing breakthrough history")
	# A newly caught live instance must gain its mirror at the actual add,
	# rather than waiting for a detached save_data projection to exist.
	var caught: RefCounted = SPECIES.spawn("bramblebun")
	caught.set_level(3, cfg)
	caught.set("traits_initialized", true)
	caught.set("rolled_traits", ["sturdy", "swift"])
	caught.set_meta("ordinary_trait_packet", {"traits_initialized": true, "rolled_traits": ["sturdy", "swift"], "taught_traits": {},
		"captured_from": {"kind": "wild", "world_namespace": "f28-owned-catch", "spawn_id": "ordinary", "spawn_generation": 1}})
	var before_catch: Dictionary = player.redesign_character.duplicate(true)
	assert_true(player.party.add(caught))
	var rules := preload("res://scripts/creatures/breakthrough.gd")
	var initialized := rules.initialize_owned_catch(player.party, before_catch, caught)
	assert_false(initialized.is_empty())
	if initialized.is_empty(): return
	assert_eq(initialized.creatures[creature.uid], before_catch.creatures[creature.uid], "another creature's history is never inferred or reset")
	assert_eq(initialized.transaction_receipts, before_catch.transaction_receipts, "local catch initialization grants no training reward receipt")
	assert_eq(initialized.creatures[caught.uid].rolled_traits, ["sturdy", "swift"], "the actual newly owned spawn roll is retained in its one durable UID mirror")
	assert_true(initialized.creatures[caught.uid].traits_initialized)
	assert_eq(initialized.creatures[caught.uid].captured_from, caught.get_meta("ordinary_trait_packet").captured_from, "actual original catch provenance reaches only its newly owned UID")
	assert_eq(caught.get("rolled_traits"), ["sturdy", "swift"], "catch projection never rerolls the instance")
	player.redesign_character = initialized
	assert_eq(caught.call("_admitted_level_cap", cfg, initialized), 10)
	REST.rest(caught, cfg, initialized)
	assert_eq(caught.xp, P.rest_xp(cfg), "newly owned catch can earn XP before a save serialization")
	initialized.creatures[caught.uid].breakthroughs = [1]
	initialized.creatures[caught.uid].cap_level = 20
	assert_eq(rules.initialize_owned_catch(player.party, initialized, caught), initialized, "repeat admission preserves existing breakthroughs")
	var unowned: RefCounted = SPECIES.spawn("terrapup")
	assert_true(rules.initialize_owned_catch(player.party, initialized, unowned).is_empty(), "no mirror for an unowned newcomer")


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

func test_feast_buttons_require_the_actual_locked_tier_and_never_reoffer_a_lifted_cap() -> void:
	var rules := preload("res://scripts/creatures/breakthrough.gd")
	for tier: int in range(1, 6):
		var owner := _admitted(_player(tier * 10))
		var card: Dictionary = owner.party[0]
		var mirror: Dictionary = owner.redesign_character.creatures[card.uid]
		var definition: Dictionary = rules.feasts().items["feast_t%d_ground" % tier]
		var original := owner.duplicate(true)
		assert_true(PANEL.feast_matches_current_cap(card, mirror, definition), "current canonical tier %d is offered" % tier)
		var below := card.duplicate(true)
		below.level -= 1
		assert_false(PANEL.feast_matches_current_cap(below, mirror, definition), "growth must reach the locked cap")
		var malformed := mirror.duplicate(true)
		malformed.cap_level += 10
		assert_false(PANEL.feast_matches_current_cap(card, malformed, definition), "mirror must agree with cleared-tier history")
		var lifted := mirror.duplicate(true)
		lifted.breakthroughs.append(tier)
		lifted.cap_level = rules.level_cap(lifted.breakthroughs)
		assert_false(PANEL.feast_matches_current_cap(card, lifted, definition), "unchanged level cannot re-offer the spent tier")
		var prior := definition.duplicate(true)
		prior.tier = maxi(1, tier - 1)
		if tier > 1:
			assert_false(PANEL.feast_matches_current_cap(card, mirror, prior), "a cleared tier is never offered")
		assert_eq(owner, original, "presentation cannot change personal state")
	assert_false(PANEL.feast_matches_current_cap({}, {}, {}), "missing state has no offer")

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

func test_master_selection_deploys_the_chosen_owned_companion_and_fences_context() -> void:
	var player := _player(9)
	var chosen: RefCounted = SPECIES.spawn("ripplet")
	player.party.add(chosen)
	var game := DuelGame.new()
	game.local = player
	var director := DuelDirector.new()
	director.party = player.party
	director.selected = player.party.active()
	var producer := DuelProducer.new()
	producer.game = game
	producer.director = director
	var service := SERVICE.new()
	service.set("_submit", producer.submit)
	var site := Node3D.new()
	assert_eq((await service.prepare_duel("foreign", site)).get("code"), "conscious_owned_creature_required")
	chosen.fainted = true
	assert_eq((await service.prepare_duel(chosen.uid, site)).get("code"), "conscious_owned_creature_required")
	chosen.fainted = false
	director.busy = true
	assert_eq((await service.prepare_duel(chosen.uid, site)).get("code"), "combat_active")
	assert_eq(director.summons, 0, "foreign/fainted/busy selection never deploys")
	director.busy = false
	assert_true((await service.prepare_duel(chosen.uid, site)).get("ok", false))
	assert_eq(player.party.active(), chosen)
	assert_eq(director.selected, chosen)
	assert_eq(director.summons, 1)
	assert_true((await service.prepare_duel(chosen.uid, site)).get("ok", false))
	assert_eq(director.summons, 1, "already deployed selection stays on the field")
	director.body.visible = false
	assert_eq((await service.prepare_duel(chosen.uid, site)).get("code"), "deployment_pending", "an existing summon has not taken the field until its body is shown")
	assert_eq(director.summons, 1, "a pending existing body is never recalled and replaced")
	director.body.visible = true
	director.ready_for_duel = false
	assert_eq((await service.prepare_duel(chosen.uid, site)).get("code"), "deployment_pending", "visibility cannot substitute for completed ground placement/publication")
	assert_eq(director.summons, 1, "visible but unfinished body is never replaced")
	director.ready_for_duel = true
	director.selected = null
	director.on_summon = func() -> void: producer.epoch = "rejoined"
	assert_eq((await service.prepare_duel(chosen.uid, site)).get("code"), "character_context_changed", "rejoin during deployment cannot submit a challenge")
	service.free()
	producer.free()
	director.free()
	game.free()
	site.free()

func test_master_choices_identify_unnamed_duplicate_and_named_saved_companions() -> void:
	var player := _player(9)
	for id: String in ["terrapup", "ripplet", "terrapup", "ripplet"]:
		player.party.add(SPECIES.spawn(id))
	player.party.at(2).nickname = "River"
	player.party.at(3).resting = true
	player.party.at(4).hp = 0.0
	var before: Dictionary = player.save_data()
	var game := DuelGame.new()
	game.local = player
	var producer := DuelProducer.new()
	producer.game = game
	var service := SERVICE.new()
	service.set("_view", producer.view)
	var panel := RecordedDuelChooser.new()
	panel.set("_service", service)
	panel.set("_mode", "duel")
	panel.set("_list", VBoxContainer.new())
	panel.set("_message", Label.new())
	panel.call("_rebuild")
	assert_eq(panel.choices.size(), 6, "five saved companions and Back")
	var members: Array = player.party.members()
	for index: int in range(5):
		var expected_name: String = members[index].label()
		assert_true(str(panel.choices[index].label).begins_with("%d · %s" % [index + 1, expected_name]))
		assert_eq(panel.choices[index].disabled, index >= 3, "only conscious awake challengers can be chosen")
	assert_true(str(panel.choices[2].label).contains("(" + str(members[2].display_name) + ")"), "nickname keeps species visible")
	assert_false(panel.choices[0].label == panel.choices[1].label, "duplicate unnamed species keep distinct visible slots")
	assert_eq(player.save_data(), before, "choice presentation never edits durable state")
	panel.get("_list").free()
	panel.get("_message").free()
	panel.free()
	service.free()
	producer.free()
	game.free()

func test_stormwood_master_uses_the_real_inherited_duel_instead_of_chapter_catalogue() -> void:
	var world := Node3D.new()
	var hub := ChapterHub.new()
	hub.name = "StormwoodEncounterHub"
	world.add_child(hub)
	var director := StormwoodDuelDirector.new()
	world.add_child(director)
	var master: Dictionary = preload("res://scripts/creatures/breakthrough.gd").master("master_t5")
	var spec := {"id": master.id, "name": master.name, "master": true,
		"team": [{"species": master.species_id, "level": master.cap_level, "combat": master.combat.duplicate(true)}]}
	var trainer := Node3D.new()
	world.add_child(trainer)
	assert_true(director.begin_trainer_battle(spec, trainer))
	assert_eq(director.sent, 1)
	assert_eq(director.get("_trainer_node"), trainer)
	assert_eq(director.get("_trainer_queue").size(), 1, "canonical Master builds exactly one opponent")
	assert_eq(hub.requested, "", "Master is never sent to the incompatible chapter catalogue")
	director.allowed = false
	assert_false(director.begin_trainer_battle(spec, trainer), "inherited admission still refuses unavailable challengers")
	assert_eq(director.sent, 1)
	director.allowed = true
	assert_true(director.begin_trainer_battle({"id": "ordinary_chapter_trainer"}, trainer))
	assert_eq(hub.requested, "ordinary_chapter_trainer", "chapter fights still use their original hub")
	world.free()

func test_master_deployment_cannot_overlap_after_cancel_and_reopen() -> void:
	var player := _player(9)
	var first: RefCounted = player.party.active()
	var second: RefCounted = SPECIES.spawn("ripplet")
	player.party.add(second)
	var game := DuelGame.new()
	game.local = player
	var director := DuelDirector.new()
	director.party = player.party
	director.hold_summon = true
	var producer := DuelProducer.new()
	producer.game = game
	producer.director = director
	var service := SERVICE.new()
	service.set("_submit", producer.submit)
	service.set("_view", producer.view)
	var panel := DetachedDuelChooser.new()
	var message := Label.new()
	panel.add_child(message)
	panel.set("_message", message)
	service.set("_panel", panel)
	var site := Node3D.new()
	panel.set("_service", service)
	panel.set("_source", site)
	panel.set("_mode", "duel")
	panel.set("_master", "master_t1")
	panel.show()
	panel.call("_duel", first.uid) # Suspends on the real await boundary.
	assert_eq(director.summons, 1)
	assert_true(service.get("_duel_preparing"))
	panel.close()
	panel.call("_cancel_duel_preparation") # Real open invalidates old preparation too.
	panel.show()
	panel.call("_duel", second.uid)
	assert_eq(director.summons, 1, "second chooser cannot free the pending body")
	assert_eq(player.party.active(), first, "overlap refuses before changing party selection")
	assert_true(message.text.contains("still taking the field"))
	director.hold_summon = false
	director.deployment_ready.emit()
	assert_false(service.get("_duel_preparing"))
	assert_eq(producer.submissions, 0, "cancelled first chooser cannot submit after summon completes")
	assert_false(service.accept_duel_offer({"master_id": "master_t1", "creature_uid": first.uid}, {}), "delayed offer cannot enter the reopened menu without a pending intent")
	assert_eq(director.accepted_offers, 0)
	panel.call("_duel", second.uid)
	assert_eq(director.summons, 2)
	assert_eq(director.selected, second)
	assert_eq(producer.submissions, 1, "reopened chooser can retry after the old summon ends")
	assert_true(service.accept_duel_offer({"master_id": "master_t1", "creature_uid": second.uid}, {}), "exact current pending offer can enter the duel")
	assert_eq(director.accepted_offers, 1)
	service.set("_panel", null)
	panel.free()
	service.free()
	producer.free()
	director.free()
	game.free()
	site.free()

func test_tidewake_and_cloudreach_master_admission_keeps_combat_and_diving_fences() -> void:
	for director: Node in [CloudMasterAdmission.new(), WaterMasterAdmission.new()]:
		var world := Node3D.new()
		world.add_child(director)
		var manager := AdmissionManager.new()
		world.add_child(manager)
		director.set("_manager", manager)
		director.set("_ally", SPECIES.spawn("terrapup"))
		var body := Node3D.new()
		world.add_child(body)
		director.set("_ally_body", body)
		var master: Dictionary = preload("res://scripts/creatures/breakthrough.gd").master("master_t3")
		var spec := {"id": master.id, "name": master.name, "master": true,
			"team": [{"species": master.species_id, "level": master.cap_level, "combat": master.combat.duplicate(true)}]}
		assert_true(director.get("trainer_specs").is_empty())
		assert_true(director.call("can_challenge", spec), "canonical Master is independent of chapter trainer catalogue")
		var ordinary := spec.duplicate(true)
		ordinary.erase("master")
		assert_false(director.call("can_challenge", ordinary), "unknown ordinary trainer still refuses")
		manager.fighting = true
		assert_false(director.call("can_challenge", spec), "common in-combat refusal still applies")
		manager.fighting = false
		if director is WaterMasterAdmission:
			var riding := DivingRider.new()
			riding.name = "RidingController"
			world.add_child(riding)
			riding.diving = true
			assert_false(director.call("can_challenge", spec), "Tidewake submerged refusal still applies")
		world.free()

func test_shipping_evolution_uses_feast_and_catalyst_text_names_actual_gate() -> void:
	assert_eq(P.config().get("evolution_mode"), "breakthrough")
	var creature: RefCounted = SPECIES.spawn("mudsnout")
	creature.set_level(20, P.config())
	assert_true(EVOLUTION.requirements("mudsnout", P.config()).is_empty(), "held-stone shortcut is disabled")
	assert_false(EVOLUTION.check(creature, P.config(), null).get("eligible", false))
	var guidance: String = EVOLUTION.check(creature, P.config(), null).get("reason", "")
	assert_true(guidance.contains("Kitchen") and guidance.contains("Lv 20"), guidance)
	assert_true(guidance.contains("evolve or stay"), "Team action describes the actual permanent feast choice")
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
