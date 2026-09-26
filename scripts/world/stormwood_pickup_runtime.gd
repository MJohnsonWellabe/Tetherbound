extends Node3D

## Stormwood's catalogue adapter.  It intentionally owns no pickup mechanics:
## each ordinary row becomes the established ItemCachePickup, which submits its
## stable realm-qualified cache flag to the host-led world ledger.  The
## catalogue's story_reward rows are events, not loose props, and rows without
## an installed item definition remain absent until their owning item lane adds
## one.

const CACHE := preload("res://scripts/world/item_cache_pickup.gd")
const POCKETS := preload("res://scripts/world/stormwood_pockets.gd")

const REALM_ID := "stormwood"
const DATA_PATH := "res://data/config/stormwood_pickups.json"
const ITEM_DATA_PATH := "res://data/items/items.json"

## These six ordinary Stormwood rewards already have item definitions but no
## `world_model` metadata. Reuse the installed pickup art instead of asking
## ItemCachePickup to stand its warning-box fallback. This maps presentation
## only; grants remain the catalogue's exact item ids.
const PRESENTATION_FALLBACKS := {
	"orb_basic": {"model": "res://assets/props/tm_orb/tm_orb.glb", "scale": 0.13},
	"orb_greater": {"model": "res://assets/props/tm_orb/tm_orb.glb", "scale": 0.13},
	"orb_prime": {"model": "res://assets/props/tm_orb/tm_orb.glb", "scale": 0.13},
	"swift_tonic": {"model": "res://assets/props/potion_plant/potion_plant.glb", "scale": 0.35},
	"attack_tonic": {"model": "res://assets/props/potion_plant/potion_plant.glb", "scale": 0.35},
	"stoneguard_brew": {"model": "res://assets/props/potion_plant/potion_plant.glb", "scale": 0.35},
}

var world: Node3D
var _game: Node
var _flags: RefCounted
var _placements: Dictionary = {}
var _pocket_by_reward: Dictionary = {}
var _revision := -1

func _process(_delta: float) -> void:
	if _flags != null and int(_flags.get("revision")) != _revision:
		_revision = int(_flags.get("revision"))
		sync_progression()


static func read(path: String = DATA_PATH) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


static func item_definitions() -> Dictionary:
	return read(ITEM_DATA_PATH).get("items", {}) as Dictionary


## Only an ordinary catalogue record with a current item definition may become
## a world pickup.  `story_reward` is deliberately excluded even when its
## eventual item exists: awarding it belongs to its successful story event.
static func can_mount(spec: Dictionary, definitions: Dictionary = {}) -> bool:
	if str(spec.get("runtime_kind", "")) != "item":
		return false
	var item_id := str(spec.get("item_id", ""))
	var id := str(spec.get("id", ""))
	var source := item_definitions() if definitions.is_empty() else definitions
	return not id.is_empty() and not item_id.is_empty() and source.has(item_id)


static func ordinary_specs() -> Array[Dictionary]:
	var definitions := item_definitions()
	var out: Array[Dictionary] = []
	for raw: Variant in (read().get("pickups", []) as Array):
		if raw is Dictionary and can_mount(raw as Dictionary, definitions):
			out.append((raw as Dictionary).duplicate(true))
	return out


static func withheld_specs() -> Array[Dictionary]:
	var definitions := item_definitions()
	var out: Array[Dictionary] = []
	for raw: Variant in (read().get("pickups", []) as Array):
		if raw is Dictionary and not can_mount(raw as Dictionary, definitions):
			out.append((raw as Dictionary).duplicate(true))
	return out


static func presentation_for(item_id: String, definition: Dictionary) -> Dictionary:
	var model := str(definition.get("world_model", ""))
	if not model.is_empty():
		return {"model": model, "scale": float(definition.get("world_model_scale", 1.0))}
	return (PRESENTATION_FALLBACKS.get(item_id, {}) as Dictionary).duplicate(true)


