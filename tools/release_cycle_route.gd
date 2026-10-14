extends "res://tools/catalogue_survey.gd"

## ACCEPTANCE §7 release reliability, run inside the real exported game through
## the title's private `--release-cycle` entry (f26_export_bootstrap.gd), or in
## the editor with --script. Proven in pieces (WORKFLOW §8.1 rule 9):
##   --piece=save   N save/mutate/load round trips on the production Meadows
##                  world; each load must restore exactly the saved snapshot.
##                  Then a corrupt, a newer-version and a v27 slot must refuse
##                  and leave live state untouched (RD-35 message for v27).
##   --piece=realm  N realm transitions Meadows <-> Cloudreach through
##                  Game.enter_realm (bypass_gate: a disclosed fixture), each
##                  landing ready in its target realm; per-crossing times.
## Fixtures, disclosed: the opening beats are pre-set (no Grandpa modal), the
## session is a host of one (as the title hosts), saves go to an isolated slot.
const SAVE_SLOT := 1
## The refusal cases rewrite the SAME slot's file (a world is bound to one
## slot) and restore its original bytes afterwards.
const BAD_SLOT := SAVE_SLOT
const MEADOWS_OPENING_FLAGS := [
	"opening:beat:wake", "opening:beat:house", "opening:beat:choose",
	"opening:starter_granted", "opening:beat:name", "opening:beat:return_starter",
	"opening:beat:walk_out",
]
var _piece := "save"
var _cycles := 10


func _prepare_character_fixture(game: Node) -> void:
	for flag: String in MEADOWS_OPENING_FLAGS:
		game.get("progression").call("set_flag", flag)


func _run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--piece="):
			_piece = arg.trim_prefix("--piece=")
		elif arg.begins_with("--cycles="):
			_cycles = maxi(1, int(arg.trim_prefix("--cycles=")))
	_biome_id = "meadows"
	print("RELEASE CYCLE begin piece=%s cycles=%d exported=%s" % [_piece, _cycles, str(OS.has_feature("template"))])
	if not await _mount_production_world():
		_release_finish()
		return
	var game := root.get_node(^"Game")
	var session: Node = game.get("session")
	if session != null and session.call("is_active") != true:
		session.call("host", -1)
	if _piece == "save":
		await _save_cycles(game)
	elif _piece == "realm":
		await _realm_cycles(game)
	else:
		_failures.append("unknown piece " + _piece)
	_release_finish()


func _release_finish() -> void:
	for failure: String in _failures:
		print("RELEASE CYCLE FAIL: " + failure)
	print("RELEASE CYCLE %s piece=%s" % ["PASS" if _failures.is_empty() else "FAIL", _piece])
	quit(0 if _failures.is_empty() else 1)


func _snapshot(game: Node) -> String:
	return JSON.stringify(game.get("save_system").call("snapshot", game), "", true)


func _save_cycles(game: Node) -> void:
	var saver: Object = game.get("save_system")
	# Disclosed warm-up: the fixture pre-sets the opening beats without the
	# opening's Home Key gift, so the first load's legacy Home Key reconcile
	# grants and binds it (a real character already holds it). One unmeasured
	# save/load and a settle bring the fixture to that steady state.
	if not bool(game.call("save_game", SAVE_SLOT)) or not bool(game.call("load_game", SAVE_SLOT)):
		_failures.append("warm-up save/load refused")
		return
	for _frame in 120:
		await physics_frame
	for cycle in _cycles:
		var started := Time.get_ticks_msec()
		if not bool(game.call("save_game", SAVE_SLOT)):
			_failures.append("cycle %d: save_game refused" % cycle)
			return
		var save_ms := Time.get_ticks_msec() - started
		var saved := _snapshot(game)
		# Change live state the load must undo: a bag stack.
		game.get("local").get("inventory").call("add", "stone", 3)
		if _snapshot(game) == saved:
			_failures.append("cycle %d: the probe mutation did not change state" % cycle)
			return
		started = Time.get_ticks_msec()
		if not bool(game.call("load_game", SAVE_SLOT)):
			_failures.append("cycle %d: load_game refused (%s)" % [cycle, str(saver.get("last_load_result"))])
			return
		var load_ms := Time.get_ticks_msec() - started
		var loaded := _snapshot(game)
		if loaded != saved:
			_failures.append("cycle %d: the load did not restore the saved snapshot (%d vs %d bytes)" % [cycle, loaded.length(), saved.length()])
			_note_difference(saved, loaded)
			return
		print("RELEASE CYCLE save %d/%d ok save_ms=%d load_ms=%d snapshot_sha=%s" % [
			cycle + 1, _cycles, save_ms, load_ms, saved.sha256_text().left(12)])
		for _frame in 10:
			await physics_frame
	_refusals(game, saver)


