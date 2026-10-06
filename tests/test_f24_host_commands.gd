extends "res://tests/test_move_commit_runtime.gd"

## Existing host transaction and canonical consumer coverage. Flags are a
## disclosed test fixture; no native, two-peer or feature activation claim.
const COMMANDS := preload("res://scripts/combat/tether_commands.gd")
const MASTERY := preload("res://scripts/creatures/move_mastery.gd")
const MOVES := preload("res://scripts/creatures/move_db.gd")
const MANAGER := preload("res://scripts/combat/combat_manager.gd")
const DATA := preload("res://tests/test_tm_teach_transaction.gd")
var _saved_commands: Dictionary

func test_satchel_pouch_recovers_same_original_and_waits_for_saved_ack() -> void:
	COMMANDS._config.feature_flags.ui_enabled = true
	var producer := DATA.ProducerDouble.new()
	producer.action = "tether_pouch"
	producer.original = {"assignment_id": "saved-pouch-choice", "index": 0, "item_id": "potion_small"}
	var game := DATA.GameDouble.new()
	game.session = producer
	var menu := DATA.MenuDouble.new()
	menu.game = game
	var tab := preload("res://scripts/ui/tab_backpack.gd").new()
	tab.menu = menu
	tab._poll_pouch_transaction()
	assert_eq(producer.submissions.size(), 1)
	assert_eq(producer.submissions[0].intent, producer.original)
	assert_eq(producer.submissions[0].revision, 7, "saved original revision, not current view's 99")
	var policy := preload("res://scripts/net/session.gd").new()
	var refused: Dictionary = policy._foundation_journal_refusal("tether_pouch", {"code": "training_journal_failed"})
	assert_false(refused.terminal_refusal)
	producer.homestead_action_completed.emit("tether_pouch", producer.original, refused)
	assert_eq(tab._pouch_intent, producer.original)
	producer.homestead_action_completed.emit("tether_pouch", producer.original,
		{"ok": true, "settled": true, "durable": true, "owner_saved": false, "owner_acknowledged": true})
	assert_eq(tab._pouch_intent, producer.original)
	assert_ne(menu.message, "Command pouch saved.")
	tab._retry_pouch_transaction()
	assert_eq(producer.submissions[1], producer.submissions[0], "failed save retry cannot choose another slot/item/revision")
	producer.homestead_action_completed.emit("tether_pouch", producer.original,
		{"ok": true, "settled": true, "durable": true, "owner_saved": true, "owner_acknowledged": true})
	assert_true(tab._pouch_intent.is_empty())
	assert_eq(menu.message, "Command pouch saved.")
	tab._pouch_view = {"character_id": "old-owner", "registry_revision": 7}
	tab._pouch_available = true
	producer.pouch_scope = {}
	assert_false(tab._bind_pouch_producer())
	assert_true(tab._pouch_view.is_empty(), "settled presentation cannot survive character/session loss")
	assert_false(tab._pouch_available)
	producer.pouch_scope = {"character_id": "new-owner", "world_namespace": "new-world", "session_epoch": "new-session"}
	assert_true(tab._bind_pouch_producer())
	assert_eq(tab._pouch_view_scope, producer.pouch_scope)
	assert_true(tab._pouch_intent.is_empty(), "old pending choice cannot travel into a replacement scope")
	tab.free()
	menu.free()
	game.free()
	producer.free()
	policy.free()

func before_each() -> void:
	super()
	_saved_commands = COMMANDS.config()
	COMMANDS._config = _saved_commands.duplicate(true)
	COMMANDS._config.feature_flags.runtime_enabled = true

func after_each() -> void:
	COMMANDS._config = _saved_commands

func _admitted(character: String = "owner_a") -> Dictionary:
	var admitted: Dictionary = DATA.new()._before()
	admitted.character_id = character
	return admitted

func _command_view() -> Dictionary:
	return {"actor": {"character_id": "owner_a", "encounter_id": id, "creature_uid": "creature_a", "generation": 1, "hp": 100.0},
		"target": {"uid": "opponent", "generation": 1, "hp": 200.0, "hostile": true, "ownership_kind": "wild", "trainer_owned": false, "snare_immune": false},
		"snare_geometry_connected": true}

