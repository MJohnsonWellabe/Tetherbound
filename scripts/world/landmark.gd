extends Node3D

## The stronghold silhouette on the ridge.
##
## R7.1: M7 asks for a distant landmark so the far edge of the map reads as a
## destination instead of a fence — the site-frames critique's "world ends
## 40m out" complaint named the horizon specifically. This is that landmark,
## not the stronghold itself: R8.2 authors the real approach and interior
## once Meadows is further along. Placeholder geometry is deliberate — a
## silhouette only has to read as a shape against the sky at ~170m, and
## CLAUDE.md is explicit that placeholder is fine to prove composition; the
## stronghold's own presentation still needs real art before it is judged.
##
## Built from primitives rather than a model: nothing in either vendored
## asset pack (the since-retired farm pack, stylized_nature) is a ruin or tower, and a
## silhouette's whole job is a dark, angular shape on the skyline, which a
## handful of tall cylinders already do at this distance.
##
## R7.1-visual-remainder: the third blind-critic round (R7.1-visual) confirmed
## colour and value hold up at all three tested distances, then said plainly
## that no amount of repositioning, recolouring or fog tuning on four bare
## tapered cylinders will read as fortified architecture — they read as
## standing stones. That needs new geometry, not scene tuning: a perimeter
## wall silhouette linking the towers (walls are the one shape a cluster of
## monoliths structurally cannot have), a peaked roof on the keep and a
## stepped second mass on another tower for varied massing, and crenellation
## rings on the rest for a roofline. Still placeholder-grade primitives
## (CLAUDE.md) — the ask is a shape that reads as built, not final art.
##
## OF4 (2026-08-12): owner playtest — "the stronghold's silhouette reads as a
## toy." The massing (R7.1-visual-remainder) and the long-range colour/value
## (R9.4) are both blind-critic-verified and deliberately NOT touched here.
## What neither of those rounds tested is the surface: one perfectly flat,
## unshaded colour over mathematically clean primitives — no masonry, no
## weathering, every merlon an identical crisp cube, towers that are 5- and
## 6-sided facet prisms up close — is exactly how a moulded plastic playset
## reads at the ranges a player actually walks past it. Three changes, none
## touching massing or the base colour:
##   1. The shader keeps `unshaded, fog_disabled` (load-bearing per R9.4: a
##      wayfinding silhouette must read the same from every approach) but
##      breaks the flat fill with WORLD-POSITION-KEYED variation — masonry
##      courses with per-block value jitter, mortar seams, broad mottling,
##      dark weather streaks, and a darkened footing where stone meets
##      ground. Position-keyed means it is exactly as view-independent as
##      the flat fill was, and it is near-zero-mean at distance, so the
##      long-range value R9.4 settled is preserved.
##   2. Regularity breakers: merlons vary in height and width and some are
##      missing entirely (a battlement time has chewed, not one a mould
##      stamped), the keep's roof cone is a darker slate than the stone so
##      the site stops being one single moulded colour, and tower silhouette
##      edges get enough radial segments to read as round masonry instead of
##      toy-block prisms (interior facets were never visible under
##      `unshaded`; only the silhouette edge changes).
##   3. Rubble — collapsed blocks half-sunk in the grass at the walls' feet.
##      Toys sit ON the ground; ruins come OUT of it.

const RISE_CENTRE := Vector2(140.0, -90.0)
## A few metres off the true peak so the towers do not have to fight the
## rise's own steepest ground for footing.
const OFFSET := Vector2(-6.0, 8.0)

