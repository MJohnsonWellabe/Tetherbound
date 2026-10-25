extends "res://tests/test_case.gd"

## The F38 matrix captures with --f38-baseline. Shipped (enabled) dressing must
## survive it; only an OFF layer is withheld or forced by the matrix flags.

const CATALOG := preload("res://scripts/world/meadows_catalog_presentation.gd")


func test_shipped_layer_survives_baseline() -> void:
	assert_true(CATALOG.resolve_active(true, PackedStringArray(["--f38-baseline"])))
	assert_true(CATALOG.resolve_active(true, PackedStringArray()))


func test_off_layer_only_shows_for_candidate() -> void:
	assert_false(CATALOG.resolve_active(false, PackedStringArray()))
	assert_false(CATALOG.resolve_active(false, PackedStringArray(["--f38-baseline"])))
	assert_true(CATALOG.resolve_active(false, PackedStringArray(["--f38-candidate"])))
