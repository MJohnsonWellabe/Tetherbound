extends CanvasLayer

## The real exploration HUD — the owner's Palworld-inspired layout
## (`ENVIRONMENT_AND_UI_BIBLE.md` §6/§6.6). This is the M-C integration pass:
## it mounts `party_strip.gd` and `stamina_arc.gd` (built and unit-tested
## standalone, `tests/test_hud_widgets.gd`) and `minimap.gd`/`map_baker.gd`
## (owned by a concurrent pass; mounted defensively, never edited here), and
## builds the rest of the layout — the active-pal block, the player vitals
## cluster, and the objective line — directly in code with `UITokens`
## factories.
##
## STRUCTURE VS DATA. The .tscn keeps only what genuinely wants to be
## hand-authored scene state: `Root` (and its load-bearing mouse_filter,
## see the .tscn's own comment), `HotbarPanel`, `Prompt` and `DebugReadout`.
## Everything the Palworld layout adds — the pal block, the vitals cluster,
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

const READOUT_INTERVAL := 0.1

## F3 cycles OFF -> PERF -> FULL rather than toggling.
const DEBUG_OFF := 0
const DEBUG_PERF := 1
const DEBUG_FULL := 2

## ~2 seconds of frames at 60 Hz.
const FRAME_WINDOW := 120

const MB := 1048576.0

const PAL_SPECIES := preload("res://scripts/pals/pal_species.gd")
const INPUT_GLYPH := preload("res://scripts/ui/input_glyph.gd")

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

const HOTBAR_MESSAGE_SECONDS := 2.2

## --- layout (spec §6/§6.6, numbers inlined per the task) --------------------
## All positions are in the HUD's own 1920x1080 authoring space (top-left
## origin), matching the rest of this file's "sized for the Ally" convention.

const PAL_BLOCK_POS := Vector2(56.0, 830.0)
const PAL_BLOCK_SIZE := Vector2(374.0, 110.0) ## x 56-430, y 830-940

const VITALS_POS := Vector2(56.0, 946.0) ## buff row starts here; satiety row ends ~1010
const VITALS_WIDTH := 300.0

const STAMINA_ARC_POS := Vector2(960.0 + 48.0, 540.0 - 160.0 * 0.5) ## centred-right of screen centre

const MINIMAP_SIZE := Vector2(240.0, 240.0)

const OBJECTIVE_MAX_WIDTH := 420.0
const OBJECTIVE_BLOCK_HEIGHT := 90.0

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
@onready var _prompt_label: RichTextLabel = $Root/Prompt
@onready var _debug_readout: Label = $Root/DebugReadout
@onready var _hotbar_chips: Array[PanelContainer] = [
	$Root/HotbarPanel/Margin/Layout/Slots/Slot1,
	$Root/HotbarPanel/Margin/Layout/Slots/Slot2,
	$Root/HotbarPanel/Margin/Layout/Slots/Slot3,
	$Root/HotbarPanel/Margin/Layout/Slots/Slot4,
	$Root/HotbarPanel/Margin/Layout/Slots/Slot5,
]
@onready var _hotbar_slots: Array[RichTextLabel] = [
	$Root/HotbarPanel/Margin/Layout/Slots/Slot1/Label,
	$Root/HotbarPanel/Margin/Layout/Slots/Slot2/Label,
	$Root/HotbarPanel/Margin/Layout/Slots/Slot3/Label,
	$Root/HotbarPanel/Margin/Layout/Slots/Slot4/Label,
	$Root/HotbarPanel/Margin/Layout/Slots/Slot5/Label,
]
@onready var _hotbar_message: Label = $Root/HotbarPanel/Margin/Layout/Message

var _hotbar_last_text: Array[String] = ["", "", "", "", ""]
var _hotbar_message_until := 0.0

## --- active-pal block --------------------------------------------------------

var _pal_block: Control = null
var _pal_content: Control = null
var _pal_chip: ColorRect = null
var _pal_name_label: Label = null
var _pal_level_label: Label = null
var _pal_type_label: Label = null
var _pal_hp_bar: ProgressBar = null
var _pal_hp_fill: StyleBoxFlat = null
var _pal_energy_bar: ProgressBar = null
var _pal_energy_fill: StyleBoxFlat = null
var _pal_no_pal_label: Label = null
var _pal_block_has_pal_last := true ## forces the first _update_pal_block to write