## R9.4. Was #2a2630 — near-black, and paired with `unshaded` below it made the
## stronghold a flat cutout. A blind critic that knew nothing about why said:
## "the stronghold spire in frame 02 is a pure black paper cutout — measured
## near 0 luminance, zero material response, hard-edged against a bright sky.
## It reads as a hole punched in the image rather than a stone ruin", and
## contrasted it with palworld-04, where the landmark "is atmospheric-hazed to
## a mid blue-grey and sits IN the distance rather than on top of it."
##
## Mid cool stone, and shaded, so the towers have a lit and a shaded face and
## the crenellations that were modelled can actually be seen.
##
## THIRD CUT, and the frames settled an argument between two earlier ones.
##
## Shading was tried at #6b6a72 and then at #33323f. Both failed the same way
## and it took the second render to see why: with normal shading the landmark's
## value depends on WHICH FACE the camera sees. From `silhouette-close` the
## camera looks at the shadowed south side and the fortress reads perfectly —
## crenellations, keep, towers, unmistakably built. From `silhouette-from-
## square` and `-from-path`, the two viewpoints a player actually uses, the
## camera looks at the sun-lit west face and the same geometry washes to a pale
## grey barely separable from the haze band behind it. Not fog: at 0.00055
## density over ~190m that is a ten per cent effect. Lighting direction.
##
## Which is what R7.1-visual was right about. A wayfinding silhouette has to
## read the same from every approach, and `unshaded` is how you get that. Its
## mistake was the colour, not the render mode — #2a2630 is so dark that a
## fresh critic called it "a hole punched in the image rather than a stone
## ruin", and it was right about that too.
##
## So: `unshaded` restored, at a value that reads as stone. Dark slate, a
## little violet so it is not a neutral smudge, sitting well under the pale
## hill band (~0.77) and just above the sky (~0.21) so it separates from both
## from any direction. `fog_disabled` comes back with it for the same reason it
## was there before — a silhouette that fades with distance is not a landmark.
const TOWER_COLOUR := Color("#4a4756")

## OF4: the keep's roof in a darker slate. A single colour over every element
## is a moulded-toy tell; a roof that differs from the walls is the cheapest
## possible "assembled from materials, not cast in one piece" cue. Kept well
## above the old #2a2630 hole-punch value, and it is a small area of the
## silhouette, so R9.4's long-range separation is unaffected.
const ROOF_COLOUR := Color("#38353f")

