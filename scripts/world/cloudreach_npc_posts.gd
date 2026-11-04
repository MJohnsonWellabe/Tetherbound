extends RefCounted

## P2-068 / F40#9 (VIS-CLOUDREACH lane, 4 Nov 2026). GPU item score 31 Oct,
## 5.50 mapped: "The named NPCs are tiny mid-ground figures beside the trainer,
## half lost in tall grass (Tavi frame), shadow (Sora frame) and the tree
## trunks (keeper frame), with no post props or poses to say who they are."
##
## `cloudreach_npc_runtime.json::post_readability` (off unless `enabled`, or
## the capture flag `--cloudreach-npc-posts-candidate`):
##   1. Ground cover (grass, flowers, bushes) is kept off a disc around every
##      position a named NPC can stand at (authored, override and every
##      `position_when` branch, so the set never depends on flags and every
##      peer builds the same cover).
##   2. Each standing NPC body gets a soft, shadowless warm fill light at chest
##      height so a post in tree or cliff shadow still reads.
## Presentation only: no collider, route, save, RPC or dialogue change.

const NPC_PATH := "res://data/config/cloudreach_npc_runtime.json"
const CHAPTER_PATH := "res://data/config/cloudreach_chapter.json"
const PHYSICAL_PATH := "res://data/config/cloudreach_physical_runtime.json"
const CANDIDATE_ARG := "--cloudreach-npc-posts-candidate"
const LIGHT_NAME := "PostFillLight"


