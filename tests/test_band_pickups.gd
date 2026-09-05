extends "res://tests/test_case.gd"

## W17-DENSITY-B2-B3. The authored per-band findables
## (`data/config/bands/<band>/pickups.json`, `scripts/world/band_pickups.gd`).
##
## What this proves, at the data level and through the real seam:
##
##   * every entry is well-formed (the loader's own `validate()`, so the test
##     and the world refuse the same things);
##   * ids are unique across the whole chapter -- an id IS the once-flag, and
##     two placements sharing one would collect each other;
##   * every item is a real `items.json` id with a real `world_model`, so a
##     candy stands up as the candy mesh and never as the box fallback;
##   * every position is inside its own band's z extent and the authored
##     world bounds (a pickup on Terrain3D's background noise looks placed
##     and has no collision under it);
##   * no two prompts contest each other: pickups keep `test_harvest.gd`'s
##     own 4.5 m rule from every other pickup and from every harvest node;
##   * the tier mix follows the addendum: the critical path is sparse and
##     never carries a Great or Rare;
##   * a collected id survives a save/load round trip, through the REAL
##     `item_cache_pickup.gd` node -- set up with the placement id as its
##     flag key, the key it resolves (`_key()`, the same one `_on_picked_up()`
##     writes) flagged in the real store, the store saved and reloaded, and
##     a fresh node for the same placement deactivated by `restore` while a
##     second placement of the same item is NOT. `_on_picked_up()` itself
##     resolves `/root/Game` by absolute path, which no unit test has
##     (`tests/test_item_cache_pickup.gd`'s header records the same limit);
##     the booted-world half is `tests/smoke_playground.gd`'s placement line.
##
## Seen red before green (W17 report): duplicating an id failed
## `test_ids_are_unique_across_the_chapter`; dropping the `flag_key` from
## the seam failed `test_two_placements_of_the_same_item_have_independent_flags`
## exactly as the header of `band_pickups.gd` predicts.

const BAND_PICKUPS := preload("res://scripts/world/band_pickups.gd")
const BAND_CONTENT := preload("res://scripts/data/band_content.gd")
const ITEM_CACHE_PICKUP := preload("res://scripts/world/item_cache_pickup.gd")
const PROGRESSION_STATE := preload("res://autoload/progression_state.gd")
const ALIGNMENT := preload("res://scripts/world/terrain_region_alignment.gd")
const ITEM_DB := preload("res://autoload/item_db.gd")

const TERRAIN_PATH := "res://data/config/terrain_playground.json"
const ITEMS_PATH := "res://data/items/items.json"
## `tests/test_harvest.gd::MIN_SPOT_SEPARATION`: closer than this and one
## prompt always beats the other.
const MIN_SEPARATION_M := 4.5
## Seam slack: a band's spine polyline is the extent, and a placement a few
## metres past its first or last point is still that band's.
const EXTENT_SLACK_M := 25.0
## The bands the density lanes authored (W17: bands 2-3; W18: bands 4-5); the
## test is chapter-wide but asserts these are not empty so a silently unread
## file cannot pass.
const AUTHORED_BANDS: Array[String] = ["band2_stone_and_root", "band3_the_river_lock", "band4_upper_meadows_ironwood", "band5_stronghold_approach"]


## A stand-in for `/root/Game` carrying the real flag store, the real item db
## and a satchel that always has room -- the same shape
## `tests/test_item_cache_pickup.gd::FakeCacheGame` uses, extended with the
## two properties `_on_picked_up()` actually reads.
class FakePickupGame:
	extends Node
	var progression: RefCounted = PROGRESSION_STATE.new()
	var items: RefCounted = ITEM_DB.new()
	var inventory: RefCounted = AlwaysRoomSatchel.new()
	var messages: Array[String] = []

	func push_world_message(text: String) -> void:
		messages.append(text)


class AlwaysRoomSatchel:
	extends RefCounted
	var added: Array = []

	func has_room_for(_item_id: String, _count: int) -> bool:
		return true

	func add(item_id: String, count: int) -> void:
		added.append([item_id, count])


