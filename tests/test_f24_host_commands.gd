extends "res://tests/test_move_commit_runtime.gd"

## Existing host transaction and canonical consumer coverage. Flags are a
## disclosed test fixture; no native, two-peer or feature activation claim.
const COMMANDS := preload("res://scripts/combat/tether_commands.gd")
const MASTERY := preload("res://scripts/creatures/move_mastery.gd")
const MOVES := preload("res://scripts/creatures/move_db.gd")
const MANAGER := preload("res://scripts/combat/combat_manager.gd")
const DATA := preload("res://tests/test_tm_teach_transaction.gd")
var _saved_commands: Dictionary

func test_personal_view_cache_requires_current_character_world_and_epoch() -> void:
	var session := preload("res://scripts/net/session.gd").new()
	var scope := {"character_id": "owner_a", "world_namespace": "world-a", "session_epoch": "epoch-a"}
	var view := {"character_id": "owner_a", "registry_revision": 7, "redesign_character": {"tether_pouch": ["potion_small"]}}
	for key: String in ["character_id", "world_namespace", "session_epoch", "missing"]:
		session._foundation_personal_cache = view.duplicate(true)
		session._foundation_personal_cache_scope = scope.duplicate(true)
		assert_eq(session._personal_view_for_scope(scope), view)
		var changed := scope.duplicate(true)
		if key == "missing": changed = {}
		else: changed[key] = "replacement"
		assert_true(session._personal_view_for_scope(changed).is_empty(), key)
		assert_true(session._foundation_personal_cache.is_empty())
		assert_true(session._foundation_personal_cache_scope.is_empty())
		assert_true(session._personal_view_for_scope(scope).is_empty(), "must await current reply; changing back cannot revive cleared cache")
	session.free()

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
	var profile := {"creature_uid": "creature_a", "max": 100.0, "regen_per_second": 10.0}
	host.preview_wind(id, 1, profile, 0.0, 7000)
	pool.wind = 0.0
	pool.wind_ready_at_ms = 7000
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

func test_snare_presentation_uses_current_record_body_and_remaining_host_duration() -> void:
	COMMANDS._config.feature_flags.ui_enabled = true
	var player: RefCounted = DATA.new()._player()
	var creature: RefCounted = player.get("party").call("at", 0)
	var uid := str(creature.get("uid"))
	var status := {"kind": "snare", "target_uid": uid, "target_generation": 3,
		"character_id": "owner_a", "until_ms": 5000, "catch_grants": {"owner_a": {"until_ms": 5000, "bonus": 0.1}}}
	var before := status.duplicate(true)
	var view := COMMANDS.snare_presentation(status, uid, 3, 3500)
	assert_eq(view.remaining_s, 1.5)
	assert_false(view.has("until_ms"), "a guest has its own clock")
	assert_false(view.has("catch_grants"), "presentation carries no catch authority")
	assert_true(COMMANDS.snare_presentation(status, uid, 4, 3500).is_empty())
	assert_true(COMMANDS.snare_presentation(status, "another-creature", 3, 3500).is_empty())
	assert_true(COMMANDS.snare_presentation(status, uid, 3, 5000).is_empty())
	assert_eq(status, before)
	var body := preload("res://scripts/creatures/wild_creature.gd").new()
	body.instance = creature
	body.set_meta(&"tether_body_generation", 3)
	var director := preload("res://tests/test_client_trainer_victory.gd").DirectorFixture.new()
	var record := {"encounter_id": "snare-view", "phase": "active", "seq": 7,
		"participants": {1: {"character_id": "owner_a"}},
		"opponent": {"card": {"uid": uid}, "body_generation": 3, "tether_snare_view": view}}
	var hp_before := float(creature.get("hp"))
	director._present_tether_snare(record, body)
	var visual: Node3D = body.get_node_or_null("TetherSnareVisual") as Node3D
	assert_true(visual != null)
	if visual == null:
		body.free()
		director.free()
		return
	assert_true(visual.visible)
	assert_eq(visual.get_child_count(), 2, "one loop and one line, no collision or particle body")
	visual.call("_process", 0.5)
	assert_eq(visual.get("_remaining_s"), 1.0)
	director._present_tether_snare(record, body)
	assert_eq(visual.get("_remaining_s"), 1.0, "duplicate record cannot restart the local duration")
	visual.call("_process", 1.0)
	assert_false(visual.visible)
	record.seq = 8
	record.opponent.tether_snare_view.remaining_s = 2.0
	director._present_tether_snare(record, body)
	assert_true(visual.visible, "new host refresh reuses the same two meshes")
	assert_eq(visual.get_child_count(), 2)
	record.seq = 7
	record.opponent.tether_snare_view.remaining_s = 3.0
	director._present_tether_snare(record, body)
	assert_eq(visual.get("_remaining_s"), 2.0, "older record cannot refresh the effect")
	body.set_meta(&"tether_body_generation", 4)
	record.seq = 9
	director._present_tether_snare(record, body)
	assert_false(visual.visible, "an older record cannot snare the same UID's new physical lifetime")
	body.set_meta(&"tether_body_generation", 3)
	record.seq = 9
	record.phase = "done"
	director._present_tether_snare(record, body)
	assert_false(visual.visible)
	record.phase = "active"
	record.seq = 10
	record.opponent.card.uid = "another-creature"
	director._present_tether_snare(record, body)
	assert_false(visual.visible, "foreign target cannot bind to this body")
	var proxy := preload("res://scripts/creatures/shared_opponent_proxy.gd").new()
	proxy.instance = creature
	proxy.body_generation = 3
	proxy.set_meta(&"tether_body_generation", 99)
	record.opponent.card.uid = uid
	director._present_tether_snare(record, proxy)
	var proxy_visual: Node3D = proxy.get_node_or_null("TetherSnareVisual") as Node3D
	assert_true(proxy_visual != null, "guest lifetime comes from the actual proxy generation")
	proxy.body_generation = 4
	director._present_tether_snare(record, proxy)
	if proxy_visual != null: assert_false(proxy_visual.visible, "guest replacement refuses older lifetime even with the same owned UID")
	proxy.free()
	assert_eq(float(creature.get("hp")), hp_before)
	assert_false(body.has_meta(&"tether_snare"), "visual consumer never installs canonical status")
	body.free()
	director.free()

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
		var ordinary := math.rolled_damage(float(moves[index].power) * (0.5 if index == 0 else 1.5), 20.0, 10.0, 0.5,
			MOVES.load_default().power("pebble_toss"), type_scale)
		assert_eq(strike.actual_hp_debit, ordinary, "rank-five profile and actual type scale exactly like one ordinary scaled-power quick")
	assert_eq(COMMANDS.stage_joint_attack(effect, moves, view, math.config()).strikes, plan.strikes, "retry retains exact child identities")
	var low_power := view.duplicate(true)
	low_power.target.defence = 1000000000.0
	for actor: Dictionary in low_power.actors: actor.attack = 1.0
	var floor_plan: Dictionary = COMMANDS.stage_joint_attack(effect, moves, low_power, math.config())
	assert_true(floor_plan.ok, str(floor_plan))
	if floor_plan.ok:
		assert_eq(floor_plan.strikes[0].actual_hp_debit, 1.0, "half power keeps the ordinary minimum damage")
		assert_eq(floor_plan.strikes[1].actual_hp_debit, 1.0, "one-and-a-half power does not amplify the minimum floor")
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


