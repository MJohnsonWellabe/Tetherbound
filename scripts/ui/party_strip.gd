extends Control

## The five-creature reveal strip (`ENVIRONMENT_AND_UI_BIBLE.md` §6.1).
##
## Slides in above the active-creature block when the player switches which creature is
## out, holds for `UITokens.T_PARTY_FADE`, then fades back out — unless
## `set_pinned(true)` is holding it up, which is what combat-side switching
## will do (a fight is exactly the moment the party needs to stay on screen,
## not flash and vanish).
##
## Decoupled from `/root/Game` ON PURPOSE. Every other value this widget draws
## arrives through `update_from_party()` as plain data the caller already
## pulled off `Party`/`CreatureInstance` — nothing here calls `get_node(^"/root/Game")`
## or reads `party.gd` itself. That is what lets `tests/test_hud_widgets.gd`
## build one of these and drive it with hand-made dictionaries, with no
## autoload booted and no scene tree required. The eventual mount
## (`playground_hud.gd`, a later integration pass) is the only thing that
## reaches into `Game.party` and hands the result in.
##
## Five ROWS ALWAYS EXIST — never four, never six. `autoload/party.gd`'s own
## header is blunt about why: "Player can own only five creatures total... Never
## implement creature storage beyond five" (CLAUDE.md, twice over). A strip that
## grew or shrank rows with the roster would be one accidental step from a
## sixth slot; a strip that always draws five with some of them dim is not.
##
## Structure is built ONCE in `_build()` (called from `_ready()`, and callable
## directly by a test with no tree — see the test file's header for why that
## split matters). `update_from_party()` never adds or removes a node; it only
## ever writes values onto the fixed five rows, the same discipline
## `scripts/ui/menu_tab.gd`'s header describes for its own `build()`/`poll()`
## split: rebuilding a focused/animating node under itself is how a controller
## cursor — or here, an in-flight reveal tween — gets destroyed mid-motion.

const UI_TOKENS := preload("res://scripts/ui/ui_tokens.gd")

const SLOTS := 5
# Fixed at the occupied row's real text-driven height. A 56px minimum let
# occupied name/level stacks grow while vacant rows stayed short, invalidating
# the mount's five-row height and putting slot 5 over ACTIVE COMPANION.
const ROW_SIZE := Vector2(250.0, 96.0)  # 76 -> 96: room for STRIP_READABLE_FONT_SIZE's bigger text without clipping
const ROW_SEPARATION := 6
const ROW_MARGIN := 6
const HEADER_HEIGHT := 30.0
const HEADER_GAP := 6.0
const TOTAL_HEIGHT := HEADER_HEIGHT + HEADER_GAP + SLOTS * ROW_SIZE.y + (SLOTS - 1) * ROW_SEPARATION
const CHIP_SIZE := Vector2(40.0, 40.0)
## Local floor for this widget's own small text (TEAM count, level, KO/REST
## tags) -- deliberately not `UI_TOKENS.FONT_TINY`, which a dozen other
## screens this lane does not own also draw with (see
## `playground_hud.gd::HUD_READABLE_FONT_SIZE`'s identical reasoning). A blind
## critic measured this strip's own small text (13px on "Ripplet", 9-10px on
## "Lv 1"/"WATER") against a ~16px arm's-length cap-height floor.
## HUD-EMPHASIS: 34 -> 36. The formula floor (`smoke_hud_handheld_legibility.gd`'s
## own `CAP_HEIGHT_RATIO`) puts 34 at ~15.9 physical px -- under the 16px bar
## with zero margin, exactly what a later critic pass flagged ("roster names
## measure exactly 16px with no margin; any world-brightness change behind
## the translucent rows pushes them under"). 36 clears it with ~0.9px to
## spare.
const STRIP_READABLE_FONT_SIZE := 36
const RAIL_WIDTH := 4.0
const HP_BAR_SIZE := Vector2(72.0, 8.0)

## Fainted always reads as fainted, whether or not the slot happens to also be
## the (impossible, but not this file's job to assume) selected one.
const FAINTED_MODULATE := 0.4
const RESTING_MODULATE := 0.5
const UNSELECTED_MODULATE := 0.78
const VACANT_MODULATE := 0.62
const SELECTED_MODULATE := 1.0

## The KO badge's own `modulate.a`, exactly reciprocal to `FAINTED_MODULATE`
## -- see `_build_row()`'s own comment on the badge for why this constant,
## not a guess, is correct AND why it has to be `modulate` (which cascades to
## the badge's own child label) rather than `self_modulate` (which does not):
## `KO` only ever shows while the row's modulate is exactly
## `FAINTED_MODULATE`, so multiplying by its reciprocal here always lands
## back on a full 1.0 final alpha for both the badge and its text.
const KO_BADGE_MODULATE_COMPENSATION := 1.0 / FAINTED_MODULATE

## How far the strip slides while revealing, in local pixels. Small on
## purpose — this is a reveal, not a fly-in; §6.1 asks for a strip that reads
## as "appearing," not one that travels across the screen.
const REVEAL_OFFSET := 12.0

