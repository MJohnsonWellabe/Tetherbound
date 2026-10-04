extends SceneTree

## Builds the declared-start proof save `tools/net/proof_saves/host_meadows_stormwood_route_open/`
## at the CURRENT save version. Run it through the wrapper, which isolates
## user:// and copies the result into the fixture folder:
##
##   tools/net/build_proof_save_host_meadows_stormwood_route_open.sh
##
## The state is the one the old hand-captured v27 save held (RD-35 refuses
## it, and it is never converted): a fresh day-1 "trainer" standing in the
## Meadows with an empty party, satchel and hotbar, and the Stormwood route
## open as WORLD flags. It is produced through the game's own code:
## the title screen's fresh-identity helper, `Game.reset_for_new_game()`,
## a real boot of the Meadows scene, and `Game.save_game()`.
##
## Disclosed state writes (ACCEPTANCE §6.1 relaxed proof starts):
##   * character id pinned to FIXED_CHARACTER_ID: proof scenarios assert it
##   * world reward namespace pinned to FIXED_WORLD_NAMESPACE (determinism)
##   * world seed pinned to FIXED_WORLD_SEED: the seed the old save rolled
##   * world flags FIXTURE_WORLD_FLAGS: stand in for earning the Stormwood key
##   * player flag `opening:beat:wake` only if the booted opening has not set it

const TITLE_SCREEN := preload("res://scripts/ui/title_screen.gd")
const SAVE_GAME := preload("res://scripts/save/save_game.gd")
const SAVE_DOCUMENT := preload("res://scripts/save/save_document.gd")

const FIXED_CHARACTER_ID := "character-f41f4a49223483d6bfdf56715944bb7b"
const FIXED_WORLD_NAMESPACE := "39191e30aa1d9fb699f1f8f2fde5042a"
const FIXED_WORLD_SEED := 1423549592
const CHOSEN_CHARACTER := "trainer"
const DISPLAY_NAME := "Trainer"
const FIXTURE_WORLD_FLAGS: Array[String] = ["realm_key_stormwood", "realm_gate_stormwood_unlocked"]
const WAKE_FLAG := "opening:beat:wake"
const SLOT := 0
const SETTLE_FRAMES := 240
const PLAYER_WAIT_FRAMES := 3000

var _game: Node


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var home := OS.get_environment("XDG_DATA_HOME")
	if home.is_empty() or not OS.get_user_data_dir().begins_with(home):
		_die("run through the .sh wrapper: user:// must be an isolated XDG_DATA_HOME")
		return
	for sub: String in ["saves", "worlds", "characters"]:
		if DirAccess.dir_exists_absolute(OS.get_user_data_dir().path_join(sub)):
			_die("user:// already holds %s/; the builder needs an empty home" % sub)
			return
	_game = root.get_node_or_null(^"Game")
	if _game == null:
		_die("no Game autoload")
		return
	await process_frame

	# New Game, as the title screen does it.
	TITLE_SCREEN._set_fresh_player_identity(_game, CHOSEN_CHARACTER, DISPLAY_NAME)
	var local: Object = _game.get("local")
	local.set("character_id", FIXED_CHARACTER_ID) # disclosed
	_game.call("reset_for_new_game")
	var world: Object = _game.get("world")
	world.set("reward_delivery_namespace", FIXED_WORLD_NAMESPACE) # disclosed
	_game.set("world_seed", FIXED_WORLD_SEED) # disclosed
	if str(_game.get("current_realm")) != "meadows":
		_die("a new game should open in the Meadows, got '%s'" % str(_game.get("current_realm")))
		return

	var scene_path := str(_game.call("current_realm_scene"))
	if change_scene_to_file(scene_path) != OK:
		_die("could not boot %s" % scene_path)
		return
	var waited := 0
	while _game.call("find_player") == null and waited < PLAYER_WAIT_FRAMES:
		await process_frame
		waited += 1
	if _game.call("find_player") == null:
		_die("the Meadows booted no player within %d frames" % PLAYER_WAIT_FRAMES)
		return
	for i in SETTLE_FRAMES:
		await physics_frame

	var player_flags: Object = _game.call("player_flags")
	var wake_injected := not bool(player_flags.call("has", WAKE_FLAG))
	if wake_injected:
		_game.call("grant_player_flag", WAKE_FLAG) # disclosed
	var world_flags: Object = _game.call("world_flags")
	for flag: String in FIXTURE_WORLD_FLAGS:
		world_flags.call("set_flag", flag, true) # disclosed

	if not bool(_game.call("save_game", SLOT)):
		_die("Game.save_game(%d) refused" % SLOT)
		return
	var saver: RefCounted = _game.get("save_system")
	var slot_file := ProjectSettings.globalize_path(str(saver.call("slot_path", SLOT)))
	var raw: Variant = SAVE_DOCUMENT.parse(FileAccess.get_file_as_string(slot_file)) \
		if FileAccess.file_exists(slot_file) else null
	if not raw is Dictionary or int((raw as Dictionary).get("version", -1)) != SAVE_GAME.VERSION:
		_die("%s is not a version %d save" % [slot_file, SAVE_GAME.VERSION])
		return
	print("BUILD_PROOF_SAVE " + JSON.stringify({
		"fixture": "host_meadows_stormwood_route_open", "version": SAVE_GAME.VERSION,
		"slot_file": slot_file, "character_id": str(local.get("character_id")),
		"world_id": str(world.get("world_id")), "realm": str(_game.get("current_realm")),
		"party_size": int((_game.get("party") as Object).call("size")) if _game.get("party") is Object else -1,
		"world_flags": FIXTURE_WORLD_FLAGS, "wake_flag_injected": wake_injected,
		"pose": _game.get("saved_player_pose"),
	}))
	quit(0)


func _die(message: String) -> void:
	push_error("build_proof_save: " + message)
	print("BUILD_PROOF_SAVE_FAILED " + message)
	quit(1)
