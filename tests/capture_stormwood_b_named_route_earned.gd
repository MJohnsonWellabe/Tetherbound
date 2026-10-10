extends "res://tests/smoke_four_biome_continuous.gd"

## F10#2 named fights from an EARNED save on the ordinary Stormwood route.
##
## The new-order run imports an earned `cloudreach_settled` F49 handoff and
## its complete hash-linked predecessor chain through production title Load.
## Ordinary Home Key, relic hang/Cancel and Stormwood portal input precede
## the unchanged named route. Old checkpoints require the explicit legacy
## diagnostic; neither this suffix nor that diagnostic proves a full campaign.
## The route retains two additions:
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
## after the Rootgate release, plus `stormwood_arrived` before the first fight
## (Hollows renders from that arrival). New-order saves retain autosave slot 0;
## the separate legacy single-fight loader currently expects slot 1. It must
## consume the recorded slot before it can render these new-order saves.
## `capture_stormwood_b_named_from_save.gd` loads a supported saved slot
## through the production title Load and renders that fight: a whole route is
## too slow to render in one process, a fight from its save is not.
## No teleport, flag, item, party, level or weather fixture is added by this
## file. New-order capture requires --handoff-from, never a generated input.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 \
##     --resolution 1280x720 --script res://tests/capture_stormwood_b_named_route_earned.gd \
##     -- --handoff-from=<actual F49 root>/cloudreach_settled \
##        --named-out=<new frames dir> --named-saves=<absent saves dir>
## Optional --compatibility-manifests=<reviewed exact-cut manifest list> uses
## the unchanged F49 importer when producer and consumer commits differ.

const NAMED_RECORDER := preload("res://tests/helpers/stormwood_b_named_fight_recorder.gd")
const NAMED_DETOURS := preload("res://tests/helpers/stormwood_b_named_detour_segment.gd")
const EARNED_HANDOFF := preload("res://tests/helpers/f49_disk_handoff.gd")
const PORTAL_TRAVEL := preload("res://tests/helpers/f20_portal_travel.gd")
const BIOME_ORDER := preload("res://scripts/data/biome_order.gd")
const NAMED_IDS := ["hollows_alpha", "capacitor_alpha", "crown_guardian",
	"old_rodfolk_hall_guardian", "blackwater_elder", "glass_field_alpha"]

var _named_recorder: Node = null
var _named_saves_dir := ""
var _earned_from := ""
var _earned_compatibility: Array[String] = []
var _earned_disk: RefCounted
var _earned_uids: Array[String] = []
var _earned_identity: Array = []
var _named_save_slot := CHECKPOINTS.CHECKPOINT_SLOT


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
		elif arg.begins_with("--handoff-from="):
			if not _earned_from.is_empty(): failures.append("Supply one earned --handoff-from")
			_earned_from = arg.trim_prefix("--handoff-from=")
		elif arg.begins_with("--compatibility-manifests="):
			if not _earned_compatibility.is_empty(): failures.append("Supply one reviewed compatibility manifest list")
			for path: String in arg.trim_prefix("--compatibility-manifests=").split(","):
				if path.strip_edges().is_empty(): failures.append("Compatibility manifest paths must be nonempty")
				_earned_compatibility.append(path)
	_named_recorder = NAMED_RECORDER.new(out, interval, gate)
	root.add_child.call_deferred(_named_recorder)
	super()


