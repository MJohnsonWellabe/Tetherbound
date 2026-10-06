extends RefCounted

## R4.6, D13/D17/D20: the Meadows' one evolution line (Mudsnout -> Tuskroot) as
## a real system, not just the two dangling `evolves_into`/`evolves_from`
## fields D20 left behind ("the evolution system itself remains unbuilt,
## deliberately... until it lands a caught Mudsnout simply stays a Mudsnout").
##
## D71/T3-SUNSTONE: Mudsnout now branches -- Tuskroot with a Heartstone,
## Ashtusk with a Sunstone -- via `evolves_into_variants` (item_id -> target)
## sitting BESIDE the original single-string `evolves_into`, which stays the
## primary/default path and keeps every pre-existing caller's shape. See
## ralph/reports/SUNSTONE_DESIGN_2026-08-30.md for why a parallel field was
## chosen over turning `evolves_into` itself into a map.
##
## Deliberately not a method on creature_instance.gd -- like teaching.gd, this
## reads BOTH a species definition (creature_species.gd) and a live instance
## to decide eligibility, and the gate numbers are genuinely data
## (data/config/progression.json's `evolution` block, keyed by the
## PRE-evolution species id), the same split progression.gd already draws
## between pure arithmetic and the instance that owns state.

const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const DATA := preload("res://scripts/data/redesign_data.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const INSTANCE := preload("res://scripts/creatures/creature_instance.gd")
const LINES_PATH := "res://data/config/evolution_lines.json"
const BEAR_PROVENANCE := "res://assets/creatures/tetherbound/stormursa/source/provenance.json"


## F29/RD-28: a pure component of F28's one feast_feed transaction. The host
## passes its admitted party card plus that uid's evolution_choices mirror.
## Ingredient is derived from the cooked feast SKU by F28, never inventory or
## a client claim. Cooking already paid the stone: debit is ALWAYS empty.
## This does not save, replace a creature, unlock a cap or change inventory.
static func prepare_feast_choice(
	creature_card: Dictionary, tier: int, choice: String, ingredient: String
) -> Dictionary:
	var offered := feast_offer(creature_card, tier)
	if not bool(offered.get("ok", false)):
		return offered
	if not ingredient in ["", "heartstone", "sunstone"]:
		return _feast_failure("evolution_ingredient_invalid")
	if not choice in ["", "evolve", "stay"]:
		return _feast_failure("evolution_choice_invalid")
	var out := creature_card.duplicate(true)
	var choices: Dictionary = out.get("evolution_choices", {}).duplicate(true)
	var key := str(tier)
	if choices.has(key):
		return _feast_failure("evolution_choice_permanent")
	var branches: Array = offered.get("branches", [])
	if branches.is_empty():
		# A disabled bear is no offer, not a permanent refusal. A T5 feast
		# still lifts the cap; missed offers are not retroactive (§8.1).
		if choice != "" or ingredient != "":
			return _feast_failure("evolution_not_offered")
		return _feast_success(out, {}, {}, "")
	if choice == "":
		return _feast_failure("evolution_choice_required")
	if choice == "stay":
		# A cooked catalyst feast can be declined, but never reimbursed.
		if ingredient != "" and not _has_ingredient(branches, ingredient):
			return _feast_failure("evolution_ingredient_invalid")
		choices[key] = "stay"
		out["evolution_choices"] = choices
		return _feast_success(out, {"tier": key, "value": "stay"}, {}, "")
	var selected: Dictionary = {}
	for branch: Dictionary in branches:
		if branch.extra_ingredient == ingredient:
			if not selected.is_empty():
				return _feast_failure("evolution_ingredient_ambiguous")
			selected = branch
	if selected.is_empty():
		return _feast_failure("evolution_catalyst_feast_required")
	var target := str(selected.target)
	var definition := SPECIES.definition(target)
	var patch := _species_patch(creature_card, target, definition)
	if patch.is_empty():
		return _feast_failure("evolution_stats_invalid")
	out.merge(patch, true)
	choices[key] = target
	out["evolution_choices"] = choices
	return _feast_success(out, {"tier": key, "value": target}, patch, ingredient)


## UI quotes use the same canonical authored lines as the host planner.
## F28 separately validates current cap, cleared tiers, recipe, actual station,
## ownership and stable character. No missed lower-tier evolution is offered.
static func feast_offer(creature_card: Dictionary, tier: int) -> Dictionary:
	if tier < 1 or tier > 5 or not INSTANCE.valid_uid(str(creature_card.get("uid", ""))):
		return _feast_failure("evolution_card_invalid")
	var raw_level: Variant = creature_card.get("level")
	if not (raw_level is int or raw_level is float) or not is_finite(float(raw_level)) \
			or float(raw_level) != float(tier * 10):
		return _feast_failure("evolution_wrong_level")
	var raw_choices: Variant = creature_card.get("evolution_choices", {})
	if not raw_choices is Dictionary:
		return _feast_failure("evolution_choices_invalid")
	if raw_choices.has(str(tier)):
		return _feast_failure("evolution_choice_permanent")
	var source := str(creature_card.get("species_id", ""))
	if not SPECIES.has(source):
		return _feast_failure("evolution_species_invalid")
	var loaded := DATA.load_catalog("evolution_lines", LINES_PATH)
	if not bool(loaded.get("ok", false)):
		return _feast_failure("evolution_config_invalid")
	var branches: Array[Dictionary] = []
	for row: Dictionary in loaded.data:
		if row.source != source or int(row.breaks_level) != tier * 10 or not bool(row.enabled):
			continue
		if row.target == "stormursa" and not storm_bear_ready():
			continue
		if not SPECIES.has(str(row.target)):
			return _feast_failure("evolution_target_missing")
		branches.append(row.duplicate(true))
	return {"ok": true, "code": "ok", "branches": branches, "choice_required": not branches.is_empty(),
		"stay_text": "Stay this species permanently for this tier. The level cap still lifts."}


## A config flip alone cannot activate a generated or retargeted candidate.
## ROOT fills this existing source manifest only after the actual full art bar.
static func storm_bear_ready() -> bool:
	if not FileAccess.file_exists(BEAR_PROVENANCE): return false
	var raw: Variant = DATA.json(BEAR_PROVENANCE)
	if not raw is Dictionary: return false
	for gate: String in ["reference_inspected", "rig_pass", "animation_pass", "scale_pass", "full_art_bar_pass"]:
		if raw.get(gate) != true: return false
	if raw.get("generation_provider") != "Meshy" or str(raw.get("meshy_task_id", "")).is_empty(): return false
	var height: Variant = raw.get("height_m")
	if not (height is int or height is float) or not is_finite(float(height)): return false
	var source_height := float(SPECIES.placeholder("staticub").get("height", INF))
	if float(height) <= maxf(source_height, 1.80): return false
	var visual := SPECIES.placeholder("stormursa")
	var model: Variant = raw.get("model")
	if not model is Dictionary or visual.get("model", "") != model.get("path", "") \
			or float(visual.get("height", 0.0)) != float(height): return false
	for slot: String in ["reference", "model", "judge_medium", "judge_high", "before_after"]:
		var artifact: Variant = raw.get(slot)
		if not artifact is Dictionary: return false
		var path := str(artifact.get("path", ""))
		var sha := str(artifact.get("sha256", ""))
		if not path.begins_with("res://") or sha.length() != 64 or not FileAccess.file_exists(path): return false
		if FileAccess.get_sha256(path) != sha: return false
		if slot in ["judge_medium", "judge_high"] and (artifact.get("verdict") != "PASS" \
				or str(artifact.get("independent_reviewer", "")).is_empty()): return false
	return true


static func _has_ingredient(branches: Array, ingredient: String) -> bool:
	for branch: Dictionary in branches:
		if branch.extra_ingredient == ingredient: return true
	return false


## Use the same curve/IV/boost math as the live individual. Everything else,
## including every loadout slot and mastery counter, stays byte-for-byte.
static func _species_patch(card: Dictionary, target: String, definition: Dictionary) -> Dictionary:
	var growth: Dictionary = PROGRESSION.config().get("level", {}).get("growth_per_level", {})
	var cfg := PROGRESSION.config()
	var patch := {"species_id": target, "display_name": str(definition.get("display_name", target)),
		"creature_type": str(definition.get("type", "")), "secondary_type": str(definition.get("type_secondary", ""))}
	for stat: String in ["hp", "attack", "defence"]:
		var raw_base: Variant = definition.get("base_" + stat)
		var raw_iv: Variant = card.get("iv_" + stat)
		var raw_boost: Variant = card.get("boost_" + stat)
		for value: Variant in [raw_base, raw_iv, raw_boost]:
			if not (value is int or value is float) or not is_finite(float(value)): return {}
		if float(raw_base) <= 0.0 or float(raw_iv) < 0.0 or float(raw_iv) > 1.0 or float(raw_boost) < 0.0: return {}
		patch["base_" + stat] = float(raw_base)
		patch["max_hp" if stat == "hp" else stat] = PROGRESSION.stat_at_level(float(raw_base), int(card.level), float(growth.get(stat, 0.0))) \
			* PROGRESSION.individuality_multiplier(float(raw_iv), cfg) + float(raw_boost)
	var old_max: Variant = card.get("max_hp")
	var old_hp: Variant = card.get("hp")
	if not (old_max is int or old_max is float) or not (old_hp is int or old_hp is float): return {}
	if not is_finite(float(old_max)) or not is_finite(float(old_hp)) or float(old_max) <= 0.0 \
			or float(old_hp) < 0.0 or float(old_hp) > float(old_max): return {}
	patch["hp"] = float(patch.max_hp) * (float(old_hp) / float(old_max))
	return patch


static func _feast_failure(code: String) -> Dictionary:
	return {"ok": false, "code": code, "reason": code, "debit": {}, "choice_record": {}, "species_patch": {}}


static func _feast_success(card: Dictionary, record: Dictionary, patch: Dictionary, ingredient: String) -> Dictionary:
	return {"ok": true, "code": "ok", "reason": "", "creature": card, "debit": {},
		"choice_record": record, "species_patch": patch, "extra_ingredient": ingredient}


## The full set of additional branches `species_id` declares beyond its
## primary `evolves_into`: item_id -> target species id, read from
## `evolves_into_variants` and filtered to targets that actually exist in the
## species table (the same defensive shape `requirements()` already applies
## to the primary target below). {} for a species with no variants, which is
## every species except Mudsnout today.
static func variant_branches(species_id: String) -> Dictionary:
	var definition := SPECIES.definition(species_id)
	var raw: Variant = definition.get("evolves_into_variants", {})
	if not (raw is Dictionary):
		return {}
	var out: Dictionary = {}
	for item_id: String in (raw as Dictionary).keys():
		var target := str((raw as Dictionary)[item_id])
		if SPECIES.has(target):
			out[item_id] = target
	return out


## The evolution requirement for `species_id`, or {} if this species does not
## evolve, or has no requirement configured yet (a species.json link with no
## matching progression.json entry -- not expected for the shipped roster,
## but a caller should read "no requirement" as "cannot evolve", never crash
## on a missing key). `target`/`item_id` are folded into the returned dict so
## a caller never has to re-read species.json to learn what it evolves into,
## and `branches` carries every OTHER catalyst-selected destination so a
## refusal message can name them all.
##
## `inventory` (optional; null reads as "nothing on hand", same direction
## every caller here already reads no-item-available) is what actually picks
## a branch: holding none of the branch items keeps the primary path as the
## reported target (unchanged behaviour for a species like Mudsnout with no
## variants, and the sensible default for one that has them but nothing is
## held yet); holding exactly one swaps `target`/`item_id` to that branch;
## holding more than one sets `ambiguous` rather than silently choosing --
## `check()` turns that into a refusal naming the problem.
static func requirements(species_id: String, cfg: Dictionary, inventory: RefCounted = null) -> Dictionary:
	# F28 activation source cut supplies this explicit mode. Legacy UI cannot
	# consume a held stone alongside the canonical feast transaction.
	if cfg.get("evolution_mode", "legacy") == "breakthrough":
		return {}
	var definition := SPECIES.definition(species_id)
	if not definition.has("evolves_into"):
		return {}
	var primary_target := str(definition["evolves_into"])
	if not SPECIES.has(primary_target):
		return {}
	var req: Variant = cfg.get("evolution", {}).get(species_id)
	if not (req is Dictionary):
		return {}
	var out: Dictionary = (req as Dictionary).duplicate()
	var primary_item := str(out.get("item_id", ""))
	out["target"] = primary_target

	var branches := variant_branches(species_id)
	out["branches"] = branches
	if branches.is_empty():
		return out

	var held: Array[String] = []
	if primary_item != "" and inventory != null and int(inventory.call("count", primary_item)) >= 1:
		held.append(primary_item)
	for item_id: String in branches.keys():
		if inventory != null and int(inventory.call("count", item_id)) >= 1:
			held.append(item_id)

	if held.size() > 1:
		out["ambiguous"] = true
		out["target"] = ""
		out["item_id"] = ""
	elif held.size() == 1 and held[0] != primary_item:
		out["item_id"] = held[0]
		out["target"] = branches[held[0]]
	# else: nothing held, or only the primary item held -- primary stays as set above
	return out


## Every catalyst item that leads somewhere from `species_id`, primary path
## included, as "Heartstone" / "Sunstone" style names -- used to build a
## refusal message that names the whole fork rather than one branch of it.
static func _catalyst_names(species_id: String, cfg: Dictionary) -> Array[String]:
	var req: Variant = cfg.get("evolution", {}).get(species_id)
	var names: Array[String] = []
	if req is Dictionary:
		var primary_item := str((req as Dictionary).get("item_id", ""))
		if primary_item != "":
			names.append(primary_item.capitalize())
	for item_id: String in variant_branches(species_id).keys():
		names.append(item_id.capitalize())
	return names


## "a Heartstone", "a Heartstone or a Sunstone", "a Heartstone, a Sunstone or
## a Whatever" -- however many catalysts a line ends up with. The shipped
## roster only ever exercises the two-name case.
static func _describe_catalysts(names: Array[String]) -> String:
	if names.is_empty():
		return "an item"
	if names.size() == 1:
		return "a " + names[0]
	var text := "a " + names[0]
	for i in range(1, names.size() - 1):
		text += ", a " + names[i]
	text += " or a " + names[names.size() - 1]
	return text


## Eligibility for THIS live creature. `inventory` is optional -- null reads
## as "no item available", the safe direction for a caller (a pure-logic
## test) that has none in hand -- and is only ever consulted when the
## requirement actually names an `item_id`. Never mutates anything; `evolve()`
## below is the only function here that does.
##
## `milestones_cfg` is OWNER-0901-BOND-MILESTONES's optional override, passed
## straight through to `creature.bond_nodes()` -- {} (the default) reads the
## real shipped ladder, same as every other production caller of
## `bond_nodes()`. Only a test that wants an isolated ladder needs to pass one.
static func check(
	creature: RefCounted, cfg: Dictionary, inventory: RefCounted = null,
	milestones_cfg: Dictionary = {}
) -> Dictionary:
	var species_id := str(creature.get("species_id"))
	if cfg.get("evolution_mode", "legacy") == "breakthrough":
		var loaded := DATA.load_catalog("evolution_lines", LINES_PATH)
		if loaded.get("ok") == true:
			for line: Dictionary in loaded.data:
				if line.source != species_id or line.enabled != true: continue
				if line.target == "stormursa" and not storm_bear_ready(): continue
				return {"eligible": false, "target": "", "reason": "Evolution is chosen when feeding the Lv %d Ascension Feast. Cook it at the Kitchen; choosing evolve or stay is permanent for that tier." % int(line.breaks_level)}
	var req := requirements(species_id, cfg, inventory)
	if req.is_empty():
		return {"eligible": false, "target": "", "reason": "%s does not evolve." % str(creature.call("label"))}

	var level_needed := int(req.get("level", 0))
	# OWNER-0901-BOND-MILESTONES: `bond` used to be a raw 0-100 value compared
	# directly; it is now `bond_tier`, read off the milestone ladder via
	# `bond_nodes()` (see that method's own comment for what `milestones_cfg`
	# does).
	var bond_tier_needed := int(req.get("bond_tier", 0))

	if int(creature.get("level")) < level_needed:
		return {
			"eligible": false, "target": str(req.get("target", "")),
			"reason": "%s needs to reach level %d first (currently %d)." % [
				str(creature.call("label")), level_needed, int(creature.get("level"))
			],
		}
	if int(creature.call("bond_nodes", milestones_cfg)) < bond_tier_needed:
		return {
			"eligible": false, "target": str(req.get("target", "")),
			"reason": "%s needs a stronger bond first." % str(creature.call("label")),
		}
	if bool(req.get("ambiguous", false)):
		return {
			"eligible": false, "target": "",
			"reason": ("%s is ready to evolve, but you're carrying more than one evolution " +
				"stone -- drop one so the choice is deliberate.") % str(creature.call("label")),
		}

	var target := str(req.get("target", ""))
	var item_id := str(req.get("item_id", ""))
	if item_id != "" and (inventory == null or int(inventory.call("count", item_id)) < 1):
		return {
			"eligible": false, "target": target,
			"reason": "%s needs %s to evolve." % [
				str(creature.call("label")), _describe_catalysts(_catalyst_names(species_id, cfg))
			],
		}
	return {"eligible": true, "target": target, "reason": ""}


## Apply an eligible evolution: consumes the item (if the requirement names
## one) and mutates `creature` in place via its own `evolve_into`. Returns
## false and changes nothing on any refusal -- re-validated here rather than
## trusted from an earlier `check()`, the same defensive shape
## `teaching.teach()` uses, so a caller cannot evolve a creature by racing a
## stale eligibility read (an item spent elsewhere between the two calls, say).
static func evolve(
	creature: RefCounted, cfg: Dictionary, inventory: RefCounted = null,
	milestones_cfg: Dictionary = {}
) -> bool:
	var result := check(creature, cfg, inventory, milestones_cfg)
	if not bool(result.get("eligible", false)):
		return false

	var req := requirements(str(creature.get("species_id")), cfg, inventory)
	var item_id := str(req.get("item_id", ""))
	if item_id != "":
		if inventory == null or not bool(inventory.call("remove", item_id, 1)):
			return false

	var target := str(req.get("target", ""))
	creature.call("evolve_into", target, SPECIES.definition(target), cfg)
	return true