func mount(owner_world: Node3D) -> void:
	world = owner_world
	_game = get_node_or_null(^"/root/Game")
	_flags = _game.get("progression") if _game != null else null
	add_to_group("progression_restore")
	sync_progression()


func restore_progression_from_game(game: Node) -> void:
	_game = game
	_flags = game.get("progression") if game != null else null
	for candidate: Variant in _placements.values():
		if is_instance_valid(candidate):
			(candidate as Node).queue_free()
	_placements.clear()
	sync_progression()


func sync_progression() -> void:
	if _game == null or _flags == null:
		return
	for spec: Dictionary in ordinary_specs():
		var id := str(spec["id"])
		var unlock := str(spec.get("requires_unlock", ""))
		if (not unlock.is_empty() and not bool(_flags.call("has", unlock))) \
				or CACHE.was_taken(_game, str(spec["item_id"]), id, REALM_ID):
			continue
		if _placements.has(id) and is_instance_valid(_placements[id]):
			continue
		_mount_pickup(spec)


func _mount_pickup(spec: Dictionary) -> void:
	var id := str(spec["id"])
	var item_id := str(spec["item_id"])
	var position: Array = spec.get("position", []) as Array
	if position.size() != 3:
		return
	var definition: Dictionary = _game.get("items").call("definition", item_id)
	if definition.is_empty():
		return
	var pickup := CACHE.new()
	pickup.name = id
	add_child(pickup)
	pickup.global_position = Vector3(float(position[0]), float(position[1]), float(position[2]))
	var presentation := presentation_for(item_id, definition)
	var pocket := _pocket_rewards().get(id, {}) as Dictionary
	var beacon: Dictionary = POCKETS.config().get("reward_beacon", {}) if not pocket.is_empty() else {}
	var scale := float(presentation.get("scale", 1.0)) * float(beacon.get("model_scale_mul", 1.0))
	pickup.setup(item_id, "Take " + str(definition.get("name", item_id)),
		str(presentation.get("model", "")), scale,
		id, REALM_ID, int(spec.get("count", 1)))
	if not beacon.is_empty() and world.get("simulation_only") != true:
		_reward_beacon(pickup, beacon, pocket)
	_placements[id] = pickup


## pickup id -> its pocket (stormwood_pockets.json), for the pocket rewards.
func _pocket_rewards() -> Dictionary:
	if _pocket_by_reward.is_empty():
		for pocket: Dictionary in POCKETS.config().get("pockets", []):
			_pocket_by_reward[str(pocket.get("reward_pickup_id", ""))] = pocket
	return _pocket_by_reward


