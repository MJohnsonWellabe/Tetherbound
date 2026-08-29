extends CanvasLayer

## Reads the fight and draws it. Owns no state of its own.
##
## It used to own a switch cursor and a tap/hold timer: D32 put mid-fight
## switching on a tap of the d-pad and a HELD d-pad opened a five-row party
## selector. CONTROLLER-MAP retired both. The owner directive of 2026-08-22
## bans held-button chords outright, and it merges "cycle party member" and
## "switch which creature you are piloting" into one `party_cycle` press on LB
## — which is also what frees the d-pad to be the hotbar during a fight. The
## selector had no other way in, and `PartyStrip` (already on screen, already
## pinned while a switch is available) shows the same five rows, so it went
## with the chord rather than being left unreachable.
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
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
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

## Horizontal inset for `PartyStrip`, matching `AllyPanel`'s own left inset
## (`combat_hud.tscn`'s `offset_left = 56.0`) so the two columns line up.
const SWITCH_PANEL_X := 56.0

## Clear space kept between the party strip's bottom row and `AllyPanel`'s
## real top edge.
##
## Used to be a single hand-measured rest position, `Vector2(56.0, 380.0)`,
## justified by a comment claiming "430px of clearance covers five rows at
## up to ~80px each" against `AllyPanel`'s top (874px on a 1080-tall canvas).
## Both numbers were already wrong the day they were written —
## `PARTY_STRIP.ROW_SIZE.y` is 96, not ~80, and 380 to 874 is 494px, not
## 430 — and `party_strip.gd`'s own row height grew again since (56 -> 96,
## HUD-EMPHASIS) without anything here noticing: real `TOTAL_HEIGHT` is 540,
## so the fixed 380 sat the strip's bottom row 46px INSIDE `AllyPanel`. That
## is the exact defect a blind visual review caught (DEFECT 1b,
## `shots/ui/10-combat-hud.png`: a half-hidden second panel between
## Brooktail and Tuskroot, a cut-off "Ener…" label bleeding past the strip's
## own right edge). `_party_strip_position()` below replaces the guess with
## real numbers — `AllyPanel`'s actual anchored offset and the strip's own
## actually-measured `size.y` — so the two can only agree from here on, not
## merely agree on the day someone last did the arithmetic by hand.
const SWITCH_PANEL_GAP := 24.0

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

## The always-on party strip (spec 9.4). Built in code, mounted at
## `_party_strip_position()`.
var _party_strip: Control = null

## --- T3-TYPECHART: the per-hit type verdict ---------------------------------
##
## Its own transient widget rather than the `_miss_text` channel every other
## short combat message uses, and the reason is a real defect that channel
## would have introduced: `_draw_grid` sets `_grid_panel.visible = false`
## whenever a message is up. That is correct for a miss or a refused throw --
## rare, and the player should read the message rather than the buttons -- but
## a type verdict fires on EVERY landed hit in a non-neutral matchup, which is
## most hits of most fights once this chart exists. Routed through there it
## would blink the action grid out of the fight almost continuously.
##
## Built in code and mounted on `$Root` rather than added to
## `scenes/combat/combat_hud.tscn`, the same convention `_orb_cluster` and
## `_party_strip` above already follow.
var _effect_banner: Label = null
var _effect_left: float = 0.0

## Clear space kept between the enemy plate's real bottom edge and the verdict
## banner. Enough that the two read as separate elements rather than as one
## overflowing panel.
const EFFECT_BANNER_GAP := 16.0

## How long the verdict stays up. Short: it is confirming a blow the player
## already threw, not asking them to change what they are doing, and a fight
## lands hits faster than a line of text can be read twice.
const EFFECT_BANNER_SECONDS := 0.7

@onready var _root: Control = $Root
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

