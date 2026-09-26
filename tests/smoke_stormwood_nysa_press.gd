extends SceneTree

## F11 focused reproduction: the earned witness (run 26) pressed Interact on
## Officer Nysa's held-winning challenge prompt at the Deepwood rod station and
## the arbiter activated circuit Tavi, 8.9 m away. This stages the facts the
## earned run held at that point (Rootgate released, Lantern Hollow reached,
## Sable's truth, the Verge and Hollows rods down, the Crown guardian cleared,
## the Deepwood Circuit not offered), a party of five at level 46, and runs the
## earned Dynamo segment's own approach-and-press code on Nysa, optionally after
## an ordinary won wild fight nearby (`-- --after-fight`), as in run 26.
##
## Disclosed fixture: flags through the host ledger, party through the party
## seam, debug travel to the Deepwood station.

const SAVE_GAME := preload("res://scripts/save/save_game.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const DYNAMO_SEGMENT := preload("res://tests/helpers/stormwood_earned_dynamo_segment.gd")
const NAVIGATOR := preload("res://tests/helpers/stick_navigator.gd")
const TEST_SAVE_DIR := "user://stormwood_nysa_press_smoke"
const FLAGS: Array[String] = ["stormwood:chapter_started", "stormwood:rootgate_released",
	"stormwood:act_ii_complete", "stormwood:engine_truth_learned", "stormwood:named:crown_guardian:cleared",
	"stormwood:rod_verge_disabled", "stormwood:rod_hollows_disabled", "stormwood:lantern_hollow_reached",
	"stormwood:captive_truth_learned", "stormwood:crown_reached", "stormwood:arch_recipe_known"]

var _failures: Array[String] = []


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(900.0).timeout.connect(func() -> void:
		_failures.append("900 s watchdog")
		_finish())
	var game := root.get_node_or_null(^"Game")
	await process_frame
	game.call("reset_for_new_game")
	game.set("save_system", SAVE_GAME.new(TEST_SAVE_DIR))
	game.set("current_realm", "stormwood")
	game.call("bind_realm_map")
	for species_id: String in ["sparkit", "mudsnout", "bramblebun", "terrapup", "brooktail"]:
		var creature: RefCounted = SPECIES.spawn(species_id)
		creature.call("set_level", 46, PROGRESSION.config())
		game.get("party").call("add", creature)
	var world := (load("res://scenes/world/stormwood.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(world)
	current_scene = world
	while not bool(world.call("shell_build_complete")):
		await process_frame
	for flag: String in FLAGS:
		game.get("ledger").call("submit", {"kind": "set_world_flag", "realm": "stormwood", "id": flag, "value": true})
	for _i in 30:
		await physics_frame
	var segment: RefCounted = DYNAMO_SEGMENT.new()
	segment.set("_tree", self)
	segment.set("_world", world)
	segment.set("_game", game)
	segment.set("_player", world.get_node("Player"))
	segment.set("_camera", world.get_node("CameraRig"))
	segment.set("_manager", world.get_node("CombatManager"))
	segment.set("_director", world.get_node("EncounterDirector"))
	segment.set("_arbiter", get_first_node_in_group("interaction_arbiter"))
	segment.set("_navigator", NAVIGATOR.new(self, world.get_node("Player"), world.get_node("CameraRig"),
		Callable(segment, "_drive_stick")))
	var player := world.get_node("Player") as CharacterBody3D
	# Run 26 came to Nysa from a rest at Lantern Hollow Waycamp; `--from-camp`
	# starts there so the approach walk passes circuit Tavi as it did.
	var start := Vector2(-422, 3924) if OS.get_cmdline_user_args().has("--from-camp") else Vector2(-890, 4470)
	player.global_position = Vector3(start.x, float(world.call("ground_height_at", start.x, start.y)) + 1.0, start.y)
	for _i in 60:
		await physics_frame
	# The earned witness walks at the wrapper's 8x/480 Hz clock; `--witness-clock`
	# reproduces it (run 26 pressed Nysa at that clock).
	if OS.get_cmdline_user_args().has("--witness-clock"):
		Engine.time_scale = 8.0
		Engine.physics_ticks_per_second = 480
		Engine.max_physics_steps_per_frame = 32
	var arbiter := get_first_node_in_group("interaction_arbiter")
	var log_activation := func(provider: Object) -> void:
		print("NYSA PRESS activation %s viewer=%s player=%s" % [str((provider as Node).get_path()),
			str(arbiter.call("viewer").get_path()), str(player.global_position)])
	arbiter.activated.connect(log_activation)
	# The same observers the segment's own run() connects.
	game.get_node("Session").stormwood_encounter_message.connect(Callable(segment, "_observe_trainer"))
	world.get_node("CombatManager").exited.connect(Callable(segment, "_on_combat_exited"))
	# `--worn-lead` reproduces runner run 27b's order: a worn lead (as after the
	# won Deepwood-station wild), so the segment rests at Lantern Hollow, walks
	# back, sends out the fittest member with LB, then challenges Nysa.
	if OS.get_cmdline_user_args().has("--worn-lead"):
		for member: RefCounted in game.get("party").call("members"):
			if str(member.get("species_id")) == "terrapup":
				member.set("hp", 250.0)
	var ok: bool = await segment.call("_trainer", "officer_nysa_deepwood_rod")
	var hub := world.get_node_or_null("StormwoodEncounterHub")
	print("NYSA PRESS hub last_start_refusal=%s trainer_events=%s" % [
		str(hub.get("last_start_refusal")) if hub != null else "?", str(segment.get("_trainer_events"))])
	print("NYSA PRESS outcomes %s defeated=%s" % [str(segment.get("_outcomes")),
		str(game.get("progression").call("has", "stormwood:trainer:officer_nysa_deepwood_rod:defeated"))])
	for line: String in segment.get("transcript"):
		print("NYSA PRESS — ", line)
	for line: String in segment.get("failures"):
		_failures.append(line)
	if not ok and _failures.is_empty():
		_failures.append("_trainer returned false")
	_finish()


func _finish() -> void:
	Engine.time_scale = 1.0
	Engine.physics_ticks_per_second = 60
	var absolute := ProjectSettings.globalize_path(TEST_SAVE_DIR)
	if DirAccess.dir_exists_absolute(absolute):
		for file: String in DirAccess.get_files_at(absolute):
			DirAccess.remove_absolute(absolute.path_join(file))
	for line in _failures:
		print("NYSA PRESS FAIL: ", line)
	print("STORMWOOD NYSA PRESS %s" % ["OK" if _failures.is_empty() else "FAILED"])
	quit(0 if _failures.is_empty() else 1)
