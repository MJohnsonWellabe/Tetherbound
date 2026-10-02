extends "res://tests/helpers/f49_portal_travel.gd"

## Preserve the existing real navigation/provider/authority checks. Hold a
## normal button edge through both clocks: world X is read on physics ticks,
## while inventory/credits also read idle frames.
func activate(prompt: Node3D) -> bool:
	# Hall arches face an authored room approach. Reaching their coordinates
	# from the exterior side of the wall does not establish a visible offer.
	# Walk the installed marker through the original capsule navigator first.
	if prompt != null and prompt.get_parent().get_script() == load("res://scripts/world/portal_arch.gd") and _bind():
		var approach := prompt.get_parent().get_parent().get_node_or_null("Approach") as Node3D
		if approach != null:
			var recoveries_before := int(_player.get("_unstick_count"))
			var nav := NAV.new(tree, _player, _rig, _stick)
			var distance := _player.global_position.distance_to(approach.global_position)
			var arrived: bool = await nav.walk_to(approach.global_position, maxi(1200, int(distance * 65.0)), 0.6)
			_stick(0, 0)
			if not arrived or int(_player.get("_unstick_count")) != recoveries_before:
				return _fail("F20 ordinary capsule walk failed to the authored Hall arch approach")
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
			" player_position=", _player.global_position if is_instance_valid(_player) else Vector3.INF,
			" prompt_position=", prompt.global_position if is_instance_valid(prompt) else Vector3.INF,
			" floor=", _player.is_on_floor() if is_instance_valid(_player) else false,
			" offer=", prompt.call("interaction_offer", _player.global_position) if is_instance_valid(prompt) and is_instance_valid(_player) else {},
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
