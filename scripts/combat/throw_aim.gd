extends Node

## Aiming and throwing an orb.
##
## Combat is piloted, so the player is driving their pal when they decide to
## throw. Pressing Throw hands camera and control back to the TRAINER for a
## real-time over-the-shoulder aim, and hands them forward again on release.
##
## That swap is the design, not an implementation detail. Your pal is left
## undefended while you aim and the opponent does not stop attacking it, so
## throwing costs you something. Without that cost, throwing is free and the
## right play is to throw constantly between attacks, which is the version of
## catching that answers no question worth asking.
##
## Split out of combat_manager.gd, which already owns the fight. This owns the
## aim: the camera profile, the reticle, the orb, and the stock.

const CATCH := preload("res://scripts/combat/catch_math.gd")
const ORB_SCENE := preload("res://scenes/combat/orb.tscn")
const FX := preload("res://scripts/combat/fx.gd")

signal aim_entered()
signal aim_exited()
## The orb landed on the target. `offset` is metres off centre of mass.
signal orb_struck(target: Node3D, offset: float)
signal orb_missed()
## A throw was refused, with a reason the HUD can show. "I pressed it and
## nothing happened" is otherwise indistinguishable from a dropped input.
signal throw_refused(reason: String)

enum State { IDLE, AIMING, THROWN }

## How far down the camera's centre ray the aim point sits when the reticle is
## not over the target. Roughly arena width: far enough that the throw reads as
## going where you pointed, near enough that it is not effectively parallel.
const AIM_REACH := 12.0

var state: State = State.IDLE
var stock: int = 0

var _player: Node3D = null
var _target: Node3D = null
var _camera_rig: Node = null
var _orb: Node3D = null

var _windup: float = 0.0
var _cooldown: float = 0.0
var _guard: float = 0.0

var _speed: float = 17.0
var _gravity: float = 14.0
var _max_flight: float = 4.0
var _spawn_height: float = 1.5
var _spawn_forward: float = 0.6
var _release_windup: float = 0.18
var _throw_cooldown: float = 0.9

## The dotted ballistic path drawn while aiming. Lazily built, hidden the
## moment the aim closes, freed with the fight.
var _arc: MeshInstance3D = null
var _arc_mesh: ImmediateMesh = null


func _ready() -> void:
	var cfg: Dictionary = CATCH.config().get("throw", {})
	_speed = float(cfg.get("speed", _speed))
	_gravity = float(cfg.get("gravity", _gravity))
	_max_flight = float(cfg.get("max_flight_time", _max_flight))
	_spawn_height = float(cfg.get("spawn_height", _spawn_height))
	_spawn_forward = float(cfg.get("spawn_forward", _spawn_forward))
	_release_windup = float(cfg.get("release_windup", _release_windup))
	_throw_cooldown = float(cfg.get("cooldown", _throw_cooldown))
	stock = CATCH.starting_stock()
	set_physics_process(false)


## Called by the combat manager when a fight opens.
func arm(player: Node3D, target: Node3D, camera_rig: Node) -> void:
	_player = player
	_target = target
	_camera_rig = camera_rig
	state = State.IDLE
	_windup = 0.0
	_cooldown = 0.0
	set_physics_process(true)


func disarm() -> void:
	if state == State.AIMING:
		_leave_aim()
	_despawn_orb()
	if _arc != null and is_instance_valid(_arc):
		_arc.queue_free()
	_arc = null
	_arc_mesh = null
	state = State.IDLE
	set_physics_process(false)


func is_aiming() -> bool:
	return state == State.AIMING


func is_busy() -> bool:
	return state != State.IDLE


func refill() -> void:
	stock = CATCH.starting_stock()


func _physics_process(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)
	_guard = maxf(0.0, _guard - delta)

	if state == State.AIMING:
		_tick_aiming(delta)
		_draw_arc()
	elif _arc != null:
		_arc.visible = false


func _tick_aiming(delta: float) -> void:
	if _windup > 0.0:
		_windup -= delta
		if _windup <= 0.0:
			_release()
		return
	if _guard > 0.0:
		return

	# Backing out is free and spends nothing. A player who opened the aim by
	# accident, mid-fight, with their pal taking hits, must be able to get out
	# without paying for it.
	if Input.is_action_just_pressed("combat_run") or Input.is_action_just_pressed("menu_cancel"):
		_leave_aim()
		return

	if Input.is_action_just_pressed("combat_throw") or Input.is_action_just_pressed("combat_quick"):
		_windup = _release_windup


