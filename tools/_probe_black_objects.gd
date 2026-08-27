extends SceneTree

## GF-B-004. "A black placeholder sphere hangs in the Meadows Hall gateway."
##
##   godot --headless --path . --script tools/_probe_black_objects.gd
##
## HEADLESS ON PURPOSE, and it is the whole point of this tool. The frame that
## reported this defect took a software-rasterised capture of the stronghold to
## produce, which on the grass-on build is well over half an hour of llvmpipe;
## the question it has to answer — "which object is that, and why is it black" —
## is a property of the SCENE GRAPH, not of the pixels. So this stands the real
## world up with the renderer off (~50 s) and asks every mesh in it directly.
##
## Reports three classes, because a black object in a frame can be any of them
## and they need different fixes:
##
##   NO MATERIAL      the surface has none at all; Godot draws a default. This
##                    is the "missing material" half of the item.
##   NEAR-BLACK       an albedo dark enough to render as a silhouette with no
##                    albedo texture to carry detail. A tinted primitive, not a
##                    missing asset.
##   FULLY METALLIC   `metallic >= METALLIC_SUSPECT` with no metallic texture to
##                    modulate it — the exact condition GF-B-010 turned out to
##                    be, kept here so the same defect in a non-humanoid asset is
##                    caught by name rather than rediscovered. The bar is high on
##                    purpose: this project's stone and iron materials set
##                    metallic 0.4-0.5 deliberately, and a first run at
##                    `metallic > 0` reported 59 correctly-authored castle blocks
##                    before it reached anything worth looking at.
##
## Sorted by height above the terrain, because "in the sky through the arch"
## says the thing is ABOVE the player, and a report ordered by Y puts the
## candidates first.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE := 240

## Albedo luminance under which an untextured surface reads as a silhouette
## rather than as a dark colour. Deliberately generous: this is a search tool,
## and a false positive costs one line of output.
const NEAR_BLACK_LUMA := 0.06

## What counts as "metal with nothing to modulate it". A deliberately metallic
## surface in this project sits at 0.4-0.5 (`stronghold.gd`'s stone and iron);
## the defect class is the glTF format default of 1.0 arriving unchanged.
const METALLIC_SUSPECT := 0.9

var _rows: Array = []


func _init() -> void:
	_run()


func _run() -> void:
	var packed: PackedScene = load(SCENE)
	if packed == null:
		print("FAIL: could not load %s" % SCENE)
		quit(1)
		return
	var world: Node = packed.instantiate()
	root.add_child(world)
	# The world stands up across several awaited frames (see
	# `playground_world.gd::_ready()`), and the settlement — which is where the
	# reported object is — is built last of all.
	for i in SETTLE:
		await process_frame

	_walk(world, "")
	_rows.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) > float(b[0]))

	print("\n=== suspect surfaces, highest first ===")
	if _rows.is_empty():
		print("none found")
	for row: Variant in _rows:
		var entry: Array = row
		print("  y=%8.2f  %-16s  %s" % [float(entry[0]), str(entry[1]), str(entry[2])])
	var by_class := {}
	for row: Variant in _rows:
		var entry: Array = row
		by_class[str(entry[1])] = int(by_class.get(str(entry[1]), 0)) + 1
	print("\n%d suspect surfaces %s" % [_rows.size(), by_class])
	quit(0)


func _walk(node: Node, path: String) -> void:
	if node is MeshInstance3D:
		var instance := node as MeshInstance3D
		# `is_visible_in_tree()` filters the fallback capsules every character
		# scene keeps behind its real rig (`character_model.gd::_hide_placeholders`)
		# -- they genuinely have no material and are genuinely never drawn, and a
		# first run reported the player's own hidden nose and body as the two
		# most suspicious things in the world.
		if instance.mesh != null and instance.is_visible_in_tree():
			for surface in instance.mesh.get_surface_count():
				_inspect(instance, surface, "%s/%s" % [path, instance.name])
	for child in node.get_children():
		_walk(child, "%s/%s" % [path, node.name])


func _inspect(instance: MeshInstance3D, surface: int, path: String) -> void:
	var y := instance.global_position.y
	var where := "%s[%d] %s at %s" % [
		path, surface, instance.mesh.get_class(), instance.global_position]
	var material: Material = instance.get_active_material(surface)
	if material == null:
		_rows.append([y, "NO MATERIAL", where])
		return
	if not material is BaseMaterial3D:
		return
	var m := material as BaseMaterial3D
	if m.albedo_texture == null:
		var c := m.albedo_color
		var luma := c.r * 0.2126 + c.g * 0.7152 + c.b * 0.0722
		if luma < NEAR_BLACK_LUMA and not m.emission_enabled:
			_rows.append([y, "NEAR-BLACK", "%s albedo=%s" % [where, c]])
			return
	if m.metallic >= METALLIC_SUSPECT and m.metallic_texture == null:
		_rows.append([y, "FULLY METALLIC", "%s metallic=%.2f" % [where, m.metallic]])
