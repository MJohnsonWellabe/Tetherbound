extends "res://scripts/ui/menu_tab.gd"

## The Palworld-style TEAM screen (spec §8): five-slot column, a live 3D
## viewport on the selected creature, and a detail column of moves and bond.
##
## CLAUDE.md: "Player can own only five creatures total" and "Never implement creature
## storage beyond five." This screen therefore draws exactly MAX_CREATURES rows
## whether or not they are filled, and the empty ones say "empty" rather than
## being absent. A list that grows from one row to five hides the cap until the
## player hits it; five rows from the first minute make it a fact of the game.
##
## There is no box, no next page and no scrollbar here, and there is nowhere to
## put a sixth creature. That is the design, not an unfinished screen. When a sixth
## capture happens the answer is the release ceremony (R4.10, spec M5), which
## now lives at the bottom of this file: the five belt rows stay put, a sixth
## row appears below a hairline — visibly NOT one of the belt's holders — and
## the player inspects all six with the same viewport and detail column the
## screen always had, then chooses who goes free. The sixth row is never in
## `_rows` and never reaches `party.add()` until a release has made room.
##
## The row/reorder/set-active machinery below is unchanged from the original
## two-panel layout, on purpose: `tests/smoke_menu.gd` drives `_rows`, `_held`
## and `ACTIVATE_ACTION` directly, proving the wiring reaches
## `party.move()`/`party.set_active()` for real rather than only in a unit
## test. This pass changes what a row LOOKS like and adds the centre/right
## columns; it does not touch how a row is picked up, placed, or activated.

