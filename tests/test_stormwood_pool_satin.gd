extends "res://tests/test_case.gd"

## VIS-STORMWOOD (4 Nov 2026), F41#5 P2-039: pool_satin_1104 replaces the
## black pools' fixed satin sheen so they stop mirroring the pale sky. It
## ships OFF; while OFF the zones config carries no pool sheen keys.

const ZONES := preload("res://scripts/world/stormwood_ground_zones.gd")


func test_pool_satin_ships_off() -> void:
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ZONES.CONFIG_PATH))
	assert_false(bool(raw.pool_satin_1104.get("enabled", true)), "ships OFF until judged")
	var zones := ZONES.config()
	# Since 10 Nov wet_earth_1110 (ON) carries its own matte pool sheen; with pool_satin OFF
	# the zones config holds exactly that sheen, and with both OFF it holds none.
	if bool(raw.wet_earth_1110.get("enabled", false)):
		assert_eq(float(zones.get("pool_roughness", -1.0)), float(raw.wet_earth_1110.ground_zones.pool_roughness), "wet earth's matte pool sheen, not pool_satin's")
	else:
		assert_false(zones.has("pool_roughness"), "OFF leaves the shader's own sheen")


func test_pool_satin_values_are_duller_than_the_shipped_sheen() -> void:
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ZONES.CONFIG_PATH))
	assert_true(float(raw.pool_satin_1104.pool_roughness) > 0.38, "rougher than the shipped 0.38")
	assert_true(float(raw.pool_satin_1104.pool_specular) < 0.25, "less specular than the shipped 0.25")


## rock_value_1104 (OFF until judged): a darker rock slot through the finish merge.
func test_rock_value_ships_off_and_darkens_rock_when_on() -> void:
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ZONES.CONFIG_PATH))
	assert_false(bool(raw.rock_value_1104.get("enabled", true)), "ships OFF until judged")
	var shipped: Dictionary = ZONES.finish()
	var rock_off := Color(str(shipped.terrain_materials.textures.rock.tint))
	assert_true("rock_value_1104" in ZONES.FINISH_CANDIDATES, "registered as a finish candidate")
	var on_tint := Color(str(raw.rock_value_1104.terrain_materials.textures.rock.tint))
	assert_true(on_tint.get_luminance() < rock_off.get_luminance(), "ON is darker than the shipped rock")
	assert_false(on_tint.r > on_tint.g * 1.3 and on_tint.r > on_tint.b * 1.3, "no red or oxblood")


## F41#4 path_loam_1104: ships ON (qj_path 5.56 -> 5.92); it darkens and cools the path slot tint
## (never near-black, never red) and deepens its relief.
func test_path_loam_ships_on_and_darkens_the_path() -> void:
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ZONES.CONFIG_PATH))
	assert_true(bool(raw.path_loam_1104.get("enabled", false)), "ships ON (judged 5.92)")
	assert_true(str(raw.path_loam_1104.get("_why_on", "")).contains("5.92"), "_why_on cites the judged score")
	var shipped := Color(str(raw.terrain_materials.textures.path.tint))
	# wet_earth_1110 (ON since 10 Nov, merged last in FINISH_CANDIDATES) supersedes the path tint;
	# with it OFF, finish() applies path_loam_1104's darker path.
	var winner: Dictionary = raw.wet_earth_1110 if bool(raw.wet_earth_1110.get("enabled", false)) else raw.path_loam_1104
	assert_eq(Color(str(ZONES.finish().terrain_materials.textures.path.tint)), Color(str(winner.terrain_materials.textures.path.tint)), "finish() applies the last enabled path finish")
	var cand := Color(str(raw.path_loam_1104.terrain_materials.textures.path.tint))
	assert_true(cand.get_luminance() < shipped.get_luminance(), "a darker path")
	assert_true(cand.get_luminance() > 0.2, "not near-black")
	assert_false(cand.r > cand.g * 1.4 and cand.r > cand.b * 1.4, "no red or oxblood")
	assert_true(float(raw.path_loam_1104.terrain_materials.textures.path.normal_depth) > 0.25, "deeper relief")


## F41#5 grass_patch_1104: ships OFF; ON switches the grass shader's colony
## mode (full contrast and a patch ramp) so clearings open in the carpet.
func test_grass_patch_ships_off_and_opens_clearings() -> void:
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ZONES.CONFIG_PATH))
	assert_false(bool(raw.grass_patch_1104.get("enabled", true)), "ships OFF until judged")
	assert_false(ZONES.finish().grass.has("clump_patch_start"), "OFF leaves the carpet as shipped")
	var grass: Dictionary = raw.grass_patch_1104.grass
	assert_eq(float(grass.clump_contrast), 1.0, "full contrast for true clearings")
	assert_true(float(grass.clump_patch_start) < float(grass.clump_patch_full), "a ramp from clearing to colony")
	assert_true(float(grass.clump_patch_start) > 0.0 and float(grass.clump_patch_full) <= 1.0, "within the shader's range")


## F41#5 macro_1104: ships ON (judged 5.31 -> 5.35); ON gives two cool, non-red macro colours at
## long noise scales (large drifts, not grain).
func test_macro_ships_on_and_is_cool_drifts() -> void:
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ZONES.CONFIG_PATH))
	assert_true(bool(raw.macro_1104.get("enabled", false)), "ships ON (judged 5.31 -> 5.35)")
	assert_false(ZONES.macro_variation().is_empty(), "ON installs the macro drifts")
	for key: String in ["macro_variation1", "macro_variation2"]:
		var c := Color(str(raw.macro_1104[key]))
		assert_false(c.r > c.g * 1.4 and c.r > c.b * 1.4, "%s is no red or oxblood" % key)
	assert_true(float(raw.macro_1104.noise1_scale) < 0.05, "long-wavelength drifts")