## Try to enter aim mode. Returns false with a reason on the signal when the
## throw cannot happen, so the refusal is always explained.
func try_begin_aim(target_can_be_caught: bool, refusal: String) -> bool:
	if state != State.IDLE or _cooldown > 0.0:
		return false
	if stock <= 0:
		throw_refused.emit("no orbs left")
		return false
	if not target_can_be_caught:
		throw_refused.emit(refusal)
		return false

	state = State.AIMING
	# The button that opens the aim is also the button that releases it, and
	# `is_action_just_pressed` stays true for the whole frame. Same guard as the
	# one that stops engaging a fight from being read as the first attack of it.
	_guard = 0.15
	_windup = 0.0
	_apply_aim_camera()
	aim_entered.emit()
	return true


func _apply_aim_camera() -> void:
	if _camera_rig == null or not _camera_rig.has_method("set_target"):
		return
	_camera_rig.call("set_target", _player, CATCH.config().get("aim", {}))


func _leave_aim() -> void:
	state = State.IDLE
	_windup = 0.0
	aim_exited.emit()


## Throw at whatever the reticle is over.
##
## NOT parallel to the camera. The aim camera sits about a metre and a half off
## to one side so the trainer's body does not cover the crosshair, and an orb
## thrown along the camera's forward from the trainer's hand travels a line
## that is offset by exactly that much — it lands a body's width to the side of
## everything the player aimed at, consistently, and reads as the game ignoring
## the input.
##
## So the aim is a point: where the camera's centre ray reaches, and then a
## direction from the hand to that point. The reticle is a promise, and this is
## what keeps it.
func _release() -> void:
	if stock <= 0:
		_leave_aim()
		return
	stock -= 1
	state = State.THROWN

	var camera := _aim_camera()
	var origin := _player.global_position + Vector3.UP * _spawn_height
	var forward := _aim_direction(camera, origin)
	origin += forward * _spawn_forward

	_despawn_orb()
	_orb = ORB_SCENE.instantiate()
	_player.get_parent().add_child(_orb)
	_orb.connect("struck", _on_struck)
	_orb.connect("missed", _on_missed)
	_orb.call("launch", origin, forward, _speed, _target)
	# The trainer throws rather than standing there. Their model is on a child
	# node, so this reaches past the body to the thing that animates.
	var body: Node = _player.get_node_or_null(^"Model")
	if body != null and body.has_method("play_throw"):
		body.call("play_throw")

	aim_exited.emit()


## Where the reticle is pointing, converted into a direction from the hand.
##
## The aim point is taken along the camera's centre ray. It prefers the actual
## target when the reticle is near it, so a throw lined up on the creature is
## thrown at the creature rather than at a spot behind it — the alternative is a
## fixed reach that is wrong at every distance except one.
func _aim_direction(camera: Camera3D, origin: Vector3) -> Vector3:
	if camera == null:
		return -_player.global_transform.basis.z

	var eye := camera.global_position
	var forward := -camera.global_transform.basis.z
	var aim_point := eye + forward * AIM_REACH

	if _target != null and is_instance_valid(_target) and _target.has_method("centre"):
		var centre: Vector3 = _target.call("centre")
		var along := (centre - eye).dot(forward)
		if along > 0.0:
			# How far the target sits from the camera's centre line. Inside a
			# body's width, the player was clearly aiming at it.
			var nearest := eye + forward * along
			var body := 1.0
			if _target.has_method("body_radius"):
				body = float(_target.call("body_radius")) * 2.0
			if nearest.distance_to(centre) <= body:
				aim_point = centre

	var direction := aim_point - origin
	return direction.normalized() if direction.length() > 0.01 else forward


func _aim_camera() -> Camera3D:
	if _camera_rig == null:
		return null
	return _camera_rig.get_node_or_null(^"Camera3D") as Camera3D


## --- the arc preview --------------------------------------------------------
##
## The path the orb will fly, drawn while aiming, from the same origin and
## direction `_release()` will use and integrated with the same step-and-gravity
## arithmetic orb.gd flies (fx.simulate_arc). The reticle is a promise (D08);
## this is the promise shown at full length — where the arc peaks and where it
## comes down — which is the half of a ballistic throw a crosshair alone cannot
## say. D06-safe: unshaded quads, no depth or screen reads.