const PARTY := preload("res://autoload/party.gd")
const CREATURE_VIEWPORT := preload("res://scripts/ui/creature_viewport.gd")
const MOVE_DB := preload("res://scripts/creatures/move_db.gd")
const TRAIT_DB := preload("res://scripts/creatures/trait_db.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const EVOLUTION := preload("res://scripts/creatures/evolution.gd")
const INPUT_GLYPH := preload("res://scripts/ui/input_glyph.gd")
## PT-17. `party_seam.gd::set_nickname` is the one place a nickname gets
## written anywhere in the project (the opening beat routes through it too,
## `sequence_director.gd::_give_to_party`) -- the rename verb below reuses it
## rather than assigning `creature.nickname` a second way in a second file.
const PARTY_SEAM := preload("res://scripts/story/party_seam.gd")
## The opening's own naming panel (`scripts/ui/name_prompt.gd`), reused
## verbatim rather than a second text-entry UI -- see `_read_rename()`'s own
## header for the rest.
const NAME_PROMPT_SCENE := preload("res://scenes/ui/name_prompt.tscn")

## Reordering is pick-up-then-place, matching the backpack. Setting the deployed
## creature needs a second verb, and `interact` (E / X) is the one already bound that
## is not doing anything else inside a menu. This agent may not add actions to
## project.godot's input map.
const ACTIVATE_ACTION := "interact"

## R4.6: evolving the focused creature. `backpack_drop` (G / gamepad LB) is a
## menu-only verb borrowing a binding `tab_backpack.gd` owns in a different
## tab — this agent may not add actions to project.godot's input map, and the
## borrow never collides because only one tab is visible/open at once. (R4.4's
## `TEACH_ACTION` borrowed `backpack_split` the same way until OF29 retired
## the auto-teach it drove; see `_read_evolve()`'s neighbouring comment.)
const EVOLVE_ACTION := "backpack_drop"

## R4.7: designate the focused creature as Best Creature. `backpack_drop`
## went to R4.6's `EVOLVE_ACTION` first, so this borrows `creature_recall`
## (R / gamepad D-pad up) instead — `encounter_director.gd`'s only consumer
## of it has no `process_mode` override, so it inherits the game tree's
## pause exactly like `backpack_drop`/`backpack_split` do while a menu is
## open, and cannot fire underneath this screen.
const BEST_ACTION := "creature_recall"

## PT-17: rename the focused creature. A name is otherwise settable exactly
## once, in the opening (`name_prompt.gd`'s only other caller,
## `sequence_director.gd`) -- one mis-navigated press there named a creature
## forever, with no way back. Borrows `backpack_split` (H / gamepad R3) the
## same way `EVOLVE_ACTION`/`BEST_ACTION` above already borrow
## `backpack_drop`/`creature_recall`: this agent may not add actions to
## project.godot's input map, only one menu tab is ever visible at a time,
## and `backpack_split`'s only other reader (`tab_backpack.gd`) is not this
## one. Free to reuse again for the same reason `R4.4`'s retired
## `TEACH_ACTION` already was, per that const's own comment above.
const RENAME_ACTION := "backpack_split"

## `_describe()` appends "G evolve" to this for a creature R4.6's `evolution`
## config actually names -- shown whether or not it is currently eligible,
## the same "always show the verb, explain the refusal on press" shape the
## rest of this screen's verbs use. Teaching is NOT a verb here (OF29): the
## line points at the satchel, where the TM itself now lives and where the
## player picks who learns it.
## "H / R3", not a bare keyboard letter, for the rename segment specifically
## (PT-17) -- CLAUDE.md's controller-first rule: this ships on a 7-inch ROG
## Ally, and a verb shown as a keyboard key alone is a verb a pad player has
## to guess at. The other segments predate that being enforced here.
const DETAIL_HINT_BASE := "A  pick up, then A again to reorder      E / X  send this one out first" \
	+ "      R  set as Best Creature      H / R3  rename      TMs are taught from the backpack"

const HEALTH_FULL := Color(0.35, 0.62, 0.28)
const HEALTH_LOW := Color(0.72, 0.22, 0.18)

const ROW_HEIGHT := 110.0
const ROW_WIDTH := 420.0
const CHIP_SIZE := Vector2(74.0, 74.0)
## The "+10px wider" selected-row cue (spec §8.1): a negative left margin on
## the selected row's wrapper, so it alone pokes past the others rather than
## every row resizing around it.
const SELECTED_POKE := 10.0

const TYPE_ICONS := {
	"ground": preload("res://assets/ui/icons/ui/type_ground.png"),
	"water": preload("res://assets/ui/icons/ui/type_water.png"),
	"air": preload("res://assets/ui/icons/ui/type_air.png"),
}
const BOND_ICON := preload("res://assets/ui/icons/ui/bond.png")

var _header: Label = null
## Button nodes only — see the header note on why `smoke_menu.gd` needs these
## to be castable straight to `Button`, not a wrapper.
var _rows: Array = []
var _row_wraps: Array = []
var _row_chips: Array = []
var _row_names: Array = []
var _row_levels: Array = []
var _row_hp_bars: Array = []
var _row_hp_fills: Array = []
var _row_bond_counts: Array = []
var _row_content: Array = []

var _focused: int = 0
var _held: int = -1

var _viewport: SubViewportContainer = null
var _shown_species: String = ""
## OF27: tracked alongside `_shown_species` for the same reason
## creature_viewport.gd tracks its own `_shiny` -- two party members can share
## a species and disagree on shiny, and the species-only gate would leave the
## wrong one on screen.
var _shown_shiny: bool = false

var _detail_name: Label = null
var _detail_type_icon: TextureRect = null
var _detail_type_label: Label = null
var _detail_hp: Label = null
var _detail_stats: Label = null
var _detail_appraisal: Label = null
var _detail_traits: Label = null
var _detail_xp: Label = null
var _detail_xp_bar: ProgressBar = null
var _move_quick_icon: TextureRect = null
var _move_quick_name: Label = null
var _move_quick_tag: Label = null
var _move_quick_sub: Label = null
var _move_charged_icon: TextureRect = null
var _move_charged_name: Label = null
var _move_charged_tag: Label = null
var _move_charged_sub: Label = null
var _bond_meter: Control = null
var _bond_caption: Label = null
var _best_caption: Label = null
var _detail_status: Label = null
## RichTextLabel, not Label (blind-judge findings #2/#5): the ceremony's one
## instruction ("A this one goes free") used to be the least prominent text
## on screen -- tiny, muted, stacked under a dense stat block -- and every
## button hint in the flow spelled its input as a bare capital letter instead
## of the glyph convention `input_glyph.gd` already establishes everywhere
## else (dialogue, combat, the backpack hotbar). BBCode is what lets this one
## Label-turned-RichTextLabel host both the outside-the-ceremony plain hint
## text (unchanged) and, during the ceremony, a real glyph plus a size/colour
## bump -- see `_describe()`'s own branch below for the two treatments.
var _detail_hint: RichTextLabel = null

var _moves: RefCounted = null
var _traits: RefCounted = null

## --- rename (PT-17) ----------------------------------------------------------

## The creature being renamed, non-null only while `NAME_PROMPT_SCENE` is on
## screen. Guards the other verbs the same way `_evolution_stage`/
## `_release_stage` guard each other -- see those readers' own bail-outs.
var _renaming: RefCounted = null
## A fresh instance per rename rather than a standing child: this tab already
## rebuilds its whole node tree on `build()` (menu reopen), and a scene
## instanced once outside that lifecycle would either leak or dangle. Freed in
## `_on_rename_confirmed()` the moment the name comes back.
var _rename_panel: CanvasLayer = null

## --- evolution ceremony (R4.6) ----------------------------------------------

var _list: VBoxContainer = null
var _detail_panel: Control = null

## "" outside a ceremony, "glow" while the creature is transforming (waiting
## for the player's own confirm press, not a timer — see `_poll_evolution()`'s
## header note on why this is player-paced rather than wall-clock-timed),
## "reveal" once the swap has happened and the new species/name is on screen.
var _evolution_stage: String = ""
var _evolving: RefCounted = null
var _evolution_from_name: String = ""

var _evolution_panel: Control = null
var _evolution_title: Label = null
var _evolution_body: Label = null
var _evolution_hint: Label = null

## --- release ceremony (R4.10) ------------------------------------------------

## "" outside the ceremony. "choose" while the six are on screen and the player
## is looking them over; "confirm" while the farewell question is up for one of
## them; "done" for the player-paced goodbye beat after the release has
## actually happened. Advanced by Button presses rather than a polled confirm
## action on purpose: the choose press and the confirm press share the A
## button, and a polled `menu_confirm` would see the very press that entered
## the beat and resolve a permanent release on it. A Button only fires on a
## fresh press, so each beat costs its own deliberate one.
var _release_stage: String = ""
## Extended index of the creature the farewell question is about: 0..4 a belt
## slot, MAX_CREATURES the newcomer.
var _release_target: int = -1
## Which row the cursor lands on when the ceremony ends — the newcomer's new
## holder when they joined, slot 0 when they were the one released.
var _release_land: int = 0

## The newcomer's row. Deliberately NOT in `_rows`: that array is the five-slot
## contract `smoke_menu.gd` asserts on, and a sixth entry there would be the
## screen quietly growing a sixth slot.
var _pending_wrap: Control = null
var _pending_button: Button = null
var _pending_rule: Control = null
var _pending_caption: Label = null

var _farewell_panel: Control = null
var _farewell_title: Label = null
var _farewell_body: Label = null
var _farewell_keep: Button = null
var _farewell_release: Button = null
var _farewell_done: Button = null
## RichTextLabel for the same reason `_detail_hint` above is: a real B glyph
## instead of a bare letter (defect 5).
var _farewell_hint: RichTextLabel = null


func build() -> void:
	for child in get_children():
		child.queue_free()
	_rows.clear()
	_row_wraps.clear()
	_row_chips.clear()
	_row_names.clear()
	_row_levels.clear()
	_row_hp_bars.clear()
	_row_hp_fills.clear()
	_row_bond_counts.clear()
	_row_content.clear()
	_held = -1
	_shown_species = ""
	_evolution_stage = ""
	_evolving = null
	# A rebuild mid-ceremony (the menu reopening on this tab) drops straight
	# back to "": poll() re-enters the ceremony on its own the moment it sees
	# `Game.pending_catch` is still set, so nothing is lost — and stale stage
	# state pointing at freed nodes would crash the first poll after a rebuild.
	_release_stage = ""
	_release_target = -1
	# Same "rebuild drops the ceremony cleanly" reasoning as the two resets
	# above -- `get_children()` above already queued the panel node itself for
	# freeing (it is a child of this tab), this just drops the dangling
	# reference to it.
	_renaming = null
	_rename_panel = null
	if _moves == null:
		_moves = MOVE_DB.load_default()
	if _traits == null:
		_traits = TRAIT_DB.load_default()

	_header = Label.new()
	_header.add_theme_font_size_override("font_size", UITokens.FONT_HEADING)
	add_child(_header)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(row)

	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 8)
	list.custom_minimum_size = Vector2(ROW_WIDTH + SELECTED_POKE, 0)
	row.add_child(list)
	_list = list

	for i in PARTY.MAX_CREATURES:
		list.add_child(_build_slot_row(i))

	# R4.10: the newcomer's row, below a hairline and a caption so it reads as
	# "beside the belt", never as a sixth holder. Built hidden on every rebuild
	# and shown only for the length of a ceremony.
	_pending_rule = _hairline()
	# WARNING, not the shared `_hairline()` default: blind-judge defect #4 --
	# the choose/inspect beats read as a routine "check my team" screen with no
	# signal this browsing is part of a permanent choice. Tinting the ceremony's
	# own divider (rather than inventing a new banner) is the restrained
	# extension the design record already gestures at.
	(_pending_rule as ColorRect).color = UITokens.WARNING
	_pending_rule.visible = false
	list.add_child(_pending_rule)
	_pending_caption = Label.new()
	# Plain ASCII, same reason `_fill_bar` gives: kenney_future is a display
	# font with no confirmed coverage past ASCII, and a tofu box in the middle
	# of the ceremony's one caption would be worse than a hyphen.
	_pending_caption.text = "JUST CAUGHT - NOT ON THE BELT"
	_pending_caption.add_theme_font_size_override("font_size", UITokens.FONT_TINY)
	# WARNING rather than TEXT_MUTED, same defect #4 tonal cue as the hairline
	# above -- the caption is the first thing naming why a sixth row exists at
	# all, so it is the natural place for the "this is not routine" signal to
	# live, not a new element bolted on elsewhere.
	_pending_caption.add_theme_color_override("font_color", UITokens.WARNING)
	_pending_caption.visible = false
	list.add_child(_pending_caption)
	_pending_wrap = _build_slot_row(PARTY.MAX_CREATURES)
	_pending_wrap.visible = false
	list.add_child(_pending_wrap)

	_viewport = CREATURE_VIEWPORT.new()
	row.add_child(_viewport)

	_detail_panel = _build_detail()
	row.add_child(_detail_panel)

	_evolution_panel = _build_evolution_panel()
	_evolution_panel.visible = false
	row.add_child(_evolution_panel)

	_farewell_panel = _build_farewell_panel()
	_farewell_panel.visible = false
	row.add_child(_farewell_panel)

	UITokens.make_text_legible(self)
	poll()


