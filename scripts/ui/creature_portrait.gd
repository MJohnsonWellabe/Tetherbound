extends RefCounted
## Dedicated portraits win. Water's temporary portraits follow its explicit
## installed body source until a species-specific portrait lands.
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const DIRECTORY := "res://assets/ui/portraits/creatures/"
const HUD_CONFIG := "res://data/config/hud.json"
static var _frames_loaded := false
static var _frames: Dictionary = {}
static var _textures: Dictionary = {}

static func resolve(species_id: String) -> String:
	if species_id.is_empty():
		return ""
	var dedicated := DIRECTORY + species_id + ".png"
	if ResourceLoader.exists(dedicated):
		return dedicated
	var definition := SPECIES.definition(species_id)
	var base := str(definition.get("variant_of", ""))
	if base.is_empty():
		base = str(definition.get("water_placeholder", {}).get("source_species", ""))
	return DIRECTORY + base + ".png" if not base.is_empty() else dedicated


## HUD views of installed art; source pixels and species resolution stay intact.
## Unknown or invalid regions retain the original texture, never a substitute.
static func texture_for_path(path: String) -> Texture2D:
	if _textures.has(path):
		return _textures[path] as Texture2D
	var source := load(path) as Texture2D if not path.is_empty() and ResourceLoader.exists(path) else null
	if source == null:
		return null
	if not _frames_loaded:
		_frames_loaded = true
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(HUD_CONFIG))
		if parsed is Dictionary:
			var config: Variant = parsed.get("creature_portrait_frames", {})
			if config is Dictionary and config.get("regions") is Dictionary:
				_frames = config.regions
	var coordinates: Variant = _frames.get(path)
	var valid: bool = coordinates is Array and coordinates.size() == 4
	if valid:
		for value: Variant in coordinates:
			if (not value is int and not value is float) or not is_finite(float(value)):
				valid = false
				break
	if valid:
		var region := Rect2(float(coordinates[0]), float(coordinates[1]), float(coordinates[2]), float(coordinates[3]))
		if region.size.x > 0 and region.size.y > 0 and Rect2(Vector2.ZERO, source.get_size()).encloses(region):
			var frame := AtlasTexture.new()
			frame.atlas = source
			frame.region = region
			frame.filter_clip = true
			_textures[path] = frame
			return frame
	_textures[path] = source
	return source
