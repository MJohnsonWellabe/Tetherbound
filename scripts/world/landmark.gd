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
## asset pack (the since-retired farm pack, stylized_nature) is a ruin or
## tower, and a silhouette's whole job is a dark, angular shape on the
## skyline, which primitives already do at this distance.
##
## OF4 (2026-08-12 owner playtest): "reads as a toy." Root causes, judged
## against the previous build (four round tapered cylinders in a 16m circle,
## a cone-hatted keep, a 9m pedestal drum):
##
##   1. Chess-piece proportions. The whole cluster spanned ~16m under a 34m
##      keep. Fortified architecture spreads: curtain walls run several times
##      their towers' height. A tall thing on a tiny footprint is a figurine.
##   2. The cone roof. A witch-hat cone on a round tower is the single
##      strongest toy-castle icon there is, and it was the site's apex.
##   3. Repetition. Four near-identical round towers with the same 0.7 taper
##      read as one toy part reused, not as a place that grew.
##   4. The base drum read as a display-stand pedestal under a model.
##
## So OF4 rebuilt the massing rather than tuning it, keeping what earlier
## rounds proved (see TOWER_COLOUR / SHADER_CODE below — unshaded and
## fog_disabled are settled): the site is now "the Meadows Hall" the spec's
## Act VI actually names — a long gabled great-hall block as the central
## shoulder mass, a dominant SQUARE keep (4-segment cylinder, corner-post
## crown) instead of the cone, square perimeter towers at three different
## heights and tops, curtain walls of varying height spread over a ~36m
## polygon, a twin-towered gatehouse facing the village, a lateral rampart
## descending the village-facing flank, and a near-vertical faceted terrace
## instead of the pedestal. EVERY tower is square: round drums kept reading
## organic ("smokestack", "bulbous dome") once flat-filled, five blind
## rounds running — a silhouette with no shading turns curves into geology.
## Footprint chosen against a measured height grid of the rise (probe, this
## task): the summit plateau holds within ~2m over local x 0..+24 /
## z -12..0 and falls 5-9m to the west and south, so the polygon is biased
## east and the terrace is deep enough to meet the downhill ground as a
## revetment instead of floating. Sightlines were computed, not guessed
## (a second probe marched rays from both player eyes over the
## heightfield): from the path, terrain hides everything below ~23m local
## at the keep — which is why the wall tops, hall ridge and rampart heights
## are all set against those numbers, and why nothing that matters to the
## read lives below them.
##
## R7.1-visual-remainder (history): the third blind-critic round confirmed
## colour and value hold up at all three tested distances, then said plainly
## that no amount of repositioning, recolouring or fog tuning on four bare
## tapered cylinders will read as fortified architecture — they read as
## standing stones. The wall-and-roofline pass that answered it is kept in
## spirit here: walls are still the one shape standing stones cannot have.

## OF13 (owner's direct answer to `OF9`): the stronghold must not be visible
## from the start, and must sit farther from the village. `unshaded,
## fog_disabled` below is settled (R7.1/R9.4) and stays — a wayfinding
## silhouette that fades or flat-out disappears with distance was already
## tried and rejected twice, so "hidden" here means real geometric occlusion,
## not a render trick. `RISE_CENTRE` still names the true peak of
## `terrain_playground.json`'s `rises.peaks[0]` (140,-90) — kept as a
## reference point since `capture_hillside.gd`/`OF11` anchor to the same
## rise — but `OFFSET` no longer sits near that peak. It now carries the
## complex ~121m out onto the rise's FAR (east) shoulder, past the dome's own
## radius (78) and onto the surrounding rolling hills, so the rise's own
## bulk sits between the village and the site.
##
## Computed, not guessed, with a scratch ray-march probe against
## `playground_heightfield.gd::height_at` from the two vantage points
## `capture_wayfinding.gd` already uses for this landmark
## (`silhouette-from-square`'s eye and the-rise-route's second waypoint,
## `silhouette-from-path`'s eye): the OLD site (RISE_CENTRE + (-6,8)) is
## clear line-of-sight from both (2.6m/2.6m minimum clearance to the apex).
## Scanning candidates along the village->RISE_CENTRE bearing, occlusion
## only starts past ~65m out (worst-case clearance still under 1m — a
## razor's edge, and the near side of that range sits on the dome's own
## steep back slope, a measured ~30-37m of height variation across the
## complex's ~36m core footprint, enough to float or bury the unmodified
## OF4 geometry). Past the dome's radius the ground flattens back out
## (rolling-hills terrain, not the rise's own steep falloff): at 121m out,
## clearance is -17.0m (village) / -23.2m (path) — comfortably occluded,
## not marginal — and the local footprint spread drops to ~4.5m, flatter
## than the original site's own ~19m. Net distance from the village square
## eye: 271m, up from 156.8m (+73%).
const RISE_CENTRE := Vector2(140.0, -90.0)
const OFFSET := Vector2(89.8, -54.4)

