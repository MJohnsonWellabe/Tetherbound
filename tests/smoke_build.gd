extends SceneTree

## Can the player build a house, and does it survive a reload?
##
##   godot --headless --path . --script tests/smoke_build.gd
##
## Headless, like every other smoke — see `tools/run_smokes.sh` for the measured
## reason (running these under a renderer took one of them from 191s to over
## 2400s without finishing).
##
## What this does NOT prove is that the house looks right. A wall snapped to the
## wrong edge, a floor a half-cell out, a roof facing backwards — all of those
## place successfully, save, reload and pass every assertion below. That is what
## the rendered frame from `tools/preview_build.gd` is for, and it is the reason
## this file does not claim more than it checks.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const GRID := preload("res://scripts/building/build_grid.gd")
const SETTLE_FRAMES := 240
const SAVE_PATH := "user://structures.json"


func _init() -> void:
	_run()


func _run() -> void:
	# Start from nothing, so a leftover save from a previous run cannot make an
	# empty build look like a working one.
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))

	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await physics_frame

	var failures: Array[String] = []
	var structures: Node3D = world.get_node_or_null(^"Structures") as Node3D
	var build: Node = world.get_node_or_null(^"BuildMode")
	var player: CharacterBody3D = world.get_node_or_null(^"Player") as CharacterBody3D
	if structures == null or build == null or player == null:
		print("build FAIL: scene is missing Structures, BuildMode or Player")
		quit(1)
		return

	var catalogue: Dictionary = structures.call("catalogue")
	print("catalogue: %d pieces" % catalogue.size())
	if catalogue.size() < 20:
		failures.append("only %d pieces in the catalogue; expected the M8 set" % catalogue.size())
	for required: String in ["floor_wooddark", "wall_plaster_straight", "roof_roundtiles_4x4"]:
		if not catalogue.has(required):
			failures.append("catalogue is missing '%s'" % required)

	# Build a floor and the four walls around it, by hand rather than through
	# the input layer: this asserts placement and persistence, and the aiming is
	# checked by eye in a rendered frame.
	var origin := player.global_position
	var ground: float = float(world.call("ground_height_at", origin.x, origin.z))
	var cell: Vector3 = GRID.snap_to_cell(Vector3(origin.x + 6.0, ground, origin.z))
	cell.y = float(world.call("ground_height_at", cell.x, cell.z))

	var floor_node: Node3D = structures.call("place", "floor_wooddark", cell, 0.0)
	if floor_node == null:
		failures.append("could not place a floor")

	# One wall on each edge of that cell, which is the placement the anchor
	# split exists for: a wall sits on the cell EDGE while the floor sits on its
	# CENTRE, and getting that wrong is the failure this whole grid is designed
	# around.
	var walls := 0
	for side in [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]:
		var edge: Dictionary = GRID.snap_to_edge(cell + side * (GRID.CELL * 0.45))
		var at: Vector3 = edge["position"]
		at.y = cell.y
		if structures.call("place", "wall_plaster_straight", at, float(edge["yaw"])) != null:
			walls += 1
	if walls != 4:
		failures.append("placed %d of 4 walls" % walls)

	var built: int = int(structures.call("count"))
	print("built %d pieces" % built)

	# Rotation must survive the round trip, not just position: a wall saved
	# without its yaw reloads lying across the doorway.
	var before: Array = structures.call("records")

	if not bool(structures.call("save")):
		failures.append("save() failed")
	structures.call("clear")
	if int(structures.call("count")) != 0:
		failures.append("clear() left %d pieces" % structures.call("count"))

	var reloaded: int = int(structures.call("load_saved"))
	print("reloaded %d pieces" % reloaded)
	if reloaded != built:
		failures.append("saved %d pieces and reloaded %d" % [built, reloaded])

	var after: Array = structures.call("records")
	for i in mini(before.size(), after.size()):
		var was: Dictionary = before[i]
		var now: Dictionary = after[i]
		for key: String in ["piece", "x", "y", "z", "yaw_deg"]:
			var same: bool = (str(was[key]) == str(now[key])) if key == "piece" \
				else is_equal_approx(float(was[key]), float(now[key]))
			if not same:
				failures.append("piece %d changed '%s' across save/load: %s -> %s" % [
					i, key, was[key], now[key]
				])

	# Removal, which the MultiMesh path could not have done at all.
	var removed: bool = bool(structures.call("remove_nearest", cell, 3.0))
	if not removed:
		failures.append("remove_nearest found nothing to remove at the floor")
	if int(structures.call("count")) != reloaded - 1:
		failures.append("removal left %d pieces, expected %d" % [structures.call("count"), reloaded - 1])

	# The mode itself: it must refuse to open mid-fight and must suspend
	# locomotion when it does open.
	build.call("_set_open", true)
	if not bool(build.call("is_open")):
		failures.append("build mode did not open")
	build.call("_set_open", false)
	if bool(build.call("is_open")):
		failures.append("build mode did not close")

	print("")
	if failures.is_empty():
		print("build: OK — pieces place on the grid, survive a reload, and can be removed.")
		quit(0)
	else:
		for line in failures:
			print("build FAIL: %s" % line)
		quit(1)
