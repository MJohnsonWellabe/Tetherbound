extends "res://tests/test_case.gd"

## Chopping, mining and foraging: what the meadow gives up, and what it costs.
##
## Three halves:
##
##   1. THE DATA. Every harvestable kind yields a real item to a real tool, and
##      nothing yields anything that came off a creature.
##   2. THE WORLD. `harvestable.gd` — the spatial index, the tool rules, the
##      deplete/regrow cycle, and the save round trip. Driven with hand-placed
##      props via `add_prop()` rather than with a real scatter, because
##      `run_tests.gd` works inside `SceneTree._init()` where nothing is in the
##      tree and no MultiMesh has been built. The MultiMesh path itself is
##      exercised here too, with a MultiMeshInstance3D built by hand — that is
##      the one piece of this that cannot be checked any other way.
##   3. THE TOOL. `tools.gd` — the cycle, the durability, and the two refusals
##      that matter: no inventory, and a bag too full to hold what the swing
##      produced.

const HARVEST := preload("res://scripts/world/harvestable.gd")
const TOOLS := preload("res://scripts/items/tools.gd")
const INVENTORY := preload("res://scripts/items/inventory.gd")
const DEFS := preload("res://scripts/items/item_defs.gd")
const SPECIES := preload("res://scripts/pals/pal_species.gd")

## A stand-in trainer with nothing on them: something with a transform to face
## away from. `tools.gd` takes a Node3D and asks it for a forward vector; it
## never asks it anything else, which is why this is four lines rather than a
## player. This one carries no inventory at all, which is the case the refusal
## test needs.
class Stander extends Node3D:
	pass


## A trainer that carries something. The other half of the duck-typed surface the
## brief fixes: a player node with an `inventory()` accessor.
class TrainerWithBag extends Node3D:
	var bag: RefCounted = null

	func inventory() -> RefCounted:
		return bag


var _built: Array[Node] = []


func after_each() -> void:
	for node: Node in _built:
		if is_instance_valid(node):
			node.free()
	_built.clear()


func _world() -> Node3D:
	var node: Node3D = HARVEST.new()
	_built.append(node)
	return node


func _bag(contents: Dictionary = {}) -> RefCounted:
	var bag: RefCounted = INVENTORY.new()
	for item: String in contents.keys():
		bag.add(item, int(contents[item]))
	return bag


func _kinds() -> Dictionary:
	var entries: Variant = HARVEST.config().get("kinds", {})
	var out: Dictionary = {}
	if entries is Dictionary:
		for name: String in (entries as Dictionary).keys():
			if not name.begins_with("_"):
				out[name] = (entries as Dictionary)[name]
	return out


## Reaching the two systems under test through `call`, because neither has a
## `class_name` (project rule) and both are therefore only statically known as
## `Node`. Wrapping them here keeps the tests below readable as statements about
## chopping rather than about dispatch.

func _add(world: Node, kind: String, at: Vector3) -> void:
	world.call("add_prop", kind, at)


func _swing(world: Node, at: Vector3, tool_id: String) -> Dictionary:
	return world.call("harvest", at, tool_id)


func _look(world: Node, at: Vector3) -> Dictionary:
	return world.call("inspect", at)


func _batch(scatter: Node3D, model: String, at: Array) -> MultiMesh:
	var node := MultiMeshInstance3D.new()
	node.name = model
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = BoxMesh.new()
	multi.instance_count = at.size()
	for i in at.size():
		multi.set_instance_transform(i, Transform3D(Basis.IDENTITY, at[i] as Vector3))
	node.multimesh = multi
	scatter.add_child(node)
	return multi


# --- the data ---------------------------------------------------------------

func test_the_four_materials_all_come_from_somewhere() -> void:
	# M8: "Wood, Stone, Fiber, Berries". A material with no source is a material
	# the player can only ever have been given, and three of these are build
	# costs.
	var yielded: Array[String] = []
	for name: String in _kinds().keys():
		var item := str((_kinds()[name] as Dictionary).get("yields", ""))
		if not yielded.has(item):
			yielded.append(item)
	for material: String in ["wood", "stone", "fiber", "berries"]:
		assert_true(yielded.has(material), "nothing in the meadow yields %s" % material)


