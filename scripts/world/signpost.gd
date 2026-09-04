extends Node3D

## A signpost, one arm per dirt path leaving its junction.
##
## R7.1: the path network (data/config/terrain_playground.json `paths.routes`)
## already IS the wayfinding spine, but nothing at the junction tells a player
## which route goes where. Built from the same route data the paths are baked
## from — a route's own points give both its label and the bearing its arm
## points along, so a new destination added to the paths config gets a sign
## arm for free instead of needing a second place to describe it.
##
## OF10-remainder: the village square's is still the only JUNCTION sign (every
## route starts there, so `build()`'s default of "one arm per route in the
## config" is exactly right), but a second use showed up at a route's other
## end — a lone TRAILHEAD marker where a road stops, with one arm continuing
## that route's own label and bearing rather than every route in the file.
## `build()`'s new `routes_override` parameter reuses every line below this
## point (post, arms, mirrored labels) for that case: pass an explicit
## `[{label, points}]` instead of `null` and the config load is skipped
## entirely. `data/config/terrain_playground.json`'s `paths.trailheads` is
## where those are authored; `playground_world.gd` turns each entry into one
## more `Signpost.new()` the same way it does the junction one.
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
## GF-B-013: 0.95 -> 1.20, and the board 0.16 -> 0.24 deep.
##
## `_label_scale()` fits the text to the board, so the board's dimensions ARE
## the label's size. At 0.95 x 0.16 the two constraints bound almost exactly
## together for a real destination name -- "Watchtower Spur" fitted at 0.00261
## m/px by width and 0.00207 by height -- which put ~7cm letters on a sign the
## player is expected to read at walking speed from the approach. Gate F's band-4
## frame shows the result: the name reads as a smear.
##
## Still a fingerpost a person could have planted. R9.4 cut this whole assembly
## down after a blind critic measured it at ~1.5x oversized against the 1.4m
## well beside it, and that ruling stands -- `POST_HEIGHT` is untouched at 2.35,
## and a 0.24m board on a 2.35m post is the proportion real fingerposts carry.
## The four arms still clear each other at `ARM_SPACING` (0.44 - 0.24 = 0.20m of
## air between boards) and the topmost still sits under the post cap.
const ARM_LENGTH := 1.20
const ARM_HEIGHT := 0.24
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
##
## BAND1-DISCOVERY-0903: was 48. `docs/VISUAL_BIBLE.md` §4 item 8 names the
## surviving defect precisely -- "signpost text is a `Label3D` resolution
## smear" -- and it is a resolution problem, not a sizing one: `_label_scale()`
## below sets `pixel_size` to `k / LABEL_FONT_SIZE` for both its board-height
## and board-width fits, so the WORLD-SPACE size of a letter (`font_size *
## pixel_size`) stays the same regardless of what `LABEL_FONT_SIZE` is -- only
## the glyph atlas's own raster resolution changes. At 48px a Label3D bakes an
## 'm' at well under 48px tall net of ascender/descender padding, then that
## same texture is magnified onto a physical board the player reads from a
## few metres away; the letterforms blur exactly the way any low-res texture
## does when a camera gets close to it. 3x raises the atlas resolution without
## moving a single mesh, sign, or route -- the board stays the same size in
## the world, and `outline_size` below is scaled by the same 3x so the ratio
## GF-B-013 tuned (outline as a fraction of the em) is unchanged.
const LABEL_FONT_SIZE := 144

var _placed := 0


## `world` is asked for ground height the same way village.gd is (D09: never
## a raycast). `at` is the junction in world metres.
##
## `routes_override`: `null` (the default) loads every route in
## `paths.routes`, the junction behaviour above. Pass an explicit
## `[{label, points}]` array instead to draw only those arms — a trailhead
## marker with one arm, not every destination in the game.
func build(world: Node, at: Vector2, routes_override: Variant = null) -> void:
	var routes: Array = routes_override if routes_override != null else _load_paths_config().get("routes", [])
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

	_build_base_dressing(at)

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


## G3-BAND1-FINISH-0904, docs/VISUAL_BIBLE.md gap list / GATE2-EVIDENCE-0903
## 2.13: "signposts as set dressing rather than bare posts". Every signpost in
## the game (the village junction and every trailhead alike, since this is the
## one file both go through) stood as a single primitive planted straight into
## grass with nothing around its foot — correct as a MECHANISM (R7.1's own
## header: "placeholder is fine to prove a mechanic"), but read as generated
## rather than placed, the exact complaint the judge's `_why` list groups with
## the scatter regularity findings. A small worked stone base — the kind of
## thing whoever dug the post hole would have packed the ground with — is the
## cheapest primitive-only fix that says "someone planted this" without a new
## mesh: a handful of low, irregular stone blocks in a loose ring, not a
## perfect circle (regularity is the thing being fixed), sized and jittered
## from a hash of the post's own world position so two signposts never carry
## the same little pile and a re-render is stable frame to frame.
const BASE_STONE_COUNT := 6
const BASE_STONE_RADIUS := 0.34
const BASE_STONE_SIZE := 0.11


