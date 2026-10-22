extends "res://tests/test_case.gd"

## F40 #1 Cloudreach items, landed ON at the owner's wind-down (every judged
## batch beat its shipping control; none reached the bar). Guards the promises
## the config makes: visual only (no new colliders without route re-proof),
## every piece resolves to an installed asset, and no reserved red in the
## window or cloud colours.
const LIFE := preload("res://scripts/world/cloudreach_settlement_life.gd")


func _reddish(colour: Color) -> bool:
	# Red/oxblood hue (within ~20 degrees of red), not amber or orange.
	return (colour.h < 0.055 or colour.h > 0.95) and colour.s > 0.5


func test_items_are_on_and_add_no_collision() -> void:
	var spec := LIFE.items_config()
	assert_true(bool(spec.get("enabled", false)))
	for site: Dictionary in (spec.settlements as Dictionary).values():
		for building: Dictionary in site.get("buildings", []):
			assert_almost_eq(float(building.get("collision_fraction", 0.8)), 0.0, 0.0001,
				"%s must stay visual only" % building.asset)


func test_every_item_piece_resolves_to_an_installed_asset() -> void:
	var spec := LIFE.items_config()
	var stand_ids := {}
	for site: Dictionary in (spec.settlements as Dictionary).values():
		for stand: Dictionary in site.get("stands", []):
			stand_ids[str(stand.id)] = true
		for building: Dictionary in site.get("buildings", []):
			var path := str(building.get("glb", LIFE.MESHY % [building.asset, building.asset]))
			assert_true(ResourceLoader.exists(path), path)
	for item: Dictionary in spec.stand_pattern:
		assert_true(LIFE.PROPS.has(item.asset), "stand pattern asset %s" % item.asset)
		assert_true(ResourceLoader.exists(str(LIFE.PROPS[item.asset])), str(LIFE.PROPS[item.asset]))
		for id: Variant in item.get("only_stands", []):
			assert_true(stand_ids.has(str(id)), "only_stands names a missing stand %s" % id)


func test_item_colours_avoid_the_reserved_red() -> void:
	var spec := LIFE.items_config()
	assert_false(_reddish(Color(str(spec.window_colour))))
	var rings: Array = spec.get("cloud_rings", []).duplicate()
	rings.append(spec.cloud_ring)
	for ring: Dictionary in rings:
		assert_false(_reddish(Color(str(ring.tint))))
		assert_false(_reddish(Color(str(ring.night_tint))))
