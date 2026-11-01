extends "res://tests/test_case.gd"

## P2-012 r2 (vis-meadows, OFF until GPU-judged): `bank.hill_shell.r2` merges
## over the shipped hill shell only when enabled, and adds to its hidden nodes.

const WARRENS := preload("res://scripts/world/burrow_warrens.gd")
const CONFIG := "res://data/config/burrow_warrens.json"


func _config() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(CONFIG)) as Dictionary


func test_r2_ships_off_and_off_returns_the_shipped_shell() -> void:
	var cfg := _config()
	var shell: Dictionary = cfg.bank.hill_shell
	assert_false(bool(shell.r2.get("enabled", true)), "r2 ships OFF")
	assert_eq(JSON.stringify(WARRENS.hill_shell_config(cfg)), JSON.stringify(shell))


func test_r2_on_hides_mound_growth_and_moves_the_clip_behind_the_beam() -> void:
	var cfg := _config()
	cfg.bank.hill_shell.r2.enabled = true
	var on := WARRENS.hill_shell_config(cfg)
	assert_true("MoundGrowth" in (on.hide_nodes as Array))
	assert_true("Bank" in (on.hide_nodes as Array), "the shell's own hidden nodes stay")
	assert_true(float(on.clip_box.min[2]) > float(cfg.bank.hill_shell.clip_box.min[2]))
	assert_true(ResourceLoader.exists(str(on.detail_texture)), "detail texture is installed")
	assert_eq(str(on.model), str(cfg.bank.hill_shell.model), "unmentioned keys stay")
