extends "res://scripts/world/realm_heart_shrine.gd"

## Stormwood masonry presentation over the existing relic state, prompts,
## companion sockets and collision. Companion slots inherit this script through
## the shared producer's get_script().new(); no relic mechanics are duplicated.
const ROCK := preload("res://assets/environment/stylized_nature/Rock_Medium_1.gltf")
const RENDER_BOUNDS := preload("res://scripts/characters/render_bounds.gd")


func _build_visual() -> void:
	if _built:
		return
	super._build_visual()
	if not presentation_enabled:
		return
	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color("b6b5a0")
	stone.albedo_texture = load("res://assets/environment/terrain/Rock030_Color.jpg")
	stone.roughness = 0.94
	stone.uv1_triplanar = true
	stone.uv1_scale = Vector3.ONE * 1.7
	(get_node("StoneBase") as MeshInstance3D).material_override = stone
	# Preserve the exact material reference repainted by inherited relic state.
	_socket_material.albedo_texture = stone.albedo_texture
	_socket_material.uv1_triplanar = true
	_socket_material.uv1_scale = Vector3.ONE * 2.0
	var masonry := Node3D.new()
	masonry.name = "WeatheredMasonry"
	add_child(masonry)
	for index in 12:
		var angle := TAU * float(index) / 12.0
		var height := 0.25 + 0.035 * float(index % 3)
		_fit_rock(masonry, "RimStone%02d" % index,
			Vector3(cos(angle) * 1.18, height * 0.5, sin(angle) * 1.18),
			Vector3(0.61, height, 0.49), -angle + 0.14 * float(index % 2))
	for index in 4:
		var standing := get_node("StandingStone%d" % (index + 1)) as MeshInstance3D
		standing.visible = false
		var height := 0.76 + 0.10 * float(index % 3)
		_fit_rock(masonry, "SocketStandingStone%d" % (index + 1),
			Vector3(standing.position.x, 0.29 + height * 0.5, standing.position.z),
			Vector3(0.32, height, 0.44), standing.rotation.y + 0.1)


func _fit_rock(parent: Node3D, label: String, at: Vector3, size: Vector3, yaw: float) -> void:
	var rock := ROCK.instantiate() as Node3D
	var bounds := RENDER_BOUNDS.measure(rock)
	if bounds.size.x <= 0.0 or bounds.size.y <= 0.0 or bounds.size.z <= 0.0:
		push_error("Stormwood shrine rock has empty imported geometry")
		rock.free()
		return
	var holder := Node3D.new()
	holder.name = label
	holder.position = at
	holder.rotation.y = yaw
	parent.add_child(holder)
	rock.scale = size / bounds.size
	rock.position = -bounds.get_center() * rock.scale
	holder.add_child(rock)
