extends "res://tests/smoke_combat.gd"

## F27#1/#2 actual-path witness: a real wild fight in the shipping Meadows
## scene, piloted with real input, pays its typed essence and the reduced
## combat XP through the canonical host wild-victory transaction.
##
##   godot --headless --path . --script tests/smoke_f27_wild_defeat_essence.gd
##   godot --headless --path . --script tests/smoke_f27_wild_defeat_essence.gd -- --actor-vitals-override
##   ... -- --actor-vitals-override --research-source
##   ... -- --actor-vitals-override --research-source --research-journal
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
const JOURNAL_PRESS := preload("res://tools/net/press_inject.gd")
const JOURNAL_BINDINGS := preload("res://tools/gate_f/operator_harness.gd")
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
	var original_character_id := str(local.character_id)
	# Canonical installs and receipt compaction do not promise a stable prefix.
	# Freeze membership before input; an old defeat can never count as this win.
	var receipts_before: Array = local.redesign_character.transaction_receipts.duplicate(true)
	var ally_before: RefCounted = _director.call("ally_instance")
	var level_before := int(ally_before.level)
	var xp_before := int(ally_before.xp)
	var battles_before := int(ally_before.battles_fought)
	print("before: essence %s, receipts %d, ally L%d xp %d" % [essence_before, receipts_before.size(), level_before, xp_before])
	print("F27_ORIGINAL_RECEIPTS ", JSON.stringify({"character_id": original_character_id, "receipts": receipts_before}))

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
	if game.get("local") != local or str(local.character_id) != original_character_id:
		_fail("original fight character changed before defeat settlement observation")
		_report()
		return
	var new_receipts: Array = local.redesign_character.transaction_receipts.filter(func(r: String) -> bool: return not receipts_before.has(r))
	var defeat_receipts := new_receipts.filter(func(r: String) -> bool: return r.begins_with("defeat:" + original_character_id + ":"))
	if defeat_receipts.size() != 1 or local.redesign_character.transaction_receipts.count(defeat_receipts[0]) != 1:
		_fail("expected exactly one durable defeat receipt, saw %s" % str(new_receipts))
	else:
		# Read the actual canonical files after the original settlement allowance.
		# Do not save/load/retry or manufacture a second source to prove persistence.
		var character_disk: Dictionary = preload("res://scripts/save/character_save.gd").new().read(str(local.character_id))
		var live_world: RefCounted = game.get("world")
		var world_reader := preload("res://scripts/save/world_save.gd").new("user://worlds/redesign-v28/")
		var world_disk: Dictionary = world_reader.read(str(live_world.get("world_id")))
		var receipt: String = defeat_receipts[0]
		if character_disk.is_empty() or (character_disk.get("redesign_character", {}).get("transaction_receipts", []) as Array).count(receipt) != 1:
			_fail("the original defeat receipt is not present exactly once in the canonical character file")
		var journal: Dictionary = world_disk.get("reward_deliveries", {}).get(ESSENCE.training_delivery_id(str(live_world.get("reward_delivery_namespace")), str(local.character_id)), {})
		if journal.get("status") != "accepted" or journal.get("character_id") != str(local.character_id) \
				or (journal.get("after", {}).get("redesign_character", {}).get("transaction_receipts", []) as Array).count(receipt) != 1:
			_fail("the canonical host journal is not accepted for the original character with exactly one defeat receipt: read=%s status=%s character=%s receipt_count=%d delivery=%s" % [
				str(world_reader.last_load_result), str(journal.get("status", "")), str(journal.get("character_id", "")),
				(journal.get("after", {}).get("redesign_character", {}).get("transaction_receipts", []) as Array).count(receipt),
				ESSENCE.training_delivery_id(str(live_world.get("reward_delivery_namespace")), str(local.character_id))])
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
		if OS.get_cmdline_user_args().has("--research-source"):
			await _research_source(game, local, session, foe_species)
	_report()


