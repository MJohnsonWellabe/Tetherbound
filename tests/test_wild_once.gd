extends "res://tests/test_case.gd"

## WARRENS-ONCE, owner playtest 2026-09-03 item 9: "Burrow warrens: I can
## fight multiple elders on there. After I fight it and catch it or kill it I
## shouldn't get another chance. Same for the guardian."
##
## The mechanism (`encounter_director.gd`'s `spawn_wild()`/`_spawn_creatures()`/
## `_on_combat_exited()`, `burrow_warrens.gd`'s guardian/nicknamed-resident
## spawn opts) leans entirely on `/root/Game`'s real `progression` store, which
## `test_shiny.gd`'s own header already documents as unreachable from this
## suite (`--script` boots no autoloads and no SceneTree). So this file proves
## what D02's "pure logic only" scope actually allows:
##
##   * the flag-id maths itself (`_once_flag_for_nickname`), which touches no
##     tree at all -- a genuine behavioural check, not a source read;
##   * `progression_state.gd`'s own round-trip for the exact id shapes this
##     mechanism mints (`wild_once_<order>`, `warrens_cleared`, the derived
##     nickname flag), which is the store every one of those ids is written
##     into and read back from;
##   * the empty-id fast path (`_once_cleared("")`), which is what an ordinary
##     wild with no once-id at all takes, and which must never reach for
##     `/root/Game` in the first place;
##   * the SHAPE of the wiring in source, `test_wild_alphas.gd`'s own proven
##     style for a mechanism this suite cannot run live -- that `spawn_wild()`
##     actually checks `once_id` before building a body, that the cluster loop
##     actually skips a cleared alpha/elder's own slot, that a won/caught fight
##     actually fires the flag and skips the ordinary respawn timer, and that
##     the guardian's own once-id is the dungeon's existing clear flag rather
##     than a duplicate.
##
## `tests/smoke_warrens.gd` carries the live half: a second `BurrowWarrens`
## built against the same, already-cleared `/root/Game` progression store
## spawns no guardian at all.

const ENCOUNTER_DIRECTOR := preload("res://scripts/combat/encounter_director.gd")
const BURROW_WARRENS := preload("res://scripts/world/burrow_warrens.gd")
const PROGRESSION_STATE := preload("res://autoload/progression_state.gd")

const BAND_DIRS := [
	"band1_lower_meadows",
	"band2_stone_and_root",
	"band3_the_river_lock",
	"band4_upper_meadows_ironwood",
	"band5_stronghold_approach",
]


func _director_source() -> String:
	return FileAccess.get_file_as_string("res://scripts/combat/encounter_director.gd")


func _warrens_source() -> String:
	return FileAccess.get_file_as_string("res://scripts/world/burrow_warrens.gd")


func _spawns(band: String) -> Array:
	var file := FileAccess.open(
		"res://data/config/bands/%s/spawns.json" % band, FileAccess.READ)
	if file == null:
		return []
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		return []
	var d: Dictionary = parsed
	return d.get("clusters", d.get("spawns", []))


## Every `alpha`/`elder` entry across all five bands -- the same universe
## `test_wild_alphas.gd::_alphas()` walks for alphas alone, widened to elder
## because the once-only rule applies to both.
func _once_entries() -> Array:
	var out: Array = []
	for band: String in BAND_DIRS:
		for entry: Variant in _spawns(band):
			if not (entry is Dictionary):
				continue
			var d: Dictionary = entry
			if d.has("alpha") or d.has("elder"):
				out.append({"band": band, "entry": d})
	return out


# --- flag-id maths: real behaviour, no tree needed --------------------------

func test_once_flag_for_nickname_lowercases_and_underscores() -> void:
	var warrens: Node3D = BURROW_WARRENS.new()
	var flag: String = warrens.call("_once_flag_for_nickname", "Elder Trailpup")
	assert_eq(flag, "warrens_once_elder_trailpup")
	warrens.free()


