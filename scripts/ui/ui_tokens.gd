extends RefCounted
class_name UITokens

## The single source of truth for UI color, type, spacing, and motion timing
## (owner spec, `docs/decisions/D28`).
##
## `scripts/ui/playground_hud.gd`, `scripts/ui/menu_tab.gd`,
## `scripts/ui/combat_hud.gd`, `scripts/ui/craft_panel.gd`, and
## `scripts/ui/storage_panel.gd` each duplicate a version of these same
## values today — `PANEL_BG`, `OUTLINE_SIZE`, and the like, one const block
## per file, already quietly disagreeing with each other (playground_hud's
## outline is 6px, combat_hud's is 7px, for what is meant to read as one
## treatment). Those files are migrating onto this module in a follow-on
## pass; this file does not delete or touch them.
##
## Everything here is a `const` or a pure `static` function — no autoload,
## nothing that needs a node in the tree. Values are starting points, not
## untouchable canon the moment this file lands: the same "tunable, not a
## new permanent mechanic" rule `CLAUDE.md` states for gameplay numbers
## applies to a hex color exactly as it does to a cooldown.

# --- Panel / surface colors ---------------------------------------------

const BG_DEEP := Color(Color("#10191E"), 0.90)
const BG_PANEL := Color(Color("#17242B"), 0.86)
const BG_PANEL_ALT := Color(Color("#1E3037"), 0.82)
const BORDER := Color(Color("#58727A"), 0.70)

# --- Text colors ----------------------------------------------------------

const TEXT_PRIMARY := Color("#F2F5F2")
const TEXT_SECONDARY := Color("#B8C5C4")
const TEXT_MUTED := Color("#7F9394")

# --- Accent / semantic colors ---------------------------------------------

const TEAL := Color("#36D6CB")
const TEAL_SOFT := Color("#73E6DD")
const SUCCESS := Color("#4BD28B")
const WARNING := Color("#E8B74A")
const DANGER := Color("#E7605B")

# --- Stat / type-adjacent colors -------------------------------------------

const HP_GREEN := Color("#43C983")
const STAMINA_ORANGE := Color("#E2A354")
const WATER_BLUE := Color("#4AADE8")
const GROUND_OCHRE := Color("#B99050")
const AIR_SKY := Color("#73C8ED")

# --- Build theme set (warm/brass, see build_theme.tres) --------------------

const BUILD_BG := Color(Color("#2A211A"), 0.92)
const BUILD_BG_ALT := Color(Color("#342A20"), 0.90)
const BUILD_ACCENT := Color("#D9C08A")
const BUILD_TEXT := Color("#EFE7D6")

# --- Track / outline --------------------------------------------------------

const TRACK := Color(0.05, 0.05, 0.06, 0.85)
const OUTLINE := Color(0.03, 0.04, 0.05, 0.95)
const OUTLINE_SIZE := 6
const SHADOW_OFFSET := Vector2(1, 2)

# --- Font sizes --------------------------------------------------------------

const FONT_TINY := 19
const FONT_LABEL := 23
const FONT_BODY := 26
const FONT_BUTTON := 28
const FONT_HEADING := 32
const FONT_TITLE := 42
const FONT_BIG_NUMBER := 56

# --- Spacing -------------------------------------------------------------

const MARGIN_SAFE := 48
const HUD_INSET := 56
const GAP := 14
const PAD := 20
const SLOT := 86
const GLYPH := 38
const RADIUS := 10
const RADIUS_BAR := 8
const RADIUS_SLOT := 6
const EDGE := 2

# --- Motion (seconds) -----------------------------------------------------

const T_FOCUS := 0.08
const T_PANEL := 0.16
const T_TAB := 0.10
const T_TOOLTIP := 0.35
const T_PARTY_REVEAL := 0.14
const T_PARTY_FADE := 2.5
const T_DAMAGE_FLASH := 0.10
const T_CAPTURE_PULSE := 0.18

# --- CanvasLayer plan -------------------------------------------------------

const LAYER_HUD := 1
const LAYER_COMBAT := 2
const LAYER_WORLD_PANELS := 3
const LAYER_DIALOGUE := 5
const LAYER_PROMPTS := 6
const LAYER_MENU := 20

# --- Fonts -----------------------------------------------------------------

const FONT_PATH := "res://assets/ui/fonts/kenney_future.ttf"
const FONT_NARROW_PATH := "res://assets/ui/fonts/kenney_future_narrow.ttf"