func test_tag_parent_retains_two_frozen_quicks_and_rejects_stale_or_duplicate_arrival() -> void:
	# Reuse the existing tracked-host fixture. Meter/combo/positions are explicit
	# unit setup; this does not claim a mounted switch, transport or native hit.
	for defect: String in ["none", "partner", "target", "body", "revision"]:
		var fixture: Dictionary = preload("res://tests/test_f22_action_publication.gd").new()._fixture()
		var tracked: RefCounted = fixture.host
		var tag_id := str(fixture.id)
		var participant: Dictionary = tracked.encounters[tag_id].participants[1]
		participant["tether_commands"] = COMMANDS.admission("character-a", tag_id, 0)
		participant.tether_commands.meter = 40.0
		participant.tether_commands.combo = {"source_uid":"owned-a", "source_generation":1,
			"target_uid":"wild-a", "target_generation":1, "action_id":"prior-landed-hit", "until_ms":11000}
		var actors: Array = []
		var frozen_moves: Array = []
		for index: int in 2:
			var uid := "owned-a" if index == 0 else "owned-b"
			var actor := {"character_id":"character-a", "encounter_id":tag_id, "creature_uid":uid,
				"generation":index + 1, "action":index + 1, "hp":100.0, "attack":20.0,
				"position":Vector3.ZERO, "facing":Vector3.RIGHT, "bonus_product":1.0}
			actors.append(actor)
			var frozen := MASTERY.freeze_action(MASTERY.owned_record(_owned(uid)), "quick", actor, [], MOVES.load_default())
			assert_true(frozen.ok, str(frozen))
			if not frozen.ok: return
			frozen_moves.append(MANAGER.host_move_profile(MOVES.load_default(), "player_quick", "pebble_toss", 0.5, 0.5, 1.0, 0.0, frozen.move))
		var view := {"actor":actors[0], "incoming":actors[1], "actors":actors, "rolls":[0.5,0.5],
			"target":{"uid":"wild-a", "generation":1, "hp":30.0, "hostile":true,
				"position":Vector3(2,0,0), "defence":10.0, "type":"Water", "secondary_type":""},
			"switch_allowed":true, "incoming_is_next_owned":true, "combo_geometry_connected":true}
		var request := COMMANDS.intent(tag_id, 1, 1, "tag_combo")
		var before: Dictionary = participant.tether_commands.duplicate(true)
		var prepared: Dictionary = tracked.prepare_tether_tag_command(request, 1, fixture.binding, view, frozen_moves, 10001)
		assert_true(prepared.ok, str(prepared))
		if not prepared.ok: return
		var parent := str(prepared.original.action_id)
		assert_eq(participant.tether_commands, before, "preparation never spends meter or switches")
		assert_eq(float(tracked.record(tag_id).opponent.hp), 30.0, "no HP before arrival")
		assert_eq(participant.creature_uid, "owned-a")
		var repeated: Dictionary = tracked.prepare_tether_tag_command(request, 1, fixture.binding, view, frozen_moves, 10002)
		assert_true(repeated.ok and repeated.duplicate)
		assert_eq(repeated.original, prepared.original, "same exact parent and two accepted profiles")
		assert_false(tracked.prepare_tether_tag_command(COMMANDS.intent(tag_id, 1, 2, "tag_combo"),
			1, fixture.binding, view, frozen_moves, 10003).ok, "another request cannot substitute the retained parent")
		prepared.original.moves[0].power = 99999.0
		assert_ne(tracked.move_action_original(tag_id, 1, parent).admission.moves[0].power, 99999.0,
			"the caller cannot mutate the retained original")
		match defect:
			"partner": view.incoming.creature_uid = "foreign-creature"
			"target": view.target.generation = 2
			"body": assert_true(tracked.bind_actor_body(tag_id, 1, "character-a", fixture.owned, 202).ok)
			"revision": participant.tether_commands.revision += 1
		var actual_before: Dictionary = participant.tether_commands.duplicate(true)
		var arrival: Dictionary = tracked.begin_tether_tag_resolution(tag_id, 1, parent, fixture.binding, view)
		assert_eq(arrival.get("ok"), defect == "none", defect + ":" + str(arrival))
		if defect == "none":
			assert_eq(arrival.joint.strikes.size(), 2)
			assert_eq(arrival.joint.strikes[0].attacker_uid, "owned-a")
			assert_eq(arrival.joint.strikes[1].attacker_uid, "owned-b")
			assert_true(tracked.move_action_publication_pending(tag_id))
		assert_false(tracked.begin_tether_tag_resolution(tag_id, 1, parent, fixture.binding, view).ok,
			"duplicate or cancelled arrival never enters the writer")
		assert_eq(float(tracked.record(tag_id).opponent.hp), 30.0)
		assert_eq(participant.tether_commands, actual_before, "arrival validation itself never spends")
		if defect == "none":
			assert_false(tracked.bind_actor_body(tag_id, 1, "character-a", fixture.owned, 303).ok,
				"the resolution fence permits only this parent's incoming creature")
			var incoming := {"uid":"owned-b", "hp":100.0, "max_hp":100.0, "fainted":false}
			var bound: Dictionary = tracked.bind_actor_body(tag_id, 1, "character-a", incoming, 202)
			assert_true(bound.ok, str(bound))
			if not bound.ok: return
			assert_true(tracked.bind_actor_body(tag_id, 1, "character-a", incoming, 202).ok,
				"unchanged canonical incoming binding remains observable")
			assert_false(tracked.bind_actor_body(tag_id, 1, "character-a", incoming, 303).ok,
				"same parent cannot replace its incoming body a second time")
			assert_false(tracked.bind_actor_vitals(tag_id, 1, "character-a", incoming, int(bound.vitals.body_generation) + 1).ok,
				"same parent cannot replace its incoming generation")
			var incoming_binding := {"character_id":"character-a", "creature_uid":"owned-b",
				"deployment_generation":2, "actor_generation":bound.vitals.body_generation, "body_instance_id":202}
			var written := [{"hp":25.0, "hp_max":30.0, "damage":999.0, "killed":false},
				{"hp":16.0, "hp_max":30.0, "damage":999.0, "killed":false}]
			tracked.set_opponent_hp(tag_id, 16.0, 30.0, written[1])
			var bad := written.duplicate(true)
			bad[1].hp = 26.0
			assert_false(tracked.record_tether_tag_outcome(tag_id, 1, parent, incoming_binding, bad, 10500).ok)
			assert_eq(participant.tether_commands, actual_before, "invalid debit cannot spend")
			var committed: Dictionary = tracked.record_tether_tag_outcome(tag_id, 1, parent, incoming_binding, written, 10500)
			assert_true(committed.ok, str(committed))
			if not committed.ok: return
			assert_eq(participant.tether_commands.meter, 0.0, "one 40-meter parent cost")
			assert_eq(participant.tether_commands.switch_until_ms, 12000, "actual arrival starts the full 1.5-second lockout")
			assert_eq(committed.delta.effect.strikes[0].actual_hp_debit, 5.0)
			assert_eq(committed.delta.effect.strikes[1].actual_hp_debit, 9.0)
			var pending: Dictionary = tracked.move_mastery_outcome(tag_id, 1, -1)
			assert_eq(pending.action_id, parent)
			assert_eq(pending.outcomes.size(), 2)
			assert_eq(pending.outcomes[0].outcome.attacker_uid, "owned-a")
			assert_eq(pending.outcomes[1].outcome.attacker_uid, "owned-b")
			assert_ne(pending.outcomes[0].outcome.action_id, pending.outcomes[1].outcome.action_id)
			assert_eq(pending.outcomes[0].binding, fixture.binding)
			assert_eq(pending.outcomes[1].binding, incoming_binding)
			assert_false(tracked.record_tether_tag_outcome(tag_id, 1, parent, incoming_binding, written, 10600).ok,
				"duplicate outcome cannot spend or write twice")
			assert_true(tracked.acknowledge_move_action_publication(tag_id, 1, parent, committed))
			assert_true(tracked.leave(tag_id, 1).ok)
			pending.peer = "character-a"
			assert_eq(tracked.move_mastery_outcome(tag_id, "character-a", -1), pending,
				"failed journal keeps both child originals under the stable departed owner")
			tracked.forget(tag_id)
			assert_false(tracked.record(tag_id).is_empty(), "pending mastery prevents losing the parent")
			assert_false(tracked.acknowledge_move_mastery(tag_id, "character-a", -1, pending.outcomes[0].outcome.action_id))
			assert_true(tracked.acknowledge_move_mastery(tag_id, "character-a", -1, parent))
			assert_true(tracked.pending_move_mastery().is_empty())
			assert_eq(float(tracked.record(tag_id).opponent.hp), 16.0, "journal acknowledgement never restores HP")


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


