extends CanvasLayer

## The real exploration HUD — the owner's Palworld-inspired layout
## (`ENVIRONMENT_AND_UI_BIBLE.md` §6/§6.6). This is the M-C integration pass:
## it mounts `party_strip.gd` and `stamina_arc.gd` (built and unit-tested
## standalone, `tests/test_hud_widgets.gd`) and `minimap.gd`/`map_baker.gd`
## (owned by a concurrent pass; mounted defensively, never edited here), and
## builds the rest of the layout — the active-creature block, the player vitals
## cluster, and the objective line — directly in code with `UITokens`
## factories.
##
## STRUCTURE VS DATA. The .tscn keeps only what genuinely wants to be
## hand-authored scene state: `Root` (and its load-bearing mouse_filter,
## see the .tscn's own comment), `HotbarPanel`, `Prompt` and `DebugReadout`.
## Everything the Palworld layout adds — the creature block, the vitals cluster,
## the mounted widgets, the objective block — is built once in `_ready()` and
## polled every frame in `_process()`, the same "structure once, poll every
## frame" split `menu_tab.gd` and `party_strip.gd` already use. Every Control
## created here sets `mouse_filter = MOUSE_FILTER_IGNORE` itself, for the same
## reason the .tscn's Root does (see its comment, and `tests/smoke_mouse_look.gd`,
## extended in this pass to walk the whole subtree and enforce it).
##
## Sized for the Ally: the project authors at 1920x1080 and stretches
## canvas_items, so the pixel positions below are real handheld screen space,
## not anchors that reflow at other resolutions. That is a deliberate scope
## limit shared with the rest of this HUD, not an oversight.
##
## F3 debug overlay is untouched by this pass — still OFF -> PERF -> FULL,
## still drawn into `DebugReadout`, which the .tscn keeps as before.

## A bar/cluster at rest fades to this rather than to zero: gone-and-back-again
## on every full heal reads as a layout pop, faint-but-present does not. Blind
## visual review flagged the first value tried (0.28) as unreadable — the fill
## and track blended into each other and the low-alpha edges read as a
## rendering artefact rather than a calm bar.
const FADE_ALPHA := 0.55
const FADE_SPEED := 2.2

## The exploration HUD's own fade while a combat throw is being aimed (spec
## §10.1) — the reticle over the wild creature is the thing to look at, and this
## HUD's own bars/hotbar/minimap are not part of that decision. Distinct
## from `FADE_ALPHA` above (that one is the per-widget idle fade for a
## calm-but-present bar); this one dims the whole `Root` at once, the same
## way `combat_hud.gd` dims its own enemy plate and move grid for the same
## reason.
const AIM_FADE_ALPHA := 0.35
const AIM_FADE_SPEED := 4.0

const READOUT_INTERVAL := 0.1

## F3 cycles OFF -> PERF -> FULL rather than toggling.
const DEBUG_OFF := 0
const DEBUG_PERF := 1
const DEBUG_FULL := 2

## ~2 seconds of frames at 60 Hz.
const FRAME_WINDOW := 120

const MB := 1048576.0

const CREATURE_SPECIES := preload("res://scripts/creatures/creature_species.gd")
const INPUT_GLYPH := preload("res://scripts/ui/input_glyph.gd")
const BUILD_MENU := preload("res://scripts/ui/build_menu.gd")
## OW10: the one "who owns input right now" question both world-verb polls ask.
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
const AUDIO_CUES := preload("res://scripts/ui/audio_cues.gd")

## EV9's owner-commissioned HUD glyphs (`docs/ASSET_LEDGER.md`, staged
## `369ecc5`). `orb_capture.png` has no mount yet — there is no orb-count
## panel anywhere in this HUD to hang it on (removed somewhere between the
## first EV9 slice's own note and this file's later full rewrite; a fresh
## grep of scripts/ui confirms no orb counter exists today) — so it stays
## unwired rather than forced onto an unrelated widget.
const ICON_HP := "res://assets/ui/icons/hud/hp_heart.png"
const ICON_STAMINA := "res://assets/ui/icons/hud/stamina_bolt.png"
const ICON_CREATURES := "res://assets/ui/icons/hud/creatures_paw.png"

const PARTY_STRIP_SCRIPT := "res://scripts/ui/party_strip.gd"
const STAMINA_ARC_SCRIPT := "res://scripts/ui/stamina_arc.gd"
## Owned by a concurrent agent this pass (see CLAUDE.md task header) — never
## edited here, only loaded and called defensively. If either file is missing
## or fails to produce a usable node, the minimap simply does not mount; every
## other block on this HUD is independent of it.
const MINIMAP_SCRIPT := "res://scripts/ui/minimap.gd"
const MAP_BAKER_SCRIPT := "res://scripts/world/map_baker.gd"

const HOTBAR_SLOTS := 5
## Action name IS the glyph id (input_glyph.gd's GLYPHS dict uses the same
## keys), so one list serves both jobs.
const HOTBAR_ACTIONS := ["hotbar_1", "hotbar_2", "hotbar_3", "hotbar_4", "hotbar_5"]
## Named constants (not the magic 28/16 this used to inline directly into the
## bbcode format string) so `smoke_hud_handheld_legibility.gd` can assert real
## physical pixel sizes against the values actually drawn, the way it already
## does for `LEGEND_GLYPH_PX`.
const HOTBAR_GLYPH_PX := 36
const HOTBAR_COUNT_FONT_SIZE := 36

const HOTBAR_MESSAGE_SECONDS := 2.2

## Pixels of clear screen between the hotbar panel's real bottom edge and the
## top of the context prompt, and the prompt row's own resting height.
##
## The two used to be pinned to the screen bottom independently — the prompt at
## -140, the hotbar at -144 — which read as one crowded block, and the first fix
## nudged the hotbar up by a hand-measured 26px. That number described one
## arrangement of one frame: the row collided again the moment either side
## changed height, which the hotbar does every time its message row appears.
## Stating the GAP instead and deriving the prompt from it is the same look with
## the relationship written down. TUNABLE.
## OW8: the gap is now `Root/BottomDock`'s own `separation` in the scene, not a
## number this script applies to the prompt's offsets. Third report of the same
## overlap, after two passes that each tuned a static gap and were each defeated
## by the hotbar's hidden Message row joining its VBox and growing the panel
## 30px. A VBoxContainer owning both controls cannot lay them into each other at
## any height, so there is no gap left to compute here.

## Owner directive, playtest pass: "name some of the areas and uncover them
## like fortnite maps do." `map_state.gd::take_pending_region_announcement()`
## queues the newly-entered region's display name once; this is how long the
## banner stays up before fading, same read-and-clear/timeout shape as
## `_hotbar_message` above just with a longer hold -- a location card is meant
## to be noticed, not glanced at.
const REGION_BANNER_SECONDS := 3.2

## --- layout (spec §6/§6.6, numbers inlined per the task) --------------------
## All positions are in the HUD's own 1920x1080 authoring space (top-left
## origin), matching the rest of this file's "sized for the Ally" convention.

## HUD-LAYOUT: the creature panel, the vitals cluster and the party strip
## used to be positioned with a fixed, hand-measured Y coordinate each,
## authored against a 1920x1080 canvas. That stopped being true the moment
## `_root`'s ACTUAL canvas stopped being 1080 tall -- this project stretches
## `canvas_items` with `aspect="expand"`, and the Ally's real 1280x800 window
## (aspect 1.6, narrower than the authored 1920x1080's 1.778) computes an
## effective canvas of 1920x1200, not 1920x1080. `Root/BottomDock` (the
## .tscn) already accounts for this correctly -- it anchors to the CANVAS
## BOTTOM (`anchor_top/bottom = 1`, `offset_top = -460`) so its position is
## always "460px above whatever the real bottom is." This left column never
## got the same treatment: `CREATURE_BLOCK_POS.y = 830` and
## `VITALS_POS.y = 1006` were both measured against an assumed 1080-tall
## canvas and anchored from the TOP. On the Ally's real 1200-tall canvas,
## BottomDock's top edge sits at 1200-460=740 -- squarely inside both blocks
## (830-992 and 1006-1070), a genuine, reproducible overlap confirmed by
## rendering the real HUD scene at 1280x800 and reading `get_global_rect()`
## on every block, not by eyeballing a screenshot. `_reflow_left_stack()`
## below fixes the ROOT cause: the whole left column (party strip, creature
## panel, vitals cluster) is now positioned from the CANVAS BOTTOM, using
## `_root.size.y` read at runtime, the same anchor BottomDock already uses --
## so the two can never drift apart again regardless of aspect ratio.
const CREATURE_BLOCK_X := 56.0
## Mirrors `Root/BottomDock`'s own `offset_top` in the .tscn exactly -- see
## the header above. Keep the two in sync if either changes; each file's
## comment points at the other.
const BOTTOM_DOCK_TOP_OFFSET := -460.0
## Clear space kept between the left column's lowest element and
## BottomDock's nominal top -- generous enough to survive BottomDock's own
## transient growth (the hotbar's Message row adding ~30px while a hotbar
## response is showing) without the two ever touching.
const LEFT_STACK_CLEARANCE := 40.0
## Floor for the party strip's reveal when there is not enough room above
## the creature panel to fit it in full -- see `party_strip_position()`'s
## own header. Matches `UITokens.HUD_INSET`, the same top-edge margin the
## minimap and objective block already use, so a clamped reveal still lines
## up with the rest of this HUD's top row rather than picking its own.
const TOP_SAFE_INSET := UITokens.HUD_INSET
const PARTY_ACTIVE_GAP := UITokens.GAP

## The creature panel no longer carries a fixed height -- see
## `_build_creature_block()`'s header for why hand-placed offsets were the
## actual defect, not just this file's old Y math. Width keeps a floor (not a
## cap): a `PanelContainer` only grows past this if a row's real content
## (namely "READY TO CALL OUT", the longest header string) genuinely needs
## more, which is the "honest minimum size" this task asked for instead of
## fixed pixels a longer string could silently overflow.
const CREATURE_BLOCK_MIN_WIDTH := 374.0

const VITALS_WIDTH := 300.0
## Real content height of the vitals cluster (buff row 0-28, HP icon/bar
## 28-54, satiety bar+label 54-70) -- used only to size the gap the left
## stack's reflow leaves above it; the cluster's own children still lay out
## with the same local offsets they always have.
const VITALS_HEIGHT := 70.0

const STAMINA_ARC_POS := Vector2(960.0 + 48.0, 540.0 - 160.0 * 0.5) ## centred-right of screen centre

const MINIMAP_SIZE := Vector2(240.0, 240.0)

const OBJECTIVE_MAX_WIDTH := 420.0
const OBJECTIVE_BLOCK_HEIGHT := 90.0

## OP21-11: the owner's own words were "should sit under the hotbar" — moved
## from RG3's original upper-left placement into `Root/BottomDock`'s
## VBoxContainer (see the .tscn's own long comment on why that container
## exists at all: it is the one place on this HUD where two variable-height
## rows genuinely cannot overlap, because Godot lays them out in sequence
## rather than at hand-tuned offsets). The legend is inserted between
## `HotbarPanel` and `Prompt` in `_build_exploration_legend()` below, so it
## always renders directly beneath the hotbar chips and directly above the
## contextual prompt — no separate position constant needed any more; the
## VBox derives it every frame from both neighbours' real heights.
##
## Glyph/font size, not position, is OP21-11's other half: the legend used to
## draw its glyphs at 24px, smaller than `input_glyph.gd::icon()`'s own
## documented floor ("28->36 was the smallest step that read clearly" for a
## harder glyph than any of these five carry) and the worst offender on the
## whole HUD at the project's 1920x1080 authoring scale. At the Ally's actual
## 1280x800 (canvas_items stretch, scale 1280/1920 = 0.667), that was ~16
## physical px. 44px authored -> ~29 physical px, comfortably past the
## established floor with margin for "more legible", not just "not the worst".
## OP21 handheld remainder: a blind critic measured the 44/24 pair above at
## real 1280x800 physical pixels and found the LABEL text -- not the glyph --
## still only 11px cap height, well under its own ~16px arm's-length bar
## (`UITokens.FONT_TINY`-scale text was the actual offender; the glyph image
## was already fine at 44 authored / ~29 physical). 24 -> 36 hits ~16.8
## physical cap height at this project's 0.667 canvas_items scale factor
## (36 * 0.667 * ~0.7 cap-height ratio); glyph raised the same 1.5x to stay
## proportional to the now-larger label beside it.
const LEGEND_GLYPH_PX := 66
const LEGEND_FONT_SIZE := 36
## Shared local floor for every other micro-label this file draws that the
## same critic measured at 9px -- "ACTIVE COMPANION", "Lv 1"/"GROUND", the
## hotbar item count. Deliberately NOT `UITokens.FONT_TINY`: that constant is
## shared by a dozen other screens this lane does not own (menu tabs, combat,
## the minimap), so bumping it here would move text this task never measured.
## 38 * 0.667 * ~0.7 ~= 17.7 physical px, clearing the ~16px bar with margin.
const HUD_READABLE_FONT_SIZE := 38
## RichTextLabel's `fit_content` measures height against its CURRENT width,
## and a freshly-built PanelContainer with no width hint of its own has none
## yet -- the label wrapped to a near-zero column and reported an absurd
## 1400+px content height the first time this ran. A fixed minimum size, the
## same approach the old top-left panel used, sidesteps that: wide enough for
## all five entries at the enlarged glyph/font (measured against "Change
## Creature", the longest label, plus its two switch-direction glyphs) with
## room to spare. Height is the 44px glyph plus `UITokens.panel_box()`'s own
## 16px top+16px content margin (32px total) -- `_build_exploration_legend`
## below deliberately adds NO further vertical margin on top of that; this
## exact double-margin mistake already shipped once (see the function's own
## history comment) and squeezed the glyph row down to an 8px label.
const LEGEND_SIZE := Vector2(1700.0, 112.0)