## Optional source segment: the original fight earns sight progress. The
## Default claim uses the public production Session service. The explicit
## journal opt-in reaches that same door through actual focused Controls and
## physical input, sharing the original allowance including its UI setup.
## Neither path injects a task, event, payout, receipt or saved boundary.
func _research_source(game: Node, local: RefCounted, session: Node, species: String) -> void:
	var research := preload("res://scripts/creatures/research_log.gd")
	var definition: Dictionary = research.config().get("species", {}).get(species, {})
	var view: Dictionary = research.view(local.redesign_character, str(local.character_id), str(definition.get("biome", "")))
	var task: Dictionary = {}
	for row: Dictionary in view.get("species", []):
		if row.get("species_id") != species: continue
		if row.get("seen") != true: break
		for candidate: Dictionary in row.get("tasks", []):
			if candidate.get("id") == "sight": task = candidate
	if view.get("ready") != true or task.get("claimable") != true \
		or int(task.get("progress", 0)) < int(task.get("required", 1)):
		_fail("original wild encounter did not earn a claimable sight task for " + species)
		return
	var expected := {}
	for stack: Dictionary in task.get("rewards", []): expected[str(stack.id)] = int(stack.n)
	if expected.is_empty():
		_fail("original sight task has no configured typed essence payout")
		return
	var before := _essence_counts(local)
	var intent := {"species_id": species, "task_id": "sight"}
	var receipt := "research:%s:sight:%s" % [species, str(local.character_id)]
	print("DISCLOSED research source: public Session claim of naturally earned %s sight task" % species)
	var journal: Node = null
	var journal_deadline := 0
	var original_world: RefCounted = null
	var original_epoch := ""
	var journal_context := {}
	var result: Dictionary
	if OS.get_cmdline_user_args().has("--research-journal"):
		journal_deadline = Engine.get_physics_frames() + SETTLE_AFTER_VICTORY
		original_world = game.get("world")
		original_epoch = session.call("_altar_current_epoch")
		var menu: Node = game.call("menu")
		var pressed: Dictionary = await JOURNAL_PRESS.tap(self, JOURNAL_BINDINGS._physical_binding, "game_menu", 1)
		if pressed.get("ok") != true or menu == null or menu.call("is_open") != true:
			_fail("ordinary Menu input did not open the research claim route")
			return
		var quest_index := -1
		var tabs: Array = menu.get("_tabs")
		for index in tabs.size():
			if tabs[index].get("id") == "quest_log": quest_index = index
		if quest_index < 0:
			_fail("actual Quest Log tab is unavailable")
			return
		var rail: Button = (menu.get("_tab_buttons") as Array)[quest_index]
		rail.grab_focus()
		await process_frame
		if root.gui_get_focus_owner() != rail:
			_fail("actual Quest Log tab did not receive focus")
			return
		pressed = await JOURNAL_PRESS.tap(self, JOURNAL_BINDINGS._physical_binding, "ui_accept", 1)
		var quest: Node = (menu.get("_bodies") as Array)[quest_index]
		var research_button: Button = quest.get("_research_button")
		if pressed.get("ok") != true or not quest.visible or research_button == null:
			_fail("ordinary A did not select the actual Quest Log research row")
			return
		research_button.grab_focus()
		await process_frame
		if root.gui_get_focus_owner() != research_button:
			_fail("actual Research log button did not receive focus")
			return
		pressed = await JOURNAL_PRESS.tap(self, JOURNAL_BINDINGS._physical_binding, "ui_accept", 1)
		journal = quest.get("_research_panel")
		if pressed.get("ok") != true or journal == null or journal.call("is_open") != true:
			_fail("ordinary A did not open the actual Research journal")
			return
		for frame in 2: await process_frame
		var species_button: Button = null
		for button: Button in journal.get("_buttons"):
			if button.get_meta("system_focus_key", "") == "species:" + species: species_button = button
		if species_button == null:
			_fail("earned species is absent from the actual journal")
			return
		species_button.grab_focus()
		for frame in 2: await process_frame
		var claim_button: Button = null
		for button: Button in journal.get("_buttons"):
			if button.get_meta("system_focus_key", "") == "claim:" + species + ":sight": claim_button = button
		if claim_button == null or claim_button.disabled:
			_fail("naturally earned sight task lacks an enabled actual Claim button")
			return
		claim_button.grab_focus()
		await process_frame
		journal_context = (journal.get("_opened_context") as Dictionary).duplicate(true)
		if root.gui_get_focus_owner() != claim_button or game.get("local") != local or game.get("session") != session \
			or game.get("world") != original_world or session.call("_altar_current_epoch") != original_epoch \
			or journal_context != preload("res://scripts/ui/system_screen.gd").character_context(game) \
			or Engine.get_physics_frames() >= journal_deadline:
			_fail("original journal focus/scope/240-frame claim allowance changed before A")
			return
		# Observe and forward the untouched actual producer Callable once. No
		# fabricated service response, second request or private Claim call.
		var actual_call := {"result": {}, "count": 0, "intent": {}}
		var producer: Callable = journal.get("claim_task")
		journal.set("claim_task", func(target_species: String, target_task: String) -> Variant:
			actual_call.count += 1
			actual_call.intent = {"species_id": target_species, "task_id": target_task}
			var response: Variant = producer.call(target_species, target_task)
			actual_call.result = response.duplicate(true) if response is Dictionary else response
			return response)
		pressed = await JOURNAL_PRESS.tap(self, JOURNAL_BINDINGS._physical_binding, "ui_accept", 1)
		if not is_instance_valid(journal):
			_fail("original journal was replaced during Claim A")
			return
		journal.set("claim_task", producer)
		if Engine.get_physics_frames() > journal_deadline or game.get("local") != local \
			or game.get("session") != session or game.get("world") != original_world \
			or session.call("_altar_current_epoch") != original_epoch \
			or journal.get("_opened_context") != journal_context \
			or journal_context != preload("res://scripts/ui/system_screen.gd").character_context(game):
			_fail("original journal scope/240-frame claim allowance changed during A")
			return
		if pressed.get("ok") != true or actual_call.count != 1 or actual_call.intent != intent \
			or not actual_call.result is Dictionary:
			_fail("ordinary Claim A did not invoke exactly the original earned task producer")
			return
		result = actual_call.result
		print("F45_JOURNAL_CLAIM_INPUT ", JSON.stringify({"deadline_frame": journal_deadline,
			"after_press_frame": Engine.get_physics_frames(), "intent": actual_call.intent, "result": result,
			"pending": journal.get("_pending_claim"), "context": journal.get("_opened_context")}))
	else:
		result = session.call("request_research_claim", intent)
	if result.get("ok") != true:
		# Host-local claims may return their retained unsaved decision before
		# the real owner BOOL/ACK completes. Only that exact original receipt
		# can enter the existing allowance; the accepted disk oracle below
		# still decides success, including the original replay checks.
		if result.get("resolved") != false or result.get("durable") != true \
			or result.get("saved") != false or result.get("receipt") != receipt \
			or result.get("code") != "awaiting_saved_decision":
			_fail("original research claim refused: " + str(result.get("code", "")))
			return
		print("DISCLOSED research source: original retained claim awaits owner save within the unchanged 240-frame allowance")
	var remaining := SETTLE_AFTER_VICTORY if journal == null else maxi(0, journal_deadline - Engine.get_physics_frames())
	for i in remaining: await physics_frame
	if journal != null and (not is_instance_valid(journal) or Engine.get_physics_frames() > journal_deadline \
		or game.get("local") != local or game.get("session") != session or game.get("world") != original_world \
		or session.call("_altar_current_epoch") != original_epoch or journal.get("_opened_context") != journal_context \
		or journal_context != preload("res://scripts/ui/system_screen.gd").character_context(game)):
		_fail("original journal completion observation exceeded its scope/240-frame allowance")
		return
	if journal != null and not (journal.get("_pending_claim") as Dictionary).is_empty():
		_fail("actual journal did not consume the original saved completion within its shared 240-frame allowance")
		return
	var after := _essence_counts(local)
	var character_disk: Dictionary = preload("res://scripts/save/character_save.gd").new().read(str(local.character_id))
	if character_disk.get("character_id") != str(local.character_id):
		_fail("research claim canonical disk lost the original character identity")
		return
	var live_world: RefCounted = game.get("world")
	var reader := preload("res://scripts/save/world_save.gd").new("user://worlds/redesign-v28/")
	var world_disk: Dictionary = reader.read(str(live_world.get("world_id")))
	var row: Dictionary = world_disk.get("reward_deliveries", {}).get(ESSENCE.training_delivery_id(str(live_world.get("reward_delivery_namespace")), str(local.character_id)), {})
	if not preload("res://autoload/world_state.gd").training_row_valid(row, str(live_world.get("reward_delivery_namespace")), str(live_world.get("world_id"))) \
		or row.get("status") != "accepted" or row.get("action") != "research_claim" \
		or row.get("character_id") != str(local.character_id) or row.get("intent") != intent \
		or row.get("source_key") != "research_journal" or row.get("receipt") != receipt:
		_fail("original research claim lacks a matching valid accepted host journal")
		return
	for carrier: Dictionary in [local.redesign_character, character_disk.get("redesign_character", {}), row.get("after", {}).get("redesign_character", {})]:
		for field: String in ["research_receipts", "transaction_receipts"]:
			if (carrier.get(field, []) as Array).count(receipt) != 1:
				_fail("original research receipt is not exactly once in " + field)
	for item: String in after:
		if int(after[item]) - int(before[item]) != int(expected.get(item, 0)):
			_fail("research typed essence delta differs for " + item)
		var saved := 0
		for slot: Variant in character_disk.get("inventory", []):
			if slot is Dictionary and slot.get("id") == item: saved += int(slot.n)
		if saved != int(after[item]): _fail("research essence disk differs for " + item)
	if journal != null:
		# Ordinary Back returns to Quest Log, then Back returns to the world.
		var closed: Dictionary = await JOURNAL_PRESS.tap(self, JOURNAL_BINDINGS._physical_binding, "menu_cancel", 1)
		for frame in 2: await process_frame
		var menu: Node = game.call("menu")
		if closed.get("ok") != true or journal.call("is_open") == true or menu.call("is_open") != true:
			_fail("ordinary journal Back did not return to Quest Log")
			return
		closed = await JOURNAL_PRESS.tap(self, JOURNAL_BINDINGS._physical_binding, "menu_cancel", 1)
		for frame in 2: await process_frame
		if closed.get("ok") != true or menu.call("is_open") == true:
			_fail("ordinary Quest Log Back did not release its menu")
			return
	# A second ordinary public request must retain the original accepted row.
	session.call("request_research_claim", intent)
	for i in SETTLE_AFTER_VICTORY: await physics_frame
	var replay_disk: Dictionary = preload("res://scripts/save/character_save.gd").new().read(str(local.character_id))
	if replay_disk.get("character_id") != str(local.character_id):
		_fail("replayed research claim disk lost the original character identity")
	var replay_world: Dictionary = reader.read(str(live_world.get("world_id")))
	var replay_row: Dictionary = replay_world.get("reward_deliveries", {}).get(str(row.delivery_id), {})
	if _essence_counts(local) != after or replay_row != row:
		_fail("replayed research claim changed essence or its original accepted journal")
	for carrier: Dictionary in [local.redesign_character, replay_disk.get("redesign_character", {})]:
		for field: String in ["research_receipts", "transaction_receipts"]:
			if (carrier.get(field, []) as Array).count(receipt) != 1:
				_fail("replayed research receipt duplicated in " + field)
	for item: String in after:
		var saved := 0
		for slot: Variant in replay_disk.get("inventory", []):
			if slot is Dictionary and slot.get("id") == item: saved += int(slot.n)
		if saved != int(after[item]): _fail("replayed research essence disk changed for " + item)
	if _failures.is_empty(): print("F27_RESEARCH_ESSENCE: PASS original %s payout %s saved and accepted once; replay unchanged" % [receipt, str(expected)])


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