func test_retained_item_ack_preserves_active_body_and_settles_same_v3_decision_once() -> void:
	var record := preload("res://scripts/net/character_record_rules.gd")
	var delivery := preload("res://scripts/net/foundation_delivery.gd")
	var authority_type := preload("res://scripts/net/character_authority.gd")
	for item: String in ["potion_small", "berries", "attack_tonic"]:
		for depart: bool in [false, true]:
			var player: RefCounted = DATA.new()._player()
			player.set("character_id", "owner_a")
			player.get("inventory").call("add", item, 2)
			var creature: RefCounted = player.get("party").call("at", 0)
			creature.set("hp", float(creature.get("max_hp")) - 10.0)
			creature.set("nourishment", 10.0)
			creature.set("happiness", 20.0)
			var before := record.portable_projection(player.call("save_data"))
			before.redesign_character["tether_pouch"] = [item]
			var uid: String = before.party[0].uid
			host = HOST.new(1)
			id = host.open(1, "meadows", "wild", {"species_id": "bramblebun", "hp": 200.0, "hp_max": 200.0}, uid, "owner_a").encounter_id
			assert_true(host.bind_actor_body(id, 1, "owner_a", before.party[0], 123).ok)
			host.bind_tether_commands(id, 1, before)
			_command_pool().meter = 100.0 # Existing component resource setup.
			var binding := {"character_id": "owner_a", "creature_uid": uid, "deployment_generation": 1, "actor_generation": 1, "body_instance_id": 123}
			var request := COMMANDS.intent(id, 1, 7, "item_throw")
			var prepared: Dictionary = host.prepare_tether_item_command(request, 1, before, binding, 0, "item-world", "item-epoch", 2000)
			if item == "attack_tonic":
				assert_true(prepared.ok, "tonic reserves the same private original; no effect before actual owner save")
				assert_eq(host.pending_tether_items(id).size(), 1)
				assert_eq(_command_pool().meter, 100.0)
				var policy := preload("res://scripts/net/session.gd").new()
				var tonic_row := {"action": "tether_item", "intent": {"effect": {"item_id": item}}}
				assert_false(policy.training_actor_baseline_ready(1, tonic_row), "recovered pending tonic refuses before the accepted World writer")
				policy.free()
				assert_eq(player.get("inventory").call("count", item), 2)
			assert_true(prepared.ok, str(prepared))
			if not prepared.ok: continue
			var original: Dictionary = prepared.original
			assert_true(original.intent.is_read_only())
			assert_true(original.intent.effect.is_read_only())
			assert_true(original.command_plan.is_read_only())
			assert_true(original.command_plan.state.is_read_only())
			assert_eq(host.prepare_tether_item_command(request, 1, before, binding, 0, "item-world", "item-epoch", 2001).original, original)
			assert_false(host.prepare_tether_item_command(COMMANDS.intent(id, 1, 8, "item_throw"), 1, before, binding, 0, "item-world", "item-epoch", 2002).ok)
			assert_eq(host.authorize_move_start({"encounter_id": id, "action": 8, "slot": "quick"}, 1, before.party[0], binding, _move(), WIND, 2000).code, "item_save_pending")
			assert_eq(host.validate_strike({"encounter_id": id}, 1, {}).code, "item_save_pending")
			assert_false(host.prepare_tether_item_command(request, 1, before, binding, 0, "foreign-world", "item-epoch", 2002).ok)
			assert_false(host.commit_tether_command(COMMANDS.intent(id, 1, 8, "rally"), 1, {}, 2000).ok)
			assert_false(host.bind_actor_body(id, 1, "owner_a", before.party[0], 456).ok)
			assert_false(host.stage_actor_vitals(id, 1, uid, 1, 0, "interleaved-damage", "damage", 5.0, 128).ok)
			host.close(id)
			host.forget(id)
			assert_eq(host.phase(id), "active")
			assert_eq(_command_pool().meter, 100.0, "prepare and refused arrivals spend no meter")
			var authority := authority_type.new()
			assert_true(authority.bind_world("item-world"))
			assert_true(authority.seed_admitted_character(before, "owner_a").ok)
			var token: Dictionary = authority.stage_character_action("owner_a", 0, "tether_item", original.intent, original.context)
			assert_true(token.ok, str(token))
			if not token.ok: continue
			var row: Dictionary = delivery.make_record("item-slot", "item-world", "item-epoch", token, null, record.errors)
			assert_false(row.is_empty())
			if row.is_empty(): continue
			var stage: Dictionary = host.stage_actor_training_baseline(row, token.state, 1, "item-world", "item-slot")
			assert_true(stage.ok, str(stage))
			assert_false(host.commit_actor_training_baseline(stage, row, token.state, 1, {row.delivery_id: row}, "item-world", "item-slot"), "pending row is not accepted owner save")
			assert_true(authority.finish_creature_training(token, false))
			assert_eq(authority.state("owner_a"), before)
			assert_eq(_command_pool().meter, 100.0)
			assert_eq(host.record(id).participants[1].actor_vitals[uid].hp, before.party[0].hp)
			assert_false(host.cancel_unjournaled_tether_item(original, {row.delivery_id: row}, "item-world"), "durable pending original survives departure policy")
			assert_false(host.cancel_unjournaled_tether_item(original, {}, "foreign-world"))
			assert_true(host.cancel_unjournaled_tether_item(original, {}, "item-world"), "failed first writer leaves an untouched reservation that departure can release")
			assert_true(host.pending_tether_items(id).is_empty())
			assert_eq(_command_pool().meter, 100.0, "cancellation neither spends nor refunds")
			assert_true(original.cancelled)
			assert_false(host.cancel_unjournaled_tether_item(original, {}, "item-world"), "duplicate cancellation is read-only")
			prepared = host.prepare_tether_item_command(request, 1, before, binding, 0, "item-world", "item-epoch", 2003)
			assert_true(prepared.ok)
			original = prepared.original
			token = authority.stage_character_action("owner_a", 0, "tether_item", original.intent, original.context)
			assert_true(authority.finish_creature_training(token, true))
			row.status = "accepted"
			if depart: assert_true(host.leave(id, 1).ok)
			assert_false(host.cancel_unjournaled_tether_item(original, {row.delivery_id: row}, "item-world"), "saved accepted original must finish even after leaving")
			stage = host.stage_actor_training_baseline(row, token.state, 1, "item-world", "item-slot")
			assert_true(stage.ok, str(stage))
			assert_eq(stage.changes.size(), 1)
			assert_eq(stage.changes[0].vitals.is_empty(), item != "potion_small", "food/tonic invent no HP proposal")
			if item == "attack_tonic":
				assert_false(authority.install_saved_tether_tonic("owner_a", row, original, "stream-a", "transport-epoch", 10), "no consumer before canonical actor commit")
			assert_true(host.commit_actor_training_baseline(stage, row, token.state, 1, {row.delivery_id: row}, "item-world", "item-slot"))
			if item == "attack_tonic":
				assert_false(host.finalize_saved_tether_item(original, row, {row.delivery_id: row}, "item-world", "item-slot").ok, "saved actor alone cannot release an uninstalled tonic")
				assert_true(authority.install_saved_tether_tonic("owner_a", row, original, "stream-a", "transport-epoch", 10))
				original["tonic_receipt"] = row.receipt
				var active: Dictionary = authority.tether_tonic_projection("owner_a")
				assert_eq(active[uid].effects[0].remaining_s, 90.0)
				authority.tick_tether_tonics("owner_a", 9.0, [uid], "stream-a", "transport-epoch", 10)
				assert_eq(authority.tether_tonic_projection("owner_a"), active, "preactivation/duplicate input cannot age a tonic")
				authority.tick_tether_tonics("owner_a", 9.0, [uid], "stream-a", "transport-epoch", 11)
				assert_eq(authority.tether_tonic_projection("owner_a")[uid].effects[0].remaining_s, 81.0)
				authority.bind_tether_tonic_stream("owner_a", "stream-b", "transport-epoch")
				authority.tick_tether_tonics("owner_a", 10.0, [uid], "stream-a", "transport-epoch", 99)
				assert_eq(authority.tether_tonic_projection("owner_a")[uid].effects[0].remaining_s, 81.0, "old buffered stream cannot age the rebased original")
				# Actual Game signal and Session callback; no new fixture or clock.
				var clock_game := preload("res://autoload/game_state.gd").new()
				clock_game.local = player
				clock_game.world = preload("res://tests/test_foundation_resources.gd").new()._world()
				clock_game.world.reward_delivery_namespace = "item-world"
				var clock_session := preload("res://scripts/net/session.gd").new()
				clock_game.add_child(clock_session)
				clock_game.session = clock_session
				clock_session._character_authority = authority
				clock_session._altar_epoch = "transport-epoch"
				clock_session._mode = "host"
				clock_session._tether_tonic_observer_scope = clock_session._tether_tonic_current_scope()
				authority.bind_tether_tonic_stream("owner_a", "local", "transport-epoch", 10)
				clock_session._sync_tether_tonic_scope()
				assert_true(clock_game.is_connected("party_passive_tick", clock_session._tether_tonic_party_tick))
				clock_session._teardown()
				assert_true(clock_game.is_connected("party_passive_tick", clock_session._tether_tonic_party_tick), "same-context host-to-offline teardown preserves the local clock")
				clock_game.party_passive_tick.emit({"character_id": "owner_a", "world_namespace": "item-world",
					"session_epoch": "transport-epoch", "uid": uid, "sequence": 11, "delta": 9.0})
				assert_eq(authority.tether_tonic_projection("owner_a")[uid].effects[0].remaining_s, 72.0, "actual signal still ages the authoritative companion after closing transport")
				clock_game.world.reward_delivery_namespace = "replacement-world"
				clock_session._sync_tether_tonic_scope()
				assert_false(clock_game.is_connected("party_passive_tick", clock_session._tether_tonic_party_tick), "changed world disconnects the old authority clock")
				clock_game.free()
				authority.bind_tether_tonic_stream("owner_a", "stream-b", "transport-epoch")
				for tick: int in range(1, 10): authority.tick_tether_tonics("owner_a", 10.0, [uid], "stream-b", "transport-epoch", tick)
				assert_true(authority.tether_tonic_projection("owner_a")[uid].effects.is_empty())
				assert_true(authority.install_saved_tether_tonic("owner_a", row, original, "stream-b", "transport-epoch", 9))
				assert_true(authority.tether_tonic_projection("owner_a")[uid].effects.is_empty(), "accepted receipt retry never refreshes expired time")
				assert_eq(authority.state("owner_a").party, row.after.party, "timers remain outside portable cards")
			var participant: Dictionary = host.record(id).retained_actor_participants["owner_a"] if depart else host.record(id).participants[1]
			assert_eq(participant.tether_commands.meter, 75.0)
			assert_eq(participant.actor_vitals[uid].hp, row.after.party[0].hp)
			assert_eq(participant.actor_vitals[uid].body_generation, 1)
			assert_eq(participant.actor_vitals[uid].body_instance_id, 123)
			assert_eq(participant.actor_bound_uid, uid)
			assert_true(host.pending_actor_vitals(id).is_empty(), "same v3 accepted decision settles the internal HP receipt")
			var after: Dictionary = host.record(id).duplicate(true)
			var duplicate: Dictionary = host.stage_actor_training_baseline(row, token.state, 1, "item-world", "item-slot")
			assert_true(duplicate.ok)
			assert_true(duplicate.changes.is_empty())
			assert_true(host.commit_actor_training_baseline(duplicate, row, token.state, 1, {row.delivery_id: row}, "item-world", "item-slot"))
			assert_eq(host.record(id), after, "accepted duplicate cannot heal or spend again")
			assert_eq(host.pending_tether_items(id).size(), 1, "publication still retains the same original fence")
			var snapshot: Dictionary = host.presentation_snapshot(host.record(id))
			if not depart: assert_false(snapshot.participants[1].tether_commands.has("item_pending"), "private original never enters network presentation")
			assert_eq(creature.get("hp"), before.party[0].hp)
			assert_eq(player.get("inventory").call("count", item), 2, "component prep/host ACK never mutates live owner inventory")
			var unrelated := row.duplicate(true)
			unrelated.intent.request.sequence += 1
			assert_false(host.finalize_saved_tether_item(original, unrelated, {unrelated.delivery_id: unrelated}, "item-world", "item-slot").ok)
			assert_false(host.finalize_saved_tether_item(original, row, {}, "item-world", "item-slot").ok)
			var finalized: Dictionary = host.finalize_saved_tether_item(original, row, {row.delivery_id: row}, "item-world", "item-slot")
			assert_true(finalized.ok, str(finalized))
			if finalized.get("ok") == true:
				assert_true(host.pending_tether_items(id).is_empty())
				assert_eq(participant.tether_commands.item_result.request, request)
				assert_eq(participant.tether_commands.item_result.receipt, row.receipt)
				assert_eq(participant.actor_vitals[uid].body_instance_id, 123)
				var finalized_record: Dictionary = host.record(id).duplicate(true)
				assert_false(host.finalize_saved_tether_item(original, row, {row.delivery_id: row}, "item-world", "item-slot").ok)
				assert_eq(host.record(id), finalized_record, "duplicate finalizer cannot publish or increment sequence again")
				var history: Dictionary = host.stage_actor_training_baseline(row, token.state, 1, "item-world", "item-slot")
				assert_true(history.ok)
				assert_true(history.changes.is_empty(), "history without private original never rewrites the live body")
				var fixture := preload("res://tests/test_foundation_resource_save.gd")
				var game := fixture.FixtureGame.new()
				game.local = player
				game.world = preload("res://tests/test_foundation_resources.gd").new()._world()
				game.world.world_id = "item-slot"
				game.world.reward_delivery_namespace = "item-world"
				game.world.reward_deliveries = {row.delivery_id: row}
				var session := fixture.FixtureSession.new()
				session.fixture = game
				session._character_authority = authority_type.new()
				var director := preload("res://tests/test_client_trainer_victory.gd").DirectorFixture.new()
				director._session = session
				var manager := MANAGER.new()
				manager._encounter_link = director
				manager._tether_command_view = {"pending_request": request, "item_result": finalized.result}
				manager._consume_saved_tether_item_result()
				assert_true(manager._tether_command_view.has("pending_request"), "accepted host result waits for owner saved receipt")
				player.redesign_character.transaction_receipts.append(row.receipt)
				assert_true(session._settle_owner_training_accepted(player, game.world, row))
				game.world.reward_deliveries = {}
				manager._consume_saved_tether_item_result()
				assert_false(manager._tether_command_view.has("pending_request"), "later station row replacement cannot strand accepted item input")
				manager._tether_command_view["pending_request"] = COMMANDS.intent(id, 1, 8, "item_throw")
				manager._consume_saved_tether_item_result()
				assert_true(manager._tether_command_view.has("pending_request"), "older publication cannot clear a newer request")
				game.world.reward_delivery_namespace = "replacement-world"
				assert_false(session.tether_item_owner_result_saved(finalized.result), "bounded proof cannot cross world scope")
				game.world.reward_delivery_namespace = "item-world"
				game.world.reward_deliveries = {row.delivery_id: row}
				assert_true(session._settle_owner_training_accepted(player, game.world, row))
				game.world = null
				assert_false(session.tether_item_owner_result_saved(finalized.result), "teardown drops a dead weak world before inspecting scope")
				manager.free()
				director.free()
				session.free()
				game.free()