@onready var _orbs_panel: PanelContainer = $Root/OrbsPanel
@onready var _orbs: Label = $Root/OrbsPanel/OrbsLabel
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
	# `slot_box()`, not `panel_box()`: this plate is 36px tall and `panel_box()`'s
	# 16px content margin on every side would leave 4px for the text itself.
	# `slot_box()` carries no content margin, so the short "Orbs N" string just
	# needs the box tall enough to hold it (already true here), not a smaller
	# margin hand-tuned to fit.
	_orbs_panel.add_theme_stylebox_override("panel", UITokens.slot_box(false))
	for cell in [_cell_quick, _cell_charged, _cell_throw, _cell_switch]:
		(cell as PanelContainer).add_theme_stylebox_override("panel", UITokens.slot_box(false))

	_party_strip = PARTY_STRIP.new()
	$Root.add_child(_party_strip)
	# `set_rest_position()`, not a plain `.position` write: the strip is not
	# visible yet (`party_strip.gd::_ready()` leaves it hidden), so this both
	# snaps `.position` now and records the real `_rest_position` the widget's
	# own reveal/hide tweens target later — a bare `.position` write here would
	# leave `_rest_position` at its `_ready()`-time default and every later
	# reveal would animate back to the wrong spot.
	_party_strip.call("set_rest_position", _party_strip_position())

	_build_orb_cluster()
	_build_effect_banner()

	UITokens.make_text_legible($Root)

	if _manager != null:
		_manager.connect("exited", _on_exited)
		_manager.connect("attack_missed", _on_missed)
		_manager.connect("hit_effectiveness", _on_hit_effectiveness)
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
## `_party_strip` above is already built the same way.
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


## T3-TYPECHART's per-hit verdict banner. See `_effect_banner`'s own comment for
## why it is a separate widget from the `_miss_text` channel.
##
## Sited directly UNDER THE ENEMY PLATE, which is where the player is already
## looking when a hit lands -- the foe's health bar is in the same glance. The
## plate occupies y 32..224 (scenes/combat/combat_hud.tscn), so this sits just
## below it and never overlaps the action grid at the bottom of the screen or
## the ally plate.
##
## Centred and anchored top like the plate it hangs from, so it stays put at
## every handheld aspect ratio rather than drifting with the safe margin.
func _build_effect_banner() -> void:
	_effect_banner = Label.new()
	_effect_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_effect_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_effect_banner.add_theme_font_size_override("font_size", 26)
	_effect_banner.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_effect_banner.offset_left = -280.0
	_effect_banner.offset_right = 280.0
	_effect_banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_effect_banner.visible = false
	$Root.add_child(_effect_banner)
	_position_effect_banner()


## Sit the banner under the enemy plate's REAL bottom edge, not the one
## `combat_hud.tscn`'s offsets declare.
##
## Same trap `_party_strip_position()` below documents at length, hit again
## here: `EnemyPanel` is a `PanelContainer`, so it grows to fit its content and
## a Control forced past its minimum size does not write that growth back to
## its offsets. The .tscn says the plate ends at 224; rendered, it ends around
## 258 — and a banner placed at the authored 232 straddled the plate's bottom
## edge, half on the panel and half on the world, which reads as a layout bug
## rather than as a deliberate element. Caught by actually rendering the frame,
## which is the entire argument for `ralph/conventions.md`'s render-before-done
## rule.
##
## Falls back to the authored offset when called from `_ready()`, before the
## panel has been laid out and while its rect is still degenerate — the same
## fallback, for the same reason, that `_party_strip_position()` keeps.
func _position_effect_banner() -> void:
	if _effect_banner == null:
		return
	var top := 232.0
	if _enemy_panel != null and _enemy_panel.size.y > 1.0:
		top = _enemy_panel.position.y + _enemy_panel.size.y + EFFECT_BANNER_GAP
	_effect_banner.offset_top = top
	_effect_banner.offset_bottom = top + 40.0


## Age the verdict banner out. Same shape as `_tick_go_text`/`_tick_outcome`
## above it: a plain countdown rather than a Tween, because the thing it drives
## is one boolean and a Tween that outlives the fight is how a HUD element gets
## stuck on screen.
func _tick_effect_banner(delta: float) -> void:
	if _effect_left <= 0.0:
		return
	_effect_left = maxf(0.0, _effect_left - delta)
	if _effect_left <= 0.0 and _effect_banner != null:
		_effect_banner.visible = false


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


func _process(delta: float) -> void:
	_tick_outcome(delta)
	_tick_xp(delta)
	_tick_go_text(delta)
	_tick_effect_banner(delta)
	_miss_left = maxf(0.0, _miss_left - delta)
	_draw_prompt()

	var fighting: bool = _manager != null and bool(_manager.call("is_fighting"))
	if not fighting:
		_show_fight(false)
		return

	_show_fight(true)
	_draw_enemy()
	_draw_ally()
	_draw_grid()
	_update_capture_reticle()
	_handle_switch_input()
	_update_party_strip()


