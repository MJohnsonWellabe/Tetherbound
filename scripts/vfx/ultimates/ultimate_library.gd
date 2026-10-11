extends RefCounted

## Local presentation adapter for an already accepted F23 action. Combat must
## freeze MoveMastery metadata and compare it to its current actor registry.
## No caller of this library can earn a hit, mastery, meter or control lease.
const CONFIG_PATH := "res://data/moves/ultimates.json"
const EFFECT := preload("res://scripts/vfx/ultimates/ultimate_effect.gd")
const MOVE_LIBRARY := preload("res://scripts/vfx/move_effect_library.gd")
static var _config: Dictionary = {}

static func config() -> Dictionary:
	return _cached_config().duplicate(true)

## Internal readers borrow the catalogue; only resolved rows and presentation
## settings are copied at launch. Public callers still receive a detached copy.
static func _cached_config() -> Dictionary:
	if _config.is_empty():
		var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
		if raw is Dictionary: _config = raw
	return _config

## The host checks this same presentation gate before it spends a meter.
static func available(move_id: String) -> bool:
	var data := _cached_config()
	return bool(data.get("enabled", false)) and (data.get("visuals", {}) as Dictionary).has(move_id)

static func resolve(move_id: String, breakthroughs: int) -> Dictionary:
	var data := _cached_config()
	var rows: Dictionary = data.get("visuals", {})
	var growth: Array = data.get("breakthrough_visuals", [])
	if not rows.has(move_id) or breakthroughs < 0 or breakthroughs >= growth.size(): return {}
	var row: Dictionary = rows[move_id].duplicate(true)
	var geometry: Dictionary = data.get("geometry_defaults", {}).duplicate(true)
	geometry.merge(row.get("visual", {}), true)
	row["visual"] = geometry
	row["growth"] = growth[breakthroughs].duplicate(true)
	return row

static func same_binding(frozen: Dictionary, current: Dictionary) -> bool:
	for key: String in ["character_id", "creature_uid", "encounter_id", "generation", "action"]:
		if not frozen.has(key) or frozen[key] != current.get(key): return false
	return not str(frozen.character_id).is_empty() and not str(frozen.creature_uid).is_empty() \
		and not str(frozen.encounter_id).is_empty() and _whole(frozen.generation, 1, 2147483647) \
		and _whole(frozen.action, 1, 2147483647)

static func _whole(value: Variant, low: int, high: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) \
		and floor(float(value)) == float(value) and float(value) >= low and float(value) <= high

static func launch(parent: Node, from: Vector3, to: Vector3, spec: Dictionary,
		context: Dictionary = {}) -> Node3D:
	var data := _cached_config()
	if parent == null or not parent.is_inside_tree() or not bool(data.get("enabled", false)): return null
	if not from.is_finite() or not to.is_finite() or str(spec.get("slot", "")) != "ultimate": return null
	var binding: Variant = spec.get("actor_binding")
	var current: Variant = context.get("current_actor")
	if not binding is Dictionary or not current is Dictionary or not same_binding(binding, current): return null
	if bool(current.get("fainted", false)): return null
	var action := str(spec.get("action_id", ""))
	if action.is_empty() or action.length() > 256: return null
	var rank: Variant = spec.get("mastery_rank")
	var count: Variant = spec.get("breakthrough_count")
	if not _whole(rank, 1, 5) or not _whole(count, 0, 5): return null
	var signature: Variant = spec.get("ultimate")
	if not signature is Dictionary: return null
	var duration: Variant = signature.get("presentation_seconds")
	var travel: Variant = context.get("travel_seconds")
	if not (duration is int or duration is float) or not (travel is int or travel is float): return null
	if not is_finite(float(duration)) or not is_finite(float(travel)) \
			or float(duration) < 2.0 or float(duration) > 3.0 or float(travel) < 0.0 or float(travel) >= float(duration): return null
	var recipient := str(context.get("recipient_character_id", ""))
	if recipient.is_empty(): return null
	var source_ground: Variant = context.get("source_ground")
	var target_ground: Variant = context.get("target_ground")
	if not source_ground is Vector3 or not target_ground is Vector3: return null
	if not source_ground.is_finite() or not target_ground.is_finite(): return null
	var row := resolve(str(spec.get("move_id", "")), int(count))
	if row.is_empty(): return null
	# Values only; never retain an authority node or portable creature object.
	var frozen := {"action_id": action, "actor_binding": binding.duplicate(true),
		"encounter_id": str(binding.encounter_id), "mastery_rank": int(rank),
		"breakthrough_count": int(count), "seed": action.sha256_text().left(8).hex_to_int(),
		"travel_seconds": float(travel), "duration_seconds": float(duration),
		"source_ground": source_ground, "target_ground": target_ground,
		"recipient_character_id": recipient, "peer_view": recipient != str(binding.character_id)}
	# Keep measured surface contact for staged signatures too. Copy only the
	# finite vectors; never retain a target body or other caller-owned values.
	var bounds: Variant = context.get("target_visual_bounds", {})
	if bounds is Dictionary:
		var position: Variant = bounds.get("position")
		var size: Variant = bounds.get("size")
		if position is Vector3 and size is Vector3 and position.is_finite() and size.is_finite() \
				and size.x > 0.0 and size.y > 0.0 and size.z > 0.0:
			var surface := {"position": position, "size": size}
			surface.make_read_only()
			frozen["target_visual_bounds"] = surface
	for value: Variant in frozen.actor_binding.values():
		if value is Object or value is Dictionary or value is Array: return null
	frozen.actor_binding.make_read_only()
	frozen.make_read_only()
	# Suppress duplicate local drawings without a durable receipt journal.
	for node: Node in parent.get_tree().get_nodes_in_group("move_effect_presentation"):
		if is_instance_valid(node) and not node.is_queued_for_deletion() and node.has_method("action_id") \
				and str(node.call("action_id")) == action: return null
	var override := MOVE_LIBRARY.ultimate_override(str(spec.get("move_id", "")))
	if not override.is_empty():
		# Owner direction: some signatures draw as the move library's staged
		# effect (a wave, a water ball). Earned mastery and breakthroughs grow
		# independently; a breakthrough cannot replace the accepted rank.
		var staged := frozen.duplicate(true)
		staged["breakthrough_growth"] = row.growth.duplicate(true)
		staged["ultimate"] = true
		staged["impact_audio_owner"] = "receipt"
		staged["peer_presentation"] = data.get("peer", {}).duplicate(true)
		staged["ultimate_launch"] = row.get("launch", {}).duplicate(true)
		return MOVE_LIBRARY.launch_presentation(parent, from, to, override, staged)
	var effect := EFFECT.new()
	effect.configure(from, to, row, frozen, data)
	parent.add_child(effect)
	return effect

static func cancel_action(tree: SceneTree, action_id: String) -> void:
	if tree == null or action_id.is_empty(): return
	for effect: Node in tree.get_nodes_in_group("ultimate_presentation"):
		if effect.has_method("action_id") and str(effect.call("action_id")) == action_id:
			effect.call("cancel_presentation")

static func cancel_encounter(tree: SceneTree, encounter_id: String) -> void:
	if tree == null or encounter_id.is_empty(): return
	for effect: Node in tree.get_nodes_in_group("ultimate_presentation"):
		if effect.has_method("encounter_id") and str(effect.call("encounter_id")) == encounter_id:
			effect.call("cancel_presentation")
