extends SceneTree

## CURRENT_STATE.md §3 P1: *"at the beginning of the game, you are submerged
## in the bed rather than on it."*
##
## `OPENING-BED-0903` fixed the wake beat by eye, from one frame, against the
## PREVIOUS defect (a collapsed skin that read as a floating backpack). Nobody
## measured the body against the mattress. This does, in numbers, before any
## render: it stages the wake beat exactly as
## `sequence_director.gd::_spawn_the_cast()` does, lets physics settle, and
## reports
##
##   * the mattress collider's own top plane and footprint;
##   * where the body actually settled, and on what;
##   * the trainer art's rendered AABB in world space (through the same
##     `render_bounds.gd` the model's own `_fit()` measures with, so a skinned
##     rig is measured the way the GPU draws it, not down its node chain);
##   * how far the body's lowest rendered point sits BELOW the mattress plane
##     -- the submersion, as one number.
##
##   godot --headless --path . --script tools/gate_f/probe_loft_bed_wake_pose.gd

const GRANDPA_HOUSE := preload("res://scripts/world/grandpa_house.gd")
const CAMERA_RIG_SCRIPT := preload("res://scripts/player/camera_rig.gd")
const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const DIRECTOR_PATH := "res://scripts/story/sequence_director.gd"
const RENDER_BOUNDS := preload("res://scripts/characters/render_bounds.gd")

const SETTLE_FRAMES := 120

## How far below the mattress plane the rendered AABB may still reach.
##
## The first cut of this probe said "zero, plus float noise", decided before
## any frame was rendered — and that criterion was wrong about what the AABB's
## minimum IS. A code-blind judge, handed a ladder of lifts, established that
## the rig's lowest rendered point is the pouch and bedroll slung at the
## trainer's hip, not the body: lift the pack clear of the sheet and the body
## flies above it (*"a body suspended from a bag, which is exactly
## backwards"*). So the criterion is the one the judge's chosen rung actually
## satisfies — the KIT sinks into the bedding by
## `sequence_director.gd::LIE_KIT_SINK_M`, and nothing more of the body than
## that goes under. Compare with the 0.331 m this measured before the fix.
const SUBMERSION_TOLERANCE_M := 0.24


func _init() -> void:
	_run()


