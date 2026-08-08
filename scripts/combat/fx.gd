extends Node

## The juice layer: presentation for combat events that already happened.
##
## Owned by CombatManager the way throw_aim.gd is, and poked with world
## positions and amounts. Nothing in here decides anything — no damage, no
## timing that gameplay reads, no odds. Every call dramatises a fact the fight
## has ALREADY resolved, which is the D08 rule (never contradict the computed
## outcome) applied to the whole file.
##
## Everything visual obeys docs/decisions/D06: no depth or screen reads, no
## volumetrics. Damage numbers are Label3D, bursts are CPUParticles3D, and both
## render identically under Forward+ and the Compatibility pipeline the survey
## is forced onto.
##
## Every number is TUNABLE in data/config/combat.json (`impact`) and
## data/config/catching.json (`resolve`, `impact_puff`).

const MATH := preload("res://scripts/combat/combat_math.gd")
const CATCH := preload("res://scripts/combat/catch_math.gd")
## Read, never edited: the damage number a blow prints must be the same colour
## as the health bar it moved, or the player learns two colour languages.
const STYLE := preload("res://scripts/ui/ui_style.gd")


## --- pure helpers, testable headlessly --------------------------------------

## The colour a damage number is drawn in, by direction.
##
## Damage YOU deal is the opponent's amber — the hue their health bar drains in.
## Damage your pal TAKES is the health-low red your own bar is sliding towards.
## The number and the bar that moved always agree, and neither is a new colour.
static func number_colour(on_enemy: bool) -> Color:
	return STYLE.ENEMY_HEALTH_FULL if on_enemy else STYLE.HEALTH_LOW


## Seconds of held breath before shake `index` (0-based). The interval grows
## each shake, so the wait rises with the count — dramatising the honest number
## `catch_math.shakes_for` already decided, never changing it.
static func shake_pause(index: int, cfg: Dictionary) -> float:
	var base := float(cfg.get("shake_interval", 0.55))
	var growth := float(cfg.get("shake_interval_growth", 0.0))
	return base + growth * float(maxi(index, 0))


## Integrate the orb's ballistic flight, exactly as orb.gd flies it: position
## stepped by velocity, gravity pulling velocity down. Pure — collision against
## the world is the caller's job — so a test can hold the arc to the same
## parabola the orb will follow.
static func simulate_arc(
	origin: Vector3, direction: Vector3, speed: float, gravity: float,
	step: float, max_time: float, max_points: int
) -> PackedVector3Array:
	var points := PackedVector3Array([origin])
	if step <= 0.0 or max_points < 2:
		return points
	var position := origin
	var velocity := direction.normalized() * speed
	var flown := 0.0
	while flown < max_time and points.size() < max_points:
		velocity.y -= gravity * step
		position += velocity * step
		points.append(position)
		flown += step
	return points


## --- time: hit-stop and the KO beat -----------------------------------------
##
## Both are Engine.time_scale, timed on the WALL clock. Timing them on game
## time would be circular — a stop at scale 0.05 measured in scaled seconds
## lasts twenty times longer than asked — and wall time also means a headless
## smoke pays milliseconds, not minutes. `_process` runs in PROCESS_MODE_ALWAYS
## so the scale is restored even if something pauses the tree mid-beat.

var _time_deadline_msec: int = -1
## A second beat queued behind the current one: the killing blow hit-stops
## first, THEN eases into the KO slow-mo.
var _queued_scale: float = 1.0
var _queued_duration: float = 0.0

## Live drifting damage numbers and expiring particle bursts: [node, age, spec].
var _numbers: Array[Array] = []
var _expiring: Array[Array] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _exit_tree() -> void:
	# Whatever happens to this node, the game's clock is not allowed to stay bent.
	if _time_deadline_msec >= 0:
		Engine.time_scale = 1.0