const MAX_BUFF_CHIPS := 3
const BUFF_CHIP_SIZE := 28.0

const HP_DANGER_BELOW := 0.30
const HP_PULSE_SPEED := 3.0
const HP_PULSE_DEPTH := 0.15

@export var player_path: NodePath
@export var arbiter_path: NodePath

const STUCK_AXES_HINT_AFTER := 3.0
const STUCK_AXES_EPSILON := 0.05

var _player: CharacterBody3D = null
var _arbiter: Node = null
var _game: Node = null
var _party: RefCounted = null

var _since_readout := 0.0
var _peak_fall := 0.0
var _last_damage := 0.0
var _debug_level := DEBUG_OFF

var _frame_ms := PackedFloat32Array()
var _frame_head := 0
var _frame_filled := 0

var _hardware_line := ""

var _pad_connected_for := 0.0
var _max_raw_axis_seen := 0.0

@onready var _root: Control = $Root
@onready var _prompt_label: RichTextLabel = $Root/BottomDock/Prompt
@onready var _debug_readout: Label = $Root/DebugReadout
@onready var _hotbar_chips: Array[PanelContainer] = [
	$Root/BottomDock/HotbarPanel/Margin/Layout/Slots/Slot1,
	$Root/BottomDock/HotbarPanel/Margin/Layout/Slots/Slot2,
	$Root/BottomDock/HotbarPanel/Margin/Layout/Slots/Slot3,
	$Root/BottomDock/HotbarPanel/Margin/Layout/Slots/Slot4,
	$Root/BottomDock/HotbarPanel/Margin/Layout/Slots/Slot5,
]
@onready var _hotbar_slots: Array[RichTextLabel] = [
	$Root/BottomDock/HotbarPanel/Margin/Layout/Slots/Slot1/Label,
	$Root/BottomDock/HotbarPanel/Margin/Layout/Slots/Slot2/Label,
	$Root/BottomDock/HotbarPanel/Margin/Layout/Slots/Slot3/Label,
	$Root/BottomDock/HotbarPanel/Margin/Layout/Slots/Slot4/Label,
	$Root/BottomDock/HotbarPanel/Margin/Layout/Slots/Slot5/Label,
]
@onready var _hotbar_panel: PanelContainer = $Root/BottomDock/HotbarPanel
@onready var _hotbar_message: Label = $Root/BottomDock/HotbarPanel/Margin/Layout/Message

var _hotbar_last_text: Array[String] = ["", "", "", "", ""]
var _hotbar_message_until := 0.0

## --- active-creature block --------------------------------------------------------

var _creature_block: Control = null
var _creature_panel: PanelContainer = null
var _creature_header: Label = null
var _creature_content: Control = null
var _creature_chip: ColorRect = null
var _creature_portrait: TextureRect = null
var _creature_portrait_path := ""
var _creature_name_label: Label = null
var _creature_level_label: Label = null
var _creature_type_label: Label = null
var _creature_hp_bar: ProgressBar = null
var _creature_hp_fill: StyleBoxFlat = null
var _creature_energy_bar: ProgressBar = null
var _creature_energy_fill: StyleBoxFlat = null
var _creature_no_creature_label: Label = null
var _creature_block_has_creature_last := true ## forces the first _update_creature_block to write
var _creature_icon: TextureRect = null
var _creature_hp_value_label: Label = null
var _creature_header_out_last := false ## -1-state forces the first header write
var _creature_header_has_creature_last := false

## Small always-on "how many, who's active" readout, five pips wide -- never
## more, never fewer, same "five rows always exist" discipline
## `party_strip.gd`'s own header documents, just persistent instead of a
## reveal-and-fade. Added because the full `party_strip.gd` reveal only shows
## for `UITokens.T_PARTY_FADE` seconds after a change: a blind critic reading
## an idle frame between changes saw ONE card (this block) and no five-slot
## roster anywhere, with the five-slot item hotbar sitting right below it as
## the only other five-of-anything on screen -- exactly the wrong thing to
## mistake for the team. This row answers "how many/which/what would cycling
## do" without text, at all times, not just mid-transition.
var _party_pips: Array[Panel] = []
var _party_pip_boxes: Array[StyleBoxFlat] = []

## --- party strip --------------------------------------------------------------

var _party_strip: Control = null
var _party_strip_script: Script = null
var _party_strip_last_index := -999
var _party_strip_last_revision := -999
## OP21-12: the last active creature's name, so a later cycle can say "Willow
## → Ashcap" instead of just lighting up a new row.
var _party_strip_last_active_label := ""

## --- player vitals cluster ----------------------------------------------------

var _vitals_cluster: Control = null
var _buff_chips: Array[Panel] = []
var _buff_chip_labels: Array[Label] = []
var _buff_overflow_label: Label = null
var _hp_icon: TextureRect = null
var _hp_bar: ProgressBar = null
var _hp_fill: StyleBoxFlat = null
var _hp_value_label: Label = null
var _satiety_bar: ProgressBar = null
var _satiety_state_label: Label = null

var _last_health_value := -1.0
var _health_flash_timer := 0.0
var _hp_pulse_time := 0.0

## --- stamina arc ---------------------------------------------------------------

var _stamina_arc: Control = null
var _stamina_icon: TextureRect = null
var _last_stamina_fraction := -1.0

## --- minimap (owned by a concurrent pass; mounted defensively) ----------------

var _minimap: Control = null
var _minimap_baked := false

## --- objective block ------------------------------------------------------------

var _objective_text_label: Label = null
var _objective_eyebrow_label: Label = null
var _objective_last_text := ""

## --- region banner ---------------------------------------------------------------

var _region_banner: Label = null
var _region_banner_until := 0.0

## --- persistent exploration legend (RG3) ---------------------------------------

var _exploration_legend: PanelContainer = null
var _exploration_legend_label: RichTextLabel = null
var _legend_last_gamepad := false
var _legend_last_party_revision := -999
var _legend_was_drawn := false

## --- left-column reflow (HUD-LAYOUT) --------------------------------------------

## Sentinel below any real canvas height, so the first `_reflow_left_stack()`
## call after `_ready()` always runs once, whatever `_root.size.y` turns out
## to be by then.
var _left_stack_canvas_h := -1.0
var _left_stack_creature_h := -1.0


func _ready() -> void:
	_player = get_node_or_null(player_path) as CharacterBody3D
	if _player == null:
		push_warning("HUD has no player; readout will stay empty")
	elif _player.has_signal("landed"):
		_player.connect("landed", _on_landed)

	_arbiter = get_node_or_null(arbiter_path)
	if _arbiter != null and _arbiter.has_signal("prompt_changed"):
		_arbiter.connect("prompt_changed", _on_prompt_changed)

	_build_creature_block()
	_mount_party_strip()
	_build_vitals_cluster()
	_mount_stamina_arc()
	_mount_minimap()
	_build_objective_block()
	_build_region_banner()
	_build_exploration_legend()
	_style_hotbar()

	# Placed FROM the hotbar rather than beside it. `resized` is the hook that
	# matters: the panel's height changes whenever its message row appears, and
	# nothing else fires on that.

	UITokens.make_text_legible(_prompt_label)
	UITokens.make_text_legible(_hotbar_message)
	UITokens.make_text_legible(_region_banner)
	for slot in _hotbar_slots:
		UITokens.make_text_legible(slot)

	_frame_ms.resize(FRAME_WINDOW)
	_hardware_line = "%s | %s | driver %s" % [
		RenderingServer.get_video_adapter_name(),
		str(ProjectSettings.get_setting("rendering/renderer/rendering_method", "?")),
		"/".join(OS.get_video_adapter_driver_info()),
	]

	_debug_readout.visible = _debug_level != DEBUG_OFF

	# Seeded from the arbiter rather than blanked, because `prompt_changed`
	# only fires on a CHANGE: if the arbiter published before this HUD
	# connected, waiting for the next edge would leave the prompt blank while
	# the player stands in front of something interactable.
	_prompt_label.text = "" if _prompt_belongs_to_combat() \
			else (str(_arbiter.call("prompt")) if _arbiter != null else "")

	# Structure is finished: outline/shadow every Label and RichTextLabel this
	# file just built, in one pass, rather than one make_text_legible call per
	# widget scattered through the builders above.
	UITokens.make_text_legible(_root)
	_strengthen_objective_contrast()
	_reflow_left_stack()


func _style_hotbar() -> void:
	$Root/BottomDock/HotbarPanel.add_theme_stylebox_override("panel", UITokens.panel_box())
	for chip in _hotbar_chips:
		chip.add_theme_stylebox_override("panel", UITokens.slot_box(false))


# --- active-creature block ----------------------------------------------------------


