extends "res://tests/test_case.gd"

## `stormwood_glass_for_bryn` logic: chain order, Bryn's greetings, the host
## delivery transaction and its journal, co-op replication of the one delta,
## save/load of the world facts, and the rod/Surge non-duplication guard. The
## live shelter, prompts and bed run in `smoke_stormwood_glass_for_bryn.gd`.
const PROGRESSION := preload("res://autoload/progression_state.gd")
const LOGIC := preload("res://scripts/world/realm_chapter_progression.gd")
const CHAPTER_RUNTIME := preload("res://scripts/world/stormwood_chapter.gd")
const GLASS := preload("res://scripts/world/stormwood_glass_for_bryn.gd")
const PEOPLE := preload("res://scripts/world/village_npcs.gd")
const WORLD := preload("res://autoload/world_state.gd")
const LEDGER := preload("res://scripts/net/world_ledger.gd")
const WORLD_SAVE := preload("res://scripts/save/world_save.gd")
const INVENTORY := preload("res://autoload/inventory.gd")
const ITEM_DB := preload("res://autoload/item_db.gd")
const CAMPS := preload("res://scripts/world/stormwood_camps.gd")
const CHAIN := "stormwood_glass_for_bryn"
const AT_BRYN := Vector3(-700.0, 44.18, 2301.5)


class Saver extends RefCounted:
	var fail_write := false
	var writes := 0
	var store := WORLD_SAVE.new("user://stormwood_glass_for_bryn_%d/" % Time.get_ticks_usec())
	func save_world(game: Object, id: String) -> bool:
		writes += 1
		var snapshot: Dictionary = game.world.save_data()
		snapshot.progression = game.world.flags.save_data()
		return false if fail_write else store.write(id, WORLD_SAVE.partition(snapshot))


class HostFixture extends RefCounted:
	var host := true
	var world: RefCounted = WORLD.new()
	var save_system: RefCounted = Saver.new()
	func is_host() -> bool:
		return host


func _chapter() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/config/stormwood_chapter.json")) as Dictionary


func _bryn_spec() -> Dictionary:
	var parsed: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/config/stormwood_npcs.json"))
	for actor: Dictionary in parsed.characters:
		if str(actor.id) == GLASS.BRYN:
			return CHAPTER_RUNTIME.npc_spec(actor)
	return {}


func _entry(flags: RefCounted, chapter: Dictionary) -> Dictionary:
	for row: Dictionary in LOGIC.side_entries(flags, chapter):
		if str(row.id) == CHAIN:
			return row
	return {}


func _asked_host() -> RefCounted:
	var host := HostFixture.new()
	host.world.world_id = "stormwood-glass-for-bryn-world"
	for flag: String in ["stormwood:rodline_linked", GLASS.REVEALED, GLASS.STEP_1]:
		host.world.flags.set_flag(flag)
	return host


func _carrying(glass: Variant, vine: Variant) -> Dictionary:
	return {"kind": GLASS.DELIVERY_KIND, "stormglass": glass, "conductor_vine": vine}


func test_steps_run_in_order_and_survive_save_load() -> void:
	var chapter := _chapter()
	var flags := PROGRESSION.new()
	assert_true(_entry(flags, chapter).is_empty(), "Hidden until Bryn has been met")
	assert_false(LOGIC.dispatch(flags, chapter, "side:%s:step_1" % CHAIN).changed,
		"Bryn cannot brief the chain before his own story conversation")
	flags.set_flag("stormwood:rodline_linked")
	flags.set_flag(GLASS.REVEALED)
	assert_false(_entry(flags, chapter).is_empty(), "Meeting Bryn reveals the chain")
	assert_false(LOGIC.dispatch(flags, chapter, "side:%s:step_2" % CHAIN).changed,
		"The delivery cannot land before Bryn asks for it")
	assert_false(LOGIC.dispatch(flags, chapter, "side:%s:step_3" % CHAIN).changed,
		"The supplies cannot be inspected before they exist")
	assert_true(LOGIC.dispatch(flags, chapter, "side:%s:step_1" % CHAIN).changed)
	assert_false(LOGIC.dispatch(flags, chapter, "side:%s:step_3" % CHAIN).changed,
		"Inspection still waits for the delivery")
	assert_true(LOGIC.dispatch(flags, chapter, "side:%s:step_2" % CHAIN).changed)
	assert_false(LOGIC.dispatch(flags, chapter, "side:%s:step_2" % CHAIN).changed, "Step 2 lands once")
	assert_true(LOGIC.dispatch(flags, chapter, "side:%s:step_3" % CHAIN).changed)
	assert_true(flags.has(GLASS.COMPLETE))
	var loaded := PROGRESSION.new()
	loaded.load_data(flags.save_data())
	for flag: String in [GLASS.STEP_1, GLASS.STEP_2, GLASS.COMPLETE]:
		assert_true(loaded.has(flag), "%s survives save/load" % flag)


