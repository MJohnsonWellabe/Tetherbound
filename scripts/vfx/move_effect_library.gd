extends RefCounted

## Presentation only. The immutable host receipt owns hit timing and results.
const CONFIG_PATH := "res://data/config/vfx.json"
const EFFECT := preload("res://scripts/vfx/move_effect.gd")
const CONTRACT := preload("res://scripts/vfx/move_presentation_contract.gd")

static var _config: Dictionary = {}

static func config() -> Dictionary:
	if _config.is_empty():
		var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
		if raw is Dictionary: _config = raw
	return _config.get("move_library", {}) as Dictionary

static func resolve(spec: Dictionary, mastery_rank: int = 1) -> Dictionary:
	var library := config()
	var archetypes: Dictionary = library.get("archetypes", {})
	var id := str(spec.get("archetype", ""))
	if not archetypes.has(id): return {}
	var resolved: Dictionary = archetypes[id].duplicate(true)
	if spec.has("body_variant"):
		var variants: Dictionary = resolved.get("body_variants", {})
		if not variants.has(str(spec.body_variant)): return {}
		resolved["body"] = variants[str(spec.body_variant)].duplicate(true)
	if spec.has("presentation_variant"):
		# A presentation variant deep-merges authored body/trail/impact/launch
		# overrides over the archetype (e.g. a water ball built on the water
		# projectile). Timing, arrival and budgets keep their archetype rules.
		var named: Dictionary = resolved.get("presentation_variants", {})
		if not named.has(str(spec.presentation_variant)): return {}
		_deep_merge(resolved, named[str(spec.presentation_variant)])
	var params: Dictionary = resolved.get("parameters", {}).duplicate(true)
	for key: String in ["count", "size", "colour", "arc", "speed", "spread", "trail", "impact_scale"]:
		if spec.has(key): params[key] = spec[key]
	var rank := clampi(mastery_rank, 1, 5)
	var tiers: Array = resolved.get("mastery", [])
	if tiers.size() != 5: return {}
	var tier: Dictionary = tiers[rank - 1]
	var base_count := int(params.get("count", 1))
	# A boulder stays one boulder at every rank. Volley growth adds bodies only
	# to an already-authored volley; size/trail/layer growth still applies.
	var count_add := int(tier.get("count_add", 0)) if base_count > 1 else 0
	params["count"] = clampi(base_count + count_add, 1, int(library.get("max_body_count", 12)))
	params["size"] = maxf(0.01, float(params.get("size", 0.4)) * float(tier.get("size_scale", 1.0)))
	params["trail"] = maxf(0.0, float(params.get("trail", 1.0)) * float(tier.get("trail_scale", 1.0)))
	params["impact_scale"] = maxf(0.01, float(params.get("impact_scale", 1.0)) * float(tier.get("impact_scale", 1.0)))
	resolved["parameters"] = params
	# Optional authored detail is presentation-only. The frozen host rank
	# selects it once; no costs, targets, clocks or damage are read here.
	if tier.has("accent_count"):
		resolved["impact"]["accent_count"] = clampi(int(tier.accent_count), 4, 18)
	if tier.has("body_layer_count"):
		var layers: Array = resolved.body.get("layers", [])
		resolved["body"]["layers"] = layers.slice(0, clampi(int(tier.body_layer_count), 0, layers.size()))
	if id == "stone_throw" and int(params.count) == 1 and float(params.size) >= 0.5:
		resolved["sound"] = (resolved.get("sound_variants", {}) as Dictionary).get("boulder", resolved.sound).duplicate(true)
	resolved["mastery_rank"] = rank
	resolved["secondary_trail"] = bool(tier.get("secondary_trail", false))
	resolved["impact_layer"] = bool(tier.get("impact_layer", false))
	resolved["archetype"] = id
	return resolved

## No gameplay geometry/timing/cost can be changed by mastery. Combat supplies
## travel_seconds from its frozen schedule; computed fallback is presentation
## for legacy callers only, never damage authority.
static func travel_seconds(from: Vector3, to: Vector3, spec: Dictionary,
		context: Dictionary = {}) -> float:
	if context.has("travel_seconds"):
		return maxf(0.0, float(context.travel_seconds))
	var row := resolve(spec, int(context.get("mastery_rank", 1)))
	if row.is_empty(): return 0.0
	if str(row.get("arrival", "")) in ["contact", "no_damage"]: return 0.0
	var timing: Dictionary = config().get("timing", {})
	var speed := maxf(0.001, float((row.parameters as Dictionary).get("speed", 24.0)))
	return clampf(from.distance_to(to) / speed,
		float(timing.get("min_travel_seconds", 0.06)), float(timing.get("max_travel_seconds", 0.42)))

