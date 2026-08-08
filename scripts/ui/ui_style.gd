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
## OPAQUE, and it has to stay that way.
##
## At 0.95 the five percent that showed through was enough for a blind reviewer
## to read `Bramblit`, `Lv 1` and `Steady 124/124 HP` through the rename panel —
## and worse, both screens put their hint row at the same height, so the footers
## superimposed and it was impossible to tell which buttons were live. A stacked
## screen has to be able to cover the one beneath it; the SCRIM is what lets the
## world show through, not the panel.
const PANEL_BG := Color(0.06, 0.07, 0.06, 1.0)
const PANEL_EDGE := Color(0.60, 0.65, 0.54, 0.32)
const SCRIM := Color(0.0, 0.0, 0.0, 0.58)

## The scrim a screen uses when it is NOT the bottom of the stack.
##
## Heavier, because what is behind a second screen is not the world — it is
## another screen, with its own panel, title and footer, and 42% of that is
## still perfectly readable.
const SCRIM_STACKED := Color(0.0, 0.0, 0.0, 0.86)

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


# ------------------------------------------------------------ device glyphs

## What the buttons are CALLED, per device, so a prompt can say [RB] on the pad
## and [F] on a keyboard instead of one of them forever.
##
## This exists because the owner playtested on the ROG Ally and the throw
## prompt said F. There is no F on an Ally. Every hardcoded button string in a
## verb row is wrong on exactly one of the two devices this game ships for, and
## which one it is wrong on flips when the player picks up the other input —
## so the glyph has to come from the ACTION, through the InputMap, at the
## moment it is drawn. That also means a remapped action names its new button
## everywhere, for free.
##
## Xbox names, because the Ally presents as an Xbox-layout pad and so does
## every other pad this game is likely to meet. 4 and 6 are "View" and "Start"
## — the Ally's own labels for them.
const PAD_BUTTON_GLYPHS := {
	JOY_BUTTON_A: "A", JOY_BUTTON_B: "B", JOY_BUTTON_X: "X", JOY_BUTTON_Y: "Y",
	JOY_BUTTON_BACK: "View", JOY_BUTTON_GUIDE: "Guide", JOY_BUTTON_START: "Start",
	JOY_BUTTON_LEFT_STICK: "LS", JOY_BUTTON_RIGHT_STICK: "RS",
	JOY_BUTTON_LEFT_SHOULDER: "LB", JOY_BUTTON_RIGHT_SHOULDER: "RB",
	JOY_BUTTON_DPAD_UP: "D-Pad Up", JOY_BUTTON_DPAD_DOWN: "D-Pad Down",
	JOY_BUTTON_DPAD_LEFT: "D-Pad Left", JOY_BUTTON_DPAD_RIGHT: "D-Pad Right",
}

## Axis-and-direction to name, for actions bound to a stick or trigger.
## Keyed "axis:sign"; sign is the sign of the binding's axis_value.
const PAD_AXIS_GLYPHS := {
	"0:-1": "L-Stick Left", "0:1": "L-Stick Right",
	"1:-1": "L-Stick Up", "1:1": "L-Stick Down",
	"2:-1": "R-Stick Left", "2:1": "R-Stick Right",
	"3:-1": "R-Stick Up", "3:1": "R-Stick Down",
	"4:1": "LT", "5:1": "RT",
}

## Which device spoke last: 1 pad, 0 keyboard/mouse, -1 nobody yet.
##
## Fed by `screen_stack._input()`, which sees every event in every scene the
## menus exist in. Before the first event the answer is "is a pad plugged in",
## which on the Ally is yes at boot — controller first is the hard rule, and a
## handheld must never boot showing keyboard letters.
static var _last_device: int = -1


## Any pad press or real stick deflection flips to pad glyphs; any key or
## mouse press flips back. The 0.5 floor on motion keeps a worn stick resting
## off-centre from flickering the whole interface between devices.
static func note_input(event: InputEvent) -> void:
	if event is InputEventJoypadButton:
		_last_device = 1
	elif event is InputEventJoypadMotion:
		if absf((event as InputEventJoypadMotion).axis_value) > 0.5:
			_last_device = 1
	elif event is InputEventKey or event is InputEventMouseButton:
		_last_device = 0


