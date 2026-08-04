extends SceneTree

## Build a small house and photograph it.
##
##   xvfb-run -a -s "-screen 0 1600x900x24" /opt/godot/godot --path . \
##     --rendering-driver opengl3 --resolution 1600x900 \
##     --script tools/preview_build.gd
##
## This is the acceptance for the whole build system, and `tests/smoke_build.gd`
## is not. Every way snapping goes subtly wrong — a wall half a cell out, a wall
## facing along the wrong axis, a roof a storey too low, a floor with a hairline
## gap to its neighbour — places successfully, saves, reloads, and passes every
## assertion in that file. You have to look at it.
##
## The trainer stands beside the house at a known 1.8m, because "does this look
## like a house" and "is this house the right size for a person" are different
## questions and only the second one has an answer a still frame can settle.

const STRUCTURES := preload("res://scripts/building/structures.gd")
const TRAINER := preload("res://scripts/player/trainer_model.gd")
const GRID := preload("res://scripts/building/build_grid.gd")
const OUT := "res://shots/_build_%s.png"

## A 3x2 cell cottage: floors, walls with a doorway and windows, a roof over it.
const ROOM := Vector2i(3, 2)


func _init() -> void:
	_run()


func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	_light(world)

	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(60, 60)
	ground.mesh = plane
	var grass := StandardMaterial3D.new()
	grass.albedo_color = Color(0.42, 0.48, 0.29)
	ground.material_override = grass
	world.add_child(ground)

	var structures := Node3D.new()
	structures.set_script(STRUCTURES)
	world.add_child(structures)
	await process_frame

	var placed := _build_cottage(structures)
	print("placed %d pieces" % placed)

	# The ruler: the real trainer, fitted to the real 1.8m capsule.
	var trainer := Node3D.new()
	trainer.set_script(TRAINER)
	world.add_child(trainer)
	trainer.position = Vector3(-1.0, 0.0, 5.5)

	var camera := Camera3D.new()
	camera.fov = 46.0
	world.add_child(camera)
	camera.make_current()

	for i in 60:
		await physics_frame

	var views := {
		"outside": {"at": Vector3(9.5, 5.0, 11.0), "look": Vector3(2.0, 1.4, 1.0)},
		"corner": {"at": Vector3(-10.0, 4.0, 10.5), "look": Vector3(1.0, 1.2, 1.0)},
		"top": {"at": Vector3(4.0, 15.0, 12.0), "look": Vector3(2.0, 0.0, 1.0)},
	}
	for name: String in views.keys():
		var view: Dictionary = views[name]
		camera.global_position = view["at"]
		camera.look_at(view["look"], Vector3.UP)
		for i in 5:
			await process_frame
		await RenderingServer.frame_post_draw
		var shot := root.get_texture().get_image()
		if shot != null:
			shot.save_png(OUT % name)
			print("wrote %s" % (OUT % name))

	print("the trainer beside it is 1.80m.")
	quit(0)


## A cottage laid out in grid coordinates, so the picture tests the grid rather
## than a set of hand-tuned positions.
func _build_cottage(structures: Node3D) -> int:
	var placed := 0
	var base := Vector3.ZERO

	# Floor: every cell of the room.
	for cx in ROOM.x:
		for cz in ROOM.y:
			var cell: Vector3 = GRID.snap_to_cell(base + Vector3(cx * GRID.CELL, 0.0, cz * GRID.CELL))
			if structures.call("place", "floor_wooddark", cell, 0.0) != null:
				placed += 1

	# Walls around the perimeter, each snapped to the edge it sits on — the same
	# call the ghost makes, so this frame shows what the player would get.
	for cx in ROOM.x:
		for cz in ROOM.y:
			var cell: Vector3 = GRID.snap_to_cell(base + Vector3(cx * GRID.CELL, 0.0, cz * GRID.CELL))
			for side in [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]:
				# Interior edges get no wall, or the room is subdivided.
				var neighbour := Vector2i(cx + int(side.x), cz + int(side.z))
				if neighbour.x >= 0 and neighbour.x < ROOM.x and neighbour.y >= 0 and neighbour.y < ROOM.y:
					continue
				var edge: Dictionary = GRID.snap_to_edge(cell + side * (GRID.CELL * 0.45))
				var piece := "wall_plaster_straight"
				# One doorway on the south face, windows on the rest.
				if side.z > 0 and cx == 1:
					piece = "wall_plaster_door_round"
				elif side.x != 0 and cz == 0:
					piece = "wall_plaster_window_wide_round"
				if structures.call("place", piece, edge["position"], float(edge["yaw"])) != null:
					placed += 1

	# Roof over the middle of the room, one storey up. `Roof_RoundTiles_6x4`
	# does not exist in the extracted set, so a 3x3 covers a 3x2 room with the
	# extra cell of overhang the kit already builds in.
	# `snap_to_cell` passes height through untouched, so the storey is set ONCE
	# here. The first version of this line added it again afterwards and put the
	# roof six metres up, hanging in the sky above a doorless box — which is
	# exactly the class of error a passing smoke test cannot see and this frame
	# caught in one look.
	var centre := Vector3(
		(ROOM.x - 1) * GRID.CELL * 0.5, 0.0, (ROOM.y - 1) * GRID.CELL * 0.5
	)
	var roof_at: Vector3 = GRID.snap_to_cell(centre)
	roof_at.y = GRID.STOREY
	if structures.call("place", "roof_roundtiles_6x6", roof_at, 0.0) != null:
		placed += 1

	# A fence run leading away from the door, which is what shows whether
	# edge-anchored pieces line up end to end. Snapped along ONE axis so they
	# form a line: picking the nearest edge per post staggers them across two
	# columns, which looks like a snapping bug and is a preview bug.
	for i in 3:
		var at := Vector3(3.0, 0.0, (ROOM.y + i) * GRID.CELL + 1.0)
		if structures.call("place", "prop_woodenfence_single", at, PI * 0.5) != null:
			placed += 1
	return placed


func _light(world: Node3D) -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.55, 0.68, 0.84)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.72, 0.76, 0.82)
	e.ambient_light_energy = 1.1
	e.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.environment = e
	world.add_child(env)

	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(deg_to_rad(-44.0), deg_to_rad(-38.0), 0.0)
	sun.light_energy = 1.5
	sun.shadow_enabled = true
	world.add_child(sun)
