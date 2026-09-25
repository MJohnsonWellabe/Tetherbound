extends "res://tests/test_case.gd"

## ACCEPTANCE §6 Cloudreach card ("Cloudreach has no legendary adoption
## offer"), C3 ("No legendary offer appears") and the §6.1 F08 row
## ("Cloudreach presents no legendary offer"); CREATURES §2 legendary row:
## "Cloudreach ends in Wings/reconnection and has no legendary offer."
##
## Pure data and source text. Nothing here instantiates a scene, so it runs in
## the sparse, asset-free checkout. Each check is a function that takes the
## data it judges and returns its violations; the `test_negative_control_*`
## methods feed those same functions an in-memory copy with one fake legendary
## path added and require a violation, so a check that silently stopped
## looking fails here rather than passing forever.
##
## Where an offer could come from, and the check that covers it:
##   * chapter reward grants/objective grants/aftermath -> _chapter_grant_violations
##   * the finale config -> _corpus_violations over cloudreach_finale.json
##   * the finale controller and every other Cloudreach script -> _source_violations
##   * Cloudreach dialogue effects -> _dialogue_violations
##   * trainer reward tiers and every reward/grant subtree -> _reward_violations
##   * the other realms' offer controllers and receipt registries -> _registry_violations,
##     _closure_violations
##   * any legendary species anywhere in Cloudreach data -> _species_violations,
##     _wild_table_legendaries

## KNOWN PENDING DECISION, not hidden and not failed on. Coordinator: flip this
## to false once the owner rules `solmane` out of the Cloudreach summit wild
## table, and the test then requires every Cloudreach wild table to carry no
## legendary at all.
##
## data/config/cloudreach_chapter.json's `cloudreach_summit_wild` table lists
## `solmane` with `roster_identity: "legendary"` as a CATCHABLE WILD. That is a
## wild encounter, not an adoption offer, and the legendary rules (CREATURES
## §2/§8: "trainer and legendary encounters refuse" capture; freed legendaries
## volunteer) have not been reconciled with it. While true, this is the single
## legendary allowed in Cloudreach data, at exactly that entry, and nowhere else.
const PENDING_OWNER_RULING_SOLMANE_SUMMIT_WILD := true
const PENDING_TABLE_ID := "cloudreach_summit_wild"
const PENDING_SPECIES := "solmane"

const CONFIG_DIR := "res://data/config"
const CHAPTER_PATH := "res://data/config/cloudreach_chapter.json"
const FINALE_PATH := "res://data/config/cloudreach_finale.json"
const ENCOUNTERS_PATH := "res://data/config/cloudreach_encounters.json"
const NPC_RUNTIME_PATH := "res://data/config/cloudreach_npc_runtime.json"
const PHYSICAL_PATH := "res://data/config/cloudreach_physical_runtime.json"
const DIALOGUE_PATH := "res://data/dialogue/cloudreach.json"
const RECIPES_PATH := "res://data/recipes/recipes_cloudreach.json"
const REALM_HEARTS_PATH := "res://data/config/realm_hearts.json"
const REGIONAL_ENDING_PATH := "res://data/config/regional_ending_objectives.json"
const SPECIES_PATH := "res://data/creatures/species.json"
const ITEMS_PATH := "res://data/items/items.json"
const MULTIPLAYER_PATH := "res://data/config/multiplayer.json"

# The other realms' offer machinery, read as data/text so this test learns
# their species, flags, events and conversations instead of restating them.
const CLIMAX_CONFIG_PATH := "res://data/config/stronghold_climax.json"
const STORMWOOD_CHAPTER_PATH := "res://data/config/stormwood_chapter.json"
const VEILFALL_CONFIG_PATH := "res://data/config/water_veilfall.json"
const WATER_ROSTER_PATH := "res://data/config/water_roster.json"
const WATER_ENCOUNTERS_PATH := "res://data/config/water_encounters.json"
const STORMWOOD_ENDING_SCRIPT := "res://scripts/world/stormwood_ending.gd"
const WATER_GUARDIAN_SCRIPT := "res://scripts/world/water_guardian_reward.gd"

## Meadows (Veridian), Stormwood (Stormheart) and Tidewake (Guardian) offer
## controllers. Each must exist and carry legendary code, so a rename cannot
## quietly empty the closure check below.
const OFFER_CONTROLLERS := [
	"res://scripts/world/stronghold_climax.gd",
	"res://scripts/world/stormwood_ending.gd",
	"res://scripts/world/water_veilfall.gd",
	"res://scripts/world/water_guardian_reward.gd",
]

const WORLD_LEDGER := preload("res://scripts/net/world_ledger.gd")

## The only keys a trainer reward tier is paid from
## (trainer_npc.gd::reward_coins/reward_items/reward_xp_bonus).
const TRAINER_REWARD_KEYS := ["coins", "items", "xp_bonus"]

## Vocabulary a grant, reward or effect would use to hand over a creature.
const CREATURE_GRANT_PATTERN := "(creature|legendary|species|offer|volunteer|companion|ceremony|party|catch|adopt|pending_catch)"

