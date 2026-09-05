extends "res://tests/test_case.gd"

## STAGE B 0.E — characterization fence for autoload/party.gd and
## autoload/inventory.gd, ahead of Wave 1's re-homing onto PlayerState.
## CLAUDE.md's hard rule ("the player can own only five creatures total")
## is enforced in exactly one place (`party.gd::add()`); this file exists so
## a refactor that moves the cap check cannot silently drop it.

const PARTY := preload("res://autoload/party.gd")
const INVENTORY := preload("res://autoload/inventory.gd")
const ITEM_DB := preload("res://autoload/item_db.gd")
const CREATURE := preload("res://scripts/creatures/creature_instance.gd")

const DEFINITION := {
	"display_name": "Terrapup", "type": "ground",
	"base_hp": 100.0, "base_attack": 20.0, "base_defence": 20.0,
}


func _creature() -> RefCounted:
	return CREATURE.from_species("terrapup", DEFINITION)


# --- party: the five-creature cap -------------------------------------------

func test_max_creatures_is_five() -> void:
	assert_eq(PARTY.MAX_CREATURES, 5, "CLAUDE.md's hard rule; never raise this without an owner directive")


func test_add_refuses_the_sixth_creature() -> void:
	var party := PARTY.new()
	for i in 5:
		assert_true(party.add(_creature()), "the first five must all be accepted")
	assert_true(party.is_full())
	assert_false(party.add(_creature()), "a sixth creature must be refused, not stored anywhere")
	assert_eq(party.size(), 5, "the refused sixth must not have been appended")


func test_add_refuses_null_and_a_duplicate_instance() -> void:
	var party := PARTY.new()
	assert_false(party.add(null))
	var c := _creature()
	assert_true(party.add(c))
	assert_false(party.add(c), "the same instance twice must be refused, not counted as a second member")
	assert_eq(party.size(), 1)


# --- set_active refuses fainted/resting -------------------------------------

func test_set_active_refuses_a_fainted_creature() -> void:
	var party := PARTY.new()
	var c := _creature()
	party.add(c)
	c.fainted = true
	assert_false(party.set_active(0), "a fainted creature must refuse to become active")
	assert_eq(party.active_index(), 0, "active_index is unmoved by a refused set_active")


func test_set_active_refuses_a_resting_creature() -> void:
	var party := PARTY.new()
	var a := _creature()
	var b := _creature()
	party.add(a)
	party.add(b)
	party.set_resting(1, true)
	assert_false(party.set_active(1), "a resting creature must refuse to become active")


func test_set_active_accepts_a_healthy_creature() -> void:
	var party := PARTY.new()
	party.add(_creature())
	party.add(_creature())
	assert_true(party.set_active(1))
	assert_eq(party.active_index(), 1)


# --- cycle_active skips fainted/resting members -----------------------------

func test_cycle_active_skips_fainted_and_resting_members() -> void:
	var party := PARTY.new()
	var a := _creature()
	var b := _creature()
	var c := _creature()
	party.add(a)  # index 0, active
	party.add(b)  # index 1, will be fainted
	party.add(c)  # index 2, healthy
	b.fainted = true
	assert_true(party.cycle_active(1))
	assert_eq(party.active_index(), 2, "cycling forward must skip the fainted middle member")


func test_cycle_active_returns_false_when_everyone_else_is_unusable() -> void:
	var party := PARTY.new()
	var a := _creature()
	var b := _creature()
	party.add(a)
	party.add(b)
	b.fainted = true
	assert_false(party.cycle_active(1), "the only other member is fainted; there is nowhere to cycle to")
	assert_eq(party.active_index(), 0, "active must not move when cycling finds nothing usable")


func test_cycle_active_on_a_single_member_party_returns_false() -> void:
	var party := PARTY.new()
	party.add(_creature())
	assert_false(party.cycle_active(1))


# --- all_fainted() ------------------------------------------------------------

func test_all_fainted_is_true_only_when_every_member_is_down() -> void:
	var party := PARTY.new()
	var a := _creature()
	var b := _creature()
	party.add(a)
	party.add(b)
	assert_false(party.all_fainted())
	a.fainted = true
	assert_false(party.all_fainted(), "one healthy member is enough to keep fighting")
	b.fainted = true
	assert_true(party.all_fainted())


func test_all_fainted_is_false_for_an_empty_party() -> void:
	# Pinned explicitly: an empty party is not a wipe, it is "nobody deployed
	# yet" -- the file's own comment says "every creature down means there is
	# no fight to be had", which an empty party trivially satisfies by
	# vacuous truth UNLESS the code special-cases it, which it does.
	var party := PARTY.new()
	assert_false(party.all_fainted())


