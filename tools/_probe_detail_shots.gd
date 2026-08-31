extends SceneTree

## Measures the real subjects of the seven `_capture_locations.gd` detail
## shots that were still using the bare RIG defaults (back 5.0, up 1.60,
## look_up 1.6) when a blind critic named five of forty-five frames as
## photographing dirt instead of their subject. That rig aims 1.6m above the
## LOOK POINT's ground -- correct for a person-height subject, wrong for a
## fire pit near ground level or an apparatus based 10m up on a deck.
##
## COORDINATES ARE NOT INVENTED HERE EITHER. Same rule as the tool this probe
## exists to fix: every look point below is copied verbatim from
## `tools/_capture_locations.gd`'s SITES table (the "apparatus" shot's `at`/
## `look` are relay-local and go through `TetherRelay.world_of()`, exactly as
## `_capture_locations.gd::_resolve()` does it, because re-deriving that
## rotation by hand here would be the second copy of a bug the capture tool's
## own header already warns against).
##
## WHAT "near" MEANS. A node matches a look point when the node's OWN
## `global_position` (not a descendant's) is within 6m of it in X/Z. All of
## the placer scripts in this world (props.gd, village.gd, severed_spokes.gd,
## tether_relay.gd) set an explicit `.position`/`.transform` on the node they
## place, so a placed prop or building's global_position is where it actually
## stands. The GROUP/holder nodes those placers use (`Props`, a cluster
## group, `Village`, `TetherConduits`, a `Spoke_id` holder, `ApparatusSeam`)
## never get their own `.position` set -- they sit at their parent's origin,
## which for every one of these is the world root, so they never spuriously
## match a look point hundreds or thousands of metres from (0,0,0). That is
## what makes a single un-scoped tree walk safe here rather than an
## expensive mistake: the only nodes that can match are the actual placed
## objects, and a match stops the walk from descending into that object's own
## sub-parts (already covered by `RenderBounds.measure`'s subtree merge) while
## every sibling branch keeps searching.
##
## Godot's default keep_aspect is KEEP_WIDTH, so a 70-degree `Camera3D.fov` on
## a 1280x800 (1.6 aspect) viewport is the HORIZONTAL field of view -- half
## angle 35 degrees -- and `_capture_locations.gd::_frame`'s own comment
## ("a 70-degree camera is about +/-23 degrees vertically") is the same
## number arrived at from the vertical side: 2*atan(tan(35deg)/1.6) = 23.6deg.
## Both are used below: width against the 35-degree horizontal half angle,
## height against the 23.6-degree vertical one.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const RENDER_BOUNDS := preload("res://scripts/characters/render_bounds.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const BOOT_FRAMES := 90
const NEAR_RADIUS := 6.0
const HALF_FOV_H := 35.0   # degrees, horizontal half-angle at fov 70
const HALF_FOV_V := 23.6   # degrees, vertical half-angle at fov 70, aspect 1.6

var _world: Node3D = null
var _field: RefCounted = null

## The seven shots verbatim from tools/_capture_locations.gd's SITES table --
## site id, shot label, `at` (player stand point) and `look` (aim point), both
## world metres unless `relay` is true, in which case both are relay-local and
## go through TetherRelay.world_of() below, same as the capture tool.
const SHOTS := [
	{"site": "02-mill-pond", "label": "wheel", "at": [-390.0, 512.0], "look": [-386.0, 514.0]},
	{"site": "03-quarry", "label": "conduit-head", "at": [399.0, 1809.0], "look": [404.0, 1804.0]},
	{"site": "05-relay-camp", "label": "fire", "at": [237.0, 3678.0], "look": [241.4, 3667.3]},
	{"site": "06-relay", "label": "apparatus", "relay": true, "at": [1.0, -4.0], "look": [7.0, -9.0]},
	{"site": "07-mill-crossing", "label": "yard", "at": [-144.0, 4212.0], "look": [-140.0, 4219.0]},
	{"site": "08-ridge-camp", "label": "fire", "at": [-230.0, 6471.0], "look": [-233.1, 6474.3]},
	{"site": "09-waystop", "label": "bench", "at": [-23.0, 7454.0], "look": [-26.5, 7457.0]},
]


func _init() -> void:
	_run()