## OP21-12: the owner could not tell what was happening while cycling — the
## strip just reappeared with a different row lit up, indistinguishable from
## a menu flickering open. `flash_cycle()` below draws the transition itself
## (which creature you were on, which you're moving to, where that sits in
## the roster) for this long — comfortably inside `T_PARTY_FADE`'s hold, so
## the strip is never showing without it once a real cycle has happened.
const CYCLE_BANNER_SECONDS := 1.3
## See `_build()`'s own comment on the cycle banner node for why this is not
## `ROW_SIZE.x` any more -- a fixed 250px box silently clipped the whole
## second half of the from-to cue on every real render. 900, not the 480
## an initial repro with "Biscuit"/"Ripplet" found sufficient: the smoke
## test's own regression check (`smoke_hud_handheld_legibility.gd`) used the
## longer "Terrapup"/"Bramblebun" pair and still measured a real overflow at
## 640 -- creature names are player-visible strings this file does not
## control the length of, so the margin is sized off a longer real species
## pair, not the shortest one that happened to work. Widened again from 820
## to 900 alongside `CYCLE_DEST_FONT_SIZE` (HUD-EMPHASIS) -- the destination
## name now renders noticeably wider than it did at the old uniform size.
const CYCLE_BANNER_WIDTH := 900.0
## HUD-EMPHASIS root-cause: a blind critic measured the destination name --
## "the single word the player cycled to find out" -- as the SMALLEST text
## on the whole screen (10px), smaller than the creature being left behind
## (16px) and the "N / 5" position readout (15px), despite `flash_cycle()`
## below wrapping it in `[b]`. The bug was never a missing size difference:
## it was that only `normal_font_size` was ever overridden on this
## `RichTextLabel` -- `[b]` renders through the theme's separate
## `bold_font_size` item, which this file never touched, so the one run the
## player most needs to read fell back to Godot's small default bold size
## while everything else drew at `STRIP_READABLE_FONT_SIZE`. Fixed at the
## root two ways: `bold_font_size` is now explicitly overridden below
## (`_build()`), and `flash_cycle()` additionally wraps every run in its own
## `[font_size=]` tag so the from/to/position sizes are never at the mercy of
## an untouched theme fallback again.
##
## The four sizes below encode the fix's whole point, in order of emphasis:
## the destination is now the dominant element (`CYCLE_DEST_FONT_SIZE`,
## bigger than every other label on this HUD, not just this strip), the
## source is deliberately the small grey one (`CYCLE_SOURCE_FONT_SIZE`), and
## the arrow/position readout sit at a legible-but-secondary size in between.
## `CYCLE_DEST_FONT_SIZE` * 0.667 (Ally content scale) * 0.7 (cap-height
## ratio, `smoke_hud_handheld_legibility.gd::CAP_HEIGHT_RATIO`) ~= 21.5
## physical px, comfortably past the ~18px floor the critic asked for.
const CYCLE_SOURCE_FONT_SIZE := 24
const CYCLE_ARROW_FONT_SIZE := 30
const CYCLE_DEST_FONT_SIZE := 46
const CYCLE_POSITION_FONT_SIZE := 34
## 42 -> 50 -> 66: even after `CYCLE_BANNER_WIDTH` stopped the text from
## wrapping to a second (clipped) line, a live measurement found the single
## real line at `STRIP_READABLE_FONT_SIZE` (34) rendering ~47px tall --
## outline/shadow padding on top of the font's own line height. Grown again
## for `CYCLE_DEST_FONT_SIZE` (46, up from the old uniform 34): the same
## ~1.38x padding ratio puts a single line at that size around 63px, so 66
## keeps a few px of headroom rather than landing exactly on the edge.
const CYCLE_BANNER_HEIGHT := 66.0

var _pinned := false
var _fade_timer := 0.0
var _tween: Tween = null
var _cycle_banner_timer := 0.0

## The position the caller (the HUD, at mount time) placed this widget at.
## Captured once in `_build()` so the reveal tween has a fixed "home" to slide
## into rather than drifting further every time it fires.
var _rest_position := Vector2.ZERO

var _rows: Array[PanelContainer] = []
var _count_label: Label = null
var _list: VBoxContainer = null
var _cycle_banner: RichTextLabel = null
var _rails: Array[ColorRect] = []
var _chips: Array[Panel] = []
var _chip_boxes: Array[StyleBoxFlat] = []
var _portraits: Array[TextureRect] = []
var _slot_labels: Array[Label] = []
var _name_labels: Array[Label] = []
var _level_labels: Array[Label] = []
var _ko_labels: Array[Label] = []
## The badges wrapping `_ko_labels` -- see `_build_row()`'s own comment;
## `visible` toggles here, not on the label directly, since the badge is what
## carries the `self_modulate` compensation.
var _ko_badges: Array[PanelContainer] = []
var _rest_labels: Array[Label] = []
var _hp_bars: Array[ProgressBar] = []
var _hp_fills: Array[StyleBoxFlat] = []

