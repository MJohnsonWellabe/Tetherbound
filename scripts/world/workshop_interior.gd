extends Node3D

## Shared dressing for the installed village workshop prefab.
##
## The prefab's open arch is local +Z at z=4; the back wall is z=-4 and the
## conservative inner wall faces are x=+-2.69. A level Stormwood foundation revealed that
## pale rear wall at its honest 8m depth after removing 3.22m of terrain that
## had previously occluded the bay. These installed work pieces give the eye
## foreground/midground silhouettes and warm falloff while leaving the whole
## centre aisle clear for the production player's 0.8m-wide capsule.

const IMPORTED_MATERIALS := preload("res://scripts/world/imported_materials.gd")


func build(room: Dictionary = {}) -> void:
	var floor_y := float(room.get("floor_top_y", 0.0))
	for raw: Variant in room.get("dressing", []):
		if not raw is Dictionary:
			continue
		var spec := raw as Dictionary
		var at_value: Array = spec.get("at", [])
		var size_value: Array = spec.get("collision_size", [])
		if at_value.size() < 2 or size_value.size() < 3:
			push_error("workshop room dressing has no placement/collision dimensions")
			continue
		_prop(str(spec.get("model", "")), str(spec.get("dir", "")),
			Vector3(float(at_value[0]), floor_y, float(at_value[1])),
			float(spec.get("yaw_deg", 0.0)),
			Vector3(float(size_value[0]), float(size_value[1]), float(size_value[2])))

	var light_spec: Dictionary = room.get("light", {})
	var light_at: Array = light_spec.get("at", [])
	if light_at.size() < 3:
		push_error("workshop room has no light placement")
		return
	var light := OmniLight3D.new()
	light.name = "WorkshopLight"
	light.position = Vector3(float(light_at[0]), float(light_at[1]), float(light_at[2]))
	light.light_color = Color(str(light_spec.get("color", "#ffffff")))
	light.light_energy = float(light_spec.get("energy", 1.0))
	light.omni_range = float(light_spec.get("range", 6.0))
	light.shadow_enabled = true
	add_child(light)


func _prop(model: String, directory: String, at: Vector3, yaw_deg: float,
		collision_size: Vector3) -> void:
	var path := "%s/%s.gltf" % [directory, model]
	if not ResourceLoader.exists(path):
		push_error("workshop interior missing installed prop: %s" % path)
		return
	var packed := load(path) as PackedScene
	if packed == null:
		push_error("workshop interior prop is not a scene: %s" % path)
		return
	var prop := packed.instantiate() as Node3D
	prop.name = model
	prop.position = at
	prop.rotation.y = deg_to_rad(yaw_deg)
	IMPORTED_MATERIALS.make_dielectric(prop)
	add_child(prop)

	# Dressing is physically present, like the furniture in every other village
	# interior. Boxes use the installed glTF accessor extents rounded upward;
	# all three remain beside/back of the configured 1.6m clear route.
	var body := StaticBody3D.new()
	body.name = "%sCollision" % model
	body.position = at + Vector3.UP * (collision_size.y * 0.5)
	body.rotation.y = deg_to_rad(yaw_deg)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = collision_size
	shape.shape = box
	body.add_child(shape)
	add_child(body)
