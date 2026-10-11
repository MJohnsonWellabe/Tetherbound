extends RefCounted

## Detached personal research proposals. Host producers own event provenance;
## Foundation's existing character_action journal owns write, delivery and ACK.
## No party membership, release, client counts or inferred history earns credit.
const DATA := preload("res://scripts/data/redesign_data.gd")
const ESSENCE := preload("res://scripts/creatures/essence.gd")
const RULES := preload("res://scripts/world/death_satchel_rules.gd")
const WATER := preload("res://scripts/creatures/water_species_catalog.gd")
const ACTIONS := ["research_event", "research_claim"]
const LOG_SCHEMA_VERSION := 2
const LEGACY_CATALOGUE_REVISION := 1
const TITLE_HISTORY_PATH := "res://data/config/research_title_requirements_v1.json"
static var _catalogue: Dictionary = {}
static var _configuration: Dictionary = {}
static var _title_history: Dictionary = {}

static func catalogue() -> Dictionary:
	if not _catalogue.is_empty(): return _catalogue
	var raw: Variant = DATA.json("res://data/creatures/species.json")
	if not raw is Dictionary or not raw.get("species") is Dictionary: return {}
	var merged := WATER.merge_catalogue(raw.species)
	if merged.get("ok") == true: _catalogue = merged.catalogue
	return _catalogue

static func config() -> Dictionary:
	if not _configuration.is_empty(): return _configuration
	var raw: Variant = DATA.json("res://data/config/research.json")
	if not raw is Dictionary or not configuration_errors(raw).is_empty():
		push_error("Research catalogue missing or invalid")
		return {}
	_configuration = raw
	return _configuration

static func configuration_errors(raw: Dictionary) -> Array[String]:
	if raw.get("schema_version") != 1 or raw.get("catalogue_revision") != 2 or not raw.get("runtime_enabled") is bool \
		or not ESSENCE._integer(raw.get("maximum_event_receipts"), 1, 4096) \
		or not ESSENCE._integer(raw.get("maximum_transaction_receipts"), 1, 4096) \
		or not raw.get("biomes") is Dictionary or not raw.get("species") is Dictionary:
		return ["invalid research configuration"]
	var definitions := catalogue()
	if definitions.is_empty() or raw.species.size() != definitions.size(): return ["research must cover every registered species"]
	for biome: String in ["meadows", "tidewake", "cloudreach", "stormwood"]:
		if not raw.biomes.get(biome) is Dictionary or not ESSENCE._component(raw.biomes[biome].get("title")): return ["missing biome title"]
	for id: String in raw.species:
		var row: Variant = raw.species[id]
		if not definitions.has(id) or not row is Dictionary or not raw.biomes.has(row.get("biome")) \
			or not row.get("tasks") is Array or row.tasks.size() < 3: return ["invalid research species " + id]
		var types: Array[String] = []
		for type_id: Variant in [definitions[id].get("type"), definitions[id].get("type_secondary", "")]:
			if type_id == "": continue
			if not type_id is String or ESSENCE.essence_item(type_id).is_empty(): return ["unknown research essence"]
			types.append(type_id)
		if types.is_empty(): return ["missing research type"]
		var ids: Array[String] = []
		for task: Variant in row.tasks:
			if not task is Dictionary or not ESSENCE._component(task.get("id")) or ids.has(task.id) \
				or task.get("kind") not in ["sight", "cast", "catch", "defeat"] \
				or not ESSENCE._component(task.get("label")) or not ESSENCE._integer(task.get("required"), 1, 999) \
				or not ESSENCE._integer(task.get("reward_count"), 5, 15): return ["invalid research task"]
			if task.has("move") and (task.kind != "cast" or not definitions[id].get("moves", {}).values().has(task.move)):
				return ["unknown signature move"]
			if task.has("night") and (task.kind != "catch" or not task.night is bool): return ["invalid night task"]
			ids.append(task.id)
	return _title_history_errors(raw)


static func _legacy_title_requirements() -> Dictionary:
	if not _title_history.is_empty(): return _title_history
	var raw: Variant = DATA.json(TITLE_HISTORY_PATH)
	if raw is Dictionary: _title_history = raw
	return _title_history


