extends SceneTree

## One real simulation shell per invocation. Checks authored support/mounts;
## direct realm fixture start is disclosed and cannot close the earned loop.
const MOUNTS := preload("res://scripts/net/waystone_mounts.gd")
const STONES := preload("res://scripts/world/waystone.gd")
const SCENES := {"meadows": "res://scenes/world/meadows_playground.tscn",
	"water": "res://scenes/world/water_archipelago.tscn",
	"cloudreach": "res://scenes/world/cloudreach_cliffs.tscn",
	"stormwood": "res://scenes/world/stormwood.tscn"}
var failures: Array[String] = []

func _initialize() -> void:
	_run.call_deferred()

func _check(ok: bool, label: String) -> void:
	if not ok: failures.append(label)

func _run() -> void:
	var realm := ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--realm="): realm = arg.trim_prefix("--realm=")
	if not SCENES.has(realm):
		print("F18 authored stones requires one --realm=meadows|water|cloudreach|stormwood")
		quit(1)
		return
	var game: Node = root.get_node(^"Game")
	game.set("current_realm", realm)
	var world: Node3D = (load(SCENES[realm]) as PackedScene).instantiate()
	world.set("simulation_only", true)
	root.add_child(world)
	current_scene = world
	var deadline := Time.get_ticks_msec() + 180000
	while not world.call("shell_build_complete") and Time.get_ticks_msec() < deadline:
		await process_frame
	_check(world.call("shell_build_complete") == true, "actual shell ready")
	_check(MOUNTS.mount(world, realm), "production collection mounted")
	var rows: Array = []
	for row: Dictionary in STONES.load_config().waystones:
		if row.realm_id != realm: continue
		var at := STONES.resolve_position(world, row)
		var arrival := STONES.resolve_position(world, row, true)
		_check(at.is_finite(), row.id + " shrine dry supported footprint")
		_check(arrival.is_finite(), row.id + " arrival dry supported footprint")
		var node := world.get_node_or_null("Waystones/" + str(row.id)) as Node3D
		_check(node != null, row.id + " mounted")
		if node != null and at.is_finite():
			_check(node.global_position.distance_to(at) < 0.01, row.id + " canonical mounted position")
		rows.append({"id": row.id, "position": str(at), "arrival": str(arrival)})
	_check(rows.size() >= 3 and rows.size() <= 5, "three to five authored stones")
	print("F18_AUTHORED_STONES " + JSON.stringify({"realm": realm, "stones": rows,
		"failures": failures, "simulation_shell": true, "earned_play": false}))
	current_scene = null
	world.queue_free()
	await process_frame
	await process_frame
	quit(0 if failures.is_empty() else 1)
