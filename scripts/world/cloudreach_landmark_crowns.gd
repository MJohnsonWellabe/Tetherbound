extends RefCounted

## F40#3 (LANE-MESHY, 11 Nov; `landmark_crowns_1111` in cloudreach_visual.json, OFF
## until judged). Judges (G-recheck-1111, 3/3, new_art): the Cloudreach landmarks read
## as plain, disconnected pieces, with "no aviary-family landmark: no dome, gold trim,
## bridges". ON crowns the Old Wind Observatory's tower and the Windscar Beacon gate with
## the aviary's own dome (cloudreach_aviary.gd _build_dome: meridian ribs, latitude rings,
## oculus), in gold over an opaque slate-blue shell, so the three summits share one
## architectural family. Presentation only: no collider, no route or stand change.

const AVIARY := preload("res://scripts/world/cloudreach_aviary.gd")
const CONFIG := "res://data/config/cloudreach_visual.json"


static func config() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	var cfg: Variant = (parsed as Dictionary).get("landmark_crowns_1111", {}) if parsed is Dictionary else {}
	return cfg if cfg is Dictionary and bool((cfg as Dictionary).get("enabled", false)) else {}


## A gold-ribbed dome whose springing ring sits at `base` (parent-local).
static func dome(parent: Node3D, label: String, base: Vector3, radius: float, cfg: Dictionary) -> Node3D:
	var holder := Node3D.new()
	holder.name = label
	holder.position = base
	parent.add_child(holder)
	var gold := StandardMaterial3D.new()
	gold.albedo_color = Color(str(cfg.get("gold", "#d6ad52")))
	gold.metallic = 0.6
	gold.roughness = 0.34
	var shell_material := StandardMaterial3D.new()
	shell_material.albedo_color = Color(str(cfg.get("shell", "#4d6e8c")))
	shell_material.roughness = 0.62
	shell_material.metallic = 0.25
	var shell := MeshInstance3D.new()
	shell.name = "CrownShell"
	var sphere := SphereMesh.new()
	sphere.is_hemisphere = true
	sphere.radius = radius * 0.96
	sphere.height = radius * 0.96
	sphere.radial_segments = 32
	sphere.rings = 12
	shell.mesh = sphere
	shell.material_override = shell_material
	holder.add_child(shell)
	AVIARY._build_dome(holder, {
		"radius_m": radius, "meridian_count": 12, "rib_segments": 6,
		"rib_base_radius_m": radius * 0.032, "rib_tip_radius_m": radius * 0.02,
		"primary_rib_every": 3, "primary_rib_radius_scale": 1.6,
		"oculus_radius_m": radius * 0.14, "ring_tube_radius_m": radius * 0.012,
		"oculus_ring_tube_radius_m": radius * 0.03, "latitude_ring_count": 3,
		"primary_ring_every": 2, "primary_ring_radius_scale": 1.8,
		"spring_ring_tube_radius_m": radius * 0.045,
	}, 0.0, gold, gold)
	var finial := MeshInstance3D.new()
	finial.name = "CrownFinial"
	var ball := SphereMesh.new()
	ball.radius = radius * 0.07
	ball.height = radius * 0.14
	finial.mesh = ball
	finial.material_override = gold
	finial.position = Vector3.UP * (radius + radius * 0.06)
	holder.add_child(finial)
	holder.set_meta("landmark_crown", true)
	return holder
