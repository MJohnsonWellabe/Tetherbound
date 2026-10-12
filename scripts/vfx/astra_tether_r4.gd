extends "res://scripts/vfx/move_effect.gd"

## No geometry, material, emission, process or lifecycle overrides. The library
## supplies the complete original water-jet drawing profiles, palette-only edits.
func configure(from: Vector3, to: Vector3, row: Dictionary, context: Dictionary,
		travel: float, config: Dictionary) -> void:
	super.configure(from, to, row, context, travel, config)
	_colour = Color("7755ef")
