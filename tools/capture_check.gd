extends RefCounted

## IS THIS FRAME ACTUALLY THE GAME? A pre-shutter sanity check for capture
## tools, so a shot that silently dropped a whole rendering system fails loudly
## instead of being committed as evidence.
##
##   const CAPTURE_CHECK := preload("res://tools/capture_check.gd")
##   ...
##   CAPTURE_CHECK.require(self, camera)          # aborts the run on a problem
##   CAPTURE_CHECK.warn_only(self, camera)        # prints, returns the problems
##
## WHY THIS EXISTS. The 2026-08-30 blind pass (`ralph/reports/JUDGE-3-2026-08-30.md`
## section 0) opened with the owner's own words about the evidence in this
## backlog:
##
##   "some of those renders are just a bad shot not actual game. the game
##    doesn't have the haze and has real grass"
##
## He was right, and the judge found the same thing independently across two
## unrelated tools: frame after frame of committed lane evidence showing
## bushes, reeds and fern cards standing on a bare splat with not one blade of
## grass between them. Lanes then reasoned from those frames about ground
## palette, scatter density and how empty the world looks -- every one of
## those claims was made against a frame that was missing the single largest
## thing in the real view.
##
## The judge attributed it to "the capture path generally (or software GL)".
## It was neither: `grass_field` follows the camera it was BOUND to, which is
## the gameplay camera, and a capture tool that builds its own Camera3D and
## calls `make_current()` leaves the ring parked somewhere else. 128 scripts in
## `tools/` build their own camera; five rebind the field. `grass_field.gd::
## _follow_camera` now fixes that at the source for all of them. This file is
## the second half of the answer: the source fix cannot help a tool that breaks
## some FUTURE system the same way, and the whole lesson of that judge section
## is that a silently-degraded frame is worse than no frame -- it is evidence
## for the opposite conclusion, and nothing in the image says so.
##
## So this asserts the things a frame cannot tell you it is missing. It is
## deliberately cheap and deliberately narrow: it checks that systems which
## should be drawing ARE drawing, and that the world state is the one the tool
## asked for. It does not judge how anything looks -- that is a blind pass's
## job and this must never become a substitute for one.
##
## T1-STORMWALL (2026-08-30) added the ground/embed and subject checks below,
## after JUDGE-4 (`ralph/reports/JUDGE-4-2026-08-30.md`, evidence-validity
## section) found `H-04-gate-mouth.png` shot from BELOW the terrain -- two
## thirds stone diffuse, one third grass seen edge-on from underneath -- and
## every check above this comment PASSED it, because none of them look at
## WHERE the camera actually is or WHAT it is actually pointed at. Every check
## here still runs at the shutter, same as the ones above: a camera that was
## fine when posed and has since desynced from the ground it is standing on
## (a marker recomputed a frame late, a rig that moved after `look_at`) is
## exactly the class of bug this file exists to catch, and checking earlier
## would miss it the same way `make_current()`-time checks missed the grass
## rebind.

const GRASS_FIELD := preload("res://scripts/world/grass_field.gd")

## How far above the ground height at its own XZ the camera must sit. Not
## zero: a deliberate ankle-height or prone framing shot is not a defect, and
## `Terrain3DData::get_height` is a bilinear sample of a baked heightfield, not
## an exact surface -- a camera resting exactly at a legitimately-posed ground
## level can land a few centimetres under the sampled height by construction.
## H-04's own camera was metres under, not centimetres; this margin is sized
## to never paper over that gap.
const GROUND_CLEARANCE_M := 0.15


## Everything wrong with the world as currently posed, as human-readable lines.
## Empty means the frame is worth keeping.
##
## `camera` is the camera the tool is about to shoot through. Pass it even if
## it is already current -- half the point is catching the case where it is
## NOT, which is how the grass bug hid. `subject` is optional: the node the
## shot exists to prove, when the tool has one (a gate, a creature, an A/B
## pair). Most tools do not and passing nothing says nothing -- this is the
## "ideally" half of the JUDGE-4 routing note, not a new hard requirement on
## every caller.
static func problems(tree: SceneTree, camera: Camera3D, want_weather := "clear",
		subject: Node3D = null) -> Array[String]:
	var out: Array[String] = []
	if camera == null or not is_instance_valid(camera):
		out.append("no capture camera")
		return out

	var viewport := camera.get_viewport()
	var current := viewport.get_camera_3d() if viewport != null else null
	if current != camera:
		out.append("the capture camera is not the current one (current: %s) -- " % [
			current.name if current != null else "<none>"] +
			"the frame will be shot through a different eye than the one posed")

	out.append_array(_grass_problems(tree, camera))
	out.append_array(_terrain_problems(tree, camera))
	out.append_array(_ground_problems(tree, camera))
	out.append_array(_embedded_problems(camera))
	out.append_array(_weather_problems(tree, want_weather))
	if subject != null:
		out.append_array(_subject_problems(camera, subject))
	return out