func test_every_kind_yields_a_real_item_to_a_real_tool() -> void:
	var checked := 0
	for name: String in _kinds().keys():
		var kind: Dictionary = _kinds()[name]
		assert_true(DEFS.has(str(kind.get("yields", ""))),
			"'%s' yields '%s', which is not an item" % [name, kind.get("yields", "")])
		var tool_id := str(kind.get("tool", ""))
		if tool_id != "":
			assert_true(DEFS.is_tool_item(tool_id),
				"'%s' wants '%s', which is not a tool" % [name, tool_id])
		assert_true(int(kind.get("amount", 0)) > 0, "'%s' yields nothing per swing" % name)
		assert_true(int(kind.get("uses", 0)) > 0, "'%s' has no swings in it" % name)
		assert_true(float(kind.get("regrow", 0.0)) > 0.0, "'%s' never comes back" % name)
		checked += 1
	assert_true(checked >= 4, "M8 wants a handful of kinds, not one")


func test_nothing_is_harvested_from_a_creature() -> void:
	# CLAUDE.md: "No hunting/butchering." GAME_DESIGN.md §19: "Do not create a
	# meat/leather economy that assumes killing pals/wildlife." A harvest table is
	# where that would arrive first and most innocently.
	var forbidden := ["meat", "hide", "leather", "bone", "pelt", "fur", "sinew"]
	for name: String in _kinds().keys():
		var kind: Dictionary = _kinds()[name]
		var item := str(kind.get("yields", ""))
		for word: String in forbidden:
			assert_false(item.contains(word), "'%s' yields '%s'" % [name, item])
			assert_false(name.contains(word), "there is a harvestable kind called '%s'" % name)
		assert_false(SPECIES.has(item), "'%s' yields a creature" % name)
		for model: Variant in kind.get("models", []):
			assert_false(SPECIES.has(str(model).to_lower()),
				"'%s' harvests a creature model" % name)


func test_a_tool_is_an_upgrade_where_it_can_be_and_a_key_where_it_must_be() -> void:
	# The design decision, pinned. Bushes have a bare-handed fallback so the
	# recipe chain is not deadlocked behind a knife you need fiber to make;
	# trees and boulders do not, because punching a tree is the cliche this
	# design does not want and because durability only means something if the
	# tool is the only way in.
	var bush: Dictionary = _kinds()["bush"]
	assert_eq(str(bush.get("tool", "")), "knife")
	assert_true(bush.has("hand_amount"), "fiber must be reachable before the knife exists")
	assert_true(int(bush["amount"]) > int(bush["hand_amount"]),
		"a knife must be worth crafting")

	for gated: String in ["tree", "rock"]:
		assert_false((_kinds()[gated] as Dictionary).has("hand_amount"),
			"'%s' must need its tool" % gated)
		assert_true(int((_kinds()[gated] as Dictionary).get("durability", 0)) > 0,
			"'%s' must wear the tool out" % gated)


func test_an_empty_handed_trainer_can_reach_the_first_workbench() -> void:
	# The bootstrap, and the thing that would break silently: if nothing at all
	# were hand-gatherable, a new game would be unwinnable and every test above
	# would still pass.
	var by_hand: Array[String] = []
	for name: String in _kinds().keys():
		if str((_kinds()[name] as Dictionary).get("tool", "")) == "":
			by_hand.append(str((_kinds()[name] as Dictionary).get("yields", "")))
	assert_true(by_hand.has("wood"), "there must be wood a bare hand can take")
	assert_true(by_hand.has("stone"), "there must be stone a bare hand can take")


# --- the world --------------------------------------------------------------

func test_a_swing_at_empty_air_finds_nothing() -> void:
	var world := _world()
	_add(world, "tree", Vector3(50.0, 0.0, 50.0))
	var result := _swing(world, Vector3.ZERO, "axe")
	assert_false(bool(result["ok"]))
	assert_eq(str(result["refusal"]), HARVEST.REFUSED_NOTHING)


func test_a_tree_gives_wood_to_an_axe() -> void:
	var world := _world()
	_add(world, "tree", Vector3(2.0, 0.0, 0.0))
	var result := _swing(world, Vector3(2.0, 0.0, 0.0), "axe")
	assert_true(bool(result["ok"]))
	assert_eq(str(result["item"]), "wood")
	assert_true(int(result["count"]) > 0)
	assert_true(int(result["durability"]) > 0, "chopping must wear the axe")