func _run() -> void:
	if OS.get_cmdline_user_args().has("--legacy-order-diagnostic"):
		if not _earned_from.is_empty() or not _earned_compatibility.is_empty():
			failures.append("Legacy diagnostics cannot import an F49 earned prefix")
			_named_stop(false)
			return
		await super._run()
		return
	started_ms = Time.get_ticks_msec()
	for arg: String in OS.get_cmdline_user_args():
		if not (arg.begins_with("--handoff-from=") or arg.begins_with("--compatibility-manifests=") \
			or arg.begins_with("--named-out=") or arg.begins_with("--named-saves=") \
			or arg.begins_with("--named-interval=") or arg == "--named-no-gate"):
			failures.append("New-order named route refuses legacy/setup or unknown option: " + arg)
	if _earned_from.is_empty() or _earned_from.trim_suffix("/").get_file() != "cloudreach_settled":
		failures.append("New-order named route requires --handoff-from=<earned F49 root>/cloudreach_settled")
	if BIOME_ORDER.runtime_ids() != ["meadows", "water", "cloudreach", "stormwood"]:
		failures.append("Named route requires the shipping new chapter order")
	if _named_saves_dir.is_empty(): _named_saves_dir = str(_named_recorder.get("out_dir")).path_join("saves")
	_named_saves_dir = ProjectSettings.globalize_path(_named_saves_dir).simplify_path().trim_suffix("/")
	if DirAccess.dir_exists_absolute(_named_saves_dir) or FileAccess.file_exists(_named_saves_dir):
		failures.append("Named save output must be absent; refusing overwrite")
	var game := root.get_node("Game")
	var config: Dictionary = game.session.call("config")
	for flag: String in ["redesign_portal_runtime_enabled", "redesign_boss_handoff_runtime_enabled", "redesign_ending_runtime_enabled"]:
		if config.get(flag) != true: failures.append("Named route requires the actual producer gate: " + flag)
	if not failures.is_empty():
		_named_stop(false)
		return
	scratch = "user://sw_b_named_route_%d_%d" % [OS.get_process_id(), started_ms]
	game.set("save_system", SAVE.new(scratch))
	_earned_disk = EARNED_HANDOFF.new(self, game, _named_saves_dir.path_join("earned_prefix"))
	if not _earned_disk.configure_compatibility(_earned_compatibility) \
		or _earned_disk.import_prefix(_earned_from, "earned") != "cloudreach_settled":
		failures.append_array(_earned_disk.failures)
		_named_stop(false)
		return
	var travel := PORTAL_TRAVEL.new(self, game)
	if not await _earned_disk.reload_boundary("cloudreach_settled", travel):
		failures.append_array(_earned_disk.failures)
		_named_stop(false)
		return
	for member: Dictionary in _earned_disk.snapshots.cloudreach_settled.state.party:
		_earned_uids.append(str(member.uid))
	_earned_identity = _named_identity(game)
	resume_boundary = "cloudreach_settled"
	resume_info = {"source": ProjectSettings.globalize_path(_earned_from), "boundary": resume_boundary,
		"journey_id": _earned_disk.journey_id, "producer_commit": _earned_disk.snapshots.cloudreach_settled.commit,
		"consumer_commit": _earned_disk.source_commit, "predecessors": _earned_disk.history.duplicate(true),
		"compatibility_transition": _earned_disk.compatibility_transition.duplicate(true),
		"retained_prefix": _earned_disk.base}
	_named_save_slot = _earned_disk.save_slot
	checkpoint_dir = _named_saves_dir
	if not _named_party_preserved(game) or not await travel.home_key() \
		or not await travel.hang_relic("cloudreach") or not await travel.enter("stormwood", "stormwood"):
		failures.append_array(travel.failures)
		if failures.is_empty(): failures.append("Earned Stormwood portal continuation did not retain its original five")
		_named_stop(false)
		return
	live = {"world": current_scene, "game": game, "player": current_scene.get_node("Player"),
		"rig": current_scene.get_node("CameraRig")}
	reached = "stormwood_arrived"
	if not _named_save(game, reached):
		_named_stop(false)
		return
	await _stage_stormwood_to_water(game)


func _named_identity(game: Node) -> Array:
	return [str(game.local.character_id), str(game.world.world_id),
		str(game.world.reward_delivery_namespace), int(game.world_seed)]

func _named_party_preserved(game: Node) -> bool:
	var uids: Array[String] = []
	for member: RefCounted in game.party.members(): uids.append(str(member.get("uid")))
	return uids.size() == 5 and uids == _earned_uids and game.pending_catch == null \
		and _named_identity(game) == _earned_identity