## R9.4. Was #2a2630 — near-black, and paired with `unshaded` below it made the
## stronghold a flat cutout. A blind critic that knew nothing about why said:
## "the stronghold spire in frame 02 is a pure black paper cutout — measured
## near 0 luminance, zero material response, hard-edged against a bright sky.
## It reads as a hole punched in the image rather than a stone ruin", and
## contrasted it with palworld-04, where the landmark "is atmospheric-hazed to
## a mid blue-grey and sits IN the distance rather than on top of it."
##
## THIRD CUT, and the frames settled an argument between two earlier ones.
##
## Shading was tried at #6b6a72 and then at #33323f. Both failed the same way
## and it took the second render to see why: with normal shading the landmark's
## value depends on WHICH FACE the camera sees. From `silhouette-close` the
## camera looks at the shadowed south side and the fortress reads perfectly.
## From `silhouette-from-square` and `-from-path`, the two viewpoints a player
## actually uses, the camera looks at the sun-lit west face and the same
## geometry washes to a pale grey barely separable from the haze band behind
## it. Not fog: at 0.00055 density over ~190m that is a ten per cent effect.
## Lighting direction.
##
## Which is what R7.1-visual was right about. A wayfinding silhouette has to
## read the same from every approach, and `unshaded` is how you get that. Its
## mistake was the colour, not the render mode — #2a2630 is so dark that a
## fresh critic called it "a hole punched in the image rather than a stone
## ruin", and it was right about that too.
##
## So: `unshaded`, at a value that reads as stone. Dark slate, a little violet
## so it is not a neutral smudge, sitting well under the pale hill band
## (~0.77) and just above the sky (~0.21) so it separates from both from any
## direction. `fog_disabled` for the same reason — a silhouette that fades
## with distance is not a landmark.
const TOWER_COLOUR := Color("#4a4756")

## OF4: a second tone ~15% darker for rooflines — the hall roof, tower crowns
## and crenellation work. One flat colour over every surface was part of the
## sticker read; two close tones keep the single-silhouette wayfinding value
## while letting the roof plane register as a different material at range.
const ROOF_COLOUR := Color("#3f3c49")

## R7.1-visual found the towers fading into horizon haze at range and fixed it
## by opting the landmark out of the world's atmosphere entirely (`unshaded`,
## `fog_disabled`). R9.4 tested taking that away after the fog was halved
## twice, and the render mode turned out to be load-bearing after all — see
## TOWER_COLOUR above. Both stay.
##
## OF4 adds the one material axis `unshaded` still allows: a vertical
## luminance gradient keyed to WORLD height, not to the camera or the sun, so
## it is identical from every approach — the wayfinding guarantee `unshaded`
## exists for is untouched. Slightly dark at the footing, slightly lifted at
## the parapets: the flat "sticker" fill was one of the toy tells, and a
## grounded tonal base with a lighter skyline edge is the cheapest thing that
## reads as a lit mass instead of a decal. The range (0.90..1.08 of albedo)
## keeps every point of it inside the value window R9.4 tuned against the
## sky (~0.21) and the hill band (~0.77).
const SHADER_CODE := """
shader_type spatial;
render_mode unshaded, fog_disabled, cull_back;

uniform vec4 albedo : source_color;
uniform float base_y = 0.0;
uniform float span_y = 38.0;

varying float world_y;

void vertex() {
	world_y = (MODEL_MATRIX * vec4(VERTEX, 1.0)).y;
}

void fragment() {
	float t = clamp((world_y - base_y) / span_y, 0.0, 1.0);
	ALBEDO = albedo.rgb * mix(0.90, 1.08, t);
}
"""

