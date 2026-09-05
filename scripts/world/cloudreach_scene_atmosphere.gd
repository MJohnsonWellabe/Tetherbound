extends "res://scripts/world/cloudreach_atmosphere.gd"

## Canonical travelers can be replaced by PhysicalRuntime on a live reload.
## Prune their old references before the base presenter's typed Node loop.
func _apply_bindings(state: Dictionary) -> void:
	for key: String in bindings:
		var valid: Array = []
		for candidate: Variant in bindings[key]:
			if is_instance_valid(candidate):
				valid.append(candidate)
		bindings[key]=valid
	super._apply_bindings(state)
