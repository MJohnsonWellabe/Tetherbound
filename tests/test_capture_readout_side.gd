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


func test_side_readout_ships_on_with_its_score() -> void:
	var cfg: Dictionary = RETICLE.load_readout_visual()
	assert_true(bool(cfg.get("readout_side_enabled", false)), "side readout ships ON (judged gain)")
	assert_true(str(cfg.get("_why_side_on", "")).contains("6.91"), "side readout records its mapped score")


func test_calm_seal_follows_catch_card() -> void:
	var orb := preload("res://scripts/combat/orb.gd")
	var hud: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/hud.json"))
	var card: Dictionary = hud.get("catch_card", {})
	var seal_on: bool = card.get("enabled") == true and (card.get("calm_seal", {}) as Dictionary).get("enabled") == true
	assert_eq(not orb.calm_seal_config().is_empty(), seal_on,
		"calm seal glow is read only while hud.json catch_card is enabled (ON since VIS-CLOUDREACH r2b, 4 Nov)")


## Visual lane (3 Nov): the contrast round 2 (larger primary caption, near-opaque
## plate) ships OFF until judged and only ever raises legibility.
func test_contrast_r2_ships_on_and_only_raises_legibility() -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/capture_readout_visual.json"))
	var r2: Dictionary = cfg.get("contrast_r2", {})
	assert_true(bool(r2.get("enabled", false)), "contrast_r2 ships ON (judged gain)")
	assert_true(str(r2.get("_why", "")).contains("6.91"), "contrast_r2 records its mapped score")
	assert_true(int(r2.get("caption_px", 0)) >= 26, "the caption never shrinks below the shipped 26 px")
	assert_true(float(r2.get("backing_opacity", 0.0)) >= float(cfg.get("backing_opacity", 0.85)), "the plate never gets more transparent")
