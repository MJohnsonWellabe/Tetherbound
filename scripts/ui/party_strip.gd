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
## PROGRESSION-VISIBLE (prompt 73 §2.2): the strip is the Tick surface. It
## polls the progression feed itself (`_poll_feed`), so a `+12 XP` or a
## `+bond · fed` flicks the right row whether this is the exploration strip
## or the combat HUD's own mount, with nothing routed through either HUD.
const FEED := preload("res://scripts/creatures/progression_feed.gd")

const SLOTS := 5
# Fixed at the occupied row's real text-driven height. A 56px minimum let
# occupied name/level stacks grow while vacant rows stayed short, invalidating
# the mount's five-row height and putting slot 5 over ACTIVE COMPANION.
## GF-B-006: 96 -> 62. The height was two stacked `STRIP_READABLE_FONT_SIZE`
## lines; `_build_row()` now lays the name, level and status tags on ONE line,
## so a row is one text line plus its margins. No font size changes and nothing
## is dropped -- see `_build_row()`'s own comment. `TOTAL_HEIGHT` falls 540 ->
## 370, which is what makes the strip fit the left column.
##
## 62 is MEASURED, not chosen: a `PanelContainer` grows past its
## `custom_minimum_size` to fit its content, so a declared height under the real
## one makes `TOTAL_HEIGHT` a lie and every bound derived from it wrong. Built
## with real entries, the five rows report combined minimum heights of 62 (the
## selected row, which carries a border), 60 (a row showing the KO badge) and 58
## (a vacant row). 62 is the largest, so the declared height is an upper bound
## on every row state rather than a guess at the common one. A first render of
## this change declared 58 and the fifth row drew 10px into the vitals plate.
##
## WIDTH grows 250 -> 420, and that is not a cosmetic choice: at 250 the fixed
## furniture in a one-line row (rail, 40px chip, "Lv 1", the HP bar and their
## separations) leaves the name about 30px, and a first render of this change
## photographed the roster reading "Te / Rip / Lv 1 KO / Bro / Tus" -- every
## creature elided to its first syllable, which is worse than the defect being
## fixed. 420 gives the name ~220px, against the ~238 it had on its own line in
## the two-line design, so no name that fitted before stops fitting.
##
## The room is there because the strip is in the LEFT COLUMN now: 56 + 420 = 476,
## and the central third of the authored canvas starts at 640. It is checked, not
## assumed -- `test_hud_widgets.gd::test_party_strip_clears_the_centre_of_the_viewport`
## fails if this width ever grows past that margin.
## HUD-SCALE (owner playtest 2026-08-28, second "too big" report): 420x62 ->
## 336x46.
##
## A first cut to 304 -- the naive 26/36 scaling of the width alongside the
## font -- reopened the exact elision defect the note above records: a render
## came back reading "Galew" where 420 had held "Galewi...". Scaling the row
## with the font is wrong because most of a row is NOT text: the rail, the
## species chip, the HP bar and the separations are fixed furniture, so
## shrinking the row by 28% takes far more than 28% out of the name column,
## which is the only part that was ever the constraint. 336 with the bar cut
## to 44 gives the name about 165px against the ~159 the font drop asks for,
## so no name that fitted at 420/36 stops fitting at 336/26.
##
## Height is 48, and it is fitted to the SELECTED row rather than the ordinary
## one. That distinction cost a test failure worth recording: a first cut to 46
## fitted the unselected row exactly (a 36px label at
## `STRIP_READABLE_FONT_SIZE` 26 plus 2 x `ROW_MARGIN`), and
## `smoke_combat_hud_left_column.gd` immediately caught the roster running 2px
## past `TOTAL_HEIGHT` -- because `UITokens.slot_box(true)` puts an `EDGE`
## border on all four sides of the selected row, and a `PanelContainer` counts
## its stylebox margins in its own minimum size. Exactly one row is selected at
## any time, so the strip is always 2px taller than a row-height fitted to the
## other four. The old 62 was fitted the same way; that was not obvious from
## the number and is why this note exists.
## BLIND-JUDGE ROUND 1: 336 -> 420. PROGRESSION-VISIBLE added the bond pip
## ("bond 2/5") to a row that was already full, and the HBox had nowhere to
## take the width from: the judge read "Biscui" (the name truncated mid-word,
## too narrow even to draw its ellipsis) and "Lv 7bond 2/5" (the separation
## squeezed to nothing), with the HP bar crushed into the row's rounded
## border. The row is the only thing that grew; the strip still docks at
## `CREATURE_BLOCK_X` and the creature block above it is narrower than this.
const ROW_SIZE := Vector2(420.0, 48.0)
## 6 -> 2, and `HEADER_GAP` 6 -> 4 alongside it: together they pay for the 24px
## `HEADER_HEIGHT` below was under-reporting. Measured, the left column at the
## shorter supported canvas (1080) offers 380px between `TOP_SAFE_INSET` and the
## vitals plate's own `PARTY_ACTIVE_GAP`, and five rows plus an honest header
## want 394 -- so once the header stopped lying, the strip did not fit, and
## `test_hud_widgets.gd`'s two column bounds said so immediately.
##
## Taken from the separations rather than from `ROW_SIZE.y` or `HEADER_HEIGHT`,
## because those two are MEASURED heights and shaving either just re-tells the
## same lie one layer down. Every row is a `PanelContainer` with its own plate,
## border and `ROW_MARGIN` (4), so the rows stay visually separate at 2px of
## gap between plates -- this is the same call `ROW_MARGIN`'s own 6 -> 4 note
## records `GF-B-006` making for the one-line row design.
##
## HUD-SCALE restores this to 6. The pressure that forced it to 2 was the
## honest header plus five 62px rows wanting 394 of a 380px column; at
## `STRIP_READABLE_FONT_SIZE` 26 the rows are 48 and the header is 40, so the
## same five rows and header want 308 and the column has room again. The note
## above is right that the 2px gap was a cost, not a preference -- this gives
## it back rather than banking the space.
##
## WORTH THE OWNER KNOWING, and no longer true: at 1080 the roster at its
## five-creature cap used essentially the whole left column. After HUD-SCALE it
## uses about two thirds of it.
const ROW_SEPARATION := 6
const ROW_MARGIN := 4  # 6 -> 4, alongside ROW_SIZE.y: a one-line row needs less breathing room than a two-line one
## MEASURED, not declared. The header is a `PanelContainer` holding one label
## at `STRIP_READABLE_FONT_SIZE` with 2px content margins, and a
## `PanelContainer` grows past its `custom_minimum_size` to fit its content --
## the same trap `ROW_SIZE.y`'s own header records `GF-B-006` paying for on the
## rows. 30 was the declared number and the header really drew at **54** at the
## old 36px font, so `TOTAL_HEIGHT` was 24px short and every bound derived from
## it was wrong by that much: `playground_hud.gd::party_strip_position()`,
## `test_hud_widgets`'s gap assertions, and `combat_hud.gd::_party_strip_position()`,
## which is half of why `HIST-013` ("the combat HUD overlaps itself") was still
## reproducible.
##
## `GF-B-006` measured the rows and stopped there; that fix was the same defect
## one widget up. HUD-SCALE re-measures rather than re-scales, because a scaled
## guess here is exactly the lie both notes above record paying for: at
## `STRIP_READABLE_FONT_SIZE` 26 the live header draws **40**, confirmed by
## instrumenting the real widget, not by taking 54 * 26/36 (which gives 39 --
## close enough to look right and still wrong, which is the whole point).
##
## Pinned rather than re-measured by hand next time:
## `smoke_combat_hud_left_column.gd` asserts the live stack against
## `TOTAL_HEIGHT` and fails naming the child that grew.
const HEADER_HEIGHT := 40.0
const HEADER_GAP := 4.0
const TOTAL_HEIGHT := HEADER_HEIGHT + HEADER_GAP + SLOTS * ROW_SIZE.y + (SLOTS - 1) * ROW_SEPARATION
## HUD-SCALE: 40 -> 30. A species chip is recognised as a silhouette rather
## than read, so it has no lettering floor; 30 authored px is 18.5 arcmin.
const CHIP_SIZE := Vector2(30.0, 30.0)
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
## HUD-SCALE: 36 -> 26. Same correction as
## `playground_hud.gd::HUD_READABLE_FONT_SIZE`, and for the same reason -- the
## "~16 physical px at 0.667 scale" bar this constant was raised to clear was
## computed through a content scale the owner's 1920x1080 device does not
## have. 26 is `HUD_SCALE.GLANCE_CAP_ARCMIN`: a roster row is a name, a level
## and a tag, all recognised rather than read.
const STRIP_READABLE_FONT_SIZE := 26
const RAIL_WIDTH := 4.0
## 72 -> 56 alongside the one-line row: the bar shares its line with the name
## now instead of sitting beside a two-line stack, and 16px of bar buys 16px of
## name. A fraction still reads at 56px -- this bar has never carried a number.
## HUD-SCALE: 56 -> 44. The note above is still the reason this bar is short:
## it has never carried a number, so a fraction still reads. The 12px it gives
## up go straight to the name column, which is the row's real constraint.
const HP_BAR_SIZE := Vector2(44.0, 8.0)
## PROGRESSION-VISIBLE: the xp sliver under the HP bar -- same width, a third
## of the height, teal. Thin on purpose: it is the "how close to a level"
## readout the directive asks the world HUD for, not a second health bar.
const XP_BAR_SIZE := Vector2(44.0, 3.0)
const BAR_GAP := 2
## The bond pip text ("bond 2/5") beside the level, one size down from the
## row so the level number stays the louder of the two.
const BOND_FONT_SIZE := 19
## The name never shrinks below this, and the level/bond group never below
## its own content (both were being squeezed to illegibility, round 1).
const NAME_MIN_WIDTH := 150.0
const LEVEL_GROUP_SEPARATION := 10
## Enough for "bond 5/5" at BOND_FONT_SIZE without the row stealing it back.
const BOND_MIN_WIDTH := 86.0
## Tick label: floats just right of the row, outside the plate, like a
## damage number -- never inside the row, where it would fight the HP bar.
const TICK_FONT_SIZE := 22
const TICK_X := ROW_SIZE.x + 10.0
const TICK_RISE := 10.0
const TICK_PLATE_INSET_Y := 8.0


