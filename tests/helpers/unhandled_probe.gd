extends Node
## Records whether an InputEventMouseMotion survives GUI handling and reaches
## _unhandled_input. Used by tests/smoke_mouse_look.gd, which cannot assert on
## camera rotation headless: the headless DisplayServer refuses mouse capture,
## Input.mouse_mode reads back VISIBLE, and camera_rig.gd's look guard is
## therefore always false. Delivery is the half that IS provable here, and it is
## the half the bug was actually in.
var seen := false
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		seen = true
