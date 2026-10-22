extends "res://tests/test_case.gd"

## A saved Master chest delivery still loads after a stack-capacity change
## (bulk tier materials 50 -> 200, 746fa2a07): the row written with the old
## 50-size stacks replays as fewer, larger stacks. The replay accepts that
## layout only when the saved slots pass the slot schema and every item total
## and stack field matches; anything else is still refused.
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const P := preload("res://scripts/creatures/progression.gd")
const RECORD := preload("res://scripts/net/character_record_rules.gd")
const RULES := preload("res://scripts/creatures/breakthrough.gd")
const ACTIONS := preload("res://scripts/net/character_action_rules.gd")
const DELIVERY := preload("res://scripts/net/character_action_delivery.gd")
const WORLD := preload("res://autoload/world_state.gd")
const PARTY := ["terrapup", "bramblebun", "mudsnout", "trailpup", "burrowback"]
const CARRIED := ["axe", "pickaxe", "knife", "hammer", "home_key", "stormwood_portal_key"]
const OLD_STACK := 50

func _record() -> Dictionary:
	var player := preload("res://autoload/player_state.gd").new()
	player.configure(preload("res://autoload/item_db.gd").new())
	player.character_id = "probe"
	for species: String in PARTY:
		var creature: RefCounted = SPECIES.spawn(species)
		creature.set_level(10, P.config())
		player.party.add(creature)
	for item: String in CARRIED:
		player.inventory.add(item, 1)
	player.inventory.set_slot(0, {"id": "axe", "n": 1, "durability": 27})
	var saved: Dictionary = player.save_data()
	player.redesign_character = RULES.initialize_caught(saved.redesign_character, saved.party[0])
	return RECORD.portable_projection(player.save_data())

func _row() -> Dictionary:
	var record := _record()
	var context := {"character_id": record.character_id, "expected_revision": 7, "owns_character": true,
		"in_range": true, "in_combat": false, "source_key": "personal_candy_feed", "master_id": "master_t1",
		"validated_host_outcome": "win", "participant_count": 1, "encounter_id": "probe-1",
		"creature_uid": str(record.party[0].uid)}
	var win := ACTIONS.stage(record, 7, "master_win", {"master_id": "master_t1", "encounter_id": "probe-1",
		"creature_uid": context.creature_uid}, context, RECORD.errors)
	assert_true(win.get("ok") == true, "master_t1 win is staged")
	var chest_context := context.duplicate()
	chest_context.expected_revision = 8
	var chest := ACTIONS.stage(win.state, 8, "master_chest", {"master_id": "master_t1"}, chest_context, RECORD.errors)
	assert_true(chest.get("ok") == true, "master_t1 chest is staged")
	chest.character_revision = 9
	var row := DELIVERY.make_record("w1", "ns1", "ep1", chest, null, RECORD.errors)
	assert_false(row.is_empty(), "the real chest row is recorded")
	return row

func _valid(row: Dictionary) -> bool:
	return DELIVERY.valid(row, RECORD.errors, "", "ns1", "w1") and WORLD.training_row_valid(row, "ns1", "w1")

## The same credit as a build with OLD_STACK capacity would have laid it out.
func _old_layout(row: Dictionary) -> Dictionary:
	var old := row.duplicate(true)
	var slots: Array = old.after.inventory
	for index in slots.size():
		var stack: Variant = slots[index]
		while stack is Dictionary and int(stack.n) > OLD_STACK:
			var spill := int(stack.n) - OLD_STACK
			stack.n = OLD_STACK
			var free := slots.find(null)
			assert_true(free >= 0, "the old layout fits the Satchel")
			if free < 0: return old
			slots[free] = {"id": stack.id, "n": mini(spill, OLD_STACK)}
			if spill > OLD_STACK:
				stack = slots[free]
				stack.n = spill
	return old

func _bulk_slots(row: Dictionary) -> Array[int]:
	var indexes: Array[int] = []
	for index in (row.after.inventory as Array).size():
		var stack: Variant = row.after.inventory[index]
		if stack is Dictionary and stack.id == "rootstone": indexes.append(index)
	return indexes

func test_a_real_chest_row_in_the_old_stack_layout_still_validates() -> void:
	var row := _row()
	assert_true(_valid(row), "the row as staged validates")
	var old := _old_layout(row)
	assert_true(_bulk_slots(old).size() > 1, "the old layout splits the bulk credit across slots")
	assert_true(_valid(old), "the old 50-size layout of the same credit validates")
	var round_trip: Dictionary = JSON.parse_string(JSON.stringify(old))
	assert_true(_valid(round_trip), "and still validates after a JSON round-trip")

func test_old_layouts_that_change_items_or_break_the_slot_schema_are_refused() -> void:
	var old := _old_layout(_row())
	var bulk := _bulk_slots(old)
	var first: int = bulk[0]
	var second: int = bulk[1]
	var cases := {}
	var other_id := old.duplicate(true)
	other_id.after.inventory[first].id = "ironwood"
	cases["a different item id"] = other_id
	var negative := old.duplicate(true)
	negative.after.inventory[first].n = int(negative.after.inventory[first].n) + int(negative.after.inventory[second].n) + 80
	negative.after.inventory[second].n = -80
	cases["a negative count"] = negative
	var ghost := old.duplicate(true)
	ghost.after.inventory[ghost.after.inventory.find(null)] = {"id": "rootstone", "n": 0}
	cases["a zero-count stack"] = ghost
	var text := old.duplicate(true)
	text.after.inventory[first].n = str(text.after.inventory[first].n)
	cases["a string count"] = text
	var fraction := old.duplicate(true)
	fraction.after.inventory[first].n = float(fraction.after.inventory[first].n) - 0.5
	fraction.after.inventory[second].n = float(fraction.after.inventory[second].n) + 0.5
	cases["a fractional count"] = fraction
	var extra := old.duplicate(true)
	extra.after.inventory[first].bound = "x"
	cases["an extra stack field"] = extra
	var worn := old.duplicate(true)
	worn.after.inventory[0].durability = 30
	cases["a changed tool durability"] = worn
	var levelled := old.duplicate(true)
	levelled.after.party[0].level = 11
	cases["another record field"] = levelled
	var shorter := old.duplicate(true)
	shorter.after.inventory.pop_back()
	cases["a shorter inventory"] = shorter
	for label: String in cases:
		assert_false(_valid(cases[label]), label + " is refused")

func test_a_whole_float_tool_field_keys_like_its_integer() -> void:
	# The replay stages from `before` (durability 27, an int); a saved `after`
	# that came back from JSON holds 27.0. _equivalent treats them alike, so
	# the layout key must too.
	var old := _old_layout(_row())
	assert_true(old.after.inventory[0].durability is int, "the staged tool durability is an integer")
	old.after.inventory[0].durability = 27.0
	assert_true(_valid(old), "durability 27.0 in the saved layout keys like 27")
