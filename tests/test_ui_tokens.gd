extends "res://tests/test_case.gd"

## `scripts/ui/ui_tokens.gd`, checked as data (`docs/decisions/D28`).
##
## The module is a pile of constants and pure functions with no scene tree
## dependency, exactly the shape `docs/decisions/D02` scopes this harness to.
## What matters most here is not any one hex value — those are starting
## points per `D28` — but that the module loads, that its two derived
## StyleBoxFlat shapes actually carry the geometry callers rely on (border
## width, corner radius), and that `chance_tier_color`'s boundaries land on
## the tier the spec names, since a fencepost there is invisible in a diff
## and only shows up as a capture reticle glowing the wrong color.

const UI_TOKENS := preload("res://scripts/ui/ui_tokens.gd")


func test_the_module_loads_and_exposes_its_constants() -> void:
	assert_eq(UI_TOKENS.FONT_BODY, 26)
	assert_eq(UI_TOKENS.MARGIN_SAFE, 48)
	assert_eq(UI_TOKENS.LAYER_MENU, 20)


func test_key_color_values_match_the_spec_hex() -> void:
	assert_eq(UI_TOKENS.TEAL, Color("#36D6CB"))
	assert_eq(UI_TOKENS.TEXT_PRIMARY, Color("#F2F5F2"))
	assert_eq(UI_TOKENS.SUCCESS, Color("#4BD28B"))
	assert_eq(UI_TOKENS.WARNING, Color("#E8B74A"))
	assert_eq(UI_TOKENS.DANGER, Color("#F07A22"))
	assert_eq(UI_TOKENS.BUILD_ACCENT, Color("#D9C08A"))


func test_panel_alphas_are_correct() -> void:
	assert_almost_eq(UI_TOKENS.BG_PANEL.a, 0.86, 0.001)
	assert_almost_eq(UI_TOKENS.BG_DEEP.a, 0.90, 0.001)
	assert_almost_eq(UI_TOKENS.BG_PANEL_ALT.a, 0.82, 0.001)
	assert_almost_eq(UI_TOKENS.BORDER.a, 0.70, 0.001)
	assert_almost_eq(UI_TOKENS.BUILD_BG.a, 0.92, 0.001)
	assert_almost_eq(UI_TOKENS.BUILD_BG_ALT.a, 0.90, 0.001)
	# The alpha lives on top of the right underlying hex, not just any color
	# with the right transparency.
	assert_almost_eq(UI_TOKENS.BG_PANEL.r, Color("#17242B").r, 0.001)
	assert_almost_eq(UI_TOKENS.BG_PANEL.g, Color("#17242B").g, 0.001)
	assert_almost_eq(UI_TOKENS.BG_PANEL.b, Color("#17242B").b, 0.001)


func test_panel_box_has_the_right_geometry() -> void:
	var box: StyleBoxFlat = UI_TOKENS.panel_box()
	assert_ne(box, null)
	assert_eq(box.border_width_left, UI_TOKENS.EDGE)
	assert_eq(box.border_width_top, UI_TOKENS.EDGE)
	assert_eq(box.border_width_right, UI_TOKENS.EDGE)
	assert_eq(box.border_width_bottom, UI_TOKENS.EDGE)
	assert_eq(box.corner_radius_top_left, UI_TOKENS.RADIUS)
	assert_eq(box.corner_radius_bottom_right, UI_TOKENS.RADIUS)
	assert_eq(box.bg_color, UI_TOKENS.BG_PANEL)
	assert_eq(box.border_color, UI_TOKENS.BORDER)


func test_panel_deep_box_uses_the_deep_background() -> void:
	var box: StyleBoxFlat = UI_TOKENS.panel_deep_box()
	assert_eq(box.bg_color, UI_TOKENS.BG_DEEP)


func test_fill_box_uses_bar_radius_and_the_given_color() -> void:
	var box: StyleBoxFlat = UI_TOKENS.fill_box(UI_TOKENS.HP_GREEN)
	assert_eq(box.bg_color, UI_TOKENS.HP_GREEN)
	assert_eq(box.corner_radius_top_left, UI_TOKENS.RADIUS_BAR)