## --- party strip --------------------------------------------------------------

var _party_strip: Control = null
var _party_strip_last_index := -999
var _party_strip_last_revision := -999

## --- player vitals cluster ----------------------------------------------------

var _vitals_cluster: Control = null
var _buff_chips: Array[Panel] = []
var _buff_chip_labels: Array[Label] = []
var _buff_overflow_label: Label = null
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
var _last_stamina_fraction := -1.0

## --- minimap (owned by a concurrent pass; mounted defensively) ----------------

var _minimap: Control = null
var _minimap_baked := false

## --- objective block ------------------------------------------------------------

var _objective_text_label: Label = null
var _objective_last_text := ""


func _ready() -> void:
	_player = get_node_or_null(player_path) as CharacterBody3D
	if _player == null:
		push_warning("HUD has no player; readout will stay empty")
	elif _player.has_signal("landed"):
		_player.connect("landed", _on_landed)

	_arbiter = get_node_or_null(arbiter_path)
	if _arbiter != null and _arbiter.has_signal("prompt_changed"):
		_arbiter.connect("prompt_changed", _on_prompt_changed)

	_build_pal_block()
	_mount_party_strip()
	_build_vitals_cluster()
	_mount_stamina_arc()
	_mount_minimap()
	_build_objective_block()
	_style_hotbar()

	UITokens.make_text_legible(_prompt_label)
	UITokens.make_text_legible(_hotbar_message)
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
	_prompt_label.text = str(_arbiter.call("prompt")) if _arbiter != null else ""

	# Structure is finished: outline/shadow every Label and RichTextLabel this
	# file just built, in one pass, rather than one make_text_legible call per
	# widget scattered through the builders above.
	UITokens.make_text_legible(_root)


func _style_hotbar() -> void:
	$Root/HotbarPanel.add_theme_stylebox_override("panel", UITokens.panel_box())
	for chip in _hotbar_chips:
		chip.add_theme_stylebox_override("panel", UITokens.slot_box(false))


# --- active-pal block ----------------------------------------------------------