## Local Y of the terrace top every structure stands on. The terrace itself
## reaches ~11m further down so its rim meets the measured -9m ground on the
## site's downhill (village-facing) side.
const TERRACE_TOP := 7.0


func build(world: Node) -> void:
	var at := RISE_CENTRE + OFFSET
	var ground: float = float(world.call("ground_height_at", at.x, at.y))
	if is_nan(ground):
		push_error("no ground under the stronghold silhouette at %.0f, %.0f" % [at.x, at.y])
		return
	position = Vector3(at.x, ground, at.y)

	var stone := _material(TOWER_COLOUR, ground)
	var roof := _material(ROOF_COLOUR, ground)

	# A wide, low terrace in place of the old pedestal drum. Faceted (8
	# segments) and NEAR-VERTICAL: the first cut battered it 15 degrees and
	# the from-path frame read the sloped faces as a rock crag, not a built
	# revetment — vertical faces are the architecture cue. Deep enough (top
	# +7 to -11) that no rim floats over the measured -9m ground at its
	# south-west edge.
	var terrace := MeshInstance3D.new()
	terrace.name = "Terrace"
	var terrace_mesh := CylinderMesh.new()
	terrace_mesh.top_radius = 21.5
	terrace_mesh.bottom_radius = 23.0
	terrace_mesh.height = 18.0
	terrace_mesh.radial_segments = 8
	terrace_mesh.material = stone
	terrace.mesh = terrace_mesh
	terrace.position = Vector3(3.0, TERRACE_TOP - 9.0, -3.0)
	add_child(terrace)

	# The great hall — the mass that makes this "the Meadows Hall" instead of
	# a toy castle: one long gabled block. Yaw puts the ridge PERPENDICULAR
	# to the shared village/path bearing (~(0.87, -0.5)): the first cut
	# (-0.45) aimed the gable end at the player, and the from-path frame
	# read that triangle-under-the-keep as a mountain apex. The long
	# horizontal eave line is the architecture cue; the gable ends show to
	# cross angles instead.
	_hall(Vector3(2.0, TERRACE_TOP, -1.0), -0.96, stone, roof)

	# Perimeter. Positions are the corners of a ~36m convex polygon biased
	# onto the summit plateau (east), with the keep folded into the perimeter
	# rather than freestanding in the middle of a tiny yard.
	var keep := Vector3(12.0, TERRACE_TOP, -10.0)
	var ne := Vector3(22.0, TERRACE_TOP, 2.0)
	var west := Vector3(-14.0, TERRACE_TOP, 9.0)
	var south := Vector3(-3.0, TERRACE_TOP, -18.0)

	# The keep: SQUARE (a 4-segment cylinder is a tapered square prism), the
	# tallest mass on site, crowned with four unequal corner posts instead
	# of the old cone hat. Apex ~+47m local, a touch over the cone's old
	# 43m, so the landmark's skyline height — the thing wayfinding actually
	# uses — still clears every hill from both player viewpoints.
	var keep_top := _tower(keep, 7.6, 44.0, 4, 0.35, stone)
	_crown(keep, 7.6 * 0.80, keep_top, roof)

	# Three perimeter towers, three different silhouettes, two different
	# plan shapes — repetition of one part was toy tell #3. Which tower gets
	# which top is chosen against the two PLAYER bearings (village square and
	# the Rise path both look along ~(0.87, -0.5)): projected onto the axis
	# perpendicular to that view, south sits ~15m clear of the keep while
	# west sits directly IN FRONT of it — so south, the one with its own sky
	# around it, carries the tall stepped mass, and west stays low and plain,
	# a deliberate near-ground layer over the keep's base rather than a
	# second silhouette fighting it.
	var ne_top := _tower(ne, 4.6, 30.0, 4, 0.2, stone)
	_crenellations(ne, 4.6 * 0.8, ne_top, 8, roof)
	var west_top := _tower(west, 4.4, 18.0, 4, 0.15, stone)
	_crenellations(west, 4.4 * 0.8, west_top, 8, roof)
	var south_top := _tower(south, 4.0, 26.0, 4, 0.5, stone)
	_stepped_mass(south, 4.0 * 0.8, south_top, stone, roof)

	# Curtain walls at VARYING heights — a uniform ribbon was part of the
	# model-kit read. All tops clear the ~16m terrain-occlusion floor earlier
	# rounds measured for the long-range frames (terrace 7 + lowest wall 13.5
	# = 20.5).
	const WALL_THICKNESS := 3.0
	_wall(keep, ne, 20.0, WALL_THICKNESS, stone)
	_wall(ne, west, 18.0, WALL_THICKNESS, stone)
	_wall(west, south, 19.0, WALL_THICKNESS, stone)
	_wall(south, keep, 21.0, WALL_THICKNESS, stone)

	# A small square turret breaking the long (36m) north wall's run. Kept
	# LOW on purpose: at 17m its top filled the sky gap between the keep and
	# the north-east tower from the path bearing, gluing the skyline back
	# into one lump.
	var turret := Vector3(4.0, TERRACE_TOP, 5.5)
	var turret_top := _tower(turret, 3.0, 22.0, 4, 0.55, stone)
	_crenellations(turret, 3.0 * 0.8, turret_top, 6, roof)

	# Twin-towered gatehouse at the midpoint of the west wall — the wall that
	# faces the village and both player viewpoints. A gate is a scale cue no
	# toy silhouette has: it says "people walk in here."
	_gatehouse(west, south, 19.0, stone, roof)

	# An outer bailey stepping DOWN the rise's shoulder to a small outpost
	# tower. Blind critics (this task) found the bare tan mound dominating
	# both player frames — "a castle on a golf bunker" — the silhouette
	# reading as one symmetric plane, and "no visible fortification running
	# down the ridge to meet the terrain." This run answers all three: dark
	# architecture claiming the shoulder, each top stepping lower than the
	# last, ending in a tower clearly smaller than anything on the summit.
	#
	# ROUTE MATTERS MORE THAN EXISTENCE, a lesson paid for twice. From a low
	# eye, a convex hill leaves exactly two reliably visible zones: the
	# skyline above its profile, and its NEAR face. The first route ran down
	# the near face but ALONG the village bearing, so 30m of wall
	# foreshortened to a few pixels ("a disconnected floating chunk"). The
	# second ran down the north-east shoulder — perpendicular, but on the
	# FAR side of the profile, so the mound's own right shoulder hid it
	# entirely. This one is both at once: ON the village-facing face,
	# running LATERALLY across it from the west corner under the gatehouse
	# toward the east, so both player vantages see ~20m of dark rampart
	# crossing the tan face below the walls. Tops descend 5 -> 3 -> a small
	# end tower; bases at -8/-9 sit below the face's measured lows (-5.5
	# near (-10,11), -4.3 near (0,15)); the run stays 6m+ clear of the
	# authored Rise path's endpoint (local -16, +10) and never crosses it.
	_wall(Vector3(-14.0, -9.0, 9.0), Vector3(-6.0, -9.0, 14.0), 14.0, 2.8, stone)
	_wall(Vector3(-6.0, -8.0, 14.0), Vector3(4.0, -8.0, 16.0), 11.0, 2.8, stone)
	var outpost := Vector3(10.0, -8.0, 17.0)
	var outpost_top := _tower(outpost, 3.0, 18.0, 4, 0.8, stone)
	_crenellations(outpost, 3.0 * 0.86, outpost_top, 6, roof)


