## Tiny production-construction check for the High Perches' installed-asset
## ground roosts. Calls the actual production builder against its registered
## crown surface without booting a second full Cloudreach world.
extends SceneTree

const WORLD_SCRIPT := preload("res://scripts/world/cloudreach_world.gd")
const EXPECTED_ASSET := "res://assets/props/kenney_survival/tree-log-small.glb"
const LANDING_CLEAR_RADIUS := 4.5
const MIN_SHAFT_GAP := 0.5
const STEP_HEIGHT := 0.35


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	# Attach after the plain node has entered the tree, so the production
	# script's full-world _ready coroutine is not invoked by this tiny fixture.
	world.set_script(WORLD_SCRIPT)
	var materials := {}
	for key in ["stone", "wood", "masonry", "masonry_trim", "weathered_timber", "rope"]:
		materials[key] = StandardMaterial3D.new()
	world.set("_materials", materials)
	world.call("register_runtime_surface", {
		"kind": "rect", "centre": Vector2(900.0, 2700.0),
		"half": Vector2(17.0, 17.0), "height": 1020.0,
	})
	var landmark := Node3D.new()
	landmark.name = "HighRoostPerches"
	landmark.position = Vector3(900.0, 1020.0, 2700.0)
	world.add_child(landmark)
	world.call("_build_high_perches", landmark)

	var racks := landmark.find_children("GroundRoostRack*", "Node3D", true, false)
	var logs := landmark.find_children("GroundRoostLog*", "Node3D", true, false)
	var sockets := landmark.find_children("GroundRoostSocket*", "MeshInstance3D", true, false)
	var needles := landmark.find_children("RoostNeedle*", "MeshInstance3D", true, false)
	var failures: Array[String] = []
	if racks.size() != 3: failures.append("expected 3 racks, got %d" % racks.size())
	if logs.size() != 3: failures.append("expected 3 installed logs, got %d" % logs.size())
	if sockets.size() != 6: failures.append("expected 6 sockets, got %d" % sockets.size())
	if needles.size() != 6: failures.append("expected 6 retained needles, got %d" % needles.size())

	var collisions := 0
	var minimum_landing_clearance := INF
	var minimum_shaft_gap := INF
	var maximum_visual_height := 0.0
	for rack: Node3D in racks:
		collisions += rack.find_children("*", "StaticBody3D", true, false).size()
		var rack_landmark := rack.get_parent() as Node3D
		var centre := Vector2(rack.position.x, rack.position.z)
		var half_length := float(rack.get_meta("crossbar_length_m", 0.0)) * 0.5
		maximum_visual_height = maxf(maximum_visual_height,
			float(rack.get_meta("visual_height_m", INF)))
		minimum_landing_clearance = minf(minimum_landing_clearance, centre.length() - half_length)
		var floor_y := float(world.call("ground_height_at", rack.global_position.x,
			rack.global_position.z, rack_landmark.global_position.y))
		if is_nan(floor_y) or absf(rack.global_position.y - floor_y) > 0.02:
			failures.append("%s is not grounded on production floor" % rack.name)
		for needle: MeshInstance3D in needles:
			if needle.get_parent() != rack_landmark or not (needle.mesh is CylinderMesh):
				continue
			var radius := (needle.mesh as CylinderMesh).bottom_radius
			var needle_local := Vector2(needle.position.x, needle.position.z)
			minimum_shaft_gap = minf(minimum_shaft_gap,
				centre.distance_to(needle_local) - half_length - radius)
	if collisions != 0: failures.append("ground roost additions contain %d collision bodies" % collisions)
	if minimum_landing_clearance < LANDING_CLEAR_RADIUS:
		failures.append("landing clearance %.3f < %.3f" % [minimum_landing_clearance, LANDING_CLEAR_RADIUS])
	if minimum_shaft_gap < MIN_SHAFT_GAP:
		failures.append("shaft gap %.3f < %.3f" % [minimum_shaft_gap, MIN_SHAFT_GAP])
	if maximum_visual_height > STEP_HEIGHT:
		failures.append("visual height %.3f > step height %.3f" % [maximum_visual_height, STEP_HEIGHT])
	for log: Node3D in logs:
		if log.scene_file_path != EXPECTED_ASSET:
			failures.append("%s does not instance installed log asset: %s" % [log.name, log.scene_file_path])

	print("CLOUDREACH GROUND ROOST %s racks=%d logs=%d sockets=%d collisions=%d landing_clearance=%.3f shaft_gap=%.3f visual_height=%.3f failures=%s" % [
		"PASS" if failures.is_empty() else "FAIL", racks.size(), logs.size(), sockets.size(),
		collisions, minimum_landing_clearance, minimum_shaft_gap, maximum_visual_height, failures])
	quit(0 if failures.is_empty() else 1)
