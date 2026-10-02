extends SceneTree

## Initialized production bodies/cues and finite casts. This is a focused
## mount regression; full player/co-op and C2/C3 evidence remain separate.
const BODY := preload("res://scenes/creatures/creature.tscn")
const WILD := preload("res://scripts/creatures/wild_creature.gd")
const PROXY := preload("res://scripts/creatures/shared_opponent_proxy.gd")
const CAST := preload("res://scripts/combat/enemy_pattern_cast.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const AI := preload("res://scripts/combat/combat_ai.gd")
const MATH := preload("res://scripts/combat/combat_math.gd")
var _errors: Array[String] = []
var _checks := 0
var _attempts := 0
var _world: Node3D


func _init() -> void:
	_run.call_deferred()


func _check(value: bool, reason: String) -> void:
	_checks += 1
	if not value: _errors.append(reason)


func _body(script: Script) -> Node3D:
	var body := BODY.instantiate() as Node3D
	body.set_script(script)
	_world.add_child(body)
	body.set_physics_process(false)
	body.set("instance", SPECIES.spawn("terrapup"))
	return body


func _observed() -> Dictionary:
	return {"creature_uid": "observed", "action": "charged_windup", "distance": 4.0,
		"safe_dodge_lane": true, "side_sign": 1.0}


func _field_contact(_profile: Dictionary, _geometry: Dictionary) -> bool:
	_attempts += 1
	return _attempts == 2


func _run() -> void:
	_world = Node3D.new()
	root.add_child(_world)
	var patterns: Dictionary = MATH.config().get("patterns", {})
	_check(patterns.get("runtime_enabled") == true, "production pattern mount is disabled")
	var target := _body(WILD)
	target.position = Vector3(0, 0, 4)
	for role: String in ["WALL", "CHARGER", "DIVER", "CURRENT", "ACE"]:
		var body := _body(WILD)
		body.set("trainer_owned", true)
		var context := {"role": role, "chapter": "water", "trainer_owned": true}
		body.call("configure_patterns", patterns, context, Callable())
		var ids := AI.pattern_ids(patterns, role, context)
		for cursor: int in mini(2, ids.size()):
			body.call("set_engaged", true, target)
			body.call("_enter", AI.Intent.TELEGRAPH)
			var profile: Dictionary = body.call("combat_config")
			_check(profile.get("pattern_attack_id") == ids[cursor], role + " did not mount authored sequence")
			_check(not (body.call("pattern_geometry") as Dictionary).is_empty(), role + " lacks frozen hit geometry")
			var cue: Variant = body.get("_lunge_lane") if profile.get("telegraph_shape") == "lane" else body.get("_pattern_cue")
			_check(is_instance_valid(cue), role + " lacks an actual cue node")
		body.call("set_engaged", false)
	var diver := _body(WILD)
	diver.call("configure_patterns", patterns, {"role": "DIVER", "chapter": "water"}, Callable())
	diver.set("_pattern_cursor", 1)
	diver.call("set_engaged", true, target)
	diver.call("_enter", AI.Intent.TELEGRAPH)
	var total := float(diver.get("_lunge_tell_total"))
	diver.set("_beat_left", total * 0.75)
	target.position = Vector3(4, 0, 0)
	diver.call("_update_pattern_geometry")
	var tracked: Vector3 = diver.call("pattern_geometry").marker
	_check(tracked.is_equal_approx(target.position), "DIVER marker did not track early tell")
	diver.set("_beat_left", total * 0.25)
	target.position = Vector3(-4, 0, 0)
	diver.call("_update_pattern_geometry")
	_check((diver.call("pattern_geometry").marker as Vector3).is_equal_approx(tracked), "DIVER marker followed after lock")
	var strikes := {"count": 0}
	diver.connect("strike_ready", func() -> void: strikes.count += 1)
	diver.call("_enter", AI.Intent.RECOVER)
	_check(bool(diver.get("_pattern_leap_active")) and bool(diver.call("combat_burst_active")), "DIVER did not start committed body travel")
	_check(strikes.count == 0, "DIVER struck before arrival")
	# Feed the real post-collision arrival branch its completed endpoint.
	diver.position = tracked
	diver.call("cancel_combat_burst")
	diver.call("_after_pattern_leap_step", 0.45)
	_check(strikes.count == 1 and diver.call("pattern_geometry").get("blocked") == false, "DIVER arrival did not release one strike")
	diver.call("set_engaged", false)
	var reactor := _body(WILD)
	reactor.call("configure_patterns", patterns, {"role": "WALL", "chapter": "water"}, _observed)
	reactor.call("set_engaged", true, target)
	_check(not bool(reactor.call("_observe_pattern_reaction", 0.0)), "reaction read a future input")
	_check(not bool(reactor.call("_observe_pattern_reaction", 0.249)), "reaction anticipated .25s observation")
	_check(bool(reactor.call("_observe_pattern_reaction", 0.002)), "measured charged tell did not cause a dodge")
	_check(reactor.get("_intent") == AI.Intent.DODGE and float(reactor.get("_pattern_dodge_left")) == 6.0, "wild dodge lost cooldown/state")
	reactor.call("set_engaged", false)
	var field_profile: Dictionary = patterns.attacks.current_zone.duplicate(true)
	field_profile["pattern_attack_id"] = "current_zone"
	var field_geometry := {"profile": field_profile, "origin": Vector3.ZERO,
		"heading": Vector3.FORWARD, "marker": Vector3(2, 0, 2), "body": reactor}
	var cast := CAST.begin(reactor, field_profile, field_geometry, {}, _field_contact, patterns)
	cast.set_physics_process(false)
	cast.call("_physics_process", 0.1)
	cast.call("_physics_process", 0.1)
	cast.call("_physics_process", 0.1)
	_check(_attempts == 2 and not cast.is_queued_for_deletion(), "field must retry misses then retain one-hit presentation")
	cast.call("_physics_process", 3.0)
	_check(cast.is_queued_for_deletion(), "field outlived authored duration")
	var proxy := _body(PROXY)
	var shape := {"pattern": {"profile": field_profile, "origin": [0.0, 0.0, 0.0],
		"heading": [0.0, 0.0, -1.0], "marker": [2.0, 0.0, 2.0]}}
	_check(bool(proxy.call("present_telegraph", 1, 1.1, 1, shape)), "guest refused current host tell")
	proxy.call("present_strike", 2, 1)
	_check((proxy.get("_pattern_fields") as Array).size() == 1, "guest field vanished at release")
	proxy.call("present_telegraph", 3, 1.0, 2, {})
	_check((proxy.get("_pattern_fields") as Array).size() == 1, "new tell erased a still-active field")
	proxy.call("apply_pattern_shape", 1, shape)
	_check((proxy.call("pattern_geometry") as Dictionary).is_empty(), "stale host pose resurrected an older tell")
	proxy.call("_physics_process", 3.1)
	_check((proxy.get("_pattern_fields") as Array).is_empty(), "guest field did not expire")
	_world.queue_free()
	await process_frame
	print("F22_LIVE_PATTERN_MOUNT " + JSON.stringify({"pass": _errors.is_empty(), "checks": _checks,
		"errors": _errors, "scope": "initialized production node mount; player/co-op and C2/C3 remain separate"}))
	quit(0 if _errors.is_empty() else 1)
