extends RefCounted

## F30 SOURCE-ONLY drafting helper. Intentionally has no class_name, autoload,
## scene, Session, LIVE inventory/roster, save, RPC or RandomNumberGenerator access.
## Teaching/distilling below stage detached candidates only, never authority.
## Every result is inadmissible for gameplay. There is no enable path here.
## Host integration must own RNG, recompute from its canonical character record,
## stage its existing personalized ledger and commit its same-record CAS.
## A caller supplying floats does NOT establish that caller's authority.
const DATA := preload("res://scripts/data/redesign_data.gd")
const ESSENCE := preload("res://scripts/creatures/essence.gd")
const RULES := preload("res://scripts/world/death_satchel_rules.gd")
const CONFIG_PATH := "res://data/config/traits.json"

## Identity/semantic contracts, not tunables. Only hardy/max_hp_scale is
## currently canonical F16. Every other pair is a registration proposal.
## Columns: rarity, effect id, domain, one scalar target, operation, gate.
const CONTRACTS := {
	"bold": ["common", "charged_power_scale", "combat", "move_power", "increase", "charged_move"],
	"calm": ["common", "wind_regeneration_scale", "combat", "wind_regeneration", "increase", "creature"],
	"sturdy": ["common", "effective_defence_scale", "combat", "effective_defence", "increase", "creature"],
	"swift": ["common", "combat_movement_scale", "combat", "movement_speed", "increase", "creature_in_combat"],
	"gentle": ["common", "recovery_received_scale", "recovery", "recovery_received", "increase", "creature"],
	"stubborn": ["common", "poise_threshold_scale", "combat", "poise_threshold", "increase", "creature"],
	"curious": ["common", "skill_cooldown_reduction", "combat", "skill_cooldown_duration", "decrease", "creature_skill"],
	"watchful": ["common", "burst_wind_cost_reduction", "combat", "burst_wind_cost", "decrease", "creature_burst"],
	"hardy": ["common", "max_hp_scale", "derived", "max_hp", "increase", "creature"],
	"surefoot": ["common", "slope_movement_scale", "traversal", "movement_speed", "increase", "outside_combat_already_walkable_slope"],
	"deep_breath": ["common", "max_wind_scale", "derived", "max_wind", "increase", "creature"],
	"nimble": ["common", "turn_rate_scale", "traversal", "turn_rate", "increase", "directly_piloted_creature"],
	"sure_strike": ["rare", "quick_power_scale", "combat", "move_power", "increase", "quick_move"],
	"resourceful": ["rare", "utility_wind_cost_reduction", "combat", "utility_wind_cost", "decrease", "utility_move"],
	"amphibious": ["rare", "swim_speed_scale", "traversal", "swim_speed", "increase", "already_swim_capable"],
	"windrider": ["rare", "fly_wind_cost_reduction", "traversal", "fly_wind_cost", "decrease", "already_fly_capable"],
	"climber": ["rare", "climb_speed_scale", "traversal", "climb_speed", "increase", "already_allowed_tap_started_climb"],
	"keen_aim": ["rare", "projectile_speed_scale", "combat", "projectile_speed", "increase", "creature_move_projectile"],
	"far_reach": ["rare", "projectile_range_scale", "combat", "projectile_range", "increase", "creature_move_projectile"],
	"resilient": ["rare", "stagger_duration_reduction", "combat", "stagger_duration", "decrease", "creature"],
	"light_landing": ["rare", "fall_damage_reduction", "traversal", "fall_damage_received", "decrease", "creature_traversal"],
	"steady_wing": ["rare", "fly_speed_scale", "traversal", "fly_speed", "increase", "already_fly_capable"],
	"flameheart": ["epic", "fire_move_power_scale", "combat", "move_power", "increase", "fire_move"],
	"tidalheart": ["epic", "water_move_power_scale", "combat", "move_power", "increase", "water_move"],
	"galesoul": ["epic", "air_move_power_scale", "combat", "move_power", "increase", "air_move"],
	"earthheart": ["epic", "ground_move_power_scale", "combat", "move_power", "increase", "ground_move"],
	"stormheart": ["epic", "electric_move_power_scale", "combat", "move_power", "increase", "electric_move"],
	"frostheart": ["epic", "ice_move_power_scale", "combat", "move_power", "increase", "ice_move"],
	"mindbright": ["epic", "psychic_move_power_scale", "combat", "move_power", "increase", "psychic_move"],
	"duskheart": ["epic", "dark_move_power_scale", "combat", "move_power", "increase", "dark_move"]
}

