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
		subject: Node3D = null, ignore_bodies: Array = []) -> Array[String]:
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
	out.append_array(_embedded_problems(camera, ignore_bodies))
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
	# The current GrassField splits the ring into cullable child tiles, so the
	# parent intentionally has no MultiMesh.  `_ring_instances` is the shipped
	# field's authoritative live count; retain the parent-MultiMesh fallback for
	# capture scenes that still build the older untiled representation.
	if not _field_has_instances(field):
		out.append("the GrassField exists but holds no instances -- nothing to draw")
	return out


static func _field_has_instances(field: Object) -> bool:
	var ring_instances := int(field.get("_ring_instances"))
	var mm: MultiMesh = field.get("multimesh")
	return ring_instances > 0 or (mm != null and mm.instance_count > 0)


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
static func _embedded_problems(camera: Camera3D, ignore_bodies: Array = []) -> Array[String]:
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
	# T1-HALL-3: was `intersect_point(query, 1)`, which reported whatever the
	# physics server happened to return FIRST and stopped. That is a real hole
	# in this check, not a tuning detail: many capture tools deliberately park
	# the player body AT the camera so the grass ring and the terrain bubble
	# stream to the stand (this file's own header is about exactly that class
	# of bug), so the one hit returned is routinely the tool's own rig -- and a
	# camera buried in BOTH the player and a wall then reports only the player
	# and passes. That is the H-04 defect hiding behind the check written to
	# catch it. Collect several hits and report the first one that is not a
	# body the caller told us to expect.
	var hits := space.intersect_point(query, 8)
	for hit: Dictionary in hits:
		var collider: Variant = hit.get("collider")
		if collider is Node and _is_ignored(collider as Node, ignore_bodies):
			continue
		var who: String = (collider as Node).name if collider is Node else "unnamed geometry"
		out.append("the capture camera's own position is inside '%s' -- " % who +
			"the shutter would open behind a solid surface, not the scene the tool posed")
		return out
	return out


## Is this collider one the caller said to expect? Matched up the ancestor
## chain, because a rig's collider is usually a child of the node a tool holds
## a reference to.
static func _is_ignored(collider: Node, ignore_bodies: Array) -> bool:
	for entry: Variant in ignore_bodies:
		var node := entry as Node
		if node == null:
			continue
		if collider == node or node.is_ancestor_of(collider) or collider.is_ancestor_of(node):
			return true
	return false


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
		subject: Node3D = null, ignore_bodies: Array = []) -> void:
	var found := problems(tree, camera, want_weather, subject, ignore_bodies)
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
		subject: Node3D = null, ignore_bodies: Array = []) -> Array[String]:
	var found := problems(tree, camera, want_weather, subject, ignore_bodies)
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


## ---------------------------------------------------------------------------
## CREATURE PRESENT AND READABLE (W01-ROUTE-STRIP, 2026-09-04).
##
## `_subject_problems` above answers "is the subject's AABB technically on
## screen", and that is the wrong question for a creature game's own evidence:
## a Bramblebun whose bounding box clips one corner of the frame, or that
## projects to eleven pixels of silhouette behind the trainer's shoulder, passes
## it -- and `docs/VISUAL_PARITY_PROGRESS.md` records a blind judge rejecting
## exactly such a fight frame ("the Bramblebun silhouette was too small and the
## trainer was absent"). The route strip's Bar B question -- is this the same
## kind of game? -- can only be asked of a frame where the trainer and the
## creatures are all READABLE, so this is the stricter check the strip refuses
## a frame on.
##
## Pure geometry, on purpose. The unit suite runs under `--script` with no
## main loop (`tests/test_gate_f_instrumentation.gd`'s foot note), so a check
## that leaned on `Camera3D.unproject_position` could never be seen to fail in a
## test. The projection here is the same arithmetic the engine's own
## `unproject_position` performs (`Projection.create_perspective` on the
## camera's vertical FOV and the viewport aspect, then NDC to pixels), and
## `_capture_route_strip.gd` prints the pixel delta between the two on its
## first frame so a drift would be loud rather than silent.
##
## A subject is `{"name": String, "aabb": AABB}` in WORLD space -- the caller
## measures it from the species' declared size or the trainer's own capsule,
## the way `_capture_life.gd` does, never from a skinned mesh's bind-pose
## AABB. Optional `"body": Node3D` is the subject's own physics body, excluded
## from the occlusion rays so a creature is never reported hidden behind
## itself.

