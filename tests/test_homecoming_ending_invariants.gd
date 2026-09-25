extends "res://tests/test_case.gd"

## F15 ending invariants (ACCEPTANCE §6.1, WORLD §6.5). The homecoming and the
## credits are a player-local acknowledgement, nothing more: they must not add
## a fifth realm key, promise a sequel, claim every force was freed, resurrect
## a released companion, or hand out anything a second time.
##
## Driven the same way `test_regional_homecoming.gd` drives it (runner +
## `regional_homecoming.gd` transaction, the calls `sequence_director.gd`
## makes on completion and on credits acknowledgement), but over the REAL
## `player_state.gd` / `world_state.gd` stores so the whole portable character
## and the whole world snapshot can be compared, not one flag at a time.

const HOMECOMING := preload("res://scripts/story/regional_homecoming.gd")
const RUNNER := preload("res://scripts/story/dialogue_runner.gd")
const PLAYER_STATE := preload("res://autoload/player_state.gd")
const WORLD_STATE := preload("res://autoload/world_state.gd")
const ITEM_DB := preload("res://autoload/item_db.gd")

const FLAG_SCOPES_PATH := "res://data/progression/flag_scopes.json"
const OBJECTIVES_PATH := "res://data/config/regional_ending_objectives.json"
const CREDITS_PATH := "res://data/config/regional_credits.json"
const HOMECOMING_DIALOGUE_PATH := "res://data/dialogue/homecoming.json"
const WATER_DIALOGUE_PATH := "res://data/dialogue/water.json"
const HOMECOMING_SCRIPT_PATH := "res://scripts/story/regional_homecoming.gd"
const CREDITS_SCRIPT_PATH := "res://scripts/ui/regional_credits.gd"

## The three keys this four-chapter pass earns: Meadows->Cloudreach,
## Cloudreach->Stormwood, Stormwood->Water. A fourth chapter's ending has no
## door to open, so a fifth entry would be an invented next realm.
const EXPECTED_REALM_KEYS: Array[String] = [
	"realm_key_cloudreach", "realm_key_stormwood", "realm_key_water",
]

## Lower-cased substrings that would break WORLD §6.5 ("no post-credits sequel
## sting, invented count of unresolved forces or fifth-chapter prompt") or the
## F15 row ("without ... claim all eight forces were freed"). Chosen as whole
## phrases rather than single words so ordinary aftermath prose stays legal:
## "continue" alone is the credits' own "Continue or Skip" instruction, and
## Sella's "the next expedition" is local swimming advice, not a new chapter.
## "chapter 5"/"chapter five"/"fifth chapter"/"next chapter" = a chapter prompt;
## "sequel", "to be continued", "coming soon", "story continues",
## "adventure continues", "next adventure" = a sequel sting; "all eight",
## "eight forces", "every force", "all forces", "all the forces",
## "forces are free", "forces were freed" = a cosmology-wide victory claim;
## "fifth key", "fifth realm" = an invented next door.
const FORBIDDEN_PHRASES: Array[String] = [
	"sequel", "to be continued", "coming soon", "story continues",
	"adventure continues", "next adventure",
	"next chapter", "fifth chapter", "chapter five", "chapter 5",
	"all eight", "eight forces", "every force", "all forces", "all the forces",
	"forces are free", "forces were freed",
	"fifth key", "fifth realm",
]

## The only player flags either acknowledgement is documented to write.
const DOCUMENTED_ENDING_FLAGS: Array[String] = [
	HOMECOMING.SEEN_FLAG, HOMECOMING.CREDITS_SEEN_FLAG,
]


class SaverStub:
	extends RefCounted
	var calls := 0
	var saved_character := ""

	func save_character(_game: Object, character_id: String) -> bool:
		calls += 1
		saved_character = character_id
		return true


## The fields `regional_homecoming.gd` reads off `Game`, backed by the real
## per-character and per-world stores.
class GameStub:
	extends RefCounted
	var world: RefCounted = null
	var local: RefCounted = null
	var party: RefCounted = null
	var save_system: RefCounted = SaverStub.new()
	var messages: Array[String] = []

	func push_world_message(message: String) -> void:
		messages.append(message)