func _show_fight(visible_now: bool) -> void:
	_enemy_panel.visible = visible_now
	_ally_panel.visible = visible_now
	_go_text.visible = visible_now
	_orbs_panel.visible = visible_now
	if not visible_now:
		_grid_panel.visible = false
		_aim_row.visible = false
		_catch_row.visible = false
		if _party_strip != null:
			_party_strip.call("set_pinned", false)
		if _orb_cluster != null:
			_orb_cluster.visible = false
		# T3-TYPECHART. Cleared with the rest of the fight, not left to age out
		# on its own timer -- a verdict about a fight that has ended would sit
		# over the world for up to 0.7s after control came back.
		if _effect_banner != null:
			_effect_banner.visible = false
		_effect_left = 0.0
		if _capture_reticle != null:
			_capture_reticle.call("update_target", Vector2.ZERO, 0.0, false)
		_enemy_panel.modulate.a = 1.0
		_grid_panel.modulate.a = 1.0


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


## T3-TYPECHART's readiness tell: the foe's type, plus how the creature the
## player is currently piloting fares into it.
##
## THE ARROW RIDES THE TAG THAT WAS ALREADY THERE. This panel has drawn the
## enemy's type in its type colour since the fight HUD was built; a matchup is
## a fact about that type, so a second widget for it would be a second thing to
## find on a 7-inch handheld mid-fight. Owner-direction section 10 asks for
## readiness communicated without a hard lock, and section 9 for "enough
## information that preparation feels intelligent rather than random" while not
## naming the creature to use -- one arrow on the creature already out says the
## matchup is favoured without ranking the other four.
##
## COLOUR CARRIES THE MATCHUP ONLY WHEN THERE IS ONE. At neutral -- the common
## case, and every fight in the game before this landed -- the tag is exactly
## what it always was: the type word in the type's own colour. When the matchup
## is not neutral the colour switches to the verdict, because colour is the
## fastest channel on screen and the thing that CHANGES deserves it more than
## the thing that is also written in words right beside it. The type is never
## lost: it is the word.
##
## Read at a glance rather than at leisure, which is the constraint a
## real-time, directly-piloted fight puts on every HUD element here.
func _draw_type_tag(foe_type: String) -> void:
	var matchup: int = int(_manager.call("active_matchup"))
	var glyph := ""
	var colour := _type_color(foe_type)
	if matchup > 0:
		glyph = "  ▲"
		colour = UITokens.SUCCESS
	elif matchup < 0:
		glyph = "  ▼"
		colour = UITokens.WARNING
	_enemy_type_tag.text = foe_type.to_upper() + glyph
	_enemy_type_tag.add_theme_color_override("font_color", colour)


func _draw_enemy() -> void:
	var foe: RefCounted = _manager.call("enemy")
	if foe == null:
		return
	_enemy_eyebrow.text = "LEVEL %d" % int(foe.level)
	# `label()`, not `display_name`: for every wild creature in the game those
	# are the same string, because `label()` falls back to the species name
	# whenever there is no nickname. The one creature that has one is the
	# Burrow Warrens guardian (`burrow_warrens.gd::_dress_the_guardian`), which
	# is named so the fight the region is built around does not open with a
	# plate reading the same species word as the three animals in the corridor
	# behind it. Reading `label()` here also means a CAUGHT creature the player
	# has renamed is called what they called it when it is on the other side of
	# a fight, which is the same rule the ally plate above already follows.
	_enemy_name.text = str(foe.label())
	_draw_type_tag(str(foe.creature_type))

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
		_orbs_panel.visible = false
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
	var glyph := INPUT_GLYPH.icon("party_cycle", 34, VERB_READY if ready else VERB_DIMMED)
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
		# The RESOLVED chance, not the last one the aim advertised -- see
		# `combat_manager.gd::last_catch_chance()`. The contract is the one beat
		# in the whole sequence that can tell the player what their placement
		# was worth, and it was showing them the aim's dead-centre figure.
		_capture_reticle.call(
			"play_contract", _last_reticle_screen_pos,
			float(_manager.call("last_catch_chance"))
		)
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
	# `locked` is the fourth argument and it is the point of this pass: the
	# ring used to draw the same way, with the same percentage, whether the
	# player was on the creature or pointing into the grass beside it. See
	# `combat_manager.gd::catch_aim_is_locked()`.
	_capture_reticle.call(
		"update_target", screen_pos, chance, true,
		bool(_manager.call("catch_aim_is_locked"))
	)


