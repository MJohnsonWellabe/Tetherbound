extends TestCase

## Dying: what falls, what stays, where you wake up, and what happens to the pals.
##
## GAME_DESIGN.md §22 is eight lines and every one of them is a test here. The two
## that matter most are the two that cannot be recovered from if they are wrong:
##
##   * MULTIPLE SATCHELS PERSIST — CLAUDE.md makes it a hard rule. The way it
##     breaks is a second death quietly replacing the first bag, and the player
##     finds out by walking to a marker that is not there.
##   * NO XP LOSS, NO LEVEL LOSS — the party comes through a death untouched.
##
## No scene. The nodes here are built with `.new()` and parented to each other,
## which is all a NodePath needs; nothing below requires a `SceneTree`, a physics
## frame or a rendered pixel (D02).

const SATCHELS := preload("res://scripts/player/satchel.gd")
const DEATH := preload("res://scripts/player/death.gd")
const BAG := preload("res://scripts/player/trainer_inventory.gd")
const VITALS := preload("res://scripts/player/player_vitals.gd")
const PARTY_MANAGER := preload("res://scripts/pals/party_manager.gd")
const RECOVERY := preload("res://scripts/pals/recovery.gd")
const SPECIES := preload("res://scripts/pals/pal_species.gd")
const INVENTORY := preload("res://scripts/items/inventory.gd")
const STACK := preload("res://scripts/items/item_stack.gd")
const DEFS := preload("res://scripts/items/item_defs.gd")

## Where the trainer is standing when they die, and where they started.
const FELL_AT := Vector3(120.0, 4.0, -60.0)
const STARTED_AT := Vector3(0.0, 2.0, 0.0)

var _root: Node3D = null
var _satchels: Node3D = null
var _bag: Node = null
var _player: Node = null
var _party: Node = null
var _recovery: Node = null
var _death: Node = null


func before_each() -> void:
	_root = Node3D.new()

	_satchels = SATCHELS.new()
	_satchels.name = "Satchels"
	# No world to ask for a ground height and no trainer to reach one: both paths
	# are optional and both degrade to "the satchel is exactly where it fell".
	_satchels.world_path = NodePath()
	_satchels.player_path = NodePath()
	_satchels.inventory_path = NodePath("../TrainerInventory")
	_root.add_child(_satchels)
	_satchels._ready()

	_bag = BAG.new()
	_bag.name = "TrainerInventory"
	_bag.player_path = NodePath()
	_bag.home_path = NodePath()
	_root.add_child(_bag)
	_bag._ready()
	_bag.inventory().clear()

	# A stand-in trainer rather than `player_controller.gd` itself. `run_tests.gd`
	# works inside `SceneTree._init()`, where nothing is actually in the tree and
	# every `Node3D.global_position` reads (0,0,0) with an engine error — so a real
	# CharacterBody3D here would make every assertion about WHERE something fell
	# meaningless. `death.gd` reads the position through `get()` for this reason
	# and this is the object on the other end of it. The real body's wiring is
	# proven by the scene and by the smokes.
	_player = _FakeTrainer.new()
	_player.name = "Player"
	_root.add_child(_player)
	_player.global_position = FELL_AT

	_party = PARTY_MANAGER.new()
	_party.name = "Party"
	_root.add_child(_party)
	_party._ready()

	_recovery = RECOVERY.new()
	_recovery.name = "Recovery"
	_recovery.party_path = NodePath("../Party")
	_root.add_child(_recovery)
	_recovery.bind(_party.party, null, null)

	_death = DEATH.new()
	_death.name = "PlayerDeath"
	_death.world_path = NodePath()
	_death.home_path = NodePath()
	_death.save_director_path = NodePath()
	_root.add_child(_death)
	_death.bind(_player, STARTED_AT)


func after_each() -> void:
	if _root != null:
		_root.free()
		_root = null


func _fill_the_bag() -> void:
	_bag.add("wood", 30)
	_bag.add("stone", 12)
	_bag.add("axe", 1)


func _kill() -> void:
	_player.global_position = FELL_AT
	_death.die()


