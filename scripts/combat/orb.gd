extends Node3D

## A thrown orb: the flight, and then the performance.
##
## A real projectile on a real arc. GAME_DESIGN.md §15 forbids throwing without
## player aim, and a hitscan gives nothing to aim: the arc is what turns "press
## the button while looking at it" into a throw that can be judged, led, and
## missed.
##
## It integrates its own position rather than being a RigidBody3D. The flight is
## a parabola and a handful of sphere checks, the tuning has to be readable in
## data/config/catching.json, and a physics body would put the arc at the mercy
## of engine defaults nobody has a reason to trust.
##
## After the strike the orb is the only actor on stage, and it used to do
## NOTHING: `_spent` froze physics with the flight trail hanging in the sky and
## the orb parked in mid-air for the whole wobble, while a HUD label printed
## dots. The catch resolution — the climax of the game's signature mechanic —
## had no body. So the strike now runs a sequence: hang at the strike point
## while the creature is drawn in, drop to the ground with a bounce, rest with
## a small idle glow, rock physically on each `shake()`, and either `seal()`
## warm on a catch or vanish under the breakout burst. All of it advances on
## the PHYSICS clock (impact_flash.gd's lesson): presentation that only moves
## on render frames is invisible to the survey harness and unreviewable.

const CATCH := preload("res://scripts/combat/catch_math.gd")
const FLASH := preload("res://scripts/combat/impact_flash.gd")

## Struck the target. `offset` is metres from its centre of mass, which is what
## the accuracy half of the catch formula reads.
signal struck(target: Node3D, offset: float)
## Hit the ground, or ran out of flight time, without touching anything.
signal missed()

enum Phase { FLYING, HANGING, DROPPING, RESTING, SEALED, DONE }

var _phase: Phase = Phase.FLYING
var _velocity: Vector3 = Vector3.ZERO
var _gravity: float = 14.0
var _radius: float = 0.42
var _life: float = 0.0
var _max_life: float = 4.0
var _target: Node3D = null
## Bodies this orb passes THROUGH rather than stops on.
##
## BP2, from the 2026-08-22 blind playtest: "your own creature and trainer
## intercept your orbs, and the orb is spent". `_hit_ground()` raycasts along
## the step and excluded only `_target`, so an ally standing between the
## trainer and the wild creature registered as ground -- the orb stopped dead
## and the throw was gone. Your own creature is not cover, and a throw a player
## aimed correctly should not be eaten by the thing fighting for them.
var _pass_through: Array[RID] = []

## The post-strike clocks.
var _hang_total: float = 0.45
var _hang_left: float = 0.45
var _rest_time: float = 0.0
var _shake_left: float = 0.0
var _trail_fade: float = 1.0
var _bounces: int = 0
var _seal_time: float = -1.0

## Flight forensics. A miss reported as one word ("miss") cannot distinguish an
## orb that fell short from one that flew past, and CATCH-FEEL burned three
## wrong diagnoses on that ambiguity. These record how near the orb actually
## got and what ended the flight, so the next question is answered by a number.
var _closest: float = INF
var _closest_at: Vector3 = Vector3.INF
var _end_reason: String = "unknown"
var _ground_collider: String = ""

## How many times the orb's own radius the readable halo is drawn at, and how
## wide the trail gets at its head. Presentation only — the collision radius the
## catch maths reads is untouched by both.
const HALO_SCALE := 5.5
## The halo while the orb is at rest. The flight halo exists so a fast 42cm
## object reads at twelve metres; the resolution plays through a close-up
## (catching.json `resolve_camera`) where 5.5x is a wall of glow.
const REST_HALO_SCALE := 2.2
const TRAIL_WIDTH := 1.1
## Flight positions kept for the trail. About a third of a second at 60Hz.
const TRAIL_POINTS := 20

const HALO_SEGMENTS := 18

## One shake's rock animation. Kept under `resolve.shake_interval` so every
## shake is followed by stillness — the stillness is where the tension lives.
const SHAKE_SECONDS := 0.45
## How far the orb tips to each side during a shake, radians (~34 degrees).
const SHAKE_TILT := 0.6
## The little hop that goes with the rock, metres.
const SHAKE_HOP := 0.14
## Energy kept after the drop's bounce.
const BOUNCE_RESTITUTION := 0.35

