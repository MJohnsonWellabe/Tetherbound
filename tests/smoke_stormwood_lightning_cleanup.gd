extends SceneTree

## Real warning/impact/timeout lifecycle without building a terrain world.
## Also: the strike bolt and light free themselves, and an impact's whole-sky
## flash is gated per peer by the real surge node (F10 review B1): a distant
## impact outside Break leaves this peer's sky dark, a nearby one flashes it,
## and in Break every impact does.
const LIGHTNING := preload("res://scripts/world/stormwood_lightning.gd")
const SURGE := preload("res://scripts/world/stormwood_surge.gd")
const MOTION_PREFS := preload("res://scripts/ui/motion_prefs.gd")

class WorldFixture extends Node3D:
	var simulation_only := false

class SessionFixture extends Node:
	func local_peer_id() -> int: return 1

class LightningFixture extends LIGHTNING:
	func _ready() -> void: pass
	func _process(_delta: float) -> void: pass

class SurgeFixture extends SURGE:
	func _ready() -> void: pass
	func _process(_delta: float) -> void: pass

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var world := WorldFixture.new()
	root.add_child(world)
	var session := SessionFixture.new()
	world.add_child(session)
	var player := Node3D.new()
	player.name = "Player"
	world.add_child(player)
	var surge := SurgeFixture.new()
	surge.name = "StormwoodSurge"
	world.add_child(surge)
	surge.world = world
	var lightning := LightningFixture.new()
	world.add_child(lightning)
	lightning.world = world
	lightning.session = session
	lightning.surge = surge

	# Lifecycle (unchanged contract).
	surge.phase = "break"
	surge.settle_presentation()
	lightning._receive({"id": 1, "kind": "warning", "at": Vector3.ZERO})
	var impacted: Node = lightning._visuals[1]
	var rim := float(impacted.get_meta("rim_radius_m"))
	var seconds := float(impacted.get_meta("telegraph_seconds"))
	lightning._receive({"id": 1, "kind": "impact", "at": Vector3.ZERO, "hits": {}})
	var bolts_after_impact := lightning.find_children("StrikeBolt", "", false, false).size()
	var lights_after_impact := lightning.find_children("StrikeLight", "", false, false).size()
	var break_flash := surge.flash_level()
	lightning._receive({"id": 2, "kind": "warning", "at": Vector3.ONE})
	var expired: Node = lightning._visuals[2]
	await create_timer(0.6).timeout
	var impact_freed := not is_instance_valid(impacted)
	var strike_freed := lightning.find_children("StrikeBolt", "", false, false).is_empty() \
		and lightning.find_children("StrikeLight", "", false, false).is_empty()
	await create_timer(3.0).timeout
	var expiry_freed := not is_instance_valid(expired)
	var clean := lightning._visuals.is_empty()

	# B1 gate, both directions, outside Break.
	surge._flash = 0.0
	surge.phase = "calm"
	surge.settle_presentation()
	lightning._receive({"id": 3, "kind": "impact", "at": Vector3(250, 0, 0), "hits": {}})
	var far_calm_flash := surge.flash_level()
	var far_bolt := lightning.find_children("StrikeBolt", "", false, false)
	var bolt_local := far_bolt.size() == 1 and (far_bolt[0] as Node3D).global_position.distance_to(Vector3(250, 0, 0)) < 50.0
	lightning._receive({"id": 4, "kind": "impact", "at": Vector3(2, 0, 0), "hits": {}})
	var near_calm_flash := surge.flash_level()
	surge._flash = 0.0
	surge.phase = "break"
	surge.settle_presentation()
	lightning._receive({"id": 5, "kind": "impact", "at": Vector3(250, 0, 0), "hits": {}})
	var far_break_flash := surge.flash_level()

	# UX 8 reduced motion: the sky flash drops to reduced_motion_scale, but
	# the gameplay tells (telegraph ring and local bolt) still draw.
	MOTION_PREFS.set_reduced_motion(true)
	surge._flash = 0.0
	for old_bolt: Node in lightning.find_children("StrikeBolt", "", false, false):
		old_bolt.free()
	lightning._receive({"id": 6, "kind": "warning", "at": Vector3(1, 0, 1)})
	var reduced_ring := lightning._visuals.has(6)
	lightning._receive({"id": 6, "kind": "impact", "at": Vector3(1, 0, 1), "hits": {}})
	var reduced_flash := surge.flash_level()
	var reduced_bolt := lightning.find_children("StrikeBolt", "", false, false).size() == 1
	MOTION_PREFS.set_reduced_motion(false)
	var reduced_ok := reduced_ring and reduced_bolt and reduced_flash <= 0.2 and reduced_flash > 0.0

	var ok := impact_freed and expiry_freed and clean and strike_freed \
		and bolts_after_impact == 1 and lights_after_impact == 1 and is_equal_approx(break_flash, 1.0) \
		and is_equal_approx(rim, 3.0) and is_equal_approx(seconds, 1.2) \
		and far_calm_flash == 0.0 and bolt_local and near_calm_flash > 0.8 and is_equal_approx(far_break_flash, 1.0) \
		and reduced_ok
	print("LIGHTNING CLEANUP impact_freed=%s expiry_freed=%s registry_empty=%s strike_freed=%s bolt=%d light=%d" % [
		impact_freed, expiry_freed, clean, strike_freed, bolts_after_impact, lights_after_impact])
	# Informational CPU cost of one warning build (headless: no GPU work).
	var t0 := Time.get_ticks_usec()
	for _i in 50:
		lightning._build_telegraph(Vector3(1, 0, 1)).free()
	var build_us := (Time.get_ticks_usec() - t0) / 50.0
	print("LIGHTNING TELEGRAPH rim_m=%.2f seconds=%.2f build_us=%.0f height_calls=%d" % [
		rim, seconds, build_us, lightning.last_telegraph_height_calls])
	print("LIGHTNING SKY GATE break=%.2f far_calm=%.2f near_calm=%.2f far_break=%.2f bolt_local=%s" % [
		break_flash, far_calm_flash, near_calm_flash, far_break_flash, bolt_local])
	print("LIGHTNING REDUCED MOTION ring=%s bolt=%s sky_flash=%.2f" % [reduced_ring, reduced_bolt, reduced_flash])
	print("LIGHTNING CLEANUP RESULT %s" % ("PASS" if ok else "FAIL"))
	world.free()
	quit(0 if ok else 1)