func test_once_flag_for_nickname_is_stable_so_a_reload_finds_the_same_id() -> void:
	var warrens: Node3D = BURROW_WARRENS.new()
	var first: String = warrens.call("_once_flag_for_nickname", "Elder Trailpup")
	var second: String = warrens.call("_once_flag_for_nickname", "Elder Trailpup")
	assert_eq(first, second, "the same named resident must derive the same flag id every boot")
	warrens.free()


# --- the store these ids actually live in -----------------------------------

func test_a_band_alphas_once_id_survives_a_save_round_trip() -> void:
	var progression: RefCounted = PROGRESSION_STATE.new()
	# The exact id shape `_spawn_creatures()` mints: "wild_once_%d" % order.
	progression.call("set_flag", "wild_once_2006")
	var saved: Dictionary = progression.call("save_data")
	var reloaded: RefCounted = PROGRESSION_STATE.new()
	reloaded.call("load_data", saved)
	assert_true(bool(reloaded.call("has", "wild_once_2006")),
		"a band alpha's once-flag did not survive a save/load round trip")


func test_the_guardians_once_id_is_the_warrens_own_clear_flag() -> void:
	var progression: RefCounted = PROGRESSION_STATE.new()
	progression.call("set_flag", "warrens_cleared")
	assert_true(bool(progression.call("has", "warrens_cleared")))
	# Idempotent: `grant_clear_reward()` and the generic once-only path in
	# `_on_combat_exited()` can both race to set this exact id (whichever the
	# guardian's fight resolves through first), and neither may fail the other.
	progression.call("set_flag", "warrens_cleared")
	assert_true(bool(progression.call("has", "warrens_cleared")))


func test_a_nicknamed_residents_once_id_survives_a_save_round_trip() -> void:
	var warrens: Node3D = BURROW_WARRENS.new()
	var flag: String = warrens.call("_once_flag_for_nickname", "Elder Trailpup")
	warrens.free()
	var progression: RefCounted = PROGRESSION_STATE.new()
	progression.call("set_flag", flag)
	var reloaded: RefCounted = PROGRESSION_STATE.new()
	reloaded.call("load_data", progression.call("save_data"))
	assert_true(bool(reloaded.call("has", flag)))


# --- the empty-id fast path: never touches /root/Game at all ---------------

func test_once_cleared_short_circuits_on_an_empty_id_without_touching_the_tree() -> void:
	# `encounter_director.gd extends Node`; `.new()` never calls `_ready()`
	# outside a live SceneTree, the same off-tree construction
	# `test_shiny.gd::_roll()` already relies on. An empty id (the ordinary
	# seeded population, which never sets `opts["once_id"]`) has to read as
	# "never cleared" WITHOUT going anywhere near `_progression()` -- reaching
	# that helper's own `/root/Game` lookup on a node with no tree at all is
	# an engine-level error in Godot itself, not something this call should
	# ever risk for the common case.
	var director: Node = ENCOUNTER_DIRECTOR.new()
	assert_false(bool(director.call("_once_cleared", "")))
	director.free()


# --- data shape: every once-only entry has a stable, collision-free id ------

func test_every_alpha_or_elder_order_is_unique() -> void:
	# The flag id `_spawn_creatures()` mints is "wild_once_%d" % order; two
	# entries sharing an order would share a life.
	var seen: Dictionary = {}
	for row: Variant in _once_entries():
		var entry: Dictionary = (row as Dictionary)["entry"]
		var order := int(entry.get("order", -1))
		assert_true(order >= 0, "a once-only entry in %s has no order" % str((row as Dictionary)["band"]))
		assert_false(seen.has(order),
			"order %d is reused by more than one alpha/elder entry; their once-only flags would collide"
			% order)
		seen[order] = true


# --- the wiring's shape, `test_wild_alphas.gd`'s own proven style for a -----
# --- mechanism this suite cannot run live -----------------------------------

func test_spawn_wild_refuses_a_body_whose_once_id_already_fired() -> void:
	var source := _director_source()
	var start := source.find("func spawn_wild(")
	assert_true(start >= 0, "encounter_director.gd has no spawn_wild")
	if start < 0:
		return
	var end := source.find("\nfunc ", start + 1)
	var body := source.substr(start, (end - start) if end > start else -1)
	assert_true(body.contains("_once_cleared(once_id)"),
		"spawn_wild does not check whether its once_id already fired")
	assert_true(body.contains("return null"),
		"spawn_wild has no early-out for an already-cleared once_id")
	assert_true(body.contains("_once_only[wild] = once_id"),
		"spawn_wild does not remember a fresh once-only body, so its own fight "
		+ "could never find the id to fire")