var _cache: Dictionary = {}


# --- loading ---------------------------------------------------------------

func _json(path: String) -> Variant:
	if _cache.has(path):
		return _cache[path]
	var text := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text) if not text.is_empty() else null
	_cache[path] = parsed
	return parsed


func _dict(path: String) -> Dictionary:
	var parsed: Variant = _json(path)
	return parsed as Dictionary if parsed is Dictionary else {}


func _text(path: String) -> String:
	var key := "text:" + path
	if not _cache.has(key):
		_cache[key] = FileAccess.get_file_as_string(path)
	return str(_cache[key])


## `const NAME := "value"` string constants of a script, read as text so the
## scene-bound controllers never have to be loaded in an asset-free checkout.
static func _string_consts(source: String) -> Dictionary:
	var out := {}
	var re := RegEx.new()
	re.compile("(?m)^const\\s+([A-Z_][A-Z0-9_]*)\\s*:?=\\s*\"([^\"]*)\"")
	for m: RegExMatch in re.search_all(source):
		out[m.get_string(1)] = m.get_string(2)
	return out


## Source with comments removed, quote-aware per line, so documentation that
## says "no legendary offer" never reads as code that makes one.
static func _code_only(source: String) -> String:
	var kept: PackedStringArray = []
	for line: String in source.split("\n"):
		var quote := ""
		var cut := line.length()
		var i := 0
		while i < line.length():
			var c := line[i]
			if quote != "":
				if c == "\\":
					i += 1
				elif c == quote:
					quote = ""
			elif c == "\"" or c == "'":
				quote = c
			elif c == "#":
				cut = i
				break
			i += 1
		kept.append(line.substr(0, cut))
	return "\n".join(kept)


# --- derived facts ----------------------------------------------------------

## Every legendary species id, learned from data rather than restated here.
func _legendary_species() -> Dictionary:
	var out := {}
	var species: Dictionary = _dict(SPECIES_PATH).get("species", {})
	for id: String in species:
		var best: Variant = (species[id] as Dictionary).get("best_creature", {})
		# `legendary_presence`, not the `prestige` kind: alphas such as
		# Tempestwing/Voltarach are prestige too (`alpha_dominance`).
		if best is Dictionary and str(best.get("id", "")) == "legendary_presence":
			out[id] = "species.json best_creature legendary_presence"
	var climax_species := str((_dict(CLIMAX_CONFIG_PATH).get("legendary", {}) as Dictionary).get("species", ""))
	if climax_species != "":
		out[climax_species] = "stronghold_climax.json legendary.species (Meadows)"
	var stormwood_species := str(_string_consts(_text(STORMWOOD_ENDING_SCRIPT)).get("LEGENDARY_SPECIES", ""))
	if stormwood_species != "":
		out[stormwood_species] = "stormwood_ending.gd LEGENDARY_SPECIES (Stormwood)"
	var guardian := str(_dict(VEILFALL_CONFIG_PATH).get("guardian_species_id", ""))
	if guardian != "":
		out[guardian] = "water_veilfall.json guardian_species_id (Tidewake)"
	var roster: Variant = _dict(WATER_ROSTER_PATH).get("species", {})
	if roster is Dictionary:
		for id: String in roster:
			if str((roster[id] as Dictionary).get("combat_role", "")).begins_with("legendary"):
				out[id] = "water_roster.json combat_role legendary*"
	# Any authored table entry that calls itself legendary, in any realm.
	for path: String in [CHAPTER_PATH, STORMWOOD_CHAPTER_PATH]:
		for entry: Dictionary in _dicts_with_key(_json(path), "roster_identity"):
			if str(entry["roster_identity"]) == "legendary" and entry.has("placeholder_species"):
				out[str(entry["placeholder_species"])] = "%s roster_identity legendary" % path.get_file()
	return out


## Strings that name another realm's offer/receipt machinery.
func _offer_vocabulary() -> Array[String]:
	var vocab: Array[String] = ["pending_catch", "volunteer", "legendary_joined", "legendary_settled",
		WORLD_LEDGER.OWNED_FLAG_PREFIX_MARK]
	var climax_flags: Dictionary = _dict(CLIMAX_CONFIG_PATH).get("flags", {})
	for key: String in ["legendary_joined", "legendary_settled"]:
		if str(climax_flags.get(key, "")) != "":
			vocab.append(str(climax_flags[key]))
	for script: String in [STORMWOOD_ENDING_SCRIPT, WATER_GUARDIAN_SCRIPT]:
		var consts := _string_consts(_text(script))
		for name: String in consts:
			var value := str(consts[name])
			if value.length() >= 6 and RegEx.create_from_string(
					"(OFFER|LEGENDARY_|RESOLUTION|ANSWER|ACCEPT|RECEIPT|CLAIM|LEGACY|FREED)").search(name) != null:
				vocab.append(value)
	# Stormwood's offer is a chapter event: learn its name from the objective
	# whose flag is the offer flag.
	var offer_flag := str(_string_consts(_text(STORMWOOD_ENDING_SCRIPT)).get("OFFER_FLAG", ""))
	for objective: Dictionary in _dicts_with_key(_json(STORMWOOD_CHAPTER_PATH), "completion_event"):
		if str(objective.get("flag_id", "")) == offer_flag or "legendary" in str(objective.get("flag_id", "")):
			vocab.append(str(objective["completion_event"]))
	var unique: Array[String] = []
	for v: String in vocab:
		if v != "" and not unique.has(v):
			unique.append(v)
	return unique