## Portrait chip, label()/level, HP bar, an energy strip shown only while
## there IS energy to show, and a type tag — or, with no active pal, a dim
## "No pal out" chip. Species tint comes from `PalSpecies.placeholder()`, the
## same lookup `party_strip.gd`'s caller (this file, below) uses, so the two
## widgets can never tint the same pal two different colours.
func _build_pal_block() -> void:
	_pal_block = Control.new()
	_pal_block.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pal_block.position = PAL_BLOCK_POS
	_pal_block.size = PAL_BLOCK_SIZE
	_root.add_child(_pal_block)

	_pal_content = Control.new()
	_pal_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pal_content.size = PAL_BLOCK_SIZE
	_pal_block.add_child(_pal_content)

	_pal_chip = ColorRect.new()
	_pal_chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pal_chip.position = Vector2(0.0, 4.0)
	_pal_chip.size = Vector2(40.0, 40.0)
	_pal_content.add_child(_pal_chip)

	_pal_name_label = Label.new()
	_pal_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pal_name_label.position = Vector2(52.0, -2.0)
	_pal_name_label.size = Vector2(280.0, 32.0)
	_pal_name_label.add_theme_font_size_override("font_size", UITokens.FONT_BODY)
	_pal_content.add_child(_pal_name_label)

	_pal_level_label = Label.new()
	_pal_level_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pal_level_label.position = Vector2(52.0, 30.0)
	_pal_level_label.add_theme_font_size_override("font_size", UITokens.FONT_TINY)
	_pal_level_label.add_theme_color_override("font_color", UITokens.TEXT_SECONDARY)
	_pal_content.add_child(_pal_level_label)

	_pal_type_label = Label.new()
	_pal_type_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pal_type_label.position = Vector2(170.0, 30.0)
	_pal_type_label.add_theme_font_size_override("font_size", UITokens.FONT_TINY)
	_pal_content.add_child(_pal_type_label)

	_pal_hp_bar = ProgressBar.new()
	_pal_hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pal_hp_bar.position = Vector2(0.0, 54.0)
	_pal_hp_bar.size = Vector2(240.0, 14.0)
	_pal_hp_bar.show_percentage = false
	_pal_hp_bar.min_value = 0.0
	_pal_hp_bar.max_value = 1.0
	_pal_hp_bar.add_theme_stylebox_override("background", UITokens.fill_box(UITokens.TRACK))
	_pal_hp_fill = UITokens.fill_box(UITokens.HP_GREEN)
	_pal_hp_bar.add_theme_stylebox_override("fill", _pal_hp_fill)
	_pal_content.add_child(_pal_hp_bar)

	_pal_energy_bar = ProgressBar.new()
	_pal_energy_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pal_energy_bar.position = Vector2(0.0, 72.0)
	_pal_energy_bar.size = Vector2(240.0, 6.0)
	_pal_energy_bar.show_percentage = false
	_pal_energy_bar.min_value = 0.0
	_pal_energy_bar.max_value = 1.0
	_pal_energy_bar.add_theme_stylebox_override("background", UITokens.fill_box(UITokens.TRACK))
	_pal_energy_fill = UITokens.fill_box(UITokens.TEAL)
	_pal_energy_bar.add_theme_stylebox_override("fill", _pal_energy_fill)
	_pal_content.add_child(_pal_energy_bar)

	_pal_no_pal_label = Label.new()
	_pal_no_pal_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pal_no_pal_label.position = Vector2(0.0, 40.0)
	_pal_no_pal_label.text = "No pal out"
	_pal_no_pal_label.add_theme_font_size_override("font_size", UITokens.FONT_LABEL)
	_pal_no_pal_label.add_theme_color_override("font_color", UITokens.TEXT_MUTED)
	_pal_no_pal_label.visible = false
	_pal_block.add_child(_pal_no_pal_label)


func _update_pal_block() -> void:
	var pal: RefCounted = null
	if _party != null and int(_party.call("size")) > 0:
		pal = _party.call("active")
	var has_pal := pal != null

	if has_pal != _pal_block_has_pal_last:
		_pal_content.visible = has_pal
		_pal_no_pal_label.visible = not has_pal
		_pal_block_has_pal_last = has_pal

	if not has_pal:
		return

	var species_id := str(pal.get("species_id"))
	_pal_chip.color = _species_tint(species_id)
	_pal_name_label.text = str(pal.call("label"))
	_pal_level_label.text = "Lv %d" % int(pal.get("level"))

	var pal_type := str(pal.get("pal_type"))
	_pal_type_label.text = pal_type.to_upper()
	_pal_type_label.add_theme_color_override("font_color", _type_colour(pal_type))

	_pal_hp_bar.value = clampf(float(pal.call("hp_fraction")), 0.0, 1.0)

	var energy := float(pal.get("energy"))
	_pal_energy_bar.visible = energy > 0.0
	if _pal_energy_bar.visible:
		_pal_energy_bar.value = clampf(float(pal.call("energy_fraction")), 0.0, 1.0)


func _species_tint(species_id: String) -> Color:
	if species_id.is_empty():
		return UITokens.TEXT_MUTED
	var placeholder: Dictionary = PAL_SPECIES.placeholder(species_id)
	return Color(str(placeholder.get("colour", "#cccccc")))


func _type_colour(pal_type: String) -> Color:
	match pal_type:
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
	_party_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Positioned to slide in ABOVE the active-pal block, sharing its left
	# edge -- SLOTS/ROW_SIZE/ROW_SEPARATION are the widget's own consts, read
	# rather than duplicated, so this position can never drift out of step
	# with what party_strip.gd actually draws.
	var height: float = (
		float(script.SLOTS) * script.ROW_SIZE.y
		+ float(script.SLOTS - 1) * script.ROW_SEPARATION
	)
	_party_strip.position = Vector2(PAL_BLOCK_POS.x, PAL_BLOCK_POS.y - height - UITokens.GAP)
	_root.add_child(_party_strip)


