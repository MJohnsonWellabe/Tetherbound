extends SceneTree

## GF-B-001. "Pressing New Game freezes the game for ~50 seconds."
##
##   godot --headless --path . --script tools/_probe_new_game_stall.gd
##
## HEADLESS ON PURPOSE. Phase B measured 49,230-50,720 ms in 6 of 8 journey
## segments with the renderer OFF, so the stall is main-thread work during world
## stand-up and no GPU change touches it. Measuring it the same way keeps the
## number comparable; it also means this runs in a minute rather than the twenty
## a software-rasterised boot costs.
##
## Drives the REAL front door, not a scene load: the configured title scene,
## its own focused Start New Game button, activated through the same physical
## joypad binding `tests/smoke_title_new_game.gd` uses. A bare
## `load(WORLD_SCENE).instantiate()` would miss whatever the title, the autoload
## reset and the scene change contribute, and those are inside the freeze the
## player sees.
##
## Reports every frame over `REPORT_MS` between the press and the world being
## up, so the answer is "one blocking frame of N ms" or "a hundred frames of
## 500ms", which are different bugs. Then reports `boot_log.gd`'s own phase
## table for the launch, so the stall is attributed rather than just measured.
##
## The scene being IN THE TREE is not the same as the world being up:
## `playground_world.gd::_ready()` awaits `process_frame` twice while Terrain3D
## builds its data, and everything expensive happens after that. So the honest
## figure is "press -> settled" at the bottom, not "press -> world in tree".

const TITLE_SCENE := "res://scenes/ui/title_screen.tscn"
const WORLD_SCENE := "res://scenes/world/meadows_playground.tscn"
const BOOT_LOG := preload("res://scripts/boot/boot_log.gd")
const REPORT_MS := 100.0
const MAX_FRAMES := 3000


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := root.get_node_or_null(^"Game")
	if game == null:
		print("FAIL: Game autoload is missing")
		quit(1)
		return

	# A save left behind by a PREVIOUS run of this probe stops the next one
	# measuring anything: the title takes its overwrite path instead of
	# changing scene, the world never arrives, and the probe reports 3,000
	# quiet frames as though the stall had vanished. It also fails
	# `tests/smoke_title_new_game.gd` for the same reason, which reads as a
	# code regression and is not one -- an hour was spent on that here.
	#
	# Reported rather than deleted. A probe that silently removes a save is a
	# worse failure than one that refuses to run.
	if DirAccess.dir_exists_absolute("user://saves"):
		var slots := DirAccess.get_files_at("user://saves")
		if slots.size() > 0:
			print("REFUSING TO MEASURE: user://saves holds %s." % ", ".join(slots))
			print("Start New Game will hit the overwrite path instead of loading the world,")
			print("and every number below would be a measurement of nothing. Clear the")
			print("directory (it is container-local state, not repository content) and re-run.")
			quit(1)
			return

	var title_started := Time.get_ticks_msec()
	var packed := load(TITLE_SCENE) as PackedScene
	var title: Node = packed.instantiate() if packed != null else null
	if title == null:
		print("FAIL: title scene did not instantiate")
		quit(1)
		return
	root.add_child(title)
	current_scene = title
	await process_frame
	print("title up in %d ms" % (Time.get_ticks_msec() - title_started))

	var focused := root.get_viewport().gui_get_focus_owner() as Button
	if focused == null or focused.text != "Start New Game":
		print("FAIL: title did not focus Start New Game; got %s" % str(focused))
		quit(1)
		return

	var button_index := _pad_button_for(&"ui_accept")
	if button_index < 0:
		print("FAIL: ui_accept has no physical joypad binding")
		quit(1)
		return

	var pressed_at := Time.get_ticks_msec()
	await _pad(button_index)

	var frames: Array[float] = []
	var last := Time.get_ticks_msec()
	var arrived := -1
	for i in MAX_FRAMES:
		await process_frame
		var now := Time.get_ticks_msec()
		frames.append(float(now - last))
		last = now
		if current_scene != null and current_scene.scene_file_path == WORLD_SCENE:
			arrived = i
			break

	var total := Time.get_ticks_msec() - pressed_at
	print("\n=== press -> world in tree ===")
	if arrived < 0:
		print("WORLD NEVER ARRIVED in %d frames" % MAX_FRAMES)
	else:
		print("arrived after %d frames, %d ms total" % [arrived + 1, total])

	var worst := 0.0
	var over := 0
	var over_ms := 0.0
	for ms: float in frames:
		worst = maxf(worst, ms)
		if ms >= REPORT_MS:
			over += 1
			over_ms += ms
	print("longest single frame: %.0f ms" % worst)
	print("frames over %.0f ms: %d, totalling %.0f ms (%.0f%% of the stall)" % [
		REPORT_MS, over, over_ms, 100.0 * over_ms / maxf(1.0, float(total))])
	print("the frames over the bar, in order:")
	for i in frames.size():
		if frames[i] >= REPORT_MS:
			print("   frame %4d: %8.0f ms" % [i, frames[i]])

	# A second frame budget AFTER arrival: the player is not playing the moment
	# the scene is in the tree if the first few frames still stall.
	var after: Array[float] = []
	last = Time.get_ticks_msec()
	for i in 120:
		await process_frame
		var now := Time.get_ticks_msec()
		after.append(float(now - last))
		last = now
	var after_worst := 0.0
	var after_total := 0.0
	for ms: float in after:
		after_worst = maxf(after_worst, ms)
		after_total += ms
	print("\n=== first 120 frames after arrival ===")
	print("worst %.0f ms, mean %.1f ms, total %.0f ms" % [
		after_worst, after_total / float(after.size()), after_total])
	print("press -> settled: %d ms" % (Time.get_ticks_msec() - pressed_at))

	# Reported LAST, not at arrival. `playground_world.gd::_ready()` awaits
	# `process_frame` twice while Terrain3D builds its data, so the scene is in
	# the tree long before it has finished standing up -- a first version of this
	# probe printed the phase table two phases in and made the world look free.
	_report_phases()
	quit(0)