## Offer conversation ids other realms open for their ceremony.
func _offer_conversations() -> Array[String]:
	var out: Array[String] = []
	var storm := _string_consts(_text(STORMWOOD_ENDING_SCRIPT))
	var water := _string_consts(_text(WATER_GUARDIAN_SCRIPT))
	for value: Variant in [storm.get("OFFER_CONVERSATION", ""), water.get("EDDA_OFFER", "")]:
		if str(value) != "":
			out.append(str(value))
	return out


## The Cloudreach data corpus: every file whose data belongs to the realm, plus
## the Cloudreach slices of shared registries.
func _corpus() -> Dictionary:
	var corpus := {}
	for file: String in DirAccess.get_files_at(CONFIG_DIR):
		if file.begins_with("cloudreach") and file.ends_with(".json"):
			corpus[file] = _json(CONFIG_DIR.path_join(file))
	corpus["dialogue/cloudreach.json"] = _json(DIALOGUE_PATH)
	corpus["recipes/recipes_cloudreach.json"] = _json(RECIPES_PATH)
	var hearts: Variant = _dict(REALM_HEARTS_PATH).get("hearts", {})
	corpus["realm_hearts.json:hearts.cloudreach"] = (hearts as Dictionary).get("cloudreach", {}) if hearts is Dictionary else {}
	var rows: Array = _dict(REGIONAL_ENDING_PATH).get("rows", [])
	var slices: Array = []
	for row: Variant in rows:
		if row is Dictionary:
			slices.append(((row as Dictionary).get("realms", {}) as Dictionary).get("cloudreach", {}))
	corpus["regional_ending_objectives.json:rows[].realms.cloudreach"] = slices
	return corpus


## The pending entry's path in the corpus walk, or "" when there is none/it is
## not allowed.
func _pending_entry_path(chapter: Dictionary) -> String:
	if not PENDING_OWNER_RULING_SOLMANE_SUMMIT_WILD:
		return ""
	var tables: Array = chapter.get("encounter_tables", [])
	for t in tables.size():
		var table: Dictionary = tables[t]
		if str(table.get("id", "")) != PENDING_TABLE_ID:
			continue
		var entries: Array = table.get("entries", [])
		for e in entries.size():
			if str((entries[e] as Dictionary).get("placeholder_species", "")) == PENDING_SPECIES:
				return "cloudreach_chapter.json:.encounter_tables[%d].entries[%d]" % [t, e]
	return ""


