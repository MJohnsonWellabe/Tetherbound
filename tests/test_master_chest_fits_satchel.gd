extends "res://tests/test_case.gd"

## Every Master's chest is delivered all-or-nothing (breakthrough.gd::prepare_chest
## refuses with chest_pending_make_satchel_room). A player always carries the four
## gathering tools, the Home Key and, between chapters, one held portal key, so
## the chest must fit the 24-slot Satchel beside those six slots. Routes-B found
## master_t4 needing 19 slots against the 18 left during Cloudreach, so Aster's
## chest could never be claimed. Bulk tier materials now stack far enough that
## each kit fits with room to spare. This drives the real Foundation staging path
## on a real save projection; nothing here sizes the kit by hand.

const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const P := preload("res://scripts/creatures/progression.gd")
const RECORD := preload("res://scripts/net/character_record_rules.gd")
const BAG := preload("res://scripts/world/death_satchel_rules.gd")
const RULES := preload("res://scripts/creatures/breakthrough.gd")
const MASTER_ACTIONS := preload("res://scripts/masters/breakthrough_actions.gd")

## What every player carries while claiming a chest: four tools, the Home Key and
## the one chapter key held from Veyra until Stormwood is entered.
const CARRIED := ["axe", "pickaxe", "knife", "hammer", "home_key", "stormwood_portal_key"]
const SPARE_SLOTS := 2
## Five creatures sharing one primary type: one attuned stack, the kit's
## ordinary size and the case the 16-slot target is set against.
const SHARED_TYPE_PARTY := ["terrapup", "bramblebun", "mudsnout", "trailpup", "burrowback"]
## Five distinct primary types: five attuned stacks, the largest kit any party
## can receive (ground, water, air, electric, dark).
const MIXED_TYPE_PARTY := ["terrapup", "ripplet", "galewisp", "sparkit", "shadelet"]

func _record(party: Array) -> Dictionary:
	var player := preload("res://autoload/player_state.gd").new()
	player.configure(preload("res://autoload/item_db.gd").new())
	player.character_id = "master-chest-fit"
	for species: String in party:
		var creature: RefCounted = SPECIES.spawn(species)
		creature.set_level(10, P.config())
		assert_true(player.party.add(creature), species + " joins the five-creature party")
	for item: String in CARRIED:
		assert_eq(player.inventory.add(item, 1), 0, item + " is carried")
	var saved: Dictionary = player.save_data()
	player.redesign_character = RULES.initialize_caught(saved.redesign_character, saved.party[0])
	var record := RECORD.portable_projection(player.save_data())
	assert_eq(RECORD.errors(record, player.character_id), [], "real save produces a canonical admission")
	return record

func _claim(record: Dictionary, tier: int) -> Dictionary:
	var master_id := "master_t%d" % tier
	var context := {"character_id": record.character_id, "expected_revision": 7, "owns_character": true,
		"in_range": true, "in_combat": false, "source_key": "personal_candy_feed", "master_id": master_id,
		"validated_host_outcome": "win", "participant_count": 1,
		"encounter_id": "master-chest-fit-%d" % tier, "creature_uid": str(record.party[0].uid)}
	var win := MASTER_ACTIONS.stage(record, 7, "master_win",
		{"master_id": master_id, "encounter_id": context.encounter_id, "creature_uid": context.creature_uid},
		context, Callable(), Callable(), Callable())
	assert_true(win.get("ok") == true, master_id + " win is staged")
	if win.get("ok") != true: return {}
	return MASTER_ACTIONS.stage(win.state, 7, "master_chest", {"master_id": master_id}, context,
		Callable(), Callable(), Callable())

func _empty_slots(inventory: Array) -> int:
	var bag := BAG.inventory_from(inventory)
	return bag.slot_count() - bag.used_slots()

func test_every_master_chest_leaves_two_spare_slots_beside_tools_home_key_and_a_chapter_key() -> void:
	var record := _record(SHARED_TYPE_PARTY)
	assert_eq(_empty_slots(record.inventory), 24 - CARRIED.size(), "only the carried six occupy the Satchel")
	for tier: int in range(1, 6):
		var chest := _claim(record, tier)
		var master_id := "master_t%d" % tier
		assert_true(chest.get("ok") == true, "%s chest fits beside the carried six (got %s)" % [master_id, chest.get("code", "")])
		if chest.get("ok") != true: continue
		var spare := _empty_slots(chest.state.inventory)
		assert_true(spare >= SPARE_SLOTS, "%s kit leaves %d spare slots; needs at least %d" % [master_id, spare, SPARE_SLOTS])
		assert_eq(BAG.inventory_from(chest.state.inventory).count("tether_candy"), 2, master_id + " kit is delivered whole")

func test_saves_holding_old_size_bulk_stacks_load_and_top_up() -> void:
	# Stack size is item data, never saved. A save written under the old caps
	# (50 ore, 30 plume) loads verbatim, stays admissible, and new pickups top up
	# those partial stacks before opening a slot.
	var record := _record(SHARED_TYPE_PARTY)
	var old_caps := {"cliffglass_ore": 50, "skyplume": 30, "sluice_metal": 30, "reef_stone": 50}
	var slot := CARRIED.size()
	for item: String in old_caps:
		for copy: int in 2:
			record.inventory[slot] = {"id": item, "n": int(old_caps[item])}
			slot += 1
	assert_true(BAG.valid_slots(record.inventory), "old-size stacks remain valid slots")
	var player := preload("res://autoload/player_state.gd").new()
	player.configure(preload("res://autoload/item_db.gd").new())
	player.load_data(JSON.parse_string(JSON.stringify(record)))
	for item: String in old_caps:
		assert_eq(player.inventory.count(item), 2 * int(old_caps[item]), item + " survives load unchanged")
	var used: int = player.inventory.used_slots()
	assert_eq(player.inventory.add("cliffglass_ore", 200), 0)
	assert_eq(player.inventory.used_slots(), used, "new ore tops up the old partial stacks first")
	assert_eq(player.inventory.count("cliffglass_ore"), 300)
	assert_eq(RECORD.errors(RECORD.portable_projection(player.save_data()), player.character_id), [],
		"the topped-up save is still canonically admissible")

func test_every_master_chest_fits_a_five_distinct_type_party() -> void:
	# Twelve distinct kit items plus five attuned stacks cannot drop below 17
	# slots by stack size alone; it must still fit the 18 left by the carried six.
	var record := _record(MIXED_TYPE_PARTY)
	for tier: int in range(1, 6):
		var chest := _claim(record, tier)
		var master_id := "master_t%d" % tier
		assert_true(chest.get("ok") == true, "%s chest fits a five-type party beside the carried six (got %s)" % [master_id, chest.get("code", "")])
		if chest.get("ok") != true: continue
		var bag := BAG.inventory_from(chest.state.inventory)
		for attuned: String in ["attuned_ground", "attuned_water", "attuned_air", "attuned_electric", "attuned_dark"]:
			assert_true(bag.count(attuned) > 0, "%s pays %s for its creature" % [master_id, attuned])