func _stage_stormwood_to_water(game: Node) -> bool:
	print("NAMED_ROUTE earned run: resumed_from=%s" % JSON.stringify(resume_info))
	var stormwood := STORMWOOD.Segment.new()
	if not _accepted(await stormwood.run(self, live["world"], game), "passed"):
		return _named_stop(false)
	reached = "stormwood_arch_recipe_earned"
	if not _named_save(game, "named_pre_capacitor"): return _named_stop(false)
	for entry: Array in [[CROWN, "stormwood_paid_crown", "named_pre_crown"],
			[ROOTGATE, "stormwood_rootgate_released", "named_pre_detours"]]:
		if not _accepted(await (entry[0] as GDScript).new().run(self, live["world"], game), "passed"):
			return _named_stop(false)
		reached = str(entry[1])
		if not str(entry[2]).is_empty():
			if not _named_save(game, str(entry[2])): return _named_stop(false)
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
			print("NAMED_ROUTE detour failure: %s" % str(line))
		if not _accepted(result, "passed"): return _named_stop(false)
	for frame in 600:
		if not bool(_named_recorder.call("is_recording")) and (_named_recorder.get("_pending") as Array).is_empty() \
			and _named_recorder.get("_saving") == false: break
		await process_frame
	if bool(_named_recorder.call("is_recording")) or not (_named_recorder.get("_pending") as Array).is_empty() \
		or _named_recorder.get("_saving") == true:
		failures.append("Named recorder did not finish its actual fight and queued captures")
	for id: String in NAMED_IDS:
		var recorded := false
		for row: Dictionary in _named_recorder.get("rows"):
			if str(row.id) == id and str(row.outcome) == "cleared": recorded = true
		if not recorded or not bool(game.progression.call("has", "stormwood:named:%s:cleared" % id)):
			failures.append("Named route did not record and earn the actual cleared fight: " + id)
	reached = "stormwood_named_fights_recorded"
	return _named_stop(failures.is_empty())


## An ordinary production save at a quiet moment on the earned route,
## exported with the four-biome receipt format (commit, party uids, every flag,
## the earned checkpoint it descends from). A refused save is reported, never
## papered over.
func _named_save(game: Node, label: String) -> bool:
	if bool(_named_recorder.call("is_recording")):
		failures.append("NAMED_ROUTE SAVE %s refused: a fight is in progress" % label)
		return false
	if _earned_disk != null and not _named_party_preserved(game):
		failures.append("NAMED_ROUTE SAVE %s lost its original five or character/world identity" % label)
		return false
	if not bool(game.call("save_game", _named_save_slot)):
		failures.append("NAMED_ROUTE SAVE %s REFUSED by Game.save_game" % label)
		return false
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
	var source := str(game.save_system.get("_dir")) if _earned_disk != null else scratch
	if _earned_disk != null:
		receipt["slot"] = _named_save_slot
		receipt["character_id"] = str(game.local.character_id)
		receipt["world_id"] = str(game.world.world_id)
		receipt["journey_id"] = _earned_disk.journey_id
		receipt["files_sha256"] = _earned_disk._hash_tree(ProjectSettings.globalize_path(source))
		if receipt.files_sha256.is_empty() or DirAccess.dir_exists_absolute(dir.path_join(label)):
			failures.append("Named checkpoint is unreadable or already exists: " + label)
			return false
	var out := CHECKPOINTS.export_checkpoint(source, dir, label, label, receipt, carried_receipts)
	print("NAMED_ROUTE SAVE %s %s" % [label, "-> " + ProjectSettings.globalize_path(out) if not out.is_empty() else "EXPORT FAILED"])
	if out.is_empty():
		failures.append("Named checkpoint export failed: " + label)
		return false
	if _earned_disk != null:
		if _earned_disk._hash_tree(ProjectSettings.globalize_path(source)) != receipt.files_sha256 \
			or _earned_disk._hash_tree(ProjectSettings.globalize_path(out.path_join("save"))) != receipt.files_sha256:
			failures.append("Named checkpoint copy changed actual split-save bytes: " + label)
			return false
		var readme := FileAccess.open(out.path_join("README.txt"), FileAccess.WRITE)
		if readme == null:
			failures.append("Named checkpoint could not disclose its actual saved slot: " + label)
			return false
		readme.store_string("Earned new-order Stormwood named-route checkpoint '%s'; production autosave slot %d.\n" % [label, _named_save_slot]
			+ "The complete original F49 prefix is retained at " + _earned_disk.base + ".\n"
			+ "Its source, predecessor receipt hashes and reviewed cut are recorded in receipts/" + label + ".json.\n"
			+ "This suffix is not an uninterrupted full-campaign proof.\n")
		readme.close()
	return true


func _named_stop(passed: bool) -> bool:
	for row: Dictionary in _named_recorder.get("rows"):
		print("NAMED_ROUTE SUMMARY %s attempt=%d outcome=%s seconds=%s tells=%s hits=%d frames=%d party=%s" % [
			str(row.id), int(row.attempt), str(row.outcome), str(row.get("seconds", "?")),
			JSON.stringify(row.tells), (row.hits as Array).size(), (row.frames as Array).size(),
			str(row.party)])
	_finish(passed)
	return false
