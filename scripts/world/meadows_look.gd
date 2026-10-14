extends "res://scripts/world/world_look.gd"

## F38: one Meadows clock/weather rig. The candidate changes presentation only;
## it does not own the clock, save state, quality selection or another realm.
const MEADOWS_SURFACES := preload("res://scripts/world/meadows_surface_finish.gd")
const MEADOWS_GRADE := preload("res://scripts/world/meadows_colour_grade.gd")
var _meadows_candidate: Dictionary = {}


func _load() -> Dictionary:
	var base := super._load()
	_meadows_candidate = MEADOWS_SURFACES.settings()
	if not bool(_meadows_candidate.get("enabled", false)):
		return base
	return merged_look(base, _meadows_candidate.get("lighting", {}))


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
