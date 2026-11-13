extends RefCounted

## F41#8 (LANE-BELOW6, 12 Nov 2026; `named_posts_1112` in
## stormwood_character_presentation.json, OFF until GPU-judged). Judges 3/3 on
## the named villagers (Elder Maud, Rodkeeper Hesk, Warden-elect Bryn): the
## road under them is "a near-black slab" and "the characters' feet vanish into
## it"; the figures are small and read alike at normal distance. The road is
## LANE-PLACES'. This is the character side: each named villager keeps a storm
## lantern at their post (the installed lantern-pool post), a step behind and
## to one side, whose warm light pools on the ground at their feet and keys the
## figure from the side. Visual only: no collider, no position, dialogue or
## progression change.
const CONFIG := "res://data/config/stormwood_character_presentation.json"
const LANTERN_POOLS := preload("res://scripts/world/stormwood_lantern_pools.gd")
const POOLS_CONFIG := "res://data/config/stormwood_lantern_pools.json"


static func settings() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	var cfg: Variant = (parsed as Dictionary).get("named_posts_1112", {}) if parsed is Dictionary else {}
	return cfg if cfg is Dictionary and bool((cfg as Dictionary).get("enabled", false)) else {}


## Where the lantern stands for a villager at `at` facing `facing` (unit, XZ).
static func post_position(at: Vector3, facing: Vector3, cfg: Dictionary) -> Vector3:
	var flat := Vector3(facing.x, 0.0, facing.z)
	flat = flat.normalized() if flat.length() > 0.001 else Vector3.BACK
	var right := Vector3.UP.cross(flat).normalized()
	var offset: Array = cfg.get("offset_m", [1.5, -1.1])
	return at + right * float(offset[0]) + flat * float(offset[1])


static func attach(world: Node3D, people: Node, actors: Array) -> int:
	var cfg := settings()
	if cfg.is_empty() or world == null or people == null:
		return 0
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(POOLS_CONFIG))
	var pools: Dictionary = parsed if parsed is Dictionary else {}
	var hero: Dictionary = pools.get("lantern_model", {})
	var light := {"light_colour": str(cfg.get("light_colour", "#ffc77a")),
		"light_energy": float(cfg.get("light_energy", 2.2)), "light_range_m": float(cfg.get("light_range_m", 8.0))}
	var ids: Array = cfg.get("ids", [])
	var count := 0
	for actor: Variant in actors:
		if not actor is Dictionary or str((actor as Dictionary).get("id", "")) not in ids:
			continue
		var body := people.get_node_or_null(NodePath(str((actor as Dictionary).get("name", "")))) as Node3D
		if body == null:
			continue
		var holder := Node3D.new()
		holder.name = "NamedPostLantern_%s" % str((actor as Dictionary).id)
		world.add_child(holder)
		var at := post_position(body.global_position, body.global_transform.basis.z, cfg)
		if world.has_method("ground_height_at"):
			at.y = float(world.call("ground_height_at", at.x, at.z))
		holder.global_position = at
		if LANTERN_POOLS._hero_lantern(holder, hero, light):
			count += 1
		else:
			holder.queue_free()
	return count
