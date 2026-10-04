extends "res://tests/smoke_f19_campaign_functional.gd"

## Read-only failure observation. The original normal fresh campaign, input,
## route and F17 contact cap remain intact; no partial checkpoint is accepted.
class ContactOverflowObserver:
	extends Node
	const CAP := preload("res://tests/helpers/opening_geometry_navigator.gd").CONTACTS
	const TOURNAMENT := preload("res://scripts/world/tournament.gd")
	const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
	var driver: WeakRef
	var captured := false
	var rest_samples := 0

	func _init() -> void:
		process_physics_priority = 100

	func _physics_process(_delta: float) -> void:
		_observe_paid_camp()
		if captured: return
		var began := Time.get_ticks_usec()
		var world := get_tree().current_scene
		if not is_instance_valid(world): return
		var observer := world.get_node_or_null(^"OpeningProductionObservationHarness")
		if observer == null: return
		var owner := observer.get("navigator") as WeakRef
		var navigator: RefCounted = owner.get_ref() if owner != null else null
		if navigator == null or str(navigator.get("_reason")) != "actual production contact observation cap": return
		var body := world.get_node_or_null(^"Player") as CharacterBody3D
		if body == null or not body.is_inside_tree() or body.process_physics_priority >= process_physics_priority: return
		var prior := 0
		var groups: Array[int] = []
		for slide in mini(CAP, body.get_slide_collision_count()):
			var collision := body.get_slide_collision(slide)
			if collision == null: return
			var count := collision.get_collision_count()
			groups.append(count)
			if prior + count > CAP:
				var index := CAP - prior
				var collider := collision.get_collider(index)
				var actual_driver: SceneTree = driver.get_ref() if driver != null else null
				var record := {"acceptance": false, "original_cap": CAP, "original_guard_unchanged": true,
					"physics_frame": Engine.get_physics_frames(), "reached": str(actual_driver.get("reached")) if actual_driver != null else "",
					"player": _vector(body.global_position), "on_floor": body.is_on_floor(),
					"slide": slide, "point_index": index, "contact_ordinal": CAP + 1,
					"slide_point_counts_through_overflow": groups, "contacts_through_overflow_group": prior + count,
					"collider_path": str((collider as Node).get_path()) if is_instance_valid(collider) and collider is Node else "<raw>",
					"collider_rid": str(collision.get_collider_rid(index)),
					"collider_shape": collision.get_collider_shape_index(index),
					"local_shape_path": str((collision.get_local_shape(index) as Node).get_path()) if collision.get_local_shape(index) is Node else "<raw>",
					"normal": _vector(collision.get_normal(index)), "point": _vector(collision.get_position(index)),
					"swept_depth": collision.get_depth(), "new_physics_queries": 0, "pose_or_input_writes": 0}
				record["observer_own_us"] = Time.get_ticks_usec() - began
				captured = true
				set_physics_process(false)
				call_deferred("_emit", record)
				return
			prior += count

	## The original rest result merges its own generic failure, so it does not
	## expose the nested TAIL stow failure. Observe existing state only; retain
	## no scene/resource references and call no input-provider methods.
	func _observe_paid_camp() -> void:
		if rest_samples >= 32: return
		var actual_driver: SceneTree = driver.get_ref() if driver != null else null
		if actual_driver == null or str(actual_driver.get("reached")) != "paid_camp": return
		var world := get_tree().current_scene
		var game := get_parent()
		if not is_instance_valid(world) or game == null: return
		var began := Time.get_ticks_usec()
		var marshal := world.find_child(TOURNAMENT.marshal_name(), true, false) as Node3D
		var prompt := marshal.get_node_or_null(^"Interactable") if marshal != null else null
		var body := world.get_node_or_null(^"Player") as CharacterBody3D
		var grouped_panels: Array[String] = []
		for panel: Node in get_tree().get_nodes_in_group(INPUT_OWNER.GROUP):
			grouped_panels.append(str(panel.get_path()))
		var record := {"acceptance": false, "physics_frame": Engine.get_physics_frames(),
			"sample": rest_samples, "reached": "paid_camp", "driver_finished": bool(actual_driver.get("finished")),
			"pending_build": str(game.get("pending_build")), "equipped_tool": str(game.get("equipped_tool")),
			"hammer_hotbar_slot": int(game.call("hotbar_slot_of", "hammer")),
			"marshal_name": TOURNAMENT.marshal_name(),
			"marshal_path": str(marshal.get_path()) if marshal != null else "",
			"prompt_path": str(prompt.get_path()) if prompt != null else "",
			"player": _vector(body.global_position) if body != null else [],
			"input_group_members": grouped_panels, "input_owner_methods_called": false,
			"build_cancel_pressed": Input.is_action_pressed(&"build_cancel"),
			"new_physics_queries": 0, "pose_or_input_writes": 0}
		record["observer_own_us"] = Time.get_ticks_usec() - began
		rest_samples += 1
		call_deferred("_emit_paid_camp", record)

	func _emit_paid_camp(record: Dictionary) -> void:
		print("F19 ORIGINAL PAID CAMP STATE " + JSON.stringify(record))

	func _vector(value: Vector3) -> Array[float]:
		return [value.x, value.y, value.z]

	func _emit(record: Dictionary) -> void:
		print("F19 ORIGINAL CONTACT OVERFLOW " + JSON.stringify(record))

func _run() -> void:
	var actual_game := root.get_node_or_null(^"Game")
	if actual_game == null:
		await process_frame
		actual_game = root.get_node_or_null(^"Game")
	if actual_game == null:
		print("F19 CONTACT OVERFLOW observer could not find the actual Game")
		quit(2)
		return
	var observer := ContactOverflowObserver.new()
	observer.name = "F19OriginalContactOverflowObserver"
	observer.driver = weakref(self)
	actual_game.add_child(observer)
	super._run()
