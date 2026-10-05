extends "res://tools/net/peer_runner.gd"

## Peer for tests/smoke_net_stormwood_charged_ground.gd (F33#3 / owner RD-14).
## Everything else is the ordinary tools/net/peer_runner.gd; this adds only
## the charged_* actions below. DISCLOSED FIXTURES (all test-only, none
## touches the shipping decision or receive path under test):
##   * `legacy_physical_crossings_fixture` for regression
##     "stormwood_charged_ground": the same retired-crossing override the
##     Stormwood realms smoke enables, so Game.enter_realm reaches Stormwood.
##   * `charged_stand`: places this peer's Player at an exact Stormwood XZ on
##     the authored heightfield and re-pins it there every physics frame
##     (drift, a fall through unstreamed collision) until released.
##   * `charged_set_health`: writes this peer's own vitals.health directly.
##   * `charged_wear`: equips/unequips the four travel pieces directly on
##     Game.player_equipment (no satchel transaction; gear is the subject).
##   * `charged_quiet_strikes` (host): parks the host's ordinary random
##     strike scheduler (_next) so a telegraphed glass-sink strike cannot add
##     its own damage to the charged-ground measurement. The charged-ground
##     tick (_tick_charged_ground) is untouched.

const CHARGED_RULES := preload("res://scripts/world/stormwood_surge_rules.gd")
const CHARGED_PIN_DRIFT_M := 0.75
const CHARGED_PIN_LIFT_M := 0.5

var _charged_rules: RefCounted = null
var _charged_pin_active := false
var _charged_pin_at := Vector3.ZERO
var _charged_pin_repins := 0
var _charged_listening := false
## Charged-ground events this process received whose hits address its own
## peer id, since the last charged_set_health; and every charged event seen.
var _charged_hits_mine := 0
var _charged_events_seen := 0
var _charged_hits_others := 0
var _charged_damage_mine := 0.0


func _execute_step(msg: Dictionary) -> Dictionary:
	var action := str(msg.get("action", ""))
	if not action.begins_with("charged_"):
		return await _charged_dispatch(msg)
	# The runner forwards only verdict/detail/data: every other key rides in data.
	var raw: Dictionary = await _charged_dispatch(msg)
	var data: Dictionary = {}
	for key: Variant in raw:
		if not str(key) in ["verdict", "detail", "data"]: data[key] = raw[key]
	return {"verdict": raw.get("verdict", "ERROR"), "detail": raw.get("detail", ""), "data": data}


func _charged_dispatch(msg: Dictionary) -> Dictionary:
	var action := str(msg.get("action", ""))
	var args: Dictionary = msg.get("args", {})
	if action == "legacy_physical_crossings_fixture" and str(args.get("regression", "")) == "stormwood_charged_ground":
		var enabled: bool = FOUNDATIONS_ORDER.set_test_overrides({"legacy_physical_crossings": true})
		return {"verdict": "PASS" if enabled else "FAIL",
			"detail": "disclosed retired crossing fixture: stormwood_charged_ground"}
	if action == "charged_stand":
		return await _charged_stand(args)
	if action == "charged_release":
		_charged_pin_active = false
		return {"verdict": "PASS", "detail": "pin released"}
	if action == "charged_health":
		return _charged_health()
	if action == "charged_set_health":
		return _charged_set_health(args)
	if action == "charged_wear":
		return _charged_wear(args)
	if action == "charged_host_ticks":
		return _charged_host_ticks()
	if action == "charged_quiet_strikes":
		return _charged_quiet_strikes()
	return await super._execute_step(msg)


func _charged_world() -> Node:
	var world := _probe.call("world") as Node
	if world == null or not world.has_method("ground_height_near"):
		return null
	return world


func _charged_lightning() -> Node:
	var world := _charged_world()
	return world.get_node_or_null(^"StormwoodLightning") if world != null else null