## One left-column slot: a wrapper (for the selected-row poke) around a
## focusable Button (for `smoke_menu.gd`'s `_rows` contract) around an
## anchored content row (portrait chip, name/level/HP, bond marker) that the
## Button draws neither of on its own.
##
## Index MAX_CREATURES is the ceremony's newcomer row (R4.10): same anatomy,
## same parallel arrays, but the Button lands on `_pending_button` rather than
## in `_rows` — see that var's own comment for why the five-slot array must
## never grow.
func _build_slot_row(index: int) -> Control:
	var wrap := MarginContainer.new()
	_row_wraps.append(wrap)

	var button := Button.new()
	button.custom_minimum_size = Vector2(ROW_WIDTH, ROW_HEIGHT)
	button.clip_text = true
	button.focus_mode = Control.FOCUS_ALL
	var slot := index
	button.pressed.connect(func() -> void: _on_row(slot))
	button.focus_entered.connect(func() -> void: _focused = slot)
	wrap.add_child(button)
	if index < PARTY.MAX_CREATURES:
		_rows.append(button)
	else:
		_pending_button = button

	var content := HBoxContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 14
	content.offset_right = -14
	content.offset_top = 10
	content.offset_bottom = -10
	content.add_theme_constant_override("separation", 14)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(content)
	_row_content.append(content)

	var chip := PanelContainer.new()
	chip.custom_minimum_size = CHIP_SIZE
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(chip)
	_row_chips.append(chip)

	var text_col := VBoxContainer.new()
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	text_col.add_theme_constant_override("separation", 4)
	text_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(text_col)

	var name_label := Label.new()
	name_label.add_theme_font_size_override("font_size", UITokens.FONT_BODY)
	text_col.add_child(name_label)
	_row_names.append(name_label)

	var stat_row := HBoxContainer.new()
	stat_row.add_theme_constant_override("separation", 8)
	text_col.add_child(stat_row)

	var level_label := Label.new()
	level_label.add_theme_font_size_override("font_size", UITokens.FONT_TINY)
	level_label.add_theme_color_override("font_color", UITokens.TEXT_SECONDARY)
	level_label.custom_minimum_size = Vector2(48, 0)
	stat_row.add_child(level_label)
	_row_levels.append(level_label)

	var hp_bar := ProgressBar.new()
	hp_bar.custom_minimum_size = Vector2(150, 8)
	hp_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hp_bar.show_percentage = false
	var hp_fill := StyleBoxFlat.new()
	hp_fill.bg_color = HEALTH_FULL
	hp_fill.corner_radius_top_left = 4
	hp_fill.corner_radius_top_right = 4
	hp_fill.corner_radius_bottom_left = 4
	hp_fill.corner_radius_bottom_right = 4
	hp_bar.add_theme_stylebox_override("fill", hp_fill)
	stat_row.add_child(hp_bar)
	_row_hp_bars.append(hp_bar)
	_row_hp_fills.append(hp_fill)

	var bond_col := VBoxContainer.new()
	bond_col.alignment = BoxContainer.ALIGNMENT_CENTER
	bond_col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bond_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(bond_col)

	var bond_icon := TextureRect.new()
	bond_icon.texture = BOND_ICON
	bond_icon.custom_minimum_size = Vector2(18, 18)
	bond_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	bond_col.add_child(bond_icon)

	var bond_count := Label.new()
	bond_count.add_theme_font_size_override("font_size", UITokens.FONT_TINY)
	bond_count.add_theme_color_override("font_color", UITokens.TEXT_MUTED)
	bond_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bond_col.add_child(bond_count)
	_row_bond_counts.append(bond_count)

	return wrap


func _build_detail() -> Control:
	var panel := VBoxContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(360, 0)
	panel.add_theme_constant_override("separation", 10)

	_detail_name = Label.new()
	_detail_name.add_theme_font_size_override("font_size", UITokens.FONT_TITLE)
	panel.add_child(_detail_name)

	var type_row := HBoxContainer.new()
	type_row.add_theme_constant_override("separation", 8)
	panel.add_child(type_row)
	_detail_type_icon = TextureRect.new()
	_detail_type_icon.custom_minimum_size = Vector2(22, 22)
	_detail_type_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	type_row.add_child(_detail_type_icon)
	_detail_type_label = Label.new()
	_detail_type_label.add_theme_font_size_override("font_size", UITokens.FONT_LABEL)
	_detail_type_label.add_theme_color_override("font_color", UITokens.TEXT_SECONDARY)
	type_row.add_child(_detail_type_label)

	_detail_hp = Label.new()
	_detail_hp.add_theme_font_size_override("font_size", UITokens.FONT_LABEL)
	panel.add_child(_detail_hp)

	_detail_stats = Label.new()
	_detail_stats.add_theme_font_size_override("font_size", UITokens.FONT_LABEL)
	_detail_stats.add_theme_color_override("font_color", UITokens.TEXT_SECONDARY)
	panel.add_child(_detail_stats)

	_detail_appraisal = Label.new()
	_detail_appraisal.add_theme_font_size_override("font_size", UITokens.FONT_TINY)
	_detail_appraisal.add_theme_color_override("font_color", UITokens.TEXT_MUTED)
	panel.add_child(_detail_appraisal)

	_detail_traits = Label.new()
	_detail_traits.add_theme_font_size_override("font_size", UITokens.FONT_TINY)
	_detail_traits.add_theme_color_override("font_color", UITokens.TEXT_MUTED)
	panel.add_child(_detail_traits)

	_detail_xp = Label.new()
	_detail_xp.add_theme_font_size_override("font_size", UITokens.FONT_TINY)
	_detail_xp.add_theme_color_override("font_color", UITokens.TEXT_MUTED)
	panel.add_child(_detail_xp)

	_detail_xp_bar = ProgressBar.new()
	_detail_xp_bar.custom_minimum_size = Vector2(320, 6)
	_detail_xp_bar.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_detail_xp_bar.show_percentage = false
	var xp_fill := StyleBoxFlat.new()
	xp_fill.bg_color = UITokens.TEAL
	xp_fill.corner_radius_top_left = 3
	xp_fill.corner_radius_top_right = 3
	xp_fill.corner_radius_bottom_left = 3
	xp_fill.corner_radius_bottom_right = 3
	_detail_xp_bar.add_theme_stylebox_override("fill", xp_fill)
	panel.add_child(_detail_xp_bar)

	panel.add_child(_hairline())

	var quick := _build_move_row()
	_move_quick_icon = quick[0]
	_move_quick_name = quick[1]
	_move_quick_tag = quick[2]
	_move_quick_sub = quick[3]
	panel.add_child(quick[4])

	panel.add_child(_hairline())

	var charged := _build_move_row()
	_move_charged_icon = charged[0]
	_move_charged_name = charged[1]
	_move_charged_tag = charged[2]
	_move_charged_sub = charged[3]
	panel.add_child(charged[4])

	panel.add_child(_hairline())

	var bond_wrap := VBoxContainer.new()
	bond_wrap.add_theme_constant_override("separation", 4)
	panel.add_child(bond_wrap)

	_bond_meter = load("res://scripts/ui/bond_meter.gd").new()
	bond_wrap.add_child(_bond_meter)

	_bond_caption = Label.new()
	_bond_caption.add_theme_font_size_override("font_size", UITokens.FONT_TINY)
	_bond_caption.add_theme_color_override("font_color", UITokens.TEXT_MUTED)
	bond_wrap.add_child(_bond_caption)

	_best_caption = Label.new()
	_best_caption.add_theme_font_size_override("font_size", UITokens.FONT_TINY)
	_best_caption.add_theme_color_override("font_color", UITokens.WARNING)
	bond_wrap.add_child(_best_caption)

	_detail_status = Label.new()
	_detail_status.add_theme_font_size_override("font_size", UITokens.FONT_LABEL)
	_detail_status.add_theme_color_override("font_color", UITokens.WARNING)
	panel.add_child(_detail_status)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(spacer)

	_detail_hint = RichTextLabel.new()
	_detail_hint.bbcode_enabled = true
	_detail_hint.fit_content = true
	_detail_hint.scroll_active = false
	_detail_hint.shortcut_keys_enabled = false
	_detail_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_detail_hint.add_theme_font_size_override("normal_font_size", UITokens.FONT_TINY)
	_detail_hint.add_theme_color_override("default_color", UITokens.TEXT_MUTED)
	_detail_hint.text = DETAIL_HINT_BASE
	panel.add_child(_detail_hint)

	return panel


