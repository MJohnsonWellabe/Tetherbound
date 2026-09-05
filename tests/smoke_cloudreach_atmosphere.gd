extends SceneTree

const AMBIENCE := preload("res://scripts/world/cloudreach_atmosphere.gd")
const MAP := preload("res://scripts/world/cloudreach_map_state.gd")
const FLAGS := preload("res://autoload/progression_state.gd")
var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)


func _run() -> void:
	await process_frame
	var scene := Node3D.new()
	root.add_child(scene)
	var actor := Node3D.new()
	actor.position = Vector3(100, 1160, 5350)
	scene.add_child(actor)
	var flags := FLAGS.new()
	var map := MAP.new()
	map.configure_cloudreach(AMBIENCE.read_json("res://data/config/cloudreach_world.json"),
		AMBIENCE.read_json("res://data/config/cloudreach_chapter.json"), flags)
	var routes := Node3D.new()
	var traveler := Node3D.new()
	var waterward := Node3D.new()
	var shrine := OmniLight3D.new()
	shrine.light_energy = 2.0
	for node in [routes, traveler, waterward, shrine]:
		scene.add_child(node)
	var runtime := AMBIENCE.new()
	runtime.configure(flags, map, actor, {"fly_routes": [routes], "returning_travelers": [traveler],
		"waterward_overlook": [waterward], "shrine_lights": [shrine]})
	scene.add_child(runtime)
	runtime.set_process(false)
	runtime.set_finale_active(true)
	runtime.advance_mix(4.0)
	_check(runtime.audio_snapshot()["boss_music"]["playing"], "Installed finale track reaches a real audio player")
	_check(runtime.audio_snapshot()["boss_zone_escalation"]["playing"], "Installed anchor drone reaches real audio player")
	_check(not traveler.visible and not waterward.visible and not routes.visible, "Locked presentation is hidden")
	flags.set_flag("fly_traversal_unlocked")
	runtime.sync_progression()
	_check(routes.visible, "Fly unlock shows physical route markers")
	_check(map.is_landmark_discovered("sky_shrine_heartstone"), "Fly unlock reaches production map interface")
	flags.set_flag("captain_veyra_defeated")
	flags.set_flag("storm_anchor_network_disabled")
	flags.set_flag("cloudreach_winds_restored")
	flags.set_flag("waterward_route_revealed")
	runtime.sync_progression()
	runtime.advance_mix(4.0)
	var mix := runtime.audio_snapshot()
	_check(not mix["boss_zone_escalation"]["playing"] and not mix["boss_music"]["playing"], "Freed network actually stops drone/music")
	_check(mix["distant_bird_calls"]["playing"], "Restored summit plays installed distant calls")
	_check(traveler.visible and waterward.visible, "Aftermath enables supplied world presentation")
	_check(is_equal_approx(shrine.light_energy, 2.7), "Shrine brightens once")
	var loaded := FLAGS.new()
	loaded.load_data(JSON.parse_string(JSON.stringify(flags.save_data())))
	# Configure is also the explicit dependency refresh API after a realm reload.
	runtime.configure(loaded, map, actor, runtime.bindings)
	runtime.sync_progression()
	runtime.sync_progression()
	_check(is_equal_approx(shrine.light_energy, 2.7), "Reload/repeated sync cannot compound light intensity")
	_check(not loaded.has("realm_key_water") and not loaded.has("cloudreach_chapter_complete"), "Atmosphere never fabricates story completion/rewards")
	scene.queue_free()
	await process_frame
	AMBIENCE.AUDIO.reset_for_test()
	await create_timer(0.15).timeout # Let the dummy mixer release stopped playback handles.
	print("CLOUDREACH ATMOSPHERE %s: gated map, real installed audio, visible bindings, reload idempotency" % ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)