func test_every_fact_is_world_scoped_and_declared() -> void:
	var side: Array = _chapter().persistent_flags.side_content
	for flag: String in [GLASS.STEP_1, GLASS.STEP_2, GLASS.COMPLETE, GLASS.THANKED]:
		assert_eq(PROGRESSION.scope_of(flag), PROGRESSION.SCOPE_WORLD,
			"%s is one shared world fact, like the shelter it repairs" % flag)
		assert_true(side.has(flag), "%s is a declared persistent chapter flag" % flag)
	for chain: Dictionary in _chapter().side_chains:
		if str(chain.id) == CHAIN:
			for step: Dictionary in chain.steps:
				assert_eq(str(step.scope), "world")


func test_bryn_greetings_follow_the_chain_then_return_to_his_lines() -> void:
	var bryn := _bryn_spec()
	var flags := PROGRESSION.new()
	flags.set_flag("stormwood:chapter_started")
	flags.set_flag("stormwood:rodline_linked")
	assert_eq(PEOPLE.greeting_for(bryn, flags), "stormwood_warden_elect_bryn_in_progress",
		"Before the chain is available Bryn gives his story account, which meets him")
	flags.set_flag(GLASS.REVEALED)
	assert_eq(PEOPLE.greeting_for(bryn, flags), GLASS.OFFER)
	flags.set_flag(GLASS.STEP_1)
	assert_eq(PEOPLE.greeting_for(bryn, flags), GLASS.REQUEST)
	flags.set_flag(GLASS.STEP_2)
	assert_eq(PEOPLE.greeting_for(bryn, flags), GLASS.INSPECT_HINT)
	flags.set_flag(GLASS.COMPLETE)
	flags.set_flag("stormwood:long_storm_ended")
	assert_eq(PEOPLE.greeting_for(bryn, flags), GLASS.THANKS,
		"The acknowledgement outranks even post-storm lines until heard")
	flags.set_flag(GLASS.THANKED)
	assert_eq(PEOPLE.greeting_for(bryn, flags), "stormwood_warden_elect_bryn_post_storm")
	var lines := GLASS.conversations()
	for id: String in [GLASS.OFFER, GLASS.REQUEST, GLASS.INSPECT_HINT, GLASS.THANKS]:
		assert_true(lines.has(id), "%s is authored" % id)
		assert_true((lines[id].lines as Array).size() >= 2)
	var request := " ".join(lines[GLASS.REQUEST].lines as Array)
	assert_true(request.contains("Three Stormglass") and request.contains("two Conductor Vine"),
		"The request names the exact delivery")
	var thanks := " ".join(lines[GLASS.THANKS].lines as Array)
	assert_true(thanks.contains("creature bed"), "The acknowledgement names the payoff")


func test_only_bryn_gains_chain_branches() -> void:
	assert_eq(GLASS.branches_for(GLASS.BRYN).size(), 4)
	assert_true(GLASS.branches_for("trader_oswin").is_empty())
	assert_true(GLASS.branches_for("courier_pim").is_empty())


func test_delivery_rule_refuses_order_stance_and_materials() -> void:
	var flags := PROGRESSION.new()
	assert_eq(GLASS.evaluate_delivery(_carrying(3, 2), AT_BRYN, flags).code, "not_asked")
	flags.set_flag(GLASS.STEP_1)
	assert_true(bool(GLASS.evaluate_delivery(_carrying(3, 2), AT_BRYN, flags).ok))
	assert_true(bool(GLASS.evaluate_delivery(_carrying(9, 7), AT_BRYN, flags).ok))
	assert_eq(GLASS.evaluate_delivery(_carrying(2, 2), AT_BRYN, flags).code, "materials",
		"Two Stormglass is not three")
	assert_eq(GLASS.evaluate_delivery(_carrying(3, 1), AT_BRYN, flags).code, "materials")
	assert_eq(GLASS.evaluate_delivery({"kind": GLASS.DELIVERY_KIND}, AT_BRYN, flags).code, "materials",
		"An empty satchel pays nothing")
	assert_eq(GLASS.evaluate_delivery(_carrying("3", 2), AT_BRYN, flags).code, "materials",
		"A non-number count is refused")
	assert_eq(GLASS.evaluate_delivery(_carrying(NAN, 2), AT_BRYN, flags).code, "materials")
	assert_eq(GLASS.evaluate_delivery(_carrying(3, 2), Vector3(-690, 44, 2300), flags).code, "too_far",
		"The host checks its own view of the trainer, 10 m out")
	assert_eq(GLASS.evaluate_delivery(_carrying(3, 2), null, flags).code, "too_far",
		"An unknown trainer is never assumed to be with Bryn")
	flags.set_flag(GLASS.STEP_2)
	assert_eq(GLASS.evaluate_delivery(_carrying(3, 2), AT_BRYN, flags).code, "already_delivered")