static func _title_history_errors(cfg: Dictionary) -> Array[String]:
	var history := _legacy_title_requirements()
	if history.get("schema_version") != 1 or history.get("catalogue_revision") != LEGACY_CATALOGUE_REVISION \
		or not history.get("biomes") is Dictionary or history.biomes.size() != cfg.biomes.size():
		return ["invalid historical research title catalogue"]
	for biome: Variant in history.biomes:
		var species: Variant = history.biomes[biome]
		if not cfg.biomes.has(biome) or not species is Dictionary or species.is_empty(): return ["invalid historical biome title"]
		for id: Variant in species:
			var tasks: Variant = species[id]
			if not cfg.species.has(id) or cfg.species[id].biome != biome or not tasks is Dictionary or tasks.is_empty():
				return ["invalid historical title species"]
			for task: Variant in tasks:
				if task_definition(str(id), str(task), cfg).is_empty() or not ESSENCE._integer(tasks[task], 1, 999):
					return ["invalid historical title task"]
	return []

static func personal_errors(personal: Dictionary, cfg: Dictionary) -> Array[String]:
	var log: Variant = personal.get("research", empty_log())
	var errors := log_errors(log, cfg)
	if not errors.is_empty(): return errors
	for receipt: Variant in personal.get("research_receipts", []):
		var parts := str(receipt).split(":")
		if parts.size() != 4 or parts[0] != "research" or not ESSENCE._component(parts[3]): return ["invalid research payout receipt"]
		var task := task_definition(parts[1], parts[2], cfg)
		if task.is_empty() or int(log.species.get(parts[1], {}).get("tasks", {}).get(parts[2], 0)) < int(task.required) \
			or not personal.get("transaction_receipts", []).has(receipt): return ["unearned research payout receipt"]
	return []

static func empty_log() -> Dictionary:
	return {"schema_version": LOG_SCHEMA_VERSION, "species": {}, "event_receipts": [], "titles": [], "title_revisions": {}}

static func task_definition(species: String, task_id: String, cfg: Dictionary) -> Dictionary:
	for task: Dictionary in cfg.get("species", {}).get(species, {}).get("tasks", []):
		if task.id == task_id: return task
	return {}

static func log_errors(raw: Variant, cfg: Dictionary) -> Array[String]:
	if not raw is Dictionary or not raw.get("species") is Dictionary \
		or not raw.get("event_receipts") is Array or not raw.get("titles") is Array: return ["invalid research carrier"]
	var legacy: bool = raw.size() == 3
	if not legacy and (raw.size() != 5 or raw.get("schema_version") != LOG_SCHEMA_VERSION \
		or not raw.get("title_revisions") is Dictionary): return ["unsupported research carrier revision"]
	if not legacy and raw.title_revisions.size() != raw.titles.size(): return ["invalid research title revisions"]
	if raw.event_receipts.size() > int(cfg.get("maximum_event_receipts", 0)): return ["research receipt budget"]
	var seen: Array = []
	for receipt: Variant in raw.event_receipts:
		if not receipt is String or receipt.length() != 64 or not receipt.is_valid_hex_number(false) or seen.has(receipt): return ["invalid research event receipt"]
		seen.append(receipt)
	for id: Variant in raw.species:
		var row: Variant = raw.species[id]
		if not id is String or not cfg.get("species", {}).has(id) or not row is Dictionary or row.size() != 3 \
			or not row.get("seen") is bool or not row.get("caught") is bool or not row.get("tasks") is Dictionary \
			or (row.caught and not row.seen): return ["invalid research species history"]
		for task_id: Variant in row.tasks:
			var definition := task_definition(id, str(task_id), cfg)
			if definition.is_empty() or not ESSENCE._integer(row.tasks[task_id], 0, int(definition.required)): return ["invalid research progress"]
	seen = []
	for biome: Variant in raw.titles:
		var revision: Variant = LEGACY_CATALOGUE_REVISION if legacy else raw.title_revisions.get(biome)
		if not biome is String or not cfg.get("biomes", {}).has(biome) or seen.has(biome) \
			or not ESSENCE._integer(revision, LEGACY_CATALOGUE_REVISION, int(cfg.get("catalogue_revision", 0))) \
			or not _earned_title(raw, biome, int(revision), cfg): return ["unearned research title"]
		seen.append(biome)
	return []


static func _earned_title(log: Dictionary, biome: String, revision: int, cfg: Dictionary) -> bool:
	if revision == int(cfg.get("catalogue_revision", 0)): return completion(log, biome, cfg) == 100
	if revision != LEGACY_CATALOGUE_REVISION or not _title_history_errors(cfg).is_empty(): return false
	var requirements: Dictionary = _legacy_title_requirements().biomes.get(biome, {})
	if requirements.is_empty(): return false
	for id: String in requirements:
		for task: String in requirements[id]:
			if int(log.species.get(id, {}).get("tasks", {}).get(task, 0)) < int(requirements[id][task]): return false
	return true


