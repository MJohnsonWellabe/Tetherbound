extends "res://tests/smoke_four_biome_continuous.gd"

## F10#2 named fights from an EARNED save on the ordinary Stormwood route.
##
## The four-biome continuous run, resumed through the production Load path from
## an earned `stormwood_arrived` checkpoint (`--resume-from=<name>:stormwood_arrived`;
## the receipt must match or the run refuses), with two additions:
##   - the passive named-fight recorder on the tree root (tells, hits, outcome
##     and production-camera frames with a display); it never acts;
##   - the Stormwood stage runs the earned segments the chapter already uses
##     (arrival prefix -> Capacitor Alpha and the paid Crown arch -> Crown
##     guardian and Rootgate), then detours to
##     each named wild the route did not fight (`stormwood_b_named_detour_segment.gd`:
##     rest at a camp, walk the road, one Engage press, ordinary fight), then
##     stops. Marrow and later chapters are not needed for F10#2.
## It also writes three ordinary production saves (`--named-saves=<dir>`,
## default `<checkpoint-dir>/named`): `named_pre_capacitor` after the arrival
## prefix, `named_pre_crown` beside the paid Crown arch, `named_pre_detours`
## after the Rootgate release (Hollows renders from the earned `stormwood_arrived`
## checkpoint itself). `capture_stormwood_b_named_from_save.gd` loads one
## through the production title Load and renders that fight: a whole route is
## too slow to render in one process, a fight from its save is not.
## No teleport, flag, item, party, level or weather fixture is added by this
## file. A run started without `--resume-from` begins the fresh campaign
## (seed4-style) exactly like the base run.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 \
##     --resolution 1280x720 --script res://tests/capture_stormwood_b_named_route_earned.gd \
##     -- --resume-from=<checkpoint>:stormwood_arrived --checkpoint-dir=user://cps \
##        --named-out=res://shots/sw_b_named_route_earned

const NAMED_RECORDER := preload("res://tests/helpers/stormwood_b_named_fight_recorder.gd")
const NAMED_DETOURS := preload("res://tests/helpers/stormwood_b_named_detour_segment.gd")
const NAMED_IDS := ["hollows_alpha", "capacitor_alpha", "crown_guardian",
	"old_rodfolk_hall_guardian", "blackwater_elder", "glass_field_alpha"]

var _named_recorder: Node = null
var _named_saves_dir := ""


func _init() -> void:
	var out := "res://shots/sw_b_named_route_earned"
	var interval := 1.0
	var gate := not OS.get_cmdline_user_args().has("--named-no-gate")
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--named-out="):
			out = arg.trim_prefix("--named-out=")
		elif arg.begins_with("--named-interval="):
			interval = float(arg.trim_prefix("--named-interval="))
		elif arg.begins_with("--named-saves="):
			_named_saves_dir = arg.trim_prefix("--named-saves=")
	_named_recorder = NAMED_RECORDER.new(out, interval, gate)
	root.add_child.call_deferred(_named_recorder)
	super()


func _stage_stormwood_to_water(game: Node) -> bool:
	print("NAMED_ROUTE earned run: resumed_from=%s" % JSON.stringify(resume_info))
	var stormwood := STORMWOOD.Segment.new()
	if not _accepted(await stormwood.run(self, live["world"], game), "passed"):
		return _named_stop(false)
	reached = "stormwood_arch_recipe_earned"
	_named_save(game, "named_pre_capacitor")
	for entry: Array in [[CROWN, "stormwood_paid_crown", "named_pre_crown"],
			[ROOTGATE, "stormwood_rootgate_released", "named_pre_detours"]]:
		if not _accepted(await (entry[0] as GDScript).new().run(self, live["world"], game), "passed"):
			return _named_stop(false)
		reached = str(entry[1])
		if not str(entry[2]).is_empty():
			_named_save(game, str(entry[2]))
	var seen := {}
	for row: Dictionary in _named_recorder.get("rows"):
		seen[str(row.id)] = true
	var todo: Array = []
	for id: String in NAMED_IDS:
		if not seen.has(id):
			todo.append(id)
	print("NAMED_ROUTE route fought %s; detouring to %s" % [str(seen.keys()), str(todo)])
	if not todo.is_empty():
		var detours := NAMED_DETOURS.new()
		var result: Dictionary = await detours.run_named(self, live["world"], game, todo)
		print("NAMED_ROUTE detours %s" % JSON.stringify(result.get("outcomes", {})))
		for line: Variant in result.get("transcript", []):
			print("NAMED_ROUTE detour — %s" % str(line))
		for line: Variant in result.get("failures", []):
			print("NAMED_ROUTE detour note (not a route failure): %s" % str(line))
	reached = "stormwood_named_fights_recorded"
	return _named_stop(true)


## An ordinary production save at a quiet moment on the earned route,
## exported with the four-biome receipt format (commit, party uids, every flag,
## the earned checkpoint it descends from). A refused save is reported, never
## papered over.
func _named_save(game: Node, label: String) -> void:
	if bool(_named_recorder.call("is_recording")):
		print("NAMED_ROUTE SAVE %s skipped: a fight is in progress" % label)
		return
	if not bool(game.call("save_game", CHECKPOINTS.CHECKPOINT_SLOT)):
		print("NAMED_ROUTE SAVE %s REFUSED by Game.save_game" % label)
		return
	var player := current_scene.get_node_or_null("Player") as Node3D if current_scene != null else null
	var elapsed := (Time.get_ticks_msec() - started_ms) / 1000.0
	var receipt := CHECKPOINTS.build_receipt(label, {
		"commit": CHECKPOINTS.commit_sha(), "world_seed": int(game.get("world_seed")),
		"elapsed_seconds": elapsed, "cumulative_elapsed_seconds": prior_elapsed_seconds + elapsed,
		"realm": str(game.get("current_realm")),
		"player": [player.global_position.x, player.global_position.y, player.global_position.z] if player != null else [],
		"party": _party_rows(game.get("party")),
		"flags": (game.get("progression").call("all_set") as Array).duplicate(),
		"resumed_from": resume_info,
	})
	var dir := _named_saves_dir if not _named_saves_dir.is_empty() else checkpoint_dir.path_join("named")
	var out := CHECKPOINTS.export_checkpoint(scratch, dir, label, label, receipt, carried_receipts)
	print("NAMED_ROUTE SAVE %s %s" % [label, "-> " + ProjectSettings.globalize_path(out) if not out.is_empty() else "EXPORT FAILED"])


func _named_stop(passed: bool) -> bool:
	for row: Dictionary in _named_recorder.get("rows"):
		print("NAMED_ROUTE SUMMARY %s attempt=%d outcome=%s seconds=%s tells=%s hits=%d frames=%d party=%s" % [
			str(row.id), int(row.attempt), str(row.outcome), str(row.get("seconds", "?")),
			JSON.stringify(row.tells), (row.hits as Array).size(), (row.frames as Array).size(),
			str(row.party)])
	_finish(passed)
	return false