## R4.6's ceremony: sits in the same slot `_build_detail()`'s panel occupies
## (swapped by visibility, not rebuilt), so the list column stays hidden and
## the centre `_viewport` stays up and visible throughout -- the player
## watches the live 3D preview change species mid-ceremony via `_describe()`'s
## own existing species-change detection, not a separate effect this file
## has to drive by hand.
func _build_evolution_panel() -> Control:
	var body := VBoxContainer.new()
	body.custom_minimum_size = Vector2(360, 0)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_theme_constant_override("separation", 14)

	_evolution_title = Label.new()
	_evolution_title.add_theme_font_size_override("font_size", UITokens.FONT_TITLE)
	_evolution_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_evolution_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(_evolution_title)

	_evolution_body = Label.new()
	_evolution_body.add_theme_font_size_override("font_size", UITokens.FONT_LABEL)
	_evolution_body.add_theme_color_override("font_color", UITokens.TEXT_SECONDARY)
	_evolution_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_evolution_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(_evolution_body)

	_evolution_hint = Label.new()
	_evolution_hint.add_theme_font_size_override("font_size", UITokens.FONT_TINY)
	_evolution_hint.add_theme_color_override("font_color", UITokens.TEXT_MUTED)
	_evolution_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(_evolution_hint)

	return _panel(body)


## R4.10's farewell panel: sits in the same slot `_build_detail()`'s panel
## occupies, the swap-by-visibility architecture `_build_evolution_panel()`
## established. The belt rows stay VISIBLE beside it on purpose — during the
## question the player is looking at the five they would keep, and during the
## goodbye they watch the belt settle into its final five behind the words.
func _build_farewell_panel() -> Control:
	var body := VBoxContainer.new()
	body.custom_minimum_size = Vector2(360, 0)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_theme_constant_override("separation", 14)

	_farewell_title = Label.new()
	_farewell_title.add_theme_font_size_override("font_size", UITokens.FONT_TITLE)
	_farewell_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_farewell_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(_farewell_title)

	_farewell_body = Label.new()
	_farewell_body.add_theme_font_size_override("font_size", UITokens.FONT_LABEL)
	_farewell_body.add_theme_color_override("font_color", UITokens.TEXT_SECONDARY)
	_farewell_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_farewell_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(_farewell_body)

	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 12)
	body.add_child(gap)

	# "Keep them" first and focused first (`_begin_farewell`): the permanent
	# choice is one deliberate press DOWN from the safe one, never the default
	# under a mashed A.
	_farewell_keep = _farewell_button("Keep them")
	_farewell_keep.pressed.connect(_back_to_choosing)
	body.add_child(_farewell_keep)

	_farewell_release = _farewell_button("Let them go")
	_farewell_release.add_theme_color_override("font_color", UITokens.DANGER)
	_farewell_release.add_theme_color_override("font_focus_color", UITokens.DANGER)
	_farewell_release.add_theme_color_override("font_hover_color", UITokens.DANGER)
	_farewell_release.pressed.connect(_do_release)
	body.add_child(_farewell_release)

	_farewell_done = _farewell_button("Back to the belt")
	_farewell_done.pressed.connect(_end_release)
	body.add_child(_farewell_done)

	# The back-out hint lives IN the panel, not in the shell footer: the
	# six-row list pushes the footer off the bottom of the frame for the
	# length of the ceremony (seen in the R4.10 capture pass), so a hint
	# down there is a hint nobody gets.
	_farewell_hint = RichTextLabel.new()
	_farewell_hint.bbcode_enabled = true
	_farewell_hint.fit_content = true
	_farewell_hint.scroll_active = false
	_farewell_hint.shortcut_keys_enabled = false
	_farewell_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_farewell_hint.text = "%s  keep looking" % INPUT_GLYPH.icon("cancel", 24)
	_farewell_hint.add_theme_font_size_override("normal_font_size", UITokens.FONT_TINY)
	_farewell_hint.add_theme_color_override("default_color", UITokens.TEXT_MUTED)
	_farewell_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(_farewell_hint)

	_fence_farewell_buttons()
	return _panel(body)


func _farewell_button(label: String) -> Button:
	var button := Button.new()
	button.text = label
	button.focus_mode = Control.FOCUS_ALL
	button.custom_minimum_size = Vector2(300, 56)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.add_theme_font_size_override("font_size", UITokens.FONT_BUTTON)
	return button


## One horizontal move row (spec §8.3): "[icon] Name  TAG" on line 1,
## "Power x1.0   Energy +26" (or "Cost 100") on line 2. A row, not a card —
## no panel background, just the hairlines `_build_detail` places around it.
## Returns [icon, name_label, tag_label, sub_label, container].
func _build_move_row() -> Array:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)

	var line1 := HBoxContainer.new()
	line1.add_theme_constant_override("separation", 8)
	box.add_child(line1)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(20, 20)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	line1.add_child(icon)

	var name_label := Label.new()
	name_label.add_theme_font_size_override("font_size", UITokens.FONT_LABEL)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line1.add_child(name_label)

	var tag_label := Label.new()
	tag_label.add_theme_font_size_override("font_size", UITokens.FONT_TINY)
	tag_label.add_theme_color_override("font_color", UITokens.TEXT_MUTED)
	tag_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	line1.add_child(tag_label)

	var sub_label := Label.new()
	sub_label.add_theme_font_size_override("font_size", UITokens.FONT_TINY)
	sub_label.add_theme_color_override("font_color", UITokens.TEXT_SECONDARY)
	box.add_child(sub_label)

	return [icon, name_label, tag_label, sub_label, box]


## A `total`-character fill bar for the appraisal line — `stars` of `*`,
## the rest `-`. Plain ASCII rather than a unicode star glyph: kenney_future
## is a display font with no confirmed coverage for U+2605, and a tofu box
## in place of the rating would be worse than an honest asterisk.
func _fill_bar(stars: int, total: int = 5) -> String:
	var filled := clampi(stars, 0, total)
	return "*".repeat(filled) + "-".repeat(total - filled)


func _hairline() -> Control:
	var line := ColorRect.new()
	line.color = UITokens.BORDER
	line.custom_minimum_size = Vector2(0, 1)
	return line


func first_focus() -> Control:
	# Mid-ceremony, the shell's own select() grabs this AFTER poll() has run
	# and entered the right beat — without these branches it would stomp the
	# ceremony's focus back onto row 0 every time the menu (re)opens.
	if _release_stage == "choose" and _pending_button != null:
		return _pending_button
	if _release_stage == "confirm" and _farewell_keep != null:
		return _farewell_keep
	if _release_stage == "done" and _farewell_done != null:
		return _farewell_done
	return _rows[0] if not _rows.is_empty() else null


## Row count never changes, so nothing here needs rebuilding — reordering
## rewrites the same five buttons. Constant for the same reason the backpack's
## is: a rebuild destroys the focused node and strands a controller.
func revision() -> int:
	return 0


func poll() -> void:
	var party: RefCounted = _party()
	if party == null or _header == null:
		return
	_poll_release()
	_read_activate()
	_read_evolve()
	_read_set_best()
	_read_rename()

	var size: int = int(party.call("size"))
	if _release_stage == "choose" or _release_stage == "confirm":
		var pending := _pending_catch()
		_header.text = "You caught %s.  The belt holds five, and one of the six goes free." % (
			str(pending.call("label")) if pending != null else "one too many"
		)
	elif _release_stage == "done":
		_header.text = "The belt holds five."
	elif bool(party.call("is_full")):
		# Said plainly, and said before it matters. The sixth capture is a
		# ceremony, not an error message, and a player who is surprised by the
		# cap has been let down by this screen.
		_header.text = "Belt  %d / %d      Full. A sixth creature means letting one go." % [size, PARTY.MAX_CREATURES]
	else:
		_header.text = "Belt  %d / %d      %d free" % [size, PARTY.MAX_CREATURES, PARTY.MAX_CREATURES - size]
	if _held >= 0:
		_header.text += "      holding slot %d" % (_held + 1)
	# Blind-judge defect #4: WARNING amber for the whole length of the
	# ceremony, not just the confirm/done beats it already reads as weighty on
	# -- the same "pay attention" tone `_detail_status` already uses elsewhere
	# on this screen, not a new colour invented for this one line.
	_header.add_theme_color_override(
		"font_color", UITokens.WARNING if _release_stage != "" else UITokens.TEXT_PRIMARY
	)

	var cfg: Dictionary = PROGRESSION.config()
	var active: int = int(party.call("active_index"))
	for i in _rows.size():
		_poll_row(i, party, cfg, active, size)
	if _pending_wrap != null and _pending_wrap.visible:
		_poll_row(PARTY.MAX_CREATURES, party, cfg, active, size)

	# During the goodbye beat the viewport belongs to the creature that just
	# left — `_do_release` pointed it there — and `_describe` would wrench it
	# back to whichever row the cursor last touched.
	if _release_stage != "done":
		_describe(_focused, cfg)