func test_command_input_honors_the_mounted_command_view_before_allocating_sequence() -> void:
	var input := preload("res://scripts/ui/tether_command_input.gd").new()
	var snapshot := {"active": true, "input_context": "combat", "encounter_id": "input-original",
		"generation": 2, "last_sequence": 0, "unlocked_commands": ["rally", "snare"]}
	var submitted: Array[Dictionary] = []
	input.configure(func() -> Dictionary: return snapshot,
		func(request: Dictionary) -> bool: submitted.append(request.duplicate(true)); return true)
	assert_false(input._request_snapshot("item_throw", snapshot), "a view without the scoped Item consumer cannot allocate an Item sequence")
	assert_false(input._request_snapshot("tag_combo", snapshot))
	assert_true(submitted.is_empty())
	assert_eq(input._sequence, 0, "locked input allocates no command sequence")
	assert_true(input._request_snapshot("rally", snapshot))
	assert_eq(submitted.size(), 1)
	assert_eq(submitted[0], COMMANDS.intent("input-original", 2, 1, "rally"))
	input.free()


func test_item_input_tracks_current_trainer_scope_and_keeps_pending_request_fenced() -> void:
	COMMANDS._config.feature_flags.network_enabled = true
	var fixture := preload("res://tests/test_foundation_resource_save.gd")
	var game := fixture.FixtureGame.new()
	game.world = preload("res://tests/test_foundation_resources.gd").new()._world()
	game.local = DATA.new()._player()
	game.local.character_id = "owner_a"
	var uid: String = game.local.party.at(0).uid
	host.record(id).participants[1].creature_uid = uid
	game.local.inventory.add("potion_small", 3)
	var session := fixture.FixtureSession.new()
	session.fixture = game
	game.session = session
	var director := preload("res://tests/test_client_trainer_victory.gd").DirectorFixture.new()
	var manager := MANAGER.new()
	director._session = session
	director._encounter_host = host
	director._manager = manager
	manager._encounter_link = director
	manager._encounter_id = id
	manager._encounter_kind = "trainer"
	manager.state = MANAGER.State.ACTIVE
	var owner_party: RefCounted = game.local.party
	var members: Array[RefCounted] = [game.local.party.at(0)]
	manager._party = members
	director._deployment_identity[1] = {"character_id": "owner_a", "creature_uid": uid, "generation": 1}
	host.encounters[id].kind = "trainer"
	host.encounters[id].opponent["owner_npc"] = "trainer_arden"
	var scope := preload("res://scripts/net/combat_round_reward.gd").scope(
		game.world.reward_delivery_namespace, "resource-epoch", "meadows", "trainer_arden", id)
	director._ordinary_combat_reward_owners[id] = scope
	host.encounters[id]["ordinary_combat_reward_owner"] = scope
	var admitted := preload("res://scripts/net/character_record_rules.gd").portable_projection(game.local.save_data())
	admitted.redesign_character["tether_pouch"] = ["potion_small"]
	assert_true(preload("res://scripts/net/character_record_rules.gd").errors(admitted, "owner_a").is_empty(), "actual spawned UID remains admissible")
	host.bind_tether_commands(id, 1, admitted)
	var pouch_view: Dictionary = host.tether_pouch_view(id, 1, admitted)
	assert_eq(pouch_view, {"pouch_count": 3, "item_consumer_ready": true})
	var input := preload("res://scripts/ui/tether_command_input.gd").new()
	var submitted: Array[Dictionary] = []
	input.configure(manager.tether_command_snapshot,
		func(request: Dictionary) -> bool: submitted.append(request.duplicate(true)); return true)
	for on_host: bool in [true, false]:
		director.host = on_host
		director._encounter = host.record(id).duplicate(true)
		manager._tether_command_view = pouch_view.duplicate(true)
		var snapshot: Dictionary = manager.tether_command_snapshot()
		assert_true(snapshot.active)
		assert_true(snapshot.unlocked_commands.has("item_throw"), "current host/guest scoped trainer exposes Item")
		assert_false(snapshot.unlocked_commands.has("tag_combo"))
		assert_true(input._request_snapshot("item_throw", snapshot))
		if submitted.is_empty(): continue # Keep the failed assertion without a Nil cascade.
		assert_eq(submitted.back(), COMMANDS.intent(id, 1, submitted.size(), "item_throw"), "only four original command fields")
		manager._tether_command_view["pending_request"] = submitted.back().duplicate(true)
		var sequence := input._sequence
		assert_false(input._request_snapshot("item_throw", manager.tether_command_snapshot()))
		assert_eq(input._sequence, sequence, "unsettled original allocates no second request")
		manager._tether_command_view = pouch_view.duplicate(true)
		for defect: String in ["world", "epoch", "realm", "character", "uid", "owner", "active_uid", "party", "phase", "kind", "encounter", "network", "runtime", "consumer"]:
			var record: Dictionary = host.encounters[id] if on_host else director._encounter
			var saved_record := record.duplicate(true)
			var saved_deployment: Dictionary = director._deployment_identity[1].duplicate(true)
			var current_scope: Dictionary = scope if on_host else record.ordinary_combat_reward_owner
			match defect:
				"world": game.world.reward_delivery_namespace = "foreign-world"
				"epoch": current_scope.session_id = "foreign-epoch"
				"realm": current_scope.realm = "cloudreach"
				"character": director._deployment_identity[1].character_id = "foreign-owner"
				"uid": director._deployment_identity[1].creature_uid = "foreign-creature"
				"owner": game.local.character_id = "foreign-owner"
				"active_uid": manager._active_index = -1
				"party": game.local.party = preload("res://autoload/party.gd").new()
				"phase": record.phase = "done"
				"kind": record.kind = "wild"
				"encounter": manager._encounter_id = "foreign-encounter"
				"network": COMMANDS._config.feature_flags.network_enabled = false
				"runtime": COMMANDS._config.feature_flags.runtime_enabled = false
				"consumer": manager._tether_command_view.item_consumer_ready = false
			assert_false(manager.tether_command_snapshot().unlocked_commands.has("item_throw"), defect)
			assert_false(input._request_snapshot("item_throw", manager.tether_command_snapshot()), defect)
			assert_eq(input._sequence, sequence)
			game.world.reward_delivery_namespace = "resource-namespace"
			game.local.character_id = "owner_a"
			game.local.party = owner_party
			manager._active_index = 0
			manager._tether_command_view = pouch_view.duplicate(true)
			scope.session_id = "resource-epoch"
			scope.realm = "meadows"
			director._deployment_identity[1] = saved_deployment
			record.clear()
			record.merge(saved_record, true)
			# Copies on the guest record must rebind the same restored scope.
			record.ordinary_combat_reward_owner = scope
			manager._encounter_id = id
			COMMANDS._config.feature_flags.network_enabled = true
			COMMANDS._config.feature_flags.runtime_enabled = true
	input.free()
	manager.free()
	director.free()
	session.free()
	game.free()


