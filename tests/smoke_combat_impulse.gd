extends SceneTree

## A single knockback must decay, not feed its previous contribution back into
## locomotion and accelerate a fighter while neither side supplies new input.
const SCENE := preload("res://scenes/creatures/creature.tscn")
const BODY := preload("res://scripts/creatures/creature_body.gd")
const ARENA := preload("res://scripts/combat/combat_arena.gd")

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var body: CharacterBody3D = SCENE.instantiate()
	body.set_script(BODY)
	root.add_child(body)
	await physics_frame
	# The real body releases overlapping host leases independently of a local
	# manager; a manager release cannot prematurely end the second hit.
	var leases_ok := true
	# The unit runner runs during SceneTree._init, before a pool root exists.
	# Exercise the actual pooled contact voice here after the real root is ready.
	var audio := preload("res://scripts/audio/audio_manager.gd")
	var mixer := preload("res://scripts/combat/impact_audio.gd")
	var semantic_layers: Array = []
	for cue: String in ["impact_normal", "impact_super", "impact_weak", "damage_taken"]:
		semantic_layers.append({"stream": audio.stream(audio.sfx_path(cue)), "gain_db": -8.0})
	var mixed := mixer.compose(semantic_layers, audio.section("combat").get("impact_feedback", {}).get("contact_mix", {}))
	var old_logging := audio.logging_enabled
	audio.logging_enabled = true
	var before := audio.recent().size()
	var contact_voice := audio.play_stream_at(mixed, "test:semantic-contact", Vector3.ZERO)
	var one_voice := contact_voice != null and contact_voice.stream == mixed and audio.recent().size() == before + 1
	leases_ok = leases_ok and one_voice
	audio.logging_enabled = old_logging
	print("Actual four-layer contact uses one pooled voice: %s" % one_voice)
	body.call("begin_combat_impact_hitstop", 0.08)
	body.call("begin_combat_impact_hitstop", 0.5)
	body.call("play_combat_flinch", Vector3.RIGHT)
	var delayed_tween := body.get("_combat_flinch_tween") as Tween
	leases_ok = leases_ok and delayed_tween != null and not delayed_tween.is_running()
	print("Reaction created during host lease is paused: %s" % (delayed_tween != null and not delayed_tween.is_running()))
	body.call("set_combat_hitstop", true)
	body.call("set_combat_hitstop", false)
	leases_ok = leases_ok and not body.is_physics_processing()
	print("Host leases after manager release: count=%d physics=%s" % [int(body.get("_combat_timed_hitstop_count")), body.is_physics_processing()])
	await create_timer(0.12).timeout
	leases_ok = leases_ok and not body.is_physics_processing()
	print("Host leases after short expiry: count=%d physics=%s" % [int(body.get("_combat_timed_hitstop_count")), body.is_physics_processing()])
	body.call("set_combat_hitstop", true)
	await create_timer(0.45).timeout
	leases_ok = leases_ok and not body.is_physics_processing()
	body.call("set_combat_hitstop", false)
	leases_ok = leases_ok and body.is_physics_processing()
	leases_ok = leases_ok and delayed_tween.is_running()
	print("Delayed reaction resumes after last owner releases: %s" % delayed_tween.is_running())
	print("Overlapping host hitstop leases / manager ownership: %s" % leases_ok)
	body.velocity = Vector3.ZERO
	body.call("add_impulse", Vector3.RIGHT, 6.0)
	var maximum := 0.0
	for frame in 60:
		await physics_frame
		maximum = maxf(maximum, Vector2(body.velocity.x, body.velocity.z).length())
	var free_tail := Vector2(body.velocity.x, body.velocity.z).length()
	var arena := ARENA.new()
	root.add_child(arena)
	body.arena = arena
	body.global_position = Vector3(arena.radius - 0.001, 0, 0)
	body.velocity = Vector3.ZERO
	body.set("_impulse", Vector3.ZERO)
	body.call("add_impulse", Vector3(1, 0, 1), 6.0)
	var edge_maximum := 0.0
	for frame in 60:
		await physics_frame
		edge_maximum = maxf(edge_maximum, Vector2(body.velocity.x, body.velocity.z).length())
	var edge_tail := Vector2(body.velocity.x, body.velocity.z).length()
	body.queue_free()
	arena.queue_free()
	await process_frame
	print("Single 6m/s impulse: peak horizontal speed %.3fm/s" % maximum)
	print("Arena diagonal 6m/s impulse: peak horizontal speed %.3fm/s" % edge_maximum)
	if not leases_ok or maximum < 4.5 or maximum > 6.01 or edge_maximum < 2.0 or edge_maximum > 6.01 \
			or free_tail > 0.01 or edge_tail > 0.01:
		print("FAIL: impulse missing, amplified, or retained a locomotion tail (%.4f, %.4f)" % [free_tail, edge_tail])
		quit(1)
	else:
		print("PASS: single impulse does not amplify itself")
		quit(0)