static func _read(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


static func spec(npc_runtime: Dictionary = {}, user_args: PackedStringArray = PackedStringArray(),
		use_cmdline: bool = true) -> Dictionary:
	var runtime := npc_runtime if not npc_runtime.is_empty() else _read(NPC_PATH)
	var raw: Variant = runtime.get("post_readability", {})
	var cfg: Dictionary = raw if raw is Dictionary else {}
	var args := user_args
	if use_cmdline and args.is_empty():
		args = OS.get_cmdline_user_args()
	if cfg.get("enabled") == true or args.has(CANDIDATE_ARG):
		return cfg
	return {}


## Every position a named NPC can be placed at, as Vector3.
static func post_positions(chapter: Dictionary, npc_runtime: Dictionary, physical: Dictionary) -> Array[Vector3]:
	var out: Array[Vector3] = []
	var overrides: Dictionary = physical.get("npc_position_overrides", {})
	for placement: Dictionary in npc_runtime.get("npcs", []):
		var id := str(placement.get("id", ""))
		var raw: Array = []
		for authored: Dictionary in chapter.get("npcs", []):
			if str(authored.get("id", "")) == id and authored.has("position"):
				raw.append(authored["position"])
		if placement.has("position"):
			raw.append(placement["position"])
		if overrides.has(id):
			raw.append(overrides[id])
		for branch: Dictionary in placement.get("position_when", []):
			if branch.has("position"):
				raw.append(branch["position"])
		for value: Variant in raw:
			if value is Array and (value as Array).size() >= 3:
				var at := Vector3(float(value[0]), float(value[1]), float(value[2]))
				if not out.has(at):
					out.append(at)
	return out


## Ground-cover exclusions (cloudreach_ground_cover.gd ellipse form) for the
## posts, or [] when the part is off.
static func cover_exclusions(cfg: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if cfg.is_empty():
		return out
	var radius := float(cfg.get("clear_radius_m", 3.2))
	for at: Vector3 in post_positions(_read(CHAPTER_PATH), _read(NPC_PATH), _read(PHYSICAL_PATH)):
		out.append({"kind": "ellipse", "centre": at, "half": Vector2(radius, radius), "rotation": 0.0})
	return out


## A soft fill light on each NPC body under `people`; idempotent.
static func light_people(people: Node, cfg: Dictionary) -> int:
	if cfg.is_empty() or people == null:
		return 0
	var light_cfg: Dictionary = cfg.get("fill_light", {})
	if light_cfg.get("enabled", true) != true:
		return 0
	var count := 0
	for body: Node in people.get_children():
		if not body is Node3D or body.get_node_or_null(NodePath(LIGHT_NAME)) != null:
			continue
		var light := OmniLight3D.new()
		light.name = LIGHT_NAME
		light.light_color = Color(str(light_cfg.get("colour", "#ffe2b8")))
		light.light_energy = float(light_cfg.get("energy", 0.7))
		light.omni_range = float(light_cfg.get("range_m", 4.5))
		light.omni_attenuation = float(light_cfg.get("attenuation", 1.2))
		light.shadow_enabled = false
		light.light_specular = 0.2
		var offset: Array = light_cfg.get("offset", [0.0, 1.6, 1.2])
		light.position = Vector3(float(offset[0]), float(offset[1]), float(offset[2]))
		body.add_child(light)
		count += 1
	return count


## P2-068 / F40#9 round 2 (NEAR6-CR, 4 Nov 2026): `post_role_props` (OFF
## until judged). Judges asked for "a role prop ... that says who they are":
## installed-family props (Quaternius fantasy set) stand beside each named
## post, in the NPC's own facing frame and mostly to its sides so they never
## stand between an approaching trainer and the NPC. Each prop is seated on
## the ground via `ground` (world xz -> resolved Vector3). Visual only: no
## collider, prompt, route or save change. Returns the number placed.
const BOUNDS := preload("res://scripts/world/building_prefabs.gd")
const ROLE_PROPS_NAME := "NpcRoleProps"


static func role_props_spec(npc_runtime: Dictionary = {}) -> Dictionary:
	var runtime := npc_runtime if not npc_runtime.is_empty() else _read(NPC_PATH)
	var raw: Variant = runtime.get("post_role_props", {})
	return raw if raw is Dictionary and (raw as Dictionary).get("enabled") == true else {}


static func place_role_props(parent: Node3D, specs: Array, positions: Dictionary, cfg: Dictionary,
		ground: Callable) -> int:
	var old := parent.get_node_or_null(NodePath(ROLE_PROPS_NAME))
	if old != null:
		parent.remove_child(old)
		old.queue_free()
	if cfg.is_empty():
		return 0
	var root := Node3D.new()
	root.name = ROLE_PROPS_NAME
	parent.add_child(root)
	var sets: Dictionary = cfg.get("posts", {})
	var count := 0
	for spec: Dictionary in specs:
		var id := str(spec.get("id", ""))
		if not sets.has(id) or not positions.has(id):
			continue
		var p: Array = positions[id]
		var at := Vector3(float(p[0]), float(p[1]), float(p[2]))
		var yaw := deg_to_rad(float(spec.get("facing_deg", 0.0)))
		var frame := Basis(Vector3.UP, yaw)
		for prop: Dictionary in sets[id]:
			var path := str(prop.get("scene", ""))
			if not ResourceLoader.exists(path):
				continue
			var scene := load(path) as PackedScene
			if scene == null:
				continue
			var o: Array = prop.get("offset", [1.6, 0.0, 0.0])
			var spot := at + frame * Vector3(float(o[0]), 0.0, float(o[2]))
			var seated: Vector3 = ground.call(spot) if ground.is_valid() else spot
			if not seated.is_finite() or absf(seated.y - at.y) > float(cfg.get("max_step_m", 1.5)):
				continue
			var model := scene.instantiate() as Node3D
			var bounds: AABB = BOUNDS.new().combined_aabb(model)
			var factor := float(prop.get("height_m", 1.0)) / maxf(bounds.size.y, 0.01)
			var anchor := Node3D.new()
			anchor.name = "%s_%s" % [id, path.get_file().get_basename()]
			anchor.position = seated + Vector3.UP * float(o[1])
			anchor.rotation.y = yaw + deg_to_rad(float(prop.get("yaw_deg", 0.0)))
			root.add_child(anchor)
			model.scale = Vector3.ONE * factor
			model.position = -Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z) * factor
			anchor.add_child(model)
			count += 1
	return count


## P2-068 / F40#9 round 3 (NEAR6-CR, 4 Nov 2026): `post_dais` (OFF until
## judged). Judges keep reading the named NPCs as small figures behind the
## trainer. When on, each listed post gets a low weathered-stone dais with
## collision and the NPC stands on it, so the figure rises above the trainer's
## shoulder line from the approach. The prompt, dialogue and save are unchanged.
const DAIS_NAME := "NpcPostDais"


static func dais_spec(npc_runtime: Dictionary = {}) -> Dictionary:
	var runtime := npc_runtime if not npc_runtime.is_empty() else _read(NPC_PATH)
	var raw: Variant = runtime.get("post_dais", {})
	return raw if raw is Dictionary and (raw as Dictionary).get("enabled") == true else {}


static func build_dais(parent: Node3D, positions: Dictionary, cfg: Dictionary) -> int:
	var old := parent.get_node_or_null(NodePath(DAIS_NAME))
	if old != null:
		parent.remove_child(old)
		old.queue_free()
	if cfg.is_empty():
		return 0
	var root := Node3D.new()
	root.name = DAIS_NAME
	parent.add_child(root)
	var height := float(cfg.get("height_m", 0.45))
	var sink := float(cfg.get("sink_m", 0.35))
	var radius := float(cfg.get("radius_m", 1.15))
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(str(cfg.get("colour", "#a9a491")))
	material.roughness = 0.95
	var count := 0
	for id: String in cfg.get("posts", []):
		if not positions.has(id):
			continue
		var p: Array = positions[id]
		var top := Vector3(float(p[0]), float(p[1]), float(p[2]))
		var mesh := CylinderMesh.new()
		mesh.top_radius = radius
		mesh.bottom_radius = radius * 1.12
		mesh.height = height + sink
		mesh.radial_segments = 10
		var body := StaticBody3D.new()
		body.name = "Dais_%s" % id
		body.position = top - Vector3.UP * (height + sink) * 0.5
		root.add_child(body)
		var visual := MeshInstance3D.new()
		visual.mesh = mesh
		visual.material_override = material
		body.add_child(visual)
		var shape := CollisionShape3D.new()
		var cylinder := CylinderShape3D.new()
		cylinder.radius = radius
		cylinder.height = height + sink
		shape.shape = cylinder
		body.add_child(shape)
		count += 1
	return count