## HUD-LAYOUT: rebuilt from hand-placed `.position`/`.size` offsets onto real
## containers. Every element that used to be told its own pixel rect now
## only says how it wants to relate to its NEIGHBOURS -- a `PanelContainer`
## whose only fixed number is a width FLOOR (`CREATURE_BLOCK_MIN_WIDTH`, not
## a cap) around a `VBoxContainer` of rows, each row itself an `HBoxContainer`
## where it has more than one element. This is a direct fix for a concrete,
## reproduced defect, not a style preference: at `HUD_READABLE_FONT_SIZE`
## (bumped 24->38 by an earlier pass for legibility, correctly, but never
## paired with bigger rects for the same text), the OLD fixed-offset layout
## had "READY TO CALL OUT" overrunning its 324px label box, the five party
## pips hand-placed at a fixed y=32 landing ON TOP OF that overrun text, the
## HP value label's 16px-tall box unable to hold its own 38px font and
## spilling below the panel's bottom edge, and the level/HP rows close
## enough together (34 and 68) that the HP bar's fill visibly clipped the
## bottom of "Lv 1". None of those are possible once each row's height comes
## from its own children's real minimum size instead of a guessed offset --
## a `VBoxContainer` cannot lay a later row on top of an earlier one, the
## same guarantee `Root/BottomDock` already relies on for the hotbar/legend/
## prompt stack (see that node's own long comment in the .tscn).
##
## Portrait chip, label()/level, HP bar, an energy strip shown only while
## there IS energy to show, and a type tag — or, with no active creature, a dim
## "No creature out" chip. Species tint comes from `CreatureSpecies.placeholder()`, the
## same lookup `party_strip.gd`'s caller (this file, below) uses, so the two
## widgets can never tint the same creature two different colours.
func _build_creature_block() -> void:
	_creature_block = Control.new()
	_creature_block.name = "CreatureBlock"
	_creature_block.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_creature_block)

	_creature_panel = PanelContainer.new()
	_creature_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_creature_panel.custom_minimum_size = Vector2(CREATURE_BLOCK_MIN_WIDTH, 0.0)
	_creature_panel.add_theme_stylebox_override(
		"panel", UITokens.panel_box(UITokens.BG_DEEP, Color(UITokens.TEAL, 0.72))
	)
	_creature_block.add_child(_creature_panel)

	# `panel_box()` already contributes 16px of content margin on every side
	# via the stylebox itself -- a `PanelContainer` applies that automatically
	# to whatever it holds, so no separate `MarginContainer` belongs here (the
	# exact double-margin trap `_build_exploration_legend()`'s own comment
	# already names for the legend panel).
	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 8)
	_creature_panel.add_child(vbox)

	var header_row := HBoxContainer.new()
	header_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header_row.add_theme_constant_override("separation", 8)
	vbox.add_child(header_row)

	_creature_icon = TextureRect.new()
	_creature_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_creature_icon.texture = load(ICON_CREATURES)
	_creature_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_creature_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_creature_icon.custom_minimum_size = Vector2(24.0, 24.0)
	_creature_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header_row.add_child(_creature_icon)

	_creature_header = Label.new()
	_creature_header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_creature_header.text = "ACTIVE COMPANION"
	_creature_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_creature_header.clip_text = true
	_creature_header.add_theme_font_size_override("font_size", HUD_READABLE_FONT_SIZE)
	_creature_header.add_theme_color_override("font_color", UITokens.TEAL_SOFT)
	header_row.add_child(_creature_header)

	## Five persistent pips, on their own row below the header text -- see
	## `_party_pips`'s own declaration for why this exists alongside the
	## transient `party_strip.gd` reveal rather than instead of it. A row of
	## its own, laid out by `HBoxContainer`, so it can never land on top of
	## the header text above it regardless of how wide that text gets.
	var pip_row := HBoxContainer.new()
	pip_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pip_row.alignment = BoxContainer.ALIGNMENT_END
	pip_row.add_theme_constant_override("separation", 6)
	vbox.add_child(pip_row)
	for i in 5:
		var pip := Panel.new()
		pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pip.custom_minimum_size = Vector2(18.0, 18.0)
		var pip_box := StyleBoxFlat.new()
		pip_box.bg_color = Color(UITokens.TEXT_MUTED, 0.35)
		pip_box.border_width_left = 1
		pip_box.border_width_top = 1
		pip_box.border_width_right = 1
		pip_box.border_width_bottom = 1
		pip_box.border_color = UITokens.BORDER
		pip_box.corner_radius_top_left = 3
		pip_box.corner_radius_top_right = 3
		pip_box.corner_radius_bottom_left = 3
		pip_box.corner_radius_bottom_right = 3
		pip.add_theme_stylebox_override("panel", pip_box)
		_party_pip_boxes.append(pip_box)
		_party_pips.append(pip)
		pip_row.add_child(pip)

	_creature_content = VBoxContainer.new()
	_creature_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_creature_content.add_theme_constant_override("separation", 6)
	vbox.add_child(_creature_content)

	var info_row := HBoxContainer.new()
	info_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_row.add_theme_constant_override("separation", 12)
	_creature_content.add_child(info_row)

	# 56x56, up from 40x40 -- a blind critic called the old ~28-physical-px
	# portrait "too small to identify a species at arm's length", and a
	# portrait reads faster than the name text beside it once it is big
	# enough to actually show the silhouette. Wrapped in its own fixed-size
	# Control: the chip and portrait are meant to overlay each other (the
	# portrait's transparent surround shows the species-tinted chip behind
	# it), which is the one place in this panel two children legitimately
	# share a rect on purpose rather than by accident.
	var portrait_slot := Control.new()
	portrait_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_slot.custom_minimum_size = Vector2(56.0, 56.0)
	info_row.add_child(portrait_slot)

	_creature_chip = ColorRect.new()
	_creature_chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_creature_chip.position = Vector2(0.0, 0.0)
	_creature_chip.size = Vector2(56.0, 56.0)
	portrait_slot.add_child(_creature_chip)

	_creature_portrait = TextureRect.new()
	_creature_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_creature_portrait.position = Vector2(3.0, 3.0)
	_creature_portrait.size = Vector2(50.0, 50.0)
	_creature_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_creature_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait_slot.add_child(_creature_portrait)

	var info_col := VBoxContainer.new()
	info_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	info_col.add_theme_constant_override("separation", 2)
	info_row.add_child(info_col)

	# Bumped to match the rest of this panel's text (was `FONT_BODY`, 26) --
	# a blind critic separately measured the creature's own NAME at ~14px
	# physical cap height, just under the ~16px arm's-length floor every
	# other label on this panel was already raised to clear.
	_creature_name_label = Label.new()
	_creature_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_creature_name_label.clip_text = true
	_creature_name_label.add_theme_font_size_override("font_size", HUD_READABLE_FONT_SIZE)
	info_col.add_child(_creature_name_label)

	var level_type_row := HBoxContainer.new()
	level_type_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	level_type_row.add_theme_constant_override("separation", 16)
	info_col.add_child(level_type_row)

	_creature_level_label = Label.new()
	_creature_level_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_creature_level_label.add_theme_font_size_override("font_size", HUD_READABLE_FONT_SIZE)
	_creature_level_label.add_theme_color_override("font_color", UITokens.TEXT_SECONDARY)
	level_type_row.add_child(_creature_level_label)

	_creature_type_label = Label.new()
	_creature_type_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_creature_type_label.add_theme_font_size_override("font_size", HUD_READABLE_FONT_SIZE)
	level_type_row.add_child(_creature_type_label)

	# HP bar and its "78 / 120" readout sit SIDE BY SIDE in one row instead
	# of the old bar-with-a-label-floating-past-its-own-rect: the bar takes
	# whatever width is left (`SIZE_EXPAND_FILL`), the value gets its own
	# fixed column, and an `HBoxContainer` cannot let either draw outside the
	# panel the way a hand-placed `position.x = 246` with a 94px-wide label
	# box could once the font inside it grew.
	var hp_row := HBoxContainer.new()
	hp_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_row.add_theme_constant_override("separation", 10)
	_creature_content.add_child(hp_row)

	_creature_hp_bar = ProgressBar.new()
	_creature_hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_creature_hp_bar.custom_minimum_size = Vector2(160.0, 18.0)
	_creature_hp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_creature_hp_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_creature_hp_bar.show_percentage = false
	_creature_hp_bar.min_value = 0.0
	_creature_hp_bar.max_value = 1.0
	_creature_hp_bar.add_theme_stylebox_override("background", UITokens.fill_box(UITokens.TRACK))
	_creature_hp_fill = UITokens.fill_box(UITokens.HP_GREEN)
	_creature_hp_bar.add_theme_stylebox_override("fill", _creature_hp_fill)
	hp_row.add_child(_creature_hp_bar)

	# Numeric readout beside the bar -- a blind critic read the bare fill as
	# "an unlabeled ~55%-filled green bar [that] reads as wrong at a glance"
	# on a fresh Lv 1 creature with nothing wrong with it. The player's own
	# vitals cluster already pairs its bar with a "284 / 320" label; this
	# gives the companion's HP the same treatment instead of a bare fill.
	_creature_hp_value_label = Label.new()
	_creature_hp_value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_creature_hp_value_label.custom_minimum_size = Vector2(100.0, 0.0)
	_creature_hp_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_creature_hp_value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_creature_hp_value_label.clip_text = true
	_creature_hp_value_label.add_theme_font_size_override("font_size", HUD_READABLE_FONT_SIZE)
	_creature_hp_value_label.add_theme_color_override("font_color", UITokens.TEXT_SECONDARY)
	hp_row.add_child(_creature_hp_value_label)

	_creature_energy_bar = ProgressBar.new()
	_creature_energy_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_creature_energy_bar.custom_minimum_size = Vector2(0.0, 6.0)
	_creature_energy_bar.show_percentage = false
	_creature_energy_bar.min_value = 0.0
	_creature_energy_bar.max_value = 1.0
	_creature_energy_bar.add_theme_stylebox_override("background", UITokens.fill_box(UITokens.TRACK))
	_creature_energy_fill = UITokens.fill_box(UITokens.TEAL)
	_creature_energy_bar.add_theme_stylebox_override("fill", _creature_energy_fill)
	_creature_content.add_child(_creature_energy_bar)

	_creature_no_creature_label = Label.new()
	_creature_no_creature_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_creature_no_creature_label.text = "No creature out"
	_creature_no_creature_label.add_theme_font_size_override("font_size", UITokens.FONT_LABEL)
	_creature_no_creature_label.add_theme_color_override("font_color", UITokens.TEXT_MUTED)
	_creature_no_creature_label.visible = false
	vbox.add_child(_creature_no_creature_label)


func _update_creature_block() -> void:
	var creature: RefCounted = null
	if _party != null and int(_party.call("size")) > 0:
		creature = _party.call("active")
	var has_creature := creature != null

	if has_creature != _creature_block_has_creature_last:
		_creature_content.visible = has_creature
		_creature_no_creature_label.visible = not has_creature
		_creature_block_has_creature_last = has_creature

	_update_creature_header(has_creature)
	_update_party_pips()

	if not has_creature:
		return

	var species_id := str(creature.get("species_id"))
	_creature_chip.color = _species_tint(species_id)
	var portrait_path := _species_portrait_path(species_id)
	if portrait_path != _creature_portrait_path:
		_creature_portrait_path = portrait_path
		var portrait_texture: Texture2D = null
		if ResourceLoader.exists(portrait_path):
			portrait_texture = load(portrait_path) as Texture2D
		_creature_portrait.texture = portrait_texture
	_creature_name_label.text = str(creature.call("label"))
	_creature_level_label.text = "Lv %d" % int(creature.get("level"))

	var creature_type := str(creature.get("creature_type"))
	_creature_type_label.text = creature_type.to_upper()
	_creature_type_label.add_theme_color_override("font_color", _type_colour(creature_type))

	_creature_hp_bar.value = clampf(float(creature.call("hp_fraction")), 0.0, 1.0)
	_creature_hp_value_label.text = "%d / %d" % [
		int(round(float(creature.get("hp")))), int(round(float(creature.get("max_hp")))),
	]

	var energy := float(creature.get("energy"))
	_creature_energy_bar.visible = energy > 0.0
	if _creature_energy_bar.visible:
		_creature_energy_bar.value = clampf(float(creature.call("energy_fraction")), 0.0, 1.0)


## Two independent critics both flagged the same contradiction: this block
## said "ACTIVE COMPANION <name>" while the centre prompt, at the same
## moment, offered "Call out <name>" -- i.e. the HUD asserted the creature
## was both out and stowed within ~100 vertical pixels. Investigation: it is
## a LABELLING bug, not a state bug. `Party.active()` (what this block reads)
## means "the roster slot the player has selected," full stop -- it carries
## no idea whether that creature is actually spawned in the world.
## `encounter_director.gd::_creature_control_offer()` is the thing that
## actually knows that, via its own `_ally_body` (a real `Node3D`, present
## only after `summon_active_creature()` runs) -- exposed publicly as
## `ally_body()`, and already read the same defensive way
## `_update_minimap()`'s own header describes (find "AllyCreature" by name in
## the current scene, no coupling to which provider is arbitrating). When
## no such node exists, the header now says "READY TO CALL OUT" instead of
## "ACTIVE COMPANION" -- true in both states, and never contradicts the
## centre prompt sitting right below it.
func _update_creature_header(has_creature: bool) -> void:
	var out := false
	if has_creature:
		var world := get_tree().get_current_scene()
		var ally: Node = world.get_node_or_null(^"AllyCreature") if world != null else null
		out = ally != null and is_instance_valid(ally)
	if out == _creature_header_out_last and has_creature == _creature_header_has_creature_last:
		return
	_creature_header_out_last = out
	_creature_header_has_creature_last = has_creature
	_creature_header.text = "ACTIVE COMPANION" if out else "READY TO CALL OUT"


## Persistent five-pip roster readout -- filled+tinted for an owned slot,
## bright ring for whichever is active, dim red for fainted. See `_party_pips`'s
## declaration for why this exists alongside `party_strip.gd`'s own transient
## reveal rather than replacing it.
func _update_party_pips() -> void:
	if _party == null:
		for i in _party_pip_boxes.size():
			_party_pip_boxes[i].bg_color = Color(UITokens.TEXT_MUTED, 0.35)
			_party_pip_boxes[i].border_color = UITokens.BORDER
			_party_pip_boxes[i].border_width_left = 1
			_party_pip_boxes[i].border_width_top = 1
			_party_pip_boxes[i].border_width_right = 1
			_party_pip_boxes[i].border_width_bottom = 1
		return
	var members: Array = _party.call("members")
	var active_index := int(_party.call("active_index"))
	for i in _party_pip_boxes.size():
		var box := _party_pip_boxes[i]
		var selected := i == active_index and i < members.size()
		var border_width := 3 if selected else 1
		box.border_width_left = border_width
		box.border_width_top = border_width
		box.border_width_right = border_width
		box.border_width_bottom = border_width
		if i >= members.size():
			box.bg_color = Color(UITokens.TEXT_MUTED, 0.18)
			box.border_color = UITokens.BORDER
			continue
		var member: RefCounted = members[i]
		var fainted := bool(member.get("fainted"))
		box.bg_color = UITokens.DANGER if fainted else _distinct_tint(members, i)
		box.border_color = UITokens.TEAL_SOFT if selected else UITokens.BORDER


func _species_tint(species_id: String) -> Color:
	if species_id.is_empty():
		return UITokens.TEXT_MUTED
	var placeholder: Dictionary = CREATURE_SPECIES.placeholder(species_id)
	return Color(str(placeholder.get("colour", "#cccccc")))