## A compact dark plate for one tick label -- the same deep panel ground the
## rest of the HUD uses, sized to its own text by PanelContainer.
static func _tick_plate_box() -> StyleBoxFlat:
	var box := UI_TOKENS.fill_box(Color(UI_TOKENS.BG_DEEP, 0.94))
	box.corner_radius_top_left = UI_TOKENS.RADIUS_SLOT
	box.corner_radius_top_right = UI_TOKENS.RADIUS_SLOT
	box.corner_radius_bottom_left = UI_TOKENS.RADIUS_SLOT
	box.corner_radius_bottom_right = UI_TOKENS.RADIUS_SLOT
	box.content_margin_left = 8.0
	box.content_margin_right = 8.0
	box.content_margin_top = 2.0
	box.content_margin_bottom = 2.0
	return box

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
const CYCLE_BANNER_WIDTH := 680.0  ## HUD-SCALE: 900 -> 680, tracking CYCLE_DEST_FONT_SIZE 46 -> 34.
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
## HUD-SCALE: 24/30/46/34 -> 22/24/34/26. The RANKING these four encode is the
## point (destination dominant, source small and grey, position quiet) and it
## is preserved exactly; only the absolute scale comes down, and the smallest
## of them -- the source name at 22 -- still sits at 11.0 arcmin cap height,
## on `HUD_SCALE.GLANCE_CAP_ARCMIN`. The destination stays the loudest text on
## this widget at 34.
const CYCLE_SOURCE_FONT_SIZE := 22
const CYCLE_ARROW_FONT_SIZE := 24
const CYCLE_DEST_FONT_SIZE := 34
const CYCLE_POSITION_FONT_SIZE := 26
## 42 -> 50 -> 66: even after `CYCLE_BANNER_WIDTH` stopped the text from
## wrapping to a second (clipped) line, a live measurement found the single
## real line at `STRIP_READABLE_FONT_SIZE` (34) rendering ~47px tall --
## outline/shadow padding on top of the font's own line height. Grown again
## for `CYCLE_DEST_FONT_SIZE` (46, up from the old uniform 34): the same
## ~1.38x padding ratio puts a single line at that size around 63px, so 66
## keeps a few px of headroom rather than landing exactly on the edge.
## HUD-SCALE: 66 -> 50. The derivation above is kept exactly -- the same
## ~1.38x outline/line-height padding ratio applied to the new
## `CYCLE_DEST_FONT_SIZE` (34) gives ~47px, so 50 keeps the same few px of
## headroom the 66 kept at 46. `smoke_hud_handheld_legibility.gd` measures the
## real banner against this box, so an over-cut fails rather than clips.
const CYCLE_BANNER_HEIGHT := 50.0