func test_a_rock_gives_stone_to_a_pickaxe_and_refuses_an_axe() -> void:
	var world := _world()
	_add(world, "rock", Vector3.ZERO)
	assert_true(bool(_swing(world, Vector3.ZERO, "pickaxe")["ok"]))
	var wrong := _swing(world, Vector3.ZERO, "axe")
	assert_false(bool(wrong["ok"]))
	assert_eq(str(wrong["refusal"]), HARVEST.REFUSED_WRONG_TOOL)


func test_bare_hands_on_a_tree_are_told_what_is_needed() -> void:
	# Two different refusals on purpose: "you need an axe" and "that is the wrong
	# tool for this" are different sentences on screen, and a HUD with one token
	# for both could only ever say the vaguer one.
	var world := _world()
	_add(world, "tree", Vector3.ZERO)
	var empty := _swing(world, Vector3.ZERO, "")
	assert_false(bool(empty["ok"]))
	assert_eq(str(empty["refusal"]), HARVEST.REFUSED_NEEDS_TOOL)
	assert_eq(str(empty["tool"]), "axe", "the refusal must name the tool")


func test_a_bush_gives_less_to_bare_hands_than_to_a_knife() -> void:
	var world := _world()
	_add(world, "bush", Vector3.ZERO)
	var handful := _swing(world, Vector3.ZERO, "")
	assert_true(bool(handful["ok"]), "a bush must be strippable by hand")
	assert_eq(str(handful["item"]), "fiber")
	assert_eq(int(handful["durability"]), 0, "bare hands wear nothing out")

	var second := _world()
	_add(second, "bush", Vector3.ZERO)
	var cut := _swing(second, Vector3.ZERO, "knife")
	assert_true(int(cut["count"]) > int(handful["count"]), "the knife must be worth having")


func test_a_berry_bush_gives_berries_to_nobody_in_particular() -> void:
	var world := _world()
	_add(world, "berry_bush", Vector3(1.0, 0.0, 1.0))
	var result := _swing(world, Vector3(1.0, 0.0, 1.0), "")
	assert_true(bool(result["ok"]))
	assert_eq(str(result["item"]), "berries")


func test_a_prop_runs_out_and_says_so() -> void:
	# The gathering model: DEPLETE, not vanish and not infinite. A tree with no
	# end is a tree the player never leaves; a forest that disappears is a meadow
	# that thins out over a session and never recovers.
	var world := _world()
	_add(world, "tree", Vector3.ZERO)
	var uses := int((_kinds()["tree"] as Dictionary)["uses"])
	for i in uses:
		assert_true(bool(_swing(world, Vector3.ZERO, "axe")["ok"]),
			"swing %d of %d should have landed" % [i + 1, uses])
	var spent := _swing(world, Vector3.ZERO, "axe")
	assert_false(bool(spent["ok"]))
	assert_eq(str(spent["refusal"]), HARVEST.REFUSED_SPENT)


func test_a_spent_prop_comes_back_after_its_own_time() -> void:
	var world := _world()
	_add(world, "pebble", Vector3.ZERO)
	assert_true(bool(_swing(world, Vector3.ZERO, "")["ok"]))
	assert_false(bool(_swing(world, Vector3.ZERO, "")["ok"]))

	var regrow := float((_kinds()["pebble"] as Dictionary)["regrow"])
	world.tick(regrow * 0.5)
	assert_false(bool(_swing(world, Vector3.ZERO, "")["ok"]), "half a regrow is not a regrow")
	assert_eq(int(world.tick(regrow)), 1, "the prop should come back")
	assert_true(bool(_swing(world, Vector3.ZERO, "")["ok"]))


func test_regrowth_costs_nothing_when_nothing_is_spent() -> void:
	# The per-frame cost of the whole system, asserted: the tick walks the SPENT
	# list, not the meadow. With 2,500 props indexed and none of them worked, this
	# is a single `is_empty()`.
	var world := _world()
	for i in 40:
		_add(world, "tree", Vector3(float(i) * 8.0, 0.0, 0.0))
	assert_eq(int(world.tick(1.0)), 0)
	assert_eq(int(world.count()), 40)


func test_the_index_finds_the_nearest_prop_and_not_a_far_one() -> void:
	var world := _world()
	_add(world, "tree", Vector3.ZERO)
	_add(world, "rock", Vector3(30.0, 0.0, 30.0))
	# A swing between them reaches neither: the reach is short on purpose, so you
	# chop what you are standing at.
	assert_eq(str(_swing(world, Vector3(15.0, 0.0, 15.0), "axe")["refusal"]), HARVEST.REFUSED_NOTHING)
	assert_eq(str(_swing(world, Vector3(0.5, 0.0, 0.5), "axe")["kind"]), "tree")
	assert_eq(str(_swing(world, Vector3(30.0, 0.0, 30.5), "pickaxe")["kind"]), "rock")


