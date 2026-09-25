extends "res://tests/test_case.gd"

## ACCEPTANCE §6 Cloudreach card ("Cloudreach has no legendary adoption
## offer"), C3 ("No legendary offer appears") and the §6.1 F08 row
## ("Cloudreach presents no legendary offer"); CREATURES §2 legendary row:
## "Cloudreach ends in Wings/reconnection and has no legendary offer."
##
## Pure data and source text. Nothing here instantiates a scene, so it runs in
## the sparse, asset-free checkout as well as a full tree. Each check is a
## function that takes the data it judges and returns its violations; the
## `test_negative_control_*` methods feed those same functions an in-memory
## copy with one fake legendary path added and require a violation, and
## `test_harmless_*` requires ordinary Cloudreach words to pass, so a check
## that silently stopped looking, or started matching prose, fails here.
##
## Where an offer could come from, and the check that covers it:
##   * chapter reward grants, objective grants_flags, aftermath -> _chapter_grant_violations
##   * the finale config and every Cloudreach data file -> _corpus_violations
##   * Cloudreach dialogue effects and guards -> _dialogue_violations
##   * trainer reward tiers and every reward/grant subtree -> _reward_violations
##   * every Cloudreach-owned script (named *cloudreach*, or referenced only
##     by Cloudreach-owned scripts/scenes) -> _source_violations
##   * any line in scripts/ or autoload/ tying Cloudreach to a legendary -> _cross_scan_violations
##   * the other realms' offer controllers, reachable from Cloudreach -> _closure_violations
##   * the other realms' offer registries naming Cloudreach -> _registry_violations
##   * legendary species anywhere in Cloudreach data -> _species_violations,
##     _wild_table_legendaries
##
## Vocabulary is applied to identifiers only (effect ids, flags, keys, kinds,
## code), never to spoken or descriptive prose: "the legendary skyroad" in a
## line of dialogue is scenery, `cloudreach:legendary_joined` is machinery.

## KNOWN PENDING DECISION, not hidden and not failed on. Coordinator: flip this
## to false once the owner rules `solmane` out of the Cloudreach summit wild
## table, and the test then requires every Cloudreach wild table to carry no
## legendary at all.
##
## data/config/cloudreach_chapter.json's `cloudreach_summit_wild` table lists
## `solmane` with `roster_identity: "legendary"` as a CATCHABLE WILD. That is a
## wild encounter, not an adoption offer, and the legendary rules (CREATURES
## §2/§8: "trainer and legendary encounters refuse" capture; freed legendaries
## volunteer) have not been reconciled with it. While true, exactly two leaves
## of exactly that entry are exempt (its `placeholder_species` and
## `roster_identity`), and the entry may carry no other key.
const PENDING_OWNER_RULING_SOLMANE_SUMMIT_WILD := true
const PENDING_TABLE_ID := "cloudreach_summit_wild"
const PENDING_SPECIES := "solmane"
const PENDING_ENTRY_KEYS := ["placeholder_species", "role", "roster_identity", "weight"]
const PENDING_EXEMPT_LEAVES := [".placeholder_species", ".roster_identity"]

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

## Cloudreach config files at the time of writing; the corpus is these plus
## dialogue, recipes and two shared-registry slices. A new cloudreach_*.json
## raises the count and is scanned automatically; a vanished one fails.
const MIN_CLOUDREACH_CONFIG_FILES := 22
const CORPUS_EXTRA_ENTRIES := 4

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

## The shared "a creature joins this belt" seam. Shared code (catching, the
## Meadows starter, trades) legitimately calls it; Cloudreach-owned code never
## may.
const PARTY_SEAM := "res://scripts/story/party_seam.gd"

const SOURCE_ROOTS := ["res://scripts", "res://autoload", "res://scenes"]
const CROSS_SCAN_ROOTS := ["res://scripts", "res://autoload"]

## Existing Meadows lines that mention Cloudreach next to `legendary_freed`:
## the Warden's victory sets `legendary_freed` and grants `realm_key_cloudreach`
## together, so both files name the pair when deciding whether Cloudreach is
## reachable. Neither offers anything. Exact [file, stripped line] pairs, not
## line numbers, so an unrelated edit above them does not break the allowance
## and any new or reworded line is judged afresh.
const CROSS_SCAN_ALLOWED := [
	["res://scripts/ui/tab_map.gd", "## `realm_key_cloudreach` at the same beat `legendary_freed` is set;"],
	["res://scripts/ui/tab_map.gd", "\"legendary_freed\", \"realm_key_cloudreach\", \"cloudreach_chapter_started\","],
	["res://scripts/world/rift_crossing.gd", "## `realm_key_cloudreach` at the same moment as `legendary_freed`, so this"],
]

const WORLD_LEDGER := preload("res://scripts/net/world_ledger.gd")

## The only keys a trainer reward tier is paid from
## (trainer_npc.gd::reward_coins/reward_items/reward_xp_bonus).
const TRAINER_REWARD_KEYS := ["coins", "items", "xp_bonus"]

## An identifier hands over a creature when it pairs a grant verb with a
## creature noun (`companion_joins`), never on either word alone
## (`companion_rests`, `aviary_catch_hint`, `interaction_offer`).
const GRANT_VERB := "(join|grant|give|gift|adopt|offer|volunteer|recruit)"
const CREATURE_NOUN := "(creature|legendary|species|companion|partner)"
## Inside a grant/reward, the kind itself names what is handed over.
const GRANT_KIND_NOUN := "(creature|legendary|species|companion|offer|volunteer|adopt)"
const IDENTIFIER := "^[A-Za-z0-9_:\\-./\\[\\]]+$"

var _cache: Dictionary = {}
var _missing_inputs: Array[String] = []


# --- loading -------------------------------------------------------------------

func _json(path: String) -> Variant:
	if _cache.has(path):
		return _cache[path]
	var text := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text) if not text.is_empty() else null
	if parsed == null and not _missing_inputs.has(path):
		_missing_inputs.append(path)
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


## `const NAME := "value"` and `const NAME: String = "value"` string constants
## of a script, read as text so the scene-bound controllers never have to be
## loaded in an asset-free checkout.
static func _string_consts(source: String) -> Dictionary:
	var out := {}
	var re := RegEx.create_from_string(
		"(?m)^const\\s+([A-Z_][A-Z0-9_]*)\\s*(?::\\s*[A-Za-z]+\\s*)?:?=\\s*\"([^\"]*)\"")
	for m: RegExMatch in re.search_all(source):
		out[m.get_string(1)] = m.get_string(2)
	return out


## Source with comments removed, quote-aware per line, so documentation that
## says "no legendary offer" never reads as code that makes one.
static func _code_only(source: String) -> String:
	var kept: PackedStringArray = []
	for line: String in source.split("\n"):
		var mark := line.find("#")
		if mark == -1:
			kept.append(line)
			continue
		if line.strip_edges().begins_with("#"):
			kept.append("")
			continue
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


## Walk a fixed shape; null when any step is missing or the wrong type.
static func _at(root: Variant, steps: Array) -> Variant:
	var node: Variant = root
	for step: Variant in steps:
		if step is int and node is Array and int(step) < (node as Array).size():
			node = node[step]
		elif step is String and node is Dictionary and (node as Dictionary).has(step):
			node = node[step]
		else:
			return null
	return node


## A shape a check depends on. Records a violation instead of letting a typed
## assignment abort the method, which the runner would report as "ok".
static func _as_dict(value: Variant, what: String, bad: Array[String]) -> Dictionary:
	if value is Dictionary:
		return value
	bad.append("SHAPE: %s is not a dictionary (%s)" % [what, type_string(typeof(value))])
	return {}


static func _as_array(value: Variant, what: String, bad: Array[String]) -> Array:
	if value is Array:
		return value
	bad.append("SHAPE: %s is not an array (%s)" % [what, type_string(typeof(value))])
	return []