func _process(_delta: float) -> void:
	if _time_deadline_msec < 0:
		return
	if Time.get_ticks_msec() < _time_deadline_msec:
		return
	if _queued_duration > 0.0:
		Engine.time_scale = _queued_scale
		_time_deadline_msec = Time.get_ticks_msec() + int(_queued_duration * 1000.0)
		_queued_duration = 0.0
		return
	Engine.time_scale = 1.0
	_time_deadline_msec = -1


func _bend_time(scale: float, duration: float) -> void:
	if duration <= 0.0:
		return
	Engine.time_scale = clampf(scale, 0.01, 1.0)
	_time_deadline_msec = Time.get_ticks_msec() + int(duration * 1000.0)


## Restore the clock and forget queued beats. Called when a fight closes so an
## interrupted KO beat cannot leak slow motion into exploration.
func clear() -> void:
	_queued_duration = 0.0
	if _time_deadline_msec >= 0:
		Engine.time_scale = 1.0
		_time_deadline_msec = -1


## --- the events -------------------------------------------------------------

## A blow landed. `host` is a Node3D in the world's transform chain (the arena,
## while a fight is running) — the same lesson _flash_at learned: a Node3D hung
## under a plain Node renders nothing, twelve times in a row.
func hit(host: Node, at: Vector3, amount: float, on_enemy: bool, charged: bool) -> void:
	var cfg: Dictionary = MATH.config().get("impact", {})
	if not bool(cfg.get("enabled", true)):
		return
	_damage_number(host, at, amount, on_enemy, charged, cfg.get("damage_numbers", {}))
	var stop: Dictionary = cfg.get("hit_stop", {})
	if bool(stop.get("enabled", true)):
		_bend_time(float(stop.get("scale", 0.05)), float(stop.get("duration", 0.05)))


## A creature went down. The Death clip is already playing (pal_body.play_faint);
## this is the burst and the beat of slow motion around it.
func ko(host: Node, at: Vector3) -> void:
	var cfg: Dictionary = MATH.config().get("impact", {})
	if not bool(cfg.get("enabled", true)):
		return
	var ko_cfg: Dictionary = cfg.get("ko", {})
	burst(
		host, at,
		Color(str(ko_cfg.get("burst_colour", "#fff0c0"))),
		int(ko_cfg.get("burst_amount", 28)),
		float(ko_cfg.get("burst_lifetime", 0.7)),
		float(ko_cfg.get("burst_speed", 5.5))
	)
	# Queued behind whatever hit-stop the killing blow just applied, so the
	# sequence reads stop-then-slow rather than the stop swallowing the beat.
	var scale := float(ko_cfg.get("slowmo_scale", 0.45))
	var duration := float(ko_cfg.get("slowmo_duration", 0.55))
	if _time_deadline_msec >= 0:
		_queued_scale = scale
		_queued_duration = duration
	else:
		_bend_time(scale, duration)


## The orb struck home, or the creature broke back out of it.
func orb_puff(host: Node, at: Vector3) -> void:
	var cfg: Dictionary = CATCH.config().get("impact_puff", {})
	if not bool(cfg.get("enabled", true)):
		return
	burst(
		host, at,
		Color(str(cfg.get("colour", "#ffe9a8"))),
		int(cfg.get("amount", 20)),
		float(cfg.get("lifetime", 0.55)),
		float(cfg.get("speed", 4.0))
	)


## Rock the resting orb for shake `index` (1-based, as orb_shook emits it).
## Amplitude grows with the index: the tension rises, the count does not change.
func wobble_orb(orb: Node3D, index: int) -> void:
	if orb == null or not is_instance_valid(orb):
		return
	var lean := 0.24 + 0.11 * float(index)
	# The tween lives ON the orb, so a cleared orb takes its animation with it.
	var tween := orb.create_tween()
	tween.tween_property(orb, "rotation:z", lean, 0.09) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(orb, "rotation:z", -lean * 0.8, 0.12) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(orb, "rotation:z", lean * 0.35, 0.1) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(orb, "rotation:z", 0.0, 0.1) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


