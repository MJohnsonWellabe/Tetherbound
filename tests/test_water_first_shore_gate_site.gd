extends "res://tests/test_case.gd"

const SITE := preload("res://scripts/world/water_first_shore_gate_site.gd")


class GroundFixture extends Node3D:
	func ground_height_at(x: float, z: float) -> float:
		return 2.0 + x * 0.001 + z * 0.0001


func _collision_objects_below(node: Node) -> Array[CollisionObject3D]:
	var found: Array[CollisionObject3D] = []
	if node is CollisionObject3D:
		found.append(node as CollisionObject3D)
	for child: Node in node.get_children():
		found.append_array(_collision_objects_below(child))
	return found


func test_first_shore_gate_site_uses_installed_visuals_without_collision() -> void:
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SITE.CONFIG_PATH))
	assert_eq(config.schema_version, 1)
	assert_eq(config.gate_xz, [12.0, 162.0])
	assert_eq(float(config.opening_width_m), 2.95)
	assert_eq(float(config.interaction_radius_m), 4.0)
	var pieces: Array = config.pieces
	assert_eq(pieces.size(), 12, "site should remain one small threshold/approach arrangement")
	var roles := {}
	for raw: Variant in pieces:
		var piece: Dictionary = raw
		assert_true(ResourceLoader.exists(str(piece.model)), "%s is not an installed model" % str(piece.model))
		roles[str(piece.role)] = int(roles.get(str(piece.role), 0)) + 1
	assert_eq(int(roles.get("threshold", 0)), 3)
	assert_eq(int(roles.get("arrival_approach", 0)), 3)
	assert_eq(int(roles.get("front_approach", 0)), 1)
	assert_eq(int(roles.get("pell_route", 0)), 3)
	assert_eq(int(roles.get("framing_stone", 0)), 2)

	var world := GroundFixture.new()
	var site := SITE.new()
	world.add_child(site)
	site.build(world, 1.881)
	assert_eq(site.get_child_count(), pieces.size())
	assert_true(_collision_objects_below(site).is_empty(),
		"visual place-making added collision beside the production gate")
	for child: Node in site.get_children():
		var piece := child as Node3D
		assert_true(piece != null and piece.position.is_finite(), "site piece is not finitely grounded")
		var spec: Dictionary = pieces.filter(func(entry: Dictionary) -> bool:
			return str(entry.id) == child.name)[0]
		var bounds := SITE.RENDER_BOUNDS.measure(piece)
		var bottom := piece.position.y + bounds.position.y * piece.scale.y
		var expected := world.ground_height_at(piece.position.x, piece.position.z) \
				+ float(spec.get("sink_y", 0.0))
		assert_almost_eq(bottom, expected, 0.001,
			"site piece render bounds are not individually grounded")
	world.free()


func test_framing_stones_and_pavers_preserve_the_gate_clearance() -> void:
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SITE.CONFIG_PATH))
	var gate := Vector2(float(config.gate_xz[0]), float(config.gate_xz[1]))
	for raw: Variant in config.pieces:
		var piece: Dictionary = raw
		var at := Vector2(float(piece.at[0]), float(piece.at[1]))
		if str(piece.role) == "framing_stone":
			var model := (load(str(piece.model)) as PackedScene).instantiate() as Node3D
			var bounds := SITE.RENDER_BOUNDS.measure(model)
			var scale_raw: Array = piece.scale
			# Half-diagonal is conservative under any configured yaw: if that
			# circle clears the prompt radius, the real rotated AABB clears it.
			var extent := Vector2(bounds.size.x * float(scale_raw[0]),
					bounds.size.z * float(scale_raw[2])).length() * 0.5
			assert_true(at.distance_to(gate) - extent > float(config.interaction_radius_m),
				"framing stone render bounds entered the gate prompt/approach circle")
			model.free()
		else:
			assert_eq(str(piece.model),
				"res://assets/buildings/quaternius_medieval/Floor_UnevenBrick.gltf",
				"an approach piece is raised geometry rather than a flat visual paver")