# --- derived facts -----------------------------------------------------------------

## Every legendary species id, learned from data rather than restated here.
func _legendary_species() -> Dictionary:
	var out := {}
	var species: Variant = _dict(SPECIES_PATH).get("species", {})
	if species is Dictionary:
		for id: String in species:
			# `legendary_presence`, not the `prestige` kind: alphas such as
			# Tempestwing/Voltarach are prestige too (`alpha_dominance`).
			if str(_at(species, [id, "best_creature", "id"])) == "legendary_presence":
				out[id] = "species.json best_creature legendary_presence"
	var climax_species: Variant = _at(_dict(CLIMAX_CONFIG_PATH), ["legendary", "species"])
	if climax_species is String and climax_species != "":
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
			if str(_at(roster, [id, "combat_role"])).begins_with("legendary"):
				out[id] = "water_roster.json combat_role legendary*"
	# Any authored table entry that calls itself legendary, in any realm.
	for path: String in [CHAPTER_PATH, STORMWOOD_CHAPTER_PATH]:
		for entry: Dictionary in _dicts_with_key(_json(path), "roster_identity"):
			if str(entry["roster_identity"]) == "legendary" and entry.has("placeholder_species"):
				out[str(entry["placeholder_species"])] = "%s roster_identity legendary" % path.get_file()
	return out


## Offer/receipt identifiers from one offer script: flags, prefixes, events and
## conversations, never display names (a value with a space) and never the
## shared capture-codec receipt prefix (RECEIPT_PREFIX is not offer machinery).
static func _script_vocabulary(source: String) -> Array[String]:
	var out: Array[String] = []
	var consts := _string_consts(source)
	var name_re := RegEx.create_from_string("(OFFER|RESOLUTION|ANSWER|ACCEPT|CLAIM|LEGACY|FREED|RECEIPT_FLAG)")
	for name: String in consts:
		var value := str(consts[name])
		if value.length() >= 6 and not " " in value and name_re.search(name) != null:
			out.append(value)
	return out


## Identifiers that name another realm's offer/receipt machinery.
func _offer_vocabulary() -> Array[String]:
	var vocab: Array[String] = ["pending_catch", "volunteer", "legendary_joined", "legendary_settled",
		WORLD_LEDGER.OWNED_FLAG_PREFIX_MARK]
	var climax_flags: Variant = _dict(CLIMAX_CONFIG_PATH).get("flags", {})
	for key: String in ["legendary_joined", "legendary_settled"]:
		if str(_at(climax_flags, [key])) not in ["", "<null>"]:
			vocab.append(str(climax_flags[key]))
	vocab.append_array(_script_vocabulary(_text(STORMWOOD_ENDING_SCRIPT)))
	vocab.append_array(_script_vocabulary(_text(WATER_GUARDIAN_SCRIPT)))
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


func _cloudreach_config_files() -> Array[String]:
	var out: Array[String] = []
	for file: String in DirAccess.get_files_at(CONFIG_DIR):
		if file.begins_with("cloudreach") and file.ends_with(".json"):
			out.append(file)
	out.sort()
	return out


## The Cloudreach data corpus: every file whose data belongs to the realm, plus
## the Cloudreach slices of shared registries.
func _corpus() -> Dictionary:
	var corpus := {}
	for file: String in _cloudreach_config_files():
		corpus[file] = _json(CONFIG_DIR.path_join(file))
	corpus["dialogue/cloudreach.json"] = _json(DIALOGUE_PATH)
	corpus["recipes/recipes_cloudreach.json"] = _json(RECIPES_PATH)
	corpus["realm_hearts.json:hearts.cloudreach"] = _at(_dict(REALM_HEARTS_PATH), ["hearts", "cloudreach"])
	var slices: Array = []
	var rows: Variant = _dict(REGIONAL_ENDING_PATH).get("rows", [])
	if rows is Array:
		for row: Variant in rows:
			slices.append(_at(row, ["realms", "cloudreach"]))
	corpus["regional_ending_objectives.json:rows[].realms.cloudreach"] = slices
	return corpus


## Path (in `_strings` form) of the pending entry, or "" when there is none or
## it is not allowed.
func _pending_entry_path(chapter: Dictionary) -> String:
	if not PENDING_OWNER_RULING_SOLMANE_SUMMIT_WILD:
		return ""
	var tables: Variant = chapter.get("encounter_tables", [])
	if not tables is Array:
		return ""
	for t in (tables as Array).size():
		if str(_at(tables, [t, "id"])) != PENDING_TABLE_ID:
			continue
		var entries: Variant = _at(tables, [t, "entries"])
		if not entries is Array:
			return ""
		for e in (entries as Array).size():
			if str(_at(entries, [e, "placeholder_species"])) == PENDING_SPECIES:
				return "cloudreach_chapter.json:.encounter_tables[%d].entries[%d]" % [t, e]
	return ""


## The two exact leaves of the pending entry the corpus/species scans skip.
func _pending_exempt(chapter: Dictionary) -> Dictionary:
	var out := {}
	var entry := _pending_entry_path(chapter)
	if entry != "":
		for leaf: String in PENDING_EXEMPT_LEAVES:
			out[entry + leaf] = true
	return out


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


static func _strings_of(node: Variant) -> Array:
	var out: Array = []
	_strings(node, "", out)
	return out


static func _is_identifier(text: String) -> bool:
	return RegEx.create_from_string(IDENTIFIER).search(text) != null


## Why an identifier (effect id, flag, key, kind, event) would hand over or
## announce a legendary/creature, or "" when it does not.
static func _identifier_reason(token: String, legendaries: Dictionary, vocab: Array[String]) -> String:
	var lower := token.to_lower()
	if "legendary" in lower:
		return "names 'legendary'"
	for id: String in legendaries:
		if id in lower:
			return "names legendary species '%s'" % id
	for word: String in vocab:
		if word in token:
			return "uses offer machinery '%s'" % word
	if RegEx.create_from_string(GRANT_VERB).search(lower) != null \
			and RegEx.create_from_string(CREATURE_NOUN).search(lower) != null:
		return "pairs a grant verb with a creature noun"
	return ""


# --- data checks (each returns its violations) -------------------------------------

## Chapter rewards: realm heart/key/map unlock only; objective grants and the
## aftermath never grant or announce a creature.
static func _chapter_grant_violations(chapter: Dictionary, legendaries: Dictionary,
		vocab: Array[String]) -> Array[String]:
	var bad: Array[String] = []
	var kind_re := RegEx.create_from_string(GRANT_KIND_NOUN)
	var rewards := _as_dict(chapter.get("rewards", null), "cloudreach_chapter.json rewards", bad)
	var grants := _as_array(rewards.get("grants", null), "rewards.grants", bad)
	if grants.is_empty():
		bad.append("rewards.grants is empty; this check would judge nothing")
	for grant: Variant in grants:
		var g := _as_dict(grant, "a rewards.grants entry", bad)
		var kind := str(g.get("kind", "")).to_lower()
		if kind_re.search(kind) != null:
			bad.append("rewards.grants '%s' has creature/offer kind '%s'" % [g.get("id", "?"), kind])
		for key: String in ["species", "species_id", "creature", "placeholder_species", "legendary", "offer"]:
			if g.has(key):
				bad.append("rewards.grants '%s' carries a '%s' field" % [g.get("id", "?"), key])
		for pair: Array in _strings_of(g):
			var reason := _identifier_reason(str(pair[1]), legendaries, vocab) if _is_identifier(str(pair[1])) else ""
			if reason != "":
				bad.append("rewards.grants '%s' %s ('%s')" % [g.get("id", "?"), reason, pair[1]])
	for feedback: Variant in _as_array(rewards.get("completion_feedback", []), "rewards.completion_feedback", bad):
		var reason := _identifier_reason(str(feedback), legendaries, vocab)
		if reason != "":
			bad.append("rewards.completion_feedback '%s' %s" % [feedback, reason])
	for objective: Dictionary in _dicts_with_key(chapter, "grants_flags"):
		for flag: Variant in _as_array(objective["grants_flags"], "grants_flags of '%s'" % objective.get("id", "?"), bad):
			var reason := _identifier_reason(str(flag), legendaries, vocab)
			if reason != "":
				bad.append("objective '%s' grants flag '%s': %s" % [objective.get("id", "?"), flag, reason])
	var aftermath := _as_dict(chapter.get("aftermath", null), "cloudreach_chapter.json aftermath", bad)
	for change: Variant in _as_array(aftermath.get("state_changes", null), "aftermath.state_changes", bad):
		var c := _as_dict(change, "an aftermath state change", bad)
		var system := str(c.get("system", "")).to_lower()
		if system in ["party", "creatures", "roster", "legendary", "companions"]:
			bad.append("aftermath '%s' changes creature system '%s'" % [c.get("id", "?"), system])
		var reason := _identifier_reason(str(c.get("id", "")), legendaries, vocab)
		if reason != "":
			bad.append("aftermath '%s' %s" % [c.get("id", "?"), reason])
	return bad


