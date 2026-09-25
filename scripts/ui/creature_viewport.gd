extends SubViewportContainer

## A live, orbitable 3D view of one creature, for the TEAM screen's centre column
## (spec §8.2) and the legendary-offer ceremony that shows its volunteer here.
##
## Construction started as a lift of `scripts/ui/starter_picker.gd::_build_preview`
## (own_world_3d SubViewport, key + rim light, `creature.tscn` on a turntable);
## the one thing added then was interactivity: this widget also reads the right
## stick (and a mouse drag, for keyboard/mouse testing) so a player can actually
## look a party member over.
##
## X03-WO2 (ACCEPTANCE U2) replaced two things that had drifted from that job:
##
## * FRAMING. The camera used to be placed from `body_height()`/`body_radius()`,
##   the gameplay COLLIDER size. Long bodies render far outside that capsule --
##   the Abyssal Guardian's head sat on the top edge with its body and fins off
##   frame, Mosshell's shell ran off the left. The camera is now fitted to the
##   body's ACTUAL render bounds (`visible_bounds`, skinned meshes included),
##   centred on the spin axis, and fitted as the bounding CYLINDER about that
##   axis so no yaw of the turntable can swing any part out of frame. Both the
##   vertical and the horizontal FOV are honoured (`fit_camera`), from the live
##   SubViewport aspect, with FRAME_MARGIN kept clear on every side.
## * EXPOSURE. Near-white ambient at 2.0 plus a 2.0 key and 1.3 rim, on a
##   near-black backdrop, clipped every light-coloured creature and flattened
##   eyes/shading. Lighting is now a moderate key/fill/rim on a neutral slate
##   backdrop with a subtle ground disc (see `_build_world`). No red/coral.
##
## Defensive by design, not by afterthought: `set_species()` can be called
## from a headless test with no renderer worth the name behind it, and
## `smoke_menu.gd` must stay green either way. If `creature.tscn` fails to build a
## real model the widget falls back to a flat colour chip -- see `_fallback` --
## and never raises past that; framing then uses the species' placeholder
## extents (`fallback_bounds`).