func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


## band id -> [z_min, z_max] from the trail's own spine points.
func _band_extents() -> Dictionary:
	var out := {}
	var trail: Dictionary = _read_json(TERRAIN_PATH).get("trail", {}) as Dictionary
	for band: Variant in (trail.get("bands", []) as Array):
		var spec: Dictionary = band
		var lo := INF
		var hi := -INF
		for point: Variant in (spec.get("points", []) as Array):
			var z := float((point as Array)[1])
			lo = minf(lo, z)
			hi = maxf(hi, z)
		out[str(spec.get("id", ""))] = [lo, hi]
	return out


func _harvest_spots() -> Array[Vector2]:
	var out: Array[Vector2] = []
	var nodes: Array = BAND_CONTENT.load_config("res://data/config/harvest.json", "nodes").get("nodes", []) as Array
	for entry: Variant in nodes:
		var at: Array = (entry as Dictionary).get("at", []) as Array
		if at.size() == 2:
			out.append(Vector2(float(at[0]), float(at[1])))
	return out


# --- schema ------------------------------------------------------------------


func test_every_authored_entry_is_well_formed() -> void:
	var seen := 0
	for band: String in BAND_CONTENT.BANDS:
		for entry: Variant in BAND_PICKUPS.read_band(band):
			seen += 1
			assert_eq(BAND_PICKUPS.validate(entry as Dictionary), "",
				"%s/pickups.json: %s" % [band, BAND_PICKUPS.validate(entry as Dictionary)])
	assert_true(seen > 0, "no band has any pickups; this test would prove nothing")


func test_the_authored_bands_are_actually_read() -> void:
	# A file that fails to parse reads as an empty band and every other check
	# here would pass vacuously for it.
	for band: String in AUTHORED_BANDS:
		assert_true(BAND_PICKUPS.read_band(band).size() >= 10,
			"%s/pickups.json read as %d entries; the W17 batch authored more than that" % [
				band, BAND_PICKUPS.read_band(band).size()])


func test_validate_refuses_each_missing_field() -> void:
	var good := {"id": "x", "item": "good_candy", "pos": [1.0, 2.0], "tier": "side", "why": "because"}
	assert_eq(BAND_PICKUPS.validate(good), "")
	for key: String in ["id", "item", "pos", "tier", "why"]:
		var broken := good.duplicate()
		broken.erase(key)
		assert_ne(BAND_PICKUPS.validate(broken), "", "dropping `%s` was accepted" % key)
	var bad_tier := good.duplicate()
	bad_tier["tier"] = "loot"
	assert_ne(BAND_PICKUPS.validate(bad_tier), "", "an unknown tier was accepted")
	var bad_pos := good.duplicate()
	bad_pos["pos"] = [1.0, 2.0, 3.0]
	assert_ne(BAND_PICKUPS.validate(bad_pos), "", "a three-value pos was accepted")


func test_ids_are_unique_across_the_chapter() -> void:
	var owner_of := {}
	for band: String in BAND_CONTENT.BANDS:
		for entry: Variant in BAND_PICKUPS.read_band(band):
			var id := str((entry as Dictionary).get("id", ""))
			assert_false(owner_of.has(id),
				"pickup id '%s' is in both %s and %s; the id is the once-flag" % [id, str(owner_of.get(id, "")), band])
			owner_of[id] = band


func test_load_all_drops_nothing_well_formed() -> void:
	var authored := 0
	for band: String in BAND_CONTENT.BANDS:
		authored += BAND_PICKUPS.read_band(band).size()
	assert_eq(BAND_PICKUPS.load_all().size(), authored,
		"load_all() returned %d of %d authored pickups" % [BAND_PICKUPS.load_all().size(), authored])


# --- items -------------------------------------------------------------------