## Dialogue: every effect goes to the Cloudreach chapter's guarded dispatcher
## (cloudreach_chapter.gd handles only the `cloudreach:` prefix), no effect or
## guard event names an offer, a legendary or a legendary species, and no
## conversation is another realm's offer conversation. Spoken text is not
## judged.
static func _dialogue_violations(dialogue: Dictionary, npc_runtime: Dictionary, legendaries: Dictionary,
		vocab: Array[String], offer_conversations: Array[String]) -> Array[String]:
	var bad: Array[String] = []
	var conversations := _as_dict(dialogue.get("conversations", null), "dialogue conversations", bad)
	if conversations.is_empty():
		bad.append("data/dialogue/cloudreach.json has no conversations; this check would judge nothing")
	for id: String in conversations:
		if offer_conversations.has(id):
			bad.append("conversation '%s' is another realm's legendary offer conversation" % id)
		var effects: Array[String] = []
		for key: String in ["effect", "confirm_effect"]:
			for node: Dictionary in _dicts_with_key(conversations[id], key):
				effects.append(str(node[key]))
		for key: String in ["effects", "confirm_effects"]:
			for node: Dictionary in _dicts_with_key(conversations[id], key):
				for e: Variant in _as_array(node[key], "'%s' %s" % [id, key], bad):
					effects.append(str(e))
		for effect: String in effects:
			if effect == "":
				continue
			if effect.get_slice(":", 0) != "cloudreach":
				bad.append("'%s' effect '%s' is not a guarded cloudreach: chapter event" % [id, effect])
			var reason := _identifier_reason(effect, legendaries, vocab)
			if reason != "":
				bad.append("'%s' effect '%s' %s" % [id, effect, reason])
	for guard: Variant in _as_array(npc_runtime.get("dialogue_event_guards", null), "npc_runtime dialogue_event_guards", bad):
		var g := _as_dict(guard, "a dialogue guard", bad)
		for key: String in ["event", "effect"]:
			var reason := _identifier_reason(str(g.get(key, "")), legendaries, vocab)
			if reason != "":
				bad.append("dialogue guard %s '%s' %s" % [key, g.get(key, ""), reason])
	return bad


## Trainer tiers pay coins/items/xp only; items are items, never creatures;
## every reward/grant subtree anywhere in the corpus is creature-free.
static func _reward_violations(encounters: Dictionary, npc_runtime: Dictionary, corpus: Dictionary,
		items: Dictionary, all_species: Dictionary, legendaries: Dictionary) -> Array[String]:
	var bad: Array[String] = []
	var tiers := _as_dict(encounters.get("reward_tiers", null), "cloudreach_encounters.json reward_tiers", bad)
	if tiers.is_empty():
		bad.append("cloudreach_encounters.json reward_tiers is empty; this check would judge nothing")
	for tier: String in tiers:
		var reward := _as_dict(tiers[tier], "reward tier '%s'" % tier, bad)
		for key: String in reward:
			if not key.begins_with("_") and not TRAINER_REWARD_KEYS.has(key):
				bad.append("trainer reward tier '%s' has non-payable key '%s'" % [tier, key])
		for entry: Variant in _as_array(reward.get("items", []), "reward tier '%s' items" % tier, bad):
			var item_id := str((entry as Dictionary).get("id", "")) if entry is Dictionary else str(entry)
			if all_species.has(item_id):
				bad.append("trainer reward tier '%s' pays species '%s' as an item" % [tier, item_id])
			if str(_at(items, [item_id, "kind"])) in ["creature", "egg", "legendary"]:
				bad.append("trainer reward tier '%s' pays creature item '%s'" % [tier, item_id])
	for payoff: Dictionary in _dicts_with_key(npc_runtime, "reward_tier"):
		if not tiers.has(str(payoff["reward_tier"])):
			bad.append("npc runtime references unknown reward tier '%s'" % payoff["reward_tier"])
	# Every reward/grant-shaped subtree in every Cloudreach file.
	var kind_re := RegEx.create_from_string(GRANT_KIND_NOUN)
	var key_re := RegEx.create_from_string("(reward|grant|gift|give)")
	for file: String in corpus:
		var hits: Array = []
		_strings(corpus[file], file + ":", hits)
		for pair: Array in hits:
			var path := str(pair[0])
			var under_reward := false
			for part: String in path.split("."):
				var name := part.get_slice("[", 0).to_lower()
				if key_re.search(name) != null and not name in ["grants_flags", "giver_npc_id", "granted_at_landmark_id"]:
					under_reward = true
			if not under_reward:
				continue
			var leaf := path.get_slice(".", path.get_slice_count(".") - 1).get_slice("[", 0)
			var value := str(pair[1])
			if legendaries.has(value):
				bad.append("%s rewards legendary '%s'" % [path, value])
			elif (leaf == "kind" or leaf == "type") and kind_re.search(value.to_lower()) != null:
				bad.append("%s is a creature/offer grant kind '%s'" % [path, value])
			elif leaf in ["species", "species_id", "creature", "placeholder_species"]:
				bad.append("%s grants a creature '%s'" % [path, value])
	return bad


## No identifier anywhere in the Cloudreach corpus names a legendary, a
## legendary species or another realm's offer machinery, except the two exempt
## leaves of the pending entry. Prose values are not judged.
static func _corpus_violations(corpus: Dictionary, legendaries: Dictionary, vocab: Array[String],
		exempt: Dictionary) -> Array[String]:
	var bad: Array[String] = []
	for file: String in corpus:
		var hits: Array = []
		_strings(corpus[file], file + ":", hits)
		for pair: Array in hits:
			var path := str(pair[0])
			var value := str(pair[1])
			if exempt.has(path) or not _is_identifier(value):
				continue
			var reason := _identifier_reason(value, legendaries, vocab)
			if reason != "":
				bad.append("%s %s ('%s')" % [path, reason, value.left(80)])
	return bad


## No legendary species id as any identifier value outside the exempt leaves:
## not a trainer slot, reward, pickup, NPC or finale field.
static func _species_violations(corpus: Dictionary, legendaries: Dictionary, exempt: Dictionary) -> Array[String]:
	var bad: Array[String] = []
	for file: String in corpus:
		var hits: Array = []
		_strings(corpus[file], file + ":", hits)
		for pair: Array in hits:
			var path := str(pair[0])
			var value := str(pair[1]).to_lower()
			if exempt.has(path) or not _is_identifier(value):
				continue
			for id: String in legendaries:
				if id in value:
					bad.append("%s names legendary species '%s' (%s)" % [path, id, legendaries[id]])
	return bad