## --- the pieces -------------------------------------------------------------

func _damage_number(
	host: Node, at: Vector3, amount: float, on_enemy: bool, charged: bool, cfg: Dictionary
) -> void:
	if not bool(cfg.get("enabled", true)) or host == null:
		return
	var label := Label3D.new()
	label.text = str(int(round(amount)))
	label.font_size = int(float(cfg.get("font_size", 96)) \
		* (float(cfg.get("charged_scale", 1.35)) if charged else 1.0))
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	# Drawn over the bodies it is about. A number swallowed by the flank of the
	# creature it reports on says nothing; this is the one element allowed on
	# top, because it exists for a fraction of a second.
	label.no_depth_test = true
	label.render_priority = 10
	label.shaded = false
	label.modulate = number_colour(on_enemy)
	label.outline_modulate = STYLE.OUTLINE
	label.outline_size = 18
	host.add_child(label)
	# Spawned a little up and to the side, deterministically alternated, so two
	# quick hits do not print on top of each other.
	var side := 0.35 if (_numbers.size() % 2 == 0) else -0.35
	label.global_position = at + Vector3(side, 0.35, 0.0)
	_numbers.append([label, 0.0, cfg, label.position.y])


func burst(
	host: Node, at: Vector3, colour: Color, amount: int, lifetime: float, speed: float
) -> void:
	if host == null:
		return
	var puff := CPUParticles3D.new()
	puff.amount = maxi(amount, 1)
	puff.lifetime = maxf(lifetime, 0.05)
	puff.one_shot = true
	puff.explosiveness = 1.0
	puff.direction = Vector3.UP
	puff.spread = 180.0
	puff.initial_velocity_min = speed * 0.45
	puff.initial_velocity_max = speed
	puff.gravity = Vector3(0.0, -7.0, 0.0)
	puff.scale_amount_min = 0.6
	puff.scale_amount_max = 1.0

	var grain := SphereMesh.new()
	grain.radius = 0.055
	grain.height = 0.11
	grain.radial_segments = 6
	grain.rings = 3
	puff.mesh = grain
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = colour
	puff.material_override = material
	puff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	host.add_child(puff)
	puff.global_position = at
	puff.emitting = true
	_expiring.append([puff, 0.0, puff.lifetime + 0.3])


## Advanced on the PHYSICS clock, the impact_flash.gd lesson: a render-clock
## effect is gone inside one frame when the survey renders at a few frames a
## second, and a fixed timestep makes "three frames after the hit" the same
## picture in every run.
func _physics_process(delta: float) -> void:
	_tick_numbers(delta)
	_tick_expiring(delta)


func _tick_numbers(delta: float) -> void:
	var keep: Array[Array] = []
	for entry: Array in _numbers:
		var label: Label3D = entry[0]
		if label == null or not is_instance_valid(label):
			continue
		var age: float = float(entry[1]) + delta
		var cfg: Dictionary = entry[2]
		var duration := maxf(float(cfg.get("duration", 0.9)), 0.05)
		if age >= duration:
			label.queue_free()
			continue
		var t := age / duration
		# Fast rise easing out, fade only in the back half — a number that starts
		# fading as it appears is never read.
		var rise := 1.0 - pow(1.0 - t, 2.2)
		label.position.y = float(entry[3]) + float(cfg.get("rise_metres", 1.4)) * rise
		var colour := label.modulate
		colour.a = 1.0 if t < 0.5 else 1.0 - (t - 0.5) * 2.0
		label.modulate = colour
		keep.append([label, age, cfg, entry[3]])
	_numbers = keep


func _tick_expiring(delta: float) -> void:
	var keep: Array[Array] = []
	for entry: Array in _expiring:
		var node: Node = entry[0]
		if node == null or not is_instance_valid(node):
			continue
		var age: float = float(entry[1]) + delta
		if age >= float(entry[2]):
			node.queue_free()
			continue
		keep.append([node, age, entry[2]])
	_expiring = keep
