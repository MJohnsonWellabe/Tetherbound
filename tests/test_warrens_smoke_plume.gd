extends "res://tests/test_case.gd"
## camfx.json `smoke_plume` (F38#30): flag-off leaves every signal column's
## arguments exactly as authored; the block names only the Warrens post.

const PROPS := preload("res://scripts/world/props.gd")


func test_plume_flag_and_names() -> void:
	var spec := {"name": "WarrensVaultSignalPost", "smoke_top_m": 26.0, "smoke_alpha": 0.55,
		"smoke_top_size_m": 11.0, "smoke_fade": 0.55, "smoke_base_size_m": 1.4, "smoke_colour": "#bdb6ab"}
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/camfx.json"))
	var plume: Dictionary = cfg.get("smoke_plume", {})
	assert_true(not plume.is_empty(), "smoke_plume block present")
	assert_true(str(plume.get("scope", "")) == "client_presentation", "scope declared")
	assert_true((plume.get("names", []) as Array) == ["WarrensVaultSignalPost"], "names only the Warrens post")
	var on: bool = plume.get("enabled") == true
	var args := PROPS.smoke_column_args(spec)
	assert_true(args.size() == 7 or (on and args.size() == 9), "configure_smoke args")
	if on:
		assert_true(is_equal_approx(float(args[1]), 0.55 * float(plume["alpha_scale"])), "alpha scaled when on")
		assert_true(float(args[6]) > 0.0, "drift set when on")
	else:
		assert_true(is_equal_approx(float(args[1]), 0.55) and is_equal_approx(float(args[2]), 11.0)
			and is_equal_approx(float(args[4]), 0.55) and is_equal_approx(float(args[5]), 1.4)
			and float(args[6]) < 0.0, "off: column unchanged")
	var other := spec.duplicate()
	other["name"] = "SomeOtherSignal"
	var oargs := PROPS.smoke_column_args(other)
	assert_true(is_equal_approx(float(oargs[1]), 0.55) and float(oargs[6]) < 0.0, "unnamed posts untouched")