class RollDraft extends RefCounted:
	var code: String = "invalid_source"
	var admissible: bool = false
	var trait_ids: Array[String] = []
	var errors: Array[String] = []

class EffectDraft extends RefCounted:
	var admissible: bool = false
	var trait_id: String = ""
	var effect_id: String = ""
	var domain: String = ""
	var target: String = ""
	var operation: String = ""
	var eligibility_gate: String = ""
	var scalar_target_group: String = ""
	var stacking_proposal: String = ""
	var requires_host_gate_evaluation: bool = true
	var magnitude: float = 0.0
	var multiplier: float = 1.0

class EffectsDraft extends RefCounted:
	var code: String = "invalid_source"
	var admissible: bool = false
	var effects: Array[EffectDraft] = []
	var errors: Array[String] = []

var _config: Dictionary = {}
var _rows: Dictionary = {}
var _source_errors: Array[String] = []

func _init() -> void:
	var source: Variant = DATA.json(CONFIG_PATH)
	if not source is Dictionary:
		_source_errors.append("missing or malformed F30 source configuration")
		return
	_source_errors = _validate(source)
	if not _source_errors.is_empty(): return
	_config = source.duplicate(true)
	for row: Dictionary in _config.candidate_catalog:
		_rows[row.id] = row.duplicate(true)

func source_errors() -> Array[String]:
	return _source_errors.duplicate()

## Seven host-sampled finite [0,1) values: count, then three rarity/pick pairs.
## Values must come from HOST spawn state, never a client intent. Consuming all
## seven before this call keeps RNG advancement independent of rolled count.
## Inputs are read only; output strings are new detached values.
func preview_roll(host_draws: Array, host_spawn_context: Dictionary) -> RollDraft:
	var result := RollDraft.new()
	result.errors = source_errors()
	if not result.errors.is_empty(): return result
	if host_draws.size() != 1 + 2 * _config.roll.count_order.back():
		result.code = "invalid_draws"
		return result
	for draw: Variant in host_draws:
		if not _number(draw) or float(draw) < 0.0 or float(draw) >= 1.0:
			result.code = "invalid_draws"
			return result
	if not _keys(host_spawn_context, ["alpha", "night", "weather"]):
		result.code = "invalid_spawn_context"
		return result
	for key: String in ["alpha", "night", "weather"]:
		if not host_spawn_context[key] is bool:
			result.code = "invalid_spawn_context"
			return result
	var counts := _weights("count", host_spawn_context)
	var rarities := _weights("rarity", host_spawn_context)
	var count: int = _config.roll.count_order[_pick(counts, float(host_draws[0]))]
	for i: int in count:
		var rarity: String = _config.roll.rarity_order[_pick(rarities, float(host_draws[1 + i * 2]))]
		var available: Array[String] = []
		# Config array order is part of reproducibility; never Dictionary order.
		for row: Dictionary in _config.candidate_catalog:
			if row.rarity == rarity and not result.trait_ids.has(row.id):
				available.append(row.id)
		if available.is_empty():
			result.trait_ids.clear()
			result.code = "exhausted_rarity"
			return result
		result.trait_ids.append(available[int(float(host_draws[2 + i * 2]) * available.size())])
	result.code = "draft_only"
	return result

