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

const GRASS_FIELD := preload("res://scripts/world/grass_field.gd")


## Everything wrong with the world as currently posed, as human-readable lines.
## Empty means the frame is worth keeping.
##
## `camera` is the camera the tool is about to shoot through. Pass it even if
## it is already current -- half the point is catching the case where it is
## NOT, which is how the grass bug hid.
static func problems(tree: SceneTree, camera: Camera3D, want_weather := "clear") -> Array[String]:
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
	out.append_array(_weather_problems(tree, want_weather))
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
	var terrain := _find(tree.current_scene if tree.current_scene != null else tree.root, "Terrain3D")
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


## Print every problem loudly and abort the run. For a tool whose whole output
## is evidence: a committed frame that quietly lost a system is worse than no
## frame at all, so the default is to refuse to write one.
static func require(tree: SceneTree, camera: Camera3D, want_weather := "clear") -> void:
	var found := problems(tree, camera, want_weather)
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
static func warn_only(tree: SceneTree, camera: Camera3D, want_weather := "clear") -> Array[String]:
	var found := problems(tree, camera, want_weather)
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
