extends "res://tests/helpers/f22_pattern_pilot.gd"

## Water harness adapter over the shared Wind-aware combat pilot.
##
## The Water continuous harnesses own engagement, victory/flag checks, faints
## and their time limits. Each physics frame they call `drive()` (then await
## the frame) and this decides the combat input against the LIVE manager and
## bodies, pressing only controller-equivalent actions: movement through the
## camera basis the manager reads, and one-frame attack presses.
##
## Policy: the shared READER's reads (interrupt a telegraph with a paid
## charged hit that lands first, otherwise step out of the blow's reach),
## pressed harder between tells. COMBAT §2 makes a paid charged hit the best
## damage per second AND per Wind; READER's 25% reserve and wait-for-recovery
## left most of the regen unspent and ran Calder past 180 s with the ally
## barely scratched. Here: charged whenever ready and paid; a Wind-short
## charged only while the foe is recovering, repositioning or staggered (its
## x2 windup then finishes before the next tell); a paid quick only from
## surplus Wind that still leaves the next charged paid, or any paid quick
## while the charged is Energy-gated (quicks are what build that Energy).
##
## The shared pilot is not modified: other lanes' callers keep its behaviour.
##
## F22 named fights (Venn, Nerissa): a committed pattern shape (cone, ring,
## lane, fan, field) is left by its shortest drawn exit, the same read the C2
## reader (f22_pattern_pilot.gd) uses, and a released field is stayed out of
## until it expires. Backing straight out of the body's spaced reach (~9 m for
## a large WALL) never cleared those shapes inside the tell, so every Venn
## strike landed. Opponents with no pattern shape keep the old read.

var _live_camera: Node


func drive(manager: Node, ally: Node3D, enemy: Node3D) -> void:
	release()
	_manager = manager
	_ally = ally
	_wild = enemy
	if _manager == null or not is_instance_valid(_ally) or not is_instance_valid(_wild):
		return
	_live_camera = _manager.get("_camera_rig")
	_frames += 1
	_act_water()


func release() -> void:
	_release_attack()
	_release_move()


func _act_water() -> void:
	if _manager.player_is_committed() or float(_manager.get("_hitstop_left")) > 0.0:
		return
	var delta := _wild.global_position - _ally.global_position
	delta.y = 0.0
	var distance := delta.length()
	var toward := delta.normalized()
	var reach: float = _manager.combat_move_reach("quick")
	var charged_reach: float = _manager.combat_move_reach("charged")
	var creature: RefCounted = _manager.active_creature()
	var charged: Dictionary = _manager.call("_move_profile", "player_charged", str(creature.move_charged))
	var wind: float = _manager.wind_value()
	var charged_cost: float = _manager.wind_cost("charged")
	var quick_cost: float = _manager.wind_cost("quick")
	var telling: bool = _manager.enemy_is_winding_up()
	var shaped := _has_pattern_shape()
	if shaped: _note_fields(telling)
	if telling:
		# READER's read: a paid charged that lands inside the tell interrupts it.
		# A protected heavy (Nerissa's slam, quake, zone and lane) cannot be
		# interrupted: committing into it only eats the strike, so leave it
		# as the C2 reader does.
		var protected: bool = _wild.has_method("protected_heavy_committed") \
			and bool(_wild.call("protected_heavy_committed"))
		if not protected and _manager.charged_ready() and distance < charged_reach - 0.2 \
				and float(_wild.get("_beat_left")) > float(charged.get("windup", 0.55)) + 0.1 \
				and wind >= charged_cost:
			_press("combat_charged")
			return
		if shaped:
			_leave_shape()
			return
		var enemy_reach := float(_wild.combat_config().get("range", 2.6))
		if distance < enemy_reach + 0.35:
			_retreat(toward)
		return
	if shaped:
		var field_exit := _field_exit()
		if field_exit != Vector3.ZERO:
			_walk(field_exit)
			return
	if _manager.charged_ready():
		var open: bool = _manager.enemy_is_staggered() \
			or int(_wild.intent()) in [AI.Intent.RECOVER, AI.Intent.REPOSITION]
		if wind >= charged_cost or open:
			if distance > charged_reach - 0.3:
				_walk(toward)
			else:
				_press("combat_charged")
			return
	if distance > reach - 0.25:
		_walk(toward)
		return
	# A charged hit also spends the creature's Energy, which only landed quicks
	# build. When Energy is what gates the charged, keeping the charged's Wind in
	# reserve deadlocks the pilot (it never attacks): press paid quicks to build
	# Energy. Low nourishment lowers the Wind cap, so this happens on a long
	# unfed route (Tidewake dry run: Aquaryn at a ~30 Wind cap).
	var energy_gated: bool = not creature.can_use_charged()
	if _manager.quick_ready() and (wind >= quick_cost + charged_cost or (energy_gated and wind >= quick_cost)):
		_press("combat_quick")


## A named F22 body draws its committed shape; a world fight with no local
## arena (the Alpha) keeps the old read.
func _has_pattern_shape() -> bool:
	if _manager.arena() == null or not is_instance_valid(_manager.arena()) \
			or not _wild.has_method("pattern_geometry"):
		return false
	return not ((_wild.call("pattern_geometry") as Dictionary).get("profile", {}) as Dictionary).is_empty()


## Walk the shortest exit from the drawn shape; burst only to finish it when
## walking alone would not clear it before the strike releases.
func _leave_shape() -> void:
	var escape := _escape_from_tell()
	if escape.is_empty():
		return
	_walk(escape.direction)
	var hop := float(MATH.config().get("burst", {}).get("distance", 3.0)) - 0.2
	if float(escape.distance) <= hop and float(escape.walk_s) > float(escape.time_left) - 0.05 \
			and _manager.wind_value() >= _manager.wind_cost("burst"):
		_press("jump")


## The manager maps stick input through the exploration camera it was given.
func _walk(direction: Vector3) -> void:
	if _live_camera != null and is_instance_valid(_live_camera) \
			and _live_camera.has_method("planar_basis"):
		direction = (_live_camera.call("planar_basis") as Basis).inverse() * direction
		direction.y = 0.0
	super(direction)


## A shared world opponent (the Alpha) has no local arena to circle.
func _retreat(toward: Vector3) -> void:
	var arena: Node3D = _manager.arena()
	if arena == null or not is_instance_valid(arena):
		_walk(-toward)
		return
	super(toward)
