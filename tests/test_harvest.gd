extends "res://tests/test_case.gd"

## R2.3: real tree/rock harvesting on the vegetation itself, not just
## harvest_node.gd's ~10 authored tutorial spots.
##
## harvest_logic.gd is the pure tool/durability gating both harvest systems
## now share; scripts/world/vegetation.gd's own selection of which SCATTERED
## instances become gather points is data-driven from vegetation.json and
## tested here directly, without paying for a full mesh-loading build().

const ITEM_DB := preload("res://autoload/item_db.gd")
const INVENTORY := preload("res://autoload/inventory.gd")
const HARVEST_LOGIC := preload("res://scripts/world/harvest_logic.gd")
const RULES := preload("res://scripts/world/scatter_rules.gd")
const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const VEGETATION := preload("res://scripts/world/vegetation.gd")
const HARVEST_NODE := preload("res://scripts/world/harvest_node.gd")

## A real authored spot from data/config/harvest.json, kept inline rather than
## re-parsed from the file: OF20's bug was specific to loading a `.gltf` model
## (a PackedScene, not a Mesh — see harvest_node.gd's own header), so the test
## below needs one of the pack's actual models, not a synthetic path.
const WOOD_SPEC := {
	"item": "wood",
	"amount": 4,
	"label": "Gather deadwood",
	"model": "res://assets/environment/stylized_nature/DeadTree_2.gltf",
	"model_scale": 0.22,
}

var db: RefCounted = null
var bag: RefCounted = null


func before_each() -> void:
	db = ITEM_DB.new()
	bag = INVENTORY.new(db)


# --- harvest_logic.gd: the shared tool/durability gate ---------------------

func test_gather_with_the_right_tool_pays_the_full_amount() -> void:
	bag.add("axe", 1)
	var result: Dictionary = HARVEST_LOGIC.gather("wood", 3, bag, db)
	assert_eq(int(result["amount"]), 3)
	assert_eq(int(result["required_slot"]), bag.find_slot("axe"))


func test_gather_bare_handed_falls_back_to_the_reduced_rate() -> void:
	var with_tool: Dictionary = HARVEST_LOGIC.gather("wood", 3, bag, db)
	bag.add("axe", 1)
	var with_axe: Dictionary = HARVEST_LOGIC.gather("wood", 3, bag, db)
	assert_true(int(with_tool["amount"]) > 0, "bare-handed must still pay something")
	assert_true(int(with_tool["amount"]) < int(with_axe["amount"]),
		"bare-handed must pay less than the right tool")
	assert_eq(int(with_tool["required_slot"]), -1, "no tool in hand, nothing to damage")


func test_gather_with_the_wrong_tool_pays_nothing() -> void:
	bag.add("pickaxe", 1)
	var result: Dictionary = HARVEST_LOGIC.gather("wood", 3, bag, db)
	assert_eq(int(result["amount"]), 0, "owning some OTHER tool must refuse, not fall back")


func test_gather_with_a_broken_required_tool_falls_back_rather_than_refusing() -> void:
	bag.add("axe", 1)
	var slot: int = bag.find_slot("axe")
	bag.damage_tool(slot, db.max_durability("axe") + 50)
	var result: Dictionary = HARVEST_LOGIC.gather("wood", 3, bag, db)
	assert_true(int(result["amount"]) > 0, "a broken axe must still pay the bare-handed rate")
	assert_eq(int(result["required_slot"]), -1, "a broken tool must not be the one that wears down")


func test_gather_of_an_untool_gated_resource_always_pays_the_full_amount() -> void:
	var result: Dictionary = HARVEST_LOGIC.gather("berries", 5, bag, db)
	assert_eq(int(result["amount"]), 5)
	assert_eq(int(result["required_slot"]), -1)


# --- OF30: the set Tam hands over --------------------------------------

## The tool gate has been correct since R2.1 and unreachable since R2.1: no
## axe, pickaxe or knife existed anywhere in the world, so "the right tool" was
## a rule the player could only ever fail. OF30 makes the blacksmith the source
## of all three. This is the yield side of that — the exact set he gives,
## against the exact resources they gate, with nothing else in the satchel.
##
## `tests/test_dialogue_runner.gd` is what checks he really gives THESE three;
## this checks that having them changes anything.
func test_the_smiths_set_covers_every_tool_gated_meadow_resource() -> void:
	const HANDOVER := {"axe": "wood", "pickaxe": "stone", "knife": "fiber"}
	for tool_id: String in HANDOVER:
		var resource: String = HANDOVER[tool_id]
		assert_eq(db.gathered_with(resource), tool_id,
			"'%s' should be gathered with '%s'" % [resource, tool_id])

		var barehanded: Dictionary = HARVEST_LOGIC.gather(resource, 4, INVENTORY.new(db), db)
		var equipped: RefCounted = INVENTORY.new(db)
		equipped.add(tool_id, 1)
		var with_tool: Dictionary = HARVEST_LOGIC.gather(resource, 4, equipped, db)

		assert_eq(int(with_tool["amount"]), 4,
			"'%s' should pay '%s' in full" % [tool_id, resource])
		assert_true(int(with_tool["amount"]) > int(barehanded["amount"]),
			"'%s' should beat bare hands on '%s'" % [tool_id, resource])
		assert_true(int(with_tool["required_slot"]) >= 0,
			"'%s' should be the tool that wears down" % tool_id)


