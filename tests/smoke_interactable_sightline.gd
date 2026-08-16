extends SceneTree

## Does an interact prompt stop at a wall?
##
##   godot --headless --path . --script tests/smoke_interactable_sightline.gd
##
## A blind playtest finished Grandpa's ENTIRE opening — his story, the pack, the
## starter choice, the naming — from the loft bedroom one floor above him. The
## prompt was ~2.9m away as the crow flies, inside its 4.0m radius
## (data/config/opening.json), and `interactable.gd::interaction_offer()` only
## ever measured `from.distance_to(global_position)`. Nothing in it looked at
## what was in between, so every offer in the game reached through every floor,
## wall and door.
##
## A whole booted playground is the wrong instrument for this: the failure is
## one function's answer given a piece of geometry, and the playground's answer
## depends on where the opening happens to stage people. So this builds the
## geometry by hand — a slab, an interactable, a point to stand at — and asks
## `interaction_offer()` directly. It is a SceneTree test rather than a
## `test_case.gd` unit test because the check is a real
## `PhysicsDirectSpaceState3D.intersect_ray`, which needs a world and a physics
## frame; docs/decisions/D02 keeps the unit harness to pure logic.
##
## The two halves matter equally, and the second is the one that is easy to get
## wrong. Blocking a prompt through a wall is trivial to implement by blocking
## every prompt, including the ones whose OWN body sits between the ray and the
## point it is drawn at — Grandpa's chest is inside Grandpa, and a harvest
## tree's prompt is on the trunk axis. So this asserts refusal AND offer, on the
## same interactable, with only the wall moved.

const INTERACTABLE := preload("res://scripts/world/interactable.gd")

## Physics frames to let a freshly added static body register with the space.
const SETTLE_FRAMES := 6

var _failures: Array[String] = []
var _world: Node3D = null


func _init() -> void:
	_run()


func _run() -> void:
	_world = Node3D.new()
	root.add_child(_world)
	for i in SETTLE_FRAMES:
		await physics_frame

	await _an_open_line_offers()
	await _a_wall_between_refuses()
	await _a_floor_overhead_refuses()
	await _the_prompts_own_body_does_not_block_it()
	await _distance_still_gates()
	_report()


# --- the cases --------------------------------------------------------------


## The control. Everything below is only meaningful if this passes: a test that
## reports "blocked" for a prompt that was never offered in the first place is
## the classic pass-because-the-feature-is-absent.
func _an_open_line_offers() -> void:
	var prompt := _spawn_prompt(Vector3(0.0, 1.0, 0.0))
	var offer: Dictionary = prompt.interaction_offer(Vector3(0.0, 0.0, 3.0))
	if offer.is_empty():
		_fail("nothing between the player and the prompt and it still offered nothing")
	else:
		print("open ground: offered '%s'" % str(offer.get("label", "")))
	prompt.queue_free()
	await physics_frame


## The playtest's bug, in its simplest form.
func _a_wall_between_refuses() -> void:
	var prompt := _spawn_prompt(Vector3(0.0, 1.0, 0.0))
	var wall := _spawn_slab(Vector3(6.0, 4.0, 0.3), Vector3(0.0, 2.0, 1.5))
	for i in SETTLE_FRAMES:
		await physics_frame

	if not prompt.interaction_offer(Vector3(0.0, 0.0, 3.0)).is_empty():
		_fail("a 4m-tall wall stood between the player and the prompt and it offered anyway")
	else:
		print("wall: refused")

	# The same prompt, the same standing point, wall gone. Without this the
	# check above would also pass on an interactable that never offers.
	wall.queue_free()
	for i in SETTLE_FRAMES:
		await physics_frame
	if prompt.interaction_offer(Vector3(0.0, 0.0, 3.0)).is_empty():
		_fail("the wall was removed and the prompt still refuses; it is not the wall doing this")
	else:
		print("wall removed: offered again")
	prompt.queue_free()
	await physics_frame


## The measured shape of the real failure: the player one floor up, the prompt
## below and slightly to the side, well inside the radius. `grandpa_house.gd`
## builds the loft as a 0.25m slab at `FLOOR_H + 0.125`, so those are the
## numbers used here rather than a convenient thick block.
func _a_floor_overhead_refuses() -> void:
	var prompt := _spawn_prompt(Vector3(0.0, 1.0, 0.0), 4.0)
	var slab := _spawn_slab(Vector3(4.6, 0.25, 5.4), Vector3(0.0, 3.325, 0.0))
	for i in SETTLE_FRAMES:
		await physics_frame

	var upstairs := Vector3(1.0, 3.45, 1.8)
	var distance := upstairs.distance_to(prompt.global_position)
	if distance > float(prompt.radius):
		_fail("the upstairs standing point is %.1fm away, outside the %.1fm radius; "
			% [distance, float(prompt.radius)]
			+ "this case would pass on distance alone and prove nothing")
	elif not prompt.interaction_offer(upstairs).is_empty():
		_fail("standing on the loft slab %.1fm above the prompt and it offered through the floor" % distance)
	else:
		print("loft floor: refused at %.1fm through a 0.25m slab" % distance)

	slab.queue_free()
	prompt.queue_free()
	await physics_frame


## The regression this fix is most likely to cause. Grandpa's prompt hangs at
## 0.6 of his height — INSIDE his own collider — and a scattered tree's gather
## prompt sits on the trunk axis inside a cylinder up to 1.1m in radius
## (data/config/vegetation.json). Neither may occlude itself.
func _the_prompts_own_body_does_not_block_it() -> void:
	var prompt := _spawn_prompt(Vector3(0.0, 1.1, 0.0), 4.0)
	# A body centred on the prompt, the way an NPC capsule or a trunk is.
	var trunk := _spawn_slab(Vector3(2.2, 4.0, 2.2), Vector3(0.0, 2.0, 0.0))
	for i in SETTLE_FRAMES:
		await physics_frame

	if prompt.interaction_offer(Vector3(0.0, 0.0, 3.0)).is_empty():
		_fail("a prompt drawn inside its own body refused; every NPC and every "
			+ "harvest tree in the game is this shape")
	else:
		print("own body: still offered")

	trunk.queue_free()
	prompt.queue_free()
	await physics_frame


## The old gate has to survive the new one.
func _distance_still_gates() -> void:
	var prompt := _spawn_prompt(Vector3(0.0, 1.0, 0.0), 4.0)
	if not prompt.interaction_offer(Vector3(0.0, 0.0, 40.0)).is_empty():
		_fail("offered from 40m away; the radius check is gone")
	else:
		print("distance: still refused from 40m")
	prompt.queue_free()
	await physics_frame


# --- building the world -----------------------------------------------------


func _spawn_prompt(at: Vector3, radius: float = 4.0) -> Node3D:
	var prompt: Node3D = INTERACTABLE.new()
	prompt.call("configure", "Talk to Grandpa", radius, true)
	_world.add_child(prompt)
	prompt.global_position = at
	return prompt


func _spawn_slab(size: Vector3, at: Vector3) -> StaticBody3D:
	var box := BoxShape3D.new()
	box.size = size
	var shape := CollisionShape3D.new()
	shape.shape = box
	var body := StaticBody3D.new()
	body.add_child(shape)
	_world.add_child(body)
	body.global_position = at
	return body


# --- reporting --------------------------------------------------------------


func _fail(message: String) -> void:
	_failures.append(message)


func _report() -> void:
	print("")
	if _failures.is_empty():
		print("interactable sight line: OK — blocked by geometry, not by its own body.")
		quit(0)
		return
	for line in _failures:
		print("sight line FAIL: %s" % line)
	quit(1)
