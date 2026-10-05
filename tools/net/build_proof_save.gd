extends SceneTree

## Builds a declared-start proof save at the CURRENT save version from a small
## declarative spec. Run it through the wrapper, which isolates user:// and
## copies the result into `tools/net/proof_saves/<fixture>/`:
##
##   tools/net/build_proof_save.sh tools/net/proof_save_specs/<fixture>.json
##
## The save is produced through the game's own code: the title screen's
## fresh-identity helper, `Game.reset_for_new_game()`, a real boot of the
## Meadows scene (the opening stages the trainer), then `Game.enter_realm()`
## when the spec names another realm, and `Game.save_game()`. It never reads
## or converts an older save (RD-35).
##
## Spec (JSON). Every field except `fixture` is optional, and every field the
## spec sets is a DISCLOSED state write (ACCEPTANCE §6.1); list them in the
## fixture's README.md:
##   fixture        output folder name under tools/net/proof_saves/
##   slot           save slot (default 0)
##   character      {id, chosen_character, display_name}: id pins the minted one
##   world          {namespace, seed}: pin the reward namespace / world seed
##   world_flags    world-scoped flags, set before any realm entry (realm keys
##                  and gate flags are flags, e.g. realm_key_stormwood)
##   player_flags   player flags, granted only if the boot did not set them
##                  (the receipt's `player_flags_injected` lists the written ones)
##   party          [{species, level?, nickname?, uid?}] added through Party.add;
##                  uid pins a valid creature uid (deterministic identity)
##   realm          realm to save in (default "meadows"), reached by enter_realm

