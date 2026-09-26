extends SceneTree
## Temporary probe (not committed): time the title Load Game path on the
## committed proof save. Mirrors title_screen._load_slot -> Game.load_game ->
## _enter_world (change to the world scene), logging every slow frame after.
const STEPS := preload("res://tools/net/proof_steps.gd")
var _last := 0
var _events: Array = []

func _on_added(n: Node) -> void:
	_events.append([Time.get_ticks_msec(), str(n.get_path())])

func _init() -> void:
	_run.call_deferred()

func _t() -> float:
	return Time.get_ticks_msec() / 1000.0

func _run() -> void:
	await process_frame
	var t0 := _t()
	var copied: Dictionary = await STEPS._load_save(self, {"from": "tools/net/proof_saves/host_meadows_stormwood_route_open", "copy_only": true})
	print("PROBE load_save step: %s (%.2fs)" % [str(copied.get("verdict")), _t() - t0])
	var game := root.get_node("Game")
	var t1 := _t()
	var ok := bool(game.call("load_game", 0))
	print("PROBE Game.load_game(0) -> %s in %.2fs; realm=%s pose=%s" % [ok, _t() - t1, game.current_realm, str(game.saved_player_pose.get("position"))])
	var scene_path := str(game.call("current_realm_scene")) if game.has_method("current_realm_scene") else "res://scenes/world/meadows_playground.tscn"
	print("PROBE scene path: ", scene_path)
	var t2 := _t()
	_last = Time.get_ticks_msec()
	if scene_path == "": scene_path = "res://scenes/world/meadows_playground.tscn"
	node_added.connect(_on_added)
	if scene_path != "":
		change_scene_to_file(scene_path)
	var frames := 0
	var slow := []
	while frames < 900:
		await physics_frame
		frames += 1
		var now := Time.get_ticks_msec()
		var gap := now - _last
		_last = now
		if gap > 250:
			var player: Node3D = null
			if current_scene != null:
				player = current_scene.find_child("Player", true, false) as Node3D
			slow.append("frame %d gap %.2fs player=%s" % [frames, gap / 1000.0, str(player.global_position) if player != null else "-"])
	print("PROBE world frames after change: total %.2fs" % (_t() - t2))
	for s in slow:
		print("PROBE slow ", s)
	var gaps: Array = []
	for i in range(1, _events.size()):
		gaps.append([_events[i][0] - _events[i - 1][0], _events[i - 1][1], _events[i][1]])
	gaps.sort_custom(func(a, b): return a[0] > b[0])
	for g in gaps.slice(0, 15):
		print("PROBE gap %.2fs after %s -> before %s" % [g[0] / 1000.0, g[1], g[2]])
	print("PROBE last node added at +%.2fs; tail after it %.2fs" % [(_events[-1][0] - _events[0][0]) / 1000.0, (Time.get_ticks_msec() - _events[-1][0]) / 1000.0])
	quit(0)