var _pinned := false
var _fade_timer := 0.0
var _tween: Tween = null
var _cycle_banner_timer := 0.0

## The position the caller (the HUD, at mount time) placed this widget at.
## Captured once in `_build()` so the reveal tween has a fixed "home" to slide
## into rather than drifting further every time it fires.
var _rest_position := Vector2.ZERO
var _readable_presentation := false


## Post-combat mechanics retain a stable, physically readable roster at 800p.
## Ordinary exploration/combat sizing and reveal timing are unchanged.
func set_readable_presentation(enabled: bool) -> void:
	_readable_presentation = enabled
	scale = Vector2.ONE / maxf(0.1, get_viewport().get_screen_transform().get_scale().x) if enabled else Vector2.ONE
	if enabled:
		if _tween != null and _tween.is_valid(): _tween.kill()
		modulate.a = 1.0
		position = _rest_position
		visible = true

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
## PROGRESSION-VISIBLE rows: xp sliver, bond pip, tick label, and the
## per-row feed state the flick/pulse read.
var _xp_bars: Array[ProgressBar] = []
var _xp_fills: Array[StyleBoxFlat] = []
var _bond_labels: Array[Label] = []
var _tick_labels: Array[Label] = []
var _tick_plates: Array[PanelContainer] = []
## One plain Control holding the five tick labels, so the widget keeps a
## fixed child list (stack, cycle banner, ticks) whatever the rows do.
var _ticks: Control = null
var _tick_left: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0]
var _near: Array[bool] = [false, false, false, false, false]
var _row_creature_ids: Array[int] = [0, 0, 0, 0, 0]
var _feed_seq: int = 0
var _feed_epoch: int = -1
var _pulse_clock: float = 0.0
## Evidence for a smoke: how many ticks each row has flicked and the last
## label it showed.
var _tick_counts: Array[int] = [0, 0, 0, 0, 0]
var _last_tick_label: Array[String] = ["", "", "", "", ""]

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
##
## OWNER-0902-HUD-TEAM-MENU: a real render caught the gap this left. The very
## first `_reflow_left_stack()` call can land before the viewport has settled
## its final stretched size (`_root.size` briefly reports a degenerate value
## on the opening frames -- the same settle race `_reflow_left_stack()`'s own
## header and several smoke tests already work around by awaiting a handful
## of frames before trusting `root.size`). If the party already has a
## creature at that moment (a save reload, a headless harness that seeds the
## party before the HUD mounts), `_update_party_strip()` can call
## `show_strip()` on that very first frame -- revealing the strip AT the
## wrong, transient rest position. Every later `set_rest_position()` call
## then only updates `_rest_position`, per this function's own contract
## above, leaving `.position` parked at that first wrong spot forever, since
## nothing ever calls `_reveal()` again. Snapping here whenever the target
## actually moved AND there is no reveal/fade tween currently running closes
## that gap without touching the tween contract above: a real mid-reveal is
## still never yanked, but a strip that already finished settling at a stale
## target self-corrects instead of staying wrong for the rest of the session.
func set_rest_position(pos: Vector2) -> void:
	var moved := not pos.is_equal_approx(_rest_position)
	_rest_position = pos
	if not visible:
		position = pos
	elif moved and (_tween == null or not _tween.is_valid()):
		position = pos