## Typed scalar proposals, one effect per distinct trait. Gates are semantic
## requirements for future consumers, NOT trusted booleans from a client.
## This method never applies a stat, grants traversal, regenerates resources,
## expands capacity or interprets legacy primary/secondary identity fields.
## Do not multiply these raw rows together. Their scalar_target_group exposes
## overlap (e.g. Bold and Flameheart) for the pending COMBAT resolution choice.
## An Epic fire/water/etc. gate must match the actual host move type; multiple
## Epic type traits never benefit the same canonical single-type move.
func preview_effects(host_trait_ids: Array) -> EffectsDraft:
	var result := EffectsDraft.new()
	result.errors = source_errors()
	if not result.errors.is_empty(): return result
	var seen: Array[String] = []
	var maximum: int = _config.roll.count_order.back() + _config.teaching.slots.size()
	if host_trait_ids.size() > maximum:
		result.code = "trait_capacity_requires_settled_identity_policy"
		return result
	for id: Variant in host_trait_ids:
		if not id is String or not _rows.has(id) or seen.has(id):
			result.code = "unknown_or_duplicate_trait"
			return result
		seen.append(id)
	for id: String in seen:
		var contract: Array = CONTRACTS[id]
		var proposal := EffectDraft.new()
		proposal.trait_id = id
		proposal.effect_id = contract[1]
		proposal.domain = contract[2]
		proposal.target = contract[3]
		proposal.operation = contract[4]
		proposal.eligibility_gate = contract[5]
		proposal.scalar_target_group = contract[3]
		proposal.stacking_proposal = _config.integration.effect_stacking_proposal
		proposal.magnitude = float(_rows[id].magnitude)
		proposal.multiplier = 1.0 + proposal.magnitude if proposal.operation == "increase" else 1.0 - proposal.magnitude
		result.effects.append(proposal)
	result.code = "draft_only"
	return result

func _weights(kind: String, context: Dictionary) -> Array:
	var weights: Array = _config.roll[kind + "_weights"].duplicate()
	for bonus: String in ["alpha", "night", "weather"]:
		if context[bonus]:
			for i: int in weights.size():
				weights[i] += _config.roll[bonus + "_" + kind + "_bonus"][i]
	return weights

func _pick(weights: Array, draw: float) -> int:
	var total := 0.0
	for weight: Variant in weights: total += float(weight)
	var threshold := draw * total
	var cumulative := 0.0
	for i: int in weights.size():
		cumulative += float(weights[i])
		if threshold < cumulative: return i
	return weights.size() - 1

static func _number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))

static func _keys(value: Variant, keys: Array) -> bool:
	if not value is Dictionary or value.size() != keys.size(): return false
	for key: String in keys:
		if not value.has(key): return false
	return true