func _command_pool() -> Dictionary:
	return host.encounters[id].participants[1].tether_commands

func test_meter_uses_original_host_hit_once_and_freezes_admitted_gear() -> void:
	host.bind_tether_commands(id, 1, _admitted())
	var frozen := MASTERY.freeze_action(MASTERY.owned_record(_owned()), "quick",
		{"character_id": "owner_a", "creature_uid": "creature_a", "encounter_id": id, "generation": 1, "action": 1}, [], MOVES.load_default())
	assert_true(frozen.ok)
	var move := MANAGER.host_move_profile(MOVES.load_default(), "player_quick", "pebble_toss", 0.5, 0.5, 1.0, 0.0, frozen.move)
	assert_true(host.authorize_move_start({"encounter_id": id, "action": 1, "slot": "quick"}, 1, _owned(), _binding(), move, WIND, 1000).ok)
	assert_true(_arrive(1, 1300).ok)
	assert_true(host.credit_move_hit(id, 1, 1, 0.0, "opponent", 200.0, 1, 100.0).is_empty())
	assert_eq(_command_pool().meter, 0.0)
	host.credit_move_hit(id, 1, 1, 2.0, "opponent", 200.0, 1, 100.0)
	assert_eq(_command_pool().meter, 8.0)
	host.credit_move_hit(id, 1, 1, 2.0, "opponent", 200.0, 1, 100.0)
	assert_eq(_command_pool().meter, 8.0)
	assert_true(host.move_commit(id, 1, 1).command_meter_credited)
	var changed := _admitted()
	changed.equipment.backpack = "invented-backpack"
	host.bind_tether_commands(id, 1, changed)
	assert_eq(_command_pool().tier, 0)
	assert_true(host.join(id, 2, "creature_b", "owner_b").ok)
	assert_true(host.leave(id, 1).ok)
	assert_true(host.join(id, 3, "creature_a", "owner_a").ok)
	assert_eq(host.encounters[id].participants[3].tether_commands.meter, 8.0)

func test_rally_spends_once_affects_only_owner_and_splits_wind_at_expiry() -> void:
	host.bind_tether_commands(id, 1, _admitted())
	assert_true(_start(1).ok)
	assert_true(host.join(id, 2, "creature_b", "owner_b").ok)
	host.bind_tether_commands(id, 2, _admitted("owner_b"))
	_command_pool().meter = 100.0 # Meter setup, actual command commit below.
	var request := COMMANDS.intent(id, 1, 1, "rally")
	var verdict: Dictionary = host.commit_tether_command(request, 1, _command_view(), 2000)
	assert_true(verdict.ok, str(verdict))
	assert_eq(_command_pool().meter, 50.0)
	assert_false(host.commit_tether_command(request, 1, _command_view(), 2001).ok)
	assert_eq(_command_pool().meter, 50.0)
	assert_eq(host.tether_rally(id, 1, 7999).damage, 1.1)
	assert_eq(host.tether_rally(id, 2, 7999).damage, 1.0)
	assert_eq(host.tether_rally(id, 1, 8000).damage, 1.0)
	var pool: Dictionary = host.encounters[id].participants[1].move_resources.creature_a
	pool.wind = 0.0
	pool.wind_updated_ms = 7000
	pool.wind_ready_at_ms = 7000
	var profile := {"creature_uid": "creature_a", "max": 100.0, "regen_per_second": 10.0}
	assert_eq(host.preview_wind(id, 1, profile, 0.0, 9000).wind, 22.5)
	var forged := _command_view()
	forged.actor.character_id = "owner_b"
	assert_false(host.commit_tether_command(COMMANDS.intent(id, 1, 2, "rally"), 1, forged, 10000).ok)