## The pending entry may not grow: anything added to it would ride the exemption.
func _pending_entry_shape_violations(chapter: Dictionary) -> Array[String]:
	var bad: Array[String] = []
	var entry_path := _pending_entry_path(chapter)
	if entry_path == "":
		bad.append("the pending %s entry in %s is gone; flip PENDING_OWNER_RULING_SOLMANE_SUMMIT_WILD" % [PENDING_SPECIES, PENDING_TABLE_ID])
		return bad
	for table: Dictionary in _dicts_with_key(chapter, "entries"):
		if str(table.get("id", "")) != PENDING_TABLE_ID:
			continue
		for entry: Variant in _as_array(table["entries"], "%s entries" % PENDING_TABLE_ID, bad):
			if str(_at(entry, ["placeholder_species"])) != PENDING_SPECIES:
				continue
			var keys: Array = (entry as Dictionary).keys()
			keys.sort()
			if keys != PENDING_ENTRY_KEYS:
				bad.append("the pending entry's keys are %s, expected exactly %s" % [keys, PENDING_ENTRY_KEYS])
			if str(_at(entry, ["roster_identity"])) != "legendary":
				bad.append("the pending entry's roster_identity changed to '%s'" % _at(entry, ["roster_identity"]))
	return bad


## {"found": {table_id: [legendary species]}, "bad": [shape violations]} over
## every Cloudreach wild table.
static func _wild_table_legendaries(chapter: Dictionary, legendaries: Dictionary) -> Dictionary:
	var bad: Array[String] = []
	var found := {}
	for table: Variant in _as_array(chapter.get("encounter_tables", null), "encounter_tables", bad):
		var t := _as_dict(table, "an encounter table", bad)
		for entry: Variant in _as_array(t.get("entries", null), "entries of '%s'" % t.get("id", "?"), bad):
			var e := _as_dict(entry, "an entry of '%s'" % t.get("id", "?"), bad)
			var species := str(e.get("placeholder_species", e.get("species", "")))
			if legendaries.has(species) or str(e.get("roster_identity", "")) == "legendary":
				var id := str(t.get("id", "?"))
				if not found.has(id):
					found[id] = []
				(found[id] as Array).append(species)
	return {"found": found, "bad": bad}


# --- source checks -----------------------------------------------------------------

## Cloudreach-owned code: no code that mints, hands over or resolves a
## legendary, and no call into the shared party seam or a party add.
static func _source_violations(sources: Dictionary, legendaries: Dictionary, vocab: Array[String]) -> Array[String]:
	var bad: Array[String] = []
	var tokens: Array[String] = ["legendary", "may_receive(", "offer_owed(", "pending_catch", PARTY_SEAM.get_file().get_basename()]
	for controller: String in OFFER_CONTROLLERS:
		tokens.append(controller.get_file())
	for word: String in vocab:
		if not tokens.has(word):
			tokens.append(word)
	for id: String in legendaries:
		tokens.append(id)
	# Any expression mentioning a party (party, Party, _party(), party_seam,
	# PartySeam, belt_party ...) followed by an add/append/insert, and any
	# local alias of the party used the same way.
	var party_add := RegEx.create_from_string(
		"(?i)party\\w*[^\\n]*(\\.(add|append|insert)\\(|call\\(\\s*[\"'](add|append|insert)[\"'])")
	var creature_add := RegEx.create_from_string("(?i)\\.(add|append|insert)\\(\\s*[\\w.]*creature")
	var alias_re := RegEx.create_from_string(
		"(?im)^\\s*var\\s+(\\w+)[^=\\n]*=[^\\n]*(get\\(\\s*[\"']party[\"']\\s*\\)|\\bparty\\b)")
	for path: String in sources:
		var code := _code_only(str(sources[path]))
		var lower := code.to_lower()
		for token: String in tokens:
			if token.to_lower() in lower:
				bad.append("%s code references '%s'" % [path, token])
		for re: RegEx in [party_add, creature_add]:
			var m := re.search(code)
			if m != null:
				bad.append("%s adds a creature to a party: '%s'" % [path, m.get_string().strip_edges().left(80)])
		for alias: RegExMatch in alias_re.search_all(code):
			var name := alias.get_string(1)
			var use := RegEx.create_from_string(
				"\\b%s\\s*\\.\\s*((add|append|insert)\\(|call\\(\\s*[\"'](add|append|insert)[\"'])" % name).search(code)
			if use != null:
				bad.append("%s adds a creature through party alias '%s': '%s'" % [path, name, use.get_string().left(80)])
	return bad


## Every line in scripts/ and autoload/ that says "cloudreach" and names a
## legendary, a legendary species or offer machinery, outside the allowance.
static func _cross_scan_violations(sources: Dictionary, legendaries: Dictionary, vocab: Array[String]) -> Array[String]:
	var bad: Array[String] = []
	var words: Array[String] = ["legendary", "volunteer", "pending_catch"]
	for id: String in legendaries:
		words.append(id)
	for word: String in vocab:
		if not words.has(word):
			words.append(word.to_lower())
	for path: String in sources:
		var lines := str(sources[path]).split("\n")
		for n in lines.size():
			var line: String = lines[n]
			var lower := line.to_lower()
			if not "cloudreach" in lower:
				continue
			for word: String in words:
				if word in lower:
					if not CROSS_SCAN_ALLOWED.has([path, line.strip_edges()]):
						bad.append("%s:%d ties Cloudreach to '%s': %s" % [path, n + 1, word, line.strip_edges().left(100)])
					break
	return bad


static func _file_refs(path: String, source: String) -> Array[String]:
	var out: Array[String] = []
	var text := _code_only(source) if path.ends_with(".gd") else source
	var re := RegEx.create_from_string(
		"(?:preload|load)\\(\\s*\"(res://[^\"]+\\.(?:gd|tscn))\"|(?m)^extends\\s+\"(res://[^\"]+\\.gd)\"|path=\"(res://[^\"]+\\.(?:gd|tscn))\"")
	for m: RegExMatch in re.search_all(text):
		for g in [1, 2, 3]:
			if m.get_string(g) != "":
				out.append(m.get_string(g))
	return out


## References of one file; cached unless the file is overridden.
func _refs(path: String, overrides: Dictionary) -> Array[String]:
	if overrides.has(path):
		return _file_refs(path, str(overrides[path]))
	var key := "refs:" + path
	if not _cache.has(key):
		_cache[key] = _file_refs(path, _text(path))
	return _cache[key]


func _source_of(path: String, overrides: Dictionary) -> String:
	return str(overrides[path]) if overrides.has(path) else _text(path)


static func _files_under(root: String, suffixes: Array) -> Array[String]:
	var out: Array[String] = []
	if not DirAccess.dir_exists_absolute(root):
		return out
	for file: String in DirAccess.get_files_at(root):
		for suffix: String in suffixes:
			if file.ends_with(suffix):
				out.append(root.path_join(file))
	for dir: String in DirAccess.get_directories_at(root):
		out.append_array(_files_under(root.path_join(dir), suffixes))
	return out


## Every script and scene the source scans consider, plus any override paths.
func _all_sources(overrides: Dictionary) -> Array[String]:
	var key := "all_sources"
	if not _cache.has(key):
		var files: Array[String] = []
		for root: String in SOURCE_ROOTS:
			files.append_array(_files_under(root, [".gd", ".tscn"]))
		_cache[key] = files
	var out: Array[String] = (_cache[key] as Array[String]).duplicate()
	for path: String in overrides:
		if not out.has(path):
			out.append(path)
	return out


func _named_cloudreach(files: Array[String]) -> Array[String]:
	var out: Array[String] = []
	for path: String in files:
		if "cloudreach" in path.get_file():
			out.append(path)
	out.sort()
	return out


