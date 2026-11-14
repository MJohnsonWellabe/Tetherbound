extends SceneTree
## camfx.json `smoke_plume` (F38#30): flag-off leaves every signal column's
## arguments exactly as authored; the block names only the Warrens post.

const PROPS := preload("res://scripts/world/props.gd")

var failures := 0


func _initialize() -> void:
	var spec := {"name": "WarrensVaultSignalPost", "smoke_top_m": 26.0, "smoke_alpha": 0.55,
		"smoke_top_size_m": 11.0, "smoke_fade": 0.55, "smoke_base_size_m": 1.4, "smoke_colour": "#bdb6ab"}
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/camfx.json"))
	var plume: Dictionary = cfg.get("smoke_plume", {})
	_check(not plume.is_empty(), "smoke_plume block present")
	_check(str(plume.get("scope", "")) == "client_presentation", "scope declared")
	_check((plume.get("names", []) as Array) == ["WarrensVaultSignalPost"], "names only the Warrens post")
	var args := PROPS.smoke_column_args(spec)
	_check(args.size() == 7, "seven configure_smoke args")
	var on: bool = plume.get("enabled") == true
	if on:
		_check(is_equal_approx(float(args[1]), 0.55 * float(plume["alpha_scale"])), "alpha scaled when on")
		_check(float(args[6]) > 0.0, "drift set when on")
	else:
		_check(is_equal_approx(float(args[1]), 0.55) and is_equal_approx(float(args[2]), 11.0)
			and is_equal_approx(float(args[4]), 0.55) and is_equal_approx(float(args[5]), 1.4)
			and float(args[6]) < 0.0, "off: column unchanged")
	var other := spec.duplicate()
	other["name"] = "SomeOtherSignal"
	var oargs := PROPS.smoke_column_args(other)
	_check(is_equal_approx(float(oargs[1]), 0.55) and float(oargs[6]) < 0.0, "unnamed posts untouched")
	print("test_warrens_smoke_plume: 1 tests, %d failed" % failures)
	quit(1 if failures > 0 else 0)


func _check(cond: bool, msg: String) -> void:
	if not cond:
		failures += 1
		push_error("FAIL: " + msg)