## Only a successful detached research proposal upgrades the carrier. Readers
## and validators leave durable before/after journal snapshots byte-for-byte
## intact. Existing titles retain their old qualification; no progress, event
## receipt, payout, or missing title is manufactured by this migration.
static func _upgraded_log(log: Dictionary) -> Dictionary:
	var upgraded := log.duplicate(true)
	if log.size() != 3: return upgraded
	upgraded["schema_version"] = LOG_SCHEMA_VERSION
	upgraded["title_revisions"] = {}
	for biome: String in log.titles: upgraded.title_revisions[biome] = LEGACY_CATALOGUE_REVISION
	return upgraded


## Frozen journal replays alone use the pre-Stormursa catalogue. Task metadata
## is unchanged by that additive release; membership and required counts are
## taken from the immutable revision1 recipe, never current-minus-one-species.
static func _legacy_configuration(current: Dictionary) -> Dictionary:
	if not _title_history_errors(current).is_empty(): return {}
	var legacy := current.duplicate(true)
	legacy.catalogue_revision = LEGACY_CATALOGUE_REVISION
	legacy.species = {}
	for biome: String in _legacy_title_requirements().biomes:
		var species: Dictionary = _legacy_title_requirements().biomes[biome]
		for id: String in species:
			var row := {"biome": biome, "tasks": []}
			for task_id: String in species[id]:
				var task := task_definition(id, task_id, current).duplicate(true)
				task.required = int(species[id][task_id])
				row.tasks.append(task)
			legacy.species[id] = row
	return legacy

static func completion(log: Dictionary, biome: String, cfg: Dictionary) -> int:
	var done := 0
	var total := 0
	for id: String in cfg.get("species", {}):
		if cfg.species[id].biome != biome: continue
		for task: Dictionary in cfg.species[id].tasks:
			total += 1
			if int(log.get("species", {}).get(id, {}).get("tasks", {}).get(task.id, 0)) >= int(task.required): done += 1
	return int(floorf(100.0 * done / total)) if total > 0 else 0

static func reward(species: String, task: Dictionary) -> Array[Dictionary]:
	var definition: Dictionary = catalogue().get(species, {})
	var types: Array[String] = []
	for type_id: Variant in [definition.get("type", ""), definition.get("type_secondary", "")]:
		if type_id is String and not type_id.is_empty(): types.append(type_id)
	return ESSENCE._split_payout(types, int(task.get("reward_count", 0)))

static func view(personal: Dictionary, character: String, biome: String) -> Dictionary:
	var cfg := config()
	var log: Variant = personal.get("research", empty_log())
	if cfg.is_empty() or not cfg.biomes.has(biome) or character.is_empty() or not log_errors(log, cfg).is_empty(): return {"ready": false}
	var rows: Array[Dictionary] = []
	var definitions := catalogue()
	for id: String in cfg.species:
		if cfg.species[id].biome != biome: continue
		var history: Dictionary = log.species.get(id, {})
		var tasks: Array[Dictionary] = []
		for task: Dictionary in cfg.species[id].tasks:
			var payout := reward(id, task)
			var receipt := "research:%s:%s:%s" % [id, task.id, character]
			var progress := int(history.get("tasks", {}).get(task.id, 0))
			tasks.append({"id": task.id, "label": task.label, "required": int(task.required), "progress": progress,
				"reward_item": payout[0].id, "reward_count": payout[0].n, "rewards": payout,
				"paid": personal.get("research_receipts", []).has(receipt),
				"claimable": progress >= int(task.required) and not personal.get("research_receipts", []).has(receipt)})
		rows.append({"species_id": id, "name": definitions[id].get("display_name", id.capitalize()),
			"seen": history.get("seen", false), "caught": history.get("caught", false), "tasks": tasks})
	return {"ready": true, "character_id": character, "completion_percent": completion(log, biome, cfg),
		"title": cfg.biomes[biome].title if log.titles.has(biome) else "", "species": rows,
		"claims_enabled": cfg.runtime_enabled}

