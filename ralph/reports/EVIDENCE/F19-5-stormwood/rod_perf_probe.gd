extends SceneTree
## Diagnostic only (not evidence): frame cost before/after the Verge-rod facts.
const SAVE := preload("res://scripts/save/save_game.gd")
const CP := preload("res://tests/helpers/four_biome_checkpoints.gd")
func _init() -> void: _run.call_deferred()
func _measure(game: Node, label: String) -> void:
	var t0 := Time.get_ticks_msec(); var f0 := Engine.get_process_frames(); var p0 := Engine.get_physics_frames()
	while Time.get_ticks_msec() - t0 < 30000: await process_frame
	var dt := (Time.get_ticks_msec() - t0) / 1000.0
	var processing := {}
	for n: Node in current_scene.find_children("*", "", true, false):
		if n.is_processing() or n.is_physics_processing():
			var s: Script = n.get_script()
			var key := "%s:%s" % [n.get_class(), s.resource_path.get_file() if s else ""]
			processing[key] = int(processing.get(key, 0)) + 1
	var keys := processing.keys(); keys.sort_custom(func(a, b): return processing[a] > processing[b])
	var top := []
	for k in keys.slice(0, 25): top.append("%s=%d" % [k, processing[k]])
	print("PROBE %s fps=%.2f physics/s=%.1f processing=%s" % [label, (Engine.get_process_frames() - f0) / dt, (Engine.get_physics_frames() - p0) / dt, ", ".join(top)])
func _run() -> void:
	var w := "/tmp/claude-0/probe/w_%d" % Time.get_ticks_usec()
	CP.copy_tree("res://tests/fixtures/earned_saves/stormwood_arrival_generated/save", w)
	var game := root.get_node("Game")
	game.set("save_system", SAVE.new(w))
	Engine.time_scale = 8.0; Engine.physics_ticks_per_second = 480; Engine.max_physics_steps_per_frame = 8
	var title := (load("res://scenes/ui/title_screen.tscn") as PackedScene).instantiate()
	root.add_child(title); current_scene = title
	for i in 10: await process_frame
	(title.get("_load_button") as Button).pressed.emit()
	await process_frame
	for n: Node in (title.get("_load_box") as Node).get_children():
		if n is Button and (n as Button).text.begins_with("Autosave"): (n as Button).pressed.emit(); break
	for f in 7200:
		await process_frame
		if current_scene != title and current_scene != null and current_scene.get_node_or_null("Player") != null and str(game.pending_realm_entry).is_empty(): break
	for i in 300: await physics_frame
	var player := current_scene.get_node("Player") as Node3D
	player.global_position = Vector3(-629.5, 23.5, 899.7)
	for i in 120: await physics_frame
	await _measure(game, "baseline_at_verge_road")
	for flag in ["stormwood:trainer:officer_maren_verge_rod:defeated"]:
		print("PROBE set ", flag, " ", game.ledger.submit({"kind": "set_world_flag", "realm": "stormwood", "id": flag, "value": true}))
	await _measure(game, "after_maren_defeated")
	print("PROBE set rod ", game.ledger.submit({"kind": "set_world_flag", "realm": "stormwood", "id": "stormwood:rod_verge_disabled", "value": true}))
	await _measure(game, "after_rod_verge_disabled")
	quit()