## Wired to `Game.party.active_index()` + `.revision`: rebuild entries and
## reveal the strip only when either actually changed, per the task spec --
## polling every frame but writing only on a real change, the same discipline
## the widget's own per-row cache already uses internally.
func _update_party_strip() -> void:
	if _party_strip == null or _party == null:
		return
	var index := int(_party.call("active_index"))
	var revision := int(_party.get("revision"))
	if index == _party_strip_last_index and revision == _party_strip_last_revision:
		return
	_party_strip_last_index = index
	_party_strip_last_revision = revision

	var entries: Array = []
	for pal: RefCounted in _party.call("members"):
		entries.append({
			"label": str(pal.call("label")),
			"level": int(pal.get("level")),
			"hp_fraction": float(pal.call("hp_fraction")),
			"tint": _species_tint(str(pal.get("species_id"))),
			"fainted": bool(pal.get("fainted")),
		})
	_party_strip.call("update_from_party", entries, index)
	_party_strip.call("show_strip")


# --- player vitals cluster --------------------------------------------------------


## Buff icons row, HP row (bar + right-aligned value text), satiety row (bar
## + hunger-state text). One Control holds all three so the idle-fade rule
## can fade the whole cluster with a single modulate write, matching the old
## per-bar fade this replaces.
func _build_vitals_cluster() -> void:
	_vitals_cluster = Control.new()
	_vitals_cluster.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vitals_cluster.position = VITALS_POS
	_vitals_cluster.size = Vector2(VITALS_WIDTH, 64.0)
	_root.add_child(_vitals_cluster)

	_build_buff_row(_vitals_cluster)

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


func _update_stamina_arc(vitals: RefCounted, delta: float) -> void:
	if _stamina_arc == null:
		return
	var fraction: float = vitals.stamina_fraction()
	var sprinting: bool = bool(_player.call("is_sprinting")) if _player.has_method("is_sprinting") else false
	var draining := sprinting or (_last_stamina_fraction >= 0.0 and fraction < _last_stamina_fraction - 0.0001)
	_stamina_arc.call("update_stamina", fraction, draining, delta)
	_last_stamina_fraction = fraction


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


## `player.global_position` and a yaw DERIVED from `CameraRig.planar_basis()`
## rather than read off a private field -- see the task brief's own reasoning,
## which mirrors `minimap.gd`'s own header derivation
## (`forward(yaw) = (sin(yaw), 0, cos(yaw))`). `pal_pos` is the follower pal's
## position when `encounter_director.gd` has spawned one (named "AllyPal" in
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

	var pal_pos: Variant = null
	if world != null:
		var follower := world.get_node_or_null(^"AllyPal")
		if follower != null and is_instance_valid(follower) and follower is Node3D:
			pal_pos = (follower as Node3D).global_position

	_minimap.call("update_view", _player.global_position, yaw, pal_pos)

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
	block.mouse_filter = Control.MOUSE_FILTER_IGNORE
	block.position = Vector2(right - OBJECTIVE_MAX_WIDTH, top)
	block.size = Vector2(OBJECTIVE_MAX_WIDTH, OBJECTIVE_BLOCK_HEIGHT)
	_root.add_child(block)

	var eyebrow := Label.new()
	eyebrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	eyebrow.text = "M A I N   S T O R Y" # letter-spaced feel; no theme letter-spacing support
	eyebrow.add_theme_font_size_override("font_size", UITokens.FONT_TINY)
	eyebrow.add_theme_color_override("font_color", UITokens.TEXT_MUTED)
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	eyebrow.size = Vector2(OBJECTIVE_MAX_WIDTH, 22.0)
	block.add_child(eyebrow)

	_objective_text_label = Label.new()
	_objective_text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_objective_text_label.position = Vector2(0.0, 24.0)
	_objective_text_label.size = Vector2(OBJECTIVE_MAX_WIDTH, OBJECTIVE_BLOCK_HEIGHT - 24.0)
	_objective_text_label.add_theme_font_size_override("font_size", UITokens.FONT_LABEL)
	_objective_text_label.add_theme_color_override("font_color", UITokens.TEXT_PRIMARY)
	_objective_text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_objective_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	block.add_child(_objective_text_label)