func test_slot_box_selected_gets_a_teal_border() -> void:
	var normal: StyleBoxFlat = UI_TOKENS.slot_box(false)
	assert_eq(normal.border_width_left, 0)

	var selected: StyleBoxFlat = UI_TOKENS.slot_box(true)
	assert_eq(selected.border_width_left, UI_TOKENS.EDGE)
	assert_eq(selected.border_color, UI_TOKENS.TEAL)
	assert_ne(selected.bg_color, normal.bg_color, "selected should read brighter than an empty slot")


func test_build_panel_box_uses_the_brass_accent() -> void:
	var box: StyleBoxFlat = UI_TOKENS.build_panel_box()
	assert_eq(box.bg_color, UI_TOKENS.BUILD_BG)
	assert_almost_eq(box.border_color.r, UI_TOKENS.BUILD_ACCENT.r, 0.001)
	assert_almost_eq(box.border_color.a, 0.5, 0.001)


func test_chance_tier_color_boundaries() -> void:
	# Just below the first tier boundary: still in the danger band.
	assert_eq(UI_TOKENS.chance_tier_color(0.24), UI_TOKENS.DANGER.darkened(0.15))
	# On the boundary: the better tier, not the worse one.
	assert_eq(UI_TOKENS.chance_tier_color(0.25), UI_TOKENS.WARNING)
	assert_eq(UI_TOKENS.chance_tier_color(0.5), UI_TOKENS.TEAL)
	assert_eq(UI_TOKENS.chance_tier_color(0.75), UI_TOKENS.SUCCESS)
	assert_eq(UI_TOKENS.chance_tier_color(0.95), UI_TOKENS.TEAL_SOFT.lerp(UI_TOKENS.WARNING, 0.5))
	# A dead-center value inside the warning band, not just its edges.
	assert_eq(UI_TOKENS.chance_tier_color(0.4), UI_TOKENS.WARNING)


func test_make_text_legible_is_callable_on_a_bare_control() -> void:
	# No scene tree needed: a freestanding Label is enough to prove the walk
	# does not crash and actually writes overrides, without instancing a
	# whole HUD scene (out of this harness's pure-logic scope per D02).
	var label := Label.new()
	UI_TOKENS.make_text_legible(label)
	assert_true(label.has_theme_color_override("font_outline_color"))
	assert_eq(label.get_theme_color("font_outline_color"), UI_TOKENS.OUTLINE)
	assert_eq(label.get_theme_constant("outline_size"), UI_TOKENS.OUTLINE_SIZE)
	label.free()


func test_both_theme_resources_load() -> void:
	var main_theme: Theme = load("res://assets/ui/theme/tetherbound_theme.tres")
	assert_ne(main_theme, null)
	assert_ne(main_theme.get_stylebox("focus", "Button"), null)
	assert_ne(main_theme.get_stylebox("panel", "PanelContainer"), null)

	var build_theme: Theme = load("res://assets/ui/theme/build_theme.tres")
	assert_ne(build_theme, null)
	assert_ne(build_theme.get_stylebox("focus", "Button"), null)


func test_both_font_files_exist() -> void:
	assert_true(FileAccess.file_exists(UI_TOKENS.FONT_PATH))
	assert_true(FileAccess.file_exists(UI_TOKENS.FONT_NARROW_PATH))


# --- X03 red rule ------------------------------------------------------------
#
# Oxblood/red is reserved for Team Tether (CLAUDE.md hard rule). DANGER used to
# be coral #E7605B, so every low-HP bar, KO badge and the "Let them go" button
# on the player's own side wore the enemy faction's hue. These pin the rule on
# the token table AND on literal colours in every UI script, so a new
# hand-picked red cannot slip in beside the tokens.


## Red or coral: a saturated, not-near-black/white colour whose hue is within
## the red band. Orange (~20 deg and up) and magenta-pink (below ~335 deg) are
## outside it.
static func _is_red_or_coral(c: Color) -> bool:
	if c.s < 0.30 or c.v < 0.25:
		return false
	var hue := c.h * 360.0
	return hue < 18.0 or hue > 335.0