func _poll_row(i: int, party: RefCounted, cfg: Dictionary, active: int, size: int) -> void:
	var button: Button = _rows[i] if i < PARTY.MAX_CREATURES else _pending_button
	var creature: RefCounted = _creature_at(i)
	var content: Control = _row_content[i]
	var chip: PanelContainer = _row_chips[i]

	button.button_pressed = i == _held
	var selected := i == _focused
	button.add_theme_stylebox_override("normal", UITokens.slot_box(selected))
	(_row_wraps[i] as MarginContainer).add_theme_constant_override(
		"margin_left", 0 if selected else int(SELECTED_POKE)
	)

	if creature == null:
		button.text = "  %d.  empty" % (i + 1)
		button.add_theme_color_override("font_color", Color(0.38, 0.39, 0.37))
		content.visible = false
		return

	button.text = ""
	content.visible = true

	var species_look: Dictionary = SPECIES.placeholder(str(creature.get("species_id")))
	var chip_box := StyleBoxFlat.new()
	var chip_colour := Color(str(species_look.get("colour", "#888888")))
	if bool(creature.get("fainted")):
		chip_colour = chip_colour.darkened(0.5)
	chip_box.bg_color = chip_colour
	chip_box.corner_radius_top_left = UITokens.RADIUS_SLOT
	chip_box.corner_radius_top_right = UITokens.RADIUS_SLOT
	chip_box.corner_radius_bottom_left = UITokens.RADIUS_SLOT
	chip_box.corner_radius_bottom_right = UITokens.RADIUS_SLOT
	chip.add_theme_stylebox_override("panel", chip_box)

	var marker := " *" if i == active and size > 0 else ""
	if i == int(party.call("best_index")):
		marker += " ★"
	(_row_names[i] as Label).text = "%s%s" % [str(creature.call("label")), marker]
	(_row_names[i] as Label).add_theme_color_override(
		"font_color", HEALTH_LOW if bool(creature.get("fainted")) else UITokens.TEXT_PRIMARY
	)
	(_row_levels[i] as Label).text = "Lv %d" % int(creature.get("level"))

	var fraction: float = float(creature.call("hp_fraction"))
	(_row_hp_bars[i] as ProgressBar).value = fraction * 100.0
	(_row_hp_fills[i] as StyleBoxFlat).bg_color = HEALTH_LOW.lerp(HEALTH_FULL, fraction)

	var nodes: int = int(creature.call("bond_nodes", cfg))
	var total: int = int(cfg.get("bond", {}).get("thresholds", []).size())
	(_row_bond_counts[i] as Label).text = "%d/%d" % [nodes, maxi(total, 1)]


func _describe(index: int, cfg: Dictionary) -> void:
	if _detail_name == null:
		return
	var party: RefCounted = _party()
	var creature: RefCounted = _creature_at(index)

	if creature == null:
		_detail_name.text = "Empty slot"
		_detail_type_icon.texture = null
		_detail_type_label.text = "Nothing here yet."
		_detail_hp.text = ""
		_detail_stats.text = ""
		_detail_appraisal.text = ""
		_detail_traits.text = ""
		_detail_xp.text = ""
		_detail_xp_bar.value = 0.0
		_move_quick_name.text = ""
		_move_quick_sub.text = ""
		_move_quick_tag.text = ""
		_move_quick_icon.texture = null
		_move_charged_name.text = ""
		_move_charged_sub.text = ""
		_move_charged_tag.text = ""
		_move_charged_icon.texture = null
		_bond_meter.call("set_bond", 0, 100, 0, 5)
		_bond_caption.text = ""
		_best_caption.text = ""
		_detail_status.text = ""
		_detail_hint.add_theme_font_size_override("normal_font_size", UITokens.FONT_TINY)
		_detail_hint.add_theme_color_override("default_color", UITokens.TEXT_MUTED)
		_detail_hint.text = DETAIL_HINT_BASE
		if _shown_species != "":
			_shown_species = ""
			_shown_shiny = false
			_viewport.call("set_species", "")
		return

	var species_id := str(creature.get("species_id"))
	var shiny := bool(creature.get("shiny"))
	if species_id != _shown_species or shiny != _shown_shiny:
		_shown_species = species_id
		_shown_shiny = shiny
		_viewport.call("set_species", species_id, shiny)

	var nickname := str(creature.get("nickname")).strip_edges()
	var display_name := str(creature.get("display_name"))
	var shown_name := str(creature.call("label"))
	# The species line only repeats the name when the creature was never renamed,
	# which is exactly when the player wants to be reminded it is a default.
	_detail_name.text = "%s     Lv %d" % [
		shown_name if not nickname.is_empty() else display_name, int(creature.get("level"))
	]

	var creature_type := str(creature.get("creature_type"))
	_detail_type_icon.texture = TYPE_ICONS.get(creature_type, null)
	_detail_type_label.text = creature_type.capitalize()

	_detail_hp.text = "HP  %d / %d" % [
		int(round(float(creature.get("hp")))), int(round(float(creature.get("max_hp"))))
	]
	_detail_stats.text = "ATK %d    DEF %d" % [
		int(round(float(creature.get("attack")))), int(round(float(creature.get("defence"))))
	]

	# GAME_DESIGN.md 11: "show appraisal through stars/bars, not exact IV
	# numbers" — a five-character fill bar, never the raw 0.0-1.0 roll.
	var overall: int = int(creature.call("overall_appraisal_stars", cfg))
	_detail_appraisal.text = "Appraisal  [%s]" % _fill_bar(overall)

	var primary := str(creature.get("trait_primary"))
	var secondary: String = str(creature.call("revealed_trait_secondary", cfg))
	if primary == "":
		_detail_traits.text = ""
	elif secondary == "":
		_detail_traits.text = "Trait: %s" % str(_traits.call("display_name", primary))
	else:
		_detail_traits.text = "Traits: %s, %s" % [
			str(_traits.call("display_name", primary)), str(_traits.call("display_name", secondary))
		]

	var xp: int = int(creature.get("xp"))
	var xp_needed: int = int(creature.call("xp_to_next", cfg))
	# "EXP", not "XP": kenney_future's capital X is a two-bar glyph almost
	# indistinguishable from H at FONT_TINY, and this row sits directly under
	# the real "HP" row — the blind-capture pass genuinely misread "XP 15 /
	# 121" as a second HP line. Spelling it out removes the collision without
	# touching the shared font.
	_detail_xp.text = "EXP  %d / %d" % [xp, xp_needed]
	_detail_xp_bar.value = 0.0 if xp_needed <= 0 else clampf(float(xp) / float(xp_needed), 0.0, 1.0) * 100.0

	_fill_move_row(
		str(creature.get("move_quick")), "QUICK", creature_type,
		_move_quick_icon, _move_quick_name, _move_quick_tag, _move_quick_sub
	)
	_fill_move_row(
		str(creature.get("move_charged")), "CHARGED", creature_type,
		_move_charged_icon, _move_charged_name, _move_charged_tag, _move_charged_sub
	)

	var nodes: int = int(creature.call("bond_nodes", cfg))
	var total: int = int(cfg.get("bond", {}).get("thresholds", []).size())
	var bond_max: int = int(cfg.get("bond", {}).get("max", 100))
	_bond_meter.call("set_bond", int(creature.get("bond")), bond_max, nodes, maxi(total, 1))
	var per_node: float = float(cfg.get("bond", {}).get("effects_per_node", {}).get("attack_scale", 0.0))
	_bond_caption.text = "+%d%% ATK/DEF per node" % int(round(per_node * 100.0))

	# R4.7's Best Creature caption, null-guarded for R4.10's ceremony: during
	# the ceremony `_creature_at()` can hand back the pending sixth catch while
	# `party` itself is unavailable, and `best_index` only ever names a belt
	# slot, so the sixth row can never match it.
	if party != null and index == int(party.call("best_index")):
		var ability: Dictionary = SPECIES.best_creature_ability(species_id)
		var kind := str(ability.get("kind", ""))
		var pct := int(round(float(ability.get("value", 0.0)) * 100.0))
		if kind == "survivability":
			_best_caption.text = "★ Best Creature — %s: +%d%% effective defence" % [
				str(ability.get("id", "")), pct
			]
		elif kind == "energy":
			_best_caption.text = "★ Best Creature — %s: +%d%% energy per quick hit" % [
				str(ability.get("id", "")), pct
			]
		else:
			_best_caption.text = "★ Best Creature"
	else:
		_best_caption.text = ""

	# R4.7's accumulating status list, with R4.10's sixth row folded in. The
	# pending catch is not on the belt, so no belt-relative line (goes out
	# first / Best Creature) can describe it, and `party` may be null while the
	# ceremony still has a creature to show.
	var status_lines: Array[String] = []
	if bool(creature.get("fainted")):
		status_lines.append("Out of the fight.")
	if index >= PARTY.MAX_CREATURES:
		status_lines.append("Not on the belt yet.")
	elif party != null:
		if index == int(party.call("active_index")):
			status_lines.append("Goes out first.")
		if index == int(party.call("best_index")):
			status_lines.append("Best Creature.")
	_detail_status.text = "  ".join(status_lines)

	if _release_stage != "":
		# The ceremony has exactly one verb, and advertising the reorder/
		# activate/teach/evolve hints here would promise four the guards below
		# refuse. Blind-judge defect #2: this is the one instruction that
		# matters most on the choose/inspect beats, so it gets the confirm
		# beat's own visual weight -- a real glyph (not a bare "A"), a body-size
		# font rather than the tiny stat-block size every other hint uses, and
		# WARNING's amber rather than muted grey, the same "pay attention" tone
		# `_detail_status` already reaches for elsewhere on this screen.
		_detail_hint.add_theme_font_size_override("normal_font_size", UITokens.FONT_BODY)
		_detail_hint.add_theme_color_override("default_color", UITokens.WARNING)
		_detail_hint.text = "%s  this one goes free" % INPUT_GLYPH.icon("confirm", 30, UITokens.WARNING)
		return
	_detail_hint.add_theme_font_size_override("normal_font_size", UITokens.FONT_TINY)
	_detail_hint.add_theme_color_override("default_color", UITokens.TEXT_MUTED)
	_detail_hint.text = DETAIL_HINT_BASE
	if not EVOLUTION.requirements(species_id, cfg).is_empty():
		_detail_hint.text += "      G  evolve"