func test_missing_counts_what_the_satchel_lacks() -> void:
	var bag := INVENTORY.new(ITEM_DB.new())
	assert_eq(GLASS.missing_from(bag), {"stormglass": 3, "conductor_vine": 2})
	bag.add("stormglass", 2)
	bag.add("stormglass_crown", 6)
	bag.add("conductor_vine", 2)
	assert_eq(GLASS.missing_from(bag), {"stormglass": 1},
		"Crown-grade glass is not ordinary Stormglass")
	bag.add("stormglass", 1)
	assert_true(GLASS.missing_from(bag).is_empty())


func test_host_commits_flag_and_both_takes_in_one_journaled_delta() -> void:
	var host := _asked_host()
	var ledger: RefCounted = LEDGER.new(host.world)
	var result := GLASS.commit_delivery(host, ledger, 1, _carrying(4, 2), AT_BRYN)
	assert_true(bool(result.ok))
	assert_true(host.world.flags.has(GLASS.STEP_2))
	assert_eq(host.save_system.writes, 1, "The world is journaled before publication")
	var ops: Array = result.delta.ops
	assert_eq(ops.size(), 3, "One flag and two takes, nothing else")
	assert_eq([ops[0].op, ops[0].scope, ops[0].id], ["flag", "world", GLASS.STEP_2])
	var taken := {}
	for op: Dictionary in ops.slice(1):
		assert_eq([op.op, op.scope, op.peers], ["item_take", "player", [1]])
		taken[str(op.item)] = int(op.count)
	assert_eq(taken, {"stormglass": 3, "conductor_vine": 2}, "Exactly the cost, never the whole stack")
	var restored := WORLD.new()
	restored.load_data(host.save_system.store.read(host.world.world_id))
	assert_true(restored.flags.has(GLASS.STEP_2), "The journal carries the delivery")


func test_double_submit_and_retry_take_nothing_twice() -> void:
	var host := _asked_host()
	var ledger: RefCounted = LEDGER.new(host.world)
	assert_true(bool(GLASS.commit_delivery(host, ledger, 1, _carrying(6, 4), AT_BRYN).ok))
	var sequence := int(ledger.seq)
	var again := GLASS.commit_delivery(host, ledger, 1, _carrying(6, 4), AT_BRYN)
	assert_false(bool(again.ok))
	assert_eq(again.code, "already_delivered")
	assert_false(again.has("delta"), "A refusal carries no takes to apply")
	var partner := GLASS.commit_delivery(host, ledger, 2, _carrying(3, 2), AT_BRYN)
	assert_eq(partner.code, "already_delivered",
		"A co-op partner racing the same delivery is not charged a second time")
	assert_eq(int(ledger.seq), sequence, "Refusals commit nothing")
	assert_eq(host.save_system.writes, 1)


func test_lacking_items_leave_the_world_untouched() -> void:
	var host := _asked_host()
	var ledger: RefCounted = LEDGER.new(host.world)
	var before: Dictionary = host.world.save_data()
	var result := GLASS.commit_delivery(host, ledger, 1, _carrying(3, 1), AT_BRYN)
	assert_eq(result.code, "materials")
	assert_eq(host.world.save_data(), before)
	assert_eq(int(ledger.seq), 0)
	assert_eq(host.save_system.writes, 0)


func test_only_the_host_commits_and_a_failed_journal_rolls_back() -> void:
	var client := _asked_host()
	client.host = false
	var client_ledger: RefCounted = LEDGER.new(client.world)
	assert_eq(GLASS.commit_delivery(client, client_ledger, 2, _carrying(3, 2), AT_BRYN).code, "not_host",
		"A client never writes the delivery itself")
	assert_false(client.world.flags.has(GLASS.STEP_2))
	var host := _asked_host()
	var ledger: RefCounted = LEDGER.new(host.world)
	host.save_system.fail_write = true
	var before: Dictionary = host.world.save_data()
	var revision := int(host.world.revision)
	var failed := GLASS.commit_delivery(host, ledger, 1, _carrying(3, 2), AT_BRYN)
	assert_eq(failed.code, "journal_failed")
	assert_false(host.world.flags.has(GLASS.STEP_2))
	assert_eq(host.world.save_data(), before)
	assert_eq(int(host.world.revision), revision)
	assert_eq(int(ledger.seq), 0)
	host.world.world_id = ""
	host.save_system.fail_write = false
	assert_eq(GLASS.commit_delivery(host, ledger, 1, _carrying(3, 2), AT_BRYN).code, "journal_failed",
		"A world with no save identity cannot take materials it could lose")


