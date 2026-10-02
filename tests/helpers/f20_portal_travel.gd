extends "res://tests/helpers/f49_portal_travel.gd"

## Preserve the existing real navigation/provider/authority checks. Hold a
## normal button edge through both clocks: world X is read on physics ticks,
## while inventory/credits also read idle frames.
func activate(prompt: Node3D) -> bool:
	var passed := await super.activate(prompt)
	if not passed and tree.current_scene != null:
		var arbiter: Node = tree.current_scene.get_node_or_null("InteractionArbiter")
		var owner := INPUT_OWNER.current(tree)
		print("F20 INPUT TRACE expected=", prompt.get_path() if is_instance_valid(prompt) else "missing",
			" activated=", _activated.get_path() if _activated is Node else str(_activated),
			" winner=", arbiter.call("winning_provider") if arbiter != null else null,
			" enabled=", arbiter.call("enabled") if arbiter != null else false,
			" fight_owns=", arbiter.call("_fight_owns_the_world") if arbiter != null else false,
			" owner=", owner.get_path() if owner != null else "none",
			" dock_complete=", game.world.flags.call("has", "water_civilian_departure_complete"))
	return passed

func tap(action: String) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventAction.new()
		event.action = action
		event.pressed = pressed
		event.strength = 1.0 if pressed else 0.0
		Input.parse_input_event(event)
		for frame in 2:
			await tree.physics_frame
			await tree.process_frame