func _fill_move_row(
	move_id: String, tag: String, fallback_type: String,
	icon: TextureRect, name_label: Label, tag_label: Label, sub_label: Label
) -> void:
	if move_id == "" or not bool(_moves.call("has", move_id)):
		name_label.text = "—"
		sub_label.text = ""
		tag_label.text = tag
		icon.texture = TYPE_ICONS.get(fallback_type, null)
		return

	var data: Dictionary = _moves.call("move", move_id)
	name_label.text = str(data.get("display_name", move_id))
	tag_label.text = tag
	icon.texture = TYPE_ICONS.get(str(data.get("type", fallback_type)), null)

	var power: float = float(data.get("power", 1.0))
	if tag == "CHARGED":
		var cost: int = int(data.get("energy_cost", 100))
		sub_label.text = "Power x%.1f   Cost %d" % [power, cost]
	else:
		var gain: int = int(data.get("energy_gain", 0))
		sub_label.text = "Power x%.1f   Energy +%d" % [power, gain]


func _on_row(index: int) -> void:
	# R4.10: while the ceremony is choosing, the row press IS the choice. In
	# any later beat a row press (still reachable by mouse, since the belt
	# stays on screen behind the farewell panel) does nothing at all.
	if _release_stage == "choose":
		_begin_farewell(index)
		return
	if _release_stage != "" or _renaming != null:
		return

	var party: RefCounted = _party()
	if party == null:
		return

	if _held < 0:
		if party.call("at", index) == null:
			say("Nothing in that slot.")
			return
		_held = index
		return

	if _held == index:
		_held = -1
		say("")
		return

	if party.call("at", index) == null:
		say("Nothing to swap with there.")
		return

	party.call("move", _held, index)
	_held = -1
	poll()


## Set who goes out first. A fainted creature refuses, and says so rather than
## silently doing nothing.
##
## Polled from poll() rather than received as an event, for the same reason the
## shell polls: a focused Button eats events, and this verb has to work while
## one is focused — which is always.
func _read_activate() -> void:
	if not visible or menu == null or not bool(menu.call("is_open")):
		return
	if _evolution_stage != "" or _release_stage != "" or _renaming != null:
		return
	if not Input.is_action_just_pressed(ACTIVATE_ACTION):
		return

	var party: RefCounted = _party()
	if party == null:
		return
	var creature: RefCounted = party.call("at", _focused)
	if creature == null:
		say("Nothing in that slot.")
	elif bool(party.call("set_active", _focused)):
		say("%s goes out first." % str(creature.call("label")))
	else:
		say("%s is out of the fight." % str(creature.call("label")))


## R4.7 (GAME_DESIGN.md §12: "Best Creature is meaningful progression, not a
## cosmetic badge"). Unlike `_read_activate()`, a fainted creature is allowed
## — this is a standing title, not "who takes the field next" — and
## `party.set_best()` itself is the toggle: pressing it again on the already-
## flagged slot clears the title.
func _read_set_best() -> void:
	if not visible or menu == null or not bool(menu.call("is_open")):
		return
	# R4.10: the ceremony has exactly one verb, the same reason
	# `_read_activate()`/`_read_evolve()` bail here. `_focused`
	# can also be the sixth row during it, which `party.at()` has no slot for.
	if _release_stage != "" or _renaming != null:
		return
	if not Input.is_action_just_pressed(BEST_ACTION):
		return

	var party: RefCounted = _party()
	if party == null:
		return
	var creature: RefCounted = party.call("at", _focused)
	if creature == null:
		say("Nothing in that slot.")
		return
	party.call("set_best", _focused)
	if int(party.call("best_index")) == _focused:
		say("%s is your Best Creature." % str(creature.call("label")))
	else:
		say("%s is no longer your Best Creature." % str(creature.call("label")))


## PT-17: a name is otherwise settable exactly once, in the opening
## (`name_prompt.gd`'s only other caller, `sequence_director.gd`) -- one
## mis-navigated press there named a creature forever, with no way back. This
## opens the same panel rather than a second text-entry UI, prefilled with
## the creature's current name (`open()`'s `prefill` param) so a stray press
## and an immediate, unedited confirm is a harmless no-op -- `name_prompt.gd`
## has no real cancel (naming is mandatory in the opening, so `menu_cancel`
## there means backspace, not back-out), and prefill is what makes that
## survivable here too, where there IS something to back out to.
func _read_rename() -> void:
	if not visible or menu == null or not bool(menu.call("is_open")):
		return
	if _evolution_stage != "" or _release_stage != "" or _renaming != null:
		return
	if _held >= 0:
		return
	if not Input.is_action_just_pressed(RENAME_ACTION):
		return

	var party: RefCounted = _party()
	var creature: RefCounted = party.call("at", _focused) if party != null else null
	if creature == null:
		say("Nothing in that slot.")
		return

	_renaming = creature
	_rename_panel = NAME_PROMPT_SCENE.instantiate() as CanvasLayer
	add_child(_rename_panel)
	_rename_panel.connect("confirmed", _on_rename_confirmed)
	_rename_panel.call("open", str(creature.get("display_name")), str(creature.call("label")))