## --- switching input (D32 §9.4, remapped by CONTROLLER-MAP) -----------------
##
## One press of `party_cycle` (LB) steps to the next available creature. No
## hold, no selector, no time-slow — the fight keeps running underneath, which
## is why this re-checks `is_aiming` / `is_resolving_catch` every frame rather
## than trusting whatever was true when the fight started.
##
## CONSUMPTION, and its limit: this reads `Input.is_action_just_pressed`
## polling, the same mechanism `CombatManager._read_player_input` already uses
## for every other combat verb. What it can NOT do is stop another poller from
## seeing the same press. That used to matter a great deal — `hotbar_2`/
## `hotbar_3` shared the physical d-pad with the old directional switch actions,
## so a mid-fight switch also ate a satchel slot — and it is exactly the bug
## CONTROLLER-MAP removes: LB is this verb and nothing else, and the d-pad is
## the hotbar and nothing else, in every context including a fight.
func _handle_switch_input() -> void:
	if _manager == null:
		return

	# Aiming and a resolving catch both already own player input elsewhere in
	# the fight (`throw_aim.gd`, the frozen beat around the orb); a switch
	# attempt here would be a second thing reading the same button.
	if bool(_manager.call("is_aiming")) or bool(_manager.call("is_resolving_catch")):
		return

	if not Input.is_action_just_pressed(&"party_cycle"):
		return
	if not bool(_manager.call("can_switch")) or not bool(_manager.call("cycle_active", 1)):
		_refuse_switch()


func _refuse_switch() -> void:
	_miss_text = "locked in — a moment"
	_miss_left = 1.2


## `AllyPanel`'s real top edge minus the strip's own real measured height
## minus `SWITCH_PANEL_GAP`, in the CURRENT canvas's own coordinates —
## `_root.size.y`, not an assumed 1080, the same "derive from the real
## canvas size" fix `playground_hud.gd::_reflow_left_stack()` already applies
## to this exact left-column-above-a-bottom-anchored-panel shape (its own
## header has the derivation for why the Ally's stretched canvas is not
## always 1080 tall). `_ally_panel.offset_top` is negative (bottom-anchored,
## `combat_hud.tscn`), so adding it to the canvas height gives the panel's
## real top in pixels.
func _party_strip_position() -> Vector2:
	# THE PANEL'S REAL TOP, not the one its offsets declare. `AllyPanel` is a
	# bottom-anchored `PanelContainer` with `grow_vertical = 0`, so when its
	# content needs more than the 150px `combat_hud.tscn` gives it, it grows
	# UPWARD -- and a Control forced past its minimum size grows its cached
	# rect without writing that growth back to its offsets (the distinction
	# `smoke_prompt_hotbar_dock.gd`'s own header draws). Measured on the live
	# scene: authored top 874 on a 1080-tall canvas, real top **833**. The
	# roster was being placed against an edge 41px below where the plate
	# actually is, which is the other half of `HIST-013` -- "the active-creature
	# plate composites over the roster's fifth row" -- and no amount of
	# correcting the arithmetic downstream could have found it, because the
	# arithmetic was right about the wrong edge.
	#
	# The authored offset stays as the fallback for exactly one case: this is
	# called from `_ready()` to seed the strip's rest position, before the
	# panel has been laid out and while its rect is still degenerate. Every
	# call after that is from `_update_party_strip()` with a real rect.
	var ally_rect := _ally_panel.get_global_rect()
	var ally_top: float = ally_rect.position.y if ally_rect.size.y > 0.0 \
			else _root.size.y + _ally_panel.offset_top
	var strip_h: float = _party_strip.size.y if _party_strip != null else 0.0
	return Vector2(SWITCH_PANEL_X, ally_top - strip_h - SWITCH_PANEL_GAP)


## Refresh the always-on party strip, pinned while a switch is available.
func _update_party_strip() -> void:
	if _party_strip == null:
		return
	# Cheap every frame (one Vector2 subtraction) and safe to call while the
	# strip is mid-reveal — `set_rest_position()` only snaps `.position` when
	# the widget is not currently visible, so this can never yank it out from
	# under its own tween (same contract `playground_hud.gd`'s identical call
	# already relies on).
	_party_strip.call("set_rest_position", _party_strip_position())
	var entries := _party_entries()
	var active_index: int = int(_manager.get("_active_index")) if _manager != null else 0
	_party_strip.call("update_from_party", entries, active_index)

	var switchable: Array = _manager.call("switchable_indices")
	var available: bool = bool(_manager.call("can_switch")) and not switchable.is_empty()
	_party_strip.call("set_pinned", available)


