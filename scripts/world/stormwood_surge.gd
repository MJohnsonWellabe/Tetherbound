extends "res://scripts/world/world_weather.gd"

## Realm-scoped WorldWeather extension. Only the host advances the persistent
## cycle; Session carries snapshots across scene changes and to late joiners.
const RULES := preload("res://scripts/world/stormwood_surge_rules.gd")
var rules := RULES.new()
var world: Node3D
var phase := "calm"
var sheltered := false
var _glyph: Label
var _local := false
var _last_phase := ""
var _shelter_check_left := 0.0

func _ready() -> void:
	world = get_parent() as Node3D
	_local = not bool(world.get("simulation_only"))
	player_path = NodePath("../Player")
	look_path = NodePath("../WorldLook")
	add_to_group(GROUP)
	if _local:
		_rain = _build_rain()
		add_child(_rain)
		_rain.emitting = true
		var layer := CanvasLayer.new()
		layer.name = "SurgeStatus"
		add_child(layer)
		_glyph = Label.new()
		_glyph.position = Vector2(24, 150)
		_glyph.add_theme_color_override("font_color", Color("c3ddff"))
		_glyph.add_theme_color_override("font_outline_color", Color("14202a"))
		_glyph.add_theme_constant_override("outline_size", 5)
		layer.add_child(_glyph)

func _process(delta: float) -> void:
	var game := get_node_or_null("/root/Game")
	if game == null:
		return
	var state: Dictionary = game.get("realm_environment")
	var saved: Variant = state.get("stormwood", {})
	var storm: Dictionary = saved.duplicate(true) if saved is Dictionary else {}
	var raw: Variant = storm.get("elapsed", 0.0)
	var elapsed := float(raw) if (raw is float or raw is int) and is_finite(float(raw)) else 0.0
	var session := get_node_or_null("/root/Game/Session")
	if session == null or bool(session.call("is_host")):
		elapsed = maxf(0.0, elapsed) + delta
		storm["elapsed"] = elapsed
		storm["schema_version"] = 1
		state["stormwood"] = storm
		game.set("realm_environment", state)
	if not _local:
		return
	_follow_player()
	var player := world.get_node("Player") as Node3D
	var region := region_at(player.global_position)
	var flags: RefCounted = game.get("progression")
	phase = phase_at_position(player.global_position)
	var lightning := world.get_node_or_null("StormwoodLightning")
	_shelter_check_left -= delta
	if _shelter_check_left <= 0.0:
		_shelter_check_left = 0.25
		sheltered = lightning.sheltered(player.global_position, player) if lightning != null else rules.sheltered(player.global_position, region, false)
	_glyph.text = "⚡ %s%s" % [phase.capitalize(), " · Sheltered" if sheltered else ""]
	if phase != _last_phase:
		_last_phase = phase
		_apply_phase_light()
	if phase == "break" and sheltered and region == "cinder_verge":
		var chapter := world.get_node_or_null("StormwoodChapter")
		if chapter != null and not flags.has("stormwood:first_break_witnessed"):
			chapter.call("emit_event", "surge:tutorial_break")

func region_at(at: Vector3) -> String:
	# Crown overlaps the Conductor Run in Z, so test the island first.
	if Vector2(at.x - 700, at.z - 2700).length() < 245 and at.y > 50:
		return "hollow_crown"
	for region: Dictionary in world.call("config_data").get("regions", []):
		var bounds: Dictionary = region.bounds
		if at.x >= float(bounds.min_x) and at.x <= float(bounds.max_x) and at.z >= float(bounds.min_z) and at.z <= float(bounds.max_z):
			return str(region.id)
	return "cinder_verge"

func weather() -> String:
	return "storm" if phase == "break" else "rain"

func charged_nodes_open() -> bool:
	return rules.charged_nodes_open(phase)

## Queries use the shared host clock and the target's region, including when
## this node is a simulation shell with no local player presentation.
func phase_at_position(at: Vector3) -> String:
	var game := get_node_or_null("/root/Game")
	if game == null:
		return "calm"
	var environment: Dictionary = game.get("realm_environment")
	var saved: Variant = environment.get("stormwood", {})
	var raw: Variant = saved.get("elapsed", 0.0) if saved is Dictionary else 0.0
	var elapsed := maxf(0.0, float(raw)) if (raw is float or raw is int) and is_finite(float(raw)) else 0.0
	var region := region_at(at)
	var flags: RefCounted = game.get("progression")
	var rod_flag := str(rules.config.regions.get(region, {}).get("rod_flag", ""))
	return str(rules.phase_at(elapsed, region, not rod_flag.is_empty() and flags.has(rod_flag), flags.has("stormwood:long_storm_ended")).phase)

func charged_nodes_open_at(at: Vector3) -> bool:
	return rules.charged_nodes_open(phase_at_position(at))

func _apply_phase_light() -> void:
	var look := world.get_node_or_null("WorldLook")
	if look != null:
		look.call("set_weather", {
			"sun": {"energy_mult": 0.65 if phase == "break" else 0.85},
			"environment": {"ambient_colour": {"calm": "#b6d5c5", "building": "#d7a77b", "break": "#d2ccff", "fading": "#e0b397"}.get(phase),
				"ambient_energy_mult": 0.85, "fog_density_add": 0.00015 if phase == "break" else 0.0}})
	if _rain != null:
		_rain.amount_ratio = 1.0 if phase == "break" else 0.35
