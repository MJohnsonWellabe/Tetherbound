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

class RigFixture extends Node3D:
	var _target: Node3D = null

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
	# A real body, so the own-RID exclusion path runs.
	var player := CharacterBody3D.new()
	player.name = "Player"
	var capsule := CollisionShape3D.new()
	capsule.shape = CapsuleShape3D.new()
	player.add_child(capsule)
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
	for old_node: Node in lightning.find_children("StrikeBolt", "", false, false) \
			+ lightning.find_children("StrikeLight", "", false, false):
		old_node.free()
	lightning._receive({"id": 6, "kind": "warning", "at": Vector3(1, 0, 1)})
	var reduced_ring := lightning._visuals.has(6)
	lightning._receive({"id": 6, "kind": "impact", "at": Vector3(1, 0, 1), "hits": {}})
	var reduced_flash := surge.flash_level()
	var reduced_bolt := lightning.find_children("StrikeBolt", "", false, false).size() == 1
	var reduced_lights := lightning.find_children("StrikeLight", "", false, false)
	var reduced_light_energy := (reduced_lights[-1] as OmniLight3D).light_energy if not reduced_lights.is_empty() else -1.0
	MOTION_PREFS.set_reduced_motion(false)
	var reduced_ok := reduced_ring and reduced_bolt and reduced_flash <= 0.2 and reduced_flash > 0.0 \
		and reduced_light_energy >= 0.0 and reduced_light_energy <= 8.0 * 0.2

	# Roof suppression with a real physics roof (review should-fix): a
	# StaticBody roof over the trainer suppresses the near rain; removed, the
	# rain returns. Camera outside the roof, so only the trainer probe counts.
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.global_position = Vector3(0, 2, 30)
	camera.make_current()
	surge._rain = surge._build_rain()
	surge.add_child(surge._rain)
	surge._update_rain({"rain_visible": true, "rain_amount": 1.0, "night_scale": 1.0, "day_t": 1.0})
	var roof := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(10, 0.3, 10)
	shape.shape = box
	roof.add_child(shape)
	world.add_child(roof)
	roof.global_position = Vector3(0, 4, 0)
	for _frame in 3:
		await physics_frame
	surge._refresh_roof(player)
	var roofed := surge._roofed
	for _i in 30:
		surge._advance_roof(0.05)
	var under_roof := surge._rain.amount_ratio
	roof.free()
	for _frame in 3:
		await physics_frame
	surge._refresh_roof(player)
	for _i in 30:
		surge._advance_roof(0.05)
	var in_open := surge._rain.amount_ratio
	var roof_ok := roofed and under_roof < 0.001 and in_open > 0.99

	# Review N2: the roof probe follows the camera's FRAMED SUBJECT. With the
	# rig on a piloted creature in the open, a trainer under a roof must not
	# dry the creature's rain; framing the trainer again, it does; and a
	# camera under a roof still counts on its own.
	var rig := RigFixture.new()
	rig.name = "CameraRig"
	world.add_child(rig)
	var creature := CharacterBody3D.new()
	var creature_shape := CollisionShape3D.new()
	creature_shape.shape = CapsuleShape3D.new()
	creature.add_child(creature_shape)
	world.add_child(creature)
	creature.global_position = Vector3(20, 0, 0)
	var roof2 := StaticBody3D.new()
	var shape2 := CollisionShape3D.new()
	var box2 := BoxShape3D.new()
	box2.size = Vector3(10, 0.3, 10)
	shape2.shape = box2
	roof2.add_child(shape2)
	world.add_child(roof2)
	roof2.global_position = Vector3(0, 4, 0)
	camera.global_position = Vector3(20, 2, 30)
	for _frame in 3:
		await physics_frame
	rig._target = creature
	surge._refresh_roof(player)
	var piloting_roofed := surge._roofed
	rig._target = player
	surge._refresh_roof(player)
	var trainer_roofed := surge._roofed
	rig._target = creature
	camera.global_position = Vector3(0, 2, 1)
	surge._refresh_roof(player)
	var camera_roofed := surge._roofed
	var subject_ok := not piloting_roofed and trainer_roofed and camera_roofed

	var ok := impact_freed and expiry_freed and clean and strike_freed \
		and bolts_after_impact == 1 and lights_after_impact == 1 and is_equal_approx(break_flash, 1.0) \
		and is_equal_approx(rim, 3.0) and is_equal_approx(seconds, 1.2) \
		and far_calm_flash == 0.0 and bolt_local and near_calm_flash > 0.8 and is_equal_approx(far_break_flash, 1.0) \
		and reduced_ok and roof_ok and subject_ok
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
	print("LIGHTNING REDUCED MOTION ring=%s bolt=%s sky_flash=%.2f strike_light=%.2f" % [reduced_ring, reduced_bolt, reduced_flash, reduced_light_energy])
	print("RAIN ROOF roofed=%s near_under_roof=%.2f near_in_open=%.2f" % [roofed, under_roof, in_open])
	print("RAIN ROOF SUBJECT piloting_open=%s framing_trainer=%s camera_under_roof=%s" % [piloting_roofed, trainer_roofed, camera_roofed])
	print("LIGHTNING CLEANUP RESULT %s" % ("PASS" if ok else "FAIL"))
	world.free()
	quit(0 if ok else 1)
