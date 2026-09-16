extends RefCounted

## Input is consumed on a later physics boundary, where the production arbiter
## recomputes its winner. A pre-press offer cannot prove which fight started.
static func started_selected_fight(selected: Object, manager: Object) -> bool:
	return is_instance_valid(selected) and is_instance_valid(manager) \
		and manager.has_method("is_fighting") and manager.has_method("enemy_body") \
		and bool(manager.call("is_fighting")) and manager.call("enemy_body") == selected

## Read-only offer identity check; an Engage label alone can name another wild.
static func matches(selected: Object, engageable: Object, director: Object,
		provider: Object, winner: Dictionary, enabled: bool) -> bool:
	return is_instance_valid(selected) and is_instance_valid(director) \
		and selected == engageable and director == provider and enabled \
		and bool(winner.get("actionable", true)) \
		and str(winner.get("label", "")).begins_with("Engage ")


## Four physical approach stances around the live target, away from the initial
## player side first. Caller owns one shared frame budget for every stance.
static func stance(target: Vector3, initial_direction: Vector3, index: int) -> Vector3:
	var direction := Vector3(initial_direction.x, 0.0, initial_direction.z).normalized()
	if direction.length_squared() < 0.5:
		direction = Vector3.RIGHT
	var angles := [0.0, PI / 2.0, -PI / 2.0, PI]
	return target + direction.rotated(Vector3.UP, angles[clampi(index, 0, 3)]) * 1.2
