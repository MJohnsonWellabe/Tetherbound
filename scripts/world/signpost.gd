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

## W22-BRIDGE-SIGNPOST-0904, prompt 74 §7: wood tones tuned AGAINST A RENDER,
## not guessed. Board 18's "Directional (Multi)" panel was sampled directly
## (crop medians, `docs/art/reference/18_Signpost_Bridge_Modular_Props.png`):
## its planks are a rich mid-brown, #85593a-#946240 (H25 S57 V52-58), its
## post #906134 (H29 S64 V57), and its lettering is CREAM on that dark wood.
## The isolated day render of the old values (`tools/
## _capture_bridge_deck_isolated.gd`) measured the lit face of a `#c8a874`
## plank at #ffdf9d -- pale, near-white, roughly 1.3x the albedo in the sun --
## and the `#6b4a2f` post at #8c6442, so both albedos below are the board's
## own rendered targets divided by that same measured 1.3x lift. The planks
## darkening from cream to the board's brown is what forces the ink swap in
## `_add_arm()`: dark ink on a dark board is unreadable, and the board's own
## answer is pale lettering with a dark edge.
const POST_COLOUR := Color("#6e4a28")
const PLANK_COLOUR := Color("#724b31")
const ROPE_COLOUR := Color("#a8905f")
const INK_COLOUR := Color("#f4ecd8")
const INK_OUTLINE_COLOUR := Color("#2a1a10")

## The rope-wrapped band every variant on board 18 carries near the top of
## the post: three stacked coils in the gap between the topmost arm's upper
## edge and the post cap. Torus coils rather than a banded cylinder so the
## silhouette actually reads as wound rope at the distance a sign is read.
const ROPE_COILS := 3
const ROPE_COIL_PITCH := 0.036
const ROPE_TUBE_RADIUS := 0.02
## A small pointed cap on the post's crown, as the board draws it -- the
## post no longer ends in a flat sawn disc.
const CAP_HEIGHT := 0.13

## The arm is ONE pointed plank (board 18: wide at the post, pointed at the
## tip) rather than a flat box with a separate cone bolted to its end. The
## body runs from the post to `ARM_LENGTH`, tapering in height to
## `ARM_TAPER` of `ARM_HEIGHT` by its far end, then the tip runs on
## `ARM_TIP_LENGTH` further to a point on the plank's centreline. The tip
## reaches to ARM_LENGTH + 0.14, within a centimetre of where the old cone's
## apex sat (ARM_LENGTH + 0.06 + 0.072), so the arm-to-arm clearances
## R7.1-visual round 2 tuned are unchanged.
const ARM_TAPER := 0.92
const ARM_TIP_LENGTH := 0.14

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
	post_mat.albedo_color = POST_COLOUR
	post_mat.roughness = 0.8
	post_mesh.material = post_mat
	add_child(post)

	_build_rope_band(post_mat)
	_build_cap(post_mat)

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

	# W22-BRIDGE-SIGNPOST-0904: the plank's own near end is pulled back to the
	# post's axis rather than starting at the mount point, and a short bracket
	# block bridges the mount offset, so an arm mounted around the post's
	# circumference reads as bolted to it instead of hovering a few
	# centimetres off its surface. `z_axis` is where the post's centreline
	# falls in this arm's own frame (local +Z is the route bearing).
	var z_axis := -(mount.x * bearing.x + mount.y * bearing.y)
	var plank := MeshInstance3D.new()
	plank.name = "Plank"
	plank.mesh = _pointed_plank_mesh(z_axis)
	var plank_mat := StandardMaterial3D.new()
	plank_mat.albedo_color = PLANK_COLOUR
	plank_mat.roughness = 0.82
	plank.mesh.surface_set_material(0, plank_mat)
	arm.add_child(plank)

	var bracket := MeshInstance3D.new()
	bracket.name = "Bracket"
	var bracket_mesh := BoxMesh.new()
	bracket_mesh.size = Vector3(ARM_THICKNESS * 2.4, ARM_HEIGHT * 0.5, ARM_MOUNT_RADIUS + POST_RADIUS)
	bracket.mesh = bracket_mesh
	var bracket_mat := StandardMaterial3D.new()
	bracket_mat.albedo_color = Color("#3a2618")
	bracket_mat.roughness = 0.9
	bracket.material_override = bracket_mat
	# From the post axis out to the mount point, in the arm's frame: the mount
	# vector's along-bearing part is `-z_axis`, its across part the rest.
	var across := mount.x * (-bearing.y) + mount.y * bearing.x
	bracket.position = Vector3(across * 0.5, 0.0, z_axis * 0.5)
	bracket.rotation.y = atan2(across, z_axis) if absf(across) + absf(z_axis) > 0.001 else 0.0
	arm.add_child(bracket)

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
		# W22-BRIDGE-SIGNPOST-0904: cream ink with a dark edge, board 18's own
		# lettering on its own dark planks (see PLANK_COLOUR). The outline's
		# job is unchanged -- hold the letters against whatever is behind the
		# plank -- it is just the other way up now that the board is dark.
		text.modulate = INK_COLOUR
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
		text.outline_modulate = INK_OUTLINE_COLOUR
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
	# W22-BRIDGE-SIGNPOST-0904: the plank body now tapers to `ARM_TAPER` of
	# its height at the far end (`_pointed_plank_mesh`), so the fit is taken
	# against the body's SHALLOWEST section -- the one the last letters of a
	# long name actually sit on -- rather than the full height at the post.
	var by_height := (ARM_HEIGHT * ARM_TAPER * 0.68) / float(LABEL_FONT_SIZE)
	# 0.55 em is a serviceable mean advance for mixed-case Latin text; the
	# 0.86 keeps a margin of board visible at each end rather than filling it
	# edge to edge.
	var glyphs := maxf(1.0, float(label.length()) * 0.55 * float(LABEL_FONT_SIZE))
	var by_width := (ARM_LENGTH * 0.86) / glyphs
	return minf(by_height, by_width)


