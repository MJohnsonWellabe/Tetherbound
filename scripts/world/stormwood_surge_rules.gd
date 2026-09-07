extends RefCounted

## Pure host policy. Presentation consumes committed snapshots; callers must
## never use a client's local clock or request as authority for a strike.
const PATH := "res://data/config/stormwood_surge.json"
const PHASES := ["calm","building","break","fading"]
var config: Dictionary

func _init(authored: Dictionary = {}) -> void:
	config = authored.duplicate(true) if not authored.is_empty() else JSON.parse_string(FileAccess.get_file_as_string(PATH))

func phase_at(elapsed: float,region: String,rod_disabled: bool = false,aftermath: bool = false) -> Dictionary:
	var row: Dictionary = config.regions.get(region,{})
	var durations: Array[float] = []
	var total := 0.0
	for entry: Dictionary in config.phases:
		var id := str(entry.id)
		var seconds := float(config.aftermath_seconds[id]) if aftermath else float(entry.seconds)
		if not aftermath:
			if id == "calm":
				if bool(row.get("gentle",false)):
					seconds *= float(config.gentle_calm_multiplier)
				if rod_disabled:
					seconds *= float(config.disabled_rod_calm_multiplier)
			elif id == "break" and rod_disabled:
				seconds *= float(config.disabled_rod_break_multiplier)
		seconds = maxf(0.01,seconds)
		durations.append(seconds)
		total += seconds
	var time := maxf(0,elapsed) if is_finite(elapsed) else 0.0
	var local := fposmod(time,total)
	for i in durations.size():
		if local < durations[i]:
			return {"phase":PHASES[i],"elapsed":local,"remaining":durations[i]-local,"duration":durations[i],"cycle":floori(time/total),"cycle_seconds":total}
		local -= durations[i]
	return {}

func sheltered(at: Vector3,region: String,canopy: bool,rods: Array = []) -> bool:
	if canopy or bool(config.regions.get(region,{}).get("safe",false)):
		return true
	var point := Vector2(at.x,at.z)
	for zone: Dictionary in config.safe_zones:
		if point.distance_to(Vector2(float(zone.at[0]),float(zone.at[1]))) <= float(zone.radius):
			return true
	for rod: Vector3 in rods:
		if absf(rod.y-at.y) <= float(config.strike.rod_radius_m) and point.distance_to(Vector2(rod.x,rod.z)) <= float(config.strike.rod_radius_m):
			return true
	return false

func eligible_ground(at: Vector3,region: String,canopy: bool,rods: Array = []) -> bool:
	if not config.regions.has(region) or sheltered(at,region,canopy,rods):
		return false
	if not bool(config.regions[region].get("gentle",false)):
		return true
	for clearing: Dictionary in config.marked_clearings:
		if str(clearing.region_id) == region and Vector2(at.x,at.z).distance_to(Vector2(float(clearing.at[0]),float(clearing.at[1]))) <= float(clearing.radius):
			return true
	return false

func strike_effect(region: String,max_health: float,insulated_pieces: int) -> Dictionary:
	var full_set := maxi(1,int(config.strike.insulation_pieces_for_immunity))
	var exposure := 1.0-float(clampi(insulated_pieces,0,full_set))/float(full_set)
	var health := maxf(0,max_health) if is_finite(max_health) else 0.0
	var base := float(config.regions.get(region,{}).get("damage",0))
	return {"damage":minf(base,health*float(config.strike.max_health_fraction))*exposure,"static_seconds":float(config.strike.static_seconds)*exposure,"regen_multiplier":float(config.strike.static_regen_multiplier),"stagger":true}

func charged_nodes_open(phase: String) -> bool:
	return phase in ["break","fading"]
