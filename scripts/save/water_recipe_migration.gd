extends RefCounted

## F13#2: Reed Camp Cordage (`water_camp_cordage`) used to unlock at
## `water_chapter_started`; it is now taught per character by the host-validated
## `reed_root_hollow` claim (`water_cordage_recipe_learned`). A character that
## already knew it must keep it -- a load never takes a known recipe away.
##
## Transaction/migration declaration (PlayerState.flags, player scope,
## data/progression/flag_scopes.json):
##   * `GATE_MARKER` is stamped on every character when it arrives in the Water
##     (`water_chapter.gd::apply_personal_event("arrival")`), in the same call
##     that first writes `water_chapter_started`. A character carrying
##     `water_chapter_started` WITHOUT the marker therefore arrived before the
##     gate existed, i.e. it had the recipe from the chapter start.
##   * `repair()` grants that legacy character `LEARNED` and stamps the marker.
##     It is pure over the store, idempotent, and never removes a flag. It runs
##     on every PlayerState load (character file, joiner), on slot load, and at
##     arrival, so no load path can meet the marker first.
## A new character arrives with both flags written together and never passes
## the legacy test; it learns the recipe only from its own hollow claim.

const CHAPTER_STARTED := "water_chapter_started"
const LEARNED := "water_cordage_recipe_learned"
const GATE_MARKER := "water_cordage_recipe_gated"


## `flags` is a PlayerState flag store (`has`/`set_flag`). Returns true when it
## granted the legacy recipe.
static func repair(flags: Object) -> bool:
	if flags == null or not flags.has_method("has") or not flags.has_method("set_flag"):
		return false
	if bool(flags.call("has", GATE_MARKER)):
		return false
	if not bool(flags.call("has", CHAPTER_STARTED)):
		return false
	var granted := not bool(flags.call("has", LEARNED))
	if granted:
		flags.call("set_flag", LEARNED, true)
	flags.call("set_flag", GATE_MARKER, true)
	return granted
