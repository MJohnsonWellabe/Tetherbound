extends RefCounted

## Presentation only. The immutable host receipt owns hit timing and results.
const CONFIG_PATH := "res://data/config/vfx.json"
const EFFECT := preload("res://scripts/vfx/move_effect.gd")
const CONTRACT := preload("res://scripts/vfx/move_presentation_contract.gd")
const GEOMETRY := preload("res://scripts/vfx/move_effect_geometry.gd")
const PIN := preload("res://scripts/vfx/material_variant_pin.gd")
## Every authored surface move_effect_geometry.authored_material() draws.
const AUTHORED_KINDS := ["bubble", "root_stone_surface", "shadow_surface", "wind_surface", "fire_explosion",
	"flame_tongue", "soft_trail", "soft_dust", "water_stream", "rolling_wave", "splash_crown", "ice_crystal",
	"ion_filament", "electrical_splash", "burning_core", "flame_orb", "fire_bloom", "soft_ember", "soft_foam",
	"flame_volume", "mist_cone", "stone"]

static var _config: Dictionary = {}
static var _prewarmed := false
static var _astra_config: Dictionary = {}
static var _astra_r2_config: Dictionary = {}
static var _astra_r3_config: Dictionary = {}
static var _astra_family_config: Dictionary = {}
static var _astra_r4_config: Dictionary = {}
static var _kit_config: Dictionary = {}

## F25#0 kit effects: one shared particle toolkit for every archetype. Shipping
## OFF on disk; a preview or the coordinator's flip enables it.
static func kit_config() -> Dictionary:
	if _kit_config.is_empty():
		var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/kit_move_effects.json"))
		if raw is Dictionary: _kit_config = raw
	return _kit_config

static func _kit_profile(archetype: String) -> Dictionary:
	var kit := kit_config()
	if not bool(kit.get("enabled", false)): return {}
	return (kit.get("profiles", {}) as Dictionary).get(archetype, {})

## The tether beam is drawn by the original water-jet renderer exactly
## (body, trail, impact, launch, light, size/trail/impact parameters); only the
## palette changes to a non-red tether hue. Arrival, timing and mastery stay.
static func _kit_donor(row: Dictionary) -> void:
	var profile := _kit_profile(str(row.archetype))
	if str(profile.get("family", "")) != "original_donor": return
	var donor := resolve({"archetype": str(profile.donor)}, int(row.mastery_rank))
	for key: String in ["body", "trail", "impact", "launch", "light"]:
		if donor.has(key): row[key] = donor[key].duplicate(true)
		else: row.erase(key)
	for key: String in ["size", "trail", "impact_scale", "spread", "arc"]:
		if (donor.parameters as Dictionary).has(key): row.parameters[key] = donor.parameters[key]
	_recolour_water(row.body)
	_recolour_water(row.trail)
	_recolour_water(row.impact)
	row.parameters["colour"] = "#" + Color.from_hsv(0.705, Color(str(donor.parameters.colour)).s, Color(str(donor.parameters.colour)).v).to_html(false)

static func astra_r4_config() -> Dictionary:
	if _astra_r4_config.is_empty():
		var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/astra_move_effects_r4.json"))
		if raw is Dictionary: _astra_r4_config = raw
	return _astra_r4_config

## Only presentation profiles. Original water-jet shape/material/emission and
## stage lifetime are retained; no r3 core, width, trail or hold-time overrides.
static func _final_drawing(row: Dictionary) -> void:
	var final := astra_r4_config()
	if not bool(final.get("enabled", false)): return
	if (final.get("profiles", {}) as Dictionary).has(str(row.archetype)):
		# The smoke path sees the same drawing metadata as the renderer, so its
		# existing projectile/ground/lifetime assertions cover the actual candidate.
		var profile: Dictionary = final.profiles[str(row.archetype)]
		for part: String in ["body", "impact"]:
			for key: String in profile.get(part, {}):
				var value: Variant = profile[part][key]
				row[part][key] = value.duplicate(true) if value is Dictionary or value is Array else value
		return
	if str(row.archetype) != "catch_tether_beam": return
	var donor: Dictionary = config().archetypes.water_jet
	for key: String in ["body", "trail", "impact", "launch", "light"]:
		if donor.has(key): row[key] = donor[key].duplicate(true)
		else: row.erase(key)
	_recolour_water(row.body)
	_recolour_water(row.trail)
	_recolour_water(row.impact)