## WO-F09-05 round 2: a pocket reward reads from its gate: a warm light pool
## and an additive glow billboard in the pocket's lamp tint, both children of
## the pickup so they leave with it when it is claimed.
func _reward_beacon(pickup: Node3D, beacon: Dictionary, pocket: Dictionary) -> void:
	var style := POCKETS.tinted(POCKETS.config().get("mouth_lure", {}), pocket)
	var colour := Color(str(style.get("flame_emission", "#ffb347")))
	var light := OmniLight3D.new()
	light.name = "RewardLightPool"
	light.position = Vector3(0.0, float(beacon.light_height_m), 0.0)
	light.light_color = Color(str(style.get("light_colour", "#ffb15c")))
	light.light_energy = float(beacon.light_energy)
	light.omni_range = float(beacon.light_range_m)
	light.shadow_enabled = false
	pickup.add_child(light)
	var gradient := Gradient.new()
	gradient.set_color(0, Color(colour, float(beacon.halo_alpha)))
	gradient.set_color(1, Color(colour, 0.0))
	var ramp := GradientTexture2D.new()
	ramp.gradient = gradient
	ramp.fill = GradientTexture2D.FILL_RADIAL
	ramp.fill_from = Vector2(0.5, 0.5)
	ramp.fill_to = Vector2(1.0, 0.5)
	ramp.width = 64
	ramp.height = 64
	var halo_material := StandardMaterial3D.new()
	halo_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	halo_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	halo_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	halo_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	halo_material.albedo_texture = ramp
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE * float(beacon.halo_radius_m) * 2.0
	var halo := MeshInstance3D.new()
	halo.name = "RewardGlow"
	halo.mesh = quad
	halo.material_override = halo_material
	halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	halo.position = Vector3(0.0, float(beacon.halo_height_m), 0.0)
	pickup.add_child(halo)
	# WO-F09-05 round 5 (blind judge 12: "from the road you never see the
	# reward"): a soft light shaft in the pocket's tint rises over the reward,
	# and a shorter one rises from the pocket's gateway at the fork, which is
	# what the road view can actually frame (the rewards sit 78-85 deg off the
	# road heading from the approach stands). Both are children of the pickup,
	# the gateway one top_level at the gate, so both exist only while the
	# reward is unclaimed and leave with it. Static: no animation.
	var shaft: Dictionary = (beacon.get("shaft", {}) as Dictionary).duplicate(true)
	shaft.merge(pocket.get("shaft", {}), true)
	if shaft.is_empty():
		return
	var material := shaft_material(colour, float(shaft.alpha))
	pickup.add_child(_shaft("RewardShaft", material, float(shaft.reward_height_m), float(shaft.reward_width_m),
		pickup.global_position))
	var gate: Dictionary = POCKETS.gateway(pocket, POCKETS.config())
	if not gate.is_empty():
		var lane := POCKETS.spur(pocket)
		var junction := Vector2(float(lane.points[0][0]), float(lane.points[0][1]))
		var up := (Vector2(float(lane.points[1][0]), float(lane.points[1][1])) - junction).normalized()
		var at := junction + up * float(gate.along)
		var ground := float(world.call("ground_height_at", at.x, at.y)) if world.has_method("ground_height_at") else pickup.global_position.y
		var gate_shaft := _shaft("GateShaft", material, float(shaft.gate_height_m), float(shaft.gate_width_m),
			Vector3(at.x, ground, at.y))
		pickup.add_child(gate_shaft)


const SHAFT_SHADER := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
uniform vec4 tint : source_color = vec4(1.0);
uniform float alpha = 0.4;
void vertex() {
	// Billboard about the vertical axis only (a column that always faces the
	// camera but stays upright), as BaseMaterial3D's BILLBOARD_FIXED_Y.
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
		vec4(normalize(cross(vec3(0.0, 1.0, 0.0), INV_VIEW_MATRIX[2].xyz)) * length(MODEL_MATRIX[0].xyz), 0.0),
		vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
		vec4(normalize(cross(INV_VIEW_MATRIX[0].xyz, vec3(0.0, 1.0, 0.0))) * length(MODEL_MATRIX[2].xyz), 0.0),
		MODEL_MATRIX[3]);
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}
void fragment() {
	// Soft across (no hard edges), brightest at the foot, fading to nothing
	// toward the top.
	float across = 1.0 - smoothstep(0.0, 0.5, abs(UV.x - 0.5));
	float up = 1.0 - UV.y;
	float along = smoothstep(0.0, 0.08, up) * (1.0 - smoothstep(0.25, 1.0, up));
	ALBEDO = tint.rgb * alpha * across * across * along;
}
"""


static func shaft_material(colour: Color, alpha: float) -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = SHAFT_SHADER
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("tint", colour)
	material.set_shader_parameter("alpha", alpha)
	return material


## A billboard column `height` x `width`, its foot at global `foot`.
func _shaft(shaft_name: String, material: Material, height: float, width: float, foot: Vector3) -> MeshInstance3D:
	var quad := QuadMesh.new()
	quad.size = Vector2(width, height)
	quad.center_offset = Vector3(0.0, height * 0.5, 0.0)
	var node := MeshInstance3D.new()
	node.name = shaft_name
	node.mesh = quad
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.top_level = true
	node.position = foot
	node.extra_cull_margin = height
	return node
