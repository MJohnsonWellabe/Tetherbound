extends SceneTree

var failures: Array[String] = []
var checks := 0
var fixture: Node3D
var world: Node3D
var space: PhysicsDirectSpaceState3D

func _init() -> void:
	_run.call_deferred()

func _check(ok: bool, label: String) -> void:
	checks += 1
	print("CHECK ", "PASS " if ok else "FAIL ", label)
	if not ok:
		failures.append(label)

func _ray(a: Vector3, b: Vector3) -> Dictionary:
	return space.intersect_ray(PhysicsRayQueryParameters3D.create(
		fixture.to_global(a), fixture.to_global(b), 1))

func _run() -> void:
	# Keep the real world object OUT of the tree: no world-build _ready.
	# Its actual geometry/surface functions populate only this tiny fixture.
	world = preload("res://scripts/world/cloudreach_world.gd").new()
	fixture = Node3D.new()
	fixture.name = "CliffholdTerracePhysicsFixture"
	fixture.position = Vector3(-340,830,3970)
	root.add_child(fixture)
	var mat := StandardMaterial3D.new()
	var materials := {"masonry":mat, "stone_light":mat, "weathered_timber":mat}
	world.call("_box", fixture, "ExistingSettlementFloor", Vector3(0,-0.22,0),
		Vector3(48,0.44,48), mat, true)
	(world.get("_surfaces") as Array).append({"kind":"rect", "centre":Vector2(-340,3970),
		"half":Vector2(24,24), "height":830.0})
	var visual: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/config/cloudreach_visual.json"))
	var cfg: Dictionary = visual.settlement.occupied_terrace
	preload("res://scripts/world/cloudreach_cliffhold_terrace.gd").build(world,fixture,cfg,materials)
	for _frame in 3:
		await physics_frame
	space = fixture.get_world_3d().direct_space_state
	var midpoint := fixture.to_global(Vector3(-11,2.1,11))
	var indexed := float(world.call("ground_height_at", midpoint.x, midpoint.z, midpoint.y))
	var top_hit := _ray(Vector3(-11,5,11), Vector3(-11,-1,11))
	_check(absf(indexed-midpoint.y)<0.002, "stair midpoint registered at exact 2.1m elevation")
	_check(not top_hit.is_empty() and absf((top_hit.position as Vector3).y-midpoint.y)<0.005,
		"real stair collider agrees with midpoint surface index")
	var crossing := fixture.to_global(Vector3(-11,0,14))
	var lower := float(world.call("ground_height_at",crossing.x,crossing.z,830.0))
	var upper := float(world.call("ground_height_at",crossing.x,crossing.z,833.36))
	_check(absf(lower-830.0)<0.002, "preferred lower watch path stays at original floor")
	_check(absf(upper-833.36)<0.002, "preferred stair crossing selects sloped upper surface")
	var capsule := CapsuleShape3D.new()
	capsule.radius=0.3
	capsule.height=1.8
	for z: float in [12.4,14.0,15.6]:
		var underside := _ray(Vector3(-11,0.2,z),Vector3(-11,5,z))
		var clearance := (underside.position as Vector3).y-830.15 if not underside.is_empty() else -INF
		_check(clearance>1.8, "watch crossing headroom z=%.1f clear=%.4fm" % [z,clearance])
		for x: float in [-13.0,-12.0,-11.0,-10.0,-9.0]:
			var query := PhysicsShapeQueryParameters3D.new()
			query.shape=capsule
			query.collision_mask=1
			query.transform=Transform3D(Basis.IDENTITY,fixture.to_global(Vector3(x,1.05,z)))
			_check(space.intersect_shape(query,8).is_empty(),
				"1.8m trainer fits watch path at x=%.1f,z=%.1f" % [x,z])
	for y: float in [4.65,5.2]:
		var guard := _ray(Vector3(0,y,18),Vector3(0,y,14))
		_check(not guard.is_empty() and absf((guard.position as Vector3).z-3986.185)<0.01,
			"front guardrail collider blocks at visible rail y=%.2f" % y)
	for side: float in [-1.0,1.0]:
		var rail := _ray(Vector3(-11,3.14,11),Vector3(-11+side*3,3.14,11))
		_check(not rail.is_empty() and absf(absf((rail.position as Vector3).x+351)-1.415)<0.01,
			"stair handrail collider matches visible side %.0f" % side)
	_check(_ray(Vector3(-11,4.8,18),Vector3(-11,4.8,14)).is_empty(),
		"deliberate stair-top opening remains clear between front guardrails")
	print("CLIFFHOLD TERRACE PHYSICS: checks=",checks," failures=",failures.size())
	fixture.free()
	world.free()
	quit(0 if failures.is_empty() else 1)
