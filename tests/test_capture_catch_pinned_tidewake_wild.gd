extends "res://tests/test_case.gd"

## F39#9 (VIS-TIDEWAKE, 4 Nov 2026): the Tidewake catch capture pins a First
## Shore wild from --seed (tools/phase2_capture_catch.gd::pinned_tidewake_wild).

const CAPTURE := preload("res://tools/phase2_capture_catch.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")


func test_same_seed_same_tidewake_wild() -> void:
	var a: Dictionary = CAPTURE.pinned_tidewake_wild(2042)
	var b: Dictionary = CAPTURE.pinned_tidewake_wild(2042)
	assert_eq(str(a["species"]), str(b["species"]), "same seed, same species")
	assert_eq(a["xz"], b["xz"], "same seed, same spot")
	assert_eq(int(a["level"]), int(b["level"]), "same seed, same level")


func test_every_pinned_tidewake_species_exists() -> void:
	for seed_value in range(6):
		var pin: Dictionary = CAPTURE.pinned_tidewake_wild(seed_value)
		assert_true(SPECIES.has(str(pin["species"])), "%s is a real species" % pin["species"])