## R7.1-visual found the towers reading correctly dark at ~40m but fading to a
## pale grey nearly matching the horizon haze at ~60m and ~157m, and fixed it
## by opting the landmark out of the world's atmosphere entirely: `unshaded` so
## no sunward highlight, `fog_disabled` so no wash. Its own note said retuning
## the shared fog instead "needs the kind of whole-survey re-verification R9.4
## exists for, not a change buried in this task."
##
## R9.4 IS THAT PASS, and it changed the premise. The fog that was eating the
## landmark has since been halved twice — 0.0022 to 0.0011 to 0.00055 — so the
## wash that justified opting out is a quarter of what was measured. Meanwhile
## the opt-out had a cost nobody had a frame to see: a fresh blind critic,
## told nothing, called the result "a hole punched in the image rather than a
## stone ruin" and pointed at palworld-04, whose landmark is hazed to a mid
## blue-grey and "sits IN the distance rather than on top of it."
##
## R9.4 tested that by taking the opt-out away, and the render mode turned out
## to be load-bearing after all — see TOWER_COLOUR above for what two rounds of
## frames actually showed. `unshaded` and `fog_disabled` stay. What R9.4 keeps
## is the other half of the finding: the COLOUR was wrong, and a silhouette
## dark enough to read as a hole is not better than one that fades.
##
## OF4 keeps both render flags for R9.4's reason and adds surface variation
## INSIDE that constraint: everything below is keyed to world position (and,
## for the masonry projection axis only, the world-space normal), never to
## the camera or the sun, so the read is identical from every approach — the
## exact property `unshaded` exists to protect. The variation is small and
## centred on the base albedo, so from 170m it averages back to the R9.4
## value; up close it resolves into coursed stone instead of plastic.
const SHADER_CODE := """
shader_type spatial;
render_mode unshaded, fog_disabled, cull_back;

uniform vec4 albedo : source_color;
uniform float base_world_y = 0.0;

varying vec3 wpos;
varying vec3 wnorm;

float hash21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(hash21(i), hash21(i + vec2(1.0, 0.0)), u.x),
		mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0, 1.0)), u.x),
		u.y);
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnorm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 col = albedo.rgb;

	// Masonry courses. Biplanar projection: each face samples along whichever
	// world axis it mostly faces, so blocks do not smear on walls that run
	// diagonal to the world grid. World-keyed — never moves with the camera.
	// Block scale: first cut was 1.3m courses x 2.2m blocks, and the render
	// showed why that itself is a toy cue — the keep face came out only ~5
	// blocks wide, and oversized bricks relative to a structure is exactly
	// how a table-top miniature reads. Smaller, more numerous blocks are the
	// scale cue that makes a 34m keep read monumental.
	float across = abs(wnorm.x) > abs(wnorm.z) ? wpos.z : wpos.x;
	float course_h = 0.8;
	float block_w = 1.3;
	float row = floor(wpos.y / course_h);
	float u = (across + hash21(vec2(row, 3.7)) * block_w) / block_w;
	float block = floor(u);

	// Per-block value jitter, about +/-8 percent, zero-mean.
	col *= 1.0 + (hash21(vec2(row, block)) - 0.5) * 0.16;

	// Mortar seams between courses and blocks, slightly darker.
	float fy = fract(wpos.y / course_h);
	float fu = fract(u);
	float seam = min(
		smoothstep(0.0, 0.06, fy) * smoothstep(1.0, 0.94, fy),
		smoothstep(0.0, 0.04, fu) * smoothstep(1.0, 0.96, fu));
	col *= mix(0.84, 1.0, seam);

	// Broad mottling so no large face is a single value.
	col *= 1.0 + (vnoise(vec2(across * 0.13, wpos.y * 0.13)) - 0.5) * 0.10;

	// Weather streaks running down the stone.
	float streak = vnoise(vec2(across * 0.9, wpos.y * 0.045));
	col *= 1.0 - 0.10 * smoothstep(0.55, 0.9, streak);

	// Darkened footing where the stone meets the ground, standing in for
	// centuries of damp and dirt — and for the contact shadow `unshaded`
	// geometry cannot receive.
	col *= mix(0.80, 1.0, clamp((wpos.y - base_world_y) / 7.0, 0.0, 1.0));

	ALBEDO = col;
}
"""

## OF4: one fixed-seed RNG for every irregularity below, so the ruin erodes
## the same way every launch and every capture frame is reproducible.
var _rng := RandomNumberGenerator.new()


