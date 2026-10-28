extends RefCounted

## F38 L4 / P2-005 (close-1024): an OFF candidate colour map for the Meadows
## terrain. `tools/bake_meadows_colour_candidate.gd` writes one varied copy of
## each shipped region's colour map; while `terrain_presentation.json
## colour_candidate.enabled`, this swaps them in after Terrain3D loads the
## shipped data. Colour only: heights, control, collision and the bake files
## on disk are untouched. The grass field samples the same colour maps, so the
## blades follow the ground.

const PRESENTATION := "res://data/config/terrain_presentation.json"
const TYPE_COLOR := 2


static func settings() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PRESENTATION))
	return (parsed as Dictionary).get("colour_candidate", {}) if parsed is Dictionary else {}


## Returns how many regions were swapped (0 when off or nothing to load).
static func apply(terrain: Node) -> int:
	var cfg := settings()
	if not bool(cfg.get("enabled", false)) or terrain == null:
		return 0
	var data: Object = terrain.get("data")
	if data == null:
		return 0
	var dir := str(cfg.get("dir", "res://data/terrain/playground_colour_candidate"))
	var swapped := 0
	for location: Vector2i in data.call("get_region_locations"):
		var path := ProjectSettings.globalize_path(dir.path_join("colour_%d_%d.png" % [location.x, location.y]))
		if not FileAccess.file_exists(path):
			continue
		var region: Object = data.call("get_region", location)
		var image := Image.load_from_file(path)
		if region == null or image == null:
			continue
		var shipped: Image = region.get("color_map")
		if shipped != null and (image.get_size() != shipped.get_size()):
			continue
		if shipped != null and shipped.get_format() != image.get_format():
			image.convert(shipped.get_format())
		image.generate_mipmaps()
		region.set("color_map", image)
		swapped += 1
	if swapped > 0:
		data.call("update_maps", TYPE_COLOR, true, false)
	print("[colour_candidate] swapped %d region colour maps from %s" % [swapped, dir])
	return swapped