## A blind critic found two of the five party pips reading as the same
## colour ("both brown") -- `CreatureSpecies.placeholder()` hands out one
## fixed colour per species (data this lane does not own, see the file
## ownership list), and nothing stopped two of a five-creature roster from
## rolling the same placeholder tint. Rather than touch creature data, this
## nudges the hue of any tint that repeats EARLIER in the same roster list,
## by a fixed step per repeat -- deterministic (same roster always renders
## the same way), and shared by both `_update_party_pips()` and
## `_update_party_strip()`'s entries below, so a duplicate is resolved once
## and both widgets agree, the same "never tint the same creature two
## different colours" guarantee `_species_tint()`'s own callers already
## relied on for a SINGLE creature.
func _distinct_tint(members: Array, index: int) -> Color:
	var base := _species_tint(str((members[index] as RefCounted).get("species_id")))
	var earlier_matches := 0
	for j in index:
		if _species_tint(str((members[j] as RefCounted).get("species_id"))).is_equal_approx(base):
			earlier_matches += 1
	if earlier_matches == 0:
		return base
	var hue := fposmod(base.h + 0.16 * earlier_matches, 1.0)
	return Color.from_hsv(hue, clampf(base.s, 0.4, 1.0), clampf(base.v, 0.45, 1.0), base.a)


## Meadows ships a curated runtime copy of the owner-supplied render for every
## installed creature. Reusing it here gives the field HUD real species
## identity without adding portrait art or coupling the strip to 3D spawning.
func _species_portrait_path(species_id: String) -> String:
	if species_id.is_empty():
		return ""
	return "res://assets/ui/portraits/creatures/%s.png" % species_id


func _type_colour(creature_type: String) -> Color:
	match creature_type:
		"ground":
			return UITokens.GROUND_OCHRE
		"water":
			return UITokens.WATER_BLUE
		"air":
			return UITokens.AIR_SKY
		_:
			return UITokens.TEXT_SECONDARY


# --- party strip -----------------------------------------------------------------


## `party_strip.gd` never reaches `Game` itself (see its own header) — this is
## the one place that reads `Game.party` and hands it entries as plain data.
func _mount_party_strip() -> void:
	var script: Script = load(PARTY_STRIP_SCRIPT)
	if script == null:
		push_warning("HUD: party_strip.gd failed to load")
		return
	var inst: Variant = script.new()
	if not (inst is Control):
		push_warning("HUD: party_strip.gd did not produce a Control")
		return
	_party_strip = inst
	_party_strip_script = script
	_party_strip.name = "PartyStrip"
	_party_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Real position comes from `_reflow_left_stack()`, once the creature
	# panel below it has a real measured height -- see that function's
	# header. `party_strip.gd::set_rest_position()` is what actually places
	# it (and is safe to call before the widget has ever been shown, which
	# is exactly when this first runs).
	_root.add_child(_party_strip)


## Pure position math for the left column (party strip / creature panel /
## vitals cluster), stacked bottom-up above `Root/BottomDock`'s real top
## edge -- see `BOTTOM_DOCK_TOP_OFFSET`'s header comment for why this has to
## be derived from the CANVAS BOTTOM rather than a fixed top offset. Static
## and side-effect-free on purpose: `_reflow_left_stack()` is the only
## caller in real play, but `tests/test_hud_widgets.gd` exercises the same
## math with hand-picked canvas heights, with no scene tree required.
static func left_stack_bottom(canvas_height: float) -> float:
	return canvas_height + BOTTOM_DOCK_TOP_OFFSET - LEFT_STACK_CLEARANCE


static func vitals_position(canvas_height: float) -> Vector2:
	return Vector2(CREATURE_BLOCK_X, left_stack_bottom(canvas_height) - VITALS_HEIGHT)


static func creature_block_position(canvas_height: float, creature_panel_height: float) -> Vector2:
	return Vector2(
		CREATURE_BLOCK_X,
		vitals_position(canvas_height).y - PARTY_ACTIVE_GAP - creature_panel_height,
	)


## Clamped to `TOP_SAFE_INSET`, not left to run negative. The party strip's
## own `TOTAL_HEIGHT` (540, five text-driven rows plus a header -- a
## deliberate legibility fix, not a number this task should shrink) does
## not actually fit in the room left ABOVE the creature panel once that
## panel is itself correctly bottom-anchored: `creature_block_position()`'s
## own gap budget above `Root/BottomDock` is under 300px at either supported
## canvas height (1080 or 1200), well short of 540+`PARTY_ACTIVE_GAP`.
##
## Two bad options, honestly, not a solved problem: the un-clamped math
## draws roughly the top third of the reveal OFF the top of the screen
## (confirmed by computing both canvas heights); this clamp instead lets the
## reveal overlap the creature panel it slides in above. The clamped case is
## the better of the two -- the strip is added to `_root` AFTER the creature
## block (`_ready()`'s build order), so it draws on top and stays fully
## readable, and the overlap is transient (`T_PARTY_FADE`/`CYCLE_BANNER_SECONDS`,
## a few seconds at most) rather than a permanent layout defect -- but it is
## a real, visible tradeoff a future pass should revisit, most likely by
## shrinking the strip's own footprint for a reveal specifically (its full
## five-row height may not need to be the reveal's height too), not by
## touching this clamp.
static func party_strip_position(canvas_height: float, creature_panel_height: float, strip_height: float) -> Vector2:
	var hugging_creature_panel: float = (
		creature_block_position(canvas_height, creature_panel_height).y - PARTY_ACTIVE_GAP - strip_height
	)
	return Vector2(CREATURE_BLOCK_X, maxf(TOP_SAFE_INSET, hugging_creature_panel))


## Places the whole left column from the CANVAS BOTTOM every time `_root`'s
## actual size is seen to change (once at startup, since `_ready()` can run
## before the viewport has settled its final stretch size, and again only if
## a real resize ever happens -- never mid-session in practice). Cheap and
## rare rather than run unconditionally every frame specifically so it never
## fights `party_strip.gd`'s own reveal/hide tween, which owns `.position`
## the rest of the time.
func _reflow_left_stack() -> void:
	var canvas_h: float = _root.size.y
	if canvas_h <= 0.0:
		return
	# The creature panel's real height can itself change (the energy bar row
	# joining/leaving, a longer name wrapping) -- gating this whole function
	# on canvas height alone would leave the party strip's REST position
	# stale the next time it revealed. `vitals_cluster`/`creature_block`
	# never animate their own `.position`, so repositioning them every frame
	# is just a couple of cheap Vector2 writes; only the party strip's tween
	# needs the change-guard below.
	# A `PanelContainer` parented directly under a plain `Control` (as this
	# one is, under `_creature_block`) does not automatically grow its own
	# `.size` to match its children's real minimum size the way it would
	# inside a parent Container -- that auto-fit only happens one layer up.
	# Setting it explicitly here, every time this runs, is what makes the
	# panel's OWN rect (what `get_global_rect()` reports, and what the
	# bounds tests in `tests/smoke_hud_handheld_legibility.gd` check every
	# child against) actually match its content instead of staying frozen at
	# whatever `custom_minimum_size` floor it started with.
	var creature_h := 0.0
	if _creature_panel != null:
		var min_size := _creature_panel.get_combined_minimum_size()
		_creature_panel.size = min_size
		creature_h = min_size.y

	if _vitals_cluster != null:
		_vitals_cluster.position = vitals_position(canvas_h)

	if _creature_block != null:
		_creature_block.position = creature_block_position(canvas_h, creature_h)

	if is_equal_approx(canvas_h, _left_stack_canvas_h) and is_equal_approx(creature_h, _left_stack_creature_h):
		return
	_left_stack_canvas_h = canvas_h
	_left_stack_creature_h = creature_h

	if _party_strip != null and _party_strip_script != null:
		var strip_h: float = float(_party_strip_script.get("TOTAL_HEIGHT"))
		var strip_pos := party_strip_position(canvas_h, creature_h, strip_h)
		if _party_strip.has_method("set_rest_position"):
			_party_strip.call("set_rest_position", strip_pos)
		else:
			_party_strip.position = strip_pos


## Wired to `Game.party.active_index()` + `.revision`: rebuild entries and
## reveal the strip only when either actually changed, per the task spec --
## polling every frame but writing only on a real change, the same discipline
## the widget's own per-row cache already uses internally.
##
## OP21-12: also decides whether this change was a genuine cycle (the active
## index landed on the slot immediately before/after where it just was, with
## wrap) and if so hands the widget a `flash_cycle()` call — this is the one
## place both the old and new index are known, since `encounter_director.gd`
## (which actually presses `combat_switch_left/right`) only ever sees the new
## state through `Party.revision`.
func _update_party_strip() -> void:
	if _party_strip == null or _party == null:
		return
	var index := int(_party.call("active_index"))
	var revision := int(_party.get("revision"))
	if index == _party_strip_last_index and revision == _party_strip_last_revision:
		return
	var previous_index := _party_strip_last_index
	var previous_label := _party_strip_last_active_label
	_party_strip_last_index = index
	_party_strip_last_revision = revision

	var members: Array = _party.call("members")
	var entries: Array = []
	for i in members.size():
		var creature: RefCounted = members[i]
		entries.append({
			"label": str(creature.call("label")),
			"level": int(creature.get("level")),
			"hp_fraction": float(creature.call("hp_fraction")),
			"tint": _distinct_tint(members, i),
			"portrait": _species_portrait_path(str(creature.get("species_id"))),
			"fainted": bool(creature.get("fainted")),
			"resting": bool(creature.get("resting")),
		})
	_party_strip.call("update_from_party", entries, index)
	_party_strip.call("show_strip")

	var total := entries.size()
	var next_label := str(entries[index].get("label", "")) if index >= 0 and index < total else ""
	_party_strip_last_active_label = next_label

	if previous_index >= 0 and previous_index != index and total > 0 \
			and not previous_label.is_empty() and not next_label.is_empty():
		var direction := 0
		if (previous_index + 1) % total == index:
			direction = 1
		elif (previous_index - 1 + total) % total == index:
			direction = -1
		if direction != 0:
			_party_strip.call("flash_cycle", direction, previous_label, next_label, index + 1, total)


# --- player vitals cluster --------------------------------------------------------


## Buff icons row, HP row (bar + right-aligned value text), satiety row (bar
## + hunger-state text). One Control holds all three so the idle-fade rule
## can fade the whole cluster with a single modulate write, matching the old
## per-bar fade this replaces.
func _build_vitals_cluster() -> void:
	_vitals_cluster = Control.new()
	_vitals_cluster.name = "VitalsCluster"
	_vitals_cluster.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Position is set by `_reflow_left_stack()`, not here -- see that
	# function's header and `BOTTOM_DOCK_TOP_OFFSET`'s comment for why a
	# fixed top-anchored offset was the actual HUD-LAYOUT defect.
	_vitals_cluster.size = Vector2(VITALS_WIDTH, VITALS_HEIGHT)
	_root.add_child(_vitals_cluster)

	_build_buff_row(_vitals_cluster)

	# hp_heart.png is a mid-tone green glyph, matching HP_GREEN by design (see
	# ASSET_LEDGER.md) -- but this cluster has no panel behind it (§16's
	# "legibility outline instead of a box" call, same as the text below), so
	# without a backing chip the icon sits directly on grass/terrain and
	# nearly disappears into it (blind-judge finding, EV9 handheld-scale
	# remainder). A small round BG_PANEL chip -- the same fill the ledger says
	# the icon was originally colour-checked against -- restores the contrast
	# without touching the owner-supplied art itself.
	var hp_icon_bg := Panel.new()
	hp_icon_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_icon_bg.position = Vector2(-30.0, 28.0)
	hp_icon_bg.size = Vector2(26.0, 26.0)
	var hp_icon_bg_box := StyleBoxFlat.new()
	hp_icon_bg_box.bg_color = UITokens.BG_PANEL
	hp_icon_bg_box.corner_radius_top_left = 13
	hp_icon_bg_box.corner_radius_top_right = 13
	hp_icon_bg_box.corner_radius_bottom_left = 13
	hp_icon_bg_box.corner_radius_bottom_right = 13
	hp_icon_bg.add_theme_stylebox_override("panel", hp_icon_bg_box)
	_vitals_cluster.add_child(hp_icon_bg)

	_hp_icon = TextureRect.new()
	_hp_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hp_icon.texture = load(ICON_HP)
	_hp_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_hp_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_hp_icon.position = Vector2(-26.0, 32.0)
	_hp_icon.size = Vector2(18.0, 18.0)
	_vitals_cluster.add_child(_hp_icon)

	_hp_bar = ProgressBar.new()
	_hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hp_bar.position = Vector2(0.0, 32.0)
	_hp_bar.size = Vector2(VITALS_WIDTH, 18.0)
	_hp_bar.show_percentage = false
	_hp_bar.min_value = 0.0
	_hp_bar.max_value = 1.0
	_hp_bar.add_theme_stylebox_override("background", UITokens.fill_box(UITokens.TRACK))
	_hp_fill = UITokens.fill_box(UITokens.HP_GREEN)
	_hp_bar.add_theme_stylebox_override("fill", _hp_fill)
	_vitals_cluster.add_child(_hp_bar)

	_hp_value_label = Label.new()
	_hp_value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hp_value_label.position = Vector2(0.0, 32.0)
	_hp_value_label.size = Vector2(VITALS_WIDTH - 8.0, 18.0)
	_hp_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hp_value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hp_value_label.add_theme_font_size_override("font_size", UITokens.FONT_LABEL)
	_vitals_cluster.add_child(_hp_value_label)

	_satiety_bar = ProgressBar.new()
	_satiety_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_satiety_bar.position = Vector2(0.0, 54.0)
	_satiety_bar.size = Vector2(VITALS_WIDTH, 10.0)
	_satiety_bar.show_percentage = false
	_satiety_bar.min_value = 0.0
	_satiety_bar.max_value = 1.0
	_satiety_bar.add_theme_stylebox_override("background", UITokens.fill_box(UITokens.TRACK))
	_satiety_bar.add_theme_stylebox_override("fill", UITokens.fill_box(UITokens.WARNING))
	_vitals_cluster.add_child(_satiety_bar)

	_satiety_state_label = Label.new()
	_satiety_state_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_satiety_state_label.position = Vector2(VITALS_WIDTH + 10.0, 51.0)
	_satiety_state_label.size = Vector2(120.0, 16.0)
	_satiety_state_label.add_theme_font_size_override("font_size", UITokens.FONT_TINY)
	_satiety_state_label.visible = false
	_vitals_cluster.add_child(_satiety_state_label)