## Minimum projected height of a subject as a fraction of the frame's height.
## 0.12 at 720 px is ~86 px of silhouette: enough to name the species and see
## the trainer as a ruler, which is what "readable" means for the two bars.
const READABLE_MIN_HEIGHT_FRAC := 0.12
## How much of the projected rect must lie inside the frame. A subject with a
## quarter of its box cropped by the frame edge is still a subject; one with
## half of it gone is not.
const READABLE_MIN_INSIDE_FRAC := 0.75
## Two subjects whose projected boxes overlap by more than this fraction of
## the smaller box's area are reported: the one behind is, to a viewer, not
## in the frame. Run 2 of W01-ROUTE-STRIP saved a fight frame whose trainer's
## whole box sat inside the companion's silhouette while the occlusion rays
## slipped past the companion's (narrower) collider -- the rays answer "is a
## wall in the way", this answers "is another subject in the way".
const READABLE_MAX_OVERLAP_FRAC := 0.5
## Near plane for the pure projection. Same order as a real Camera3D's default.
const READABLE_NEAR := 0.05


## Screen-space point for `world_point` through a camera at `cam` (its global
## transform) with vertical field of view `fov_deg`, drawing into a viewport
## `size` pixels large. Null when the point is behind the near plane --
## `unproject_position` returns a mirrored, meaningless point there and the
## caller must not treat it as a position.
static func project_point(cam: Transform3D, fov_deg: float, size: Vector2,
		world_point: Vector3) -> Variant:
	if size.x <= 0.0 or size.y <= 0.0:
		return null
	var view := cam.affine_inverse() * world_point
	if view.z > -READABLE_NEAR:
		return null
	var projection := Projection.create_perspective(fov_deg, size.x / size.y, READABLE_NEAR, 4000.0)
	var clip := projection * Vector4(view.x, view.y, view.z, 1.0)
	if is_zero_approx(clip.w):
		return null
	var ndc := Vector2(clip.x / clip.w, clip.y / clip.w)
	return Vector2((ndc.x * 0.5 + 0.5) * size.x, (-ndc.y * 0.5 + 0.5) * size.y)


## The projected screen rect of a world-space box, and whether any corner was
## behind the camera. `rect` is meaningful only when `behind` is false.
static func projected_rect(cam: Transform3D, fov_deg: float, size: Vector2,
		box: AABB) -> Dictionary:
	var min_pt := Vector2(INF, INF)
	var max_pt := Vector2(-INF, -INF)
	for i in 8:
		var screen: Variant = project_point(cam, fov_deg, size, box.get_endpoint(i))
		if screen == null:
			return {"rect": Rect2(), "behind": true}
		var pt: Vector2 = screen
		min_pt = Vector2(minf(min_pt.x, pt.x), minf(min_pt.y, pt.y))
		max_pt = Vector2(maxf(max_pt.x, pt.x), maxf(max_pt.y, pt.y))
	return {"rect": Rect2(min_pt, max_pt - min_pt), "behind": false}


