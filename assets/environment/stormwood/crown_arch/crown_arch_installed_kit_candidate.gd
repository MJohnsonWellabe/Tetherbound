extends RefCounted

## Crown-only installed-family silhouette experiment. The production caller owns
## the slab, clearance node, support/collider, and all gameplay state.
const CONFIG := "res://assets/environment/stormwood/crown_arch/installed_kit_candidate.json"
const TOWER := "res://assets/buildings/quaternius_castle/LargeSquareTowerBricks.obj"
const PIECE := preload("res://scripts/build/stormwood_arch_piece.gd")
const TOWER_SURFACES := 3
const TOWERS := [
    {"name": "CrownWestFlankTower", "x": -3.3, "scale": 1.7},
    {"name": "CrownEastFlankTower", "x": 3.3, "scale": 1.4},
]


static func _settings() -> Dictionary:
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
    return parsed if parsed is Dictionary else {}


static func has_opt_in() -> bool:
    return bool(_settings().get("enabled", false))


static func apply(piece: Node3D, slab: MeshInstance3D, clearance: Node3D) -> bool:
    var settings := _settings()
    if settings.get("enabled", false) != true:
        return false
    if piece == null or slab == null or clearance == null:
        push_warning("Crown installed-kit candidate unavailable; retaining installed presentation")
        return false
    if not is_instance_valid(piece) or not is_instance_valid(slab) or not is_instance_valid(clearance):
        push_warning("Crown installed-kit candidate unavailable; retaining installed presentation")
        return false
    var frame := piece.get_node_or_null("StormglassFrame") as MeshInstance3D
    var tower_mesh := load(TOWER) as Mesh
    if frame == null or tower_mesh == null or tower_mesh.get_surface_count() != TOWER_SURFACES:
        push_warning("Crown installed-kit mesh contract unavailable; retaining installed presentation")
        return false
    var stone := PIECE.masonry_material()
    if stone == null:
        return false
    var dark_stone := stone.duplicate() as StandardMaterial3D
    if dark_stone == null:
        return false
    dark_stone.albedo_color = Color(stone.albedo_color.r * 0.58, stone.albedo_color.g * 0.58,
        stone.albedo_color.b * 0.58, stone.albedo_color.a)
    dark_stone.roughness = maxf(stone.roughness, 0.9)
    var additions: Array[MeshInstance3D] = []
    for row: Dictionary in TOWERS:
        var tower := MeshInstance3D.new()
        tower.name = str(row.name)
        tower.mesh = tower_mesh
        var tower_scale := float(row.scale)
        tower.position = Vector3(float(row.x), 0.0, 0.0)
        tower.scale = Vector3.ONE * tower_scale
        for surface: int in range(tower_mesh.get_surface_count()):
            var surface_name: String = tower_mesh.surface_get_name(surface)
            tower.set_surface_override_material(surface,
                dark_stone if surface_name.begins_with("Black") else stone)
        additions.append(tower)
    # This architecture-only variant never mutates slab, clearance, or physics.
    for tower: MeshInstance3D in additions:
        piece.add_child(tower)
    return true