func _build_buff_row(parent: Control) -> void:
	var x := 0.0
	for i in MAX_BUFF_CHIPS:
		var chip := Panel.new()
		chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chip.position = Vector2(x, 0.0)
		chip.size = Vector2(BUFF_CHIP_SIZE, BUFF_CHIP_SIZE)
		var box := StyleBoxFlat.new()
		box.bg_color = UITokens.SUCCESS
		box.corner_radius_top_left = UITokens.RADIUS_SLOT
		box.corner_radius_top_right = UITokens.RADIUS_SLOT
		box.corner_radius_bottom_left = UITokens.RADIUS_SLOT
		box.corner_radius_bottom_right = UITokens.RADIUS_SLOT
		chip.add_theme_stylebox_override("panel", box)
		chip.visible = false
		parent.add_child(chip)
		_buff_chips.append(chip)

		var label := Label.new()
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.size = Vector2(BUFF_CHIP_SIZE, BUFF_CHIP_SIZE)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", UITokens.FONT_TINY)
		chip.add_child(label)
		_buff_chip_labels.append(label)

		x += BUFF_CHIP_SIZE + UITokens.GAP

	_buff_overflow_label = Label.new()
	_buff_overflow_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_buff_overflow_label.position = Vector2(x, 6.0)
	_buff_overflow_label.add_theme_font_size_override("font_size", UITokens.FONT_TINY)
	_buff_overflow_label.add_theme_color_override("font_color", UITokens.TEXT_SECONDARY)
	_buff_overflow_label.visible = false
	parent.add_child(_buff_overflow_label)


func _update_buff_row(vitals: RefCounted) -> void:
	var buffs: Array = vitals.active_buffs
	var count := buffs.size()
	for i in MAX_BUFF_CHIPS:
		var show := i < count
		_buff_chips[i].visible = show
		if show:
			var buff: Dictionary = buffs[i]
			var id := str(buff.get("id", ""))
			_buff_chip_labels[i].text = id.substr(0, 1).to_upper() if id.length() > 0 else "?"
	var overflow := count - MAX_BUFF_CHIPS
	_buff_overflow_label.visible = overflow > 0
	if overflow > 0:
		_buff_overflow_label.text = "+%d" % overflow


## HP: bar + "284 / 320" value text, a brief white-ish flash on any decrease
## (`T_DAMAGE_FLASH`), and below `HP_DANGER_BELOW` a lerp toward `DANGER` plus
## a gentle alpha pulse on the bar itself (not the whole cluster -- the pulse
## should read as "this bar is alarmed", not affect the buff row above it).
## Satiety: bar + hunger-state text ("HUNGRY" / "STARVING"). Then the whole
## cluster's idle-fade, unchanged in spirit from the old per-bar version.
func _update_vitals_cluster(vitals: RefCounted, delta: float) -> void:
	var health_fraction: float = vitals.health_fraction()
	var health_value: float = vitals.health
	var max_health: float = vitals.max_health

	if _last_health_value >= 0.0 and health_value < _last_health_value - 0.001:
		_health_flash_timer = UITokens.T_DAMAGE_FLASH
	_last_health_value = health_value

	_hp_bar.value = health_fraction
	var normal_colour := UITokens.HP_GREEN.lerp(UITokens.DANGER, 1.0 - health_fraction)
	if _health_flash_timer > 0.0:
		_health_flash_timer = maxf(0.0, _health_flash_timer - delta)
		var t: float = _health_flash_timer / UITokens.T_DAMAGE_FLASH
		_hp_fill.bg_color = Color(1.0, 1.0, 1.0).lerp(normal_colour, 1.0 - t)
	else:
		_hp_fill.bg_color = normal_colour

	if health_fraction < HP_DANGER_BELOW:
		_hp_pulse_time += delta
		_hp_bar.modulate.a = 1.0 - HP_PULSE_DEPTH * absf(sin(_hp_pulse_time * HP_PULSE_SPEED))
	else:
		_hp_pulse_time = 0.0
		_hp_bar.modulate.a = 1.0

	_hp_value_label.text = "%d / %d" % [int(round(health_value)), int(round(max_health))]

	_satiety_bar.value = vitals.satiety_fraction()
	var hunger := str(vitals.call("hunger_state"))
	match hunger:
		"hungry":
			_satiety_state_label.text = "HUNGRY"
			_satiety_state_label.add_theme_color_override("font_color", UITokens.WARNING)
			_satiety_state_label.visible = true
		"critical":
			_satiety_state_label.text = "STARVING"
			_satiety_state_label.add_theme_color_override("font_color", UITokens.DANGER)
			_satiety_state_label.visible = true
		_:
			_satiety_state_label.visible = false

	_update_buff_row(vitals)

	var sprinting: bool = bool(_player.call("is_sprinting")) if _player.has_method("is_sprinting") else false
	var relevant := health_fraction < 0.999 or hunger != "ok" or sprinting
	_fade_toward(_vitals_cluster, 1.0 if relevant else FADE_ALPHA, delta)


# --- stamina arc -------------------------------------------------------------------


func _mount_stamina_arc() -> void:
	var script: Script = load(STAMINA_ARC_SCRIPT)
	if script == null:
		push_warning("HUD: stamina_arc.gd failed to load")
		return
	var inst: Variant = script.new()
	if not (inst is Control):
		push_warning("HUD: stamina_arc.gd did not produce a Control")
		return
	_stamina_arc = inst
	_stamina_arc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stamina_arc.position = STAMINA_ARC_POS
	_root.add_child(_stamina_arc)

	# Centred above the arc's own SIZE (48x160, stamina_arc.gd), so it reads
	# as the gauge's label rather than a stray badge. Fades with the arc
	# itself in _update_stamina_arc below -- the icon has nothing to say
	# once the gauge has hidden.
	# 24x24, not 18x18 -- blind-judge finding (EV9 handheld-scale remainder,
	# round 2): the bolt's zigzag notch, the one feature that reads as
	# "lightning" rather than a generic blob, softens into a rounded paddle
	# shape at 18px/315ppi. Same lever EV9's second slice already used for
	# an input-glyph legibility miss (28px->36px). Position offset shifted
	# by -half the size delta so the icon stays centred on the same anchor
	# point above the arc.
	_stamina_icon = TextureRect.new()
	_stamina_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stamina_icon.texture = load(ICON_STAMINA)
	_stamina_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_stamina_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_stamina_icon.position = STAMINA_ARC_POS + Vector2(12.0, -27.0)
	_stamina_icon.size = Vector2(24.0, 24.0)
	_stamina_icon.visible = false
	_stamina_icon.modulate.a = 0.0
	_root.add_child(_stamina_icon)


func _update_stamina_arc(vitals: RefCounted, delta: float) -> void:
	if _stamina_arc == null:
		return
	var fraction: float = vitals.stamina_fraction()
	var sprinting: bool = bool(_player.call("is_sprinting")) if _player.has_method("is_sprinting") else false
	var draining := sprinting or (_last_stamina_fraction >= 0.0 and fraction < _last_stamina_fraction - 0.0001)
	_stamina_arc.call("update_stamina", fraction, draining, delta)
	_last_stamina_fraction = fraction

	if _stamina_icon != null:
		_stamina_icon.visible = _stamina_arc.visible
		_stamina_icon.modulate.a = _stamina_arc.modulate.a


# --- minimap (mounted defensively; owned by a concurrent pass) ---------------------


func _mount_minimap() -> void:
	if not ResourceLoader.exists(MINIMAP_SCRIPT):
		push_warning("HUD: minimap.gd not found; minimap disabled for this pass")
		return
	var script: Script = load(MINIMAP_SCRIPT)
	if script == null:
		push_warning("HUD: minimap.gd failed to load; minimap disabled")
		return
	var inst: Variant = script.new()
	if not (inst is Control):
		push_warning("HUD: minimap.gd did not produce a Control; minimap disabled")
		return
	_minimap = inst
	_minimap.name = "Minimap"
	_minimap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_minimap.position = Vector2(
		1920.0 - UITokens.HUD_INSET - MINIMAP_SIZE.x, UITokens.HUD_INSET
	)
	_root.add_child(_minimap)


## Baked lazily and once: `map_baker.gd::bake_cached` is a real terrain bake
## the first time it runs (cheap after, via its own disk cache), so this waits
## for a world with `ground_height_at` to exist rather than baking in
## `_ready()` before the world scene is necessarily up -- headless-safe, same
## reasoning `tools/capture_minimap.gd` already relies on.
func _ensure_minimap_baked() -> void:
	if _minimap == null or _minimap_baked:
		return
	var world := get_tree().get_current_scene()
	if world == null or not world.has_method("ground_height_at"):
		return
	if not ResourceLoader.exists(MAP_BAKER_SCRIPT):
		return
	var baker: Script = load(MAP_BAKER_SCRIPT)
	if baker == null:
		return
	if _game == null:
		return
	var game_map: RefCounted = _game.get("map")
	if game_map == null:
		return
	var terrain: Texture2D = baker.call("bake_cached", world)
	_minimap.call("configure", game_map, terrain, 90.0)
	_minimap_baked = true


## `player.global_position` and LOOK yaw derived from `CameraRig.planar_basis()`
## rather than read off a private field. `minimap.gd` derives its separate
## travel heading from successive real positions after movement resolution.
## Both use the project convention `forward(yaw) = (sin(yaw), 0, cos(yaw))`.
## `creature_pos` is the follower creature's
## position when `encounter_director.gd` has spawned one (named "AllyCreature" in
## the world, per that file), else null.
func _update_minimap() -> void:
	if _minimap == null or not _minimap_baked or _player == null:
		return
	var world := get_tree().get_current_scene()
	var yaw := 0.0
	if world != null:
		var rig := world.get_node_or_null(^"CameraRig")
		if rig != null and rig.has_method("planar_basis"):
			var basis: Basis = rig.call("planar_basis")
			yaw = atan2(basis.z.x, basis.z.z)

	var creature_pos: Variant = null
	if world != null:
		var follower := world.get_node_or_null(^"AllyCreature")
		if follower != null and is_instance_valid(follower) and follower is Node3D:
			creature_pos = (follower as Node3D).global_position

	_minimap.call("update_view", _player.global_position, yaw, creature_pos)

	var dim := 1.0
	if world != null:
		var combat := world.get_node_or_null(^"CombatManager")
		if combat != null and combat.has_method("is_fighting") and bool(combat.call("is_fighting")):
			dim = 0.55
	_minimap.call("set_dim", dim)


# --- objective block ---------------------------------------------------------------


## Below the minimap, right-aligned to the same inset. Naked text with a
## legibility outline rather than a panel -- the spec's own call ("no giant
## quest window"), and `UITokens.make_text_legible` already gives every Label
## here the same outline the rest of the HUD relies on for contrast over open
## sky and grass.
func _build_objective_block() -> void:
	var right := 1920.0 - UITokens.HUD_INSET
	var top := UITokens.HUD_INSET + MINIMAP_SIZE.y + UITokens.GAP
	var block := Control.new()
	block.name = "ObjectiveBlock"
	block.mouse_filter = Control.MOUSE_FILTER_IGNORE
	block.position = Vector2(right - OBJECTIVE_MAX_WIDTH, top)
	block.size = Vector2(OBJECTIVE_MAX_WIDTH, OBJECTIVE_BLOCK_HEIGHT)
	_root.add_child(block)

	var eyebrow := Label.new()
	eyebrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	eyebrow.text = "M A I N   S T O R Y" # letter-spaced feel; no theme letter-spacing support
	# `UITokens.FONT_TINY` (19) measured ~7 physical px at the Ally's real
	# resolution -- same "shared by a dozen screens this lane does not own"
	# reason `HUD_READABLE_FONT_SIZE`'s own header gives for not raising that
	# shared constant; a local override here does the same job this file
	# already does for its other micro-labels.
	eyebrow.add_theme_font_size_override("font_size", HUD_READABLE_FONT_SIZE)
	eyebrow.add_theme_color_override("font_color", UITokens.TEXT_MUTED)
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	eyebrow.size = Vector2(OBJECTIVE_MAX_WIDTH, 34.0)
	block.add_child(eyebrow)
	_objective_eyebrow_label = eyebrow

	_objective_text_label = Label.new()
	_objective_text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_objective_text_label.position = Vector2(0.0, 36.0)
	_objective_text_label.size = Vector2(OBJECTIVE_MAX_WIDTH, OBJECTIVE_BLOCK_HEIGHT - 36.0)
	_objective_text_label.add_theme_font_size_override("font_size", UITokens.FONT_LABEL)
	_objective_text_label.add_theme_color_override("font_color", UITokens.TEXT_PRIMARY)
	_objective_text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_objective_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	block.add_child(_objective_text_label)