## The grass field: present when config says so, following this camera, and
## actually holding instances.
##
## The three failures are separate on purpose because they need different
## fixes. Absent means the world did not stand it up (wrong scene, or the boot
## did not finish -- `playground_world.gd::_ready` is a coroutine and a tool
## that waits too few frames photographs a half-built world). Following the
## wrong camera is the bug this file was written for. Zero instances means it
## stood up and built nothing, which is a real defect and not a capture one.
static func _grass_problems(tree: SceneTree, camera: Camera3D) -> Array[String]:
	var out: Array[String] = []
	if not GRASS_FIELD.is_enabled():
		return out
	var field := _find(tree.current_scene if tree.current_scene != null else tree.root, "GrassField")
	if field == null:
		out.append("grass_field.json says the field is ON but no GrassField node exists in the " +
			"tree -- the ground in this frame is bare splat plus baked scatter, which is NOT " +
			"what the game draws (JUDGE-3 section 0)")
		return out
	# Read through `get` rather than a typed call: this file is a checker and
	# must never be the reason a capture crashes.
	var followed: Variant = field.get("_camera")
	if followed != camera:
		out.append("the GrassField is following '%s', not the capture camera '%s' -- " % [
			(followed as Node).name if followed is Node else "<none>", camera.name] +
			"the grass ring is centred somewhere this frame does not show")
	var mm: MultiMesh = field.get("multimesh")
	if mm == null or mm.instance_count <= 0:
		out.append("the GrassField exists but holds no instances -- nothing to draw")
	return out


## Terrain3D streams around whatever camera it was handed, so a tool that poses
## a camera without telling it photographs whatever coarse LOD the gameplay rig
## last parked on. Every capture tool in this repo that gets this right does it
## by hand; this is the same class of bug as the grass one and worth the same
## check, but it is a WARNING rather than an error because a frame with coarse
## far LOD is degraded, not fictional.
static func _terrain_problems(tree: SceneTree, camera: Camera3D) -> Array[String]:
	var out: Array[String] = []
	var terrain := _find_terrain(tree.current_scene if tree.current_scene != null else tree.root)
	if terrain == null:
		return out
	if not terrain.has_method("get_camera"):
		return out
	var held: Variant = terrain.call("get_camera")
	if held != camera:
		out.append("Terrain3D is streaming around '%s', not the capture camera -- " % [
			(held as Node).name if held is Node else "<none>"] +
			"call terrain.set_camera(camera) before framing")
	return out


## The camera is not at or below the ground it stands on. This is the H-04
## check: samples `Terrain3DData::get_height` at the camera's own XZ -- the
## same call `playground_world.gd::ground_height_at` already uses to place
## everything else in this project, so this checker trusts nothing about
## terrain height it did not already trust -- and fails if the camera's Y is
## at or under that surface (past `GROUND_CLEARANCE_M`). A camera under the
## heightfield renders the underside of the terrain mesh (stone diffuse, the
## triplanar material's cliff/underside face) and any grass geometry above it
## edge-on from beneath, which is exactly what JUDGE-4 described.
##
## Says nothing when there is no Terrain3D or no baked data at this XZ (NAN):
## a stage scene with a bare `PlaneMesh` and no heightfield, same carve-out
## `_terrain_problems` above already makes, has nothing for this to compare
## against.
static func _ground_problems(tree: SceneTree, camera: Camera3D) -> Array[String]:
	var out: Array[String] = []
	var terrain := _find_terrain(tree.current_scene if tree.current_scene != null else tree.root)
	if terrain == null:
		return out
	var data: Object = terrain.get("data")
	if data == null or not data.has_method("get_height"):
		return out
	var pos := camera.global_position
	var ground := float(data.call("get_height", Vector3(pos.x, 0.0, pos.z)))
	if is_nan(ground):
		return out
	if pos.y <= ground + GROUND_CLEARANCE_M:
		out.append(("the capture camera sits at y=%.2f, at or below the terrain height %.2f " +
			"at its own XZ (%.2fm clearance required) -- this is a below-ground shot, the " +
			"JUDGE-4 H-04-gate-mouth.png defect (ralph/reports/JUDGE-4-2026-08-30.md)") % [
			pos.y, ground, GROUND_CLEARANCE_M])
	return out


