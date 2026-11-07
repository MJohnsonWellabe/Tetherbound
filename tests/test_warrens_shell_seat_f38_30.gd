extends "res://tests/test_case.gd"

## F38#30 (LANE-MS, owner 7 Nov): the Burrow Warrens hill shell is re-seated
## 5 m into the terrain so its lip meets the meadow; judged CPU 2.95 -> 3.51.

const PATH := "res://data/config/burrow_warrens.json"


func test_hill_shell_sits_into_the_terrain_with_its_score() -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	var shell: Dictionary = cfg.bank.hill_shell
	assert_true(bool(shell.enabled), "the shell stays on")
	assert_true(float(shell.at[1]) <= -5.0, "base sunk below the meadow round the site")
	assert_true(str(shell.get("_why_seat_on", "")).contains("2.95 -> 3.51"))
	assert_eq(float(shell.clip_box.min[2]), 1.4, "mouth clip unchanged: the entrance is kept")