func test_wild_item_input_requires_current_saved_scope_and_refuses_older_health_original() -> void:
	# Reuse the actual guest record consumer and existing owner fixture. No
	# mounted solo/host runtime, physical input, journal or transport is claimed.
	COMMANDS._config.feature_flags.network_enabled = true
	var fixture := preload("res://tests/test_foundation_resource_save.gd")
	var game := fixture.FixtureGame.new()
	game.world = preload("res://tests/test_foundation_resources.gd").new()._world()
	game.local = DATA.new()._player()
	game.local.character_id = "owner_a"
	var uid: String = game.local.party.at(0).uid
	host.record(id).participants[1].creature_uid = uid
	game.local.inventory.add("potion_small", 2)
	var session := fixture.FixtureSession.new()
	session.fixture = game
	game.session = session
	var director := preload("res://tests/test_client_trainer_victory.gd").DirectorFixture.new()
	director.host = false
	director._session = session
	director._encounter_host = host
	var manager := MANAGER.new()
	director._manager = manager
	manager._encounter_link = director
	manager._encounter_id = id
	manager._encounter_kind = "wild"
	manager.state = MANAGER.State.ACTIVE
	var members: Array[RefCounted] = [game.local.party.at(0)]
	manager._party = members
	director._deployment_identity[1] = {"character_id": "owner_a", "creature_uid": uid, "generation": 1}
	var record: Dictionary = host.record(id)
	record["wild_actor_owner"] = preload("res://scripts/net/wild_actor_scope.gd").make(
		game.world.reward_delivery_namespace, session._altar_current_epoch(), "meadows", id)
	director._encounter = record
	var admitted := preload("res://scripts/net/character_record_rules.gd").portable_projection(game.local.save_data())
	admitted.redesign_character["tether_pouch"] = ["potion_small"]
	assert_true(preload("res://scripts/net/character_record_rules.gd").errors(admitted, "owner_a").is_empty(), "actual spawned UID remains admissible")
	host.bind_tether_commands(id, 1, admitted)
	manager._tether_command_view = host.tether_pouch_view(id, 1, admitted)
	assert_true(director.tether_item_command_available(id), "same current wild saved-HP scope exposes Item")
	assert_true(manager.tether_command_snapshot().unlocked_commands.has("item_throw"))
	assert_false(director.uses_durable_trainer_rewards(id), "no trainer/round reward capability is installed")
	record["ordinary_actor_vitals_pending"] = true
	var request := COMMANDS.intent(id, 1, 1, "item_throw")
	var refused: Dictionary = director._host_commit_encounter({"kind": "tether_command", "encounter_id": id, "request": request}, 1)
	assert_eq(refused.code, "pending_vitals")
	assert_eq(refused.command_request, request)
	assert_true(host.pending_tether_items(id).is_empty(), "an older saved HP proposal prevents first Item reservation")
	record.ordinary_actor_vitals_pending = false
	for field: String in ["world_namespace", "session_id", "realm", "encounter_id"]:
		var original: Dictionary = record.wild_actor_owner.duplicate(true)
		record.wild_actor_owner[field] = "foreign"
		assert_false(director.tether_item_command_available(id), field)
		assert_false(manager.tether_command_snapshot().unlocked_commands.has("item_throw"), field)
		record.wild_actor_owner = original
	record.erase("wild_actor_owner")
	assert_false(director.tether_item_command_available(id), "legacy wild record cannot offer an unsaved Item consumer")
	var before := record.duplicate(true)
	assert_true(director.finalize_saved_tether_item({"intent": {"request": {"encounter_id": "another-director"}}}),
		"unrelated offline director is a no-op, not a veto on another source's exact saved ACK")
	assert_eq(record, before)
	assert_eq(session._registry.peer_for_character("owner_a"), 0, "offline has no network registry row")
	assert_eq(session._saved_actor_delivery_peer("owner_a"), 1, "actual local owner can receive its saved Item/Heal")
	assert_eq(session._saved_actor_delivery_peer(""), 0)
	assert_eq(session._saved_actor_delivery_peer("foreign"), 0)
	session._registry.add(2, "guest_a")
	assert_eq(session._saved_actor_delivery_peer("guest_a"), 2, "guest still resolves through actual registry")
	game.local.character_id = "replacement"
	assert_eq(session._saved_actor_delivery_peer("owner_a"), 0, "an old local owner cannot borrow the replacement's peer")
	assert_eq(session._saved_actor_delivery_peer("replacement"), 1)
	manager.free()
	director.free()
	session.free()
	game.free()


