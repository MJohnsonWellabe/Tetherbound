extends CanvasLayer

## M1 debug HUD: health, stamina, and the numbers needed to tune movement.
##
## Not the real HUD. GAME_DESIGN.md's interface work comes much later; this
## exists so the owner can answer "sprint too slow" with a number rather than a
## feeling, and so a stamina meter that never moves is visible immediately.
##
## Sized for the Ally: the project authors at 1920x1080 and stretches
## canvas_items, so text set here is at real handheld pixel density.

const READOUT_INTERVAL := 0.1

@export var player_path: NodePath

var _player: CharacterBody3D = null
var _since_readout := 0.0
var _peak_fall := 0.0
var _last_damage := 0.0

@onready var _health_bar: ProgressBar = $Root/Bars/Health
@onready var _stamina_bar: ProgressBar = $Root/Bars/Stamina
@onready var _readout: Label = $Root/Readout


func _ready() -> void:
	_player = get_node_or_null(player_path) as CharacterBody3D
	if _player == null:
		push_warning("HUD has no player; readout will stay empty")
		return
	if _player.has_signal("landed"):
		_player.connect("landed", _on_landed)


func _on_landed(impact_speed: float, damage: float) -> void:
	_peak_fall = maxf(_peak_fall, impact_speed)
	_last_damage = damage


func _process(delta: float) -> void:
	if _player == null:
		return
	var vitals: RefCounted = _player.get("vitals")
	if vitals == null:
		return

	_health_bar.value = vitals.health_fraction() * 100.0
	_stamina_bar.value = vitals.stamina_fraction() * 100.0

	# Throttled: rebuilding this string every frame is wasted work and makes the
	# numbers flicker too fast to read while tuning.
	_since_readout += delta
	if _since_readout < READOUT_INTERVAL:
		return
	_since_readout = 0.0

	var speed: float = _player.call("ground_speed")
	var sprinting: bool = _player.call("is_sprinting")
	var pos: Vector3 = _player.global_position

	_readout.text = "\n".join([
		"M1 movement playground",
		"",
		"speed      %.2f m/s%s" % [speed, "   SPRINT" if sprinting else ""],
		"vertical   %+.2f m/s" % _player.velocity.y,
		"grounded   %s" % ("yes" if _player.is_on_floor() else "NO"),
		"position   %.0f, %.0f, %.0f" % [pos.x, pos.y, pos.z],
		"",
		"stamina    %.0f / %.0f" % [vitals.stamina, vitals.max_stamina],
		"health     %.0f / %.0f" % [vitals.health, vitals.max_health],
		"",
		"worst landing  %.1f m/s  (%.0f damage)" % [_peak_fall, _last_damage],
		"",
		"left stick move / right stick look / A jump / L3 sprint",
	])
