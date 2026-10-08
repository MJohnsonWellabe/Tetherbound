extends "res://tests/smoke_combat.gd"

## F27#1/#2 actual-path witness: a real wild fight in the shipping Meadows
## scene, piloted with real input, pays its typed essence and the reduced
## combat XP through the canonical host wild-victory transaction.
##
##   godot --headless --path . --script tests/smoke_f27_wild_defeat_essence.gd
##   godot --headless --path . --script tests/smoke_f27_wild_defeat_essence.gd -- --actor-vitals-override
##
## The canonical wild-victory transaction runs only while combat.json
## `actor_vitals.runtime_enabled` is true. With the shipped value false this
## smoke FAILS by design (wild defeats pay no essence). The disclosed override
## flips only that in-memory flag, before the scene loads, to prove the path.
##
## Reuses smoke_combat's walk/engage/fight helpers unchanged; only the
## assertions differ. No essence, XP or receipt is injected here: the only
## writer is EncounterDirector -> Session._host_wild_training_context ->
## essence.stage_captured_host_victory -> the prepared owner save.
const ESSENCE := preload("res://scripts/creatures/essence.gd")
const SETTLE_AFTER_VICTORY := 240

func _run() -> void:
	var vitals: Dictionary = MATH.config().get("actor_vitals", {})
	if OS.get_cmdline_user_args().has("--actor-vitals-override"):
		print("DISCLOSED FIXTURE: combat.json actor_vitals.runtime_enabled forced true in memory (shipped: %s)" % str(vitals.get("runtime_enabled")))
		vitals["runtime_enabled"] = true
	elif vitals.get("runtime_enabled") != true:
		_fail("OFF: combat.json actor_vitals.runtime_enabled is false, so the canonical wild-victory transaction (essence + hybrid XP) never runs")
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	current_scene = _world # As the shipping game boot does; Foundation reads it.
	for i in SETTLE_FRAMES:
		await physics_frame
	await _ensure_ally()
	# The opening's own ownership step (sequence_director._own_the_late_arrival):
	# the adopted body is only a companion once it is in this character's party.
	var owner_party: RefCounted = root.get_node(^"Game").get("party")
	if owner_party.size() == 0: owner_party.call("add", _world.get_node(^"EncounterDirector").call("ally_instance"))
	_leave_the_farmhouse()
	if not _collect_nodes():
		_report()
		return
	var game := root.get_node_or_null(^"Game")
	var session: Node = game.get("session") if game != null else null
	var context: Variant = session.call("_host_wild_training_context") if session != null else {}
	if not context is Dictionary or context.get("ready") != true:
		_fail("solo host wild-training context is not ready: %s" % str(context))
	var local: RefCounted = game.get("local")
	var essence_before := _essence_counts(local)
	var receipts_before: int = local.redesign_character.transaction_receipts.size()
	var ally_before: RefCounted = _director.call("ally_instance")
	var level_before := int(ally_before.level)
	var xp_before := int(ally_before.xp)
	var battles_before := int(ally_before.battles_fought)
	print("before: essence %s, receipts %d, ally L%d xp %d" % [essence_before, receipts_before, level_before, xp_before])

	await _walk_to_the_wild_creature()
	await _engage()
	if not bool(_manager.call("is_fighting")):
		_fail("could not enter combat")
		_report()
		return
	_ally = _director.call("ally_body") as Node3D
	var foe: RefCounted = _manager.call("enemy")
	var foe_level := int(foe.level)
	var foe_species := str(foe.species_id)
	var foe_types: Array[String] = []
	for type_id: Variant in [foe.get("creature_type"), foe.get("secondary_type")]:
		if type_id is String and not type_id.is_empty(): foe_types.append(type_id)
	await _fight_to_a_finish()
	for i in SETTLE_AFTER_VICTORY:
		await physics_frame
	_print_victory_runtime()

	var essence_after := _essence_counts(local)
	var gained := {}
	for item: String in essence_after:
		var delta: int = int(essence_after[item]) - int(essence_before.get(item, 0))
		if delta != 0: gained[item] = delta
	print("after: foe %s L%d types %s, essence gained %s" % [foe_species, foe_level, foe_types, gained])
	var expected := 1 + int(floorf(float(foe_level) / float(ESSENCE.config().defeat_bonus_level_interval)))
	var total := 0
	for item: String in gained:
		total += int(gained[item])
		var type_id := item.trim_prefix("essence_")
		if not foe_types.has(type_id): _fail("essence %s does not match the defeated wild's types %s" % [item, foe_types])
	if total != expected:
		_fail("wild defeat paid %d essence, expected %d (base 1 + level bonus)" % [total, expected])
	var new_receipts: Array = local.redesign_character.transaction_receipts.slice(receipts_before)
	var defeat_receipts := new_receipts.filter(func(r: String) -> bool: return r.begins_with("defeat:"))
	if defeat_receipts.size() != 1:
		_fail("expected exactly one durable defeat receipt, saw %s" % str(new_receipts))
	else:
		# Read the actual canonical files after the original settlement allowance.
		# Do not save/load/retry or manufacture a second source to prove persistence.
		var character_disk: Dictionary = preload("res://scripts/save/character_save.gd").new().read(str(local.character_id))
		var live_world: RefCounted = game.get("world")
		var world_disk: Dictionary = preload("res://scripts/save/world_save.gd").new().read(str(live_world.get("world_id")))
		var receipt: String = defeat_receipts[0]
		if character_disk.is_empty() or (character_disk.get("redesign_character", {}).get("transaction_receipts", []) as Array).count(receipt) != 1:
			_fail("the original defeat receipt is not present exactly once in the canonical character file")
		var journal: Dictionary = world_disk.get("reward_deliveries", {}).get(ESSENCE.training_delivery_id(str(live_world.get("reward_delivery_namespace")), str(local.character_id)), {})
		if journal.get("status") != "accepted" or journal.get("character_id") != str(local.character_id) \
				or (journal.get("after", {}).get("redesign_character", {}).get("transaction_receipts", []) as Array).count(receipt) != 1:
			_fail("the canonical host journal is not accepted for the original character with exactly one defeat receipt")
		for item: String in essence_after:
			var saved_count := 0
			for slot: Variant in character_disk.get("inventory", []):
				if slot is Dictionary and slot.get("id") == item: saved_count += int(slot.get("n", 0))
			if saved_count != int(essence_after[item]):
				_fail("canonical character %s count %d differs from original settled live count %d" % [item, saved_count, int(essence_after[item])])
	var ally_after: RefCounted = _director.call("ally_instance")
	var xp_gain := (int(ally_after.level) - level_before) * 1000000 + int(ally_after.xp) - xp_before
	if xp_gain <= 0:
		_fail("the reduced automatic combat XP was zero (L%d xp %d -> L%d xp %d)" % [level_before, xp_before, int(ally_after.level), int(ally_after.xp)])
	print("ally L%d xp %d -> L%d xp %d" % [level_before, xp_before, int(ally_after.level), int(ally_after.xp)])
	# One win is one battle fought, credited once (by the host transaction when
	# it owns the award, never also by the legacy local award loop).
	if int(ally_after.battles_fought) != battles_before + 1:
		_fail("one win credited %d battles fought, expected 1" % (int(ally_after.battles_fought) - battles_before))
	# The sole fighter is the active member: exactly the reduced hybrid award,
	# never the legacy full award on top of it.
	var hybrid := PROGRESSION.scaled_combat_xp(foe_level, PROGRESSION.config(), ESSENCE.config())
	if int(ally_after.level) == level_before and int(ally_after.xp) - xp_before != hybrid:
		_fail("ally gained %d XP, expected exactly the hybrid %d (legacy %d)" % [int(ally_after.xp) - xp_before,
			hybrid, PROGRESSION.raw_xp_award_for(foe_level, PROGRESSION.config())])
	if _failures.is_empty():
		print("F27_WILD_DEFEAT_ESSENCE: PASS real wild fight paid %s and reduced XP via the host transaction" % str(gained))
	_report()


func _essence_counts(local: RefCounted) -> Dictionary:
	var out := {}
	for type_id: String in ["ground", "water", "air", "electric", "fire", "dark", "ice", "psychic"]:
		out["essence_" + type_id] = int(local.inventory.count("essence_" + type_id))
	return out


## Diagnostic only: the director's retained capture/settlement verdicts.
func _print_victory_runtime() -> void:
	var fights: Variant = _director.get("_shared_host_fights")
	if not fights is Dictionary or fights.is_empty():
		print("victory runtime: none retained")
		return
	for id: String in fights:
		var runtime: Object = _director.call("_shared_host_fight", id)
		if runtime == null: continue
		var metas := {}
		for key: StringName in [&"wild_victory_capture_refusal", &"wild_victory_result", &"wild_victory_resolved", &"wild_victory_training_resolved"]:
			if runtime.has_meta(key): metas[key] = runtime.get_meta(key)
		metas["has_source"] = runtime.has_meta(&"wild_victory_source")
		metas["phase"] = _director.get("_encounter_host").call("phase", id) if _director.get("_encounter_host") != null else ""
		print("victory runtime %s: %s" % [id, str(metas).left(600)])