func test_wild_disposal_retains_same_actor_source_until_item_hp_prejournal_and_mastery_settle() -> void:
	# Existing actual runtime and Session context; detached bodies and prepared
	# component originals only. No mounted fight, transport or disk-save claim.
	var fixture := preload("res://tests/test_foundation_resource_save.gd")
	var essence := preload("res://scripts/creatures/essence.gd")
	var saved_essence: Dictionary = essence.config().duplicate(true)
	essence._configuration = saved_essence.duplicate(true)
	essence._configuration.wild_victory_runtime_enabled = true
	for pending_kind: String in ["item", "hp", "prejournal", "mastery"]:
		for restore_ambient: bool in [false, true]:
			var game := fixture.FixtureGame.new()
			game.world = preload("res://tests/test_foundation_resources.gd").new()._world()
			game.local = DATA.new()._player()
			game.local.character_id = "owner_a"
			var owned: RefCounted = game.local.party.at(0)
			owned.hp = owned.max_hp - 10.0
			game.local.inventory.add("potion_small", 2)
			game.save_system = fixture.BoolWriter.new()
			var session := fixture.FixtureSession.new()
			session.fixture = game
			game.session = session
			var transport := fixture.FixtureRpc.new()
			transport.name = "LedgerRpc"
			transport.fixture = game
			transport.ledger = preload("res://scripts/net/world_ledger.gd").new(game.world)
			session.add_child(transport)
			assert_false(session._ordinary_actor_vitals_journal_epoch().is_empty())
			var context: Dictionary = session._host_wild_training_context()
			assert_true(context.ready, "same actual prepared writer/context supports solo ownership")
			var director := preload("res://tests/test_client_trainer_victory.gd").DirectorFixture.new()
			director.host = false
			director._session = session
			director._encounter_host = HOST.new(1)
			director._catch_arbiter = preload("res://scripts/net/catch_arbiter.gd").new()
			var before := preload("res://scripts/net/character_record_rules.gd").portable_projection(game.local.save_data())
			before.redesign_character["tether_pouch"] = ["potion_small"]
			assert_true(preload("res://scripts/net/character_record_rules.gd").errors(before, "owner_a").is_empty(), "actual spawned UID remains admissible")
			var rec: Dictionary = director._encounter_host.open(1, "meadows", "wild",
				{"hp": 200.0, "hp_max": 200.0, "species_id": "bramblebun"}, owned.uid, "owner_a")
			var wild_id: String = rec.encounter_id
			rec["wild_actor_owner"] = preload("res://scripts/net/wild_actor_scope.gd").make(
				game.world.reward_delivery_namespace, session._altar_current_epoch(), "meadows", wild_id)
			director._encounter = rec
			var body := preload("res://tests/test_shared_wild_host_fight.gd").Body.new()
			body.visible = false
			body.set_meta(&"tether_snare", {"until_ms": 2500})
			body.set_meta(&"tether_body_generation", 1)
			assert_true(director._encounter_host.bind_actor_body(wild_id, 1, "owner_a", before.party[0], body.get_instance_id()).ok)
			var runtime := preload("res://scripts/combat/shared_wild_host_fight.gd").new()
			runtime.authority_body = body
			runtime.set_meta(&"canonical_wild_context", context)
			director._shared_host_fights[wild_id] = runtime
			assert_true(director._owns_canonical_wild(wild_id))
			var original: Dictionary = {}
			match pending_kind:
				"item":
					director._encounter_host.bind_tether_commands(wild_id, 1, before)
					rec.participants[1].tether_commands.meter = 100.0
					var binding := {"character_id": "owner_a", "creature_uid": owned.uid,
						"deployment_generation": 1, "actor_generation": 1, "body_instance_id": body.get_instance_id()}
					var prepared: Dictionary = director._encounter_host.prepare_tether_item_command(
						COMMANDS.intent(wild_id, 1, 7, "item_throw"), 1, before, binding, 0,
						game.world.reward_delivery_namespace, session._ordinary_actor_vitals_journal_epoch(), 2000)
					assert_true(prepared.ok, str(prepared))
					original = prepared.get("original", {})
				"hp":
					original = director._encounter_host.stage_actor_vitals(wild_id, 1, owned.uid, 1, 0, "saved-hit", "damage", 3.0, 128)
					assert_true(director._encounter_host.commit_actor_vitals(original).ok)
				"prejournal":
					var proposal: Dictionary = director._encounter_host.stage_actor_vitals(wild_id, 1, owned.uid, 1, 0, "before-save-hit", "damage", 3.0, 128)
					assert_true(proposal.ok)
					original = {"encounter_id": wild_id, "proposal": proposal, "presented": false}
					director._ordinary_actor_vitals_proposals["before-world-save"] = original
				"mastery":
					var binding := {"character_id": "owner_a", "creature_uid": owned.uid,
						"deployment_generation": 1, "actor_generation": 1, "body_instance_id": body.get_instance_id()}
					assert_true(director._encounter_host.authorize_move_start(
						{"encounter_id": wild_id, "action": 1, "slot": "quick"}, 1, _owned(owned.uid), binding, _move(), WIND, 1000).ok)
					var started: Dictionary = director._encounter_host.move_commit(wild_id, 1, 1)
					assert_true(director._encounter_host.validate_strike(
						{"encounter_id": wild_id, "action": 1, "slot": "quick", "move_id": started.move_id, "move": started.move, "facing": Vector3.RIGHT},
						1, {"now_ms": 1300, "origin": Vector3.ZERO, "bodies": [], "move_actor_binding": binding, "f22_actor_binding": binding}).ok)
					director._encounter_host.credit_move_hit(wild_id, 1, 1, 10.0, "opponent_a", 200.0)
					original = director._encounter_host.move_mastery_outcome(wild_id, 1, 1)
					assert_false(original.is_empty())
					assert_true(director._encounter_host.pending_actor_vitals(wild_id).is_empty(), "mastery can outlive settled HP")
			assert_true(director._encounter_host.leave(wild_id, 1).ok)
			assert_eq(director._encounter_host.phase(wild_id), "done")
			director._dispose_shared_host_fight(wild_id, restore_ambient)
			assert_true(is_same(director._shared_host_fight(wild_id), runtime), pending_kind)
			assert_true(director._owns_canonical_wild(wild_id), "retry keeps exact canonical solo source")
			assert_eq(runtime.get_meta(&"dispose_after_actor_settlement", null), restore_ambient)
			assert_false(body.visible, "pending source does not restore ambient presentation")
			assert_true(body.has_meta(&"tether_body_generation"), "pending source preserves body identity")
			director._tick_encounter(0.1)
			assert_true(is_same(director._shared_host_fight(wild_id), runtime), "tick retains pending source")
			match pending_kind:
				"item":
					var pending: Array = director._encounter_host.pending_tether_items(wild_id)
					assert_eq(pending.size(), 1)
					if pending.size() == 1: assert_true(is_same(pending[0], original))
					assert_true(director._encounter_host.cancel_unjournaled_tether_item(original, {}, game.world.reward_delivery_namespace))
				"hp":
					assert_true(director._encounter_host.acknowledge_actor_vitals(wild_id, "owner_a", owned.uid, original.revision, original.settlement_receipt))
				"prejournal": original.presented = true
				"mastery":
					assert_eq(director._encounter_host.pending_move_mastery().size(), 1)
					assert_true(director._encounter_host.acknowledge_move_mastery(wild_id, "owner_a", 1, original.outcome.action_id))
			director._tick_encounter(0.1)
			assert_eq(director._shared_host_fight(wild_id), null, "settled source resumes deferred disposal")
			assert_false(runtime.has_meta(&"dispose_after_actor_settlement"))
			assert_false(director._owns_canonical_wild(wild_id))
			assert_true(director._encounter_host.record(wild_id).is_empty(), "finished Host record is forgotten after settlement")
			assert_eq(body.visible, restore_ambient, "actual disposal applies retained restoration policy")
			assert_eq(body.engagements, [false] if restore_ambient else [])
			assert_false(body.has_meta(&"tether_snare"))
			assert_false(body.has_meta(&"tether_body_generation"))
			runtime.free()
			body.free()
			director.free()
			session.free()
			game.free()
	essence._configuration = saved_essence