func _refusals(game: Node, saver: Object) -> void:
	if not bool(game.call("save_game", BAD_SLOT)):
		_failures.append("could not write the slot the refusal cases start from")
		return
	var path: String = saver.call("slot_path", BAD_SLOT)
	var original := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(original)
	if not parsed is Dictionary:
		_failures.append("slot %d is not a JSON object (%s)" % [BAD_SLOT, path])
		return
	# v27 is the real archived fixture (RD-35 reset); "newer" is that fixture
	# stamped one version past this build. Each must refuse with its own code.
	var v27_text := FileAccess.get_file_as_string("res://data/schema/fixtures/v27_save.json")
	var v27: Variant = JSON.parse_string(v27_text)
	if not v27 is Dictionary:
		_failures.append("the v27 fixture is missing")
		return
	var cases := {
		"corrupt": original.left(original.length() / 2),
		"newer": JSON.stringify(_with_version(v27, int(saver.get("VERSION")) + 1)),
		"v27": v27_text,
	}
	var expected_codes := {"corrupt": "unreadable_save", "newer": "incompatible_future_version",
		"v27": "incompatible_old_version"}
	var live := _snapshot(game)
	for name: String in cases:
		var file := FileAccess.open(path, FileAccess.WRITE)
		file.store_string(cases[name])
		file.close()
		var accepted := bool(game.call("load_game", BAD_SLOT))
		var result: Variant = saver.get("last_load_result")
		if accepted:
			_failures.append("%s save was accepted" % name)
		elif not result is Dictionary or result.get("code") != expected_codes[name]:
			_failures.append("%s save refused with %s, wanted %s" % [name, str(result), expected_codes[name]])
		elif _snapshot(game) != live:
			_failures.append("%s save changed live state while refusing" % name)
		else:
			print("RELEASE CYCLE refusal %s ok: %s" % [name, str(result)])
	var restore := FileAccess.open(path, FileAccess.WRITE)
	restore.store_string(original)
	restore.close()


static func _with_version(data: Dictionary, version: int) -> Dictionary:
	var copy := data.duplicate(true)
	copy["version"] = version
	return copy


func _note_difference(left: String, right: String) -> void:
	var a: Variant = JSON.parse_string(left)
	var b: Variant = JSON.parse_string(right)
	if a is Dictionary and b is Dictionary:
		for key: Variant in a:
			if JSON.stringify(a[key]) != JSON.stringify(b.get(key)):
				print("RELEASE CYCLE diff key=%s saved=%s loaded=%s" % [str(key), JSON.stringify(a[key]).left(400), JSON.stringify(b.get(key)).left(400)])


func _realm_cycles(game: Node) -> void:
	for cycle in _cycles:
		var target := "cloudreach" if str(game.get("current_realm")) == "meadows" else "meadows"
		var started := Time.get_ticks_msec()
		var ok: bool = await game.call("enter_realm", target, "", true)
		var ms := Time.get_ticks_msec() - started
		var scene := current_scene
		var ready := scene != null and (not scene.has_method("shell_build_complete") or bool(scene.call("shell_build_complete")))
		if not ok or str(game.get("current_realm")) != target or not ready:
			_failures.append("transition %d to %s failed (ok=%s realm=%s ready=%s, %d ms)" % [
				cycle + 1, target, str(ok), str(game.get("current_realm")), str(ready), ms])
			return
		print("RELEASE CYCLE realm %d/%d -> %s ok ms=%d scene=%s" % [cycle + 1, _cycles, target, ms, str(scene.name)])
		for _frame in 30:
			await physics_frame