# --- one death ---------------------------------------------------------------

func test_dying_drops_the_carried_inventory_where_you_fell() -> void:
	_fill_the_bag()
	_kill()
	assert_eq(_satchels.count(), 1)
	var satchel: RefCounted = _satchels.at(0)
	assert_eq(satchel.where, FELL_AT, "the satchel is not where the trainer fell")
	assert_eq(satchel.count(), 3, "three stacks were carried and this many fell")
	assert_eq(_bag.inventory().used_slots(), 0, "the trainer kept their things after dying")


func test_the_satchel_keeps_the_wear_on_the_axe() -> void:
	_bag.add("axe", 1)
	_bag.use_tool(0, 47)
	var worn_to: int = int(_bag.at(0).durability)
	_kill()
	var stack: RefCounted = (_satchels.at(0) as RefCounted).stacks()[0]
	assert_eq(str(stack.item_id), "axe")
	assert_eq(int(stack.durability), worn_to, "the satchel repaired the axe on the way down")


func test_you_wake_up_where_you_started_when_there_is_no_bed() -> void:
	# §20 makes the bed the respawn point and §22 does not say what happens without
	# one. Waking where the journey began is the only other place that is the
	# player's; waking where you died is waking in the jaws of whatever killed you.
	_kill()
	var woke: Vector3 = _player.global_position
	assert_almost_eq(woke.x, STARTED_AT.x, 0.001)
	assert_almost_eq(woke.z, STARTED_AT.z, 0.001)
	assert_true(woke.y >= STARTED_AT.y, "the trainer woke up underground")
	assert_ne(woke, FELL_AT, "the trainer woke up where they died")


func test_you_wake_up_at_the_bed_when_there_is_one() -> void:
	# `home.respawn_point()` is the seam and it has existed since M6 waiting for
	# this. A stand-in stands in for it here: what is under test is that death
	# ASKS, not what `home.gd` answers.
	var home := _FakeHome.new()
	home.name = "Home"
	home.point = Vector3(-40.0, 3.0, 18.0)
	_root.add_child(home)
	_death.home_path = NodePath("../Home")
	_kill()
	assert_almost_eq(_player.global_position.x, -40.0, 0.001)
	assert_almost_eq(_player.global_position.z, 18.0, 0.001)


func test_waking_up_costs_health_but_never_all_of_it() -> void:
	_player.vitals.configure({})
	_player.vitals.health = 0.0
	_kill()
	assert_true(_player.vitals.health > 0.0, "the trainer woke up dead")
	assert_true(_player.vitals.health < _player.vitals.max_health,
		"dying cost nothing at all")
	assert_false(_player.vitals.is_dead())


func test_a_meal_does_not_survive_the_death_it_did_not_prevent() -> void:
	_player.vitals.configure({})
	_player.vitals.eat("berries", {"seconds": 300.0, "max_health": 12.0})
	assert_true(_player.vitals.is_fed())
	_kill()
	assert_false(_player.vitals.is_fed(), "the buff outlived the trainer")


# --- more than one death ------------------------------------------------------

func test_a_second_death_does_not_touch_the_first_satchel() -> void:
	# THE HARD RULE. CLAUDE.md: "Multiple death satchels persist." The way this
	# breaks is a field that holds one satchel instead of a list, and the symptom
	# is a player walking to a marker for a bag that was silently replaced.
	_bag.add("wood", 10)
	_kill()
	var first: RefCounted = _satchels.at(0)
	var first_where: Vector3 = first.where

	_bag.add("stone", 5)
	_player.global_position = Vector3(-200.0, 1.0, 200.0)
	_death.die()

	assert_eq(_satchels.count(), 2, "the second death replaced the first satchel")
	assert_eq(_satchels.at(0), first, "the first satchel is not the first satchel any more")
	assert_eq((_satchels.at(0) as RefCounted).where, first_where, "an old satchel moved")
	assert_eq(int((_satchels.at(0) as RefCounted).items.count_of("wood")), 10)
	assert_eq(int((_satchels.at(1) as RefCounted).items.count_of("stone")), 5)
	assert_ne(int((_satchels.at(0) as RefCounted).id), int((_satchels.at(1) as RefCounted).id))


