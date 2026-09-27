extends SceneTree

## DRY RUN — fixture start, does not count.
## Whole-chapter Tidewake dry run: find every route blocker before the counting
## run from the earned handoff. The ONLY fixture is the declared start: a
## disclosed Stormwood->Water handoff state (gate flags, consumed key, a
## five-creature L44 belt, knife/axe). The Water world is then built at its
## production arrival. From there, every beat is an existing segment helper
## driven by controller input: no pose, flag, ledger, HP or inventory writes.
## After every segment: production Game.save_game, the world is destroyed,
## Game is reset, then Game.load_game and a fresh Water scene (the title
## Continue order). The save is copied to a checkpoint, so --from=<name>
## resumes from the save just before a failing step while debugging.
##
##   godot --headless --path . --script tests/smoke_tidewake_dry_run.gd -- \
##     [--from=<checkpoint>] [--through=<checkpoint>] [--out=<dir>]
##
## Checkpoints, in order: start, pell, reedhaven, brine, shellwatch, tidal.
## Each segment prints "TIDEWAKE DRY RUN SEGMENT <name> {result}". The run ends
## with "TIDEWAKE DRY RUN {summary}". The summary is also written to <out>/summary.json.
const WORLD := preload("res://scenes/world/water_archipelago.tscn")
const SAVE := preload("res://scripts/save/save_game.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const WATER_OPENING := preload("res://tests/helpers/water_earned_opening_segment.gd")
const REEDHAVEN := preload("res://tests/helpers/water_reedhaven_segment.gd")
const BRINE := preload("res://tests/helpers/water_brine_segment.gd")
const SHELLWATCH := preload("res://tests/helpers/water_shellwatch_segment.gd")
const TIDAL := preload("res://tests/helpers/water_tidal_segment.gd")
const LABEL := "DRY RUN — fixture start, does not count"
const SLOT := 1
## Same disclosed belt the opening diagnostic carries through Brine (L44).
const PARTY: Array[String] = ["sparkit", "mudsnout", "bramblebun", "terrapup", "brooktail"]
const PARTY_LEVEL := 44
## The handoff facts the earned Waterward segment leaves behind.
const HANDOFF_WORLD_FLAGS: Array[String] = ["realm_gate_water_unlocked", "stormwood:waterward_revealed"]
const CHECKPOINTS: Array[String] = ["start", "pell", "reedhaven", "brine", "shellwatch", "tidal"]

var game: Node
var world: Node3D
var out_dir := "user://tidewake_dry_run"
var run_dir := ""
var summary := {"label": LABEL, "segments": [], "blocker": "", "reached": "", "passed": false,
	"fixture": "declared start only: gate flags %s, key consumed, belt %s at L%d, knife/axe" % [
		str(HANDOFF_WORLD_FLAGS), str(PARTY), PARTY_LEVEL]}
var _started_ms := 0


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	_started_ms = Time.get_ticks_msec()
	var from := "start"
	var through := CHECKPOINTS[-1]
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--from="): from = arg.trim_prefix("--from=")
		elif arg.begins_with("--through="): through = arg.trim_prefix("--through=")
		elif arg.begins_with("--out="): out_dir = arg.trim_prefix("--out=")
	if not CHECKPOINTS.has(from) or not CHECKPOINTS.has(through):
		_finish("unknown checkpoint (valid: %s)" % str(CHECKPOINTS))
		return
	print("TIDEWAKE DRY RUN: " + LABEL)
	await process_frame
	game = root.get_node("Game")
	run_dir = out_dir.path_join("run_%d" % Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(run_dir))
	if from == "start":
		if not await _fixture_start():
			return
	elif not await _resume(from):
		return
	summary.reached = from
	var index := CHECKPOINTS.find(from)
	while index < CHECKPOINTS.find(through):
		var next: String = CHECKPOINTS[index + 1]
		var outcome: Dictionary = await _segment(next)
		summary.segments.append(outcome)
		print("TIDEWAKE DRY RUN SEGMENT %s %s" % [next, JSON.stringify(outcome)])
		if not bool(outcome.get("passed", false)):
			_finish("%s: %s" % [next, str(outcome.get("failures", []))])
			return
		if not await _checkpoint(next):
			return
		summary.reached = next
		index += 1
	summary.passed = true
	_finish("")


## The declared fixture start. Nothing after this function writes state.
func _fixture_start() -> bool:
	game.save_system = SAVE.new(run_dir.path_join("live/"))
	game.reset_for_new_game()
	game.current_realm = "water"
	for flag: String in HANDOFF_WORLD_FLAGS:
		game.world.flags.set_flag(flag)
	for species_id: String in PARTY:
		var creature: RefCounted = SPECIES.spawn(species_id)
		if creature == null:
			_finish("fixture: cannot construct " + species_id)
			return false
		creature.set_level(PARTY_LEVEL, PROGRESSION.config())
		game.local.party.add(creature)
	if game.inventory.add("axe", 1) != 0 or game.inventory.add("knife", 1) != 0:
		_finish("fixture: cannot carry knife/axe")
		return false
	game.assign_hotbar(0, "axe")
	game.assign_hotbar(1, "knife")
	print("TIDEWAKE DRY RUN FIXTURE: " + str(summary.fixture))
	world = WORLD.instantiate()
	root.add_child(world)
	current_scene = world
	if not await _wait_built():
		_finish("fixture: Water world did not build")
		return false
	return await _checkpoint("start", false)


## Load a checkpoint written by an earlier run (its directory is copied into
## a fresh live save directory so the original stays untouched).
func _resume(name: String) -> bool:
	var source := _latest_checkpoint(name)
	if source.is_empty():
		_finish("no saved checkpoint %s under %s" % [name, out_dir])
		return false
	var live := run_dir.path_join("live/")
	_copy_dir(source, live)
	game.save_system = SAVE.new(live)
	game.reset_for_new_game()
	if not bool(game.load_game(SLOT)):
		_finish("resume: Game.load_game failed for " + source)
		return false
	world = WORLD.instantiate()
	root.add_child(world)
	current_scene = world
	if not await _wait_built():
		_finish("resume: Water world did not build")
		return false
	await _frames(30)
	print("TIDEWAKE DRY RUN RESUMED from %s (%s)" % [name, source])
	return true


func _segment(name: String) -> Dictionary:
	var started := Time.get_ticks_msec()
	var player: Node3D = world.get_node_or_null("Player")
	var rig: Node3D = world.get_node_or_null("CameraRig")
	var outcome := {"name": name, "passed": false, "failures": []}
	match name:
		"pell":
			var opening := WATER_OPENING.new()
			var result: Dictionary = await opening.run(self, world, game)
			outcome.passed = bool(result.get("passed", false))
			outcome.failures = result.get("failures", [])
		"reedhaven", "brine", "shellwatch", "tidal":
			var segment: RefCounted = {"reedhaven": REEDHAVEN, "brine": BRINE,
				"shellwatch": SHELLWATCH, "tidal": TIDAL}[name].new()
			segment.setup(self, world, player, rig)
			var completed: bool = await segment.run()
			var result: Dictionary = segment.result()
			outcome.passed = completed and bool(result.get("ok", false))
			outcome.failures = result.get("failures", [])
	outcome.seconds = snappedf((Time.get_ticks_msec() - started) / 1000.0, 0.1)
	outcome.player = _pose()
	return outcome


## Production save, destroy, reset, load, rebuild: the Continue order. Copies
## the saved slot to <run>/cp_<name>/ for --from.
func _checkpoint(name: String, reload := true) -> bool:
	if not bool(game.save_game(SLOT)):
		_finish("checkpoint %s: Game.save_game failed" % name)
		return false
	var live := str(game.save_system.slot_path(SLOT)).get_base_dir()
	_copy_dir(live, run_dir.path_join("cp_" + name))
	print("TIDEWAKE DRY RUN CHECKPOINT %s saved at %s" % [name, _pose()])
	if not reload:
		return true
	var before := _pose()
	var party_ids := _party_ids()
	current_scene = null
	world.queue_free()
	await process_frame
	await process_frame
	game.reset_for_new_game()
	game.save_system = SAVE.new(live + "/")
	if not bool(game.load_game(SLOT)):
		_finish("checkpoint %s: Game.load_game failed" % name)
		return false
	world = WORLD.instantiate()
	root.add_child(world)
	current_scene = world
	if not await _wait_built():
		_finish("checkpoint %s: Water world did not rebuild" % name)
		return false
	await _frames(30)
	var after := _pose()
	var moved := Vector3(before[0], before[1], before[2]).distance_to(Vector3(after[0], after[1], after[2]))
	print("TIDEWAKE DRY RUN RELOADED %s: pose drift %.2f m, party same=%s" % [name, moved, party_ids == _party_ids()])
	if moved > 2.0 or party_ids != _party_ids():
		_finish("checkpoint %s: reload did not restore pose/party (drift %.2f m)" % [name, moved])
		return false
	return true


func _wait_built() -> bool:
	for frame in 1800:
		await process_frame
		if world.shell_build_complete():
			return true
	return world.shell_build_complete()


func _pose() -> Array:
	var player: Node3D = world.get_node_or_null("Player") if is_instance_valid(world) else null
	if player == null:
		return [0.0, 0.0, 0.0]
	var at := player.global_position
	return [snappedf(at.x, 0.01), snappedf(at.y, 0.01), snappedf(at.z, 0.01)]


func _party_ids() -> Array:
	var ids: Array = []
	for member: RefCounted in game.local.party.members():
		var uid := str(member.get("uid")) if member.get("uid") != null else ""
		ids.append("%s:%s:%d" % [uid, str(member.species_id), int(member.level)])
	return ids


func _latest_checkpoint(name: String) -> String:
	var root_abs := ProjectSettings.globalize_path(out_dir)
	var best := ""
	var dir := DirAccess.open(root_abs)
	if dir == null:
		return ""
	var runs := dir.get_directories()
	runs.sort()
	for run: String in runs:
		var candidate := out_dir.path_join(run).path_join("cp_" + name)
		if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(candidate)):
			best = candidate
	return best


static func _copy_dir(from: String, to: String) -> void:
	var src := ProjectSettings.globalize_path(from)
	var dst := ProjectSettings.globalize_path(to)
	DirAccess.make_dir_recursive_absolute(dst)
	var dir := DirAccess.open(src)
	if dir == null:
		return
	for file: String in dir.get_files():
		DirAccess.copy_absolute(src.path_join(file), dst.path_join(file))
	for sub: String in dir.get_directories():
		_copy_dir(from.path_join(sub), to.path_join(sub))


func _frames(count: int) -> void:
	for frame in count:
		await physics_frame


func _finish(blocker: String) -> void:
	summary.blocker = blocker
	summary.minutes = snappedf((Time.get_ticks_msec() - _started_ms) / 60000.0, 0.1)
	summary.final_pose = _pose() if is_instance_valid(world) else []
	print("TIDEWAKE DRY RUN " + JSON.stringify(summary))
	var file := FileAccess.open(run_dir.path_join("summary.json"), FileAccess.WRITE) if not run_dir.is_empty() else null
	if file != null:
		file.store_string(JSON.stringify(summary, "  "))
	quit(0 if blocker.is_empty() else 1)