## Root scripts of the other realms' scenes (realm_hearts.json `realms`), read
## from each scene's root node. A realm root builds that realm's world, its
## offer controller included, only when it IS the running scene; shared code
## may preload one for a static helper (world_look.gd calls
## `playground_world.gd::set_aerial_fade_colour`). Empty when the scenes are
## not checked out.
func _realm_root_scripts() -> Dictionary:
	var out := {}
	var realms: Variant = _dict(REALM_HEARTS_PATH).get("realms", {})
	if not realms is Dictionary:
		return out
	var ext_re := RegEx.create_from_string("(?m)^\\[ext_resource[^\\]\\n]*path=\"([^\"]+)\"[^\\]\\n]*id=\"([^\"]+)\"")
	var root_re := RegEx.create_from_string("(?m)^\\[node (?![^\\]\\n]*parent=)[^\\]\\n]*\\]\\s*\\nscript = ExtResource\\(\"([^\"]+)\"\\)")
	for realm: String in realms:
		if realm == "cloudreach":
			continue
		var scene := str(_at(realms, [realm, "scene"]))
		var text := _text(scene) if FileAccess.file_exists(scene) else ""
		var root := root_re.search(text)
		if root == null:
			continue
		for ext: RegExMatch in ext_re.search_all(text):
			if ext.get_string(2) == root.get_string(1):
				out[ext.get_string(1)] = realm
	return out


## {"seen": {path: true}, "parent": {path: referrer}, "starts": [...],
## "stopped": [realm roots reached]} over preload/load/extends and .tscn
## ext_resource edges from every Cloudreach-named script and scene. The walk
## does not continue past another realm's root script (see above).
func _cloudreach_closure(overrides: Dictionary, stops: Dictionary = {}) -> Dictionary:
	var starts := _named_cloudreach(_all_sources(overrides))
	var parent := {}
	var seen := {}
	var stopped: Array[String] = []
	var stack: Array[String] = starts.duplicate()
	while not stack.is_empty():
		var path: String = stack.pop_back()
		if seen.has(path):
			continue
		seen[path] = true
		if stops.has(path):
			stopped.append(path)
			continue
		for dep: String in _refs(path, overrides):
			if not seen.has(dep):
				if not parent.has(dep):
					parent[dep] = path
				stack.append(dep)
	return {"seen": seen, "parent": parent, "starts": starts, "stopped": stopped}


static func _chain(from: String, parent: Dictionary) -> String:
	var chain: Array[String] = [from]
	while parent.has(chain[-1]) and chain.size() < 64:
		chain.append(str(parent[chain[-1]]))
	return " <- ".join(chain)


## Cloudreach-owned scripts: named *cloudreach*, or in the Cloudreach closure
## and referenced ONLY by Cloudreach-owned scripts/scenes. Shared machinery
## (the encounter director, catching, the party seam itself) is referenced
## from other realms too and is judged by its own tests, not this one.
func _cloudreach_owned_scripts(overrides: Dictionary) -> Array[String]:
	var files := _all_sources(overrides)
	var referrers := {}
	for path: String in files:
		for dep: String in _refs(path, overrides):
			if not referrers.has(dep):
				referrers[dep] = {}
			(referrers[dep] as Dictionary)[path] = true
	var closure: Dictionary = _cloudreach_closure(overrides)["seen"]
	var owned := {}
	for path: String in _named_cloudreach(files):
		owned[path] = true
	var changed := true
	while changed:
		changed = false
		for path: String in closure:
			if owned.has(path) or not referrers.has(path):
				continue
			var only_owned := true
			for referrer: String in referrers[path]:
				if not owned.has(referrer):
					only_owned = false
					break
			if only_owned:
				owned[path] = true
				changed = true
	var out: Array[String] = []
	for path: String in owned:
		if path.ends_with(".gd") and (overrides.has(path) or FileAccess.file_exists(path)):
			out.append(path)
	out.sort()
	return out


## No Cloudreach script or scene reaches an offer controller, and nothing in
## the Cloudreach closure instantiates another realm's root script (which would
## build that realm's world and its offer). `roots` defaults to the derived
## realm roots; controls pass their own.
func _closure_violations(overrides: Dictionary, roots: Variant = null) -> Array[String]:
	var bad: Array[String] = []
	var stops: Dictionary = roots if roots is Dictionary else _realm_root_scripts()
	var closure := _cloudreach_closure(overrides, stops)
	var seen: Dictionary = closure["seen"]
	var parent: Dictionary = closure["parent"]
	if (closure["starts"] as Array).size() < 30:
		bad.append("only %d Cloudreach-named scripts/scenes found; the closure would judge nothing" % (closure["starts"] as Array).size())
	for controller: String in OFFER_CONTROLLERS:
		if seen.has(controller):
			bad.append("Cloudreach reaches offer controller: %s" % _chain(controller, parent))
	for root: String in stops:
		for path: String in seen:
			if not path.ends_with(".gd") or stops.has(path):
				continue
			var code := _code_only(_source_of(path, overrides))
			if not root in code:
				continue
			var names: Array[String] = []
			var const_re := RegEx.create_from_string("(?m)^\\s*(?:const|var)\\s+(\\w+)[^=\\n]*=\\s*(?:pre)?load\\(\\s*\"%s\"" % root)
			for m: RegExMatch in const_re.search_all(code):
				names.append(m.get_string(1))
			var use_res: Array[String] = ["(?:pre)?load\\(\\s*\"%s\"\\s*\\)\\s*\\.new\\(" % root]
			for name: String in names:
				use_res.append("\\b%s\\s*\\.\\s*new\\(" % name)
				use_res.append("set_script\\(\\s*%s\\b" % name)
			for pattern: String in use_res:
				var m := RegEx.create_from_string(pattern).search(code)
				if m != null:
					bad.append("%s instantiates %s's root %s: '%s'" % [path, stops[root], root, m.get_string()])
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


# --- inputs for the checks -----------------------------------------------------------

func _sources(paths: Array[String], overrides: Dictionary = {}) -> Dictionary:
	var out := {}
	for path: String in paths:
		out[path] = _source_of(path, overrides)
	return out


func _cross_scan_sources() -> Dictionary:
	var paths: Array[String] = []
	for root: String in CROSS_SCAN_ROOTS:
		paths.append_array(_files_under(root, [".gd"]))
	return _sources(paths)


func _offer_controllers() -> Array[String]:
	var out: Array[String] = []
	for path: String in OFFER_CONTROLLERS:
		out.append(path)
	return out


func _ledger_prefixes() -> Array:
	var prefixes: Array = WORLD_LEDGER.OWNED_FLAG_PREFIXES.duplicate()
	var configured: Variant = _at(_dict(MULTIPLAYER_PATH), ["ledger", "owned_flag_prefixes"])
	if configured is Array:
		prefixes.append_array(configured)
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
	var out := {}
	var species: Variant = _dict(SPECIES_PATH).get("species", {})
	if species is Dictionary:
		out.merge(species)
	var roster: Variant = _dict(WATER_ROSTER_PATH).get("species", {})
	if roster is Dictionary:
		out.merge(roster as Dictionary)
	out.merge(_legendary_species())
	return out


func _report(label: String, bad: Array[String]) -> void:
	for line: String in bad:
		print("    VIOLATION %s: %s" % [label, line])
	assert_true(bad.is_empty(), "%s: %d violation(s), first: %s" % [label, bad.size(), bad[0] if not bad.is_empty() else ""])


# --- tests ----------------------------------------------------------------------------

