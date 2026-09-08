extends "res://tests/smoke_water_continuous.gd"

## Diagnostic-only replay from a test-owned overnight-rest save. The source
## save was produced by smoke_water_continuous.gd after Bex and the western
## Sluice control, but before Calder. It is copied before loading because the
## production loader may write migrations/splits. This probe therefore proves
## neither the earlier route nor fresh-save continuity; it only shortens the
## ordinary Calder/control path needed to measure the later Ride interaction.
const DEFAULT_SOURCE := "user://water_continuous_late_3915153/"


func _run() -> void:
	started_ms = Time.get_ticks_msec()
	_watchdog.call_deferred()
	await process_frame
	var source := _source_dir()
	var destination := "user://probe_water_saved_suffix_%d/" % Time.get_ticks_usec()
	if not _copy_tree(source, destination):
		_fail("Could not copy test-owned source save %s to %s" % [source, destination])
		_finish()
		return

	game = root.get_node("Game")
	game.reset_for_new_game()
	var merged: Dictionary = CATALOG.merge_catalogue(SPECIES.table())
	if not _check(bool(merged.ok), "Water catalogue accepts the saved Aquaryn"):
		_finish()
		return
	SPECIES.table().merge(merged.catalogue, true)
	game.save_system = SAVE.new(destination)
	if not _check(game.load_game(0), "Copied pre-Calder test save loads through the production save path"):
		_finish()
		return
	if not _check(game.current_realm == "water", "Diagnostic source save resumes in Tidewake"):
		_finish()
		return
	for flag: String in ["water_aquaryn_resolved", "defeated_water_trainer_bex", "water_sluice_west_disabled"]:
		if not _check(game.world.flags.has(flag), "Diagnostic source already earned " + flag):
			_finish()
			return
	for absent: String in ["defeated_water_trainer_calder", "water_sluice_east_disabled", "water_dock_sluice_isle_both_controls_disabled"]:
		if not _check(not game.world.flags.has(absent), "Diagnostic source has not pre-earned " + absent):
			_finish()
			return
	_checkpoint("LOADED copied pre-Calder diagnostic save; no progression was injected")

	world = WORLD.instantiate()
	root.add_child(world)
	current_scene = world
	var deadline := Time.get_ticks_msec() + 90000
	while not world.shell_build_complete() and Time.get_ticks_msec() < deadline:
		await process_frame
	if not _check(world.shell_build_complete(), "Production Tidewake world finishes building"):
		_finish()
		return
	player = world.local_rig()
	camera = world.local_camera_rig()
	director = world.get_node("EncounterDirector")
	manager = world.get_node("CombatManager")
	riding = world.get_node("RidingController")
	navigator = NAVIGATOR.new(self, player, camera, _send_stick)
	await _frames(24)
	_checkpoint("RESUMED player=%s ally=%s" % [str(player.global_position), str(director.ally_body())])

	if director.ally_body() == null:
		await _tap("creature_recall")
		await _frames(24)
	if not _check(director.ally_body() != null, "Controller input deploys the saved healthy Aquaryn"):
		_finish()
		return

	var sluice_path := _land_route("sluice_isle_exploration_spine")
	for index in range(4, 6):
		var point: Vector3 = sluice_path[index]
		if not await _walk_to(point, "Saved suffix Sluice departure waypoint %d" % index):
			_finish()
			return
		_checkpoint("Saved suffix waypoint %d player=%s target=%s" % [
			index, str(player.global_position), str(point)])
	if not await _defeat_trainer("water_trainer_calder", "defeated_water_trainer_calder"):
		_finish()
		return
	if not await _activate_dock_action("sluice_east_control", "water_sluice_east_disabled"):
		_finish()
		return
	if not await _wait_flag("water_dock_sluice_isle_both_controls_disabled", 240):
		_fail("Both physical Sluice controls did not publish their combined completion")
		_finish()
		return
	_checkpoint("CALDER/control replay complete; measuring ordinary Ride predicates")
	if not await _mount_existing("Saved suffix Sluice departure"):
		_finish()
		return
	_checkpoint("MOUNTED through the actionable production Ride offer after Calder")
	_finish()


func _source_dir() -> String:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--source-save-dir="):
			var selected := argument.trim_prefix("--source-save-dir=")
			return selected + ("" if selected.ends_with("/") else "/")
	return DEFAULT_SOURCE


func _copy_tree(source: String, destination: String) -> bool:
	var source_absolute := ProjectSettings.globalize_path(source)
	var destination_absolute := ProjectSettings.globalize_path(destination)
	if not DirAccess.dir_exists_absolute(source_absolute):
		return false
	if DirAccess.make_dir_recursive_absolute(destination_absolute) != OK:
		return false
	var directory := DirAccess.open(source_absolute)
	if directory == null:
		return false
	directory.list_dir_begin()
	var entry := directory.get_next()
	while not entry.is_empty():
		if entry != "." and entry != "..":
			var from := source_absolute.path_join(entry)
			var to := destination_absolute.path_join(entry)
			if directory.current_is_dir():
				if not _copy_tree(from, to):
					directory.list_dir_end()
					return false
			elif DirAccess.copy_absolute(from, to) != OK:
				directory.list_dir_end()
				return false
		entry = directory.get_next()
	directory.list_dir_end()
	return true