func test_pouch_presentation_reads_first_live_stack_and_frozen_gear_without_spending() -> void:
	var player: RefCounted = DATA.new()._player()
	player.character_id = "owner_a"
	player.inventory.add("potion_small", 3)
	player.inventory.add("berries", 4)
	var record := preload("res://scripts/net/character_record_rules.gd")
	var admitted := record.portable_projection(player.save_data())
	admitted.equipment.backpack = "stormglass_command_pouch"
	admitted.redesign_character["tether_pouch"] = ["potion_small", "berries", ""]
	host.bind_tether_commands(id, 1, admitted)
	var original := admitted.duplicate(true)
	assert_eq(host.tether_pouch_view(id, 1, admitted), {"pouch_count": 3, "item_consumer_ready": true})
	assert_eq(admitted, original, "HUD count never edits inventory or pouch")
	assert_eq(_command_pool().meter, 0.0)
	player.inventory.remove("potion_small", 3)
	admitted.inventory = record.portable_projection(player.save_data()).inventory
	assert_eq(host.tether_pouch_view(id, 1, admitted), {"pouch_count": 4, "item_consumer_ready": true}, "next assigned non-empty stack is the same staging selection")
	admitted.character_id = "foreign-owner"
	assert_eq(host.tether_pouch_view(id, 1, admitted), {"pouch_count": 0, "item_consumer_ready": false})
	admitted.character_id = "owner_a"
	admitted.redesign_character.tether_pouch = ["orb_basic"]
	assert_eq(host.tether_pouch_view(id, 1, admitted), {"pouch_count": 0, "item_consumer_ready": false}, "invalid/unsupported saved pouch fails closed")
	player.inventory.add("attack_tonic", 2)
	admitted.inventory = record.portable_projection(player.save_data()).inventory
	admitted.redesign_character.tether_pouch = ["attack_tonic", "berries"]
	assert_eq(host.tether_pouch_view(id, 1, admitted), {"pouch_count": 2, "item_consumer_ready": true}, "first-slot tonic remains the selected stack; never skip to later food")
	admitted = original.duplicate(true)
	admitted.equipment.backpack = ""
	admitted.redesign_character.tether_pouch = ["potion_small"]
	host.bind_tether_commands(id, 1, admitted)
	assert_eq(_command_pool().tier, 4, "live presentation cannot re-admit a different gear tier")
	assert_eq(host.tether_pouch_view(id, 1, admitted), {"pouch_count": 3, "item_consumer_ready": true})
	assert_eq(_command_pool().meter, 0.0)


func test_first_item_dispatch_refuses_an_older_uncommitted_actor_original() -> void:
	# Reuse the existing detached Director/Session fixtures. The dispatcher,
	# pending scan and real Host reservation remain production methods.
	var fixture := preload("res://tests/test_foundation_resource_save.gd")
	var game := fixture.FixtureGame.new()
	game.world = preload("res://tests/test_foundation_resources.gd").new()._world()
	var session := fixture.FixtureSession.new()
	session.fixture = game
	game.session = session
	var director := preload("res://tests/test_client_trainer_victory.gd").DirectorFixture.new()
	director._session = session
	director._encounter_host = host
	host.encounters[id].kind = "trainer"
	host.encounters[id].opponent["owner_npc"] = "trainer_arden"
	director._ordinary_combat_reward_owners[id] = preload("res://scripts/net/combat_round_reward.gd").scope(
		game.world.reward_delivery_namespace, "resource-epoch", "meadows", "trainer_arden", id)
	director._ordinary_actor_vitals_proposals["older-unsaved-hit"] = {"encounter_id": id, "presented": false}
	assert_true(director.ordinary_actor_vitals_pending(id))
	var request := COMMANDS.intent(id, 1, 7, "item_throw")
	var verdict: Dictionary = director._host_commit_encounter({"kind": "tether_command", "encounter_id": id, "request": request}, 1)
	assert_false(verdict.ok)
	assert_eq(verdict.code, "pending_vitals")
	assert_eq(verdict.command_request, request, "owner can release this matching refused command")
	assert_true(host.pending_tether_items(id).is_empty(), "no new item original can reserve the stale HP baseline")
	director.free()
	session.free()
	game.free()


func test_item_owner_checkpoint_matches_only_its_submitted_command_and_current_deployment() -> void:
	var manager := MANAGER.new()
	var director := preload("res://scripts/combat/encounter_director.gd").new()
	manager._encounter_link = director
	manager._encounter_id = "item-original"
	director._deployment_identity[1] = {"character_id": "owner_a", "generation": 2}
	var request := COMMANDS.intent("item-original", 2, 7, "item_throw")
	manager._tether_command_view["pending_request"] = request.duplicate(true)
	var envelope := {"op": "tether_item", "character_id": "owner_a", "world_namespace": "item-world",
		"session_epoch": "transport-epoch", "station_key": "tether_item:original", "revision": 0,
		"intent": {"request": request, "effect": {}}}
	assert_true(manager.owner_tether_item_request_matches(envelope))
	for field: String in ["encounter_id", "generation", "sequence", "command_id"]:
		var forged := envelope.duplicate(true)
		forged.intent.request[field] = 3 if field in ["generation", "sequence"] else "replacement"
		assert_false(manager.owner_tether_item_request_matches(forged), field)
	var forged := envelope.duplicate(true)
	forged.character_id = "other-owner"
	assert_false(manager.owner_tether_item_request_matches(forged))
	var refused := {"ok": false, "pending": false, "encounter_id": "item-original", "command_generation": 2,
		"command_request": COMMANDS.intent("item-original", 2, 6, "item_throw")}
	manager.apply_tether_command_verdict(refused)
	assert_eq(manager._tether_command_view.pending_request, request, "late older refusal cannot clear the current original")
	refused.command_request = request.duplicate(true)
	refused.pending = true
	manager.apply_tether_command_verdict(refused)
	assert_eq(manager._tether_command_view.pending_request, request, "pending save keeps input fenced")
	refused.pending = false
	manager.apply_tether_command_verdict(refused)
	assert_false(manager._tether_command_view.has("pending_request"), "matching asynchronous terminal refusal releases input")
	manager._tether_command_view["pending_request"] = request.duplicate(true)
	director._deployment_identity[1].generation = 3
	assert_false(manager.owner_tether_item_request_matches(envelope), "old original cannot authorize replacement body")
	var session := preload("res://scripts/net/session.gd").new()
	assert_false(session._tether_item_commit_original(director, {}).ok, "detached/non-source Director cannot journal an item")
	assert_false(session._owner_passive_request_matches("tether_item", envelope), "no actual Game/world scope")
	session.free()
	manager.free()
	director.free()


