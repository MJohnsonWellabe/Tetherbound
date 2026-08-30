extends SceneTree

## T5-CARE probe: where does the player actually spawn, per opening state?
##
##   godot --headless --path . --script tools/_probe_t5_spawn.gd
##   godot --headless --path . --script tools/_probe_t5_spawn.gd -- --free-play
##
## `tools/_play_t5_walk_build_route.gd` booted the real Meadows with
## `opening:beat:free_play` set -- the ordinary "the opening is over" state --
## and found the player standing at
##
##   (-6789674, 2686.5, 2137802)
##
## nearly seven million metres from the world origin. Everything downstream
## follows from that: terrain collision is built around the player, so with the
## player seven million metres away nothing near the village is resident, a
## trainer set down at the Village Square falls through the floor, and the
## world's own perimeter guard catches them at y=-133 and returns them to
## spawn. That is the whole of the Gate A build segment's failure.
##
## This isolates it: same scene, same frame budget, one flag different.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 300


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var free_play := "--free-play" in OS.get_cmdline_user_args()
	var game := root.get_node_or_null(^"Game")
	if free_play:
		game.get("progression").call("set_flag", "opening:beat:free_play")
	var world := (load(SCENE) as PackedScene).instantiate() as Node3D
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await physics_frame
	var player := world.get_node_or_null(^"Player") as Node3D
	print("")
	print("=== T5 spawn probe (opening:beat:free_play = %s) ===" % str(free_play))
	if player == null:
		print("  no Player in the world")
		quit(1)
		return
	var p := player.global_position
	print("  player at (%.1f, %.2f, %.1f)" % [p.x, p.y, p.z])
	var sane := absf(p.x) < 5000.0 and absf(p.z) < 5000.0 and absf(p.y) < 500.0
	print("  within a sane Meadows coordinate range: %s" % str(sane))
	if not sane:
		print("  VERDICT: FAIL — the player spawns outside the world. Terrain collision "
			+ "is built around the player, so nothing in the Meadows is resident and the "
			+ "chapter cannot be walked from here.")
	else:
		print("  ground_height_at under the player: %.2f" % float(world.call("ground_height_at", p.x, p.z)))
	quit(0)
