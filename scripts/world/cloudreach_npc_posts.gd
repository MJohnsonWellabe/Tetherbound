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