## Per-row cache so a poll call that changes nothing writes nothing — the same
## reason `playground_hud.gd::_update_hotbar` only assigns a Label's `text`
## when it actually changed. `selected` state additionally gates which
## StyleBoxFlat a row wears; regenerating that box every call for five rows,
## sixty times a second, for four states that mostly do not change frame to
## frame, is wasted allocation for no visible difference.
var _last_label: Array[String] = ["", "", "", "", ""]
var _last_level: Array[int] = [-1, -1, -1, -1, -1]
var _last_portrait: Array[String] = ["", "", "", "", ""]
var _last_selected: Array[bool] = [false, false, false, false, false]
var _last_vacant: Array[bool] = [true, true, true, true, true]
## HUD-POPUP: whether the row that WAS selected last frame was also "out"
## (see `update_from_party()`'s own header) -- a separate cache from
## `_last_selected` because the same row can flip out<->not-out without its
## selected-ness changing at all (summoning a creature that was already the
## active pick), which needs the rail/chip recoloured even though neither
## `vacant` nor `selected` moved.
var _last_out: Array[bool] = [true, true, true, true, true]


## HUD-LAYOUT: `playground_hud.gd::_reflow_left_stack()` is the sole caller,
## once the creature panel below this widget has a real measured height (and
## again only if that height or the canvas size genuinely changes -- see
## that function's own header). Updates `_rest_position` unconditionally;
## only snaps `.position` to match immediately while the strip is not
## currently visible, so this can never yank the widget mid-reveal or
## mid-fade out from under its own tween -- the next `show_strip()` simply
## targets the new rest position like it always does.
func set_rest_position(pos: Vector2) -> void:
	_rest_position = pos
	if not visible:
		position = pos


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rest_position = position
	_build()
	UI_TOKENS.make_text_legible(self)
	modulate.a = 0.0
	visible = false


