extends "res://tests/test_case.gd"

## PR #712 (22 Oct): with the Meshy hero gatehouse on, the gate built its
## camera-only occluder from the ~62k-triangle hero mesh. The fight camera
## tests that shape every physics frame, and smoke_relay went from 378 s to
## about 35 minutes. The occluder must stay the fitted kit arch: same envelope
## and opening, a small shape. The hero itself renders and never collides.

const RELAY := preload("res://scripts/world/tether_relay.gd")
const CONFIG_PATH := "res://data/config/tether_relay.json"
const MAX_OCCLUDER_FACES := 20000


func _gate() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	return ((parsed as Dictionary).get("gate", {}) as Dictionary).duplicate(true)


func _occluders(root: Node) -> Array[StaticBody3D]:
	var out: Array[StaticBody3D] = []
	for node: Node in root.find_children("CameraOccluder", "StaticBody3D", true, false):
		out.append(node as StaticBody3D)
	return out


func _faces(body: StaticBody3D) -> int:
	var count := 0
	for child: Node in body.get_children():
		if child is CollisionShape3D and (child as CollisionShape3D).shape is ConcavePolygonShape3D:
			count += ((child as CollisionShape3D).shape as ConcavePolygonShape3D).get_faces().size() / 3
	return count


func _build(gate: Dictionary) -> Array:
	var relay: Node3D = RELAY.new()
	var holder := Node3D.new()
	var outer_height := float(gate.get("pier_height", 0.0)) + float(gate.get("lintel_height", 0.0))
	var arch: MeshInstance3D = relay.call("_build_gate_presentation", holder, gate, Vector2.ZERO, 0.0, 0.0,
		float(gate.get("opening", 0.0)), outer_height, float(gate.get("pier_depth", 0.0)))
	return [relay, holder, arch]


func test_hero_gatehouse_keeps_the_kit_arch_as_its_camera_occluder() -> void:
	var gate := _gate()
	var presentation := gate.get("presentation", {}) as Dictionary
	presentation["hero"] = {"enabled": true,
		"scene": "res://assets/props/meshy-1022/relay_gatehouse_arch/relay_gatehouse_arch.glb"}
	gate["presentation"] = presentation
	var built := _build(gate)
	var arch: MeshInstance3D = built[2]
	assert_true(arch != null, "the hero gatehouse builds")
	if arch == null:
		(built[1] as Node).free()
		(built[0] as Node).free()
		return
	assert_true(arch.find_children("*", "StaticBody3D", true, false).is_empty(),
		"the dense hero mesh carries no collider of its own")
	var occluders := _occluders(built[1])
	assert_eq(occluders.size(), 1, "exactly one camera occluder")
	for body: StaticBody3D in occluders:
		assert_between(_faces(body), 1, MAX_OCCLUDER_FACES, "the occluder is the small kit-arch shape")
		assert_eq(body.collision_mask, 0, "the occluder collides with nothing")
	(built[1] as Node).free()
	(built[0] as Node).free()