func test_every_item_exists_and_has_a_world_model_that_exists() -> void:
	var items: Dictionary = _read_json(ITEMS_PATH).get("items", {}) as Dictionary
	assert_false(items.is_empty(), "items.json has no items; this test would prove nothing")
	for entry: Variant in BAND_PICKUPS.load_all():
		var pickup: Dictionary = entry
		var item := str(pickup["item"])
		assert_true(items.has(item), "pickup '%s' names item '%s', which items.json does not define" % [str(pickup["id"]), item])
		if not items.has(item):
			continue
		var model := str((items[item] as Dictionary).get("world_model", ""))
		assert_ne(model, "", "pickup '%s': item '%s' has no world_model; it would stand up as the barrel" % [str(pickup["id"]), item])
		assert_true(ResourceLoader.exists(model),
			"pickup '%s': item '%s' points at %s, which does not exist" % [str(pickup["id"]), item, model])


# --- positions ---------------------------------------------------------------


func test_every_pickup_is_inside_its_own_band() -> void:
	var extents := _band_extents()
	assert_false(extents.is_empty(), "terrain_playground.json declares no trail bands")
	for entry: Variant in BAND_PICKUPS.load_all():
		var pickup: Dictionary = entry
		var band := str(pickup["band"])
		assert_true(extents.has(band), "band '%s' has no spine extent" % band)
		if not extents.has(band):
			continue
		var z := (pickup["pos"] as Vector2).y
		var lo := float((extents[band] as Array)[0]) - EXTENT_SLACK_M
		var hi := float((extents[band] as Array)[1]) + EXTENT_SLACK_M
		assert_true(z >= lo and z <= hi,
			"pickup '%s' sits at z=%.0f, outside %s's extent [%.0f, %.0f]" % [str(pickup["id"]), z, band, lo, hi])


func test_every_pickup_is_inside_the_authored_world() -> void:
	var bounds := ALIGNMENT.world_bounds(_read_json(TERRAIN_PATH))
	for entry: Variant in BAND_PICKUPS.load_all():
		var pickup: Dictionary = entry
		var at: Vector2 = pickup["pos"]
		assert_true(at.x >= float(bounds.get("min_x", -256.0)) and at.x <= float(bounds.get("max_x", 256.0))
			and at.y >= float(bounds.get("min_z", -256.0)) and at.y <= float(bounds.get("max_z", 256.0)),
			"pickup '%s' at %s is outside the authored world bounds %s" % [str(pickup["id"]), str(at), str(bounds)])


func test_no_two_pickups_contest_the_same_prompt() -> void:
	var pickups := BAND_PICKUPS.load_all()
	for i in pickups.size():
		for j in range(i + 1, pickups.size()):
			var a: Vector2 = (pickups[i] as Dictionary)["pos"]
			var b: Vector2 = (pickups[j] as Dictionary)["pos"]
			assert_true(a.distance_to(b) >= MIN_SEPARATION_M,
				"pickups '%s' and '%s' are %.1fm apart; one prompt will always beat the other" % [
					str((pickups[i] as Dictionary)["id"]), str((pickups[j] as Dictionary)["id"]), a.distance_to(b)])


func test_no_pickup_contests_a_harvest_node() -> void:
	var spots := _harvest_spots()
	assert_false(spots.is_empty(), "the merged harvest table is empty; this test would prove nothing")
	for entry: Variant in BAND_PICKUPS.load_all():
		var pickup: Dictionary = entry
		var at: Vector2 = pickup["pos"]
		for spot: Vector2 in spots:
			assert_true(at.distance_to(spot) >= MIN_SEPARATION_M,
				"pickup '%s' at %s is %.1fm from the harvest node at %s" % [
					str(pickup["id"]), str(at), at.distance_to(spot), str(spot)])


# --- the addendum's tiering ----------------------------------------------------


