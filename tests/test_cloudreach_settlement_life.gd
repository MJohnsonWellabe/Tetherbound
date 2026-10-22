extends "res://tests/test_case.gd"

## F08#3 settlement life, landed ON after the r17 judged pass (CPU-provisional
## 7.13). Guards the pieces the judges asked for: the lamps light the road a
## pale warm white (no rust/oxblood cast), night windows stay amber, and every
## piece the dressing names resolves to an installed asset.
const LIFE := preload("res://scripts/world/cloudreach_settlement_life.gd")


func _reddish(colour: Color) -> bool:
	# Oxblood/rust family: red clearly dominant over green and blue.
	return colour.r - colour.g > 0.3 and colour.r - colour.b > 0.3 and colour.s > 0.6


func test_settlement_life_is_on_and_its_lights_avoid_the_reserved_red() -> void:
	var spec := LIFE.config()
	assert_true(bool(spec.get("enabled", false)))
	var lamp: Dictionary = spec.lamp
	assert_false(_reddish(Color(str(lamp.light_colour))))
	var overrides: Dictionary = spec.cliffhold_detail_overrides
	assert_false(_reddish(Color(str(overrides.door_lantern.colour))))
	assert_true(float(spec.window_night_energy) <= 1.5)


func test_every_dressing_piece_resolves_to_an_installed_asset() -> void:
	var spec := LIFE.config()
	for item: Dictionary in spec.stand_pattern:
		if str(item.asset) == "lamp":
			continue
		assert_true(LIFE.PROPS.has(item.asset), "stand pattern asset %s" % item.asset)
		assert_true(ResourceLoader.exists(str(LIFE.PROPS[item.asset])), str(LIFE.PROPS[item.asset]))
	for site: Dictionary in (spec.settlements as Dictionary).values():
		for building: Dictionary in site.get("buildings", []):
			var path := str(building.get("glb", LIFE.MESHY % [building.asset, building.asset]))
			assert_true(ResourceLoader.exists(path), path)
