extends SceneTree

## Targeted wrapper for tests/helpers/gate_a_build_segment.gd.
##
## This is explicitly a fixture, not Gate A's canonical continuous session. It
## provisions the state that the reusable segment deliberately refuses to
## manufacture: progressed opening, a clear real-Meadows start patch, and paid
## materials. From the first build_open press onward, the helper changes the
## game only with parsed physical joypad events.

const SCENE := preload("res://scenes/world/meadows_playground.tscn")
const SEGMENT := preload("res://tests/helpers/gate_a_build_segment.gd")
const SETTLE_FRAMES := 300
## Wrapper-only fixture entry. The reusable segment then walks the documented
## Village Square -> Practice Meadow road by parsed controller input.
const ROUTE_ENTRY_XZ := Vector2(10.0, -10.0)


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := root.get_node_or_null(^"Game")
	if game == null:
		print("GATE A BUILD MEADOWS SEGMENT: FAIL — Game autoload missing")
		quit(1)
		return
	_fixture_state(game)

	var world := SCENE.instantiate() as Node3D
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await physics_frame
	var player := world.get_node_or_null(^"Player") as CharacterBody3D
	var rig := world.get_node_or_null(^"CameraRig") as Node3D
	if player == null or rig == null:
		print("GATE A BUILD MEADOWS SEGMENT: FAIL — real world player/camera missing")
		quit(1)
		return

	# Wrapper-only fixture placement, before the reusable player-action segment.
	# This is not canonical positioning: the real chain reaches Village Square
	# by ordinary exploration, then the helper walks the authored road. Ask the
	# same live world height source the placer uses.
	var ground := float(world.call("ground_height_at", ROUTE_ENTRY_XZ.x, ROUTE_ENTRY_XZ.y))
	player.global_position = Vector3(ROUTE_ENTRY_XZ.x, ground + 1.0, ROUTE_ENTRY_XZ.y)
	player.velocity = Vector3.ZERO
	for i in 60:
		await physics_frame

	var segment := SEGMENT.new()
	var result: Dictionary = await segment.run(self, world, player, rig)
	for line in result.get("transcript", []):
		print("  ok    %s" % line)
	if bool(result.get("passed", false)):
		print("GATE A BUILD MEADOWS SEGMENT: PASS")
		quit(0)
		return
	for failure in result.get("failures", []):
		print("  FAIL  %s" % failure)
	print("GATE A BUILD MEADOWS SEGMENT: FAIL")
	quit(1)


func _fixture_state(game: Node) -> void:
	game.set("free_build", false)
	game.set("pending_build", "")
	game.set("placed_buildings", [])
	game.get("progression").call("set_flag", "opening:beat:free_play")
	var inventory: RefCounted = game.get("inventory")
	# Deliberate targeted-test fixture. The reusable segment itself never grants
	# resources and checks the exact paid delta against these ordinary stacks.
	inventory.call("add", "wood", 60)
	inventory.call("add", "stone", 60)
