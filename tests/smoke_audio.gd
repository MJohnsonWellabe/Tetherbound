extends SceneTree

## Does the SHIPPING GAME make a sound?
##
##   godot --headless --path . --script tests/smoke_audio.gd
##
## The repo's evidence rule is that evidence which does not show the shipping
## game is worse than no evidence, and audio makes that unusually easy to fake:
## a test that asserts `assets/audio/ambience/wind_low.wav` exists on disk
## passes on a build where nothing is wired to play it, which is precisely the
## state this lane found the project in (fifteen files present, one script
## referencing any of them).
##
## So this proves the opposite thing. It boots `meadows_playground.tscn` -- the
## real world, the same scene `smoke_combat.gd` and every other smoke test drive
## -- walks the player with real input actions, fights a real fight, and asserts
## on what actually reached the mixer, via `AudioManager.recent()`.
##
## **Why a log rather than a listener.** CI has no audio device, so nothing can
## measure output. But everything up to the device is real here: the streams are
## loaded, the pool nodes exist in the tree, the bus indices are resolved, and
## `play()` is called on real `AudioStreamPlayer`s. `AudioManager` records each
## call when `logging_enabled` is set. A regression that breaks the wiring --
## a renamed signal, a missing file, a bus typo, an ambience layer that never
## starts -- fails here. A regression that only a human ear could catch does
## not, and this file does not pretend otherwise.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const AUDIO := preload("res://scripts/audio/audio_manager.gd")

## Matches smoke_combat.gd: long enough for terrain, collision and the director.
const SETTLE_FRAMES := 240
const WALK_FRAMES := 150
const FIGHT_FRAME_LIMIT := 2000

var _failures: Array[String] = []
var _world: Node = null
var _player: CharacterBody3D = null
var _audio: Node = null
var _manager: Node = null
var _director: Node = null


func _init() -> void:
	_run()


func _run() -> void:
	AUDIO.logging_enabled = true

	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in SETTLE_FRAMES:
		await physics_frame

	if not _collect_nodes():
		_report()
		return

	_the_mixer_exists()
	await _the_world_has_an_ambient_bed()

	# Out of Grandpa's farmhouse and onto open meadow near the practice cluster,
	# exactly as smoke_combat.gd does and for the same reason: this test does not
	# drive the opening, and the rest of it needs meadow and wild creatures
	# rather than an interior wall.
	await _ensure_ally()
	_leave_the_farmhouse()
	for i in 60:
		await physics_frame

	await _walking_makes_footsteps()
	# The fight runs BEFORE the region check: engaging needs the practice
	# cluster's wild creatures, and the region check teleports 2 km up the
	# corridor away from them.
	await _a_fight_is_audible()
	await _the_ambience_changes_between_regions()
	_report()


func _collect_nodes() -> bool:
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_audio = _world.get_node_or_null(^"WorldAudio")
	_manager = _world.get_node_or_null(^"CombatManager")
	_director = _world.get_node_or_null(^"EncounterDirector")
	if _player == null:
		_fail("no Player in the world scene")
	if _audio == null:
		_fail("no WorldAudio node in meadows_playground.tscn -- nothing plays anything")
	return _player != null and _audio != null


# --- the checks --------------------------------------------------------------


## The buses named in audio.json all exist in the layout the engine loaded.
## A bus that is missing does not error at play time -- the sound routes to
## Master at the wrong level and ignores the player's slider for its category.
func _the_mixer_exists() -> void:
	var buses: Dictionary = AUDIO.section("buses")
	var order: Variant = buses.get("order", [])
	if typeof(order) != TYPE_ARRAY or (order as Array).is_empty():
		_fail("audio.json names no buses")
		return
	for entry: Variant in order as Array:
		var name := str(entry)
		if AudioServer.get_bus_index(name) < 0:
			_fail("audio.json names bus '%s' but default_bus_layout.tres has no such bus" % name)


## At least one ambience layer is PLAYING, in the world, having been started by
## the world's own node rather than by this test.
func _the_world_has_an_ambient_bed() -> void:
	var playing: Array[String] = []
	for child in _audio.get_children():
		if not (child is AudioStreamPlayer):
			continue
		var player := child as AudioStreamPlayer
		if player.name.begins_with("Ambience_") and player.playing:
			playing.append(player.name)

	if playing.is_empty():
		_fail("no ambience layer is playing in the real world scene; the Meadows is silent")
		return
	print("  ambience playing: %s" % ", ".join(playing))

	# Playing is not enough -- a layer at -80 dB is playing and inaudible.
	for child in _audio.get_children():
		if child is AudioStreamPlayer and (child as AudioStreamPlayer).playing \
				and (child as AudioStreamPlayer).name.begins_with("Ambience_"):
			var db := (child as AudioStreamPlayer).volume_db
			if db < -60.0:
				_fail("%s is playing but at %.1f dB, which is silence" % [child.name, db])
	await physics_frame


## Walking the player with the real input action produces footstep sounds on the
## SFX bus, and they are not all the same variant.
func _walking_makes_footsteps() -> void:
	AUDIO.clear_log()
	Input.action_press("move_forward")
	for i in WALK_FRAMES:
		await physics_frame
	Input.action_release("move_forward")
	await physics_frame

	var steps: Array[Dictionary] = []
	for entry in AUDIO.recent():
		if str((entry as Dictionary).get("name", "")).begins_with("step_"):
			steps.append(entry as Dictionary)

	if steps.is_empty():
		_fail("the player walked for %d frames and made no footstep sound" % WALK_FRAMES)
		return
	print("  %d footsteps over %d frames" % [steps.size(), WALK_FRAMES])

	for step in steps:
		if str(step.get("bus", "")) != "SFX":
			_fail("a footstep played on bus '%s', not SFX" % step.get("bus", ""))
			break

	# The whole reason the generator writes four variants per surface. One
	# repeated file is the single most fatiguing sound a game can make, and a
	# regression in `pick_variant` would be inaudible to every other test.
	if steps.size() >= 4:
		var paths: Array[String] = []
		for step in steps:
			var path := str(step.get("path", ""))
			if not paths.has(path):
				paths.append(path)
		if paths.size() < 2:
			_fail("every one of %d footsteps played the same file (%s); variants are not working"
				% [steps.size(), paths[0] if not paths.is_empty() else "?"])
		else:
			print("  %d distinct footstep variants used" % paths.size())


