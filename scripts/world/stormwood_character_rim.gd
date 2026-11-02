extends RefCounted

## P2-056 (GPU 3.91: "Grunt Lieutenant Dace, Lieutenant Varga and Defector
## Sable are small dark figures lost against dark green-teal grass, with no rim
## light or uniform accent to pick them out"). `stormwood_character_rim.json`,
## OFF by default: every visible mesh of a Stormwood person or trainer body
## gets a cool fresnel backlight as its material overlay. Bodies added to the
## container later (residency rebuilds) get it on arrival. Client presentation
## only; no state, no collision, no other realm.
const CONFIG := "res://data/config/stormwood_character_rim.json"
const SHADER := preload("res://shaders/character_rim_overlay.gdshader")
const META := &"stormwood_character_rim"


static func settings() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG)) \
		if FileAccess.file_exists(CONFIG) else {}
	return parsed if parsed is Dictionary else {}


## Dress every body under `container` now and every body added to it later.
static func attach(container: Node) -> void:
	var cfg := settings()
	if container == null or not bool(cfg.get("enabled", false)):
		return
	var material := overlay(cfg)
	dress(container, material)
	if not container.child_entered_tree.is_connected(_on_child.bind(material)):
		container.child_entered_tree.connect(_on_child.bind(material))


static func overlay(cfg: Dictionary) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = SHADER
	material.set_shader_parameter("rim_colour", Color(str(cfg.get("colour", "#b8c8ff"))))
	material.set_shader_parameter("rim_energy", float(cfg.get("energy", 0.45)))
	material.set_shader_parameter("rim_power", float(cfg.get("power", 3.0)))
	return material


static func dress(root: Node, material: ShaderMaterial) -> int:
	var count := 0
	var nodes: Array = root.find_children("*", "GeometryInstance3D", true, false)
	if root is GeometryInstance3D:
		nodes.append(root)
	for node: Variant in nodes:
		var geometry := node as GeometryInstance3D
		# Prompts, rings and effect cards cast no shadow; bodies do.
		if geometry == null or geometry.has_meta(META) \
				or geometry.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF \
				or not (geometry is MeshInstance3D):
			continue
		geometry.material_overlay = material
		geometry.set_meta(META, true)
		count += 1
	return count


static func _on_child(child: Node, material: ShaderMaterial) -> void:
	# The body builds its meshes during its own setup, after it enters.
	dress.call_deferred(child, material)