static func pad_active() -> bool:
	if _last_device == -1:
		return not Input.get_connected_joypads().is_empty()
	return _last_device == 1


## The name of the button that fires `action` on the device the player is
## actually holding. Falls back across devices — an action with only a keyboard
## binding names its key even on the pad, because a wrong-device name is still
## infinitely better than a blank — and falls back to the action id itself when
## nothing is bound, for the cooldown-verb reason: absence reads as a bug.
static func glyph(action: StringName) -> String:
	if not InputMap.has_action(action):
		return str(action)
	var key_name := ""
	var pad_name := ""
	for event in InputMap.action_get_events(action):
		if event is InputEventKey and key_name == "":
			key_name = key_glyph(event as InputEventKey)
		elif event is InputEventJoypadButton and pad_name == "":
			pad_name = button_glyph(int((event as InputEventJoypadButton).button_index))
		elif event is InputEventJoypadMotion and pad_name == "":
			pad_name = axis_glyph(event as InputEventJoypadMotion)
		elif event is InputEventMouseButton and key_name == "":
			key_name = mouse_glyph(event as InputEventMouseButton)
	if pad_active():
		return pad_name if pad_name != "" else (key_name if key_name != "" else str(action))
	return key_name if key_name != "" else (pad_name if pad_name != "" else str(action))


static func key_glyph(event: InputEventKey) -> String:
	var code := event.physical_keycode if event.physical_keycode != KEY_NONE else event.keycode
	var text := OS.get_keycode_string(code)
	return text if text != "" else "Key %d" % int(code)


static func button_glyph(index: int) -> String:
	return str(PAD_BUTTON_GLYPHS.get(index, "Pad %d" % index))


static func axis_glyph(event: InputEventJoypadMotion) -> String:
	var sign_key := "%d:%d" % [int(event.axis), 1 if event.axis_value >= 0.0 else -1]
	return str(PAD_AXIS_GLYPHS.get(sign_key, "Axis %d" % int(event.axis)))


static func mouse_glyph(event: InputEventMouseButton) -> String:
	match event.button_index:
		MOUSE_BUTTON_LEFT: return "LMB"
		MOUSE_BUTTON_RIGHT: return "RMB"
		MOUSE_BUTTON_MIDDLE: return "MMB"
	return "Mouse %d" % int(event.button_index)


## `verb()`, with the button looked up from the action instead of hardcoded.
## New verb rows should use this; the ones that predate it are listed in the
## remap milestone's audit.
static func verb_for(action: StringName, label: String, ready: bool) -> String:
	return verb(glyph(action), label, ready)


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
## Five even bands, floored rather than rounded.
##
## Rounding gave a 0.9 pal the same five stars as a perfect one, which makes the
## top of the scale meaningless in the one place — a keep-or-release decision —
## where the player most needs it to mean something. Floored, the fifth star is
## the top fifth of the range and nothing else.
static func stars(fraction: float, colour: String = GOOD) -> String:
	return star_row(int(clampf(fraction, 0.0, 1.0) * float(STARS)), STARS, colour)


## `filled` out of `total`, when the caller already has both as counts.
##
## Prefer this over `stars()` whenever the number came from the data layer as an
## integer. `pal_instance.appraisal()` hands back a star COUNT, and the obvious
## thing — divide by max_stars, hand the fraction to `stars()`, multiply back —
## is off by one for a third of its inputs: 3.0/5.0 is 0.5999999999999999 in
## binary, times five is 2.9999999999999996, and `int()` truncates that to two.
## A three-star pal drew two stars. Counts in, counts out, no float in between.
static func star_row(filled: int, total: int, colour: String = GOOD) -> String:
	var cap := maxi(1, total)
	var lit := clampi(filled, 0, cap)
	return "[color=#%s]%s[/color][color=#%s]%s[/color]" % [
		colour, STAR_FULL.repeat(lit), INK_DIM, STAR_EMPTY.repeat(cap - lit)
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