func test_the_red_band_check_itself_catches_coral_and_oxblood() -> void:
	assert_true(_is_red_or_coral(Color("#E7605B")), "the old coral DANGER must count as red")
	assert_true(_is_red_or_coral(Color(0.72, 0.22, 0.18)), "the old brick HEALTH_LOW must count as red")
	assert_true(_is_red_or_coral(Color("#7A1F2B")), "Team Tether oxblood must count as red")
	assert_false(_is_red_or_coral(UI_TOKENS.WARNING), "amber is not red")
	assert_false(_is_red_or_coral(UI_TOKENS.TEXT_PRIMARY), "near-white is not red")


func test_no_ui_colour_token_is_red_or_coral() -> void:
	var constants: Dictionary = (load("res://scripts/ui/ui_tokens.gd") as GDScript).get_script_constant_map()
	var checked := 0
	for name in constants:
		var value: Variant = constants[name]
		if value is Color:
			checked += 1
			assert_false(_is_red_or_coral(value as Color),
				"UITokens.%s = %s is red/coral; red is Team Tether's alone" % [name, (value as Color).to_html()])
	assert_true(checked >= 20, "expected the token table's colours, found %d" % checked)


func test_danger_stays_distinct_from_warning() -> void:
	# The urgent role must still read apart from amber once it is not red.
	var hue_gap := absf(UI_TOKENS.DANGER.h - UI_TOKENS.WARNING.h) * 360.0
	assert_true(hue_gap >= 12.0, "DANGER and WARNING are only %.1f deg apart" % hue_gap)
	assert_true(UI_TOKENS.WARNING.get_luminance() - UI_TOKENS.DANGER.get_luminance() >= 0.10,
		"DANGER must also sit darker than WARNING so the pair survives colour-blindness")


func test_no_literal_colour_in_a_ui_script_is_red_or_coral() -> void:
	var hex := RegEx.create_from_string("Color\\(\\s*\"#?([0-9A-Fa-f]{6})\"")
	var floats := RegEx.create_from_string("Color\\(\\s*([0-9.]+)\\s*,\\s*([0-9.]+)\\s*,\\s*([0-9.]+)")
	var dir := DirAccess.open("res://scripts/ui")
	assert_true(dir != null, "scripts/ui must be readable")
	var files := 0
	for file_name in dir.get_files():
		if not file_name.ends_with(".gd"):
			continue
		files += 1
		var lines := FileAccess.get_file_as_string("res://scripts/ui/" + file_name).split("\n")
		for i in lines.size():
			var line: String = lines[i]
			for m in hex.search_all(line):
				var c := Color("#" + m.get_string(1))
				assert_false(_is_red_or_coral(c), "%s:%d literal %s is red/coral" % [file_name, i + 1, c.to_html(false)])
			for m in floats.search_all(line):
				var r := m.get_string(1).to_float()
				var g := m.get_string(2).to_float()
				var b := m.get_string(3).to_float()
				if maxf(r, maxf(g, b)) > 1.0:
					continue
				assert_false(_is_red_or_coral(Color(r, g, b)), "%s:%d literal Color(%s, %s, %s) is red/coral" % [file_name, i + 1, r, g, b])
	assert_true(files >= 30, "expected the UI scripts, scanned %d" % files)


func test_warning_icon_is_an_amber_caution_triangle() -> void:
	var texture: Texture2D = UI_TOKENS.warning_icon(28)
	assert_true(texture != null, "warning_icon returned nothing")
	assert_eq(texture.get_width(), 28)
	assert_eq(texture.get_height(), 28)
	var image := texture.get_image()
	assert_almost_eq(image.get_pixel(0, 0).a, 0.0, 0.01, "the corner outside the triangle must be transparent")
	# Just inside the lower-left interior, clear of the "!" bar and dot.
	var body := image.get_pixel(9, 21)
	assert_true(body.a > 0.9 and absf(body.h - UI_TOKENS.WARNING.h) < 0.02,
		"the triangle body is not WARNING amber (%s)" % body.to_html())
	var mark := image.get_pixel(14, 13)
	assert_true(mark.get_luminance() < 0.3, "the '!' must be dark ink on the amber (%s)" % mark.to_html())
	assert_true(UI_TOKENS.warning_icon(28) == texture, "the icon is cached per size")