## Constructs the five fixed rows. Split out from `_ready()` so a test can call
## it directly on a bare `PartyStrip.new()` with no scene tree — see this
## file's header and `tests/test_hud_widgets.gd`.
func _build() -> void:
	if not _rows.is_empty():
		return  # idempotent: a test calling this twice must not double the rows

	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# HUD-POPUP: this widget's own rect used to stay (0, 0)-sized forever --
	# a plain `Control` parented directly under `Root` (not inside a
	# Container) never grows to fit its children the way `_creature_panel`'s
	# own `_reflow_left_stack()` comment describes for the SAME class of
	# node. Nothing noticed while every overlap check on this widget was
	# pure position math against the documented `TOTAL_HEIGHT`/`ROW_SIZE.x`
	# contract; the first check run against the REAL live scene
	# (`smoke_hud_handheld_legibility.gd`'s new overlap test) found
	# `get_global_rect()` reporting a real position but a zero size, which
	# makes `Rect2.intersects()` vacuously false against anything -- a check
	# that could never fail no matter where this widget actually drew.
	size = Vector2(ROW_SIZE.x, TOTAL_HEIGHT)
	var stack := VBoxContainer.new()
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_theme_constant_override("separation", int(HEADER_GAP))
	add_child(stack)

	var header := PanelContainer.new()
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.custom_minimum_size = Vector2(ROW_SIZE.x, HEADER_HEIGHT)
	var header_box := UI_TOKENS.panel_box(UI_TOKENS.BG_DEEP, Color(UI_TOKENS.TEAL, 0.72))
	header_box.content_margin_left = 6.0
	header_box.content_margin_top = 2.0
	header_box.content_margin_right = 6.0
	header_box.content_margin_bottom = 2.0
	header.add_theme_stylebox_override("panel", header_box)
	stack.add_child(header)

	_count_label = Label.new()
	_count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_count_label.text = "TEAM  0 / 5"
	_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_count_label.add_theme_font_size_override("font_size", STRIP_READABLE_FONT_SIZE)
	_count_label.add_theme_color_override("font_color", UI_TOKENS.TEAL_SOFT)
	header.add_child(_count_label)

	_list = VBoxContainer.new()
	_list.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_list.add_theme_constant_override("separation", ROW_SEPARATION)
	stack.add_child(_list)

	for i in SLOTS:
		_list.add_child(_build_row(i))

	# OP21-12's cycle banner. A sibling of `stack`, not a row inside it —
	# `TOTAL_HEIGHT` above is a hard contract other code measures against
	# (`playground_hud.gd::party_strip_position`, `test_hud_widgets.gd`'s
	# gap assertion), so this cannot join the VBox as a real row without
	# invalidating both. It sits just above the header instead, on-screen
	# clearance already checked by that same gap test.
	_cycle_banner = RichTextLabel.new()
	_cycle_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cycle_banner.bbcode_enabled = true
	_cycle_banner.fit_content = false
	_cycle_banner.scroll_active = false
	_cycle_banner.shortcut_keys_enabled = false
	# HUD-EMPHASIS: the destination name is wrapped in `[b]` (see
	# `flash_cycle()`) for extra weight on top of its own larger
	# `[font_size=]` tag -- `RichTextLabel` renders bold runs through the
	# theme's separate `bold_font_size` item, not `normal_font_size`, and
	# this was never overridden. Left alone, `[b]` silently fell back to
	# Godot's small default bold size, which is the actual reason the
	# destination name rendered as the SMALLEST text on screen even before
	# this task's font-size rework -- see `CYCLE_DEST_FONT_SIZE`'s own
	# header. Both are now explicit so neither can regress independently.
	_cycle_banner.add_theme_font_size_override("bold_font_size", CYCLE_DEST_FONT_SIZE)
	# HUD-EMPHASIS: a plate, docked onto the TEAM header rather than floating
	# free above it -- a blind critic found the banner sitting at the very
	# top of the screen with nothing behind it and no visual relationship to
	# the panel below ("Biscuit ▶ [unreadable] 2/5" at arm's length). Same
	# shape/tint as the header's own box so the two read as one element that
	# grew, not two unrelated widgets; the RichTextLabel's own `normal`
	# background stylebox is enough -- no extra Panel/Container needed.
	# Fully opaque background, not `BG_DEEP`'s own 0.90 alpha: the banner
	# renders on top of (and, while docked, exactly over) the header's own
	# bright `TEAM n / 5` text -- a real render with the header's default
	# alpha showed that text ghosting through the plate at zoom, since the
	# whole point of docking here is for the banner to fully replace the
	# header while it shows, not layer over it.
	var banner_box := UI_TOKENS.panel_box(Color(UI_TOKENS.BG_DEEP, 1.0), Color(UI_TOKENS.TEAL, 0.85))
	banner_box.content_margin_left = 12.0
	banner_box.content_margin_top = 4.0
	banner_box.content_margin_right = 12.0
	banner_box.content_margin_bottom = 4.0
	_cycle_banner.add_theme_stylebox_override("normal", banner_box)
	# HUD-EMPHASIS: was `-CYCLE_BANNER_HEIGHT` (fully above the header, flush
	# with its top) -- at the taller `CYCLE_BANNER_HEIGHT` the bigger
	# destination text now needs, that pushed the banner's own top edge
	# within single-digit px of the real screen top (`TOP_SAFE_INSET` is 56;
	# a critic already measured this banner's text starting at y~=13 even at
	# the OLD, shorter height). Docking it onto the header instead --
	# bottom edge flush with the header's own bottom, so the plated banner
	# visually REPLACES the header while it shows rather than stacking a
	# second box above it -- keeps only `CYCLE_BANNER_HEIGHT - HEADER_HEIGHT`
	# of new height pushing upward past the header's old top, not the whole
	# banner height. The banner draws after `stack` in this function (later
	# sibling = on top), so its opaque plate fully covers the header's own
	# "TEAM n / 5" text while visible instead of doubling it up.
	_cycle_banner.position = Vector2(0.0, -(CYCLE_BANNER_HEIGHT - HEADER_HEIGHT))
	# HUD-POPUP task 2: was `Vector2(ROW_SIZE.x, 42.0)` (250 wide) with CENTER
	# alignment. `flash_cycle()`'s bbcode ("Biscuit  ▶  Ripplet   2 / 5") is
	# wider than that at this font size; a first investigation into the
	# banner rendering as fully blank in every real capture chased this as
	# the cause (a too-narrow box wrapping to a clipped second line) and
	# widened it defensively -- worth keeping regardless, since it removes a
	# REAL (if smaller) partial-clip on longer creature-name pairs, see
	# `_check_cycle_banner_fits_without_clipping()` in
	# `smoke_hud_handheld_legibility.gd`. It was not, however, the actual
	# cause of the "completely blank" failure -- see `CYCLE_BANNER_SECONDS`'s
	# own comment on `tools/capture_hud_op21.gd`'s frame budget for that.
	# Left-aligned, not centered: if a name long enough to still overflow
	# this ever appears, the OUTGOING name and arrow -- the part of the cue
	# that establishes direction -- are what a reader sees first, not a
	# coin-flip on which end centering keeps on-screen.
	_cycle_banner.size = Vector2(CYCLE_BANNER_WIDTH, CYCLE_BANNER_HEIGHT)
	_cycle_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_cycle_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_cycle_banner.add_theme_font_size_override("normal_font_size", STRIP_READABLE_FONT_SIZE)
	_cycle_banner.visible = false
	add_child(_cycle_banner)


## HUD-EMPHASIS: a locally-owned row background rather than the shared
## `UI_TOKENS.slot_box()` a dozen other screens (menu tabs, combat, the
## minimap) also draw with -- the same "shared token, local override"
## reasoning `STRIP_READABLE_FONT_SIZE`'s own header gives for not raising
## that shared font floor. `slot_box()`'s `BG_PANEL_ALT` is already 0.82
## alpha, but a blind critic's proof case (Kite's greyed "KO" over a
## near-black rock) was not the alpha alone -- `_update_row()` ALSO
## multiplies the whole row's `modulate.a` down to `FAINTED_MODULATE` (0.4)
## for a fainted entry, compounding with the panel's own translucency to
## ~0.33 effective opacity over a variable, moving 3D backdrop. Raised here
## to a near-opaque floor so the row itself stays legible against any
## backdrop; the KO tag's own legibility against ITS row is handled
## separately below (`_ko_badge_boxes`), since a more opaque row alone does
## not fix a badge still multiplied by the same row modulate.
static func _row_box(selected: bool) -> StyleBoxFlat:
	var box := UI_TOKENS.slot_box(selected)
	var bg := box.bg_color
	box.bg_color = Color(bg.r, bg.g, bg.b, maxf(bg.a, 0.94))
	return box