func _ready() -> void:
	add_to_group("progression_party_strips")
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rest_position = position
	# Start from the feed's present, not its history: a strip mounted after a
	# fight must not replay that fight's ticks.
	_feed_seq = FEED.latest_seq()
	_feed_epoch = FEED.epoch()
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

	# GF-B-006: ONE text line per row, not two stacked ones.
	#
	# The name used to sit in a VBox above a second line carrying the level and
	# the KO/REST tags, which made every row two `STRIP_READABLE_FONT_SIZE`
	# lines tall -- and five of those plus a header is `TOTAL_HEIGHT` 540, over
	# half the authored canvas, which is what `HIST-136`/OP23-09 ("the HUD takes
	# up far too much screen") and Gate F's own frame are both about. Nothing is
	# dropped and no text shrinks: the level and the tags move ONTO the name's
	# line, where there is room for them, and the row loses the line it did not
	# need. That is what lets the strip stand in the left column at all -- see
	# `playground_hud.gd::party_strip_position()` for why the left column is the
	# only place on this canvas that is out of the player's forward view.
	var info := HBoxContainer.new()
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	info.add_theme_constant_override("separation", 6)
	hbox.add_child(info)

	var name_label := Label.new()
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.add_theme_font_size_override("font_size", STRIP_READABLE_FONT_SIZE)
	# The name is the row's variable-length element, so it takes the slack and
	# elides; the level and the tags keep their own minimum widths beside it.
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.clip_text = true
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	# A floor under the name, so it elides with a visible "..." instead of
	# being cut mid-word when the level and bond pip beside it are long.
	name_label.custom_minimum_size = Vector2(NAME_MIN_WIDTH, 0.0)
	_name_labels.append(name_label)
	info.add_child(name_label)

	# Kept as its own container so the level, the KO badge and the REST tag stay
	# one group with their own separation -- the comments below on the badge's
	# `PanelContainer` and `modulate` compensation are about being inside a
	# Container, and that is still true here.
	var level_row := HBoxContainer.new()
	level_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	level_row.add_theme_constant_override("separation", LEVEL_GROUP_SEPARATION)
	level_row.size_flags_horizontal = Control.SIZE_SHRINK_END
	info.add_child(level_row)

	var level_label := Label.new()
	level_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	level_label.add_theme_font_size_override("font_size", STRIP_READABLE_FONT_SIZE)
	level_label.add_theme_color_override("font_color", UI_TOKENS.TEXT_SECONDARY)
	_level_labels.append(level_label)
	level_row.add_child(level_label)

	# PROGRESSION-VISIBLE: the bond pip. "bond 2/5" in the row itself, so the
	# roster answers "how bonded" without opening the Team screen; it flicks
	# on a bond tick and pulses slowly while a milestone is near.
	var bond_label := Label.new()
	bond_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bond_label.add_theme_font_size_override("font_size", BOND_FONT_SIZE)
	bond_label.add_theme_color_override("font_color", UI_TOKENS.WARNING)
	bond_label.visible = false
	bond_label.custom_minimum_size = Vector2(BOND_MIN_WIDTH, 0.0)
	_bond_labels.append(bond_label)
	# BLIND-JUDGE ROUND 2: this sat in `level_row`, immediately left of the HP
	# pill, and the judge read the pill as the bond meter -- "it reads as the
	# bond meter and therefore actively contradicts the number beside it".
	# It belongs with the name, on the text side of the row, with the bars
	# left to mean what the bars mean.
	info.add_child(bond_label)
	info.move_child(bond_label, 1)

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

	# HP bar over the xp sliver, one column at the row's right end.
	var bars := VBoxContainer.new()
	bars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bars.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bars.add_theme_constant_override("separation", BAR_GAP)
	hbox.add_child(bars)

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
	bars.add_child(hp_bar)

	# PROGRESSION-VISIBLE: the xp sliver (prompt 73 §2.2's Tick surface for
	# xp) -- fills toward the next level, flicks on an award, pulses when a
	# level is one fight away.
	var xp_bar := ProgressBar.new()
	xp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	xp_bar.custom_minimum_size = XP_BAR_SIZE
	xp_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	xp_bar.show_percentage = false
	xp_bar.min_value = 0.0
	xp_bar.max_value = 1.0
	xp_bar.add_theme_stylebox_override("background", UI_TOKENS.fill_box(UI_TOKENS.TRACK))
	var xp_fill := UI_TOKENS.fill_box(UI_TOKENS.TEAL)
	xp_bar.add_theme_stylebox_override("fill", xp_fill)
	xp_bar.visible = false
	_xp_fills.append(xp_fill)
	_xp_bars.append(xp_bar)
	bars.add_child(xp_bar)

	# The tick label lives on the STRIP, not in the row: a PanelContainer
	# would lay it into the row's rect, and the row's rect is full. It draws
	# just right of the plate, at this row's height (see `_row_top`).
	# BLIND-JUDGE ROUND 1: the tick was bare text with only a shadow, and the
	# judge measured the amber bond tag at ~1.3:1 against the backdrop --
	# "the feature's payload, invisible". It is the one HUD element that
	# lands over open ground rather than over a plate, so it gets its own.
	var tick_plate := PanelContainer.new()
	tick_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tick_plate.add_theme_stylebox_override("panel", _tick_plate_box())
	tick_plate.visible = false
	tick_plate.position = Vector2(TICK_X, _row_top(slot_index) + TICK_PLATE_INSET_Y)
	_tick_plates.append(tick_plate)

	var tick := Label.new()
	tick.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tick.add_theme_font_size_override("font_size", TICK_FONT_SIZE)
	tick.add_theme_color_override("font_color", UI_TOKENS.TEAL_SOFT)
	tick.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tick_plate.add_child(tick)
	_tick_labels.append(tick)
	if _ticks == null:
		_ticks = Control.new()
		_ticks.name = "Ticks"
		_ticks.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_ticks)
	_ticks.add_child(tick_plate)

	return row