func test_every_input_exists_and_parses() -> void:
	for path: String in [CHAPTER_PATH, FINALE_PATH, ENCOUNTERS_PATH, NPC_RUNTIME_PATH, PHYSICAL_PATH,
			DIALOGUE_PATH, RECIPES_PATH, REALM_HEARTS_PATH, REGIONAL_ENDING_PATH, SPECIES_PATH,
			ITEMS_PATH, MULTIPLAYER_PATH, CLIMAX_CONFIG_PATH, STORMWOOD_CHAPTER_PATH,
			VEILFALL_CONFIG_PATH, WATER_ROSTER_PATH, WATER_ENCOUNTERS_PATH]:
		assert_false(_dict(path).is_empty(), "%s exists and parses to a non-empty object" % path)
	for path: String in [STORMWOOD_ENDING_SCRIPT, WATER_GUARDIAN_SCRIPT, PARTY_SEAM]:
		assert_false(_text(path).is_empty(), "%s exists" % path)
	var configs := _cloudreach_config_files()
	assert_true(configs.size() >= MIN_CLOUDREACH_CONFIG_FILES,
		"%d cloudreach*.json configs, expected at least %d" % [configs.size(), MIN_CLOUDREACH_CONFIG_FILES])
	var corpus := _corpus()
	assert_eq(corpus.size(), configs.size() + CORPUS_EXTRA_ENTRIES, "corpus = every Cloudreach config + dialogue, recipes, hearts and ending slices")
	for label: String in corpus:
		assert_true(corpus[label] is Dictionary or corpus[label] is Array, "corpus entry %s parsed" % label)
		assert_false(str(corpus[label]) in ["{}", "[]", "<null>"], "corpus entry %s is not empty" % label)
	assert_true(_missing_inputs.is_empty(), "no input failed to load: %s" % [_missing_inputs])


func test_legendary_species_and_offer_vocabulary_are_derived_from_every_realm() -> void:
	var legendaries := _legendary_species()
	print("    INFO legendary species derived from data: %s" % ", ".join(PackedStringArray(legendaries.keys())))
	assert_true(legendaries.has(str(_at(_dict(CLIMAX_CONFIG_PATH), ["legendary", "species"]))),
		"Meadows' Veridian comes from stronghold_climax.json")
	assert_true(legendaries.has(str(_string_consts(_text(STORMWOOD_ENDING_SCRIPT)).get("LEGENDARY_SPECIES", "?"))),
		"Stormwood's Stormheart species comes from stormwood_ending.gd")
	assert_true(legendaries.has(str(_dict(VEILFALL_CONFIG_PATH).get("guardian_species_id", "?"))),
		"Tidewake's Guardian comes from water_veilfall.json")
	assert_true(legendaries.size() >= 4, "at least four legendary ids are known, got %d" % legendaries.size())
	for controller: String in OFFER_CONTROLLERS:
		assert_true(FileAccess.file_exists(controller), "offer controller %s exists" % controller)
		var code := _code_only(_text(controller)).to_lower()
		assert_true("legendary" in code or "guardian" in code, "%s still carries legendary offer code" % controller)
	var storm_vocab := _script_vocabulary(_text(STORMWOOD_ENDING_SCRIPT))
	var water_vocab := _script_vocabulary(_text(WATER_GUARDIAN_SCRIPT))
	print("    INFO offer vocabulary: stormwood %s; tidewake %s" % [storm_vocab, water_vocab])
	assert_true(storm_vocab.size() >= 4, "Stormwood offer identifiers were learned (%d)" % storm_vocab.size())
	assert_true(water_vocab.size() >= 3, "Tidewake offer identifiers were learned (%d)" % water_vocab.size())
	for word: String in storm_vocab + water_vocab:
		assert_false(" " in word, "vocabulary holds identifiers, not display names ('%s')" % word)
		assert_false(word.begins_with("water_capture_receipt"), "the shared capture-codec receipt prefix is not offer machinery")
	assert_true(_offer_vocabulary().has("legendary:offer_shown"), "Stormwood's offer event was learned from stormwood_chapter.json")
	assert_true(_offer_conversations().size() >= 2, "Stormwood and Tidewake offer conversations were found")
	# Typed constants parse too.
	assert_eq(_string_consts("const A: String = \"typed_value\"\nconst B := \"inferred\"\n"),
		{"A": "typed_value", "B": "inferred"}, "typed and inferred string consts both parse")


func test_chapter_rewards_grant_no_creature_legendary_or_offer() -> void:
	_report("chapter grants", _chapter_grant_violations(_dict(CHAPTER_PATH), _legendary_species(), _offer_vocabulary()))


func test_finale_config_and_whole_cloudreach_corpus_name_no_legendary_offer() -> void:
	var corpus := _corpus()
	assert_true(corpus.has("cloudreach_finale.json") and str(corpus["cloudreach_finale.json"]) != "{}",
		"the finale config is part of the scanned corpus")
	var chapter := _dict(CHAPTER_PATH)
	_report("corpus", _corpus_violations(corpus, _legendary_species(), _offer_vocabulary(), _pending_exempt(chapter)))


func test_every_cloudreach_owned_script_makes_no_offer() -> void:
	var owned := _cloudreach_owned_scripts({})
	print("    INFO %d Cloudreach-owned scripts content-scanned" % owned.size())
	for required: String in ["res://scripts/world/cloudreach_finale_controller.gd", "res://scripts/world/cloudreach_chapter.gd",
			"res://scripts/combat/cloudreach_encounter_director.gd", "res://scripts/world/cloudreach_world.gd"]:
		assert_true(owned.has(required), "%s is content-scanned" % required)
	_report("scripts", _source_violations(_sources(owned), _legendary_species(), _offer_vocabulary()))


func test_no_line_in_scripts_ties_cloudreach_to_a_legendary() -> void:
	var sources := _cross_scan_sources()
	assert_true(sources.size() > 200, "scripts/ and autoload/ were scanned (%d files)" % sources.size())
	_report("cross scan", _cross_scan_violations(sources, _legendary_species(), _offer_vocabulary()))


func test_no_cloudreach_script_or_scene_reaches_another_realms_offer_controller() -> void:
	var roots := _realm_root_scripts()
	var closure := _cloudreach_closure({}, roots)
	for root: String in closure["stopped"]:
		print("    INFO the Cloudreach closure statically references %s's root script, not followed further: %s"
			% [roots[root], _chain(root, closure["parent"])])
	if roots.is_empty():
		print("    INFO realm scenes are not checked out; realm roots are unknown and every edge is followed")
	_report("closure", _closure_violations({}, roots))


func test_cloudreach_dialogue_effects_grant_no_creature_or_offer() -> void:
	_report("dialogue", _dialogue_violations(_dict(DIALOGUE_PATH), _dict(NPC_RUNTIME_PATH),
		_legendary_species(), _offer_vocabulary(), _offer_conversations()))


func test_trainer_and_activity_rewards_grant_no_creature() -> void:
	_report("rewards", _reward_violations(_dict(ENCOUNTERS_PATH), _dict(NPC_RUNTIME_PATH), _corpus(),
		_items(), _all_species(), _legendary_species()))


func test_no_legendary_species_anywhere_in_cloudreach_data_but_the_pending_entry() -> void:
	var chapter := _dict(CHAPTER_PATH)
	_report("species", _species_violations(_corpus(), _legendary_species(), _pending_exempt(chapter)))


func test_other_realms_offer_registries_do_not_name_cloudreach() -> void:
	var configs := _offer_configs()
	for label: String in configs:
		assert_false(str(configs[label]) in ["{}", "[]", "<null>"], "offer registry slice %s is not empty" % label)
	_report("registries", _registry_violations(_ledger_prefixes(), configs, _sources(_offer_controllers())))


func test_pending_solmane_is_the_only_wild_legendary_in_cloudreach() -> void:
	var chapter := _dict(CHAPTER_PATH)
	var result := _wild_table_legendaries(chapter, _legendary_species())
	_report("wild table shape", result["bad"])
	var expected := {PENDING_TABLE_ID: [PENDING_SPECIES]} if PENDING_OWNER_RULING_SOLMANE_SUMMIT_WILD else {}
	if PENDING_OWNER_RULING_SOLMANE_SUMMIT_WILD:
		_report("pending entry", _pending_entry_shape_violations(chapter))
		print("    INFO PENDING OWNER DECISION: cloudreach_chapter.json '%s' lists '%s' (roster_identity legendary) as a catchable wild. " % [PENDING_TABLE_ID, PENDING_SPECIES]
			+ "It is not an adoption offer and is tolerated only until ruled on; flip PENDING_OWNER_RULING_SOLMANE_SUMMIT_WILD in tests/test_cloudreach_no_legendary_offer.gd.")
	assert_eq(result["found"], expected, "legendary species in Cloudreach wild tables")