## Everything that makes `subjects` unreadable in a frame shot through `cam`,
## as human-readable lines. Empty means every named subject is present,
## inside the frame, and big enough to read.
##
## An EMPTY subject list is a failure, not a pass: this check exists to refuse
## the frame with nobody in it, and a caller that found no creature to name
## has exactly that frame.
##
## `opts`:
##   min_height_frac  -- override `READABLE_MIN_HEIGHT_FRAC`
##   min_inside_frac  -- override `READABLE_MIN_INSIDE_FRAC`
##   max_height_frac  -- a subject taller than this fraction of the frame is
##                       too close to read as part of a scene (0 = no cap)
##   max_overlap_frac -- override `READABLE_MAX_OVERLAP_FRAC`
##   space            -- a `PhysicsDirectSpaceState3D`; when given, two rays
##                       (camera -> box centre, camera -> three-quarter height)
##                       must not BOTH be stopped by something that is not the
##                       subject's own body. Skipped when null: a stage with no
##                       physics cannot be assessed for occlusion, and this
##                       must never be the reason a capture crashes.
static func readable_problems(cam: Transform3D, fov_deg: float, size: Vector2,
		subjects: Array, opts: Dictionary = {}) -> Array[String]:
	var out: Array[String] = []
	if subjects.is_empty():
		out.append("no subject was named for this frame -- a creature-game frame with " +
			"nobody in it is the exact frame this check exists to refuse")
		return out
	if size.x <= 0.0 or size.y <= 0.0:
		out.append("the viewport has no size; nothing can be measured")
		return out
	var min_height := float(opts.get("min_height_frac", READABLE_MIN_HEIGHT_FRAC))
	var min_inside := float(opts.get("min_inside_frac", READABLE_MIN_INSIDE_FRAC))
	var max_height := float(opts.get("max_height_frac", 0.0))
	var max_overlap := float(opts.get("max_overlap_frac", READABLE_MAX_OVERLAP_FRAC))
	var space: Variant = opts.get("space", null)
	var frame := Rect2(Vector2.ZERO, size)
	var rects: Array = []
	for entry: Variant in subjects:
		var subject: Dictionary = entry if entry is Dictionary else {}
		var name := str(subject.get("name", "subject"))
		if not subject.has("aabb"):
			out.append("'%s' has no bounding box to measure" % name)
			continue
		var box: AABB = subject["aabb"]
		var projected := projected_rect(cam, fov_deg, size, box)
		if bool(projected["behind"]):
			out.append("'%s' has a corner behind the capture camera -- it cannot be read in this frame" % name)
			continue
		var rect: Rect2 = projected["rect"]
		if not frame.intersects(rect):
			out.append("'%s' projects to %s, entirely outside the %s frame" % [name, str(rect), str(size)])
			continue
		var height_frac := rect.size.y / size.y
		if height_frac < min_height:
			out.append(("'%s' is only %.1f%% of the frame's height (%.0f px); %.0f%% is the " +
				"floor for a readable silhouette") % [name, height_frac * 100.0, rect.size.y, min_height * 100.0])
		if max_height > 0.0 and height_frac > max_height:
			out.append("'%s' fills %.0f%% of the frame's height; over %.0f%% it is a close-up, not a subject in a scene" % [
				name, height_frac * 100.0, max_height * 100.0])
		rects.append({"name": name, "rect": rect})
		var visible := frame.intersection(rect)
		var inside_frac := 0.0
		if rect.get_area() > 0.0:
			inside_frac = visible.get_area() / rect.get_area()
		if inside_frac < min_inside:
			out.append("'%s' is cropped by the frame edge: only %.0f%% of its box is inside (%.0f%% required)" % [
				name, inside_frac * 100.0, min_inside * 100.0])
		if space is PhysicsDirectSpaceState3D:
			var blocker := _occluder(space as PhysicsDirectSpaceState3D, cam.origin, box,
				subject.get("body", null), subjects)
			if blocker != "":
				out.append("'%s' is hidden behind '%s' from this camera -- present in the world, unreadable in the frame" % [
					name, blocker])
	if max_overlap > 0.0:
		for i in rects.size():
			for j in range(i + 1, rects.size()):
				var a: Rect2 = rects[i]["rect"]
				var b: Rect2 = rects[j]["rect"]
				var smaller := minf(a.get_area(), b.get_area())
				if smaller <= 0.0:
					continue
				var shared := a.intersection(b).get_area() / smaller
				if shared > max_overlap:
					out.append("'%s' and '%s' overlap on screen by %.0f%% of the smaller one -- one is hiding the other" % [
						str(rects[i]["name"]), str(rects[j]["name"]), shared * 100.0])
	return out


## The same check, read off a live camera: its global transform, vertical FOV,
## the size of the viewport it draws into, and its world's physics space for
## the occlusion rays. For a tool at the shutter.
static func readable_problems_for_camera(camera: Camera3D, subjects: Array,
		opts: Dictionary = {}) -> Array[String]:
	if camera == null or not is_instance_valid(camera):
		var out: Array[String] = ["no capture camera"]
		return out
	var viewport := camera.get_viewport()
	var size := viewport.get_visible_rect().size if viewport != null else Vector2.ZERO
	var merged := opts.duplicate()
	if not merged.has("space"):
		var world := camera.get_world_3d()
		merged["space"] = world.direct_space_state if world != null else null
	return readable_problems(camera.global_transform, camera.fov, size, subjects, merged)


