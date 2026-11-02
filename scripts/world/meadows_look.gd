extends "res://scripts/world/world_look.gd"

## F38: one Meadows clock/weather rig. The candidate changes presentation only;
## it does not own the clock, save state, quality selection or another realm.
const MEADOWS_SURFACES := preload("res://scripts/world/meadows_surface_finish.gd")
const MEADOWS_GRADE := preload("res://scripts/world/meadows_colour_grade.gd")
var _meadows_candidate: Dictionary = {}
## Viewport values `cause_ground.viewport` replaced, restored on exit.
var _cause_viewport_restore: Dictionary = {}
## `cause_ground.viewport`, read once at load (the environment re-applies on
## the clock; no file read per apply).
var _cause_viewport: Dictionary = {}


func _load() -> Dictionary:
	var base := cause_light_look(light_candidate_look(super._load()), MEADOWS_SURFACES.CONFIG)
	_cause_viewport = cause_ground_viewport(MEADOWS_SURFACES.CONFIG)
	_meadows_candidate = MEADOWS_SURFACES.settings()
	if not bool(_meadows_candidate.get("enabled", false)):
		return base
	return merged_look(base, _meadows_candidate.get("lighting", {}))


## Group 3 (vis-meadows, OFF until GPU-judged): meadows_look.json
## `light_candidate.look` is merged over art.json for the Meadows rig only,
## the same recursive overlay a realm look uses. Off: `base` unchanged.
static func light_candidate_look(base: Dictionary) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MEADOWS_SURFACES.CONFIG))
	if not parsed is Dictionary:
		return base
	var candidate: Dictionary = (parsed as Dictionary).get("light_candidate", {})
	if not bool(candidate.get("enabled", false)):
		return base
	return merged_look(base, candidate.get("look", {}))


## Cause lane tb/cause-meadows (OFF until GPU-judged): meadows_look.json
## `cause_light.look` merged over the loaded look, after light_candidate, so
## the two compose. Off: `base` unchanged. `look_path` is a parameter so a
## unit test can point it at a fixture.
static func cause_light_look(base: Dictionary, look_path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(look_path))
	if not parsed is Dictionary:
		return base
	var cause: Dictionary = (parsed as Dictionary).get("cause_light", {})
	if not bool(cause.get("enabled", false)):
		return base
	return merged_look(base, cause.get("look", {}))


## `cause_ground.viewport` while `cause_ground.enabled`, else empty. Only the
## two texture-clarity keys are honoured.
static func cause_ground_viewport(look_path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(look_path))
	if not parsed is Dictionary:
		return {}
	var cause: Dictionary = (parsed as Dictionary).get("cause_ground", {})
	if not bool(cause.get("enabled", false)):
		return {}
	var viewport: Dictionary = cause.get("viewport", {})
	var out: Dictionary = {}
	for key: String in ["anisotropic_filtering_level", "texture_mipmap_bias"]:
		if viewport.has(key):
			out[key] = viewport[key]
	return out


func _apply_cause_viewport() -> void:
	var wanted := _cause_viewport
	var viewport := get_viewport()
	if wanted.is_empty() or viewport == null:
		return
	if _cause_viewport_restore.is_empty():
		_cause_viewport_restore = {
			"anisotropic_filtering_level": viewport.anisotropic_filtering_level,
			"texture_mipmap_bias": viewport.texture_mipmap_bias,
		}
	if wanted.has("anisotropic_filtering_level"):
		viewport.anisotropic_filtering_level = clampi(int(wanted.anisotropic_filtering_level), 0, 4) \
			as Viewport.AnisotropicFiltering
	if wanted.has("texture_mipmap_bias"):
		viewport.texture_mipmap_bias = clampf(float(wanted.texture_mipmap_bias), -2.0, 0.0)


func _exit_tree() -> void:
	# The Meadows' texture clarity must not follow the player into another realm.
	var viewport := get_viewport()
	if _cause_viewport_restore.is_empty() or viewport == null:
		return
	viewport.anisotropic_filtering_level = _cause_viewport_restore.anisotropic_filtering_level
	viewport.texture_mipmap_bias = float(_cause_viewport_restore.texture_mipmap_bias)
	_cause_viewport_restore = {}


func _ready() -> void:
	super._ready()
	if not bool(_meadows_candidate.get("enabled", false)):
		return
	var finish := MEADOWS_SURFACES.new()
	finish.name = "MeadowsSurfaceFinish"
	add_child(finish)
	finish.watch(get_parent())


func _apply_environment(cfg: Dictionary, sky_cfg: Dictionary) -> void:
	super._apply_environment(cfg, sky_cfg)
	# After super: GRAPHICS_PREFS.apply_viewport runs there and would otherwise
	# put its own (absent by default) values back over these.
	_apply_cause_viewport()
	if not bool(_meadows_candidate.get("enabled", false)):
		return
	var holder := get_node_or_null(environment_path) as WorldEnvironment
	if holder == null or holder.environment == null:
		return
	holder.environment = MEADOWS_GRADE.apply_to(holder.environment, _meadows_candidate)
	# Quality owns feature enablement. The biome owns the atmosphere when that
	# feature is selected; Low never gets a Forward+-only feature switched on.
	var environment := holder.environment
	if environment.volumetric_fog_enabled:
		environment.volumetric_fog_density = float(cfg.get("meadows_volume_density", 0.0012)) \
			* (1.0 + 0.6 * float(_weather.get("ground_wetness", 0.0)))
		environment.volumetric_fog_albedo = _as_colour(cfg.get("fog_colour"), "#98b2cb")
		environment.volumetric_fog_length = float(cfg.get("meadows_volume_length", 180.0))
	# The terrain is built after WorldLook and asks this rig to reapply once
	# ready. Use that existing hook instead of another frame-time poll.
	var terrain: Object = get_parent().get("_terrain")
	if is_instance_valid(terrain):
		var material: Object = terrain.get("material")
		if is_instance_valid(material):
			MEADOWS_SURFACES.apply_terrain(material)