## The y of row `i`'s top edge inside the strip.
static func _row_top(i: int) -> float:
	return HEADER_HEIGHT + HEADER_GAP + float(i) * (ROW_SIZE.y + float(ROW_SEPARATION))


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


## OWNER-0902-HUD-TEAM-MENU (owner playtest 2026-09-02, finding #12: "the team
## menu comes up twice after a fight"). `combat_hud.gd` mounts its own separate
## instance of this widget for mid-fight switching; `playground_hud.gd`'s
## exploration HUD mounts a second, independent instance that reveals itself
## whenever `Party.active_index`/`revision` changes -- which combat almost
## always does on the way out (a switch during the fight, a faint). Ending a
## fight by calling `set_pinned(false)` on the COMBAT instance only starts its
## `T_PARTY_FADE` countdown (see that function's own header on why -- it is the
## right behaviour for un-pinning mid-fight, when the strip is still relevant
## and just not locked open any more). Combat's strip is not "still relevant,
## just unpinned" once the fight is actually over, though: the exploration
## strip is about to reveal fresh in its place, and the two, fading in and out
## in different screen positions at once, is exactly the "twice" the owner
## saw -- along with combat's own instance, fed only the creatures still able
## to fight (`combat_manager.gd::_party` excludes fainted members), reading as
## a roster that "doesn't always show the full team." Called instead of
## `set_pinned(false)` at the exact moment a fight ends, so there is no second
## instance left on screen to be stale.
func hide_now() -> void:
	_pinned = false
	_fade_timer = 0.0
	_cycle_banner_timer = 0.0
	if _tween != null and _tween.is_valid():
		_tween.kill()
	if _cycle_banner != null:
		_cycle_banner.visible = false
	if _count_label != null:
		_count_label.visible = true
	modulate.a = 0.0
	visible = false