## `boot_log.gd`'s own record for this launch, in the order the world passed
## through the phases and again ranked by cost, so the biggest is named rather
## than having to be spotted. The order matters as much as the ranking: a phase
## that is cheap on its own but forces the one after it to be expensive reads
## quite differently in sequence.
func _report_phases() -> void:
	var rows: Array = BOOT_LOG.boot_phase_ms()
	if rows.is_empty():
		print("\n(boot_log recorded no phases -- total only)")
		return
	print("\n=== world stand-up, in order ===")
	var total := 0
	for row: Variant in rows:
		var entry: Array = row
		var ms: int = int(entry[1])
		if ms >= 0:
			total += ms
		print("   %8s  %s" % [("first" if ms < 0 else "%d ms" % ms), str(entry[0])])
	print("   %8d ms  TOTAL of the phases above" % total)

	var ranked: Array = rows.duplicate(true)
	ranked.sort_custom(func(a: Array, b: Array) -> bool: return int(a[1]) > int(b[1]))
	print("\n=== the same phases, most expensive first ===")
	for row: Variant in ranked:
		var entry: Array = row
		var ms: int = int(entry[1])
		if ms <= 0:
			continue
		print("   %8d ms  %5.1f%%  %s" % [ms, 100.0 * float(ms) / maxf(1.0, float(total)), str(entry[0])])


func _pad(button_index: int) -> void:
	var down := InputEventJoypadButton.new()
	down.button_index = button_index
	down.pressed = true
	Input.parse_input_event(down)
	await process_frame
	var up := InputEventJoypadButton.new()
	up.button_index = button_index
	up.pressed = false
	Input.parse_input_event(up)


func _pad_button_for(action: StringName) -> int:
	if not InputMap.has_action(action):
		return -1
	for event in InputMap.action_get_events(action):
		var button := event as InputEventJoypadButton
		if button != null:
			return button.button_index
	return -1