## Moving the player between two bands changes the ambience mix.
##
## This is the check that would have caught the whole feature being wired to a
## constant: it drives the player to a z well inside Band 2 and asserts the set
## of playing layers is genuinely different from Band 1's.
func _the_ambience_changes_between_regions() -> void:
	var before := _playing_layers()

	# Band 2 begins at z = 1360 (the trail's own band boundary, which
	# world_audio.gd derives from terrain_playground.json). Well inside it.
	_player.global_position = Vector3(0.0, _player.global_position.y + 2.0, 2000.0)
	# Long enough to cover band_fade_seconds; the fade is deliberately slow.
	for i in 480:
		await physics_frame

	var after := _playing_layers()
	print("  band 1 layers: %s" % ", ".join(before))
	print("  band 2 layers: %s" % ", ".join(after))

	if after.is_empty():
		_fail("moving into Band 2 left no ambience playing at all")
		return
	if before == after:
		_fail("Band 1 and Band 2 play an identical layer set (%s); the regions do not "
			% ", ".join(before) + "sound different")


## A real fight produces combat audio, driven by combat_manager.gd's own signals.
func _a_fight_is_audible() -> void:
	if _manager == null or _director == null:
		_fail("no CombatManager/EncounterDirector; combat audio was not tested")
		return

	AUDIO.clear_log()
	if not await _start_a_fight():
		_fail("could not start a fight; combat audio was not tested")
		return

	if not AUDIO.recent_names().has("combat_start"):
		_fail("a fight began and no combat_start sound played")

	# Swing repeatedly with the real action. Either it connects (an impact) or
	# it misses (a whoosh); both are sounds this lane added, and either one
	# proves the manager's signals reach the mixer.
	for i in 900:
		if i % 25 == 0:
			Input.action_press("combat_quick")
			await physics_frame
			Input.action_release("combat_quick")
		await physics_frame
		if not bool(_manager.call("is_fighting")):
			break

	var names := AUDIO.recent_names()
	print("  combat sounds heard: %s" % ", ".join(names))
	var wanted := ["impact_normal", "impact_weak", "impact_super", "attack_miss", "damage_taken"]
	var heard := false
	for name in wanted:
		if names.has(name):
			heard = true
			break
	if not heard:
		_fail("a whole fight was fought and none of %s played" % ", ".join(wanted))


## Steer to the wild creature and engage it, exactly as smoke_combat.gd does.
##
## STEERED, not walked blindly: an earlier version of this pressed
## `move_forward` and hoped, which never arrived and spent the whole frame
## budget doing it. The camera yaw is what makes "forward" mean a direction, so
## aiming the rig and holding forward is also the same path the player's stick
## takes -- a broken `planar_basis` fails here rather than on the handheld.
func _start_a_fight() -> bool:
	var wild := _director.call("wild_creature") as Node3D
	if wild == null:
		return false
	var rig := _world.get_node_or_null(^"CameraRig") as Node3D
	var engage_range := 6.0

	for i in FIGHT_FRAME_LIMIT:
		if bool(_manager.call("is_fighting")):
			return true
		if not is_instance_valid(wild):
			return false
		var to := wild.global_position - _player.global_position
		to.y = 0.0
		if to.length() > engage_range * 0.6:
			if rig != null:
				rig.set("yaw", atan2(-to.x, -to.z))
			Input.action_press("move_forward")
			await physics_frame
			continue
		Input.action_release("move_forward")
		Input.action_press("interact")
		await physics_frame
		await physics_frame
		Input.action_release("interact")
		# flow.input_guard: the engage button is also the charged attack, and the
		# manager goes deaf briefly so one press is not both.
		for j in 30:
			await physics_frame
	Input.action_release("move_forward")
	return bool(_manager.call("is_fighting"))


## Matches smoke_combat.gd: the opening suspends the sandbox starter, and this
## test does not drive the opening, so it asks for a creature directly.
func _ensure_ally() -> void:
	if _director == null or _director.call("ally_instance") != null:
		return
	await _director.call("adopt_starter", "terrapup")


## The opening wakes the player in Grandpa's bed. This test bypasses it and
## needs open meadow, so it starts where smoke_combat.gd starts: beside the
## practice cluster in data/config/spawns.json.
func _leave_the_farmhouse() -> void:
	if _player == null:
		return
	_player.global_position = Vector3(48.0, _player.global_position.y + 1.0, -58.0)


# --- plumbing ----------------------------------------------------------------


func _playing_layers() -> Array[String]:
	var out: Array[String] = []
	for child in _audio.get_children():
		if child is AudioStreamPlayer and (child as AudioStreamPlayer).playing \
				and child.name.begins_with("Ambience_"):
			out.append(str(child.name).replace("Ambience_", ""))
	out.sort()
	return out


func _fail(message: String) -> void:
	_failures.append(message)


func _report() -> void:
	if _failures.is_empty():
		print("smoke_audio: OK -- the shipping game makes sound")
		quit(0)
		return
	for failure in _failures:
		printerr("smoke_audio: %s" % failure)
	printerr("smoke_audio: %d failure(s)" % _failures.size())
	quit(1)
