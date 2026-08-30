extends "res://tests/test_case.gd"

## The shared pickup highlight (OP-0830-3).
##
## The owner's report was *"all items in the grass like tms, potions, orbs
## whatever should glow so they're visible"*, and the two ways that defect comes
## back are both covered here:
##
##   1. **A pickup path forgets to register.** The repo has six of them and the
##      whole point of the shared treatment is that adding a seventh is one
##      call. `test_every_pickup_path_attaches_the_shared_highlight` reads the
##      scripts and fails if one draws a pickup without asking for the glow.
##   2. **The grass grows past the mote.** This is the specific trap the lane
##      order named: the ground lane is raising grass density, and a highlight
##      tuned against today's carpet is a highlight that stops working when
##      theirs ships. Height is what beats grass, not brightness, so the mote
##      height is asserted against `grass_field.json`'s OWN blade numbers rather
##      than against a constant copied out of them -- if the grass gets taller,
##      this fails and names the number to move.
##
## Nothing here pins a look. Radii, colours, pulse and fade are the owner's to
## move on the Ally, and a test that pinned them would break every time the glow
## was made to feel better.

const GLOW := preload("res://scripts/world/pickup_glow.gd")

const GRASS_CONFIG := "res://data/config/grass_field.json"

## Every script that puts a takeable thing in the world. A seventh belongs in
## this list on the day it is written.
const PICKUP_SCRIPTS := [
	"res://scripts/world/key_pickup.gd",
	"res://scripts/world/tm_pickup.gd",
	"res://scripts/world/item_cache_pickup.gd",
	"res://scripts/world/harvest_node.gd",
	"res://scripts/world/felled_resource.gd",
	"res://scripts/world/death_satchel.gd",
]


