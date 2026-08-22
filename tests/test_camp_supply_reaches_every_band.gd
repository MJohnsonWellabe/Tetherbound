extends "res://tests/test_case.gd"

## EXPEDITION-REST (prompt 61): a rest point has to be worth stopping at.
##
## The 2026-08-22 Gate C audit found `band3`, `band4` and `band5` each shipping
## a `harvest.json` whose `nodes` array was empty -- comment-only stubs. Across
## the back ~4.4 km of corridor there was no local harvest at all. Corridor
## scatter still yields wood, stone and fiber, so a camp was BUILDABLE
## everywhere; what was missing was anywhere it was worth stopping.
##
## What this pins is the property, not the node count: **every band can pay for
## a camp and a creature bed out of its own ground.** A band that fields only
## deadwood is a detour, not a rest point, because `buildables.json` charges
## fiber and stone too.

const BUILDABLES_PATH := "res://data/items/buildables.json"
const BANDS := [
	"band1_lower_meadows",
	"band2_stone_and_root",
	"band3_the_river_lock",
	"band4_upper_meadows_ironwood",
	"band5_stronghold_approach",
]


func _json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


func _nodes(band: String) -> Array:
	return _json("res://data/config/bands/%s/harvest.json" % band).get("nodes", [])


## What `camp` and `creature_bed` together actually cost, read from the
## shipping build data rather than restated here.
func _rest_point_cost() -> Dictionary:
	var buildables: Dictionary = _json(BUILDABLES_PATH)
	var entries: Variant = buildables.get("buildables", buildables)
	var cost: Dictionary = {}
	for id: String in ["camp", "creature_bed"]:
		var entry: Dictionary = (entries as Dictionary).get(id, {})
		for line: Variant in (entry.get("cost", []) as Array):
			var item := str((line as Dictionary).get("id", ""))
			if item != "":
				cost[item] = int(cost.get(item, 0)) + int((line as Dictionary).get("count", 0))
	return cost


func test_the_rest_point_cost_is_readable_at_all() -> void:
	var cost := _rest_point_cost()
	assert_false(cost.is_empty(),
		"neither camp nor creature_bed has a readable cost in buildables.json; "
		+ "every check below would pass vacuously")
	assert_true(cost.size() >= 2,
		"a rest point costs only one material (%s); this test assumes it takes "
		% str(cost.keys()) + "more than one, which is the whole reason a single "
		+ "deadwood node is not a camp site")


func test_every_band_can_pay_for_a_rest_point_from_its_own_ground() -> void:
	var needed: Array = _rest_point_cost().keys()
	for band: String in BANDS:
		var yielded: Dictionary = {}
		for node: Variant in _nodes(band):
			yielded[str((node as Dictionary).get("item", ""))] = true
		assert_false(yielded.is_empty(),
			"%s has no harvest nodes at all; a player crossing it can build a rest "
			% band + "point only from corridor scatter, which is why bands 3-5 were "
			+ "buildable-but-not-worth-stopping")
		for material: String in needed:
			assert_true(yielded.has(material),
				"%s yields no %s, which a camp and creature bed both need; a band "
				% [band, material] + "that fields only some of the cost is a detour, "
				+ "not a rest point")


func test_every_harvest_node_names_a_model_that_exists() -> void:
	# The first pass at bands 3-5 referenced `Grass_Large.gltf` for fiber, which
	# is not in the project -- the shipped fiber model is `Plant_7_Big`. That is
	# a node that would spawn with no mesh, which reads as "nothing is there"
	# rather than as an error.
	var checked := 0
	for band: String in BANDS:
		for node: Variant in _nodes(band):
			var model := str((node as Dictionary).get("model", ""))
			if model.is_empty():
				continue
			checked += 1
			assert_true(ResourceLoader.exists(model),
				"%s harvests with '%s', which is not in the project; the node would "
				% [band, model] + "stand there with no mesh")
	assert_true(checked >= 20,
		"only %d harvest models were checked; this test went blind" % checked)


func test_no_two_harvest_nodes_share_an_order() -> void:
	# `order` decides merge position across bands and the file comments reserve a
	# range per band precisely so five authors cannot collide. A duplicate would
	# silently drop or reorder a node.
	var seen: Dictionary = {}
	for band: String in BANDS:
		for node: Variant in _nodes(band):
			var order := int((node as Dictionary).get("order", -1))
			assert_true(order >= 0, "%s has a harvest node with no order" % band)
			assert_false(seen.has(order),
				"order %d is used by both %s and %s" % [order, str(seen.get(order, "")), band])
			seen[order] = band


func test_each_bands_nodes_sit_in_its_own_reserved_range() -> void:
	var ranges := {
		"band2_stone_and_root": [2000, 2999],
		"band3_the_river_lock": [3000, 3999],
		"band4_upper_meadows_ironwood": [4000, 4999],
		"band5_stronghold_approach": [5000, 5999],
	}
	for band: String in ranges:
		var low: int = ranges[band][0]
		var high: int = ranges[band][1]
		for node: Variant in _nodes(band):
			var order := int((node as Dictionary).get("order", -1))
			assert_true(order >= low and order <= high,
				"%s has a node at order %d, outside its reserved %d-%d; another "
				% [band, order, low, high] + "band's author can collide with it")
