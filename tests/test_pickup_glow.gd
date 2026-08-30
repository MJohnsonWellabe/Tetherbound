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
##   2. **The grass grows past the glow.** This is the specific trap the lane
##      order named: the ground lane is raising grass density, and a highlight
##      tuned against today's carpet is one that stops working when theirs
##      ships. Blades are opaque, so the glow has to physically reach above them
##      -- and it does that by RADIUS, because the owner's directive puts its
##      centre down on the item. The reach is asserted against
##      `grass_field.json`'s OWN blade numbers rather than a constant copied out
##      of them, so taller grass fails here and names the number to move.
##   3. **The glow eats the item.** Two owner directives on 2026-08-30 --
##      *"glow on the actual item, not floating in the air above it"* and
##      *"don't make it take over the items actual geometry or design"* -- are
##      pinned by `test_the_glow_sits_on_the_item_not_above_it` and
##      `test_the_glow_does_not_paint_over_the_item`. Both describe failures
##      this treatment has actually shipped once each.
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

## The tallest blade `grass_field.json` can currently grow.
func _tallest_blade() -> float:
	var grass := _json(GRASS_CONFIG)
	return float(grass.get("height_far", 0.62)) \
		* (1.0 + float(grass.get("height_jitter", 0.38)))


func test_the_glow_reaches_above_the_grass_canopy_that_is_shipping() -> void:
	# Blades are opaque geometry; emission does not get you through one, so the
	# glow has to physically extend above the carpet to be seen over it.
	#
	# It does that by RADIUS, not by altitude. The owner's directive is that the
	# glow is on the item -- so its centre sits low, on the prop's own body, and
	# what clears the grass is the top of the halo. This asserts the reach
	# against `grass_field.json`'s OWN numbers rather than a constant copied out
	# of them: if the ground lane raises blade height or jitter, this fails and
	# names the number to move.
	var mote: Dictionary = GLOW.config().get("mote", {})
	var reach := float(mote.get("height", 0.0)) + float(mote.get("radius", 0.0))
	var tallest := _tallest_blade()
	assert_true(reach > tallest,
		"the glow reaches %.2fm and the grass field's tallest blade is %.2fm -- "
		% [reach, tallest] + "raise `mote.radius` in data/config/pickup_glow.json "
		+ "(NOT `mote.height`, which would lift it off the item), or the highlight "
		+ "is inside the carpet it is supposed to beat")


func test_it_reaches_over_the_grass_with_margin_not_by_a_hair() -> void:
	var mote: Dictionary = GLOW.config().get("mote", {})
	var reach := float(mote.get("height", 0.0)) + float(mote.get("radius", 0.0))
	var margin := reach - _tallest_blade()
	assert_true(margin >= 0.1,
		"only %.2fm of reach above the tallest blade; the ground lane is still "
		% margin + "raising density and a hair of margin is a regression waiting "
		+ "for their next push")


func test_the_glow_sits_on_the_item_not_above_it() -> void:
	# OWNER DIRECTIVE, 2026-08-30: *"glow on the actual item, not floating in the
	# air above it."* The first version hung the mark at 1.15m, above the grass
	# canopy, which is exactly what this now forbids -- a light hovering over an
	# object is a waypoint marker, not an object that glows.
	var mote: Dictionary = GLOW.config().get("mote", {})
	var centre := float(mote.get("height", 0.0))
	assert_true(centre <= _tallest_blade(),
		"the glow's centre is at %.2fm, above the %.2fm grass canopy -- it is "
		% [centre, _tallest_blade()] + "floating over the item rather than sitting "
		+ "on it. Reach over the grass with `mote.radius` instead.")
	assert_true(centre > 0.0, "the glow's centre is at or below ground level")


func test_the_glow_does_not_paint_over_the_item() -> void:
	# OWNER DIRECTIVE, 2026-08-30: *"don't make it take over the items actual
	# geometry or design. just add the glow to them."*
	#
	# A camera-facing quad centred on a small prop covers it, and the player
	# sees a bright disc where the object used to be. `behind` pushes the quad
	# away from the camera so the prop's own opaque geometry occludes the middle
	# of its glow and only the halo escapes. Without it, the treatment replaces
	# the item it is supposed to be pointing at.
	var behind := float(GLOW.config().get("mote", {}).get("behind", 0.0))
	assert_true(behind > 0.0,
		"`mote.behind` is %.2f, so the halo is drawn ON TOP of the item rather "
		% behind + "than behind it; the object it marks stops being visible")


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


func test_the_glow_never_drifts_off_the_object_it_marks() -> void:
	var mote: Dictionary = GLOW.config().get("mote", {})
	var ceiling := float(mote.get("max_height", 0.0))
	assert_true(ceiling >= float(mote.get("height", 0.0)),
		"max_height is below the configured floor height, so a short prop would be "
		+ "clamped ABOVE its own centre")
	assert_true(ceiling <= 1.6,
		"max_height %.2f puts the glow above waist height even on a tall prop, "
		% ceiling + "which reads as a waypoint rather than as the object glowing")


func test_a_tall_prop_glows_through_its_own_body() -> void:
	# `prop_glow_height` centres the halo on the prop, so a felled log glows
	# through its trunk rather than over its head OR down at its feet. Built from
	# primitives so this stays a unit test rather than a scene test.
	var node := Node3D.new()
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.6, 1.8, 0.6)
	mesh.mesh = box
	mesh.position = Vector3.UP * 0.9
	node.add_child(mesh)

	var floor_height := float(GLOW.config().get("mote", {}).get("height", 0.28))
	var placed := GLOW.prop_glow_height(node, floor_height)
	assert_true(placed > floor_height,
		"a 1.8m prop put its glow at the same height as a 20cm one (%.2f)" % placed)
	assert_true(placed < 1.8,
		"the glow sits at %.2f on a 1.8m prop -- above its crown, which is the "
		% placed + "floating-marker failure the owner rejected")
	node.free()


func test_a_short_prop_keeps_the_glow_down_on_itself() -> void:
	# The TM orb is 20cm. A small object must not have its glow hoisted into the
	# air; it glows where it is, and the halo's radius is what reaches the eye.
	var node := Node3D.new()
	var mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.1
	sphere.height = 0.2
	mesh.mesh = sphere
	mesh.position = Vector3.UP * 0.1
	node.add_child(mesh)

	var floor_height := float(GLOW.config().get("mote", {}).get("height", 0.28))
	assert_almost_eq(GLOW.prop_glow_height(node, floor_height), floor_height, 0.001,
		"a 20cm pickup moved its glow off the prop")
	node.free()