# --- harmless words must pass ---------------------------------------------------------

func test_harmless_cloudreach_words_do_not_fail() -> void:
	var legendaries := _legendary_species()
	var vocab := _offer_vocabulary()
	var dialogue := {"conversations": {"cloudreach_harmless": {"lines": [
		{"speaker": "Aila", "text": "They say the legendary skyroad once ran the whole summit.",
			"effect": "cloudreach:companion_rests"}]}}}
	var dialogue_bad := _dialogue_violations(dialogue, {"dialogue_event_guards": []}, legendaries, vocab, _offer_conversations())
	assert_true(dialogue_bad.is_empty(), "prose 'legendary' and effect 'companion_rests' pass the dialogue check: %s" % [dialogue_bad])
	var corpus := {"harmless.json": {"aviary_catch_hint": "cloudreach:companion_rests", "hint": "A legendary view.",
		"interaction_offer": "ride", "creature_bed": "camp_bed"}}
	var corpus_bad := _corpus_violations(corpus, legendaries, vocab, {})
	assert_true(corpus_bad.is_empty(), "harmless identifiers and prose pass the corpus check: %s" % [corpus_bad])
	print("    HARMLESS passed: dialogue %d violation(s), corpus %d violation(s)" % [dialogue_bad.size(), corpus_bad.size()])


# --- negative controls: the same checks, one fake legendary path each -----------------

func _control(label: String, bad: Array[String], expect: String = "") -> void:
	assert_false(bad.is_empty(), "negative control '%s' must produce a violation" % label)
	var first := bad[0] if not bad.is_empty() else "NOTHING (check is blind)"
	if expect != "":
		var matched := false
		for line: String in bad:
			if expect in line:
				matched = true
				first = line
				break
		assert_true(matched, "negative control '%s' must fire through '%s', got %s" % [label, expect, bad])
	print("    NEGATIVE-CONTROL %s fired: %s" % [label, first])


## Fails (rather than aborting as "ok") when a control's fixed shape moved.
func _need(value: Variant, is_array: bool, what: String) -> bool:
	var ok := value is Array if is_array else value is Dictionary
	assert_true(ok, "negative-control fixture '%s' no longer has the expected shape; update the control" % what)
	return ok


func test_negative_control_fake_legendary_chapter_grant() -> void:
	var chapter: Dictionary = _dict(CHAPTER_PATH).duplicate(true)
	var grants: Variant = _at(chapter, ["rewards", "grants"])
	if not _need(grants, true, "rewards.grants"):
		return
	(grants as Array).append({"id": "fake_solmane_offer", "kind": "legendary_offer", "species": PENDING_SPECIES})
	_control("chapter grant", _chapter_grant_violations(chapter, _legendary_species(), _offer_vocabulary()), "kind")


func test_negative_control_objective_grants_flags() -> void:
	var chapter: Dictionary = _dict(CHAPTER_PATH).duplicate(true)
	chapter["fake_side_content"] = {"objectives": [{"id": "fake_bond", "grants_flags": ["cloudreach_companion_joined"]}]}
	_control("objective grants_flags", _chapter_grant_violations(chapter, _legendary_species(), _offer_vocabulary()), "grants flag")


func test_negative_control_aftermath_changes_the_party() -> void:
	var chapter: Dictionary = _dict(CHAPTER_PATH).duplicate(true)
	var changes: Variant = _at(chapter, ["aftermath", "state_changes"])
	if not _need(changes, true, "aftermath.state_changes"):
		return
	(changes as Array).append({"id": "sky_friend_arrives", "system": "party", "change": "A new friend."})
	_control("aftermath", _chapter_grant_violations(chapter, _legendary_species(), _offer_vocabulary()), "creature system")


func test_negative_control_fake_offer_in_finale_config() -> void:
	var corpus := _corpus().duplicate(true)
	if not _need(corpus.get("cloudreach_finale.json"), false, "cloudreach_finale.json"):
		return
	(corpus["cloudreach_finale.json"] as Dictionary)["aftermath_offer_flag"] = "stormwood:legendary_offer_made"
	_control("finale corpus", _corpus_violations(corpus, _legendary_species(), _offer_vocabulary(),
		_pending_exempt(_dict(CHAPTER_PATH))), "aftermath_offer_flag")


func test_negative_control_derived_tidewake_vocabulary() -> void:
	# No 'legendary', no species, no verb+noun: only the vocabulary learned
	# from water_guardian_reward.gd can catch this identifier.
	var water_vocab := _script_vocabulary(_text(WATER_GUARDIAN_SCRIPT))
	if not _need(water_vocab if not water_vocab.is_empty() else null, true, "Tidewake vocabulary"):
		return
	var corpus := {"cloudreach_finale.json": {"relay_flag": water_vocab[0] + "abc"}}
	_control("derived vocabulary", _corpus_violations(corpus, _legendary_species(), _offer_vocabulary(), {}), "offer machinery")


func test_negative_control_pending_entry_cannot_grow() -> void:
	var chapter: Dictionary = _dict(CHAPTER_PATH).duplicate(true)
	var path := _pending_entry_path(chapter)
	if not PENDING_OWNER_RULING_SOLMANE_SUMMIT_WILD:
		return
	var found_at := RegEx.create_from_string("encounter_tables\\[(\\d+)\\]\\.entries\\[(\\d+)\\]").search(path)
	var entry: Variant = _at(chapter, ["encounter_tables", int(found_at.get_string(1)), "entries", int(found_at.get_string(2))]) if found_at != null else null
	if not _need(entry, false, "the pending entry"):
		return
	(entry as Dictionary)["on_defeat"] = "legendary_offer"
	_control("pending entry shape", _pending_entry_shape_violations(chapter), "keys are")
	var corpus := _corpus().duplicate(true)
	corpus["cloudreach_chapter.json"] = chapter
	_control("pending entry exemption", _corpus_violations(corpus, _legendary_species(), _offer_vocabulary(),
		_pending_exempt(chapter)), ".on_defeat")


func test_negative_control_fake_ceremony_in_finale_controller() -> void:
	var path := "res://scripts/world/cloudreach_finale_controller.gd"
	var sources := {path: _text(path) + "\nfunc _fake() -> void:\n\tgame.set(\"pending_catch\", creature)\n"}
	_control("finale controller", _source_violations(sources, _legendary_species(), _offer_vocabulary()), "pending_catch")


func test_negative_control_party_seam_route() -> void:
	# The review's example: a species-named effect plus a party-seam grant in
	# the chapter adapter.
	var path := "res://scripts/world/cloudreach_chapter.gd"
	var fake := {path: _text(path) + "\nconst PARTY_SEAM := preload(\"res://scripts/story/party_seam.gd\")\n" \
		+ "func _fake_gift() -> void:\n\tPARTY_SEAM.add(Game.make_creature(\"solmane\"))\n"}
	var owned := _cloudreach_owned_scripts(fake)
	if not _need(owned if owned.has(path) else null, true, "cloudreach_chapter.gd owned"):
		return
	var bad := _source_violations(_sources(owned, fake), _legendary_species(), _offer_vocabulary())
	_control("party seam", bad, "party_seam")
	_control("party seam species", bad, "'solmane'")


func test_negative_control_party_alias_add() -> void:
	var path := "res://scripts/world/cloudreach_world_payoffs.gd"
	var sources := {path: _text(path) + "\nfunc _fake_gift(gift: RefCounted) -> void:\n" \
		+ "\tvar belt: RefCounted = get_node(\"/root/Game\").get(\"party\")\n\tbelt.add(gift)\n"}
	_control("party alias", _source_violations(sources, {}, []), "alias 'belt'")


