extends "res://tests/test_case.gd"

## F10#6 device profile (code-blind 7-inch judges r2 and r3, both NO on combat
## HUD text): `smoke_hud_handheld_legibility.gd` holds the exploration HUD to
## `hud_scale.gd`'s angular floors, but nothing held the combat HUD to them,
## and its level, element, move and status labels sat at 19-23 px. This pins
## every text node in `combat_hud.tscn` to the same floors: a glanced label
## clears GLANCE_CAP_ARCMIN, and the lines a player reads as a sentence (the
## tell line, the contextual prompt, the miss/catch rows) clear
## SENTENCE_CAP_ARCMIN. Checked as scene data, no tree needed.

const COMBAT_HUD_SCENE := preload("res://scenes/combat/combat_hud.tscn")
const COMBAT_HUD := preload("res://scripts/ui/combat_hud.gd")
const HUD_SCALE := preload("res://scripts/ui/hud_scale.gd")
const UI_TOKENS := preload("res://scripts/ui/ui_tokens.gd")
const CREATURE_INSTANCE := preload("res://scripts/creatures/creature_instance.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")

const SENTENCES: Array[String] = ["Telegraph", "Prompt", "AimRow", "CatchRow"]


func _text_nodes(node: Node, into: Array[Node]) -> void:
	if node is Label or node is RichTextLabel:
		into.append(node)
	for child in node.get_children():
		_text_nodes(child, into)


func _authored_size(node: Node) -> int:
	var key := "theme_override_font_sizes/normal_font_size" if node is RichTextLabel \
		else "theme_override_font_sizes/font_size"
	var value: Variant = node.get(key)
	return int(value) if value != null else -1


func test_every_combat_hud_text_clears_its_handheld_floor() -> void:
	var hud := COMBAT_HUD_SCENE.instantiate()
	var nodes: Array[Node] = []
	_text_nodes(hud, nodes)
	assert_true(nodes.size() >= 15, "found %d text nodes in combat_hud.tscn" % nodes.size())
	var glance := HUD_SCALE.font_size_for_cap_arcmin(HUD_SCALE.GLANCE_CAP_ARCMIN)
	var sentence := HUD_SCALE.font_size_for_cap_arcmin(HUD_SCALE.SENTENCE_CAP_ARCMIN)
	for node in nodes:
		var size := _authored_size(node)
		if size < 0:
			continue
		var floor_px := sentence if SENTENCES.has(String(node.name)) else glance
		# F10#6 r6: UX section 8's raster floors bind too (18 px essential text
		# and 20 px prompts at the 1280x720 stress raster).
		floor_px = maxi(floor_px, UI_TOKENS.FONT_PROMPT if SENTENCES.has(String(node.name)) \
			else UI_TOKENS.FONT_READ)
		assert_true(size >= floor_px, "%s authored at %d px, below its %d px handheld floor" % [
			str(hud.get_path_to(node)), size, floor_px])
	hud.free()


func test_move_badges_and_roster_portraits_read_at_seven_inches() -> void:
	# F10#6 r6: badge lettering at 34 px read about 4 px on the 7-inch sheet.
	assert_true(COMBAT_HUD.CELL_GLYPH_PX >= 40, "move badge %d px" % COMBAT_HUD.CELL_GLYPH_PX)
	assert_true(COMBAT_HUD.GLANCE_FONT_PX >= UI_TOKENS.FONT_READ)
	# The compact fight column knows each member by portrait (r6: five swatches).
	var member: RefCounted = CREATURE_INSTANCE.from_species("mudsnout",
		SPECIES.definition("mudsnout"), 0.5)
	var hud := COMBAT_HUD.new()
	var entries: Array = hud._party_entries([member])
	assert_eq(entries.size(), 1)
	assert_eq(str(entries[0].get("portrait", "")), "res://assets/ui/portraits/creatures/mudsnout.png")
	assert_true(ResourceLoader.exists(str(entries[0]["portrait"])), "the portrait exists")
	hud.free()


func test_dimmed_move_cells_keep_names_and_glyphs_readable() -> void:
	var panel := Color("1b2530")
	var name_colour := Color(UI_TOKENS.TEXT_PRIMARY) * COMBAT_HUD.CELL_DIMMED
	var glyph_colour := COMBAT_HUD.VERB_DIMMED * COMBAT_HUD.CELL_DIMMED
	assert_true(_contrast(name_colour, panel) >= 7.0,
		"dimmed move name %.2f:1 over the cell" % _contrast(name_colour, panel))
	assert_true(_contrast(glyph_colour, panel) >= 4.5,
		"dimmed glyph %.2f:1 over the cell" % _contrast(glyph_colour, panel))


## F10#6 (UX §1.4): a fight panel fades only when it covers a real share of a
## subject's screen area, not for a pixel of edge contact.
func test_panels_fade_only_over_a_subject() -> void:
	var grid := Rect2(1420, 790, 440, 230)
	var trainer_under := [Rect2(1500, 850, 40, 120)] as Array[Rect2]
	var trainer_clear := [Rect2(1200, 700, 40, 120)] as Array[Rect2]
	var edge_touch := [Rect2(1380, 700, 44, 120)] as Array[Rect2]
	assert_almost_eq(COMBAT_HUD.subject_fade_target(grid, trainer_under, 0.1, 0.3), 0.3, 0.001,
		"the grid over the trainer fades")
	assert_almost_eq(COMBAT_HUD.subject_fade_target(grid, trainer_clear, 0.1, 0.3), 1.0, 0.001,
		"a clear trainer leaves the grid opaque")
	assert_almost_eq(COMBAT_HUD.subject_fade_target(grid, edge_touch, 0.1, 0.3), 1.0, 0.001,
		"a sliver of edge contact is not covering")
	assert_almost_eq(COMBAT_HUD.subject_fade_target(grid, [] as Array[Rect2], 0.1, 0.3), 1.0, 0.001)


func _contrast(a: Color, b: Color) -> float:
	var la := _luminance(a)
	var lb := _luminance(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


func _luminance(c: Color) -> float:
	var lin := func(v: float) -> float:
		return v / 12.92 if v <= 0.03928 else pow((v + 0.055) / 1.055, 2.4)
	return 0.2126 * float(lin.call(c.r)) + 0.7152 * float(lin.call(c.g)) + 0.0722 * float(lin.call(c.b))