func test_looking_at_something_changes_nothing() -> void:
	# What an interaction prompt calls, every frame. If it could deplete a prop,
	# standing still would strip the meadow.
	var world := _world()
	_add(world, "tree", Vector3.ZERO)
	for i in 5:
		var seen := _look(world, Vector3.ZERO)
		assert_eq(str(seen["display_name"]), "Tree")
		assert_false(bool(seen["spent"]))
	assert_true(bool(_swing(world, Vector3.ZERO, "axe")["ok"]),
		"looking must not have used the tree up")


func test_a_swing_with_nowhere_to_put_the_wood_is_undone() -> void:
	# `put_back`. A full bag must cost the player a walk, not the prop.
	var world := _world()
	_add(world, "pebble", Vector3.ZERO)
	var taken := _swing(world, Vector3.ZERO, "")
	assert_true(bool(taken["ok"]))
	assert_true(bool(_look(world, Vector3.ZERO)["spent"]))
	assert_true(bool(world.put_back(taken)))
	assert_false(bool(_look(world, Vector3.ZERO)["spent"]), "the prop must be as it was")
	assert_true(bool(_swing(world, Vector3.ZERO, "")["ok"]))


# --- the MultiMesh, which is the whole difficulty ---------------------------
##
## AND THE LIMIT OF WHAT A HEADLESS TEST CAN SAY ABOUT IT. Under `--headless`
## Godot runs the DUMMY renderer: `MultiMesh.set_instance_transform()` is accepted
## and discarded, `get_instance_transform()` hands back the identity, and `buffer`
## is empty. So the position of a prop in a real batch is simply not knowable from
## this suite, and pretending otherwise would be a green test over a system that
## could be indexing every tree in the meadow onto the world origin.
##
## What IS checked here: that a batch is classified by the model it draws, that
## the batches nobody harvests are skipped, and — the important one — that a batch
## whose instance data cannot be read is DROPPED LOUDLY rather than heaped on the
## origin. The positions themselves are a rendered-session question, the same
## family of thing D06 records about frame timing under software rendering.

func test_a_batch_is_classified_by_the_model_it_draws() -> void:
	# A batch node is named after the model it draws, plus a `_x_y` suffix when the
	# scatter splits a model into spatial cells for culling. That name is the only
	# identity a MultiMesh batch has, and this is the rule that reads it.
	var world := _world()
	assert_eq(str(world.kind_of_batch("CommonTree_3_0_0")), "tree")
	assert_eq(str(world.kind_of_batch("TwistedTree_2")), "tree")
	assert_eq(str(world.kind_of_batch("Rock_Medium_1_-4_7")), "rock")
	assert_eq(str(world.kind_of_batch("Pebble_Round_2")), "pebble")
	assert_eq(str(world.kind_of_batch("DeadTree_3_1_1")), "deadfall")


func test_a_batch_of_something_nobody_harvests_is_skipped_entirely() -> void:
	# Grass alone is over 60,000 instances. Indexing it would multiply the spatial
	# hash by twenty-five to sell fiber that bushes already sell better, and this is
	# the rule that keeps it out. Architecture and path stones are out for the more
	# obvious reason.
	var world := _world()
	for ignored: String in [
		"Grass_Common_Short_2_2", "Grass_Wispy_Tall", "Flower_3_Group", "Clover_1",
		"RockPath_Round_Wide", "Wall_Plaster_Straight", "Mushroom_Common",
	]:
		assert_eq(str(world.kind_of_batch(ignored)), "",
			"'%s' must not be a resource" % ignored)


func test_a_berry_bush_batch_is_not_read_as_a_plain_bush() -> void:
	# `Bush_Common` is a prefix of `Bush_Common_Flowers`. Matching shortest-first
	# would turn every berry bush in the meadow into a fiber bush, which would look
	# exactly like a content decision rather than like a bug. Longest name wins.
	var world := _world()
	assert_eq(str(world.kind_of_batch("Bush_Common_Flowers_1_-2")), "berry_bush")
	assert_eq(str(world.kind_of_batch("Bush_Common_4_4")), "bush")
	assert_eq(str(world.kind_of_batch("Plant_1_Big")), "bush")
	assert_eq(str(world.kind_of_batch("Plant_1")), "bush")