func _charged_listen() -> void:
	if _charged_listening:
		return
	var sess := _session()
	if sess == null or not sess.has_signal("stormwood_strike_received"):
		return
	sess.connect("stormwood_strike_received", _charged_on_event)
	_charged_listening = true


func _charged_on_event(event: Dictionary) -> void:
	if str(event.get("kind", "")) != "charged_ground":
		return
	_charged_events_seen += 1
	var sess := _session()
	var me := int(sess.call("local_peer_id")) if sess != null else -1
	var hits: Dictionary = event.get("hits", {}) as Dictionary
	for peer: Variant in hits:
		if int(peer) == me:
			_charged_hits_mine += 1
			_charged_damage_mine += float((hits[peer] as Dictionary).get("damage", 0.0))
		else:
			_charged_hits_others += 1


func _charged_reset_counts() -> void:
	_charged_hits_mine = 0
	_charged_events_seen = 0
	_charged_hits_others = 0
	_charged_damage_mine = 0.0


## Stand this peer's own Player at {x, z} on the authored ground and keep it
## there. Reports the settled position and whether shipping rules call it
## charged ground (stormwood_surge_rules.in_glass_sink).
func _charged_stand(args: Dictionary) -> Dictionary:
	_charged_listen()
	var world := _charged_world()
	var player := _probe.call("player") as Node3D
	if world == null or player == null:
		return {"verdict": "ERROR", "detail": "no Stormwood world/Player on this peer"}
	var x := float(args.get("x", NAN))
	var z := float(args.get("z", NAN))
	if not is_finite(x) or not is_finite(z):
		return {"verdict": "ERROR", "detail": "charged_stand needs args.x and args.z"}
	var ground := float(world.call("ground_height_near", Vector3(x, 0.0, z)))
	_charged_pin_at = Vector3(x, ground + CHARGED_PIN_LIFT_M, z)
	_charged_pin_repins = 0
	_charged_place(player)
	_charged_pin_active = true
	if not physics_frame.is_connected(_charged_pin_tick):
		physics_frame.connect(_charged_pin_tick)
	for i in maxi(1, int(args.get("settle", 120))):
		await physics_frame
	var at := player.global_position
	var ground_here := float(world.call("ground_height_near", at))
	if _charged_rules == null:
		_charged_rules = CHARGED_RULES.new()
	var charged := bool(_charged_rules.call("in_glass_sink", at))
	return {"verdict": "PASS",
		"detail": "stands at (%.1f, %.2f, %.1f), ground %.2f, charged=%s, repins=%d"
			% [at.x, at.y, at.z, ground_here, str(charged), _charged_pin_repins],
		"at": [at.x, at.y, at.z], "ground_y": ground_here, "charged": charged,
		"contact": absf(at.y - ground_here) <= 1.5}


func _charged_place(player: Node3D) -> void:
	REMOTE_CREATURE_TP.teleport_body(player as PhysicsBody3D, _charged_pin_at)
	if player is CharacterBody3D:
		(player as CharacterBody3D).velocity = Vector3.ZERO
	var rig := _probe.call("camera_rig") as Node3D
	if rig != null:
		rig.global_position = player.global_position


func _charged_pin_tick() -> void:
	if not _charged_pin_active:
		return
	var player := _probe.call("player") as Node3D
	if player == null:
		return
	var at := player.global_position
	var drift := Vector2(at.x - _charged_pin_at.x, at.z - _charged_pin_at.z).length()
	# Re-pin on horizontal drift or a fall through not-yet-streamed collision.
	if drift > CHARGED_PIN_DRIFT_M or at.y < _charged_pin_at.y - CHARGED_PIN_LIFT_M - 2.0:
		_charged_pin_repins += 1
		_charged_place(player)


func _charged_vitals() -> RefCounted:
	var player := _probe.call("player") as Node3D
	return player.get("vitals") as RefCounted if player != null else null


func _charged_in_fight() -> bool:
	var world := _charged_world()
	if world == null:
		return false
	var manager := world.get_node_or_null(^"CombatManager")
	return manager != null and bool(manager.call("is_fighting"))