func test_saved_item_carrier_keeps_one_original_debit_and_owned_effect_with_runtime_off() -> void:
	var actions := preload("res://scripts/net/foundation_actions.gd")
	var record := preload("res://scripts/net/character_record_rules.gd")
	var delivery := preload("res://scripts/net/foundation_delivery.gd")
	var authority_type := preload("res://scripts/net/character_authority.gd")
	var rules := preload("res://scripts/world/death_satchel_rules.gd")
	for item: String in ["potion_small", "berries", "attack_tonic"]:
		var player: RefCounted = DATA.new()._player()
		player.set("character_id", "owner_a")
		player.get("inventory").call("add", item, 2)
		var creature: RefCounted = player.get("party").call("at", 0)
		creature.set("hp", float(creature.get("max_hp")) - 10.0)
		creature.set("nourishment", 10.0)
		creature.set("happiness", 20.0)
		var before := record.portable_projection(player.call("save_data"))
		before.redesign_character["tether_pouch"] = [item]
		var request := COMMANDS.intent("item-encounter", 2, 7, "item_throw")
		var effect := {"kind": "item_throw", "character_id": "owner_a", "creature_uid": before.party[0].uid,
			"generation": 2, "item_id": item, "count": 1, "action_id": "command:item-encounter:owner_a:2:7"}
		var actor := {"character_id": "owner_a", "encounter_id": request.encounter_id, "creature_uid": before.party[0].uid,
			"generation": 2, "body_generation": 1, "body_instance_id": 123, "vitals_revision": 0,
			"hp": before.party[0].hp, "max_hp": before.party[0].max_hp}
		var context := {"character_id": "owner_a", "expected_revision": 0, "source_key": "tether_item:" + str(effect.action_id),
			"in_range": true, "in_combat": true, "foundation_runtime_authorized": true, "item_runtime_authorized": true,
			"world_namespace": "item-world", "session_id": "item-epoch", "item_actor": actor}
		var intent := {"request": request, "effect": effect}
		var authority := authority_type.new()
		assert_true(authority.bind_world("item-world"))
		assert_true(authority.seed_admitted_character(before, "owner_a").ok)
		var token: Dictionary = authority.stage_character_action("owner_a", 0, "tether_item", intent, context)
		assert_true(token.ok, str(token))
		if not token.ok: continue
		assert_eq(rules.inventory_from(token.state.inventory).count(item), 1)
		assert_eq(token.state.party[1], before.party[1])
		assert_eq(token.intent, intent)
		assert_true(authority.finish_creature_training(token, false))
		assert_eq(authority.state("owner_a"), before, "false first writer restores BOTH inventory and selected HP/condition")
		assert_eq(authority.revision("owner_a"), 0)
		token = authority.stage_character_action("owner_a", 0, "tether_item", intent, context)
		var row: Dictionary = delivery.make_record("item-slot", "item-world", "item-epoch", token, null, record.errors)
		assert_false(row.is_empty())
		if row.is_empty(): continue
		row = preload("res://scripts/save/save_document.gd").parse(preload("res://scripts/save/save_document.gd").stringify(row))
		COMMANDS._config.feature_flags.runtime_enabled = false
		assert_true(delivery.valid(row, record.errors, "owner_a", "item-world", "item-slot"), "saved entitlement survives runtime OFF")
		assert_false(COMMANDS.stage_item_use(before, effect, {"actor": actor, "owner_admitted": true, "encounter_active": true}).ok, "ordinary live helper still refuses OFF")
		var recovered := authority_type.new()
		assert_true(recovered.bind_world("item-world"))
		assert_true(recovered.seed_admitted_character(before, "owner_a").ok)
		assert_true(recovered.recover_durable_training("owner_a", {row.delivery_id: row}).ok)
		assert_false(recovered.acknowledge_creature_training("owner_a", row), "pending world row cannot assert owner save")
		var owner: Dictionary = delivery.owner_plan(before, row, record.errors)
		assert_true(owner.ok and owner.requires_owner_save)
		assert_eq(owner.state, row.after)
		assert_true(delivery.owner_plan(owner.state, row, record.errors).duplicate, "retry never consumes a second stack")
		assert_false(actions.stage(owner.state, 1, "tether_item", intent, context, record.errors).ok)
		row.status = "accepted"
		assert_true(recovered.acknowledge_creature_training("owner_a", row))
		assert_eq(recovered.state("owner_a"), row.after)
		for field: String in ["world_namespace", "session_id", "source_key", "item_runtime_authorized", "in_combat"]:
			var forged := row.duplicate(true)
			forged.host_context[field] = false if field in ["item_runtime_authorized", "in_combat"] else "foreign"
			assert_false(delivery.valid(forged, record.errors), field)
		if item == "potion_small": assert_eq(row.after.party[0].hp, before.party[0].max_hp)
		if item == "berries": assert_eq(row.after.party[0].nourishment, 45.0)
		if item == "attack_tonic": assert_eq(row.after.party, before.party, "timed tonic is not persisted in a card")
		assert_eq(creature.get("hp"), before.party[0].hp, "detached carrier never writes the live creature")
		assert_eq(player.get("inventory").call("count", item), 2)
		COMMANDS._config.feature_flags.runtime_enabled = true

func test_tonic_wind_boundaries_update_active_and_retained_character_uid_without_resetting_resources() -> void:
	var move := _move()
	move.wind_cost = 100.0
	assert_true(host.authorize_move_start({"encounter_id": id, "action": 1, "slot": "quick"},
		1, _owned(), _binding(), move, WIND, 1000).ok)
	assert_true(host.join(id, 3, "creature_a", "owner_b").ok)
	var foreign_binding := _binding()
	foreign_binding.character_id = "owner_b"
	assert_true(host.authorize_move_start({"encounter_id": id, "action": 1, "slot": "quick"},
		3, _owned(), foreign_binding, move, WIND, 1000).ok)
	var pool: Dictionary = host.encounters[id].participants[1].move_resources.creature_a
	var foreign: Dictionary = host.encounters[id].participants[3].move_resources.creature_a.duplicate(true)
	var cooldowns: Dictionary = pool.cooldowns.duplicate(true)
	var ready := int(pool.wind_ready_at_ms)
	var activation := ready + 500
	host.settle_tether_tonic_wind("owner_a", "creature_a", activation)
	host.settle_tether_tonic_wind("owner_a", "creature_a", activation, {"max": 200.0, "regen_per_second": 36.0})
	assert_almost_eq(float(pool.wind), 9.0, 0.001, "the interval before activation uses the old rate")
	assert_eq(pool.wind_max, 200.0)
	assert_eq(host.encounters[id].participants[3].move_resources.creature_a, foreign, "the same UID under another character is untouched")
	host.note_opponent_position(id, Vector3.ZERO, activation + 1000)
	assert_almost_eq(float(pool.wind), 45.0, 0.001, "new rate is installed without another action")
	assert_true(host.leave(id, 1).ok)
	host.settle_tether_tonic_wind("owner_a", "creature_a", activation + 1500)
	host.settle_tether_tonic_wind("owner_a", "creature_a", activation + 1500, WIND)
	assert_almost_eq(float(pool.wind), 63.0, 0.001, "the final boosted interval survives expiry after departure")
	assert_eq(pool.wind_max, 100.0)
	host.settle_tether_tonic_wind("owner_a", "creature_a", activation + 2500)
	assert_almost_eq(float(pool.wind), 81.0, 0.001, "retained pool immediately returns to its base rate")
	assert_eq(pool.cooldowns, cooldowns)
	assert_eq(pool.wind_ready_at_ms, ready)
	assert_eq(pool.wind_last_action, 1)
	assert_eq(pool.energy, 0.0)
	assert_eq(pool.ultimate_meter, 0.0)

func test_tonic_scope_cleanup_preserves_current_context_and_unmanaged_same_instance_buffs() -> void:
	var fixture := preload("res://tests/test_foundation_resource_save.gd")
	var game := fixture.FixtureGame.new()
	game.local = DATA.new()._player()
	game.world = preload("res://tests/test_foundation_resources.gd").new()._world()
	var session := fixture.FixtureSession.new()
	session.fixture = game
	game.session = session
	var member: RefCounted = game.local.party.at(0)
	var buff: Dictionary = preload("res://scripts/world/death_satchel_rules.gd").db().definition("attack_tonic").creature_buff
	assert_true(member.call("apply_buff", "native-speed", "speed", 1.1, 90.0))
	var effect := {"id": buff.id, "stat": buff.stat, "scale": buff.scale, "remaining_s": 90.0, "receipt": "same-receipt"}
	assert_true(session._apply_host_tether_tonics({str(member.uid): {"version": 1, "effects": [effect]}}))
	var original: Array = member.get("active_buffs").duplicate(true)
	session._sync_tether_tonic_scope()
	assert_eq(member.get("active_buffs"), original, "transport retirement does not expire a matching context")
	game.world.reward_delivery_namespace = "replacement-world"
	session._sync_tether_tonic_scope()
	assert_eq(member.get("active_buffs").size(), 1)
	assert_eq(member.get("active_buffs")[0].id, "native-speed", "changed-world cleanup removes only receipt-managed IDs")
	assert_true(is_same(game.local.party.at(0), member), "cleanup retains the actual owned instance")
	assert_true(session._apply_host_tether_tonics({str(member.uid): {"version": 1, "effects": [effect]}}))
	var seen: Dictionary = member.get_meta("tether_tonic_projection")
	seen.context[2] = "departed-epoch"
	session._sync_tether_tonic_scope()
	assert_eq(member.get("active_buffs").size(), 1, "changed-epoch cleanup works without a later projection packet")
	assert_eq(member.get("active_buffs")[0].id, "native-speed")
	session.free()
	game.free()

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