func build(world: Node) -> void:
	var at := RISE_CENTRE + OFFSET
	var ground: float = float(world.call("ground_height_at", at.x, at.y))
	if is_nan(ground):
		push_error("no ground under the stronghold silhouette at %.0f, %.0f" % [at.x, at.y])
		return
	position = Vector3(at.x, ground, at.y)

	_rng.seed = 71

	var shader := Shader.new()
	shader.code = SHADER_CODE
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("albedo", TOWER_COLOUR)
	mat.set_shader_parameter("base_world_y", ground)

	var roof_mat := ShaderMaterial.new()
	roof_mat.shader = shader
	roof_mat.set_shader_parameter("albedo", ROOF_COLOUR)
	roof_mat.set_shader_parameter("base_world_y", ground)

	# A wide base connecting the towers' feet. A blind critic round on the
	# first pass at this (a 3m-tall drum) still called the long-range frame
	# an ambiguous pair of "standing-stone" prongs: the straight wall
	# segments between towers go edge-on and vanish from most viewing
	# angles, so at range the only thing left on screen was the two towers
	# nearest the camera, with nothing visibly joining them. A cylinder's
	# silhouette width is the same from every angle, unlike a straight wall,
	# so this drum is deliberately tall enough (was 3m) to read as a solid
	# fortress plinth under the towers regardless of which way the camera
	# looks — fixing the long-range read and the "obelisk with no base"
	# proportion problem in the same shape.
	var base := MeshInstance3D.new()
	base.name = "Base"
	var base_mesh := CylinderMesh.new()
	base_mesh.top_radius = 10.0
	base_mesh.bottom_radius = 11.5
	base_mesh.height = 9.0
	base_mesh.radial_segments = 14
	base_mesh.material = mat
	base.mesh = base_mesh
	base.position = Vector3(1.25, 4.5, 3.25)
	add_child(base)

	# One tall keep and three shorter towers around it — an irregular skyline
	# reads as a ruin far more than one uniform silhouette does. Positions are
	# unchanged from the shape the critic already confirmed reads dark and
	# solid; what's new below is the roofline on each and the wall between
	# them, in polygon order (keep -> east -> north -> west -> keep) so the
	# wall traces the same footprint the base drum already spans.
	var keep := Vector3(0.0, 0.0, 0.0)
	var east := Vector3(9.0, 0.0, -4.0)
	var north := Vector3(3.0, 0.0, 11.0)
	var west := Vector3(-7.0, 0.0, 6.0)

	# OF4: segment counts up from 5/6 — under `unshaded` the interior facets
	# were never visible, but the SILHOUETTE edge of a 5-sided prism shows
	# hard toy-block corners at approach range. The massing itself is the
	# blind-critic-verified shape and does not change.
	var keep_top := _tower(keep, 5.5, 34.0, 12, mat)
	_tower(east, 3.2, 22.0, 11, mat)
	var north_top := _tower(north, 3.6, 25.0, 11, mat)
	_tower(west, 2.6, 18.0, 10, mat)

	# Roofline / varied massing, so the four towers stop reading as identical
	# tapered stubs: the keep gets a peaked roof (the tallest mass on site,
	# capped rather than flat), one tower gets a stepped second drum (a
	# turret standing on a turret), the rest get a crenellation ring — three
	# different silhouettes on four towers.
	_cone_roof(keep, 5.5 * 0.7, keep_top, 9.0, roof_mat)
	_stepped_mass(north, 3.6 * 0.7, north_top, mat)
	_crenellations(east, 3.2 * 0.7, 22.0, 8, mat)
	_crenellations(west, 2.6 * 0.7, 18.0, 6, mat)

	# The perimeter wall: what a cluster of standing stones structurally
	# cannot have. Lower than every tower (shortest is west at 18m) so the
	# towers still read as the skyline's tallest shapes; its own crenellated
	# top is what makes the whole cluster read as one fortified site rather
	# than four separate ones.
	#
	# Round 2 of the blind-critic loop still failed the long-range frame,
	# even after round 1's fix widened the LOW base drum (0-9m) to hold its
	# footprint at any camera angle: the drum's own width was invisible from
	# a far, low, grazing viewpoint because nearby ridge terrain occludes
	# low-elevation geometry from exactly that kind of angle, the same way a
	# fence looks taller than a house standing right behind a hill crest.
	# The one part of this structure confirmed to clear the terrain from
	# every tested distance is the towers themselves (they're the only thing
	# visible in the long-range frame at all) -- so this raises the wall
	# itself, not just the base drum, from 11m to 16m: still under every
	# tower's own height, but tall enough to connect the towers' visible
	# upper portions instead of only their already-occluded feet.
	const WALL_HEIGHT := 16.0
	const WALL_THICKNESS := 2.8
	_wall(keep, east, WALL_HEIGHT, WALL_THICKNESS, mat)
	_wall(east, north, WALL_HEIGHT, WALL_THICKNESS, mat)
	_wall(north, west, WALL_HEIGHT, WALL_THICKNESS, mat)
	_wall(west, keep, WALL_HEIGHT, WALL_THICKNESS, mat)

	# OF4: collapsed masonry half-sunk in the grass around the perimeter.
	_rubble(world, mat)