func _charged_health() -> Dictionary:
	var vitals := _charged_vitals()
	if vitals == null:
		return {"verdict": "ERROR", "detail": "no live Player vitals"}
	var sess := _session()
	var player := _probe.call("player") as Node3D
	var at: Vector3 = player.global_position if player != null else Vector3.INF
	return {"verdict": "PASS",
		"detail": "health %.2f/%.2f, my hits %d, others' hits %d, events %d"
			% [float(vitals.get("health")), float(vitals.get("max_health")), _charged_hits_mine,
				_charged_hits_others, _charged_events_seen],
		"health": float(vitals.get("health")), "max_health": float(vitals.get("max_health")),
		"dead": bool(vitals.call("is_dead")), "hits_mine": _charged_hits_mine,
		"damage_mine": _charged_damage_mine, "hits_others": _charged_hits_others,
		"events_seen": _charged_events_seen, "in_fight": _charged_in_fight(),
		"peer_id": int(sess.call("local_peer_id")) if sess != null else -1,
		"at": [at.x, at.y, at.z], "repins": _charged_pin_repins}


## Sets this peer's own health and resets the received-hit counters in the
## same frame, so health == value - sum(received hits after gear/floor).
func _charged_set_health(args: Dictionary) -> Dictionary:
	_charged_listen()
	var vitals := _charged_vitals()
	if vitals == null:
		return {"verdict": "ERROR", "detail": "no live Player vitals"}
	var value := clampf(float(args.get("value", 100.0)), 1.0, float(vitals.get("max_health")))
	vitals.set("health", value)
	_charged_reset_counts()
	return {"verdict": "PASS", "detail": "health set to %.2f" % value, "health": float(vitals.get("health"))}


func _charged_wear(args: Dictionary) -> Dictionary:
	var game := root.get_node_or_null(^"Game")
	var equipment: RefCounted = game.get("player_equipment") as RefCounted if game != null else null
	if equipment == null:
		return {"verdict": "ERROR", "detail": "no Game.player_equipment"}
	var tier := str(args.get("tier", ""))
	for slot: String in ["helmet", "upper_body", "lower_body", "boots"]:
		equipment.call("unequip", slot)
	if not tier.is_empty():
		for piece: String in ["hood", "coat", "trousers", "boots"]:
			var item := "%s_travel_%s" % [tier, piece]
			var result: Dictionary = equipment.call("equip", item)
			if not bool(result.get("ok", false)):
				return {"verdict": "FAIL", "detail": "could not equip " + item}
	var reduction := float(equipment.call("hazard_reduction", "terrain"))
	return {"verdict": "PASS", "detail": "wearing '%s', terrain reduction %.2f" % [tier, reduction],
		"terrain_reduction": reduction}


func _charged_host_ticks() -> Dictionary:
	var sess := _session()
	var lightning := _charged_lightning()
	if sess == null or not bool(sess.call("is_host")):
		return {"verdict": "FAIL", "detail": "charged_host_ticks is host-only"}
	if lightning == null:
		return {"verdict": "ERROR", "detail": "no StormwoodLightning in the host's current scene"}
	var serial := int(lightning.get("_charged_serial"))
	return {"verdict": "PASS", "detail": "host charged serial %d" % serial, "serial": serial,
		"simulation_only": bool(_charged_world().get("simulation_only"))}


func _charged_quiet_strikes() -> Dictionary:
	var sess := _session()
	var lightning := _charged_lightning()
	if sess == null or not bool(sess.call("is_host")) or lightning == null:
		return {"verdict": "FAIL", "detail": "charged_quiet_strikes needs the host's StormwoodLightning"}
	lightning.set("_next", 1.0e9)
	(lightning.get("_pending") as Array).clear()
	return {"verdict": "PASS", "detail": "host random strike scheduler parked (charged ground untouched)"}