# =============================================================================
# inventory.gd
# =============================================================================

var db: RefCounted = null


func before_each() -> void:
	db = ITEM_DB.new()


func test_slot_count_is_24() -> void:
	var bag := INVENTORY.new(db)
	assert_eq(INVENTORY.SLOT_COUNT, 24)
	assert_eq(bag.slot_count(), 24)


func test_add_leftover_arithmetic_at_the_stack_cap() -> void:
	var bag := INVENTORY.new(db)
	var cap: int = db.stack_size("wood")
	assert_true(cap > 1, "sanity: wood must actually stack for this test to mean anything")
	# Pinning ACTUAL behaviour: add() does not stop at one slot. An amount
	# bigger than one stack overflows into the NEXT slot in the same call --
	# leftover is only ever nonzero once every slot is full, never merely
	# because one stack capped out.
	var leftover := bag.add("wood", cap + 5)
	assert_eq(leftover, 0, "a fresh satchel has 23 more empty slots to spill the remainder into")
	assert_eq(bag.count("wood"), cap + 5, "the excess opened a second slot rather than being dropped")
	assert_eq(bag.stack_at(0).get("n"), cap, "the first slot is filled to the cap before a new one opens")
	assert_eq(bag.stack_at(1).get("n"), 5, "the remainder becomes its own new stack, not a second creation of the first")
	# Filling every slot to the cap, then trying to add one more of anything
	# stackable must report the WHOLE amount as leftover, not silently drop it.
	var bag2 := INVENTORY.new(db)
	for i in INVENTORY.SLOT_COUNT:
		bag2.add("wood", cap)
	assert_true(bag2.is_full())
	assert_eq(bag2.add("wood", 3), 3, "a full satchel returns the whole requested amount as leftover")


func test_add_of_a_non_stacking_item_opens_one_slot_per_unit() -> void:
	var bag := INVENTORY.new(db)
	# Anything with stack_size 1 (a tool) must never combine into one slot.
	var non_stacking_id := ""
	for id in ["axe", "pickaxe", "hoe"]:
		if db.has(id) and db.stack_size(id) <= 1:
			non_stacking_id = id
			break
	if non_stacking_id == "":
		_fail("no known non-stacking item id found in items.json to test against")
		return
	var leftover := bag.add(non_stacking_id, 2)
	assert_eq(leftover, 0)
	var used := 0
	for i in INVENTORY.SLOT_COUNT:
		if not bag.is_slot_empty(i) and bag.stack_at(i).get("id") == non_stacking_id:
			used += 1
	assert_eq(used, 2, "two non-stacking items must occupy two separate slots")


func test_remove_is_all_or_nothing() -> void:
	var bag := INVENTORY.new(db)
	bag.add("wood", 5)
	assert_false(bag.remove("wood", 6), "asking for more than is held must refuse")
	assert_eq(bag.count("wood"), 5, "a refused remove must change nothing")
	assert_true(bag.remove("wood", 5))
	assert_eq(bag.count("wood"), 0)


func test_is_full_treats_a_null_slot_as_room() -> void:
	var bag := INVENTORY.new(db)
	assert_false(bag.is_full(), "a fresh satchel of 24 null slots is not full")
	var cap: int = db.stack_size("wood")
	for i in INVENTORY.SLOT_COUNT:
		bag.add("wood", cap)
	assert_true(bag.is_full())


func test_drain_returns_only_the_occupied_stacks_compacted_not_a_full_width_null_padded_array() -> void:
	# Pinning ACTUAL behaviour, not the assumption: drain() appends only
	# non-null slots (`if _slots[i] != null: out.append(...)`) -- the
	# returned array is the COMPACT list of stacks that were actually
	# present, never SLOT_COUNT long and never carrying `null` placeholders
	# for the empty slots. A death-satchel or any other consumer of drain()
	# that assumes index-aligned-with-slot-number output would be wrong.
	var bag := INVENTORY.new(db)
	bag.add("wood", 3)
	bag.set_slot(10, {"id": "stone", "n": 2})
	var drained := bag.drain()
	assert_eq(drained.size(), 2, "exactly the two occupied slots, not 24")
	for entry in drained:
		assert_ne(entry, null, "drain() must never emit a null placeholder for an empty slot")
	assert_eq(bag.used_slots(), 0, "drain must empty every slot")


func test_drain_on_an_empty_satchel_returns_an_empty_array_and_does_not_bump_revision() -> void:
	var bag := INVENTORY.new(db)
	var rev_before := bag.revision
	var drained := bag.drain()
	assert_eq(drained.size(), 0)
	assert_eq(bag.revision, rev_before, "draining nothing must not register as a change")
