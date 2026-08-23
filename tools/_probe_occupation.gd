extends SceneTree

## GATE-E-STRONGHOLD-ART diagnostic (scratch): where every occupation prop and
## brazier actually ends up, in landmark-local space, and how each one sits
## against the `gate-close` capture camera. Written because round 5 left a
## large dark bowl filling the bottom-right corner of that frame and no amount
## of reading the config identified which basket it was. Delete once settled.

const OCCUPATION := preload("res://scripts/world/stronghold_occupation.gd")
const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")

## capture_castle_lite.gd's `gate-close`: eye (229.8, -162.8) at +2.5, aimed at
## the tower point (229.8, -144.4) at +2.65. The landmark itself sits at
## (229.8, -144.4), so the camera's LOCAL position is (0, ~2.5, -18.4).
const SITE := Vector2(229.8, -144.4)
const EYE := Vector2(229.8, -162.8)
const EYE_H := 2.5
const TARGET_H := 2.65
const FOV := 70.0


class FakeWorld:
	extends Node3D
	var field: RefCounted = null
	func ground_height_at(x: float, z: float) -> float:
		return field.height_at(x, z)


func _init() -> void:
	_run()


func _run() -> void:
	var field: RefCounted = HEIGHTFIELD.new()
	var world := FakeWorld.new()
	world.field = field
	root.add_child(world)

	var site_y: float = field.height_at(SITE.x, SITE.y)
	var site := Node3D.new()
	site.name = "Landmark"
	site.position = Vector3(SITE.x, site_y, SITE.y)
	world.add_child(site)

	var occupation: Node3D = OCCUPATION.new()
	site.add_child(occupation)
	occupation.call("build", world, 4.2, site.position, 11.0)
	await process_frame

	var eye_local := Vector3(
		EYE.x - SITE.x,
		float(field.height_at(EYE.x, EYE.y)) + EYE_H - site_y,
		EYE.y - SITE.y)
	var target_local := Vector3(0.0, TARGET_H, 0.0)
	var forward := (target_local - eye_local).normalized()
	# Godot's `fov` is the VERTICAL angle at this aspect; the horizontal reach
	# is what decides whether something at the frame's edge is on screen.
	var half_v := deg_to_rad(FOV * 0.5)
	var half_h := atan(tan(half_v) * 16.0 / 9.0)
	print("gate-close eye (local): (%.2f, %.2f, %.2f)  half-h %.1f deg" % [
		eye_local.x, eye_local.y, eye_local.z, rad_to_deg(half_h)])
	print("")

	for holder_name in ["Braziers", "TetherLamps", "Checkpoint"]:
		var holder := occupation.get_node_or_null(NodePath(holder_name))
		if holder == null:
			continue
		print("%s:" % holder_name)
		for child in holder.get_children():
			var node: Node3D = child as Node3D
			if node == null:
				continue
			var to := node.position - eye_local
			var distance := to.length()
			var right := forward.cross(Vector3.UP).normalized()
			var lateral := rad_to_deg(atan2(to.dot(right), to.dot(forward)))
			var behind := to.dot(forward) < 0.0
			var on_screen := (not behind) and absf(lateral) < rad_to_deg(half_h)
			print("  %-16s local (%7.2f, %6.2f, %7.2f)  d %6.2f  lateral %7.1f deg  %s" % [
				node.name, node.position.x, node.position.y, node.position.z,
				distance, lateral,
				("ON SCREEN" if on_screen else ("behind" if behind else "off-edge")),
			])
		print("")
	quit(0)