static func _recolour_water(value: Variant) -> void:
	if value is Array:
		for child: Variant in value: _recolour_water(child)
	elif value is Dictionary:
		for key: Variant in value:
			if value[key] is Dictionary or value[key] is Array: _recolour_water(value[key])
			elif str(key).ends_with("colour"):
				var old := Color(str(value[key]))
				# Preserve saturation/value/alpha, including white foam and dark mark.
				value[key] = "#" + Color.from_hsv(0.705, old.s, old.v, old.a).to_html(true)

## Independent, shipping-OFF four-example selector. Preview writes are
## process-local; the existing library config, resolved rows and timing stay intact.
static func astra_config() -> Dictionary:
	if _astra_config.is_empty():
		var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/astra_move_effects.json"))
		if raw is Dictionary: _astra_config = raw
	return _astra_config

static func astra_r2_config() -> Dictionary:
	if _astra_r2_config.is_empty():
		var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/astra_move_effects_r2.json"))
		if raw is Dictionary: _astra_r2_config = raw
	return _astra_r2_config

static func astra_r3_config() -> Dictionary:
	if _astra_r3_config.is_empty():
		var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/astra_move_effects_r3.json"))
		if raw is Dictionary: _astra_r3_config = raw
	return _astra_r3_config

static func astra_family_config() -> Dictionary:
	if _astra_family_config.is_empty():
		var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/astra_move_effects_families.json"))
		if raw is Dictionary: _astra_family_config = raw
	return _astra_family_config

static func _ordinary_effect(row: Dictionary, context: Dictionary) -> Node3D:
	var kit_profile := _kit_profile(str(row.archetype))
	if not kit_profile.is_empty():
		if str(kit_profile.get("family", "")) in ["original", "original_donor"]: return EFFECT.new()
		var kit_effect := (load("res://scripts/vfx/kit_effect.gd") as Script).new() as Node3D
		kit_effect.set("tuning", kit_config().duplicate(true))
		if str(kit_profile.get("family", "")) == "self":
			var source_id := int(context.get("local_visual_source_id", 0))
			var source := instance_from_id(source_id) as Node3D if source_id > 0 and is_instance_id_valid(source_id) else null
			# Unbound callers keep a caster-sized volume at the muzzle.
			kit_effect.call("bind_source", source)
		return kit_effect
	var final := astra_r4_config()
	if bool(final.get("enabled", false)) and str(row.archetype) in final.get("archetypes", []):
		var path := "res://scripts/vfx/astra_family_effect_r4.gd"
		if str(row.archetype) == "catch_tether_beam": path = "res://scripts/vfx/astra_tether_r4.gd"
		elif str(row.archetype) == "buff_aura": path = "res://scripts/vfx/astra_aura_r4.gd"
		var script := load(path) as Script
		var effect := script.new() as Node3D
		if str(row.archetype) != "catch_tether_beam": effect.set("tuning", final.duplicate(true))
		if str(row.archetype) == "buff_aura":
			var source_id := int(context.get("local_visual_source_id", 0))
			var source := instance_from_id(source_id) as Node3D if source_id > 0 and is_instance_id_valid(source_id) else null
			if not effect.call("bind_source", source):
				effect.free()
				return EFFECT.new()
		return effect
	var families := astra_family_config()
	var admitted := str(row.archetype) in ["stone_throw", "ember_burst", "tidal_wave", "wind_blade", "tornado",
		"ice_shard_volley", "psychic_pulse", "root_stone_spikes", "quake_ring", "debuff_hex"]
	var refined_slash := str(row.archetype) == "slash_trail" and bool(families.get("include_slash_refinement", false))
	if bool(families.get("enabled", false)) and (admitted or refined_slash) \
			and (families.get("profiles", {}) as Dictionary).has(str(row.archetype)):
		var family_script := load("res://scripts/vfx/astra_family_effect.gd") as Script
		var family_effect := family_script.new() as Node3D
		family_effect.set("tuning", families.duplicate(true))
		return family_effect
	var candidate := astra_config()
	var script_path := "res://scripts/vfx/astra_move_effect.gd"
	var revision := astra_r2_config()
	if bool(revision.get("enabled", false)) and str(row.archetype) in revision.get("archetypes", []) \
			and str(row.archetype) in ["buff_aura", "catch_tether_beam", "bubble_volley"]:
		candidate = revision
		script_path = "res://scripts/vfx/astra_move_effect_r2.gd"
	var third := astra_r3_config()
	if bool(third.get("enabled", false)) and str(row.archetype) in third.get("archetypes", []) \
			and str(row.archetype) in ["buff_aura", "catch_tether_beam"]:
		candidate = third
		script_path = "res://scripts/vfx/astra_gate_effect_r3.gd"
	if bool(candidate.get("enabled", false)) and str(row.archetype) in candidate.get("archetypes", []) \
			and str(row.archetype) in ["slash_trail", "buff_aura", "catch_tether_beam", "bubble_volley"]:
		var script := load(script_path) as Script
		var effect := script.new() as Node3D
		effect.set("tuning", candidate.duplicate(true))
		if str(row.archetype) == "buff_aura":
			var source_id := int(context.get("local_visual_source_id", 0))
			var source := instance_from_id(source_id) as Node3D if source_id > 0 and is_instance_id_valid(source_id) else null
			if not effect.call("bind_source", source):
				effect.free()
				# No guessed body at a muzzle: older callers retain the fallback.
				return EFFECT.new()
		return effect
	return EFFECT.new()

