extends RefCounted

## Every colour and text treatment the interface is allowed to use, in one file.
##
## This was `combat_hud.gd`'s private const block until the screen system needed
## the same values. It is lifted out rather than copied because the numbers here
## are not taste — each one is the answer to a measured failure, and a second
## copy would drift away from the measurement that produced it. The comments came
## with the constants deliberately: anybody who wants to "tidy up" the outline has
## to read why it is there first.
##
## Nothing here draws or holds state. It is constants plus four formatters,
## preloaded rather than autoloaded, because a screen that needs its text to be
## readable should not also need a singleton to have booted.
##
## The one colour that is NOT here is `tether_oxblood` (`data/config/palette.json`
## `_reserved`). It is the danger accent, it belongs to Team Tether, and a party
## menu is the last place it should start leaking from.


# ---------------------------------------------------------------- bar colours

## Health bar colour at full and at empty. The slide between them is the only
## warning the player gets that the fight is going badly, since a placeholder
## capsule cannot look hurt.
## YOUR pal's health, and the OPPONENT's, in two different hues.
##
## They used to be the same green — measured identical by the blind critic at
## (0.349, 0.620, 0.278) in both bars, top-centre and bottom-left. In a fight
## where both are draining, you cannot tell at a glance which one just moved,
## which is the one thing a health bar exists to tell you.
##
## Yours stays the friendly green. Theirs is a warm amber-to-red, which is also
## the direction it drains toward, so a damaged opponent reads as damaged
## without needing the number.
##
## Neither is the reserved Team Tether oxblood (`palette.json` `_reserved`) —
## the critic confirmed that discipline is holding at 0.004-0.07% across every
## world frame, and an HP bar is not where it should start leaking.
##
## HEALTH_FULL/HEALTH_LOW are shared with the party screen on purpose. A pal's
## health has to be the same green in the menu as it is in the fight, or the
## player is learning the colour twice.
const HEALTH_FULL := Color(0.35, 0.62, 0.28)
const HEALTH_LOW := Color(0.72, 0.22, 0.18)
const ENEMY_HEALTH_FULL := Color(0.84, 0.55, 0.20)
const ENEMY_HEALTH_LOW := Color(0.68, 0.17, 0.14)
const ENERGY_READY := Color(0.95, 0.80, 0.30)
const ENERGY_FILLING := Color(0.58, 0.52, 0.34)
## The energy TRACK is lighter than the health track, because an empty energy
## bar is a normal state and an empty black slot reads as a broken widget. The
## critic saw it at zero in all eight combat frames and called it exactly that.
const ENERGY_TRACK := Color(0.20, 0.19, 0.16, 0.92)
## Nearly opaque. At 0.72 the enemy's health bar showed tree trunks and canopy
## through its interior, which the blind critic read as a rendering fault rather
## than as a style.
const TRACK := Color(0.05, 0.05, 0.06, 0.94)


# ------------------------------------------------------------ text legibility

## Every label is outlined and shadowed rather than plated.
##
## Measured contrast on the old unplated white text was 1.45:1, 1.38:1 and
## 1.45:1 against a large-text minimum of 3:1 — in one frame the em dash and
## half a word were simply invisible against a hillside. Every text element in
## the Palworld references either sits on a dark plate or carries a heavy
## outline.
##
## Outline rather than plate because the HUD has to work over a meadow, a cliff
## and a sunset without a designer choosing a plate colour for each; an outline
## is the same decision everywhere and costs no layout.
const OUTLINE := Color(0.03, 0.04, 0.05, 0.95)
const OUTLINE_SIZE := 7
const SHADOW := Color(0.0, 0.0, 0.0, 0.55)
const SHADOW_OFFSET := Vector2(0.0, 3.0)

## Unavailable verbs are dimmed, not blanked.
##
## The prompt row used to render `[ ]` for a verb on cooldown — an empty pair of
## brackets, in every combat frame, which reads as a missing glyph rather than
## as a disabled button. The button never changes; its availability does.
const VERB_READY := "e8f0e0"
const VERB_DIMMED := "8b9184"


# --------------------------------------------------------------- screen chrome

## Menu chrome. Dark and neutral: a screen sits over the meadow, over a cliff and
## over a fight, and a panel tinted toward any of the world palettes reads as
## belonging to one of them.
const PANEL_BG := Color(0.06, 0.07, 0.06, 0.95)
const PANEL_EDGE := Color(0.60, 0.65, 0.54, 0.32)
const SCRIM := Color(0.0, 0.0, 0.0, 0.58)

## A row you are not on, a row you are on, and a row with nothing in it.
##
## Three states, three fills, all three drawn. An empty party slot renders as a
## visible sunken row rather than as nothing, for the same reason the cooldown
## verb keeps its glyph: absence reads as a bug, and a drawn empty box reads as
## "there is room here".
const ROW_BG := Color(0.11, 0.12, 0.10, 0.90)
const ROW_FOCUS_BG := Color(0.19, 0.24, 0.16, 0.96)
const ROW_FOCUS_EDGE := Color(0.55, 0.76, 0.45, 0.85)
const ROW_EMPTY_BG := Color(0.08, 0.08, 0.08, 0.70)
const ROW_EMPTY_EDGE := Color(0.42, 0.44, 0.39, 0.35)