func test_negative_control_non_cloudreach_named_helper_is_owned_and_scanned() -> void:
	var world := "res://scripts/world/cloudreach_world.gd"
	var helper := "res://scripts/world/sky_gift_helper_fake.gd"
	var fake := {
		world: _text(world) + "\nconst SKY_GIFT := preload(\"%s\")\n" % helper,
		helper: "extends RefCounted\nconst SEAM := preload(\"res://scripts/story/party_seam.gd\")\n" \
			+ "static func gift(c: RefCounted) -> void:\n\tSEAM.add(c)\n",
	}
	var owned := _cloudreach_owned_scripts(fake)
	assert_true(owned.has(helper), "a helper referenced only by Cloudreach is Cloudreach-owned")
	var bad := _source_violations(_sources(owned, fake), _legendary_species(), _offer_vocabulary())
	_control("owned helper", bad, helper)


func test_negative_control_realm_root_instantiated() -> void:
	var path := "res://scripts/world/cloudreach_world.gd"
	var meadows := "res://scripts/world/playground_world.gd"
	var fake := {path: _text(path) + "\nconst MEADOWS_WORLD := preload(\"%s\")\nfunc _fake() -> void:\n\tadd_child(MEADOWS_WORLD.new())\n" % meadows}
	_control("realm root", _closure_violations(fake, {meadows: "meadows"}), "instantiates meadows's root")


func test_negative_control_fake_offer_controller_preload() -> void:
	var path := "res://scripts/world/cloudreach_finale_controller.gd"
	var fake := {path: _text(path) + "\nconst FAKE := preload(\"res://scripts/world/stormwood_ending.gd\")\n"}
	_control("closure", _closure_violations(fake), "stormwood_ending.gd")


func test_negative_control_cross_scan_line() -> void:
	var sources := _cross_scan_sources()
	var path := "res://scripts/ui/tab_map.gd"
	if not _need(sources if sources.has(path) else null, false, "tab_map.gd source"):
		return
	sources[path] = str(sources[path]) + "\n## Cloudreach's summit hands the player Solmane.\n"
	_control("cross scan", _cross_scan_violations(sources, _legendary_species(), _offer_vocabulary()), "solmane")


func test_negative_control_fake_dialogue_offer_effect() -> void:
	var dialogue: Dictionary = _dict(DIALOGUE_PATH).duplicate(true)
	if not _need(dialogue.get("conversations"), false, "dialogue conversations"):
		return
	(dialogue["conversations"] as Dictionary)["cloudreach_fake_volunteer"] = {
		"lines": [{"speaker": "Solmane", "text": "Take me.", "confirm_effect": "stormheart:accept"}]}
	_control("dialogue", _dialogue_violations(dialogue, _dict(NPC_RUNTIME_PATH), _legendary_species(),
		_offer_vocabulary(), _offer_conversations()), "stormheart:accept")


func test_negative_control_species_named_effect() -> void:
	var dialogue: Dictionary = _dict(DIALOGUE_PATH).duplicate(true)
	if not _need(dialogue.get("conversations"), false, "dialogue conversations"):
		return
	(dialogue["conversations"] as Dictionary)["cloudreach_fake_summit"] = {
		"lines": [{"speaker": "Aila", "text": "Look.", "effect": "cloudreach:solmane_joins"}]}
	_control("species effect", _dialogue_violations(dialogue, _dict(NPC_RUNTIME_PATH), _legendary_species(),
		_offer_vocabulary(), _offer_conversations()), "names legendary species 'solmane'")


func test_negative_control_dialogue_guard_event() -> void:
	var runtime: Dictionary = _dict(NPC_RUNTIME_PATH).duplicate(true)
	var guards: Variant = runtime.get("dialogue_event_guards")
	if not _need(guards, true, "npc_runtime dialogue_event_guards"):
		return
	(guards as Array).append({"conversation": "cloudreach_aila_final_reward", "effect": "cloudreach:cloudreach_aila_final_reward_complete",
		"event": "dialogue:legendary_offer", "requires_flags": []})
	_control("dialogue guard", _dialogue_violations(_dict(DIALOGUE_PATH), runtime, _legendary_species(),
		_offer_vocabulary(), _offer_conversations()), "dialogue guard event")


func test_negative_control_fake_trainer_creature_reward() -> void:
	var encounters: Dictionary = _dict(ENCOUNTERS_PATH).duplicate(true)
	var captain: Variant = _at(encounters, ["reward_tiers", "captain"])
	if not _need(captain, false, "reward_tiers.captain"):
		return
	(captain as Dictionary)["creature"] = {"species": PENDING_SPECIES}
	_control("trainer reward", _reward_violations(encounters, _dict(NPC_RUNTIME_PATH), _corpus(),
		_items(), _all_species(), _legendary_species()), "non-payable key")


func test_negative_control_fake_activity_reward_grant() -> void:
	var corpus := _corpus().duplicate(true)
	if not _need(corpus.get("cloudreach_physical_runtime.json"), false, "cloudreach_physical_runtime.json"):
		return
	(corpus["cloudreach_physical_runtime.json"] as Dictionary)["activity_rewards"] = {
		"aerie_trial": {"kind": "creature", "species": "fulgocobra"}}
	_control("activity reward", _reward_violations(_dict(ENCOUNTERS_PATH), _dict(NPC_RUNTIME_PATH), corpus,
		_items(), _all_species(), _legendary_species()), "activity_rewards")


func test_negative_control_fake_legendary_trainer_slot() -> void:
	var corpus := _corpus().duplicate(true)
	var slots: Variant = _at(corpus, ["cloudreach_chapter.json", "trainer_ladder", 0, "team_contract", "slots"])
	if not _need(slots, true, "trainer_ladder[0].team_contract.slots"):
		return
	(slots as Array).append({"role": "fake", "placeholder_species": "veridian", "level": 30})
	_control("trainer slot", _species_violations(corpus, _legendary_species(), _pending_exempt(_dict(CHAPTER_PATH))), "veridian")


func test_negative_control_second_wild_legendary() -> void:
	var chapter: Dictionary = _dict(CHAPTER_PATH).duplicate(true)
	var entries: Variant = _at(chapter, ["encounter_tables", 0, "entries"])
	if not _need(entries, true, "encounter_tables[0].entries"):
		return
	(entries as Array).append({"role": "fake", "placeholder_species": "fulgocobra", "weight": 1})
	var found: Dictionary = _wild_table_legendaries(chapter, _legendary_species())["found"]
	var expected := {PENDING_TABLE_ID: [PENDING_SPECIES]} if PENDING_OWNER_RULING_SOLMANE_SUMMIT_WILD else {}
	assert_ne(found, expected, "negative control 'second wild legendary' must differ from the allowed set")
	print("    NEGATIVE-CONTROL second wild legendary fired: found %s, allowed %s" % [found, expected])


func test_negative_control_fake_cloudreach_receipt_registry() -> void:
	var prefixes := _ledger_prefixes()
	prefixes.append("cloudreach:legendary_resolution:accepted:")
	_control("registry prefix", _registry_violations(prefixes, {}, {}), "receipt prefix")


func test_negative_control_offer_config_names_cloudreach() -> void:
	var configs := _offer_configs().duplicate(true)
	if not _need(configs.get("stronghold_climax.json:legendary"), false, "stronghold_climax.json legendary"):
		return
	(configs["stronghold_climax.json:legendary"] as Dictionary)["realm"] = "cloudreach"
	_control("registry offer config", _registry_violations([], configs, {}), "stronghold_climax.json:legendary")


func test_negative_control_offer_controller_names_cloudreach() -> void:
	var path := "res://scripts/world/stormwood_ending.gd"
	var sources := {path: _text(path) + "\nconst ALSO_IN := \"cloudreach\"\n"}
	_control("registry controller", _registry_violations([], {}, sources), "offer controller")