func test_dying_with_nothing_still_leaves_a_marker() -> void:
	# "Where did I die" is a question worth answering even when the answer is not
	# worth carrying home.
	_kill()
	assert_eq(_satchels.count(), 1)
	assert_true((_satchels.at(0) as RefCounted).is_empty())


# --- the party ----------------------------------------------------------------

func test_no_xp_and_no_level_is_lost() -> void:
	# §22, in as many words: "no XP loss, no level loss". §16 adds "no pal loss".
	var pal: RefCounted = SPECIES.spawn(_a_species())
	pal.set_level(7)
	pal.grant_xp(25.0)
	assert_true(bool(_party.add(pal)))
	var level_before: int = int(pal.level)
	var xp_before: float = float(pal.xp)
	var hp_before: float = float(pal.hp)

	_kill()

	assert_eq(_party.size(), 1, "a pal was lost when the trainer died")
	assert_eq(int(pal.level), level_before, "dying cost the pal a level")
	assert_almost_eq(float(pal.xp), xp_before, 0.001, "dying cost the pal xp")
	# §16: "preserve their damage/fainted state as appropriate". Going home is a
	# lie-down, not a heal — the bed does the healing, over time.
	assert_almost_eq(float(pal.hp), hp_before, 0.001, "dying healed the party for free")


func test_the_pals_are_told_to_go_home() -> void:
	# Without a home there is nowhere to send them, and the refusal is the correct
	# answer rather than a failure — but nothing may be lost on the way.
	var pal: RefCounted = SPECIES.spawn(_a_species())
	pal.hp = pal.max_hp * 0.4
	_party.add(pal)
	_kill()
	assert_eq(_party.size(), 1)
	assert_eq(str(_recovery.last_refusal()), RECOVERY.REFUSED_NO_HOME,
		"death did not even ask recovery to take the pals home")


func _a_species() -> String:
	for id: String in SPECIES.table().keys():
		if not id.begins_with("_"):
			return id
	return ""


# --- exemptions ---------------------------------------------------------------

func test_the_exemption_list_is_honoured_when_it_is_not_empty() -> void:
	# §22: "Exact item exemptions can be tuned." The shipping list is EMPTY —
	# everything drops — and this proves the hook works so that turning it on is a
	# data edit rather than a code change.
	_fill_the_bag()
	_death._config = {"death": {"keeps": ["axe"]}}
	_kill()
	assert_eq(_bag.count_of("axe"), 1, "an exempt item fell into the satchel anyway")
	assert_eq(_bag.count_of("wood"), 0, "an item that is not exempt was kept")
	assert_eq((_satchels.at(0) as RefCounted).count(), 2)


# --- getting it back ----------------------------------------------------------

func test_looting_puts_everything_back_and_takes_the_satchel_away() -> void:
	_fill_the_bag()
	_kill()
	var satchel: RefCounted = _satchels.at(0)
	assert_eq(_satchels.loot(satchel, _bag), 3)
	assert_eq(_bag.count_of("wood"), 30)
	assert_eq(_bag.count_of("stone"), 12)
	assert_eq(_bag.count_of("axe"), 1)
	assert_eq(_satchels.count(), 0, "an emptied satchel is still on the map")


func test_looting_takes_what_fits_and_leaves_the_rest_where_it_is() -> void:
	# Partial on purpose, unlike a crafting cost: a player standing over their own
	# belongings with two free slots should get two slots' worth, not a refusal.
	_fill_the_bag()
	_kill()
	var small: RefCounted = INVENTORY.new(1)
	var satchel: RefCounted = _satchels.at(0)
	assert_eq(_satchels.loot(satchel, _SmallBag.new(small)), 1)
	assert_eq(satchel.count(), 2, "the satchel lost what would not fit")
	assert_eq(_satchels.count(), 1, "a satchel that still holds things was cleared")