# --- 1: no fifth key ---------------------------------------------------------

func test_only_three_realm_keys_are_declared() -> void:
	var scopes: Dictionary = _json(FLAG_SCOPES_PATH)
	var found: Array[String] = []
	_collect_realm_key_strings(scopes, found)
	found.sort()
	assert_eq(found, EXPECTED_REALM_KEYS,
		"flag_scopes.json declares exactly the three chapter keys and no fifth")


func test_ending_sources_never_name_a_realm_key() -> void:
	# Stronger than "never writes": none of these files so much as mentions a
	# realm_key_* id, so no code or data path here can set, grant or migrate
	# one. A future need to READ a key here should revisit this deliberately.
	for path: String in [OBJECTIVES_PATH, CREDITS_PATH, HOMECOMING_DIALOGUE_PATH,
			HOMECOMING_SCRIPT_PATH, CREDITS_SCRIPT_PATH]:
		var text := FileAccess.get_file_as_string(path)
		assert_false(text.is_empty(), path + " is readable")
		assert_false(text.contains("realm_key"), path + " must not name a realm key")


func test_ending_path_adds_no_realm_key_to_either_store() -> void:
	# The fixture world legitimately holds the spent Water key from Stormwood's
	# finale; the ending may neither add another key nor touch that one.
	var game := _ending_game([["terrapup", "Pip"]])
	var before := _realm_keys(game)
	assert_eq(before, ["realm_key_water"], "fixture carries the earned Water key")
	_run_homecoming_and_credits(game)
	assert_eq(_realm_keys(game), before, "ending path adds or removes no realm key")


# --- 2: no sequel / all-forces claim ----------------------------------------

func test_ending_text_makes_no_sequel_or_all_forces_claim() -> void:
	var texts: Array[String] = []
	_collect_visible(_json(HOMECOMING_DIALOGUE_PATH), texts)
	_collect_visible(_json(CREDITS_PATH), texts)
	_collect_visible(_json(OBJECTIVES_PATH), texts)
	var water: Dictionary = _json(WATER_DIALOGUE_PATH).get("conversations", {})
	var aftermath := 0
	for id: String in water:
		if id.ends_with("_post"):
			aftermath += 1
			_collect_visible(water[id], texts)
	assert_true(water.has("water_mara_post"), "Mara's afterword is among the scanned lines")
	assert_true(aftermath >= 18, "every Water aftermath conversation is scanned")
	assert_true(texts.size() > 60, "the scan actually reached player-visible prose")
	for text: String in texts:
		var lowered := text.to_lower()
		for phrase: String in FORBIDDEN_PHRASES:
			assert_false(lowered.contains(phrase),
				"ending text claims '%s': %s" % [phrase, text])


func test_forbidden_phrase_scan_detects_a_planted_claim() -> void:
	# Guard against a scan that silently reads nothing: a planted sequel line
	# in the same shape as a real conversation must be caught.
	var texts: Array[String] = []
	_collect_visible({"lines": ["All Eight Forces are free. To be continued..."]}, texts)
	var hits := 0
	for phrase: String in FORBIDDEN_PHRASES:
		hits += 1 if texts[0].to_lower().contains(phrase) else 0
	assert_true(hits >= 2)


# --- 3: no mutation beyond the documented flags, no duplicate rewards --------

