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

## Health bar colour at full and at empty. The slide between them is the only
## warning the player gets that the fight is going badly, since a placeholder
## capsule cannot look hurt.
const HEALTH_FULL := Color(0.35, 0.62, 0.28)
const HEALTH_LOW := Color(0.72, 0.22, 0.18)
const ENERGY_READY := Color(0.85, 0.70, 0.25)
const ENERGY_FILLING := Color(0.55, 0.48, 0.30)
const TRACK := Color(0.07, 0.07, 0.08, 0.72)

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
@onready var _ally_energy: ProgressBar = $Root/Ally/Energy
@onready var _actions: Label = $Root/Actions
@onready var _prompt: Label = $Root/Prompt
@onready var _outcome: Label = $Root/Outcome


func _ready() -> void:
	_manager = get_node_or_null(manager_path)
	_director = get_node_or_null(director_path)

	_ally_health_fill = _style(HEALTH_FULL)
	_enemy_health_fill = _style(HEALTH_FULL)
	_energy_fill = _style(ENERGY_FILLING)
	_dress(_ally_health, _ally_health_fill)
	_dress(_enemy_health, _enemy_health_fill)
	_dress(_ally_energy, _energy_fill)

	if _manager != null:
		_manager.connect("exited", _on_exited)
		_manager.connect("attack_missed", _on_missed)
	_show_fight(false)


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


func _draw_prompt() -> void:
	if _director == null:
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
		_telegraph.text = "open"
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
	if _miss_left > 0.0:
		_actions.text = _miss_text
		return
	var quick := "[A] Quick" if bool(_manager.call("quick_ready")) else "[ ] Quick"
	var charged := "[X] Charged" if bool(_manager.call("charged_ready")) else "[ ] Charged"
	_actions.text = "%s      %s      [B] Run       move to dodge" % [quick, charged]


## A miss has to be legible or it reads as the game dropping the input.
##
## This is the single most likely complaint about aimed attacks — "I pressed it
## and nothing happened" — and the difference between a bug and a mechanic is
## whether the game says which one it was.
func _on_missed(by_player: bool) -> void:
	_miss_text = "missed — too far, or facing the wrong way" if by_player else "it missed you"
	_miss_left = 0.9


func _on_exited(outcome: String) -> void:
	match outcome:
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