func _build_row(slot_index: int) -> PanelContainer:
	var row := PanelContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.custom_minimum_size = ROW_SIZE
	row.add_theme_stylebox_override("panel", _row_box(false))
	_rows.append(row)

	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, ROW_MARGIN)
	row.add_child(margin)

	var hbox := HBoxContainer.new()
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_theme_constant_override("separation", 8)
	margin.add_child(hbox)

	var rail := ColorRect.new()
	rail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rail.custom_minimum_size = Vector2(RAIL_WIDTH, 0.0)
	rail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rail.color = UI_TOKENS.TEAL
	rail.visible = false
	_rails.append(rail)
	hbox.add_child(rail)

	# A species-tinted frame around an existing creature reference render. The
	# frame preserves the old at-a-glance type colour while the actual creature
	# silhouette makes adjacent party members identifiable without reading text.
	var chip := Panel.new()
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.custom_minimum_size = CHIP_SIZE
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var chip_box := StyleBoxFlat.new()
	chip_box.bg_color = UI_TOKENS.TEXT_MUTED
	chip_box.border_width_left = 1
	chip_box.border_width_top = 1
	chip_box.border_width_right = 1
	chip_box.border_width_bottom = 1
	chip_box.border_color = UI_TOKENS.BORDER
	chip.add_theme_stylebox_override("panel", chip_box)
	_chip_boxes.append(chip_box)
	_chips.append(chip)
	hbox.add_child(chip)

	var portrait := TextureRect.new()
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.position = Vector2(2.0, 2.0)
	portrait.size = CHIP_SIZE - Vector2(4.0, 4.0)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.visible = false
	_portraits.append(portrait)
	chip.add_child(portrait)

	var slot_label := Label.new()
	slot_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot_label.text = str(slot_index + 1)
	slot_label.position = Vector2.ZERO
	slot_label.size = CHIP_SIZE
	slot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slot_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	slot_label.add_theme_font_size_override("font_size", UI_TOKENS.FONT_LABEL)
	slot_label.add_theme_color_override("font_color", UI_TOKENS.TEXT_SECONDARY)
	_slot_labels.append(slot_label)
	chip.add_child(slot_label)

	var info := VBoxContainer.new()
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	info.add_theme_constant_override("separation", 2)
	hbox.add_child(info)

	var name_label := Label.new()
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.add_theme_font_size_override("font_size", STRIP_READABLE_FONT_SIZE)
	_name_labels.append(name_label)
	info.add_child(name_label)

	var level_row := HBoxContainer.new()
	level_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	level_row.add_theme_constant_override("separation", 6)
	info.add_child(level_row)

	var level_label := Label.new()
	level_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	level_label.add_theme_font_size_override("font_size", STRIP_READABLE_FONT_SIZE)
	level_label.add_theme_color_override("font_color", UI_TOKENS.TEXT_SECONDARY)
	_level_labels.append(level_label)
	level_row.add_child(level_label)

	# Small "KO" tag next to the level, shown only for a fainted entry — blind
	# visual review: a fainted creature in the strip had no marker at all, reading
	# identically to a healthy one at a glance.
	#
	# HUD-EMPHASIS: a solid badge, not bare text. A blind critic's proof case
	# (Kite's greyed "KO" over a near-black rock) traced to `_update_row()`
	# dimming the WHOLE row's `modulate.a` to `FAINTED_MODULATE` (0.4) for a
	# fainted entry -- exactly the state "KO" exists to announce, which made
	# the single most important status word in the roster its LEAST emphatic
	# one, for a compositing reason rather than a font-size one. A solid
	# `chip_box`-shaped backing plus `modulate` compensation
	# (`KO_BADGE_MODULATE_COMPENSATION`, below) makes the badge read at full
	# strength regardless of the row's own fade.
	#
	# `modulate`, not `self_modulate`: a first version of this used
	# `self_modulate`, which only affects a node's OWN drawing and does NOT
	# cascade to children -- a real render still showed the badge's child
	# `ko_label` text at the row's dim 0.4 alpha, because `self_modulate`
	# never touched it at all. `modulate` cascades multiplicatively to every
	# descendant the same way the row's own dimming does, so it both lifts
	# the badge's own panel AND the label text drawn inside it back to a
	# combined 1.0.
	# `PanelContainer`, not a bare `Panel`: a `Panel` reports a (0, 0) minimum
	# size and never auto-sizes to its child the way a Container does, so
	# inside `level_row`'s `HBoxContainer` it was allocated essentially no
	# area at all -- the label still drew (a `Control` draws itself at its
	# own computed rect regardless of its parent's), but the red backing box
	# behind it had almost no visible rect to paint. A real render caught
	# this directly: sampling pixels around the "KO" text found plain grass
	# green, not `UI_TOKENS.DANGER`. `PanelContainer` sizes itself to its
	# child plus the stylebox's own content margins, the same way every
	# other badge/chip shape in this codebase gets its background from its
	# content instead of a hand-measured size.
	var ko_badge := PanelContainer.new()
	ko_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ko_badge_box := StyleBoxFlat.new()
	ko_badge_box.bg_color = UI_TOKENS.DANGER
	ko_badge_box.corner_radius_top_left = UI_TOKENS.RADIUS_SLOT
	ko_badge_box.corner_radius_top_right = UI_TOKENS.RADIUS_SLOT
	ko_badge_box.corner_radius_bottom_left = UI_TOKENS.RADIUS_SLOT
	ko_badge_box.corner_radius_bottom_right = UI_TOKENS.RADIUS_SLOT
	ko_badge_box.content_margin_left = 6.0
	ko_badge_box.content_margin_right = 6.0
	ko_badge_box.content_margin_top = 1.0
	ko_badge_box.content_margin_bottom = 1.0
	ko_badge.add_theme_stylebox_override("panel", ko_badge_box)
	# `KO` only ever shows while `fainted` is true, and `_update_row()` only
	# ever sets the row's own `modulate.a` to exactly `FAINTED_MODULATE` in
	# that same state (see its own header) -- so a constant reciprocal here
	# is exact, not a guess: 0.4 (parent) * 2.5 (this) = 1.0 final alpha,
	# every time the badge is actually visible.
	ko_badge.modulate.a = KO_BADGE_MODULATE_COMPENSATION
	ko_badge.visible = false
	_ko_badges.append(ko_badge)
	level_row.add_child(ko_badge)

	var ko_label := Label.new()
	ko_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ko_label.text = "KO"
	ko_label.add_theme_font_size_override("font_size", STRIP_READABLE_FONT_SIZE)
	ko_label.add_theme_color_override("font_color", UI_TOKENS.TEXT_PRIMARY)
	_ko_labels.append(ko_label)
	ko_badge.add_child(ko_label)

	var rest_label := Label.new()
	rest_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rest_label.text = "REST"
	rest_label.add_theme_font_size_override("font_size", STRIP_READABLE_FONT_SIZE)
	rest_label.add_theme_color_override("font_color", UI_TOKENS.WATER_BLUE)
	rest_label.visible = false
	_rest_labels.append(rest_label)
	level_row.add_child(rest_label)

	var hp_bar := ProgressBar.new()
	hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_bar.custom_minimum_size = HP_BAR_SIZE
	hp_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hp_bar.show_percentage = false
	hp_bar.min_value = 0.0
	hp_bar.max_value = 1.0
	var track := UI_TOKENS.fill_box(UI_TOKENS.TRACK)
	hp_bar.add_theme_stylebox_override("background", track)
	var fill := UI_TOKENS.fill_box(UI_TOKENS.HP_GREEN)
	hp_bar.add_theme_stylebox_override("fill", fill)
	_hp_fills.append(fill)
	_hp_bars.append(hp_bar)
	hbox.add_child(hp_bar)

	return row