## Runs after `UITokens.make_text_legible(_root)`, which would otherwise
## overwrite a per-widget override applied earlier in `_ready()` -- see
## `_build_objective_block()`'s own comment for why this exists and why a
## backing panel is not the fix. Roughly 1.5x the shared outline both labels
## already carry, tuned as "clearly heavier," not a specific measured target
## -- unlike the font-size fixes above, no blind pass measured a physical
## contrast ratio for naked text over a variable, moving 3D background to
## check this against.
func _strengthen_objective_contrast() -> void:
	var wide_outline := int(round(UITokens.OUTLINE_SIZE * 1.5))
	for label in [_objective_eyebrow_label, _objective_text_label]:
		if label == null:
			continue
		label.add_theme_constant_override("outline_size", wide_outline)
		label.add_theme_color_override("font_outline_color", Color(UITokens.OUTLINE, 1.0))


func _update_objective() -> void:
	if _game == null:
		return
	var text := str(_game.get("objective_text"))
	if text == _objective_last_text:
		return
	_objective_last_text = text
	_objective_text_label.text = text


# --- region banner ---------------------------------------------------------------


## Top-centre, well clear of the prompt/hotbar block anchored to the bottom of
## the screen -- a Fortnite-style location card announces itself where the
## player is already looking, not down where their eyes are on the hotbar.
## Naked text, no panel, same "legibility outline instead of a box" call the
## objective block above already makes.
func _build_region_banner() -> void:
	_region_banner = Label.new()
	_region_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_region_banner.visible = false
	_region_banner.anchor_left = 0.5
	_region_banner.anchor_right = 0.5
	_region_banner.offset_left = -400.0
	_region_banner.offset_right = 400.0
	_region_banner.offset_top = 120.0
	_region_banner.offset_bottom = 168.0
	_region_banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_region_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_region_banner.add_theme_font_size_override("font_size", 40)
	_region_banner.add_theme_color_override("font_color", UITokens.TEXT_PRIMARY)
	_root.add_child(_region_banner)


## Polls `Game.map`'s one-shot queue (`take_pending_region_announcement()`)
## every frame, the same read-and-clear contract `_hotbar_message` already
## uses for its own timed banners -- a region is entered on at most one frame,
## so a plain equality check like `_update_objective()`'s would miss it the
## instant the queue is cleared by this same call.
func _update_region_banner() -> void:
	if _game == null:
		return
	var map: RefCounted = _game.get("map")
	if map == null:
		return
	var text := str(map.call("take_pending_region_announcement"))
	if not text.is_empty():
		_region_banner.text = text
		_region_banner.visible = true
		_region_banner_until = Time.get_ticks_msec() / 1000.0 + REGION_BANNER_SECONDS
	elif _region_banner_until > 0.0 and Time.get_ticks_msec() / 1000.0 >= _region_banner_until:
		_region_banner_until = 0.0
		_region_banner.visible = false


# --- frame / lifecycle ---------------------------------------------------------------


func _on_landed(impact_speed: float, damage: float) -> void:
	_peak_fall = maxf(_peak_fall, impact_speed)
	_last_damage = damage


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
		_debug_level = (_debug_level + 1) % 3
		_debug_readout.visible = _debug_level != DEBUG_OFF


## Perf readout first, always (see `_debug_text`'s header). Everything else
## polls in a fixed order: `_game` refreshed once, hotbar (functionally
## unchanged), the creature block/party strip/objective (all `Game`-sourced), the
## minimap (bake-once then update), then player-sourced vitals/stamina last,
## behind the same null-player / null-vitals guards the old HUD used --
## a capture tool or a headless smoke boot with no player still gets every
## `Game`-sourced block drawn correctly.
func _process(delta: float) -> void:
	if _debug_level != DEBUG_OFF:
		_sample_frame(delta)
		_since_readout += delta
		if _since_readout >= READOUT_INTERVAL:
			_since_readout = 0.0
			_debug_readout.text = _debug_text()

	_refresh_game_ref()
	_yield_bottom_to_build_menu()
	_update_hotbar_and_message()
	_update_world_message()
	_read_hotbar_input()
	_read_world_hotkeys()
	_update_creature_block()
	# After the creature block's content is written for this frame, not
	# before: `_reflow_left_stack()` measures the creature panel's real
	# combined-minimum-size, so it has to run once this frame's text/energy
	# bar visibility is actually in place, or it is always one frame stale.
	_reflow_left_stack()
	_update_party_strip()
	_update_objective()
	_update_region_banner()
	_update_exploration_legend()
	_ensure_minimap_baked()
	_update_minimap()
	_update_aim_fade(delta)

	if _player == null:
		return
	var vitals: RefCounted = _player.get("vitals")
	if vitals == null:
		return
	_update_vitals_cluster(vitals, delta)
	_update_stamina_arc(vitals, delta)


func _sample_frame(delta: float) -> void:
	_frame_ms[_frame_head] = delta * 1000.0
	_frame_head = (_frame_head + 1) % FRAME_WINDOW
	_frame_filled = mini(_frame_filled + 1, FRAME_WINDOW)


func _perf_lines() -> Array[String]:
	var worst := 0.0
	var best := 0.0
	var total := 0.0
	if _frame_filled > 0:
		best = _frame_ms[0]
		for i in _frame_filled:
			var ms: float = _frame_ms[i]
			total += ms
			worst = maxf(worst, ms)
			best = minf(best, ms)
	var avg: float = total / float(_frame_filled) if _frame_filled > 0 else 0.0

	var vp := get_viewport()
	var scale: float = vp.scaling_3d_scale if vp != null else 1.0
	var size: Vector2i = vp.get_visible_rect().size if vp != null else Vector2i.ZERO

	var vsync := -1
	if DisplayServer.get_name() != "headless":
		vsync = int(DisplayServer.window_get_vsync_mode())

	return [
		"perf (F3 again for movement/input, once more to hide)",
		"",
		"fps        %d      frame %.1f ms   min %.1f   max %.1f" % [
			Engine.get_frames_per_second(), avg, best, worst,
		],
		"draw calls %d      primitives %d" % [
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
		],
		"video mem  %.0f MB   textures %.0f MB" % [
			Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / MB,
			Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / MB,
		],
		"static mem %.0f MB   nodes %d" % [
			Performance.get_monitor(Performance.MEMORY_STATIC) / MB,
			int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		],
		"cpu        process %.2f ms   physics %.2f ms" % [
			Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
			Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
		],
		"3d scale   %.2f  (%d x %d)   msaa %d" % [
			scale, int(size.x * scale), int(size.y * scale),
			int(vp.msaa_3d) if vp != null else 0,
		],
		"vsync      %d      max_fps %d" % [vsync, Engine.max_fps],
		_hardware_line,
	]


func _on_prompt_changed(text: String) -> void:
	_prompt_label.text = "" if _prompt_belongs_to_combat() else text


## True when the arbiter's winning offer came from the encounter director —
## whose lines ("Engage X", "Call out Biscuit") CombatHUD renders in its own
## combat-styled row. Rendering them here too put the same sentence on
## screen twice, which a blind visual review read as a bug the moment the
## two rows stopped sitting at the same pixel. Duck-typed on
## `owns_active_prompt`, a method only the director carries.
func _prompt_belongs_to_combat() -> bool:
	if _arbiter == null or not is_instance_valid(_arbiter):
		return false
	var winner: Object = _arbiter.call("winning_provider")
	return winner != null and winner.has_method("owns_active_prompt")


## RG3's small, always-present answer to "what can I do from the field?".
## Situation-specific verbs remain exclusively in `Prompt`; this row contains
## only persistent world shortcuts. A single RichTextLabel keeps the
## relationship compact and makes device changes atomic -- there cannot be one
## stale keyboard chip beside three updated controller chips for a frame.
##
## OP21-11: mounted into `Root/BottomDock`'s VBoxContainer, not `_root`
## directly, and moved to sit right after `HotbarPanel` (index 1, ahead of
## `Prompt`) -- literally "under the hotbar," and laid out by the same
## container that already keeps the hotbar and the contextual prompt from
## overlapping (see the .tscn's own long comment on why BottomDock exists).
## `size_flags_horizontal = SHRINK_END` matches `HotbarPanel`'s own flag so
## both hug the same right-hand safe zone instead of the legend spanning the
## full authored width behind the player's back.
func _build_exploration_legend() -> void:
	var dock: VBoxContainer = $Root/BottomDock

	_exploration_legend = PanelContainer.new()
	_exploration_legend.name = "ExplorationLegend"
	_exploration_legend.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_exploration_legend.custom_minimum_size = LEGEND_SIZE
	_exploration_legend.size_flags_horizontal = Control.SIZE_SHRINK_END
	_exploration_legend.add_theme_stylebox_override("panel", UITokens.panel_box())
	dock.add_child(_exploration_legend)
	dock.move_child(_exploration_legend, 1)

	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 16)
	# No vertical margin here -- the panel style already contributes 16px top
	# and 16px bottom (see `LEGEND_SIZE`'s own comment above).
	margin.add_theme_constant_override("margin_top", 0)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 0)
	_exploration_legend.add_child(margin)

	_exploration_legend_label = RichTextLabel.new()
	_exploration_legend_label.name = "Label"
	_exploration_legend_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_exploration_legend_label.bbcode_enabled = true
	_exploration_legend_label.fit_content = false
	_exploration_legend_label.scroll_active = false
	_exploration_legend_label.shortcut_keys_enabled = false
	_exploration_legend_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_exploration_legend_label.add_theme_font_size_override("normal_font_size", LEGEND_FONT_SIZE)
	margin.add_child(_exploration_legend_label)
	UITokens.make_text_legible(_exploration_legend_label)


func _update_exploration_legend() -> void:
	if _exploration_legend == null:
		return
	var should_show := _exploration_legend_should_show()
	_exploration_legend.visible = should_show
	if not should_show:
		return
	var gamepad := INPUT_GLYPH.using_gamepad()
	var revision := int(_party.get("revision")) if _party != null else -1
	if _legend_was_drawn and gamepad == _legend_last_gamepad \
			and revision == _legend_last_party_revision:
		return
	_legend_was_drawn = true
	_legend_last_gamepad = gamepad
	_legend_last_party_revision = revision
	_exploration_legend_label.text = _exploration_legend_text()


func _exploration_legend_should_show() -> bool:
	if _combat_is_running() or _build_menu_is_open():
		return false
	if _game != null and str(_game.get("pending_build")) != "":
		return false
	if _arbiter != null and is_instance_valid(_arbiter) \
			and not bool(_arbiter.call("enabled")):
		return false
	return INPUT_OWNER.current(get_tree()) == null


func _exploration_legend_text() -> String:
	var normal := UITokens.TEXT_PRIMARY
	var change_tint := normal if _cycleable_party_count() > 1 else UITokens.TEXT_MUTED
	var entries: Array[String] = [
		_legend_entry("build_open", "Build", normal),
		_legend_entry("map", "Map", normal),
		_legend_entry("inventory", "Satchel", normal),
		"%s%s  [color=#%s]Change Creature[/color]" % [
			INPUT_GLYPH.icon("switch_left", LEGEND_GLYPH_PX, change_tint),
			INPUT_GLYPH.icon("switch_right", LEGEND_GLYPH_PX, change_tint),
			change_tint.to_html(true),
		],
		_legend_entry("torch_place", "Torch", normal),
	]
	return "     ".join(entries)


func _legend_entry(action: String, label: String, tint: Color) -> String:
	return "%s  [color=#%s]%s[/color]" % [
		INPUT_GLYPH.icon(action, LEGEND_GLYPH_PX, tint), tint.to_html(true), label,
	]


func _cycleable_party_count() -> int:
	if _party == null:
		return 0
	var count := 0
	for member: Variant in _party.call("members"):
		var creature := member as RefCounted
		if creature != null and not bool(creature.get("fainted")) \
				and not bool(creature.get("resting")):
			count += 1
	return count


