extends Node3D

## A signpost at the village square, one arm per dirt path leaving it.
##
## R7.1: the path network (data/config/terrain_playground.json `paths.routes`)
## already IS the wayfinding spine, but nothing at the junction tells a player
## which route goes where. Built from the same route data the paths are baked
## from — a route's own points give both its label and the bearing its arm
## points along, so a new destination added to the paths config gets a sign
## arm for free instead of needing a second place to describe it.
##
## Placeholder geometry (CLAUDE.md: placeholder is fine to prove a mechanic).
## The post is a primitive, not a Quaternius model — there is no signpost mesh
## in either vendored pack (checked: quaternius_farm has Well/Fence/barns/
## windmill only, stylized_nature has no sign/post/board model).

const TERRAIN_CONFIG := "res://data/config/terrain_playground.json"

## Tall enough to clear four stacked arms at ARM_START_HEIGHT/ARM_SPACING
## below with a small cap above the topmost one.
const POST_HEIGHT := 3.2
const POST_RADIUS := 0.09
const ARM_LENGTH := 1.1
const ARM_HEIGHT := 0.16
const ARM_THICKNESS := 0.05
## Arms stack up the post, closest destination lowest. Spaced wide enough
## that the billboarded labels below do not overlap head-on, the one angle a
## rotated plank cannot separate them at.
##
## R7.1-visual: the blind critic caught this at only 0.5m and called the
## bottom two labels of four "fully unreadable, reduced to fragments" in the
## head-on frame — a Label3D's billboard always faces the camera regardless
## of the arm's own yaw, so from close to head-on, differing bearings buy no
## separation at all and spacing is the only thing that does. Measured against
## the actual label: font_size 28 at pixel_size 0.008 is ~0.22m of glyph
## height alone, before line spacing — 0.5m between anchors left barely a
## gap. 0.85m clears a full label plus breathing room.
const ARM_SPACING := 0.75
const ARM_START_HEIGHT := 2.9

var _placed := 0


## `world` is asked for ground height the same way village.gd is (D09: never
## a raycast). `at` is the junction in world metres.
func build(world: Node, at: Vector2) -> void:
	var cfg := _load_paths_config()
	var routes: Array = cfg.get("routes", [])
	if routes.is_empty():
		return

	var ground: float = float(world.call("ground_height_at", at.x, at.y))
	if is_nan(ground):
		push_error("no ground under the signpost at %.0f, %.0f" % [at.x, at.y])
		return

	position = Vector3(at.x, ground, at.y)

	var post := MeshInstance3D.new()
	post.name = "Post"
	var post_mesh := CylinderMesh.new()
	post_mesh.top_radius = POST_RADIUS
	post_mesh.bottom_radius = POST_RADIUS * 1.15
	post_mesh.height = POST_HEIGHT
	post.mesh = post_mesh
	post.position = Vector3(0.0, POST_HEIGHT * 0.5, 0.0)
	var post_mat := StandardMaterial3D.new()
	post_mat.albedo_color = Color("#6b4a2f")
	post_mat.roughness = 0.85
	post_mesh.material = post_mat
	add_child(post)

	var body := StaticBody3D.new()
	body.name = "Post_Collision"
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = POST_RADIUS * 1.5
	cyl.height = POST_HEIGHT
	shape.shape = cyl
	shape.position = Vector3(0.0, POST_HEIGHT * 0.5, 0.0)
	body.add_child(shape)
	add_child(body)

	var i := 0
	for entry: Variant in routes:
		var route: Dictionary = entry as Dictionary
		var label := str(route.get("label", ""))
		var points: Array = route.get("points", [])
		if label.is_empty() or points.size() < 2:
			continue
		_add_arm(str(label), Vector2(points[0][0], points[0][1]), Vector2(points[1][0], points[1][1]), i)
		i += 1
	_placed = i


func placed() -> int:
	return _placed


func _add_arm(label: String, origin: Vector2, next: Vector2, index: int) -> void:
	var bearing := (next - origin).normalized()
	var yaw := atan2(bearing.x, bearing.y)

	var arm := Node3D.new()
	arm.name = "Arm_%s" % label.validate_filename()
	arm.position = Vector3(0.0, ARM_START_HEIGHT - index * ARM_SPACING, 0.0)
	arm.rotation.y = yaw
	add_child(arm)

	var plank := MeshInstance3D.new()
	var plank_mesh := BoxMesh.new()
	plank_mesh.size = Vector3(ARM_THICKNESS, ARM_HEIGHT, ARM_LENGTH)
	plank.mesh = plank_mesh
	# The arm points AWAY from the post along the route's own bearing, so the
	# plank sits centred on that offset rather than through the post.
	plank.position = Vector3(0.0, 0.0, ARM_LENGTH * 0.5)
	var plank_mat := StandardMaterial3D.new()
	plank_mat.albedo_color = Color("#c8a874")
	plank_mat.roughness = 0.8
	plank_mesh.material = plank_mat
	arm.add_child(plank)

	# R7.1-visual: the critic named the plank "a plain flat rectangle with no
	# arrowhead... doesn't function as pointing to anything." A 3-sided
	# cylinder is a triangular prism — cheapest possible primitive that reads
	# as a point rather than a blunt end.
	var head := MeshInstance3D.new()
	var head_mesh := CylinderMesh.new()
	head_mesh.top_radius = 0.0
	head_mesh.bottom_radius = ARM_HEIGHT * 0.6
	head_mesh.height = ARM_HEIGHT * 0.8
	head_mesh.radial_segments = 3
	head_mesh.material = plank_mat
	head.mesh = head_mesh
	head.rotation.x = deg_to_rad(-90.0)
	head.position = Vector3(0.0, 0.0, ARM_LENGTH + ARM_HEIGHT * 0.4)
	arm.add_child(head)

	var text := Label3D.new()
	text.text = label
	text.font_size = 28
	text.pixel_size = 0.008
	text.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	text.no_depth_test = false
	text.position = Vector3(0.0, ARM_HEIGHT * 0.5 + 0.02, ARM_LENGTH * 0.5)
	text.modulate = Color("#241a10")
	# R7.1-visual: 0 meant letters vanished wherever a label crossed a dark
	# background (a roof, a shadow) — the critic called this out directly. A
	# light outline holds the dark ink readable against both the pale sky and
	# dark structures, the two backgrounds these labels actually cross.
	text.outline_size = 10
	text.outline_modulate = Color("#f4ecd8")
	arm.add_child(text)


func _load_paths_config() -> Dictionary:
	var file := FileAccess.open(TERRAIN_CONFIG, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return {}
	return (parsed as Dictionary).get("paths", {})
