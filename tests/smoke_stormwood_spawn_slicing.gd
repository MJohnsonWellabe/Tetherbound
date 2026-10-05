extends SceneTree

## A host standing up a Stormwood realm shell must keep producing frames.
##
##   godot --headless --path . --script tests/smoke_stormwood_spawn_slicing.gd
##
## CI's two-peer smokes (smoke_net_water_return, smoke_net_stormwood_realms)
## lost a peer to the 15 s heartbeat when Stormwood's 808 wild creatures
## spawned in one frame after the sliced world build (measured 9.4 s on a 4-core
## container). encounter_director.gd now yields every `wild_spawn_slice_ms` of
## spawning. This asserts:
## - the longest main-thread gap of the whole shell boot stays under
##   MAX_GAP_MSEC;
## - every wild still spawns, with its deterministic authored name
##   (Wild_<species>_<order>_<n>, or Named_<id> for the realm's named
##   residents, all unique), so wild identity, and with it
##   host authority over which wilds exist, is unchanged by the slicing;
## - while the sliced build runs, the director carries the population-build
##   marker that holds back a foundation alpha publish (which would otherwise
##   spawn a retained alpha the build is about to spawn itself), and the
##   marker is gone once the population is ready.

const SCENE := "res://scenes/world/stormwood.tscn"
## The co-op heartbeat window is 15 s; the target is a single gap far under it.
const MAX_GAP_MSEC := 2000
const BOOT_LIMIT_MSEC := 240000

var _failures: Array[String] = []


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var game := root.get_node_or_null(^"Game")
	if game == null:
		_finish(["Game autoload missing"])
		return
	game.call("reset_for_new_game")
	game.set("current_realm", "stormwood")
	var started := Time.get_ticks_msec()
	var world := (load(SCENE) as PackedScene).instantiate()
	# The host realm-shell path: the same world, built for simulation only.
	world.set("simulation_only", true)
	root.add_child(world)
	var worst := 0
	var previous := Time.get_ticks_msec()
	var director: Node = null
	var marked_while_slicing := false
	while true:
		await process_frame
		var now := Time.get_ticks_msec()
		worst = maxi(worst, now - previous)
		previous = now
		if director == null:
			director = world.get_node_or_null(^"EncounterDirector")
		if director != null and director.get("population_ready") == true:
			break
		if director != null and director.has_meta(&"wild_population_spawning"):
			marked_while_slicing = true
		if now - started > BOOT_LIMIT_MSEC:
			_failures.append("population never became ready within %d ms" % BOOT_LIMIT_MSEC)
			break
	print("stormwood spawn slicing: worst main-thread gap %d ms over a %d ms shell boot" % [
		worst, Time.get_ticks_msec() - started])
	if worst > MAX_GAP_MSEC:
		_failures.append("longest main-thread gap %d ms exceeds %d ms" % [worst, MAX_GAP_MSEC])
	if director != null:
		if not marked_while_slicing:
			_failures.append("the sliced population build never carried its spawning marker")
		if director.has_meta(&"wild_population_spawning"):
			_failures.append("the spawning marker outlived the population build")
		var wilds: Array = director.get("_wild_creatures")
		var names := {}
		var pattern := RegEx.new()
		pattern.compile("^(Wild_[a-z0-9_]+_\\d+_\\d+|Named_[a-z0-9_]+)$")
		for wild: Variant in wilds:
			if not is_instance_valid(wild):
				continue
			var wild_name := str((wild as Node).name)
			if pattern.search(wild_name) == null:
				_failures.append("wild %s lost its authored name" % wild_name)
			names[wild_name] = true
		if wilds.size() < 800:
			_failures.append("only %d wilds spawned" % wilds.size())
		if names.size() != wilds.size():
			_failures.append("%d wild names are not unique" % (wilds.size() - names.size()))
		print("stormwood spawn slicing: %d wilds, %d unique names" % [wilds.size(), names.size()])
	_finish(_failures)


func _finish(failures: Array) -> void:
	if failures.is_empty():
		print("stormwood spawn slicing: OK")
		quit(0)
		return
	for failure: Variant in failures:
		push_error("stormwood spawn slicing: %s" % str(failure))
	print("stormwood spawn slicing: FAILED")
	quit(1)