## The orb glows hard in flight so four pixels of gold read against sunlit
## grass; the resolution plays at arm's length, where the same emission blew
## the sphere out to a featureless white blob — the first captured close-up
## showed no gold at all. Resting drops low enough that the albedo gold is
## what you see; the halo supplies the glow.
const FLIGHT_EMISSION := 2.2
const REST_EMISSION := 0.45

var _halo: MeshInstance3D = null
var _halo_mesh: ImmediateMesh = null
var _trail: MeshInstance3D = null
var _trail_mesh: ImmediateMesh = null
var _path: PackedVector3Array = PackedVector3Array()
var _orb_material: StandardMaterial3D = null

@onready var _mesh: MeshInstance3D = $Mesh


func _ready() -> void:
	var cfg: Dictionary = CATCH.config().get("throw", {})
	_gravity = float(cfg.get("gravity", _gravity))
	_radius = float(cfg.get("radius", _radius))
	_max_life = float(cfg.get("max_flight_time", _max_life))
	_hang_total = float(CATCH.config().get("resolve", {}).get("absorb_seconds", 0.45))
	_hang_left = _hang_total
	_build_placeholder()


## Placeholder art, and labelled as such. M11 replaces this with the real orb;
## nothing else in this file changes.
##
## But it has to be VISIBLE, which it was not. The blind critic diffed
## `combat/08-orb-in-flight` against the frame before it and found no
## projectile, no trail and no arc anywhere in the image — the largest change in
## the frame was a creature repositioning. A 42cm sphere twelve metres away is
## about four pixels, and four gold pixels over sunlit grass is nothing. The
## signature mechanic of the game was invisible in the frame named after it.
##
## So: a camera-facing halo several times the orb's physical size, and a ribbon
## trail behind it. The COLLISION radius is untouched — the orb still tests at
## exactly the size the catch maths reads, and only the glow around it is
## larger, because an aim you cannot see is not a skill.
func _build_placeholder() -> void:
	var sphere := SphereMesh.new()
	sphere.radius = _radius * 0.5
	sphere.height = _radius
	var material := StandardMaterial3D.new()
	# Gold from the palette board, and emissive so a small fast object stays
	# readable against sunlit grass — which is the entire background of every
	# throw in the Meadows.
	material.albedo_color = Color("#d9b340")
	material.emission_enabled = true
	material.emission = Color("#ffe9a8")
	material.emission_energy_multiplier = FLIGHT_EMISSION
	_mesh.mesh = sphere
	_mesh.material_override = material
	_orb_material = material

	# A dark equator band, child of the sphere so it tilts with it. A uniform
	# glowing sphere shows NO rotation: the first captured shake frame was
	# pixel-identical to the resting frame because there was nothing on the
	# ball for the tilt to move. The band is the feature the rock reads by.
	var band := TorusMesh.new()
	band.inner_radius = _radius * 0.48
	band.outer_radius = _radius * 0.56
	var band_material := StandardMaterial3D.new()
	band_material.albedo_color = Color("#5f4514")
	band_material.roughness = 0.6
	var band_mesh := MeshInstance3D.new()
	band_mesh.mesh = band
	band_mesh.material_override = band_material
	band_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mesh.add_child(band_mesh)

	# A disc with alpha falling to nothing at its rim, rebuilt each frame facing
	# the camera. It was a QuadMesh with a flat colour, which is exactly what it
	# looked like: a hard-edged opaque tan SQUARE hanging in the middle of the
	# frame, drawn over the trainer. A glow needs a gradient or it is a sticker.
	_halo_mesh = ImmediateMesh.new()
	_halo = MeshInstance3D.new()
	_halo.mesh = _halo_mesh
	_halo.material_override = _glow(Color(1.0, 0.85, 0.45, 1.0))
	_halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_halo)

	_trail_mesh = ImmediateMesh.new()
	_trail = MeshInstance3D.new()
	_trail.mesh = _trail_mesh
	_trail.material_override = _glow(Color(1.0, 0.82, 0.40, 1.0))
	_trail.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# The trail is in WORLD space: it is where the orb has been, not where the
	# orb is, so it must not inherit the orb's motion.
	_trail.top_level = true
	add_child(_trail)


