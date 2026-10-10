extends "res://tools/earned_saves/earned_chain_runner.gd"

## Writes one committed generated boundary profile as an ordinary production
## save directory, for witnesses that load a `<dir>/save/` slot through the
## title (e.g. tests/smoke_cloudreach_continuous.gd --from-save=). The slot is
## the one the generated world's retained journal is bound to (0): saving a
## live world under another slot would rebind journal ownership, which
## save_game.gd refuses by design.
##
## The profile is applied by the runner's own disclosed generated-fixture
## path (`_generate_boundary_fixture`): the same template bytes, provenance
## check, production Load/Save validation and declared-carrier comparison.
## With `--enter=<arch>:<realm>` the generated boundary then plays the ordinary
## F49 portal leg (tests/helpers/f49_portal_travel.gd: Home Key, hang the held
## relic, walk through the arch) before publishing. The game is then saved once
## more with `Game.save_game(slot)` into `--out=<dir>/save`.
##
## USAGE
##   godot --headless --path . --script tools/earned_saves/generate_boundary_save.gd -- \
##     --profile=cloudreach --enter=cloudreach:cloudreach --slot=0 --out=<absent dir>
## Writes <out>/save/ and <out>/PROVENANCE.json; exit 0 on success.

const PORTAL := preload("res://tests/helpers/f49_portal_travel.gd")
var _out := ""
var _slot := 0
var _enter := ""


func _run() -> void:
	started_ms = Time.get_ticks_msec()
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--profile="):
			segment = arg.trim_prefix("--profile=")
		elif arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
		elif arg.begins_with("--enter="):
			_enter = arg.trim_prefix("--enter=")
		elif arg.begins_with("--slot="):
			_slot = int(arg.trim_prefix("--slot="))
		else:
			failures.append("Unknown generator option: " + arg)
	_out = ProjectSettings.globalize_path(_out).simplify_path().trim_suffix("/")
	if segment.is_empty() or _out.is_empty() or _slot < 0:
		failures.append("usage: --profile=<id> --slot=<n> --out=<absent dir>")
	elif DirAccess.dir_exists_absolute(_out) or FileAccess.file_exists(_out):
		failures.append("Generator output must be absent; refusing overwrite")
	if OS.has_environment("TB_WORLD_SEED"):
		failures.append("Generated boundaries keep the template's saved population; no seed override")
	game = root.get_node("Game")
	if not failures.is_empty():
		_finish()
		return
	# The runner derives its scratch roots from save_dir: <root>/<profile>/save.
	var scratch := _out + "_scratch"
	save_dir = scratch.path_join(segment + "/save")
	receipt_path = scratch.path_join(segment + "/receipt.json")
	generated_fixture = true
	game.set("save_system", SAVE.new(scratch + "_working"))
	if not await _generate_boundary_fixture():
		_finish()
		return
	var table: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(GENERATED_PROFILES))
	var profile: Dictionary = table.profiles[segment]
	var realm := str(profile.realm)
	if not _enter.is_empty():
		var parts := _enter.split(":")
		var held: Array = profile.get("character_fields", {}).get("relics_held", [])
		var travel := PORTAL.new(self, game)
		if parts.size() != 2 or held.size() != 1 or not await travel.home_key() \
				or not await travel.hang_relic(str(held[0])) or not await travel.enter(parts[0], parts[1]):
			failures.append("Ordinary portal leg failed: " + str(travel.failures))
			_finish()
			return
		realm = parts[1]
	game.set("save_system", SAVE.new(_out.path_join("save")))
	if not bool(game.call("save_game", _slot)):
		failures.append("Game.save_game(%d) refused the generated boundary" % _slot)
		_finish()
		return
	var info: Dictionary = game.call("save_slot_info", _slot)
	if str(info.get("realm", "")) != realm:
		failures.append("Published slot does not report the declared realm: " + str(info))
		_finish()
		return
	var provenance := {"kind": "generated_boundary_save", "profile": segment,
		"profile_sha256": FileAccess.get_sha256(GENERATED_PROFILES), "slot": _slot,
		"portal_leg": _enter, "source": CHECKPOINTS.commit_sha(), "prior_earned_play": false, "continuous_fresh_save": false,
		"disclosure": str(profile.get("disclosure", "")), "slot_info": info}
	var file := FileAccess.open(_out.path_join("PROVENANCE.json"), FileAccess.WRITE)
	if file == null:
		failures.append("Generator could not write provenance")
	else:
		file.store_string(JSON.stringify(provenance, "  ") + "\n")
		file.close()
	print("GENERATED BOUNDARY SAVE " + JSON.stringify({"profile": segment, "slot": _slot, "out": _out,
		"passed": failures.is_empty(), "info": info}))
	_finish()
