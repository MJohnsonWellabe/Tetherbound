extends CanvasLayer

## Reads the fight and draws it. Owns no state of its own — except the switch
## selector's cursor and the tap/hold timers, which are interaction state, not
## fight state: `CombatManager` has no idea whether a d-pad press is 0.1s or
## 0.4s into being held, and it should not have to.
##
## Everything else is pulled from CombatManager and the two creature instances each
## frame rather than pushed in on signals. A HUD that keeps its own copy of the
## health bar is a HUD that can disagree with the fight, and the first time that
## happens it costs an afternoon.
##
## The exceptions are the outcome banner, the XP line and the "GO, <label>!"
## line, which are driven by signals (`exited`, `catch_resolved`, `creature_switched`)
## because each describes a moment rather than a value.
##
## Rebuilt to the owner's Palworld-inspired spec (§9) plus D32's mid-combat
## switching UI. The old single-`RichTextLabel` verb row is gone; the four
## verbs are now grid cells (`_draw_cells`), each independently ready/dimmed,
## with a one-shot pulse on the frame a cell becomes usable rather than the
## old plain colour swap.

const INPUT_GLYPH := preload("res://scripts/ui/input_glyph.gd")
const CATCH := preload("res://scripts/combat/catch_math.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const MOVE_DB := preload("res://scripts/creatures/move_db.gd")
const PARTY_STRIP := preload("res://scripts/ui/party_strip.gd")

## The orb cluster's fallback icon/id (spec §10.4), used only if the combat
## manager cannot be reached. R4.9: the real icon and name are read per-frame
## off whichever tier `combat_manager.gd::current_orb_id()` says a throw
## would actually spend, through `data/items/items.json`'s own `Game.items`
## lookup (same convention `playground_hud.gd`'s hotbar already uses) — so a
## fuller satchel showing a stronger tier changes what this cluster prints,
## and it never claims to be about to throw an orb that a throw would not.
const ORB_ICON_PATH := "res://assets/ui/icons/items/orb_basic.png"
const ORB_ITEM_ID := "orb_basic"

## Verb glyph colour when a grid cell IS/IS NOT usable right now. Kept as
## plain hex (not `UITokens.TEXT_PRIMARY`/`TEXT_MUTED`) because `input_glyph.icon`
## wants a `Color`, not a token name, and these feed straight into it.
const VERB_READY := Color("F2F5F2")
const VERB_DIMMED := Color("8b9184")

## Non-usable grid cell: 55% grey, not full transparency — the button is still
## there, only its availability changed (`_verb`'s old header comment, ported
## from the verb-row era: an unavailable action reads as disabled, not gone).
const CELL_DIMMED := Color(0.55, 0.55, 0.55, 1.0)
const CELL_READY := Color(1.0, 1.0, 1.0, 1.0)

## Tap vs hold for `combat_switch_left`/`combat_switch_right` (D32, spec §9.4).
## Below this, a release cycles; at or above it, the party selector opens.
const SWITCH_HOLD_THRESHOLD := 0.28

const SELECTOR_ROWS := 5
const SELECTOR_ROW_SIZE := Vector2(280.0, 56.0)
const SELECTOR_CHIP_SIZE := Vector2(36.0, 36.0)
const SELECTOR_HP_SIZE := Vector2(84.0, 8.0)

## Shared screen slot for `PartyStrip` and the selector panel. Both sit
## directly above the creature block (`AllyPanel`, whose top edge is 206px off the
## bottom of a 1080-tall canvas — see `combat_hud.tscn`'s own offsets) with
## generous headroom: `PARTY_STRIP.ROW_SIZE`'s 56px is a MINIMUM, not the
## real rendered height — a row's two-line name/level stack plus its
## `MarginContainer` padding measured taller than that in a real capture, and
## the first version of this file placed the strip only 10px above the creature
## block, which overlapped it outright. 430px of clearance covers five rows
## at up to ~80px each plus separation with room to spare.
##
## The two widgets never actually occupy this slot at the same time — see
## `_open_selector()` — so sharing one position is a deliberate simplification
## of spec §9.4's "party_strip mounted ABOVE this block... pinned visible
## while a switch is available/being chosen": showing the identical four rows
## twice, side by side, read as a duplication bug in the first capture of
## this shot, not as two different pieces of information.
const SWITCH_PANEL_POS := Vector2(56.0, 380.0)

@export var manager_path: NodePath
@export var director_path: NodePath

var _manager: Node = null
var _director: Node = null
var _moves: RefCounted = null

var _ally_health_fill: StyleBoxFlat = null
var _enemy_health_fill: StyleBoxFlat = null
var _energy_fill: StyleBoxFlat = null

var _outcome_left: float = 0.0
var _xp_left: float = 0.0
var _go_left: float = 0.0
var _miss_left: float = 0.0
var _miss_text: String = ""

## Grid cell ready-state on the PREVIOUS frame, so a cell pulses once on the
## frame it flips false -> true and never again while it stays ready.
var _prev_ready: Dictionary = {"quick": false, "charged": false, "throw": false, "switch": false}
var _energy_was_full: bool = false
var _pulse_tweens: Dictionary = {}

## --- capture reticle / orb cluster (spec §10, D31) --------------------------
var _orb_cluster: RichTextLabel = null
var _was_resolving_catch: bool = false
var _last_reticle_screen_pos: Vector2 = Vector2.ZERO

## --- switching (D32) --------------------------------------------------------
var _switch_hold_dir: int = 0
var _switch_hold_time: float = 0.0
var _selector_open: bool = false
var _selector_list: Array = []
var _selector_cursor: int = 0

var _party_strip: Control = null
var _selector_root: PanelContainer = null
var _selector_rows: Array[PanelContainer] = []
var _selector_rails: Array[ColorRect] = []
var _selector_chips: Array[ColorRect] = []
var _selector_names: Array[Label] = []
var _selector_levels: Array[Label] = []
var _selector_hp_bars: Array[ProgressBar] = []
var _selector_hp_fills: Array[StyleBoxFlat] = []

@onready var _enemy_panel: PanelContainer = $Root/EnemyPanel
@onready var _enemy_eyebrow: Label = $Root/EnemyPanel/EnemyVBox/Eyebrow
@onready var _enemy_name: Label = $Root/EnemyPanel/EnemyVBox/Name
@onready var _enemy_type_tag: Label = $Root/EnemyPanel/EnemyVBox/TypeTag
@onready var _enemy_health: ProgressBar = $Root/EnemyPanel/EnemyVBox/Health
@onready var _telegraph: Label = $Root/EnemyPanel/EnemyVBox/Telegraph

@onready var _ally_panel: PanelContainer = $Root/AllyPanel
@onready var _ally_chip: ColorRect = $Root/AllyPanel/AllyVBox/TopRow/Chip
@onready var _ally_name: Label = $Root/AllyPanel/AllyVBox/TopRow/Info/Name
@onready var _ally_level: Label = $Root/AllyPanel/AllyVBox/TopRow/Info/Level
@onready var _ally_health: ProgressBar = $Root/AllyPanel/AllyVBox/Health
@onready var _ally_energy: ProgressBar = $Root/AllyPanel/AllyVBox/EnergyRow/EnergyHost/Energy
@onready var _energy_pulse: ColorRect = $Root/AllyPanel/AllyVBox/EnergyRow/EnergyHost/Pulse
@onready var _ally_status: Label = $Root/AllyPanel/AllyVBox/Status

@onready var _go_text: Label = $Root/GoText

@onready var _orbs: Label = $Root/OrbsLabel
@onready var _grid_panel: PanelContainer = $Root/GridPanel

@onready var _cell_quick: PanelContainer = $Root/GridPanel/Grid/CellQuick
@onready var _cell_quick_hairline: ColorRect = $Root/GridPanel/Grid/CellQuick/Layout/Row/Hairline
@onready var _cell_quick_content: RichTextLabel = $Root/GridPanel/Grid/CellQuick/Layout/Row/Content
@onready var _cell_quick_pulse: ColorRect = $Root/GridPanel/Grid/CellQuick/Layout/Pulse

@onready var _cell_charged: PanelContainer = $Root/GridPanel/Grid/CellCharged
@onready var _cell_charged_hairline: ColorRect = $Root/GridPanel/Grid/CellCharged/Layout/Row/Hairline
@onready var _cell_charged_content: RichTextLabel = $Root/GridPanel/Grid/CellCharged/Layout/Row/Content
@onready var _cell_charged_pulse: ColorRect = $Root/GridPanel/Grid/CellCharged/Layout/Pulse

@onready var _cell_throw: PanelContainer = $Root/GridPanel/Grid/CellThrow
@onready var _cell_throw_content: RichTextLabel = $Root/GridPanel/Grid/CellThrow/Layout/Row/Content
@onready var _cell_throw_pulse: ColorRect = $Root/GridPanel/Grid/CellThrow/Layout/Pulse

@onready var _cell_switch: PanelContainer = $Root/GridPanel/Grid/CellSwitch
@onready var _cell_switch_content: RichTextLabel = $Root/GridPanel/Grid/CellSwitch/Layout/Row/Content
@onready var _cell_switch_pulse: ColorRect = $Root/GridPanel/Grid/CellSwitch/Layout/Pulse

@onready var _prompt: RichTextLabel = $Root/Prompt
@onready var _aim_row: RichTextLabel = $Root/AimRow
@onready var _catch_row: RichTextLabel = $Root/CatchRow
@onready var _capture_reticle: Control = $Root/CaptureReticle
@onready var _outcome: Label = $Root/Outcome
@onready var _xp_line: Label = $Root/XPLine


func _ready() -> void:
	layer = UITokens.LAYER_COMBAT

	_manager = get_node_or_null(manager_path)
	_director = get_node_or_null(director_path)
	_moves = MOVE_DB.load_default()

	_ally_health_fill = UITokens.fill_box(UITokens.HP_GREEN)
	_enemy_health_fill = UITokens.fill_box(UITokens.HP_GREEN)
	_energy_fill = UITokens.fill_box(UITokens.TEAL)
	_dress(_ally_health, _ally_health_fill)
	_dress(_enemy_health, _enemy_health_fill)
	_dress(_ally_energy, _energy_fill)

	_enemy_panel.add_theme_stylebox_override("panel", _quiet_panel_box())
	_ally_panel.add_theme_stylebox_override("panel", UITokens.panel_box())
	_grid_panel.add_theme_stylebox_override("panel", UITokens.panel_box())
	for cell in [_cell_quick, _cell_charged, _cell_throw, _cell_switch]:
		(cell as PanelContainer).add_theme_stylebox_override("panel", UITokens.slot_box(false))

	_build_selector()

	_party_strip = PARTY_STRIP.new()
	_party_strip.position = SWITCH_PANEL_POS
	$Root.add_child(_party_strip)

	_build_orb_cluster()

	UITokens.make_text_legible($Root)

	if _manager != null:
		_manager.connect("exited", _on_exited)
		_manager.connect("attack_missed", _on_missed)
		_manager.connect("catch_refused", _on_catch_refused)
		_manager.connect("catch_resolved", _on_catch_resolved)
		_manager.connect("creature_switched", _on_creature_switched)
		_manager.connect("orb_shook", _on_orb_shook)
	_show_fight(false)


## The lower-right orb cluster (spec §10.4): icon, item name, count, and the
## throw/cancel glyphs, all as one BBCode block rather than a fistful of
## separate Controls — `RichTextLabel`'s `[img]` tag already draws the icon
## inline, and this cluster only ever needs to change together (one
## `_update_orb_cluster` call, one string). Built here rather than in the
## .tscn per the task brief's own scope line for that file ("mount only");
## `_selector_root`/`_party_strip` above are already built the same way.
func _build_orb_cluster() -> void:
	_orb_cluster = RichTextLabel.new()
	_orb_cluster.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_orb_cluster.bbcode_enabled = true
	_orb_cluster.fit_content = false
	_orb_cluster.scroll_active = false
	_orb_cluster.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_orb_cluster.add_theme_font_size_override("normal_font_size", UITokens.FONT_LABEL)
	_orb_cluster.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_orb_cluster.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_orb_cluster.grow_vertical = Control.GROW_DIRECTION_BEGIN
	# Inset to UITokens.MARGIN_SAFE (48px), not the wider HUD_INSET (56px) the
	# rest of this HUD uses — blind visual review flagged this cluster as
	# flush against the screen edge; box size (244x238) is unchanged, only
	# shifted to hang off the safe-margin edge instead.
	_orb_cluster.offset_left = -300.0 + (UITokens.HUD_INSET - UITokens.MARGIN_SAFE)
	_orb_cluster.offset_top = -294.0 + (UITokens.HUD_INSET - UITokens.MARGIN_SAFE)
	_orb_cluster.offset_right = -float(UITokens.MARGIN_SAFE)
	_orb_cluster.offset_bottom = -float(UITokens.MARGIN_SAFE)
	_orb_cluster.visible = false
	$Root.add_child(_orb_cluster)


## The health-bar track/fill treatment, shared by both bars. Split out of the
## old per-bar `_style`/`_dress` pair now that `UITokens.fill_box` already
## builds the fill half — this only still needs to own the track.
func _dress(bar: ProgressBar, fill: StyleBoxFlat) -> void:
	var track := UITokens.fill_box(UITokens.TRACK)
	track.border_width_left = 2
	track.border_width_right = 2
	track.border_width_top = 2
	track.border_width_bottom = 2
	track.border_color = Color(0.02, 0.02, 0.02, 0.85)
	bar.add_theme_stylebox_override("background", track)
	bar.add_theme_stylebox_override("fill", fill)


## The enemy plate's own quiet backing (spec §9): `BG_DEEP` at ~55% alpha, no
## border. Every other panel in this HUD uses `UITokens.panel_box()` as-is;
## this one deliberately does not, because the plate sits over open sky/hillside
## for the whole fight and a bordered frame there reads as a window, not a
## label floating over the world.
func _quiet_panel_box() -> StyleBoxFlat:
	var box := UITokens.panel_box(Color(UITokens.BG_DEEP.r, UITokens.BG_DEEP.g, UITokens.BG_DEEP.b, 0.55))
	box.border_width_left = 0
	box.border_width_right = 0
	box.border_width_top = 0
	box.border_width_bottom = 0
	return box


## --- the small custom switch selector (D32, spec §9.4) ---------------------
##
## Not `PartyStrip` reused wholesale — the task brief itself offers that as
## the alternative and picks this as the simpler path. It draws the same five
## fixed party rows `PartyStrip` does (chip/name/level/hp, vacant and fainted
## states) so the two widgets read as one family sitting side by side, but adds
## the one thing `PartyStrip` has no reason to know about: a cursor separate
## from "who is out right now".
func _build_selector() -> void:
	_selector_root = PanelContainer.new()
	_selector_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_selector_root.add_theme_stylebox_override("panel", UITokens.panel_box())
	_selector_root.position = SWITCH_PANEL_POS
	_selector_root.visible = false
	$Root.add_child(_selector_root)

	var list := VBoxContainer.new()
	list.mouse_filter = Control.MOUSE_FILTER_IGNORE
	list.add_theme_constant_override("separation", 6)
	_selector_root.add_child(list)

	for i in SELECTOR_ROWS:
		list.add_child(_build_selector_row())


func _build_selector_row() -> PanelContainer:
	var row := PanelContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.custom_minimum_size = SELECTOR_ROW_SIZE
	row.add_theme_stylebox_override("panel", UITokens.slot_box(false))
	_selector_rows.append(row)

	var hbox := HBoxContainer.new()
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_theme_constant_override("separation", 8)
	row.add_child(hbox)

	var rail := ColorRect.new()
	rail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rail.custom_minimum_size = Vector2(4.0, 0.0)
	rail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rail.color = UITokens.TEAL
	rail.visible = false
	_selector_rails.append(rail)
	hbox.add_child(rail)

	var chip := ColorRect.new()
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.custom_minimum_size = SELECTOR_CHIP_SIZE
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_selector_chips.append(chip)
	hbox.add_child(chip)

	var info := VBoxContainer.new()
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	info.add_theme_constant_override("separation", 2)
	hbox.add_child(info)

	var name_label := Label.new()
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.add_theme_font_size_override("font_size", UITokens.FONT_LABEL)
	_selector_names.append(name_label)
	info.add_child(name_label)

	var level_label := Label.new()
	level_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	level_label.add_theme_font_size_override("font_size", UITokens.FONT_TINY)
	level_label.add_theme_color_override("font_color", UITokens.TEXT_SECONDARY)
	_selector_levels.append(level_label)
	info.add_child(level_label)

	var hp_bar := ProgressBar.new()
	hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_bar.custom_minimum_size = SELECTOR_HP_SIZE
	hp_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hp_bar.show_percentage = false
	hp_bar.min_value = 0.0
	hp_bar.max_value = 1.0
	hp_bar.add_theme_stylebox_override("background", UITokens.fill_box(UITokens.TRACK))
	var fill := UITokens.fill_box(UITokens.HP_GREEN)
	hp_bar.add_theme_stylebox_override("fill", fill)
	_selector_hp_fills.append(fill)
	_selector_hp_bars.append(hp_bar)
	hbox.add_child(hp_bar)

	return row


func _process(delta: float) -> void:
	_tick_outcome(delta)
	_tick_xp(delta)
	_tick_go_text(delta)
	_miss_left = maxf(0.0, _miss_left - delta)
	_draw_prompt()

	var fighting: bool = _manager != null and bool(_manager.call("is_fighting"))
	if not fighting:
		_reset_switch_input()
		_show_fight(false)
		return

	_show_fight(true)
	_draw_enemy()
	_draw_ally()
	_draw_grid()
	_update_capture_reticle()
	_handle_switch_input(delta)
	_update_party_strip()


func _show_fight(visible_now: bool) -> void:
	_enemy_panel.visible = visible_now
	_ally_panel.visible = visible_now
	_go_text.visible = visible_now
	_orbs.visible = visible_now
	if not visible_now:
		_grid_panel.visible = false
		_aim_row.visible = false
		_catch_row.visible = false
		if _party_strip != null:
			_party_strip.call("set_pinned", false)
		if _orb_cluster != null:
			_orb_cluster.visible = false
		if _capture_reticle != null:
			_capture_reticle.call("update_target", Vector2.ZERO, 0.0, false)
		_enemy_panel.modulate.a = 1.0
		_grid_panel.modulate.a = 1.0
	if _selector_root != null:
		_selector_root.visible = visible_now and _selector_open


## `EV9-double-prompt`: this row exists to keep showing "Engage X" before a
## fight starts, not to repeat whatever unrelated line `PlaygroundHUD` is
## currently showing (Grandpa, a starter, a harvest node) just because this
## `CanvasLayer` never toggles fully invisible outside a fight. Once fighting,
## the arbiter is disabled scene-wide and `prompt()` already reads "" from it,
## so the fighting branch does not need its own ownership check.
func _draw_prompt() -> void:
	if _director == null:
		return
	var fighting: bool = _manager != null and bool(_manager.call("is_fighting"))
	if not fighting and not bool(_director.call("owns_active_prompt")):
		_prompt.text = ""
		return
	_prompt.text = str(_director.call("prompt"))


func _type_color(type_id: String) -> Color:
	match type_id:
		"water":
			return UITokens.WATER_BLUE
		"air":
			return UITokens.AIR_SKY
		_:
			return UITokens.GROUND_OCHRE


func _draw_enemy() -> void:
	var foe: RefCounted = _manager.call("enemy")
	if foe == null:
		return
	_enemy_eyebrow.text = "LEVEL %d" % int(foe.level)
	_enemy_name.text = str(foe.display_name)
	_enemy_type_tag.text = str(foe.creature_type).to_upper()
	_enemy_type_tag.add_theme_color_override("font_color", _type_color(str(foe.creature_type)))

	var fraction: float = foe.hp_fraction()
	_enemy_health.value = fraction * 100.0
	_enemy_health_fill.bg_color = UITokens.DANGER.lerp(UITokens.HP_GREEN, fraction)

	# The enemy's wind-up and its recovery, in words, because a placeholder
	# capsule has no animation to show either with. Scaffolding for real
	# animation, not a UI decision to keep.
	#
	# Silenced through the catch resolution and the fight's ending — the wild
	# creature freezes mid-beat when it goes into the orb, so whatever it was doing
	# otherwise stays on screen shouting stale advice over the wobble.
	if bool(_manager.call("is_resolving_catch")) or str(_manager.call("outcome")) != "":
		_telegraph.text = ""
	elif bool(_manager.call("enemy_is_winding_up")):
		_telegraph.text = "!  incoming — move"
		_telegraph.add_theme_color_override("font_color", UITokens.WARNING)
	elif bool(_manager.call("enemy_is_rooted")):
		_telegraph.text = "↯  it's open — hit it"
		_telegraph.add_theme_color_override("font_color", UITokens.TEAL_SOFT)
	else:
		_telegraph.text = ""


func _draw_ally() -> void:
	var creature: RefCounted = _manager.call("active_creature")
	if creature == null:
		return
	_ally_name.text = creature.label()
	_ally_level.text = "Lv %d" % int(creature.level)
	_ally_chip.color = _species_colour(str(creature.species_id))

	var fraction: float = creature.hp_fraction()
	_ally_health.value = fraction * 100.0
	_ally_health_fill.bg_color = UITokens.DANGER.lerp(UITokens.HP_GREEN, fraction)

	var energy: float = creature.energy_fraction()
	_ally_energy.value = energy * 100.0

	# Once, not constantly: a bar that pulses every frame it happens to be full
	# stops meaning anything. Only the RISING edge (not-full -> full) fires it.
	var now_full: bool = energy >= 0.999
	if now_full and not _energy_was_full:
		_pulse(_energy_pulse)
	_energy_was_full = now_full


func _species_colour(species_id: String) -> Color:
	var placeholder: Dictionary = SPECIES.placeholder(species_id)
	return Color(str(placeholder.get("colour", "#888888")))


## --- move grid (spec §9) ----------------------------------------------------

## Orbs, the grid itself, or whichever of the two mutually-exclusive
## alternate rows (aiming / resolving-catch / a transient miss-or-refusal
## message) currently owns the bottom-centre strip. Precedence mirrors the
## pre-rebuild `_draw_actions`: a resolving catch always wins, a live miss or
## switch-refusal message wins over aiming, and the grid only draws once none
## of those are true.
func _draw_grid() -> void:
	var orbs: int = int(_manager.call("orbs_left"))
	_orbs.text = "Orbs  %d" % orbs

	var resolving: bool = bool(_manager.call("is_resolving_catch"))
	var aiming: bool = bool(_manager.call("is_aiming"))
	var has_message: bool = _miss_left > 0.0

	# The orb cluster and the enemy plate/grid dim (spec §10.1/§10.4) only ever
	# apply to the AIMING branch below; every other branch clears them, same
	# discipline `_show_fight` already uses for the fully-not-fighting case.
	if not aiming:
		if _orb_cluster != null:
			_orb_cluster.visible = false
		_enemy_panel.visible = true
		_enemy_panel.modulate.a = 1.0
		_grid_panel.modulate.a = 1.0

	_catch_row.visible = resolving
	if resolving:
		_grid_panel.visible = false
		_aim_row.visible = false
		_catch_row.text = "[center]%s[/center]" % (_miss_text if has_message else "")
		return

	if has_message:
		_grid_panel.visible = false
		_aim_row.visible = true
		_aim_row.text = "[center]%s[/center]" % _miss_text
		return

	if aiming:
		_grid_panel.visible = false
		# Odds-free and empty: Throw/Cancel used to be worded out here AND in
		# the lower-right orb cluster at the same time (blind visual review's
		# "duplicate Throw/Cancel while aiming") — the orb cluster
		# (`_draw_orb_cluster`) is the one home for those verbs now (spec
		# §10.4); the percentage itself already lives on the capture reticle
		# (D31). Nothing left for this row to say while aiming.
		_aim_row.visible = false
		_aim_row.text = ""
		_orbs.visible = false
		_draw_orb_cluster(orbs)
		# Hidden, not dimmed (blind visual review: a 35%-alpha plate over open
		# sky read as "a broken grey ghost", not "temporarily de-emphasised").
		# The move grid stays a plain alpha dim — it is still a legible panel
		# at 35%, just quieter; the enemy plate at that alpha was not.
		_enemy_panel.visible = false
		_grid_panel.modulate.a = 0.35
		return

	_aim_row.visible = false
	_grid_panel.visible = true
	_draw_cells(orbs)


func _draw_cells(orbs: int) -> void:
	var creature: RefCounted = _manager.call("active_creature")
	if creature == null:
		return

	var quick_ready: bool = bool(_manager.call("quick_ready"))
	var charged_ready: bool = bool(_manager.call("charged_ready"))
	var throw_ready: bool = orbs > 0
	var switchable: Array = _manager.call("switchable_indices")
	var switch_ready: bool = bool(_manager.call("can_switch")) and not switchable.is_empty()

	_draw_quick_cell(creature, quick_ready)
	_draw_charged_cell(creature, charged_ready)
	_draw_throw_cell(orbs, throw_ready)
	_draw_switch_cell(switch_ready)


func _move_name(move_id: String, fallback: String) -> String:
	if move_id != "" and _moves.has(move_id):
		return _moves.display_name(move_id)
	return fallback


func _move_type(move_id: String, fallback_type: String) -> String:
	if move_id != "" and _moves.has(move_id):
		return str(_moves.move(move_id).get("type", fallback_type))
	return fallback_type


func _draw_quick_cell(creature: RefCounted, ready: bool) -> void:
	var name_text := _move_name(str(creature.move_quick), "Quick")
	var glyph := INPUT_GLYPH.icon("quick", 34, VERB_READY if ready else VERB_DIMMED)
	_cell_quick_content.text = "[center]%s\n%s[/center]" % [glyph, name_text]
	_cell_quick_hairline.color = _type_color(_move_type(str(creature.move_quick), str(creature.creature_type)))
	_cell_quick.modulate = CELL_READY if ready else CELL_DIMMED
	_mark_ready("quick", ready, _cell_quick_pulse)


func _draw_charged_cell(creature: RefCounted, ready: bool) -> void:
	var move_id := str(creature.move_charged)
	var name_text := _move_name(move_id, "Charged")
	var glyph := INPUT_GLYPH.icon("charged", 34, VERB_READY if ready else VERB_DIMMED)
	var text := "[center]%s\n%s[/center]" % [glyph, name_text]
	if not ready:
		var required: int = int(_moves.move(move_id).get("energy_cost", 100)) if move_id != "" else 100
		text = "[center]%s\n%s\n[font_size=%d][color=#%s]%d[/color][/font_size][/center]" % [
			glyph, name_text, UITokens.FONT_TINY, VERB_DIMMED.to_html(false), required
		]
	_cell_charged_content.text = text
	_cell_charged_hairline.color = _type_color(_move_type(move_id, str(creature.creature_type)))
	_cell_charged.modulate = CELL_READY if ready else CELL_DIMMED
	_mark_ready("charged", ready, _cell_charged_pulse)


func _draw_throw_cell(orbs: int, ready: bool) -> void:
	var glyph := INPUT_GLYPH.icon("throw", 34, VERB_READY if ready else VERB_DIMMED)
	var name_text := "Throw" if ready else "No orbs"
	_cell_throw_content.text = "[center]%s\n%s[/center]" % [glyph, name_text]
	_cell_throw.modulate = CELL_READY if ready else CELL_DIMMED
	_mark_ready("throw", ready, _cell_throw_pulse)


func _draw_switch_cell(ready: bool) -> void:
	var glyph := "%s%s" % [
		INPUT_GLYPH.icon("switch_left", 28, VERB_READY if ready else VERB_DIMMED),
		INPUT_GLYPH.icon("switch_right", 28, VERB_READY if ready else VERB_DIMMED),
	]
	_cell_switch_content.text = "[center]%s\nSwitch[/center]" % glyph
	_cell_switch.modulate = CELL_READY if ready else CELL_DIMMED
	_mark_ready("switch", ready, _cell_switch_pulse)


## Fire the teal pulse exactly once, on the frame a cell's `ready` flips from
## false to true — never on every frame it merely stays ready, which is what a
## plain "if ready: pulse" would do.
func _mark_ready(key: String, ready: bool, pulse_rect: ColorRect) -> void:
	var was_ready: bool = bool(_prev_ready.get(key, ready))
	if ready and not was_ready:
		_pulse(pulse_rect)
	_prev_ready[key] = ready


## A brief teal flash over `rect` — `T_CAPTURE_PULSE` in, the same back out.
## Used for a cell becoming ready and for the energy bar topping out. Kills
## any tween already running on this exact rect so a rapid repeat retriggers
## cleanly instead of stacking.
func _pulse(rect: ColorRect) -> void:
	var key: int = rect.get_instance_id()
	if _pulse_tweens.has(key):
		var old: Tween = _pulse_tweens[key]
		if old != null and old.is_valid():
			old.kill()
	rect.color.a = 0.0
	var tw := create_tween()
	_pulse_tweens[key] = tw
	tw.tween_property(rect, "color:a", 0.55, UITokens.T_CAPTURE_PULSE)
	tw.tween_property(rect, "color:a", 0.0, UITokens.T_CAPTURE_PULSE)


## Icon, item name, count and the throw/cancel glyphs, replacing the plain
## "Orbs N" label for the length of the aim (spec §10.4). The item's display
## name is read off `Game.items` rather than hard-coded, so a renamed item
## cannot leave this cluster calling it something else than the satchel does.
func _draw_orb_cluster(orbs: int) -> void:
	if _orb_cluster == null:
		return
	_orb_cluster.visible = true
	var orb_id := ORB_ITEM_ID
	if _manager != null:
		orb_id = str(_manager.call("current_orb_id"))
	var item_name := "Tether Orb"
	var icon_path := ORB_ICON_PATH
	var game := get_node_or_null(^"/root/Game")
	if game != null:
		var db: RefCounted = game.get("items")
		if db != null:
			item_name = str(db.call("item_name", orb_id))
			icon_path = str(db.call("definition", orb_id).get("icon", ORB_ICON_PATH))
	_orb_cluster.text = "[right][img=24x24]%s[/img]  %s  x%d\n%s %s     %s %s[/right]" % [
		icon_path, item_name, orbs,
		INPUT_GLYPH.icon("throw", 26, VERB_READY), "Throw",
		INPUT_GLYPH.icon("cancel", 26, VERB_READY), "Cancel",
	]


## What the reticle needs this frame: the enemy's screen position and the
## chance a clean hit would resolve at right now. The enemy BODY is reached
## by reflection (`_manager.get("_wild")`) rather than a new accessor —
## `combat_manager.gd` is out of scope for this task, and `_party_entries()`
## above already reads a different underscore-prefixed field the identical
## way, for the identical reason. `target_marker.gd`'s own `centre()`/
## `body_radius()` calls on this same node are the precedent for treating it
## as the enemy's world anchor.
func _update_capture_reticle() -> void:
	if _capture_reticle == null or _manager == null:
		return

	var resolving_now: bool = bool(_manager.call("is_resolving_catch"))
	if resolving_now and not _was_resolving_catch:
		_capture_reticle.call("play_contract", _last_reticle_screen_pos)
	_was_resolving_catch = resolving_now

	if not bool(_manager.call("is_aiming")):
		_capture_reticle.call("update_target", Vector2.ZERO, 0.0, false)
		return

	var chance := float(_manager.call("catch_chance_now"))
	var wild: Variant = _manager.get("_wild")
	var camera: Camera3D = get_viewport().get_camera_3d()
	if not (wild is Node3D) or not is_instance_valid(wild) or camera == null \
			or not (wild as Node3D).has_method("centre"):
		_capture_reticle.call("update_target", Vector2.ZERO, chance, false)
		return

	var world_pos: Vector3 = (wild as Node3D).call("centre")
	var to_target: Vector3 = world_pos - camera.global_position
	if to_target.dot(-camera.global_transform.basis.z) <= 0.0:
		# Behind the camera — unproject_position() would return nonsense.
		_capture_reticle.call("update_target", Vector2.ZERO, chance, false)
		return

	var screen_pos: Vector2 = camera.unproject_position(world_pos)
	_last_reticle_screen_pos = screen_pos
	_capture_reticle.call("update_target", screen_pos, chance, true)


## --- switching input (D32, spec §9.4) ---------------------------------------
##
## Tap `combat_switch_left`/`combat_switch_right` (< `SWITCH_HOLD_THRESHOLD`)
## cycles; holding opens the selector below. No time-slow (D32's own "what was
## deliberately not built") — the fight keeps running underneath this the
## entire time, which is why every branch here re-checks `is_aiming` /
## `is_resolving_catch` rather than assuming whatever was true when the hold
## started still is.
##
## CONSUMPTION, and its limit: this reads `Input.is_action_just_pressed`
## polling, the same mechanism `CombatManager._read_player_input` already
## uses for every other combat verb, and is deliberately guarded to do nothing
## at all while `_manager.call("is_fighting")` is false. What it can NOT do is
## stop `playground_hud.gd`'s own hotbar poll from seeing the same press:
## `hotbar_2`/`hotbar_3` share the identical physical d-pad-left/right buttons
## (`project.godot`), `Input.is_action_just_pressed` is a global read with no
## concept of one script consuming it before another, and `playground_hud.gd`
## polls its hotbar with no combat gate at all — a documented, pre-existing gap
## (that file's own `_read_hotbar_input` header, "KNOWN GAP: not gated off
## during combat"). This file does not touch `playground_hud.gd` (out of
## scope for this task) — see this task's report for the confirmed leak.
func _handle_switch_input(delta: float) -> void:
	if _manager == null:
		return

	# Aiming and a resolving catch both already own player input elsewhere in
	# the fight (`throw_aim.gd`, the frozen beat around the orb); a switch
	# attempt here would be a second thing reading the same buttons. Close
	# any selector left open rather than strand it mid-throw.
	if bool(_manager.call("is_aiming")) or bool(_manager.call("is_resolving_catch")):
		if _selector_open:
			_close_selector()
		_switch_hold_dir = 0
		_switch_hold_time = 0.0
		return

	var can_switch: bool = bool(_manager.call("can_switch"))

	for dir in [-1, 1]:
		var action := "combat_switch_left" if dir < 0 else "combat_switch_right"
		if not Input.is_action_just_pressed(action):
			continue
		if not can_switch:
			_refuse_switch()
			continue
		_switch_hold_dir = dir
		_switch_hold_time = 0.0

	if _switch_hold_dir != 0:
		var held_action := "combat_switch_left" if _switch_hold_dir < 0 else "combat_switch_right"
		var other_action := "combat_switch_right" if _switch_hold_dir < 0 else "combat_switch_left"

		if Input.is_action_pressed(held_action):
			_switch_hold_time += delta
			if not _selector_open and _switch_hold_time >= SWITCH_HOLD_THRESHOLD:
				_open_selector()
			# While held, the OTHER switch action steps the highlight — the
			# held button's own `just_pressed` cannot fire again without a
			# release, which is reserved for confirming (spec §9.4: "d-pad
			# up/down (or the switch actions themselves stepping)").
			if _selector_open and Input.is_action_just_pressed(other_action):
				_step_selector(-_switch_hold_dir)
		else:
			if _selector_open:
				_confirm_selector()
			elif _switch_hold_time < SWITCH_HOLD_THRESHOLD:
				if not bool(_manager.call("cycle_active", _switch_hold_dir)):
					_refuse_switch()
			_switch_hold_dir = 0
			_switch_hold_time = 0.0

	if _selector_open:
		if Input.is_action_just_pressed("menu_confirm"):
			_confirm_selector()
		elif Input.is_action_just_pressed("menu_cancel"):
			_close_selector()


func _refuse_switch() -> void:
	_miss_text = "locked in — a moment"
	_miss_left = 1.2


func _reset_switch_input() -> void:
	_switch_hold_dir = 0
	_switch_hold_time = 0.0
	if _selector_open:
		_close_selector()


func _open_selector() -> void:
	var list: Array = _manager.call("switchable_indices")
	if list.is_empty():
		return
	_selector_list = list
	_selector_cursor = 0
	_selector_open = true
	if _selector_root != null:
		_selector_root.visible = true
	# Hand the shared screen slot off from the ambient strip to the selector
	# immediately, rather than leaving both visible together (see
	# `SWITCH_PANEL_POS`'s header). `_hide_strip` is `PartyStrip`'s own
	# private fade-out — reflection, the same idiom this file already uses
	# for `_party_entries()` and `_active_index`, because starting that fade
	# is not part of `PartyStrip`'s public API and this task does not touch
	# `party_strip.gd`.
	if _party_strip != null:
		_party_strip.call("_hide_strip")
	_refresh_selector()


func _step_selector(steps: int) -> void:
	if _selector_list.is_empty():
		return
	var size: int = _selector_list.size()
	_selector_cursor = ((_selector_cursor + steps) % size + size) % size
	_refresh_selector()


func _confirm_selector() -> void:
	if _selector_open and not _selector_list.is_empty():
		var index: int = int(_selector_list[_selector_cursor])
		if not bool(_manager.call("request_switch", index)):
			_refuse_switch()
	_close_selector()


func _close_selector() -> void:
	_selector_open = false
	if _selector_root != null:
		_selector_root.visible = false


## The five party rows: chip/name/level/hp for whichever entries exist, a teal
## rail on whichever slot is the CURRENTLY PILOTED creature (not the cursor), and a
## brighter cursor-highlighted border on whichever slot the d-pad selection is
## currently on. Those two are different things on purpose — the player is
## choosing who to switch TO, and needs both "who is out now" and "what my
## cursor is on" visible at once.
func _refresh_selector() -> void:
	var entries := _party_entries()
	var active_index: int = int(_manager.get("_active_index")) if _manager != null else -1
	var highlighted_index: int = int(_selector_list[_selector_cursor]) if not _selector_list.is_empty() else -1

	for i in SELECTOR_ROWS:
		var has_creature: bool = i < entries.size()
		var entry: Dictionary = entries[i] if has_creature else {}
		var fainted: bool = has_creature and bool(entry.get("fainted", false))
		var is_active: bool = has_creature and i == active_index
		var is_cursor: bool = has_creature and i == highlighted_index

		_selector_rows[i].add_theme_stylebox_override("panel", UITokens.slot_box(is_cursor))
		_selector_rails[i].visible = is_active

		if not has_creature:
			_selector_chips[i].color = Color(UITokens.TEXT_MUTED, 0.35)
			_selector_rows[i].modulate.a = 0.35
			_selector_names[i].text = ""
			_selector_levels[i].text = ""
			_selector_hp_bars[i].value = 0.0
			continue

		_selector_rows[i].modulate.a = 0.4 if fainted else 1.0
		_selector_chips[i].color = entry.get("tint", UITokens.TEXT_MUTED)
		_selector_names[i].text = str(entry.get("label", ""))
		_selector_levels[i].text = "Lv %d" % int(entry.get("level", 1))
		_selector_hp_bars[i].value = clampf(float(entry.get("hp_fraction", 0.0)), 0.0, 1.0)
		_selector_hp_fills[i].bg_color = UITokens.DANGER if fainted else UITokens.HP_GREEN


## Refresh the always-on party strip (pinned while a switch is available or
## being chosen) and, while a selector is open, its rows too.
func _update_party_strip() -> void:
	if _party_strip == null:
		return
	var entries := _party_entries()
	var active_index: int = int(_manager.get("_active_index")) if _manager != null else 0
	_party_strip.call("update_from_party", entries, active_index)

	# Pinned while a switch is available, EXCEPT while the selector has taken
	# over the shared screen slot (`_open_selector` already started its fade
	# out) -- pinning here too would re-reveal it every frame, right under
	# the selector it just handed the slot to.
	var switchable: Array = _manager.call("switchable_indices")
	var available: bool = bool(_manager.call("can_switch")) and not switchable.is_empty()
	_party_strip.call("set_pinned", available and not _selector_open)

	if _selector_open:
		_refresh_selector()


## The combat party, as `{label, level, hp_fraction, tint, fainted}` entries
## in party order — the exact shape both `PartyStrip.update_from_party` and
## this file's own selector rows want.
##
## Reads `CombatManager`'s own `_party` array by reflection (`.get("_party")`)
## rather than a formal getter: the manager exposes `switchable_indices()` /
## `request_switch(i)` / `cycle_active()`, all indexed into that exact array,
## and this file is not permitted to add a getter to `combat_manager.gd` for
## this task (its `_active_index` is read the same way, one line below every
## call site above). Reading a script var through `Object.get()` on an
## underscore-prefixed name is the same reflection `combat_manager.gd` itself
## already does elsewhere (`_ally_body.get("species_id")`,
## `creature.get("fainted")` in `autoload/party.gd`) — GDScript's underscore is a
## convention, not enforced privacy. Falls back to `Game.party` if the manager
## is unavailable or (a test harness, say) never got a party at all.
func _party_entries() -> Array:
	var source: Array = []
	if _manager != null:
		var raw: Variant = _manager.get("_party")
		if raw is Array:
			source = raw as Array
	if source.is_empty():
		var game: Node = get_node_or_null(^"/root/Game")
		if game != null:
			var party_auto: Variant = game.get("party")
			if party_auto != null:
				source = party_auto.call("members")

	var entries: Array = []
	for member in source:
		if member == null:
			continue
		entries.append({
			"label": member.label(),
			"level": int(member.level),
			"hp_fraction": member.hp_fraction(),
			"tint": _species_colour(str(member.species_id)),
			"fainted": bool(member.fainted),
		})
	return entries


func _on_creature_switched(_index: int) -> void:
	var creature: RefCounted = _manager.call("active_creature") if _manager != null else null
	_go_text.text = "GO, %s!" % creature.label() if creature != null else ""
	_go_left = 1.2
	if _party_strip != null:
		_party_strip.call("show_strip")


func _tick_go_text(delta: float) -> void:
	if _go_left <= 0.0:
		_go_text.text = ""
		return
	_go_left -= delta


## --- moments (signal-driven) -------------------------------------------------

## A miss has to be legible or it reads as the game dropping the input.
func _on_missed(by_player: bool) -> void:
	_miss_text = "missed — too far, or facing the wrong way" if by_player else "it missed you"
	_miss_left = 0.9


## A throw the game declined to make, and why.
func _on_catch_refused(reason: String) -> void:
	_miss_text = reason
	_miss_left = 1.6


## The pulse half of a shake — the number itself is unreadable text at this
## distance, but a ring expanding at the exact moment the orb rocks is not.
func _on_orb_shook(_index: int) -> void:
	if _capture_reticle != null:
		_capture_reticle.call("play_pulse")


func _on_catch_resolved(success: bool, shakes: int) -> void:
	if _capture_reticle != null:
		_capture_reticle.call("play_success" if success else "play_break")
	if success:
		var foe: RefCounted = _manager.call("enemy")
		_outcome.text = "Caught %s!" % (str(foe.display_name) if foe != null else "it")
		_outcome.add_theme_color_override("font_color", UITokens.TEAL)
		_outcome_left = 2.4
		return
	var most := int(CATCH.config().get("resolve", {}).get("max_shakes_on_failure", 3))
	if shakes >= most:
		_miss_text = "so close — it almost stayed in"
	elif shakes >= 2:
		_miss_text = "it broke out"
	else:
		_miss_text = "not even close — weaken it first"
	_miss_left = 1.8


func _on_exited(outcome: String) -> void:
	match outcome:
		"caught":
			# Already announced by _on_catch_resolved, which knows the name.
			return
		"won":
			_outcome.text = "The wild creature is beaten."
			_outcome.add_theme_color_override("font_color", UITokens.TEAL)
			_set_xp_line()
		"lost":
			_outcome.text = "Your creature is out of the fight."
			_outcome.add_theme_color_override("font_color", UITokens.DANGER)
		"fled":
			_outcome.text = "You backed off."
			_outcome.add_theme_color_override("font_color", UITokens.TEXT_PRIMARY)
		_:
			_outcome.text = ""
	_outcome_left = 2.5


## D30's award, read off the manager for the creature that fought. `last_xp_award`
## is a plain public var, not a function — `.get()` reflection is not needed
## here, but is used anyway for consistency with `_party_entries()` above and
## because `_manager` is typed `Node`, which has no `last_xp_award` of its own
## to autocomplete against.
func _set_xp_line() -> void:
	if _manager == null:
		return
	var creature: RefCounted = _manager.call("active_creature")
	if creature == null:
		_xp_line.text = ""
		return
	var all_awards: Variant = _manager.get("last_xp_award")
	var award: Dictionary = (all_awards as Dictionary).get(creature.label(), {}) if all_awards is Dictionary else {}
	if award.is_empty():
		_xp_line.text = ""
		return
	var xp := int(award.get("xp", 0))
	var levels := int(award.get("levels", 0))
	_xp_line.text = "+%d XP%s" % [xp, "   ·   Lv up!" if levels > 0 else ""]
	_xp_left = 2.4


func _tick_outcome(delta: float) -> void:
	if _outcome_left <= 0.0:
		_outcome.text = ""
		return
	_outcome_left -= delta


func _tick_xp(delta: float) -> void:
	if _xp_left <= 0.0:
		_xp_line.text = ""
		return
	_xp_left -= delta