## Reveal the strip and (re)start its `T_PARTY_FADE` countdown. Call this
## every time the active creature changes, whether or not the strip is already
## showing — a second switch inside the fade window should refresh the timer,
## not let it lapse mid-read.
func show_strip() -> void:
	_fade_timer = UI_TOKENS.T_PARTY_FADE
	_reveal()


## OP21-12. `direction`: +1 for next, -1 for previous, called only when the
## caller (`playground_hud.gd::_update_party_strip`) can tell the new active
## index is genuinely adjacent (with wrap) to the one it replaced — a
## same-frame roster edit (a catch, a menu reorder) that happens to also move
## the active index leaves `direction` 0 and this call is skipped, so the
## banner never claims a cycle that didn't happen.
##
## Small muted "was" name, an arrow, LARGE bold "now" name, then position in
## the roster as a medium readout — the three things the owner said cycling
## didn't make clear: who you left, who you're on, and where that sits among
## five. HUD-EMPHASIS: every run carries its own explicit `[font_size=]` tag
## now (see `CYCLE_DEST_FONT_SIZE`'s own header for why relying on `[b]`
## alone silently under-sized the one run that matters most) -- the
## destination name is deliberately the dominant element on this whole HUD,
## not just the strip, since it is the one word the player cycled to find
## out.
func flash_cycle(direction: int, previous_label: String, next_label: String,
		position_1based: int, total: int) -> void:
	if _cycle_banner == null or direction == 0:
		return
	var arrow := "▶" if direction > 0 else "◀"
	_cycle_banner.text = (
		"[font_size=%d][color=#%s]%s[/color][/font_size]  " +
		"[font_size=%d][color=#%s]%s[/color][/font_size]  " +
		"[font_size=%d][b][color=#%s]%s[/color][/b][/font_size]   " +
		"[font_size=%d][color=#%s]%d / %d[/color][/font_size]"
	) % [
		CYCLE_SOURCE_FONT_SIZE, UI_TOKENS.TEXT_MUTED.to_html(false), previous_label,
		CYCLE_ARROW_FONT_SIZE, UI_TOKENS.TEXT_SECONDARY.to_html(false), arrow,
		CYCLE_DEST_FONT_SIZE, UI_TOKENS.TEAL_SOFT.to_html(false), next_label,
		CYCLE_POSITION_FONT_SIZE, UI_TOKENS.TEXT_SECONDARY.to_html(false), position_1based, total,
	]
	_cycle_banner.visible = true
	# HUD-EMPHASIS: the banner is docked directly over the header (see
	# `_build()`'s own comment on `_cycle_banner.position`) and its plate is
	# fully opaque -- but a real render still showed "TEAM n / 5" ghosting
	# through at zoom regardless, which a compositing z-order/alpha fix alone
	# did not fully explain. Hiding the header's own label outright while the
	# banner shows is the deterministic fix: there is nothing left underneath
	# to bleed through, however the plate itself ends up compositing.
	_count_label.visible = false
	_cycle_banner_timer = CYCLE_BANNER_SECONDS