func test_the_critical_path_is_sparse_and_never_better_than_good() -> void:
	# Addendum section B: "critical path: sparse, mostly Good". Great and Rare
	# are the answer to "why should I explore over there?" and a Rare on the
	# road would be the placement that makes exploring pointless.
	for band: String in AUTHORED_BANDS:
		var candy := 0
		var critical_candy := 0
		for entry: Variant in BAND_PICKUPS.read_band(band):
			var spec: Dictionary = entry
			var item := str(spec.get("item", ""))
			if not item.ends_with("_candy"):
				continue
			candy += 1
			if str(spec.get("tier", "")) != "critical":
				continue
			critical_candy += 1
			assert_eq(item, "good_candy",
				"%s: '%s' puts a %s on the critical path" % [band, str(spec.get("id", "")), item])
		assert_true(candy > 0, "%s has no candy at all" % band)
		assert_true(critical_candy * 4 <= candy,
			"%s: %d of %d candies are on the critical path; the road must stay sparse" % [band, critical_candy, candy])


func test_every_tier_and_every_candy_grade_is_present_in_the_authored_bands() -> void:
	var tiers := {}
	var grades := {}
	for band: String in AUTHORED_BANDS:
		for entry: Variant in BAND_PICKUPS.read_band(band):
			var spec: Dictionary = entry
			tiers[str(spec.get("tier", ""))] = true
			grades[str(spec.get("item", ""))] = true
	for tier: String in BAND_PICKUPS.TIERS:
		assert_true(tiers.has(tier), "no authored pickup carries tier '%s'" % tier)
	for grade: String in ["good_candy", "great_candy", "rare_candy"]:
		assert_true(grades.has(grade), "no authored pickup is a %s" % grade)


# --- persistence, through the real seam ------------------------------------------


func test_flag_id_is_keyed_on_the_placement_not_the_item() -> void:
	assert_eq(BAND_PICKUPS.flag_id("b2_candy_quarry_ledge"), "cache:b2_candy_quarry_ledge")
	assert_ne(BAND_PICKUPS.flag_id("b2_candy_quarry_ledge"), ITEM_CACHE_PICKUP.flag_id("good_candy"),
		"a placement's flag must not be the item's flag, or every Good Candy shares one")


func test_a_collected_id_survives_a_save_round_trip() -> void:
	# `_on_picked_up()` resolves `/root/Game` by path and unit tests have no
	# SceneTree, so the two halves the seam exposes are exercised without one:
	# the flag it writes (`flag_id(_key())`, the node's own key -- see the
	# test below) and the restore path a reload takes.
	var game := FakePickupGame.new()
	var first: Node3D = ITEM_CACHE_PICKUP.new()
	first.call("setup", "good_candy", "Take the candy", "", 1.0, "b2_candy_quarry_ledge")
	game.progression.call("set_flag", ITEM_CACHE_PICKUP.flag_id(first.call("_key")))
	var saved: Dictionary = game.progression.call("save_data")
	var reloaded := FakePickupGame.new()
	reloaded.progression.call("load_data", saved)
	assert_true(bool(reloaded.progression.call("has", "cache:b2_candy_quarry_ledge")),
		"the collected placement's flag did not survive save/load")
	var again: Node3D = ITEM_CACHE_PICKUP.new()
	again.call("setup", "good_candy", "Take the candy", "", 1.0, "b2_candy_quarry_ledge")
	again.call("restore_progression_from_game", reloaded)
	assert_false(again.visible, "a reloaded game re-offered a placement that was already taken")
	again.free()
	first.free()
	game.free()
	reloaded.free()


func test_two_placements_of_the_same_item_have_independent_flags() -> void:
	# The defect the flag key exists to prevent: thirty Good Candies keyed on
	# "cache:good_candy" would all vanish the moment one was taken.
	var game := FakePickupGame.new()
	var first: Node3D = ITEM_CACHE_PICKUP.new()
	first.call("setup", "good_candy", "Take the candy", "", 1.0, "b2_candy_quarry_ledge")
	# The write `_on_picked_up()` makes when the satchel accepts the item.
	game.progression.call("set_flag", ITEM_CACHE_PICKUP.flag_id(first.call("_key")))
	var other: Node3D = ITEM_CACHE_PICKUP.new()
	other.call("setup", "good_candy", "Take the candy", "", 1.0, "b3_candy_mill_yard")
	other.call("restore_progression_from_game", game)
	assert_true(other.visible, "taking one Good Candy deactivated a different Good Candy placement")
	assert_false(ITEM_CACHE_PICKUP.was_taken(game, "b3_candy_mill_yard"))
	assert_true(ITEM_CACHE_PICKUP.was_taken(game, "b2_candy_quarry_ledge"))
	# And the old CACHE_AT caches, keyed on the item, are untouched by either.
	assert_false(ITEM_CACHE_PICKUP.was_taken(game, "good_candy"))
	first.free()
	other.free()
	game.free()