func _on_rename_confirmed(chosen: String) -> void:
	if _renaming == null:
		return
	PARTY_SEAM.set_nickname(_renaming, chosen)
	say("Renamed to %s." % chosen)
	_renaming = null
	if _rename_panel != null:
		_rename_panel.queue_free()
		_rename_panel = null
	if _focused >= 0 and _focused < _rows.size():
		(_rows[_focused] as Button).grab_focus()


## R4.4 put a `TEACH_ACTION` here: one press taught the focused creature the
## first known, compatible TM it did not already know, chosen for the player
## by list order. OF29 retires it. The owner's report — "I can pick up a TM
## but it needs to go in my inventory and then I see it's stats and choose
## who to teach it to" — is precisely the complaint that this screen picked
## the TM AND applied it with nothing shown and nothing chosen. Teaching now
## starts from the disc in the satchel (`tab_backpack.gd`, which shows the
## move's stats and opens the same target picker a potion uses), so there is
## no second, silent path here to disagree with it. `DETAIL_HINT_BASE` points
## at the backpack instead of advertising a verb this tab no longer has.


## R4.6: start (or advance) the focused creature's evolution ceremony.
##
## Split into "start" here and "advance" in `_poll_evolution()` rather than
## one function, because a ceremony in progress reads `menu_confirm`
## instead of `EVOLVE_ACTION` -- a fork the tab's single-press verbs
## (`_read_activate()`, `_read_set_best()`) never need, since neither has a
## multi-beat sequence to be mid-way through.
func _read_evolve() -> void:
	if not visible or menu == null or not bool(menu.call("is_open")):
		return
	if _release_stage != "" or _renaming != null:
		return
	if _evolution_stage != "":
		_poll_evolution()
		return
	if _held >= 0:
		return
	if not Input.is_action_just_pressed(EVOLVE_ACTION):
		return

	var party: RefCounted = _party()
	var creature: RefCounted = party.call("at", _focused) if party != null else null
	if creature == null:
		say("Nothing in that slot.")
		return

	var cfg: Dictionary = PROGRESSION.config()
	var result: Dictionary = EVOLUTION.check(creature, cfg, _inventory())
	if not bool(result.get("eligible", false)):
		say(str(result.get("reason", "Cannot evolve right now.")))
		return

	_evolving = creature
	_evolution_from_name = str(creature.call("label"))
	_evolution_stage = "glow"
	menu.call("hold_input", true)
	menu.call("override_footer", "")
	_list.visible = false
	_detail_panel.visible = false
	_evolution_panel.visible = true
	_evolution_title.text = "%s is evolving..." % _evolution_from_name
	_evolution_body.text = ""
	_evolution_hint.text = "A  continue"


## Advances the ceremony one beat per `menu_confirm` press -- player-paced
## rather than a wall-clock timer on purpose. `conventions.md`'s testing
## traps section (and `LP9`'s own investigation) already found this
## project's tick-counted waits decoupling from real time under CPU load;
## a fixed-duration "glow" stage would be exactly that class of bug, in a
## screen this agent has no reason to add it to. The actual transformation
## happens on the FIRST press (species swap, stat recompute, item spend),
## not at ceremony start, so `_describe()`'s already-existing species-change
## detection is what makes the live `_viewport` visibly change mid-ceremony
## -- nothing here talks to the viewport directly.
func _poll_evolution() -> void:
	if not Input.is_action_just_pressed("menu_confirm"):
		return

	if _evolution_stage == "glow":
		var cfg: Dictionary = PROGRESSION.config()
		if not bool(EVOLUTION.evolve(_evolving, cfg, _inventory())):
			say("%s could not evolve." % _evolution_from_name)
			_end_evolution()
			return
		_evolution_stage = "reveal"
		_evolution_title.text = "%s evolved!" % _evolution_from_name
		_evolution_body.text = "%s is now %s." % [_evolution_from_name, str(_evolving.call("label"))]
		_evolution_hint.text = "A  close"
		return

	_end_evolution()


func _end_evolution() -> void:
	_evolving = null
	_evolution_stage = ""
	menu.call("hold_input", false)
	menu.call("override_footer", "")
	_evolution_panel.visible = false
	_list.visible = true
	_detail_panel.visible = true
	if _focused >= 0 and _focused < _rows.size():
		(_rows[_focused] as Button).grab_focus()


## --- release ceremony (R4.10) ------------------------------------------------
##
## The emotional payload of the five-creature rule (GAME_DESIGN.md 3, spec M5:
## "Do not settle for a generic 'delete' dialog"). Three beats, all
## player-paced, all inside the screen the player already knows:
##
##   choose   the five belt rows plus the newcomer's row below the hairline.
##            Full inspection through the same viewport and detail column as
##            always — the decision is made by comparing real creatures, not
##            by reading a list of names. Focus starts on the newcomer: the
##            first question is "is this one worth a holder?"
##   confirm  the farewell question, in the detail column's slot. Focus lands
##            on "Keep them" — letting a creature go forever takes a
##            deliberate stick move, and B backs out to more looking.
##   done     the goodbye. The released creature holds the viewport one last
##            time (`party.remove_at` returns it for exactly this) while the
##            belt rows behind it visibly settle into the final five.
##
## Entered from poll() whenever `Game.pending_catch` is set — the Game
## autoload's `_watch_pending_catch()` guarantees this tab is on screen for
## it. The shell is held deaf the whole time and focus is fenced inside the
## ceremony's own controls: there is no closing, no tab away, no save screen,
## and no sixth creature in `Game.party` at any point in any beat.


func _poll_release() -> void:
	if not visible or menu == null or not bool(menu.call("is_open")):
		return
	if _release_stage == "":
		_maybe_begin_release()
		return
	# choose advances through the row Buttons, confirm/done through the
	# farewell Buttons — see `_release_stage`'s own comment for why presses,
	# not a polled confirm action. Only backing out is polled, backpack-style.
	if _release_stage == "confirm" and Input.is_action_just_pressed("menu_cancel"):
		_back_to_choosing()


func _maybe_begin_release() -> void:
	if _evolution_stage != "" or _renaming != null:
		return
	var pending := _pending_catch()
	if pending == null:
		return
	var party: RefCounted = _party()
	var game := state()
	if party == null or game == null:
		return
	if not bool(party.call("is_full")):
		# Room opened between the catch and the ceremony (a load, a future
		# system). No choice to stage — the newcomer just takes the free
		# holder, said out loud.
		if bool(party.call("add", pending)):
			game.set("pending_catch", null)
			say("%s joins the belt." % str(pending.call("label")))
		return

	_release_stage = "choose"
	_release_target = -1
	_held = -1
	menu.call("hold_input", true)
	menu.call("override_footer", "Up / Down  look them over        A  this one goes free")
	_show_pending_row(true)
	_fence_choose_focus(true)
	if _pending_button != null:
		_pending_button.grab_focus()