## The combat party, as `{label, level, hp_fraction, tint, fainted}` entries
## in party order — the exact shape `PartyStrip.update_from_party` wants.
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

## T3-TYPECHART's teaching signal: the hit that just landed was type-advantaged
## or type-disadvantaged, and the player is told at the exact moment it
## mattered.
##
## THIS IS HOW THE CHART IS LEARNED. Nothing anywhere teaches the triangle --
## no tutorial, no matchup screen, and section 9 rules out naming the creature
## to use. What a player gets instead is confirmation: they swung, and the game
## said whether it was the right swing. A dozen fights of that is the chart,
## learned the way a player actually learns one.
##
## Silent at neutral, which is most hits. A banner that fires on every blow is
## a banner nobody reads.
##
## Rides the same transient message channel as `_on_missed` below rather than
## opening a second one. A swing either lands or misses, never both, so the two
## cannot contend for the same event; across swings, whichever spoke last is
## the one still relevant. Deliberately SHORTER-lived than a miss (0.7s against
## 0.9s): a miss is telling the player to change what they are doing, this is
## confirming what they already did.
##
## Phrased from the player's side in both directions -- "you hit a weakness" /
## "it shrugged that off" -- because "WEAK" alone is ambiguous about who is
## weak, and an ambiguous tell in a fast fight is worse than no tell.
func _on_hit_effectiveness(on_enemy: bool, effectiveness: int) -> void:
	if effectiveness == 0 or _effect_banner == null:
		return
	var text := ""
	var colour := UITokens.SUCCESS
	if on_enemy:
		if effectiveness > 0:
			text = "▲  STRONG — you hit a weakness"
		else:
			text = "▼  WEAK — it shrugged that off"
			colour = UITokens.WARNING
	else:
		if effectiveness > 0:
			text = "▼  it hit YOUR weakness"
			colour = UITokens.DANGER
		else:
			text = "▲  your type held — that barely landed"
	_effect_banner.text = text
	_effect_banner.add_theme_color_override("font_color", colour)
	# Re-measured every time it is shown rather than once at build: the plate
	# above it is a PanelContainer whose height follows its content, and the
	# telegraph line inside it appears and disappears during a fight.
	_position_effect_banner()
	_effect_banner.visible = true
	_effect_left = EFFECT_BANNER_SECONDS


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
	if levels <= 0:
		_xp_line.text = "+%d XP" % xp
		_xp_left = 2.4
		return
	# OP11: "level-up must announce identity, level, unlock". The line used to
	# read "+12 XP   ·   Lv up!" -- which announces none of the three. WHOSE
	# level went up is the question a five-creature team makes urgent (the XP
	# is split across everyone who fought, so "Lv up!" over a shared party
	# strip names nobody), and the new NUMBER is the thing a player is actually
	# tracking. Both were already in hand here: `creature.label()` and
	# `creature.level` sit one line above and were simply not being read.
	var line := "%s reached Lv %d" % [creature.label(), int(creature.level)]
	# The unlock, when the same fight bought one. `trait_unlocked()` is the
	# only thing levelling actually opens, and it turns on bond nodes rather
	# than level -- so this is reported when it is true and the creature has a
	# second trait to show for it, not asserted on every level.
	var cfg: Dictionary = PROGRESSION.config()
	# GATE-E: this used to read `creature.get("bond_nodes")`, and `bond_nodes`
	# is a METHOD on creature_instance.gd, not a property. `get()` handed back a
	# Callable, `int(Callable)` is not a constructor, and the whole announcement
	# died at this line with "Invalid call. Nonexistent 'int' constructor" --
	# every trainer fight in the chapter, every time somebody levelled. The
	# level-up line the player is meant to see was never assigned.
	#
	# It survived because tests/test_level_up_announcement.gd asserts on the
	# SOURCE TEXT of this function rather than running it (prompt 33's exact
	# false-positive shape). Found by driving four real fights end to end.
	var nodes := int(creature.call("bond_nodes", cfg)) if creature.has_method("bond_nodes") else 0
	if PROGRESSION.trait_unlocked(nodes, cfg):
		line += "   ·   trait unlocked"
	_xp_line.text = "+%d XP   ·   %s" % [xp, line]
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