## The camera is not standing inside a solid body. Broader than the ground
## check above and catches what it cannot: a camera embedded in a wall, a
## rock or a hillside has no defect in `get_height`'s eyes, because that only
## knows about the open terrain surface, not what stands on it. A point query
## against the physics world is the general form of "is this position inside
## geometry" -- it is what `PhysicsDirectSpaceState3D.intersect_point` exists
## for.
##
## Best-effort by design: no physics space, or a query that returns nothing
## usable, says nothing rather than failing a frame this checker cannot
## actually assess. This must never be the reason a capture crashes.
static func _embedded_problems(camera: Camera3D) -> Array[String]:
	var out: Array[String] = []
	var world := camera.get_world_3d()
	if world == null:
		return out
	var space := world.direct_space_state
	if space == null:
		return out
	var query := PhysicsPointQueryParameters3D.new()
	query.position = camera.global_position
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var hits := space.intersect_point(query, 1)
	if hits.is_empty():
		return out
	var collider: Variant = hits[0].get("collider")
	var who: String = (collider as Node).name if collider is Node else "unnamed geometry"
	out.append("the capture camera's own position is inside '%s' -- " % who +
		"the shutter would open behind a solid surface, not the scene the tool posed")
	return out


## The named subject of the shot is actually somewhere in it. Optional: most
## capture tools have no single "the thing this frame is about" and this says
## nothing when `subject` is null. When a tool DOES know what it is proving --
## a gate, a creature, an A/B pair -- this is the check JUDGE-4's Q2-D12 named:
## eight A/B close-ups with a subject pushed to the frame edge or cropped by
## it, the same blind spot as H-04's camera pointed at nothing the shot could
## name.
##
## Projects every corner of the subject's own world-space visual AABB through
## the camera -- not just its centre, since a subject half off one edge is
## still a failing frame even though its centre is on screen -- and fails only
## if NONE of the projected bounds overlap the viewport. A corner behind the
## camera is dropped rather than treated as "off to one side":
## `unproject_position` does not know it is behind the camera and returns a
## meaningless mirrored point for those.
static func _subject_problems(camera: Camera3D, subject: Node3D) -> Array[String]:
	var out: Array[String] = []
	if not is_instance_valid(subject):
		return out
	var corners := _world_aabb_corners(subject)
	if corners.is_empty():
		return out
	var viewport := camera.get_viewport()
	var size := viewport.get_visible_rect().size if viewport != null else Vector2.ZERO
	if size.x <= 0.0 or size.y <= 0.0:
		return out
	var any_in_front := false
	var min_pt := Vector2(INF, INF)
	var max_pt := Vector2(-INF, -INF)
	for corner: Vector3 in corners:
		if camera.is_position_behind(corner):
			continue
		any_in_front = true
		var screen := camera.unproject_position(corner)
		min_pt = Vector2(minf(min_pt.x, screen.x), minf(min_pt.y, screen.y))
		max_pt = Vector2(maxf(max_pt.x, screen.x), maxf(max_pt.y, screen.y))
	if not any_in_front:
		out.append("'%s' is entirely behind the capture camera -- the frame cannot show it" %
			subject.name)
		return out
	var screen_rect := Rect2(Vector2.ZERO, size)
	var subject_rect := Rect2(min_pt, max_pt - min_pt)
	if not screen_rect.intersects(subject_rect):
		out.append(("'%s' projects to %s, entirely outside the %s frame -- " % [
			subject.name, str(subject_rect), str(size)]) +
			"the named subject is not in this shot")
	return out


## Every corner of `node`'s own combined visual AABB, in world space. Walks
## VisualInstance3D descendants so a subject built from several parts (a rig,
## an assembled prop) is measured as one bounding volume rather than needing
## its own `get_aabb()`. Falls back to the node's own position when nothing
## visual is found under it, so a bare marker Node3D can still be a subject.
static func _world_aabb_corners(node: Node3D) -> Array[Vector3]:
	var combined: Variant = _collect_world_aabb(node)
	if combined == null:
		return [node.global_position]
	var box: AABB = combined
	var corners: Array[Vector3] = []
	for i in 8:
		corners.append(box.get_endpoint(i))
	return corners


static func _collect_world_aabb(node: Node3D) -> Variant:
	var result: Variant = null
	if node is VisualInstance3D:
		var local: AABB = (node as VisualInstance3D).get_aabb()
		result = node.global_transform * local
	for child in node.get_children():
		if child is Node3D:
			var child_box: Variant = _collect_world_aabb(child)
			if child_box != null:
				result = (result as AABB).merge(child_box) if result != null else child_box
	return result