func _glow(colour: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	# Depth test ON, unlike the impact flash. An orb passing behind the trainer's
	# shoulder should go behind it; punching through would read as the orb being
	# painted on the lens.
	material.no_depth_test = false
	material.albedo_color = colour
	material.vertex_color_use_as_albedo = true
	return material


## A camera-facing disc, bright at the centre and gone at the rim. `scale_value`
## is in multiples of the orb's radius; `alpha` scales the centre's opacity.
func _draw_halo(scale_value: float, alpha: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var basis := camera.global_transform.basis
	var right: Vector3 = basis.x * _radius * scale_value * 0.5
	var up: Vector3 = basis.y * _radius * scale_value * 0.5

	_halo_mesh.clear_surfaces()
	_halo_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in HALO_SEGMENTS:
		var a: float = TAU * float(i) / float(HALO_SEGMENTS)
		var b: float = TAU * float(i + 1) / float(HALO_SEGMENTS)
		_halo_mesh.surface_set_color(Color(1.0, 0.92, 0.66, 0.85 * alpha))
		_halo_mesh.surface_add_vertex(Vector3.ZERO)
		_halo_mesh.surface_set_color(Color(1.0, 0.78, 0.32, 0.0))
		_halo_mesh.surface_add_vertex(right * cos(a) + up * sin(a))
		_halo_mesh.surface_set_color(Color(1.0, 0.78, 0.32, 0.0))
		_halo_mesh.surface_add_vertex(right * cos(b) + up * sin(b))
	_halo_mesh.surface_end()


## Redraw the trail from the recorded flight path, tapering to nothing at the
## oldest end so it reads as motion rather than as a wire.
func _draw_trail() -> void:
	_trail_mesh.clear_surfaces()
	if _path.size() < 2 or _trail_fade <= 0.01:
		return
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return

	_trail_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for i in _path.size():
		var t: float = float(i) / float(_path.size() - 1)
		var point: Vector3 = _path[i]
		# Widen towards the head. A constant-width ribbon reads as a rope.
		var to_camera: Vector3 = (camera.global_position - point).normalized()
		var along: Vector3 = (_path[mini(i + 1, _path.size() - 1)] - _path[maxi(i - 1, 0)])
		if along.length() < 0.0001:
			along = _velocity
		var side: Vector3 = along.cross(to_camera).normalized() * _radius * TRAIL_WIDTH * t
		var alpha: float = t * t * 0.85 * _trail_fade
		_trail_mesh.surface_set_color(Color(1.0, 0.82, 0.40, alpha))
		_trail_mesh.surface_add_vertex(point + side)
		_trail_mesh.surface_set_color(Color(1.0, 0.82, 0.40, alpha))
		_trail_mesh.surface_add_vertex(point - side)
	_trail_mesh.surface_end()


## Bleed the flight trail away after the strike. The trail is where the orb HAS
## BEEN; once the orb stops, a frozen gold streak hanging across the sky for the
## whole wobble reads as a rendering fault, which is exactly what it was.
func _fade_trail() -> void:
	_trail_fade = maxf(0.0, _trail_fade - 0.12)
	if _path.size() > 1:
		_path.remove_at(0)
	if _trail_fade <= 0.01 or _path.size() < 2:
		_path = PackedVector3Array()
	_draw_trail()


## Launch. `target` is the creature this throw is aimed at; the orb only tests
## against that one, because a throw is at a creature, not at the world.
func launch(from: Vector3, direction: Vector3, speed: float, target: Node3D,
		pass_through: Array = []) -> void:
	_pass_through.clear()
	for body: Variant in pass_through:
		if body is CollisionObject3D and is_instance_valid(body):
			_pass_through.append((body as CollisionObject3D).get_rid())
	global_position = from
	_velocity = direction.normalized() * speed
	_target = target
	_life = 0.0
	_phase = Phase.FLYING
	_trail_fade = 1.0
	_bounces = 0
	_path = PackedVector3Array([from])


func _physics_process(delta: float) -> void:
	match _phase:
		Phase.FLYING:
			_tick_flight(delta)
		Phase.HANGING:
			_tick_hang(delta)
		Phase.DROPPING:
			_tick_drop(delta)
		Phase.RESTING, Phase.SEALED:
			_tick_rest(delta)
		Phase.DONE:
			pass


func _tick_flight(delta: float) -> void:
	_life += delta
	_velocity.y -= _gravity * delta
	global_position += _velocity * delta
	# Spin, so a placeholder sphere still reads as an object in flight rather
	# than a decal sliding through the air.
	_mesh.rotate_x(12.0 * delta)

	_draw_halo(HALO_SCALE, 1.0)
	_path.append(global_position)
	while _path.size() > TRAIL_POINTS:
		_path.remove_at(0)
	_draw_trail()

	_note_closest_approach()
	if _check_target():
		return
	if _life >= _max_life:
		_end_reason = "flight_time"
		_finish_with_miss()
	elif _hit_ground():
		_end_reason = "ground"
		_finish_with_miss()


## The beat after the strike: the orb hangs at the strike point while the
## creature is drawn in (`resolve.absorb_seconds` — the same clock the absorb
## animation runs on, so the creature always shrinks toward a stationary orb),
## then drops.
func _tick_hang(delta: float) -> void:
	_hang_left -= delta
	_fade_trail()
	# The halo eases from its flight size down toward its resting size while the
	# camera glides in — the big glow was for reading a fast object at distance.
	var t: float = clampf(1.0 - _hang_left / maxf(_hang_total, 0.01), 0.0, 1.0)
	_draw_halo(lerpf(HALO_SCALE, REST_HALO_SCALE, t), 1.0)
	if _hang_left <= 0.0:
		_phase = Phase.DROPPING
		_velocity = Vector3.ZERO


## Fall to the ground like the object it is, with one small bounce.
func _tick_drop(delta: float) -> void:
	_fade_trail()
	_velocity.y -= _gravity * delta
	var step := _velocity * delta
	var landed := _ground_below(global_position, global_position + step)
	global_position += step
	_draw_halo(REST_HALO_SCALE, 1.0)

	if not is_nan(landed):
		global_position.y = landed + _radius * 0.5
		if _bounces < 1 and absf(_velocity.y) > 1.2:
			_bounces += 1
			_velocity.y = absf(_velocity.y) * BOUNCE_RESTITUTION
			return
		_velocity = Vector3.ZERO
		_phase = Phase.RESTING
		_rest_time = 0.0
		_mesh.rotation = Vector3.ZERO
	elif _velocity.y < -30.0:
		# Falling with no ground found (struck over a hole, a prop, a seam):
		# rest where it is rather than falling forever under the camera.
		_velocity = Vector3.ZERO
		_phase = Phase.RESTING
		_rest_time = 0.0


## At rest: a small idle pulse so the orb reads as alive while the player waits,
## the rock-and-hop of each `shake()`, and the warm bloom after `seal()`.
func _tick_rest(delta: float) -> void:
	_rest_time += delta
	var halo_scale: float = REST_HALO_SCALE
	var halo_alpha: float = 0.85 + 0.15 * sin(_rest_time * 2.4)

	if _shake_left > 0.0:
		_shake_left = maxf(0.0, _shake_left - delta)
		var t: float = 1.0 - _shake_left / SHAKE_SECONDS
		# Rise-and-settle envelope so the rock starts and ends at zero tilt —
		# a shake that ends mid-lean reads as the animation being cut off.
		var envelope: float = sin(t * PI)
		var rock: float = sin(t * TAU * 1.5) * envelope
		_mesh.rotation.z = rock * SHAKE_TILT
		# The rock pivots at the GROUND CONTACT, not the sphere's centre: a ball
		# tipping on the spot displaces sideways by its own radius's worth of
		# lean, and that lateral travel is what a still frame (and a player's
		# eye) actually registers — the first capture proved pure rotation on a
		# ball is invisible. Displaced across the camera's view so the travel
		# is never along the look axis.
		var lateral: Vector3 = _across_the_view() * sin(rock * SHAKE_TILT) * _radius * 1.6
		_mesh.position = lateral + Vector3.UP * envelope * SHAKE_HOP
		halo_scale += envelope * 1.1
		halo_alpha = 1.0
		if _shake_left <= 0.0:
			_mesh.rotation.z = 0.0
			_mesh.position = Vector3.ZERO

	if _phase == Phase.SEALED:
		_seal_time += delta
		# Bloom fast, then settle into a calm, brighter-than-before glow: the
		# orb has decided, and it should look pleased about it.
		var bloom: float = exp(-_seal_time * 3.0)
		halo_scale = REST_HALO_SCALE + 0.8 + bloom * 2.2
		halo_alpha = 1.0
		if _orb_material != null:
			# Warm, not white: past ~2.5 the sphere clips to a featureless blob
			# and the seal stops reading as the gold orb it is.
			_orb_material.emission_energy_multiplier = 1.1 + bloom * 0.9

	_draw_halo(halo_scale, halo_alpha)


## One wobble, called by the combat manager per `orb_shook`. The count and the
## outcome were decided when the orb landed; this is the performance of it.
## The small ground pulse guarantees each shake reads as a beat even at a
## distance where the rock itself is a few pixels.
func shake(_index: int) -> void:
	_shake_left = SHAKE_SECONDS
	FLASH.burst(get_parent(), global_position, Color("#ffd27a"), 0.55, 0.28, 0.8)


## The horizontal direction across the current camera's view, for shake travel
## the camera can actually see.
func _across_the_view() -> Vector3:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return Vector3.RIGHT
	var right: Vector3 = camera.global_transform.basis.x
	right.y = 0.0
	return Vector3.RIGHT if right.length() < 0.01 else right.normalized()


## The catch succeeded: hold a warm, settled glow until the fight cleans up.
func seal() -> void:
	_phase = Phase.SEALED
	_seal_time = 0.0
	_shake_left = 0.0
	_mesh.rotation = Vector3.ZERO
	_mesh.position = Vector3.ZERO


func is_resting() -> bool:
	return _phase == Phase.RESTING or _phase == Phase.SEALED


## The nearest the orb came to the target's centre, sampled every flight frame.
func _note_closest_approach() -> void:
	if _target == null or not is_instance_valid(_target):
		return
	var centre: Vector3 = _target.call("centre") if _target.has_method("centre") \
		else _target.global_position
	var offset := global_position.distance_to(centre)
	if offset < _closest:
		_closest = offset
		_closest_at = global_position


func _check_target() -> bool:
	if _target == null or not is_instance_valid(_target) or not _target.visible:
		return false
	var centre: Vector3 = _target.call("centre") if _target.has_method("centre") \
		else _target.global_position
	var body_radius := 0.5
	if _target.has_method("body_radius"):
		body_radius = float(_target.call("body_radius"))

	var offset := global_position.distance_to(centre)
	if offset > body_radius + _radius:
		return false

	_phase = Phase.HANGING
	_velocity = Vector3.ZERO
	if _orb_material != null:
		_orb_material.emission_energy_multiplier = REST_EMISSION
	# Reported as distance from the centre, clamped at the body's own radius, so
	# the accuracy bonus is scored against the creature rather than against the
	# orb's generous collision sphere. Widening `radius` to forgive the input
	# must not silently make every throw count as dead centre.
	struck.emit(_target, minf(offset, body_radius))
	return true


## Ground test by raycast along the step just travelled, rather than by sampling
## a height. Over Terrain3D the ground can move a long way inside one frame of a
## fast projectile, and a point check tunnels straight through hillsides.
func _hit_ground() -> bool:
	var world := get_world_3d()
	if world == null:
		return false
	var from := global_position - _velocity * get_physics_process_delta_time()
	var query := PhysicsRayQueryParameters3D.create(from, global_position)
	query.collide_with_areas = false
	query.exclude = _excluded_rids()
	var hit: Dictionary = world.direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return false
	var collider := hit.get("collider") as Node
	_ground_collider = collider.name if collider != null else "unnamed"
	global_position = hit["position"]
	return true


## Ground height along the drop step, or NAN. Same ray-along-the-step approach
## as `_hit_ground`, but returning the height so the resting orb can sit ON the
## ground rather than at whatever depth the frame's step ended.
func _ground_below(from: Vector3, to: Vector3) -> float:
	var world := get_world_3d()
	if world == null:
		return NAN
	var query := PhysicsRayQueryParameters3D.create(from, to + Vector3.DOWN * _radius)
	query.collide_with_areas = false
	query.exclude = _excluded_rids()
	var hit: Dictionary = world.direct_space_state.intersect_ray(query)
	return NAN if hit.is_empty() else float((hit["position"] as Vector3).y)


func _finish_with_miss() -> void:
	_phase = Phase.DONE
	var need := 0.92
	if _target != null and is_instance_valid(_target) and _target.has_method("body_radius"):
		need = float(_target.call("body_radius")) + _radius
	print("catch launch: miss forensics reason=%s closest=%.2f needed=%.2f at=(%.2f, %.2f, %.2f) ground=%s life=%.2f" % [
		_end_reason, _closest, need,
		_closest_at.x, _closest_at.y, _closest_at.z,
		_ground_collider if _ground_collider != "" else "none", _life,
	])
	missed.emit()


## The target plus everything the throw passes through.
##
## One list, built in one place, used by both raycasts -- they had two copies of
## the target-exclusion line and only one of them would have gained the ally.
func _excluded_rids() -> Array[RID]:
	var out: Array[RID] = []
	if _target != null and is_instance_valid(_target) and _target is CollisionObject3D:
		out.append((_target as CollisionObject3D).get_rid())
	out.append_array(_pass_through)
	return out