func test_a_batch_whose_transforms_cannot_be_read_is_dropped_loudly() -> void:
	# THE BUG THIS EXISTS TO PREVENT, and it was found by writing the naive version
	# first: under `--headless` Godot runs the DUMMY renderer, which accepts
	# `set_instance_transform()` and discards it, hands back the identity from
	# `get_instance_transform()`, and leaves `buffer` empty. An indexer that trusted
	# those reads put every prop in the meadow on the world origin — which looks
	# exactly like a working meadow with infinite wood at the spawn point.
	#
	# So a batch that will not give up its buffer is worth nothing and is counted as
	# nothing. This test passes in both worlds and says which one it is in.
	var scatter := Node3D.new()
	_built.append(scatter)
	var at: Array = []
	for i in 6:
		at.append(Vector3(float(i) * 10.0, 0.0, 0.0))
	var multi := _batch(scatter, "CommonTree_1_0_0", at)
	var readable := multi.buffer.size() >= multi.instance_count * 12

	var world := _world()
	world.bind(scatter)
	if readable:
		# A rendered session: six trees, where they were put.
		assert_eq(int(world.count()), 6)
		assert_true(bool(world.transforms_readable()))
		assert_eq(str(_swing(world, Vector3(20.0, 0.0, 0.0), "axe")["kind"]), "tree")
	else:
		# Headless, which is how this suite always runs.
		assert_eq(int(world.count()), 0, "an unreadable batch must index nothing at all")
		assert_false(bool(world.transforms_readable()),
			"and the world must be able to say that is what happened")
		assert_eq(str(_swing(world, Vector3(20.0, 0.0, 0.0), "axe")["refusal"]),
			HARVEST.REFUSED_NO_SCATTER)


func test_a_prop_that_still_has_a_collider_is_never_hidden() -> void:
	# The rule, and why it is observed from the world rather than configured:
	# hiding the mesh of something that still has a collision shape leaves an
	# INVISIBLE WALL, which is a worse bug than a tree that is visibly still there.
	# So a spent bush disappears and a spent tree stays standing, and which is which
	# is decided by what the scatter actually put there.
	#
	# Asserted on the DECISION rather than on the pixels, because the pixels need a
	# renderer — see the note at the top of this section.
	var bare := Node3D.new()
	_built.append(bare)
	var loose := _world()
	loose.bind(bare)
	_add(loose, "bush", Vector3.ZERO)
	assert_eq(int(loose.count()), 1)
	assert_false(bool(loose.collides_at(Vector3.ZERO)),
		"a bush has no collision in the scatter and may be hidden while it is spent")

	var walled := Node3D.new()
	_built.append(walled)
	var body := StaticBody3D.new()
	walled.add_child(body)
	var shape := CollisionShape3D.new()
	shape.shape = CylinderShape3D.new()
	# The scatter puts a trunk cylinder at the prop's XZ, lifted to half its own
	# height. Matching is on XZ alone for exactly that reason.
	shape.position = Vector3(0.0, 2.0, 0.0)
	body.add_child(shape)

	var solid := _world()
	solid.bind(walled)
	_add(solid, "tree", Vector3.ZERO)
	assert_true(bool(solid.collides_at(Vector3.ZERO)),
		"a tree with a trunk collider must be found to have one, or hiding it leaves a wall")
	_add(solid, "tree", Vector3(20.0, 0.0, 0.0))
	assert_false(bool(solid.collides_at(Vector3(20.0, 0.0, 0.0))),
		"and a prop nowhere near that collider must not be credited with it")


# --- the save round trip ----------------------------------------------------

func test_an_untouched_meadow_saves_nothing() -> void:
	# The props are CONTENT: the scatter is deterministic and comes back identical
	# every boot, so writing 2,500 untouched trees into every save would be 2,500
	# lines saying "still a tree".
	var world := _world()
	for i in 20:
		_add(world, "tree", Vector3(float(i) * 9.0, 0.0, 0.0))
	assert_eq((world.save_data()["worked"] as Array).size(), 0)