func test_homecoming_and_credits_change_only_documented_player_flags() -> void:
	var game := _ending_game([
		["terrapup", "Pip"], ["brooktail", ""], ["mosshell", "Shelby"],
	])
	var world_before := JSON.stringify(game.world.save_data())
	var local_before: Dictionary = game.local.save_data()
	var flags_before: Array = local_before.get("flags", {}).get("flags", []).duplicate()
	var party_before := _party_fingerprint(game)
	var skills_before := JSON.stringify(game.local.skills.save_data())
	var inventory_before := JSON.stringify(local_before.get("inventory"))

	_run_homecoming_and_credits(game)

	var local_after: Dictionary = game.local.save_data()
	assert_eq(JSON.stringify(game.world.save_data()), world_before,
		"world snapshot is byte-identical after homecoming and credits")
	assert_eq(JSON.stringify(local_after.get("inventory")), inventory_before,
		"inventory unchanged: the ending grants no item")
	assert_eq(_party_fingerprint(game), party_before,
		"party ids, species, levels and XP unchanged")
	assert_eq(JSON.stringify(game.local.skills.save_data()), skills_before,
		"player skill XP unchanged")
	var expected_flags: Array = flags_before.duplicate()
	expected_flags.append_array(DOCUMENTED_ENDING_FLAGS)
	expected_flags.sort()
	var flags_after: Array = local_after.get("flags", {}).get("flags", []).duplicate()
	flags_after.sort()
	assert_eq(flags_after, expected_flags,
		"only homecoming_seen and regional_credits_seen are added")
	# Everything else on the portable character, byte for byte.
	local_before.erase("flags")
	local_after.erase("flags")
	assert_eq(JSON.stringify(local_after), JSON.stringify(local_before),
		"no other portable-character field changes")
	assert_eq(game.save_system.calls, 2, "one save per acknowledgement")
	assert_true(game.messages.is_empty(), "no failure notices on the happy path")


func test_second_visit_changes_nothing_and_grants_nothing() -> void:
	var game := _ending_game([["terrapup", "Pip"], ["mosshell", ""]])
	_run_homecoming_and_credits(game)
	var world_once := JSON.stringify(game.world.save_data())
	var local_once := JSON.stringify(game.local.save_data())
	var saves_once: int = game.save_system.calls

	# Talk to Grandpa again: only the repeat greeting is offered, and when it
	# completes the director asks credits_pending(), which must be false.
	assert_eq(HOMECOMING.conversation_id(game), HOMECOMING.REPEAT_ID)
	var completed := _talk(game, HOMECOMING.conversation_id(game), {})
	assert_eq(completed, [HOMECOMING.REPEAT_ID])
	assert_false(HOMECOMING.credits_pending(game), "credits do not reopen after completion")
	# Even a stray re-entry of both transactions is an idempotent no-op.
	assert_true(HOMECOMING.complete(game, HOMECOMING.character_id(game)))
	assert_true(HOMECOMING.complete_credits(game, HOMECOMING.character_id(game)))

	assert_eq(JSON.stringify(game.world.save_data()), world_once, "second visit leaves the world as it was")
	assert_eq(JSON.stringify(game.local.save_data()), local_once, "second visit grants nothing")
	assert_eq(game.save_system.calls, saves_once, "second visit saves nothing new")


# --- 4: released companions are not named -----------------------------------

func test_released_companion_is_not_named_by_grandpa() -> void:
	var game := _ending_game([
		["terrapup", "Pip"], ["brooktail", "Rill"], ["mosshell", "Shelby"],
	])
	# The release ceremony (tab_creatures.gd) removes the chosen creature from
	# the party; there is no reserve it could be read back from.
	var released: RefCounted = game.local.party.remove_at(1)
	assert_eq(str(released.get("nickname")), "Rill")
	var released_display := str(released.get("display_name"))
	var id := HOMECOMING.conversation_id(game)
	assert_eq(id, "regional_homecoming_2", "the acknowledgement counts the current team")
	var spoken: Array[String] = []
	_talk(game, id, HOMECOMING.substitutions(game), spoken)
	var joined := "\n".join(spoken)
	assert_true(joined.contains("Pip") and joined.contains("Shelby"),
		"current companions are acknowledged")
	assert_false(joined.contains("Rill"), "released companion's nickname is not spoken")
	assert_false(joined.contains(released_display),
		"released companion's species name is not spoken either")
	assert_false(joined.contains("$party_"), "no unsubstituted token leaks a slot")


# --- helpers -------------------------------------------------------------------

