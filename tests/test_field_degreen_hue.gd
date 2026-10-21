extends "res://tests/test_case.gd"

## Close-1020: the field-brightness push must never walk a creature's coat
## toward red (reserved for Team Tether). Bramblebun's olive-brown texture
## (field_emission 2.5, field_degreen 0.75) rendered red-orange because red and
## blue were boosted past green on `albedo_color`, which tints every texel.

const CREATURE_BODY := preload("res://scripts/creatures/creature_body.gd")
const OLIVE_BROWN := Color(0.48, 0.40, 0.22)


func _tinted(strength: float, degreen: float) -> Color:
	var material := StandardMaterial3D.new()
	var info := {"material": material, "orig_albedo": Color.WHITE, "orig_emission_mult": 1.0,
		"strength": strength, "degreen": degreen, "species_id": "test_degreen_hue"}
	CREATURE_BODY._apply_field_bright_values(info)
	var tint: Color = material.albedo_color
	return Color(OLIVE_BROWN.r * tint.r, OLIVE_BROWN.g * tint.g, OLIVE_BROWN.b * tint.b)


func test_degreen_keeps_olive_brown_hue() -> void:
	CREATURE_BODY.set_field_brightness_scale(1.0)
	for pair: Array in [[2.5, 0.75], [0.9, 1.0], [0.6, 0.0], [2.2, 0.0]]:
		var out := _tinted(pair[0], pair[1])
		assert_almost_eq(out.h, OLIVE_BROWN.h, 0.002, "hue moved at strength %s degreen %s" % pair)
		assert_true(out.r / out.g <= OLIVE_BROWN.r / OLIVE_BROWN.g + 0.0001,
			"red rose against green at strength %s degreen %s" % pair)
		assert_true(out.g > out.b, "coat lost its green-over-blue order at %s" % [pair])


func test_degreen_still_trims_the_push() -> void:
	CREATURE_BODY.set_field_brightness_scale(1.0)
	assert_true(_tinted(2.5, 0.75).v < _tinted(2.5, 0.0).v, "field_degreen no longer trims the brightness push")
