extends "res://tests/test_case.gd"

## F20 co-op (render.yml 37357527445): the host standing at Grandpa hid his
## prompt from a guest behind them, because the line-of-sight ray stopped at
## the host's trainer capsule. Another player's trainer is not a wall; walls
## and every other body still occlude.

const INTERACTABLE := preload("res://scripts/world/interactable.gd")


## Scripted physics: each cast returns the next hit not yet excluded.
class Ray:
	var hits: Array = []
	var casts := 0
	func cast(query: PhysicsRayQueryParameters3D) -> Dictionary:
		casts += 1
		for hit: Dictionary in hits:
			if not query.exclude.has(hit.rid): return hit
		return {}


func _hit(other_player: bool) -> Dictionary:
	var body := Node.new()
	if other_player: body.add_to_group(&"remote_trainer")
	return {"collider": body, "rid": RID(PhysicsServer3D.body_create())}


func _query() -> PhysicsRayQueryParameters3D:
	return PhysicsRayQueryParameters3D.create(Vector3.ZERO, Vector3(4, 0, 0))


func _free(ray: Ray) -> void:
	for hit: Dictionary in ray.hits:
		PhysicsServer3D.free_rid(hit.rid)
		hit.collider.free()


func test_a_clear_line_offers() -> void:
	var ray := Ray.new()
	assert_true(INTERACTABLE.sight_clear(_query(), ray.cast))


func test_partners_on_the_line_are_looked_past() -> void:
	var ray := Ray.new()
	ray.hits = [_hit(true)]
	assert_true(INTERACTABLE.sight_clear(_query(), ray.cast), "a co-op partner between the viewer and Grandpa does not hide him")
	_free(ray)
	ray = Ray.new()
	ray.hits = [_hit(true), _hit(true), _hit(true)]
	assert_true(INTERACTABLE.sight_clear(_query(), ray.cast), "a full party's three other trainers are all looked past")
	_free(ray)


func test_walls_and_other_bodies_still_occlude() -> void:
	var ray := Ray.new()
	ray.hits = [_hit(false)]
	assert_false(INTERACTABLE.sight_clear(_query(), ray.cast), "a wall or any non-player body still occludes")
	_free(ray)
	ray = Ray.new()
	ray.hits = [_hit(true), _hit(false)]
	assert_false(INTERACTABLE.sight_clear(_query(), ray.cast), "a wall behind a partner still occludes")
	_free(ray)


func test_the_look_past_is_bounded() -> void:
	var ray := Ray.new()
	for i in INTERACTABLE.SIGHT_PASSABLE_BODIES + 1: ray.hits.append(_hit(true))
	assert_false(INTERACTABLE.sight_clear(_query(), ray.cast), "more bodies than a party fails closed")
	assert_eq(ray.casts, INTERACTABLE.SIGHT_PASSABLE_BODIES)
	_free(ray)