## Builds a tapered tower and returns the world-space Y of its flat top, so
## callers can stack roofline geometry on it without recomputing height math.
func _tower(at: Vector3, radius: float, height: float, sides: int, mat: ShaderMaterial) -> float:
	var mesh := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = radius * 0.7
	cyl.bottom_radius = radius
	cyl.height = height
	cyl.radial_segments = sides
	cyl.material = mat
	mesh.mesh = cyl
	mesh.position = at + Vector3(0.0, height * 0.5, 0.0)
	add_child(mesh)
	return at.y + height


## A pointed roof capping the keep — a cylinder tapered to a near-point reads
## as a peaked roof at silhouette range without needing real roof geometry.
func _cone_roof(at: Vector3, base_radius: float, base_y: float, roof_height: float, mat: ShaderMaterial) -> void:
	var mesh := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.bottom_radius = base_radius * 1.05
	cone.top_radius = 0.05
	cone.height = roof_height
	cone.radial_segments = 10
	cone.material = mat
	mesh.mesh = cone
	mesh.position = at + Vector3(0.0, base_y - at.y + roof_height * 0.5, 0.0)
	add_child(mesh)


## A narrower second drum standing on the first — varied massing (a turret
## on a turret) rather than a flat cap, distinct from both the cone roof and
## the crenellation rings so no two towers on site share a silhouette.
func _stepped_mass(at: Vector3, base_radius: float, base_y: float, mat: ShaderMaterial) -> void:
	var step_radius := base_radius * 0.6
	var step_height := 7.0
	var mesh := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = step_radius * 0.75
	cyl.bottom_radius = step_radius
	cyl.height = step_height
	cyl.radial_segments = 9
	cyl.material = mat
	mesh.mesh = cyl
	mesh.position = at + Vector3(0.0, base_y - at.y + step_height * 0.5, 0.0)
	add_child(mesh)
	_crenellations(at, step_radius * 0.75, base_y - at.y + step_height, 6, mat)


## A ring of alternating merlons around a tower's flat top — the roofline
## silhouette a real curtain wall or keep has and a bare tapered cylinder
## does not.
##
## Round 1 of the blind-critic loop on this task found the merlons alone
## "separate into three or four separated, pointed teeth that look more
## like claws, broken glass, or a jagged rock spur than a battlement" once
## the tower shrinks with distance — individual boxes with open gaps
## between them lose their shared base the moment they stop being
## resolvable as separate objects. A solid collar under the merlons gives
## them a continuous rim to sit on, so at range it reads as "a solid top
## with a notched edge" rather than "several separate spikes."
##
## OF4: the merlons themselves stop being identical. Each one draws its
## height, width, yaw and radial seat from the fixed-seed RNG, and roughly
## one in five is simply gone — a moulded toy has every merlon it was cast
## with; a five-hundred-year-old battlement does not.
func _crenellations(at: Vector3, top_radius: float, top_y: float, count: int, mat: ShaderMaterial) -> void:
	var collar_height := 1.4
	var collar := MeshInstance3D.new()
	var collar_mesh := CylinderMesh.new()
	collar_mesh.top_radius = top_radius * 0.95
	collar_mesh.bottom_radius = top_radius * 1.05
	collar_mesh.height = collar_height
	collar_mesh.radial_segments = max(count, 8)
	collar_mesh.material = mat
	collar.mesh = collar_mesh
	collar.position = at + Vector3(0.0, top_y + collar_height * 0.5, 0.0)
	add_child(collar)

	var merlon_width: float = max(top_radius * 0.7, 1.4)
	var merlon_top_y := top_y + collar_height
	for i in range(count):
		if i % 2 == 1:
			continue # every other gap is open, so the ring reads as crenellation, not a solid rim
		# Draw every merlon's variation BEFORE the missing-merlon roll, so
		# the RNG stream stays aligned and one skip does not reshuffle every
		# merlon after it.
		var h := 2.2 * _rng.randf_range(0.55, 1.25)
		var w := merlon_width * _rng.randf_range(0.85, 1.15)
		var yaw := _rng.randf_range(-0.35, 0.35)
		var seat := _rng.randf_range(0.78, 0.9)
		var missing := _rng.randf() < 0.2
		if missing:
			continue
		var angle := i * TAU / count
		var offset := Vector3(cos(angle), 0.0, sin(angle)) * top_radius * seat
		var mesh := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(w, h, w)
		box.material = mat
		mesh.mesh = box
		mesh.position = at + offset + Vector3(0.0, merlon_top_y + h * 0.5, 0.0)
		mesh.rotation.y = angle + yaw
		add_child(mesh)


