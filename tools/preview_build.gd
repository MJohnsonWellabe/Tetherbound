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
const STATION := preload("res://scripts/building/station.gd")
const TRAINER := preload("res://scripts/player/trainer_model.gd")
const GRID := preload("res://scripts/building/build_grid.gd")
const OUT := "res://shots/_build_%s.png"

## A 3x2 cell cottage: floors, walls with a doorway and windows, a roof over it.
const ROOM := Vector2i(3, 2)

## Where the doorway lands, given the layout below: the +Z edge of the middle
## cell of the far row. Stated rather than searched for, so the camera can be
## pointed at it.
const DOOR_AT := Vector3(3.0, 0.0, 4.0)
## Outside the door, and inside it. The trainer stands at one or the other.
const PORCH := Vector3(3.9, 0.0, 6.1)
const PARLOUR := Vector3(2.1, 0.0, 2.0)


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

	# The door itself. A door in the wrong place is a LOOKING problem — every
	# assertion in the suite was green while the leaf hung half over the pier and
	# while the doorway it hung in was a sealed box — so this tool photographs it
	# shut and open, from outside and from inside, with the trainer for scale.
	var door: Node = structures.call("nearest_station", DOOR_AT, 2.0, STATION.BEHAVIOUR_DOOR)
	if door == null:
		print("NO DOOR STATION: the leaf placed as bare geometry")

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
		await _shoot(name)

	# THE DOOR, four ways. Shut and open, from the porch and from the parlour.
	#
	# Each pair is the same camera on the same frame, so the only thing that
	# changes between them is the leaf: anything else that moves is a bug. The
	# trainer walks round to whichever side is being photographed, because "is
	# that opening big enough to walk through" has no answer in a picture with
	# nobody in it.
	for state: String in ["closed", "open"]:
		if state == "open" and door != null:
			# Opened from OUTSIDE, so the leaf must swing into the room.
			door.call("toggle", PORCH)
			door.call("snap")
		trainer.position = PORCH
		trainer.look_at(Vector3(DOOR_AT.x, 0.0, DOOR_AT.z), Vector3.UP)
		camera.global_position = Vector3(6.4, 2.5, 10.4)
		camera.look_at(Vector3(3.0, 1.3, 4.2), Vector3.UP)
		await _shoot("door_outside_%s" % state)

		trainer.position = PARLOUR
		trainer.look_at(Vector3(DOOR_AT.x, 0.0, DOOR_AT.z), Vector3.UP)
		camera.global_position = Vector3(3.6, 1.65, 0.6)
		camera.look_at(Vector3(3.0, 1.35, 4.4), Vector3.UP)
		await _shoot("door_inside_%s" % state)

	print("the trainer beside it is 1.80m.")
	quit(0)


func _shoot(name: String) -> void:
	for i in 5:
		await process_frame
	await RenderingServer.frame_post_draw
	var shot := root.get_texture().get_image()
	if shot != null:
		shot.save_png(OUT % name)
		print("wrote %s" % (OUT % name))


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
				# A DOOR HANGS IN THE DOORWAY. The kit splits the two, and the
				# cottage was rendered without the second half for as long as this
				# tool has existed — which is exactly why nobody looking at these
				# frames noticed the leaf was half a metre out when the settlement
				# started using it.
				if piece == "wall_plaster_door_round":
					if structures.call("place", "doorframe_round_wooddark", edge["position"], float(edge["yaw"])) != null:
						placed += 1
					if structures.call("place", "door_1_round", edge["position"], float(edge["yaw"])) != null:
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
		# Beside the porch, not across it: the fence used to run out of the
		# doorway at x=3 and stood between the camera and the one piece these
		# frames now exist to show.
		var at := Vector3(-1.0, 0.0, (ROOM.y + i) * GRID.CELL + 1.0)
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