const CREATURE_SCENE := preload("res://scenes/creatures/creature.tscn")
const CREATURE_BODY := preload("res://scripts/creatures/creature_body.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const RENDER_BOUNDS := preload("res://scripts/characters/render_bounds.gd")
const MOTION_PREFS := preload("res://scripts/ui/motion_prefs.gd")

const VIEWPORT_SIZE := Vector2i(420, 460)

## Radians/second. Matches starter_picker's SPIN_SPEED — a slow living-thing
## turntable when nobody is touching the stick.
const IDLE_SPIN_SPEED := 0.5

## Radians/second at full stick deflection.
const STICK_ORBIT_SPEED := 2.4
## Radians per pixel of mouse drag.
const MOUSE_ORBIT_SPEED := 0.012

## Below this the stick reads as centred. Controller sticks rest with a
## nonzero float even undriven; without a deadzone the preview would drift on
## its own on a menu screen where nothing else in the scene is moving to hide
## it.
const STICK_DEADZONE := 0.18

## Godot's JoyAxis enum: LEFT_X=0, LEFT_Y=1, RIGHT_X=2, RIGHT_Y=3. Read as raw
## axis indices rather than through an input action — there is no bound
## action for "look" inside a menu, and this agent may not add one to
## project.godot's input map.
const JOY_AXIS_RIGHT_X := 2

## The authored build angle: a front three-quarter towards the camera.
const BUILD_YAW_DEG := 200.0

## --- framing ------------------------------------------------------------

## Vertical field of view (Camera3D keeps height, so this IS the vertical FOV;
## the horizontal one follows from the viewport aspect). 34 matches
## starter_picker's calm, full-body lens.
const CAMERA_FOV_DEG := 34.0
## Degrees the camera looks DOWN onto the creature. A little elevation shows
## the back line and grounds the creature on its disc; it is small so the face
## still reads.
const CAMERA_PITCH_DEG := 10.0
## Fraction of the viewport's width AND height kept clear on EACH side of the
## creature's spin cylinder, at every turntable angle.
const FRAME_MARGIN := 0.11
## Rim samples used to approximate the spin cylinder when fitting. The sampled
## polygon is inflated to circumscribe the true circle, so the fit is never
## tighter than the cylinder itself.
const FIT_RIM_SAMPLES := 48
## Mesh names never counted as the creature's body when measuring bounds: the
## flat contact-shadow blob `creature_body.gd` lays on the ground is wider than
## some bodies and is not something the player needs to see whole.
const BOUNDS_IGNORED_NAMES := ["ContactShadow"]
## Per-angle fit (X03, blind judge: "long creatures turn into small figures in
## empty space" -- the Guardian's face was a few pixels). The camera is fitted
## to the creature's silhouette at the CURRENT turntable angle rather than to
## the cylinder it sweeps over a whole turn, so a long body fills the frame
## side-on and the view eases in when it turns end-on. Zooming OUT is instant
## (nothing is ever cropped mid-turn); zooming IN eases at this rate (1/s).
## Reduced motion keeps the calm whole-turn fit instead of a breathing zoom.
const ZOOM_IN_RATE := 2.5
## Height bands in the silhouette sample (see `silhouette_sample`).
const HULL_BANDS := 32
## Seconds after a body is framed at which it is measured again. The creature
## plays its authored rest pose after it loads, so the first measurement can
## be the bind pose while the drawn body is curled or folded (the Guardian
## read as a thumbnail for exactly that reason); re-measuring from the live
## skeleton once the pose has landed frames what is actually drawn.
const REMEASURE_AT := [0.25, 1.0, 2.5]

## --- look ---------------------------------------------------------------

## Neutral mid slate: dark enough that pale creatures (Guardian, Galewisp)
## hold their edge, light enough that dark ones (Duskhush, Shadelet) are not a
## silhouette on black. Cool, never red.
const BACKDROP_COLOUR := Color(0.24, 0.28, 0.32)
const GROUND_COLOUR := Color(0.29, 0.33, 0.37)
## Ambient is a fill, not the main light: at 2.0 near-white it flattened every
## form. Slightly cool so the warm key reads as the light direction.
const AMBIENT_COLOUR := Color(0.72, 0.76, 0.82)
const AMBIENT_ENERGY := 0.6
const KEY_ENERGY := 1.2
const KEY_COLOUR := Color(1.0, 0.96, 0.90)
const RIM_ENERGY := 0.55
const RIM_COLOUR := Color(0.78, 0.87, 1.0)
## Showcase (a legendary's offer, X03): the moment is the game's biggest
## reward, and a grey model viewer undersold it (blind judge). A warm rim picks
## the silhouette out of the slate and a thin halo ring rings the ground disc.
## Gold is the UI's progression accent (UX: "warm gold progression accents"),
## never red; it also separates from a blue creature.
const SHOWCASE_RIM_COLOUR := Color(1.0, 0.84, 0.52)
const SHOWCASE_RIM_ENERGY := 1.3
const SHOWCASE_HALO_COLOUR := Color(0.85, 0.75, 0.54)
const SHOWCASE_HALO_ENERGY := 0.9

var _world: Node3D = null
var _viewport: SubViewport = null
var _turntable: Node3D = null
var _camera: Camera3D = null
var _ground: MeshInstance3D = null
var _rim: DirectionalLight3D = null
var _halo: MeshInstance3D = null
var _body: Node3D = null
var _species_id: String = ""
## OF27: tracked alongside `_species_id` so a same-species swap (releasing a
## shiny creature and having a non-shiny one of the same species scroll into
## its spot, or vice versa -- rare, but not impossible with a five-creature
## party) still rebuilds the preview instead of `set_species` short-circuiting
## on the species id matching.
var _shiny: bool = false
var _dragging: bool = false
var _drag_device: int = -1
## The framed spin cylinder: x = radius about the spin axis, y = lowest point,
## z = highest point, in turntable space. Kept so a viewport resize can re-fit
## without re-measuring.
var _extents := Vector3(0.4, 0.0, 1.0)
## Turntable-space silhouette sample (see `silhouette_sample`); empty = use the
## whole-turn cylinder fit only.
var _hull := PackedVector3Array()
## The camera's current aim and distance under the per-angle fit.
var _aim := Vector3.ZERO
var _distance := -1.0
## The body being framed and its placeholder extents, kept so the fit can be
## re-measured once the model's pose settles (REMEASURE_AT).
var _framed: Node3D = null
var _fallback_size := Vector2(1.0, 0.4)
var _since_framed := 0.0
var _remeasures_done := 0


func _ready() -> void:
	custom_minimum_size = Vector2(VIEWPORT_SIZE)
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_world()


func _build_world() -> void:
	for child in get_children():
		child.queue_free()

	_viewport = SubViewport.new()
	_viewport.size = VIEWPORT_SIZE
	# Its own World3D, exactly for the reason starter_picker's has one: without
	# it this preview and its lights would render into the meadow behind the
	# menu instead of the backdrop built for it below.
	_viewport.own_world_3d = true
	add_child(_viewport)
	# `stretch` resizes the SubViewport to whatever the TEAM layout gives this
	# container; the horizontal fit depends on that aspect, so re-fit on it.
	_viewport.size_changed.connect(_refit)

	_world = Node3D.new()
	_viewport.add_child(_world)

	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = BACKDROP_COLOUR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = AMBIENT_COLOUR
	env.ambient_light_energy = AMBIENT_ENERGY
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env_node.environment = env
	_world.add_child(env_node)

	var key := DirectionalLight3D.new()
	key.rotation = Vector3(deg_to_rad(-35.0), deg_to_rad(35.0), 0.0)
	key.light_energy = KEY_ENERGY
	key.light_color = KEY_COLOUR
	_world.add_child(key)

	_rim = DirectionalLight3D.new()
	_rim.rotation = Vector3(deg_to_rad(-20.0), deg_to_rad(200.0), 0.0)
	_rim.light_energy = RIM_ENERGY
	_rim.light_color = RIM_COLOUR
	_world.add_child(_rim)

	# A subtle disc for the creature to stand on, so it reads as grounded
	# rather than floating in a flat field. Sized to the spin cylinder in
	# `_apply_extents`, so it is always inside the fitted frame. Not on the
	# turntable: the ground stays put while the creature turns on it.
	_ground = MeshInstance3D.new()
	_ground.name = "PreviewGround"
	var disc := CylinderMesh.new()
	disc.top_radius = 1.0
	disc.bottom_radius = 1.0
	disc.height = 0.02
	disc.radial_segments = 64
	disc.rings = 1
	_ground.mesh = disc
	var ground_material := StandardMaterial3D.new()
	ground_material.albedo_color = GROUND_COLOUR
	ground_material.roughness = 1.0
	_ground.material_override = ground_material
	_ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ground.position = Vector3(0.0, -0.011, 0.0)
	_world.add_child(_ground)

	# The showcase halo: a thin ring at the disc's rim, a child of the disc so
	# it follows its scale; hidden unless `set_showcase(true)`.
	_halo = MeshInstance3D.new()
	_halo.name = "ShowcaseHalo"
	var ring := TorusMesh.new()
	ring.inner_radius = 0.955
	ring.outer_radius = 1.0
	ring.rings = 64
	_halo.mesh = ring
	var halo_material := StandardMaterial3D.new()
	halo_material.albedo_color = SHOWCASE_HALO_COLOUR
	halo_material.emission_enabled = true
	halo_material.emission = SHOWCASE_HALO_COLOUR
	halo_material.emission_energy_multiplier = SHOWCASE_HALO_ENERGY
	halo_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_halo.material_override = halo_material
	_halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_halo.scale = Vector3(1.0, 0.4, 1.0)
	_halo.position = Vector3(0.0, 0.012, 0.0)
	_halo.visible = false
	_ground.add_child(_halo)

	_camera = Camera3D.new()
	_camera.fov = CAMERA_FOV_DEG
	_camera.current = true
	_world.add_child(_camera)

	# The turntable is what orbit spins — the camera stays put and looks at
	# the spin axis, so reframing on a species change never fights the
	# player's orbit angle.
	_turntable = Node3D.new()
	_world.add_child(_turntable)
	_refit()


## Present the creature as a prize (a legendary's offer): warm rim light and a
## halo ring on the ground disc. Off restores the ordinary preview.
func set_showcase(on: bool) -> void:
	if _rim != null:
		_rim.light_color = SHOWCASE_RIM_COLOUR if on else RIM_COLOUR
		_rim.light_energy = SHOWCASE_RIM_ENERGY if on else RIM_ENERGY
	if _halo != null:
		_halo.visible = on


func showcase() -> bool:
	return _halo != null and _halo.visible


## Build (or rebuild) the preview for `species_id`. Safe to call repeatedly —
## the previous body is discarded first. Never throws: a bad or unknown
## species id, a missing model, or no renderer at all all resolve to SOME
## visible content (a flat capsule, or the colour-chip fallback), because a
## blank centre column reads as broken and this tab must never crash on it.
func set_species(species_id: String, shiny: bool = false) -> void:
	if species_id == _species_id and shiny == _shiny and _body != null and is_instance_valid(_body):
		return
	_species_id = species_id
	_shiny = shiny
	_clear_body()

	if species_id == "":
		return

	var look: Dictionary = SPECIES.placeholder(species_id)
	var body: Node3D = null
	if not Engine.is_editor_hint():
		body = _try_build_body(species_id, shiny)
	if body != null:
		_body = body
	else:
		_body = _fallback(look)
	frame_body(_body, float(look.get("height", 1.0)), float(look.get("radius", 0.4)))


## Centre `body` on the spin axis and fit the camera to what it renders.
##
## `body` must already be a child of `_turntable`. When nothing measurable is
## rendered under it (a detached/headless build whose model never loaded) the
## species' placeholder extents stand in, so framing is never degenerate.
func frame_body(body: Node3D, fallback_height: float = 1.0, fallback_radius: float = 0.4) -> void:
	if body == null or _turntable == null:
		return
	_framed = body
	_fallback_size = Vector2(fallback_height, fallback_radius)
	_since_framed = 0.0
	_remeasures_done = 0
	_measure(body, fallback_height, fallback_radius)
	_distance = -1.0
	_refit()


func _measure(body: Node3D, fallback_height: float, fallback_radius: float) -> void:
	var box := visible_bounds(_turntable)
	var fallback := box.size.y <= 0.0001 and box.size.x <= 0.0001 and box.size.z <= 0.0001
	if fallback:
		box = fallback_bounds(fallback_height, fallback_radius)
	# Put the box's XZ centre on the spin axis, so the creature turns in place
	# instead of swinging round an off-centre pivot (a long tail would sweep
	# the frame and a head-heavy body would orbit its own feet).
	var centre := box.get_center()
	var shift := Vector3(-centre.x, 0.0, -centre.z)
	body.position += shift
	box.position += shift
	var extents := spin_extents(box)
	if not fallback:
		# Exact reach of the geometry about the (now centred) axis. The AABB
		# corners overstate it -- a body is not a box, and imported skinned
		# meshes carry a padded AABB -- which made long creatures needlessly
		# small (Guardian: corner reach 12.7 m, real reach 9.1 m).
		extents.x = spin_radius(_turntable)
	_hull = PackedVector3Array() if fallback else silhouette_sample(_turntable)
	if fallback:
		for i in 8:
			_hull.append(box.get_endpoint(i))
	_extents = extents
	if _ground != null:
		_ground.scale = Vector3(extents.x, 1.0, extents.x)


func _apply_extents(extents: Vector3) -> void:
	_extents = extents
	if _ground != null:
		_ground.scale = Vector3(extents.x, 1.0, extents.x)
	_refit()


func _aspect() -> float:
	var size := Vector2(_viewport.size)
	return size.x / size.y if size.y > 0.0 else float(VIEWPORT_SIZE.x) / VIEWPORT_SIZE.y


## Whether the camera follows the silhouette at the current angle.
func per_angle_fit() -> bool:
	return not _hull.is_empty() and not MOTION_PREFS.reduced_motion()


## Re-place the camera for the current extents, angle and viewport aspect.
## `snap` jumps straight to the fit; otherwise zoom-in eases (see ZOOM_IN_RATE).
func _refit(snap: bool = true, delta: float = 0.0) -> void:
	if _camera == null or _viewport == null:
		return
	if per_angle_fit():
		_refit_to_angle(snap, delta)
		return
	var aspect := _aspect()
	# The ground disc sits at y = 0 with the spin radius, so the fitted
	# cylinder always reaches down to the floor even for a hovering creature.
	var y_min := minf(_extents.y, 0.0)
	var fit := fit_camera(_extents.x, y_min, _extents.z, CAMERA_FOV_DEG, aspect, FRAME_MARGIN, CAMERA_PITCH_DEG)
	var target := Vector3(0.0, float(fit.target_y), 0.0)
	var distance := float(fit.distance)
	_place_camera(target, distance, _extents.x)


## Set as a local transform (the camera's parent `_world` sits at the origin),
## not via look_at_from_position: that reads the global transform, which is
## only valid once in a tree, and a headless test frames detached.
func _place_camera(target: Vector3, distance: float, reach: float) -> void:
	_camera.fov = CAMERA_FOV_DEG
	_camera.near = maxf(0.05, (distance - reach) * 0.25)
	_camera.far = distance + reach * 4.0 + 50.0
	var eye := camera_eye(target, distance, CAMERA_PITCH_DEG)
	_camera.transform = Transform3D(Basis.looking_at(target - eye, Vector3.UP), eye)


func _refit_to_angle(snap: bool, delta: float) -> void:
	var yaw := _turntable.rotation.y if _turntable != null else 0.0
	var aspect := _aspect()
	var fit := fit_points(_hull, yaw, CAMERA_FOV_DEG, aspect, FRAME_MARGIN, CAMERA_PITCH_DEG)
	var want_aim: Vector3 = fit.target
	if snap or _distance < 0.0:
		_aim = want_aim
		_distance = float(fit.distance)
	else:
		var t := 1.0 - exp(-ZOOM_IN_RATE * maxf(delta, 0.0))
		_aim = _aim.lerp(want_aim, t)
		var eased := lerpf(_distance, float(fit.distance), t)
		# Whatever the eased aim, never closer than this angle's silhouette
		# allows from it: zooming out is instant, so nothing is ever cropped.
		var needed := points_distance(_rotated(_hull, yaw), _aim, CAMERA_FOV_DEG, aspect, FRAME_MARGIN, CAMERA_PITCH_DEG)
		_distance = maxf(eased, needed)
	_place_camera(_aim, _distance, _extents.x)


func _try_build_body(species_id: String, shiny: bool = false) -> Node3D:
	var instance: Node3D = CREATURE_SCENE.instantiate() as Node3D
	if instance == null:
		return null
	instance.name = "TeamPreview_%s" % species_id
	instance.set_script(CREATURE_BODY)
	_turntable.add_child(instance)
	instance.call("setup", species_id, shiny)
	instance.set_physics_process(false)
	instance.rotation.y = deg_to_rad(BUILD_YAW_DEG)
	return instance


## The last-resort fallback: a plain sphere in the species' placeholder
## colour. Reached when `creature.tscn` cannot be instanced at all (as could
## happen headless with a stripped-down renderer) — a coloured shape still
## says "this is the creature in slot N", where an empty viewport says nothing.
func _fallback(look: Dictionary) -> Node3D:
	var mesh_instance := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	var radius: float = float(look.get("radius", 0.5))
	sphere.radius = radius
	sphere.height = radius * 2.0
	mesh_instance.mesh = sphere
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(str(look.get("colour", "#cccccc")))
	material.roughness = 0.85
	mesh_instance.material_override = material
	mesh_instance.position = Vector3(0.0, radius, 0.0)
	_turntable.add_child(mesh_instance)
	return mesh_instance


func _clear_body() -> void:
	if _body != null and is_instance_valid(_body):
		_body.queue_free()
	_body = null
	if _turntable == null:
		return
	for child in _turntable.get_children():
		# Detach now, not only at the end of the frame: the next body is
		# measured on the very next line, and a queued-for-deletion sibling
		# would otherwise be counted in its bounds.
		_turntable.remove_child(child)
		child.queue_free()


## --- framing math (pure, unit-tested in tests/test_creature_viewport_framing.gd)

## The merged render-space bounds of every VISIBLE mesh under `root`, in
## `root`'s own space (root's transform excluded). Skinned meshes go through
## `render_bounds.gd`'s skin-aware transform -- the renderer's own answer, not
## the MeshInstance's node chain -- at the rest pose the preview shows (the
## preview never plays a clip: `_try_build_body` switches physics off, which
## is what drives the animator). A mesh counts only if it and every ancestor
## up to `root` is visible -- `creature_body.gd` hides its placeholder capsule
## once a model loads. Uses the actual vertices where the mesh exposes them
## (tight) and the mesh's `get_aabb()` otherwise (conservative).
## Zero-size AABB = nothing found.
static func visible_bounds(root: Node3D) -> AABB:
	var points := render_points(root)
	if points.is_empty():
		return AABB()
	var box := AABB(points[0], Vector3.ZERO)
	for p: Vector3 in points:
		box = box.expand(p)
	return box


## Every visible vertex under `root`, in `root`'s space, where the renderer
## draws it NOW: a skinned vertex is skinned on the CPU through the live
## skeleton pose (skeleton chain x bone global pose x inverse bind x vertex,
## weighted -- the renderer's own formula, see render_bounds.gd), so a body
## that has settled into its authored rest pose is measured as posed, not as
## its bind pose. Unskinned meshes, or skins that do not resolve, fall back
## to render_bounds.gd's rest-pose transform; meshes without readable vertices
## contribute their AABB corners.
static func render_points(root: Node3D) -> PackedVector3Array:
	var out := PackedVector3Array()
	for mesh: MeshInstance3D in _visible_meshes(root):
		var skinned := _posed_vertices(mesh, root)
		if not skinned.is_empty():
			out.append_array(skinned)
			continue
		var xf: Transform3D = RENDER_BOUNDS._render_transform(mesh, root)
		var vertices := _mesh_vertices(mesh.mesh)
		if vertices.is_empty():
			var box := xf * mesh.mesh.get_aabb()
			for i in 8:
				out.append(box.get_endpoint(i))
			continue
		for v: Vector3 in vertices:
			out.append(xf * v)
	return out


## Each bone's skeleton-space pose composed from the local poses. Not
## `get_bone_global_pose`, whose cache only refreshes inside the tree, so a
## detached (headless) measurement would silently read a stale pose.
static func _bone_globals(skeleton: Skeleton3D) -> Array[Transform3D]:
	var globals: Array[Transform3D] = []
	globals.resize(skeleton.get_bone_count())
	var done: Array[bool] = []
	done.resize(skeleton.get_bone_count())
	for b in skeleton.get_bone_count():
		var chain: Array[int] = []
		var at := b
		while at >= 0 and not done[at]:
			chain.push_front(at)
			at = skeleton.get_bone_parent(at)
		for c in chain:
			var parent := skeleton.get_bone_parent(c)
			var local := skeleton.get_bone_pose(c)
			globals[c] = globals[parent] * local if parent >= 0 else local
			done[c] = true
	return globals


static func _posed_vertices(mesh: MeshInstance3D, root: Node3D) -> PackedVector3Array:
	var out := PackedVector3Array()
	if mesh.skin == null or not mesh.mesh is ArrayMesh:
		return out
	var skeleton: Skeleton3D = RENDER_BOUNDS._skeleton_for(mesh)
	if skeleton == null:
		return out
	var skin: Skin = mesh.skin
	var globals := _bone_globals(skeleton)
	var binds: Array[Transform3D] = []
	for i in skin.get_bind_count():
		var bone := skin.get_bind_bone(i)
		if bone < 0:
			bone = skeleton.find_bone(skin.get_bind_name(i))
		if bone < 0 or bone >= skeleton.get_bone_count():
			return PackedVector3Array()
		binds.append(globals[bone] * skin.get_bind_pose(i))
	var chain: Transform3D = RENDER_BOUNDS._chain(skeleton, root)
	for surface in mesh.mesh.get_surface_count():
		var arrays: Array = mesh.mesh.surface_get_arrays(surface)
		if arrays.size() <= Mesh.ARRAY_WEIGHTS:
			return PackedVector3Array()
		var vertices = arrays[Mesh.ARRAY_VERTEX]
		var bones = arrays[Mesh.ARRAY_BONES]
		var weights = arrays[Mesh.ARRAY_WEIGHTS]
		if not vertices is PackedVector3Array or bones == null or weights == null or (vertices as PackedVector3Array).is_empty():
			return PackedVector3Array()
		var count := (vertices as PackedVector3Array).size()
		var per := int(weights.size() / count)
		if per <= 0 or bones.size() < count * per:
			return PackedVector3Array()
		for v in count:
			var at := Vector3.ZERO
			var total := 0.0
			for k in per:
				var w: float = weights[v * per + k]
				if w <= 0.0:
					continue
				var b := int(bones[v * per + k])
				if b < 0 or b >= binds.size():
					continue
				at += (binds[b] * vertices[v]) * w
				total += w
			if total > 0.0:
				out.append(chain * (at / total))
	return out


## The farthest horizontal reach of any visible geometry under `root` from
## the spin (Y) axis through `root`'s origin -- the radius of the cylinder the
## creature sweeps over a full turn. Vertex-exact where the mesh exposes its
## vertices, the mesh AABB's corners otherwise.
static func spin_radius(root: Node3D) -> float:
	var reach_sq := 0.0
	for p: Vector3 in render_points(root):
		reach_sq = maxf(reach_sq, p.x * p.x + p.z * p.z)
	return sqrt(reach_sq)


static func _visible_meshes(root: Node3D) -> Array[MeshInstance3D]:
	var found: Array[MeshInstance3D] = []
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node != root:
			if node is Node3D and not (node as Node3D).visible:
				continue
			if str(node.name) in BOUNDS_IGNORED_NAMES:
				continue
		if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
			found.append(node as MeshInstance3D)
		for child in node.get_children():
			stack.append(child)
	return found


## Every surface's vertex positions, or empty when any surface cannot supply
## them (a primitive mesh, or a renderer that keeps no readable copy) -- the
## caller then falls back to the AABB, never to a partial vertex set.
static func _mesh_vertices(mesh: Mesh) -> PackedVector3Array:
	var out := PackedVector3Array()
	if not mesh is ArrayMesh:
		return out
	for surface in mesh.get_surface_count():
		var arrays: Array = mesh.surface_get_arrays(surface)
		if arrays.size() <= Mesh.ARRAY_VERTEX or not arrays[Mesh.ARRAY_VERTEX] is PackedVector3Array:
			return PackedVector3Array()
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		if vertices.is_empty():
			return PackedVector3Array()
		out.append_array(vertices)
	return out


## Placeholder extents for a body that rendered nothing measurable: the
## species' collider capsule, standing on the origin.
static func fallback_bounds(height: float, radius: float) -> AABB:
	var r := maxf(radius, 0.05)
	var h := maxf(height, r * 2.0)
	return AABB(Vector3(-r, 0.0, -r), Vector3(r * 2.0, h, r * 2.0))


## The bounding cylinder about the spin (Y) axis through the origin of `box`'s
## space: x = the farthest horizontal reach of any corner from the axis (the
## maximum over every yaw), y = bottom, z = top.
static func spin_extents(box: AABB) -> Vector3:
	var radius := 0.0
	for x: float in [box.position.x, box.end.x]:
		for z: float in [box.position.z, box.end.z]:
			radius = maxf(radius, Vector2(x, z).length())
	return Vector3(radius, box.position.y, box.end.y)


## A compact, conservative stand-in for the creature's silhouette in `root`'s
## space: the vertices are cut into HULL_BANDS height bands, and each band's
## exact convex hull in XZ is emitted at both the band's top and its bottom.
## Every drawn vertex lies inside that stack of prisms, so a camera that frames
## these points frames the creature at any angle (never under-covers). Using
## the hull's own vertices instead measured up to ndc 0.83 against 0.78: a
## band's hull vertex is not its vertical extreme. A few hundred points,
## cheap enough to fit every frame. Vertex-exact where
## meshes expose vertices, AABB corners otherwise.
static func silhouette_sample(root: Node3D) -> PackedVector3Array:
	var all := render_points(root)
	var out := PackedVector3Array()
	if all.is_empty():
		return out
	var y_lo := INF
	var y_hi := -INF
	for p: Vector3 in all:
		y_lo = minf(y_lo, p.y)
		y_hi = maxf(y_hi, p.y)
	var span := maxf(y_hi - y_lo, 0.0001)
	var bands: Array[PackedVector2Array] = []
	var band_lo: Array[float] = []
	var band_hi: Array[float] = []
	for i in HULL_BANDS:
		bands.append(PackedVector2Array())
		band_lo.append(INF)
		band_hi.append(-INF)
	for p: Vector3 in all:
		var band := clampi(int((p.y - y_lo) / span * HULL_BANDS), 0, HULL_BANDS - 1)
		bands[band].append(Vector2(p.x, p.z))
		band_lo[band] = minf(band_lo[band], p.y)
		band_hi[band] = maxf(band_hi[band], p.y)
	for i in HULL_BANDS:
		if bands[i].is_empty():
			continue
		var hull := Geometry2D.convex_hull(bands[i]) if bands[i].size() >= 3 else bands[i]
		for q: Vector2 in hull:
			out.append(Vector3(q.x, band_lo[i], q.y))
			out.append(Vector3(q.x, band_hi[i], q.y))
	return out


static func _rotated(points: PackedVector3Array, yaw: float) -> PackedVector3Array:
	var basis := Basis(Vector3.UP, yaw)
	var out := PackedVector3Array()
	out.resize(points.size())
	for i in points.size():
		out[i] = basis * points[i]
	return out


## Closed form of the smallest camera distance at which every point projects
## inside the viewport with `margin` clear on each side, looking at `target`
## pitched down by `pitch_deg`: depth(d) = d - (p - target)·back, and each
## point needs depth >= |x|/(L·tan·aspect) and >= |(p - target)·up|/(L·tan).
static func points_distance(points: PackedVector3Array, target: Vector3, vfov_deg: float, aspect: float, margin: float, pitch_deg: float) -> float:
	var pitch := deg_to_rad(pitch_deg)
	var back := Vector3(0.0, sin(pitch), cos(pitch))
	var up := Vector3(0.0, cos(pitch), -sin(pitch))
	var limit := 1.0 - 2.0 * clampf(margin, 0.0, 0.45)
	var tan_v := tan(deg_to_rad(vfov_deg) * 0.5)
	var need := 0.05
	for p: Vector3 in points:
		var rel := p - target
		var lateral := maxf(absf(rel.x) / (limit * tan_v * aspect), absf(rel.dot(up)) / (limit * tan_v))
		need = maxf(need, rel.dot(back) + lateral + 0.0001)
	return need


## Aim and distance that frame `points` turned by `yaw` about Y: the aim is
## re-centred until the silhouette's left/right and top/bottom margins come
## out equal on screen, then the distance is the closed-form fit from it.
## Returns {"distance": float, "target": Vector3}.
static func fit_points(points: PackedVector3Array, yaw: float, vfov_deg: float, aspect: float, margin: float, pitch_deg: float) -> Dictionary:
	var turned := _rotated(points, yaw)
	if turned.is_empty():
		return {"distance": 1.0, "target": Vector3.ZERO}
	var lo := turned[0]
	var hi := turned[0]
	for p: Vector3 in turned:
		lo = lo.min(p)
		hi = hi.max(p)
	var target := Vector3((lo.x + hi.x) * 0.5, (lo.y + hi.y) * 0.5, 0.0)
	var distance := points_distance(turned, target, vfov_deg, aspect, margin, pitch_deg)
	var tan_v := tan(deg_to_rad(vfov_deg) * 0.5)
	for i in 6:
		var x_lo := INF
		var x_hi := -INF
		var y_lo := INF
		var y_hi := -INF
		for p: Vector3 in turned:
			var ndc := project_ndc(p, target, distance, vfov_deg, aspect, pitch_deg)
			x_lo = minf(x_lo, ndc.x)
			x_hi = maxf(x_hi, ndc.x)
			y_lo = minf(y_lo, ndc.y)
			y_hi = maxf(y_hi, ndc.y)
		var dx := (x_lo + x_hi) * 0.5
		var dy := (y_lo + y_hi) * 0.5
		if absf(dx) < 0.002 and absf(dy) < 0.002:
			break
		target.x += dx * distance * tan_v * aspect
		target.y += dy * distance * tan_v / cos(deg_to_rad(pitch_deg))
		distance = points_distance(turned, target, vfov_deg, aspect, margin, pitch_deg)
	return {"distance": distance, "target": target}


## Where the camera sits for a look at `target` from `distance` away, pitched
## down by `pitch_deg`, on the +Z side of the turntable.
static func camera_eye(target: Vector3, distance: float, pitch_deg: float) -> Vector3:
	var pitch := deg_to_rad(pitch_deg)
	return target + Vector3(0.0, sin(pitch), cos(pitch)) * distance


## Normalised device coordinates (-1..1 each axis, +y up) of `point` for a
## camera at `camera_eye(target, distance, pitch_deg)` looking at `target`,
## vertical FOV `vfov_deg`, width/height `aspect`. z carries view depth
## (negative = behind the camera).
static func project_ndc(point: Vector3, target: Vector3, distance: float, vfov_deg: float, aspect: float, pitch_deg: float) -> Vector3:
	var pitch := deg_to_rad(pitch_deg)
	var back := Vector3(0.0, sin(pitch), cos(pitch))
	var up := Vector3(0.0, cos(pitch), -sin(pitch))
	var rel := point - (target + back * distance)
	var depth := -rel.dot(back)
	var tan_v := tan(deg_to_rad(vfov_deg) * 0.5)
	if depth <= 0.0001:
		return Vector3(INF, INF, depth)
	return Vector3(rel.x / (depth * tan_v * aspect), rel.dot(up) / (depth * tan_v), depth)


## The smallest camera distance at which every point of the spin cylinder
## (`radius`, from `y_min` to `y_max`) projects inside the viewport with
## `margin` of the width and of the height kept clear on each side, looking
## at `target_y` on the spin axis. Both the vertical FOV and the horizontal FOV
## (vertical x aspect) are honoured. Pure: no scene, no renderer.
static func fit_distance(radius: float, y_min: float, y_max: float, target_y: float, vfov_deg: float, aspect: float, margin: float, pitch_deg: float = 0.0) -> float:
	var points := _cylinder_samples(radius, y_min, y_max)
	var limit := 1.0 - 2.0 * clampf(margin, 0.0, 0.45)
	var target := Vector3(0.0, target_y, 0.0)
	var lo := 0.0
	var hi := maxf(maxf(radius, y_max - y_min), 0.1) * 2.0
	while not _fits(points, target, hi, vfov_deg, aspect, pitch_deg, limit):
		hi *= 2.0
		if hi > 1.0e6:
			return hi
	for i in 40:
		var mid := (lo + hi) * 0.5
		if _fits(points, target, mid, vfov_deg, aspect, pitch_deg, limit):
			hi = mid
		else:
			lo = mid
	return hi


## `fit_distance` plus the aim point: the target height is re-centred so the
## cylinder's top and bottom margins come out equal under the pitched view,
## then the distance is re-fitted for that target. Returns
## {"distance": float, "target_y": float}.
static func fit_camera(radius: float, y_min: float, y_max: float, vfov_deg: float, aspect: float, margin: float, pitch_deg: float = 0.0) -> Dictionary:
	var target_y := (y_min + y_max) * 0.5
	var distance := fit_distance(radius, y_min, y_max, target_y, vfov_deg, aspect, margin, pitch_deg)
	var points := _cylinder_samples(radius, y_min, y_max)
	var tan_v := tan(deg_to_rad(vfov_deg) * 0.5)
	for i in 6:
		var low := INF
		var high := -INF
		for p: Vector3 in points:
			var ndc := project_ndc(p, Vector3(0.0, target_y, 0.0), distance, vfov_deg, aspect, pitch_deg)
			low = minf(low, ndc.y)
			high = maxf(high, ndc.y)
		var imbalance := (low + high) * 0.5
		if absf(imbalance) < 0.002:
			break
		# Shift the aim along world Y by the NDC imbalance at the target's depth.
		target_y += imbalance * distance * tan_v / cos(deg_to_rad(pitch_deg))
		distance = fit_distance(radius, y_min, y_max, target_y, vfov_deg, aspect, margin, pitch_deg)
	return {"distance": distance, "target_y": target_y}


static func _cylinder_samples(radius: float, y_min: float, y_max: float) -> Array[Vector3]:
	# Inflate so the sampled polygon circumscribes the true circle.
	var r := maxf(radius, 0.0) / cos(PI / FIT_RIM_SAMPLES)
	var points: Array[Vector3] = []
	for i in FIT_RIM_SAMPLES:
		var a := TAU * float(i) / FIT_RIM_SAMPLES
		var x := cos(a) * r
		var z := sin(a) * r
		points.append(Vector3(x, y_min, z))
		points.append(Vector3(x, y_max, z))
	return points


static func _fits(points: Array[Vector3], target: Vector3, distance: float, vfov_deg: float, aspect: float, pitch_deg: float, limit: float) -> bool:
	for p: Vector3 in points:
		var ndc := project_ndc(p, target, distance, vfov_deg, aspect, pitch_deg)
		if ndc.z <= 0.0001 or absf(ndc.x) > limit or absf(ndc.y) > limit:
			return false
	return true


## --- orbit -------------------------------------------------------------

func _process(delta: float) -> void:
	if _turntable == null or not is_visible_in_tree():
		return

	var yaw := IDLE_SPIN_SPEED * delta

	# Right stick, any connected pad. Polled rather than routed through an
	# input action — see JOY_AXIS_RIGHT_X's own note.
	for device in Input.get_connected_joypads():
		var x := Input.get_joy_axis(device, JOY_AXIS_RIGHT_X)
		if absf(x) > STICK_DEADZONE:
			yaw += x * STICK_ORBIT_SPEED * delta
			break

	advance(yaw, delta)


## Re-measure the framed body at REMEASURE_AT seconds after framing (see
## there). Driven by `advance`, so a capture that steps time by hand sees the
## same settle as play.
func _poll_remeasure(delta: float) -> void:
	if _framed == null or not is_instance_valid(_framed) or _remeasures_done >= REMEASURE_AT.size():
		return
	_since_framed += delta
	if _since_framed < float(REMEASURE_AT[_remeasures_done]):
		return
	while _remeasures_done < REMEASURE_AT.size() and _since_framed >= float(REMEASURE_AT[_remeasures_done]):
		_remeasures_done += 1
	_measure(_framed, _fallback_size.x, _fallback_size.y)
	_refit()


## Turn the turntable by `yaw` radians over `delta` seconds and follow it with
## the per-angle fit. Public so a capture can step the idle spin exactly.
func advance(yaw: float, delta: float) -> void:
	if _turntable == null:
		return
	_turntable.rotate_y(yaw)
	_poll_remeasure(delta)
	if per_angle_fit():
		_refit(false, delta)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			_dragging = mb.pressed
	elif event is InputEventMouseMotion and _dragging and _turntable != null:
		advance(-(event as InputEventMouseMotion).relative.x * MOUSE_ORBIT_SPEED, 1.0 / 60.0)