## A general panel surface: `bg`/`border` fill and edge, `EDGE`-width border
## on all sides, `RADIUS` corners, and content margins roomy enough that text
## never touches the border (the same shape `playground_hud.gd::_style_panel`
## and `menu_tab.gd::_panel` already draw by hand).
static func panel_box(bg: Color = BG_PANEL, border: Color = BORDER) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.border_width_left = EDGE
	box.border_width_right = EDGE
	box.border_width_top = EDGE
	box.border_width_bottom = EDGE
	box.corner_radius_top_left = RADIUS
	box.corner_radius_top_right = RADIUS
	box.corner_radius_bottom_left = RADIUS
	box.corner_radius_bottom_right = RADIUS
	box.content_margin_left = 16
	box.content_margin_top = 16
	box.content_margin_right = 16
	box.content_margin_bottom = 16
	return box


## The same panel shape over `BG_DEEP` instead of `BG_PANEL` — for a surface
## that wants to read as further back / behind everything else on screen.
static func panel_deep_box() -> StyleBoxFlat:
	return panel_box(BG_DEEP, BORDER)


## A flat fill with bar-radius corners: bar/track fills, nothing else.
static func fill_box(color: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.corner_radius_top_left = RADIUS_BAR
	box.corner_radius_top_right = RADIUS_BAR
	box.corner_radius_bottom_left = RADIUS_BAR
	box.corner_radius_bottom_right = RADIUS_BAR
	return box


## A grid/slot cell: dark and slightly lighter than the panel behind it, so an
## empty slot still reads as "a slot" rather than vanishing into the panel
## (the same fix `menu_tab.gd::_style_slot`'s header comment describes).
## `selected` adds a teal border and brightens the fill — the one state that
## has to be the loudest.
static func slot_box(selected: bool = false) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = BG_PANEL_ALT.lightened(0.08) if selected else BG_PANEL_ALT
	box.corner_radius_top_left = RADIUS_SLOT
	box.corner_radius_top_right = RADIUS_SLOT
	box.corner_radius_bottom_left = RADIUS_SLOT
	box.corner_radius_bottom_right = RADIUS_SLOT
	if selected:
		box.border_color = TEAL
		box.border_width_left = EDGE
		box.border_width_right = EDGE
		box.border_width_top = EDGE
		box.border_width_bottom = EDGE
	return box


## The warm/brass panel shape for build and craft surfaces.
static func build_panel_box() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = BUILD_BG
	box.border_color = Color(BUILD_ACCENT, 0.5)
	box.border_width_left = EDGE
	box.border_width_right = EDGE
	box.border_width_top = EDGE
	box.border_width_bottom = EDGE
	box.corner_radius_top_left = RADIUS
	box.corner_radius_top_right = RADIUS
	box.corner_radius_bottom_left = RADIUS
	box.corner_radius_bottom_right = RADIUS
	return box


## Outlines and shadows every `Label`/`RichTextLabel` under `root`, recursing
## into every child. Ports `playground_hud.gd::_make_text_legible` verbatim —
## that function exists because measured contrast on unplated white HUD text
## fell below the large-text minimum over an unpredictable world backdrop
## (see that file's and `combat_hud.gd`'s header comments); an outline is the
## same fix everywhere and costs no layout, unlike a plate.
static func make_text_legible(root: Node) -> void:
	if root is Label or root is RichTextLabel:
		var control := root as Control
		control.add_theme_constant_override("outline_size", OUTLINE_SIZE)
		control.add_theme_color_override("font_outline_color", OUTLINE)
		control.add_theme_color_override("font_shadow_color", Color(OUTLINE, 0.6))
		control.add_theme_constant_override("shadow_offset_x", int(SHADOW_OFFSET.x))
		control.add_theme_constant_override("shadow_offset_y", int(SHADOW_OFFSET.y))
	for child in root.get_children():
		make_text_legible(child)


## Capture-odds tier color, keyed to the same 0..1 chance
## `scripts/combat/catch_math.gd::catch_chance` returns. Presentation only —
## mirrors the worded tiers `combat_hud.gd::ODDS_TIERS` already reads out
## ("great odds" / "poor odds"), for the capture reticle that wants a color
## rather than (or in addition to) a word. Boundaries are exclusive on the
## low side of each tier: a chance exactly on a boundary reads as the better
## tier, not the worse one.
static func chance_tier_color(chance: float) -> Color:
	if chance < 0.25:
		return DANGER.darkened(0.15)
	elif chance < 0.50:
		return WARNING
	elif chance < 0.75:
		return TEAL
	elif chance < 0.95:
		return SUCCESS
	else:
		return TEAL_SOFT.lerp(WARNING, 0.5)
