extends "res://tests/test_case.gd"

## OP-0904-3 / CL-O3, the third item, which is a design rule rather than a bug.
##
## Owner, playing the shipped build: *"Nothing that is rideable should come
## with a saddle on it. You have to build the saddle and put it on then it
## visually appears. It shouldn't visually be there."*
##
## This file holds the half of that rule that is pure logic: WHICH species the
## saddle belongs on, and WHEN a fit counts as having happened. The half that
## needs a body standing in the world — no `RideSaddle` node before the fit,
## exactly one after it, on every rideable species — is
## `tests/smoke_riding_saddle.gd`, because `run_tests.gd` does all its work
## inside `_init()` and there is no tree, no autoload and no creature scene at
## that point.
##
## Everything here reads the REAL `data/creatures/species.json`, the same way
## `test_recipes.gd` reads the real recipe file: a species that gains or loses
## its `rideable` block fails here rather than silently changing what the
## saddle rule covers.

const RIDING := preload("res://scripts/world/riding_controller.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PROGRESSION_STATE := preload("res://autoload/progression_state.gd")

var store: RefCounted = null


func before_each() -> void:
	store = PROGRESSION_STATE.new()


## Every species carrying a `rideable` block, read from the data rather than
## typed here. The brief names Terrapup, Tuskroot and Burrowback as the roster
## CL-O9's design contract will add; this lane must not decide that, so the
## list is whatever the file says today and the assertions below hold for
## whatever it says tomorrow.
func _rideable_species() -> Array[String]:
	var found: Array[String] = []
	var file := FileAccess.open("res://data/creatures/species.json", FileAccess.READ)
	if file == null:
		return found
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return found
	var table: Variant = (parsed as Dictionary).get("species", {})
	if not table is Dictionary:
		return found
	for id: String in (table as Dictionary):
		if id.begins_with("_"):
			continue
		if SPECIES.is_rideable(id):
			found.append(id)
	found.sort()
	return found


func test_the_data_still_has_something_to_ride() -> void:
	# The guard every data-driven test needs: an empty roster would make every
	# loop below pass without asserting anything.
	assert_true(_rideable_species().size() > 0,
		"species.json declares no rideable species at all; the saddle rule has nothing to cover")


## Claim 1, the owner's "it shouldn't visually be there": at a new game nothing
## is fitted, so nothing wears a saddle. The flag store is what decides, and a
## fresh one is empty.
func test_nothing_is_fitted_at_the_start_of_a_new_game() -> void:
	for id in _rideable_species():
		assert_false(RIDING.saddle_is_fitted(id, store),
			"'%s' reads as saddle-fitted on a fresh save; the saddle would be on it before it was built" % id)


## Claim 3: build it, put it on, and from then on it reads as worn.
func test_fitting_is_what_makes_the_saddle_appear() -> void:
	for id in _rideable_species():
		if not RIDING.saddle_belongs_on(id):
			continue
		store.set_flag(RIDING.saddle_fitted_flag(id))
		assert_true(RIDING.saddle_is_fitted(id, store),
			"'%s' was fitted and still does not read as saddled" % id)


## The fit outlives the session. A saddle that has to be re-fitted after every
## load is a saddle the player will believe they lost.
func test_the_fit_survives_a_save_and_load() -> void:
	var ridden := _rideable_species()
	assert_true(ridden.size() > 0, "no rideable species to fit")
	for id in ridden:
		if RIDING.saddle_belongs_on(id):
			store.set_flag(RIDING.saddle_fitted_flag(id))
	var saved: Dictionary = store.save_data()
	var reloaded: RefCounted = PROGRESSION_STATE.new()
	reloaded.load_data(saved)
	for id in ridden:
		if not RIDING.saddle_belongs_on(id):
			continue
		assert_true(RIDING.saddle_is_fitted(id, reloaded),
			"'%s' lost its fitted saddle across a save/load round trip" % id)


## The exemption, and it is a story point rather than a special case:
## species.json's own `_comment_rideable` on the legendary says *"it carries you
## because it offered to"* and gives it an empty `requires_item`. Strapping the
## crafting bench's leather to it would say the wrong thing, so the saddle mesh
## is gated on the species' own required item and not on "is it rideable".
func test_a_mount_that_needs_no_tack_never_wears_a_saddle() -> void:
	var tackless: Array[String] = []
	var saddled: Array[String] = []
	for id in _rideable_species():
		if str(SPECIES.rideable(id).get("requires_item", "")) == "":
			tackless.append(id)
		else:
			saddled.append(id)
	assert_true(tackless.size() > 0,
		"no rideable species needs zero tack any more; R8.5's legendary advantage is gone")
	assert_true(saddled.size() > 0,
		"every rideable species is tack-free; the saddle craft gates nothing")
	for id in tackless:
		assert_false(RIDING.saddle_belongs_on(id),
			"'%s' needs no tack and the saddle mesh would still be hung on it" % id)
		# ...and not even setting the flag by hand puts one on it.
		store.set_flag(RIDING.saddle_fitted_flag(id))
		assert_false(RIDING.saddle_belongs_on(id),
			"'%s' picked up a saddle from a flag alone; the species' own requirement is meant to decide" % id)


## The flag id is a contract with the save file: rename it and every player's
## fitted saddle silently un-fits. Pinned so that rename has to be deliberate.
func test_the_fitted_flag_is_named_per_species() -> void:
	assert_eq(RIDING.saddle_fitted_flag("meadowhart"), "saddle_fitted_meadowhart",
		"the fitted-saddle flag id changed shape; existing saves would forget every fitting")
	assert_ne(RIDING.saddle_fitted_flag("meadowhart"), RIDING.saddle_fitted_flag("veridian"),
		"two species share one fitted flag; fitting either would saddle both")


## The saddle is the tournament's prize (D48 section 4) and the item id the
## rideable block asks for has to be the item the recipe makes, or the craft
## unlocks nothing a mount will accept.
func test_the_tack_a_mount_asks_for_is_the_item_the_recipe_makes() -> void:
	var recipes := FileAccess.open("res://data/recipes/recipes_rootstone.json", FileAccess.READ)
	assert_true(recipes != null, "recipes_rootstone.json is missing; the saddle cannot be crafted")
	if recipes == null:
		return
	var parsed: Variant = JSON.parse_string(recipes.get_as_text())
	assert_true(parsed is Dictionary, "recipes_rootstone.json is not valid JSON")
	if not parsed is Dictionary:
		return
	var makes := _crafted_ids(parsed as Dictionary)
	for id in _rideable_species():
		var required := str(SPECIES.rideable(id).get("requires_item", ""))
		if required == "":
			continue
		assert_true(makes.has(required),
			"'%s' wants '%s' to be ridden and no recipe makes it" % [id, required])


## The recipe file's shape is not this test's business, so the item ids are
## gathered from whichever of the usual keys it uses rather than assumed.
func _crafted_ids(table: Dictionary) -> Array:
	var ids: Array = []
	var entries: Variant = table.get("recipes", table)
	if entries is Dictionary:
		for key: String in (entries as Dictionary):
			if key.begins_with("_"):
				continue
			ids.append(key)
			var entry: Variant = (entries as Dictionary)[key]
			if entry is Dictionary and (entry as Dictionary).has("output"):
				ids.append(str((entry as Dictionary)["output"]))
	elif entries is Array:
		for entry: Variant in (entries as Array):
			if entry is Dictionary:
				ids.append(str((entry as Dictionary).get("id", "")))
				ids.append(str((entry as Dictionary).get("output", "")))
	return ids
