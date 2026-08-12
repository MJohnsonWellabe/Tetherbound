extends CanvasLayer

## Reads the fight and draws it. Owns no state of its own.
##
## Everything here is pulled from CombatManager and the two pal instances each
## frame rather than pushed in on signals. A HUD that keeps its own copy of the
## health bar is a HUD that can disagree with the fight, and the first time that
## happens it costs an afternoon.
##
## The exception is the outcome banner, which is driven by the `exited` signal
## because it describes a moment rather than a value.

const PALETTE_PATH := "res://data/config/palette.json"
const INPUT_GLYPH := preload("res://scripts/ui/input_glyph.gd")

## Health bar colour at full and at empty. The slide between them is the only
## warning the player gets that the fight is going badly, since a placeholder
## capsule cannot look hurt.
const HEALTH_FULL := Color(0.35, 0.62, 0.28)
const HEALTH_LOW := Color(0.72, 0.22, 0.18)
const ENERGY_READY := Color(0.85, 0.70, 0.25)
const ENERGY_FILLING := Color(0.55, 0.48, 0.30)
## Nearly opaque. At 0.72 the enemy's health bar showed tree trunks and canopy
## through its interior, which the blind critic read as a rendering fault rather
## than as a style.
const TRACK := Color(0.05, 0.05, 0.06, 0.94)

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

@export var manager_path: NodePath
@export var director_path: NodePath

var _manager: Node = null
var _director: Node = null

var _ally_health_fill: StyleBoxFlat = null
var _enemy_health_fill: StyleBoxFlat = null
var _energy_fill: StyleBoxFlat = null

var _outcome_left: float = 0.0
var _miss_left: float = 0.0
var _miss_text: String = ""

@onready var _enemy_name: Label = $Root/Enemy/Name
@onready var _enemy_health: ProgressBar = $Root/Enemy/Health
@onready var _telegraph: Label = $Root/Enemy/Telegraph
@onready var _ally_box: VBoxContainer = $Root/Ally
@onready var _ally_name: Label = $Root/Ally/Name
@onready var _ally_health: ProgressBar = $Root/Ally/Health
@onready var _ally_energy: ProgressBar = $Root/Ally/EnergyRow/Energy
@onready var _actions: RichTextLabel = $Root/Actions
@onready var _prompt: RichTextLabel = $Root/Prompt
@onready var _outcome: Label = $Root/Outcome
@onready var _orbs: Label = $Root/Orbs
@onready var _reticle: Label = $Root/Reticle


func _ready() -> void:
	_manager = get_node_or_null(manager_path)
	_director = get_node_or_null(director_path)

	_ally_health_fill = _style(HEALTH_FULL)
	_enemy_health_fill = _style(HEALTH_FULL)
	_energy_fill = _style(ENERGY_FILLING)
	_dress(_ally_health, _ally_health_fill)
	_dress(_enemy_health, _enemy_health_fill)
	_dress(_ally_energy, _energy_fill)

	_make_text_legible($Root)

	if _manager != null:
		_manager.connect("exited", _on_exited)
		_manager.connect("attack_missed", _on_missed)
		_manager.connect("catch_refused", _on_catch_refused)
		_manager.connect("catch_resolved", _on_catch_resolved)
		_manager.connect("orb_shook", _on_orb_shook)
	_show_fight(false)


## Outline and shadow every piece of text in the tree, whatever gets added later.
##
## Walked rather than set per node on purpose: the failure being fixed is a label
## somebody adds next month with no override on it, and a list of node paths here
## would not catch that.
func _make_text_legible(node: Node) -> void:
	if node is Label or node is RichTextLabel:
		var control := node as Control
		control.add_theme_constant_override("outline_size", OUTLINE_SIZE)
		control.add_theme_color_override("font_outline_color", OUTLINE)
		control.add_theme_color_override("font_shadow_color", SHADOW)
		control.add_theme_constant_override("shadow_offset_x", int(SHADOW_OFFSET.x))
		control.add_theme_constant_override("shadow_offset_y", int(SHADOW_OFFSET.y))
		control.add_theme_constant_override("shadow_outline_size", 2)
	for child in node.get_children():
		_make_text_legible(child)


