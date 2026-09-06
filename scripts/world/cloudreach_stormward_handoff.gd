extends RefCounted

const GATE := preload("res://scripts/world/realm_gate.gd")
const SHRINE := preload("res://scripts/world/realm_heart_shrine.gd")

## Summit's short scarred descent. Surfaces register with Cloudreach's normal
## height queries so arrival, recovery and host-shell collision agree.
static func build(world: Node3D) -> void:
	var root := Node3D.new()
	root.name = "StormwardPassage"
	world.add_child(root)
	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color("575967")
	stone.roughness = 0.95
	for i in 24:
		var top := 1110.0 - float(i) * 0.25
		var at := Vector3(-420, top - 0.6, 5664 + i * 1.4)
		var body := StaticBody3D.new()
		body.name = "ScarredStep%02d" % i
		body.position = at
		root.add_child(body)
		var mesh := BoxMesh.new()
		mesh.size = Vector3(10,1.2,1.5)
		var visual := MeshInstance3D.new()
		visual.mesh = mesh
		visual.material_override = stone
		body.add_child(visual)
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = mesh.size
		collision.shape = shape
		body.add_child(collision)
		world.call("register_runtime_surface", {"kind":"rect", "centre":Vector2(at.x,at.z), "half":Vector2(5,0.75), "height":top})
	var gate := GATE.new()
	gate.name = "StormwardRealmGate"
	gate.position = Vector3(-420,1104.25,5696.2)
	gate.origin_realm = "cloudreach"
	gate.setup("stormwood", "stormwood_arrival_from_cloudreach", "The Stormwood", "realm_key_stormwood", "realm_gate_stormwood_unlocked")
	root.add_child(gate)
	var shrine := SHRINE.new()
	shrine.name = "WingsOfCloudreachShrine"
	shrine.position = Vector3(1104,1051.3,2936)
	shrine.setup("cloudreach", "Wings of Cloudreach", "cloudreach")
	root.add_child(shrine)