static func config() -> Dictionary:
	if _config.is_empty():
		var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
		if raw is Dictionary: _config = raw
	return _config.get("move_library", {}) as Dictionary

## F25#4: on Forward+ the first material of a variant compiled its shader on
## the launch frame (10-43 ms each). Building one of each standard variant and
## each authored surface while the world loads moves that cost off the fight.
## Idempotent and presentation-only.
static func prewarm() -> void:
	if _prewarmed: return
	_prewarmed = true
	PIN.prewarm()
	for kind: String in AUTHORED_KINDS:
		GEOMETRY.authored_material(kind, {}, Color.WHITE).get_rid()
	for style: String in ["painted_flame", "dust"]:
		GEOMETRY.authored_material("soft_trail", {"style": style}, Color.WHITE).get_rid()
	# Contact stages (flash, ground mark, spark motes) build their own surfaces.
	for shader: Shader in [EFFECT.FLASH_SHADER, EFFECT.GROUND_MARK_SHADER, EFFECT.SPARK_SHADER, EFFECT.SPARK_GLOW_SHADER]:
		var stage := ShaderMaterial.new()
		stage.shader = shader
		stage.set_shader_parameter("opacity", 1.0)
		stage.get_rid()

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
	_final_drawing(resolved)
	_kit_donor(resolved)
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
	var effect := _ordinary_effect(row, context)
	effect.call("configure", from, to, row, frozen_copy(frozen), float(frozen.travel_seconds), config())
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
	var growth: Dictionary = frozen.get("breakthrough_growth", {})
	if not growth.is_empty():
		# The accepted rank already selected the mastery tier. Authored
		# breakthrough detail uses the same body/accent clamps and leases.
		var params: Dictionary = row.parameters
		params["size"] = maxf(0.01, float(params.size) * float(growth.get("size_scale", 1.0)))
		var base_count := int(visual.get("count", config().archetypes[row.archetype].parameters.get("count", 1)))
		if base_count > 1:
			params["count"] = clampi(int(params.count) + int(growth.get("count_add", 0)), 1, int(config().get("max_body_count", 12)))
		row.impact["accent_count"] = clampi(int(round(float(row.impact.get("accent_count", 4)) * float(growth.get("accent_scale", 1.0)))), 4, 18)
		if int(growth.get("secondary_layers", 0)) > 0:
			row["secondary_trail"] = true
			row["impact_layer"] = true
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
