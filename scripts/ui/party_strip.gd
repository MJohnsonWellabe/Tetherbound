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
const ROW_SIZE := Vector2(250.0, 76.0)
const ROW_SEPARATION := 6
const ROW_MARGIN := 6
const HEADER_HEIGHT := 30.0
const HEADER_GAP := 6.0
const TOTAL_HEIGHT := HEADER_HEIGHT + HEADER_GAP + SLOTS * ROW_SIZE.y + (SLOTS - 1) * ROW_SEPARATION
const CHIP_SIZE := Vector2(40.0, 40.0)
const RAIL_WIDTH := 4.0
const HP_BAR_SIZE := Vector2(72.0, 8.0)

## Fainted always reads as fainted, whether or not the slot happens to also be
## the (impossible, but not this file's job to assume) selected one.
const FAINTED_MODULATE := 0.4
const RESTING_MODULATE := 0.5
const UNSELECTED_MODULATE := 0.78
const VACANT_MODULATE := 0.62
const SELECTED_MODULATE := 1.0

## How far the strip slides while revealing, in local pixels. Small on
## purpose — this is a reveal, not a fly-in; §6.1 asks for a strip that reads
## as "appearing," not one that travels across the screen.
const REVEAL_OFFSET := 12.0

var _pinned := false
var _fade_timer := 0.0
var _tween: Tween = null

## The position the caller (the HUD, at mount time) placed this widget at.
## Captured once in `_build()` so the reveal tween has a fixed "home" to slide
## into rather than drifting further every time it fires.
var _rest_position := Vector2.ZERO

var _rows: Array[PanelContainer] = []
var _count_label: Label = null
var _list: VBoxContainer = null
var _rails: Array[ColorRect] = []
var _chips: Array[Panel] = []
var _chip_boxes: Array[StyleBoxFlat] = []
var _portraits: Array[TextureRect] = []
var _slot_labels: Array[Label] = []
var _name_labels: Array[Label] = []
var _level_labels: Array[Label] = []
var _ko_labels: Array[Label] = []
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
	_count_label.add_theme_font_size_override("font_size", UI_TOKENS.FONT_TINY)
	_count_label.add_theme_color_override("font_color", UI_TOKENS.TEAL_SOFT)
	header.add_child(_count_label)

	_list = VBoxContainer.new()
	_list.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_list.add_theme_constant_override("separation", ROW_SEPARATION)
	stack.add_child(_list)

	for i in SLOTS:
		_list.add_child(_build_row(i))


func _build_row(slot_index: int) -> PanelContainer:
	var row := PanelContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.custom_minimum_size = ROW_SIZE
	row.add_theme_stylebox_override("panel", UI_TOKENS.slot_box(false))
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
	name_label.add_theme_font_size_override("font_size", UI_TOKENS.FONT_LABEL)
	_name_labels.append(name_label)
	info.add_child(name_label)

	var level_row := HBoxContainer.new()
	level_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	level_row.add_theme_constant_override("separation", 6)
	info.add_child(level_row)

	var level_label := Label.new()
	level_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	level_label.add_theme_font_size_override("font_size", UI_TOKENS.FONT_TINY)
	level_label.add_theme_color_override("font_color", UI_TOKENS.TEXT_SECONDARY)
	_level_labels.append(level_label)
	level_row.add_child(level_label)

	# Small "KO" tag next to the level, shown only for a fainted entry — blind
	# visual review: a fainted creature in the strip had no marker at all, reading
	# identically to a healthy one at a glance.
	var ko_label := Label.new()
	ko_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ko_label.text = "KO"
	ko_label.add_theme_font_size_override("font_size", UI_TOKENS.FONT_TINY)
	ko_label.add_theme_color_override("font_color", UI_TOKENS.DANGER)
	ko_label.visible = false
	_ko_labels.append(ko_label)
	level_row.add_child(ko_label)

	var rest_label := Label.new()
	rest_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rest_label.text = "REST"
	rest_label.add_theme_font_size_override("font_size", UI_TOKENS.FONT_TINY)
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
func update_from_party(entries: Array, active_index: int) -> void:
	_count_label.text = "TEAM  %d / %d" % [mini(entries.size(), SLOTS), SLOTS]
	for i in SLOTS:
		var has_creature: bool = i < entries.size()
		var entry: Dictionary = entries[i] if has_creature else {}
		_update_row(i, entry, has_creature, has_creature and i == active_index)


func _update_row(i: int, entry: Dictionary, has_creature: bool, selected: bool) -> void:
	var fainted := has_creature and bool(entry.get("fainted", false))
	var resting := has_creature and bool(entry.get("resting", false))
	var vacant := not has_creature

	if vacant != _last_vacant[i] or selected != _last_selected[i]:
		_rows[i].add_theme_stylebox_override("panel", UI_TOKENS.slot_box(selected))
		_rails[i].visible = selected
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
		_ko_labels[i].visible = false
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
	_ko_labels[i].visible = fainted
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


func _process(delta: float) -> void:
	if _pinned or not visible:
		return
	if _fade_timer > 0.0:
		_fade_timer -= delta
		if _fade_timer <= 0.0:
			_hide_strip()