static func _validate(cfg: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	if not _keys(cfg, ["schema_version", "enabled", "source_only", "_scope", "canonical_catalog", "candidate_catalog", "presentation", "magnitude_caps", "roll", "teaching", "distillation", "personality_mapping", "integration"]):
		return ["unknown or missing configuration field"]
	if not _number(cfg.schema_version) or cfg.schema_version != 1 \
			or not cfg.enabled is bool or cfg.enabled != false \
			or not cfg.source_only is bool or cfg.source_only != true:
		return ["source-only disabled version required; activation is unsupported"]
	if not cfg._scope is String or cfg._scope.is_empty(): return ["source scope required"]
	for field: String in ["roll", "teaching", "distillation", "personality_mapping", "integration", "presentation", "magnitude_caps"]:
		if not cfg[field] is Dictionary: errors.append("malformed " + field)
	if not errors.is_empty(): return errors
	# Use actual F16 manifest/relations, without accepting a caller catalog.
	var canonical: Dictionary = DATA.load_catalog("traits")
	if not canonical.get("ok", false) or cfg.canonical_catalog != canonical.get("data"):
		errors.append("canonical catalog differs from source F16 manifest")
	var hard_caps := {"common": 0.05, "rare": 0.08, "epic": 0.12}
	if not _keys(cfg.magnitude_caps, hard_caps.keys()): return ["malformed rarity caps"]
	for tier: String in hard_caps:
		var cap: Variant = cfg.magnitude_caps[tier]
		if not _number(cap) or float(cap) <= 0.0 or float(cap) > float(hard_caps[tier]):
			errors.append("rarity cap exceeds F30 contract: " + tier)
	if not errors.is_empty(): return errors
	if not cfg.candidate_catalog is Array or cfg.candidate_catalog.size() != CONTRACTS.size():
		return ["complete authored candidate catalog required"]
	var ids: Array[String] = []
	for row: Variant in cfg.candidate_catalog:
		if not _keys(row, ["id", "rarity", "effect", "magnitude"]) or not row.id is String or not CONTRACTS.has(row.id):
			errors.append("malformed or unknown proposed trait")
			continue
		var contract: Array = CONTRACTS[row.id]
		if ids.has(row.id) or row.rarity != contract[0] or row.effect != contract[1]:
			errors.append("duplicate or inconsistent proposed trait " + row.id)
		ids.append(row.id)
		if not _number(row.magnitude) or float(row.magnitude) <= 0.0 or float(row.magnitude) > float(cfg.magnitude_caps[contract[0]]):
			errors.append("invalid magnitude for " + row.id)
		var copy: Variant = cfg.presentation.get(row.id)
		if not _keys(copy, ["display_name", "description"]) or not copy.display_name is String or not copy.description is String:
			errors.append("missing plain-language presentation for " + row.id)
		elif copy.display_name.is_empty() or copy.description.is_empty():
			errors.append("empty plain-language presentation for " + row.id)
	if not _keys(cfg.presentation, CONTRACTS.keys()): errors.append("unknown presentation id")
	for row: Variant in cfg.canonical_catalog:
		if row is Dictionary:
			for candidate: Variant in cfg.candidate_catalog:
				if candidate is Dictionary and candidate.get("id") == row.get("id") and candidate != row:
					errors.append("canonical row changed inside candidate pool")
	var roll: Dictionary = cfg.roll
	if not _keys(roll, ["count_order", "rarity_order", "count_weights", "rarity_weights", "alpha_count_bonus", "alpha_rarity_bonus", "night_count_bonus", "night_rarity_bonus", "weather_count_bonus", "weather_rarity_bonus", "weather_eligibility", "selection", "host_draw_order", "input_range", "starter_policy", "world_scope_until_catch"]):
		return ["unknown or missing roll policy"]
	if roll.count_order != [0, 1, 2, 3] or roll.rarity_order != ["common", "rare", "epic"] \
			or roll.weather_eligibility != "host_active_weather_spawn_not_clear" \
			or roll.selection != "uniform_within_rarity_without_replacement" \
			or roll.host_draw_order != "one_count_then_three_rarity_pick_pairs" \
			or roll.input_range != "finite_0_inclusive_1_exclusive" \
			or roll.starter_policy != "same_pool_as_ordinary_spawn" or roll.world_scope_until_catch != true:
		return ["unsupported roll policy"]
	for kind: String in ["count", "rarity"]:
		var size: int = roll[kind + "_order"].size()
		for key: String in [kind + "_weights", "alpha_" + kind + "_bonus", "night_" + kind + "_bonus", "weather_" + kind + "_bonus"]:
			var vector: Variant = roll[key]
			if not vector is Array or vector.size() != size:
				return ["malformed weight vector " + key]
			for value: Variant in vector:
				if not _number(value): return ["nonfinite weight vector " + key]
		for bonus: String in ["alpha", "night", "weather"]:
			var cumulative := 0.0
			var improves := false
			for value: Variant in roll[bonus + "_" + kind + "_bonus"]:
				cumulative += float(value)
				if cumulative > 0.0: errors.append("bonus moves probability toward worse outcomes")
				if cumulative < 0.0: improves = true
			if not _number(cumulative) or cumulative != 0.0 or not improves:
				errors.append("bonus must strictly improve equal-total weights")
		for mask: int in 8:
			var total := 0.0
			for i: int in size:
				var weight := float(roll[kind + "_weights"][i])
				for b: int in 3:
					if mask & (1 << b): weight += float(roll[["alpha", "night", "weather"][b] + "_" + kind + "_bonus"][i])
				if not _number(weight) or weight < 0.0: errors.append("negative or nonfinite combined roll weight")
				total += weight
			if not _number(total) or total <= 0.0: errors.append("empty or nonfinite roll distribution")
	# These are policy invariants; costs remain authored tunables in JSON.
	var teaching: Dictionary = cfg.teaching
	if not _keys(teaching, ["slots", "extra_to_rolled", "unlock_requires_completed_breakthrough", "essence_type_policy", "dual_type_policy_status", "overwrite_destroys_previous", "duplicate_policy", "maximum_owned_creatures", "inventory_contract", "transaction_template", "scope"]):
		return ["malformed teaching policy"]
	if not teaching.slots is Array or teaching.slots.size() != 3: return ["three taught slots required"]
	for i: int in teaching.slots.size():
		var slot: Variant = teaching.slots[i]
		if not _keys(slot, ["slot", "breakthrough_level", "essence_cost"]) \
				or slot.slot != i + 1 or slot.breakthrough_level != [10, 30, 50][i] \
				or not _number(slot.essence_cost) or float(slot.essence_cost) <= 0.0 \
				or float(slot.essence_cost) != floorf(float(slot.essence_cost)):
			errors.append("invalid taught slot or essence cost")
	if teaching.extra_to_rolled != true or teaching.unlock_requires_completed_breakthrough != true \
			or teaching.overwrite_destroys_previous != true or teaching.maximum_owned_creatures != 5 \
			or teaching.duplicate_policy != "refuse_across_rolled_taught_and_revealed_identity" \
			or teaching.essence_type_policy != "canonical_species_primary_type" \
			or teaching.dual_type_policy_status != "proposal_pending_training_owner_review" \
			or teaching.inventory_contract != "seed_item_and_trait_payload_not_yet_registered_no_generic_item_id_assumed" \
			or teaching.transaction_template != "trait_teach:<uid>:<slot>:<sequence>" or teaching.scope != "character":
		errors.append("unsupported teaching policy")
	var distil: Dictionary = cfg.distillation
	if not _keys(distil, ["maximum_seeds_per_release", "selection", "hidden_secondary_eligible", "transaction_template", "canonical_receipts", "commit", "scope"]):
		return ["malformed distillation policy"]
	if distil.maximum_seeds_per_release != 1 or distil.hidden_secondary_eligible != false \
			or distil.selection != "one_player_chosen_known_visible_trait" or distil.scope != "character" \
			or distil.transaction_template != "release:<uid>" \
			or distil.canonical_receipts != "redesign_character.release_receipts_and_transaction_receipts" \
			or distil.commit != "same_atomic_release_as_essence_inventory_and_owned_uid_removal":
		errors.append("unsupported release policy")
	var mapping: Dictionary = cfg.personality_mapping
	if not _keys(mapping, ["enabled", "status", "common_ids", "primary_proposal", "secondary_proposal", "bond_gate_source", "capacity_question", "duplicate_question", "unrevealed_effect", "no_new_bond_threshold"]):
		return ["malformed identity proposal"]
	if mapping.enabled != false or mapping.status != "proposal_pending_existing_open_owner_decision_TRAINING_12_4" \
			or mapping.common_ids != ["bold", "calm", "sturdy", "swift", "gentle", "stubborn", "curious", "watchful"] \
			or mapping.unrevealed_effect != "none" or mapping.no_new_bond_threshold != true \
			or mapping.bond_gate_source != "data/config/progression.json:traits.unlock_bond_nodes":
		errors.append("identity mapping activation or new bond rule refused")
	for key: String in ["primary_proposal", "secondary_proposal", "capacity_question", "duplicate_question"]:
		if not mapping[key] is String or mapping[key].is_empty(): errors.append("missing identity proposal " + key)
	var integration: Dictionary = cfg.integration
	if not _keys(integration, ["effect_stacking_status", "effect_stacking_proposal", "same_target_resolution", "type_bonus_rule", "single_effect_boundaries", "application", "session_rule", "ledger_rule", "required_registry_extensions", "required_runtime_work", "acceptance_status"]):
		return ["malformed integration boundary"]
	if integration.effect_stacking_status != "proposal_pending_COMBAT_formula_order_caps_and_network_review" \
			or integration.effect_stacking_proposal != "strongest_eligible_trait_magnitude_per_scalar_target_per_event_no_multiplicative_trait_stacking" \
			or integration.same_target_resolution != "proposal_only_pending_COMBAT_review_never_resolve_before_host_eligibility_checks" \
			or integration.type_bonus_rule != "eight_epic_move_type_gates_are_mutually_exclusive_for_canonical_single_type_moves_no_off_type_bonus" \
			or integration.single_effect_boundaries != "projectile_speed_preserves_authored_range_projectile_range_preserves_authored_speed_burst_cost_preserves_distance_timing_vulnerability_slope_speed_applies_only_outside_combat":
		errors.append("unsupported disabled effect-resolution proposal")
	for key: String in ["effect_stacking_status", "effect_stacking_proposal", "same_target_resolution", "type_bonus_rule", "single_effect_boundaries", "application", "session_rule", "ledger_rule", "acceptance_status"]:
		if not integration[key] is String or integration[key].is_empty(): errors.append("missing integration boundary " + key)
	for key: String in ["required_registry_extensions", "required_runtime_work"]:
		if not integration[key] is Array or integration[key].is_empty(): errors.append("missing integration requirements")
		else:
			for entry: Variant in integration[key]:
				if not entry is String or entry.is_empty(): errors.append("malformed integration requirement")
	return errors


## Source generation for F30 Altar transactions. Actual Session sender,
## station/reach/input/cooldown and same-record registry/world/owner save
## integration remain required. This pure helper has no live activation arm.
func _registered_traits() -> Dictionary:
	if not source_errors().is_empty(): return {}
	var catalog: Dictionary = DATA.load_catalog("traits")
	if catalog.get("ok") != true or not catalog.get("data") is Array: return {}
	var result := {}
	for row: Variant in catalog.data:
		if not row is Dictionary or not row.get("id") is String or not _rows.has(row.id) \
				or row != _rows[row.id] or result.has(row.id): return {}
		result[row.id] = row.duplicate(true)
	return result


## Existing inventory id/count shape: each admitted trait has a separate
## registered seed SKU. No generic payload, unknown-id fallback or cross-trait
## merge. Registration belongs to the item/schema owner; none is invented.
func registered_seed(trait_id: String) -> String:
	if not _registered_traits().has(trait_id): return ""
	var id := "trait_seed_" + trait_id
	if not RULES.db().has(id): return ""
	var definition: Dictionary = RULES.db().definition(id)
	var stack: Variant = definition.get("stack")
	if definition.get("kind") != "trait_seed" or definition.get("trait_id") != trait_id \
			or not _number(stack) or float(stack) != floorf(float(stack)) \
			or float(stack) < 1.0 or float(stack) > 2147483647.0: return ""
	return id


func _record_trait_errors(record: Variant, registered: Dictionary) -> Array[String]:
	if not record is Dictionary or not record.get("rolled_traits") is Array \
			or not record.get("taught_traits") is Dictionary or not record.get("breakthroughs") is Array:
		return ["missing admitted trait record"]
	var rolled: Array = record.rolled_traits
	var taught: Dictionary = record.taught_traits
	if rolled.size() > 3 or taught.size() > 3: return ["trait capacity"]
	var seen := {}
	for id: Variant in rolled:
		if not id is String or not registered.has(id) or seen.has(id): return ["unknown or duplicate trait"]
		seen[id] = true
	for slot: Variant in taught:
		if not slot is String or not slot in ["1", "2", "3"]: return ["unknown taught slot"]
		var id: Variant = taught[slot]
		if not id is String or not registered.has(id) or seen.has(id): return ["unknown or duplicate trait"]
		if not record.breakthroughs.has([1, 3, 5][int(slot) - 1]): return ["taught slot breakthrough missing"]
		seen[id] = true
	return []


func _refused(code: String) -> Dictionary:
	return {"ok": false, "code": code, "ready_to_commit": false}


## Client intent nominates only one owned UID/slot/trait/payment and the
## existing revision. Cost, seed identity and completed tiers come from host
## canonical data. No unchanged/duplicate trait consumes either resource.
func stage_teach(admitted: Dictionary, character: String, host_revision: int,
		intent: Dictionary, essence_cfg: Dictionary) -> Dictionary:
	if not source_errors().is_empty() or not ESSENCE._baseline_errors(admitted, character).is_empty() \
			or not ESSENCE.configuration_errors(essence_cfg).is_empty(): return _refused("invalid_trait_baseline")
	var fields := ["teach_id", "creature_uid", "slot", "trait_id", "payment_item", "expected_character_revision"]
	if not _keys(intent, fields): return _refused("invalid_trait_intent")
	for field: String in ["teach_id", "creature_uid", "trait_id", "payment_item"]:
		if not ESSENCE._component(intent[field]): return _refused("invalid_trait_identity")
	if not ESSENCE._integer(intent.slot, 1, 3) \
			or not ESSENCE._integer(intent.expected_character_revision, 0, 2147483646):
		return _refused("invalid_trait_revision")
	var signature := JSON.stringify([intent.creature_uid, intent.slot, intent.trait_id,
		intent.payment_item, intent.expected_character_revision]).sha256_text()
	var prefix := "trait_teach:%s:%s:" % [character, intent.teach_id]
	var receipt := prefix + signature
	var duplicate := false
	for old: String in admitted.redesign_character.transaction_receipts:
		if not old.begins_with(prefix): continue
		if duplicate or old != receipt: return _refused("trait_receipt_conflict")
		duplicate = true
	if duplicate:
		return {"ok": true, "duplicate": true, "receipt": receipt, "ready_to_commit": false,
			"resolved": false, "requires": ["existing_durable_decision_owner_save_reconciliation"]}
	if host_revision != int(intent.expected_character_revision): return _refused("stale_revision")
	var index := ESSENCE._owned_index(admitted, intent.creature_uid)
	if index < 0: return _refused("not_owned")
	var owned: Dictionary = admitted.party[index]
	# Identity unification stays under the existing pending mapping decision.
	# Refuse the whole composition instead of probing an unrevealed secondary
	# for a duplicate and leaking its identity through a different refusal.
	if owned.get("trait_primary", "") != "" or owned.get("trait_secondary", "") != "":
		return _refused("legacy_trait_composition_not_admitted")
	var registered := _registered_traits()
	var record: Variant = admitted.redesign_character.creatures.get(intent.creature_uid)
	if not registered.has(intent.trait_id) or not _record_trait_errors(record, registered).is_empty():
		return _refused("unregistered_or_invalid_trait")
	var key := str(int(intent.slot))
	if not record.breakthroughs.has([1, 3, 5][int(intent.slot) - 1]): return _refused("breakthrough_needed")
	if record.rolled_traits.has(intent.trait_id) or record.taught_traits.values().has(intent.trait_id):
		return _refused("duplicate_or_unchanged_trait")
	var types := ESSENCE._species_types(owned)
	if types.is_empty(): return _refused("invalid_species_type")
	# Use the authored primary-type debit proposal for this detached stage.
	# This technical default creates no new owner approval gate; production
	# adoption still requires the training integrator's coherent design review.
	if intent.payment_item != ESSENCE.essence_item(types[0]): return _refused("wrong_payment_type")
	var seed := registered_seed(intent.trait_id)
	if seed.is_empty() or not RULES.db().has(intent.payment_item): return _refused("seed_or_essence_not_registered")
	var cost := int(_config.teaching.slots[int(intent.slot) - 1].essence_cost)
	if admitted.redesign_character.transaction_receipts.size() >= int(essence_cfg.maximum_transaction_receipts):
		return _refused("receipt_budget")
	var inventory := RULES.inventory_from(admitted.inventory)
	if not inventory.remove(seed, 1) or not inventory.remove(intent.payment_item, cost):
		return _refused("insufficient_seed_or_essence")
	var next := admitted.duplicate(true)
	next.inventory = RULES.slots(inventory).duplicate(true)
	var replaced := str(record.taught_traits.get(key, ""))
	next.redesign_character.creatures[intent.creature_uid].taught_traits[key] = intent.trait_id
	next.redesign_character.transaction_receipts.append(receipt)
	if not _record_trait_errors(next.redesign_character.creatures[intent.creature_uid], registered).is_empty() \
			or not ESSENCE._baseline_errors(next, character).is_empty(): return _refused("invalid_trait_candidate")
	return {"ok": true, "duplicate": false, "ready_to_commit": false,
		"expected_character_revision": host_revision, "receipt": receipt, "before": admitted.duplicate(true),
		"state": next, "creature_uid": intent.creature_uid, "slot": int(intent.slot),
		"trait_id": intent.trait_id, "destroyed_trait": replaced, "seed_debit": {"id": seed, "n": 1},
		"essence_debit": {"id": intent.payment_item, "n": cost},
		"requires": ["actual_host_Altar_identity_and_reach", "same_record_trait_derived_power_rebuild",
			"typed_registry_world_and_owner_save_ACK", "post_durable_UI_feed"]}


## Seed, type essence and UID removal are ONE detached release candidate.
## The existing release:<uid> marker remains canonical; a binding in that same
## transaction receipt array records the chosen seed. No old release can mint
## a retrospective seed, and conflicting retry choices never pay again.
func stage_distil_release(admitted: Dictionary, character: String, uid: String,
		chosen_trait: String, host_revision: int, essence_cfg: Dictionary) -> Dictionary:
	if not source_errors().is_empty() or not ESSENCE._baseline_errors(admitted, character).is_empty() \
			or not ESSENCE._component(uid) or not ESSENCE._integer(host_revision, 0, 2147483646) \
			or (not chosen_trait.is_empty() and not ESSENCE._component(chosen_trait)):
		return _refused("invalid_distil_release")
	var release_receipt := "release:" + uid
	var prefix := release_receipt + ":seed:"
	var binding := ""
	for old: String in admitted.redesign_character.transaction_receipts:
		if old.begins_with(prefix):
			if not binding.is_empty(): return _refused("release_seed_receipt_conflict")
			binding = old
	var wanted := prefix + chosen_trait.sha256_text() if not chosen_trait.is_empty() else ""
	if admitted.redesign_character.release_receipts.has(release_receipt):
		if binding != wanted: return _refused("historical_release_has_no_matching_seed")
		return {"ok": true, "duplicate": true, "ready_to_commit": false, "resolved": false,
			"receipt": release_receipt, "seed_binding": binding,
			"requires": ["existing_durable_release_decision_owner_save_reconciliation"]}
	if not binding.is_empty(): return _refused("orphan_release_seed_binding")
	var proposal := ESSENCE.stage_release(admitted, character, uid, host_revision, essence_cfg)
	if proposal.get("ok") != true or proposal.get("duplicate") == true: return proposal
	proposal["ready_to_commit"] = false
	proposal["requires"] = ["actual_host_Altar_release_eligibility", "single_release_UID_essence_seed_commit",
		"typed_registry_world_and_owner_save_ACK", "replacement_catch_or_volunteer_composition_if_any"]
	if chosen_trait.is_empty(): return proposal # Ordinary zero-trait release survives.
	var released: Dictionary = proposal.released
	if released.get("trait_primary", "") != "" or released.get("trait_secondary", "") != "":
		return _refused("legacy_trait_composition_not_admitted")
	var registered := _registered_traits()
	var record: Variant = admitted.redesign_character.creatures.get(uid)
	if not registered.has(chosen_trait) or not _record_trait_errors(record, registered).is_empty() \
			or not (record.rolled_traits.has(chosen_trait) or record.taught_traits.values().has(chosen_trait)):
		return _refused("not_a_visible_admitted_trait")
	var seed := registered_seed(chosen_trait)
	if seed.is_empty(): return _refused("seed_not_registered")
	var next: Dictionary = proposal.state
	if next.redesign_character.transaction_receipts.size() >= int(essence_cfg.maximum_transaction_receipts):
		return _refused("receipt_budget")
	var inventory := RULES.inventory_from(next.inventory)
	if inventory.add(seed, 1) != 0: return _refused("inventory_full")
	next.inventory = RULES.slots(inventory).duplicate(true)
	next.redesign_character.transaction_receipts.append(wanted)
	if not ESSENCE._baseline_errors(next, character).is_empty(): return _refused("invalid_release_seed_candidate")
	proposal["seed_binding"] = wanted
	proposal["seed_grant"] = {"id": seed, "n": 1}
	proposal["chosen_trait"] = chosen_trait
	return proposal