## Only the currently responsible HUD may reveal this strip for a tick.
## Inactive combat strips still advance their cursor without replaying awards.
var progression_feedback_enabled := true


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
		_xp_bars[i].visible = false
		_bond_labels[i].visible = false
		_near[i] = false
		_row_creature_ids[i] = 0
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

	# PROGRESSION-VISIBLE. An entry that carries no progression fields (an
	# older caller, a bare test) simply shows no sliver and no pip.
	_row_creature_ids[i] = int(entry.get("creature_id", 0))
	var has_xp := entry.has("xp_fraction")
	_xp_bars[i].visible = has_xp
	if has_xp:
		_xp_bars[i].value = clampf(float(entry.get("xp_fraction", 0.0)), 0.0, 1.0)
	var has_bond := entry.has("bond_nodes")
	_bond_labels[i].visible = has_bond
	if has_bond:
		_bond_labels[i].text = "bond %d/%d" % [int(entry.get("bond_nodes", 0)), int(entry.get("bond_total", 5))]
	_near[i] = bool(entry.get("bond_near", false)) or bool(entry.get("xp_near", false))
	if not _near[i]:
		_bond_labels[i].modulate.a = 1.0
		_xp_bars[i].modulate.a = 1.0


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
	if not is_inside_tree() or _readable_presentation:
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
	_poll_feed()
	_tick_ticks(timer_delta)
	_pulse_near(delta)

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

	if _pinned or _readable_presentation or not visible:
		return
	if _fade_timer > 0.0:
		_fade_timer -= timer_delta
		if _fade_timer <= 0.0:
			_hide_strip()