func test_the_nodes_key_is_the_placement_id_not_the_item() -> void:
	# The write `_on_picked_up()` makes is `flag_id(_key())`; a node set up
	# with a placement id must key on it, and one set up without must keep
	# keying on the item exactly as every `CACHE_AT` cache always has.
	var placed: Node3D = ITEM_CACHE_PICKUP.new()
	placed.call("setup", "great_candy", "Take the candy", "", 1.0, "b3_candy_springhead")
	assert_eq(str(placed.call("_key")), "b3_candy_springhead")
	placed.free()
	var legacy: Node3D = ITEM_CACHE_PICKUP.new()
	legacy.call("setup", "elixir_might", "Take the elixir", "", 1.0)
	assert_eq(str(legacy.call("_key")), "elixir_might", "a cache with no flag key must still key on its item")
	legacy.free()


func test_label_follows_the_item_family() -> void:
	assert_eq(BAND_PICKUPS.label_for("good_candy"), "Take the candy")
	assert_eq(BAND_PICKUPS.label_for("wild_mushroom"), "Take the mushroom")
	assert_eq(BAND_PICKUPS.label_for("potion_large"), "Take the potion")
	assert_eq(BAND_PICKUPS.label_for("revive"), "Take the revive")


# --- the tier look ---------------------------------------------------------------


func _walk(node: Node) -> Array[Node]:
	var out: Array[Node] = [node]
	for child in node.get_children():
		out.append_array(_walk(child))
	return out


func _built(item_id: String, key: String) -> Node3D:
	var items: Dictionary = _read_json(ITEMS_PATH).get("items", {}) as Dictionary
	var definition: Dictionary = items.get(item_id, {}) as Dictionary
	var node: Node3D = ITEM_CACHE_PICKUP.new()
	node.call("setup", item_id, BAND_PICKUPS.label_for(item_id), str(definition.get("world_model", "")),
		float(definition.get("world_model_scale", 1.0)), key)
	BAND_PICKUPS.dress(node, item_id, Color.WHITE)
	return node


func _names(node: Node) -> Array[String]:
	var out: Array[String] = []
	for descendant in _walk(node):
		out.append(descendant.name)
	return out


func test_rare_candy_grows_wings_and_a_medallion_and_good_candy_does_not_grow_wings() -> void:
	var rare := _built("rare_candy", "t_rare")
	var names := _names(rare)
	assert_true(names.has("TierMedallion"), "rare candy has no medallion")
	assert_true(names.has("RareWingL") and names.has("RareWingR"), "rare candy has no wings")
	rare.free()
	var good := _built("good_candy", "t_good")
	names = _names(good)
	assert_true(names.has("TierMedallion"), "good candy has no medallion")
	assert_false(names.has("RareWingL"), "good candy grew wings")
	good.free()


func test_the_three_candy_tiers_are_tinted_differently() -> void:
	var tints := {}
	for grade: String in ["good_candy", "great_candy", "rare_candy"]:
		var node := _built(grade, "t_" + grade)
		var tinted: Color = Color.BLACK
		for descendant in _walk(node):
			if descendant is MeshInstance3D and descendant.name != "TierMedallion" and not descendant.name.begins_with("RareWing"):
				var material: Material = (descendant as MeshInstance3D).material_override
				assert_true(material is StandardMaterial3D, "%s's body carries no tinted override" % grade)
				if material is StandardMaterial3D:
					tinted = (material as StandardMaterial3D).albedo_color
				break
		tints[grade] = tinted
		node.free()
	assert_false((tints["good_candy"] as Color).is_equal_approx(tints["great_candy"] as Color), "Good and Great share a tint")
	assert_false((tints["great_candy"] as Color).is_equal_approx(tints["rare_candy"] as Color), "Great and Rare share a tint")
	assert_false((tints["good_candy"] as Color).is_equal_approx(tints["rare_candy"] as Color), "Good and Rare share a tint")