func _style(colour: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = colour
	box.corner_radius_top_left = 3
	box.corner_radius_top_right = 3
	box.corner_radius_bottom_left = 3
	box.corner_radius_bottom_right = 3
	return box


func _dress(bar: ProgressBar, fill: StyleBoxFlat) -> void:
	var track := _style(TRACK)
	track.border_width_left = 2
	track.border_width_right = 2
	track.border_width_top = 2
	track.border_width_bottom = 2
	track.border_color = Color(0.02, 0.02, 0.02, 0.85)
	bar.add_theme_stylebox_override("background", track)
	bar.add_theme_stylebox_override("fill", fill)


func _process(delta: float) -> void:
	_tick_outcome(delta)
	_miss_left = maxf(0.0, _miss_left - delta)
	_draw_prompt()

	if _manager == null or not bool(_manager.call("is_fighting")):
		_show_fight(false)
		return

	_show_fight(true)
	_draw_enemy()
	_draw_ally()
	_draw_actions()


func _show_fight(visible_now: bool) -> void:
	$Root/Enemy.visible = visible_now
	_ally_box.visible = visible_now
	_actions.visible = visible_now
	_orbs.visible = visible_now
	# The reticle only exists while aiming. A crosshair sitting on screen during
	# normal combat would promise an aim the game is not taking.
	_reticle.visible = visible_now and _manager != null and bool(_manager.call("is_aiming"))


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


func _draw_enemy() -> void:
	var foe: RefCounted = _manager.call("enemy")
	if foe == null:
		return
	_enemy_name.text = str(foe.display_name)
	var fraction: float = foe.hp_fraction()
	_enemy_health.value = fraction * 100.0
	_enemy_health_fill.bg_color = HEALTH_LOW.lerp(HEALTH_FULL, fraction)

	# The enemy's wind-up and its recovery, in words, because a placeholder
	# capsule has no animation to show either with. Scaffolding for real
	# animation, not a UI decision to keep.
	#
	# The recovery line matters as much as the warning: it is the window the
	# player is meant to punish, and a fight where the opening is invisible
	# teaches people to mash rather than to watch.
	if bool(_manager.call("enemy_is_winding_up")):
		_telegraph.text = "!  incoming — move"
	elif bool(_manager.call("enemy_is_rooted")):
		# Was the bare word `open`, which is the name of a state in the AI and not
		# something to say to a player. It appeared in three survey frames and the
		# blind critic flagged it as a debug string left in the HUD, which is
		# exactly what it was.
		_telegraph.text = "↯  it's open — hit it"
	else:
		_telegraph.text = ""


func _draw_ally() -> void:
	var pal: RefCounted = _manager.call("active_pal")
	if pal == null:
		return
	_ally_name.text = str(pal.display_name)
	var fraction: float = pal.hp_fraction()
	_ally_health.value = fraction * 100.0
	_ally_health_fill.bg_color = HEALTH_LOW.lerp(HEALTH_FULL, fraction)

	var energy: float = pal.energy_fraction()
	_ally_energy.value = energy * 100.0
	_energy_fill.bg_color = ENERGY_READY if pal.can_use_charged() else ENERGY_FILLING


## The verb list, greyed when the verb is unavailable.
##
## Shown permanently rather than learned once. M2's whole job is to find out
## whether the fight is worth repeating, and a player who has forgotten that the
## charged attack exists is answering a different question.
func _draw_actions() -> void:
	var orbs: int = int(_manager.call("orbs_left"))
	_orbs.text = "Orbs  %d" % orbs

	if _miss_left > 0.0:
		_actions.text = "[center]%s[/center]" % _miss_text
		return

	# Aiming has its own verb list. Showing Quick and Charged while the player is
	# looking down a reticle would offer two moves their pal cannot make.
	if bool(_manager.call("is_aiming")):
		_actions.text = "[center]%s     %s     [color=#%s]your pal is undefended[/color][/center]" % [
			_verb("throw", "Throw", true), _verb("cancel", "Cancel", true), VERB_DIMMED
		]
		return

	_actions.text = "[center]%s    %s    %s    %s[/center]" % [
		_verb("quick", "Quick", bool(_manager.call("quick_ready"))),
		_verb("charged", "Charged", bool(_manager.call("charged_ready"))),
		_verb("throw", "Throw", orbs > 0) if orbs > 0 else _verb("throw", "No orbs", false),
		# `combat_run` binds to the identical physical button as `menu_cancel`
		# (Escape / gamepad B) -- reaching for the `cancel` glyph id rather
		# than a near-duplicate `run` entry in input_glyph.gd's GLYPHS dict.
		_verb("cancel", "Run", true),
	]


## One verb in the prompt row: the button, then what it does.
##
## The button glyph is ALWAYS drawn. It used to be replaced by `[ ]` when the
## verb was on cooldown, which put an empty pair of brackets in every combat
## frame and read as a missing icon. Which button does a thing never changes;
## only whether you can press it right now does, and that is what the dimming
## says.
##
## `HD1`: a real device-aware Kenney icon (`input_glyph.gd`) replaces the
## hardcoded Xbox letter this used to print unconditionally -- the owner's
## own reproduction case, `combat_throw` showing "F" to a gamepad player and
## vice versa, lived exactly here.
func _verb(glyph_id: String, label: String, ready: bool) -> String:
	return "[color=#%s]%s %s[/color]" % [
		VERB_READY if ready else VERB_DIMMED, INPUT_GLYPH.icon(glyph_id, 30), label
	]


## A miss has to be legible or it reads as the game dropping the input.
##
## This is the single most likely complaint about aimed attacks — "I pressed it
## and nothing happened" — and the difference between a bug and a mechanic is
## whether the game says which one it was.
func _on_missed(by_player: bool) -> void:
	_miss_text = "missed — too far, or facing the wrong way" if by_player else "it missed you"
	_miss_left = 0.9


## A throw the game declined to make, and why.
##
## Separate from a failed catch on purpose. "It fainted, too late" and "it broke
## out" are different things to have just done, and collapsing them into one
## message teaches the player nothing about which mistake they made.
func _on_catch_refused(reason: String) -> void:
	_miss_text = reason
	_miss_left = 1.6


## Count the wobbles out loud. The shakes come from a decision already made
## (`catch_math.resolve`), so this is showing the player something true — a near
## miss really does shake longer than a hopeless throw.
func _on_orb_shook(index: int) -> void:
	_miss_text = "%s" % "•".repeat(index)
	_miss_left = 0.7


func _on_catch_resolved(success: bool, shakes: int) -> void:
	if success:
		var foe: RefCounted = _manager.call("enemy")
		_outcome.text = "Caught %s!" % (str(foe.display_name) if foe != null else "it")
		_outcome_left = 2.4
		return
	_miss_text = "it broke out" if shakes >= 2 else "not even close"
	_miss_left = 1.6


func _on_exited(outcome: String) -> void:
	match outcome:
		"caught":
			# Already announced by _on_catch_resolved, which knows the name.
			# Overwriting it here would replace the moment with a generic line.
			return
		"won":
			_outcome.text = "The wild pal is beaten."
		"lost":
			_outcome.text = "Your pal is out of the fight."
		"fled":
			_outcome.text = "You backed off."
		_:
			_outcome.text = ""
	_outcome_left = 2.5


func _tick_outcome(delta: float) -> void:
	if _outcome_left <= 0.0:
		_outcome.text = ""
		return
	_outcome_left -= delta
