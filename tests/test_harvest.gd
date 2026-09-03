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
const PROGRESSION_STATE := preload("res://autoload/progression_state.gd")

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
	var result: Dictionary = HARVEST_LOGIC.gather("wood", 3, bag, db, "axe")
	assert_eq(int(result["amount"]), 3)
	assert_eq(int(result["required_slot"]), bag.find_slot("axe"))


func test_gather_with_no_equipped_tool_is_refused() -> void:
	bag.add("axe", 1)
	var result: Dictionary = HARVEST_LOGIC.gather("wood", 3, bag, db, "")
	assert_eq(int(result["amount"]), 0,
		"carrying an axe is not enough when no tool is visibly equipped")
	assert_eq(int(result["required_slot"]), -1, "a refusal must damage nothing")


func test_gather_with_the_wrong_tool_pays_nothing() -> void:
	bag.add("axe", 1)
	bag.add("pickaxe", 1)
	var result: Dictionary = HARVEST_LOGIC.gather("wood", 3, bag, db, "pickaxe")
	assert_eq(int(result["amount"]), 0,
		"holding a pickaxe must refuse wood even when an axe is also in the Satchel")
	assert_eq(int(result["required_slot"]), -1, "the hidden axe must not wear down")


func test_gather_with_a_broken_equipped_tool_is_refused() -> void:
	bag.add("axe", 1)
	var slot: int = bag.find_slot("axe")
	bag.damage_tool(slot, db.max_durability("axe") + 50)
	var result: Dictionary = HARVEST_LOGIC.gather("wood", 3, bag, db, "axe")
	assert_eq(int(result["amount"]), 0, "a broken held axe must not authorize a hit")
	assert_eq(int(result["required_slot"]), -1, "a broken tool must not wear down again")


func test_gather_of_an_untool_gated_resource_always_pays_the_full_amount() -> void:
	var result: Dictionary = HARVEST_LOGIC.gather("berries", 5, bag, db)
	assert_eq(int(result["amount"]), 5)
	assert_eq(int(result["required_slot"]), -1)


# --- Opening tool handovers ---------------------------------------------

## The tool gate has been correct since R2.1 and unreachable since R2.1: no
## axe, pickaxe or knife existed anywhere in the world, so "the right tool" was
## a rule the player could only ever fail. The opening now gives the axe and
## pickaxe through Mira's required visit, then the knife through Tam's follow-up.
## This is the yield side of that route — the exact combined set, against the
## exact resources they gate, with nothing else in the satchel.
##
## `tests/test_dialogue_runner.gd` is what checks he really gives THESE three;
## this checks that having them changes anything.
func test_the_opening_tool_handoffs_cover_every_tool_gated_meadow_resource() -> void:
	const HANDOVER := {"axe": "wood", "pickaxe": "stone", "knife": "fiber"}
	for tool_id: String in HANDOVER:
		var resource: String = HANDOVER[tool_id]
		assert_eq(db.gathered_with(resource), tool_id,
			"'%s' should be gathered with '%s'" % [resource, tool_id])

		var barehanded: Dictionary = HARVEST_LOGIC.gather(resource, 4, INVENTORY.new(db), db, "")
		var equipped: RefCounted = INVENTORY.new(db)
		equipped.add(tool_id, 1)
		var with_tool: Dictionary = HARVEST_LOGIC.gather(resource, 4, equipped, db, tool_id)

		assert_eq(int(with_tool["amount"]), 4,
			"'%s' should pay '%s' in full" % [tool_id, resource])
		assert_eq(int(barehanded["amount"]), 0,
			"'%s' must be equipped before '%s' can be gathered" % [tool_id, resource])
		assert_true(int(with_tool["required_slot"]) >= 0,
			"'%s' should be the tool that wears down" % tool_id)


## The complete opening set must cover every gated meadow resource when the
## matching member is equipped. Merely carrying the set is checked separately
## above and no longer authorizes a mismatched visible swing.
func test_equipping_each_member_of_the_opening_set_gathers_everything_the_meadow_offers() -> void:
	bag.add("axe", 1)
	bag.add("pickaxe", 1)
	bag.add("knife", 1)
	for resource in ["wood", "stone", "fiber", "berries"]:
		var required: String = str(db.gathered_with(resource))
		var result: Dictionary = HARVEST_LOGIC.gather(resource, 3, bag, db, required)
		assert_eq(int(result["amount"]), 3,
			"equipping '%s' should pay '%s' in full" % [required, resource])