func test_a_worked_tree_comes_back_worked() -> void:
	var before := _world()
	_add(before, "tree", Vector3(4.0, 0.0, -8.0))
	_swing(before, Vector3(4.0, 0.0, -8.0), "axe")
	_swing(before, Vector3(4.0, 0.0, -8.0), "axe")
	var data: Dictionary = before.save_data()
	assert_eq((data["worked"] as Array).size(), 1, "a half-chopped tree is worth saving")

	# The load arrives BEFORE the world exists, which is the real ordering: the
	# save director restores a frame after boot and the scatter is built across
	# several awaited frames after that.
	var after := _world()
	after.load_data(data)
	_add(after, "tree", Vector3(4.0, 0.0, -8.0))
	var uses := int((_kinds()["tree"] as Dictionary)["uses"])
	var landed := 0
	while bool(_swing(after, Vector3(4.0, 0.0, -8.0), "axe")["ok"]):
		landed += 1
	assert_eq(landed, uses - 2, "the reloaded tree must have two swings missing")


func test_a_spent_prop_comes_back_spent_with_its_timer() -> void:
	var before := _world()
	_add(before, "berry_bush", Vector3.ZERO)
	_swing(before, Vector3.ZERO, "")
	before.tick(30.0)
	var data: Dictionary = before.save_data()

	var after := _world()
	after.load_data(data)
	_add(after, "berry_bush", Vector3.ZERO)
	assert_true(bool(_look(after, Vector3.ZERO)["spent"]), "a picked bush must come back picked")
	var left := float(_look(after, Vector3.ZERO)["regrow_left"])
	var full := float((_kinds()["berry_bush"] as Dictionary)["regrow"])
	assert_between(left, full - 31.0, full - 29.0, "and with its timer where it was")


func test_saved_depletion_for_a_prop_that_is_gone_is_dropped_not_kept() -> void:
	# A save written against a different scatter seed. The honest outcome is a
	# meadow that is fully grown, not an invisible bookkeeping entry that can never
	# be cleared.
	var world := _world()
	world.load_data({"worked": [{"at": "9999,9999", "kind": "tree", "left": 0, "regrow": 100.0}]})
	_add(world, "tree", Vector3.ZERO)
	assert_true(bool(_swing(world, Vector3.ZERO, "axe")["ok"]),
		"a stale save entry must not empty a tree that has nothing to do with it")
	assert_eq((world.save_data()["worked"] as Array).size(), 1,
		"and only the tree actually worked should be written back")


# --- the tool ---------------------------------------------------------------

## A trainer holding `bag`, with a tool kit wired to `world`. The kit is a child
## of the trainer so freeing one frees both.
func _rig(bag: RefCounted, world: Node) -> Node:
	var trainer := TrainerWithBag.new()
	trainer.bag = bag
	_built.append(trainer)
	var kit: Node = TOOLS.new()
	trainer.add_child(kit)
	kit.call("bind", trainer, world)
	return kit


func test_a_swing_with_no_inventory_is_refused_rather_than_swallowed() -> void:
	# The brief for the trainer's inventory: if it is absent at runtime, refuse the
	# action and say why — never silently succeed, and never fall back to an
	# inventory of your own.
	var world := _world()
	_add(world, "pebble", Vector3.ZERO)
	var trainer := Stander.new()
	_built.append(trainer)
	var kit: Node = TOOLS.new()
	trainer.add_child(kit)
	kit.call("bind", trainer, world)

	var result: Dictionary = kit.call("swing", Vector3.ZERO)
	assert_false(bool(result["ok"]))
	assert_eq(str(result["refusal"]), TOOLS.REFUSED_NO_INVENTORY)
	assert_false(bool(_look(world, Vector3.ZERO)["spent"]),
		"a refused swing must not have taken the stone")


func test_a_swing_puts_the_yield_in_the_bag_and_wears_the_tool() -> void:
	var world := _world()
	_add(world, "tree", Vector3.ZERO)
	var bag := _bag({"axe": 1})
	var kit := _rig(bag, world)
	assert_true(bool(kit.call("equip", "axe")))

	var slot := int(kit.call("equipped_slot"))
	var full := int((bag.at(slot) as RefCounted).durability)
	var result: Dictionary = kit.call("swing", Vector3.ZERO)
	assert_true(bool(result["ok"]))
	assert_eq(bag.count_of("wood"), 3, "the wood must end up in the bag")
	assert_true(int((bag.at(slot) as RefCounted).durability) < full,
		"the swing must have cost the axe something")