## Pinned keeps the strip visible with no fade countdown at all — combat
## switching pins this so the party is always readable mid-fight. Unpinning
## does not snap the strip away; it hands control back to the fade timer,
## restarted, so a fight ending does not yank the strip off screen the instant
## the flag flips.
func set_pinned(pinned: bool) -> void:
	_pinned = pinned
	if pinned:
		_reveal()
	else:
		_fade_timer = UI_TOKENS.T_PARTY_FADE


## `entries`: up to `SLOTS` Dictionaries of
## `{label: String, level: int, hp_fraction: float, tint: Color,
## portrait: String, fainted: bool, resting: bool}`,
## in party order. Anything beyond `entries.size()` (and always, past
## `SLOTS`) reads as a vacant slot. The caller — `playground_hud.gd`, in the
## later integration pass — builds these from `Party.members()` and
## `CreatureInstance.label()`/`hp_fraction()`; this widget never reaches for either
## itself (see this file's header).
##
## HUD-POPUP task 2: `active_out` answers a question this widget could not
## ask on its own before -- is the SELECTED slot actually standing in the
## world, or just the roster's current pick? (`playground_hud.gd`'s own
## `_active_creature_is_out()` is the one place that reads `AllyCreature`
## from the live scene; this widget stays decoupled from the scene tree, per
## this file's own header, so the caller hands the answer in as plain data,
## the same as every other field on `entries`.) Defaults `true` so a caller
## that never passes it (every existing test) keeps the old always-bright
## rail rather than silently downgrading every selected row to "picked, not
## present."
func update_from_party(entries: Array, active_index: int, active_out: bool = true) -> void:
	_count_label.text = "TEAM  %d / %d" % [mini(entries.size(), SLOTS), SLOTS]
	for i in SLOTS:
		var has_creature: bool = i < entries.size()
		var entry: Dictionary = entries[i] if has_creature else {}
		var selected := has_creature and i == active_index
		_update_row(i, entry, has_creature, selected, selected and active_out)


func _update_row(i: int, entry: Dictionary, has_creature: bool, selected: bool, out: bool) -> void:
	var fainted := has_creature and bool(entry.get("fainted", false))
	var resting := has_creature and bool(entry.get("resting", false))
	var vacant := not has_creature

	if vacant != _last_vacant[i] or selected != _last_selected[i] or out != _last_out[i]:
		_last_out[i] = out
		_rows[i].add_theme_stylebox_override("panel", _row_box(selected))
		_rails[i].visible = selected
		# The rail is the ONE piece of this row's chrome that changes with
		# `out` -- full-brightness `TEAL` for "this creature is standing in
		# the world," the dimmer `TEAL_SOFT` for "this is the roster's pick,
		# nothing more" -- rather than touching the chip border too, which
		# stays the plain "this row is selected" signal it always was
		# (`test_selected_row_gets_the_teal_rail_and_full_modulate` already
		# covers that it must not vary).
		_rails[i].color = UI_TOKENS.TEAL if out else UI_TOKENS.TEAL_SOFT
		_chip_boxes[i].border_color = UI_TOKENS.TEAL_SOFT if selected else UI_TOKENS.BORDER
		var border_width := 2 if selected else 1
		_chip_boxes[i].border_width_left = border_width
		_chip_boxes[i].border_width_top = border_width
		_chip_boxes[i].border_width_right = border_width
		_chip_boxes[i].border_width_bottom = border_width
		_last_vacant[i] = vacant
		_last_selected[i] = selected

	if vacant:
		_chip_boxes[i].bg_color = Color(UI_TOKENS.TEXT_MUTED, 0.35)
		_rows[i].modulate.a = VACANT_MODULATE
		_set_label(_name_labels[i], i, "OPEN SLOT")
		_name_labels[i].add_theme_color_override("font_color", UI_TOKENS.TEXT_SECONDARY)
		_set_level(_level_labels[i], i, -1, "")
		# Chip outline only — a vacant row's HP bar (an empty track over
		# nothing) and level label are what blind visual review saw as "a
		# stray bar" between real entries. Hidden entirely, not just emptied.
		_level_labels[i].visible = false
		_ko_badges[i].visible = false
		_rest_labels[i].visible = false
		_set_portrait(i, "")
		_slot_labels[i].visible = true
		_hp_bars[i].visible = false
		_hp_bars[i].value = 0.0
		_hp_fills[i].bg_color = UI_TOKENS.HP_GREEN
		return

	_level_labels[i].visible = true
	_hp_bars[i].visible = true
	_slot_labels[i].visible = false
	_name_labels[i].add_theme_color_override("font_color", UI_TOKENS.TEXT_PRIMARY)

	var tint: Color = entry.get("tint", UI_TOKENS.TEXT_MUTED)
	_chip_boxes[i].bg_color = tint
	_set_portrait(i, str(entry.get("portrait", "")))
	_rows[i].modulate.a = (
		FAINTED_MODULATE if fainted
		else (RESTING_MODULATE if resting else (SELECTED_MODULATE if selected else UNSELECTED_MODULATE))
	)

	_set_label(_name_labels[i], i, str(entry.get("label", "")))
	var level := int(entry.get("level", 1))
	_set_level(_level_labels[i], i, level, "Lv %d" % level)
	_ko_badges[i].visible = fainted
	_rest_labels[i].visible = resting

	_hp_bars[i].value = clampf(float(entry.get("hp_fraction", 0.0)), 0.0, 1.0)
	_hp_fills[i].bg_color = UI_TOKENS.DANGER if fainted else UI_TOKENS.HP_GREEN