func test_snare_canonical_status_has_one_shared_slow_and_own_catch_grant() -> void:
	host.bind_tether_commands(id, 1, _admitted())
	assert_true(_start(1).ok)
	_command_pool().meter = 100.0
	for defect: String in ["trainer", "boss", "geometry", "generation"]:
		var view := _command_view()
		match defect:
			"trainer": view.target.trainer_owned = true
			"boss": view.target.snare_immune = true
			"geometry": view.snare_geometry_connected = false
			"generation": view.actor.generation = 2
		assert_false(host.commit_tether_command(COMMANDS.intent(id, 1, 1, "snare"), 1, view, 2000).ok, defect)
		assert_eq(_command_pool().meter, 100.0)
	var verdict: Dictionary = host.commit_tether_command(COMMANDS.intent(id, 1, 1, "snare"), 1, _command_view(), 2000)
	assert_true(verdict.ok, str(verdict))
	assert_eq(_command_pool().meter, 40.0)
	assert_eq(host.record(id).opponent.hp, 200.0, "trainer command never damages")
	var status: Dictionary = host.record(id).opponent.tether_snare
	assert_eq(COMMANDS.snare_modifiers(status, "opponent", 1, "owner_a", 4999).catch_bonus, 0.1)
	assert_eq(COMMANDS.snare_modifiers(status, "opponent", 1, "owner_b", 4999).catch_bonus, 0.0)
	assert_eq(COMMANDS.snare_modifiers(status, "opponent", 1, "owner_b", 4999).movement, 0.6)
	assert_eq(COMMANDS.snare_modifiers(status, "opponent", 2, "owner_a", 4999).movement, 1.0)
	assert_eq(COMMANDS.snare_modifiers(status, "opponent", 1, "owner_a", 5000).movement, 1.0)
	assert_false(host.commit_tether_command(COMMANDS.intent(id, 1, 2, "tag_combo"), 1, _command_view(), 2500).ok)
	assert_false(host.commit_tether_command(COMMANDS.intent(id, 1, 2, "item_throw"), 1, _command_view(), 2500).ok)

func test_equipped_authored_pouches_bind_each_upgrade_on_the_same_participant() -> void:
	var ids := ["", "rootiron_command_pouch", "tidesteel_command_pouch", "skyglass_command_pouch", "stormglass_command_pouch"]
	for tier: int in 5:
		var authority := HOST.new(1)
		var record: Dictionary = authority.open(1, "meadows", "wild", {"hp": 100.0, "hp_max": 100.0}, "creature_a", "owner_a")
		var admitted := _admitted()
		admitted.equipment.backpack = ids[tier]
		authority.bind_tether_commands(record.encounter_id, 1, admitted)
		assert_eq(authority.record(record.encounter_id).participants[1].tether_commands.tier, tier)
		var profile := COMMANDS.tier_profile(tier)
		assert_true(float(profile.meter_rate) >= 1.0)
		assert_true(int(profile.pouch_size) >= 1 and int(profile.pouch_size) <= 3)

func test_rally_can_commit_on_current_owned_deployment_before_its_first_move() -> void:
	host.bind_tether_commands(id, 1, _admitted())
	assert_true(_start(1).ok)
	_command_pool().meter = 100.0
	var current := _command_view()
	current.actor.creature_uid = "creature_b"
	current.actor.generation = 2
	assert_true(host.commit_tether_command(COMMANDS.intent(id, 2, 1, "rally"), 1, current, 2000).ok)
	var binding := _binding("creature_b")
	binding.deployment_generation = 2
	assert_true(host.authorize_move_start({"encounter_id": id, "action": 2, "slot": "quick"}, 1, _owned("creature_b"), binding, _move(), WIND, 3000).ok)
	assert_eq(host.encounters[id].participants[1].move_resources.creature_b.tether_rally_until_ms, 8000)