func test_bare_hands_wear_nothing_out() -> void:
	var world := _world()
	_add(world, "berry_bush", Vector3.ZERO)
	var bag := _bag({"axe": 1})
	var kit := _rig(bag, world)
	var full := int((bag.at(0) as RefCounted).durability)
	assert_eq(str(kit.call("equipped")), TOOLS.HANDS, "a trainer starts empty-handed")
	assert_true(bool((kit.call("swing", Vector3.ZERO) as Dictionary)["ok"]))
	assert_eq(bag.count_of("berries"), 3)
	assert_eq(int((bag.at(0) as RefCounted).durability), full, "the axe was not even out")


func test_a_broken_tool_will_not_swing() -> void:
	# §19 wants durability to be a real cost, and a broken axe that keeps chopping
	# is not one. Broken, NOT destroyed — the axe keeps its slot and the workbench
	# mends it for free.
	var world := _world()
	_add(world, "tree", Vector3.ZERO)
	var bag := _bag({"axe": 1})
	var kit := _rig(bag, world)
	kit.call("equip", "axe")
	var axe: RefCounted = bag.at(0)
	axe.use(axe.max_durability())

	var result: Dictionary = kit.call("swing", Vector3.ZERO)
	assert_false(bool(result["ok"]))
	assert_eq(str(result["refusal"]), TOOLS.REFUSED_TOOL_BROKEN)
	assert_eq(bag.count_of("wood"), 0)
	assert_eq(bag.count_of("axe"), 1, "a broken axe is still an axe")


func test_a_full_bag_costs_a_walk_and_not_the_prop() -> void:
	var world := _world()
	_add(world, "pebble", Vector3.ZERO)
	# One slot, already full of something else.
	var bag: RefCounted = INVENTORY.new(1)
	bag.add("wood", DEFS.stack_limit("wood"))
	var kit := _rig(bag, world)

	var result: Dictionary = kit.call("swing", Vector3.ZERO)
	assert_false(bool(result["ok"]))
	assert_eq(str(result["refusal"]), TOOLS.REFUSED_BAG_FULL)
	assert_false(bool(_look(world, Vector3.ZERO)["spent"]), "the stone must still be lying there")


func test_the_cycle_walks_hands_and_every_tool_in_the_bag() -> void:
	# §19: "quick tool selection". `tool_cycle` has been bound in project.godot
	# since M0 and was read by nothing until now.
	var bag := _bag({"axe": 1, "pickaxe": 1, "wood": 20})
	var kit := _rig(bag, _world())
	var order: Array = kit.call("hand_cycle")
	assert_eq(str(order[0]), TOOLS.HANDS, "hands are a real position in the wheel")
	assert_true(order.has("axe") and order.has("pickaxe"))
	assert_false(order.has("wood"), "wood is not a tool")

	assert_eq(str(kit.call("cycle", 1)), str(order[1]))
	assert_eq(str(kit.call("cycle", 1)), str(order[2]))
	assert_eq(str(kit.call("cycle", 1)), TOOLS.HANDS, "the wheel must come back round")


func test_equipping_a_tool_the_trainer_does_not_own_is_refused() -> void:
	var kit := _rig(_bag({"wood": 5}), _world())
	assert_false(bool(kit.call("equip", "axe")), "the HUD must not draw an axe nobody owns")
	assert_eq(str(kit.call("equipped")), TOOLS.HANDS)


func test_what_is_in_hand_survives_a_reload() -> void:
	var bag := _bag({"pickaxe": 1})
	var kit := _rig(bag, _world())
	kit.call("equip", "pickaxe")
	var data: Dictionary = kit.call("save_data")

	var other := _rig(bag, _world())
	other.call("load_data", data)
	assert_eq(str(other.call("equipped")), "pickaxe")

	# And a save naming a tool that has since gone comes back as empty hands rather
	# than as a phantom.
	var empty := _rig(_bag({}), _world())
	empty.call("load_data", data)
	assert_eq(str(empty.call("equipped")), TOOLS.HANDS)


func test_a_tool_is_never_a_weapon() -> void:
	# CLAUDE.md: "Human cannot fight." GAME_DESIGN.md §19: tools "cannot damage
	# pals or humans". The day this file grows a verb that takes a target, the hard
	# rule has been broken by whoever added it and this is where it stops.
	var kit := _rig(_bag({}), _world())
	for verb: String in ["attack", "hit", "damage", "strike", "target_pal", "aim_at"]:
		assert_false(kit.has_method(verb),
			"tools.gd has a '%s' method; the trainer cannot fight" % verb)