static func stage(current: Dictionary, revision: int, action: String, intent: Dictionary, context: Dictionary,
		legacy_delivery_replay: bool = false) -> Dictionary:
	if action not in ACTIONS or context.get("character_id") != current.get("character_id") \
		or context.get("expected_revision") != revision or context.get("in_range") != true: return _deny("invalid_research_authority")
	var cfg := config()
	if cfg.is_empty(): return _deny("research_configuration_unavailable")
	if legacy_delivery_replay:
		cfg = _legacy_configuration(cfg)
		if cfg.is_empty(): return _deny("historical_research_configuration_unavailable")
	var personal: Dictionary = current.redesign_character
	for paid: String in personal.get("research_receipts", []):
		if not paid.ends_with(":" + str(current.character_id)): return _deny("foreign_research_receipt")
	if not personal_errors(personal, cfg).is_empty(): return _deny("invalid_research_history")
	var log: Dictionary
	if legacy_delivery_replay:
		log = personal.get("research", {"species": {}, "event_receipts": [], "titles": []}).duplicate(true)
		if log.size() != 3: return _deny("historical_research_carrier_required")
	else:
		log = _upgraded_log(personal.get("research", empty_log()))
	var next := current.duplicate(true)
	var receipt := ""
	if action == "research_event":
		# Session/encounter owner supplies this frozen context, never a client RPC.
		if not intent.is_empty() or context.get("event_confirmed") != true \
			or not ESSENCE._opaque_id(context.get("world_namespace")) or not ESSENCE._opaque_id(context.get("session_id")) \
			or not ESSENCE._opaque_id(context.get("event_id")) or not context.get("participants") is Array \
			or not context.participants.has(current.character_id) or not cfg.species.has(context.get("species_id")) \
			or context.get("kind") not in ["sight", "cast", "catch", "defeat"]: return _deny("accepted_host_research_event_required")
		var id: String = context.species_id
		if context.kind == "cast" and (not context.get("move_id") is String \
			or not catalogue()[id].get("moves", {}).values().has(context.move_id)): return _deny("actual_species_cast_required")
		if context.kind == "catch" and (context.get("wild") != true or not context.get("night") is bool): return _deny("accepted_wild_catch_required")
		if context.kind == "defeat" and context.get("opponent_defeated") != true: return _deny("accepted_defeat_required")
		var event := JSON.stringify([context.world_namespace, context.session_id, context.event_id, id, context.kind]).sha256_text()
		if log.event_receipts.has(event): return _deny("reconcile_original_decision")
		if log.event_receipts.size() >= int(cfg.maximum_event_receipts): return _deny("research_event_budget")
		var row: Dictionary = log.species.get(id, {"seen": false, "caught": false, "tasks": {}}).duplicate(true)
		row.seen = true
		if context.kind == "catch": row.caught = true
		for task: Dictionary in cfg.species[id].tasks:
			if task.kind != context.kind and task.kind != "sight": continue
			if task.has("move") and task.move != context.get("move_id"): continue
			if task.has("night") and task.night != context.get("night"): continue
			row.tasks[task.id] = mini(int(task.required), int(row.tasks.get(task.id, 0)) + 1)
		if row == log.species.get(id, {}): return _deny("research_no_progress")
		log.species[id] = row
		log.event_receipts.append(event)
		receipt = "research:event_%s:%s" % [event, current.character_id]
		for biome: String in cfg.biomes:
			if not log.titles.has(biome) and completion(log, biome, cfg) == 100:
				log.titles.append(biome)
				if not legacy_delivery_replay: log.title_revisions[biome] = int(cfg.catalogue_revision)
	else:
		if intent.size() != 2 or not intent.get("species_id") is String or not intent.get("task_id") is String \
			or context.get("source_key") != "research_journal": return _deny("invalid_research_claim")
		var task := task_definition(intent.species_id, intent.task_id, cfg)
		if task.is_empty() or int(log.species.get(intent.species_id, {}).get("tasks", {}).get(intent.task_id, 0)) < int(task.required): return _deny("research_incomplete")
		receipt = "research:%s:%s:%s" % [intent.species_id, intent.task_id, current.character_id]
		if personal.research_receipts.has(receipt): return _deny("reconcile_original_decision")
		var inventory := RULES.inventory_from(current.inventory)
		var payout := reward(intent.species_id, task)
		if payout.is_empty(): return _deny("research_reward_unavailable")
		for stack: Dictionary in payout:
			if not RULES.give_stack(inventory, stack): return _deny("reward_inventory_full")
		next.inventory = RULES.slots(inventory)
		next.redesign_character.research_receipts.append(receipt)
	if personal.transaction_receipts.has(receipt): return _deny("reconcile_original_decision")
	if personal.transaction_receipts.size() >= int(cfg.maximum_transaction_receipts): return _deny("receipt_budget")
	next.redesign_character["research"] = log
	next.redesign_character.transaction_receipts.append(receipt)
	return {"ok": true, "before": current.duplicate(true), "state": next, "receipt": receipt,
		"expected_character_revision": revision}

static func _deny(code: String) -> Dictionary:
	return {"ok": false, "code": code, "durable": false, "resolved": false}