func test_every_joint_damage_event_is_attributed_to_one_of_the_two_owned_creatures() -> void:
	var target := {"uid": "opponent", "generation": 1, "hp": 200.0, "hostile": true,
		"position": Vector3(2, 0, 0), "defence": 10.0, "type": "Water", "secondary_type": ""}
	var actors: Array = []
	var moves: Array = []
	for index: int in 2:
		var uid := "creature_a" if index == 0 else "creature_b"
		var actor := {"character_id": "owner_a", "encounter_id": id, "creature_uid": uid,
			"generation": index + 1, "action": index + 1, "hp": 100.0, "attack": 20.0, "position": Vector3.ZERO,
			"facing": Vector3.RIGHT, "bonus_product": 1.0}
		actors.append(actor)
		var owned := _owned(uid)
		owned["move_mastery_uses"] = {"pebble_toss": 300}
		var frozen := MASTERY.freeze_action(MASTERY.owned_record(owned), "quick", actor, [], MOVES.load_default())
		assert_true(frozen.ok, str(frozen))
		if not frozen.ok: return
		moves.append(MANAGER.host_move_profile(MOVES.load_default(), "player_quick", "pebble_toss", 0.5, 0.5, 1.0, 0.0, frozen.move))
	var effect := {"kind": "tag_combo", "character_id": "owner_a", "encounter_id": id,
		"target_uid": target.uid, "target_generation": target.generation,
		"strikes": [COMMANDS.joint_strike(actors[0], target, "joint-original", "outgoing", 0.5),
			COMMANDS.joint_strike(actors[1], target, "joint-original", "incoming", 1.5)]}
	var view := {"actors": actors, "rolls": [0.5, 0.5], "target": target}
	var plan := COMMANDS.stage_joint_attack(effect, moves, view, preload("res://scripts/combat/combat_math.gd").config())
	assert_true(plan.ok, str(plan))
	if not plan.ok: return
	assert_eq(plan.strikes.size(), 2)
	assert_ne(plan.strikes[0].action_id, plan.strikes[1].action_id, "each owned contribution has its own original")
	var math := preload("res://scripts/combat/combat_math.gd")
	var chart := preload("res://scripts/combat/type_chart.gd")
	var type_scale := chart.multiplier_dual(MOVES.load_default().type_of("pebble_toss"), "Water", "")
	assert_ne(type_scale, 1.0, "exercise an actual non-neutral type pairing")
	for index: int in 2:
		var strike: Dictionary = plan.strikes[index]
		assert_true(float(strike.actual_hp_debit) > 0.0)
		assert_eq(strike.source_kind, "creature")
		assert_true(["creature_a", "creature_b"].has(strike.attacker_uid))
		assert_eq(strike.character_id, "owner_a")
		assert_eq(strike.parent_action_id, "joint-original")
		assert_ne(strike.action_id, "joint-original")
		var ordinary := math.rolled_damage(float(moves[index].power), 20.0, 10.0, 0.5,
			MOVES.load_default().power("pebble_toss"), type_scale)
		assert_eq(strike.actual_hp_debit, ordinary * (0.5 if index == 0 else 1.5), "rank-five profile and actual type scale exactly like one ordinary quick")
	assert_eq(COMMANDS.stage_joint_attack(effect, moves, view, math.config()).strikes, plan.strikes, "retry retains exact child identities")
	view.target.hp = 1.0
	var finishing: Dictionary = COMMANDS.stage_joint_attack(effect, moves, view, math.config())
	assert_true(finishing.ok)
	if finishing.ok:
		assert_eq(finishing.hp_after, 0.0)
		assert_eq(finishing.strikes[0].actual_hp_debit, 1.0)
		assert_eq(finishing.strikes[1].actual_hp_debit, 0.0, "incoming cannot credit already-debited HP")
		assert_false(finishing.strikes[1].landed)
	var forged := effect.duplicate(true)
	forged.strikes[0].source_kind = "trainer"
	assert_false(COMMANDS.stage_joint_attack(forged, moves, view, preload("res://scripts/combat/combat_math.gd").config()).ok)
	view.actors[1].character_id = "owner_b"
	assert_false(COMMANDS.stage_joint_attack(effect, moves, view, preload("res://scripts/combat/combat_math.gd").config()).ok)