## The generalisation of the case above, so a NEW tool-gated resource added
## later cannot quietly become unreachable: the combined mandatory opening
## handovers must cover every resource in items.json that gates on a tool. Read
## straight off the dialogue data rather than restated here.
func test_nothing_the_opening_handoffs_give_leaves_a_tool_gated_resource_stranded() -> void:
	const RUNNER := preload("res://scripts/story/dialogue_runner.gd")
	var owned: RefCounted = INVENTORY.new(db)
	for conversation_id in ["village_mira_shop_intro", "village_tam_tools"]:
		var conversation: Dictionary = RUNNER.table().get(conversation_id, {})
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
		var required: String = str(db.gathered_with(resource))
		var result: Dictionary = HARVEST_LOGIC.gather(resource, 2, owned, db, required)
		assert_eq(int(result["amount"]), 2,
			"'%s' gates on '%s', which the mandatory opening handovers do not include -- with the other tools in hand it now pays nothing at all" % [
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
const BAND1_HARVEST_CONFIG := "res://data/config/bands/band1_lower_meadows/harvest.json"
const BUILDABLES_CONFIG := "res://data/items/buildables.json"
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


func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if parsed is Dictionary else {}


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


## Gate A's continuous evidence is one paid session, not three isolated smokes:
## the player builds the simple house, then a campsite (tent, campfire,
## bedroll -- OWNER-0902-CAMP-SPLIT retired the old single bundled `camp` buy)
## and a creature bed without a debug grant in between. The old opening
## authored only 12 fiber while the campsite and creature bed alone consume
## 18, so a perfectly thorough natural gather still hit an artificial wall.
## Keep the requirement derived from the real catalogue so a later tuning
## pass cannot recreate that failure silently.
func test_band1_naturally_supplies_the_gate_a_paid_build_session() -> void:
	var build_counts := {
		"tent": 1,
		"campfire": 1,
		"bedroll": 1,
		"floor": 4,
		"wall": 7,
		"door": 1,
		"roof": 4,
		"creature_bed": 1,
	}
	var required_fiber := 0
	for buildable: Variant in _read_json(BUILDABLES_CONFIG).get("buildables", []):
		var spec := buildable as Dictionary
		var copies := int(build_counts.get(str(spec.get("id", "")), 0))
		if copies <= 0:
			continue
		for cost: Variant in spec.get("cost", []):
			if str((cost as Dictionary).get("id", "")) == "fiber":
				required_fiber += int((cost as Dictionary).get("n", 0)) * copies

	assert_true(required_fiber >= 18,
		"the canonical paid house + camp + creature-bed session unexpectedly costs only %d fiber; this regression no longer represents the Gate A shortfall" % required_fiber)
	var natural_fiber := 0
	for node: Variant in _read_json(BAND1_HARVEST_CONFIG).get("nodes", []):
		var spec := node as Dictionary
		if str(spec.get("item", "")) == "fiber":
			natural_fiber += int(spec.get("amount", 0))
	assert_true(natural_fiber >= required_fiber,
		"Band 1 naturally supplies %d fiber, but the continuous paid build session needs %d" % [natural_fiber, required_fiber])


## The two extra plants are intentionally discoverable from ordinary travel,
## but are not placed ON the critical dirt route merely to make the count pass.
## Heightfield probes also catch a future terrain edit leaving either plant on
## a sharp lip where its interaction body or the player cannot stand reliably.
func test_gate_a_fiber_supply_nodes_are_safe_short_route_detours() -> void:
	var field := HEIGHTFIELD.new()
	var supply_orders := {1000: true, 1001: true}
	var found := {}
	for node: Variant in _read_json(BAND1_HARVEST_CONFIG).get("nodes", []):
		var spec := node as Dictionary
		var order := int(spec.get("order", -1))
		if not supply_orders.has(order):
			continue
		found[order] = true
		assert_eq(str(spec.get("item", "")), "fiber")
		assert_eq(int(spec.get("amount", 0)), 4)
		var at: Array = spec.get("at", [])
		assert_eq(at.size(), 2, "Gate A fiber order %d has no [x,z] position" % order)
		if at.size() != 2:
			continue
		var point := Vector2(float(at[0]), float(at[1]))
		var nearest: Vector2 = field.nearest_point_on_paths(point.x, point.y)
		var detour := point.distance_to(nearest)
		assert_true(detour >= 7.0,
			"Gate A fiber order %d is only %.1fm off the route and can obstruct/read as part of the trail" % [order, detour])
		assert_true(detour <= 18.0,
			"Gate A fiber order %d is %.1fm off the route instead of a natural short gathering detour" % [order, detour])
		assert_true(field.path_factor(point.x, point.y) <= 0.01,
			"Gate A fiber order %d still lies inside the authored trail/shoulder" % order)

		var low := field.height_at(point.x, point.y)
		var high := low
		for offset in [Vector2(1.5, 0.0), Vector2(-1.5, 0.0), Vector2(0.0, 1.5), Vector2(0.0, -1.5)]:
			var sample := field.height_at(point.x + offset.x, point.y + offset.y)
			low = minf(low, sample)
			high = maxf(high, sample)
		assert_true(high - low <= 0.75,
			"Gate A fiber order %d spans %.2fm of ground over its 3m standing pad" % [order, high - low])

	assert_eq(found.size(), supply_orders.size(),
		"both reserved Gate A fiber nodes must remain authored; found orders %s" % str(found.keys()))


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
	var bare: Dictionary = HARVEST_LOGIC.gather("rootstone", 2, INVENTORY.new(db), db, "")
	var equipped: RefCounted = INVENTORY.new(db)
	equipped.add("pickaxe", 1)
	var with_tool: Dictionary = HARVEST_LOGIC.gather("rootstone", 2, equipped, db, "pickaxe")
	assert_eq(int(with_tool["amount"]), 2, "a pickaxe should pay rootstone in full")
	assert_eq(int(bare["amount"]), 0, "rootstone must refuse an empty hand")


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
#
# PERF, 2026-08-25: this file's own tests were the single biggest cost in the
# whole suite -- 816s of a ~830s local run, almost entirely `RULES.
# all_placements()`, which walks all ten layers across the REAL corridor
# (`_place_corridor_fill` reads `field.world_bounds()`, the true ~7500m
# extent, not the `world_size` argument, so shrinking that argument does not
# shrink this cost). Measured per layer with `tools/_probe_placements_timing.
# gd` (kept for the next time this needs re-checking): trees 14.0s, grove
# 0.1s, saplings 1.0s, deadfall 0.05s, bushes 15.7s, GRASS 112.6s, drygrass
# 30.1s, flowers 22.4s, rocks 2.9s, path_stones 1.9s -- ~200s for one full
# call, and this file made four of them (800s), one pair of which only ever
# read the "rocks" layer back out.
#
# `_layer_placements()` below calls `RULES.placements_for()` directly for
# exactly the layer(s) a test actually reads, using the same per-layer seed
# `all_placements()` itself derives (base_seed + offset*7919 +
# seed_offset, `offset` being the layer's position in `config()["layers"]`'s
# own key order) so a single-layer call reproduces precisely what a full
# `all_placements()` call would have produced for that layer -- `vegetation.
# gd`'s own `_mark_harvestable()` already iterates `by_layer.keys()`
# independently per entry (scripts/world/vegetation.gd:368-369), so handing
# it a partial dict is exactly what it is written to accept, not a
# workaround.
func _layer_placements(name: String) -> Array[Dictionary]:
	var layers: Dictionary = RULES.config().get("layers", {})
	var offset := 0
	var layer: Dictionary = {}
	for key: String in layers.keys():
		if key == name:
			layer = layers[key]
			break
		offset += 1
	if layer.is_empty():
		return []
	var seed_value := int(RULES.config().get("seed", 1)) + offset * 7919 + int(layer.get("seed_offset", 0))
	var field: RefCounted = HEIGHTFIELD.new()
	var world_size: float = float(HEIGHTFIELD.load_config().get("world_size", 512))
	return RULES.placements_for(layer, field, world_size, seed_value)


func test_marking_produces_a_sane_slice_of_the_configured_layers() -> void:
	var veg: Node3D = VEGETATION.new()
	var by_layer := {"trees": _layer_placements("trees")}
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

	# DERIVED from the config rather than a hardcoded list. This used to name
	# ["flowers", "grass", "drygrass", "bushes"], which was correct until
	# EXPEDITION-REST gave `bushes` a harvest_item of its own -- at which point
	# a literal list would have failed the build for the layer doing exactly
	# what it was configured to do. Asking the config which layers are supposed
	# to be inert tests the actual rule ("no harvest_item means never marked")
	# and cannot rot the next time a layer gains or loses one.
	#
	# Only the inert layers' placements are computed -- this test never reads
	# the harvestable ones (trees/bushes/rocks), so generating them would only
	# pay their cost (30s+ apiece) for nothing this assertion looks at.
	var by_layer: Dictionary = {}
	for name: String in (RULES.config().get("layers", {}) as Dictionary).keys():
		var layer: Dictionary = RULES.config()["layers"][name]
		if str(layer.get("harvest_item", "")) != "":
			continue
		by_layer[name] = _layer_placements(name)
	veg.call("_mark_harvestable", by_layer)

	var checked := 0
	for name: String in by_layer.keys():
		checked += 1
		for p: Dictionary in (by_layer[name] as Array):
			assert_false((p as Dictionary).has("harvest_item"),
				"layer '%s' has no harvest_item configured and must never be marked" % name)
	assert_true(checked >= 3,
		"only %d layers have no harvest_item; this check has stopped testing anything" % checked)
	veg.free()


func test_marking_is_deterministic_for_the_same_seed() -> void:
	# Only "rocks" -- the sole layer this test ever reads back -- computed
	# twice and independently, which is the actual property under test ("the
	# same seed reproduces the same placements/marking"), not "every layer
	# generates the same numbers as some other layer," which nothing here
	# asserts. Was two full `all_placements()` calls (~400s for the pair);
	# `_layer_placements("rocks")` alone measured 2.9s per call.
	var veg: Node3D = VEGETATION.new()
	var first := {"rocks": _layer_placements("rocks")}
	veg.call("_mark_harvestable", first)
	var first_marked: Array = []
	for p: Dictionary in (first.get("rocks", []) as Array):
		first_marked.append(p.has("harvest_item"))

	var second := {"rocks": _layer_placements("rocks")}
	veg.call("_mark_harvestable", second)
	var second_marked: Array = []
	for p: Dictionary in (second.get("rocks", []) as Array):
		second_marked.append(p.has("harvest_item"))

	assert_eq(first_marked, second_marked, "the same seed must mark the same instances every run")
	veg.free()


# --- OF20: harvest_node.gd's model loading ----------------------------------
#
# Both of these run `HarvestNode` standing entirely alone -- never added to
# any tree -- the same "pure logic" shape as the rest of this file (D02). That
# is enough to cover OF20's actual bug: `_build_visual()`'s PackedScene-vs-
# Mesh branch touches nothing but the node's own children. What is
# deliberately NOT exercised here is `_on_gathered()`'s inventory half, which
# needs the real `/root/Game` autoload -- unreachable from a node with no
# SceneTree (see `test_party_seam.gd`'s header for why `run_tests.gd` boots
# none) -- and is already covered pure-logic-only by `harvest_logic.gd`'s own
# tests above.


# --- D72: gathered stays gone -- flag_id()/was_taken()/restore, the same
# contract `test_item_cache_pickup.gd` already proves for item_cache_pickup.gd.
# `was_taken()`/`restore_progression_from_game()` both take `game: Node` and
# read its `progression` property through the ordinary `Object.get()` -- a
# plain `Node` carrying the real flag store, the same double
# `test_item_cache_pickup.gd::FakeCacheGame` uses, stands in without a live
# SceneTree.


class FakeHarvestGame:
	extends Node
	var progression: RefCounted = PROGRESSION_STATE.new()


func test_flag_id_is_the_harvest_node_prefix_plus_the_node_id() -> void:
	assert_eq(HARVEST_NODE.flag_id("order:5"), "harvest_node:order:5")


func test_was_taken_is_false_with_no_game_at_all() -> void:
	assert_false(HARVEST_NODE.was_taken(null, "order:5"),
		"a missing autoload must read as 'not taken', the cautious direction for a permanent removal")


func test_was_taken_reads_the_real_flag_store() -> void:
	var game := FakeHarvestGame.new()
	assert_false(HARVEST_NODE.was_taken(game, "order:5"))
	game.progression.set_flag(HARVEST_NODE.flag_id("order:5"))
	assert_true(HARVEST_NODE.was_taken(game, "order:5"))
	game.free()


func test_was_taken_is_per_node_not_global() -> void:
	var game := FakeHarvestGame.new()
	game.progression.set_flag(HARVEST_NODE.flag_id("order:5"))
	assert_false(HARVEST_NODE.was_taken(game, "order:6"),
		"one node's flag must not read as every node having been gathered")
	game.free()


## `order` is what every real authored node carries (band_content.gd enforces
## it unique); a caller with no `order` (burrow_warrens.gd's deposits, this
## test's own WOOD_SPEC) still needs a stable id, derived from its item and
## authored `at` instead.
func test_setup_derives_its_id_from_order_when_present() -> void:
	var node: Node3D = HARVEST_NODE.new()
	node.call("setup", {"item": "wood", "amount": 4, "order": 2013})
	assert_eq(str(node.get("_node_id")), "order:2013")
	node.free()


func test_setup_falls_back_to_item_and_position_when_order_is_absent() -> void:
	var node: Node3D = HARVEST_NODE.new()
	node.call("setup", {"item": "stone", "amount": 2, "at": [4.0, -2.0]})
	assert_eq(str(node.get("_node_id")), "stone@[4.0, -2.0]")
	node.free()


## `_deactivate()` calls `queue_free()`, deferred to the next idle frame --
## this harness never steps the SceneTree (D02), so `is_instance_valid()`
## right after the call would still read true regardless of whether
## deactivation ran. `visible` is set synchronously, before the deferred free,
## so it is what a test without a running tree can actually observe -- the
## same shape `test_item_cache_pickup.gd` uses for its own restore test.
func test_restore_deactivates_a_node_whose_flag_is_already_set() -> void:
	var node: Node3D = HARVEST_NODE.new()
	node.call("setup", WOOD_SPEC)
	var game := FakeHarvestGame.new()
	game.progression.set_flag(HARVEST_NODE.flag_id(str(node.get("_node_id"))))

	node.call("restore_progression_from_game", game)

	assert_false(node.visible, "an already-gathered node must hide itself on restore, the same as key_pickup.gd's contract")
	node.free()
	game.free()


func test_restore_leaves_an_ungathered_node_alone() -> void:
	var node: Node3D = HARVEST_NODE.new()
	node.call("setup", WOOD_SPEC)
	var game := FakeHarvestGame.new()

	node.call("restore_progression_from_game", game)

	assert_true(node.visible, "a node nobody has gathered yet must stay visible after a restore call")
	node.free()
	game.free()


## `setup()` itself already checks `was_taken()` through the real `/root/Game`
## lookup path, which resolves to null on a freestanding node -- so `setup()`
## on a fresh, untouched flag store must leave the node active.
func test_setup_on_a_fresh_flag_store_leaves_the_node_active() -> void:
	var node: Node3D = HARVEST_NODE.new()
	node.call("setup", WOOD_SPEC)
	assert_true(is_instance_valid(node), "setup() must not free a node nobody has gathered yet")
	if is_instance_valid(node):
		node.free()


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


func test_authored_node_exposes_read_only_resource_identity_for_route_selection() -> void:
	var node: Node3D = HARVEST_NODE.new()
	node.call("setup", WOOD_SPEC)
	assert_true(node.has_method("resource_item"),
		"a controller route must not inspect HarvestNode's private `_item_id`")
	assert_true(node.has_method("resource_amount"),
		"a controller route must not inspect HarvestNode's private `_amount`")
	assert_eq(str(node.call("resource_item")), "wood")
	assert_eq(int(node.call("resource_amount")), 4)
	node.free()


# D72: gathering no longer hides-and-respawns. See "D72: gathered stays gone"
# above for the flag_id()/was_taken()/restore_progression_from_game() coverage
# that replaces this test.
