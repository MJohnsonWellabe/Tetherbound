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
## The prediction written here during the shaded experiment — "if the long-range
## frames come back washed out, the answer is a value, not a render mode" — was
## half right and worth leaving on the record. The value did need fixing. So did
## the render mode, in the opposite direction to the one being tried.
const SHADER_CODE := """
shader_type spatial;
render_mode unshaded, fog_disabled, cull_back;

uniform vec4 albedo : source_color;

void fragment() {
	ALBEDO = albedo.rgb;
}
"""


func build(world: Node) -> void:
	var at := RISE_CENTRE + OFFSET
	var ground: float = float(world.call("ground_height_at", at.x, at.y))
	if is_nan(ground):
		push_error("no ground under the stronghold silhouette at %.0f, %.0f" % [at.x, at.y])
		return
	position = Vector3(at.x, ground, at.y)

	var shader := Shader.new()
	shader.code = SHADER_CODE
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("albedo", TOWER_COLOUR)

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
	base_mesh.radial_segments = 10
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

	var keep_top := _tower(keep, 5.5, 34.0, 5, mat)
	_tower(east, 3.2, 22.0, 6, mat)
	var north_top := _tower(north, 3.6, 25.0, 6, mat)
	_tower(west, 2.6, 18.0, 5, mat)

	# Roofline / varied massing, so the four towers stop reading as identical
	# tapered stubs: the keep gets a peaked roof (the tallest mass on site,
	# capped rather than flat), one tower gets a stepped second drum (a
	# turret standing on a turret), the rest get a crenellation ring — three
	# different silhouettes on four towers.
	_cone_roof(keep, 5.5 * 0.7, keep_top, 9.0, mat)
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
	cone.radial_segments = 8
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
	cyl.radial_segments = 6
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
func _crenellations(at: Vector3, top_radius: float, top_y: float, count: int, mat: ShaderMaterial) -> void:
	var collar_height := 1.4
	var collar := MeshInstance3D.new()
	var collar_mesh := CylinderMesh.new()
	collar_mesh.top_radius = top_radius * 0.95
	collar_mesh.bottom_radius = top_radius * 1.05
	collar_mesh.height = collar_height
	collar_mesh.radial_segments = max(count, 6)
	collar_mesh.material = mat
	collar.mesh = collar_mesh
	collar.position = at + Vector3(0.0, top_y + collar_height * 0.5, 0.0)
	add_child(collar)

	var merlon_height := 2.2
	var merlon_width: float = max(top_radius * 0.7, 1.4)
	var merlon_top_y := top_y + collar_height
	for i in range(count):
		if i % 2 == 1:
			continue # every other gap is open, so the ring reads as crenellation, not a solid rim
		var angle := i * TAU / count
		var offset := Vector3(cos(angle), 0.0, sin(angle)) * top_radius * 0.85
		var mesh := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(merlon_width, merlon_height, merlon_width)
		box.material = mat
		mesh.mesh = box
		mesh.position = at + offset + Vector3(0.0, merlon_top_y + merlon_height * 0.5, 0.0)
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
	var merlon_height := 1.6
	var step := 3.0
	var count := int(length / step)
	if count < 1:
		return
	var dir := Vector2(delta.x, delta.z).normalized()
	for i in range(count + 1):
		if i % 2 == 1:
			continue
		var t := (float(i) / float(count) - 0.5) * length
		var pos := mid + Vector3(dir.x, 0.0, dir.y) * t
		var merlon := MeshInstance3D.new()
		var mbox := BoxMesh.new()
		mbox.size = Vector3(step * 0.6, merlon_height, thickness * 1.1)
		mbox.material = mat
		merlon.mesh = mbox
		merlon.position = pos + Vector3(0.0, height + merlon_height * 0.5, 0.0)
		merlon.rotation.y = atan2(-delta.z, delta.x)
		add_child(merlon)
