extends "res://tests/test_case.gd"

## P2-058/P2-114 UIPOSES candidate: capture_readout_visual `readout_side_enabled`
## places the percentage and caption beside the ring, off the target body.

const RETICLE := preload("res://scripts/ui/capture_reticle.gd")
const VIEW := Vector2(1920, 1080)


func test_side_readout_sits_right_of_ring_and_clear_of_it() -> void:
	var center := Vector2(900, 500)
	var placed: Array = RETICLE.side_readout_positions(center, 90.0, Vector2(80, 50), Vector2(200, 20), 40.0, VIEW, 36.0)
	var pct: Vector2 = placed[0]
	var caption: Vector2 = placed[1]
	assert_true(minf(pct.x, caption.x) >= center.x + 90.0 + 36.0 - 0.01, "readout starts past the ring edge")
	assert_true(caption.y > pct.y, "caption sits under the number")
	assert_true(absf((pct.y - 40.0 + caption.y) * 0.5 - center.y) < 30.0, "block is vertically centred on the ring")


func test_side_readout_flips_left_near_right_edge() -> void:
	var center := Vector2(1750, 500)
	var placed: Array = RETICLE.side_readout_positions(center, 90.0, Vector2(80, 50), Vector2(200, 20), 40.0, VIEW, 36.0)
	var caption: Vector2 = placed[1]
	assert_true(caption.x + 200.0 <= center.x - 90.0 - 36.0 + 0.01, "flipped readout ends before the ring's left edge")


func test_side_readout_stays_inside_safe_area() -> void:
	var placed: Array = RETICLE.side_readout_positions(Vector2(300, 1060), 90.0, Vector2(80, 50), Vector2(200, 20), 40.0, VIEW, 36.0)
	var caption: Vector2 = placed[1]
	assert_true(caption.y <= VIEW.y * 0.95 + 0.01, "caption baseline stays inside the bottom safe margin")


func test_side_readout_ships_off() -> void:
	var cfg: Dictionary = RETICLE.load_readout_visual()
	assert_false(bool(cfg.get("readout_side_enabled", true)), "candidate flag defaults OFF")