## All three at once is the state the player is actually left in after the
## handover, and it is the state the wrong-tool rule would otherwise have
## broken. Owning a pickaxe alone pays ZERO on wood (test above), so any gap in
## the set leaves the player strictly worse off at that resource than they were
## bare-handed a minute earlier — which is why the knife is in the handover
## even though the owner named two tools. See village.json's
## `_comment_of30_knife`. This is the test that fails if it is ever taken back
## out without re-gating `fiber`.
func test_carrying_his_whole_set_gathers_everything_the_meadow_offers() -> void:
	bag.add("axe", 1)
	bag.add("pickaxe", 1)
	bag.add("knife", 1)
	for resource in ["wood", "stone", "fiber", "berries"]:
		var result: Dictionary = HARVEST_LOGIC.gather(resource, 3, bag, db)
		assert_eq(int(result["amount"]), 3,
			"carrying the smith's set, '%s' should pay in full" % resource)


## The generalisation of the case above, so a NEW tool-gated resource added
## later cannot quietly become unreachable: whatever the smith hands over must
## cover every resource in items.json that gates on a tool. Read straight off
## the dialogue data rather than restated here.
func test_nothing_the_smith_gives_leaves_a_tool_gated_resource_stranded() -> void:
	const RUNNER := preload("res://scripts/story/dialogue_runner.gd")
	var owned: RefCounted = INVENTORY.new(db)
	var conversation: Dictionary = RUNNER.table().get("village_tam_tools", {})
	for raw: Variant in (conversation.get("lines", []) as Array):
		if not raw is Dictionary:
			continue
		for effect: Variant in ((raw as Dictionary).get("effects", []) as Array):
			var parts: Array = RUNNER.parse_effect(str(effect))
			if str(parts[0]) == "give":
				owned.add(str(parts[1]).split(":")[0], 1)

	for id: Variant in db.ids():
		var resource := str(id)
		if db.gathered_with(resource).is_empty():
			continue
		var result: Dictionary = HARVEST_LOGIC.gather(resource, 2, owned, db)
		assert_eq(int(result["amount"]), 2,
			"'%s' gates on '%s', which Tam's handover does not include -- with his other tools in hand it now pays nothing at all" % [
				resource, db.gathered_with(resource)])


# --- vegetation.json data integrity ------------------------------------

func test_every_harvest_item_named_in_vegetation_json_is_a_real_tool_gated_resource() -> void:
	var layers: Dictionary = RULES.config().get("layers", {})
	for name: String in layers.keys():
		if name.begins_with("_"):
			continue
		var layer: Dictionary = layers[name]
		var item_id := str(layer.get("harvest_item", ""))
		if item_id == "":
			continue
		assert_true(not db.definition(item_id).is_empty(), "layer '%s' names a harvest_item that is not a real item: %s" % [name, item_id])
		assert_false(db.gathered_with(item_id).is_empty(),
			"layer '%s's harvest_item '%s' has no gathered_with tool; a real-world resource with no tool gate has nothing distinguishing a gathered instance from harvest_node.gd's own bare_handed rate" % [name, item_id])
		assert_between(float(layer.get("harvest_fraction", 0.0)), 0.0, 1.0,
			"layer '%s's harvest_fraction must be a fraction" % name)
		assert_true(int(layer.get("harvest_amount", 0)) > 0, "layer '%s's harvest_amount must be positive" % name)


# --- data/config/harvest.json: the authored spots themselves ---------------
#
# Nothing read this file until SD16 added the Old Quarry's Rootstone to it,
# and every failure below is silent at run time. `playground_world.gd::
# _place_harvest_nodes()` skips a node whose ground sample is NaN and warns
# about nothing else: a typo'd item id builds a prompt that hands over an item
# the satchel has never heard of, a missing model quietly falls back to the
# coloured box R9.4's blind critic named as one of the three worst assets in
# the game, and a position outside the baked world simply never appears.