## A ShaderMaterial in the landmark's one shader, with the gradient anchored
## to the ground the site actually stands on.
func _material(colour: Color, ground_y: float) -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = SHADER_CODE
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("albedo", colour)
	mat.set_shader_parameter("base_y", ground_y)
	mat.set_shader_parameter("span_y", 38.0)
	return mat


## The gabled great-hall block: box walls and a PrismMesh roof. The prism's
## ridge runs along its local Z, so the roof is yawed 90 degrees relative to
## the box, whose long axis is X.
func _hall(at: Vector3, yaw: float, stone: ShaderMaterial, roof: ShaderMaterial) -> void:
	var walls := MeshInstance3D.new()
	walls.name = "HallWalls"
	var box := BoxMesh.new()
	box.size = Vector3(28.0, 18.0, 12.0)
	box.material = stone
	walls.mesh = box
	walls.position = at + Vector3(0.0, 9.0, 0.0)
	walls.rotation.y = yaw
	add_child(walls)

	var gable := MeshInstance3D.new()
	gable.name = "HallRoof"
	var prism := PrismMesh.new()
	prism.size = Vector3(12.8, 7.5, 28.6)
	prism.material = roof
	gable.mesh = prism
	gable.position = at + Vector3(0.0, 18.0 + 3.75, 0.0)
	gable.rotation.y = yaw + PI / 2.0
	add_child(gable)