## Text colours as bbcode hex, so they can be dropped into a RichTextLabel.
##
## GOOD and WARN are the build ghost's own green and amber
## (`data/config/building.json` `ghost_valid_colour` / `ghost_invalid_colour`).
## Deliberately the same two: the ghost already teaches "green means yes, amber
## means the game is refusing", and the palette strip that explains the refusal
## should not answer in a third colour.
const GOOD := "8fd694"
const WARN := "e0a05a"
const INK := "e8f0e0"
const INK_DIM := "8b9184"

## Five stars, filled and hollow.
##
## GAME_DESIGN.md §11: "Show appraisal through stars/bars, not exact IV numbers."
## The hollow star is drawn rather than omitted so a one-star pal and a
## five-star pal are the same width and can be compared down a column.
const STAR_FULL := "★"
const STAR_EMPTY := "☆"
const STARS := 5


## Outline and shadow every piece of text in the tree, whatever gets added later.
##
## Walked rather than set per node on purpose: the failure being fixed is a label
## somebody adds next month with no override on it, and a list of node paths here
## would not catch that. Screens call this once after they finish building
## themselves, which covers rows duplicated from a template too.
static func make_legible(node: Node) -> void:
	if node is Label or node is RichTextLabel:
		var control := node as Control
		control.add_theme_constant_override("outline_size", OUTLINE_SIZE)
		control.add_theme_color_override("font_outline_color", OUTLINE)
		control.add_theme_color_override("font_shadow_color", SHADOW)
		control.add_theme_constant_override("shadow_offset_x", int(SHADOW_OFFSET.x))
		control.add_theme_constant_override("shadow_offset_y", int(SHADOW_OFFSET.y))
		control.add_theme_constant_override("shadow_outline_size", 2)
	for child in node.get_children():
		make_legible(child)


## One verb in a prompt row: the button, then what it does.
##
## The button glyph is ALWAYS drawn. It used to be replaced by `[ ]` when the
## verb was on cooldown, which put an empty pair of brackets in every combat
## frame and read as a missing icon. Which button does a thing never changes;
## only whether you can press it right now does, and that is what the dimming
## says.
static func verb(button: String, label: String, ready: bool) -> String:
	return "[color=#%s][b][%s][/b] %s[/color]" % [
		VERB_READY if ready else VERB_DIMMED, button, label
	]


## A whole footer row of verbs, centred. Each entry is [button, label, ready].
##
## Menus and the combat HUD share this formatter so the button language is one
## language. A player who has learned that A confirms in a fight has learned that
## A confirms in the party menu, and the two rows should not look different
## enough to make them wonder.
static func hint_row(hints: Array[Array]) -> String:
	var parts: Array[String] = []
	for hint: Array in hints:
		var ready: bool = true if hint.size() < 3 else bool(hint[2])
		parts.append(verb(str(hint[0]), str(hint[1]), ready))
	return "[center]%s[/center]" % "     ".join(parts)


## `fraction` of five stars, as bbcode. Filled stars in `colour`, hollow ones
## dimmed, so the rating reads at a glance and the scale still reads at all.
static func stars(fraction: float, colour: String = GOOD) -> String:
	var filled := int(round(clampf(fraction, 0.0, 1.0) * float(STARS)))
	return "[color=#%s]%s[/color][color=#%s]%s[/color]" % [
		colour, STAR_FULL.repeat(filled), INK_DIM, STAR_EMPTY.repeat(STARS - filled)
	]


static func bar_style(colour: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = colour
	box.corner_radius_top_left = 3
	box.corner_radius_top_right = 3
	box.corner_radius_bottom_left = 3
	box.corner_radius_bottom_right = 3
	return box


static func dress_bar(bar: ProgressBar, fill: StyleBoxFlat, track_colour: Color = TRACK) -> void:
	var track := bar_style(track_colour)
	track.border_width_left = 2
	track.border_width_right = 2
	track.border_width_top = 2
	track.border_width_bottom = 2
	track.border_color = Color(0.02, 0.02, 0.02, 0.85)
	bar.add_theme_stylebox_override("background", track)
	bar.add_theme_stylebox_override("fill", fill)


## A panel fill with an edge. Used for the screen itself and for every row on it,
## which is why the colours are arguments and the geometry is not: one radius and
## one border weight everywhere is what makes five screens look like one game.
static func panel_style(fill: Color, edge: Color, radius: int = 6) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = edge
	box.border_width_left = 2
	box.border_width_right = 2
	box.border_width_top = 2
	box.border_width_bottom = 2
	box.corner_radius_top_left = radius
	box.corner_radius_top_right = radius
	box.corner_radius_bottom_left = radius
	box.corner_radius_bottom_right = radius
	return box