func test_pouch_assignment_uses_original_character_journal_and_owner_save_without_moving_stacks() -> void:
	var actions := preload("res://scripts/net/foundation_actions.gd")
	var record := preload("res://scripts/net/character_record_rules.gd")
	var delivery := preload("res://scripts/net/foundation_delivery.gd")
	var authority_type := preload("res://scripts/net/character_authority.gd")
	var before := _admitted()
	var context := {"character_id": "owner_a", "expected_revision": 0, "source_key": "personal_pouch:owner_a",
		"station_kind": "personal_pouch", "owns_character": true, "in_range": true, "in_combat": false, "foundation_runtime_authorized": true}
	var intent := {"assignment_id": "pouch-original", "index": 0, "item_id": "potion_small"}
	var authority := authority_type.new()
	assert_true(authority.bind_world("pouch-world"))
	assert_true(authority.seed_admitted_character(before, "owner_a").ok)
	var token: Dictionary = authority.stage_character_action("owner_a", 0, "tether_pouch", intent, context)
	assert_true(token.ok, str(token))
	if not token.ok: return
	assert_eq(token.state.inventory, before.inventory)
	assert_eq(token.state.party, before.party)
	assert_eq(token.state.redesign_character.tether_pouch, ["potion_small"])
	assert_true(preload("res://scripts/creatures/receipt_windows.gd").is_kind(token.receipt, "station_craft", "owner_a"))
	assert_true(authority.finish_creature_training(token, false))
	assert_eq(authority.state("owner_a"), before, "failed world save rolls back the binding")
	token = authority.stage_character_action("owner_a", 0, "tether_pouch", intent, context)
	var row: Dictionary = delivery.make_record("pouch-slot", "pouch-world", "pouch-session", token, null, record.errors)
	assert_false(row.is_empty())
	if row.is_empty(): return
	var codec := preload("res://scripts/save/save_document.gd")
	row = codec.parse(codec.stringify(row))
	assert_true(delivery.valid(row, record.errors, "owner_a", "pouch-world", "pouch-slot"))
	var rejoined := authority_type.new()
	assert_true(rejoined.bind_world("pouch-world"))
	assert_true(rejoined.seed_admitted_character(before, "owner_a").ok)
	assert_true(rejoined.recover_durable_training("owner_a", {row.delivery_id: row}).ok)
	assert_false(rejoined.acknowledge_creature_training("owner_a", row), "owner save required")
	var owner: Dictionary = delivery.owner_plan(before, row, record.errors)
	assert_true(owner.ok and owner.get("requires_owner_save") == true)
	assert_true(delivery.owner_plan(owner.state, row, record.errors).duplicate)
	row.status = "accepted"
	assert_true(rejoined.acknowledge_creature_training("owner_a", row))
	assert_eq(rejoined.state("owner_a").inventory, before.inventory)
	assert_eq(rejoined.state("owner_a").party, before.party)
	assert_eq(rejoined.state("owner_a").redesign_character.tether_pouch, ["potion_small"])
	assert_false(rejoined.stage_character_action("owner_a", 0, "tether_pouch", intent, context).ok, "old original revision cannot edit again")
	var windows := preload("res://scripts/creatures/receipt_windows.gd")
	var crowded := before.duplicate(true)
	for index: int in range(windows.window("station_craft") + 1):
		crowded.redesign_character.transaction_receipts.append("craft:owner_a:" + ("old_pouch:" + str(index)).sha256_text().substr(0, 32))
	var compacted: Dictionary = actions.stage(crowded, 0, "tether_pouch", intent, context, record.errors)
	assert_true(compacted.ok, str(compacted))
	if compacted.ok:
		assert_eq(compacted.state.redesign_character.transaction_receipts.size(), windows.window("station_craft"))
		assert_eq(compacted.state.inventory, before.inventory)
		assert_eq(compacted.state.party, before.party)
	for defect: String in ["combat", "foreign_owner", "tier", "orb", "extra_field"]:
		var forged := intent.duplicate(true)
		var view := context.duplicate(true)
		match defect:
			"combat": view.in_combat = true
			"foreign_owner": view.character_id = "owner_b"
			"tier": forged.index = 2
			"orb": forged.item_id = "orb_basic"
			"extra_field": forged.meter = 100
		assert_false(actions.stage(before, 0, "tether_pouch", forged, view, record.errors).ok, defect)
	var forged_saved := before.duplicate(true)
	forged_saved.redesign_character.tether_pouch = ["orb_basic"]
	assert_false(record.errors(forged_saved, "owner_a").is_empty())