## Builds a tapered tower and returns the world-space Y of its flat top, so
## callers can stack roofline geometry on it without recomputing height math.
## `sides` = 4 gives a square prism; `yaw` varies square towers' orientation
## so no two share an angle.
func _tower(at: Vector3, radius: float, height: float, sides: int, yaw: float, mat: ShaderMaterial) -> float:
	var mesh := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = radius * 0.93
	cyl.bottom_radius = radius
	cyl.height = height
	cyl.radial_segments = sides
	cyl.material = mat
	mesh.mesh = cyl
	mesh.position = at + Vector3(0.0, height * 0.5, 0.0)
	mesh.rotation.y = yaw
	add_child(mesh)
	return at.y + height


## The keep's crown: an irregular ring of merlons — two gaps, no two heights
## equal — in place of the old cone. Deterministic, no RNG: a hand-authored
## pattern reads as age without flickering between runs.
func _crown(at: Vector3, top_radius: float, top_y: float, mat: ShaderMaterial) -> void:
	var collar_height := 1.6
	var collar := MeshInstance3D.new()
	var collar_mesh := CylinderMesh.new()
	collar_mesh.top_radius = top_radius * 0.98
	collar_mesh.bottom_radius = top_radius * 1.08
	collar_mesh.height = collar_height
	collar_mesh.radial_segments = 4
	collar_mesh.material = mat
	collar.mesh = collar_mesh
	collar.position = at + Vector3(0.0, top_y - at.y + collar_height * 0.5, 0.0)
	collar.rotation.y = 0.35
	add_child(collar)

	# Four corner posts, no two the same height. The first cut used eight
	# small irregular merlons and the from-path frame read them as knobbly
	# rock lumps at 110m — fewer, larger, squarer masses stay architectural
	# after distance shrinks them. Unequal heights keep the crown from
	# reading as a machined part.
	var heights: Array[float] = [5.2, 4.0, 4.6, 3.4]
	var merlon_width: float = max(top_radius * 0.55, 2.8)
	var base := top_y - at.y + collar_height
	for i in heights.size():
		var h: float = heights[i]
		var angle := 0.35 + TAU / 8.0 + float(i) * TAU / float(heights.size())
		var offset := Vector3(cos(angle), 0.0, sin(angle)) * top_radius * 0.78
		var mesh := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(merlon_width, h, merlon_width)
		box.material = mat
		mesh.mesh = box
		mesh.position = at + offset + Vector3(0.0, base + h * 0.5, 0.0)
		mesh.rotation.y = 0.35
		add_child(mesh)


