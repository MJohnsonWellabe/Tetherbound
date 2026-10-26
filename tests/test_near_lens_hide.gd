extends "res://tests/test_case.gd"

## F41#5 near-lens rule (`foliage_camera_visibility.json near_lens_hide`):
## a big trunk whose surface comes within the clearance of the camera moves
## from the opaque instancer into its model's small near-fade MultiMesh (so
## only the pixels at the lens dissolve), and moves back once the camera
## leaves; a far trunk never moves; a tree felled meanwhile is never put back.
## Data level, like `test_fight_ring_occluders.gd`: a recording stand-in
## replaces the Terrain3D instancer.

const VEGETATION := preload("res://scripts/world/vegetation.gd")
const MODEL := "res://assets/environment/stylized_nature/CommonTree_1.gltf" # vegetation.json `trees`
const CFG := {"enabled": true, "realms": ["stormwood"],
	"layers": {"trees": {"reach": 1.0, "fade": [2.5, 3.0]}}, "show_margin_m": 1.0}


class RecordingInstancer extends RefCounted:
	var removed: Array[Vector3] = []
	var added: Array[Transform3D] = []
	var refreshes := 0

	func remove_instances(at: Vector3, _params: Dictionary) -> void:
		removed.append(at)

	func add_transforms(_mesh_id: int, transforms: Array[Transform3D], _colours: PackedColorArray, _update: bool) -> void:
		added.append_array(transforms)

	func update_mmis(_rebuild: bool) -> void:
		refreshes += 1


func _veg(with_fade_mesh := true) -> Array:
	var veg: Node3D = VEGETATION.new()
	var instancer := RecordingInstancer.new()
	veg.set("_instancer", instancer)
	veg.set("near_lens_override", CFG)
	if with_fade_mesh:
		(veg.get("_lens_fade_meshes") as Dictionary)[MODEL] = BoxMesh.new()
	return [veg, instancer]


## One upright trunk of collision radius 0.5 x scale 4 = 2 m at `at`.
func _record(veg: Node3D, at: Vector3, harvest_index: int = -1) -> void:
	var placement := {"model": MODEL, "position": at, "scale": 4.0, "yaw": 0.0}
	if harvest_index >= 0:
		placement["harvest_layer"] = "trees"
		placement["harvest_index"] = harvest_index
		(veg.get("_harvest_lookup") as Dictionary)["trees#%d" % harvest_index] = {"position": at}
	var xform := Transform3D(Basis().scaled(Vector3.ONE * 4.0), at - Vector3.UP * VEGETATION.SINK)
	var transforms: Array[Transform3D] = [xform]
	veg.call("_record_lens_occluders", MODEL, {"collision_radius": 0.5}, [placement], 3, transforms, PackedColorArray())


func test_trunk_at_the_lens_moves_to_the_near_fade_and_back() -> void:
	var pair := _veg()
	var veg: Node3D = pair[0]
	var instancer: RecordingInstancer = pair[1]
	_record(veg, Vector3(3.5, 0.0, 0.0), 0) # surface 1.5 m from the lens
	assert_eq(int(veg.call("update_near_lens", Vector3.ZERO)), 1)
	assert_eq(instancer.removed, [Vector3(3.5, 0.0, 0.0)], "out of the opaque instancer at its own spot")
	assert_eq(int(veg.call("near_lens_fade_instances", MODEL)), 1, "drawn by the near-fade MultiMesh instead")
	assert_eq(int(veg.call("update_near_lens", Vector3(-2.0, 0.0, 0.0))), 0,
		"inside clearance + margin it stays swapped (no flicker)")
	assert_eq(int(veg.call("update_near_lens", Vector3(-6.0, 0.0, 0.0))), 1)
	assert_eq(instancer.added.size(), 1, "back in the instancer once the camera moves away")
	assert_eq(instancer.added[0].origin, Vector3(3.5, 0.0, 0.0) - Vector3.UP * VEGETATION.SINK)
	assert_eq(int(veg.call("near_lens_fade_instances", MODEL)), 0, "and gone from the near fade")
	veg.free()


func test_far_trunk_never_moves() -> void:
	var pair := _veg()
	var veg: Node3D = pair[0]
	var instancer: RecordingInstancer = pair[1]
	_record(veg, Vector3(0.0, 0.0, -6.0)) # surface 4 m away
	assert_eq(int(veg.call("update_near_lens", Vector3.ZERO)), 0)
	assert_true(instancer.removed.is_empty())
	assert_eq(int(veg.call("near_lens_fade_instances", MODEL)), 0)
	veg.free()


func test_felled_tree_is_not_put_back() -> void:
	var pair := _veg()
	var veg: Node3D = pair[0]
	var instancer: RecordingInstancer = pair[1]
	_record(veg, Vector3(3.5, 0.0, 0.0), 5)
	veg.call("update_near_lens", Vector3.ZERO)
	(veg.get("_harvest_lookup") as Dictionary).erase("trees#5")
	veg.call("update_near_lens", Vector3(-20.0, 0.0, 0.0))
	assert_true(instancer.added.is_empty(), "a tree felled while swapped stays gone")
	assert_eq(int(veg.call("near_lens_fade_instances", MODEL)), 0, "and is not drawn by the near fade either")
	veg.free()


func test_without_a_fade_mesh_nothing_moves() -> void:
	var pair := _veg(false)
	var veg: Node3D = pair[0]
	var instancer: RecordingInstancer = pair[1]
	_record(veg, Vector3(3.5, 0.0, 0.0))
	assert_eq(int(veg.call("update_near_lens", Vector3.ZERO)), 0)
	assert_true(instancer.removed.is_empty(), "never removed without its near-fade copy to draw it")
	veg.free()


func test_off_by_default() -> void:
	assert_true(VEGETATION.near_lens_config("stormwood").is_empty(), "shipped config keeps the rule OFF")
	var veg: Node3D = VEGETATION.new()
	var instancer := RecordingInstancer.new()
	veg.set("_instancer", instancer)
	_record(veg, Vector3(3.5, 0.0, 0.0))
	assert_eq(int(veg.call("update_near_lens", Vector3.ZERO)), 0, "nothing recorded while OFF")
	assert_true(instancer.removed.is_empty())
	veg.free()