## A straight wall segment between two tower footings, with its own
## crenellated top edge — the shape that makes the cluster read as one
## fortified perimeter instead of four unrelated towers.
func _wall(from: Vector3, to: Vector3, height: float, thickness: float, mat: ShaderMaterial) -> void:
	var delta := to - from
	var length := Vector2(delta.x, delta.z).length()
	if length < 0.01:
		return
	var mid := (from + to) * 0.5
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(length, height, thickness)
	box.material = mat
	mesh.mesh = box
	mesh.position = mid + Vector3(0.0, height * 0.5, 0.0)
	mesh.rotation.y = atan2(-delta.z, delta.x)
	add_child(mesh)

	# Merlons along the wall's own top edge, spaced along its length in the
	# wall's local (rotated) frame rather than world axes.
	#
	# OF4: same erosion treatment as the tower rings — per-merlon height and
	# width variation and the occasional missing tooth, so the parapet reads
	# weathered rather than moulded.
	var step := 3.0
	var count := int(length / step)
	if count < 1:
		return
	var dir := Vector2(delta.x, delta.z).normalized()
	for i in range(count + 1):
		if i % 2 == 1:
			continue
		var h := 1.6 * _rng.randf_range(0.55, 1.3)
		var w := step * 0.6 * _rng.randf_range(0.85, 1.15)
		var missing := _rng.randf() < 0.18
		if missing:
			continue
		var t := (float(i) / float(count) - 0.5) * length
		var pos := mid + Vector3(dir.x, 0.0, dir.y) * t
		var merlon := MeshInstance3D.new()
		var mbox := BoxMesh.new()
		mbox.size = Vector3(w, h, thickness * 1.1)
		mbox.material = mat
		merlon.mesh = mbox
		merlon.position = pos + Vector3(0.0, height + h * 0.5, 0.0)
		merlon.rotation.y = atan2(-delta.z, delta.x)
		add_child(merlon)


## OF4: fallen masonry scattered around the perimeter, half-sunk and tilted
## into the grass. This is the cheapest cue primitives can give that the
## structure is old and belongs to the ground it stands on — a toy castle
## sits cleanly on the carpet; a ruin sheds itself into the hillside. Blocks
## share the stone material, so the shader's footing-darkening grounds them
## the same way it grounds the walls.
func _rubble(world: Node, mat: ShaderMaterial) -> void:
	for i in 14:
		var ang := _rng.randf_range(0.0, TAU)
		var dist := _rng.randf_range(11.5, 18.0)
		var local := Vector2(cos(ang), sin(ang)) * dist
		var s := _rng.randf_range(0.8, 2.2)
		var size := Vector3(
			s * _rng.randf_range(0.8, 1.4),
			s * _rng.randf_range(0.45, 0.8),
			s * _rng.randf_range(0.8, 1.4))
		var tilt_x := _rng.randf_range(-0.28, 0.28)
		var yaw := _rng.randf_range(0.0, TAU)
		var tilt_z := _rng.randf_range(-0.28, 0.28)
		var g: float = float(world.call("ground_height_at", position.x + local.x, position.z + local.y))
		if is_nan(g):
			continue
		var mesh := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = size
		box.material = mat
		mesh.mesh = box
		# A third of the block below grade: sunk, not placed.
		mesh.position = Vector3(local.x, g - position.y + size.y * 0.17, local.y)
		mesh.rotation = Vector3(tilt_x, yaw, tilt_z)
		add_child(mesh)