func test_item_candidate_debits_one_own_stack_with_actual_heal_food_or_unsaved_tonic() -> void:
	var rules := preload("res://scripts/world/death_satchel_rules.gd")
	var record := preload("res://scripts/net/character_record_rules.gd")
	for item: String in ["potion_small", "berries", "attack_tonic"]:
		var player: RefCounted = DATA.new()._player()
		player.set("character_id", "owner_a")
		var inventory: RefCounted = player.get("inventory")
		inventory.call("add", item, 2)
		var party: RefCounted = player.get("party")
		var creature: RefCounted = party.call("at", 0)
		creature.set("hp", float(creature.get("max_hp")) - 10.0)
		creature.set("nourishment", 10.0)
		creature.set("happiness", 20.0)
		var saved: Dictionary = player.call("save_data")
		saved.redesign_character = preload("res://scripts/creatures/teaching.gd").character_loadout_mirror(saved.party, saved.redesign_character)
		var before := record.portable_projection(saved)
		before.redesign_character["tether_pouch"] = [item]
		var original := before.duplicate(true)
		var effect := {"kind": "item_throw", "character_id": "owner_a", "creature_uid": before.party[0].uid,
			"generation": 1, "item_id": item, "count": 1, "action_id": "item-original-" + item}
		var view := {"owner_admitted": true, "encounter_active": true,
			"actor": {"character_id": "owner_a", "creature_uid": before.party[0].uid, "generation": 1,
				"hp": before.party[0].hp, "max_hp": before.party[0].max_hp}}
		var plan := COMMANDS.stage_item_use(before, effect, view)
		assert_true(plan.ok, str(plan))
		if not plan.ok: continue
		assert_eq(before, original, "candidate does not mutate inventory or owned creature")
		assert_true(plan.requires_owner_debit_ack)
		assert_eq(plan.effect, effect, "retain the original command identity")
		assert_eq(plan.state.party[1], before.party[1], "other owned creature unchanged")
		assert_eq(plan.state.redesign_character, before.redesign_character)
		assert_eq(rules.inventory_from(plan.state.inventory).count(item), 1)
		assert_eq(rules.inventory_from(plan.state.inventory).count("tm_burrow_strike"), 1)
		assert_eq(COMMANDS.stage_item_use(before, effect, view), plan, "retry stages the same candidate")
		match item:
			"potion_small":
				assert_eq(plan.state.party[0].hp, before.party[0].max_hp, "ordinary heal caps at actual maximum")
				assert_eq(plan.state.party[0].nourishment, 10.0)
				assert_true(plan.buff.is_empty())
			"berries":
				assert_eq(plan.state.party[0].hp, before.party[0].hp)
				assert_eq(plan.state.party[0].nourishment, 45.0)
				assert_eq(plan.state.party[0].happiness, 28.0)
			"attack_tonic":
				assert_eq(plan.state.party, before.party, "temporary tonic never becomes a saved party field")
				assert_eq(plan.buff, rules.db().definition(item).creature_buff)
		for defect: String in ["foreign_owner", "foreign_uid", "generation", "stale_hp", "empty", "fainted", "extra"]:
			var current := before.duplicate(true)
			var forged := effect.duplicate(true)
			var changed := view.duplicate(true)
			match defect:
				"foreign_owner": forged.character_id = "owner_b"
				"foreign_uid": forged.creature_uid = current.party[1].uid
				"generation": forged.generation = 2
				"stale_hp": changed.actor.hp = float(current.party[0].hp) - 1.0
				"empty": current.inventory = rules.slots(rules.inventory_from([]))
				"fainted":
					current.party[0].hp = 0.0
					current.party[0].fainted = true
					changed.actor.hp = 0.0
				"extra": forged.heal = 9999
			var frozen := current.duplicate(true)
			assert_false(COMMANDS.stage_item_use(current, forged, changed).ok, item + ":" + defect)
			assert_eq(current, frozen)
		if item == "potion_small":
			before.party[0].hp = before.party[0].max_hp
			view.actor.hp = before.party[0].hp
			assert_false(COMMANDS.stage_item_use(before, effect, view).ok, "full creature consumes no potion")