static func _dicts_with_key(node: Variant, key: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if node is Dictionary:
		if (node as Dictionary).has(key):
			out.append(node)
		for k: Variant in node:
			out.append_array(_dicts_with_key(node[k], key))
	elif node is Array:
		for v: Variant in node:
			out.append_array(_dicts_with_key(v, key))
	return out


## [path, key-or-value string] for every non-comment key and string value.
static func _strings(node: Variant, path: String, out: Array) -> void:
	if node is Dictionary:
		for k: Variant in node:
			var key := str(k)
			if key.begins_with("_"):
				continue
			out.append([path + "." + key, key])
			_strings(node[k], path + "." + key, out)
	elif node is Array:
		for i in (node as Array).size():
			_strings(node[i], "%s[%d]" % [path, i], out)
	elif node is String:
		out.append([path, str(node)])


# --- checks (each returns its violations) -------------------------------------

## Chapter rewards: realm heart/key/map unlock only; objective grants and the
## aftermath never grant or announce a creature.
static func _chapter_grant_violations(chapter: Dictionary, legendaries: Dictionary) -> Array[String]:
	var bad: Array[String] = []
	var grant_re := RegEx.create_from_string(CREATURE_GRANT_PATTERN)
	var rewards: Dictionary = chapter.get("rewards", {})
	var grants: Array = rewards.get("grants", [])
	if grants.is_empty():
		bad.append("rewards.grants is empty or missing; this check would judge nothing")
	for grant: Variant in grants:
		var g: Dictionary = grant if grant is Dictionary else {}
		var kind := str(g.get("kind", "")).to_lower()
		if grant_re.search(kind) != null:
			bad.append("rewards.grants '%s' has creature/offer kind '%s'" % [g.get("id", "?"), kind])
		for key: String in ["species", "species_id", "creature", "placeholder_species", "legendary", "offer"]:
			if g.has(key):
				bad.append("rewards.grants '%s' carries a '%s' field" % [g.get("id", "?"), key])
		for pair: Array in _strings_of(g):
			if legendaries.has(pair[1]) or "legendary" in str(pair[1]).to_lower():
				bad.append("rewards.grants '%s' names legendary '%s'" % [g.get("id", "?"), pair[1]])
	for feedback: Variant in rewards.get("completion_feedback", []):
		if grant_re.search(str(feedback).to_lower()) != null:
			bad.append("rewards.completion_feedback '%s' announces a creature/offer" % feedback)
	for objective: Dictionary in _dicts_with_key(chapter, "grants_flags"):
		for flag: Variant in objective["grants_flags"]:
			if "legendary" in str(flag).to_lower() or "volunteer" in str(flag).to_lower():
				bad.append("objective '%s' grants legendary flag '%s'" % [objective.get("id", "?"), flag])
	var aftermath: Dictionary = chapter.get("aftermath", {})
	for change: Variant in aftermath.get("state_changes", []):
		var c: Dictionary = change if change is Dictionary else {}
		var system := str(c.get("system", "")).to_lower()
		if system in ["party", "creatures", "roster", "legendary"]:
			bad.append("aftermath '%s' changes creature system '%s'" % [c.get("id", "?"), system])
		if "legendary" in str(c.get("change", "")).to_lower():
			bad.append("aftermath '%s' mentions a legendary" % c.get("id", "?"))
	return bad


static func _strings_of(node: Variant) -> Array:
	var out: Array = []
	_strings(node, "", out)
	return out


## Dialogue: every effect goes to the Cloudreach chapter's guarded dispatcher
## (cloudreach_chapter.gd handles only the `cloudreach:` prefix), none names an
## offer, and no conversation is another realm's offer conversation.
static func _dialogue_violations(dialogue: Dictionary, npc_runtime: Dictionary,
		vocab: Array[String], offer_conversations: Array[String]) -> Array[String]:
	var bad: Array[String] = []
	var conversations: Dictionary = dialogue.get("conversations", {})
	if conversations.is_empty():
		bad.append("data/dialogue/cloudreach.json has no conversations; this check would judge nothing")
	var grant_re := RegEx.create_from_string(CREATURE_GRANT_PATTERN)
	for id: String in conversations:
		if offer_conversations.has(id):
			bad.append("conversation '%s' is another realm's legendary offer conversation" % id)
		var effects: Array[String] = []
		for node: Dictionary in _dicts_with_key(conversations[id], "effect"):
			effects.append(str(node["effect"]))
		for node: Dictionary in _dicts_with_key(conversations[id], "confirm_effect"):
			effects.append(str(node["confirm_effect"]))
		for key: String in ["effects", "confirm_effects"]:
			for node: Dictionary in _dicts_with_key(conversations[id], key):
				for e: Variant in node[key]:
					effects.append(str(e))
		for effect: String in effects:
			if effect == "":
				continue
			var prefix := effect.get_slice(":", 0)
			if prefix != "cloudreach":
				bad.append("'%s' effect '%s' is not a guarded cloudreach: chapter event" % [id, effect])
			if grant_re.search(effect.substr(prefix.length()).to_lower()) != null:
				bad.append("'%s' effect '%s' names a creature/offer" % [id, effect])
			for word: String in vocab:
				if word in effect:
					bad.append("'%s' effect '%s' uses offer machinery '%s'" % [id, effect, word])
	for guard: Variant in npc_runtime.get("dialogue_event_guards", []):
		var event := str((guard as Dictionary).get("event", "")) if guard is Dictionary else ""
		if "legendary" in event.to_lower() or grant_re.search(event.to_lower()) != null:
			bad.append("dialogue guard event '%s' names a legendary/offer" % event)
	return bad


## Trainer tiers pay coins/items/xp only; items are items, never creatures;
## every reward/grant subtree anywhere in the corpus is creature-free.
static func _reward_violations(encounters: Dictionary, npc_runtime: Dictionary, corpus: Dictionary,
		items: Dictionary, all_species: Dictionary, legendaries: Dictionary) -> Array[String]:
	var bad: Array[String] = []
	var tiers: Dictionary = encounters.get("reward_tiers", {})
	if tiers.is_empty():
		bad.append("cloudreach_encounters.json reward_tiers is empty; this check would judge nothing")
	for tier: String in tiers:
		var reward: Dictionary = tiers[tier] if tiers[tier] is Dictionary else {}
		for key: String in reward:
			if not key.begins_with("_") and not TRAINER_REWARD_KEYS.has(key):
				bad.append("trainer reward tier '%s' has non-payable key '%s'" % [tier, key])
		for entry: Variant in reward.get("items", []):
			var item_id := str((entry as Dictionary).get("id", "")) if entry is Dictionary else str(entry)
			if all_species.has(item_id):
				bad.append("trainer reward tier '%s' pays species '%s' as an item" % [tier, item_id])
			var definition: Variant = items.get(item_id, null)
			if definition is Dictionary and str((definition as Dictionary).get("kind", "")) in ["creature", "egg", "legendary"]:
				bad.append("trainer reward tier '%s' pays creature item '%s'" % [tier, item_id])
	for payoff: Dictionary in _dicts_with_key(npc_runtime, "reward_tier"):
		if not tiers.has(str(payoff["reward_tier"])):
			bad.append("npc runtime references unknown reward tier '%s'" % payoff["reward_tier"])
	# Every reward/grant-shaped subtree in every Cloudreach file.
	var grant_re := RegEx.create_from_string(CREATURE_GRANT_PATTERN)
	var key_re := RegEx.create_from_string("(reward|grant|gift|give)")
	for file: String in corpus:
		var hits: Array = []
		_strings(corpus[file], file + ":", hits)
		for pair: Array in hits:
			var path := str(pair[0])
			var leaf := path.get_slice(".", path.get_slice_count(".") - 1).get_slice("[", 0)
			# Only judge the values under a reward-shaped key.
			var under_reward := false
			for part: String in path.split("."):
				if key_re.search(part.get_slice("[", 0).to_lower()) != null \
						and not part.begins_with("grants_flags") and not part.begins_with("giver_npc_id") \
						and not part.begins_with("granted_at"):
					under_reward = true
			if not under_reward:
				continue
			var value := str(pair[1])
			if legendaries.has(value):
				bad.append("%s rewards legendary '%s'" % [path, value])
			elif (leaf == "kind" or leaf == "type") and grant_re.search(value.to_lower()) != null:
				bad.append("%s is a creature/offer grant kind '%s'" % [path, value])
			elif leaf in ["species", "species_id", "creature", "placeholder_species"]:
				bad.append("%s grants a creature '%s'" % [path, value])
	return bad


## No legendary mention and no other-realm offer vocabulary anywhere in the
## Cloudreach corpus, except the pending summit entry.
static func _corpus_violations(corpus: Dictionary, vocab: Array[String], pending_path: String) -> Array[String]:
	var bad: Array[String] = []
	for file: String in corpus:
		var hits: Array = []
		_strings(corpus[file], file + ":", hits)
		for pair: Array in hits:
			var path := str(pair[0])
			var value := str(pair[1])
			if pending_path != "" and path.begins_with(pending_path + "."):
				continue
			if "legendary" in value.to_lower():
				bad.append("%s mentions legendary ('%s')" % [path, value.left(80)])
			for word: String in vocab:
				if word in value:
					bad.append("%s uses offer machinery '%s'" % [path, word])
	return bad


## No legendary species id anywhere in the corpus outside the pending entry:
## not a trainer slot, reward, pickup, NPC or finale field.
static func _species_violations(corpus: Dictionary, legendaries: Dictionary, pending_path: String) -> Array[String]:
	var bad: Array[String] = []
	for file: String in corpus:
		var hits: Array = []
		_strings(corpus[file], file + ":", hits)
		for pair: Array in hits:
			var path := str(pair[0])
			if legendaries.has(str(pair[1])) and not (pending_path != "" and path.begins_with(pending_path + ".")):
				bad.append("%s names legendary species '%s' (%s)" % [path, pair[1], legendaries[str(pair[1])]])
	return bad


## {table_id: [legendary species]} over every Cloudreach wild table.
static func _wild_table_legendaries(chapter: Dictionary, legendaries: Dictionary) -> Dictionary:
	var out := {}
	for table: Variant in chapter.get("encounter_tables", []):
		var t: Dictionary = table if table is Dictionary else {}
		for entry: Variant in t.get("entries", []):
			var e: Dictionary = entry if entry is Dictionary else {}
			var species := str(e.get("placeholder_species", e.get("species", "")))
			if legendaries.has(species) or str(e.get("roster_identity", "")) == "legendary":
				var id := str(t.get("id", "?"))
				if not out.has(id):
					out[id] = []
				(out[id] as Array).append(species)
	return out


## Cloudreach scripts: no code that mints, hands over or resolves a legendary.
static func _source_violations(sources: Dictionary, vocab: Array[String]) -> Array[String]:
	var bad: Array[String] = []
	var party_add := RegEx.create_from_string("party\\b[^\\n]*(\\.add\\(|call\\(\\s*\"add\")")
	var tokens: Array[String] = ["legendary", "may_receive(", "offer_owed(", "pending_catch"]
	for controller: String in OFFER_CONTROLLERS:
		tokens.append(controller.get_file())
	for word: String in vocab:
		if not tokens.has(word):
			tokens.append(word)
	for path: String in sources:
		var code := _code_only(str(sources[path]))
		for token: String in tokens:
			if token in code:
				bad.append("%s code references '%s'" % [path, token])
		var m := party_add.search(code)
		if m != null:
			bad.append("%s adds a creature to the party: '%s'" % [path, m.get_string().strip_edges().left(80)])
	return bad


static func _deps(code: String) -> Array[String]:
	var out: Array[String] = []
	var re := RegEx.create_from_string("(?:preload|load)\\(\\s*\"(res://[^\"]+\\.gd)\"|(?m)^extends\\s+\"(res://[^\"]+\\.gd)\"")
	for m: RegExMatch in re.search_all(code):
		out.append(m.get_string(1) if m.get_string(1) != "" else m.get_string(2))
	return out


## No Cloudreach script reaches an offer controller through preload/load/
## extends. `overrides` substitutes source text (negative control).
func _closure_violations(starts: Array[String], overrides: Dictionary) -> Array[String]:
	var bad: Array[String] = []
	var parent := {}
	var seen := {}
	var stack: Array[String] = starts.duplicate()
	while not stack.is_empty():
		var path: String = stack.pop_back()
		if seen.has(path):
			continue
		seen[path] = true
		var source := str(overrides[path]) if overrides.has(path) else _text(path)
		for dep: String in _deps(_code_only(source)):
			if not seen.has(dep):
				if not parent.has(dep):
					parent[dep] = path
				stack.append(dep)
	for controller: String in OFFER_CONTROLLERS:
		if seen.has(controller):
			var chain: Array[String] = [controller]
			while parent.has(chain[-1]):
				chain.append(str(parent[chain[-1]]))
			bad.append("Cloudreach reaches offer controller: %s" % " <- ".join(chain))
	return bad


## The other realms' offer registries never name Cloudreach.
static func _registry_violations(ledger_prefixes: Array, offer_configs: Dictionary,
		controller_sources: Dictionary) -> Array[String]:
	var bad: Array[String] = []
	for prefix: Variant in ledger_prefixes:
		if "cloudreach" in str(prefix).to_lower():
			bad.append("legendary receipt prefix '%s' names Cloudreach" % prefix)
	for label: String in offer_configs:
		var hits: Array = []
		_strings(offer_configs[label], label + ":", hits)
		for pair: Array in hits:
			if "cloudreach" in str(pair[1]).to_lower():
				bad.append("%s names Cloudreach ('%s')" % [pair[0], str(pair[1]).left(80)])
	for path: String in controller_sources:
		if "cloudreach" in _code_only(str(controller_sources[path])).to_lower():
			bad.append("offer controller %s references Cloudreach in code" % path)
	return bad


# --- inputs for the checks ---------------------------------------------------

func _cloudreach_scripts() -> Array[String]:
	var out: Array[String] = []
	for dir: String in ["res://scripts/world", "res://scripts/combat", "res://scripts/ui", "res://scripts/net", "res://autoload"]:
		for file: String in DirAccess.get_files_at(dir):
			if file.ends_with(".gd") and "cloudreach" in file:
				out.append(dir.path_join(file))
	out.sort()
	return out


func _sources(paths: Array[String]) -> Dictionary:
	var out := {}
	for path: String in paths:
		out[path] = _text(path)
	return out


func _offer_controllers() -> Array[String]:
	var out: Array[String] = []
	for path: String in OFFER_CONTROLLERS:
		out.append(path)
	return out


func _ledger_prefixes() -> Array:
	var prefixes: Array = WORLD_LEDGER.OWNED_FLAG_PREFIXES.duplicate()
	var ledger: Variant = _dict(MULTIPLAYER_PATH).get("ledger", {})
	if ledger is Dictionary:
		prefixes.append_array((ledger as Dictionary).get("owned_flag_prefixes", []))
	return prefixes


func _offer_configs() -> Dictionary:
	var climax := _dict(CLIMAX_CONFIG_PATH)
	var veilfall := _dict(VEILFALL_CONFIG_PATH)
	var guardian := {}
	for key: String in veilfall:
		if key.begins_with("guardian"):
			guardian[key] = veilfall[key]
	var storm_objectives: Array = []
	for objective: Dictionary in _dicts_with_key(_json(STORMWOOD_CHAPTER_PATH), "flag_id"):
		if "legendary" in str(objective["flag_id"]):
			storm_objectives.append(objective)
	var water_ceremonies: Array = []
	for entry: Dictionary in _dicts_with_key(_json(WATER_ENCOUNTERS_PATH), "role"):
		if "legendary" in str(entry["role"]):
			water_ceremonies.append(entry)
	return {
		"stronghold_climax.json:legendary": climax.get("legendary", {}),
		"stronghold_climax.json:flags": climax.get("flags", {}),
		"water_veilfall.json:guardian_*": guardian,
		"stormwood_chapter.json:legendary objectives": storm_objectives,
		"water_encounters.json:legendary ceremonies": water_ceremonies,
	}


func _items() -> Dictionary:
	var items: Dictionary = _dict(ITEMS_PATH)
	var nested: Variant = items.get("items", null)
	return nested as Dictionary if nested is Dictionary else items


func _all_species() -> Dictionary:
	var out: Dictionary = (_dict(SPECIES_PATH).get("species", {}) as Dictionary).duplicate()
	var roster: Variant = _dict(WATER_ROSTER_PATH).get("species", {})
	if roster is Dictionary:
		out.merge(roster as Dictionary)
	out.merge(_legendary_species())
	return out


func _report(label: String, bad: Array[String]) -> void:
	for line: String in bad:
		print("    VIOLATION %s: %s" % [label, line])
	assert_true(bad.is_empty(), "%s: %d violation(s), first: %s" % [label, bad.size(), bad[0] if not bad.is_empty() else ""])


# --- tests --------------------------------------------------------------------

func test_legendary_species_are_derived_from_every_realm() -> void:
	var legendaries := _legendary_species()
	print("    INFO legendary species derived from data: %s" % ", ".join(PackedStringArray(legendaries.keys())))
	# The derivation must see each realm's offer, or every check below that
	# keys on species would pass by knowing nothing.
	assert_true(legendaries.has(str((_dict(CLIMAX_CONFIG_PATH).get("legendary", {}) as Dictionary).get("species", "?"))),
		"Meadows' Veridian comes from stronghold_climax.json")
	assert_true(legendaries.has(str(_string_consts(_text(STORMWOOD_ENDING_SCRIPT)).get("LEGENDARY_SPECIES", "?"))),
		"Stormwood's Stormheart species comes from stormwood_ending.gd")
	assert_true(legendaries.has(str(_dict(VEILFALL_CONFIG_PATH).get("guardian_species_id", "?"))),
		"Tidewake's Guardian comes from water_veilfall.json")
	assert_true(legendaries.size() >= 4, "at least four legendary ids are known, got %d" % legendaries.size())
	for controller: String in OFFER_CONTROLLERS:
		assert_true(FileAccess.file_exists(controller), "offer controller %s exists" % controller)
		assert_true("legendary" in _code_only(_text(controller)).to_lower() or "guardian" in _code_only(_text(controller)).to_lower(),
			"%s still carries legendary offer code" % controller)
	assert_true(_offer_vocabulary().size() >= 8, "offer vocabulary was learned from the other realms")
	assert_true(_offer_conversations().size() >= 2, "Stormwood and Tidewake offer conversations were found")


func test_chapter_rewards_grant_no_creature_legendary_or_offer() -> void:
	_report("chapter grants", _chapter_grant_violations(_dict(CHAPTER_PATH), _legendary_species()))


func test_finale_config_and_whole_cloudreach_corpus_name_no_legendary_offer() -> void:
	var corpus := _corpus()
	assert_true(corpus.has("cloudreach_finale.json") and not (corpus["cloudreach_finale.json"] as Dictionary).is_empty(),
		"the finale config is part of the scanned corpus")
	assert_true(corpus.size() >= 10, "the Cloudreach corpus has its configs, dialogue and shared slices (%d)" % corpus.size())
	_report("corpus", _corpus_violations(corpus, _offer_vocabulary(), _pending_entry_path(_dict(CHAPTER_PATH))))


func test_finale_controller_and_every_cloudreach_script_make_no_offer() -> void:
	var scripts := _cloudreach_scripts()
	assert_true(scripts.has("res://scripts/world/cloudreach_finale_controller.gd"), "the finale controller is scanned")
	assert_true(scripts.has("res://scripts/world/cloudreach_chapter.gd"), "the chapter reward adapter is scanned")
	assert_true(scripts.has("res://scripts/combat/cloudreach_encounter_director.gd"), "the trainer reward director is scanned")
	_report("scripts", _source_violations(_sources(scripts), _offer_vocabulary()))


func test_no_cloudreach_script_reaches_another_realms_offer_controller() -> void:
	_report("closure", _closure_violations(_cloudreach_scripts(), {}))


func test_cloudreach_dialogue_effects_grant_no_creature_or_offer() -> void:
	_report("dialogue", _dialogue_violations(_dict(DIALOGUE_PATH), _dict(NPC_RUNTIME_PATH),
		_offer_vocabulary(), _offer_conversations()))


func test_trainer_and_activity_rewards_grant_no_creature() -> void:
	_report("rewards", _reward_violations(_dict(ENCOUNTERS_PATH), _dict(NPC_RUNTIME_PATH), _corpus(),
		_items(), _all_species(), _legendary_species()))


func test_no_legendary_species_anywhere_in_cloudreach_data_but_the_pending_entry() -> void:
	_report("species", _species_violations(_corpus(), _legendary_species(), _pending_entry_path(_dict(CHAPTER_PATH))))


func test_other_realms_offer_registries_do_not_name_cloudreach() -> void:
	_report("registries", _registry_violations(_ledger_prefixes(), _offer_configs(), _sources(_offer_controllers())))


func test_pending_solmane_is_the_only_wild_legendary_in_cloudreach() -> void:
	var found := _wild_table_legendaries(_dict(CHAPTER_PATH), _legendary_species())
	var expected := {PENDING_TABLE_ID: [PENDING_SPECIES]} if PENDING_OWNER_RULING_SOLMANE_SUMMIT_WILD else {}
	if PENDING_OWNER_RULING_SOLMANE_SUMMIT_WILD:
		assert_ne(_pending_entry_path(_dict(CHAPTER_PATH)), "",
			"the pending entry still exists; if the owner removed it, flip PENDING_OWNER_RULING_SOLMANE_SUMMIT_WILD")
		print("    INFO PENDING OWNER DECISION: cloudreach_chapter.json '%s' lists '%s' (roster_identity legendary) as a catchable wild. " % [PENDING_TABLE_ID, PENDING_SPECIES]
			+ "It is not an adoption offer and is tolerated only until ruled on; flip PENDING_OWNER_RULING_SOLMANE_SUMMIT_WILD in tests/test_cloudreach_no_legendary_offer.gd.")
	assert_eq(found, expected, "legendary species in Cloudreach wild tables")


# --- negative controls: the same checks, one fake legendary path each --------

func _control(label: String, bad: Array[String]) -> void:
	assert_false(bad.is_empty(), "negative control '%s' must produce a violation" % label)
	print("    NEGATIVE-CONTROL %s fired: %s" % [label, bad[0] if not bad.is_empty() else "NOTHING (check is blind)"])


func test_negative_control_fake_legendary_chapter_grant() -> void:
	var chapter: Dictionary = _dict(CHAPTER_PATH).duplicate(true)
	(chapter["rewards"]["grants"] as Array).append(
		{"id": "fake_solmane_offer", "kind": "legendary_offer", "species": PENDING_SPECIES})
	_control("chapter grant", _chapter_grant_violations(chapter, _legendary_species()))


func test_negative_control_fake_offer_in_finale_config() -> void:
	var corpus := _corpus().duplicate(true)
	(corpus["cloudreach_finale.json"] as Dictionary)["aftermath_offer_flag"] = "stormwood:legendary_offer_made"
	_control("finale corpus", _corpus_violations(corpus, _offer_vocabulary(), _pending_entry_path(_dict(CHAPTER_PATH))))


func test_negative_control_fake_ceremony_in_finale_controller() -> void:
	var sources := _sources(_cloudreach_scripts())
	var path := "res://scripts/world/cloudreach_finale_controller.gd"
	sources[path] = str(sources[path]) + "\nfunc _fake() -> void:\n\tgame.set(\"pending_catch\", creature)\n\tgame.get(\"party\").call(\"add\", creature)\n"
	_control("finale controller", _source_violations(sources, _offer_vocabulary()))


func test_negative_control_fake_offer_controller_preload() -> void:
	var path := "res://scripts/world/cloudreach_finale_controller.gd"
	var fake := {path: _text(path) + "\nconst FAKE := preload(\"res://scripts/world/stormwood_ending.gd\")\n"}
	_control("closure", _closure_violations(_cloudreach_scripts(), fake))


func test_negative_control_fake_dialogue_offer_effect() -> void:
	var dialogue: Dictionary = _dict(DIALOGUE_PATH).duplicate(true)
	(dialogue["conversations"] as Dictionary)["cloudreach_fake_volunteer"] = {
		"lines": [{"speaker": "Solmane", "text": "Take me.", "confirm_effect": "stormheart:accept"}]}
	_control("dialogue", _dialogue_violations(dialogue, _dict(NPC_RUNTIME_PATH), _offer_vocabulary(), _offer_conversations()))


func test_negative_control_fake_trainer_creature_reward() -> void:
	var encounters: Dictionary = _dict(ENCOUNTERS_PATH).duplicate(true)
	(encounters["reward_tiers"]["captain"] as Dictionary)["creature"] = {"species": PENDING_SPECIES}
	_control("trainer reward", _reward_violations(encounters, _dict(NPC_RUNTIME_PATH), _corpus(),
		_items(), _all_species(), _legendary_species()))


func test_negative_control_fake_activity_reward_grant() -> void:
	var corpus := _corpus().duplicate(true)
	(corpus["cloudreach_physical_runtime.json"] as Dictionary)["activity_rewards"] = {
		"aerie_trial": {"kind": "creature", "species": "fulgocobra"}}
	_control("activity reward", _reward_violations(_dict(ENCOUNTERS_PATH), _dict(NPC_RUNTIME_PATH), corpus,
		_items(), _all_species(), _legendary_species()))


func test_negative_control_fake_legendary_trainer_slot() -> void:
	var corpus := _corpus().duplicate(true)
	var ladder: Array = (corpus["cloudreach_chapter.json"] as Dictionary)["trainer_ladder"]
	(ladder[0]["team_contract"]["slots"] as Array).append({"role": "fake", "placeholder_species": "veridian", "level": 30})
	_control("trainer slot", _species_violations(corpus, _legendary_species(), _pending_entry_path(_dict(CHAPTER_PATH))))


func test_negative_control_second_wild_legendary() -> void:
	var chapter: Dictionary = _dict(CHAPTER_PATH).duplicate(true)
	(chapter["encounter_tables"][0]["entries"] as Array).append({"role": "fake", "placeholder_species": "fulgocobra", "weight": 1})
	var found := _wild_table_legendaries(chapter, _legendary_species())
	var expected := {PENDING_TABLE_ID: [PENDING_SPECIES]} if PENDING_OWNER_RULING_SOLMANE_SUMMIT_WILD else {}
	assert_ne(found, expected, "negative control 'second wild legendary' must differ from the allowed set")
	print("    NEGATIVE-CONTROL second wild legendary fired: found %s, allowed %s" % [found, expected])


func test_negative_control_fake_cloudreach_receipt_registry() -> void:
	var prefixes := _ledger_prefixes()
	prefixes.append("cloudreach:legendary_resolution:accepted:")
	_control("registry", _registry_violations(prefixes, _offer_configs(), {}))
