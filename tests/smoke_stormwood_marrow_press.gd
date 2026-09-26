extends SceneTree

## F11 focused reproduction before the earned witness reaches the Dynamo core
## (handoff risk: Captain Marrow is a same-person NPC + trainer pair at one
## seat, so the NPC prompt may win the challenge press). This stages the facts
## an earned run holds on arriving at the core (every critical flag through
## `stormwood:core_reached`, Kestrel beaten), a party of five at level 46,
## places the player on the core, and runs the earned Marrow segment's own
## press, five hosted rounds and four-conduit Break unchanged. It stops at the
## automatic Stormheart release, before any offer, as the segment does.
##
## Disclosed fixture: flags through the host ledger, party through the party
## seam, debug travel onto the core.

const SAVE_GAME := preload("res://scripts/save/save_game.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const MARROW_SEGMENT := preload("res://tests/helpers/stormwood_earned_marrow_segment.gd")
const TEST_SAVE_DIR := "user://stormwood_marrow_press_smoke"
const CHAPTER_CONFIG := "res://data/config/stormwood_chapter.json"
const STOP_AT := "stormwood:marrow_defeated"
## Facts an earned run also holds at the core that the chapter's main list
## names only in aggregate (each rod, each Dynamo approach trainer).
const EARNED_EXTRA: Array[String] = ["stormwood:rod_verge_disabled", "stormwood:rod_hollows_disabled",
	"stormwood:rod_deepwood_disabled", "stormwood:trainer:officer_nysa_deepwood_rod:defeated",
	"stormwood:trainer:outerworks_lieutenant_sera:defeated", "stormwood:trainer:officer_kestrel_outer_works:defeated"]

var _failures: Array[String] = []


func _init() -> void:
	_run.call_deferred()


## Every critical chapter flag before Marrow's defeat, in authored order.
static func staged_flags() -> Array[String]:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CHAPTER_CONFIG))
	var out: Array[String] = []
	if not parsed is Dictionary:
		return out
	var persistent: Dictionary = (parsed as Dictionary).get("persistent_flags", {})
	for raw: Variant in (persistent.get("main", []) as Array):
		var flag := str(raw)
		if flag == STOP_AT:
			break
		out.append(flag)
	for flag: String in EARNED_EXTRA:
		if not out.has(flag):
			out.append(flag)
	return out


func _run() -> void:
	create_timer(1500.0).timeout.connect(func() -> void:
		_failures.append("1500 s watchdog")
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
	var flags := staged_flags()
	if not flags.has("stormwood:kestrel_defeated") or not flags.has("stormwood:core_reached"):
		_failures.append("chapter critical path lacks Kestrel/core flags: %s" % str(flags))
		_finish()
		return
	for flag: String in flags:
		game.get("ledger").call("submit", {"kind": "set_world_flag", "realm": "stormwood", "id": flag, "value": true})
	for _i in 30:
		await physics_frame
	var player := world.get_node("Player") as CharacterBody3D
	# Where the earned ascent ends (`_walk_actual_ascent`): the top of the
	# Stormheart helix, ~150 m above the terrain, beside Marrow's seat.
	var trunk := world.get_node_or_null("StormheartTree") as Node3D
	if trunk == null:
		_failures.append("no StormheartTree")
		_finish()
		return
	player.global_position = (trunk.call("core_anchor") as Vector3) + Vector3.UP * 0.5
	for _i in 60:
		await physics_frame
	print("MARROW PRESS standing at %s (core seat y 262.21)" % str(player.global_position))
	var arbiter := get_first_node_in_group("interaction_arbiter")
	arbiter.activated.connect(func(provider: Object) -> void:
		print("MARROW PRESS activation %s player=%s" % [str((provider as Node).get_path()),
			str(player.global_position)]))
	var hub := world.get_node_or_null("StormwoodEncounterHub")
	var segment: RefCounted = MARROW_SEGMENT.new()
	var result: Dictionary = await segment.call("run", self, world, game)
	print("MARROW PRESS hub last_start_refusal=%s outcomes=%s" % [
		str(hub.get("last_start_refusal")) if hub != null else "?", str(segment.get("_outcomes"))])
	for line: String in result.get("transcript", []):
		print("MARROW PRESS — ", line)
	for line: String in result.get("failures", []):
		_failures.append(line)
	if not bool(result.get("passed", false)) and _failures.is_empty():
		_failures.append("Marrow segment did not pass")
	for flag: String in MARROW_SEGMENT.END_FLAGS:
		if not bool(game.get("progression").call("has", flag)):
			_failures.append("missing end flag " + flag)
	_finish()


func _finish() -> void:
	Engine.time_scale = 1.0
	Engine.physics_ticks_per_second = 60
	var absolute := ProjectSettings.globalize_path(TEST_SAVE_DIR)
	if DirAccess.dir_exists_absolute(absolute):
		for file: String in DirAccess.get_files_at(absolute):
			DirAccess.remove_absolute(absolute.path_join(file))
	for line in _failures:
		print("MARROW PRESS FAIL: ", line)
	print("STORMWOOD MARROW PRESS %s" % ["OK" if _failures.is_empty() else "FAILED"])
	quit(0 if _failures.is_empty() else 1)
