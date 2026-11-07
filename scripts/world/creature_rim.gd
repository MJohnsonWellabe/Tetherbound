extends RefCounted

## F38#1/#2/#26 ("creatures sit in the shaded tree-trunk band, read as small
## dark blobs, no rim light"). `creature_rim.json`, OFF by default: while a
## listed realm look is loaded (Meadows), every creature body, wild or
## companion, gets the same cool fresnel backlight the Stormwood people wear,
## as a material overlay on its shadow-casting model meshes. Reuses
## stormwood_character_rim.gd's overlay()/dress(); nothing is copied.
##
## The overlay slot is shared with transient combat/VFX overlays (tell_style
## wind-up auras, enemy_pattern_telegraph boss auras, body_glow hit flashes and
## level-up pulses). They may take a rimmed mesh (`is_rim`) and hand it back
## through `rest_overlay` when they end; an overlay that is not ours is never
## replaced by the rim. While OFF no mesh carries the rim, so `is_rim` is
## always false and `rest_overlay` always null: those callers behave exactly
## as before. Client presentation only; no state, no collision.
const CONFIG := "res://data/config/creature_rim.json"
const RIM := preload("res://scripts/world/stormwood_character_rim.gd")
## Every creature body joins this group (creature_body.gd::AUDIO_GROUP).
const BODY_GROUP := &"creature_voice"
## Set on the rim material and, holding it, on each mesh it dresses.
const META := &"creature_rim"

static var _material: ShaderMaterial = null


static func settings() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG)) \
		if FileAccess.file_exists(CONFIG) else {}
	return parsed if parsed is Dictionary else {}


static func active() -> bool:
	return _material != null


## Called by world_look.gd when a realm look loads. Turns the rim on for a
## listed look (dressing bodies already alive, e.g. companions carried across
## a realm crossing) and off for any other (undressing them).
static func set_realm(look_path: String) -> void:
	var cfg := settings()
	var wanted := bool(cfg.get("enabled", false)) \
		and (cfg.get("realm_looks", []) as Array).has(look_path)
	var tree := Engine.get_main_loop() as SceneTree
	if not wanted:
		if _material != null and tree != null:
			for body: Node in tree.get_nodes_in_group(BODY_GROUP):
				undress(body)
		_material = null
		return
	if _material == null:
		_material = RIM.overlay(cfg)
		_material.set_meta(META, true)
	if tree != null:
		for body: Node in tree.get_nodes_in_group(BODY_GROUP):
			dress_body(body)


## Called by creature_body.gd whenever it (re)builds its model. A no-op while
## the rim is not active.
static func dress_body(body: Node) -> int:
	if _material == null or body == null:
		return 0
	var art: Variant = body.call("model_pivot") if body.has_method("model_pivot") else body
	# A body leaving the tree (world freed, realm handover) sheds its rim first:
	# freeing a MeshInstance3D that still wears the overlay logs "Parameter
	# material is null" from material_get_instance_shader_parameters on every
	# net/region smoke (CI 4 Nov, batch 6). It is dressed again on re-entry.
	if not body.tree_exiting.is_connected(undress.bind(body)):
		body.tree_exiting.connect(undress.bind(body))
		body.tree_entered.connect(dress_body.bind(body))
	return dress(art as Node, _material)


## Dress the shadow-casting MeshInstance3D bodies under `root`, leaving any
## mesh that already carries someone else's overlay alone.
static func dress(root: Node, material: ShaderMaterial) -> int:
	if root == null or material == null:
		return 0
	var count := RIM.dress(root, material, true)
	var nodes: Array = root.find_children("*", "MeshInstance3D", true, false)
	nodes.append(root)
	for node: Variant in nodes:
		var mesh := node as MeshInstance3D
		if mesh != null and mesh.material_overlay == material:
			mesh.set_meta(META, material)
	return count


static func undress(body: Node) -> void:
	if body == null:
		return
	for node: Node in body.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		if not mesh.has_meta(META):
			continue
		if mesh.material_overlay == mesh.get_meta(META):
			mesh.material_overlay = null
		mesh.remove_meta(META)
		mesh.remove_meta(RIM.META)


## True for the rim overlay: a transient overlay may take that mesh.
static func is_rim(material: Material) -> bool:
	return material != null and material.has_meta(META)


## What a mesh's overlay returns to when a transient overlay ends: its rim if
## it was dressed and the rim is still on, otherwise nothing.
static func rest_overlay(mesh: GeometryInstance3D) -> Material:
	if _material == null or mesh == null or not mesh.has_meta(META):
		return null
	return mesh.get_meta(META) as Material
