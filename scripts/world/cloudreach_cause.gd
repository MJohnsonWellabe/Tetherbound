extends RefCounted

## Cause lane tb/cause-cloudreach (owner, 1 Nov 2026: fix shared causes, not
## items). Four local-presentation parts over the built Cloudreach realm, each
## OFF by default in `data/config/cloudreach_cause.json`:
##
## - `pale_strata`: pale stratified stone on every cliff, crown bank, rock
##   section and buttress; the F26 course surface on; rusty stone retinted.
## - `cloud_sea`: settlement cloud cards never stand on the meadow (pushed out
##   over open air and below the rim), and the cloud deck rises, lit, under
##   the plateau edges.
## - `light_grade`: bright sky, warmer lower key, cool ambient, depth haze.
## - `meadow_groves`: groves, clearings and outcrops break the grass carpet
##   (`cloudreach_meadow_groves.gd`).
##
## No collider, route, save field, RPC or creature change; every peer builds
## the same dressing from the same data. A part merges last over the other
## overlays, so other lanes' flags compose underneath it.

const PATH := "res://data/config/cloudreach_cause.json"
const PARTS := ["pale_strata", "cloud_sea", "light_grade", "meadow_groves"]
const ALL_ARG := "--cloudreach-cause-candidate"
const PART_ARG_PREFIX := "--cloudreach-cause-"
const CLOUD_CARD_TEXTURE := "res://assets/environment/cloudreach/cloud_bank_v1.png"

static var _loaded := false
static var _config: Dictionary = {}


## The parsed config (cached: material factories call this per rock).
static func config() -> Dictionary:
	if not _loaded:
		_loaded = true
		var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		_config = raw as Dictionary if raw is Dictionary else {}
	return _config


## Tests swap the config in and out; production never calls this.
static func set_config_for_test(value: Variant) -> void:
	_loaded = value != null
	_config = value as Dictionary if value is Dictionary else {}


static func part_on(part: String, cfg: Dictionary = {}, user_args: PackedStringArray = PackedStringArray(),
		use_cmdline: bool = true) -> bool:
	var source := cfg if not cfg.is_empty() else config()
	var spec: Variant = source.get(part)
	if not spec is Dictionary:
		return false
	if bool(source.get("enabled", false)) or bool((spec as Dictionary).get("enabled", false)):
		return true
	var args := user_args
	if use_cmdline and args.is_empty():
		args = OS.get_cmdline_user_args()
	return args.has(ALL_ARG) or args.has(PART_ARG_PREFIX + part)


## The part's block when it is on, else {}.
static func part(name: String, cfg: Dictionary = {}, user_args: PackedStringArray = PackedStringArray(),
		use_cmdline: bool = true) -> Dictionary:
	if not part_on(name, cfg, user_args, use_cmdline):
		return {}
	var source := cfg if not cfg.is_empty() else config()
	return source.get(name, {}) as Dictionary


## Visual-config overlay (`cloudreach_world.gd::_ready`, after every other
## overlay): pale_strata's geology/relief and cloud_sea's deck settings.
static func apply_visual(base: Dictionary, cfg: Dictionary = {},
		user_args: PackedStringArray = PackedStringArray(), use_cmdline: bool = true) -> Dictionary:
	var result := base
	for name: String in ["pale_strata", "cloud_sea"]:
		var spec := part(name, cfg, user_args, use_cmdline)
		if not spec.is_empty():
			result = merge(result, spec.get("visual", {}))
	return result


## light_grade's time overrides when on, else {} (the realm applies them with
## its own `apply_time_overrides`, after the light candidate).
static func light_overrides(cfg: Dictionary = {},
		user_args: PackedStringArray = PackedStringArray(), use_cmdline: bool = true) -> Dictionary:
	var spec := part("light_grade", cfg, user_args, use_cmdline)
	return spec.get("time_overrides", {}) as Dictionary if not spec.is_empty() else {}


## Retints the realm's plain stone materials (pale_strata).
static func apply_materials(materials: Dictionary, cfg: Dictionary = {},
		user_args: PackedStringArray = PackedStringArray(), use_cmdline: bool = true) -> int:
	var spec := part("pale_strata", cfg, user_args, use_cmdline)
	if spec.is_empty():
		return 0
	var touched := 0
	var tints: Dictionary = spec.get("materials", {})
	for key: Variant in tints:
		var material := materials.get(key) as BaseMaterial3D
		if material != null:
			material.albedo_color = Color(str(tints[key]))
			touched += 1
	return touched