## Caches the `Game` autoload lookup and the `party` RefCounted it exposes.
## Looked up by path rather than the bare autoload name so a HUD instanced
## without `Game` running (a capture tool, an isolated test scene) just shows
## nothing here instead of crashing -- same convention `sequence_director.gd`
## uses.
func _refresh_game_ref() -> void:
	if not is_instance_valid(_game):
		_game = get_node_or_null(^"/root/Game")
	if _game != null:
		_party = _game.get("party") as RefCounted


func _update_hotbar_and_message() -> void:
	if _game == null:
		return
	var inventory: RefCounted = _game.get("inventory")
	if inventory == null:
		return
	_update_hotbar(inventory)
	if _hotbar_message_until > 0.0 and Time.get_ticks_msec() / 1000.0 >= _hotbar_message_until:
		_hotbar_message_until = 0.0
		_hotbar_message.visible = false


## The hotbar draws `Game.hotbar` — five item ids the player assigned, NOT
## satchel slots 0-4.
##
## It used to mirror the satchel directly, which is why the owner found wood
## and stone occupying action slots that answered "is not something you can
## use here", and why the 2026-08-15 blind playtest (PT-11) watched a potion
## silently leave slot 2 when the backpack was rearranged. A slot now names an
## item and looks up whatever stack currently holds it, so sorting the bag,
## splitting a stack, or spending the last one and picking another up all
## leave the binding alone. A bound item the satchel has none of draws greyed
## with a zero rather than disappearing — the habit survives running out.
##
## Blind visual review: the old chip drew glyph + "Name xN" text at 13px,
## illegible at handheld distance. The backpack already owns telling the
## player an item's NAME (`tab_backpack.gd`); this chip's only job is "what
## is it, how many" at a glance, so it now draws the input glyph, the item's
## own icon art (`items.json`'s `icon` field) at 28px, and the count at 16px
## — no name text at all. Durability-bearing tools keep their `n/max` reading
## in place of a plain count, unchanged from before.
func _update_hotbar(inventory: RefCounted) -> void:
	var db: RefCounted = _game.get("items")
	if db == null:
		return
	var assignments: Array = _game.get("hotbar") as Array
	# A completely empty bar fills itself from what the player is carrying.
	# That covers a brand new game -- Grandpa hands over orbs, potions, berries
	# and revives in one conversation, and a bar that stayed blank until the
	# player found the assign verb would read as broken. The condition is
	# deliberately "ALL five empty", not "any empty": once a single slot is
	# bound the bar is the player's, and nothing rearranges it behind them.
	# That is the whole complaint PT-11 recorded against the old mirror.
	if not assignments.is_empty() and assignments.count("") == assignments.size():
		_game.call("autofill_hotbar")
		assignments = _game.get("hotbar") as Array
	for i in HOTBAR_SLOTS:
		var id := str(assignments[i]) if i < assignments.size() else ""
		# The satchel slot currently holding this item, or -1 for "assigned but
		# carrying none". Everything below reads from the LIVE slot, so a stack
		# that moved in the bag keeps drawing its real count here.
		var slot := int(inventory.call("find_slot", id)) if not id.is_empty() else -1
		var stack: Dictionary = inventory.call("stack_at", slot) if slot >= 0 else {}
		# 28 -> 36: this call used to override `icon()`'s own documented 36px
		# floor ("the smallest step that read clearly" -- see that function's
		# header) down to 28, the one glyph call on this whole HUD that did.
		# A blind critic separately flagged the hotbar numerals as visibly
		# more pixelated than the legend's -- same vendored PNGs, same
		# `icon()` call, the only difference was this smaller target size.
		var glyph := INPUT_GLYPH.icon(HOTBAR_ACTIONS[i], HOTBAR_GLYPH_PX)
		var text: String
		if id.is_empty():
			# Blank second line, not a "-" glyph: a blind critic read the old
			# dash as "a ~2px dark dot artifact" in every empty slot at
			# handheld distance -- a single punctuation character has nothing
			# to read once it is downscaled that far. An empty slot now draws
			# cleanly empty instead of a mark nobody can identify.
			text = "%s\n" % glyph
		else:
			var icon_path := str(db.call("definition", id).get("icon", ""))
			var tool_max: int = int(inventory.call("max_durability_at", slot)) if slot >= 0 else 0
			var count_text: String
			if tool_max > 0:
				count_text = "%d/%d" % [int(inventory.call("durability_at", slot)), tool_max]
			else:
				count_text = "x%d" % int(stack.get("n", 0))
			# The count text's OWN colour, not `items.json`'s `colour` field --
			# that field is a slot-tile TINT (`item_db.gd::colour()`'s own
			# header calls it exactly that), never designed to be read as
			# foreground text. A blind critic could not read "berries"'s tile
			# tint (#a33a55, dark crimson) as the "x12" count text against the
			# hotbar's dark navy panel without 4x magnification -- the one
			# number in the hotbar that actually matters. Out-of-stock still
			# greys, same as before; in-stock now reads at full contrast.
			var text_colour := Color(0.4, 0.42, 0.39) if stack.is_empty() else UITokens.TEXT_PRIMARY
			var icon_bbcode := "[img=28x28]%s[/img]" % icon_path if not icon_path.is_empty() else ""
			# 16 -> 34: 16 authored ~= 7 physical px at the Ally's real
			# resolution, the smallest text on the whole HUD and, per the
			# blind critic, illegible without magnification.
			text = "%s\n%s [font_size=%d][color=#%s]%s[/color][/font_size]" % [
				glyph, icon_bbcode, HOTBAR_COUNT_FONT_SIZE, text_colour.to_html(false), count_text
			]
		if text != _hotbar_last_text[i]:
			_hotbar_last_text[i] = text
			_hotbar_slots[i].text = text


func _read_hotbar_input() -> void:
	if _game == null:
		return
	# OW10: one gate, shared with `_read_world_hotkeys`. This poll used to carry
	# its own two-thirds of the answer (a fight, the arbiter's modal flag) and
	# not the third -- `_build_menu_is_open()` was written onto the world-hotkey
	# poll alone -- which is exactly why the hotbar leaked under an open build
	# menu and the hammer did not.
	if not _world_input_allowed():
		return
	for i in HOTBAR_SLOTS:
		if Input.is_action_just_pressed(HOTBAR_ACTIONS[i]):
			_use_hotbar_slot(i)
			return


## The same defensive CombatManager lookup the minimap dim uses; false when
## no world or no manager is reachable, so menus and tests are unaffected.
func _combat_is_running() -> bool:
	var world := get_tree().get_current_scene()
	if world == null:
		return false
	var combat := world.get_node_or_null(^"CombatManager")
	return combat != null and combat.has_method("is_fighting") and bool(combat.call("is_fighting"))


## Same defensive lookup, one method further: is that fight currently AIMING
## a throw. Split from `_combat_is_running()` rather than folded into it —
## the aim fade (spec §10.1) only wants the narrower condition, and every
## other `_combat_is_running()` call site (the hotbar gate) has no reason to
## also ask about aiming.
func _combat_is_aiming() -> bool:
	var world := get_tree().get_current_scene()
	if world == null:
		return false
	var combat := world.get_node_or_null(^"CombatManager")
	return combat != null and combat.has_method("is_aiming") and bool(combat.call("is_aiming"))


func _use_hotbar_slot(slot_index: int) -> void:
	var inventory: RefCounted = _game.get("inventory")
	var db: RefCounted = _game.get("items")
	if inventory == null or db == null:
		return

	# `slot_index` is a position on the BAR; the id it names is the thing being
	# used, and its satchel slot is looked up fresh every press.
	var assignments: Array = _game.get("hotbar") as Array
	var id := str(assignments[slot_index]) if slot_index < assignments.size() else ""
	if id.is_empty():
		_show_hotbar_message("Nothing on that slot yet — assign one from the backpack.")
		return
	var index := int(inventory.call("find_slot", id))
	if index < 0:
		_show_hotbar_message("Out of %s." % str(db.call("item_name", id)))
		return
	var stack: Dictionary = inventory.call("stack_at", index)
	if stack.is_empty():
		return

	# Owner directive: "press slot, tool in hand". A tool slot EQUIPS now --
	# pressing it again puts the tool away, so one button is both draw and
	# stow. Repair moved to the backpack's own Use verb (`tab_backpack.gd`),
	# which is where it always belonged: free repair was the only thing a tool
	# press did before this, and it is why the owner could carry an axe for a
	# whole session without ever seeing one.
	if str(db.call("kind", id)) == "tool":
		var item_name := str(db.call("item_name", id))
		if str(_game.get("equipped_tool")) == id:
			_game.set("equipped_tool", "")
			_show_hotbar_message("Put the %s away." % item_name.to_lower())
			return
		# A tool worn down to nothing still equips -- it just gathers like bare
		# hands until repaired, which `harvest_logic.gd` already decides. Saying
		# so here beats letting the player wonder why the swing yields less.
		var maximum := int(inventory.call("max_durability_at", index))
		var current := int(inventory.call("durability_at", index))
		_game.set("equipped_tool", id)
		if maximum > 0 and current <= 0:
			_show_hotbar_message("%s in hand — but it's blunt. Repair it at the bench." % item_name)
		else:
			_show_hotbar_message("%s in hand." % item_name)
		return

	# D40 (OF32): `heal` (potions) and `revive` (Revives) are mutually
	# exclusive fields on an item's definition -- a potion tops up the
	# living, a Revive raises the fallen, and never the same item both ways.
	var definition := db.call("definition", id) as Dictionary
	var heal := float(definition.get("heal", 0.0))
	var revive_fraction := float(definition.get("revive", 0.0))

	# Food. The backpack could always eat berries (`tab_backpack.gd`'s Use verb
	# reads `satiety` the same way) and the hotbar could not -- pressing them
	# here answered "Berries is not something you can use here", which is the
	# kind of inconsistency that teaches a player the bar is unreliable. Same
	# call, same buff dictionary, so one food item cannot behave two ways
	# depending on which screen reached it.
	var satiety := float(definition.get("satiety", 0.0))
	if satiety > 0.0:
		var vitals := _game.call("player_vitals") as RefCounted
		if vitals == null:
			_show_hotbar_message("Nothing to eat that here.")
			return
		vitals.call("eat", satiety, definition.get("buff", {}))
		inventory.call("remove", id, 1)
		_show_hotbar_message("Ate %s." % str(db.call("item_name", id)))
		return

	# A tonic from the bar goes to the first standing party member -- the
	# creature the recall button would send out, which is who a player buffing
	# from the field means. The backpack's target picker stays the way to
	# choose somebody else.
	var tonic := definition.get("creature_buff", {}) as Dictionary
	if not tonic.is_empty():
		if _party == null or int(_party.call("size")) == 0:
			_show_hotbar_message("Nobody on the belt yet.")
			return
		var drinker: RefCounted = null
		for i in int(_party.call("size")):
			var member: RefCounted = _party.call("at", i)
			if member != null and not bool(member.get("fainted")):
				drinker = member
				break
		if drinker == null:
			_show_hotbar_message("Nobody standing to drink it.")
			return
		if not bool(drinker.call("apply_buff",
				str(tonic.get("id", id)), str(tonic.get("stat", "")),
				float(tonic.get("scale", 0.0)), float(tonic.get("duration_s", 0.0)))):
			_show_hotbar_message("That tonic isn't mixed right.")
			return
		inventory.call("remove", id, 1)
		_show_hotbar_message("%s drank the %s." % [
			str(drinker.call("label")), str(db.call("item_name", id))
		])
		return

	if heal <= 0.0 and revive_fraction <= 0.0:
		_show_hotbar_message("%s is not something you can use here." % str(db.call("item_name", id)))
		return

	if _party == null or int(_party.call("size")) == 0:
		_show_hotbar_message("Nobody on the belt yet.")
		return

	if revive_fraction > 0.0:
		# Auto-targets the first fainted party member -- there is no "worst"
		# among the fallen the way there is a most-hurt among the living, so
		# party order (the same order the belt/strip already shows) is the
		# tiebreak.
		var revive_target: RefCounted = null
		for i in int(_party.call("size")):
			var creature: RefCounted = _party.call("at", i)
			if creature != null and bool(creature.get("fainted")):
				revive_target = creature
				break

		if revive_target == null:
			_show_hotbar_message("Nobody needs reviving.")
			return

		revive_target.call("revive", revive_fraction)
		inventory.call("remove", id, 1)
		_show_hotbar_message("%s is back on its feet." % str(revive_target.call("label")))
		return

	var heal_target: RefCounted = null
	var worst_deficit := 0.0
	for i in int(_party.call("size")):
		var creature: RefCounted = _party.call("at", i)
		# A fainted creature is skipped, not targeted -- `heal()` now refuses
		# it anyway (D40), and a potion auto-aimed at the one creature it
		# cannot help would read as broken.
		if creature == null or bool(creature.get("fainted")):
			continue
		var deficit: float = float(creature.get("max_hp")) - float(creature.get("hp"))
		if deficit > worst_deficit:
			worst_deficit = deficit
			heal_target = creature

	if heal_target == null:
		_show_hotbar_message("Everybody's already at full health.")
		return

	var restored := float(heal_target.call("heal", heal))
	inventory.call("remove", id, 1)
	_show_hotbar_message("%s recovers %d." % [str(heal_target.call("label")), int(restored)])


