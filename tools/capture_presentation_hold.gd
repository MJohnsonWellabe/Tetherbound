extends SceneTree

## X03 / F05 heal evidence: the world HUD during the Meadows heal payoff, with
## and without a presentation hold, through the PRODUCTION player camera rig,
## HUD on. Adapted from the finale lane's own `capture_heal.gd` (branch
## ralph/f05-land-heals, ralph/reports/MEADOWS-FINALE/heal/).
##
##   flock /tmp/claude-0/godot-render.lock xvfb-run -a -s "-screen 0 1280x720x24" \
##     godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/capture_presentation_hold.gd -- <out_dir>
##
## Disclosed staging, as in capture_heal.gd: the main chain up to the Warden is
## set directly, then `legendary_freed` is set directly (the lever is not
## pulled), which leaves "Settle who walks with you" open exactly as in the
## judge's frames; the player is placed at each vantage and the rig's yaw set
## behind them; the day clock is held at 13:00. The hold is a plain node this
## tool adds to presentation_hold.gd's GROUP, standing in for the heal
## payoff's own node (the finale lane joins it while its payoff plays).

const SCENE := "res://scenes/world/meadows_playground.tscn"
const PRESENTATION_HOLD := preload("res://scripts/ui/presentation_hold.gd")
const SETTLE := 120
const SHOT_FRAMES := 24
const HOLD_CLOCK_S := 325.0
const APPROACH_AT := Vector2(-24.0, 7478.0)
const APPROACH_LOOK := Vector3(-8.0, 0.0, 7505.0)
const WORKS_AT := Vector2(-14.0, 7518.0)
const WORKS_LOOK := Vector3(0.0, 0.0, 7560.0)

var _out := "user://presentation_hold_shots"
var _world: Node3D
var _game: Node
var _player: CharacterBody3D
var _rig: Node3D
var _look: Node = null


func _process(_delta: float) -> bool:
	if _look != null and is_instance_valid(_look):
		_look.set("_elapsed_seconds", HOLD_CLOCK_S)
	return false


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_out = args[0]
	DirAccess.make_dir_recursive_absolute(_out)
	await process_frame
	RenderingServer.render_loop_enabled = false
	_game = root.get_node(^"Game")
	var party: RefCounted = _game.get("party")
	party.call("clear")
	for species: String in ["terrapup", "mudsnout", "bramblebun", "brooktail"]:
		party.call("add", _game.call("make_creature", species, species.capitalize()))
	var chain: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/progression/objectives.json"))
	for entry: Dictionary in chain.get("main", []):
		var id := str(entry.get("flag_id", ""))
		if id == "legendary_freed":
			break
		_game.get("progression").call("set_flag", id)
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	current_scene = _world
	for i in SETTLE:
		await process_frame
	_player = _world.get_node(^"Player") as CharacterBody3D
	_rig = get_first_node_in_group("camera_rig") as Node3D
	for node: Node in _world.find_children("*", "", true, false):
		if node.has_method("elapsed_seconds") and "_elapsed_seconds" in node:
			_look = node
			break
	_game.get("progression").call("set_flag", "legendary_freed")
	for i in 60:
		await process_frame

	for pair: Array in [["approach", APPROACH_AT, APPROACH_LOOK], ["works", WORKS_AT, WORKS_LOOK]]:
		await _shot("%s-no-hold" % pair[0], pair[1], pair[2])
		var payoff := Node.new()
		payoff.name = "HealPayoffStandIn"
		_world.add_child(payoff)
		payoff.add_to_group(PRESENTATION_HOLD.GROUP)
		await _shot("%s-payoff-hold" % pair[0], pair[1], pair[2])
		payoff.queue_free()
		for i in 4:
			await process_frame
	print("done: %s" % ProjectSettings.globalize_path(_out))
	quit(0)


func _shot(name: String, flat: Vector2, target: Vector3) -> void:
	var y := float(_world.call("ground_height_at", flat.x, flat.y))
	var t := target
	if t.y == 0.0:
		t.y = float(_world.call("ground_height_at", t.x, t.z))
	var at := Vector3(flat.x, y, flat.y)
	_player.global_position = at + Vector3(0.0, 0.3, 0.0)
	_player.velocity = Vector3.ZERO
	var dir := t - at
	dir.y = 0.0
	if dir.length() > 0.01:
		_player.rotation.y = atan2(dir.x, dir.z)
		if _rig != null:
			_rig.set("yaw", wrapf(atan2(-dir.x, -dir.z), -PI, PI))
			_rig.set("pitch", deg_to_rad(-8.0))
	for i in SHOT_FRAMES:
		await process_frame
	var path := "%s/%s.png" % [_out, name]
	RenderingServer.force_draw(false)
	root.get_texture().get_image().save_png(path)
	print("shot -> %s" % path)