const HARVEST_CONFIG := "res://data/config/harvest.json"
const ALIGNMENT := preload("res://scripts/world/terrain_region_alignment.gd")
const TERRAIN_CONFIG_FOR_BOUNDS := "res://data/config/terrain_playground.json"
## OW5D: was a hardcoded WORLD_HALF := 256.0 (a symmetric square), which the
## corridor cannot express -- z runs -512..7680, nowhere near symmetric. Reads
## the same world_bounds() the bake and its own alignment guard use, so this
## check tracks the actual authored footprint instead of a stale constant.
static func _world_bounds() -> Dictionary:
	var file := FileAccess.open(TERRAIN_CONFIG_FOR_BOUNDS, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return {}
	return ALIGNMENT.world_bounds(parsed as Dictionary)
## Two authored spots closer than this contest for the same interact prompt
## (`interactable.gd`'s own radius here is 2.4m, and the arbiter picks by
## distance) — the exact problem `playground_world.gd`'s GATE_AT comment
## records paying for once with the road gate and a berry bush.
const MIN_SPOT_SEPARATION := 4.5


## BAND-SPLIT. Through the merge, not a raw read of `harvest.json` — the `nodes`
## array is per-band now, and reading the head file would silently return an
## empty list and pass every check below.
const BAND_CONTENT := preload("res://scripts/data/band_content.gd")


func _authored_nodes() -> Array:
	return BAND_CONTENT.load_config(HARVEST_CONFIG, "nodes").get("nodes", []) as Array


func test_every_authored_harvest_spot_is_real_and_reachable() -> void:
	var nodes := _authored_nodes()
	assert_false(nodes.is_empty(), "harvest.json has no nodes at all")
	for entry: Variant in nodes:
		var spec := entry as Dictionary
		var item_id := str(spec.get("item", ""))
		assert_false(db.definition(item_id).is_empty(),
			"a harvest spot names '%s', which is not an item in items.json" % item_id)
		assert_true(int(spec.get("amount", 0)) > 0,
			"the '%s' spot pays %d" % [item_id, int(spec.get("amount", 0))])
		assert_false(str(spec.get("label", "")).is_empty(),
			"the '%s' spot has no prompt label" % item_id)
		var at: Array = spec.get("at", [])
		assert_eq(at.size(), 2, "the '%s' spot's `at` is not an [x, z] pair" % item_id)
		if at.size() == 2:
			var bounds := _world_bounds()
			var x := float(at[0])
			var z := float(at[1])
			assert_true(x >= float(bounds.get("min_x", -256.0)) and x <= float(bounds.get("max_x", 256.0))
				and z >= float(bounds.get("min_z", -256.0)) and z <= float(bounds.get("max_z", 256.0)),
				"the '%s' spot at %s is outside the authored world bounds %s" % [item_id, str(at), str(bounds)])
		var model := str(spec.get("model", ""))
		if not model.is_empty():
			assert_true(ResourceLoader.exists(model),
				"the '%s' spot names a model that does not exist: %s" % [item_id, model])


func test_no_two_authored_harvest_spots_contest_the_same_prompt() -> void:
	var nodes := _authored_nodes()
	for i in nodes.size():
		for j in range(i + 1, nodes.size()):
			var a: Array = (nodes[i] as Dictionary).get("at", [])
			var b: Array = (nodes[j] as Dictionary).get("at", [])
			if a.size() != 2 or b.size() != 2:
				continue
			var gap := Vector2(float(a[0]), float(a[1])).distance_to(Vector2(float(b[0]), float(b[1])))
			assert_true(gap >= MIN_SPOT_SEPARATION,
				"the '%s' spot at %s and the '%s' spot at %s are %.1fm apart; one prompt will always beat the other" % [
					str((nodes[i] as Dictionary).get("item", "?")), str(a),
					str((nodes[j] as Dictionary).get("item", "?")), str(b), gap])


# --- SD16: Rootstone, and where it may be taken from -----------------------

## Spec §3 Band 2 / §10. Rootstone is the chapter's first tier material and the
## whole reason the South Bridge is worth opening, so the two properties that
## make that true get asserted rather than assumed: it is a real tool-gated
## resource, and every deposit of it is on the far side of Gate 1.
##
## The second half is the one worth having. "The quarry is past the bridge" is
## a claim about geometry that a later re-tune of either could break silently —
## drop a Rootstone node on the village side and Band 2's material is free, the
## gate stops meaning anything, and nothing in the game says a word about it.
## Both sides are read from their own config, never restated here.
const TERRAIN_CONFIG := "res://data/config/terrain_playground.json"


func _crossing() -> Dictionary:
	var file := FileAccess.open(TERRAIN_CONFIG, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return {}
	for entry: Variant in (parsed as Dictionary).get("crossings", []):
		if entry is Dictionary and str((entry as Dictionary).get("id", "")) == "south_bridge":
			return entry as Dictionary
	return {}


func test_rootstone_is_a_real_pickaxe_gated_resource() -> void:
	var definition: Dictionary = db.definition("rootstone")
	assert_false(definition.is_empty(), "rootstone is not in items.json")
	assert_eq(db.gathered_with("rootstone"), "pickaxe",
		"rootstone should want the same tool stone does; §10 upgrades what exists rather than adding a system")
	var bare: Dictionary = HARVEST_LOGIC.gather("rootstone", 2, INVENTORY.new(db), db)
	var equipped: RefCounted = INVENTORY.new(db)
	equipped.add("pickaxe", 1)
	var with_tool: Dictionary = HARVEST_LOGIC.gather("rootstone", 2, equipped, db)
	assert_eq(int(with_tool["amount"]), 2, "a pickaxe should pay rootstone in full")
	assert_true(int(with_tool["amount"]) > int(bare["amount"]),
		"a pickaxe should beat bare hands on rootstone")


func test_every_rootstone_deposit_is_past_the_south_bridge() -> void:
	var crossing := _crossing()
	assert_false(crossing.is_empty(), "no `south_bridge` crossing in terrain_playground.json")
	var carve: Dictionary = crossing.get("carve", {})
	var at: Array = carve.get("centre", [])
	assert_eq(at.size(), 2, "the south gully's carve has no centre")
	if at.size() != 2:
		return
	var centre := Vector2(float(at[0]), float(at[1]))
	var axis := Vector2.RIGHT.rotated(deg_to_rad(float(carve.get("axis_deg", 0.0))))
	var across := Vector2(-axis.y, axis.x)
	# Which side of the gully the village is on, resolved the same way
	# south_bridge.gd resolves it: from the road's own start point.
	var road: Array = crossing.get("road", [])
	assert_true(road.size() >= 2, "the crossing has no road to take a bearing from")
	if road.size() < 2:
		return
	var start := Vector2(float((road[0] as Array)[0]), float((road[0] as Array)[1]))
	if start.distance_to(centre + across) < start.distance_to(centre - across):
		across = -across
	var reach: float = float(carve.get("half_width", 3.6)) + float(carve.get("rim", 3.4))

	var deposits := 0
	for entry: Variant in _authored_nodes():
		var spec := entry as Dictionary
		if str(spec.get("item", "")) != "rootstone":
			continue
		deposits += 1
		var node_at: Array = spec.get("at", [])
		if node_at.size() != 2:
			continue
		var past := (Vector2(float(node_at[0]), float(node_at[1])) - centre).dot(across)
		assert_true(past > reach,
			"a rootstone deposit at %s is only %.1fm past the gully centre (the far rim is at %.1fm) — Band 2's material is not behind Gate 1" % [
				str(node_at), past, reach])
	assert_true(deposits >= 3,
		"only %d rootstone deposits authored; one trip to the quarry should be worth the walk" % deposits)


# --- selection: scripts/world/vegetation.gd's _mark_harvestable ------------

func _placements() -> Dictionary:
	var field: RefCounted = HEIGHTFIELD.new()
	var world_size: float = float(HEIGHTFIELD.load_config().get("world_size", 512))
	var cfg: Dictionary = RULES.config()
	return RULES.all_placements(field, world_size, int(cfg.get("seed", 1)))


func test_marking_produces_a_sane_slice_of_the_configured_layers() -> void:
	var veg: Node3D = VEGETATION.new()
	var by_layer := _placements()
	veg.call("_mark_harvestable", by_layer)

	var trees: Array = by_layer.get("trees", [])
	var marked := 0
	for p: Dictionary in trees:
		if p.has("harvest_item"):
			marked += 1
			assert_eq(str(p["harvest_item"]), "wood")
	var fraction := float(RULES.config()["layers"]["trees"].get("harvest_fraction", 0.0))
	var expected := int(trees.size() * fraction)
	# A stride selection, not a perfectly exact count -- within a rounding
	# tooth of the configured fraction is the real guarantee.
	assert_true(marked > 0, "no tree in the whole layer was marked harvestable")
	assert_true(absi(marked - expected) <= maxi(2, int(expected * 0.4)),
		"marked %d of %d trees, expected roughly %d (fraction %.3f)" % [marked, trees.size(), expected, fraction]
	)
	veg.free()


func test_marking_leaves_layers_with_no_harvest_item_untouched() -> void:
	var veg: Node3D = VEGETATION.new()
	var by_layer := _placements()
	veg.call("_mark_harvestable", by_layer)

	for name: String in ["flowers", "grass", "drygrass", "bushes"]:
		for p: Dictionary in (by_layer.get(name, []) as Array):
			assert_false((p as Dictionary).has("harvest_item"),
				"layer '%s' has no harvest_item configured and must never be marked" % name)
	veg.free()


func test_marking_is_deterministic_for_the_same_seed() -> void:
	var veg: Node3D = VEGETATION.new()
	var first := _placements()
	veg.call("_mark_harvestable", first)
	var first_marked: Array = []
	for p: Dictionary in (first.get("rocks", []) as Array):
		first_marked.append(p.has("harvest_item"))

	var second := _placements()
	veg.call("_mark_harvestable", second)
	var second_marked: Array = []
	for p: Dictionary in (second.get("rocks", []) as Array):
		second_marked.append(p.has("harvest_item"))

	assert_eq(first_marked, second_marked, "the same seed must mark the same instances every run")
	veg.free()


# --- OF20: harvest_node.gd's model loading and the hide/respawn cycle ------
#
# Both of these run `HarvestNode` standing entirely alone -- never added to
# any tree -- the same "pure logic" shape as the rest of this file (D02). That
# is enough to cover OF20's actual bug: `_build_visual()`'s PackedScene-vs-
# Mesh branch and `_process()`'s respawn timer touch nothing but the node's
# own children. What is deliberately NOT exercised here is `_on_gathered()`'s
# inventory half, which needs the real `/root/Game` autoload -- unreachable
# from a node with no SceneTree (see `test_party_seam.gd`'s header for why
# `run_tests.gd` boots none) -- and is already covered pure-logic-only by
# `harvest_logic.gd`'s own tests above. The respawn case below reproduces the
# hidden -> respawned half of that cycle directly, the same fields
# `_on_gathered()` itself sets on a successful gather.


func _walk(node: Node) -> Array[Node]:
	var out: Array[Node] = [node]
	for child in node.get_children():
		out.append_array(_walk(child))
	return out


## The real acid test. `mesh.mesh = load(<gltf>)` (the OF20 bug) does not
## throw or abort -- it silently leaves a `MeshInstance3D` in the tree with
## `.mesh == null` (confirmed against the unfixed code before this fix: no
## script error, just a null mesh). A plain "is there a MeshInstance3D
## anywhere" check passes on that broken node just as happily as on a fixed
## one, so this checks for one with an actual mesh resource attached --
## which is what OF20 was really missing.
func _has_a_populated_mesh_instance(node: Node) -> bool:
	for descendant in _walk(node):
		if descendant is MeshInstance3D and (descendant as MeshInstance3D).mesh != null:
			return true
	return false


func test_a_gltf_model_builds_a_real_populated_mesh_not_a_dead_assignment() -> void:
	var node: Node3D = HARVEST_NODE.new()
	node.call("setup", WOOD_SPEC)
	assert_true(_has_a_populated_mesh_instance(node),
		"a .gltf model (a PackedScene, per its own .import sidecar) must produce a MeshInstance3D with a real mesh somewhere in the visual subtree, not a null one")
	node.free()


func test_a_missing_model_still_falls_back_to_the_box() -> void:
	var node: Node3D = HARVEST_NODE.new()
	node.call("setup", {"item": "wood", "amount": 4, "label": "Gather deadwood", "model": ""})
	assert_true(_has_a_populated_mesh_instance(node),
		"the no-model fallback must still be a real, populated MeshInstance3D (the BoxMesh mound)")
	node.free()


func test_gather_hides_the_visual_and_respawn_restores_it() -> void:
	var node: Node3D = HARVEST_NODE.new()
	node.call("setup", WOOD_SPEC)
	var visual: Node3D = node.get("_visual")
	assert_true(is_instance_valid(visual) and visual.visible, "a fresh node's visual must start visible")

	# The state `_on_gathered()` itself sets on a successful gather (harvest_node.gd
	# lines ~101-104) -- set directly here rather than through `_on_gathered()`,
	# which needs the `/root/Game` autoload this runner never boots.
	visual.visible = false
	node.set("_respawn_left", HARVEST_NODE.RESPAWN_SECONDS)
	node.set_process(true)
	assert_false(visual.visible, "gathering must hide the visual")

	node.call("_process", HARVEST_NODE.RESPAWN_SECONDS + 0.01)
	assert_true(visual.visible, "the respawn timer must restore the visual once it elapses")
	node.free()