## One pointed plank, built as a closed flat-shaded ArrayMesh in the arm's
## own frame: x is thickness, y height, z runs from the post (`z_axis`,
## behind the mount point) out along the route bearing. Profile, in the y-z
## plane: full `ARM_HEIGHT` at the post end, `ARM_TAPER` of it at
## `ARM_LENGTH`, then a point on the centreline `ARM_TIP_LENGTH` further out.
##
## `_label_scale()` keeps its rectangular-board assumption honestly: the
## label spans at most 0.86 of `ARM_LENGTH` centred on its midpoint, which
## is entirely inside the tapered BODY (z in [0, ARM_LENGTH]) and never on
## the tip, and the height fit is taken at the body's shallow end.
func _pointed_plank_mesh(z_axis: float) -> ArrayMesh:
	var half_t := ARM_THICKNESS * 0.5
	var h0 := ARM_HEIGHT * 0.5
	var h1 := ARM_HEIGHT * ARM_TAPER * 0.5
	var z0 := minf(z_axis, 0.0)
	var z1 := ARM_LENGTH
	var z2 := ARM_LENGTH + ARM_TIP_LENGTH

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for side: float in [1.0, -1.0]:
		var x := side * half_t
		# The broad face is a pentagon; fan it from the post-end top corner.
		# Winding flips with the side so both faces look outward.
		var ring: Array[Vector3] = [
			Vector3(x, h0, z0), Vector3(x, h1, z1), Vector3(x, 0.0, z2),
			Vector3(x, -h1, z1), Vector3(x, -h0, z0)]
		if side < 0.0:
			ring.reverse()
		for i in range(1, ring.size() - 1):
			_tri(st, ring[0], ring[i], ring[i + 1])
	# Top edge: the tapering body, then the tip's upper bevel.
	_quad(st, Vector3(-half_t, h0, z0), Vector3(-half_t, h1, z1), Vector3(half_t, h1, z1), Vector3(half_t, h0, z0))
	_quad(st, Vector3(-half_t, h1, z1), Vector3(-half_t, 0.0, z2), Vector3(half_t, 0.0, z2), Vector3(half_t, h1, z1))
	# Bottom edge, mirrored.
	_quad(st, Vector3(half_t, -h0, z0), Vector3(half_t, -h1, z1), Vector3(-half_t, -h1, z1), Vector3(-half_t, -h0, z0))
	_quad(st, Vector3(half_t, -h1, z1), Vector3(half_t, 0.0, z2), Vector3(-half_t, 0.0, z2), Vector3(-half_t, -h1, z1))
	# The post end.
	_quad(st, Vector3(half_t, h0, z0), Vector3(-half_t, h0, z0), Vector3(-half_t, -h0, z0), Vector3(half_t, -h0, z0))
	st.generate_normals()
	return st.commit()


func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	st.add_vertex(a)
	st.add_vertex(b)
	st.add_vertex(c)


func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	_tri(st, a, b, c)
	_tri(st, a, c, d)


## Three rope coils wound round the post just above the topmost arm. The
## topmost arm's upper edge is at ARM_START_HEIGHT + ARM_HEIGHT/2; the coils
## sit in the air between that and the cap, never on a plank.
func _build_rope_band(_post_mat: StandardMaterial3D) -> void:
	var rope_mat := StandardMaterial3D.new()
	rope_mat.albedo_color = ROPE_COLOUR
	rope_mat.roughness = 1.0
	var holder := Node3D.new()
	holder.name = "RopeBand"
	var bottom := ARM_START_HEIGHT + ARM_HEIGHT * 0.5 + 0.035
	holder.position = Vector3(0.0, bottom, 0.0)
	add_child(holder)
	for i in ROPE_COILS:
		var coil := MeshInstance3D.new()
		coil.name = "Coil%d" % i
		var torus := TorusMesh.new()
		torus.inner_radius = POST_RADIUS - ROPE_TUBE_RADIUS * 0.4
		torus.outer_radius = POST_RADIUS + ROPE_TUBE_RADIUS * 1.6
		torus.rings = 24
		torus.ring_segments = 8
		coil.mesh = torus
		coil.material_override = rope_mat
		coil.position = Vector3(0.0, ROPE_TUBE_RADIUS + i * ROPE_COIL_PITCH, 0.0)
		# A real wrap climbs; a hair of roll per coil keeps the three from
		# reading as one machined ridge.
		coil.rotation = Vector3(deg_to_rad(4.0), float(i) * 0.9, 0.0)
		holder.add_child(coil)


## The post's pointed crown.
func _build_cap(post_mat: StandardMaterial3D) -> void:
	var cap := MeshInstance3D.new()
	cap.name = "Cap"
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = POST_RADIUS * 1.35
	cone.height = CAP_HEIGHT
	cone.radial_segments = 6
	cap.mesh = cone
	cap.material_override = post_mat
	cap.position = Vector3(0.0, POST_HEIGHT + CAP_HEIGHT * 0.5 - 0.01, 0.0)
	add_child(cap)


func _load_paths_config() -> Dictionary:
	var file := FileAccess.open(TERRAIN_CONFIG, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return {}
	return (parsed as Dictionary).get("paths", {})
