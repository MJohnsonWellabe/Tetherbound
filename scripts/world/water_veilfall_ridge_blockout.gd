extends Node3D
## Independent P2-010 blockout. Render-only installed rock masses; old candidates
## and their physical supports remain untouched. No terrain/route/gate mutation.
const CONFIG := "res://data/config/water_veilfall_ridge_blockout.json"
const ASSETS := preload("res://scripts/world/water_blockout_assets.gd")
const FALLS := preload("res://scripts/world/water_veilfall_falls.gd")

func build(world: Node3D, veilfall: Node3D) -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	if not bool(cfg.get("ridge_blockout_enabled", false)) or bool(world.get("simulation_only")):
		return
	for spec: Dictionary in cfg.masses:
		var rock := ASSETS.piece(str(spec.model), _v(spec.size_m))
		if rock == null:
			push_error("Veilfall blockout could not build " + str(spec.id))
			return
		rock.name = str(spec.id)
		add_child(rock)
		rock.position = _v(spec.base_xyz)
		rock.rotation_degrees = _v(spec.rotation_deg)
	# Select the new render candidate after the ordinary hierarchy is complete.
	# Visibility never changes the old StaticBody3D/collider/transport nodes.
	var old_near := veilfall.get_node_or_null("WaterfallPassage/VeilfallExteriorComposition") as Node3D
	if old_near != null:
		old_near.visible = false
	var far := veilfall.get_node_or_null("VeilfallFarSilhouette")
	if far != null:
		for child: Node in far.get_children():
			if child is MeshInstance3D and str(child.name).begins_with("Far_"):
				child.visible = false
	var old_falls := veilfall.get_node_or_null("VeilfallWhiteFalls") as Node3D
	if old_falls != null:
		old_falls.visible = false
	var falls := FALLS.new()
	falls.name = "RidgeBlockoutCurtain"
	add_child(falls)
	var centre: Array = cfg.centre_xz
	falls.build(world, cfg.falls, Vector2(float(centre[0]), float(centre[1])))
	if far != null:
		for material: ShaderMaterial in falls.materials:
			far.call("register_fogged", material)

static func _v(a: Array) -> Vector3:
	return Vector3(float(a[0]), float(a[1]), float(a[2]))
