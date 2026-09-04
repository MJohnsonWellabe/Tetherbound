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

## T3-MATCHUPS. The five types the creature expansion brought in.
##
## They shipped with no colour of their own, so `combat_hud.gd::_type_color`
## fell through to GROUND_OCHRE and `playground_hud.gd::_type_colour` to
## TEXT_SECONDARY. A Dark creature reading as the GROUND colour on the fight
## HUD is worse than no colour at all -- the type tag is the readiness tell the
## matchup arrow rides on, so it was actively telling the player the wrong
## thing about a matchup that now has real numbers behind it.
##
## Hues are taken from the owner's own art: the board's FUTURE TYPES swatches,
## and the creature-expansion reference sheets. Nightburrow's "strong purple
## emissive cracks" and Shadelet's "violet sheen" give Dark; Stormtrail's
## "bright yellow-gold lightning markings" and Sparkit's "yellow-gold" give
## Electric; Cindercub's terracotta and Ashtusk's "orange glowing cracks" give
## Fire; Frostclaw's "icy blue" gives Ice; Riftfrill's "lilac frills,
## cyan/violet markings" gives Psychic.
##
## The two constraints that shaped the exact values, both of which cost
## something:
##
## - ICE had to be separable from WATER_BLUE and AIR_SKY, which are already two
##   blues sitting next to each other. It is therefore much paler and less
##   saturated than either rather than a third mid-blue -- "frost", not "a
##   colder water".
## - DARK and PSYCHIC are both purple in the owner's art. Separated by hue
##   rather than by lightness (violet vs pink-magenta), because lightness is
##   what a 19px label on a 7-inch handheld loses first.
##
## Nature and Light are deliberately absent. They have no species, no move and
## no chart row, and a colour for a type nothing can be is a stub -- the same
## position `type_chart.json` takes about their matchup rows.
const FIRE_EMBER := Color("#EE7B33")
const ELECTRIC_GOLD := Color("#F5D33A")
const ICE_FROST := Color("#A8E6EC")
const PSYCHIC_LILAC := Color("#F09ADB")
const DARK_VIOLET := Color("#9B7BEA")

## Every type that has a colour, keyed by the string `species.json` and
## `moves.json` use.
##
## ONE table, because there were already two copies of the three-type version
## (`combat_hud.gd` and `playground_hud.gd` each had their own `match`), they
## disagreed about the fallback, and adding five types to two hand-written
## `match` statements is exactly the shape of duplication this repo keeps
## rediscovering -- `type_chart.json`'s own `_comment_types` says so about the
## type vocabulary, which had the same problem. Callers keep their own fallback
## because they genuinely differ: the fight HUD wants the tag to stay readable,
## the field HUD wants an unknown type to recede.
const TYPE_COLOURS := {
	"ground": GROUND_OCHRE,
	"water": WATER_BLUE,
	"air": AIR_SKY,
	"fire": FIRE_EMBER,
	"electric": ELECTRIC_GOLD,
	"ice": ICE_FROST,
	"psychic": PSYCHIC_LILAC,
	"dark": DARK_VIOLET,
}


## The colour for a type, or `fallback` if it has none.
##
## Case-folded and whitespace-tolerant for the same reason
## `type_chart.gd::multiplier` is: these strings come from hand-authored JSON
## where "Ground" and "ground" are the same intent, and a capital letter should
## not silently change what the player sees any more than it should silently
## switch a mechanic off.
static func type_colour(type_id: String, fallback: Color) -> Color:
	var key := type_id.strip_edges().to_lower()
	return TYPE_COLOURS.get(key, fallback)

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


## The same panel shape over `BG_DEEP` instead of `BG_PANEL`, with NO border —
## for a surface that wants to read as further back / behind everything else
## on screen, not as another card in the same stack.
##
## GATE3-HUD-HIERARCHY (Gate 2 evidence judge, `ralph/reports/GATE2-EVIDENCE-0903/JUDGE.md`
## §6, and a second blind pass on this lane's own fix): a border-plus-darker-
## fill treatment still read as "the same card template with a duller
## colour," because every tier still carried an edge. Dropping the edge here
## — kept on `panel_box_accent()`'s two MESSAGE tiers below — is what turns
## "duller card" into "this is furniture, not a message."
static func panel_deep_box() -> StyleBoxFlat:
	var box := panel_box(BG_DEEP, Color(BORDER, 0.0))
	box.border_width_left = 0
	box.border_width_right = 0
	box.border_width_top = 0
	box.border_width_bottom = 0
	return box


## `panel_box()` with a bright, doubled-width border instead of the neutral
## `BORDER` — for a panel that has to read as a DIFFERENT KIND of message
## from a plain HUD panel sitting right next to it, not just another box in
## the same stack (GATE3-HUD-HIERARCHY, a Gate 2 evidence blind judge on
## `ralph/reports/GATE2-EVIDENCE-0903/JUDGE.md` §6: "objective / action /
## interact hierarchy does not separate ... every element is the same
## dark-navy rounded panel at the same opacity"). `playground_hud.gd` uses
## this for the two tiers that ARE telling the player something (the
## objective card, WARNING; the interact pill, TEAL) and leaves the third
## tier — the persistent hotbar/legend capability row, which never is —
## on the plain, receding `panel_deep_box()`.
static func panel_box_accent(accent: Color, bg: Color = BG_PANEL) -> StyleBoxFlat:
	var box := panel_box(bg, accent)
	box.border_width_left = EDGE * 2
	box.border_width_right = EDGE * 2
	box.border_width_top = EDGE * 2
	box.border_width_bottom = EDGE * 2
	return box


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


## The tile a stack was picked up FROM, while it is in hand. Amber rather than
## `slot_box(true)`'s teal — the same warning color `_held_banner` already
## uses for "HOLDING" — so the source tile reads as a distinct state from an
## ordinary focused tile, not as "also selected".
static func slot_box_held() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = BG_PANEL_ALT
	box.corner_radius_top_left = RADIUS_SLOT
	box.corner_radius_top_right = RADIUS_SLOT
	box.corner_radius_bottom_left = RADIUS_SLOT
	box.corner_radius_bottom_right = RADIUS_SLOT
	box.border_color = WARNING
	box.border_width_left = EDGE
	box.border_width_right = EDGE
	box.border_width_top = EDGE
	box.border_width_bottom = EDGE
	return box


## A valid drop target while something is in hand, but not the one the cursor
## is actually on — a fainter border than `slot_box(true)`'s so the one tile
## that IS focused still reads as the loudest thing on screen.
static func slot_box_target() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = BG_PANEL_ALT
	box.corner_radius_top_left = RADIUS_SLOT
	box.corner_radius_top_right = RADIUS_SLOT
	box.corner_radius_bottom_left = RADIUS_SLOT
	box.corner_radius_bottom_right = RADIUS_SLOT
	box.border_color = TEAL_SOFT
	box.border_width_left = 1
	box.border_width_right = 1
	box.border_width_top = 1
	box.border_width_bottom = 1
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