func test_the_candy_tiers_step_up_in_size_not_only_in_hue() -> void:
	# Round 1's code-blind judge could not read the ladder from hue alone
	# ("grade is carried entirely by a colour with no key attached to it").
	# A tier now also differs in size, so the ladder survives a frame where
	# the hue does not.
	var sizes := {}
	for grade: String in ["good_candy", "great_candy", "rare_candy"]:
		var node := _built(grade, "s_" + grade)
		for descendant in _walk(node):
			if descendant is MeshInstance3D and descendant.name != "TierMedallion" and not descendant.name.begins_with("RareWing"):
				sizes[grade] = (descendant as Node3D).scale.x
				break
		node.free()
	assert_true(float(sizes["great_candy"]) > float(sizes["good_candy"]),
		"Great is not larger than Good (%s vs %s)" % [str(sizes["great_candy"]), str(sizes["good_candy"])])
	assert_true(float(sizes["rare_candy"]) > float(sizes["great_candy"]),
		"Rare is not larger than Great (%s vs %s)" % [str(sizes["rare_candy"]), str(sizes["great_candy"])])


func test_a_higher_tier_glows_harder() -> void:
	# The other half of the ladder: Rare's hue has to sit ON TOP of the
	# wrapper texture (emission adds) rather than under it (albedo
	# multiplies), which is what made round 1's Rare read as the most washed
	# out of the three.
	var energies := {}
	for grade: String in ["good_candy", "great_candy", "rare_candy"]:
		var node := _built(grade, "e_" + grade)
		for descendant in _walk(node):
			if descendant is MeshInstance3D and descendant.name != "TierMedallion" and not descendant.name.begins_with("RareWing"):
				var material: Material = (descendant as MeshInstance3D).material_override
				assert_true(material is StandardMaterial3D, "%s has no override" % grade)
				var standard := material as StandardMaterial3D
				assert_true(standard.emission_enabled, "%s does not glow at all" % grade)
				energies[grade] = standard.emission_energy_multiplier
				break
		node.free()
	assert_true(float(energies["great_candy"]) > float(energies["good_candy"]),
		"Great does not glow harder than Good")
	assert_true(float(energies["rare_candy"]) > float(energies["great_candy"]),
		"Rare does not glow harder than Great")


func test_realm_pickups_preserve_shipped_meadows_keys_and_isolate_other_realms() -> void:
	assert_eq(ITEM_CACHE_PICKUP.flag_id("good_candy", "b2_candy_quarry_ledge", "meadows"), "cache:b2_candy_quarry_ledge")
	assert_eq(ITEM_CACHE_PICKUP.flag_id("good_candy", "b2_candy_quarry_ledge", "cloudreach"), "cache:cloudreach:b2_candy_quarry_ledge")
	assert_eq(ITEM_CACHE_PICKUP.flag_id("elixir_attack"), "cache:elixir_attack")


func test_the_wild_shroom_is_broader_than_the_stamina_shroom() -> void:
	var wild := _built("wild_mushroom", "t_wild")
	var stamina := _built("stamina_mushroom", "t_stamina")
	var wild_scale := Vector3.ONE
	var stamina_scale := Vector3.ONE
	for descendant in _walk(wild):
		if descendant is MeshInstance3D:
			wild_scale = (descendant as Node3D).scale
			break
	for descendant in _walk(stamina):
		if descendant is MeshInstance3D:
			stamina_scale = (descendant as Node3D).scale
			break
	assert_true(wild_scale.x > stamina_scale.x and wild_scale.z > stamina_scale.z,
		"the Wild Shroom's cap is not broader (%s vs %s)" % [str(wild_scale), str(stamina_scale)])
	wild.free()
	stamina.free()