## The farewell question for the creature on extended row `index`. Nothing is
## spent here: the party, the newcomer and the seam are all untouched until
## `_do_release`.
func _begin_farewell(index: int) -> void:
	var creature := _creature_at(index)
	if creature == null:
		return
	_release_target = index
	_release_stage = "confirm"

	var label := str(creature.call("label"))
	_farewell_title.text = "Let %s go?" % label
	if index >= PARTY.MAX_CREATURES:
		_farewell_body.text = ("%s was never on the belt. They go back to the meadow, " +
			"and your five keep their holders.") % label
	else:
		var cfg: Dictionary = PROGRESSION.config()
		var nodes: int = int(creature.call("bond_nodes", cfg))
		var total: int = maxi(int(cfg.get("bond", {}).get("thresholds", []).size()), 1)
		var pending := _pending_catch()
		var newcomer := str(pending.call("label")) if pending != null else "the newcomer"
		# Level and bond restated at the moment of the question — the two
		# numbers that say what is being given up, in front of the player at
		# the exact press that gives it up.
		_farewell_body.text = ("Lv %d, bond %d/%d. %s gives up their holder and %s takes it. " +
			"A released creature does not come back.") % [
			int(creature.get("level")), nodes, total, label, newcomer
		]

	_farewell_keep.visible = true
	_farewell_release.visible = true
	_farewell_done.visible = false
	_farewell_hint.visible = true
	_detail_panel.visible = false
	_farewell_panel.visible = true
	# Blind-judge defect #3: the confirm beat's own text already resolves the
	# newcomer's presence in words ("X gives up their holder and NEWCOMER takes
	# it", or the newcomer's own name as the question itself) -- their row in
	# the list is no longer doing any work once the question is up, and left
	# on screen with no other change it read as an unfinished layout rather
	# than a beat. Hiding it here is the exact same move `_do_release()` below
	# already makes for the done beat (also five rows, never reported as dead
	# space), not a new mechanism -- the question narrows focus to the five
	# belt rows the farewell text is actually about, matching D38's own "during
	# the question you look at the five you would keep."
	_show_pending_row(false)
	# Not "B  keep looking" here too: `_farewell_hint` (built above, right next
	# to the buttons it describes) already says this with a real device-aware
	# glyph. A second copy in the shell's own corner footer -- found duplicated,
	# and in two different input conventions (a keyboard Esc glyph down here
	# vs the footer's hardcoded "B"), by a fresh blind pass on this exact beat
	# -- is redundant at best and contradictory at worst.
	#
	# A single space, not "": "" restores the shell's own DEFAULT footer (the
	# full "A Select / B Close / Q/LB Prev tab / Tab/RB Next tab / ..." bar),
	# which is worse than the duplicate it replaces -- most of those verbs are
	# refused while the ceremony holds the shell (`smoke_release.gd`'s own "no
	# close, no tab away"). Same lever the "done" beat below already uses for
	# the identical reason.
	menu.call("override_footer", " ")
	_farewell_keep.grab_focus()


func _back_to_choosing() -> void:
	if _release_stage != "confirm":
		return
	_release_stage = "choose"
	_farewell_panel.visible = false
	_detail_panel.visible = true
	_show_pending_row(true)
	menu.call("override_footer", "Up / Down  look them over        A  this one goes free")
	var back: Button = _pending_button if _release_target >= PARTY.MAX_CREATURES \
		else (_rows[_release_target] as Button)
	_release_target = -1
	if back != null:
		back.grab_focus()


## The one irreversible press in the ceremony. Wired to the "Let them go"
## Button and nothing else.
func _do_release() -> void:
	if _release_stage != "confirm":
		return
	var game := state()
	var party: RefCounted = _party()
	var pending := _pending_catch()
	if game == null or party == null or pending == null:
		_end_release()
		return

	var released: RefCounted = null
	if _release_target >= PARTY.MAX_CREATURES:
		released = pending
		_release_land = 0
	else:
		released = party.call("remove_at", _release_target)
		if released == null:
			push_error("release ceremony chose slot %d but nothing was there" % _release_target)
			_end_release()
			return
		if not bool(party.call("add", pending)):
			# remove_at just made the room, so this cannot refuse — but if it
			# somehow does, the pending seam still holds the newcomer and the
			# ceremony will re-enter rather than lose a creature silently.
			push_error("the freed holder refused %s" % str(pending.call("label")))
			return
		_release_land = maxi(int(party.call("size")) - 1, 0)
	game.set("pending_catch", null)

	var released_label := str(released.call("label"))
	var released_species := str(released.get("species_id"))
	_release_stage = "done"
	_show_pending_row(false)
	_farewell_title.text = "%s goes free." % released_label
	if _release_target >= PARTY.MAX_CREATURES:
		_farewell_body.text = "The meadow takes them back. The belt stays as it was."
	else:
		_farewell_body.text = "The meadow takes them back. %s settles into the empty holder." % \
			str(pending.call("label"))
	_farewell_keep.visible = false
	_farewell_release.visible = false
	_farewell_done.visible = true
	_farewell_hint.visible = false
	# A single space, not "": empty restores the shell's default footer, which
	# advertises "B  Close" — a button that does nothing while the shell is
	# held deaf, seen doing exactly that in the R4.10 capture pass.
	menu.call("override_footer", " ")
	_farewell_done.grab_focus()

	# One last look: the released creature holds the 3D viewport through the
	# goodbye beat. poll() skips `_describe` while stage is "done" so nothing
	# wrenches it away; the belt rows behind it are already showing the final
	# five.
	var released_shiny := bool(released.get("shiny"))
	_shown_species = released_species
	_shown_shiny = released_shiny
	_viewport.call("set_species", released_species, released_shiny)


func _end_release() -> void:
	_release_stage = ""
	_release_target = -1
	menu.call("hold_input", false)
	menu.call("override_footer", "")
	_farewell_panel.visible = false
	_detail_panel.visible = true
	_show_pending_row(false)
	_fence_choose_focus(false)
	var land: int = clampi(_release_land, 0, _rows.size() - 1)
	_release_land = 0
	if land < _rows.size():
		(_rows[land] as Button).grab_focus()


func _show_pending_row(on: bool) -> void:
	if _pending_rule != null:
		_pending_rule.visible = on
	if _pending_caption != null:
		_pending_caption.visible = on
	if _pending_wrap != null:
		_pending_wrap.visible = on


## Keep the controller cursor inside the six rows for the length of the
## ceremony. Without this, ui_up from row 0 escapes to the shell's tab row —
## whose buttons call select(), which un-holds the shell and walks the player
## out of a ceremony that must not be left. Up from the top wraps to the
## newcomer and down from the newcomer wraps to the top, which also makes the
## newcomer one press away from anywhere.
func _fence_choose_focus(on: bool) -> void:
	if _rows.is_empty() or _pending_button == null:
		return
	var top: Button = _rows[0]
	var everyone: Array = _rows.duplicate()
	everyone.append(_pending_button)
	for entry in everyone:
		var row := entry as Button
		row.focus_neighbor_left = row.get_path_to(row) if on else NodePath("")
		row.focus_neighbor_right = row.get_path_to(row) if on else NodePath("")
	top.focus_neighbor_top = top.get_path_to(_pending_button) if on else NodePath("")
	top.focus_previous = top.focus_neighbor_top
	_pending_button.focus_neighbor_bottom = _pending_button.get_path_to(top) if on else NodePath("")
	_pending_button.focus_next = _pending_button.focus_neighbor_bottom


## Same fence for the farewell Buttons: keep/release wrap onto each other,
## the lone done button points every direction at itself.
func _fence_farewell_buttons() -> void:
	for pair in [[_farewell_keep, _farewell_release], [_farewell_release, _farewell_keep]]:
		var it := pair[0] as Button
		var other := pair[1] as Button
		var to_other := it.get_path_to(other)
		it.focus_neighbor_top = to_other
		it.focus_neighbor_bottom = to_other
		it.focus_neighbor_left = it.get_path_to(it)
		it.focus_neighbor_right = it.get_path_to(it)
		it.focus_next = to_other
		it.focus_previous = to_other
	var to_self := _farewell_done.get_path_to(_farewell_done)
	_farewell_done.focus_neighbor_top = to_self
	_farewell_done.focus_neighbor_bottom = to_self
	_farewell_done.focus_neighbor_left = to_self
	_farewell_done.focus_neighbor_right = to_self
	_farewell_done.focus_next = to_self
	_farewell_done.focus_previous = to_self


## The creature the ceremony's extended index space points at: belt slots
## 0..MAX-1 are the party's, MAX is the catch waiting on the seam.
func _creature_at(index: int) -> RefCounted:
	if index >= PARTY.MAX_CREATURES:
		return _pending_catch()
	var party: RefCounted = _party()
	return party.call("at", index) if party != null else null


func _pending_catch() -> RefCounted:
	var game := state()
	return game.get("pending_catch") if game != null else null


func _inventory() -> RefCounted:
	var game := state()
	return game.get("inventory") if game != null else null


func _party() -> RefCounted:
	var game := state()
	return game.get("party") if game != null else null