## Whether the F26 course surface is on, and its knobs with pale_strata's
## overrides merged over art.json's `cloudreach_rock_surface`.
static func rock_surface(base: Dictionary, preset_enabled: bool) -> Dictionary:
	var spec := part("pale_strata")
	var result := base.duplicate(true)
	result["enabled"] = preset_enabled or not spec.is_empty()
	if not spec.is_empty():
		result.merge(spec.get("rock_surface", {}), true)
	return result


static func merge(base: Dictionary, overlay: Dictionary) -> Dictionary:
	var result := base.duplicate(true)
	for key: Variant in overlay:
		if str(key).begins_with("_"):
			continue
		if result.get(key) is Dictionary and overlay[key] is Dictionary:
			result[key] = merge(result[key], overlay[key])
		else:
			result[key] = overlay[key]
	return result


## cloud_sea: every settlement cloud-ring card whose footprint meets walkable
## ground moves out over open air and below its rim, or hides when no open
## air lies within reach. `ground_at` is (x, z) -> walkable height or NAN.
## Returns {"moved": n, "hidden": n}. Runs once after every builder.
static func reseat_cloud_cards(world: Node3D, ground_at: Callable, cfg: Dictionary = {},
		user_args: PackedStringArray = PackedStringArray(), use_cmdline: bool = true) -> Dictionary:
	var spec := part("cloud_sea", cfg, user_args, use_cmdline)
	var result := {"moved": 0, "hidden": 0}
	if spec.is_empty():
		return result
	var clear := float(spec.get("card_clear_m", 30.0))
	var step := maxf(5.0, float(spec.get("push_step_m", 40.0)))
	var max_push := float(spec.get("max_push_m", 640.0))
	var drop: Array = spec.get("drop_below_rim_m", [22.0, 60.0])
	for card: MeshInstance3D in cloud_cards(world):
		var width := (card.mesh as QuadMesh).size.x
		var at := card.global_position if card.is_inside_tree() else card.position
		var rim := footprint_ground(ground_at, at, width, at.y - width * 0.25 - clear, at.y + width * 0.25 + clear)
		if is_nan(rim):
			continue
		var centre: Variant = card.get_meta(&"cloud_ring_centre", null)
		var outward := Vector2(at.x, at.z) - (Vector2((centre as Vector3).x, (centre as Vector3).z) \
			if centre is Vector3 else Vector2.ZERO)
		outward = outward.normalized() if outward.length() > 0.01 else Vector2(0.0, 1.0)
		# Deterministic per card: its own position picks the drop.
		var t := fposmod(sin(at.x * 0.137 + at.z * 0.071) * 43758.5453, 1.0)
		var new_y := rim - lerpf(float(drop[0]), float(drop[1]), t) - width * 0.25
		var placed := false
		var distance := step
		while distance <= max_push:
			var probe := Vector3(at.x + outward.x * distance, new_y, at.z + outward.y * distance)
			# Open air: no walkable surface from the card's bottom-minus-clear up.
			if is_nan(footprint_ground(ground_at, probe, width, new_y - width * 0.25 - clear, INF)):
				_set_card_position(card, probe)
				placed = true
				break
			distance += step
		if placed:
			result.moved = int(result.moved) + 1
		else:
			card.visible = false
			result.hidden = int(result.hidden) + 1
	return result


## The highest walkable height under a card's footprint inside [low, high], or NAN.
static func footprint_ground(ground_at: Callable, at: Vector3, width: float, low: float, high: float) -> float:
	var best := NAN
	for offset: Vector2 in [Vector2.ZERO, Vector2(0.5, 0.0), Vector2(-0.5, 0.0), Vector2(0.0, 0.5),
			Vector2(0.0, -0.5), Vector2(0.25, 0.0), Vector2(-0.25, 0.0), Vector2(0.0, 0.25), Vector2(0.0, -0.25)]:
		var ground: Variant = ground_at.call(at.x + offset.x * width, at.z + offset.y * width)
		if ground == null:
			continue
		var g := float(ground)
		if is_finite(g) and g >= low and g <= high:
			best = g if is_nan(best) else maxf(best, g)
	return best


static func cloud_cards(world: Node) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	var stack: Array[Node] = [world]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		for child: Node in node.get_children():
			stack.append(child)
		var card := node as MeshInstance3D
		if card == null or not (card.mesh is QuadMesh) or not card.visible:
			continue
		var material := card.material_override as StandardMaterial3D
		if material == null or material.albedo_texture == null \
				or material.albedo_texture.resource_path != CLOUD_CARD_TEXTURE:
			continue
		out.append(card)
	return out


static func _set_card_position(card: Node3D, world_position: Vector3) -> void:
	if card.is_inside_tree():
		card.global_position = world_position
	else:
		card.position = world_position
