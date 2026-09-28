extends Node3D

## F13#5: people at every mandatory Tidewake dock, so each reads as a lived
## destination (ART_DIRECTION Tidewake). Config: data/config/water_dock_residents.json.
## Presentation only, like WaterDockDressing beside it: installed humanoid
## bodies standing idle on land by the cargo, no prompt, no dialogue, no
## collider and no state. Every peer builds the same people from data; a
## simulation shell builds none.

const CONFIG_PATH := "res://data/config/water_dock_residents.json"
const NPC := preload("res://scripts/npc/npc_body.gd")

var _built := false


func build(water_world: Node3D) -> void:
	if _built:
		return
	_built = true
	if bool(water_world.get("simulation_only")):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	if not parsed is Dictionary:
		push_error("water dock residents config is invalid")
		return
	var cfg := parsed as Dictionary
	var world_cfg: Dictionary = water_world.get("config")
	var anchors := {}
	for anchor: Variant in world_cfg.get("anchors", []):
		anchors[str((anchor as Dictionary).get("id", ""))] = anchor
	var ramps := {}
	for shortcut: Variant in world_cfg.get("return_shortcuts", []):
		if str((shortcut as Dictionary).get("kind", "")) == "physical_ramp":
			ramps[str((shortcut as Dictionary).get("to_anchor", ""))] = shortcut
	var dressing: Node = water_world.get_node_or_null("WaterDockDressing")
	var player: Node3D = water_world.call("local_rig") if water_world.has_method("local_rig") else null
	var profiles: Array = cfg.get("profiles", [])
	var dock_index := 0
	for raw: Variant in world_cfg.get("docks", []):
		var dock := raw as Dictionary
		if bool(cfg.get("mandatory_only", true)) and not bool(dock.get("mandatory", false)):
			continue
		var anchor_id := str(dock.get("departure_anchor", ""))
		var anchor: Dictionary = anchors.get(anchor_id, {})
		var sign := 1.0
		if dressing != null and dressing.has_method("_side_away_from"):
			sign = float(dressing.call("_side_away_from", anchor, ramps.get(anchor_id, {})))
		var spots := spots_for(anchor, sign, cfg)
		for index in spots.size():
			var spot: Dictionary = spots[index]
			var at: Vector2 = spot.at
			var ground := float(water_world.call("ground_height_at", at.x, at.y))
			if not is_finite(ground) or ground < float(cfg.get("min_ground_y_m", 0.4)):
				continue
			var profile := str(profiles[(dock_index * spots.size() + index) % profiles.size()]) \
				if not profiles.is_empty() else ""
			var body: Node3D = NPC.new()
			body.name = "%s_resident_%d" % [str(dock.get("id", "dock")), index]
			body.set_meta("water_dock_resident", str(dock.get("id", "")))
			add_child(body)
			if not body.call("setup", profile, player):
				body.queue_free()
				continue
			# Presentation only: nothing on a dock approach may block a walk.
			var collider: Node = body.get_node_or_null("Body")
			if collider != null:
				collider.queue_free()
			body.global_position = Vector3(at.x, ground, at.y)
			body.rotation.y = float(spot.yaw)
		dock_index += 1


## Where this dock's residents stand and which way they face, in world XZ.
## `sign` is the side the dock dressing's pier and cargo stand on.
static func spots_for(anchor: Dictionary, sign: float, cfg: Dictionary) -> Array:
	var out: Array = []
	var safe_raw: Array = anchor.get("safe_position", [])
	var shore_raw: Array = anchor.get("shore_position", [])
	if safe_raw.size() < 3 or shore_raw.size() < 3:
		return out
	var safe := Vector2(float(safe_raw[0]), float(safe_raw[2]))
	var shore := Vector2(float(shore_raw[0]), float(shore_raw[2]))
	var forward := (shore - safe).normalized()
	if forward.length() < 0.5:
		return out
	var side := Vector2(-forward.y, forward.x) * sign
	var pier_head := shore + side * 4.0
	for raw: Variant in cfg.get("spots", []):
		var spec := raw as Dictionary
		var at := safe + side * float(spec.get("side_m", 0.0)) - forward * float(spec.get("back_m", 0.0))
		var look := pier_head - at if str(spec.get("face", "water")) == "pier" else forward
		out.append({"at": at, "yaw": atan2(look.x, look.y), "lane_offset_m": absf((at - safe).dot(side))})
	return out