const TITLE_SCREEN := preload("res://scripts/ui/title_screen.gd")
const SAVE_GAME := preload("res://scripts/save/save_game.gd")
const SAVE_DOCUMENT := preload("res://scripts/save/save_document.gd")
const SPECIES_DATA := preload("res://scripts/creatures/creature_species.gd")
const PARTY_SEAM := preload("res://scripts/story/party_seam.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const CREATURE_INSTANCE := preload("res://scripts/creatures/creature_instance.gd")

const START_REALM := "meadows"
const SETTLE_FRAMES := 240
const PLAYER_WAIT_FRAMES := 3000

var _game: Node


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var spec := _spec()
	if spec.is_empty():
		return
	var home := OS.get_environment("XDG_DATA_HOME")
	if home.is_empty() or not OS.get_user_data_dir().begins_with(home):
		_die("run through build_proof_save.sh: user:// must be an isolated XDG_DATA_HOME")
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
	var character: Dictionary = spec.get("character", {})
	TITLE_SCREEN._set_fresh_player_identity(_game, str(character.get("chosen_character", "trainer")),
		str(character.get("display_name", "Trainer")))
	var local: Object = _game.get("local")
	if character.has("id"):
		local.set("character_id", str(character.id))
	_game.call("reset_for_new_game")
	var world_spec: Dictionary = spec.get("world", {})
	var world: Object = _game.get("world")
	if world_spec.has("namespace"):
		world.set("reward_delivery_namespace", str(world_spec.namespace))
	if world_spec.has("seed"):
		_game.set("world_seed", int(world_spec.seed))
	if str(_game.get("current_realm")) != START_REALM:
		_die("a new game should open in the Meadows, got '%s'" % str(_game.get("current_realm")))
		return
	if not await _boot(str(_game.call("current_realm_scene"))):
		return

	var injected: Array[String] = []
	var player_flags: Object = _game.call("player_flags")
	for flag: Variant in spec.get("player_flags", []):
		if not bool(player_flags.call("has", str(flag))):
			_game.call("grant_player_flag", str(flag))
			injected.append(str(flag))
	var world_flags: Object = _game.call("world_flags")
	for flag: Variant in spec.get("world_flags", []):
		world_flags.call("set_flag", str(flag), true)
	for raw: Variant in spec.get("party", []):
		if not _add_member(raw as Dictionary if raw is Dictionary else {}):
			return

	var realm := str(spec.get("realm", START_REALM))
	if realm != START_REALM:
		if not bool(await _game.call("enter_realm", realm, str(spec.get("entry", "")))):
			_die("Game.enter_realm('%s') refused" % realm)
			return
		if not await _settle():
			return

	var slot := int(spec.get("slot", 0))
	if not bool(_game.call("save_game", slot)):
		_die("Game.save_game(%d) refused" % slot)
		return
	var saver: RefCounted = _game.get("save_system")
	var slot_file := ProjectSettings.globalize_path(str(saver.call("slot_path", slot)))
	var raw_save: Variant = SAVE_DOCUMENT.parse(FileAccess.get_file_as_string(slot_file)) \
		if FileAccess.file_exists(slot_file) else null
	if not raw_save is Dictionary or int((raw_save as Dictionary).get("version", -1)) != SAVE_GAME.VERSION:
		_die("%s is not a version %d save" % [slot_file, SAVE_GAME.VERSION])
		return
	var party: RefCounted = _game.get("party")
	var members: Array = []
	for member: Variant in party.call("members"):
		members.append({"species": str((member as Object).get("species_id")), "level": int((member as Object).get("level")),
			"uid": str((member as Object).get("uid"))})
	print("BUILD_PROOF_SAVE " + JSON.stringify({
		"fixture": str(spec.fixture), "version": SAVE_GAME.VERSION, "slot_file": slot_file,
		"character_id": str(local.get("character_id")), "world_id": str(world.get("world_id")),
		"realm": str(_game.get("current_realm")), "party": members,
		"world_flags": spec.get("world_flags", []), "player_flags_injected": injected,
		"pose": _game.get("saved_player_pose"),
	}))
	quit(0)


func _spec() -> Dictionary:
	var path := ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--spec="):
			path = arg.trim_prefix("--spec=")
	if path.is_empty():
		_die("pass -- --spec=<tools/net/proof_save_specs/<fixture>.json>")
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary or str((parsed as Dictionary).get("fixture", "")).is_empty():
		_die("%s is not a spec object with a `fixture`" % path)
		return {}
	return parsed as Dictionary


func _boot(scene_path: String) -> bool:
	if change_scene_to_file(scene_path) != OK:
		_die("could not boot %s" % scene_path)
		return false
	return await _settle()


func _settle() -> bool:
	var waited := 0
	while _game.call("find_player") == null and waited < PLAYER_WAIT_FRAMES:
		await process_frame
		waited += 1
	if _game.call("find_player") == null:
		_die("%s booted no player within %d frames" % [str(_game.get("current_realm")), PLAYER_WAIT_FRAMES])
		return false
	for i in SETTLE_FRAMES:
		await physics_frame
	return true


## The same seam a catch lands through: a species instance, its level set by
## the progression config, an optional nickname, then `Party.add` (which
## alone enforces the five-creature cap).
func _add_member(entry: Dictionary) -> bool:
	var species := str(entry.get("species", ""))
	var creature: RefCounted = SPECIES_DATA.spawn(species)
	if creature == null:
		_die("species.json has no '%s'" % species)
		return false
	if entry.has("uid"):
		if not CREATURE_INSTANCE.valid_uid(str(entry.uid)):
			_die("party uid '%s' is not a creature uid (creature_instance.gd mint_uid format)" % str(entry.uid))
			return false
		creature.set("uid", str(entry.uid))
	if entry.has("level"):
		creature.call("set_level", int(entry.level), PROGRESSION.config())
	if entry.has("nickname"):
		PARTY_SEAM.set_nickname(creature, str(entry.nickname))
	if not bool((_game.get("party") as RefCounted).call("add", creature)):
		_die("Party.add refused '%s' (the party holds five at most)" % species)
		return false
	return true


func _die(message: String) -> void:
	push_error("build_proof_save: " + message)
	print("BUILD_PROOF_SAVE_FAILED " + message)
	quit(1)