# --- PROGRESSION-VISIBLE: ticks and the near pulse -------------------------------

## Read every feed event since this strip last looked and flick the row it
## belongs to. Only Tick-level kinds (`xp_gained`, `bond_credit`) touch the
## strip; Moments are the world HUD banner's. A tick also reveals the strip
## (the same `show_strip()` a roster change uses), so an award seen while
## walking is seen on the plate that shows it, then fades as usual.
func _poll_feed() -> void:
	if _feed_epoch != FEED.epoch():
		_feed_epoch = FEED.epoch()
		_feed_seq = 0
		for i in SLOTS:
			_tick_left[i] = 0.0
			_tick_plates[i].hide()
			_tick_counts[i] = 0
			_last_tick_label[i] = ""
			_bond_labels[i].scale = Vector2.ONE
	var newest := FEED.latest_seq()
	if newest == _feed_seq:
		return
	var events := FEED.peek_since(_feed_seq)
	_feed_seq = newest
	if not progression_feedback_enabled:
		return
	var flicked := false
	for raw: Variant in events:
		var event := raw as Dictionary
		if not FEED.is_tick(event):
			continue
		var id := int(event.get("creature_id", 0))
		for i in SLOTS:
			if id != 0 and _row_creature_ids[i] == id:
				_flick(i, event)
				flicked = true
				# The sliver moves on the award itself, not on the next roster
				# poll, so the bar and the "+12 XP" agree on the same frame.
				if str(event.get("kind", "")) == "xp_gained" and _xp_bars[i].visible:
					var needed := float(event.get("xp_to_next", 0))
					if needed > 0.0:
						_xp_bars[i].value = clampf(float(event.get("xp", 0)) / needed, 0.0, 1.0)
	if flicked and not _pinned:
		show_strip()