func _run() -> void:
	var world := Node3D.new()
	world.name = "World"
	root.add_child(world)
	current_scene = world
	await process_frame

	var rig := CAMERA_RIG_SCRIPT.new() as Node3D
	rig.name = "CameraRig"
	world.add_child(rig)
	var camera := Camera3D.new()
	camera.current = true
	rig.add_child(camera)

	var player := PLAYER_SCENE.instantiate() as CharacterBody3D
	player.name = "Player"
	world.add_child(player)

	var house := GRANDPA_HOUSE.new()
	house.name = "GrandpaHouse"
	house.position = Vector3.ZERO
	world.add_child(house)
	house.call("build", rig, player)

	for i in 40:
		await physics_frame

	var bed: Vector3 = house.call("marker", "bed")
	var director_script := load(DIRECTOR_PATH) as GDScript
	var reach := float(director_script.get_script_constant_map().get("BED_LIE_REACH", 1.5))
	# Exactly `_spawn_the_cast()`'s own WAKE staging.
	player.global_position = Vector3(bed.x, bed.y + 0.05, bed.z + reach)
	player.velocity = Vector3.ZERO
	var model: Node3D = player.get_node_or_null(^"Model") as Node3D
	if model == null or not model.has_method("set_lying"):
		print("PROBE FAIL: no trainer Model / set_lying")
		quit(1)
		return
	model.call("set_lying", true)
	# The lift the real wake beat applies, from the director's own shipped
	# function rather than a copy of it (`sequence_director.gd::
	# _refresh_lying_lift()` calls exactly this every frame the body is lying).
	model.position.y = float(director_script.call("lying_lift_for", model))
	print("  lying lift applied   : %.3f m" % model.position.y)
	for i in SETTLE_FRAMES:
		await physics_frame

	var failures: Array[String] = []
	var mesh: Mesh = load("res://assets/props/quaternius_furniture/BedTwin.obj")
	var scale_factor := float(house.get_script().get_script_constant_map()["FURNITURE_SCALE"])
	var aabb := mesh.get_aabb()
	var inner_w := float(house.get_script().get_script_constant_map()["INNER_W"])
	var inner_d := float(house.get_script().get_script_constant_map()["INNER_D"])
	var floor_h := float(house.get_script().get_script_constant_map()["FLOOR_H"])
	var bed_at := Vector3(-inner_w * 0.5 + 1.3, floor_h + 0.25, -inner_d * 0.5 + 1.9)
	var half := aabb.size * scale_factor * 0.5
	# `BedTwin.obj`'s AABB is not centred on its own origin, and the mesh is
	# drawn at `bed_at` — so the bed a player sees, and the collider
	# `_bed_mattress_collider()` now builds, are both centred here rather than
	# on `bed_at` itself. Getting this wrong is the defect that fix corrected.
	var centre := aabb.get_center() * scale_factor
	bed_at.x += centre.x
	bed_at.z += centre.z
	var plane := bed_at.y + 0.3
	print("")
	print("=== the wake beat, measured ===")
	print("  BED_LIE_REACH        : %.2f" % reach)
	print("  bed marker           : %s" % str(bed.snapped(Vector3.ONE * 0.01)))
	print("  mattress plane (top) : y=%.3f" % plane)
	print("  mattress footprint   : x %.3f..%.3f  z %.3f..%.3f"
		% [bed_at.x - half.x, bed_at.x + half.x, bed_at.z - half.z, bed_at.z + half.z])
	print("  staged at            : %s" % str(Vector3(bed.x, bed.y + 0.05, bed.z + reach).snapped(Vector3.ONE * 0.01)))
	print("  settled at           : %s (on_floor=%s)"
		% [str(player.global_position.snapped(Vector3.ONE * 0.001)), str(player.is_on_floor())])
	var support := player.global_position.y
	print("  supported by         : %s"
		% ("the MATTRESS" if absf(support - plane) < 0.05
			else ("the LOFT FLOOR (%.3f)" % support)))

	var box: AABB = RENDER_BOUNDS.measure(model)
	var world_min := model.global_position + box.position
	var world_max := world_min + box.size
	print("  rendered body AABB   : size %s" % str(box.size.snapped(Vector3.ONE * 0.001)))
	print("     world y %.3f .. %.3f     z %.3f .. %.3f"
		% [world_min.y, world_max.y, world_min.z, world_max.z])
	var sunk := plane - world_min.y
	print("  SUBMERSION           : %.3f m of the body is below the mattress plane" % sunk)
	print("  body length in Z     : %.3f m  (mattress is %.3f m)" % [box.size.z, half.z * 2.0])

	if support < plane - 0.05:
		failures.append("the body settles %.3fm BELOW the mattress top -- the staging point"
			% (plane - support) + " is outside the mattress footprint, so it lands on the loft floor")
	if sunk > SUBMERSION_TOLERANCE_M:
		failures.append("%.3fm of the rendered body is below the mattress plane (the slung"
			% sunk + " kit may sink %.3fm; more than that is the body itself)"
			% SUBMERSION_TOLERANCE_M)
	if world_min.z < bed_at.z - half.z - 0.02 or world_max.z > bed_at.z + half.z + 0.02:
		failures.append("the body hangs off the mattress in Z (%.3f..%.3f vs %.3f..%.3f)"
			% [world_min.z, world_max.z, bed_at.z - half.z, bed_at.z + half.z])

	print("")
	if failures.is_empty():
		print("PROBE RESULT: the wake beat lies ON the mattress")
		quit(0)
		return
	print("PROBE RESULT: %d unresolved" % failures.size())
	for f in failures:
		print("  - %s" % f)
	quit(1)
