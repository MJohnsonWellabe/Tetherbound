extends SceneTree

## Follow-up to `_probe_detail_shots.gd`: ground height (same raycast-over-
## analytic method `_capture_locations.gd::_surface` uses) at the player
## stand point and at a spread of candidate `back` distances toward the
## camera, for each of the seven shots. Needed because `up_m` in
## `_capture_locations.gd::_frame` is added to the ground UNDER THE CAMERA,
## not under the look point, and this project's own analytic/collision
## heightfields are documented to disagree by metres near uneven ground (the
## mill sits right on the pond's stream carve) -- guessing that number by hand
## here would repeat the exact mistake this sweep exists to stop making.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const BOOT_FRAMES := 90
const BACK_CANDIDATES := [0.0, 1.0, 2.0, 2.5, 3.0, 4.0, 5.0, 6.0, 8.0, 10.0, 12.0, 15.0]

var _world: Node3D = null
var _field: RefCounted = null

const SHOTS := [
	{"site": "02-mill-pond", "label": "wheel", "at": [-390.0, 512.0], "look": [-386.0, 514.0]},
	{"site": "03-quarry", "label": "conduit-head", "at": [399.0, 1809.0], "look": [404.0, 1804.0]},
	{"site": "05-relay-camp", "label": "fire", "at": [237.0, 3678.0], "look": [241.4, 3667.3]},
	{"site": "06-relay", "label": "apparatus", "relay": true, "at": [1.0, -4.0], "look": [7.0, -9.0]},
	{"site": "07-mill-crossing", "label": "yard", "at": [-144.0, 4212.0], "look": [-140.0, 4219.0]},
	{"site": "08-ridge-camp", "label": "fire", "at": [-230.0, 6471.0], "look": [-233.9, 6473.7]},
	{"site": "09-waystop", "label": "bench", "at": [-23.0, 7454.0], "look": [-26.5, 7457.0]},
]


func _init() -> void:
	_run()


func _run() -> void:
	_field = HEIGHTFIELD.new()
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in BOOT_FRAMES:
		await physics_frame
	print("[ground-probe] world up, boot settled\n")

	var relay: Node = _world.get_node_or_null(^"TetherRelay")

	for entry: Variant in SHOTS:
		var shot: Dictionary = entry as Dictionary
		var at: Array = shot["at"] as Array
		var look: Array = shot["look"] as Array
		var eye := Vector2(float(at[0]), float(at[1]))
		var target := Vector2(float(look[0]), float(look[1]))
		if bool(shot.get("relay", false)):
			eye = relay.call("world_of", eye) as Vector2
			target = relay.call("world_of", target) as Vector2
		var toward := (target - eye).normalized()

		print("=== %s-%s  eye(%.2f,%.2f)  look(%.2f,%.2f) ===" % [
			shot["site"], shot["label"], eye.x, eye.y, target.x, target.y])
		print("  ground at eye:  %.2f" % _surface(eye))
		print("  ground at look: %.2f" % _surface(target))
		for back_m: float in BACK_CANDIDATES:
			var cam := eye - toward * back_m
			print("  back=%5.1f  cam(%.2f,%.2f)  ground=%.2f" % [back_m, cam.x, cam.y, _surface(cam)])
		print("")
	quit(0)


func _surface(at: Vector2) -> float:
	var analytic: float = _field.height_at(at.x, at.y)
	var space: PhysicsDirectSpaceState3D = (_world as Node3D).get_world_3d().direct_space_state
	if space == null:
		return analytic
	var query := PhysicsRayQueryParameters3D.create(
		Vector3(at.x, analytic + 400.0, at.y), Vector3(at.x, analytic - 400.0, at.y))
	query.collide_with_areas = false
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return analytic
	return float((hit["position"] as Vector3).y)