## Name of whatever stops BOTH occlusion rays before they reach the subject,
## or "" when at least one ray gets through. The subject's own body (and any
## collider under it) is excluded from the query, not skipped after the fact:
## a ray that stops on the subject's own capsule has reached the subject.
static func _occluder(space: PhysicsDirectSpaceState3D, from: Vector3, box: AABB,
		own_body: Variant, _all_subjects: Array) -> String:
	var exclude: Array[RID] = []
	if own_body is Node:
		_collect_rids(own_body as Node, exclude)
	var centre := box.get_center()
	var upper := Vector3(centre.x, box.position.y + box.size.y * 0.75, centre.z)
	var blockers: Array[String] = []
	for target: Vector3 in [centre, upper]:
		var query := PhysicsRayQueryParameters3D.create(from, target)
		query.exclude = exclude
		query.collide_with_areas = false
		var hit: Dictionary = space.intersect_ray(query)
		if hit.is_empty():
			return ""
		# A hit INSIDE the subject's own box counts as reaching it (a collider
		# the exclude list did not know about, or terrain the creature stands
		# on at its feet).
		var at: Vector3 = hit.get("position", target)
		if box.grow(0.05).has_point(at):
			return ""
		var collider: Variant = hit.get("collider")
		blockers.append((collider as Node).name if collider is Node else "unnamed geometry")
	return blockers[0] if not blockers.is_empty() else ""


static func _collect_rids(node: Node, into: Array[RID]) -> void:
	if node is CollisionObject3D:
		into.append((node as CollisionObject3D).get_rid())
	for child in node.get_children():
		_collect_rids(child, into)


## Smallest camera distance along `bearing` (a unit vector pointing FROM the
## focus TOWARD where the camera should stand, horizontal) at which every
## subject's projected box sits inside the frame with `margin_frac` of the
## frame's size kept clear on each edge. The camera is placed at
## `focus + bearing * d + (0, height, 0)` and aimed at `focus + (0, look_up, 0)`.
##
## This is the "camera distance solved against all three projected bounds"
## that `docs/VISUAL_PARITY_PROGRESS.md`'s route-strip investigation named as
## the first of its two lessons: a distance solved for the two creatures left
## the trainer out of the fight frame. Stepped rather than closed-form because
## the bound is a max over eight corners of several boxes, and a 0.25 m step
## is finer than any framing difference a judge could see.
##
## `max_height_frac`, when positive, keeps stepping out past the first fit
## until no subject is taller than that fraction of the frame: the first fit
## puts the nearest body at the safe-area edge, which for a looming companion
## is a close-up with the scene behind it (W01 run 2: 69% of the frame).
##
## `min_height_frac`, when positive, additionally requires the SMALLEST
## subject to reach that fraction. Without it the solve is free to satisfy
## everything else by standing far enough back that the smallest fighter is a
## smudge: W01 run 3 framed a mudsnout at 14.5% of frame height, passed every
## other rule, and the code-blind judge reported the opponent as unreadable
## and ambiguous with a background prop. The two bounds together state the
## real requirement -- nobody a close-up, nobody a smudge -- and a bearing
## where they cannot both hold returns -1.0 so the caller tries another.
##
## Returns -1.0 when no distance in [`d_min`, `d_max`] fits everything.
static func fit_distance(focus: Vector3, bearing: Vector3, height: float, look_up: float,
		fov_deg: float, size: Vector2, subjects: Array, margin_frac := 0.06,
		d_min := 3.0, d_max := 30.0, step := 0.25, max_height_frac := 0.0,
		min_height_frac := 0.0) -> float:
	var flat := Vector3(bearing.x, 0.0, bearing.z)
	if flat.length() < 0.001:
		return -1.0
	flat = flat.normalized()
	var safe := Rect2(size * margin_frac, size * (1.0 - 2.0 * margin_frac))
	var d := d_min
	while d <= d_max + 0.0001:
		var cam := camera_transform_at(focus, flat, d, height, look_up)
		var all_in := true
		for entry: Variant in subjects:
			var subject: Dictionary = entry if entry is Dictionary else {}
			if not subject.has("aabb"):
				continue
			var projected := projected_rect(cam, fov_deg, size, subject["aabb"])
			if bool(projected["behind"]) or not safe.encloses(projected["rect"]):
				all_in = false
				break
			var box_h: float = (projected["rect"] as Rect2).size.y
			if max_height_frac > 0.0 and box_h > size.y * max_height_frac:
				all_in = false
				break
			if min_height_frac > 0.0 and box_h < size.y * min_height_frac:
				all_in = false
				break
		if all_in:
			return d
		d += step
	return -1.0


## The transform `fit_distance` evaluates: standing `distance` metres from
## `focus` along `bearing`, `height` above it, looking at `focus + look_up`.
static func camera_transform_at(focus: Vector3, bearing: Vector3, distance: float,
		height: float, look_up: float) -> Transform3D:
	var origin := focus + bearing * distance + Vector3(0.0, height, 0.0)
	var target := focus + Vector3(0.0, look_up, 0.0)
	var xform := Transform3D(Basis.IDENTITY, origin)
	return xform.looking_at(target, Vector3.UP)