## A Meadows character in a world whose currents are restored, carrying a
## non-trivial inventory, party progress and skill XP so "unchanged" means
## something.
func _ending_game(members: Array) -> GameStub:
	var game := GameStub.new()
	var world: RefCounted = WORLD_STATE.new()
	world.world_id = "world-ending-invariants"
	world.flags.set_flag(HOMECOMING.WORLD_FLAG)
	world.flags.set_flag("water_captain_nerissa_defeated")
	world.flags.set_flag("realm_key_water")
	var local: RefCounted = PLAYER_STATE.new()
	local.configure(ITEM_DB.new())
	local.character_id = "character-ending-invariants"
	local.realm = "meadows"
	local.flags.set_flag("opening_free_play")
	assert_eq(local.inventory.add("wood", 7), 0)
	assert_eq(local.inventory.add("stone", 3), 0)
	assert_eq(local.inventory.add("cloudberry", 2), 0)
	var level := 30
	for row: Array in members:
		var creature: RefCounted = local.make_creature(str(row[0]), str(row[1]))
		assert_true(creature != null, "species exists: " + str(row[0]))
		creature.level = level
		creature.xp = 11 * level
		level += 3
		assert_true(local.party.add(creature))
	local.skills.add_xp("running", 12.5)
	local.skills.add_xp("swimming", 4.0)
	assert_true(local.skills.level("running") > 0 or local.skills.fraction("running") > 0.0,
		"fixture skill XP is non-zero, so 'unchanged' is a real comparison")
	game.world = world
	game.local = local
	game.party = local.party
	return game


## The director's path: open the initial conversation with the current
## substitutions, and on `completed` save homecoming; then the credits roll's
## `acknowledged` saves the credits receipt.
func _run_homecoming_and_credits(game: GameStub) -> void:
	var id := HOMECOMING.conversation_id(game)
	assert_true(HOMECOMING.is_initial(id), "fresh character is offered the initial homecoming")
	var character := HOMECOMING.character_id(game)
	var completed := _talk(game, id, HOMECOMING.substitutions(game))
	assert_eq(completed, [id])
	assert_true(HOMECOMING.complete(game, character))
	assert_true(HOMECOMING.credits_pending(game), "credits open after the saved homecoming")
	assert_true(HOMECOMING.complete_credits(game, character))
	assert_false(HOMECOMING.credits_pending(game))


func _talk(_game: GameStub, id: String, values: Dictionary,
		spoken: Array[String] = []) -> Array[String]:
	var runner := RUNNER.new()
	var completed: Array[String] = []
	runner.completed.connect(func(done: String) -> void: completed.append(done))
	runner.set_values(values)
	assert_true(runner.start(id), "conversation starts: " + id)
	var guard := 0
	while runner.is_active() and guard < 64:
		spoken.append(str(runner.line().get("text", "")))
		runner.advance()
		guard += 1
	return completed


## Every realm_key_* id held by either store, world first then player.
func _realm_keys(game: GameStub) -> Array[String]:
	var out: Array[String] = []
	for store: RefCounted in [game.world.flags, game.local.flags]:
		for id: Variant in store.save_data().get("flags", []):
			if str(id).begins_with("realm_key_"):
				out.append(str(id))
	return out


func _party_fingerprint(game: GameStub) -> String:
	var rows: Array = []
	for creature: RefCounted in game.local.party.members():
		rows.append([str(creature.get("uid")), str(creature.get("species_id")),
			str(creature.get("nickname")), int(creature.get("level")), int(creature.get("xp"))])
	return JSON.stringify(rows)


func _collect_realm_key_strings(node: Variant, out: Array[String]) -> void:
	if node is Dictionary:
		for key: Variant in node:
			_collect_realm_key_strings(key, out)
			_collect_realm_key_strings(node[key], out)
	elif node is Array:
		for entry: Variant in node:
			_collect_realm_key_strings(entry, out)
	elif node is String and (node as String).begins_with("realm_key") \
			and not out.has(node as String):
		out.append(node as String)


## Every string a player can see. Skipped: `_comment*` notes, the credits'
## `layout_note`, asset paths and flag/realm ids, which are never rendered.
func _collect_visible(node: Variant, out: Array[String]) -> void:
	if node is Dictionary:
		for key: Variant in node:
			var name := str(key)
			if name.begins_with("_") or name in ["layout_note", "portrait", "flag_id",
					"id", "scope", "required_world_flag", "supported_realms", "motion", "layout"]:
				continue
			_collect_visible(node[key], out)
	elif node is Array:
		for entry: Variant in node:
			_collect_visible(entry, out)
	elif node is String:
		out.append(node as String)


func _json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	assert_true(parsed is Dictionary, path + " parses")
	return parsed if parsed is Dictionary else {}
