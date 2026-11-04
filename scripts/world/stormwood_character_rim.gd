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
	var cfg: Dictionary = parsed if parsed is Dictionary else {}
	# Visual lane 3 Nov: r2 widens and brightens the rim (CPU v1/b10: r1 5.58 -> 5.98
	# for F41#18), applied only while r2.enabled; OFF until judged.
	var r2: Variant = cfg.get("r2", {})
	if r2 is Dictionary and bool((r2 as Dictionary).get("enabled", false)):
		for key: String in ["energy", "power"]:
			if (r2 as Dictionary).has(key):
				cfg[key] = (r2 as Dictionary)[key]
	# F41#8/#18 fill_1104 (OFF until judged; coordinator 4 Nov 19:25): a soft
	# front fill through the shared overlay's `fill_energy`, so faces and
	# uniform fronts lift off the dark moss ("flat faces, no catchlight").
	var fill: Variant = cfg.get("fill_1104", {})
	if fill is Dictionary and bool((fill as Dictionary).get("enabled", false)):
		cfg["fill_energy"] = float((fill as Dictionary).get("fill_energy", 0.0))
	return cfg


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
	material.set_shader_parameter("fill_energy", float(cfg.get("fill_energy", 0.0)))
	return material


## `keep_existing_overlay` (creature_rim.gd) leaves a mesh that already wears
## another overlay alone instead of replacing it.
static func dress(root: Node, material: ShaderMaterial, keep_existing_overlay := false) -> int:
	var count := 0
	var nodes: Array = root.find_children("*", "GeometryInstance3D", true, false)
	if root is GeometryInstance3D:
		nodes.append(root)
	for node: Variant in nodes:
		var geometry := node as GeometryInstance3D
		# Prompts, rings and effect cards cast no shadow; bodies do.
		if geometry == null or geometry.has_meta(META) \
				or geometry.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF \
				or not (geometry is MeshInstance3D) \
				or (keep_existing_overlay and geometry.material_overlay != null):
			continue
		geometry.material_overlay = material
		geometry.set_meta(META, true)
		count += 1
	return count


static func _on_child(child: Node, material: ShaderMaterial) -> void:
	# The body builds its meshes during its own setup, after it enters.
	dress.call_deferred(child, material)