func _set_portrait(i: int, path: String) -> void:
	if _last_portrait[i] == path:
		return
	_last_portrait[i] = path
	var texture := load(path) as Texture2D if not path.is_empty() and ResourceLoader.exists(path) else null
	_portraits[i].texture = texture
	_portraits[i].visible = texture != null


func _set_label(label: Label, i: int, text: String) -> void:
	if _last_label[i] == text:
		return
	_last_label[i] = text
	label.text = text


func _set_level(label: Label, i: int, level: int, text: String) -> void:
	if _last_level[i] == level:
		return
	_last_level[i] = level
	label.text = text


func _reveal() -> void:
	visible = true
	if not is_inside_tree():
		# No live tree (a headless test calling this directly, say) — land in
		# the fully-shown state instantly rather than erroring on
		# `create_tween()`, which requires one.
		modulate.a = 1.0
		position = _rest_position
		return

	if _tween != null and _tween.is_valid():
		_tween.kill()
	position = _rest_position + Vector2(0.0, REVEAL_OFFSET)
	modulate.a = 0.0
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(self, "modulate:a", 1.0, UI_TOKENS.T_PARTY_REVEAL)
	_tween.tween_property(self, "position", _rest_position, UI_TOKENS.T_PARTY_REVEAL)


func _hide_strip() -> void:
	if not is_inside_tree():
		modulate.a = 0.0
		visible = false
		return

	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 0.0, UI_TOKENS.T_PARTY_REVEAL)
	_tween.finished.connect(_on_fade_out_finished)


func _on_fade_out_finished() -> void:
	visible = false


## HUD-LAYOUT root-cause: "the cycle banner works in an isolated harness but
## never appears in a real full-world capture" (CLAUDE.md task header).
## Instrumenting the real mounted widget at the moment of capture
## (`tools/capture_hud_op21.gd::_diagnose_cycle_banner`) found it exactly as
## the isolated harness did -- correct text, correct position, inside the
## viewport -- except `visible=false` on BOTH the banner and the whole
## strip. Both timers below are WALL-CLOCK countdowns (`CYCLE_BANNER_SECONDS`
## 1.3s, `UI_TOKENS.T_PARTY_FADE` 2.5s), decremented by `delta`, Godot's
## real elapsed seconds since the last `_process()` call -- not a frame
## count. A cold full Meadows boot (129k scattered props, first frames after
## a heavy scene load, worse still under software rendering or contended
## CPU) can render at a genuinely low framerate for its first several real
## frames, meaning `delta` on any one of those frames can be large -- easily
## large enough that a HANDFUL of real `_process()` calls exhausts a
## 1.3-2.5s hold before the reveal is ever drawn, let alone screenshotted.
## This is not a z-order or positioning bug at all: the widget is briefly
## alive and correct, then times itself out before anyone sees it.
##
## `MAX_TIMER_DELTA` caps what ANY SINGLE frame is allowed to subtract from
## either hold timer, the same technique a physics step clamps its own delta
## with to survive a debugger pause or a slow frame without a huge catch-up
## jump. One abnormally slow frame (a hitch, or the first frame after a
## scene transition) now costs at most one frame's worth of hold time, not
## however many real seconds it actually took -- the exact gap this bug
## lived in.
const MAX_TIMER_DELTA := 1.0 / 20.0


func _process(delta: float) -> void:
	var timer_delta: float = minf(delta, MAX_TIMER_DELTA)

	# Runs whether or not the strip itself is fading/pinned — a cycle mid-fight
	# (pinned) still deserves the same "who you were on, who you're on now"
	# readout the fade path gets.
	if _cycle_banner_timer > 0.0:
		_cycle_banner_timer -= timer_delta
		if _cycle_banner_timer <= 0.0:
			_cycle_banner.visible = false
			# HUD-EMPHASIS: undo flash_cycle()'s own header hide -- see that
			# function's comment for why the header label is hidden while the
			# banner shows.
			_count_label.visible = true

	if _pinned or not visible:
		return
	if _fade_timer > 0.0:
		_fade_timer -= timer_delta
		if _fade_timer <= 0.0:
			_hide_strip()