func _build_base_dressing(at: Vector2) -> void:
	var stone_mat := StandardMaterial3D.new()
	stone_mat.albedo_color = Color("#8f897c")
	stone_mat.roughness = 0.95
	var rng := RandomNumberGenerator.new()
	# Deterministic per site: the same two floats every time this exact
	# signpost is built, so a render taken twice for a before/after comparison
	# never shows the stones having quietly rearranged themselves.
	rng.seed = hash(Vector2i(int(round(at.x * 4.0)), int(round(at.y * 4.0))))

	var holder := Node3D.new()
	holder.name = "BaseDressing"
	add_child(holder)

	for i in BASE_STONE_COUNT:
		var angle := (float(i) / float(BASE_STONE_COUNT)) * TAU + rng.randf_range(-0.35, 0.35)
		var reach := BASE_STONE_RADIUS * rng.randf_range(0.7, 1.15)
		var stone := MeshInstance3D.new()
		stone.name = "BaseStone%d" % i
		var box := BoxMesh.new()
		var size := BASE_STONE_SIZE * rng.randf_range(0.75, 1.3)
		box.size = Vector3(size, size * rng.randf_range(0.55, 0.85), size * rng.randf_range(0.85, 1.25))
		stone.mesh = box
		stone.material_override = stone_mat
		stone.position = Vector3(cos(angle) * reach, size * 0.3, sin(angle) * reach)
		stone.rotation = Vector3(
			rng.randf_range(-0.12, 0.12), rng.randf_range(0.0, TAU), rng.randf_range(-0.12, 0.12))
		holder.add_child(stone)


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
		# VP4-CORRIDOR: `Label3D.double_sided` defaults to true, which means
		# each face's text is also visible (mirrored) from behind its own
		# plank -- a real defect on a plank this thin (0.05m, with the two
		# labels' quads just 0.012m apart), even though it turned out NOT to
		# be the cause of station 08's "Stone Gate Spoke" reading as "one Gate
		# Spoke": rendering a fresh frame with only this line changed left the
		# corrupted text unchanged, which is what ruled it out. `_label_scale()`
		# already fits any length correctly, so this was never a sizing bug --
		# the actual cause was two separate trailhead signposts (`Warren
		# Undertrail` and this one) sited only 4m apart at the same shared
		# road junction, close enough for their physical planks to visually
		# collide from a distance; fixed by separating them in
		# `terrain_playground.json` instead (see that file's own note on the
		# `Stone Gate Spoke` trailhead). Kept here regardless: double-sided
		# text bleeding through a 5cm plank is a real defect in its own right,
		# independent of this specific station's actual bug.
		text.double_sided = false
		text.rotation.y = side * PI * 0.5
		text.position = Vector3(side * (ARM_THICKNESS * 0.5 + 0.006), 0.0, ARM_LENGTH * 0.5)
		text.modulate = Color("#241a10")
		# R7.1-visual round 1: 0 meant letters vanished wherever a label
		# crossed a dark background (a roof, a shadow) — the critic called
		# this out directly. A light outline holds the dark ink readable
		# against both the pale sky and dark structures, the two backgrounds
		# these labels actually cross.
		# GF-B-013: 10 -> 4.
		#
		# `outline_size` is in the same font pixels as `font_size`, so 10 against
		# a 48pt face is an outline ~21% of the em thick, growing outward from
		# every contour -- including the INSIDE contours. At that size it floods
		# the counter of an `o` or an `e` shut and closes the gaps between
		# adjacent letters, so a word stops being letters and becomes one pale
		# blob with dark marks in it. That is the "illegible smear" reading, and
		# it is why bigger boards alone would not have fixed this: the ratio is
		# what breaks, and the ratio does not care how large the glyphs are.
		#
		# 4 is ~8% of the em -- a legibility edge that still holds the dark ink
		# against both the pale sky and the dark structures these labels cross,
		# which is the job the outline was added for (R7.1-visual round 1, when
		# it was 0 and letters vanished over a roof).
		#
		# BAND1-DISCOVERY-0903: 4 -> 12, holding the same ~8% of the em now
		# that LABEL_FONT_SIZE went 48 -> 144. `outline_size` is in font pixels
		# like `font_size` is, so leaving it at 4 against the new 144pt face
		# would have thinned the outline to ~3% of the em -- the letters would
		# render sharper (the actual fix above) but lose the contrast edge
		# GF-B-013 tuned against the sky and dark structures these labels cross.
		text.outline_size = 12
		text.outline_modulate = Color("#f4ecd8")
		arm.add_child(text)


## Metres per font pixel, chosen so the longest label still fits the plank.
##
## The old value was a flat 0.008, which suited "The Road" and sent "Practice
## Meadow" straight off both ends of the board. Fitting to whichever of height
## or width binds first means a new destination name can be any length and the
## sign stays a sign.
func _label_scale(label: String) -> float:
	# GF-B-013: 0.62 -> 0.68 of the board's depth. The remaining third is the
	# margin above and below the text; at 0.62 with a 4px outline instead of a
	# 10px one there is more clear board than the letters need.
	var by_height := (ARM_HEIGHT * 0.68) / float(LABEL_FONT_SIZE)
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