static func launch(parent: Node, from: Vector3, to: Vector3, spec: Dictionary,
		context: Dictionary = {}) -> Node3D:
	if parent == null or not parent.is_inside_tree() or not bool(config().get("enabled", false)): return null
	if not from.is_finite() or not to.is_finite(): return null
	var frozen := CONTRACT.birth(spec, context)
	if frozen.is_empty(): return null
	var visual: Dictionary = spec.vfx
	var row := resolve(visual, int(frozen.mastery_rank))
	if row.is_empty():
		push_error("Unmapped move effect archetype: %s" % visual.get("archetype", ""))
		return null
	for node: Node in parent.get_tree().get_nodes_in_group("move_effect_presentation"):
		if is_instance_valid(node) and not node.is_queued_for_deletion() and node.has_method("action_id") \
				and str(node.call("action_id")) == str(frozen.action_id): return null
	var effect := EFFECT.new()
	effect.configure(from, to, row, frozen_copy(frozen), float(frozen.travel_seconds), config())
	parent.add_child(effect)
	return effect

static func _deep_merge(base: Dictionary, over: Dictionary) -> void:
	for key: Variant in over:
		if base.get(key) is Dictionary and over[key] is Dictionary:
			_deep_merge(base[key], over[key])
		else:
			base[key] = over[key].duplicate(true) if (over[key] is Dictionary or over[key] is Array) else over[key]

## Authored replacement presentation for a whole ultimate, keyed by move id
## (owner direction: water ultimates read as a wave or a water ball). Empty
## when the ultimate keeps its own composition.
static func ultimate_override(move_id: String) -> Dictionary:
	return (config().get("ultimate_overrides", {}) as Dictionary).get(move_id, {}).duplicate(true)

## Draw an already-validated ultimate (ultimate_library.launch checked its
## binding, duration and grounds) with this library's staged effect. The
## caller's frozen context is kept; no gameplay value is read or written.
static func launch_presentation(parent: Node, from: Vector3, to: Vector3, visual: Dictionary,
		frozen: Dictionary) -> Node3D:
	if parent == null or not parent.is_inside_tree(): return null
	if not from.is_finite() or not to.is_finite(): return null
	var row := resolve(visual, int(frozen.get("mastery_rank", 1)))
	if row.is_empty(): return null
	var effect := EFFECT.new()
	effect.configure(from, to, row, frozen_copy(frozen), float(frozen.get("travel_seconds", 0.0)), config())
	parent.add_child(effect)
	effect.add_to_group("ultimate_presentation")
	return effect

static func frozen_copy(value: Variant) -> Variant:
	if value is Object:
		push_error("Move presentation context must contain values, not object references")
		return null
	if value is Dictionary:
		var copy: Dictionary = {}
		for key: Variant in value: copy[key] = frozen_copy(value[key])
		copy.make_read_only()
		return copy
	if value is Array:
		var copy: Array = []
		for entry: Variant in value: copy.append(frozen_copy(entry))
		copy.make_read_only()
		return copy
	return value

## Resolve the one contact cue for the accepted receipt owner. This does not
## play, deduplicate or authorize it; the existing transaction owns all three.
static func impact_cue(frozen_move: Dictionary) -> Dictionary:
	if not CONTRACT.whole(frozen_move.get("mastery_rank"), 1, 5) \
			or not frozen_move.get("vfx") is Dictionary \
			or not CONTRACT.visual(frozen_move.vfx): return {}
	var row := resolve(frozen_move.vfx, int(frozen_move.mastery_rank))
	if row.is_empty(): return {}
	var sound: Dictionary = row.sound
	var phase := "impact_mastery" if int(frozen_move.mastery_rank) >= 5 else "impact"
	var cue_id := str(sound.get(phase, ""))
	var audio := preload("res://scripts/audio/audio_manager.gd")
	var path := str(audio.section("move_effect_cues").get(cue_id, ""))
	if path.is_empty(): return {}
	return {"cue_id": cue_id, "path": path, "gain_db": float(sound.get("gain_db", -7.0))}

static func cancel_action(tree: SceneTree, action_id: String) -> void:
	if tree == null or action_id.is_empty(): return
	for effect: Node in tree.get_nodes_in_group("move_effect_presentation"):
		if is_instance_valid(effect) and not effect.is_queued_for_deletion() \
				and effect.has_method("action_id") and str(effect.call("action_id")) == action_id:
			effect.call("cancel_presentation")

static func cancel_encounter(tree: SceneTree, encounter_id: String) -> void:
	if tree == null or encounter_id.is_empty(): return
	for effect: Node in tree.get_nodes_in_group("move_effect_presentation"):
		if is_instance_valid(effect) and not effect.is_queued_for_deletion() \
				and effect.has_method("encounter_id") and str(effect.call("encounter_id")) == encounter_id:
			effect.call("cancel_presentation")
