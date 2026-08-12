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
## The post is a primitive, not a Quaternius model — there was no signpost
## mesh in the packs vendored when it was built (the farm pack EV6 retired had
## Well/Fence/barns/windmill only; stylized_nature has no sign/post/board
## model). The Medieval Village kit may yield a better post; that is dressing
## work, not this file's mechanic.

const TERRAIN_CONFIG := "res://data/config/terrain_playground.json"

## Tall enough to clear four stacked arms at ARM_START_HEIGHT/ARM_SPACING
## below with a small cap above the topmost one.
## R9.4. Was 3.2, with arms from 2.9 down at 0.75 spacing — a blind critic
## measured the whole assembly against the 1.4m well beside it and called it
## roughly 1.5x oversized, "dominating" the square. Scaled to a fingerpost a
## person could have planted: head just above eye line, arms at chest-to-eye
## height where a sign is actually read.
const POST_HEIGHT := 2.35
const POST_RADIUS := 0.09
const ARM_LENGTH := 0.95
const ARM_HEIGHT := 0.16
const ARM_THICKNESS := 0.05
## Arms stack up the post, closest destination lowest.
##
## R7.1-visual pushed this to 0.75 because the labels were BILLBOARDED and so
## kept facing the camera no matter which way their plank pointed — from
## head-on, differing bearings bought no separation at all and only vertical
## spacing did. That stopped being true when the labels stopped billboarding,
## and R9.4 moved them onto the plank faces, where a label is physically part
## of its own arm and cannot drift onto a neighbour's. The constraint that set
## 0.75 no longer exists, and the old number was making a fingerpost as tall
## as a doorway. Now it only has to clear the plank itself.
const ARM_SPACING := 0.44
const ARM_START_HEIGHT := 2.05
## R9.4. Point size is fixed; `_label_scale()` fits metres-per-pixel to the
## plank instead, so a long destination name shrinks rather than overrunning.
const LABEL_FONT_SIZE := 48

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


## R7.1-visual round 3: the critic caught two arms visually crossing in an X
## near the top of the post in signpost-front, swallowing the apostrophe in
## "Grandpa's House" at the crossing point. Every arm's own local origin sat
## exactly on the post's centreline, so from a viewing angle where two
## opposite-ish bearings compress toward the same screen height, their
## planks radiate from what looks like a single point and visibly overlap.
## Mounting each arm at a small offset around the post's own circumference —
## the golden angle (137.5°) per index, so any arm count spreads evenly
## without needing the total up front — is how a real multi-arm signpost is
## built anyway: separate mounting brackets around the pole, not all four
## arms bolted through the same point.
const ARM_MOUNT_RADIUS := 0.16
const GOLDEN_ANGLE := 2.399963229728653  # 137.5 degrees, in radians


func _add_arm(label: String, origin: Vector2, next: Vector2, index: int) -> void:
	var bearing := (next - origin).normalized()
	var yaw := atan2(bearing.x, bearing.y)
	var mount_angle := float(index) * GOLDEN_ANGLE
	var mount := Vector2(cos(mount_angle), sin(mount_angle)) * ARM_MOUNT_RADIUS

	var arm := Node3D.new()
	arm.name = "Arm_%s" % label.validate_filename()
	arm.position = Vector3(mount.x, ARM_START_HEIGHT - index * ARM_SPACING, mount.y)
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

	# R7.1-visual round 1: the critic named the plank "a plain flat rectangle
	# with no arrowhead... doesn't function as pointing to anything." A
	# 3-sided cylinder is a triangular prism — cheapest possible primitive
	# that reads as a point rather than a blunt end. Smaller and closer to
	# the post than the first attempt (round 2 found it projecting far enough
	# forward, at ARM_LENGTH + 0.4*height, to visually land on a neighbouring
	# arm's billboarded text at some viewing angles).
	var head := MeshInstance3D.new()
	var head_mesh := CylinderMesh.new()
	head_mesh.top_radius = 0.0
	head_mesh.bottom_radius = ARM_HEIGHT * 0.45
	head_mesh.height = ARM_HEIGHT * 0.6
	head_mesh.radial_segments = 3
	head_mesh.material = plank_mat
	head.mesh = head_mesh
	head.rotation.x = deg_to_rad(-90.0)
	head.position = Vector3(0.0, 0.0, ARM_LENGTH + ARM_HEIGHT * 0.25)
	arm.add_child(head)

	# R9.4: the label is PAINTED ON THE PLANK'S TWO BROAD FACES, once each.
	#
	# It used to be a single Label3D sitting on the plank's TOP EDGE
	# (y = ARM_HEIGHT * 0.5) facing along the arm's own +Z. Three separate
	# defects came out of that one placement, and a blind critic found all
	# three: the text "floats above" the plank rather than sitting on it,
	# because the top edge is 0.05m wide and the text is not; long names
	# "overrun both ends of the plank" and hang in open air, because nothing
	# fitted the glyphs to the board; and — the loud one — the text renders
	# MIRRORED from the side you actually read it from. A Label3D faces its
	# own local +Z, the arm's +Z points away from the post, so anyone standing
	# at the junction is looking at the back of the letters.
	#
	# A real signpost solves this by being painted on both faces, and each
	# face reads left-to-right from its own side. That means the word starts
	# at the tip on one face and at the post on the other, which looks wrong
	# written down and is exactly right in the world — it is what every
	# fingerpost on every road does.
	#
	# Local +Z maps to world +X at yaw +90°, so a face turned -90° looks along
	# -X and runs its text post-to-tip; +90° looks along +X and runs tip-to-
	# post. One of each, a hair proud of the plank so they do not z-fight.
	var fit := _label_scale(label)
	for side in [-1.0, 1.0]:
		var text := Label3D.new()
		text.text = label
		text.font_size = LABEL_FONT_SIZE
		text.pixel_size = fit
		text.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		text.no_depth_test = false
		text.rotation.y = side * PI * 0.5
		text.position = Vector3(side * (ARM_THICKNESS * 0.5 + 0.006), 0.0, ARM_LENGTH * 0.5)
		text.modulate = Color("#241a10")
		# R7.1-visual round 1: 0 meant letters vanished wherever a label
		# crossed a dark background (a roof, a shadow) — the critic called
		# this out directly. A light outline holds the dark ink readable
		# against both the pale sky and dark structures, the two backgrounds
		# these labels actually cross.
		text.outline_size = 10
		text.outline_modulate = Color("#f4ecd8")
		arm.add_child(text)


## Metres per font pixel, chosen so the longest label still fits the plank.
##
## The old value was a flat 0.008, which suited "The Road" and sent "Practice
## Meadow" straight off both ends of the board. Fitting to whichever of height
## or width binds first means a new destination name can be any length and the
## sign stays a sign.
func _label_scale(label: String) -> float:
	var by_height := (ARM_HEIGHT * 0.62) / float(LABEL_FONT_SIZE)
	# 0.55 em is a serviceable mean advance for mixed-case Latin text; the
	# 0.86 keeps a margin of board visible at each end rather than filling it
	# edge to edge.
	var glyphs := maxf(1.0, float(label.length()) * 0.55 * float(LABEL_FONT_SIZE))
	var by_width := (ARM_LENGTH * 0.86) / glyphs
	return minf(by_height, by_width)


func _load_paths_config() -> Dictionary:
	var file := FileAccess.open(TERRAIN_CONFIG, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return {}
	return (parsed as Dictionary).get("paths", {})