func _run() -> void:
	_field = HEIGHTFIELD.new()
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in BOOT_FRAMES:
		await physics_frame
	print("[probe] world up, boot settled\n")

	var relay: Node = _world.get_node_or_null(^"TetherRelay")

	for entry: Variant in SHOTS:
		var shot: Dictionary = entry as Dictionary
		var at: Array = shot["at"] as Array
		var look: Array = shot["look"] as Array
		var eye := Vector2(float(at[0]), float(at[1]))
		var target := Vector2(float(look[0]), float(look[1]))
		if bool(shot.get("relay", false)):
			if relay == null or not relay.has_method("world_of"):
				print("### %s-%s: relay:true but TetherRelay is missing world_of()" % [shot["site"], shot["label"]])
				continue
			eye = relay.call("world_of", eye) as Vector2
			target = relay.call("world_of", target) as Vector2

		print("=== %s-%s  eye(%.1f,%.1f)  look(%.1f,%.1f) ===" % [
			shot["site"], shot["label"], eye.x, eye.y, target.x, target.y])

		var matches: Array = []
		_walk(_world, target, matches)

		var ground_at_look := _surface(target)
		print("  ground at look point: %.2f" % ground_at_look)
		if matches.is_empty():
			print("  NOTHING within %.0fm of this look point -- the coordinate is wrong, not the framing.\n" % NEAR_RADIUS)
			continue

		var toward := (target - eye).normalized()
		var aside := Vector2(-toward.y, toward.x).normalized()
		var dist_eye_to_look := eye.distance_to(target)

		for m: Variant in matches:
			var rec: Dictionary = m as Dictionary
			var box: AABB = rec["box"]
			var bottom: float = box.position.y
			var top: float = box.position.y + box.size.y
			var centre_h := (bottom + top) * 0.5
			var width := _project_extent(box, aside)
			var depth := _project_extent(box, toward)
			print("  %-28s bottom %6.2f  top %6.2f  centre_h %6.2f  width(across view) %5.2f  depth(along view) %5.2f  size.xyz (%.2f,%.2f,%.2f)" % [
				str(rec["name"]), bottom, top, centre_h, width, depth,
				box.size.x, box.size.y, box.size.z])
			print("    height above ground at look point (centre_h - ground): %.2f" % (centre_h - ground_at_look))
			# The distance a camera BACKED `back_m` off the player stand point
			# ends up from the subject, along the same toward line
			# `_capture_locations.gd::_shoot` uses (`back := eye - toward*back_m`,
			# and camera-to-look distance grows by back_m since back sits
			# further from `target` than `eye` does on that line).
			var min_dist_w := (width * 0.5) / tan(deg_to_rad(HALF_FOV_H))
			var min_dist_h := (top - centre_h) / tan(deg_to_rad(HALF_FOV_V)) if top > centre_h else 0.0
			var min_dist := maxf(min_dist_w, min_dist_h)
			var back_for_fit := min_dist - dist_eye_to_look
			print("    min camera distance to fit width+height in FOV: %.2f  (=> back >= %.2f, eye is already %.2f from look)" % [
				min_dist, back_for_fit, dist_eye_to_look])
		print("")
	quit(0)


## Stops descending into a matched branch: `RenderBounds.measure` already
## merges the whole matched node's subtree, so a child of a match is not a
## second subject, it is the first one's own geometry.
func _walk(node: Node, target: Vector2, matches: Array) -> void:
	var n3 := node as Node3D
	if n3 != null:
		var gp := n3.global_position
		if Vector2(gp.x, gp.z).distance_to(target) <= NEAR_RADIUS:
			var local_box: AABB = RENDER_BOUNDS.measure(n3)
			if local_box.size.length() > 0.001:
				matches.append({
					"name": "%s (%s)" % [n3.name, str(n3.get_path()).replace(str(_world.get_path()), "")],
					"box": n3.global_transform * local_box,
				})
				return
	for child in node.get_children():
		_walk(child, target, matches)


## The AABB's horizontal footprint (all 4 corners at box.position.y, ignoring
## height) projected onto `axis`, max minus min -- the apparent width a camera
## looking along the perpendicular of `axis` would actually see, not the
## axis-aligned box.size.x/z which overstates a diagonal object's true width.
func _project_extent(box: AABB, axis: Vector2) -> float:
	var lo := INF
	var hi := -INF
	for dx in [0.0, box.size.x]:
		for dz in [0.0, box.size.z]:
			var p := Vector2(box.position.x + dx, box.position.z + dz)
			var d := p.dot(axis)
			lo = minf(lo, d)
			hi = maxf(hi, d)
	return hi - lo


## Copied from `_capture_locations.gd::_surface` verbatim (raycast over the
## streamed collision surface, analytic heightfield as a fallback when the ray
## misses) -- the analytic-vs-collision disagreement that file documents (up
## to 22m near the river) applies here too, and a ground reference for
## `look_up` has to be the one the actual camera rig will ask for.
func _surface(at: Vector2) -> float:
	var analytic: float = _field.height_at(at.x, at.y)
	var space: PhysicsDirectSpaceState3D = (_world as Node3D).get_world_3d().direct_space_state
	if space == null:
		return analytic
	var query := PhysicsRayQueryParameters3D.create(
		Vector3(at.x, analytic + 400.0, at.y), Vector3(at.x, analytic - 400.0, at.y))
	query.collide_with_areas = false
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return analytic
	return float((hit["position"] as Vector3).y)