func _draw_arc() -> void:
	var cfg: Dictionary = CATCH.config().get("arc_preview", {})
	if not bool(cfg.get("enabled", true)) or _player == null:
		return
	var camera := _aim_camera()
	if camera == null:
		return
	if _arc == null:
		_build_arc()
		if _arc == null:
			return
	_arc.visible = true

	var origin := _player.global_position + Vector3.UP * _spawn_height
	var forward := _aim_direction(camera, origin)
	origin += forward * _spawn_forward

	var points := FX.simulate_arc(
		origin, forward, _speed, _gravity,
		float(cfg.get("step_seconds", 0.05)), _max_flight, int(cfg.get("max_points", 60))
	)
	points = _clip_to_world(points)

	# Dots SHRINK toward the landing point rather than fading: per-vertex alpha
	# under the Compatibility renderer is how the first impact flash spent a
	# survey invisible (impact_flash.gd), so the material carries the one alpha
	# and the geometry carries the taper.
	var size := float(cfg.get("dot_size", 0.11))
	var right := camera.global_transform.basis.x
	var up := camera.global_transform.basis.y
	_arc_mesh.clear_surfaces()
	if points.size() < 2:
		return
	_arc_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(1, points.size()):
		var t := float(i) / float(points.size() - 1)
		var half := size * (1.0 - 0.6 * t) * 0.5
		var centre := points[i]
		_arc_mesh.surface_add_vertex(centre - right * half - up * half)
		_arc_mesh.surface_add_vertex(centre + right * half - up * half)
		_arc_mesh.surface_add_vertex(centre + up * half)
	_arc_mesh.surface_end()


func _build_arc() -> void:
	if _player == null or _player.get_parent() == null:
		return
	var cfg: Dictionary = CATCH.config().get("arc_preview", {})
	_arc_mesh = ImmediateMesh.new()
	_arc = MeshInstance3D.new()
	_arc.name = "ThrowArcPreview"
	_arc.mesh = _arc_mesh
	_arc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# The dots are placed in world space each frame; stated bounds so an
	# ImmediateMesh with no surfaces yet cannot be culled before its first draw
	# (the impact_flash lesson).
	_arc.custom_aabb = AABB(Vector3.ONE * -40.0, Vector3.ONE * 80.0)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.disable_receive_shadows = true
	var colour := Color(str(cfg.get("colour", "#ffe9a8")))
	colour.a = 0.85
	material.albedo_color = colour
	_arc.material_override = material
	_player.get_parent().add_child(_arc)


## Truncate the simulated flight at the first thing it would strike — the
## ground, a rock, or the creature itself. The preview must not promise a path
## through a hillside.
func _clip_to_world(points: PackedVector3Array) -> PackedVector3Array:
	if _player == null or points.size() < 2:
		return points
	var world := _player.get_world_3d()
	if world == null:
		return points
	var space := world.direct_space_state
	if space == null:
		return points
	var out := PackedVector3Array([points[0]])
	for i in range(1, points.size()):
		var query := PhysicsRayQueryParameters3D.create(points[i - 1], points[i])
		query.collide_with_areas = false
		if _player is CollisionObject3D:
			query.exclude = [(_player as CollisionObject3D).get_rid()]
		var hit: Dictionary = space.intersect_ray(query)
		if not hit.is_empty():
			out.append(hit["position"])
			return out
		out.append(points[i])
	return out


func _on_struck(target: Node3D, offset: float) -> void:
	state = State.IDLE
	_cooldown = _throw_cooldown
	orb_struck.emit(target, offset)


func _on_missed() -> void:
	state = State.IDLE
	_cooldown = _throw_cooldown
	_despawn_orb()
	orb_missed.emit()


func _despawn_orb() -> void:
	if _orb != null and is_instance_valid(_orb):
		_orb.queue_free()
	_orb = null


## The orb that is currently resting on the ground after a strike, so the catch
## resolution can wobble it. Null at every other time.
func resting_orb() -> Node3D:
	return _orb if _orb != null and is_instance_valid(_orb) else null


func clear_orb() -> void:
	_despawn_orb()
