extends SceneTree

## Disclosed chapter-end diagnostic: five level55 companions, freed tether
## flags and one initial interior pose. Then the actual earned helper owns
## every movement, invitation and GUI input. Never campaign acceptance.
const ENDING := preload("res://tests/helpers/water_earned_ending_segment.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const SAVE := preload("res://scripts/save/save_game.gd")
var finished := false

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	_watchdog.call_deferred()
	var game := root.get_node("Game")
	game.save_system = SAVE.new("user://earned_guardian_probe_%d/" % Time.get_ticks_usec())
	game.reset_for_new_game()
	game.current_realm = "water"
	game.local.character_id = "earned-guardian-probe"
	game.world.world_id = "earned-guardian-world"
	for index in 5:
		var member := SPECIES.spawn("water_mosshell")
		member.set_level(55, preload("res://scripts/creatures/progression.gd").config())
		game.party.add(member)
	for flag in ["water_captain_nerissa_defeated", "water_tether_disabled", "water_guardian_freed"]:
		game.world.flags.set_flag(flag)
	var world := preload("res://scenes/world/water_archipelago.tscn").instantiate()
	root.add_child(world)
	current_scene = world
	var deadline := Time.get_ticks_msec() + 90000
	while not world.shell_build_complete() and Time.get_ticks_msec() < deadline:
		await process_frame
	if not world.shell_build_complete():
		_finish(false, "Water world failed its original90s setup bound")
		return
	var cave := world.get_node("WaterVeilfall")
	var prompt: Node3D = cave.get("_guardian_prompt")
	var player: CharacterBody3D = world.local_rig()
	player.global_position = prompt.global_position + Vector3(0, -1.3, -1.8)
	player.velocity = Vector3.ZERO
	for frame in 8:
		await physics_frame
	print("FIXTURE only: freed tether flags, fiveMosshell55, initialinteriorpose=", player.global_position)
	var segment := ENDING.new()
	var result: Dictionary = await segment.run_earned(self, world, game)
	print("ACTUAL EARNED ENDING HELPER ", JSON.stringify(result))
	if not bool(result.ok):
		_finish(false, "actual controller ending helper failed")
		return
	var character: Dictionary = game.save_system.get("_characters").read(game.local.character_id)
	var disk: Dictionary = game.save_system.get("_worlds").read(game.world.world_id)
	var saved := (character.get("party", []) as Array).size() == 5 \
		and (character.get("flags", {}).get("flags", []) as Array).has("water_capture_receipt:" + segment._claim_id) \
		and not (disk.get("water_capture_claims", {}) as Dictionary).has(segment._claim_id)
	for flag in ENDING.END_FLAGS:
		saved = saved and (disk.get("flags", {}).get("flags", []) as Array).has(flag)
	_finish(saved, "Actual GUI newcomer decline saved five/receipt/host acknowledgment/endingflags")

func _watchdog() -> void:
	await create_timer(180.0).timeout
	if not finished:
		_finish(false, "bounded guardian diagnostic exceeded180s")

func _finish(passed: bool, reason: String) -> void:
	finished = true
	print("GUARDIAN FAREWELL NATIVE RESULT passed=", passed, " reason=", reason)
	quit(0 if passed else 1)
