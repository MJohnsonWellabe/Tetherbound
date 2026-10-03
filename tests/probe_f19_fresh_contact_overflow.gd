extends "res://tests/smoke_f19_campaign_functional.gd"

## Read-only failure observation. The original normal fresh campaign, input,
## route and F17 contact cap remain intact; no partial checkpoint is accepted.
class ContactOverflowObserver:
	extends Node
	const CAP := preload("res://tests/helpers/opening_geometry_navigator.gd").CONTACTS
	var driver: WeakRef
	var captured := false

	func _init() -> void:
		process_physics_priority = 100

	func _physics_process(_delta: float) -> void:
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