## OF24 originally gave `build_open` (gamepad Start / keyboard B, opens the
## build menu without a trip through the pause menu's Build tab first) and
## `torch_place` (RT / keyboard P) the same job: read straight from the
## world and hand off to `build_menu.gd::_pick`'s own arming, `torch_place`
## planting a free ground torch directly. OW12 retired that ground torch
## (data/items/buildables.json), so `torch_place` now does the OTHER thing
## the owner asked for -- a fast draw/stow for the carried torch tool without
## hunting the hotbar for whichever slot it landed on (`_arm_torch_placement`
## below, despite the name it kept). Gated the same way `_read_hotbar_input`
## gates the hotbar: silent during a fight, and (new here) silent while the
## interaction arbiter is asleep -- a conversation, a naming prompt or a fade
## owns the screen exactly when that flag goes false
## (`sequence_director.gd::_refresh_lockout`), and a hammer opening over a
## dialogue box is the same class of bug OF23 fixed for a refused build pick.
## Neither reads while the build menu is already open -- `build_open` because
## a second press should not fight the first one's `open()`, `torch_place`
## because equipping UNDER an open menu makes no sense to the player either.
func _read_world_hotkeys() -> void:
	if Input.is_action_just_pressed(&"build_open"):
		# BUILD-FLOW promises that Start reopens the dedicated catalogue to
		# change pieces while a ghost remains armed. SequenceDirector correctly
		# disables InteractionArbiter during placement so X cannot both place and
		# talk/harvest, but the shared world-input gate treated that build-owned
		# lockout as a story modal and swallowed Start too. Allow only this one
		# catalogue action through when pending_build is the reason; combat and
		# an actual open input-owning panel still refuse it below.
		if not _world_input_allowed(true):
			return
		BUILD_MENU.get_or_make(get_tree()).call_deferred("open")
		return
	if not _world_input_allowed():
		return
	if Input.is_action_just_pressed(&"torch_place"):
		_arm_torch_placement()
		return
	# Swing whatever is in hand. Read here rather than in the player controller
	# so it inherits this function's gating for free: silent during a fight,
	# during a conversation, and while a build ghost is armed -- the three
	# states where the trainer does not have free run of the world.
	if Input.is_action_just_pressed(&"use_tool"):
		_swing_equipped_tool()


## Does the trainer have free run of the world this frame?
##
## OW10: the ONE answer both world-verb polls ask -- the hotbar
## (`_read_hotbar_input`) and the hammer/torch/tool hotkeys
## (`_read_world_hotkeys`). It used to be two functions with two different
## ideas of the answer: this one, and an inline pair inside the hotbar poll.
## They agreed about a fight and about the arbiter and disagreed about the
## build menu, which is the whole of the owner's report -- a d-pad press with
## the build menu open moved the grid selection AND spent a potion, because
## `hotbar_2`/`3`/`4` are bound to d-pad left/right/down (project.godot,
## joypad 13/14/12) and that menu deliberately does not pause the tree.
##
## Three things can hold input, and they are asked in cost order:
##
##   - a fight (HD2: `hotbar_2`/`3` share the d-pad with
##     `combat_switch_left`/`right` per D32, so without this a mid-fight
##     creature switch also quietly ate a potion)
##   - the interaction arbiter being asleep, which is a conversation, a naming
##     prompt or a fade (`sequence_director.gd::_refresh_lockout`) -- reused
##     rather than re-derived, and the reason OF25 stopped a digit typed into a
##     name from spending a satchel slot
##   - any panel that has claimed input via `input_owner.gd`'s group, which is
##     how a non-pausing panel says so without anything here naming it
##
## A tree-pausing panel needs no entry: `PlaygroundHUD` is `PAUSABLE`, so it is
## already not running. No arbiter reachable (a stripped-down test or capture
## scene) reads as permissive, the same null-safe default `_combat_is_running()`
## already uses -- nothing there to be modal ABOUT.
func _world_input_allowed(allow_armed_build: bool = false) -> bool:
	if _combat_is_running():
		return false
	if _arbiter != null and is_instance_valid(_arbiter) and not bool(_arbiter.call("enabled")):
		var armed_build := allow_armed_build and _game != null \
				and str(_game.get("pending_build")) != ""
		if not armed_build:
			return false
	if INPUT_OWNER.current(get_tree()) != null:
		return false
	return true


## OW11: the build selector docks along the bottom of the screen, over the
## ground the hotbar block stands on, the same way Valheim's build bar takes
## the hotbar's place while you are building. So the hotbar and the context
## prompt stand down while it is open.
##
## This is a visibility swap, not a nudge. `build_menu.gd` is its own
## CanvasLayer and cannot see these rects (nor they its), so leaving both drawn
## does not produce two panels sharing a space — it produces the hotbar's slot
## chips reading THROUGH the selector's semi-transparent background, which is
## what the first captured frame of the docked menu showed: five numbered
## squares scattered along the thumbnail row like missing art.
##
## The hotbar is already inert while the selector is open, so nothing readable
## is being taken away — only the drawing of it.
func _yield_bottom_to_build_menu() -> void:
	var building := _build_menu_is_open()
	if _hotbar_panel != null:
		_hotbar_panel.visible = not building
	if _prompt_label != null:
		_prompt_label.visible = not building


func _build_menu_is_open() -> bool:
	for node: Node in get_tree().get_nodes_in_group(BUILD_MENU.GROUP):
		if node.has_method("is_open") and bool(node.call("is_open")):
			return true
	return false


## Swing the equipped tool at whatever is in front of the trainer.
##
## The refusal is deliberately spoken rather than silent. The 2026-08-15 blind
## playtest (PT-08) recorded the opposite pattern for the combat buttons --
## "silently inert outside an encounter... nothing teaches the player that
## these buttons need an encounter, so they read as broken" -- and an empty
## hand pressing swing is exactly that shape of mistake.
func _swing_equipped_tool() -> void:
	if _game == null:
		return
	var player := _game.call("find_player") as Node3D
	var hold: Node3D = player.get("tool_hold") if player != null else null
	if hold == null:
		return
	if str(_game.get("equipped_tool")).is_empty():
		_show_hotbar_message("Nothing in hand — press a tool on the bar first.")
		return
	hold.call("swing")


## OW12: the torch is a satchel item now (items.json's `torch`, `kind:
## "tool"`), equipped exactly the way `_use_hotbar_slot()` equips any other
## tool -- toggle off if it is already in hand, otherwise on. This function
## kept its old name and its old input (RT / keyboard P) rather than gaining
## a new hotkey action, since the button's whole point (a fast reach for the
## torch without hunting the hotbar) survives the swap from "arm a ground
## placement" to "equip the carried one" unchanged.
func _arm_torch_placement() -> void:
	if _game == null:
		return
	var inventory: RefCounted = _game.get("inventory")
	if inventory == null or int(inventory.call("find_slot", "torch")) < 0:
		AUDIO_CUES.play(&"ui_error")
		_show_hotbar_message("No torch in the satchel.")
		return
	if str(_game.get("equipped_tool")) == "torch":
		_game.set("equipped_tool", "")
		AUDIO_CUES.play(&"ui_accept")
		_show_hotbar_message("Put the torch away.")
		return
	_game.set("equipped_tool", "torch")
	AUDIO_CUES.play(&"ui_accept")
	_show_hotbar_message("Torch in hand.")


## OF20. Polls `Game`'s one-shot toast queue (`take_pending_world_message()`)
## every frame -- the same read-and-clear contract `_update_region_banner()`
## already polls `map` through -- and surfaces it through the same message
## strip a hotbar-triggered refusal (repair, heal) already uses, rather than
## inventing a second banner for what is the same kind of event.
func _update_world_message() -> void:
	if _game == null:
		return
	var text := str(_game.call("take_pending_world_message"))
	if not text.is_empty():
		_show_hotbar_message(text)


func _show_hotbar_message(text: String) -> void:
	_hotbar_message.text = text
	_hotbar_message.visible = true
	_hotbar_message_until = Time.get_ticks_msec() / 1000.0 + HOTBAR_MESSAGE_SECONDS


func _fade_toward(control: Control, target: float, delta: float) -> void:
	var current: float = control.modulate.a
	var next: float = move_toward(current, target, FADE_SPEED * delta)
	control.modulate.a = next


## Fades this whole HUD toward `AIM_FADE_ALPHA` while a throw is being
## aimed, and back to fully opaque the moment it is not — `_root`, not any
## one block, so the creature block/vitals/hotbar/minimap dim together rather
## than each needing their own aim check layered onto their own idle-fade.
func _update_aim_fade(delta: float) -> void:
	var target := AIM_FADE_ALPHA if _combat_is_aiming() else 1.0
	_root.modulate.a = move_toward(_root.modulate.a, target, AIM_FADE_SPEED * delta)


func _debug_text() -> String:
	var lines: Array[String] = _perf_lines()
	if _debug_level != DEBUG_FULL:
		return "\n".join(lines)

	if _player != null:
		var speed: float = _player.call("ground_speed")
		var sprinting: bool = _player.call("is_sprinting")
		var pos: Vector3 = _player.global_position
		lines.append_array([
			"",
			"--- movement ---",
			"speed      %.2f m/s%s" % [speed, "   SPRINT" if sprinting else ""],
			"vertical   %+.2f m/s" % _player.velocity.y,
			"grounded   %s" % ("yes" if _player.is_on_floor() else "NO"),
			"position   %.0f, %.0f, %.0f" % [pos.x, pos.y, pos.z],
		])
		var vitals: RefCounted = _player.get("vitals")
		if vitals != null:
			lines.append_array([
				"stamina    %.0f / %.0f" % [vitals.stamina, vitals.max_stamina],
				"health     %.0f / %.0f" % [vitals.health, vitals.max_health],
				"worst landing  %.1f m/s  (%.0f damage)" % [_peak_fall, _last_damage],
			])
	lines.append_array(_input_diagnostics())
	return "\n".join(lines)


func _input_diagnostics() -> Array[String]:
	var lines: Array[String] = ["", "--- input ---"]

	var pads := Input.get_connected_joypads()
	if pads.is_empty():
		lines.append("controller  NONE DETECTED BY GODOT")
		lines.append("  the handheld is probably in desktop/mouse mode,")
		lines.append("  or the window does not have focus")
		_pad_connected_for = 0.0
		_max_raw_axis_seen = 0.0
	else:
		for device_id in pads:
			lines.append("controller  %d: %s" % [device_id, Input.get_joy_name(device_id)])
			if not Input.is_joy_known(device_id):
				lines.append("  NOT a standard mapping: buttons/axes may be wrong")

	var move := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var look := Input.get_vector("look_left", "look_right", "look_up", "look_down")
	lines.append("move  %+.2f %+.2f     look  %+.2f %+.2f" % [move.x, move.y, look.x, look.y])

	if not pads.is_empty():
		var device: int = pads[0]
		var lx: float = Input.get_joy_axis(device, JOY_AXIS_LEFT_X)
		var ly: float = Input.get_joy_axis(device, JOY_AXIS_LEFT_Y)
		var rx: float = Input.get_joy_axis(device, JOY_AXIS_RIGHT_X)
		var ry: float = Input.get_joy_axis(device, JOY_AXIS_RIGHT_Y)
		lines.append("raw axes  L %+.2f %+.2f   R %+.2f %+.2f" % [lx, ly, rx, ry])

		_max_raw_axis_seen = maxf(_max_raw_axis_seen, maxf(
			maxf(absf(lx), absf(ly)), maxf(absf(rx), absf(ry))))
		_pad_connected_for += READOUT_INTERVAL

		if _pad_connected_for >= STUCK_AXES_HINT_AFTER and _max_raw_axis_seen < STUCK_AXES_EPSILON:
			lines.append("  raw axes have not moved at all since the pad was seen.")
			lines.append("  On ROG Ally: Command Center -> Gamepad Mode (not Desktop")
			lines.append("  Mode) — desktop mode sends the sticks to Windows as a")
			lines.append("  mouse, not to the game as a controller.")

	lines.append("jump %s  sprint %s  interact %s" % [
		_held("jump"), _held("sprint"), _held("interact")
	])
	lines.append("")
	lines.append("pad: left stick move, right stick look, A jump, L3 sprint")
	lines.append("keyboard: WASD move, mouse look, Space jump, Shift sprint")
	return lines


func _held(action: String) -> String:
	return "[X]" if Input.is_action_pressed(action) else "[ ]"