func test_spawn_creatures_skips_a_clusters_own_alpha_or_elder_slot_once_cleared() -> void:
	var source := _director_source()
	assert_true(source.contains("once_already_cleared"),
		"_spawn_creatures no longer computes whether this entry's own alpha/elder "
		+ "already fired")
	assert_true(source.contains("if n == 0 and once_already_cleared:"),
		"_spawn_creatures does not skip the cluster's own named slot once its flag has fired")
	assert_true(source.contains('once_id = "wild_once_%d" % int(spawn.get("order"'),
		"the once-id is no longer derived from the spawn entry's own stable `order`")


func test_combat_exit_fires_the_flag_and_skips_the_respawn_timer_for_once_only_wilds() -> void:
	var source := _director_source()
	var start := source.find("func _on_combat_exited(")
	assert_true(start >= 0, "encounter_director.gd has no _on_combat_exited")
	if start < 0:
		return
	var end := source.find("\nfunc ", start + 1)
	var body := source.substr(start, (end - start) if end > start else -1)
	assert_true(body.contains("_once_only.get(wild"),
		"_on_combat_exited no longer looks up whether the departing wild is once-only")
	assert_true(body.contains("_mark_once_cleared(once_id)"),
		"_on_combat_exited no longer fires the once-only flag on a win/catch")
	# Both branches ("won" and CAUGHT) have to gate their OWN respawn-timer
	# write behind the once-id check, or a once-only wild would still come
	# back on the ordinary cooldown even with its flag set.
	var won_at := body.find('"won":')
	var caught_at := body.find("CAUGHT:")
	assert_true(won_at >= 0 and caught_at >= 0, "the won/CAUGHT branches moved")
	if won_at < 0 or caught_at < 0:
		return
	var won_branch := body.substr(won_at, caught_at - won_at)
	var caught_branch := body.substr(caught_at)
	for branch: Dictionary in [{"name": "won", "text": won_branch}, {"name": "CAUGHT", "text": caught_branch}]:
		assert_true(str(branch["text"]).contains("if once_id != \"\":"),
			"the %s branch does not branch on once_id before scheduling a respawn" % str(branch["name"]))
		assert_true(str(branch["text"]).contains("_respawn_timers[wild] = _respawn_delay_for(wild)"),
			"the %s branch lost its ordinary respawn scheduling for a ordinary wild" % str(branch["name"]))


func test_guardian_reuses_the_dungeons_own_clear_flag_as_its_once_id() -> void:
	var source := _warrens_source()
	assert_true(source.contains('guardian_opts["once_id"] = _clear_flag()'),
		"the guardian no longer spawns with an once_id at all, or uses a second, "
		+ "disagreeing flag instead of the dungeon's own clear flag")


func test_nicknamed_residents_get_a_once_id_derived_from_their_nickname() -> void:
	var source := _warrens_source()
	assert_true(source.contains('spawn_opts["once_id"] = _once_flag_for_nickname(once_nickname)'),
		"a named resident (the vault's Elder Trailpup) no longer spawns with its own once_id")


## The mechanism has nothing to apply to if the config it targets ever loses
## its one nicknamed entry.
func test_the_shipped_warrens_config_still_names_a_nicknamed_resident() -> void:
	var file := FileAccess.open("res://data/config/burrow_warrens.json", FileAccess.READ)
	assert_true(file != null, "burrow_warrens.json is missing")
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	assert_true(parsed is Dictionary, "burrow_warrens.json did not parse as an object")
	if not (parsed is Dictionary):
		return
	var cfg: Dictionary = parsed
	var found := false
	for entry: Variant in cfg.get("spawns", []):
		if entry is Dictionary and str((entry as Dictionary).get("nickname", "")) != "":
			found = true
	assert_true(found, "no spawns entry in burrow_warrens.json carries a nickname any more")