func _flick(i: int, event: Dictionary) -> void:
	var label := FEED.tick_label(event)
	if label.is_empty():
		return
	var bond := str(event.get("kind", "")) == "bond_credit"
	_tick_labels[i].text = label
	_tick_labels[i].add_theme_color_override("font_color", UI_TOKENS.WARNING if bond else UI_TOKENS.TEAL_SOFT)
	_tick_plates[i].position = Vector2(TICK_X, _row_top(i) + TICK_PLATE_INSET_Y)
	_tick_plates[i].modulate.a = 1.0
	_tick_plates[i].visible = true
	_tick_left[i] = FEED.seconds("tick_seconds", 0.9)
	_tick_counts[i] += 1
	_last_tick_label[i] = label
	if bond and _bond_labels[i].visible:
		# The pip itself flicks: full bright now, eased back by `_tick_ticks`.
		_bond_labels[i].scale = Vector2(1.25, 1.25)
		_bond_labels[i].pivot_offset = _bond_labels[i].size * 0.5


func _tick_ticks(timer_delta: float) -> void:
	var total := FEED.seconds("tick_seconds", 0.9)
	for i in SLOTS:
		if _tick_left[i] <= 0.0:
			continue
		_tick_left[i] -= timer_delta
		var t := clampf(1.0 - _tick_left[i] / maxf(total, 0.01), 0.0, 1.0)
		# Rise a little and fade over the last half.
		_tick_plates[i].position = Vector2(TICK_X, _row_top(i) + TICK_PLATE_INSET_Y - TICK_RISE * t)
		_tick_plates[i].modulate.a = 1.0 if t < 0.5 else 1.0 - (t - 0.5) * 2.0
		_bond_labels[i].scale = Vector2.ONE.lerp(Vector2(1.25, 1.25), maxf(0.0, 1.0 - t * 2.0))
		if _tick_left[i] <= 0.0:
			_tick_plates[i].visible = false
			_bond_labels[i].scale = Vector2.ONE


## The Near level: a slow breathe on the pip and the sliver of any row within
## a threshold of a milestone or a level, until the milestone resolves and
## the next roster poll clears `_near`.
func _pulse_near(delta: float) -> void:
	var period := maxf(FEED.seconds("near_pulse_seconds", 1.6), 0.1)
	_pulse_clock = fmod(_pulse_clock + delta, period)
	var a := 0.55 + 0.45 * (0.5 + 0.5 * sin(_pulse_clock / period * TAU))
	for i in SLOTS:
		if not _near[i]:
			continue
		_bond_labels[i].modulate.a = a
		_xp_bars[i].modulate.a = a


## Evidence accessors for smokes: ticks flicked on row `i` and the last label.
func tick_count(i: int) -> int:
	return _tick_counts[i] if i >= 0 and i < SLOTS else 0


func last_tick_label(i: int) -> String:
	return _last_tick_label[i] if i >= 0 and i < SLOTS else ""


func row_is_near(i: int) -> bool:
	return _near[i] if i >= 0 and i < SLOTS else false


func xp_bar_value(i: int) -> float:
	return float(_xp_bars[i].value) if i >= 0 and i < SLOTS else 0.0


func bond_label_text(i: int) -> String:
	return _bond_labels[i].text if i >= 0 and i < SLOTS and _bond_labels[i].visible else ""
