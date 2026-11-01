extends "res://tests/test_case.gd"

## Cause lane tb/cause-meadows (OFF until GPU-judged). Three flags:
## meadows_look.json `cause_light` (biome light/grade), meadows_look.json
## `cause_ground` (terrain shader, grass zones, viewport texture clarity) and
## capture_stands.json `buried_stand_guard` (P2-014 capture stands).
## OFF changes nothing; ON applies the intended keys.

const LOOK := preload("res://scripts/world/meadows_look.gd")
const GRASS := preload("res://scripts/world/grass_field.gd")
const PLAYGROUND := preload("res://scripts/world/playground_world.gd")
const CREATURE := preload("res://scripts/creatures/creature_body.gd")
const CAPTURE := preload("res://tools/phase2_capture_locations.gd")
const CONFIG := "res://data/config/meadows_look.json"
const STANDS := "res://data/config/capture_stands.json"
const FIXTURE := "user://test_meadows_cause_flags.json"


func _shipping(path: String = CONFIG) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(path)) as Dictionary


## The shipping file with the named blocks switched on, written to user://.
func _fixture(path: String, blocks: Array) -> String:
	var cfg := _shipping(path)
	for block: String in blocks:
		cfg[block].enabled = true
	var file := FileAccess.open(FIXTURE, FileAccess.WRITE)
	file.store_string(JSON.stringify(cfg))
	file.close()
	return FIXTURE


func after_each() -> void:
	super.after_each()
	CREATURE.set_field_rim_floor(0.0)
	if FileAccess.file_exists(FIXTURE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(FIXTURE))


func _base_look() -> Dictionary:
	return {"sun": {"energy": 1.5, "pitch_deg": -38.0},
		"environment": {"ambient_energy": 1.9, "fog_density": 0.001},
		"times": {"day": {"hour": 8.0, "environment": {"aerial_fade_colour": "#7f8c9e"}},
			"golden": {"hour": 18.0, "sun": {"pitch_deg": -16.0}, "environment": {"fog_density": 0.0016}},
			"night": {"environment": {"ambient_energy": 1.5, "exposure": 1.2}}}}


func test_all_three_ship_off_and_off_changes_nothing() -> void:
	var cfg := _shipping()
	assert_false(bool(cfg.cause_light.get("enabled", true)), "cause_light ships OFF")
	assert_false(bool(cfg.cause_ground.get("enabled", true)), "cause_ground ships OFF")
	assert_false(bool(_shipping(STANDS).buried_stand_guard.get("enabled", true)), "stand guard ships OFF")
	var base := _base_look()
	assert_eq(LOOK.cause_light_look(base, CONFIG), base)
	assert_true(LOOK.cause_ground_viewport(CONFIG).is_empty())
	assert_true(PLAYGROUND.meadows_cause_ground_shader(CONFIG).is_empty())
	var grass := {"zone_strength": 0.85, "cover_tiers": [{"name": "flowers", "patch_start": 0.6}]}
	var before := JSON.stringify(grass)
	GRASS.apply_meadows_cause_ground(grass, CONFIG)
	assert_eq(JSON.stringify(grass), before)
	assert_almost_eq(CAPTURE.stand_guard_window(STANDS), 0.0)
	assert_true(CAPTURE.stand_guard_offsets(STANDS).is_empty())


func test_light_on_warms_day_key_cools_fill_and_keeps_golden() -> void:
	var on := LOOK.cause_light_look(_base_look(), _fixture(CONFIG, ["cause_light"]))
	var day: Dictionary = on.times.day
	assert_almost_eq(float(day.sun.pitch_deg), -30.0)
	assert_true(float(day.sun.energy) > 1.5, "warmer, stronger key")
	assert_true(float(day.environment.ambient_energy) < 1.9, "weaker fill for a value range")
	assert_true(float(day.environment.fog_density) > 0.001, "aerial depth")
	assert_eq(str(day.environment.fog_colour), str(day.sky.horizon_colour), "fog meets the horizon (EV8)")
	assert_eq(str(day.environment.aerial_fade_colour), "#7088ae")
	assert_almost_eq(float(day.hour), 8.0, 0.0001, "day keeps its hour")
	assert_almost_eq(float(on.environment.creature_field_rim_floor), 0.12)
	assert_eq(JSON.stringify(on.times.golden), JSON.stringify(_base_look().times.golden), "golden untouched")
	assert_true(float(on.times.night.environment.ambient_energy) > 1.5, "night fill carried from light_candidate")


func test_ground_on_returns_shader_viewport_and_grass_keys() -> void:
	var path := _fixture(CONFIG, ["cause_ground"])
	var shader := PLAYGROUND.meadows_cause_ground_shader(path)
	assert_almost_eq(float(shader.mipmap_bias), 0.7)
	assert_true(shader.has("macro_variation2"))
	var viewport := LOOK.cause_ground_viewport(path)
	assert_eq(int(viewport.anisotropic_filtering_level), 4)
	assert_true(float(viewport.texture_mipmap_bias) < 0.0)
	var grass := {"zone_strength": 0.85, "cover_tiers": [
		{"name": "flowers", "patch_start": 0.6, "count": 12000}, {"name": "bushes", "count": 6000}]}
	GRASS.apply_meadows_cause_ground(grass, path)
	assert_almost_eq(float(grass.zone_strength), 1.0)
	assert_almost_eq(float(grass.clump_contrast), 0.75)
	assert_almost_eq(float(grass.cover_tiers[0].patch_start), 0.62)
	assert_eq(int(grass.cover_tiers[0].count), 12000, "unmentioned tier keys stay")
	assert_eq(JSON.stringify(grass.cover_tiers[1]), JSON.stringify({"name": "bushes", "count": 6000}))


func test_creature_rim_floor_stays_under_the_rarity_rungs() -> void:
	CREATURE.set_field_rim_floor(0.5)
	assert_almost_eq(CREATURE.field_rim_floor(), CREATURE.FIELD_RIM_FLOOR_MAX)
	assert_true(CREATURE.FIELD_RIM_FLOOR_MAX < float(CREATURE.TIER_RIM_STRENGTH.uncommon))
	CREATURE.set_field_rim_floor(-1.0)
	assert_almost_eq(CREATURE.field_rim_floor(), 0.0)


func test_stand_guard_on_reads_window_and_fallback_offsets() -> void:
	var path := _fixture(STANDS, ["buried_stand_guard"])
	assert_almost_eq(CAPTURE.stand_guard_window(path), 8.0)
	assert_eq(CAPTURE.stand_guard_offsets(path), [18.0, 26.0])
	assert_eq(CAPTURE.capture_overhead_failure(null, Vector3.ZERO, 8.0, 1, []), "",
		"no space, no verdict")