## A narrower second drum standing on the first — varied massing (a turret
## on a turret) rather than a flat cap, distinct from both the crown and the
## crenellation rings so no two towers on site share a silhouette.
func _stepped_mass(at: Vector3, base_radius: float, base_y: float, stone: ShaderMaterial, roof: ShaderMaterial) -> void:
	var step_radius := base_radius * 0.6
	var step_height := 7.0
	var mesh := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = step_radius * 0.78
	cyl.bottom_radius = step_radius
	cyl.height = step_height
	cyl.radial_segments = 4
	cyl.material = stone
	mesh.mesh = cyl
	mesh.position = at + Vector3(0.0, base_y - at.y + step_height * 0.5, 0.0)
	mesh.rotation.y = 0.15
	add_child(mesh)
	_crenellations(at, step_radius * 0.78, base_y + step_height, 6, roof)


## A ring of alternating merlons around a tower's flat top — the roofline
## silhouette a real curtain wall or keep has and a bare tapered cylinder
## does not.
##
## Round 1 of the R7.1 blind-critic loop found merlons alone "separate into
## three or four separated, pointed teeth that look more like claws, broken
## glass, or a jagged rock spur than a battlement" once the tower shrinks
## with distance. A solid collar under the merlons gives them a continuous
## rim to sit on, so at range it reads as "a solid top with a notched edge"
## rather than "several separate spikes."
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
	collar.position = at + Vector3(0.0, top_y - at.y + collar_height * 0.5, 0.0)
	add_child(collar)

	var merlon_width: float = max(top_radius * 0.8, 2.0)
	var merlon_top_y := top_y - at.y + collar_height
	for i in range(count):
		if i % 2 == 1:
			continue # every other gap is open, so the ring reads as crenellation, not a solid rim
		# unequal tooth heights, deterministic — even teeth read as clip-art
		var merlon_height := 2.6 + 0.6 * float((i * 3) % 3)
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
## fortified perimeter instead of unrelated towers. `from`/`to` carry the
## terrace-top Y; the wall stands on it.
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
	# A blind critic round read evenly-sized, evenly-spaced teeth as "generic
	# castle clip-art... a comb" — so the rhythm is deliberately irregular:
	# width and height vary per tooth on a fixed deterministic pattern (no
	# RNG, so the skyline never flickers between runs).
	var step := 6.2
	var count := int(length / step)
	if count < 1:
		return
	var dir := Vector2(delta.x, delta.z).normalized()
	for i in range(count + 1):
		if i % 2 == 1:
			continue
		var merlon_height := 2.6 + 0.7 * float((i * 5) % 3)
		var merlon_len := step * (0.42 + 0.13 * float((i * 7) % 3))
		var t := (float(i) / float(count) - 0.5) * length
		var pos := mid + Vector3(dir.x, 0.0, dir.y) * t
		var merlon := MeshInstance3D.new()
		var mbox := BoxMesh.new()
		mbox.size = Vector3(merlon_len, merlon_height, thickness * 1.1)
		mbox.material = mat
		merlon.mesh = mbox
		merlon.position = pos + Vector3(0.0, height + merlon_height * 0.5, 0.0)
		merlon.rotation.y = atan2(-delta.z, delta.x)
		add_child(merlon)


## Two square flanking towers astride the village-facing wall with a raised
## lintel block between them — the entrance motif. At 170m the gate opening
## itself would be sub-pixel; the paired-tower-and-lintel silhouette is what
## carries "this is a door", so no opening is cut.
func _gatehouse(from: Vector3, to: Vector3, wall_height: float, stone: ShaderMaterial, roof: ShaderMaterial) -> void:
	var mid := (from + to) * 0.5
	var delta := to - from
	var dir := Vector3(delta.x, 0.0, delta.z).normalized()
	var yaw := atan2(-delta.z, delta.x)
	# Flanker height sits just over the wall line and UNDER the main towers:
	# at 16.5m these tops filled the keep-to-south sky gap from the path
	# bearing and fused the skyline into one mass.
	for s: float in [-3.5, 3.5]:
		var foot := mid + dir * s
		var top := _tower(foot, 2.8, 23.0, 4, yaw, stone)
		_crenellations(foot, 2.8 * 0.86, top, 4, roof)
	var lintel := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(5.4, 3.2, 4.4)
	box.material = roof
	lintel.mesh = box
	lintel.position = mid + Vector3(0.0, wall_height + 1.6, 0.0)
	lintel.rotation.y = yaw
	add_child(lintel)