func test_the_nearest_satchel_is_the_one_you_are_standing_over() -> void:
	_bag.add("wood", 1)
	_kill()
	_bag.add("stone", 1)
	_player.global_position = Vector3(300.0, 0.0, 300.0)
	_death.die()
	var near: RefCounted = _satchels.nearest(Vector3(301.0, 0.0, 300.0), 5.0)
	assert_ne(near, null)
	assert_eq(int(near.items.count_of("stone")), 1)
	assert_eq(_satchels.nearest(Vector3(0.0, 0.0, 0.0), 5.0), null,
		"a satchel was reachable from the other side of the meadow")


# --- persistence --------------------------------------------------------------

func test_satchels_survive_a_save_and_a_load() -> void:
	# smoke_persistence is what proves the game's own lifecycle writes this; what
	# is under test here is the record itself. A satchel that does not come back
	# has EATEN the player's inventory, which is worse than never dropping one.
	_fill_the_bag()
	_bag.use_tool(_slot_of("axe"), 33)
	var worn_to: int = int(_bag.at(_slot_of("axe")).durability)
	_kill()
	_bag.add("fiber", 4)
	_player.global_position = Vector3(-88.0, 2.0, 15.0)
	_death.die()

	var record: Dictionary = _satchels.save_data()
	var second: Node3D = SATCHELS.new()
	second.world_path = NodePath()
	second.player_path = NodePath()
	_root.add_child(second)
	second._ready()
	second.load_data(record)

	assert_eq(second.count(), 2, "both satchels did not come back")
	assert_eq((second.at(0) as RefCounted).where, FELL_AT)
	assert_eq(int((second.at(0) as RefCounted).items.count_of("wood")), 30)
	assert_eq(int((second.at(1) as RefCounted).items.count_of("fiber")), 4)
	var axe: RefCounted = _find(second.at(0) as RefCounted, "axe")
	assert_ne(axe, null, "the axe did not come back")
	assert_eq(int(axe.durability), worn_to, "the save file polished the axe")


func test_a_restored_satchel_keeps_its_id_so_the_next_one_is_new() -> void:
	_bag.add("wood", 1)
	_kill()
	var record: Dictionary = _satchels.save_data()
	var second: Node3D = SATCHELS.new()
	second.world_path = NodePath()
	second.player_path = NodePath()
	_root.add_child(second)
	second._ready()
	second.load_data(record)
	var restored_id: int = int((second.at(0) as RefCounted).id)
	var fresh: RefCounted = second.drop(Vector3.ZERO, [STACK.create("stone", 1)])
	assert_ne(int(fresh.id), restored_id, "a new satchel took a restored satchel's id")
	assert_eq(second.count(), 2)


func _slot_of(item_id: String) -> int:
	for i in _bag.slot_count():
		var stack: RefCounted = _bag.at(i)
		if stack != null and str(stack.item_id) == item_id:
			return i
	return -1


func _find(satchel: RefCounted, item_id: String) -> RefCounted:
	for entry: Variant in satchel.stacks():
		if str((entry as RefCounted).item_id) == item_id:
			return entry as RefCounted
	return null


## A trainer, as far as `death.gd` is concerned: somewhere to stand and a set of
## vitals. Deliberately not a `Node3D` — see `before_each`.
class _FakeTrainer extends Node:
	signal died()

	var global_position: Vector3 = Vector3.ZERO
	var vitals: RefCounted = preload("res://scripts/player/player_vitals.gd").new()


## A stand-in for `home.gd`: the one question death asks it.
class _FakeHome extends Node:
	var point: Vector3 = Vector3.INF

	func respawn_point() -> Vector3:
		return point

	func home_point() -> Vector3:
		return point

	func is_at_home(_where: Vector3) -> bool:
		return true


## A bag with one slot, to prove a partial loot. `loot()` needs something with
## `place()`; this is the smallest thing that has one.
class _SmallBag extends RefCounted:
	var _items: RefCounted = null

	func _init(items: RefCounted) -> void:
		_items = items

	func place(stack: RefCounted, index: int = -1) -> bool:
		return bool(_items.place(stack, index))