func _update_objective() -> void:
	if _game == null:
		return
	var text := str(_game.get("objective_text"))
	if text == _objective_last_text:
		return
	_objective_last_text = text
	_objective_text_label.text = text


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
## unchanged), the pal block/party strip/objective (all `Game`-sourced), the
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
	_update_hotbar_and_message()
	_read_hotbar_input()
	_update_pal_block()
	_update_party_strip()
	_update_objective()
	_ensure_minimap_baked()
	_update_minimap()

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
	_prompt_label.text = text


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


## HD2. The hotbar mirrors satchel slots 0-4 directly.
func _update_hotbar(inventory: RefCounted) -> void:
	var db: RefCounted = _game.get("items")
	if db == null:
		return
	for i in HOTBAR_SLOTS:
		var stack: Dictionary = inventory.call("stack_at", i)
		var glyph := INPUT_GLYPH.icon(HOTBAR_ACTIONS[i], 28)
		var text: String
		if stack.is_empty():
			text = "%s\n[color=#666a63]-[/color]" % glyph
		else:
			var id := str(stack.get("id", ""))
			var name := str(db.call("item_name", id))
			var colour: Color = db.call("colour", id)
			var tool_max: int = int(inventory.call("max_durability_at", i))
			var count_text: String
			if tool_max > 0:
				count_text = "%d/%d" % [int(inventory.call("durability_at", i)), tool_max]
			else:
				count_text = "x%d" % int(stack.get("n", 0))
			text = "%s\n[color=#%s]%s %s[/color]" % [glyph, colour.to_html(false), name, count_text]
		if text != _hotbar_last_text[i]:
			_hotbar_last_text[i] = text
			_hotbar_slots[i].text = text


func _read_hotbar_input() -> void:
	if _game == null:
		return
	for i in HOTBAR_SLOTS:
		if Input.is_action_just_pressed(HOTBAR_ACTIONS[i]):
			_use_hotbar_slot(i)
			return


func _use_hotbar_slot(index: int) -> void:
	var inventory: RefCounted = _game.get("inventory")
	var db: RefCounted = _game.get("items")
	if inventory == null or db == null:
		return
	var stack: Dictionary = inventory.call("stack_at", index)
	if stack.is_empty():
		return
	var id := str(stack.get("id", ""))

	if str(db.call("kind", id)) == "tool":
		var maximum := int(inventory.call("max_durability_at", index))
		if maximum > 0:
			var current := int(inventory.call("durability_at", index))
			if current >= maximum:
				_show_hotbar_message("%s is already in good repair." % str(db.call("item_name", id)))
			else:
				inventory.call("repair_tool", index)
				_show_hotbar_message("%s repaired, free." % str(db.call("item_name", id)))
			return

	var heal := float((db.call("definition", id) as Dictionary).get("heal", 0.0))
	if heal <= 0.0:
		_show_hotbar_message("%s is not something you can use here." % str(db.call("item_name", id)))
		return

	if _party == null or int(_party.call("size")) == 0:
		_show_hotbar_message("Nobody on the belt yet.")
		return

	var target: RefCounted = null
	var worst_deficit := 0.0
	for i in int(_party.call("size")):
		var pal: RefCounted = _party.call("at", i)
		if pal == null:
			continue
		var deficit: float = float(pal.get("max_hp")) - float(pal.get("hp"))
		if deficit > worst_deficit:
			worst_deficit = deficit
			target = pal

	if target == null:
		_show_hotbar_message("Everybody's already at full health.")
		return

	var restored := float(target.call("heal", heal))
	inventory.call("remove", id, 1)
	_show_hotbar_message("%s recovers %d." % [str(target.call("label")), int(restored)])


func _show_hotbar_message(text: String) -> void:
	_hotbar_message.text = text
	_hotbar_message.visible = true
	_hotbar_message_until = Time.get_ticks_msec() / 1000.0 + HOTBAR_MESSAGE_SECONDS


func _fade_toward(control: Control, target: float, delta: float) -> void:
	var current: float = control.modulate.a
	var next: float = move_toward(current, target, FADE_SPEED * delta)
	control.modulate.a = next


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
