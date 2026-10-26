extends OmniLight3D

## F38 band5_stronghold_approach_1 (close-1024, OFF until judged): the
## courtyard daylight fill's night step-down. All three r1 judges read night
## frames as "lit like day" under the broad day bounce, so this light follows
## the shared clock the way `campfire_glow.gd` and torches do
## (`world_look.gd::is_dark()`, group `day_cycle`): the day values while light,
## a dimmer cool moonlit fill while dark, so the braziers' warm pools carry the
## night. Without a clock it stays at its day values.

var day_energy := 1.0
var day_colour := Color.WHITE
var night_energy := 1.0
var night_colour := Color.WHITE
var _world_look: Node = null
var _dark := false


func configure(day: Dictionary, night: Dictionary) -> void:
	day_energy = float(day.get("energy", light_energy))
	day_colour = Color(str(day.get("colour", "#ffffff")))
	night_energy = float(night.get("energy", day_energy))
	night_colour = Color(str(night.get("colour", day.get("colour", "#ffffff"))))
	_apply()


func _process(_delta: float) -> void:
	if _world_look == null or not is_instance_valid(_world_look):
		_world_look = get_tree().get_first_node_in_group(&"day_cycle")
	var dark := _world_look != null and _world_look.has_method("is_dark") and bool(_world_look.call("is_dark"))
	if dark != _dark:
		_dark = dark
		_apply()


func _apply() -> void:
	light_energy = night_energy if _dark else day_energy
	light_color = night_colour if _dark else day_colour