func _read(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	assert_true(file != null, "could not read %s" % path)
	return "" if file == null else file.get_as_text()


func _json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(_read(path))
	return parsed if parsed is Dictionary else {}


# --- coverage -------------------------------------------------------------

func test_every_pickup_path_attaches_the_shared_highlight() -> void:
	for path: String in PICKUP_SCRIPTS:
		var source := _read(path)
		assert_true(source.contains("PICKUP_GLOW.attach("),
			"%s draws a world pickup but never registers it with the shared highlight; "
			% path + "OP-0830-3 is 'every item in the grass', not 'the ones someone remembered'")


func test_no_pickup_keeps_a_light_of_its_own() -> void:
	# OP-0830-6 (ROG performance) is open, the world holds well over a hundred
	# pickups, and two of these scripts used to carry an `OmniLight3D` each.
	# The shared highlight is what replaced them and this is what stops the
	# next pickup from reaching for a light again.
	for path: String in PICKUP_SCRIPTS:
		# The CONSTRUCTOR, not the word: both scripts carry a comment recording
		# why the light they used to build was removed, and that history is
		# worth keeping.
		assert_false(_read(path).contains("OmniLight3D.new("),
			"%s gives a pickup its own light; the shared highlight exists so a "
			% path + "hundred-plus pickups cost two draw calls, not a hundred lights")


# --- the grass rule -------------------------------------------------------

func test_the_mote_clears_the_grass_canopy_that_is_shipping() -> void:
	# The whole reason this treatment is a HEIGHT rather than a brightness.
	# Blades are opaque geometry; emission does not get you through one.
	var grass := _json(GRASS_CONFIG)
	var tallest := float(grass.get("height_far", 0.62)) \
		* (1.0 + float(grass.get("height_jitter", 0.38)))
	var mote := float(GLOW.config().get("mote", {}).get("height", 0.0))
	assert_true(mote > tallest,
		"the pickup mote sits at %.2fm and the grass field's tallest blade is %.2fm -- "
		% [mote, tallest] + "raise `mote.height` in data/config/pickup_glow.json, or the "
		+ "highlight is inside the carpet it is supposed to beat")


func test_the_mote_clears_it_with_margin_not_by_a_hair() -> void:
	var grass := _json(GRASS_CONFIG)
	var tallest := float(grass.get("height_far", 0.62)) \
		* (1.0 + float(grass.get("height_jitter", 0.38)))
	var mote := float(GLOW.config().get("mote", {}).get("height", 0.0))
	assert_true(mote - tallest >= 0.2,
		"only %.2fm of clearance between the mote and the tallest blade; the ground "
		% (mote - tallest) + "lane is still raising density and a hair of margin is a "
		+ "regression waiting for their next push")


# --- tint -----------------------------------------------------------------

func test_a_dark_item_colour_still_produces_a_visible_glow() -> void:
	# `items.json` authors ALBEDO. `wood` is #7a5a35 -- correct for a surface,
	# nearly invisible as additive light. Without normalisation a deadwood pile
	# would get a highlight that does not highlight, purely because of what the
	# item happens to be made of.
	var wood := GLOW.glow_tint(Color("#7a5a35"))
	assert_true(wood.v >= 0.8,
		"a dark item colour glows at value %.2f; an additive glow that dark adds "
		% wood.v + "almost nothing to the frame")


func test_the_glow_keeps_the_items_own_hue() -> void:
	# Brightness is this system's; identity is the object's. A world where every
	# pickup glows the same colour tells the player less than one where a fiber
	# node reads green and the gate key reads gold.
	var fiber := GLOW.glow_tint(Color("#9aa64a"))
	var key := GLOW.glow_tint(Color("#c9a227"))
	assert_true(absf(fiber.h - Color("#9aa64a").h) < 0.02, "the tint lost the item's hue")
	assert_true(absf(fiber.h - key.h) > 0.02,
		"two differently-coloured items glow the same hue; the tint is flattening "
		+ "everything to one colour")


func test_a_grey_item_is_not_given_an_invented_hue() -> void:
	# `stone` is #8e8d86 -- saturation near zero, where the hue channel means
	# nothing. Clamping saturation UP would read that meaningless hue and glow a
	# stone deposit pink. Saturation is capped, never floored.
	var stone := GLOW.glow_tint(Color("#8e8d86"))
	assert_true(stone.s < 0.15,
		"a near-grey item was given saturation %.2f; a stone deposit glowing a "
		% stone.s + "colour is worse than one glowing warm white")


# --- restraint ------------------------------------------------------------

func test_the_glow_gets_out_of_the_way_up_close() -> void:
	# "Tasteful, not a loot-beam shooter." Inside a few metres the player can
	# see the object; a glow that stayed at full strength there would be sitting
	# on top of the thing it was pointing at.
	var distance: Dictionary = GLOW.config().get("distance", {})
	var floor_value := float(distance.get("near_floor", 1.0))
	assert_true(floor_value < 1.0,
		"the highlight never dims as the player arrives (near_floor %.2f)" % floor_value)
	assert_true(floor_value > 0.0,
		"the highlight vanishes entirely up close (near_floor %.2f); an item at your "
		% floor_value + "feet in tall grass is still the case being solved")


func test_the_glow_stops_before_it_becomes_a_map_marker() -> void:
	var distance: Dictionary = GLOW.config().get("distance", {})
	var fade_end := float(distance.get("far_fade_end", 0.0))
	assert_true(fade_end > 0.0 and fade_end < 120.0,
		"far_fade_end is %.1fm; a pickup glow readable across the whole meadow is a "
		% fade_end + "quest marker, not an affordance")
	assert_true(float(distance.get("far_fade_start", 0.0)) < fade_end,
		"the far fade must start before it ends")


func test_the_mote_never_floats_off_the_object_it_marks() -> void:
	var mote: Dictionary = GLOW.config().get("mote", {})
	var ceiling := float(mote.get("max_height", 0.0))
	assert_true(ceiling >= float(mote.get("height", 0.0)),
		"max_height is below the configured floor height, so tall props would be "
		+ "clamped BELOW their own crown")
	assert_true(ceiling <= 3.0,
		"max_height %.2f puts the mote above head height on a tall prop, which reads "
		% ceiling + "as a waypoint rather than as the object glowing")


func test_the_prop_clearance_rule_lifts_a_mote_over_a_tall_prop() -> void:
	# `prop_clearance_height` is what stops the mote rendering INSIDE a felled
	# log or a rootstone deposit. Built from primitives so this stays a unit
	# test rather than a scene test.
	var node := Node3D.new()
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.6, 1.8, 0.6)
	mesh.mesh = box
	mesh.position = Vector3.UP * 0.9
	node.add_child(mesh)

	var floor_height := float(GLOW.config().get("mote", {}).get("height", 1.15))
	var lifted := GLOW.prop_clearance_height(node, floor_height)
	assert_true(lifted > floor_height,
		"a 1.8m prop did not push the mote above the configured floor (%.2f)" % lifted)
	assert_true(lifted <= float(GLOW.config().get("mote", {}).get("max_height", 2.2)) + 0.001,
		"the clearance rule ignored its own ceiling (%.2f)" % lifted)
	node.free()


func test_a_short_prop_keeps_the_configured_grass_clearing_height() -> void:
	# The TM orb is 20cm. Nothing about a small object should pull the mote back
	# down into the grass.
	var node := Node3D.new()
	var mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.1
	sphere.height = 0.2
	mesh.mesh = sphere
	mesh.position = Vector3.UP * 0.1
	node.add_child(mesh)

	var floor_height := float(GLOW.config().get("mote", {}).get("height", 1.15))
	assert_almost_eq(GLOW.prop_clearance_height(node, floor_height), floor_height, 0.001,
		"a 20cm pickup moved the mote off the configured grass-clearing height")
	node.free()