## Print every problem loudly and abort the run. For a tool whose whole output
## is evidence: a committed frame that quietly lost a system is worse than no
## frame at all, so the default is to refuse to write one.
static func require(tree: SceneTree, camera: Camera3D, want_weather := "clear",
		subject: Node3D = null) -> void:
	var found := problems(tree, camera, want_weather, subject)
	if found.is_empty():
		print("[capture_check] ok -- grass field bound to this camera and drawing")
		return
	print("")
	print("CAPTURE CHECK FAILED -- this frame would not show the build.")
	for line: String in found:
		print("  * %s" % line)
		push_error("[capture_check] %s" % line)
	print("")
	print("See tools/capture_check.gd's own header and JUDGE-3 section 0 for why")
	print("this refuses rather than warns. If a tool legitimately wants a frame")
	print("without one of these systems, it should say so in its own header and")
	print("call warn_only().")
	tree.quit(1)


## Same checks, no abort. For a tool that deliberately photographs a world with
## a system switched off, and for retrofitting the check onto existing tools
## without changing what they produce today.
static func warn_only(tree: SceneTree, camera: Camera3D, want_weather := "clear",
		subject: Node3D = null) -> Array[String]:
	var found := problems(tree, camera, want_weather, subject)
	for line: String in found:
		print("[capture_check] WARNING: %s" % line)
		push_warning("[capture_check] %s" % line)
	if found.is_empty():
		print("[capture_check] ok -- grass field bound to this camera and drawing")
	return found


## The weather the frame is actually being shot under, against the one the tool
## asked for.
##
## The other half of JUDGE-3 section 0: alongside the missing grass, the owner
## said "the game doesn't have the haze", and the judge found "a milky haze at
## the horizon ... where the far terrain goes flat pale and detail simply
## stops" in the T1-CAST band24 set and in the night set -- while its own fresh
## captures on the same `main`, with a tool that pins and freezes the clock,
## came back with "real cloud detail, real value range, no milky horizon". Same
## build, same day. So the haze is not something the game has and is not the
## aerial-perspective shader either (that is on in both sets); it tracks which
## TOOL took the shot, and the tools without it are the ones that pin weather.
##
## `_capture_ground_and_sky.gd`'s own header already carries the lesson in
## capitals -- "Pin the clock AND FREEZE both WorldLook/WorldWeather -- a pin
## that is not frozen wears off across a multi-viewpoint pass and the later
## frames come back in a dusk wash under whatever weather rolled underneath."
## `capture_water.gd` is on record as having shipped exactly that failure.
## This turns that from a comment one tool author read into a check every tool
## can run.
##
## Default `want_weather` is "clear" because that is what almost every evidence
## frame in this project intends. A tool deliberately photographing rain or fog
## passes its own name and this says nothing.
static func _weather_problems(tree: SceneTree, want_weather: String) -> Array[String]:
	var out: Array[String] = []
	var weather := _find(tree.current_scene if tree.current_scene != null else tree.root, "WorldWeather")
	if weather == null or not weather.has_method("weather"):
		return out
	var now := str(weather.call("weather"))
	if want_weather != "" and now != want_weather:
		out.append("the world is in '%s' weather, not the '%s' this shot asked for -- " % [
			now, want_weather] +
			"an unpinned preset is how frames pick up haze and dusk washes the build does not have")
	# A pin that is still ticking is a pin that wears off. Frozen means
	# `set_process(false)`, which is what every tool that gets this right does.
	if weather.is_processing():
		out.append("WorldWeather is still processing -- the weather pin will drift across a " +
			"multi-shot pass; call set_process(false) after setting it")
	return out


## The Terrain3D node, found by CLASS rather than by name. T1-STORMWALL
## (2026-08-30): the by-name `_find(..., "Terrain3D")` this file's own terrain
## checks used to run was silently dead in this project -- `playground_world.gd`
## names its instance `terrain.name = "Terrain"`, so a search for the literal
## string "Terrain3D" never matched it and both `_terrain_problems` and the
## ground check below always fell through their "no terrain" carve-out,
## finding nothing to warn or fail on. `get_class()` reads the engine class
## regardless of what the scene author named the instance, so this is the one
## lookup here that cannot be defeated by a rename.
static func _find_terrain(from: Node) -> Node:
	if from == null:
		return null
	if from.get_class() == "Terrain3D":
		return from
	for child in from.get_children():
		var hit := _find_terrain(child)
		if hit != null:
			return hit
	return null


## First node named `want` anywhere under `from`. Searched by name rather than
## by class so this file needs no preloads of the world's own scripts beyond
## the one it genuinely reads config from.
static func _find(from: Node, want: String) -> Node:
	if from == null:
		return null
	if from.name == want:
		return from
	for child in from.get_children():
		var hit := _find(child, want)
		if hit != null:
			return hit
	return null