func test_a_remote_delivery_charges_only_the_requester_and_replicates_the_repair() -> void:
	var host := _asked_host()
	var ledger: RefCounted = LEDGER.new(host.world)
	var result := GLASS.commit_delivery(host, ledger, 2, _carrying(3, 2), AT_BRYN)
	assert_true(bool(result.ok))
	assert_true(LEDGER.player_ops_for(result.delta, 1).is_empty(), "The host's own satchel is untouched")
	assert_eq(LEDGER.player_ops_for(result.delta, 2).size(), 2, "The requester pays both materials")
	assert_true(LEDGER.player_ops_for(result.delta, 3).is_empty(), "A third player pays nothing")
	# A partner's world receives the same delta and sees the same repair.
	var partner_world := WORLD.new()
	for flag: String in ["stormwood:rodline_linked", GLASS.REVEALED, GLASS.STEP_1]:
		partner_world.flags.set_flag(flag)
	var partner_ledger: RefCounted = LEDGER.new(partner_world)
	partner_ledger.apply(result.delta)
	assert_true(partner_world.flags.has(GLASS.STEP_2), "The second player sees the delivered state")
	var bag := INVENTORY.new(ITEM_DB.new())
	bag.add("stormglass", 5)
	bag.add("conductor_vine", 2)
	for op: Dictionary in LEDGER.player_ops_for(result.delta, 2):
		bag.remove(str(op.item), int(op.count))
	assert_eq([bag.count("stormglass"), bag.count("conductor_vine")], [2, 0])


func test_chain_never_writes_a_rod_flag_or_camp_rod() -> void:
	var chapter := _chapter()
	var flags := PROGRESSION.new()
	for flag: String in ["stormwood:chapter_started", "stormwood:rodline_linked", GLASS.REVEALED]:
		flags.set_flag(flag)
	var before: Array = flags.all_set()
	for step in ["step_1", "step_2", "step_3"]:
		LOGIC.dispatch(flags, chapter, "side:%s:%s" % [CHAIN, step])
	var added: Array = []
	for flag: String in flags.all_set():
		if not before.has(flag):
			added.append(flag)
	added.sort()
	assert_eq(added, [GLASS.STEP_1, GLASS.STEP_2, GLASS.COMPLETE],
		"The chain grants only its own step facts: no rod disable, no lower/all-rods aggregate")
	var surge: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/config/stormwood_surge.json"))
	assert_false((surge.regions.conductor_run as Dictionary).has("rod_flag"),
		"Conductor Run has no rod whose Calm multiplier the shelter could duplicate")
	var zone_ok := false
	var shelter := GLASS.shelter_at()
	for zone: Dictionary in surge.safe_zones:
		if str(zone.id) == str(GLASS.config().shelter.safe_zone_id):
			zone_ok = shelter.distance_to(Vector2(float(zone.at[0]), float(zone.at[1]))) < float(zone.radius)
	assert_true(zone_ok, "The shelter already stands inside Rodline Post's Surge safe zone")
	var camps_rods := 0
	for camp: Dictionary in CAMPS.load_config().camps:
		for prop: Dictionary in camp.props:
			if str(prop.model) == "lightning_rod":
				camps_rods += 1
	assert_eq(camps_rods, 6, "The shelter's rod is dressing, not a seventh camp safe rod")


func test_bed_uses_a_free_reserved_index_and_existing_props() -> void:
	var index := GLASS.bed_index()
	assert_true(index <= -10, "Inside rest_point.gd's reserved authored range")
	for camp: Dictionary in CAMPS.load_config().camps:
		assert_ne(int(camp.creature_bed.bed_index), index, "Not shared with a Stormwood camp bed")
	var water: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_camps.json"))
	for camp: Dictionary in water.camps:
		assert_ne(int(camp.creature_bed_index), index, "Not shared with a Tidewake camp bed")
	var cloud: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/cloudreach_chapter.json"))
	for camp: Dictionary in cloud.camping_contract.camps:
		assert_ne(int(camp.creature_bed.bed_index), index, "Not shared with a Cloudreach camp bed")
	for path: String in GLASS.MODEL_PATHS.values():
		assert_true(ResourceLoader.exists(path), "%s is an installed asset" % path)
	assert_eq(GLASS.cost(), {"stormglass": 3, "conductor_vine": 2})
